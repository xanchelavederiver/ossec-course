#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_access and pam_listfile: deny login to a specific user'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd grep sed
cleanup() {
  restore_files
  rm -f /etc/denyusers
  remove_user
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
pause_demo 'Press Enter to switch to the pam_listfile variant.'

restore_files
backup_file /etc/pam.d/sshd
printf '\n--- 2. pam_listfile: deny by list file ---\n'
echo "$DEMO_USER" > /etc/denyusers
run cat /etc/denyusers
sed -i '1i auth     requisite    pam_listfile.so onerr=fail item=user sense=deny file=/etc/denyusers' /etc/pam.d/sshd
run head -1 /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id  # Permission denied already at the auth stage\n' "$DEMO_USER"
pause_demo
