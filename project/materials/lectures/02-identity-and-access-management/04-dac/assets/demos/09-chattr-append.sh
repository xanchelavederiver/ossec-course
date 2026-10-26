#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='chattr +a on /var/log/auth.log: append-only even for root'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need chattr lsattr
[[ -f /var/log/auth.log ]] || die 'No /var/log/auth.log (is rsyslog installed and running?)'
cleanup() {
  chattr -a /var/log/auth.log 2>/dev/null
  sed -i '/^hehehe$/d' /var/log/auth.log 2>/dev/null
  pkill -HUP rsyslogd 2>/dev/null   # журнал пересоздавался sed — переоткрыть
  rm -f /tmp/auth.log
}

echo; echo '===== Журнал ====='
run ls -l /var/log/auth.log
run lsattr /var/log/auth.log
run tail -n 1 /var/log/auth.log

echo; echo '===== chattr +a ====='
run chattr +a /var/log/auth.log
run lsattr /var/log/auth.log
printf '\nВойдите по ssh из другого терминала и убедитесь, что записи появляются:\n'
printf '  ssh <user>@<vm> id ; tail -n 3 /var/log/auth.log\n'

echo; echo '===== Попытки изменить журнал ====='
run cp /var/log/auth.log /tmp/auth.log
tryrun rm /var/log/auth.log
tryrun mv /var/log/auth.log /var/log/auth-moved.log
tryrun bash -c 'echo "" > /var/log/auth.log'
run bash -c 'echo "hehehe" >> /var/log/auth.log'
run tail -n 2 /var/log/auth.log
# атрибут и след hehehe убираются в cleanup()
