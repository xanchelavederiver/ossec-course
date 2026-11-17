# Демо к лекции 3 (PAM)

Эталон – одноразовые **Ubuntu Server 26.04 LTS VM** (Linux-PAM 1.7.0), Bash, локаль вывода C.
Все сценарии правят «живую» конфигурацию PAM и требуют root; тронутые файлы
копируются в резерв и восстанавливаются при выходе (`backup_file`/`restore_files`
в `lib/common.sh`). Тем не менее запускайте их **только на одноразовой VM со снимком**:
ошибка в стеке PAM может заблокировать вход в систему целиком.

Нумерация задаёт учебный каталог, а не зависимости; исключение – демо 13,
использующее программу `authprint` из демо 12 как тестовый клиент.

## Подготовка

~~~bash
sudo apt-get update
sudo apt-get install openssh-server gcc libpam0g-dev libpam-pwquality \
  libpam-google-authenticator oathtool pamtester binutils shellcheck
~~~

Запуск:

~~~bash
bash 01-nologin.sh --help
sudo env OSSEC_DEMO_VM=1 bash 01-nologin.sh
~~~

## Сценарии

| № | Файл | Модули | Захват |
|---|------|--------|--------|
| 00 | `00-stack-examples.sh` | исполнение стека: pam_succeed_if, pam_deny, pam_permit, pam_nologin + `pamtester` (раздел 2.5) | `captures/14-stack-examples.txt` |
| 00 | `00-module-args.sh` | предоставляемые типы (`nm -D`), PAM_MODULE_UNKNOWN и `module_unknown=ignore`, `use_first_pass`/`try_first_pass`, незнакомый аргумент, `debug`, `nullok` + `pamtester` (разделы 3.2–3.3) | `captures/16-module-args.txt` |
| 01 | `01-nologin.sh` | pam_nologin | `captures/04-nologin.txt` |
| 02 | `02-access-listfile.sh` | pam_access (запрет, разрешающий список), pam_listfile | `captures/05-access-listfile.txt` |
| 03 | `03-time.sh` | pam_time | `captures/06-time.txt` |
| 04 | `04-limits.sh` | pam_limits: `fsize`, `maxlogins` | `captures/07-limits.txt` |
| 05 | `05-wheel.sh` | pam_wheel в службе `su` | `captures/18-wheel.txt` |
| 06 | `06-exec-hook.sh` | pam_exec: сценарий при открытии сеанса | `captures/19-exec-hook.txt` |
| 07 | `07-mkhomedir.sh` | pam_mkhomedir через `pam-auth-update` | `captures/20-mkhomedir.txt` |
| 08 | `08-safe-edit.sh` | порядок правки: копия, `pamtester`, вход по ключу и по паролю, опечатка в имени модуля | `captures/21-safe-edit.txt` |
| 09 | `09-password-policy.sh` | pam_pwquality, pam_pwhistory | `captures/08-password-policy.txt` |
| 10 | `10-faillock.sh` | pam_faillock | `captures/09-faillock.txt` |
| 11 | `11-totp-ssh.sh` | pam_google_authenticator | `captures/10-totp.txt` |
| 12 | `12-authprint.sh` | libpam-приложение (`src/authprint.c`) | `captures/11-authprint.txt` |
| 13 | `13-pam-math.sh` | собственный модуль (`src/pam_math.c`) | `captures/12-pam-math.txt` |

Захваты 01–03 (`01-pam-locations.txt`, `02-common-files.txt`, `03-service-files.txt`) –
не демо, а снимки состояния системы; см. `../captures/README.md`.

Интерактивные проверки (вход по ssh, диалоги `passwd`) сценарии не автоматизируют:
они печатают команды, которые выполняются с другого терминала, и ждут Enter
перед откатом конфигурации.

Особенности отдельных сценариев:

- демо 02 (разрешающий список) закрывает вход по ssh всем, кроме группы
  `ossec-admins` и пользователя, запустившего сценарий через `sudo`
  (`SUDO_USER`); остальные учётные записи VM до отката по ssh не войдут;
- демо 04 (`maxlogins`) требует работающего systemd-logind: Ubuntu 26.04 считает
  сеансы logind, включая сеанс менеджера `systemd --user`, поэтому значение 2
  допускает один вход, а значение 1 модуль отвергает;
- демо 05 требует пароля root (`passwd root`) – иначе `su` нечем проверять;
- демо 08 на третьем шаге закрывает вход по ssh всем, включая root: сеанс, в
  котором запущен сценарий, до завершения не закрывать;
- после серии неудачных входов sshd (OpenSSH ≥ 9.8) временно отклоняет новые
  соединения с того же адреса; на учебной VM это отключается строкой
  `PerSourcePenalties no` в `sshd_config`.
