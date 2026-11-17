#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Password authentication against /etc/shadow via getpwnam/getspnam/getpass/crypt (builds 11-password-auth.c; interactive)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gcc getent useradd userdel chpasswd runuser install

U1=ossec-demo1
! getent passwd "$U1" >/dev/null || die "$U1 already exists"
! getent group "$U1" >/dev/null || die "group $U1 already exists"
BIN=/usr/local/bin/pwcheck
[[ ! -e $BIN ]] || die "$BIN already exists"
cleanup() {
  local rc=0
  if [[ ${NSS_SAVED:-0} == 1 ]]; then
    install -m 644 "$DEMO_TMP/nsswitch.conf.orig" /etc/nsswitch.conf || rc=1
  fi
  rm -f "$BIN" || rc=1
  if getent passwd "$U1" >/dev/null; then
    userdel "$U1" || { printf 'Remove %s manually\n' "$U1" >&2; rc=1; }
  fi
  return "$rc"
}

SRC="$(dirname "${BASH_SOURCE[0]}")/11-password-auth.c"

printf '\n### 1. Build (crypt lives in libcrypt)\n'
run gcc -Wall -O2 -o "$DEMO_TMP/pwcheck" "$SRC" -lcrypt
install -m 755 "$DEMO_TMP/pwcheck" "$BIN"

printf '\n### 2. Demo account (password: Lab-Demo-42!)\n'
run useradd -M "$U1"
printf '%s:Lab-Demo-42!\n' "$U1" | chpasswd

printf '\n### 3. Root session: type the correct, then a wrong password\n'
run "$BIN" "$U1" || true
run "$BIN" "$U1" || true

printf '\n### 4. Unprivileged session: shadow is unreadable\n'
run ls -l /etc/shadow
run grep '^shadow:' /etc/nsswitch.conf
# Ubuntu Server: "shadow: files systemd" - the EACCES of files is masked by the
# next source, getspnam() returns NULL with errno 0 and pwcheck asks for a password.
run runuser -u "$U1" -- "$BIN" "$U1" || true
# With files alone the classic TLPI behaviour is visible: errno = EACCES.
install -m 644 /etc/nsswitch.conf "$DEMO_TMP/nsswitch.conf.orig"
NSS_SAVED=1
sed -i -E 's/^(shadow):.*/\1:         files/' /etc/nsswitch.conf
run grep '^shadow:' /etc/nsswitch.conf
run runuser -u "$U1" -- "$BIN" "$U1" || true
