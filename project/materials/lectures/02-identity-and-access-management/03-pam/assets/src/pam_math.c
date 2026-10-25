/*
 * pam_math — учебный PAM-модуль (лекция 3, раздел 8).
 *
 * «Аутентифицирует» пользователя арифметической задачей: модуль задаёт
 * пример a + b и сравнивает ответ. Реализует стек auth: обязательную
 * функцию pam_sm_authenticate() и сопутствующую pam_sm_setcred().
 *
 * Сборка:    gcc -Wall -fPIC -shared pam_math.c -o pam_math.so -lpam
 * Установка: install -m 644 pam_math.so /usr/lib/x86_64-linux-gnu/security/
 * Пример правила:  auth  required  pam_math.so max=20
 *
 * ВНИМАНИЕ: модуль учебный; знание арифметики — не секрет, поэтому
 * в реальных системах он может быть лишь ДОПОЛНИТЕЛЬНЫМ фактором.
 */
#include <security/pam_modules.h>
#include <security/pam_ext.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* Стек auth: проверка подлинности пользователя. */
int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                        int argc, const char **argv)
{
    const char *user = NULL;
    char *resp = NULL;
    long max = 100;             /* верхняя граница слагаемых */
    int a, b, rc, i;

    (void) flags;

    /* Разбор module-arguments: поддерживаем max=N. */
    for (i = 0; i < argc; i++)
        if (strncmp(argv[i], "max=", 4) == 0)
            max = atol(argv[i] + 4);
    if (max < 2)
        max = 2;

    /* Имя пользователя: из контекста PAM или вопросом через диалог. */
    rc = pam_get_user(pamh, &user, NULL);
    if (rc != PAM_SUCCESS)
        return rc;

    /* Задача. */
    srandom((unsigned) (time(NULL) ^ getpid()));
    a = (int) (random() % max);
    b = (int) (random() % max);

    /* Вопрос пользователю через функцию диалога приложения:
     * PAM_PROMPT_ECHO_ON — ввод отображается (это не пароль). */
    rc = pam_prompt(pamh, PAM_PROMPT_ECHO_ON, &resp,
                    "math for %s: %d + %d = ", user, a, b);
    if (rc != PAM_SUCCESS)
        return rc;
    if (resp == NULL)
        return PAM_AUTH_ERR;

    if (atoi(resp) == a + b) {
        rc = PAM_SUCCESS;
    } else {
        pam_error(pamh, "Wrong answer.");   /* сообщение PAM_ERROR_MSG */
        rc = PAM_AUTH_ERR;
    }

    free(resp);
    return rc;
}

/* Стек auth, вторая функция: установка «удостоверений» (групп и т. п.).
 * Модулю нечего устанавливать — сообщаем PAM_IGNORE. */
int pam_sm_setcred(pam_handle_t *pamh, int flags,
                   int argc, const char **argv)
{
    (void) pamh; (void) flags; (void) argc; (void) argv;
    return PAM_IGNORE;
}
