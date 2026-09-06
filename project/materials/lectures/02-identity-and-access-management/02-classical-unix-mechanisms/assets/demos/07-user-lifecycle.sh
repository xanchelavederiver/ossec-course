#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='useradd, usermod, userdel, defaults and skeleton'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd usermod userdel
cleanup() { remove_user; }
run useradd -D
run grep -E '^(UID_MIN|UID_MAX|GID_MIN|GID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|UMASK|ENCRYPT_METHOD)' /etc/login.defs
run ls -la /etc/skel
new_user
run usermod -c 'Course demonstration account' -s /usr/sbin/nologin "$DEMO_USER"
run getent passwd "$DEMO_USER"
run userdel "$DEMO_USER"
DEMO_CREATED=0
# Demonstrate -m safely within the private temporary directory.
run useradd -U -m -k /etc/skel -d "$DEMO_TMP/home" -s /bin/bash "$DEMO_USER"
DEMO_CREATED=1
run ls -la "$DEMO_TMP/home"
run userdel -r "$DEMO_USER"
DEMO_CREATED=0
if getent passwd "$DEMO_USER"; then die 'Account still present'; fi
printf 'Account and temporary home removed. userdel does not find all files on the system.\n'
