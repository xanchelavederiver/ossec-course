#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='cgroup2: квотирование CPU по иерархии A -> {P,Q,R} (модель лимитов)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { pkill -9 -x stress-ng-cpu 2>/dev/null; pkill -9 -x stress-ng 2>/dev/null; sleep 1; cg_cleanup; }
need stress-ng pidstat pgrep

[[ $(stat -fc %T /sys/fs/cgroup) == cgroup2fs ]] || die 'Требуется cgroup2'
grep -qw cpu /sys/fs/cgroup/cgroup.controllers || die 'Контроллер cpu недоступен'

# Поддерево A -> {P,Q,R} с включённым контроллером cpu на каждом уровне.
mkdir "$CG"
echo "+cpu" > "$CG/cgroup.subtree_control"
mkdir "$CG/A"
echo "+cpu" > "$CG/A/cgroup.subtree_control"
mkdir "$CG/A/P" "$CG/A/Q" "$CG/A/R"

# Квоты (модель лимитов): A=50%, P=10%, Q=15%, R=25% одного процессора.
run cat "$CG/A/cpu.max"
echo "50000 100000" > "$CG/A/cpu.max"
echo "10000 100000" > "$CG/A/P/cpu.max"
echo "15000 100000" > "$CG/A/Q/cpu.max"
echo "25000 100000" > "$CG/A/R/cpu.max"
run cat "$CG/A/P/cpu.max" "$CG/A/Q/cpu.max" "$CG/A/R/cpu.max"

measure() { # $1 target group spec: "P Q R" (one each) | "R R R" (all in R)
  ( cd /tmp && stress-ng --temp-path /tmp --cpu 3 --timeout 20s >/dev/null 2>&1 & )
  sleep 4
  mapfile -t PIDS < <(pgrep -x stress-ng-cpu)
  local i=0
  for g in $1; do echo "${PIDS[$i]}" > "$CG/A/$g/cgroup.procs"; i=$((i+1)); done
  sleep 3
  pidstat -u 5 1 -C stress-ng | grep -E 'stress-ng-cpu|%CPU'
  pkill -9 -x stress-ng-cpu 2>/dev/null; pkill -9 -x stress-ng 2>/dev/null; sleep 2
}

printf '\n# по одному процессу в P, Q, R\n'
measure "P Q R"
printf '\n# три процесса в одной группе R\n'
measure "R R R"
