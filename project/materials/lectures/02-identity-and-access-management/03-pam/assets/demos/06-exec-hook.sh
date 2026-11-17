#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_exec: log every opened ssh session from a hook script'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd logger grep
HOOK=/usr/local/sbin/login-hook
cleanup() {
  restore_files
  rm -f "$HOOK"
  remove_user
}
[[ ! -e $HOOK ]] || die "$HOOK already exists"
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/pam.d/sshd

cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
# вызывается pam_exec: сведения о транзакции – в переменных PAM_*
[ "$PAM_TYPE" = open_session ] || exit 0
logger -p auth.notice -t login-hook \
  "session opened: user=$PAM_USER service=$PAM_SERVICE rhost=${PAM_RHOST:-local} tty=$PAM_TTY"
HOOK_EOF
chmod 755 "$HOOK"
run cat "$HOOK"
# optional: a failing hook must not close the login path (compare with required).
printf 'session    optional     pam_exec.so %s\n' "$HOOK" >> /etc/pam.d/sshd
run tail -1 /etc/pam.d/sshd

printf '\nTry: ssh %s@<vm> id\n' "$DEMO_USER"
printf "     grep -o 'login-hook.*' /var/log/auth.log | tail -1\n"
printf 'Experiment: replace the script body with "exit 1" and the flag with\n'
printf 'required - every ssh login is closed after "... failed: exit code 1".\n'
pause_demo
