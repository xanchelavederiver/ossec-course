#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Changing the defaults (useradd -D, login.defs) and observing the difference on a new account'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel groupdel getent stat grep sed cp

U1=ossec-demo1 U2=ossec-demo2
for u in "$U1" "$U2"; do
  ! getent passwd "$u" >/dev/null || die "$u already exists"
done
LOGINDEFS=/etc/login.defs
DEFUSERADD=/etc/default/useradd
BK="$DEMO_TMP/login.defs.bak"; BD="$DEMO_TMP/useradd.bak"
cp -a "$LOGINDEFS" "$BK"; cp -a "$DEFUSERADD" "$BD"
cleanup() {
  local u rc=0
  for u in "$U1" "$U2"; do
    if getent passwd "$u" >/dev/null; then
      userdel -r "$u" 2>/dev/null || userdel "$u" || { printf 'Remove %s manually\n' "$u" >&2; rc=1; }
    fi
    getent group "$u" >/dev/null && { groupdel "$u" 2>/dev/null || true; }
  done
  cp -a "$BK" "$LOGINDEFS"; cp -a "$BD" "$DEFUSERADD"
  return "$rc"
}

printf '\n### 1. Baseline user with the stock defaults\n'
run useradd -m "$U1"
run getent passwd "$U1"
run stat -c '%A  %n' /home/"$U1"

printf '\n### 2. Change the system-wide defaults\n'
run useradd -D -s /bin/bash -f 30
sed -i 's|^HOME_MODE.*|HOME_MODE\t0700|' "$LOGINDEFS"
run grep -E '^HOME_MODE' "$LOGINDEFS"
run grep -E '^(SHELL|INACTIVE)' "$DEFUSERADD"

printf '\n### 3. New user – same command, different result\n'
run useradd -m "$U2"
run getent passwd "$U2"
run stat -c '%A  %n' /home/"$U2"
run getent shadow "$U1"
run getent shadow "$U2"
