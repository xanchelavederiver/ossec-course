#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

/* getpwuid(3) возвращает указатель на статический буфер, поэтому имя
 * копируем до следующего вызова */
static void uid_name(uid_t uid, char *buf, size_t len) {
    struct passwd *pw = getpwuid(uid);
    snprintf(buf, len, "%s", pw ? pw->pw_name : "неизвестно");
}

int main() {
    uid_t real_uid = getuid();      /* реальный UID: кто запустил */
    uid_t eff_uid = geteuid();      /* эффективный UID: от чьего имени работает */
    char real_name[64], eff_name[64];

    uid_name(real_uid, real_name, sizeof(real_name));
    uid_name(eff_uid, eff_name, sizeof(eff_name));

    printf("Реальный UID  (кто запустил):      %d (%s)\n", real_uid, real_name);
    printf("Эффективный UID (кем исполняется): %d (%s)\n", eff_uid, eff_name);

    return 0;
}
