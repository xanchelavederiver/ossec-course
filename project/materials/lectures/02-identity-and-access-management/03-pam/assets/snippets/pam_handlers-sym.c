@@ 759
    switch (type) {
    case PAM_T_AUTH:
	handler_p = &the_handlers->authenticate;
	sym = "pam_sm_authenticate";
	handler_p2 = &the_handlers->setcred;
	sym2 = "pam_sm_setcred";
	break;
@@ 798
    if ((mod_type == PAM_MT_DYNAMIC_MOD) &&
        !(func = _pam_dlsym(mod->dl_handle, sym)) ) {
	pam_syslog(pamh, LOG_ERR, "unable to resolve symbol: %s", sym);
    }
