---
theme: default
title: Классические механизмы управления пользователями в ОС Unix
author: OSSec
addons: [../../../theme]
layout: cover
colorSchema: light
duration: 90min
defaults:
  class: lecture-iam
---

# Лекция 2

## Классические механизмы управления пользователями в ОС Unix

Ubuntu 24.04 LTS · локальные учётные записи → централизованный каталог

<!--
90 минут: введение 5; passwd 12; group 10; shadow и криптография 22;
управление 10; логин 8; sudo 8; NSS/LDAP 12; итоги 3.
LDAP-VM подготовить заранее. Полный прогон всех демо — дополнительный практикум.
-->

---

# Что будем уметь

- Читать базы пользователей и групп и связывать поля с C API.
- Отличать имя учётной записи от числовых полномочий процесса.
- Объяснять проверку пароля, блокировку и срок действия.
- Управлять пользователями и ограниченными правилами sudo.
- Проследить запрос от login через NSS и PAM до LDAP.

Терминальные фрагменты — **иллюстративный ожидаемый вывод**:
UID, даты, хэши и приглашения зависят от VM. Скрипты показывают фактический результат.

---

# IAM: имя, доказательство, полномочия

**Identity and Access Management** — управление идентичностями и доступом:
создание учётных записей, подтверждение личности, выдача и отзыв полномочий.

| Вопрос | Механизм |
|---|---|
| «Кто такой alice?» | passwd / NSS: имя → UID, GID, home, shell |
| «Это действительно alice?» | Пароль, ключ; PAM и провайдер аутентификации |
| «Что ей разрешено?» | UID/GID, права файлов, ACL, sudoers |
| «Что произошло?» | Журналы сессий и событий аутентификации |

Ядро проверяет **числовые credentials процесса**. Человек работает с именами.

---

# От одной машины к сети

- Unix 1970-х: многопользовательская ОС, UID/GID и локальные текстовые базы.
- Хэш в общедоступном passwd позволял каждому проводить офлайн-подбор.
- Shadow отделяет общедоступные атрибуты от проверочных данных пароля.
- Сеть машин требует общего пространства имён: NIS, LDAP, Active Directory.
- NSS выбирает источник сведений; PAM отделяет приложения от проверки входа.

Червь Морриса (2 ноября 1988) использовал подбор слабых паролей.
Он показал масштаб риска; «shadow изобрели только из-за червя» — слишком
категоричное утверждение: закрытое хранение обсуждалось раньше.

Источники: Morris & Thompson (1979); Spafford (1988), ссылки в конце.

---

# Одна сессия — несколько механизмов

~~~text
login / sshd / su
 ├─ getpwnam("alice") → NSS → files / sss → UID, GID, home, shell
 ├─ PAM authenticate/account → pam_unix / pam_sss → проверка + политика
 ├─ initgroups + setgid + setuid → credentials нового процесса
 └─ PAM session + журналы → домашний каталог → оболочка

passwd → PAM / привилегированная запись → shadow или удалённый провайдер
sudo   → sudoers + проверка пользователя → команда с целевыми credentials
~~~

NSS сам по себе **не проверяет пароль**. PAM подробно разбирается в лекции 3.

---

# /etc/passwd: семь полей

~~~text
alice:x:1000:1000:Alice Example:/home/alice:/bin/bash
  1   2   3    4        5           6         7
~~~

| № | Назначение | Поле struct passwd |
|---|---|---|
| 1 | Имя входа | pw_name |
| 2 | Проверочные данные; x → shadow | pw_passwd |
| 3 | Числовой идентификатор пользователя | pw_uid |
| 4 | Основная группа | pw_gid |
| 5 | Комментарий GECOS | pw_gecos |
| 6 | Домашний каталог | pw_dir |
| 7 | Программа входа / оболочка | pw_shell |

---

# C API: &lt;pwd.h&gt;

~~~c
#include <pwd.h>
struct passwd {
    char  *pw_name;
    char  *pw_passwd;
    uid_t  pw_uid;
    gid_t  pw_gid;
    char  *pw_gecos;
    char  *pw_dir;
    char  *pw_shell;
};

struct passwd *getpwnam(const char *name);
struct passwd *getpwuid(uid_t uid);
~~~

Все поля glibc показаны; GECOS — историческое расширение.
Функции используют NSS. Для многопоточного кода есть getpwnam_r/getpwuid_r.

