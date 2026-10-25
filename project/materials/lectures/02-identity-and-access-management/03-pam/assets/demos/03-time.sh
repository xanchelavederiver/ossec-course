#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_time: deny ssh login to a user at any time of day'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd grep sed
cleanup() {
  restore_files
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/security/time.conf /etc/pam.d/sshd

# services;ttys;users;times — "!Al0000-2400" means "never".
printf 'sshd;*;%s;!Al0000-2400\n' "$DEMO_USER" >> /etc/security/time.conf
run tail -1 /etc/security/time.conf
sed -i '/^@include common-account/i account  requisite    pam_time.so' /etc/pam.d/sshd
run grep pam_time /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id   # password accepted, account stage closes the session\n' "$DEMO_USER"
printf 'Any other user logs in as usual.\n'
pause_demo
