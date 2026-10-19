#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Compare stored aging fields and derived dates after passwd'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need chage passwd chpasswd useradd userdel date
[[ -t 0 ]] || die 'An interactive terminal is required for passwd'
cleanup() { remove_user; }
new_user
printf 'ossec-demo:Demo-Initial-42!\n' | chpasswd
run chage -m 0 -M 90 -W 7 -I 14 -E "$(date -u -d '+365 days' +%F)" "$DEMO_USER"
run chage -d "$(date -u -d '10 days ago' +%F)" "$DEMO_USER"
show() {
  printf '\n$ awk -F: ... /etc/shadow  # hash redacted\n'
  awk -F: '$1=="ossec-demo" {$2="<redacted>"; print}' OFS=: /etc/shadow
  run chage -l "$DEMO_USER"
}
show
awk -F: '$1=="ossec-demo" {print $2}' /etc/shadow >"$DEMO_TMP/before-hash"
printf 'Set a different temporary password:\n'
run passwd "$DEMO_USER"
show
awk -F: '$1=="ossec-demo" {print $2}' /etc/shadow >"$DEMO_TMP/after-hash"
if cmp -s "$DEMO_TMP/before-hash" "$DEMO_TMP/after-hash"; then die 'Hash did not change'; fi
printf 'Hash and last-change day changed. Aging intervals and absolute account expiry did not.\n'
