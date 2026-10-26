#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='setuid: effective UID follows the file owner; ignored on scripts'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gcc
cleanup() { remove_users; }
new_users "$U1" "$U2" "$U3"
chmod 755 "/home/$U1"   # прочим пользователям нужен проход к бинарнику
SRC="$(dirname "${BASH_SOURCE[0]}")/../src/userinfo.c"

echo; echo '===== setuid-программы системы ====='
run find /usr/bin -perm -4000 -type f -exec ls -l {} \;

echo; echo '===== Без setuid ====='
install -o "$U1" -g "$U1" -m 644 "$SRC" "/home/$U1/userinfo.c"
as "$U1" 'gcc -o userinfo userinfo.c && ls -l userinfo && ./userinfo'
as "$U3" "/home/$U1/userinfo"

echo; echo '===== С setuid (владелец '"$U2"') ====='
run chown "$U2:$U2" "/home/$U1/userinfo"
run chmod u+s "/home/$U1/userinfo"
as "$U1" 'ls -l userinfo && ./userinfo'
as "$U3" "/home/$U1/userinfo"

echo; echo '===== Бит s без права x владельца (S) ====='
run chmod u-x "/home/$U1/userinfo"
as "$U1" 'ls -l userinfo'
as "$U2" "/home/$U1/userinfo"   # владелец запустить не может
as "$U1" './userinfo'           # прочие — могут, euid = владелец

echo; echo '===== setuid на скрипте игнорируется ====='
as "$U1" 'printf "#!/bin/bash\n\nid\n" > id.sh && chmod a+x id.sh && ./id.sh'
run chown "$U2" "/home/$U1/id.sh"
run chmod u+s "/home/$U1/id.sh"
as "$U1" 'ls -l id.sh && ./id.sh'
