# Захваченные выводы (captures)

Курируемые транскрипты терминальных сессий для слайдов лекции 3 (PAM); показываются
компонентом `TerminalCapture` (секции разделены строками `===== Заголовок =====`).

Все транскрипты сняты 25.10.2026 в одноразовом контейнере `ubuntu:26.04`
(Ubuntu 26.04.1 LTS, Linux-PAM 1.7.0-5ubuntu3.2, hostname `srv`). Пользователи:
`bob` (UID 1001), `carol` (1002), `alice` (1003). Дополнительно установлены:
`openssh-server` (PermitRootLogin yes, KbdInteractiveAuthentication yes — для
демо), `gdm3` (--no-install-recommends, ради файлов `/etc/pam.d/gdm-*`),
`libpam-google-authenticator`, `oathtool`, `libpam-pwquality` (по ходу демо 05),
`rsyslog`, `gcc`, `libpam-dev`. Интерактивные сессии записаны через expect;
пароли при вводе не отображаются и перечислены в комментариях `# …`.
Табуляция развёрнута (`expand -t 8`), иначе колонки TCallout съезжают.

- `01-pam-locations.txt` — где живёт PAM: `ldd` PAM-aware программ, каталог
  модулей, `/etc/pam.d/`, `/etc/pam.conf`, отсутствующий `/usr/lib/pam.d/`,
  `/etc/security/` (листинги каталогов отформатированы в колонки).
  Снято после установки openssh-server и gdm3 (в `/etc/pam.d/` видны их файлы).
- `02-common-files.txt` — файлы `common-*` и `other` в состоянии по умолчанию
  (до установки libpam-pwquality; `common-session` содержит `pam_systemd`,
  добавленный libpam-systemd при установке gdm3/openssh — как на реальном
  сервере).
- `03-service-files.txt` — `login`, `sshd`, `gdm-password` без комментариев.
- `04-nologin.txt` — демо 01: `/etc/nologin`, отказ bob, вход root.
- `05-access-listfile.txt` — демо 02: pam_access (`-:bob:ALL`) и pam_listfile;
  в секции 2 пять одинаковых попыток сведены к показанным.
- `06-time.txt` — демо 03: правило `sshd;*;bob;!Al0000-2400`.
- `07-limits.txt` — демо 04: `hard fsize 1024`, сеанс bob снят целиком
  (приветствие Ubuntu сокращено до первой строки).
- `08-password-policy.txt` — демо 05: установка libpam-pwquality (вывод apt
  сокращён до строки Setting up), политика из PAM.pptx (retry=7 minlen=10
  d/u/l/ocredit=-2 dictcheck=0), диалог passwd, pam_pwhistory remember=3,
  `/etc/security/opasswd` (хэши заменены на `<хэши>`).
- `09-faillock.txt` — демо 06: deny=5/unlock_time=900, прыжок pam_unix
  исправлен на success=2; пять одинаковых неудачных попыток свёрнуты в одну
  с ремаркой.
- `10-totp.txt` — демо 07: google-authenticator для alice (QR-код заменён
  ремаркой; секрет и scratch-коды одноразового контейнера показаны как есть),
  подключение к sshd, вход с верным и неверным кодом.
- `11-authprint.txt` — демо 08: сборка `src/authprint.c`, запуск через other,
  собственная служба с pam_listfile (bob разрешён, carol отклонена), строка
  syslog (timestamp сокращён).
- `12-pam-math.txt` — демо 09: сборка/установка `src/pam_math.c`, служба
  mathtest (клиент — authprint), подключение модуля вторым фактором в sshd.
