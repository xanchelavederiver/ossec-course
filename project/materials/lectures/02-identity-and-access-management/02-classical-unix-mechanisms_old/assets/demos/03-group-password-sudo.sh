#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Group password via newgrp sudo, not the sudo authentication password'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gpasswd newgrp runuser useradd userdel chpasswd
[[ -t 0 ]] || die 'An interactive terminal is required'
getent group sudo >/dev/null || die 'Install sudo first'
cleanup() {
  # Restore the original gshadow before userdel changes membership lists.
  [[ ! -f $DEMO_TMP/gshadow ]] || cp -a -- "$DEMO_TMP/gshadow" /etc/gshadow
  remove_user
}
new_user
cp -a /etc/gshadow "$DEMO_TMP/gshadow"
printf 'ossec-demo:Demo-Login-42!\n' | chpasswd
printf 'Set a temporary GROUP password below. Remember it for newgrp.\n'
run gpasswd sudo
run id "$DEMO_USER"
printf '\nInside the shell run: newgrp sudo\nEnter the GROUP password, then: id -g; id -gn; exit; exit\n'
printf 'Expected group name: sudo. Do not run privileged commands in this shell.\n'
run runuser -u "$DEMO_USER" -- /bin/bash --noprofile --norc
