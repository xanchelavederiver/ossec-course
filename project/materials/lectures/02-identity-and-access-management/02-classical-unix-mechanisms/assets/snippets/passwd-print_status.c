@@ 453
static void print_status (const struct passwd *pw)
{
	char         date[80];
	struct spwd *sp;

	sp = prefix_getspnam (pw->pw_name); /* local, no need for xprefix_getspnam */
	if (NULL != sp) {
		DAY_TO_STR(date, sp->sp_lstchg);
		(void) printf ("%s %s %s %ld %ld %ld %ld\n",
		               pw->pw_name,
		               pw_status (sp->sp_pwdp),
		               date,
		               sp->sp_min,
		               sp->sp_max,
		               sp->sp_warn,
		               sp->sp_inact);
