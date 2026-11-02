@@ 163
	    } else if (!strcasecmp("required", tok)) {
		D(("*PAM_F_REQUIRED*"));
		actions[PAM_SUCCESS] = _PAM_ACTION_OK;
		actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_OK;
                actions[PAM_IGNORE] = _PAM_ACTION_IGNORE;
		_pam_set_default_control(actions, _PAM_ACTION_BAD);
	    } else if (!strcasecmp("requisite", tok)) {
		D(("*PAM_F_REQUISITE*"));
		actions[PAM_SUCCESS] = _PAM_ACTION_OK;
		actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_OK;
                actions[PAM_IGNORE] = _PAM_ACTION_IGNORE;
		_pam_set_default_control(actions, _PAM_ACTION_DIE);
	    } else if (!strcasecmp("optional", tok)) {
		D(("*PAM_F_OPTIONAL*"));
		actions[PAM_SUCCESS] = _PAM_ACTION_OK;
		actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_OK;
		_pam_set_default_control(actions, _PAM_ACTION_IGNORE);
	    } else if (!strcasecmp("sufficient", tok)) {
		D(("*PAM_F_SUFFICIENT*"));
		actions[PAM_SUCCESS] = _PAM_ACTION_DONE;
		actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_DONE;
		_pam_set_default_control(actions, _PAM_ACTION_IGNORE);
@@ 193
	    } else {
		D(("will need to parse %s", tok));
		_pam_parse_control(actions, tok);
		/* by default the default is to treat as failure */
		_pam_set_default_control(actions, _PAM_ACTION_BAD);
	    }
