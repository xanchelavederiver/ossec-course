@@ 3307
static inline int may_create(struct mnt_idmap *idmap,
			     struct inode *dir, struct dentry *child)
{
	audit_inode_child(dir, child, AUDIT_TYPE_CHILD_CREATE);
	if (child->d_inode)
		return -EEXIST;
	if (IS_DEADDIR(dir))
		return -ENOENT;
	if (!fsuidgid_has_mapping(dir->i_sb, idmap))
		return -EOVERFLOW;

	return inode_permission(idmap, dir, MAY_WRITE | MAY_EXEC);
}
