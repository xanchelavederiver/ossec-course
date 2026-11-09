@@ 82
pam_get_authtok_internal (pam_handle_t *pamh, int item,
			  const char **authtok, const char *prompt,
			  unsigned int flags)
@@ 119
  retval = pam_get_item (pamh, item, &prevauthtok);
  if (retval == PAM_SUCCESS && prevauthtok != NULL)
    {
      *authtok = prevauthtok;
      return PAM_SUCCESS;
    }
  else if (get_option (pamh, "use_first_pass") ||
	   (chpass && get_option (pamh, "use_authtok")))
    {
      if (prevauthtok == NULL)
	{
	  if (chpass)
	    return PAM_AUTHTOK_ERR;
	  else
	    return PAM_AUTH_ERR;
	}
      else
	return retval;
    }
