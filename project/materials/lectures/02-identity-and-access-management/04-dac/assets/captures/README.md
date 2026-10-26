# Захваченные выводы (captures)

Курируемые транскрипты терминальных сессий для слайдов лекции 4 (механизмы
разграничения доступа); показываются компонентом `TerminalCapture`
(секции разделены строками `===== Заголовок =====`).

Транскрипты 01–06 и 08–16 сняты 25.10.2026 в одноразовом **privileged**
контейнере `ubuntu:26.04` (Ubuntu 26.04.1 LTS, hostname `srv`). Пользователи:
`bob` (UID 1001, sudo без пароля — в транскриптах `$`-prompt), `carol` (1002),
`alice` (1003), `dave` (1004); в капчере 14 дополнительно создаётся `johnny`
(1005, член групп alice/carol/dave). Чтобы работали `chattr` и loop-устройства
(overlayfs их не поддерживает), поверх `/etc/pam.d`, `/var/log`, `/tmp` и
`/home` смонтирован образ ext4 (`/e4.img`, bind-mount). Для капчера 09 в
контейнере запущены `rsyslogd` и `sshd` (после рестарта rsyslog нужно
перезапускать sshd, иначе он пишет в удалённый сокет `/dev/log`);
интерактивный вход по ssh записан через expect. `07-inodes.txt` снят на
рабочей машине (реальная ext4 с миллионами inode). Фрагменты кода ядра на
слайдах — не captures, а листинги из github (v6.18).

Курирование: табуляция развёрнута (`expand -t 8`), хвостовые пробелы сняты,
префикс ошибок bash-редиректов приведён к интерактивному виду (`bash: …`),
прогресс-строки `mkfs.ext2` (CR-перерисовка) свёрнуты до итоговых `… done`.
Остальной вывод — дословный.

- `01-file-perms.txt` — права файлов: ELF исполняется без `r` (копия
  сохраняет имя `ls` — coreutils 26.04 multi-call), скрипту нужны `r`+`x`,
  шебанг.
- `02-dir-perms.txt` — каталоги: `r` без `x` (знаки `?`), `x` без `r`,
  `w` только с `x`.
- `03-setuid.txt` — setuid-root в /usr/bin; `userinfo` (assets/src);
  буква `S`; setuid на скрипте игнорируется.
- `04-setgid.txt` — `groupinfo`; setgid-каталог: наследование группы.
- `05-sticky.txt` — удаление чужого файла: свой каталог vs `/tmp` c `t`.
- `06-umask.txt` — umask 022/077 при создании файлов и каталогов.
- `07-inodes.txt` — `df --inodes /` (мотивация хранения прав в inode).
- `08-chattr-immutable.txt` — `+i` на /etc/pam.d/common-*: отказ root;
  тестовые строки «# edited …» после записи удалены из файлов.
- `09-chattr-append.txt` — `+a` на /var/log/auth.log: ssh-вход дописывает,
  root не может усечь/удалить; след `hehehe` затем удалён, rsyslog — HUP.
- `10-chattr-dir.txt` — `a`/`i` на каталоге /tmp/experiments.
- `11-secure-delete.txt` — ext2 на loop: `+s` не перезаписывает блок
  (debugfs/dd — чтение устройства в обход ФС).
- `12-xattr.txt` — пространства имён user/trusted/security; setcap и
  `security.capability`.
- `13-acl-basics.txt` — минимальный vs расширенный ACL;
  `system.posix_acl_access`.
- `14-acl-algorithm.txt` — алгоритм проверки: владелец, именованный
  пользователь, группы, johnny (права из разных записей), `file_reader`
  (O_RDWR требует rw в одной записи).
- `15-acl-mask.txt` — chmod↔маска, `#effective`, маска в выводе `ls`.
- `16-acl-default.txt` — default ACL: наследование, umask не используется,
  независимость списков, `system.posix_acl_default`.
