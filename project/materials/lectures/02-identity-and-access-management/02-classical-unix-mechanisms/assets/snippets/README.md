# Kernel source snippets

Verbatim excerpts from **Linux v6.18 (LTS)** shown on the «Исходный код ядра»
slides via the `CodeSnippet` component. Source tree: the sparse clone in
`.sources/kernel` (tag `v6.18`); GitHub links on the slides point to
`github.com/torvalds/linux/blob/v6.18/...`.

Format: lines are copied from the kernel byte-for-byte; a marker line `@@ <n>`
says the following lines are file lines `<n>, <n+1>, …` (at the top of the file
it only sets the numbering, elsewhere it also renders a `⋯` skip row); a bare
`@@` renders a skip row without renumbering. TCallout coordinates on the slides
are 1-based rows of the shown excerpt (skip rows count) and tab-expanded
(8-cell) columns — recompute them if an excerpt changes.

| Snippet | Source | Lines |
|---|---|---|
| `uidgid_types.h` | `include/linux/uidgid_types.h` | 7–13 |
| `cred-group_info.h` | `include/linux/cred.h` | 23–30 |
| `cred-struct.h` | `include/linux/cred.h` | 111–120, 141, 147 |
| `cred-current.h` | `include/linux/cred.h` | 352–357, 359, 363 |
| `sys-getuid.c` | `kernel/sys.c` | 1027–1037 |
| `namei-acl_permission_check.c` | `fs/namei.c` | 381–385, 409–415, 424–425, 432–440 |
| `fork-copy_process.c` | `kernel/fork.c` | 1926–1931, 2046–2048 |
| `cred-prepare_creds.c` | `kernel/cred.c` | 206–210, 218–219 |
| `cred-copy_creds.c` | `kernel/cred.c` | 290–293, 299–305, 309–314, 344 |
| `exec-bprm_fill_uid.c` | `fs/exec.c` | 1534–1540, 1544–1552, 1561, 1575–1578, 1584 |
| `commoncap-fix-ids.c` | `security/commoncap.c` | 953–954 |

To (re-)extract a range verbatim:

```sh
{ echo "@@ 381"; sed -n '381,385p' .sources/kernel/fs/namei.c; } >> snippet.c
```
