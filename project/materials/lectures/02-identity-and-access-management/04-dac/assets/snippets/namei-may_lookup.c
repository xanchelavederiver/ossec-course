@@ 1852
static inline int may_lookup(struct mnt_idmap *idmap,
			     struct nameidata *restrict nd)
{
	int err, mask;

	mask = nd->flags & LOOKUP_RCU ? MAY_NOT_BLOCK : 0;
	err = inode_permission(idmap, nd->inode, mask | MAY_EXEC);
