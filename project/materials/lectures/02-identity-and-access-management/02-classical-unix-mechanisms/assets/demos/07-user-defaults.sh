#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Account creation with default values: login.defs, /etc/default/useradd, /etc/skel'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd groupadd userdel groupdel getent stat grep

U1=ossec-demo1 G=ossec-proj
! getent passwd "$U1" >/dev/null || die "$U1 already exists"
! getent group "$U1" >/dev/null || die "group $U1 already exists"
! getent group "$G" >/dev/null || die "$G already exists"
cleanup() {
  local rc=0
  if getent passwd "$U1" >/dev/null; then
    userdel -r "$U1" 2>/dev/null || userdel "$U1" || { printf 'Remove %s manually\n' "$U1" >&2; rc=1; }
  fi
  getent group "$U1" >/dev/null && { groupdel "$U1" 2>/dev/null || true; }
  if getent group "$G" >/dev/null; then
    groupdel "$G" || { printf 'Remove group %s manually\n' "$G" >&2; rc=1; }
  fi
  return "$rc"
}

printf '\n### 1. Defaults that govern useradd\n'
run useradd -D
run grep -E '^(UID_MIN|UID_MAX|GID_MIN|GID_MAX|HOME_MODE|USERGROUPS_ENAB)' /etc/login.defs

printf '\n### 2. One user with pure defaults\n'
run useradd -m "$U1"
run getent passwd "$U1"
run getent group "$U1"
run stat -c '%A  %U:%G  %n' /home/"$U1"
run ls -A /home/"$U1"
run getent shadow "$U1"

printf '\n### 3. A standalone group\n'
run groupadd "$G"
run getent group "$G"
