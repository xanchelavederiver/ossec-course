#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='NSS host lookup scenarios: files vs dns, status codes, unavailable source'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need getent runuser strace grep chmod stat useradd userdel

# A host entry that exists only locally and a public name that exists only in DNS.
LOCAL_NAME=intranet.example.test
LOCAL_ADDR=192.0.2.80          # TEST-NET-1, documentation address (RFC 5737)
DNS_NAME=example.org
MISSING_NAME=nosuch.example.test
U1=ossec-demo1

! getent passwd "$U1" >/dev/null || die "$U1 already exists"
HOSTS_MODE=$(stat -c '%a' /etc/hosts)
cleanup() {
  local rc=0
  chmod "$HOSTS_MODE" /etc/hosts || rc=1
  # rewrite in place: /etc/hosts may be a bind mount (containers), sed -i would fail
  sed "\#^$LOCAL_ADDR[[:space:]]\+$LOCAL_NAME\$#d" /etc/hosts > "$DEMO_TMP/hosts" \
    && cat "$DEMO_TMP/hosts" > /etc/hosts || rc=1
  if getent passwd "$U1" >/dev/null; then
    userdel -r "$U1" 2>/dev/null || userdel "$U1" || { printf 'Remove %s manually\n' "$U1" >&2; rc=1; }
  fi
  return "$rc"
}

useradd -m "$U1"   # unprivileged observer for the "source unavailable" scenario

printf '\n### 0. NSS policy for the hosts database; NSS modules on disk\n'
run grep '^hosts:' /etc/nsswitch.conf
run ls /usr/lib/x86_64-linux-gnu/ --format=single-column
printf '\n(see libnss_*.so.2; files and dns are also built into libc since glibc 2.34)\n'

printf '\n### 1. The name is in /etc/hosts: files answers, dns is never asked\n'
printf '%s\t%s\n' "$LOCAL_ADDR" "$LOCAL_NAME" >> /etc/hosts
run getent hosts "$LOCAL_NAME"

printf '\n### 2. The name is only in DNS: files reports NOTFOUND, lookup continues\n'
run getent -s files hosts "$DNS_NAME" || printf 'exit status: %s\n' "$?"
run getent hosts "$DNS_NAME"

printf '\n### 3. The name exists nowhere: both sources report NOTFOUND\n'
run getent hosts "$MISSING_NAME" || printf 'exit status: %s\n' "$?"

printf '\n### 4. The files source is unavailable (UNAVAIL): lookup still continues\n'
# For an unprivileged process an unreadable /etc/hosts is an unavailable source,
# not an authoritative "no such record".
run chmod 000 /etc/hosts
run runuser -u "$U1" -- getent hosts "$LOCAL_NAME" || printf 'exit status: %s\n' "$?"
run runuser -u "$U1" -- getent hosts "$DNS_NAME"
runuser -u "$U1" -- strace -f -e trace=openat getent hosts "$LOCAL_NAME" 2>&1 \
  | grep -E '/etc/(hosts|resolv\.conf)' || true
run chmod "$HOSTS_MODE" /etc/hosts
run getent hosts "$LOCAL_NAME"
