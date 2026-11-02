@@ 292
static int
_pam_open_config_file(pam_handle_t *pamh
			, const char *service
			, char **path
			, FILE **file)
{
    const char *const pamd_dirs[] = { PAM_CONFIG_DF, PAM_CONFIG_DIST_DF
@@ 302
    };
@@ 333
    for (i = 0; i < PAM_ARRAY_SIZE(pamd_dirs); i++) {
@@ 335
	if (asprintf (&p, pamd_dirs[i], service) < 0) {
@@ 342
	f = fopen(p, "r");
	if (f != NULL) {
	    *path = p;
	    *file = f;
	    return PAM_SUCCESS;
	}
@@ 351
    return PAM_ABORT;
}
