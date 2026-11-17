# Демо к лекции 2 (новая версия)

Эталон – одноразовые **Ubuntu Server 26.04 LTS VM**, Bash, локаль вывода C.
Сценарии требуют root и меняют учётные записи (создают и удаляют временных
пользователей `ossec-demo1`/`ossec-demo2` и группу `ossec-proj`); запускайте
их **только на одноразовой VM со снимком**.

Демо 01–04 (раздел 2) перенесены из старой версии лекции вместе со слайдами
(там они были пронумерованы 01, 02, 12, 13): создают и удаляют временного
пользователя `ossec-demo`; демо 01 через `vipw` временно ставит ему UID 0 и
восстанавливает исходный, демо 04 собирает `gcc` и временно устанавливает
setuid-программу `/usr/local/bin/ossec-idprobe` и скрипт
`/usr/local/bin/ossec-suid-script`. Захваты 01–04 сняты вручную теми же командами
(пользователи `alice`/`bob`, `idprobe`, `suid.sh`), поэтому имена в выводе
сценариев отличаются от слайдов.

Сценарии раздела 4 (07–09) создают и удаляют временных пользователей
`ossec-demo1`/`ossec-demo2` и группы `ossec-proj`; демо 08 временно правит
`/etc/default/useradd` и `/etc/login.defs` и восстанавливает их из резервной
копии, демо 09 добавляет и удаляет `/etc/profile.d/99-ossec-demo.sh` и файл-маркер
`/tmp/ossec-backdoor-marker`. Запускать только на одноразовой VM.

Демо 10–11 (раздел 5) – программы на C (`10-enum-accounts.c`,
`11-password-auth.c`); одноимённые сценарии собирают их `gcc` и запускают.
Демо 11 интерактивно (пароль вводится с терминала), создаёт и удаляет
пользователя `ossec-demo1` и временно устанавливает `/usr/local/bin/pwcheck`.

Демо 12–13 (раздел 6, NSS) меняют системную конфигурацию и потому особенно
требовательны к одноразовости VM. Демо 12 временно добавляет запись в
`/etc/hosts` и на время снимает с него права чтения (`chmod 000`), пользуется
сетевым DNS (имя `google.com`). Демо 13 **переконфигурирует slapd**
(существующий каталог откладывается `dpkg-reconfigure` в `/var/backups`),
создаёт в LDAP пользователя `dave` (uid 5000) и группы `dave`/`developers`
(gid 5000/5100), пишет `/etc/sssd/sssd.conf` (отказывается работать, если файл
уже существует), правит и восстанавливает `/etc/nsswitch.conf`, создаёт и
удаляет локальных `ossec-demo1` и группу `developers`, по завершении
останавливает sssd/slapd и чистит кеши `/var/lib/sss/{db,mc}`. Пароль
администратора LDAP – публичное лабораторное значение `LabLDAP-42!`.
Лабораторное упрощение: канал к slapd без TLS (`ldap_id_use_start_tls = false`);
в эксплуатации так настраивать нельзя.

## Подготовка

~~~bash
sudo apt-get update
sudo apt-get install python3 procps gcc libc6-dev   # демо 01, 03, 04
sudo apt-get install whois util-linux-extra   # mkpasswd; newgrp/sg
sudo apt-get install gcc libc6-dev libcrypt-dev   # демо 10–11 (crypt.h, -lcrypt)
sudo apt-get install strace                   # демо 12
sudo apt-get install slapd ldap-utils sssd libnss-sss   # демо 13
~~~

Запуск:

~~~bash
bash 01-passwd-uid-zero.sh --help
sudo env OSSEC_DEMO_VM=1 bash 01-passwd-uid-zero.sh
~~~

## Сценарии

