update lecture slides `02-identity-and-access-management/02-classical-unix-mechanisms`:

1. remove slide #2
2. make section 1 - `Введение`:
   - slide 1: copy slide 3 `Управление идентификацией и доступом: основные понятия` + IAM definition in the beginning
   - slide 2: copy slide 5 `Монитор обращений: куда встроены механизмы защиты`
3. make section 3 - `Идентификация`:
    - copy slide 4 `Субъекты и объекты в Linux`, move `«Дочерний процесс, созданный fork(2), наследует копии идентификаторов пользователя и групп родителя» — credentials(7).` to the next section
    - copy slides 6-10
   - add subsection dedicated to process IDs handling
     * describe processes' UID / EUID / SUID / FSUID (and analogous to group-) values
     * demo: example with `/proc` - how to get ID values for programs
     * forking and the UIDs: why SUID/SGID are necessary, the inheritance rules
     * demos: examples of inheritance with various edge cases
     * section `kernel source` - show code snippets from the Linux kernel:
       ** definition of process' UIDs / GIUs in kernel
       ** code snippet of selecting effective user ID, example of this function's usage
       ** code snippet that defines process' IDs inheritance during fork


**IMPORTANT**:

1. the source of slides 3-10 is `../dpo/decks/02-identification-authentication`
2. keep the general outline of the source slides
3. use latest Linux LTS version, add links to github - source files with a starting line pinned
4. if necessary, it's OK to fetch the kernel's source code locally (place it in gitignored `.sources/kernel`)
5. show the kernel code snippets with syntax coloring, comments (reference source lines with callouts)

---

