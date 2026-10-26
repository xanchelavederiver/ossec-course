#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='ulimit: display limits, soft vs hard'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { remove_users; }
new_users "$U1"

# All действующие пределы процесса.
as "$U1" 'ulimit -a'

# Мягкий (-S) и жёсткий (-H) лимиты числа открытых файлов.
as "$U1" 'ulimit -Sn; ulimit -Hn; \
          ulimit -Sn 512; ulimit -Sn; \
          ulimit -Sn 1048576; \
          ulimit -Hn 4096; ulimit -Hn; \
          ulimit -Hn 1048576'
