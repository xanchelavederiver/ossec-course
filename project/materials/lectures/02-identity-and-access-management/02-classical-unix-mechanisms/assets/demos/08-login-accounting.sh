#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='A real login session and login accounting (wtmpdb/lastlog2 on 26.04)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need login script who w passwd useradd userdel
# Ubuntu 26.04 no longer ships last/lastb/lastlog/utmpdump: accounting moved
# to the wtmpdb and lastlog2 SQLite databases (install wtmpdb lastlog2
# libpam-wtmpdb libpam-lastlog2). Classic tools are used when still present.
if ! command -v wtmpdb >/dev/null && ! command -v last >/dev/null; then
  die 'Install wtmpdb and lastlog2 (with their PAM modules) first; see README.md'
fi
[[ -t 0 ]] || die 'Interactive terminal required'
cleanup() { remove_user; }
new_user
run passwd "$DEMO_USER"
printf '\nAt login enter ossec-demo and its password. Then run: id; who; w; exit\n'
printf 'A failed attempt may be made first; on 26.04 it lands in journald, not btmp.\n'
run script -q -c /bin/login /dev/null
if command -v wtmpdb >/dev/null; then
  run wtmpdb last -n 5
else
  run last -n 5 "$DEMO_USER"
fi
if command -v lastlog2 >/dev/null; then
  run lastlog2 -u "$DEMO_USER"
elif command -v lastlog >/dev/null; then
  run lastlog -u "$DEMO_USER"
fi
if command -v lastb >/dev/null && [[ -f /var/log/btmp ]]; then
  run lastb -n 5 "$DEMO_USER"
else
  run journalctl -n 5 -t login --no-pager || true
fi
printf 'Accounting entries are retained as evidence; they are NOT erased by cleanup.\n'
