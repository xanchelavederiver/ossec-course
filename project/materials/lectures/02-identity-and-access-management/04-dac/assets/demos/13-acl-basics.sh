#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='POSIX ACL: minimal vs extended lists, storage in xattr'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need setfacl getfacl getfattr
cleanup() { remove_users; }
new_users "$U1" "$U2"

echo; echo '===== Минимальный список ====='
as "$U1" 'mkdir demo13 && cd demo13 && touch 1.txt && ls -l 1.txt && getfacl 1.txt'
as "$U1" 'cd demo13 && getfattr -d -m "system.posix_acl_*" 1.txt'   # атрибута нет

echo; echo '===== Расширенный список ====='
as "$U1" "cd demo13 && touch 2.txt && setfacl -m user:$U2:rx 2.txt && getfacl --omit-header 2.txt && ls -l 2.txt"
as "$U1" 'cd demo13 && getfattr -d -m "system.posix_acl_*" 2.txt'   # появился xattr
