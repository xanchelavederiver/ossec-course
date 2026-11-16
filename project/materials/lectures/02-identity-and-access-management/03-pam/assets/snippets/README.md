# Source-code snippets

Verbatim excerpts shown via the `CodeSnippet` component (sections 7–9).
Library snippets come from **Linux-PAM v1.7.0** – the version packaged in
Ubuntu 26.04 (1.7.0-5ubuntu3.2); source tree: sparse clone in
`.sources/linux-pam` (tag `v1.7.0`). Links on the slides point to
`github.com/linux-pam/linux-pam/blob/v1.7.0/…`. Snippets of the lecture's own
programs are cut from `assets/src/authprint.c` (demo 08) and
`assets/src/pam_math.c` (demo 09).

Format: lines are copied byte-for-byte; a marker line `@@ <n>` says the
following lines are file lines `<n>, <n+1>, …` (at the top of the file it only
sets the numbering, elsewhere it also renders a `⋯` skip row). Linux-PAM mixes
4-space indents with 8-column tabs – keep the default `tabSize` 8. TCallout
coordinates on the slides are 1-based rows of the shown excerpt (skip rows
count) and tab-expanded columns – recompute them if an excerpt changes.

| Snippet | Source | Lines |
|---|---|---|
| `sudo-pam-service.c` | sudo v1.9.17p2 `plugins/sudoers/auth/pam.c` (GitHub, tag `v1.9.17p2`) | 195–197, 219–226 |
| `sudo-rs-pam-service.rs` | sudo-rs v0.2.13 `src/sudo/pam.rs` (GitHub, tag `v0.2.13`) | 41–44 |
| `pam_appl-start.h` | `libpam/include/security/pam_appl.h` | 22–25, 32–33 |
| `pam_types-conv.h` | `libpam/include/security/_pam_types.h` | 254–257, 279–290 |
| `pam_modules-sm.h` | `libpam/include/security/pam_modules.h` | 34–35 |
| `authprint-start.c` | `assets/src/authprint.c` | 12–13, 22–43 |
| `authprint-end.c` | `assets/src/authprint.c` | 45–62 |
| `pam_math-auth1.c` | `assets/src/pam_math.c` | 15–16, 25–31, 35–38, 42–50 |
| `pam_math-auth2.c` | `assets/src/pam_math.c` | 52–70, 74–79 |
| `pam_private-handle.h` | `libpam/pam_private.h` | 153–173, 183 |
| `pam_private-handler.h` | `libpam/pam_private.h` | 53–66, 83–93, 98–100 |
| `pam_private-actions.h` | `libpam/pam_private.h` | 194–200 |
| `pam_private-config.h` | `libpam/pam_private.h` | 28–32 |
| `pam_handlers-open.c` | `libpam/pam_handlers.c` | 292–298, 302, 333, 335, 342–347, 351–352 |
| `pam_handlers-type.c` | `libpam/pam_handlers.c` | 118–138 |
| `pam_handlers-control.c` | `libpam/pam_handlers.c` | 163–184, 193–198 |
| `pam_handlers-load.c` | `libpam/pam_handlers.c` | 604–605, 616–621, 643, 678–681 |
| `pam_handlers-sym.c` | `libpam/pam_handlers.c` | 759–765, 798–801 |
| `pam_auth-authenticate.c` | `libpam/pam_auth.c` | 14–15, 22–38, 48–49 |
| `pam_dispatch-select.c` | `libpam/pam_dispatch.c` | 334, 349–359, 364–366, 383–388 |
| `pam_dispatch-loop.c` | `libpam/pam_dispatch.c` | 34–35, 42, 49–50, 72–73, 79, 96–98, 102–110, 174, 194 |
| `pam_dispatch-ok.c` | `libpam/pam_dispatch.c` | 201, 208–229 |
| `pam_dispatch-bad.c` | `libpam/pam_dispatch.c` | 231–232, 240–254, 259–260 |
| `pam_dispatch-sanity.c` | `libpam/pam_dispatch.c` | 309–318 |
| `pam_get_authtok-first.c` | `libpam/pam_get_authtok.c` | 82–84, 119–137 (section 3.3: a cached PAM_AUTHTOK is reused, `use_first_pass` forbids prompting) |

Text snippets (rendered with `lang="text"`, no line numbers):

| Snippet | Source |
|---|---|
| `auth-log-listfile.txt` | syslog record of demo 08 (`assets/captures/11-authprint.txt`), wrapped for the slide |
| `pam-conf-controls.txt` | `doc/man/pam.conf-syntax.xml`, lines 349–377: short control flags and their bracket forms |
| `sag-other.conf` | `doc/sag/Linux-PAM_SAG.xml`, lines 359–369: conservative `/etc/pam.d/other` |

Illustrative configuration fragments for section 2 (not copied from a system;
written for the slides after pam.conf(5)/pam.d(5) and the Linux-PAM SAG):

| Snippet | Shown on |
|---|---|
| `ex-pamconf.txt`, `ex-pamd-files.txt` | rule format: `/etc/pam.conf` line vs. per-service files |
| `ex-syntax.txt` | syntax details: comments, continuation, `[...]` argument grouping, leading hyphen |
| `ex-types.txt` | one stack per management type, `required` only – the types and their purpose, not the flags |
| `ex-include-typed.txt` | `/etc/pam.d/other` of Ubuntu 26.04 rewritten with typed `include` lines – slide «Две формы include» |
| `ex-stack.txt` | a four-rule auth stack |
| `ex-flags.txt` | required / requisite / sufficient / optional examples |
| `ex-ext-syntax.txt`, `ex-ext-actions.txt`, `ex-default.txt` | extended control syntax: namespaces, actions, default matching, exact equivalents |
| `ex-include-parent.txt`, `ex-include-child.txt`, `ex-include-effective.txt` | `include` expansion |
| `ex-substack-include.txt`, `ex-substack-substack.txt` | `include` vs `substack` boundary |
| `ex-two-layers.txt` | PAM rule vs. module file (`faillock.conf`) |

Illustrative module examples for section 3.1 (one per module slide; written for the
slides after the Linux-PAM 1.7.0 man pages, rule lines of `login`/`sshd`/`common-*`
as in Ubuntu 26.04):

| Snippet | Shown on |
|---|---|
| `mod-unix.txt` | `pam_unix` in the four `common-*` stacks (arguments by type) |
| `mod-permit-deny.txt` | `pam_deny` closing a stack and the `other` service, `pam_permit` priming a stack |
| `mod-faillock.txt` | `preauth` / `authfail` / `authsucc` scheme (pam_faillock(8) example) + `faillock.conf` |
| `mod-nologin.txt` | `pam_nologin` in auth (`login`) and account (`sshd`), `file=` |
| `mod-access.txt` | `pam_access` rule and an allow-list `access.conf` |
| `mod-listfile.txt` | deny list and allow list with `pam_listfile` |
| `mod-time.txt` | `pam_time` rule and `time.conf` entries |
| `mod-limits.txt` | `pam_limits` rule and `limits.conf` entries |
