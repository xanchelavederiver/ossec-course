/* 10-enum-accounts.c – перебор всех учётных записей и групп средствами libc.
 * Основано на: Kerrisk M. The Linux Programming Interface, гл. 8.
 * Сборка: gcc -Wall -O2 -o enum-accounts 10-enum-accounts.c
 */
#include <pwd.h>
#include <grp.h>
#include <stdio.h>
#include <string.h>

/* Вторичные группы: имя пользователя ищется в списках членов gr_mem. */
static void print_supplementary(const char *user)
{
    struct group *gr;
    const char *sep = "";

    setgrent();
    while ((gr = getgrent()) != NULL) {
        for (char **mem = gr->gr_mem; *mem != NULL; mem++) {
            if (strcmp(*mem, user) == 0) {
                printf("%s%s", sep, gr->gr_name);
                sep = ",";
            }
        }
    }
    endgrent();
}

int main(void)
{
    struct passwd *pw;
    struct group *gr;

    printf("%-16s %5s %5s  %-17s %s\n",
           "USER", "UID", "GID", "SHELL", "SUPPLEMENTARY");
    setpwent();                           /* открыть поток записей passwd */
    while ((pw = getpwent()) != NULL) {   /* очередная запись или NULL    */
        printf("%-16s %5u %5u  %-17s ", pw->pw_name,
               (unsigned) pw->pw_uid, (unsigned) pw->pw_gid, pw->pw_shell);
        print_supplementary(pw->pw_name);
        putchar('\n');
    }
    endpwent();                           /* закрыть /etc/passwd          */

    printf("\n%-16s %5s  %s\n", "GROUP", "GID", "MEMBERS");
    setgrent();
    while ((gr = getgrent()) != NULL) {
        printf("%-16s %5u ", gr->gr_name, (unsigned) gr->gr_gid);
        for (char **mem = gr->gr_mem; *mem != NULL; mem++)
            printf(" %s", *mem);
        putchar('\n');
    }
    endgrent();
    return 0;
}
