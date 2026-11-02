@@ 52
    /* Вопрос пользователю через функцию диалога приложения:
     * PAM_PROMPT_ECHO_ON – ввод отображается (это не пароль). */
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
@@ 74
int pam_sm_setcred(pam_handle_t *pamh, int flags,
                   int argc, const char **argv)
{
    (void) pamh; (void) flags; (void) argc; (void) argv;
    return PAM_IGNORE;
}
