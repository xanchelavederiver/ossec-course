# Демо к лекции 2 (новая версия)

Эталон – одноразовые **Ubuntu Server 26.04 LTS VM**, Bash, локаль вывода C.
Сценарии требуют root и меняют учётные записи (создают и удаляют временных
пользователей `ossec-demo1`/`ossec-demo2` и группу `ossec-proj`); запускайте
их **только на одноразовой VM со снимком**.

Демо 01–04 перенесены из старой версии лекции вместе со слайдами – их сценарии
остаются в `../../02-classical-unix-mechanisms_old/assets/demos/` (там они
пронумерованы 01, 02, 12, 13). Здесь лежат новые сценарии разделов 3 и 4.

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
sudo apt-get install whois util-linux-extra   # mkpasswd; newgrp/sg
sudo apt-get install gcc libc6-dev libcrypt-dev   # демо 10–11 (crypt.h, -lcrypt)
sudo apt-get install strace                   # демо 12
sudo apt-get install slapd ldap-utils sssd libnss-sss   # демо 13
~~~

Запуск:

~~~bash
bash 05-password-hashing.sh --help
sudo env OSSEC_DEMO_VM=1 bash 05-password-hashing.sh
~~~

## Сценарии

| № | Файл | Содержание | Захват |
|---|------|------------|--------|
| 05 | `05-password-hashing.sh` | проверка пароля повторным вычислением хеша (mkpasswd); хеш без соли; случайная соль; фиксированная соль | `captures/05-password-hashing.txt` |
| 06 | `06-password-policy.sh` | поля устаревания и `chage`; значения по умолчанию `login.defs`; блокировка `passwd -l` (`!` в `/etc/shadow`); пустое поле хеша и вход без пароля (`nullok`); пароль группы в `/etc/gshadow` и `newgrp` | `captures/06-password-policy.txt` |
| 07 | `07-user-defaults.sh` | `useradd -D` и умолчания `login.defs`; создание пользователя одной командой (UID/GID, UPG, `HOME_MODE`, skel, заблокированное поле пароля); создание группы | `captures/07-user-defaults.txt` |
| 08 | `08-change-defaults.sh` | изменение умолчаний (`useradd -D -s/-f`, `HOME_MODE` в `login.defs`) и разница в новой записи: оболочка, права дома, поле `inactive` | `captures/08-change-defaults.txt` |
| 09 | `09-environment-files.sh` | файлы окружения: `/etc/environment` (pam_env), `/etc/profile.d`; login- vs интерактивная оболочка (маркеры); злоупотребление `~/.bashrc` – выполнение кода от имени владельца и перехват `PATH` | `captures/09-environment-files.txt` |
| 10 | `10-enum-accounts.sh` (+ `10-enum-accounts.c`) | перебор всех учётных записей и групп средствами libc: `setpwent`/`getpwent`/`endpwent`, `getgrent`, массив `gr_mem`; сводная таблица пользователей (UID, GID, оболочка, вторичные группы) и групп | `captures/10-enum-accounts.txt` |
| 11 | `11-password-auth.sh` (+ `11-password-auth.c`) | парольная аутентификация по листингу 8-2 TLPI: `getpwnam` → `getspnam` (EACCES без привилегий) → `getpass` → `crypt` → `strcmp`; верный/неверный пароль, несуществующее имя, запуск без привилегий | `captures/11-password-auth.txt` |
| 12 | `12-nss-hosts.sh` | NSS для базы `hosts`: модули на диске; имя в `/etc/hosts` / только в DNS / нигде (коды выхода `getent`, изоляция источника `-s`); недоступный источник (нечитаемый `/etc/hosts` для непривилегированного процесса → UNAVAIL → поиск продолжается; `strace` показывает EACCES) | `captures/12-nss-hosts.txt` |
| 13 | `13-nss-sssd.sh` | NSS + SSSD: локальный slapd (`dc=example,dc=test`, posixAccount `dave`), `sssd.conf` с `id_provider = ldap`; `passwd: files sss` – одна функция, два источника (`getent -s`); ловушка `sss [!UNAVAIL=return] files` (NOTFOUND каталога скрывает `root`); `group: files [SUCCESS=merge] sss` – объединение членов; быстрый mmap-кеш `/var/lib/sss/mc` отвечает при остановленном sssd | `captures/13-nss-sssd.txt` |
