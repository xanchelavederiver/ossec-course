@@ 2441
static int link_path_walk(const char *name, struct nameidata *nd)
{
@@ 2460
	/* At this point we know we have a real path component. */
	for(;;) {
@@ 2466
		idmap = mnt_idmap(nd->path.mnt);
		err = may_lookup(idmap, nd);
		if (unlikely(err))
			return err;
