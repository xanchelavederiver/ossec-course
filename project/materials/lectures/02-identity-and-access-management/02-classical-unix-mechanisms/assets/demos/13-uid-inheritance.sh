#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='UID inheritance across fork/execve and its edge cases (setuid helper)'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need useradd userdel runuser gcc install
cleanup() {
  rm -f /usr/local/bin/ossec-idprobe /usr/local/bin/ossec-suid-script
  remove_user
}
new_user

# Small helper: prints getresuid(2), demonstrates fork/execve inheritance.
cat >"$DEMO_TMP/idprobe.c" <<'IDPROBE'
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static void show(const char *label)
{
    uid_t ruid, euid, suid;
    getresuid(&ruid, &euid, &suid);
    printf("%-22s pid=%d ruid=%d euid=%d suid=%d\n",
           label, getpid(), ruid, euid, suid);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    const char *mode = argc > 1 ? argv[1] : "show";
    uid_t ruid, euid, suid;

    getresuid(&ruid, &euid, &suid);
    show("start");
    if (strcmp(mode, "fork") == 0) {
        if (seteuid(ruid)) { perror("seteuid(ruid)"); return 1; }
        show("after seteuid(ruid)");
        pid_t pid = fork();
        if (pid < 0) { perror("fork"); return 1; }
        if (pid == 0) {
            show("child after fork");
            if (seteuid(suid)) { perror("child seteuid(0)"); return 1; }
            show("child seteuid(0)");
            return 0;
        }
        if (waitpid(pid, NULL, 0) < 0) { perror("waitpid"); return 1; }
        if (seteuid(suid)) { perror("seteuid(0)"); return 1; }
        show("parent seteuid(0)");
    } else if (strcmp(mode, "exec") == 0) {
        execlp("id", "id", (char *)NULL);
        perror("execlp(id)"); return 1;
    } else if (strcmp(mode, "bash") == 0) {
        execlp("bash", "bash", "-c", "id", (char *)NULL);
        perror("execlp(bash)"); return 1;
    } else if (strcmp(mode, "bash-p") == 0) {
        execlp("bash", "bash", "-p", "-c", "id", (char *)NULL);
        perror("execlp(bash -p)"); return 1;
    }
    return 0;
}
IDPROBE
run gcc -Wall -O2 -o "$DEMO_TMP/ossec-idprobe" "$DEMO_TMP/idprobe.c"
run install -o root -g root -m 4755 "$DEMO_TMP/ossec-idprobe" /usr/local/bin/ossec-idprobe
run ls -l /usr/local/bin/ossec-idprobe

# 1. setuid binary: euid/suid become 0; fork inherits everything, including
#    the saved UID — both parent and child can re-raise privileges.
run runuser -u "$DEMO_USER" -- ossec-idprobe fork

# 2. execve of a non-setuid program keeps the credentials.
run runuser -u "$DEMO_USER" -- ossec-idprobe exec

# 3. Edge case: bash resets euid to ruid unless started with -p.
run runuser -u "$DEMO_USER" -- ossec-idprobe bash
run runuser -u "$DEMO_USER" -- ossec-idprobe bash-p

# 4. Edge case: the setuid bit on interpreter scripts is ignored by execve.
cat >/usr/local/bin/ossec-suid-script <<'SCRIPT'
#!/bin/bash
id
SCRIPT
chown root:root /usr/local/bin/ossec-suid-script
chmod 4755 /usr/local/bin/ossec-suid-script
run ls -l /usr/local/bin/ossec-suid-script
run runuser -u "$DEMO_USER" -- /usr/local/bin/ossec-suid-script
SCRIPT_EUID=$(runuser -u "$DEMO_USER" -- /usr/local/bin/ossec-suid-script | grep -c 'euid=0') || true
[[ $SCRIPT_EUID == 0 ]] || die 'setuid script unexpectedly gained privileges'
printf 'fork(2) copies all credentials; execve(2) keeps them unless the file has setuid/setgid.\n'
