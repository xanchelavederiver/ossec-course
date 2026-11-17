#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Four UIDs/GIDs of a process: /proc/PID/status, ps, a setuid binary'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel runuser script pgrep ps sleep
cleanup() {
  [[ -z ${SLEEP_PID:-} ]] || kill "$SLEEP_PID" 2>/dev/null || true
  [[ -z ${RUNUSER_PID:-} ]] || kill "$RUNUSER_PID" 2>/dev/null || true
  [[ -z ${PASSWD_PID:-} ]] || kill "$PASSWD_PID" 2>/dev/null || true
  [[ -z ${SCRIPT_PID:-} ]] || kill "$SCRIPT_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  remove_user
}
new_user

# Root shell: all four UID columns are 0 (real, effective, saved, filesystem).
run grep -E '^(Name|Uid|Gid)' "/proc/$$/status"

# Background process of the demo user: all four columns equal its UID.
printf '\n$ runuser -u %s -- sleep 300 &\n' "$DEMO_USER"
runuser -u "$DEMO_USER" -- sleep 300 &
RUNUSER_PID=$!
SLEEP_PID=
for _ in $(seq 1 50); do
  SLEEP_PID=$(pgrep -x -u "$DEMO_USER" sleep | head -n 1) && [[ -n $SLEEP_PID ]] && break
  sleep 0.1
done
[[ -n $SLEEP_PID ]] || die 'sleep did not start'
run grep -E '^(Name|Uid|Gid)' "/proc/$SLEEP_PID/status"
run ps -o pid,ruid,euid,suid,fsuid,rgid,egid,sgid,fsgid,comm -p "$SLEEP_PID"
kill "$SLEEP_PID" 2>/dev/null || true
wait "$RUNUSER_PID" 2>/dev/null || true
SLEEP_PID=

# A setuid-root binary started by the demo user: ruid stays, euid/suid/fsuid become 0.
run ls -l /usr/bin/passwd
printf '\n$ passwd  # started by %s under a pty; waits for input\n' "$DEMO_USER"
script -qc "runuser -u $DEMO_USER -- passwd" /dev/null </dev/null >/dev/null 2>&1 &
SCRIPT_PID=$!
PASSWD_PID=
for _ in $(seq 1 50); do
  PASSWD_PID=$(pgrep -x passwd | head -n 1) && [[ -n $PASSWD_PID ]] && break
  sleep 0.1
done
[[ -n $PASSWD_PID ]] || die 'passwd did not start'
run grep -E '^(Name|Uid|Gid)' "/proc/$PASSWD_PID/status"
run ps -o pid,ruid,euid,suid,fsuid,comm -p "$PASSWD_PID"
STATUS_UID=$(awk '$1 == "Uid:" { print $2, $3, $4, $5 }' "/proc/$PASSWD_PID/status")
[[ $STATUS_UID == "$(id -u "$DEMO_USER") 0 0 0" ]] || die "Unexpected passwd credentials: $STATUS_UID"
kill "$PASSWD_PID" 2>/dev/null || true
PASSWD_PID=
printf 'passwd keeps ruid=%s to know who is calling, but works with euid=0.\n' "$(id -u "$DEMO_USER")"
