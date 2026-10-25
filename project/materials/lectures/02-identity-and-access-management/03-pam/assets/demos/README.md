# Демо к лекции 3 (PAM)

Эталон — одноразовые **Ubuntu Server 26.04 LTS VM** (Linux-PAM 1.7.0), Bash, локаль вывода C.
Все сценарии правят «живую» конфигурацию PAM и требуют root; тронутые файлы
копируются в резерв и восстанавливаются при выходе (`backup_file`/`restore_files`
в `lib/common.sh`). Тем не менее запускайте их **только на одноразовой VM со снимком**:
ошибка в стеке PAM может заблокировать вход в систему целиком.

Нумерация задаёт учебный каталог, а не зависимости; исключение — демо 09,
использующее программу `authprint` из демо 08 как тестовый клиент.

## Подготовка

~~~bash
sudo apt-get update
sudo apt-get install openssh-server gcc libpam0g-dev libpam-pwquality \
  libpam-google-authenticator oathtool shellcheck
~~~

Запуск:

~~~bash
bash 01-nologin.sh --help
sudo env OSSEC_DEMO_VM=1 bash 01-nologin.sh
~~~

## Сценарии

| № | Файл | Модули | Захват |
|---|------|--------|--------|
| 01 | `01-nologin.sh` | pam_nologin | `captures/04-nologin.txt` |
| 02 | `02-access-listfile.sh` | pam_access, pam_listfile | `captures/05-access-listfile.txt` |
| 03 | `03-time.sh` | pam_time | `captures/06-time.txt` |
| 04 | `04-limits.sh` | pam_limits | `captures/07-limits.txt` |
| 05 | `05-password-policy.sh` | pam_pwquality, pam_pwhistory | `captures/08-password-policy.txt` |
| 06 | `06-faillock.sh` | pam_faillock | `captures/09-faillock.txt` |
| 07 | `07-totp-ssh.sh` | pam_google_authenticator | `captures/10-totp.txt` |
| 08 | `08-authprint.sh` | libpam-приложение (`src/authprint.c`) | `captures/11-authprint.txt` |
| 09 | `09-pam-math.sh` | собственный модуль (`src/pam_math.c`) | `captures/12-pam-math.txt` |

Захваты 01–03 (`01-pam-locations.txt`, `02-common-files.txt`, `03-service-files.txt`) —
не демо, а снимки состояния системы; см. `../captures/README.md`.

Интерактивные проверки (вход по ssh, диалоги `passwd`) сценарии не автоматизируют:
они печатают команды, которые выполняются с другого терминала, и ждут Enter
перед откатом конфигурации.
