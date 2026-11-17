@@ 757
	amroot = (getuid () == 0);
@@ 904
	pw = get_my_pwent ();
@@ 986
	pw = xprefix_getpwnam (name);
@@ 1007
	/*
	 * If the UID of the user does not match the current real UID,
	 * check if I'm root.
	 */
	if (!amroot && (pw->pw_uid != getuid ())) {
@@ 1019
		exit (E_NOPERM);
	}