Источник: [getpwnam(3)](https://man7.org/linux/man-pages/man3/getpwnam.3.html).

---

# Кто читает и кто меняет passwd

~~~console
$ stat -c '%a %U:%G %n' /etc/passwd /etc/shadow
644 root:root /etc/passwd
640 root:shadow /etc/shadow
~~~

- passwd читают все: ls должен превратить UID владельца в имя.
- Запись — root; обычный пользователь не может произвольно менять свой UID.
- Shadow в Ubuntu обычно доступен root и группе shadow на чтение.
- В других системах режим shadow бывает 600 или 000; проверяем VM.
- Администрирование: useradd/usermod; ручное редактирование с блокировкой: vipw.

Читаемость passwd нужна приложениям; читаемость хэша для всех — нет.

---

# Не все учётные записи принадлежат людям

~~~text
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
alice:x:1000:1000:Alice Example:/home/alice:/bin/bash
~~~

- root: традиционный суперпользователь, особое значение имеет UID 0.
- daemon: историческая запись, не универсальный пользователь всех демонов.
- www-data: отдельные права веб-службы; процессы работают с её UID.
- nobody: минимальная общая идентичность, в том числе для некоторых отображений NFS.

UID служебных записей зависят от системы. Сервисам полезны отдельные UID.

---

# Псевдопользователь и программа входа

**Псевдопользователь** — служебная учётная запись для владения файлами
и выполнения процессов, обычно без интерактивного входа.

| Объект | Поведение |
|---|---|
| /usr/sbin/nologin | Сообщает об отказе, ненулевой код выхода |
| /bin/false | Немедленно завершает работу с кодом 1 |
| /bin/true | Немедленно завершает работу с кодом 0 |
| /dev/null | Устройство: запись отбрасывает данные, чтение даёт EOF |

/dev/null — не исполняемая оболочка и не каталог home.
true не даёт shell, но успешный код важен вызывающей программе.
Блокировка пароля и nologin не мешают root запустить службу от этого UID.

---

# Демо 01: имя и UID

~~~console
$ getent passwd ossec-demo
ossec-demo:x:1001:1001::/home/ossec-demo:/bin/bash
$ runuser -u ossec-demo -- id -u
1001
$ vipw
# Только у ossec-demo: третье поле 1001 → 0
$ getent passwd ossec-demo
ossec-demo:x:0:1001::/home/ossec-demo:/bin/bash
$ runuser -u ossec-demo -- id -u
0
~~~

**01-passwd-uid-zero.sh**. Нужен root в одноразовой VM.
Это последствия права записи в базу, а не обход защиты.
Уже запущенный процесс UID не меняет; скрипт возвращает UID до удаления записи.

---

# /etc/group: четыре поля

~~~text
sudo:x:27:alice,bob
  1  2  3     4
~~~

| № | Назначение | Поле struct group |
|---|---|---|
| 1 | Имя группы | gr_name |
| 2 | Пароль / x → gshadow | gr_passwd |
| 3 | Числовой GID | gr_gid |
| 4 | Дополнительные участники через запятую | gr_mem |

Основная группа пользователя хранится в **passwd.pw_gid**.
Его имя не обязано присутствовать в списке участников этой группы.

---

# C API: &lt;grp.h&gt;

~~~c
#include <grp.h>
struct group {
    char   *gr_name;
    char   *gr_passwd;
    gid_t   gr_gid;
    char  **gr_mem;
};

struct group *getgrnam(const char *name);
struct group *getgrgid(gid_t gid);
~~~

gr_mem — массив указателей на строки с завершающим NULL.
getgrnam получает одну запись. Для групп пользователя нужны
getgrouplist/initgroups с учётом NSS.

Источник: [getgrnam(3)](https://man7.org/linux/man-pages/man3/getgrnam.3.html).

---

# Демо 02: группы и права файла

~~~console
$ stat -c '%a %U:%G %n' /etc/group
644 root:root /etc/group
$ usermod -aG sudo ossec-demo
$ groups ossec-demo
ossec-demo : ossec-demo sudo
$ id ossec-demo
uid=1001(ossec-demo) gid=1001(ossec-demo) groups=1001(ossec-demo),27(sudo)
$ grep -E '^(ossec-demo|sudo):' /etc/group
sudo:x:27:alice,ossec-demo
ossec-demo:x:1001:
~~~

**02-group-membership.sh**. Читать group могут все, писать — root.
id без имени показывает группы процесса; id USER — сведения из базы.
Новая группа обычно появляется в сессии после нового входа.

---

# /etc/gshadow и пароль группы

~~~text
sudo:!:alice:alice,bob
name:password:administrators:members
~~~

| Поле | Назначение |
|---|---|
| name | Имя, связанное с /etc/group |
| password | Хэш для newgrp; ! или * запрещает вход по паролю группы |
| administrators | Управляют паролем и участниками |
| members | Должны соответствовать списку в group |

Ubuntu: обычно **640 root:shadow**; менять через gpasswd/vigr.
Пароль позволяет неучастнику получить GID через newgrp.
Участнику он обычно не нужен; пустой пароль — доступ только участникам.

Источник: [gshadow(5)](https://manpages.ubuntu.com/manpages/noble/man5/gshadow.5.html).

---

# Демо 03: пароль группы sudo

~~~console
# root, только учебная VM:
$ gpasswd sudo
Changing the password for group sudo
New Password:
Re-enter new password:
# В оболочке ossec-demo, который не включён в sudo:
$ newgrp sudo
Password:
$ id -gn
sudo
$ exit
~~~

**03-group-password-sudo.sh**; затем ещё exit для возврата к сценарию.
Проверяется пароль **группы при смене GID**, а не пароль вызова sudo.
Пароль административной группы расширяет доступ; на рабочей машине не задавать.

---

# /etc/shadow: девять полей

~~~text
alice:$y$j9T$SALT$DIGEST:20000:0:90:7:14:21000:
~~~

| № | Поле spwd | Значение |
|---|---|---|
| 1–2 | sp_namp, sp_pwdp | Имя и парольный verifier |
| 3 | sp_lstchg | День последней смены от 1970-01-01 UTC |
| 4–5 | sp_min, sp_max | Минимальный / максимальный возраст, дни |
| 6 | sp_warn | За сколько дней предупреждать |
| 7 | sp_inact | Дней после истечения пароля до блокировки входа |
| 8 | sp_expire | Абсолютный день истечения учётной записи |
| 9 | sp_flag | Резерв; обычно пусто |

SALT/DIGEST — условные обозначения, не действительный хэш.

---

# C API: &lt;shadow.h&gt;

~~~c
#include <shadow.h>
struct spwd {
    char          *sp_namp;
    char          *sp_pwdp;
    long int       sp_lstchg;
    long int       sp_min;
    long int       sp_max;
    long int       sp_warn;
    long int       sp_inact;
    long int       sp_expire;
    unsigned long int sp_flag;
};

struct spwd *getspnam(const char *name);
~~~

Это Linux/glibc API, не переносимый на все Unix интерфейс POSIX.
Источник: [getspnam(3)](https://man7.org/linux/man-pages/man3/getspnam.3.html).

---

# Блокировка пароля и другие способы входа

- **!HASH**: пароль заблокирован; старое значение может быть восстановлено.
- **! или \***: не являются допустимым результатом crypt.
- Пустое поле: потенциально беспарольная проверка; итог зависит от PAM.
- sp_lstchg = 0: потребовать смену при следующем входе.
- Пустой sp_expire: нет абсолютного срока учётной записи.

~~~console
$ passwd -l alice     # блокировать пароль
$ passwd -u alice     # разблокировать
$ chage -E 2026-12-31 alice
~~~

SSH-ключ может продолжить работать при блокировке только пароля.
Источник: [shadow(5)](https://manpages.ubuntu.com/manpages/noble/man5/shadow.5.html).

---

# Кто имеет доступ к shadow

~~~console
$ stat -c '%a %U:%G %n' /etc/shadow /usr/bin/passwd /bin/login
640 root:shadow /etc/shadow
4755 root:root /usr/bin/passwd
755 root:root /bin/login
~~~

- login обычно запускает привилегированный getty; setuid ему не обязателен.
- passwd контролируемо повышает привилегии и проверяет, чью запись меняет.
- PAM может использовать привилегированный помощник unix_chkpwd.
- Обычному процессу не дают все хэши ради проверки одного пользователя.

Режимы — типичный пример Ubuntu; локальный stat является источником истины.

---

# Политика: интервалы и абсолютная дата

~~~console
$ chage -m 0 -M 90 -W 7 -I 14 -E 2027-09-06 alice
$ chage -l alice
~~~

~~~text
last-change ─────── +90 → password expires ─── +14 → inactive
                           ↑
                     warning за 7 дней
account expires: отдельная абсолютная дата
~~~

min/max/warn/inactive — интервалы. expire — день календаря.
Смена пароля сдвигает вычисляемые даты от last-change,
но не переписывает интервалы и абсолютный срок учётной записи.

---

# Демо 04: до и после passwd

~~~console
$ chage -d 2026-08-27 -M 90 -W 7 -I 14 ossec-demo
$ chage -l ossec-demo
Last password change                                    : Aug 27, 2026
Password expires                                        : Nov 25, 2026
Password inactive                                       : Dec 09, 2026
$ passwd ossec-demo
New password:
Retype new password:
passwd: password updated successfully
~~~

После смены **2026-09-06**: last change → Sep 06; expires → Dec 05;
inactive → Dec 19. Срок учётной записи и 0/90/7/14 сохраняются.

**04-shadow-password-policy.sh** задаёт прошлую дату:
две смены в один день не изменят поле с точностью до дня.

---

# Что хранится вместо пароля

~~~text
password + salt + cost parameters → password KDF → verifier

$6$rounds=100000$CourseSalt$<86 characters>
 │       │          │              └─ SHA-512-crypt result
 │       │          └─ открытая соль
 │       └─ число раундов
 └─ идентификатор формата

$y$j9T$<salt>$<digest>    # типичный формат yescrypt
~~~

При проверке берём сохранённые параметры и повторяем вычисление.
Это не шифрование: ключа для «расшифровки пароля» нет.
Структура и разделители зависят от алгоритма.

---

# Алгоритмы: формат ≠ обычный SHA(password)

| Формат | Алгоритм | Контекст |
|---|---|---|
| 13 символов без $ | traditional DES crypt | Исторический, устарел |
| `$1$` / `$apr1$` | MD5-crypt / Apache | Устаревшие форматы |
| `$2a$`, `$2b$`, `$2y$` | bcrypt | Свой формат и cost |
| `$5$`, `$6$` | SHA-256-crypt, SHA-512-crypt | Итерированные password hashes |
| `$y$` / `$gy$` | yescrypt / gost-yescrypt | Ubuntu обычно `$y$` |
| `$7$` | scrypt | Memory-hard формат libxcrypt |
| `$argon2id$` | Argon2id (PHC format) | Не штатный формат pam_unix Ubuntu |

Основные семейства; поддержку определяет сборка.
Полный перечень VM: **man 5 crypt**; для OpenSSL: **openssl passwd -help**.

---

# Почему хэш, зачем соль

- Утечка базы не раскрывает пароли немедленно; догадки всё равно можно проверять.
- Выход KDF имеет выбранный размер; длина пароля напрямую не видна.
- Полная строка меняется по длине из-за алгоритма, соли и параметров.
- Случайная уникальная соль даёт разные verifier для одинаковых паролей.
- Она разрушает повторное использование предвычислений между записями.
- Соль открыта; от перебора **одной** записи она не защищает.

Нужны одновременно: качественные пароли, дорогая KDF, соль и защита базы.

---

# Соль и перец решают разные задачи

| | Соль (salt) | Перец (pepper) |
|---|---|---|
| Секретность | Открыта | Секрет приложения |
| Область | Случайная для каждой записи | Может быть общим ключом |
| Хранение | В verifier | Отдельно от базы |
| Эффект | Разделяет вычисления для записей | Утечки одной базы недостаточно |
| Сложность | Без управления секретом | Ротация, доступность, восстановление |

«Что лучше?» — некорректный выбор: перец может **дополнять** соль.
Классический crypt проверяет пароль по самодостаточной строке с солью.
Отдельный общий секрет не входит в обычную схему pam_unix.

---

# Timing attack: утечка через ранний выход

~~~python
def unsafe(candidate, secret):
    for a, b in zip(candidate, secret):
        if a != b:
            return False
        # В демо: искусственная задержка 2 ms на совпадение.
    return len(candidate) == len(secret)
~~~

При равной длине больше совпавших начальных байтов → больше работы.
Измеряя время серии запросов, атакующий угадывает очередной символ.

Сравниваем **вычисленные verifier фиксированной длины** подходящим
constant-time примитивом, например hmac.compare_digest.

---

# Демо 06: восстановление учебного секрета

~~~console
$ bash assets/demos/06-timing-attack.sh
prefix=c max_median_ms=2.06
prefix=ca max_median_ms=4.12
...
prefix=cabdab max_median_ms=12.36
Recovered: True
compare_digest(correct): True
compare_digest(wrong): False
~~~

**06-timing-attack.sh**. Локальный синтетический oracle, алфавит a–d.
Задержка усилена; миллисекунды иллюстративны.
Это не утверждение об уязвимости login/PAM.
Повторы уменьшают шум, но не гарантируют точность на загруженной VM.

---

# PBKDF2 и Argon2: намеренно дорогая проверка

- **PBKDF2** повторяет PRF (обычно HMAC); итерации задают объём работы.
- **Argon2id**: память, проходы и параллелизм; затрудняет массовый перебор.
- Стоимость подбирают под оборудование и нагрузку входов.
- Фиксированное время в миллисекундах не гарантируется.
- KDF не заменяет constant-time сравнение и ограничение онлайн-попыток.

На Ubuntu 24.04 локальные пароли обычно использует **yescrypt** через pam_unix.
PBKDF2 и Argon2 здесь объясняют принцип, не меняют системный формат.

Источники: [RFC 8018](https://www.rfc-editor.org/rfc/rfc8018.html),
[RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html).

---

# Демо 05: один пароль, разные соли и алгоритмы

~~~console
$ printf '%s\n' 'Demo-Only-42!' | openssl passwd -1 -stdin
$1$<random-salt-A>$<digest-A>
$ printf '%s\n' 'Demo-Only-42!' | openssl passwd -1 -stdin
$1$<random-salt-B>$<digest-B>
$ printf '%s\n' 'Demo-Only-42!' | openssl passwd -5 -stdin
$5$<random-salt-C>$<digest-C>
$ printf '%s\n' 'Demo-Only-42!' | openssl passwd -6 -stdin
$6$<random-salt-D>$<digest-D>
~~~

**05-password-hashes.sh**: по два вычисления для -1, -5, -6.
Условные обозначения сокращают строки; сценарий выводит хэши целиком.
OpenSSL passwd 3.x не генерирует yescrypt/Argon2; MD5 — только для сравнения.

---

# Демо 05: та же соль даёт тот же результат

~~~bash
a=$(printf '%s\n' 'Demo-Only-42!' |
    openssl passwd -6 -salt CourseSalt -stdin)
b=$(printf '%s\n' 'Demo-Only-42!' |
    openssl passwd -6 -salt CourseSalt -stdin)
printf '%s\n%s\n' "$a" "$b"
test "$a" = "$b" && echo IDENTICAL
~~~

~~~text
$6$CourseSalt$<одинаковый digest>
$6$CourseSalt$<одинаковый digest>
IDENTICAL
~~~

Совпадают алгоритм, параметры, соль и пароль. Пароль примера публичный.
Реальный пароль не передавайте аргументом процесса.
Источник: [openssl-passwd](https://docs.openssl.org/3.0/man1/openssl-passwd/).

---

# Жизненный цикл: useradd → usermod → userdel

~~~console
$ useradd -m -s /bin/bash -c 'Alice Example' alice
$ passwd alice
$ usermod -aG sudo alice
$ usermod -s /usr/sbin/nologin alice
$ userdel -r alice
~~~

- useradd создаёт локальную запись; пароль задаётся отдельно.
- usermod -G заменяет список дополнительных групп; **-aG** дополняет.
- Изменение имени/UID требует учесть файлы и действующие процессы.
- userdel -r удаляет home и почтовый spool; другие файлы и журналы остаются.

Ubuntu adduser — отдельная высокоуровневая оболочка; здесь изучаем useradd.

---

# /etc/default/useradd: значения для новых записей

~~~console
$ useradd -D
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/sh
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
~~~

GROUP — запасная основная группа при создании без user-private group;
HOME — базовый путь; SHELL — программа входа; SKEL — источник шаблона.
INACTIVE/EXPIRE — исходные сроки; CREATE_MAIL_SPOOL — почтовый файл.

Это пример: опции и user-private groups меняют результат.
Изменение defaults не переписывает существующих пользователей.

---

# /etc/login.defs: defaults и граница PAM

| Параметры | Краткое назначение |
|---|---|
| UID_MIN/MAX, SYS_UID_MIN/MAX | Диапазоны обычных / служебных UID |
| GID_MIN/MAX, SYS_GID_MIN/MAX | Аналогичные диапазоны GID |
| CREATE_HOME, USERGROUPS_ENAB | Home, пользовательские группы |
| UMASK, HOME_MODE | Права home; HOME_MODE может переопределять UMASK |
| PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE | Начальные сроки новых записей shadow |
| ENCRYPT_METHOD | Для использующих его shadow-утилит |

При PAM сложность, хэширование passwd, отказы входа и session policy
задаются модулями /etc/pam.d: например, pam_unix yescrypt и pam_pwquality.
login.defs **не становится целиком неиспользуемым**: создание записей остаётся.

---

# /etc/skel и демо 07

| Файл шаблона Ubuntu | Назначение |
|---|---|
| .profile | Окружение login shell |
| .bashrc | Настройки интерактивного Bash |
| .bash_logout | Действия при выходе login Bash |

~~~console
$ useradd -m -k /etc/skel -s /bin/bash ossec-demo
$ ls -a /home/ossec-demo
.  ..  .bash_logout  .bashrc  .profile
$ usermod -c 'Course demonstration account' ossec-demo
$ userdel -r ossec-demo
~~~

**07-user-lifecycle.sh** использует временный home, показывает defaults.
Изменение skel не обновляет старые home. PAM mkhomedir может копировать
шаблон при первом входе удалённого пользователя.

---

# Вход в ОС: последовательность

1. getty/login либо sshd получает имя.
2. NSS возвращает UID, основной GID, home и shell.
3. PAM authenticate подтверждает личность; account проверяет допустимость входа.
4. Настраиваются дополнительные группы, GID/UID и окружение.
5. Открывается PAM session, обновляются журналы, запускается shell.

Детальный порядок зависит от приложения.
У SSH проверку ключа выполняет sshd; PAM account/session могут применяться отдельно.
su из root обычно не требует пароль цели и **не доказывает** парольную аутентификацию.

---

# Где сохраняются сведения о входах

| Файл Ubuntu | Формат / смысл | Просмотр |
|---|---|---|
| /run/utmp | Бинарные utmp-записи, текущие сессии | who, w, utmpdump |
| /var/log/wtmp | История utmp: входы, выходы, загрузки | last |
| /var/log/btmp | Неудачные попытки, utmp-формат | lastb (root) |
| /var/log/lastlog | Разреженный файл: struct lastlog по смещению UID | lastlog |
| /var/log/auth.log | Текст, если настроен rsyslog | less, tail |
| systemd journal | Структурированные события служб | journalctl |

Это не CSV. Запись ведёт приложение: не каждое окно терминала создаёт utmp.
btmp и auth-журналы могут быть доступны только привилегированным читателям.

---
class: lecture-iam dense
---

# struct utmp: Linux/glibc, &lt;utmp.h&gt;

~~~c
struct exit_status { short int e_termination; short int e_exit; };
struct utmp {
    short int ut_type;
    pid_t ut_pid;
    char ut_line[32];     /* terminal */
    char ut_id[4];
    char ut_user[32];
    char ut_host[256];
    struct exit_status ut_exit;
#if __WORDSIZE_TIME64_COMPAT32
    int32_t ut_session;
    struct { int32_t tv_sec; int32_t tv_usec; } ut_tv;
#else
    long int ut_session;
    struct timeval ut_tv;
#endif
    int32_t ut_addr_v6[4];
    char __glibc_reserved[20];
};
~~~

Все поля и ветви ABI сохранены; атрибуты компилятора опущены, размеры подставлены.
ut_type: USER_PROCESS=7, DEAD_PROCESS=8, BOOT_TIME=2. Строки могут не иметь NUL.

---

# Демо 08: настоящая login-сессия

~~~console
$ script -q -c /bin/login /dev/null
login: ossec-demo
Password:
$ who
ossec-demo pts/1 2026-09-06 12:00
$ w
 12:00:10 up 10 min, 1 user, load average: 0.00, 0.01, 0.00
USER       TTY   FROM  LOGIN@ IDLE JCPU PCPU WHAT
ossec-demo pts/1 -     12:00  0.00s ...  ...  -bash
$ exit
$ last -n 1 ossec-demo
ossec-demo pts/1 ... Sun Sep 6 12:00 - 12:01 (00:01)
~~~

**08-login-accounting.sh**. /dev/null отбрасывает transcript команды script.
Данные login сохраняются приложением в системных журналах.

---

# Последний вход, ошибки и ограничения аудита

~~~console
$ lastlog -u ossec-demo
Username         Port     From             Latest
ossec-demo       pts/1                      Sun Sep  6 12:00:00 +0000 2026
$ lastb -n 1 ossec-demo
ossec-demo       tty...                     Sun Sep 6 11:59 - 11:59 (00:00)
$ journalctl -b _COMM=login
... login[...]: pam_unix(login:session): session opened for user ...
~~~

Для lastb сначала нужна неудачная попытка.
lastlog может показать Never logged in, если путь входа его не обновляет.
Ротация, PAM и доступность журналов влияют на вывод.

Скрипт 08 сохраняет следы входов. Полный возврат учебной VM — снимком.

---

# su и sudo: чьи полномочия, чей пароль

| | su | sudo |
|---|---|---|
| Назначение | Shell/команда другого пользователя | Команда по политике |
| Пароль обычно | Цели; root освобождён | Вызывающего пользователя |
| Политика | PAM, ограничения su | sudoers + PAM |
| Login-окружение | su - alice | sudo -i |

~~~console
$ su - alice
Password:
$ sudo -u www-data id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
~~~

Ubuntu root часто имеет заблокированный пароль; администратор использует sudo.
rootpw/targetpw/runaspw в sudoers могут изменить правило проверки пароля.

---

# sudoers: группа не обладает магией сама по себе

~~~text
# /etc/sudoers (типичное правило Ubuntu)
%sudo ALL=(ALL:ALL) ALL
# who where=(runas_user:runas_group) commands

@includedir /etc/sudoers.d
~~~

~~~console
$ visudo
$ visudo -f /etc/sudoers.d/ossec-demo
$ visudo -c
/etc/sudoers: parsed OK
~~~

%sudo обозначает группу. Разрешение даёт правило, не GID сам по себе.
Фрагменты root:root, обычно 0440. Не добавлять расширение .conf:
includedir обычно пропускает имена с точкой.

---

# Демо 09: ограниченное NOPASSWD

~~~text
ossec-demo ALL=(root) /usr/bin/id
# Затем меняем проверенное visudo правило:
ossec-demo ALL=(root) NOPASSWD: /usr/bin/id
~~~

~~~console
$ sudo -l
... (root) NOPASSWD: /usr/bin/id
$ sudo -k -n /usr/bin/id
uid=0(root) gid=0(root) groups=0(root)
~~~

**09-su-sudo.sh**. Сначала запрос пароля, затем -k -n:
кэш сброшен, интерактивный запрос запрещён.
Не выдавать NOPASSWD: ALL ради одной команды; shell/редактор могут дать root-shell.
Фрагмент удаляется при завершении.

---

# NSS: одно имя на множестве машин

Ручное копирование passwd приводит к конфликтам UID, устаревшим записям,
несогласованному удалению пользователей и размножению чувствительных данных.

**Name Service Switch** в libc выбирает источники каждой базы:
passwd, group, hosts, services и других.

~~~text
application → getpwnam("ldapstudent") → NSS
                                       ├─ files → /etc/passwd
                                       └─ sss → SSSD → LDAP
~~~

Приложение получает тот же struct passwd независимо от источника.
Согласованные UID/GID важны для общих файловых систем; имён недостаточно.

---

# Каталог, протокол, посредник

| Термин | Что это |
|---|---|
| LDAP | Протокол доступа к каталогу; OpenLDAP — сервер |
| NIS | Историческое распространение Unix-баз; слабая модель доверия |
| Active Directory | Каталог и доменные службы, LDAP/Kerberos |
| Winbind | Компонент Samba для Windows-доменов, NSS/PAM |
| SSSD | Демон: идентичности, аутентификация, кэширование |

SSSD и Winbind — **не типы баз данных**.
Для AD выбирают SSSD с AD provider либо Samba/Winbind под задачи системы.
LDAP simple bind требует защищённого канала.

---

# /etc/nsswitch.conf: базы, источники, действия

~~~text
passwd: files systemd sss
group:  files systemd sss
shadow: files
hosts:  files dns
~~~

Слева — база; справа — порядок провайдеров.
Результат: SUCCESS, NOTFOUND, UNAVAIL, TRYAGAIN.
Обычные defaults: SUCCESS → return, остальные → continue.

~~~text
hosts: files mdns4_minimal [NOTFOUND=return] dns
~~~

Скобки меняют действие для **предыдущего** провайдера.
Ошибочное правило может оборвать поиск до нужного источника.

---

# Ubuntu: типичный исходный nsswitch.conf

~~~text
passwd:         files systemd
group:          files systemd
shadow:         files
gshadow:        files
hosts:          files dns
networks:       files
protocols:      db files
services:       db files
ethers:         db files
rpc:            db files
netgroup:       nis
~~~

Базовый Ubuntu Server 24.04; Desktop, образы и пакеты могут
добавлять mdns4_minimal, resolve, myhostname, sss.
nis в netgroup не означает настроенную NIS-аутентификацию.
Файл — **nsswitch.conf**, не /etc/nsswitch.h.

---

# service_user: историческая реализация NSS

~~~c
/* glibc 2.31: internal header nss/nsswitch.h */
typedef struct service_user {
    struct service_user *next;
    lookup_actions actions[5];
    service_library *library;
    void *known;
    char name[0];
} service_user;
~~~

name — провайдер; next — следующий; actions — реакции на статус;
library и known — библиотека и кэш функций.
Имя базы — в name_database_entry, не в service_user.

Полный исторический состав. В **glibc 2.39 Ubuntu 24.04 структуры нет**:
используется struct nss_action. Заголовок внутренний, стабильного публичного ABI нет.

---

# Демо LDAP: две одноразовые VM

~~~text
client Ubuntu 24.04                      server Ubuntu 24.04
login → pam_sss → SSSD ─── STARTTLS ───→ OpenLDAP :1389
getent → NSS sss ────→ SSSD             dc=ossec,dc=test
                                       ldapstudent / UID 20000
~~~

**10-ldap-server.sh**, **11-ldap-client.sh**.
Частная сеть; временная база и сертификат с SAN IP.
На клиент копируется только публичный сертификат; сверяем SHA-256 fingerprint.

Серверный терминал остаётся открытым до завершения клиента.
Сеть, зависимости, порядок запуска и откат — в README демо.

---
class: lecture-iam dense
---

# Демо 10–11: SSSD и проверка пароля

~~~ini
[sssd]
config_file_version = 2
services = nss, pam
domains = ossec
[domain/ossec]
id_provider = ldap
auth_provider = ldap
access_provider = permit
ldap_uri = ldap://192.168.56.10:1389
ldap_search_base = dc=ossec,dc=test
ldap_id_use_start_tls = true
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/sssd/ossec-demo-ca.crt
~~~

/etc/sssd/sssd.conf — root:root, 0600; дополнительные параметры — в скрипте.
permit подходит только учебному каталогу; реальный доступ ограничивают политикой.
NSS sss возвращает UID/GID; pam_sss аутентифицирует через SSSD.

---

# Демо 11: локальной строки нет, вход работает

~~~console
$ grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf
passwd: files systemd sss
group: files systemd sss
shadow: files
$ grep '^ldapstudent:' /etc/passwd
$ getent passwd ldapstudent
ldapstudent:*:20000:20000:LDAP Student:/home/ldapstudent:/bin/bash
$ id ldapstudent
uid=20000(ldapstudent) gid=20000(ldapstudents) groups=20000(ldapstudents)
$ ldapwhoami -x -ZZ -H ldap://192.168.56.10:1389 \
    -D uid=ldapstudent,ou=People,dc=ossec,dc=test -W
dn:uid=ldapstudent,ou=People,dc=ossec,dc=test
~~~

Второе поле getent может отличаться. Хэш LDAP **не переносится в /etc/shadow**.

---

# Демо 11: вход и диагностика

~~~console
$ script -q -c /bin/login /dev/null
login: ldapstudent
Password:
$ id -u
20000
$ pwd
/home/ldapstudent
$ exit
~~~

- getent не работает → NSS, соединение, поиск LDAP, UID/GID.
- getent работает, вход нет → TLS, пароль, PAM, account.
- Вход есть, home нет → pam_mkhomedir, права, session.

Проверяем пароль через login, не root su.
После клиента восстанавливаем NSS/PAM, останавливаем сервер; полный reset — snapshots.

---

# Проверим понимание

1. Почему строка root с UID 1000 не делает процесс суперпользователем?
2. Почему пользователя может не быть в gr_mem его основной группы?
3. Что сдвинется после passwd: sp_max или вычисленная дата истечения?
4. Защищает ли соль от перебора одного украденного verifier?
5. Доказывает ли успешный getent успешность аутентификации?

Ответы: credentials числовые; primary GID в passwd; дата;
нет, повышает стоимость массового подбора; нет, NSS и PAM решают разные задачи.

---

# Источники: форматы и администрирование

- [passwd(5)](https://manpages.ubuntu.com/manpages/noble/man5/passwd.5.html),
  [group(5)](https://manpages.ubuntu.com/manpages/noble/man5/group.5.html),
  [shadow(5)](https://manpages.ubuntu.com/manpages/noble/man5/shadow.5.html),
  [gshadow(5)](https://manpages.ubuntu.com/manpages/noble/man5/gshadow.5.html).
- [useradd(8)](https://manpages.ubuntu.com/manpages/noble/man8/useradd.8.html),
  [usermod(8)](https://manpages.ubuntu.com/manpages/noble/man8/usermod.8.html),
  [userdel(8)](https://manpages.ubuntu.com/manpages/noble/man8/userdel.8.html),
  [login.defs(5)](https://manpages.ubuntu.com/manpages/noble/man5/login.defs.5.html).
- [utmp(5)](https://man7.org/linux/man-pages/man5/utmp.5.html),
  [nsswitch.conf(5)](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html),
  [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/).
- [Ubuntu: SSSD with LDAP](https://documentation.ubuntu.com/server/how-to/sssd/with-ldap/index.html).
- [GNU libc: NSS](https://www.gnu.org/software/libc/manual/html_node/Name-Service-Switch.html).

Точные версии и особенности системы: локальные man-страницы Ubuntu 24.04.

---

# Источники: программирование, история, криптография

- Michael Kerrisk. *The Linux Programming Interface*, No Starch Press, 2010.
- W. Richard Stevens, Stephen A. Rago. *Advanced Programming in the UNIX Environment*, 3rd ed., 2013.
- Evi Nemeth et al. *UNIX and Linux System Administration Handbook*, 5th ed., 2017.
- Morris & Thompson. [Password Security: A Case History](https://doi.org/10.1145/359168.359172), CACM, 1979.
- E. Spafford. [The Internet Worm Program: An Analysis](https://spaf.cerias.purdue.edu/tech-reps/823.pdf), 1988.
- glibc [2.31 nsswitch.h](https://github.com/bminor/glibc/blob/glibc-2.31/nss/nsswitch.h)
  и [2.39 nsswitch.h](https://github.com/bminor/glibc/blob/release/2.39/master/nss/nsswitch.h).
- [libxcrypt crypt(5)](https://github.com/besser82/libxcrypt/blob/develop/doc/crypt.5),
  [PBKDF2 — RFC 8018](https://www.rfc-editor.org/rfc/rfc8018.html),
  [Argon2 — RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html).

Демо и инструкция: assets/demos/README.md. Следующая лекция — PAM.
