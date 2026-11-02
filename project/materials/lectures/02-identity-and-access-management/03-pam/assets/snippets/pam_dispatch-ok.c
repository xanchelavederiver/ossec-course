@@ 201
	switch (action) {
@@ 208
	case _PAM_ACTION_OK:
	case _PAM_ACTION_DONE:

	    if ( impression == _PAM_UNDEF
		 || (impression == _PAM_POSITIVE && status == PAM_SUCCESS) ) {
                /* in case of using cached chain
                   we could get here with PAM_IGNORE - don't return it */
                if ( retval != PAM_IGNORE || cached_retval == retval ) {
		    impression = _PAM_POSITIVE;
                    status = retval;
                }
	    }
	    if ( impression == _PAM_POSITIVE ) {
		if ( retval == PAM_SUCCESS ) {
		    h->grantor = 1;
		}

		if ( action == _PAM_ACTION_DONE ) {
		    goto decision_made;
		}
	    }
	    break;
