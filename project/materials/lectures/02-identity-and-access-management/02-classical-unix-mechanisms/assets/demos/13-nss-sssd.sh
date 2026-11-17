#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='NSS + SSSD: passwd/group from LDAP, custom actions ([!UNAVAIL=return] trap, [SUCCESS=merge]), sss memory cache'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
# Prerequisites: apt-get install slapd ldap-utils sssd libnss-sss
# (installing libnss-sss appends sss to passwd/group/shadow in /etc/nsswitch.conf:
#  on Ubuntu Server 26.04 the lines become "files systemd sss").
need getent id slapd sssd ldapadd ldapsearch debconf-set-selections dpkg-reconfigure \
     groupadd gpasswd groupdel useradd userdel sed install systemctl

# DANGER: this demo RECONFIGURES slapd (any existing directory is moved aside by
# dpkg-reconfigure), replaces /etc/sssd/sssd.conf and edits /etc/nsswitch.conf.
# Run it ONLY on a disposable VM. The LDAP admin password is a public lab value.
BASE='dc=example,dc=test'
ADMIN="cn=admin,$BASE"
LDAP_PW='LabLDAP-42!'
U1=ossec-demo1 G=developers

! getent -s files passwd "$U1" >/dev/null || die "$U1 already exists"
! getent -s files group "$G" >/dev/null || die "group $G already exists"
[[ ! -e /etc/sssd/sssd.conf ]] || die '/etc/sssd/sssd.conf already exists; refusing to overwrite'
grep -Eq '^passwd:.*\bsss\b' /etc/nsswitch.conf || die 'passwd line of nsswitch.conf has no sss source; install libnss-sss'
install -m 600 /etc/nsswitch.conf "$DEMO_TMP/nsswitch.conf.orig"
restore_nss() { install -m 644 "$DEMO_TMP/nsswitch.conf.orig" /etc/nsswitch.conf; }
cleanup() {
  local rc=0
  restore_nss 2>/dev/null || rc=1
  systemctl stop sssd 2>/dev/null || true
  rm -f /etc/sssd/sssd.conf
  find /var/lib/sss/db /var/lib/sss/mc -type f -delete 2>/dev/null || true
  systemctl stop slapd 2>/dev/null || true
  ! getent -s files group "$G" >/dev/null || groupdel "$G" || rc=1
  if getent -s files passwd "$U1" >/dev/null; then
    userdel -r "$U1" 2>/dev/null || userdel "$U1" || { printf 'Remove %s manually\n' "$U1" >&2; rc=1; }
  fi
  return "$rc"
}

set_db() { sed -i -E "s/^($1):.*/\1:\t\t$2/" /etc/nsswitch.conf; }

printf '\n### 0. A local user and a minimal LDAP directory with user dave\n'
run useradd -m -s /bin/bash "$U1"
debconf-set-selections <<EOF
slapd slapd/domain string example.test
slapd shared/organization string OSSec Lab
slapd slapd/password1 password $LDAP_PW
slapd slapd/password2 password $LDAP_PW
slapd slapd/no_configuration boolean false
slapd slapd/move_old_database boolean true
EOF
dpkg-reconfigure -f noninteractive slapd
systemctl restart slapd
ldapadd -x -D "$ADMIN" -w "$LDAP_PW" <<EOF
dn: ou=people,$BASE
objectClass: organizationalUnit
ou: people

dn: ou=groups,$BASE
objectClass: organizationalUnit
ou: groups

dn: uid=dave,ou=people,$BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: dave
cn: Dave Directory
sn: Directory
uidNumber: 5000
gidNumber: 5000
homeDirectory: /home/dave
loginShell: /bin/bash

dn: cn=dave,ou=groups,$BASE
objectClass: posixGroup
cn: dave
gidNumber: 5000

dn: cn=$G,ou=groups,$BASE
objectClass: posixGroup
cn: $G
gidNumber: 5100
memberUid: dave
EOF
run ldapsearch -x -LLL -b "ou=people,$BASE" '(uid=dave)'

printf '\n### 1. SSSD serves the directory to NSS through the sss backend\n'
install -m 600 /dev/null /etc/sssd/sssd.conf
cat > /etc/sssd/sssd.conf <<EOF
[sssd]
config_file_version = 2
domains = example.test
services = nss, pam

[domain/example.test]
id_provider = ldap
ldap_uri = ldap://localhost
ldap_search_base = $BASE
# Lab shortcut: production deployments must use TLS on the id channel.
ldap_id_use_start_tls = false
ldap_auth_disable_tls_never_use_in_production = true
sudo_provider = none
cache_credentials = true
enumerate = true
EOF
run cat /etc/sssd/sssd.conf
run systemctl restart sssd
sleep 4
run grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf

printf '\n### 2. One getpwnam interface, two sources\n'
run grep -E '^(passwd|group):' /etc/nsswitch.conf
run grep dave /etc/passwd || printf 'exit status: %s\n' "$?"
run grep -E "dave|$G" /etc/group || printf 'exit status: %s\n' "$?"
run getent passwd "$U1"
run getent passwd dave
run getent -s files passwd dave || printf 'exit status: %s\n' "$?"
run getent -s sss passwd dave
run id dave

printf '\n### 3. Trap: passwd: sss [!UNAVAIL=return] files hides local accounts\n'
set_db passwd 'sss [!UNAVAIL=return] files systemd'
run grep '^passwd:' /etc/nsswitch.conf
run getent passwd dave
run getent passwd root || printf 'exit status: %s\n' "$?"
run getent passwd "$U1" || printf 'exit status: %s\n' "$?"
printf '\n--- sssd is stopped: sss returns UNAVAIL, files is reachable again ---\n'
run systemctl stop sssd
sleep 1
run getent passwd root
restore_nss
run systemctl start sssd
sleep 4

printf '\n### 4. [SUCCESS=merge]: one group, members from both sources\n'
set_db group 'files systemd'    # otherwise groupadd sees the LDAP group and refuses
run groupadd -g 5100 "$G"       # same name and GID as the LDAP group
run gpasswd -a "$U1" "$G"
run grep "^$G" /etc/group
restore_nss
run grep '^group:' /etc/nsswitch.conf
run getent group "$G"
# merge joins two ADJACENT sources, so sss goes right after files
# ("files [SUCCESS=merge] systemd sss" does not merge the members).
set_db group 'files [SUCCESS=merge] sss systemd'
run grep '^group:' /etc/nsswitch.conf
run getent group "$G"
run id "$U1"
run id dave

printf '\n### 5. The sss fast memory cache answers even when SSSD is down\n'
run getent passwd dave
run systemctl stop sssd
sleep 1
run getent passwd dave
run ls /var/lib/sss/mc
find /var/lib/sss/mc -type f -delete
run getent passwd dave || printf 'exit status: %s\n' "$?"
