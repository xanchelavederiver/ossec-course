#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='ulimit: защита от исчерпания ресурсов (nofile, nproc, fsize, as, cpu)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { rm -f /tmp/file_* /tmp/dd 2>/dev/null; remove_users; }
new_users "$U1"
need python3 dd

# Каждый лимит задаётся в дочерней оболочке, чтобы не затронуть остальные демо.

# -n: исчерпание файловых дескрипторов.
as "$U1" "ulimit -n 128; \
          python3 -c \"[open(f'/tmp/file_{i}', 'w') for i in range(128+10)]\""
rm -f /tmp/file_*

# -u: форк-бомба. Запускаем в отдельной сессии, лимит защищает систему.
as "$U1" 'ulimit -u 200; :(){ :|:& };: ; true'

# -f: предел размера файла 10 МБ.
as "$U1" 'ulimit -f 10240; dd if=/dev/urandom bs=11M count=1 of=/tmp/dd'
rm -f /tmp/dd

# -v: предел виртуальной памяти 100 МБ.
as "$U1" "ulimit -v 102400; python3 -c 'import os; os.urandom(100 * 1024 * 1024)'"
as "$U1" 'ulimit -v 102400; dd if=/dev/urandom bs=92M count=1 of=/dev/null'

# -t: предел процессорного времени 5 с.
as "$U1" "ulimit -t 5; python3 -c 'while True: pass'; echo \$?"
