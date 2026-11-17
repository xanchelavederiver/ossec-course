#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='safe editing: backup, pamtester per stack, key and password paths, a typo that locks everyone out'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd pamtester ssh-keygen grep sed
RULE='pam_listfile.so onerr=fail item=user sense=deny file=/etc/denyusers'
cleanup() {
  restore_files
  rm -f /etc/denyusers
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
backup_file /etc/pam.d/sshd
# A key pair for the demo user: the login path that skips the auth stack.
install -d -m 700 -o "$DEMO_USER" -g "$DEMO_USER" "/home/$DEMO_USER/.ssh"
ssh-keygen -q -t ed25519 -N '' -f "$DEMO_TMP/key"
install -m 600 -o "$DEMO_USER" -g "$DEMO_USER" "$DEMO_TMP/key.pub" "/home/$DEMO_USER/.ssh/authorized_keys"
echo "$DEMO_USER" > /etc/denyusers
key_login() {
  printf '\n$ ssh -i <key> %s@127.0.0.1 id\n' "$DEMO_USER"
  ssh -i "$DEMO_TMP/key" -o StrictHostKeyChecking=accept-new "$DEMO_USER@127.0.0.1" id || true
}

printf '\n--- 1. deny rule in the auth stack ---\n'
sed -i "1i auth     requisite    $RULE" /etc/pam.d/sshd
run head -1 /etc/pam.d/sshd
run pamtester sshd "$DEMO_USER" authenticate || true
run pamtester sshd "$DEMO_USER" acct_mgmt || true
key_login   # succeeds: sshd does not run the auth stack for a key login
pause_demo 'Press Enter to move the rule to the account stack.'

restore_files
printf '\n--- 2. the same rule in the account stack ---\n'
sed -i "/^@include common-account/i account  required     $RULE" /etc/pam.d/sshd
run grep pam_listfile /etc/pam.d/sshd
run pamtester sshd "$DEMO_USER" acct_mgmt || true
key_login   # connection closed
pause_demo 'Press Enter to plant a typo in the module name (KEEP THIS ROOT SESSION OPEN).'

restore_files
printf '\n--- 3. a typo closes sshd for everyone, root included ---\n'
sed -i "/^@include common-account/i account  required     ${RULE/listfile/listflie}" /etc/pam.d/sshd
run grep listfl /etc/pam.d/sshd
run pamtester sshd root acct_mgmt || true
printf '\nTry from another terminal: ssh <anyone>@<vm> id   # Connection closed\n'
printf "     grep -o 'PAM adding.*' /var/log/auth.log | tail -1\n"
printf 'Only this still-open root session can undo the edit.\n'
pause_demo 'Press Enter to restore /etc/pam.d/sshd and exit.'
