#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='chattr +i: even root cannot modify, rename or delete the file'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need chattr lsattr
cleanup() {
  chattr -i /etc/pam.d/common-* 2>/dev/null
  restore_files
  rm -f /tmp/common-password
}
backup_file /etc/pam.d/common-*
cd /etc/pam.d

echo; echo '===== Исходное состояние ====='
run lsattr .  | grep common || true
run ls -l common-password
run bash -c 'echo "# edited by root" >> common-password'
run tail -n 1 common-password

echo; echo '===== chattr +i ====='
run chattr +i common-*
run lsattr . | grep common || true
run cp common-password /tmp/common-password
tryrun bash -c 'echo "# edited again" >> common-password'
tryrun rm common-password
tryrun mv common-password common-password.moved

echo; echo '===== Сброс атрибута ====='
run chattr -i common-*
run bash -c 'echo "# edited again" >> common-password'
run tail -n 1 common-password
# файлы будут восстановлены из резервной копии в cleanup()
