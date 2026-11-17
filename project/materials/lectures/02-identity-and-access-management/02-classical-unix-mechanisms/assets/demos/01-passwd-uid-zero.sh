#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Change a temporary account UID to 0; restore before deleting it'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need vipw useradd userdel runuser python3
cleanup() {
  if [[ -n ${ORIGINAL_UID:-} ]]; then
    OSSEC_UID="$ORIGINAL_UID" VISUAL="$DEMO_TMP/editor" EDITOR="$DEMO_TMP/editor" vipw
    if [[ $(id -u "$DEMO_USER") != "$ORIGINAL_UID" ]]; then
      printf 'UID restoration FAILED. Keep VM isolated; revert its snapshot.\n' >&2
      return 1
    fi
  fi
  remove_user
}
new_user
ORIGINAL_UID=$(id -u "$DEMO_USER")
run getent passwd "$DEMO_USER"
run runuser -u "$DEMO_USER" -- id -u
# vipw locks the database and invokes this editor on its temporary copy.
cat >"$DEMO_TMP/editor" <<'EDITOR'
#!/usr/bin/env python3
import os, pathlib, sys, time
p = pathlib.Path(sys.argv[1])
rows = p.read_text().splitlines()
matches = [i for i, row in enumerate(rows) if row.startswith('ossec-demo:')]
assert len(matches) == 1
i = matches[0]
fields = rows[i].split(':')
fields[2] = os.environ['OSSEC_UID']
rows[i] = ':'.join(fields)
previous_mtime = p.stat().st_mtime
p.write_text('\n'.join(rows) + '\n')
# vipw checks second-resolution mtime; ensure a quick edit is detected.
modified = max(time.time(), previous_mtime + 2)
os.utime(p, (modified, modified))
EDITOR
chmod 700 "$DEMO_TMP/editor"
printf '\n$ vipw  # change only ossec-demo UID to 0\n'
OSSEC_UID=0 VISUAL="$DEMO_TMP/editor" EDITOR="$DEMO_TMP/editor" vipw
run getent passwd "$DEMO_USER"
run runuser -u "$DEMO_USER" -- id -u
[[ $(runuser -u "$DEMO_USER" -- id -u) == 0 ]]
printf 'A newly created process has UID 0. Existing process credentials do not change.\n'
