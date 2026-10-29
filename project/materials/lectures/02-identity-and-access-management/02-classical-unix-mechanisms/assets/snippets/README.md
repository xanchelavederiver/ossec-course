# Source-code snippets

Verbatim excerpts shown via the `CodeSnippet` component. Kernel snippets come
from **Linux v6.18 (LTS)** («Исходный код ядра» slides); section-5 snippets
come from **glibc 2.43**, **libxcrypt v4.5.1**, **shadow 4.17.4** and the
lecture's own demo programs. Source trees: sparse clones in `.sources/kernel`
(tag `v6.18`), `.sources/glibc` (tag `glibc-2.43`, cloned from
sourceware.org), `.sources/libxcrypt` (tag `v4.5.1`), `.sources/shadow`
(tag `4.17.4`). Links on the slides point to `github.com/torvalds/linux`,
sourceware.org gitweb (glibc), `github.com/besser82/libxcrypt` and
`github.com/shadow-maint/shadow` respectively.

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

Section 5 (идентификация и аутентификация в приложениях):

| Snippet | Source | Lines |
|---|---|---|
| `pwd-struct.h` | glibc `nss/pwd.h` | 48–59 |
| `pwd-lookup.h` | glibc `nss/pwd.h` | 110, 116 |
| `pwd-enum.h` | glibc `nss/pwd.h` | 72, 78, 84 |
| `grp-struct.h` | glibc `nss/grp.h` | 41–48 |
| `grp-lookup.h` | glibc `nss/grp.h` | 101, 107 |
| `grp-enum.h` | glibc `nss/grp.h` | 61, 67, 73 |
| `spwd-struct.h` | glibc `nss/shadow.h` | 42–57 |
| `spwd-lookup.h` | glibc `nss/shadow.h` | 90 |
| `spwd-enum.h` | glibc `nss/shadow.h` | 66, 74, 82 |
| `unistd-getpass.h` | glibc `posix/unistd.h` | 979–981 |
| `crypt-proto.h` | libxcrypt `lib/crypt.h.in` | 44–50, 57–62 |
| `login-user-lookup.c` | shadow `src/login.c` | 847–862 |
| `login-shadow-auth.c` | shadow `src/login.c` | 879–883, 891–892, 902–908 |
| `pwauth-pw_auth.c` | shadow `lib/pwauth.c` | 51–53, 76–78, 114–116, 125–130, 157–160 |
| `encrypt-pw_encrypt.c` | shadow `lib/encrypt.c` | 21–27, 33–34 |
| `myname-get_my_pwent.c` | shadow `lib/myname.c` | 25–29, 41–45, 51–52 |
| `passwd-target.c` | shadow `src/passwd.c` | 757, 904, 913–914, 919–922, 1007–1011, 1019–1020 |
| `passwd-pw_status.c` | shadow `src/passwd.c` | 439–448 |
| `passwd-print_status.c` | shadow `src/passwd.c` | 453–468 |
| `passwd-lock.c` | shadow `src/passwd.c` | 510, 534–537, 544–547 |
| `passwd-old-verify.c` | shadow `src/passwd.c` | 178, 197–198, 203, 216, 221–226 |
| `passwd-new-hash.c` | shadow `src/passwd.c` | 353–358, 367–368 |
| `passwd-update_shadow.c` | shadow `src/passwd.c` | 604, 623, 638, 642, 657–658 |
| `demo10-main.c` | `../demos/10-enum-accounts.c` | 28–42 |
| `demo10-supp.c` | `../demos/10-enum-accounts.c` | 10–26 |
| `demo11-lookup.c` | `../demos/11-password-auth.c` | 25–38 |
| `demo11-verify.c` | `../demos/11-password-auth.c` | 40–56 |

To (re-)extract a range verbatim:

```sh
{ echo "@@ 381"; sed -n '381,385p' .sources/kernel/fs/namei.c; } >> snippet.c
```
