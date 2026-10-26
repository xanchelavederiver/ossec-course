#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Directory permissions: r, x and w act together'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
cleanup() { remove_users; }
new_users "$U1"

echo; echo '===== r без x ====='
as "$U1" 'mkdir -p d2/f && touch d2/f/1.txt d2/f/2.txt && echo Hello > d2/f/3.txt && chmod 0400 d2/f'
as "$U1" 'ls -ld d2/f; ls -l d2/f/; cat d2/f/3.txt'

echo; echo '===== x без r ====='
as "$U1" 'mkdir -p d2/f2 && echo "Hello!" > d2/f2/file.txt && chmod 0100 d2/f2'
as "$U1" 'ls -ld d2/f2; ls -l d2/f2/; cat d2/f2/file.txt'

echo; echo '===== w требует x ====='
as "$U1" 'mkdir -p d2/f3 && echo Hello > d2/f3/1.txt && chmod 0200 d2/f3'
as "$U1" 'touch d2/f3/2.txt; cp d2/f3/1.txt d2/f3/1-copy.txt; mv d2/f3/1.txt d2/f3/1-moved.txt; rm d2/f3/1.txt'
as "$U1" 'chmod 0700 d2/f3 && touch d2/f3/2.txt && mv d2/f3/1.txt d2/f3/1-moved.txt && rm d2/f3/1-moved.txt && ls d2/f3/'
