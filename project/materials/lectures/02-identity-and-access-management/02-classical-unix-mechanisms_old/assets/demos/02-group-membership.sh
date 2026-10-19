#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Primary and supplementary groups, id and /etc/group'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel usermod
cleanup() { remove_user; }
getent group sudo >/dev/null || die 'Install sudo first'
new_user
run usermod -aG sudo "$DEMO_USER"
run groups "$DEMO_USER"
run id "$DEMO_USER"
run grep -E '^(ossec-demo|sudo):' /etc/group
printf 'The primary GID comes from passwd; it need not be listed in gr_mem.\n'
