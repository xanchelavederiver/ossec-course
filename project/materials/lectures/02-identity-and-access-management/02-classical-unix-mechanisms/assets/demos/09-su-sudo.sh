#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='su, sudo and a command-scoped NOPASSWD rule'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sudo visudo runuser useradd userdel passwd
[[ -t 0 ]] || die 'Interactive terminal required'
RULE=/etc/sudoers.d/ossec-demo
[[ ! -e $RULE ]] || die "$RULE already exists"
cleanup() {
  [[ ${RULE_CREATED:-0} != 1 ]] || rm -- "$RULE"
  remove_user
}
new_user
run passwd "$DEMO_USER"
printf 'ossec-demo ALL=(root) /usr/bin/id\n' >"$DEMO_TMP/rule"
run visudo -cf "$DEMO_TMP/rule"
RULE_CREATED=1
install -m 440 "$DEMO_TMP/rule" "$RULE"
run visudo -c
run su -s /bin/bash "$DEMO_USER" -c id
run sudo -l -U "$DEMO_USER"
printf 'sudo asks for the password of ossec-demo:\n'
run runuser -u "$DEMO_USER" -- sudo -k /usr/bin/id
printf 'ossec-demo ALL=(root) NOPASSWD: /usr/bin/id\n' >"$DEMO_TMP/rule"
run visudo -cf "$DEMO_TMP/rule"
install -m 440 "$DEMO_TMP/rule" "$RULE"
run visudo -c
run runuser -u "$DEMO_USER" -- sudo -k -n /usr/bin/id
printf 'Only /usr/bin/id is permitted. No unrestricted root shell is granted.\n'
