@@ 604
static void update_shadow (void)
@@ 642
	nsp->sp_pwdp = update_crypt_pw (nsp->sp_pwdp);
@@ 657
		if (do_update_age) {
			nsp->sp_lstchg = gettime () / DAY;
