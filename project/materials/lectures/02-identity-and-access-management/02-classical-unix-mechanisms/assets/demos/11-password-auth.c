/* 11-password-auth.c – парольная аутентификация по /etc/shadow.
 * Основано на: Kerrisk M. The Linux Programming Interface, листинг 8-2.
 * Сборка: gcc -Wall -O2 -o pwcheck 11-password-auth.c -lcrypt
 */
#define _DEFAULT_SOURCE
#include <pwd.h>
#include <shadow.h>
#include <crypt.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[])
{
    struct passwd *pwd;
    struct spwd *spwd;
    char *password, *encrypted;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <username>\n", argv[0]);
        return 2;
    }

    pwd = getpwnam(argv[1]);              /* идентификация: запись passwd */
    if (pwd == NULL) {
        fprintf(stderr, "no such user: %s\n", argv[1]);
        return 2;
    }

    errno = 0;
    spwd = getspnam(argv[1]);             /* хеш пароля – в /etc/shadow   */
    if (spwd == NULL && errno == EACCES) {
        fprintf(stderr, "no permission to read shadow file\n");
        return 2;
    }
    if (spwd != NULL)
        pwd->pw_passwd = spwd->sp_pwdp;

    password = getpass("Password: ");     /* запрос пароля без эха        */

    /* Хеш введённого пароля: алгоритм, параметры и соль crypt берёт
     * из хранимого хеша, переданного вторым аргументом. */
    encrypted = crypt(password, pwd->pw_passwd);
    explicit_bzero(password, strlen(password));  /* стереть открытый пароль */
    if (encrypted == NULL) {
        perror("crypt");
        return 2;
    }

    if (strcmp(encrypted, pwd->pw_passwd) != 0) {
        printf("Access denied\n");
        return 1;
    }

    printf("Successfully authenticated: UID=%u\n", (unsigned) pwd->pw_uid);
    /* ...дальше программа действовала бы от имени этого пользователя */
    return 0;
}
