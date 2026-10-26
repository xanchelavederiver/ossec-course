#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='POSIX ACL check algorithm: owner, named user, groups, no bit merging'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need setfacl getfacl gcc xxd
JOHNNY=ossec-johnny
cleanup() { remove_users; }
# U1 = владелец (bob), U2 = alice, U3 = carol, U4 = dave, JOHNNY в группах U2-U4
new_users "$U1" "$U2" "$U3" "$U4"
run useradd -m -G "$U2,$U3,$U4" "$JOHNNY"
DEMO_USERS+=("$JOHNNY")
chmod 755 "/home/$U1"
D="/home/$U1/demo14"
for f in hello.c file_reader.c; do
  install -o "$U1" -g "$U1" -m 644 "$(dirname "${BASH_SOURCE[0]}")/../src/$f" "/home/$U1/$f"
done
as "$U1" "mkdir -p demo14 && cp hello.c file_reader.c demo14/ && chmod 755 demo14"

echo; echo '===== 1. Привилегированному процессу нужен x хотя бы в одном правиле ====='
as "$U1" 'cd demo14 && gcc -o 3 hello.c && ./3 && chmod ugo-x 3 && ls -l 3'
tryrun "$D/3"
as "$U1" 'cd demo14 && setfacl -m g:users:--x 3 && getfacl --omit-header 3 && ./3'
tryrun "$D/3"   # root: исполнение возможно — x есть в одном из правил

echo; echo '===== 2. Владелец: ACL_USER_OBJ, маска не применяется ====='
as "$U1" "cd demo14 && echo Hello > 4.txt && setfacl -m u:$U2:r 4.txt && chmod u-r 4.txt && ls -l 4.txt && getfacl --omit-header 4.txt && cat 4.txt"
as "$U1" 'cd demo14 && chmod u+r 4.txt && cat 4.txt'
as "$U1" 'cd demo14 && setfacl -m mask::--x 4.txt && getfacl --omit-header 4.txt && cat 4.txt'
as "$U2" "cat $D/4.txt"

echo; echo '===== 3. Именованный пользователь: ACL_USER, маска применяется ====='
as "$U1" "cd demo14 && echo Hello > 5.txt && chmod ugo-r 5.txt && setfacl -m u:$U2:r 5.txt && getfacl --omit-header 5.txt && cat 5.txt"
as "$U2" "cat $D/5.txt"
as "$U3" "cat $D/5.txt"
as "$U1" 'cd demo14 && setfacl -m mask::--x 5.txt'
as "$U2" "cat $D/5.txt"

echo; echo '===== 4. Группа владельцев: ACL_GROUP_OBJ ====='
as "$U1" 'cd demo14 && echo Hello > 6.txt'
run chown "$U3" "$D/6.txt"
run setfacl -m group:nogroup:-wx "$D/6.txt"
as "$U1" "getfacl $D/6.txt && id -gn && cat $D/6.txt"

echo; echo '===== 5. Именованная группа: ACL_GROUP ====='
as "$U1" 'cd demo14 && echo Hello > 7.txt'
run chown "$U3:$U3" "$D/7.txt"
run chmod 0000 "$D/7.txt"
run setfacl -m "group:$U1:rwx" "$D/7.txt"
as "$U1" "groups && cat $D/7.txt"
as nobody "cat $D/7.txt"

echo; echo '===== 6. Несколько подходящих записей: права не складываются ====='
run runuser -u "$JOHNNY" -- id
as "$U1" "cd demo14 && gcc -o 8 hello.c && printf '#!/bin/bash\n\necho \"Hello\"\n' > 8.sh && chmod 0000 8 8.sh && setfacl -m g:$U2:r -m g:$U3:w -m g:$U4:x 8 8.sh && ls -l 8 8.sh && getfacl --omit-header 8.sh"
as "$JOHNNY" "cat $D/8 | xxd -l 16"
as "$JOHNNY" "$D/8"
as "$JOHNNY" "cat $D/8.sh"
as "$JOHNNY" "echo 'echo \"World!\"' >> $D/8.sh"
as "$JOHNNY" "cd $D && ./8.sh"

echo; echo '===== 7. O_RDWR требует rw в одной записи ====='
as "$U1" 'cd demo14 && grep -n O_RDWR file_reader.c && gcc -o file_reader file_reader.c'
as "$JOHNNY" "cd $D && ./file_reader 8.sh"
as "$U1" "cd demo14 && setfacl -m g:$U2:rw- 8.sh"
as "$JOHNNY" "cd $D && ./file_reader 8.sh"
as "$U1" "cd demo14 && setfacl -m g:$U2:r 8.sh"
as "$JOHNNY" "cd $D && ./8.sh"   # запуск скрипта: x при execve, r при чтении bash
