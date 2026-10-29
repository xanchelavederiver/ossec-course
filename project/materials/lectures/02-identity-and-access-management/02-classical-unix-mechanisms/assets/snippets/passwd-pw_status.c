@@ 439
static /*@observer@*/const char *pw_status (const char *pass)
{
	if (*pass == '*' || *pass == '!') {
		return "L";
	}
	if (streq(pass, "")) {
		return "NP";
	}
	return "P";
}
