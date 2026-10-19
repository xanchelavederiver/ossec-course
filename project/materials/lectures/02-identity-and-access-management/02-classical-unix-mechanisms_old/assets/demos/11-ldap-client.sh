#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='SSSD/NSS/PAM client, real login, then restore original configuration'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sssd sssctl systemctl pam-auth-update ldapwhoami login script python3
[[ -t 0 ]] || die 'Interactive terminal required'
: "${LDAP_SERVER_IP:?Set server private IPv4 address}"
: "${LDAP_CA_FILE:?Path to certificate copied from server}"
python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "$LDAP_SERVER_IP"
[[ -f $LDAP_CA_FILE ]] || die 'Missing certificate'
[[ ! -e /etc/sssd/sssd.conf ]] || die 'Requires a fresh client with no sssd.conf'
if systemctl is-active --quiet sssd; then die 'SSSD must not be running before demo'; fi
for key in ldapstudent 20000; do
  if getent passwd "$key" >/dev/null; then die "Account collision: $key"; fi
done
if getent group 20000 >/dev/null; then die 'GID 20000 already used'; fi
[[ ! -e /home/ldapstudent ]] || die 'Home directory already exists'
CA_TARGET=/etc/sssd/ossec-demo-ca.crt
[[ ! -e $CA_TARGET ]] || die 'Demo certificate already exists'
mkdir "$DEMO_TMP/pam"
cp -a /etc/nsswitch.conf "$DEMO_TMP/nsswitch.conf"
cp -a /etc/pam.d/common-* "$DEMO_TMP/pam/"
cleanup() {
  if [[ ${CONFIG_CREATED:-0} == 1 ]]; then
    systemctl stop sssd
    cp -a "$DEMO_TMP/nsswitch.conf" /etc/nsswitch.conf
    cp -a "$DEMO_TMP/pam/"* /etc/pam.d/
    rm -f /etc/sssd/sssd.conf "$CA_TARGET"
    # Keep logs; clear only this temporary domain's identity cache.
    rm -f /var/lib/sss/db/cache_ossec.ldb /var/lib/sss/db/timestamps_ossec.ldb
    if [[ -d /home/ldapstudent ]]; then
      printf 'Generated home /home/ldapstudent retained; revert VM snapshot for full reset.\n'
    fi
  fi
}
CONFIG_CREATED=1
install -m 644 "$LDAP_CA_FILE" "$CA_TARGET"
cat >/etc/sssd/sssd.conf <<EOF
[sssd]
config_file_version = 2
services = nss, pam
domains = ossec

[domain/ossec]
id_provider = ldap
auth_provider = ldap
access_provider = permit
ldap_uri = ldap://$LDAP_SERVER_IP:1389
ldap_search_base = dc=ossec,dc=test
ldap_schema = rfc2307
ldap_id_use_start_tls = true
ldap_tls_reqcert = demand
ldap_tls_cacert = $CA_TARGET
cache_credentials = false
enumerate = false
EOF
chmod 600 /etc/sssd/sssd.conf
run sssctl config-check
# pam-auth-update also records enabled profiles; VM snapshot resets package state.
run pam-auth-update --enable sss --enable mkhomedir
python3 - <<'PY'
from pathlib import Path
p = Path('/etc/nsswitch.conf')
lines = p.read_text().splitlines()
for i, line in enumerate(lines):
    if line.partition(':')[0].strip() in ('passwd', 'group'):
        # Fixed instructional ordering: local accounts remain available first.
        lines[i] = line.partition(':')[0] + ': files systemd sss'
    elif line.partition(':')[0].strip() == 'shadow':
        lines[i] = 'shadow: files'
p.write_text('\n'.join(lines) + '\n')
PY
run systemctl start sssd
run grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf
run getent passwd ldapstudent
run id ldapstudent
if grep -q '^ldapstudent:' /etc/passwd; then die 'Unexpected local account'; fi
printf 'No LDAP hash is copied into /etc/shadow. PAM calls pam_sss for authentication.\n'
run env LDAPTLS_CACERT="$CA_TARGET" ldapwhoami -x -ZZ \
  -H "ldap://$LDAP_SERVER_IP:1389" -D uid=ldapstudent,ou=People,dc=ossec,dc=test -W
printf 'At login enter ldapstudent and its LDAP password; run id; pwd; exit\n'
run script -q -c /bin/login /dev/null
pause_demo 'Press Enter to stop SSSD and restore NSS/PAM files. '
