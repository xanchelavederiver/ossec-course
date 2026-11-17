#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_mkhomedir: create the home directory at first login (pam-auth-update profile)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need sshd pam-auth-update getent
export DEBIAN_FRONTEND=noninteractive
cleanup() {
  if [[ ${PROFILE_ENABLED:-0} == 1 ]]; then pam-auth-update --disable mkhomedir; fi
  # userdel -r also removes the home directory created by pam_mkhomedir.
  remove_user
}
DEMO_USER=ossec-demo
! getent passwd "$DEMO_USER" >/dev/null || die 'ossec-demo already exists'
! grep -q pam_mkhomedir /etc/pam.d/common-session || die 'mkhomedir profile is already enabled'
# -M: no home directory, as for an account that comes from a directory service.
run useradd -M -U -s /bin/bash "$DEMO_USER"
DEMO_CREATED=1
echo "$DEMO_USER:Winter#2026x" | chpasswd
run getent passwd "$DEMO_USER"

printf '\nTry: ssh %s@<vm> pwd   # Could not chdir to home directory\n' "$DEMO_USER"
pause_demo 'Press Enter to enable the mkhomedir profile.'

run cat /usr/share/pam-configs/mkhomedir
run pam-auth-update --enable mkhomedir
PROFILE_ENABLED=1
run grep mkhomedir /etc/pam.d/common-session

printf '\nTry: ssh %s@<vm> pwd   # /home/%s\n' "$DEMO_USER" "$DEMO_USER"
printf '     ls -ld /home/%s; ls -A /home/%s   # mode from HOME_MODE, files from /etc/skel\n' "$DEMO_USER" "$DEMO_USER"
pause_demo
