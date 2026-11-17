#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_wheel: only members of a group may use su'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need su grep sed
cleanup() {
  restore_files
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/pam.d/su

# Ubuntu ships the rule commented out. Without group= the module looks for the
# group "wheel" (absent in Ubuntu) and then falls back to GID 0.
run grep -n 'pam_rootok\|pam_wheel' /etc/pam.d/su
grep -q '^# auth       required   pam_wheel.so$' /etc/pam.d/su || die 'unexpected /etc/pam.d/su: sample pam_wheel line not found'
sed -i 's/^# auth       required   pam_wheel.so$/auth       required   pam_wheel.so group=sudo/' /etc/pam.d/su
run grep '^auth' /etc/pam.d/su

printf '\nsu needs the root password: set one on the VM first (passwd root).\n'
printf 'In a session of %s (not in group sudo):\n' "$DEMO_USER"
printf '  su -c id            # correct root password, still: su: Permission denied\n'
printf 'In a session of a member of group sudo:\n'
printf '  su -c id            # uid=0(root)\n'
printf 'As root (pam_rootok is sufficient and stands first):\n'
printf '  su %s -c id\n' "$DEMO_USER"
printf '  grep FAILED /var/log/auth.log | tail -1\n'
pause_demo
