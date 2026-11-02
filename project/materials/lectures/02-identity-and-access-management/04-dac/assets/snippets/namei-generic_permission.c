@@ 464
int generic_permission(struct mnt_idmap *idmap, struct inode *inode,
		       int mask)
{
	int ret;

	/*
	 * Do the basic permission checks.
	 */
	ret = acl_permission_check(idmap, inode, mask);
	if (ret != -EACCES)
		return ret;

	if (S_ISDIR(inode->i_mode)) {
		/* DACs are overridable for directories */
		if (!(mask & MAY_WRITE))
			if (capable_wrt_inode_uidgid(idmap, inode,
						     CAP_DAC_READ_SEARCH))
				return 0;
		if (capable_wrt_inode_uidgid(idmap, inode,
					     CAP_DAC_OVERRIDE))
			return 0;
		return -EACCES;
	}
