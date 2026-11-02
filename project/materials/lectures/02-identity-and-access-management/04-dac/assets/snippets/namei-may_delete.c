@@ 3255
static int may_delete(struct mnt_idmap *idmap, struct inode *dir,
		      struct dentry *victim, bool isdir)
{
	struct inode *inode = d_backing_inode(victim);
@@ 3272
	audit_inode_child(dir, victim, AUDIT_TYPE_CHILD_DELETE);

	error = inode_permission(idmap, dir, MAY_WRITE | MAY_EXEC);
	if (error)
		return error;
	if (IS_APPEND(dir))
		return -EPERM;

	if (check_sticky(idmap, dir, inode) || IS_APPEND(inode) ||
	    IS_IMMUTABLE(inode) || IS_SWAPFILE(inode) ||
	    HAS_UNMAPPED_ID(idmap, inode))
		return -EPERM;
