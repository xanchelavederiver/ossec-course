@@ 231
	case _PAM_ACTION_BAD:
	case _PAM_ACTION_DIE:
@@ 240
	    if ( impression != _PAM_NEGATIVE ) {
		impression = _PAM_NEGATIVE;
	        /* Don't return with PAM_IGNORE as status */
		if ( retval == PAM_IGNORE )
		    status = PAM_MUST_FAIL_CODE;
		else
		    status = retval;
	    }
	    if ( action == _PAM_ACTION_DIE ) {
		goto decision_made;
	    }
	    break;

	case _PAM_ACTION_IGNORE:
	    break;
@@ 259
	default:
	    if ( _PAM_ACTION_IS_JUMP(action) ) {
