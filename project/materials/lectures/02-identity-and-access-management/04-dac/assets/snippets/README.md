# Source-code snippets

Verbatim excerpts shown via the `CodeSnippet` component on the slides of
section 3 («Реализация в ядре Linux»). All snippets come from
**Linux v6.18 (LTS)**: sparse clone in `.sources/kernel` (tag `v6.18`);
`include/uapi/linux/stat.h` is outside the sparse checkout and was extracted
with `git show v6.18:include/uapi/linux/stat.h`. Links on the slides point to
`github.com/torvalds/linux/blob/v6.18/…`.

Format: lines are copied from the kernel byte-for-byte; a marker line `@@ <n>`
says the following lines are file lines `<n>, <n+1>, …` (at the top of the file
it only sets the numbering, elsewhere it also renders a `⋯` skip row); a bare
`@@` renders a skip row without renumbering. TCallout coordinates on the slides
are 1-based rows of the shown excerpt (skip rows count) and tab-expanded
(8-cell) columns – recompute them if an excerpt changes.

| Snippet | Source | Lines |
|---|---|---|
| `fs-inode.h` | `include/linux/fs.h` | 793–803 |
| `stat-mode.h` | `include/uapi/linux/stat.h` | 9–19, 29, 34, 39 |
| `namei-generic_permission.c` | `fs/namei.c` | 464–486 |
| `namei-acl_permission_check.c` | `fs/namei.c` | 381–385, 402–407, 409–415, 424–425, 432–440 |
| `namei-may_delete.c` | `fs/namei.c` | 3255–3258, 3272–3283 |
| `namei-vfs_create.c` | `fs/namei.c` | 3477–3484, 3489 |
| `namei-may_create.c` | `fs/namei.c` | 3307–3319 |
| `open-sys_open.c` | `fs/open.c` | 1456–1461 |
| `namei-may_open.c` | `fs/namei.c` | 3527–3529, 3537–3542, 3557–3560, 3563–3577 |
| `namei-link_path_walk.c` | `fs/namei.c` | 2441–2442, 2460–2461, 2466–2469 |
| `namei-may_lookup.c` | `fs/namei.c` | 1852–1858 |

Illustrative fragments that are not verbatim sources stay inline on the slides:
the `ioctl(FS_IOC_GETFLAGS/SETFLAGS)` pseudocode (section 5, `CodeSnippet`
with `code=`) and the two bash excerpts on the «Запуск скрипта» slide.

To (re-)extract a range verbatim:

```sh
{ echo "@@ 381"; sed -n '381,385p' .sources/kernel/fs/namei.c; } >> snippet.c
```
