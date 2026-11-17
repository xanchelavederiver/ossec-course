#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='libpam-google-authenticator: TOTP as a second factor for sshd'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need apt-get sshd sed grep runuser
cleanup() {
  restore_files
  if command -v systemctl >/dev/null && systemctl is-active -q ssh; then
    systemctl reload ssh || true
  fi
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
apt-get install -y libpam-google-authenticator >/dev/null
backup_file /etc/pam.d/sshd /etc/ssh/sshd_config

printf '\n--- 1. enrol the user (run interactively to see the QR code) ---\n'
printf '  su - %s -c "google-authenticator -t -d -r 3 -R 30 -W"\n' "$DEMO_USER"
printf 'Flags: -t TOTP, -d disallow code reuse, -r/-R rate limit, -W window of 3 codes.\n'
printf 'The secret and settings land in ~/.google_authenticator (mode 400).\n'

printf '\n--- 2. wire the module into sshd ---\n'
sed -i '/^@include common-auth/a auth\trequired\tpam_google_authenticator.so' /etc/pam.d/sshd
run grep google /etc/pam.d/sshd
# sshd converses with PAM modules only over keyboard-interactive.
sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
run grep '^KbdInteractiveAuthentication' /etc/ssh/sshd_config
if command -v systemctl >/dev/null && systemctl is-active -q ssh; then systemctl reload ssh; fi

printf '\n--- 3. after enrolment try: ssh %s@<vm>  # Password: then Verification code: ---\n' "$DEMO_USER"
pause_demo
