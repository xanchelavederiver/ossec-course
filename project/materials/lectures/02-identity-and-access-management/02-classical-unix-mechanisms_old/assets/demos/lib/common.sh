#!/usr/bin/env bash
# Shared by the numbered demos. Run only in a disposable Ubuntu 26.04 VM.
set -Eeuo pipefail
export LC_ALL=C
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run() { printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@"; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null || die "Missing command: $c (see README.md)"; done; }
demo_init() {
  if [[ ${1:-} == --help ]]; then
    printf '%s\n' "$(basename "$0"): ${DEMO_DESCRIPTION:-OSSec demo}" \
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
  exec 9>/run/lock/ossec-iam-demo.lock
  flock -n 9 || die 'Another OSSec demo is running on this VM'
  umask 077
  DEMO_TMP=$(mktemp -d /tmp/ossec-iam.XXXXXXXX)
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
  if [[ -n ${DEMO_TMP:-} && $DEMO_TMP == /tmp/ossec-iam.* && -d $DEMO_TMP ]]; then
    rm -r -- "$DEMO_TMP"
  fi
  exit "$status"
}
new_user() {
  DEMO_USER=ossec-demo
  ! getent passwd "$DEMO_USER" >/dev/null || die 'ossec-demo already exists'
  ! getent group "$DEMO_USER" >/dev/null || die 'ossec-demo group already exists'
  run useradd -M -U -s /bin/bash "$DEMO_USER"
  DEMO_CREATED=1
}
remove_user() {
  if [[ ${DEMO_CREATED:-0} == 1 ]]; then
    userdel "$DEMO_USER" || {
      printf 'Cleanup failed: remove %s manually before reusing VM\n' "$DEMO_USER" >&2
      return 1
    }
  fi
}
pause_demo() { read -r -p "${1:-Press Enter to clean up and exit.}" _ </dev/tty; }
