#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='Account creation with default values: login.defs, /etc/default/useradd, /etc/skel + /usr/etc/skel merge'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd groupadd userdel groupdel getent stat grep install

U1=ossec-demo1 G=ossec-proj
USRSKEL=/usr/etc/skel
# files this demo seeds into /usr/etc/skel (removed on cleanup)
SEED_VENDOR="$USRSKEL/.ossec_profile"
SEED_COLLIDE="$USRSKEL/.bash_logout"
USRSKEL_PREEXISTING=0
[[ -d $USRSKEL ]] && USRSKEL_PREEXISTING=1

! getent passwd "$U1" >/dev/null || die "$U1 already exists"
! getent group "$U1" >/dev/null || die "group $U1 already exists"
! getent group "$G" >/dev/null || die "$G already exists"
[[ -e $SEED_VENDOR ]] && die "$SEED_VENDOR already exists"
cleanup() {
  local rc=0
  if getent passwd "$U1" >/dev/null; then
    userdel -r "$U1" 2>/dev/null || userdel "$U1" || { printf 'Remove %s manually\n' "$U1" >&2; rc=1; }
  fi
  getent group "$U1" >/dev/null && { groupdel "$U1" 2>/dev/null || true; }
  if getent group "$G" >/dev/null; then
    groupdel "$G" || { printf 'Remove group %s manually\n' "$G" >&2; rc=1; }
  fi
  rm -f "$SEED_VENDOR" "$SEED_COLLIDE"
  # remove the directory only if this demo created it
  [[ $USRSKEL_PREEXISTING == 0 && -d $USRSKEL ]] && rmdir "$USRSKEL" 2>/dev/null || true
  return "$rc"
}

# Seed a vendor template in /usr/etc/skel (shadow 4.17 feature; empty by default).
# .ossec_profile – vendor-only file; .bash_logout – collides with /etc/skel to show precedence.
install -d -m 0755 "$USRSKEL"
printf '# корпоративный профиль (поставляется дистрибутивом)\numask 027\n' >"$SEED_VENDOR"
printf 'FROM /usr/etc/skel\n' >"$SEED_COLLIDE"

printf '\n### 1. Defaults that govern useradd\n'
run useradd -D
run grep -E '^(UID|GID)_|^HOME_MODE|^PASS_|^ENCRYPT_|^USERGROUPS' /etc/login.defs

printf '\n### 2. The two skeleton directories\n'
run ls -A /etc/skel
run ls -A "$USRSKEL"

printf '\n### 3. One user with pure defaults (home = union of both skels)\n'
run useradd -m "$U1"
run getent passwd "$U1"
run getent group "$U1"
run stat -c '%A  %U:%G  %n' /home/"$U1"
run ls -A /home/"$U1"
run getent shadow "$U1"
# merge evidence: vendor-only file lands in home; on collision /etc/skel wins
run head -1 /home/"$U1"/.bash_logout
run cat /home/"$U1"/.ossec_profile

printf '\n### 4. A standalone group\n'
run groupadd "$G"
run getent group "$G"
