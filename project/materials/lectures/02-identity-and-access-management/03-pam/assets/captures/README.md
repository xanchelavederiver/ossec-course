# Захваченные выводы (captures)

Курируемые транскрипты терминальных сессий для слайдов лекции 3 (PAM); показываются
компонентом `TerminalCapture` (секции разделены строками `===== Заголовок =====`).

Транскрипты 01–12 сняты 25.10.2026 в одноразовом контейнере `ubuntu:26.04`
(Ubuntu 26.04.1 LTS, Linux-PAM 1.7.0-5ubuntu3.2, hostname `srv`). Пользователи:
`bob` (UID 1001), `carol` (1002), `alice` (1003). Дополнительно установлены:
`openssh-server` (PermitRootLogin yes, KbdInteractiveAuthentication yes – для
демо), `gdm3` (--no-install-recommends, ради файлов `/etc/pam.d/gdm-*`),
`libpam-google-authenticator`, `oathtool`, `libpam-pwquality` (по ходу демо 09),
`rsyslog`, `gcc`, `libpam-dev`. Интерактивные сессии записаны через expect;
пароли при вводе не отображаются и перечислены в комментариях `# …`.
Табуляция развёрнута (`expand -t 8`), иначе колонки TCallout съезжают.

- `01-pam-locations.txt` – где живёт PAM: `ldd` PAM-aware программ, каталог
  модулей, `/etc/pam.d/`, `/etc/pam.conf`, отсутствующий `/usr/lib/pam.d/`,
  `/etc/security/` (листинги каталогов отформатированы в колонки).
  Снято после установки openssh-server и gdm3 (в `/etc/pam.d/` видны их файлы).
- `02-common-files.txt` – файлы `common-*` и `other` в состоянии по умолчанию
  (до установки libpam-pwquality; `common-session` содержит `pam_systemd`,
  добавленный libpam-systemd при установке gdm3/openssh – как на реальном
  сервере).
- `03-service-files.txt` – `login`, `sshd`, `gdm-password` без комментариев.
- `04-nologin.txt` – демо 01: `/etc/nologin`, отказ bob, вход root.
- `05-access-listfile.txt` – демо 02: pam_access (`-:bob:ALL`) и pam_listfile;
  в секции 2 пять одинаковых попыток сведены к показанным.
  Секции 4–5 (разрешающий список `+:(admins):ALL` / `+:root:LOCAL` / `-:ALL:ALL`,
  alice – член группы `admins`, GID 1010) дозаписаны 17.11.2026.
- `06-time.txt` – демо 03: правило `sshd;*;bob;!Al0000-2400`.
- `07-limits.txt` – демо 04: `hard fsize 1024`, сеанс bob снят целиком
  (приветствие Ubuntu сокращено до первой строки).
  Секции 3–5 (`maxlogins`) дозаписаны 17.11.2026 в контейнере с systemd
  (см. ниже): подсчёт сеансов ведёт systemd-logind, сеанс менеджера
  `systemd --user` учитывается, значение 1 модуль отвергает.
- `08-password-policy.txt` – демо 09: установка libpam-pwquality (вывод apt
  сокращён до строки Setting up), политика из PAM.pptx (retry=7 minlen=10
  d/u/l/ocredit=-2 dictcheck=0), диалог passwd, pam_pwhistory remember=3,
  `/etc/security/opasswd` (хэши заменены на `<хэши>`).
- `09-faillock.txt` – демо 10: deny=5/unlock_time=900, прыжок pam_unix
  исправлен на success=2; пять одинаковых неудачных попыток свёрнуты в одну
  с ремаркой.
- `10-totp.txt` – демо 11: google-authenticator для alice (QR-код заменён
  ремаркой; секрет и scratch-коды одноразового контейнера показаны как есть),
  подключение к sshd, вход с верным и неверным кодом.
- `11-authprint.txt` – демо 12: сборка `src/authprint.c`, запуск через other,
  собственная служба с pam_listfile (bob разрешён, carol отклонена), строка
  syslog (timestamp сокращён).
- `12-pam-math.txt` – демо 13: сборка/установка `src/pam_math.c`, служба
  mathtest (клиент – authprint), подключение модуля вторым фактором в sshd.
- `13-login-paths.txt` – `sshd -V` и `sshd -T` (UsePAM и методы аутентификации
  OpenSSH 10.2p1 по умолчанию); снято 09.11.2026 в свежем контейнере ubuntu:26.04
  (openssh-server 1:10.2p1-2ubuntu3.8, libpam0g 1.7.0-5ubuntu3.2).
