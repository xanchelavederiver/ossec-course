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

Text snippets (rendered with `lang="text"`, no line numbers):

| Snippet | Source |
|---|---|
| `auth-log-listfile.txt` | syslog record of demo 08 (`assets/captures/11-authprint.txt`), wrapped for the slide |
| `pam-conf-controls.txt` | `doc/man/pam.conf-syntax.xml`, lines 349–377: short control flags and their bracket forms |
| `sag-other.conf` | `doc/sag/Linux-PAM_SAG.xml`, lines 359–369: conservative `/etc/pam.d/other` |
