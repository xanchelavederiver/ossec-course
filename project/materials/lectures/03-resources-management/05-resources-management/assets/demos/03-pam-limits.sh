#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_limits: постоянный жёсткий лимит fsize, применяемый при входе по ssh'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd ssh expect python3
cleanup() {
  [[ -n ${SSHD_PID:-} ]] && kill "$SSHD_PID" 2>/dev/null
  rm -f /tmp/random_file /tmp/random_file2 2>/dev/null
  restore_files
  remove_users
}
new_users "$U2"
echo "${U2}:res12345" | chpasswd

# pam_limits.so уже подключён в session-стеке sshd (Ubuntu 26.04).
grep -q pam_limits.so /etc/pam.d/sshd || die 'pam_limits.so отсутствует в /etc/pam.d/sshd'

# Постоянный жёсткий лимит размера файла: 1024 КБ (= 1 МБ).
backup_file /etc/security/limits.conf
printf '%s\thard\tfsize\t1024\n' "$U2" >> /etc/security/limits.conf
run tail -n1 /etc/security/limits.conf

# Отдельный sshd на нестандартном порту, вход по паролю.
mkdir -p /run/sshd
/usr/sbin/sshd -p 2222 \
  -o PasswordAuthentication=yes -o UsePAM=yes -o PidFile=/run/sshd/ossec.pid &
SSHD_PID=$!
sleep 1

# Вход и проверка: файл 32 КБ создаётся, файл 2 МБ — нет.
expect <<EOF
set timeout 25
spawn ssh -p 2222 -o StrictHostKeyChecking=no ${U2}@127.0.0.1
expect "password:" { send "res12345\r" }
expect "\\\$ "
send "ulimit -Hf\r";                                                   expect "\\\$ "
send "cd /tmp\r";                                                      expect "\\\$ "
send "dd if=/dev/urandom bs=1024 count=32 of=/tmp/random_file\r";      expect "\\\$ "
send "echo \\\$?\r";                                                   expect "\\\$ "
send "python3 -c \"import os; open('/tmp/random_file2','wb+').write(os.urandom(2**10 * 2**11))\"\r"
expect "\\\$ "
send "ls -l /tmp/random_file*\r";                                      expect "\\\$ "
send "exit\r"
expect eof
EOF
