#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='cgroup2: управление контроллерами, ограничение сверху вниз, cgroup.events'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { cg_cleanup; }

[[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Требуется cgroup2'
run mkdir "$CG"

# Доступные (controllers) и включённые для потомков (subtree_control).
run cat "$CG/cgroup.controllers"
run cat "$CG/cgroup.subtree_control"
echo "+cpu +memory -io" > "$CG/cgroup.subtree_control"
run cat "$CG/cgroup.subtree_control"

# Ограничение сверху вниз: потомку доступны лишь переданные контроллеры.
run mkdir "$CG/child"
run cat "$CG/child/cgroup.controllers"
tryrun bash -c "echo +pids > '$CG/child/cgroup.subtree_control'"

# Уведомление о населённости поддерева.
run cat "$CG/cgroup.events"
sleep 200 & SP=$!
echo "$SP" > "$CG/child/cgroup.procs"
run cat "$CG/cgroup.events"
kill "$SP" 2>/dev/null || true
sleep 1
run cat "$CG/child/cgroup.events"

rmdir "$CG/child"
