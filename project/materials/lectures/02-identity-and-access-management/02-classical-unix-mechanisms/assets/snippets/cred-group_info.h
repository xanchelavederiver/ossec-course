@@ 23
/*
 * COW Supplementary groups list
 */
struct group_info {
	refcount_t	usage;
	int		ngroups;
	kgid_t		gid[];
} __randomize_layout;
