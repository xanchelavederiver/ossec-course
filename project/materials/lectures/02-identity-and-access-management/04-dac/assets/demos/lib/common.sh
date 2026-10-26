#!/usr/bin/env bash
# Shared by the numbered DAC demos (lecture 4). Run only in a disposable
# Ubuntu 26.04 VM: several demos touch live paths (/etc/pam.d, /var/log, /tmp).
set -Eeuo pipefail
export LC_ALL=C
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run() { printf '\n#'; printf ' %q' "$@"; printf '\n'; "$@"; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null || die "Missing command: $c (see README.md)"; done; }
demo_init() {
  if [[ ${1:-} == --help ]]; then
    printf '%s\n' "$(basename "$0"): ${DEMO_DESCRIPTION:-OSSec DAC demo}" \
      'Usage: sudo env OSSEC_DEMO_VM=1 bash NN-name.sh' \
      'Only on a disposable Ubuntu 26.04 VM. See README.md for prerequisites and cleanup.'
    exit 0
  fi
  [[ $# == 0 ]] || die 'Unsupported argument; use --help'
  [[ $EUID == 0 ]] || die 'Run as root in the lab VM'
  [[ ${OSSEC_DEMO_VM:-} == 1 ]] || die 'Set OSSEC_DEMO_VM=1 only in a disposable VM'
  # shellcheck source=/dev/null
  source /etc/os-release
  [[ $ID == ubuntu && $VERSION_ID == 26.04 ]] || die 'Expected Ubuntu 26.04'
  need flock mktemp
  exec 9>/run/lock/ossec-dac-demo.lock
  flock -n 9 || die 'Another OSSec demo is running on this VM'
  umask 022
  DEMO_TMP=$(mktemp -d /tmp/ossec-dac.XXXXXXXX)
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
  if [[ -n ${DEMO_TMP:-} && $DEMO_TMP == /tmp/ossec-dac.* && -d $DEMO_TMP ]]; then
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
# Demo subjects. The lecture transcripts use bob (owner), alice, carol, dave;
# the scripts create disposable stand-ins so a student VM stays clean.
U1=ossec-bob U2=ossec-alice U3=ossec-carol U4=ossec-dave
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
# Print and execute a command as a demo user ($ prompt), in that user's home
# unless an explicit `cd` is part of the command string.
as() {
  local u=$1; shift
  printf '\n$ %s\n' "$*"
  # Expected-failure steps (Permission denied, EPERM) are part of the demos,
  # so a non-zero status does not abort the script.
  runuser -u "$u" -- bash -c "cd ~ 2>/dev/null; $*" || true
}
# Same, but for root steps whose failure is the demonstrated effect.
tryrun() { printf '\n#'; printf ' %q' "$@"; printf '\n'; "$@" || true; }
