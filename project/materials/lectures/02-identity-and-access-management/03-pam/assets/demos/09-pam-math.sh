#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='pam_math: build, install and wire a custom PAM module (src/pam_math.c)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need apt-get gcc grep sed runuser
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../src" && pwd)"
MODDIR=/usr/lib/x86_64-linux-gnu/security
cleanup() {
  restore_files
  rm -f "$MODDIR/pam_math.so" /etc/pam.d/mathtest
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
apt-get install -y libpam0g-dev >/dev/null
backup_file /etc/pam.d/sshd

printf '\n--- 1. build and install the module ---\n'
run gcc -Wall -fPIC -shared "$SRC_DIR/pam_math.c" -o "$DEMO_TMP/pam_math.so" -lpam
run install -m 644 "$DEMO_TMP/pam_math.so" "$MODDIR/"

printf '\n--- 2. test service (use authprint from demo 08 or pamtester) ---\n'
cat > /etc/pam.d/mathtest <<'EOF'
auth     required   pam_math.so max=50
account  required   pam_permit.so
EOF
run cat /etc/pam.d/mathtest
printf 'Run:  su - %s -c "authprint mathtest"   # answer the arithmetic prompt\n' "$DEMO_USER"

printf '\n--- 3. the module as a second factor for sshd ---\n'
sed -i '/^@include common-auth/a auth\trequired\tpam_math.so max=50' /etc/pam.d/sshd
run grep pam_math /etc/pam.d/sshd
printf 'Needs KbdInteractiveAuthentication yes (see demo 07).\n'
printf 'Try:  ssh %s@<vm> id   # Password: then the math prompt\n' "$DEMO_USER"
pause_demo
