#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Shell/login environment files: who reads what, and abuse of ~/.bashrc (persistence, PATH hijack)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel groupdel getent runuser grep install

U=ossec-demo1
! getent passwd "$U" >/dev/null || die "$U already exists"
PROFILED=/etc/profile.d/99-ossec-demo.sh
MARK=/tmp/ossec-backdoor-marker
cleanup() {
  local rc=0
  if getent passwd "$U" >/dev/null; then
    userdel -r "$U" 2>/dev/null || userdel "$U" || { printf 'Remove %s manually\n' "$U" >&2; rc=1; }
  fi
  getent group "$U" >/dev/null && { groupdel "$U" 2>/dev/null || true; }
  rm -f "$PROFILED" "$MARK"
  return "$rc"
}
run useradd -m -s /bin/bash "$U"
H=/home/"$U"

printf '\n### 1. System-wide files: /etc/environment and /etc/profile.d\n'
run cat /etc/environment
run grep -n 'pam_env' /etc/pam.d/login
run grep -nE 'profile.d' /etc/profile

printf '\n### 2. Who reads what: login shell vs interactive shell\n'
printf '[profile.d] выполнен (во всех login-сеансах)\n' >"$PROFILED.src"
install -m 0644 "$PROFILED.src" "$PROFILED"
printf 'echo "[.profile] выполнен (login-оболочка пользователя)"\n' >>"$H/.profile"
printf 'echo "[.bashrc] выполнен (любая интерактивная оболочка)"\n' >>"$H/.bashrc"
# inject an echo into the profile.d snippet so it announces itself
printf 'echo "[profile.d] выполнен (во всех login-сеансах)"\n' >"$PROFILED"
chmod 0644 "$PROFILED"
printf '$ runuser -u %s -- bash -l -c id   # login-оболочка\n' "$U"
runuser -u "$U" -- bash -l -c 'id -un' || true
printf '$ runuser -u %s -- bash -i -c id   # интерактивная НЕ login-оболочка\n' "$U"
runuser -u "$U" -- bash -i -c 'id -un' 2>/dev/null || true

printf '\n### 3. Abuse: writing to ~/.bashrc runs code as the owner\n'
printf '# echo %q >> %s/.bashrc   # attacker appends a payload\n' "touch $MARK" "$H"
printf 'touch %s\n' "$MARK" >>"$H/.bashrc"
run tail -n 1 "$H/.bashrc"
printf '$ runuser -u %s -- bash -i -c true   # victim starts a shell\n' "$U"
runuser -u "$U" -- bash -i -c 'true' 2>/dev/null || true
run ls -l "$MARK"

printf '\n### 4. Abuse: PATH hijack via ~/.bashrc shadows a command\n'
install -d -m 0755 "$H/.local/bin"
cat >"$H/.local/bin/id" <<'EOF'
#!/bin/sh
echo "[trojan id] перехвачен вызов; дальше можно подделать вывод"
exec /usr/bin/id "$@"
EOF
chmod 0755 "$H/.local/bin/id"
chown -R "$U:$U" "$H/.local"
printf 'export PATH="$HOME/.local/bin:$PATH"\n' >>"$H/.bashrc"
printf '$ runuser -u %s -- bash -i -c "command -v id; id -un"\n' "$U"
runuser -u "$U" -- bash -i -c 'command -v id; id -un' 2>/dev/null || true
