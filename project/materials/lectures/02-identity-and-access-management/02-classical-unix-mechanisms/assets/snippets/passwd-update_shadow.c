@@ 604
static void update_shadow (void)
@@ 623
	sp = spw_locate (name);
@@ 638
	nsp = __spw_dup (sp);
@@ 642
	nsp->sp_pwdp = update_crypt_pw (nsp->sp_pwdp);
@@ 657
		if (do_update_age) {
			nsp->sp_lstchg = gettime () / DAY;
