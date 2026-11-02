@@ 3477
int vfs_create(struct mnt_idmap *idmap, struct inode *dir,
	       struct dentry *dentry, umode_t mode, bool want_excl)
{
	int error;

	error = may_create(idmap, dir, dentry);
	if (error)
		return error;
@@ 3489
	mode = vfs_prepare_mode(idmap, dir, mode, S_IALLUGO, S_IFREG);
