@@ 53
struct handler {
    int handler_type;
    int (*func)(pam_handle_t *pamh, int flags, int argc, char **argv);
    int actions[_PAM_RETURN_VALUES];
    /* set by authenticate, open_session, chauthtok(1st)
       consumed by setcred, close_session, chauthtok(2nd) */
    int cached_retval; int *cached_retval_p;
    int argc;
    char **argv;
    struct handler *next;
    char *mod_name;
    int stack_level;
    int grantor;
};
@@ 83
struct handlers {
    struct handler *authenticate;
    struct handler *setcred;
    struct handler *acct_mgmt;
    struct handler *open_session;
    struct handler *close_session;
    struct handler *chauthtok;
};

struct service {
    struct loaded_module *module; /* Array of modules */
@@ 98
    struct handlers conf;        /* the configured handlers */
    struct handlers other;       /* the default handlers */
};
