#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>

/* getgrgid(3) возвращает указатель на статический буфер, поэтому имя
 * копируем до следующего вызова */
static void gid_name(gid_t gid, char *buf, size_t len) {
    struct group *gr = getgrgid(gid);
    snprintf(buf, len, "%s", gr ? gr->gr_name : "неизвестно");
}

int main() {
    gid_t real_gid = getgid();      /* реальный GID: группа запустившего */
    gid_t eff_gid = getegid();      /* эффективный GID: от чьего имени работает */
    char real_name[64], eff_name[64];

    gid_name(real_gid, real_name, sizeof(real_name));
    gid_name(eff_gid, eff_name, sizeof(eff_name));

    printf("Реальный GID  (группа запустившего): %d (%s)\n", real_gid, real_name);
    printf("Эффективный GID (кем исполняется):   %d (%s)\n", eff_gid, eff_name);

    return 0;
}
