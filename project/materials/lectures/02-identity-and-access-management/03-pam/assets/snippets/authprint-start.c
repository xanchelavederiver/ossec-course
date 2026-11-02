@@ 12
#include <security/pam_appl.h>
#include <security/pam_misc.h>
@@ 22
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
