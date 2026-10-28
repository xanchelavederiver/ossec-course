@@ 290
int copy_creds(struct task_struct *p, u64 clone_flags)
{
	struct cred *new;
	int ret;
@@ 299
	if (
#ifdef CONFIG_KEYS
		!p->cred->thread_keyring &&
#endif
		clone_flags & CLONE_THREAD
	    ) {
		p->real_cred = get_cred_many(p->cred, 2);
@@ 309
		return 0;
	}

	new = prepare_creds();
	if (!new)
		return -ENOMEM;
@@ 344
	p->cred = p->real_cred = get_cred(new);
@@
