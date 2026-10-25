#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_limits: hard fsize limit kills a process that writes a too-large file'
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
pause_demo
