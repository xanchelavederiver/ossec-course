@@ 845
		failent_user = get_failent_user (username);

		pwd = xgetpwnam (username);
		if (NULL == pwd) {
			preauth_flag = false;
			failed = true;
		} else {
			user_passwd = pwd->pw_passwd;
			/*
			 * If the encrypted password begins with a "!",
			 * the account is locked and the user cannot
			 * login, even if they have been
			 * "pre-authenticated."
			 */
			if (   ('!' == user_passwd[0])
			    || ('*' == user_passwd[0])) {
				failed = true;
			}
