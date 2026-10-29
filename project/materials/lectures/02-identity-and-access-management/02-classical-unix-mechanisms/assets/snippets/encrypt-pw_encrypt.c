@@ 21
/*@exposed@*//*@null@*/char *pw_encrypt (const char *clear, const char *salt)
{
	static char cipher[128];
	char *cp;

	cp = crypt (clear, salt);
	if (NULL == cp) {
@@ 33
		return NULL;
	}
