#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='ACL_MASK: chmod edits the mask; ls shows the mask'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need setfacl getfacl
cleanup() { remove_users; }
new_users "$U1" "$U2"

echo; echo '===== Минимальный список: chmod меняет ACL_GROUP_OBJ ====='
as "$U1" 'mkdir demo15 && cd demo15 && touch file && ls -l file && getfacl --omit-header file'
as "$U1" 'cd demo15 && chmod 0770 file && ls -l file && getfacl --omit-header file'

echo; echo '===== Расширенный список: chmod меняет ACL_MASK ====='
as "$U1" "cd demo15 && setfacl -m user:$U2:rw file && ls -l file && getfacl --omit-header file"
as "$U1" 'cd demo15 && chmod 0333 file && ls -l file && getfacl --omit-header file'

echo; echo '===== Маска отражается во втором триплете ls ====='
as "$U1" 'cd demo15 && touch file2 && setfacl -m g:nogroup:w file2 && ls -l file2 && getfacl --omit-header file2'
as "$U1" 'cd demo15 && setfacl -m mask::--x file2 && ls -l file2'
