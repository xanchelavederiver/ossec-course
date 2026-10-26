# Демо к лекции 2 (новая версия)

Эталон — одноразовые **Ubuntu Server 26.04 LTS VM**, Bash, локаль вывода C.
Сценарии требуют root и меняют учётные записи (создают и удаляют временных
пользователей `ossec-demo1`/`ossec-demo2` и группу `ossec-proj`); запускайте
их **только на одноразовой VM со снимком**.

Демо 01–04 перенесены из старой версии лекции вместе со слайдами — их сценарии
остаются в `../../02-classical-unix-mechanisms_old/assets/demos/` (там они
пронумерованы 01, 02, 12, 13). Здесь лежат новые сценарии раздела 3.

## Подготовка

~~~bash
sudo apt-get update
sudo apt-get install whois util-linux-extra   # mkpasswd; newgrp/sg
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
