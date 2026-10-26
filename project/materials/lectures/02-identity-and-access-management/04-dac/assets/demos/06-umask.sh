#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='umask: mask of permission bits always cleared on creation'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { remove_users; }
new_users "$U1"

as "$U1" 'umask 022; umask; mkdir demo06 && cd demo06 && touch file-default && mkdir dir-default && ls -l'
as "$U1" 'cd demo06 && umask 077 && umask && touch file-077 && mkdir dir-077 && ls -l'
