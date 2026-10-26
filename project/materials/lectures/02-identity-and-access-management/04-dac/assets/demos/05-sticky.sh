#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='sticky bit: in /tmp only the file owner may delete'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() {
  rm -f /tmp/ossec-sticky-file2.txt
  rm -r -f /tmp/ossec-sticky-exp
  remove_users
}
new_users "$U1" "$U2"

echo; echo '===== /tmp со sticky-битом ====='
run ls -ld /tmp

echo; echo '===== Каталог без sticky: чужой файл удаляется ====='
as "$U1" 'mkdir -p /tmp/ossec-sticky-exp && echo Hello > /tmp/ossec-sticky-exp/file.txt'
run chown "$U2" /tmp/ossec-sticky-exp/file.txt
as "$U1" 'ls -la /tmp/ossec-sticky-exp && rm /tmp/ossec-sticky-exp/file.txt && ls -l /tmp/ossec-sticky-exp'

echo; echo '===== /tmp (sticky): чужой файл удалить нельзя ====='
as "$U1" 'echo Hello > /tmp/ossec-sticky-file2.txt'
run chown "$U2" /tmp/ossec-sticky-file2.txt
as "$U1" 'ls -l /tmp/ossec-sticky-file2.txt && rm /tmp/ossec-sticky-file2.txt'
