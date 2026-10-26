#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Default ACL: inheritance on create, umask not applied'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need setfacl getfacl getfattr
B=/tmp/ossec-acl
cleanup() {
  rm -r -f "$B"
  remove_users
}
new_users "$U1" "$U2"
mkdir -p "$B"; chown "$U1" "$B"

echo; echo '===== Список по умолчанию создаётся вместе с обычным ====='
as "$U1" "mkdir $B/d && setfacl -d -m u::rwx,g::wx,o::x $B/d && getfacl --omit-header $B/d"

echo; echo '===== Создание файла: вместо umask — default-список ====='
as "$U1" "umask 022; mkdir $B/no-acl $B/acl && umask && touch $B/no-acl/file && ls -l $B/no-acl/file"
as "$U1" "setfacl -d -m u::rwx,g::wx,o::x $B/acl && getfacl -d --omit-header $B/acl"
as "$U1" "umask 022; touch $B/acl/file && ls -l $B/acl/file && getfacl --omit-header $B/acl/file"

echo; echo '===== Поддиректория наследует и сам default-список ====='
as "$U1" "umask 022; mkdir $B/acl/dir && ls -ld $B/acl/dir && getfacl --omit-header $B/acl/dir"

echo; echo '===== Расширенный default-список и маска ====='
as "$U1" "mkdir $B/acl/sub && setfacl -d -m g:nogroup:x $B/acl/sub && getfacl -d --omit-header $B/acl/sub"
as "$U1" "umask 022; touch $B/acl/sub/file && ls -l $B/acl/sub/file && getfacl --omit-header $B/acl/sub/file"

echo; echo '===== После наследования списки независимы ====='
as "$U1" "setfacl -m u:$U2:rwx $B/acl/file && getfacl --omit-header $B/acl/file && getfacl -d --omit-header $B/acl"

echo; echo '===== Хранение ====='
run getfattr -d -m 'system.posix_acl_*' "$B/acl/sub"
run getfattr -d -m 'system.posix_acl_*' "$B/acl/sub/file"
