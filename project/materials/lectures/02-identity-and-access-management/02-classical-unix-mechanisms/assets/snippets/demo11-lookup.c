@@ 25
    pwd = getpwnam(argv[1]);              /* идентификация: запись passwd */
    if (pwd == NULL) {
        fprintf(stderr, "no such user: %s\n", argv[1]);
        return 2;
    }

    errno = 0;
    spwd = getspnam(argv[1]);             /* хеш пароля — в /etc/shadow   */
    if (spwd == NULL && errno == EACCES) {
        fprintf(stderr, "no permission to read shadow file\n");
        return 2;
    }
    if (spwd != NULL)
        pwd->pw_passwd = spwd->sp_pwdp;
