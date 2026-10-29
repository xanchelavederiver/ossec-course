@@ 10
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
