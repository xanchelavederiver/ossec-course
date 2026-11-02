@@ 334
int _pam_dispatch(pam_handle_t *pamh, int flags, int choice)
@@ 349
    if ((retval = _pam_init_handlers(pamh)) != PAM_SUCCESS) {
	pam_syslog(pamh, LOG_ERR, "unable to dispatch function");
	goto end;
    }

    use_cached_chain = _PAM_PLEASE_FREEZE;

    switch (choice) {
    case PAM_AUTHENTICATE:
	h = pamh->handlers.conf.authenticate;
	break;
@@ 364
    case PAM_ACCOUNT:
	h = pamh->handlers.conf.acct_mgmt;
	break;
@@ 383
    if (h == NULL) {     /* there was no handlers.conf... entry; will use
			  * handlers.other... */
	switch (choice) {
	case PAM_AUTHENTICATE:
	    h = pamh->handlers.other.authenticate;
	    break;
