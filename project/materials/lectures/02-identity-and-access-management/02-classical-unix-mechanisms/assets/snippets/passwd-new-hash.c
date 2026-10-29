@@ 353
	/*
	 * Encrypt the password, then wipe the cleartext password.
	 */
	salt = crypt_make_salt (NULL, NULL);
	cp = pw_encrypt (pass, salt);
	MEMZERO(pass);
@@ 367
	STRTCPY(crypt_passwd, cp);
	return 0;
