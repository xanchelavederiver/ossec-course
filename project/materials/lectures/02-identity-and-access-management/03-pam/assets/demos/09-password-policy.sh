#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_pwquality + pam_pwhistory: password quality rules and reuse ban'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need apt-get grep sed passwd
cleanup() {
  restore_files
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd

printf '\n--- 1. installing libpam-pwquality adds its line (pam-auth-update) ---\n'
run grep -Ev '^#|^$' /etc/pam.d/common-password
apt-get install -y libpam-pwquality >/dev/null
backup_file /etc/pam.d/common-password
run grep -Ev '^#|^$' /etc/pam.d/common-password

printf '\n--- 2. policy as module arguments ---\n'
sed -i 's/pam_pwquality\.so.*/pam_pwquality.so retry=7 minlen=10 dcredit=-2 ucredit=-2 lcredit=-2 ocredit=-2 dictcheck=0/' \
  /etc/pam.d/common-password
run grep pwquality /etc/pam.d/common-password

printf '\n--- 3. pam_pwhistory: remember the last 3 passwords ---\n'
sed -i '/pam_pwquality/a password\trequisite\t\t\tpam_pwhistory.so remember=3 use_authtok' \
  /etc/pam.d/common-password
run grep pwhistory /etc/pam.d/common-password

printf '\nNow run as the test user (su - %s):\n' "$DEMO_USER"
printf '  passwd    # try 1234567890, AB34567890, ABcd567890, ABcd%%^yuio, AAbb##44, ABcd%%^7890\n'
printf '  passwd    # change again, then try to reuse the previous password\n'
printf 'History is stored in /etc/security/opasswd.\n'
pause_demo