1. reserve slide 2 for `План лекции`, keep it empty for now (it'll be filled in at the end)
2. make section `1. Введение`:
   - section title slide - slide 3 (copy from old slides)
   - slide 4 (copy from old slides):
   - slide 5 (copy from old slides)
   - slide 6 (copy from old slides) + enrich the history review
3. make section `2. Идентификация`
   - section title slide:
     * make it ins the style of section caption with list of its (sub)sections:
       ** Субъекты и объекты
       ** Файл паролей /etc/passwd
       ** Файл групп /etc/group
       ** Идентификаторы процесса
     * the first subsection is shown as usual, the others are greyed out; along the section it will be shown before the next subsection with this subsection being highlighted and the others greyed out
   - slide 9 (copy from old slides):
     * replace `в теме3` -> `в лекции 3`
     * show more examples of Linux objects that have file interface (i.e. are viewed as files)
     * show the terminal output using the project's special terminal output object (with coloring)
   - slide 10 (copy from old slides):
     * replace `в теме3` -> `в лекции 3`
     * update references to sections 2.1 and 2.2 -> 2.2 and 2.3
   - slide 11 (copy from old slides):
     ** `Диапазоны UID — Debian Policy, п. 9.2.2 (показаны основные); Ubuntu наследует их, границы обычных пользователей — ...` - align left
     ** terminal output with coloring
     ** copy command card `Команда id` style from slide 7 of `../dpo/decks/02-identification-authentication` - use it here (as Vue object?)
     ** copy the terminal example from this slide 7 as well (replacing ivanov with bob); keep the coloring
   - slide 12 (copy from old slides):
     * create Vue object to match the style of blocks `Первичная группа` and `Вторичные (дополнительные) группы` of `../dpo/decks/02-identification-authentication`
     * update the rendering of these blocks
     * update explanations block:
       ** remove `Соответствующие строки файлов...` sentence
       ** arrange the facts into a list
     * update the terminal:
       ** make the terminal wider and taller to provide space for the callouts and remove the scrollbar
       ** fix markups over the terminal: currently two rectangles are drawn around `gid=...` and `4(adm)...` - make it one border
       **N.B.** the same fix applies to every other markup
     * actually, copy the example (update for different users) and the explanation from slide 8 of `../dpo/decks/02-identification-authentication` - show several users with different group memberships; don't use markups over the terminal in this example - asciidoctor's callouts (numbered balls) is an option
   - other sections to be added later
3. make section references - this will be the last one


additionally, apply to the whole presentation the following rules:

- man pages references (e.g. `capabilities(7)`) are also links that follow to the respective man pages
- slide numbers in lower right corner
- small `References` block at the very bottom of each slide, referencing exactly the sources for this slide (except demo slides) - analogous to style of the slides in `../dpo/decks/02-identification-authentication`; also make this `[42]` links be clickable - on click move to the references page and mark the source item

---

slide 7:
  - move title up
  - make the subsections titles larger
  - 2.1 should be the same size as the other numbers

slide 8:
  - remove clicks
  - merge two terminal outputs into one
  - enumerate typical OS object types in a list, not in a row
  - if necessary: enlarge the diagram a little to take more space and make the two sides of the slide relatively the same size
  - if necessary: remove some special fiels/folders (`/bin/`, `/tmp`) from the first example to save some space to the second example
  - use `Ubuntu Server 26.04 ·` in the terminal title - as in the other terminals

slide 9:
  - remove clicks
  - match the style of the two diagrams to the style of the diagram on slide 8

slide 10:
  - remove `подразделы 2.2 и 2.3` in `Команда id`

slide 11:
  - callouts alone don't localize the point of interese within the line, let's use a rectangle with rounded corners and a number - kind of localized callout; **IMPORTANT**: try to find a standard / commonly used element that does this and is fairly well-known


general:
  - left-align the references
  - make the slide's text selectable with a mouse

---

1. add slide 19 (copy from old slides) after the current slide 10 (`UID и GID ...`):
   - make the table's style so that it has borders and its header is distinctive enough
   - add more relevant examples of (currently present) special users
2. mention pseudo-users on the current slide 9 (to be discussed in section 2.2)
3. create subsection `2.2 Файл паролей /etc/passwd`
   - subsection title with `** Файл паролей /etc/passwd` in black and the others greyed out
   - slide 14 (copy from old slides):
     * first give this file's definition: what is it, what is it for
     * then describe the file format properly - more verbose the it is now
     * then the block that shows one line break down - use wordings from slide 9 in `../dpo/decks/02-identification-authentication`
     * then copy `Поле 2` explanation block and a terminal output example - also from slide 9 in `../dpo/decks/02-identification-authentication`
   - slide 18 (copy from old slides):
     * rename slide `Пример /etc/passwd`
     * show `/etc/passwd` in terminal - as output of `cat /etc/passwd` command
     * show several "human" users
     * break down the example - name these human users, the root user, some system-users **and some pseudo-users**
   - slide 20 (copy from old slides):
     * change the style of the table accordingly; decrease the table's text font size
     * make a linkage-phrase that explains that the table shows the typical means of creating pseudo-users
     * in the second column give more verbose explanations with concrete examples - how the means is used to create a pseudo-user
     * remove terminal output and the comments below
   - slide 16 (copy from old slides):
     * show terminal output using the project's terminal object
     * outline two problems:
       ** plain-text password - obvious password leakage; give the 1966 CTSS example here - with more details, the slide's space allows it
       ** hashes are also bad idea - Morris warm, similarly tell a story, not just give a reference
   - slide 21 (copy from old slides)

---

slides 7, 13:
  - make subsections titles larger - increase font size

slide 18:
  - in the example first show the alice's original line and id output - e.g. in the first terminal
  - then show the change and the id output - e.g. in the second terminal
  - use the outline element from slide 15 - rectangle with number (what is its name? how do I refer to it?) - to break down the example with detailed comments
  - make a conclusion: no write access for regular users
  - rename `01-passwd-uid-zero.sh` -> `demos/01-passwd-uid-zero.sh`; reference it only, don't explain (e.g. `See `demos/01-passwd-uid-zero.sh``)

generic updates:
  - make text sizes uniform on the slides - the main text should be of the defined size unless it is required to make it bigger/smaller on a particular size; also use black for the main text

---

create subsection `2.3 Файл групп /etc/group`:

1. slide 10 in `../dpo/decks/02-identification-authentication`
   - update for this project's Ubuntu image
   - first give this file's definition: what is it, what is it for; then describe the file format properly
2. slide 25 (copy from old slides):
   - update the breakdown similarly to the current slide 18
   - increase the terminal's size to get rid of the scrollbar
   - rename `02-group-membership.sh` -> `demos/02-group-membership.sh`; reference it only, don't explain (e.g. `See `demos/02-group-membership.sh``)

---

create subsection `2.4 Идентификаторы процесса:

1. subsection title slide
2. slide 29 (copy from old slides):
   - replace `Роль` -> `Назначение`
   - update table formatting and style, update links and references style
   - remove clicks
3. slides 30-31 (copy from old slides):
   - update the formatting to match this project's (e.g. slide 18, numbered rectangle as callout with detailed explanations)
   - make a detailed break down of these demos
   - name the demo `03-{name}`, reference this file on the slides

4. add a couple of slides that discuss:
   - syscalls to change processes IDs
   - secure programming concept
   - suid and slide 32 (update from old slides):
     * update table formatting
     * remove clicks
     * make clear description of actions in the table cells, currently they are not
     * update references
     * show the inheritance rules as an algorithm (Kerris Linux book contains it if I recall correctly); place the table on the right of the algorithm
     * `Зачем saved UID` -> `Назначение saved UID`; move this to the tup of the slide
     * `Событие` -> `Действие`
6. slides 33-35 (copy from old slides):
   - update using the project's styles and elements
   - add detailed descriptions of each step
   - analyze `.sources/misc/03_resids_output_ids.c`, identify potentially valuable example (not covered by `idprobe`) and add if there is any such valuable example

---

create subsection `2.5 Реализация в ядре Linux`: slides 36-39 (copy from old slides)

---

write section 3 of 2nd lecture

section 3 structure:

3.1 `Парольная аутентификация - исторический экскурс`
3.2 `Теневой файл паролей `/etc/shadow`` и групп `/etc/gshadow`
3.3 `Хеширование пароля`
3.4 `Парольная политика`


subsection `3.1 Парольная аутентификация - исторический экскурс`:
- remove `Исторический экскурс · CTSS, 1966` from slide 17
- make a detailed password authentication history review based on `.tmp/history_of_os_password_authentication.pdf`, sections 1-4

subsection 3.2 `Теневой файл паролей `/etc/shadow` и групп `/etc/gshadow``
- detailed description of the structure of `/etc/shadow` (based on slide 16 from `../dpo/decks/02-identification-authentication`)
- detailed description of the structure of `/etc/gshadow` (based on slide 17 from `../dpo/decks/02-identification-authentication`)
- access rights to `/etc/shadow` and `/etc/gshadow`
- example of typical `/etc/shadow` and `/etc/gshadow` from Ubuntu 26.04

subsection `3.3 Хеширование пароля`:
- generic principles of applying one-way hash functions to password verification (integrate slide 13 from `../dpo/decks/02-identification-authentication`)
- detailed description of salt mechanism
- hash algorithms evolution - based on:
  * slide 15 from `../dpo/decks/02-identification-authentication`
  * section 6 from `.tmp/history_of_os_password_authentication.pdf`
- detailed description of the salted hash format used in `/etc/[g]shadow` (similar to slide 46 from the old presentation)
- detailed verbousely-explained demos:
  * no salt / fixed salt - the same hash for the same pass
  * with salt hashing the same password gives different hashes

subsection `3.4 Парольная политика`:
- password and account policy configurable usng the classic Unix mechanisnms:
  * what can be controlled
  * how the typical configurations can be achieved
  * show demos
  * include:
    ** slide 44 from the old version of the presentation)
    ** password locking via `!` in `/etc/shadow` and `/etc/gshadow`
    ** no password via the shadow files - emtpy hash field

---

1. the custom callouts rendering issues:
   - the rectangle is drawn such that the text being outlined is not centered - try to center-align the contents being outlined both horizontally and vertically
   - if two values being outlined are placed on two adjacent lines the number bubble of the lower's callout block overlaps with the upper one (an the text it highlights) - try to move the number bubble to the lower right corner
   - in the explanation block move the number bubbles up - so that the numbers inside them are aligned vertically with the line of text that follows

2. slide 47:
   - in the explanation block `Поле 2 — пароль группы` - add bullets/dashes to visually separate the two lines
   - the 3rd callout should be rdawn around `::` to identify empty 3rd field

3. slide 50:
   - `$алгоритм$параметры$соль$хеш` extends beyond the right 

4. slides 54, 56:
   - the custom callouts' round boxes overlap - try to make them thinner perhaps (or increase interval in the terminal's output)

5. slide 59:
   - cut the hash from the output so that the terminals lose scrollbars
   - draw a box #2 around `Last password change`, fix the existing box #2 to include three values: 0, 99999, 7

6. slide 61:
   - extenx box #1 to outline the whole hash string
   - draw one more box #5 aroud `su: Authentication failure`

7. slide 62:
   - update the example:
     * add a group with password - bob not a member
     * add command in which bob uses `newgrp` with password to set this group their primary

---

1. slide (after current 24):
   - create a slide that describes the means of making EUID != RUID:
     * setuid/setgid
     * system calls
     * smth. else?
  - also discuss typical scenarious that require such change
2. move the setuid/setgid demo (current slide 25) after secure programming slide (current 28)

---

0. implement custom code snippet viewer element capable of:
   - showing the code snippet in C/C++ (possibly other languages later)
   - showing fully controllable line numbers ranges (no line numbers, sequential numbers, non-overlapping number ranges)
   - showing skipped lines with elipse
   - supporting asciidoctor-style and this project's callouts

1. slide 35
   - show type definitions for `kuid_t`, `kgid_t`
   - show `struct group_info` type definition

2. slide 37
   - show `copy_process` and `prepare_creds` function definitions around the snippets shown on the two blocks
   - move the references block `Linux v6.18: fork.c#L2046 · cred.c#L290 · cred.c#L219.` upper

3. slide 38
   - `mode` in `if (mode & S_ISUID)` is not defined - show its definition (in the function's prolog?)

4. new slide after the current 36:
   - show DAC access control check function snippet
   - comment on the way EUID/FSUID are used in this check

---

create a new section (Lecture 2) `4. Управление пользователями`:

- subtitle on the section's title slide `CRUD и значения по уполчанию`
- commands to create, edit and delete users and groups (two slides)
- a table of the most important and relevant to the topic values from `login.defs`: param name, its purpose
- `useradd`'s' own default and `/etc/skel` / `/usr/etc/skel`
- demos:
  * standard user and group creation - show how the defaults in `login.defs` affect
  * change defauls in `login.defs` and create another user - show the difference
- use environment configuration: `/etc/environment`, `~/.bashrc`, `~/.profile` (smth. else?)
- try to find examples of attacks done through modifying the environment files - add if there is something that fits into the narrative
- demo: effect of modifying env files on the setup

---

create a new section (Lecture 2) `5. Идентификация и парольная аутентификация в приложениях`:

- section subtitile `Программный интерфейс стандартной библиотеки C`

- show libc user info and password authentication handling (reference Kerrisk, chapter 8)
  * Retrieving records from the password file
    ** show `struct passwd` definition, also on this slide show a row from `/etc/password` and identify which fileds of the row go in which struct fields
    ** show two blocks of function definitions and briefly describe their purpose:
        i. `getpwnam` and `getpwuid`
       ii. `*getpwent`, `setpwent`, and`endpwent`
  * Retrieving records from the group file
    ** show `struct group` definition, also on this slide show a row from `/etc/group` and identify which fileds of the row go in which struct fields
    ** show two blocks of function definitions and briefly describe their purpose:
        i. `getgrnam` and `getgrgid`
       ii. `getgrent`, `setgrent`, and `endgrent`
  * demo: enumerate all users and groups, output to stdout info anout them in rows (as a table), including UID and GIDs
    ** show the most important code snippets first
    ** show the result of running the program on the next slide
  * Retrieving records from the shadow password file
    ** show `struct spwd` definition, also on this slide show a row from `/etc/shadow` and identify which fileds of the row go in which struct fields
    ** show two blocks of function definitions and briefly describe their purpose:
        i. `getspnam`
       ii. `getspent`, `setspent`, and `endspent`
  * Password Encryption and User Authentication
    ** show `getpass` and `crypt` definitions, descrip their purpose
  * demo: password authentication
    ** accept username
    ** request password
    ** check the correspong hashes
    ** show the most important code snippets first
    ** show the result of running the program on the next slide

- example: `login` util
  * show the util's source code snippets that shows querying the user info and verifying the password they entered
  * add detailed explanations of these snippets

- example: `passwd` util
  * show the util's source code snippets that demostrate:
    ** showing info andou the password (`passwd -l`)
    ** setting the new password hash (also show how RUID is used to identify the target user)
  * add detailed explanations of these snippets

---

create a new section (Lecture 2) `6. Name Service Switch`:

- the problems with classical Unix approach to retrieving information about users and services from local files, including:
  * working with hundreds of computers would require to copy `/etc/passwd` / `/etc/shadow` manually (along with other files), which is daunting and error-prone, e.g. UIDs might get desynchronized and more
  * the need for a centralized source of information
  * the applications that use `getpwnam`, `getgrnam`, etc. would have to be rewritten and recompiled - also demanding and risky task
- the solution - NSS
 * briefly make a history overview
 * outline the basic idea: call to `getpwnam` ,`getgrnam`, `getaddrinfo` and others don't necessarily lead to the corresponding files reading – the NSS now searches various places (including the traditional files) for the requested info - this way we can solve the outlined problem and also keep bakward compatibility
- NSS architecture:
  * the principle scheme
  * Application layer
  * GNU C Library lookup functions
  * NSS modules – what modules are available, typical location in OS (incl. Ubuntu OS)
  * configuration via file `/etc/nsswitch.conf` (just mention its location here)
- NSS configuration:
  * 
  * Database types
  * Common NSS backends
  * NSS lookup order and control flow
    ** NSS status codes
    ** demo: hostname search in several scenarious:
       *** Hostname exists in /etc/hosts
       *** Hostname exists only in DNS
       *** Hostname is absent from both
       *** File backend is unavailable
    ** demo: passwd info from local files of via sss
    ** Custom actions – syntax, available options, purpose
    ** demo:
       *** `passwd : sss [!UNAVAIL=return] files`
       *** so that passwd only is first queried from sss, and the local file is used only ib the service is not available
       *** **IMPORTANT**: review this demo, suggest a more useful demo of the custom actions that is relevant to passwd info lookup
- NSS and quierying centralized storages via SSSD
  * outline the idea, describe what LDAP, Active Directory, or FreeIPA are
  * desribe an example "enterprise" architecture
  * Identity retrieval is not authentication - draw a clear line between what NSS and PAM do (and how SSSD separates its functionality for these two)
- Performance characteristics
  * briefly discuss the overhead imposed by introduction of the NSS
  * briefly discuss caching - its purpose, who it works, the performance implications
- Security
  * Trust boundaries
  * Dynamic module loading
  * Identity collisions
  * Fail-open versus fail-closed policies
  * examples of attacks involving the NSS services

use the relevant parts of the review `.tmp/history_of_os_password_authentication.pdf` as a reference; update it if necessary: fix errors, add details and new material, etc.

---

update section 4 (Lecture 2):

- remove subsection title slides and subsection titles from the section's title slide
- slide 66:
  * split options in the third column - one option per line, or make several columns inside the third table column
  * for Debian-specific add smth. like DebianMan custom object capable of makeing links to the Debian Manpages (for `adduser(8)`, `addgroup(8)`, etc.); fix the link on this slide
- slide 67: split options in the third column - one option per line, or make several columns inside the third table column
- slide 69:
  * move text up, table and terminal below
  * show `PASS_*`, `ENCRYPT_METHOD` here as well
  * replace `дом` -> `домашняя директория`
- slide 70:
  * move text before `Каталог-шаблон ` up, the rest of the text and terminal – below
  * show typical `SKEL` and `USRSKEL` folders contents in another terminal
- slide 71:
  * replace `дом` -> `домашняя директория`; **IMPORTANT**: here and everywhere - don't call home directory `дом` in Russian, use `домашняя директория`
  * place terminals one by one on the left
  * add demo (preferably extend this one) that shows how merging of `SKEL` and `USRSKEL` is done - its effect on the home
  * decrease the width of the terminal on the left to save more space for the explanations
- slide 72:
  * terminals on the left, explanations on the right
  * ascending order of the numbered bubbles in the explanations block
- slide 76: remove this part of the demo
- slide 77:
  * terminals on the left side, explanations on the right
  * update the demo:
    ** in one terminal show actions of the attacker
    ** in the other show the victim's actions
    ** make the attack simulate more realistic scrnarion: `~/.bashrc` alegedly triggers remote shell via bash tcp (in reality just output to the stdout some memo like connecting to ***)

---

update Lecture 2:

1. replace "—" with "–", use "–" througout the presentations
2. check man pages links, fix those that are actually not working

3. slide 66: `Подвох: usermod -G` block overlaps the references - decrease indents to save some space and move this block up (perhaps, removing `-f принудительно` option can be a solution)
4. slide 69: move `skel – чувствительное место...` text block to left + return border and background, move `Каталог-шаблон копируется` to take the empty space above it - align the slide contents, move numbered bubble of callout #2 to the upper right corner 
5. move blocks that reference the demos of source codes in place of the slide references; if slide references are present then place the source refs above it

---

update section 5(Lecture 2):

- `5. Идентификация и парольная аутентификация в приложениях` -> `5. Идентификация и аутентификация в приложениях`
- remove subtitle `Программный интерфейс стандартной библиотеки C` from all subsection' title slides

- slide 77:
  * move `Для многопоточных программ предусмотрены реентерабельные варианты getpwnam_r и др.` in another attention block (above the current) + briefly describe the difference
  * align the left explanations text block (`getpwnam(3) – запись...`) with the right one - move it below
- slide 79:
  * align the left explanations text block (`getpwnam(3) – запись...`) with the right one - move it below
- slide 80:
  * align height of the first source code view to match th second's
- slide 81:
  * align terminal's height (increase the second one's)
  * move the explanations and conclusions block under the both terminals - not in the second column

- slide 84:
  * add `getpwuid`
  * arrange the laoyout similarly to slides 77, 79
  * `Структуру и функции остальных теневых файлов повторяет <gshadow.h> (struct sgrp, getsgnam) – для /etc/gshadow.` - replace with a propper slide
  * rename the subsection: `Чтение теневого файла shadow` -> `Чтение теневых файлов: shadow и gshadow`

slide 86:
  * add `readpassphrase` funciton description (can be split into two slides)
slide 87:
  - move the callout #7 to the right column
  - extend the left source code block's heigth - make it equal the right one's
slide 88:
  - move the right terminal on the left

slides 90-95:
  - make use of the utils that are actually used in mordern Linux (e.g. Ubuntu 26.04) - aren't they come from `util-linux` package?
  - if `login` that is actually in use doesn't have no-PAM, classic source branch, fallback to **shadow** package
  - similarly for `passwd`: if there is not non-PAM branch, keep using **shadow** version

---

- callout's numbered bubbles should always be on top - sometimes elements wrapped in `<code></code>` overlap the lower part of the bubble (e.g. on slide 96 the callouts #2 and #3 are partially overlapped with the code right below them)
- MITRE ATT&CK - turn into clickable links, analogous to the man pages, create a custom object
- check the sequential numbers (e.g. sections', demo numbers, etc.)
- check the spelling on all slides

---

update section 6 (lecture 2):

- remove subtitle `Единый интерфейс к базам учётных данных и имён`
- `От локальных файлов к NSS` -> `От локальных файлов к централизованной базе`

- slide 101: decrease margin between `к проблемам:` and `- на каждой машине необходимо`
- slide 102: split on two columns is removed, check that no relevant stale css style/class is left
- slide 103: add memo clarifying that not all libc implementations support NSS on Linux
- slide 105: increase space between the three levels a little - the slide has spare space; also move the scheme close to the senter of the slide
- slide 108: decrease indent of block `база: источник [действие] источник …`
- slide 111:
  * move the numbered buble of the first callout #2 (line `getent -s files`) to the lower right corner
  * demo 12: use some well-known address like google.com instead of example.org
- slide 113:
  * is it worth it to replace `hosts: resolve [!UNAVAIL=return] files dns` -> `hosts: files resolve [!UNAVAIL=return] dns` so that the meaning would be "first search in /etc/hosts, as usually, then use either systemd-resolved or dns if the former is not available" ?
- slide 114, demo 13: 
  * the forth `и вторичные группы (initgroups) собраны из каталога` is not clear as previously the local groups list was not shown - add this to the demo so the absence of `dave` (?) group is explicit
  * first show the policy in place: grep from `/etc/nsswitch.conf` of the relevant lines

---

- rename `6.4 SSSD и централизованные каталоги` -> `6.4 SSSD и службы каталогов`
- add RFC references custom object (analogous to the man pages and MITRE), replace RFC references with it (e.g. RFC 4511 on slide 118)
- similarly for CVE - custom reference object, update usages
- slide 128: `Закладка-модуль NSS` and `Навязывание ответа` - try to find real-world example, add CVE ref

keep my edits intact


## TODO

### Лекция 2

- демо создания файла из-под пользователя и наследование его первичной GID в качестве группы владельцев файла;
  + изменение первичной GID с помощью `newgrp` и создание файла - показать, что группа владельцев у нового изменилась
  + пароль на группу здесь же, не после обсуждения `/etc/gshadow` (?)
- показать, что `!` и `*` имеют особый смысл только для утилиты `passwd` (которая следует соглашению), а на самом деле 
  важно, может ли система разобрать хранимую во втором поле файла `/etc/[g]shadow` строку по формату `crypt` 
- показать полноценный пример Secure programming - вешаемся на порт 80, дропаем привилегии и работает нормально (например, `echo`-сервер)
- сл. 28: пример кода показать с помощью новой вьюшки для просмотра кода
- увеличить шрифт заголовков подразделов
- ревью заголовоков разделов и слайдов
- обновить стиль блоков с текстом (сл. 42, 53)
- заполнить слай с планом лекции
- подробнее про псеводпользователей: i. демо попытки сохранить файл из-под пользователя с хомяком `/nonexistent`, ii. демо попытки залогинится из-под пользователя с `/usr/sbin/nologin`
- !!! показать правила изменения FS[U|G]ID (при наследовании и проч.) - т.к. сейчас показана только классика, этот аспект упущен
  + проверить, что показанные фрагменты кода из ядра полностью демонстрируют все правила изменения этих идентификаторов (добавить функции `set*id` (?) )
- добавить таблицу хешей с указанием маркера алгоритма, перечислением параметроа, ссылкой на RFC / източник (код и когда разработал) и статус (можно ли использовать);
  + добавить хеши отечественных ОС
  + подробнее про основные алгоритмы (?) (можно вынести в доп. материалы - показать отдельно)
- NSS module load details? in source code and strace?
