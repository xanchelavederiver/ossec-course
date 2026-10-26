#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Password hashing: verification by recomputation, salt, fixed salt determinism'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need mkpasswd sha256sum useradd userdel chpasswd
DEMO_PASS='Lab-Demo-42!'

U1=ossec-demo1 U2=ossec-demo2
for u in "$U1" "$U2"; do
  ! getent passwd "$u" >/dev/null || die "$u already exists"
done
cleanup() {
  local u rc=0
  for u in "$U1" "$U2"; do
    if getent passwd "$u" >/dev/null; then
      userdel "$u" || { printf 'Remove %s manually\n' "$u" >&2; rc=1; }
    fi
  done
  return "$rc"
}
run useradd -M -U -s /usr/sbin/nologin "$U1"
run useradd -M -U -s /usr/sbin/nologin "$U2"
printf '%s:%s\n%s:%s\n' "$U1" "$DEMO_PASS" "$U2" "$DEMO_PASS" | chpasswd

printf '\n### 1. Verification: recomputing with the stored salt reproduces the hash\n'
run grep "^$U1:" /etc/shadow
hash=$(getent shadow "$U1" | cut -d: -f2)
salt=${hash%\$*}                      # $y$j9T$<salt> — all but the last $-field
run mkpasswd -m yescrypt -S "$salt" "$DEMO_PASS"
[[ $(mkpasswd -m yescrypt -S "$salt" "$DEMO_PASS") == "$hash" ]]
printf 'MATCH: correct password reproduces the stored string\n'
run mkpasswd -m yescrypt -S "$salt" "${DEMO_PASS%!}?"
printf 'DIFFERS: wrong password does not\n'

printf '\n### 2. No salt: a plain hash betrays equal passwords\n'
for attempt in 1 2; do
  printf '$ printf %%s %s | sha256sum   # run %s\n' "$DEMO_PASS" "$attempt"
  printf '%s' "$DEMO_PASS" | sha256sum
done

printf '\n### 3. Random salt: same password, different verifiers\n'
run grep -E "^($U1|$U2):" /etc/shadow
a=$(mkpasswd -m yescrypt "$DEMO_PASS"); printf '%s\n' "$a"
b=$(mkpasswd -m yescrypt "$DEMO_PASS"); printf '%s\n' "$b"
[[ $a != "$b" ]]
printf 'DIFFERENT: a fresh random salt each time\n'

printf '\n### 4. Fixed salt: deterministic result\n'
a=$(mkpasswd -m yescrypt -S "$salt" "$DEMO_PASS")
b=$(mkpasswd -m yescrypt -S "$salt" "$DEMO_PASS")
printf '%s\n%s\n' "$a" "$b"
[[ $a == "$b" ]]
printf 'IDENTICAL: same algorithm, parameters, salt and password\n'
