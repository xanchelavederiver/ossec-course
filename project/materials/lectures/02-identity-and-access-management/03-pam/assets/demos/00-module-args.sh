#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Module types provided (pam_sm_* symbols) and module arguments: use_first_pass, try_first_pass, unknown option, debug, nullok'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need pamtester expand nm
U2=ossec-demo2
cleanup() {
  rm -f /etc/pam.d/demo-{f,f2,f3,g,h,h3,i,j,k,k2}
  remove_user
  if [[ ${U2_CREATED:-0} == 1 ]]; then userdel -r "$U2" 2>/dev/null || userdel "$U2" || true; fi
}
for f in /etc/pam.d/demo-{f,f2,f3,g,h,h3,i,j,k,k2}; do [[ ! -e $f ]] || die "$f already exists"; done
! getent passwd "$U2" >/dev/null || die "$U2 already exists"
new_user                                   # ossec-demo: has a password
echo "$DEMO_USER:Winter#2026x" | chpasswd
run useradd -m -U -s /bin/bash "$U2"; U2_CREATED=1   # ossec-demo2: EMPTY password
run passwd -d "$U2"
D=/usr/lib/x86_64-linux-gnu/security
try() { printf '\n# pamtester %s %s %s   (%s)\n' "$1" "$2" "$3" "$4"; pamtester "$1" "$2" "$3" || true; }

printf '\n=== 1. Which pam_sm_* entry points does a module export? ===\n'
run nm -D --defined-only "$D/pam_securetty.so" | grep pam_sm_
for m in pam_unix pam_securetty pam_nologin pam_faillock pam_time pam_limits pam_pwhistory pam_umask; do
  printf '%-16s' "$m"
  nm -D --defined-only "$D/$m.so" | awk '/pam_sm_/{sub("pam_sm_","",$3); printf "%s ",$3}'; echo
done

printf '\n=== 2. A type the module does not provide: PAM_MODULE_UNKNOWN ===\n'
printf 'session\trequired\tpam_securetty.so\n' > /etc/pam.d/demo-f; expand -t 8 /etc/pam.d/demo-f
try demo-f "$DEMO_USER" open_session 'expect: Module is unknown; syslog: unable to resolve symbol pam_sm_open_session'

printf '\n=== 3. module_unknown=ignore: ignored rule leaves the stack without a verdict ===\n'
printf 'session\t[success=ok module_unknown=ignore default=bad]\tpam_securetty.so\n' > /etc/pam.d/demo-f2; expand -t 8 /etc/pam.d/demo-f2
try demo-f2 "$DEMO_USER" open_session 'expect: Permission denied - nothing in the stack produced a result'
{ cat /etc/pam.d/demo-f2; printf 'session\trequired\tpam_permit.so\n'; } > /etc/pam.d/demo-f3; expand -t 8 /etc/pam.d/demo-f3
try demo-f3 "$DEMO_USER" open_session 'expect: successfully opened a session'

printf '\n=== 4. use_first_pass / try_first_pass (pam_get_authtok reuses PAM_AUTHTOK by default) ===\n'
printf 'auth\trequired\tpam_unix.so\nauth\trequired\tpam_unix.so\n' > /etc/pam.d/demo-g; expand -t 8 /etc/pam.d/demo-g
try demo-g "$DEMO_USER" authenticate 'enter Winter#2026x ONCE: second pam_unix reuses the token'
printf 'auth\trequired\tpam_unix.so use_first_pass\n' > /etc/pam.d/demo-h; expand -t 8 /etc/pam.d/demo-h
try demo-h "$DEMO_USER" authenticate 'no prompt, failure: nothing stacked before'
printf 'auth\trequired\tpam_unix.so try_first_pass\n' > /etc/pam.d/demo-h3; expand -t 8 /etc/pam.d/demo-h3
try demo-h3 "$DEMO_USER" authenticate 'prompt shown: no earlier token, so ask'

printf '\n=== 5. Unknown argument is only logged; debug adds log lines ===\n'
printf 'auth\trequired\tpam_unix.so foo=bar\n' > /etc/pam.d/demo-i; expand -t 8 /etc/pam.d/demo-i
try demo-i "$DEMO_USER" authenticate 'RIGHT password -> success; syslog: unrecognized option [foo=bar]'
printf 'auth\trequired\tpam_unix.so debug\n' > /etc/pam.d/demo-j; expand -t 8 /etc/pam.d/demo-j
try demo-j "$DEMO_USER" authenticate 'RIGHT password -> success; syslog: username [...] obtained'

printf '\n=== 6. nullok: empty password accepted only with the argument ===\n'
run passwd -S "$U2"
printf 'auth\trequired\tpam_unix.so\n' > /etc/pam.d/demo-k; expand -t 8 /etc/pam.d/demo-k
try demo-k "$U2" authenticate 'press Enter at the prompt -> failure'
printf 'auth\trequired\tpam_unix.so nullok\n' > /etc/pam.d/demo-k2; expand -t 8 /etc/pam.d/demo-k2
try demo-k2 "$U2" authenticate 'no prompt, success'
printf '\nSee /var/log/auth.log (or journalctl -t pamtester) for the module messages.\n'
pause_demo
