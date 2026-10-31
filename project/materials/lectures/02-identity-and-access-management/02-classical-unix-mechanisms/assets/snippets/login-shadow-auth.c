@@ 859
			if (   ('!' == user_passwd[0])
			    || ('*' == user_passwd[0])) {
				failed = true;
			}

			if (streq(user_passwd, "")) {
				const char *prevent_no_auth = getdef_str("PREVENT_NO_AUTH");
@@ 870
				if (streq(prevent_no_auth, "yes")) {
					failed = true;
				} else if ((pwd->pw_uid == 0)
					&& streq(prevent_no_auth, "superuser")) {
					failed = true;
				}
			}
		}

		if (streq(user_passwd, SHADOW_PASSWD_STRING)) {
			spwd = xgetspnam (username);
			if (NULL != spwd) {
				user_passwd = spwd->sp_pwdp;
			} else {
@@ 891
			}
		}
@@ 902
		if (pw_auth(user_passwd, username) == 0) {
			goto auth_ok;
		}

		SYSLOG ((LOG_WARN, "invalid password for '%s' %s",
		         failent_user, fromhost));
		failed = true;
