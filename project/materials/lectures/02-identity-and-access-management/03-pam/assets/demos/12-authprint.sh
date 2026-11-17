#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='authprint: a PAM-aware application built with libpam (src/authprint.c)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need apt-get gcc grep runuser
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../src" && pwd)"
cleanup() {
  rm -f /usr/local/bin/authprint /etc/pam.d/authprint /etc/authprint.allow
  remove_user
}
new_user
echo "$DEMO_USER:Winter#2026x" | chpasswd
apt-get install -y libpam0g-dev >/dev/null

printf '\n--- 1. build and install ---\n'
run gcc -Wall "$SRC_DIR/authprint.c" -o "$DEMO_TMP/authprint" -lpam -lpam_misc
install -m 755 "$DEMO_TMP/authprint" /usr/local/bin/authprint

printf '\n--- 2. without /etc/pam.d/authprint the service "other" applies ---\n'
printf 'Run as the test user:  authprint        # asks the password, prints the line\n'

printf '\n--- 3. own service config: only listed users allowed ---\n'
echo "$DEMO_USER" > /etc/authprint.allow
cat > /etc/pam.d/authprint <<'EOF'
auth     required   pam_listfile.so onerr=fail item=user sense=allow file=/etc/authprint.allow
@include common-auth
@include common-account
EOF
run cat /etc/pam.d/authprint
printf '\nRun:  su - %s -c "authprint authprint"   # allowed\n' "$DEMO_USER"
printf '      su - <other-user> -c "authprint authprint"   # refused by pam_listfile\n'
printf 'PAM logs the refusal to syslog (/var/log/auth.log).\n'
pause_demo
