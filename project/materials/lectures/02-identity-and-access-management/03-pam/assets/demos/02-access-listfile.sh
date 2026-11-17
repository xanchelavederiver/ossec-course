#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_access (deny rule, allow-list) and pam_listfile: who may log in over ssh'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd grep sed
cleanup() {
  restore_files
  rm -f /etc/denyusers
  remove_user
  if [[ ${GROUP_CREATED:-0} == 1 ]]; then groupdel ossec-admins; fi
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/security/access.conf /etc/pam.d/sshd

printf '\n--- 1. pam_access: rule in /etc/security/access.conf ---\n'
printf -- '-:%s:ALL\n' "$DEMO_USER" >> /etc/security/access.conf
run tail -1 /etc/security/access.conf
sed -i '/^@include common-account/i account  required     pam_access.so' /etc/pam.d/sshd
run grep pam_access /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id  # password accepted, then connection closed\n' "$DEMO_USER"
pause_demo 'Press Enter to switch to the allow-list variant.'

restore_files
backup_file /etc/security/access.conf /etc/pam.d/sshd
printf '\n--- 2. pam_access: allow-list (first matching rule wins) ---\n'
! getent group ossec-admins >/dev/null || die 'group ossec-admins already exists'
run groupadd ossec-admins
GROUP_CREATED=1
{
  printf '+:(ossec-admins):ALL\n'
  # Keep the account that started the demo able to open new ssh sessions.
  [[ -z ${SUDO_USER:-} ]] || printf '+:%s:ALL\n' "$SUDO_USER"
  printf '+:root:LOCAL\n-:ALL:ALL\n'
} >> /etc/security/access.conf
run tail -4 /etc/security/access.conf
sed -i '/^@include common-account/i account  required     pam_access.so' /etc/pam.d/sshd
run grep '^account.*pam_access' /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id   # not in ossec-admins: connection closed\n' "$DEMO_USER"
printf '     ssh root@<vm> id         # root is allowed only from LOCAL (console)\n'
printf 'Then: gpasswd -a %s ossec-admins; ssh %s@<vm> id   # allowed\n' "$DEMO_USER" "$DEMO_USER"
printf "     grep -o 'pam_access.*' /var/log/auth.log | tail -2\n"
pause_demo 'Press Enter to switch to the pam_listfile variant.'

restore_files
backup_file /etc/pam.d/sshd
printf '\n--- 3. pam_listfile: deny by list file ---\n'
echo "$DEMO_USER" > /etc/denyusers
run cat /etc/denyusers
sed -i '1i auth     requisite    pam_listfile.so onerr=fail item=user sense=deny file=/etc/denyusers' /etc/pam.d/sshd
run head -1 /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id  # Permission denied already at the auth stage\n' "$DEMO_USER"
printf 'Note: a public-key login skips the auth stack and is NOT stopped by this rule (demo 08).\n'
pause_demo
