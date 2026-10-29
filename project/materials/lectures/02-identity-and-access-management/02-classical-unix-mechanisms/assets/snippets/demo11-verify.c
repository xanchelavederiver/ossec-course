@@ 40
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
