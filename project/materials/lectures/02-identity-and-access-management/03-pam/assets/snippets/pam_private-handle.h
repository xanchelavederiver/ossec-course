@@ 153
struct pam_handle {
    char *authtok;
    unsigned caller_is;
    struct pam_conv *pam_conversation;
    char *oldauthtok;
    char *prompt;                /* for use by pam_get_user() */
    char *service_name;
    char *user;
    char *rhost;
    char *ruser;
    char *tty;
    char *xdisplay;
    char *authtok_type;          /* PAM_AUTHTOK_TYPE */
    struct pam_data *data;
    struct pam_environ *env;      /* structure to maintain environment list */
    struct _pam_fail_delay fail_delay;   /* helper function for easy delays */
    struct pam_xauth_data xauth;        /* auth info for X display */
    struct service handlers;
    struct _pam_former_state former;  /* library state - support for
					 event driven applications */
    const char *mod_name;	/* Name of the module currently executed */
@@ 183
};
