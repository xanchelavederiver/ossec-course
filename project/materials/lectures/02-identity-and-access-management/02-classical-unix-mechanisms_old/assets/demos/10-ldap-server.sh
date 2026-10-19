#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Temporary standalone OpenLDAP on TCP 1389 with STARTTLS; keep running during client demo'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need slapd slappasswd ldapadd ldapwhoami openssl python3
[[ -t 0 ]] || die 'Interactive terminal required'
: "${LDAP_SERVER_IP:?Set the server private IPv4 address}"
python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "$LDAP_SERVER_IP"
cleanup() {
  if [[ -n ${SLAPD_PID:-} ]]; then kill "$SLAPD_PID" 2>/dev/null; wait "$SLAPD_PID" 2>/dev/null; fi
  if [[ ${LDAP_CONFIG:-} == /etc/ldap/ossec-demo.* ]]; then rm -r -- "$LDAP_CONFIG"; fi
  if [[ ${LDAP_DATA:-} == /var/lib/ldap/ossec-demo.* ]]; then rm -r -- "$LDAP_DATA"; fi
  if [[ ${LDAP_PID_FILE:-} == /run/slapd/ossec-demo-*.pid ]]; then
    rm -f -- "$LDAP_PID_FILE" "$LDAP_PID_FILE.args"
  fi
}
# Paths permitted by Ubuntu's stock slapd AppArmor profile.
LDAP_CONFIG=$(mktemp -d /etc/ldap/ossec-demo.XXXXXXXX)
LDAP_DATA=$(mktemp -d /var/lib/ldap/ossec-demo.XXXXXXXX)
install -d -m 755 /run/slapd
LDAP_PID_FILE="/run/slapd/ossec-demo-$$.pid"
read -r -s -p 'Temporary LDAP administrator password: ' ADMIN_PASSWORD </dev/tty; printf '\n'
[[ ${#ADMIN_PASSWORD} -ge 12 ]] || die 'Use at least 12 characters'
printf '%s' "$ADMIN_PASSWORD" >"$DEMO_TMP/admin-secret"
unset ADMIN_PASSWORD
ADMIN_HASH=$(slappasswd -T "$DEMO_TMP/admin-secret")
read -r -s -p 'Password for LDAP user ldapstudent: ' USER_PASSWORD </dev/tty; printf '\n'
[[ ${#USER_PASSWORD} -ge 12 ]] || die 'Use at least 12 characters'
printf '%s' "$USER_PASSWORD" >"$DEMO_TMP/user-secret"
unset USER_PASSWORD
USER_HASH=$(slappasswd -T "$DEMO_TMP/user-secret")
run openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
  -subj '/CN=OSSec disposable LDAP' -addext "subjectAltName=IP:$LDAP_SERVER_IP" \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -keyout "$LDAP_CONFIG/tls.key" -out "$LDAP_CONFIG/ldap-ca.crt"
cat >"$LDAP_CONFIG/slapd.conf" <<EOF
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/nis.schema
include /etc/ldap/schema/inetorgperson.schema
pidfile $LDAP_PID_FILE
argsfile $LDAP_PID_FILE.args
modulepath /usr/lib/ldap
moduleload back_mdb
TLSCertificateFile $LDAP_CONFIG/ldap-ca.crt
TLSCertificateKeyFile $LDAP_CONFIG/tls.key
TLSCACertificateFile $LDAP_CONFIG/ldap-ca.crt
security simple_bind=128
database mdb
maxsize 1073741824
suffix "dc=ossec,dc=test"
rootdn "cn=admin,dc=ossec,dc=test"
rootpw $ADMIN_HASH
directory $LDAP_DATA
index objectClass eq
access to attrs=userPassword by self write by anonymous auth by * none
access to * by * read
EOF
printf '\n$ slapd -f <temporary config> -h ldap://%s:1389 -d 0\n' "$LDAP_SERVER_IP"
slapd -f "$LDAP_CONFIG/slapd.conf" -h "ldap://$LDAP_SERVER_IP:1389" -d 0 >"$DEMO_TMP/slapd.log" 2>&1 &
SLAPD_PID=$!
export LDAPTLS_CACERT="$LDAP_CONFIG/ldap-ca.crt"
ready=0
for _ in {1..30}; do
  if ldapwhoami -x -ZZ -H "ldap://$LDAP_SERVER_IP:1389" >/dev/null 2>&1; then ready=1; break; fi
  kill -0 "$SLAPD_PID" 2>/dev/null || { cat "$DEMO_TMP/slapd.log"; die 'slapd exited'; }
  sleep .2
done
[[ $ready == 1 ]] || die 'LDAP failed to become ready'
cat >"$DEMO_TMP/entries.ldif" <<EOF
dn: dc=ossec,dc=test
objectClass: top
objectClass: dcObject
objectClass: organization
o: OSSec laboratory
dc: ossec

dn: ou=People,dc=ossec,dc=test
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=ossec,dc=test
objectClass: organizationalUnit
ou: Groups

dn: cn=ldapstudents,ou=Groups,dc=ossec,dc=test
objectClass: posixGroup
cn: ldapstudents
gidNumber: 20000
memberUid: ldapstudent

dn: uid=ldapstudent,ou=People,dc=ossec,dc=test
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: LDAP Student
sn: Student
uid: ldapstudent
uidNumber: 20000
gidNumber: 20000
homeDirectory: /home/ldapstudent
loginShell: /bin/bash
userPassword: $USER_HASH
EOF
run ldapadd -x -ZZ -H "ldap://$LDAP_SERVER_IP:1389" \
  -D cn=admin,dc=ossec,dc=test -y "$DEMO_TMP/admin-secret" -f "$DEMO_TMP/entries.ldif"
run openssl x509 -in "$LDAP_CONFIG/ldap-ca.crt" -noout -fingerprint -sha256
printf '\nPublic certificate (copy ONLY this certificate to the client, verify fingerprint):\n'
cat "$LDAP_CONFIG/ldap-ca.crt"
printf '\nServer ready: ldap://%s:1389; user: ldapstudent\n' "$LDAP_SERVER_IP"
pause_demo 'Keep this terminal open. After client demo/cleanup press Enter to stop LDAP and delete its temporary DB. '
