#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Classic password policy: aging fields, login.defs defaults, locking, empty hash, group password'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need chage passwd chpasswd useradd userdel groupadd groupdel su newgrp runuser
DEMO_PASS='Lab-Demo-42!'

U1=ossec-demo1 U2=ossec-demo2 G=ossec-proj G2=ossec-aud
GPASS='Audit-Demo-7!'
for u in "$U1" "$U2"; do
  ! getent passwd "$u" >/dev/null || die "$u already exists"
done
for g in "$G" "$G2"; do
  ! getent group "$g" >/dev/null || die "$g already exists"
done
cleanup() {
  local u g rc=0
  for u in "$U1" "$U2"; do
    if getent passwd "$u" >/dev/null; then
      userdel -r "$u" 2>/dev/null || userdel "$u" || { printf 'Remove %s manually\n' "$u" >&2; rc=1; }
    fi
  done
  for g in "$G" "$G2"; do
    if getent group "$g" >/dev/null; then
      groupdel "$g" || { printf 'Remove group %s manually\n' "$g" >&2; rc=1; }
    fi
  done
  return "$rc"
}
run groupadd "$G"
run groupadd "$G2"
printf '%s:%s\n' "$G2" "$GPASS" | chgpasswd   # group password: G2 stays member-less
run useradd -m -U -s /bin/bash -G "$G" "$U1"
run useradd -m -U -s /bin/bash "$U2"
printf '%s:%s\n%s:%s\n' "$U1" "$DEMO_PASS" "$U2" "$DEMO_PASS" | chpasswd

printf '\n### 1. Aging fields: defaults, then chage\n'
run grep "^$U1:" /etc/shadow
run chage -l "$U1"
run chage -m 1 -M 90 -W 7 -I 14 -E 2027-12-31 "$U1"
run grep "^$U1:" /etc/shadow
run chage -l "$U1"

printf '\n### 2. System-wide defaults for new accounts\n'
run grep -E '^(PASS_(MAX|MIN)_DAYS|PASS_WARN_AGE|ENCRYPT_METHOD)' /etc/login.defs

printf '\n### 3. Locking a password: "!" prefix in /etc/shadow\n'
run passwd -l "$U1"
run grep "^$U1:" /etc/shadow
run passwd -S "$U1"
printf '$ su - %s -c id   # %s enters the CORRECT password\n' "$U1" "$U2"
printf '%s\n' "$DEMO_PASS" | runuser -u "$U2" -- su - "$U1" -c id || true
run passwd -u "$U1"
run passwd -S "$U1"

printf '\n### 4. Empty hash field: login without a password (pam_unix nullok)\n'
run passwd -d "$U2"
run grep "^$U2:" /etc/shadow
printf '$ su - %s -c id   # run as %s: no password prompt\n' "$U2" "$U1"
runuser -u "$U1" -- su - "$U2" -c id
printf '%s:%s\n' "$U2" "$DEMO_PASS" | chpasswd   # restore

printf '\n### 5. Group password: "!" vs a hash in /etc/gshadow\n'
run grep -E "^($G|$G2):" /etc/gshadow
printf '$ newgrp %s; id -gn   # member %s: no password required\n' "$G" "$U1"
runuser -u "$U1" -- newgrp "$G" <<< 'id -gn'
printf '$ newgrp %s; id -gn   # non-member %s: knows the group password (%s — type it at the prompt)\n' "$G2" "$U2" "$GPASS"
runuser -u "$U2" -- newgrp "$G2" <<< 'id -gn' || true   # newgrp prompts on the terminal
printf '$ newgrp %s   # non-member %s: wrong password is rejected\n' "$G2" "$U1"
printf 'x\n' | runuser -u "$U1" -- newgrp "$G2" || true
