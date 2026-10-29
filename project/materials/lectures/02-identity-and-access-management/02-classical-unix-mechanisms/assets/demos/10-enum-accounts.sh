#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Enumerate all users and groups via libc getpwent/getgrent (builds 10-enum-accounts.c)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gcc

SRC="$(dirname "${BASH_SOURCE[0]}")/10-enum-accounts.c"
BIN="$DEMO_TMP/enum-accounts"

printf '\n### 1. Build\n'
run gcc -Wall -O2 -o "$BIN" "$SRC"

printf '\n### 2. Enumerate users and groups\n'
run "$BIN"
