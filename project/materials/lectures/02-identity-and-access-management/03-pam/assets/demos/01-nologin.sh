#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_nologin: deny all logins except root via /etc/nologin'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd grep
cleanup() {
  rm -f /etc/nologin
  remove_user
}
[[ ! -e /etc/nologin ]] || die '/etc/nologin already exists'
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd

# pam_nologin is already wired into the stock Ubuntu configs: show where.
run grep -H pam_nologin /etc/pam.d/login /etc/pam.d/sshd

printf '\n# echo '\''You shall not pass!'\'' > /etc/nologin\n'
echo 'You shall not pass!' > /etc/nologin
run cat /etc/nologin

printf '\nTry now from another terminal (password Winter#2026x):\n'
printf '  ssh %s@<vm> id   # message printed, connection closed\n' "$DEMO_USER"
printf '  ssh root@<vm> id         # message printed, login still works\n'
pause_demo
