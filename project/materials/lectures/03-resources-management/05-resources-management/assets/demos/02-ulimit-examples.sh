#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='ulimit: защита от исчерпания ресурсов (nofile, nproc, fsize, as, cpu)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
# Процессы форк-бомбы занимают освободившиеся места новыми потомками, и pkill
# их не догоняет. Поэтому бомба запускается в отдельной группе управления
# (раздел 3 лекции), а завершает её атомарная запись в cgroup.kill.
bomb_kill() {
  [[ -d $CG ]] || return 0
  echo 1 > "$CG/cgroup.kill" 2>/dev/null || true
  local i; for i in $(seq 1 50); do rmdir "$CG" 2>/dev/null && return 0; sleep 0.1; done
}
cleanup() { bomb_kill; rm -f /tmp/file_* /tmp/dd 2>/dev/null; remove_users; }
new_users "$U1"
need python3 dd

# Каждый лимит задаётся в дочерней оболочке, чтобы не затронуть остальные демо.

# -n: исчерпание файловых дескрипторов.
as "$U1" "ulimit -n 128; \
          python3 -c \"[open(f'/tmp/file_{i}', 'w') for i in range(128+10)]\""
rm -f /tmp/file_*

# -u: форк-бомба. Лимит защищает систему, но процессы бомбы продолжают
# безуспешно ветвиться (fork: retry), пока их не завершат: показываем первые
# строки и принудительно завершаем все процессы демо-пользователя.
[[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Требуется cgroup2'
mkdir "$CG"
( echo "$BASHPID" > "$CG/cgroup.procs"
  as "$U1" 'ulimit -u 200; :(){ :|:& };: ; sleep 6' 2>&1 ) | head -n 8 || true
bomb_kill

# -f: предел размера файла 10 МБ.
as "$U1" 'ulimit -f 10240; dd if=/dev/urandom bs=11M count=1 of=/tmp/dd'
rm -f /tmp/dd

# -v: предел виртуальной памяти 100 МБ.
as "$U1" "ulimit -v 102400; python3 -c 'import os; os.urandom(100 * 1024 * 1024)'"
as "$U1" 'ulimit -v 102400; dd if=/dev/urandom bs=92M count=1 of=/dev/null'

# -t: предел процессорного времени 5 с.
as "$U1" "ulimit -t 5; python3 -c 'while True: pass'; echo \$?"
