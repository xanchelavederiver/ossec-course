@@ 206
struct cred *prepare_creds(void)
{
	struct task_struct *task = current;
	const struct cred *old;
	struct cred *new;
@@ 218
	old = task->cred;
	memcpy(new, old, sizeof(struct cred));
@@