- `14-stack-examples.txt` – раздел 2.5: учебные службы `/etc/pam.d/demo-a…demo-e`
  (примеры A–E исполнения стека) и проверки `pamtester <служба> <пользователь>
  authenticate` (пакет pamtester); bob – член группы `operators` (GID 1004),
  carol – нет; пароли в ремарках `# …`; снято 09.11.2026 тем же контейнером
  (expect-driven ввод пароля).
- `15-distro-stacks.txt` – раздел 4.3–4.5: файлы PAM других дистрибутивов, сняты
  09.11.2026 в одноразовых контейнерах: `rockylinux/rockylinux:10` (Rocky Linux 10.2,
  pam 1.6.1-9.el10, authselect 1.5.2; доустановлены authselect, openssh-server;
  вывод `system-auth` показан через `tr -s ' '`, из `list-features` оставлены пять
  строк), `archlinux:latest` (pam 1.7.3-1, доустановлены openssh 10.6p1 и sudo),
  `registry.astralinux.ru/astra/ubi18` (Astra Linux SE 1.8.7, libpam 1.5.2 astra.se39;
  доустановлены parsec-mac/-aud/-cap 3.11, openssh-server, astra-safepolicy – после
  этого в `common-*` появились профили faillock и pwquality, а в файлах служб –
  строки pam_parsec_*). Файлы показаны без комментариев (`grep -Ev '^#|^$'`),
  табуляция развёрнута.
- `16-module-args.txt` – раздел 3.2–3.3: экспортируемые функции `pam_sm_*` (`nm -D`,
  пакет binutils), учебные службы `/etc/pam.d/demo-f…demo-k` (неподдерживаемый тип,
  `module_unknown=ignore`, `use_first_pass`/`try_first_pass`, незнакомый аргумент,
  `debug`, `nullok`) и проверки `pamtester`; снято 09.11.2026 в свежем контейнере
  ubuntu:26.04 (libpam 1.7.0-5ubuntu3.2; rsyslog для `/var/log/auth.log`, метки
  времени сокращены до часов; alice создана без пароля – `passwd -d`).
- `17-pam-auth-update.txt` – раздел 4.1: профили `/usr/share/pam-configs/` (`unix`,
  `mkhomedir`) и шаблон `/usr/share/pam/common-auth`; `pam-auth-update --enable /
  --disable mkhomedir`, сохранение ручной правки аргументов (удалён `nullok`),
  отказ от обновления после удаления маркера `# end of pam-auth-update config`
  (в неинтерактивном режиме – без сообщения) и пересборка `--force`; снято
  16.11.2026 в свежем контейнере `ubuntu:26.04` (libpam-runtime 1.7.0-5ubuntu3.2,
  `DEBIAN_FRONTEND=noninteractive`).
- `18-wheel.txt` – демо 05: pam_wheel в `/etc/pam.d/su` (`group=sudo`; alice – член
  группы sudo, bob – нет), отказ при верном пароле root, запись `FAILED SU`,
  поведение без `group=` (группы wheel в Ubuntu нет). Пароли перечислены в ремарках.
- `19-exec-hook.txt` – демо 06: сценарий `/usr/local/sbin/login-hook`, вызываемый
  pam_exec в стеке session службы sshd, запись в auth.log; вариант с флагом
  `required` и сценарием, завершающимся с кодом 1.
- `20-mkhomedir.txt` – демо 07: пользователь `dave` (UID 1004, создан `useradd -M`),
  профиль `mkhomedir`, `pam-auth-update --enable mkhomedir` (сообщения debconf об
  отсутствии терминала опущены), каталог после первого входа.
- `21-safe-edit.txt` – демо 08: правило pam_listfile в стеке auth и в стеке account,
  проверки `pamtester` и вход bob по ключу ed25519; опечатка в имени модуля
  (`pam_listflie.so`), записи журнала, откат из копии.

Захваты 18–21 и дозаписанные секции 05/07 сняты 17.11.2026 в контейнерах
`ubuntu:26.04` (libpam 1.7.0-5ubuntu3.2, openssh-server 1:10.2p1-2ubuntu3.8,
pamtester 0.1.2-4build1): разрешающий список pam_access – в обычном контейнере,
остальное – в контейнере с systemd в роли PID 1 (`--privileged`, `/sbin/init`;
работают systemd-logind и pam_systemd). В sshd дополнительно задано
`PerSourcePenalties no`: иначе после серии неудачных входов с 127.0.0.1 сервер
временно отклоняет новые соединения с этого адреса. Строки журнала выведены
через `grep -o`, поэтому показаны без метки времени и имени узла; приветствие
Ubuntu сокращено до первой строки, строка `Last login` опущена.
