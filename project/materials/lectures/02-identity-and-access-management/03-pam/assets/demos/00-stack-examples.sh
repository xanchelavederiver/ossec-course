#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Stack execution examples A-E (pam.d/demo-*), checked with pamtester'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need pamtester expand
G=ossec-ops
U2=ossec-demo2
cleanup() {
  rm -f /etc/nologin /etc/pam.d/demo-{a,b,c,d,e}
  remove_user
  if [[ ${U2_CREATED:-0} == 1 ]]; then userdel -r "$U2" 2>/dev/null || userdel "$U2" || true; fi
  if [[ ${G_CREATED:-0} == 1 ]]; then groupdel "$G" || true; fi
}
[[ ! -e /etc/nologin ]] || die '/etc/nologin already exists'
for f in /etc/pam.d/demo-{a,b,c,d,e}; do [[ ! -e $f ]] || die "$f already exists"; done
! getent group "$G" >/dev/null || die "$G group already exists"
! getent passwd "$U2" >/dev/null || die "$U2 already exists"
new_user                                   # ossec-demo: member of the operators-like group
echo "$DEMO_USER:Winter#2026x" | chpasswd
run groupadd "$G"; G_CREATED=1
run usermod -aG "$G" "$DEMO_USER"
run useradd -m -U -s /bin/bash "$U2"; U2_CREATED=1   # ossec-demo2: not a member
echo "$U2:Summer#2026y" | chpasswd

cat > /etc/pam.d/demo-a <<'PAM'
auth	required	pam_unix.so
auth	required	pam_nologin.so
PAM
cat > /etc/pam.d/demo-b <<'PAM'
auth	requisite	pam_nologin.so
auth	required	pam_unix.so
PAM
cat > /etc/pam.d/demo-c <<PAM
auth	required	pam_succeed_if.so quiet user ingroup $G
auth	sufficient	pam_unix.so
auth	required	pam_deny.so
PAM
cat > /etc/pam.d/demo-d <<'PAM'
auth	[success=1 default=ignore]	pam_unix.so
auth	requisite			pam_deny.so
auth	required			pam_permit.so
PAM
cat > /etc/pam.d/demo-e <<PAM
auth	[success=2 default=ignore]	pam_succeed_if.so quiet user ingroup $G
auth	required			pam_unix.so
auth	required			pam_nologin.so
auth	required			pam_permit.so
PAM
try() { printf '\n# pamtester %s %s authenticate   (%s)\n' "$1" "$2" "$3"; pamtester "$1" "$2" authenticate || true; }

printf '\n=== A: two required (both run; /etc/nologin present) ===\n'; expand -t 8 /etc/pam.d/demo-a
echo 'System closed for maintenance' > /etc/nologin
try demo-a "$DEMO_USER" 'enter the RIGHT password Winter#2026x: prompt shown, then nologin message, failure'

printf '\n=== B: requisite stops the stack (no password prompt) ===\n'; expand -t 8 /etc/pam.d/demo-b
try demo-b "$DEMO_USER" 'no prompt: pam_nologin fails first'
rm -f /etc/nologin
try demo-b "$DEMO_USER" 'nologin removed: RIGHT password -> success'

printf '\n=== C: sufficient after an earlier failure ===\n'; expand -t 8 /etc/pam.d/demo-c
try demo-c "$DEMO_USER" 'group member, RIGHT password -> success'
try demo-c "$U2" 'non-member, RIGHT password Summer#2026y -> failure (pam_deny)'

printf '\n=== D: numeric jump, Debian pattern ===\n'; expand -t 8 /etc/pam.d/demo-d
try demo-d "$DEMO_USER" 'RIGHT password -> success'
try demo-d "$DEMO_USER" 'WRONG password -> failure'

printf '\n=== E: jump over two modules = authentication bypass ===\n'; expand -t 8 /etc/pam.d/demo-e
try demo-e "$U2" 'non-member, WRONG password -> failure'
try demo-e "$DEMO_USER" 'group member: NO password asked, success'
pause_demo
