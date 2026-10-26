# Демонстрации лекции 4

Нумерованные сценарии повторяют демонстрации слайдов (номера совпадают с
файлами в `../captures/`). Запуск — **только в одноразовой ВМ**
Ubuntu Server 26.04:

```console
sudo env OSSEC_DEMO_VM=1 bash 01-file-perms.sh
```

Каждый сценарий сам создаёт одноразовых пользователей (`ossec-bob`,
`ossec-alice`, `ossec-carol`, `ossec-dave`, в демо 14 — `ossec-johnny`) и
удаляет их при завершении; изменяемые системные файлы резервируются
(`backup_file`/`restore_files` в `lib/common.sh`) и восстанавливаются даже
при ошибке посередине. Ожидаемые отказы (`Permission denied`,
`Operation not permitted`) — часть демонстраций: сценарий продолжает работу.

Требования: базовая система + `gcc`, `acl`, `attr`, `libcap2-bin`,
`e2fsprogs`, `xxd`; для 09 — работающие `rsyslog` и `openssh-server`;
для 11 — возможность создавать loop-устройства. Исходные тексты программ
(`userinfo.c`, `groupinfo.c`, `hello.c`, `file_reader.c`) — в `../src/`.

| Сценарий | Слайды | Что показывает |
|---|---|---|
| `01-file-perms.sh` | раздел 2.1 | ELF без `r`; скрипт и шебанг |
| `02-dir-perms.sh` | раздел 2.1 | `r`/`x`/`w` на каталоге |
| `03-setuid.sh` | раздел 2.3 | setuid, буква `S`, скрипты |
| `04-setgid.sh` | раздел 2.4 | setgid на файле и каталоге |
| `05-sticky.sh` | раздел 2.5 | sticky-бит в /tmp |
| `06-umask.sh` | раздел 2.6 | umask 022/077 |
| `08-chattr-immutable.sh` | раздел 5.2 | `+i` на PAM-конфигах (с восстановлением) |
| `09-chattr-append.sh` | раздел 5.2 | `+a` на auth.log |
| `10-chattr-dir.sh` | раздел 5.2 | `a`/`i` на каталоге |
| `11-secure-delete.sh` | раздел 5.3 | атрибут `s` не работает (ext2, loop) |
| `12-xattr.sh` | раздел 6 | пространства имён, setcap |
| `13-acl-basics.sh` | раздел 7.1 | минимальный/расширенный ACL |
| `14-acl-algorithm.sh` | раздел 7.2 | алгоритм проверки, johnny, O_RDWR |
| `15-acl-mask.sh` | раздел 7.3 | chmod и ACL_MASK |
| `16-acl-default.sh` | раздел 7.4 | default ACL |

Демонстрации 8–11 предполагают, что соответствующие пути лежат на ext4
(в контейнере поверх overlayfs `chattr` и loop-устройства не работают —
см. `../captures/README.md`).
