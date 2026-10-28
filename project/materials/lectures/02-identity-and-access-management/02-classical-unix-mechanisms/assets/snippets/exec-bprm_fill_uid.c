@@ 1534
static void bprm_fill_uid(struct linux_binprm *bprm, struct file *file)
{
	/* Handle suid and sgid on files */
	struct mnt_idmap *idmap;
	struct inode *inode = file_inode(file);
	unsigned int mode;
	vfsuid_t vfsuid;
@@ 1544
	if (!mnt_may_suid(file->f_path.mnt))
		return;

	if (task_no_new_privs(current))
		return;

	mode = READ_ONCE(inode->i_mode);
	if (!(mode & (S_ISUID|S_ISGID)))
		return;
@@ 1561
	vfsuid = i_uid_into_vfsuid(idmap, inode);
@@ 1575
	if (mode & S_ISUID) {
		bprm->per_clear |= PER_CLEAR_ON_SETID;
		bprm->cred->euid = vfsuid_into_kuid(vfsuid);
	}
@@ 1584
}
