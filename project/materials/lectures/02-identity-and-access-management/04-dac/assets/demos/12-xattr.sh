#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='xattr namespaces (user/trusted/security) and file capabilities'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need setfattr getfattr setcap getcap gcc
cleanup() { remove_users; }
new_users "$U1"
SRC="$(dirname "${BASH_SOURCE[0]}")/../src/hello.c"
install -o "$U1" -g "$U1" -m 644 "$SRC" "/home/$U1/hello.c"

echo; echo '===== Пространства имён ====='
as "$U1" 'touch 1.txt && getfattr -d 1.txt'
as "$U1" 'setfattr -n user.mylabel -v "User" 1.txt'
run setfattr -n trusted.mylabel -v "Trusted" "/home/$U1/1.txt"
run setfattr -n security.mylabel -v "Security" "/home/$U1/1.txt"
as "$U1" 'setfattr -n trusted.other -v "x" 1.txt'   # отказ для непривилегированного
as "$U1" 'getfattr -d 1.txt'
run getfattr -d "/home/$U1/1.txt"                    # и root видит только user.
run getfattr -n trusted.mylabel "/home/$U1/1.txt"
run getfattr -n security.mylabel "/home/$U1/1.txt"
run setfattr -x security.mylabel "/home/$U1/1.txt"
tryrun getfattr -n security.mylabel "/home/$U1/1.txt"

echo; echo '===== Файловые capabilities ====='
as "$U1" 'gcc -o hello hello.c'
run setcap cap_net_bind_service=+ep "/home/$U1/hello"
run getcap "/home/$U1/hello"
run getfattr -d -m 'security.*' "/home/$U1/hello"
