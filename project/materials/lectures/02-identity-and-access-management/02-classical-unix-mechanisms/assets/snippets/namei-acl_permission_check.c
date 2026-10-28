@@ 381
static int acl_permission_check(struct mnt_idmap *idmap,
				struct inode *inode, int mask)
{
	unsigned int mode = inode->i_mode;
	vfsuid_t vfsuid;
@@ 409
	/* Are we the owner? If so, ACL's don't matter */
	vfsuid = i_uid_into_vfsuid(idmap, inode);
	if (likely(vfsuid_eq_kuid(vfsuid, current_fsuid()))) {
		mask &= 7;
		mode >>= 6;
		return (mask & ~mode) ? -EACCES : 0;
	}
@@ 424
	/* Only RWX matters for group/other mode bits */
	mask &= 7;
@@ 432
	if (mask & (mode ^ (mode >> 3))) {
		vfsgid_t vfsgid = i_gid_into_vfsgid(idmap, inode);
		if (vfsgid_in_group_p(vfsgid))
			mode >>= 3;
	}

	/* Bits in 'mode' clear that we require? */
	return (mask & ~mode) ? -EACCES : 0;
}
