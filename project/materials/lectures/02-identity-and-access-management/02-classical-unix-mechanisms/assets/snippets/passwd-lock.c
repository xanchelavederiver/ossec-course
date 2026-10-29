@@ 510
static char *update_crypt_pw (char *cp)
@@ 534
	if (lflg && *cp != '!') {
		char  *newpw;

		xasprintf(&newpw, "!%s", cp);
@@ 544
		cp = newpw;
	}
	return cp;
}
