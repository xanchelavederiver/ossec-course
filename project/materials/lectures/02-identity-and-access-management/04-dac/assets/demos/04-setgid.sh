#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='setgid on executables and directories (group inheritance)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gcc
cleanup() { remove_users; }
new_users "$U1" "$U2" "$U3"
chmod 755 "/home/$U1"
SRC="$(dirname "${BASH_SOURCE[0]}")/../src/groupinfo.c"

echo; echo '===== Без setgid ====='
install -o "$U1" -g "$U1" -m 644 "$SRC" "/home/$U1/groupinfo.c"
as "$U1" 'gcc -o groupinfo groupinfo.c && ./groupinfo'

echo; echo '===== setgid: эффективный GID = группа файла ====='
run chgrp "$U3" "/home/$U1/groupinfo"
run chmod g+s "/home/$U1/groupinfo"
as "$U1" 'ls -l groupinfo && ./groupinfo'
as "$U2" "/home/$U1/groupinfo"

echo; echo '===== setgid на каталоге ====='
as "$U1" 'mkdir shared'
run chgrp "$U3" "/home/$U1/shared"
run chmod 2775 "/home/$U1/shared"
as "$U1" 'ls -ld shared && echo Hello > shared/1.txt'
as "$U3" "touch /home/$U1/shared/2.txt"
as "$U1" 'ls -l shared/'
