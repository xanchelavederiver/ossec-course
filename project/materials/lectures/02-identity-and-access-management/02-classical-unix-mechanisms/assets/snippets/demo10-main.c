@@ 28
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
