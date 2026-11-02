@@ 309
    /* Sanity check */
    if ( status == PAM_SUCCESS && impression != _PAM_POSITIVE ) {
	D(("caught on sanity check -- this is probably a config error!"));
	status = PAM_MUST_FAIL_CODE;
    }

    free(substates);
    /* We have made a decision about the modules executed */
    return status;
}
