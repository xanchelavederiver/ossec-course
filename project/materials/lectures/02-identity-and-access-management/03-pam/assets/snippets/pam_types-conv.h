@@ 254
struct pam_message {
    int msg_style;
    const char *msg;
};
@@ 279
struct pam_response {
    char *resp;
    int	resp_retcode;	/* currently un-used, zero expected */
};

/* The actual conversation structure itself */

struct pam_conv {
    int (*conv)(int num_msg, const struct pam_message **msg,
		struct pam_response **resp, void *appdata_ptr);
    void *appdata_ptr;
};
