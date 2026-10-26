#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='cgroup2: создание группы, добавление процесса, лимит pids, удаление'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { cg_cleanup; }

[[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Требуется cgroup2'
# Корень делегирует контроллеры потомкам (иначе файлов контроллеров не будет).
grep -qw pids /sys/fs/cgroup/cgroup.controllers || die 'Контроллер pids недоступен'

# Создание группы и её интерфейсные файлы.
run mkdir "$CG"
run ls "$CG"
run cat "$CG/cgroup.controllers"
run cat "$CG/cgroup.stat"

# Добавление текущей оболочки; потомок (cat) наследует группу.
echo $$ > "$CG/cgroup.procs"
run cat "$CG/cgroup.procs"
run cat "$CG/pids.current"
run cat "/proc/$$/cgroup"

# Лимит числа процессов в группе: четыре запускаются, пятый — отказ.
echo 5 > "$CG/pids.max"
run cat "$CG/pids.max"
printf '\n$ for a in $(seq 1 5); do sleep 10 & done\n'
for a in $(seq 1 5); do sleep 10 & done || true
wait 2>/dev/null || true

# Удаление: непустую группу удалить нельзя; выводим оболочку и удаляем.
tryrun rmdir "$CG"
echo $$ > /sys/fs/cgroup/cgroup.procs 2>/dev/null || \
  echo $$ > /sys/fs/cgroup/init.scope/cgroup.procs 2>/dev/null || true
run rmdir "$CG"
