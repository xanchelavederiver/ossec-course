#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_limits: hard fsize limit and maxlogins session limit'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd grep runuser dd
cleanup() {
  restore_files
  rm -f /tmp/small /tmp/big
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/security/limits.conf

printf '%s    hard    fsize    1024\n' "$DEMO_USER" >> /etc/security/limits.conf
run tail -1 /etc/security/limits.conf
run grep pam_limits /etc/pam.d/sshd

printf '\nIn an ssh session as %s (limits are applied by the session stack):\n' "$DEMO_USER"
printf '  ulimit -f                                  # 1024 (KB)\n'
printf '  dd if=/dev/zero of=/tmp/small bs=1k count=512   # OK\n'
printf '  dd if=/dev/zero of=/tmp/big bs=1M count=2       # SIGXFSZ: File size limit exceeded\n'
pause_demo 'Press Enter to switch to the maxlogins variant.'

restore_files
backup_file /etc/security/limits.conf
printf '\n--- 2. maxlogins: limit on concurrent sessions ---\n'
# Ubuntu 26.04 counts logind sessions, and the "systemd --user" manager is one
# of them: maxlogins 2 = one ssh session; maxlogins 1 is rejected by the module.
printf '%s    hard    maxlogins    2\n' "$DEMO_USER" >> /etc/security/limits.conf
run tail -1 /etc/security/limits.conf

printf '\nOpen one ssh session as %s and keep it, then from another terminal:\n' "$DEMO_USER"
printf '  loginctl list-sessions             # classes "user" and "manager"\n'
printf "  ssh %s@<vm>                # There were too many logins for '%s'.\n" "$DEMO_USER" "$DEMO_USER"
printf "  grep -o 'pam_limits.*' /var/log/auth.log | tail -1\n"
pause_demo