| № | Файл | Содержание | Захват |
|---|------|------------|--------|
| 01 | `01-passwd-uid-zero.sh` | подмена третьего поля `/etc/passwd` (через `vipw`) на 0: новый процесс пользователя получает UID 0; исходный UID восстанавливается | `captures/01-passwd-uid-zero.txt` |
| 02 | `02-group-membership.sh` | первичная и вторичные группы: `usermod -aG`, `groups`, `id`, строки `/etc/group` | `captures/02-group-membership.txt` |
| 03 | `03-process-credentials.sh` | четыре UID/GID процесса в `/proc/PID/status` и `ps`: оболочка root, процесс пользователя, setuid-программа `passwd` (ruid ≠ euid = 0) | `captures/03-process-credentials.txt` |
| 04 | `04-uid-inheritance.sh` | setuid-утилита `idprobe`: наследование при `fork`; сброс привилегий `seteuid` против `setuid`; `execve` без setuid-бита; `bash` сбрасывает euid без `-p`; setuid-бит на скрипте игнорируется | `captures/04-uid-inheritance.txt` |
| 05 | `05-password-hashing.sh` | проверка пароля повторным вычислением хеша (mkpasswd); хеш без соли; случайная соль; фиксированная соль | `captures/05-password-hashing.txt` |
| 06 | `06-password-policy.sh` | поля устаревания и `chage`; значения по умолчанию `login.defs`; блокировка `passwd -l` (`!` в `/etc/shadow`); пустое поле хеша и вход без пароля (`nullok`); пароль группы в `/etc/gshadow` и `newgrp` | `captures/06-password-policy.txt` |
| 07 | `07-user-defaults.sh` | `useradd -D` и умолчания `login.defs`; создание пользователя одной командой (UID/GID, UPG, `HOME_MODE`, skel, заблокированное поле пароля); создание группы | `captures/07-user-defaults.txt` |
| 08 | `08-change-defaults.sh` | изменение умолчаний (`useradd -D -s/-f`, `HOME_MODE` в `login.defs`) и разница в новой записи: оболочка, права дома, поле `inactive` | `captures/08-change-defaults.txt` |
| 09 | `09-environment-files.sh` | файлы окружения: `/etc/environment` (pam_env), `/etc/profile.d`; login- vs интерактивная оболочка (маркеры); злоупотребление `~/.bashrc` – выполнение кода от имени владельца и перехват `PATH` | `captures/09-environment-files.txt` |
| 10 | `10-enum-accounts.sh` (+ `10-enum-accounts.c`) | перебор всех учётных записей и групп средствами libc: `setpwent`/`getpwent`/`endpwent`, `getgrent`, массив `gr_mem`; сводная таблица пользователей (UID, GID, оболочка, вторичные группы) и групп | `captures/10-enum-accounts.txt` |
| 11 | `11-password-auth.sh` (+ `11-password-auth.c`) | парольная аутентификация по листингу 8-2 TLPI: `getpwnam` → `getspnam` → `getpass` → `crypt` → `strcmp`; верный/неверный пароль, несуществующее имя, запуск без привилегий (на сервере `shadow: files systemd` маскирует EACCES; при `shadow: files` – классический EACCES; сценарий временно правит и восстанавливает `/etc/nsswitch.conf`) | `captures/11-password-auth.txt` |
| 12 | `12-nss-hosts.sh` | NSS для базы `hosts`: модули на диске; имя в `/etc/hosts` / только в DNS / нигде (коды выхода `getent`, изоляция источника `-s`); недоступный источник (нечитаемый `/etc/hosts` для непривилегированного процесса → UNAVAIL → поиск продолжается: на сервере имя отдаёт `dns` через systemd-resolved; `strace` показывает EACCES) | `captures/12-nss-hosts.txt` |
| 13 | `13-nss-sssd.sh` | NSS + SSSD: локальный slapd (`dc=example,dc=test`, posixAccount `dave`), `sssd.conf` с `id_provider = ldap`; `passwd: files systemd sss` – одна функция, два источника (`getent -s`); ловушка `sss [!UNAVAIL=return] files systemd` (NOTFOUND каталога скрывает `root`); `group: files [SUCCESS=merge] sss systemd` – объединение членов; быстрый mmap-кеш `/var/lib/sss/mc` отвечает при остановленном sssd | `captures/13-nss-sssd.txt` |
