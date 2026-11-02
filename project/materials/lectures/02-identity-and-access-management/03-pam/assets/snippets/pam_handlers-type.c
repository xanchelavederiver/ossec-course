@@ 118
		if (tok[0] == '-') { /* do not log module load errors */
		    handler_type = PAM_HT_SILENT_MODULE;
		    ++tok;
		}
		if (!strcasecmp("auth", tok)) {
		    module_type = PAM_T_AUTH;
		} else if (!strcasecmp("session", tok)) {
		    module_type = PAM_T_SESS;
		} else if (!strcasecmp("account", tok)) {
		    module_type = PAM_T_ACCT;
		} else if (!strcasecmp("password", tok)) {
		    module_type = PAM_T_PASS;
		} else {
		    /* Illegal module type */
		    D(("bad module type: %s", tok));
		    pam_syslog(pamh, LOG_ERR, "(%s) illegal module type: %s",
			    this_service, tok);
		    module_type = (requested_module_type != PAM_T_ANY) ?
			    requested_module_type : PAM_T_AUTH;	/* most sensitive */
		    handler_type = PAM_HT_MUST_FAIL; /* install as normal but fail when dispatched */
		}
