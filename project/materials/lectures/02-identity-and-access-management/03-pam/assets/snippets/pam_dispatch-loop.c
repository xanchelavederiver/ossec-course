@@ 34
static int _pam_dispatch_aux(pam_handle_t *pamh, int flags, struct handler *h,
			     _pam_boolean resumed, int use_cached_chain)
@@ 42
    if (h == NULL) {
@@ 49
	return PAM_MUST_FAIL_CODE;
    }
@@ 72
	substates[0].impression = impression = _PAM_UNDEF;
	substates[0].status = status = PAM_MUST_FAIL_CODE;
@@ 79
    for (depth=0 ; h != NULL ; prev_level = stack_level, h = h->next, ++depth) {
@@ 96
	if (h->handler_type == PAM_HT_MUST_FAIL) {
	    D(("module poorly listed in PAM config; forcing failure"));
	    retval = PAM_MUST_FAIL_CODE;
@@ 102
	} else if (h->func == NULL) {
	    D(("module function is not defined, indicating failure"));
	    retval = PAM_MODULE_UNKNOWN;
	} else {
	    D(("passing control to module..."));
	    pamh->mod_name=h->mod_name;
	    pamh->mod_argc = h->argc;
	    pamh->mod_argv = h->argv;
	    retval = h->func(pamh, flags, h->argc, h->argv);
@@ 174
	    cached_retval = h->cached_retval = retval;
@@ 194
	    action = h->actions[cached_retval];
