@@ 3527
static int may_open(struct mnt_idmap *idmap, const struct path *path,
		    int acc_mode, int flag)
{
@@ 3537
	switch (inode->i_mode & S_IFMT) {
	case S_IFLNK:
		return -ELOOP;
	case S_IFDIR:
		if (acc_mode & MAY_WRITE)
			return -EISDIR;
@@ 3557
	case S_IFREG:
		if ((acc_mode & MAY_EXEC) && path_noexec(path))
			return -EACCES;
		break;
@@ 3563
	}

	error = inode_permission(idmap, inode, MAY_OPEN | acc_mode);
	if (error)
		return error;

	/*
	 * An append-only file must be opened in append mode for writing.
	 */
	if (IS_APPEND(inode)) {
		if  ((flag & O_ACCMODE) != O_RDONLY && !(flag & O_APPEND))
			return -EPERM;
		if (flag & O_TRUNC)
			return -EPERM;
	}
