@@ 1926
__latent_entropy struct task_struct *copy_process(
					struct pid *pid,
					int trace,
					int node,
					struct kernel_clone_args *args)
{
@@ 2046
	retval = copy_creds(p, clone_flags);
	if (retval < 0)
		goto bad_fork_free;
@@
