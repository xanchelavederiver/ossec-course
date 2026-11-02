@@ 15
#include <security/pam_modules.h>
#include <security/pam_ext.h>
@@ 25
int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                        int argc, const char **argv)
{
    const char *user = NULL;
    char *resp = NULL;
    long max = 100;             /* верхняя граница слагаемых */
    int a, b, rc, i;
@@ 35
    /* Разбор module-arguments: поддерживаем max=N. */
    for (i = 0; i < argc; i++)
        if (strncmp(argv[i], "max=", 4) == 0)
            max = atol(argv[i] + 4);
@@ 42
    /* Имя пользователя: из контекста PAM или вопросом через диалог. */
    rc = pam_get_user(pamh, &user, NULL);
    if (rc != PAM_SUCCESS)
        return rc;

    /* Задача. */
    srandom((unsigned) (time(NULL) ^ getpid()));
    a = (int) (random() % max);
    b = (int) (random() % max);
