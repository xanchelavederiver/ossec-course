@@ 45
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
