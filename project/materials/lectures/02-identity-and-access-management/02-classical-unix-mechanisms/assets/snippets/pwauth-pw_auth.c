@@ 51
int
pw_auth(const char *cipher, const char *user)
{
@@ 76
	if ((NULL == cipher) || streq(cipher, "")) {
		return 0;
	}
@@ 114
	SNPRINTF(prompt, cp, user);
	clear = agetpass(prompt);
	input = (clear == NULL) ? "" : clear;
@@ 125
	encrypted = pw_encrypt (input, cipher);
	if (NULL != encrypted) {
		retval = strcmp (encrypted, cipher);
	} else {
		retval = -1;
	}
@@ 157
	erase_pass(clear);

	return retval;
}
