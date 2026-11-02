@@ 22
extern int PAM_NONNULL((1,3,4))
pam_start(const char *service_name, const char *user,
	  const struct pam_conv *pam_conversation,
	  pam_handle_t **pamh);
@@ 32
extern int PAM_NONNULL((1))
pam_end(pam_handle_t *pamh, int pam_status);
