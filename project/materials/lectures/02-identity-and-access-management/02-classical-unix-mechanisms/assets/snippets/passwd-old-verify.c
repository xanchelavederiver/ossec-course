@@ 178
static int new_password (const struct passwd *pw)
@@ 197
	if (!amroot && !streq(crypt_passwd, "")) {
		clear = agetpass (_("Old password: "));
		if (NULL == clear) {
			return -1;
		}

		cipher = pw_encrypt (clear, crypt_passwd);
@@ 216
		if (!streq(cipher, crypt_passwd)) {
			erase_pass (clear);
@@ 221
			(void) sleep (1);
			(void) fprintf (stderr,
			                _("Incorrect password for %s.\n"),
			                pw->pw_name);
			return -1;
		}
