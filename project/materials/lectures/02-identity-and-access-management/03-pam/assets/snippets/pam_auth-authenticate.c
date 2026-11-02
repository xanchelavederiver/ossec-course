@@ 14
int pam_authenticate(pam_handle_t *pamh, int flags)
{
@@ 22
    if (__PAM_FROM_MODULE(pamh)) {
	D(("called from module!?"));
	return PAM_SYSTEM_ERR;
    }

    if (pamh->former.choice == PAM_NOT_STACKED) {
	_pam_sanitize(pamh);
	_pam_start_timer(pamh);    /* we try to make the time for a failure
				      independent of the time it takes to
				      fail */
    }

    retval = _pam_dispatch(pamh, flags, PAM_AUTHENTICATE);

    if (retval != PAM_INCOMPLETE) {
	_pam_sanitize(pamh);
	_pam_await_timer(pamh, retval);   /* if unsuccessful then wait now */
@@ 48
    return retval;
}
