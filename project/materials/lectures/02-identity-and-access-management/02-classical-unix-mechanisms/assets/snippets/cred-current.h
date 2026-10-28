@@ 352
#define current_cred_xxx(xxx)			\
({						\
	current_cred()->xxx;			\
})

#define current_uid()		(current_cred_xxx(uid))
@@ 359
#define current_euid()		(current_cred_xxx(euid))
@@ 363
#define current_fsuid() 	(current_cred_xxx(fsuid))
