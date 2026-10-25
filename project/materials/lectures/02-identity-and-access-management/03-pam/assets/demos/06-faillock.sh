#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_faillock: lock an account after 5 failed logins'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need faillock grep sed
cleanup() {
  restore_files
  faillock --user "$DEMO_USER" --reset 2>/dev/null
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/security/faillock.conf /etc/pam.d/common-auth

sed -i 's/^#\? \?deny = .*/deny = 5/; s/^#\? \?unlock_time = .*/unlock_time = 900/' /etc/security/faillock.conf
run grep -E '^(deny|unlock_time)' /etc/security/faillock.conf

# preauth before pam_unix, authfail after it; the pam_unix success jump grows
# from 1 to 2 so that a good password skips BOTH authfail and pam_deny.
cat > /etc/pam.d/common-auth <<'EOF'
auth	required			pam_faillock.so preauth
auth	[success=2 default=ignore]	pam_unix.so nullok
auth	[default=die]			pam_faillock.so authfail
auth	requisite			pam_deny.so
auth	required			pam_permit.so
auth	optional			pam_faillock.so authsucc
EOF
run grep -Ev '^#|^$' /etc/pam.d/common-auth

printf '\nFrom another non-root account:\n'
printf '  su - %s -c id      # 5 times with a wrong password\n' "$DEMO_USER"
printf '  su - %s -c id      # with the RIGHT password: account is locked\n' "$DEMO_USER"
printf 'Then back here as root:\n'
printf '  faillock --user %s          # show the counter\n' "$DEMO_USER"
printf '  faillock --user %s --reset  # unlock\n' "$DEMO_USER"
pause_demo
