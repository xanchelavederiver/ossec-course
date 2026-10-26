#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='chattr a/i on a directory: forbid deletion, then freeze structure'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need chattr lsattr
D=/tmp/ossec-experiments
cleanup() {
  chattr =e "$D" 2>/dev/null
  rm -r -f "$D"
  remove_users
}
new_users "$U1" "$U2"

echo; echo '===== Каталог с файлами нескольких пользователей ====='
as "$U1" "mkdir $D"
run chgrp "$U2" "$D"
run chmod 775 "$D"
as "$U1" "cd $D && touch 1.txt && mkdir 1"
as "$U2" "cd $D && echo Hello > 2.txt && mkdir 2"
as "$U1" "ls -la $D"

echo; echo '===== Атрибут a: удалять нельзя, создавать можно ====='
run chattr +a "$D"
run lsattr /tmp | grep ossec-experiments || true
as "$U1" "rm -f $D/1.txt"
as "$U2" "rm -r $D/2"
tryrun rm -r "$D/1" "$D/1.txt" "$D/2" "$D/2.txt"
as "$U1" "touch $D/new.txt && ls -la $D | grep new"

echo; echo '===== Атрибут i: структура фиксируется ====='
run chattr -a "$D"
run chattr +i "$D"
as "$U1" "touch $D/newer.txt"
tryrun mkdir "$D/newer"

echo; echo '===== Сброс ====='
run chattr =e "$D"
run rm -r "$D"
tryrun ls -ld "$D"
