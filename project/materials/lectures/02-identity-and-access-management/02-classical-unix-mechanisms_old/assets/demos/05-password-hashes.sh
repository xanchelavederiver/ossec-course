#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
if [[ ${1:-} == --help ]]; then printf 'bash 05-password-hashes.sh: OpenSSL hashes; no root or account changes\n'; exit 0; fi
[[ $# == 0 ]] || die 'Unsupported argument'
need openssl
for algorithm in -1 -5 -6; do
  for attempt in 1 2; do
    printf '\n$ printf "%%s\\n" "Demo-Only-42!" | openssl passwd %s -stdin # run %s\n' "$algorithm" "$attempt"
    printf '%s\n' 'Demo-Only-42!' | openssl passwd "$algorithm" -stdin
  done
done
printf '\n$ openssl passwd -6 -salt CourseSalt -stdin # same demo password twice\n'
a=$(printf '%s\n' 'Demo-Only-42!' | openssl passwd -6 -salt CourseSalt -stdin)
b=$(printf '%s\n' 'Demo-Only-42!' | openssl passwd -6 -salt CourseSalt -stdin)
printf '%s\n%s\n' "$a" "$b"
[[ $a == "$b" ]]
printf 'IDENTICAL: same algorithm, parameters, salt and password\n'
