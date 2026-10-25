/*
 * authprint — учебное PAM-приложение (лекция 3, раздел 7).
 *
 * Печатает строку только после успешной аутентификации пользователя
 * через PAM: pam_start() → pam_authenticate() → pam_acct_mgmt() → pam_end().
 *
 * Сборка:  gcc -Wall authprint.c -o authprint -lpam -lpam_misc
 * Запуск:  ./authprint [служба]     (по умолчанию служба "authprint")
 *
 * Без файла /etc/pam.d/authprint применяется конфигурация службы other.
 */
#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* Функция диалога: готовая реализация misc_conv из libpam_misc
 * печатает сообщения модулей и читает ответы с терминала
 * (пароль — с отключённым эхом). */
static struct pam_conv conv = { misc_conv, NULL };

int main(int argc, char *argv[])
{
    const char *service = (argc > 1) ? argv[1] : "authprint";
    pam_handle_t *pamh = NULL;
    struct passwd *pw;
    int rc;

    /* Кто запустил программу: аутентифицируем текущего пользователя. */
    pw = getpwuid(getuid());
    if (pw == NULL) {
        fprintf(stderr, "authprint: cannot resolve current UID\n");
        return 1;
    }

    /* Инициализация контекста PAM для службы service. */
    rc = pam_start(service, pw->pw_name, &conv, &pamh);
    if (rc != PAM_SUCCESS) {
        fprintf(stderr, "pam_start failed: %s\n", pam_strerror(NULL, rc));
        return 1;
    }

    /* Стек auth: подлинность пользователя. */
    rc = pam_authenticate(pamh, 0);

    /* Стек account: разрешён ли доступ прямо сейчас. */
    if (rc == PAM_SUCCESS)
        rc = pam_acct_mgmt(pamh, 0);

    if (rc == PAM_SUCCESS)
        printf("Authenticated printf :-)\n");
    else
        fprintf(stderr, "authprint failed: %s\n", pam_strerror(pamh, rc));

    /* Завершение диалога с PAM; rc сообщается модулям. */
    if (pam_end(pamh, rc) != PAM_SUCCESS)
        return 1;

    return rc == PAM_SUCCESS ? 0 : 1;
}
