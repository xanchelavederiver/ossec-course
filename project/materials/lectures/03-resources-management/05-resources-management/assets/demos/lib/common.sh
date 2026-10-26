#!/usr/bin/env bash
# Shared by the numbered resource-management demos (lecture 5). Run only in a
# disposable Ubuntu 26.04 VM or a privileged ubuntu:26.04 container with
# cgroup2 delegated: several demos edit /etc/security/limits.conf, start sshd
# and create groups under /sys/fs/cgroup.
set -Eeuo pipefail
export LC_ALL=C
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run() { printf '\n#'; printf ' %q' "$@"; printf '\n'; "$@"; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null || die "Missing command: $c (see README.md)"; done; }
demo_init() {
  if [[ ${1:-} == --help ]]; then
    printf '%s\n' "$(basename "$0"): ${DEMO_DESCRIPTION:-OSSec resource-management demo}" \
      'Usage: sudo env OSSEC_DEMO_VM=1 bash NN-name.sh' \
      'Only on a disposable Ubuntu 26.04 VM/container. See README.md.'
    exit 0
  fi
  [[ $# == 0 ]] || die 'Unsupported argument; use --help'
  [[ $EUID == 0 ]] || die 'Run as root in the lab VM'
  [[ ${OSSEC_DEMO_VM:-} == 1 ]] || die 'Set OSSEC_DEMO_VM=1 only in a disposable VM'
  # shellcheck source=/dev/null
  source /etc/os-release
  [[ $ID == ubuntu && $VERSION_ID == 26.04 ]] || die 'Expected Ubuntu 26.04'
  need flock mktemp
  exec 9>/run/lock/ossec-res-demo.lock
  flock -n 9 || die 'Another OSSec demo is running on this VM'
  umask 022
  DEMO_TMP=$(mktemp -d /tmp/ossec-res.XXXXXXXX)
  trap demo_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
}
demo_cleanup() {
  local status=$?
  trap - EXIT INT TERM
  set +e
  if declare -F cleanup >/dev/null; then
    cleanup
    local cleanup_status=$?
    if [[ $cleanup_status != 0 ]]; then
      printf 'Cleanup failed; diagnostic files retained at %s. Revert VM snapshot.\n' "$DEMO_TMP" >&2
      exit 1
    fi
  fi
  if [[ -n ${DEMO_TMP:-} && $DEMO_TMP == /tmp/ossec-res.* && -d $DEMO_TMP ]]; then
    rm -r -- "$DEMO_TMP"
  fi
  exit "$status"
}
backup_file() {
  local f
  for f in "$@"; do
    [[ -e $f ]] || die "backup_file: $f does not exist"
    mkdir -p "$DEMO_TMP/backup/$(dirname "$f")"
    cp -a -- "$f" "$DEMO_TMP/backup/$f"
  done
}
restore_files() {
  local status=0 f src
  [[ -d $DEMO_TMP/backup ]] || return 0
  while IFS= read -r -d '' src; do
    f=${src#"$DEMO_TMP/backup"}
    cp -a -- "$src" "$f" || { printf 'Failed to restore %s\n' "$f" >&2; status=1; }
  done < <(find "$DEMO_TMP/backup" -type f -print0)
  return "$status"
}
# Demo subjects. The lecture transcripts use bob (owner) and x; the scripts
# create disposable stand-ins so a student VM stays clean.
U1=ossec-bob U2=ossec-x
new_users() {
  local u
  for u in "$@"; do
    ! getent passwd "$u" >/dev/null || die "$u already exists"
    run useradd -m -U -s /bin/bash "$u"
  done
  DEMO_USERS=("$@")
}
remove_users() {
  local u status=0
  for u in "${DEMO_USERS[@]:-}"; do
    [[ -n $u ]] || continue
    userdel -r "$u" 2>/dev/null || userdel "$u" || {
      printf 'Cleanup failed: remove %s manually before reusing VM\n' "$u" >&2
      status=1
    }
  done
  return "$status"
}
# Print and execute a command as a demo user ($ prompt). A fresh login shell
# re-reads limits, so resource-limit demos pass the whole scenario to one
# `bash -lc` (see individual scripts).
as() {
  local u=$1; shift
  printf '\n$ %s\n' "$*"
  # Expected-failure steps (EPERM, EMFILE, SIGXFSZ) are part of the demos,
  # so a non-zero status does not abort the script.
  runuser -u "$u" -- bash -c "cd ~ 2>/dev/null; $*" || true
}
# Root step whose failure is the demonstrated effect.
tryrun() { printf '\n#'; printf ' %q' "$@"; printf '\n'; "$@" || true; }
# A control-group path used by the cgroup demos; removed on cleanup.
CG=/sys/fs/cgroup/ossec-demo
cg_cleanup() {
  [[ -d $CG ]] || return 0
  # Move any stuck processes to the root, then remove leaves depth-first.
  find "$CG" -depth -type d 2>/dev/null | while read -r d; do rmdir "$d" 2>/dev/null; done
  [[ -d $CG ]] && printf 'Note: %s not empty; remove manually.\n' "$CG" >&2
  return 0
}
