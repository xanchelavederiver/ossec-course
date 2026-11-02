@@ 604
static struct loaded_module *
_pam_load_module(pam_handle_t *pamh, const char *mod_path, int handler_type)
@@ 616
    while (x < pamh->handlers.modules_used) {
	if (!strcmp(mod[x].name, mod_path)) {  /* case sensitive ! */
	    break;
	}
	x++;
    }
@@ 643
	mod->dl_handle = _pam_dlopen(mod_path);
@@ 678
	if (success != PAM_SUCCESS) {	         /* add a malformed module */
	    mod->dl_handle = NULL;
	    mod->type = PAM_MT_FAULTY_MOD;
	    pamh->handlers.modules_used++;
