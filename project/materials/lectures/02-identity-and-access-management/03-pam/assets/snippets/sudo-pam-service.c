@@ 195
static int
sudo_pam_init2(const struct sudoers_context *ctx, struct passwd *pw,
    sudo_auth *auth, bool quiet)
@@ 219
    /* Initialize PAM. */
    if (ISSET(ctx->mode, MODE_ASKPASS) && def_pam_askpass_service != NULL) {
	pam_service = def_pam_askpass_service;
    } else {
	pam_service = ISSET(ctx->mode, MODE_LOGIN_SHELL) ?
	    def_pam_login_service : def_pam_service;
    }
    pam_status = pam_start(pam_service, pw->pw_name, &pam_conv, &pamh);
