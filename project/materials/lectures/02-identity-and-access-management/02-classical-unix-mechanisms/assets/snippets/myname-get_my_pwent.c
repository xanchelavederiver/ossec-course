@@ 25
/*@null@*/ /*@only@*/struct passwd *get_my_pwent (void)
{
	struct passwd *pw;
	const char *cp = getlogin ();
	uid_t ruid = getuid ();
@@ 41
	if ((NULL != cp) && !streq(cp, "")) {
		pw = xgetpwnam (cp);
		if ((NULL != pw) && (pw->pw_uid == ruid)) {
			return pw;
		}
@@ 51
	return xgetpwuid (ruid);
}
