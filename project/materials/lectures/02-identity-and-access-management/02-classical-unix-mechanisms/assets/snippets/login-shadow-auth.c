@@ 879
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

	      auth_ok:
