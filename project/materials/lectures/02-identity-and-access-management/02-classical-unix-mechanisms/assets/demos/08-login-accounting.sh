#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='A real login session and binary accounting logs'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need login script who w last lastb lastlog passwd useradd userdel
[[ -t 0 ]] || die 'Interactive terminal required'
cleanup() { remove_user; }
new_user
run passwd "$DEMO_USER"
printf '\nAt login enter ossec-demo and its password. Then run: id; who; w; exit\n'
printf 'A failed attempt may be made first to demonstrate btmp.\n'
run script -q -c /bin/login /dev/null
run last -n 5 "$DEMO_USER"
run lastlog -u "$DEMO_USER"
if [[ -f /var/log/btmp ]]; then run lastb -n 5 "$DEMO_USER"; fi
printf 'Accounting entries are retained as evidence; they are NOT erased by cleanup.\n'
