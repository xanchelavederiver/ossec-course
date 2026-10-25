---
theme: default
title: Pluggable Authentication Modules
author: OSSec
addons: [../../../theme]
layout: cover
colorSchema: light
duration: 90min
mdc: true
selectable: true
transition: slide-left
defaults:
  class: lecture-pam
---

# Лекция 3

## Pluggable Authentication Modules

<!--
Сквозные правила деки: номер слайда — в правом нижнем углу (тема);
внизу каждого слайда (кроме демо) — блок «Источники: [n]» (<Refs ids="…"/>,
номера по sources.json, клик ведёт на слайд routeAlias: refs и подсвечивает
источник); упоминания man-страниц — ссылки (<Man p="name(sec)"/>).
Демонстрационная среда — Ubuntu Server 26.04 LTS, Linux-PAM 1.7.0;
захваты сняты в одноразовом контейнере (assets/captures/README.md).
-->

---
layout: default
---

# План лекции

<div class="grid grid-cols-2 gap-x-8 mt-4 plan-list">
<div>

1. **Введение** — зачем нужен PAM
2. **Устройство PAM** — библиотека, модули, конфигурация, типы, флаги, стек
3. **Конфигурация Ubuntu Server 26.04** — файлы `common-*`; `login`, `gdm-password`, `sshd`
4. **Административные задачи** — pam_nologin, pam_access, pam_listfile, pam_time, pam_limits
5. **Парольная политика** — pam_pwquality, pam_pwhistory, pam_faillock

</div>
<div>

6. **Двухфакторная аутентификация** — TOTP, аппаратные ключи
7. **PAM в собственных программах** — libpam API, программа `authprint`
8. **Разработка модуля PAM** — интерфейс модуля, `pam_math.so`
9. **Реализация Linux-PAM** — структуры, разбор конфигурации, исполнение стека

<div class="mt-4 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Сквозной пример: сервер Ubuntu 26.04, пользователи <code>bob</code>, <code>alice</code>,
<code>carol</code>; разделы 4–8 сопровождаются демонстрациями
(<code>assets/demos/01–09</code>).
</div>

</div>
</div>

<style>
.plan-list li { margin: 0.45em 0; }
</style>

<!--
Девять разделов. Сначала мотивация: какие задачи не решаются классическими
механизмами лекции 2. Затем устройство PAM и его конфигурация на Ubuntu 26.04.
Разделы 4–6 — администрирование: типовые задачи, парольная политика, второй
фактор. Разделы 7–8 — программирование: использование libpam в своих программах
и разработка собственного модуля. Раздел 9 — чтение исходного кода Linux-PAM.
-->

---
layout: section
---

# 1. Введение
## Зачем нужен PAM

---

# Чего не хватает классическим механизмам

В лекции 2 аутентификация выглядела так: программа сама читает базы учётных записей
и сама сверяет хеш пароля.

<BlockFlow class="mt-2 mb-3" :blocks="[
  { head: 'login, sshd, su, passwd…', sub: 'логика проверки\nзашита в каждую программу' },
  { head: 'crypt(3)', sub: 'сверка хеша' },
  { head: '/etc/passwd, /etc/shadow', mono: true, sub: 'единственный источник\nучётных данных' },
]" :arrows="['вызывает', 'читает']" />

<div class="grid grid-cols-3 gap-3">
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Проверка зашита в код</b><br/>
новый способ аутентификации — смарт-карта, одноразовый код — требует
<b>изменить и перекомпилировать</b> каждую программу входа
</div>
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Источник данных фиксирован</b><br/>
только локальные файлы: учётные записи из сетевого каталога
(LDAP, Active Directory) этой схеме недоступны
</div>
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Политика не централизована</b><br/>
правила сложности пароля, блокировки, времени входа пришлось бы
дублировать в каждой программе
</div>
</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10">
<b>Решение</b> — промежуточный слой: точка аутентификации (программа) отделяется
от <b>службы аутентификации</b>; способы проверки становятся <b>подключаемыми
модулями</b>, которые выбирает администратор, а не разработчик программы.
</div>

</v-click>

<Refs ids="pam-sag osf-rfc86" />

<!--
Мост от лекции 2. Классическая схема: каждая программа входа самостоятельно
читает /etc/passwd и /etc/shadow и сверяет хеш. Три следствия. Во-первых,
логика проверки зашита в код: чтобы добавить второй фактор, пришлось бы править
и перекомпилировать login, sshd, su, sudo, passwd — у администратора исходного
кода нет. Во-вторых, источник учётных данных фиксирован: предприятию нужен
общий каталог на тысячи машин, а не локальные файлы на каждой. В-третьих,
политику не задать в одном месте. Решение известно из инженерии: промежуточный
слой. Его и предложили в 1995 году под именем PAM.
-->

---

# Назначение PAM

**PAM** (Pluggable Authentication Modules, подключаемые модули аутентификации) —
набор разделяемых библиотек, позволяющий администратору выбирать, **как приложения
аутентифицируют пользователей**, — без изменения кода и перекомпиляции приложений.

<div class="grid grid-cols-[1.25fr_1fr] gap-5 mt-3 items-start">
<div>

<div class="pam-map">
  <div class="bf-block pm-apps"><div class="bf-head">PAM-aware приложения</div><div class="bf-sub">login · sshd · su · sudo · passwd</div></div>
  <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
  <div class="bf-block pm-lib" :class="'bf-dark'"><div class="bf-head">libpam.so</div><div class="bf-sub">читает /etc/pam.d/&lt;служба&gt;,
вызывает модули по порядку</div></div>
  <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
  <div class="pm-mods">
    <div class="bf-block"><div class="bf-head">pam_unix.so</div><div class="bf-sub">/etc/shadow</div></div>
    <div class="bf-block"><div class="bf-head">pam_faillock.so</div><div class="bf-sub">счётчик неудач</div></div>
    <div class="bf-block"><div class="bf-head">pam_google_<br/>authenticator.so</div><div class="bf-sub">одноразовые коды</div></div>
    <div class="bf-block"><div class="bf-head">pam_sss.so</div><div class="bf-sub">каталог домена</div></div>
  </div>
</div>

</div>
<div>

**Что это даёт:**

- **модульность** — любая служба через модули работает с любым провайдером
  аутентификационной информации;
- **разнесение** точки аутентификации (приложения) и службы аутентификации;
- подключение провайдеров **без изменения кода** приложений — перекомпиляция
  не требуется: администратор меняет строку конфигурации.

<v-click>

<HistoryNote class="mt-2">
Идею описали В. Самар и Р. Шемерс (Sun Microsystems) в документе
OSF RFC 86.0 (октябрь 1995 г.); реализация Linux-PAM развивается с 1996 г.
В Ubuntu 26.04 — Linux-PAM 1.7.0.
</HistoryNote>

</v-click>

</div>
</div>

<Refs ids="osf-rfc86 pam-sag man-pam" />

<style>
.pam-map { display: flex; align-items: stretch; gap: 0; font-size: 0.72rem; text-align: center; }
.pam-map > .bf-block { flex: 1.1; display: flex; flex-direction: column; justify-content: center; }
.pam-map > .bf-arrow { flex: 0 0 1.6em; align-self: center; }
.pm-mods { flex: 1.15; display: flex; flex-direction: column; gap: 0.4em; }
.pm-mods .bf-block { padding: 0.25em 0.4em; }
</style>

<!--
Определение по руководству администратора Linux-PAM: suite of shared libraries
that enable the local system administrator to choose how applications
authenticate users. Схема: программы больше не проверяют пароли сами — они
обращаются к libpam, а та по конфигурационному файлу службы вызывает модули.
Каждый модуль умеет работать со своим провайдером: pam_unix — классические
файлы лекции 2, pam_faillock — счётчик неудач, pam_google_authenticator —
одноразовые коды, pam_sss — каталог домена. Три выгоды соответствуют трём
проблемам предыдущего слайда. История: OSF RFC 86.0, 1995; Linux-PAM — 1996.
-->

---

# Типовые задачи, решаемые через PAM

Классические механизмы отвечают на один вопрос — «совпал ли пароль с хешем
в `/etc/shadow`». Всё остальное — задачи модульного слоя:

<div class="t-table text-xs mt-2">

| Задача администратора | Классические механизмы | PAM |
|---|---|---|
| Единая политика сложности и истории паролей | логику пришлось бы дублировать в программах | `pam_pwquality`, `pam_pwhistory` — **раздел 5** |
| Блокировка учётной записи после N неудач | — | `pam_faillock` — **раздел 5** |
| Второй фактор: одноразовый код, аппаратный ключ | — | `pam_google_authenticator`, `pam_u2f` — **раздел 6** |
| Учётные записи из каталога домена (AD, FreeIPA) | — | `pam_sss` (служба sssd) + NSS |
| Запрет входа: всем, по списку, по времени | частично («запрещающие» оболочки) | `pam_nologin`, `pam_access`, `pam_listfile`, `pam_time` — **раздел 4** |
| Лимиты ресурсов сеанса пользователя | — | `pam_limits` — **раздел 4** |
| Собственная проверка в своей программе | писать с нуля | libpam API — **разделы 7–8** |

</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10">
Через PAM проходит <b>почти каждый вход в систему</b>: консоль, ssh, графический
сеанс, <code>su</code>/<code>sudo</code>, смена пароля. Ошибка в его конфигурации
равносильна отказу в обслуживании — или открытой двери.
</div>

</v-click>

<Refs ids="pam-sag man-pam" />

<!--
Мотивационная таблица: колонка «классические механизмы» почти пуста — эти
задачи либо не решаются файлами passwd/shadow вообще, либо требуют дублирования
логики в каждой программе. Каждая строка правой колонки — конкретный модуль, и
почти каждый мы увидим в работе: разделы 4–6 — административные демонстрации,
разделы 7–8 — программирование. Предупреждение внизу задаёт тон лекции: PAM —
критическая точка системы, через неё проходит каждый вход.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="1" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил',
  'Управляющие флаги',
  'Стек модулей',
]" />

---

# PAM-aware программы и библиотека libpam

**PAM-aware** — программа, скомпонованная с `libpam.so` и доверяющая ей
аутентификацию. Проверить это позволяет `ldd`:

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="1" title="Ubuntu Server 26.04 · ldd и пакет libpam" fontSize="0.5rem">
  <TCallout :line="2" :col="9" :span="11" :n="1" />
  <TCallout :line="3" :col="9" :span="16" :n="2" />
  <TCallout :line="11" :col="20" :span="16" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>libpam.so.0</code> — ядро PAM: разбор конфигурации и исполнение стека модулей</div>
<div><span class="co-ball">2</span> <code>libpam_misc.so.0</code> — вспомогательная библиотека: готовая функция диалога <code>misc_conv</code> (раздел 7)</div>
<div><span class="co-ball">3</span> версия: Linux-PAM <b>1.7.0</b> (пакет <code>libpam0g</code>)</div>
</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Сами способы проверки реализуются <b>модулями</b> — динамически подгружаемыми
библиотеками <code>pam_*.so</code>; libpam загружает их через <code>dlopen(3)</code>
при первом обращении службы (механика — раздел 9).
</div>

<Refs ids="man-pam pam-sag linux-pam-src" />

<!--
Термин PAM-aware: программа доверяет аутентификацию libpam. ldd показывает две
библиотеки: libpam — ядро (разбор конфигурации, исполнение стека), libpam_misc —
небольшая добавка для консольных приложений с готовой функцией диалога.
Версию см. по пакету: 1.7.0 в Ubuntu 26.04. Модули — отдельные .so, подгружаемые
динамически; поэтому новый способ аутентификации — это новый файл на диске плюс
строка конфигурации, а не пересборка программ.
-->

---

# Каталог модулей

<div class="grid grid-cols-[1.4fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="2" title="Ubuntu Server 26.04 · модули PAM" fontSize="0.5rem" highlight="5,11" />

</div>
<div>

Путь к каталогу модулей зависит от дистрибутива:

<div class="t-table text-xs mt-2">

| Семейство | Каталог модулей |
|---|---|
| Debian, Ubuntu | `/usr/lib/<triplet>/security`, напр. `/usr/lib/x86_64-linux-gnu/security` |
| RHEL, Fedora, РЕД ОС | `/usr/lib64/security` |
| умолчание Linux-PAM | `/lib/security`, `/lib64/security` |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<Man p="pam.conf(5)" />: относительный путь модуля в правиле отсчитывается
от каталога модулей по умолчанию; на практике в правилах пишут только
имя файла — <code>pam_unix.so</code>.
</div>

</div>
</div>

<div class="mt-2">

Уже в базовой системе — **45 модулей**: выделены `pam_deny.so` и `pam_faillock.so`,
с которыми мы будем работать; пакеты добавляют свои (`pam_pwquality.so`,
`pam_google_authenticator.so` — разделы 5–6).

</div>

<Refs ids="man-pam-conf linux-pam-src redos-pam rhel-pam" />

<!--
Каталог модулей. В Debian/Ubuntu — мультиархитектурный путь с triplet,
в семействе Red Hat (и в РЕД ОС) — /usr/lib64/security, upstream-умолчание —
/lib/security. Поэтому инструкции «положите модуль в /lib/security» из старых
руководств на современных системах не работают — путь нужно проверять.
45 модулей уже в базовой поставке; в правилах пишется только имя .so,
полный путь нужен лишь для модулей вне каталога по умолчанию.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="2" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил',
  'Управляющие флаги',
  'Стек модулей',
]" />

---

# Файлы конфигурации: /etc/pam.conf и /etc/pam.d

<div class="grid grid-cols-[1.3fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="3" title="Ubuntu Server 26.04 · конфигурация PAM" fontSize="0.5rem">
  <TCallout :line="1" :col="6" :span="11" :n="1" />
  <TCallout :line="12" :col="41" :span="13" :n="2" />
  <TCallout :line="14" :col="20" :span="15" :n="3" />
  <TCallout :line="15" :col="6" :span="14" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> современная схема: каталог <code>/etc/pam.d/</code> — <b>по файлу на службу</b>; имя файла = имя службы (<code>login</code>, <code>sshd</code>, <code>su</code>…)</div>
<div><span class="co-ball">2</span> исторический единый файл <code>/etc/pam.conf</code>: при наличии каталога <code>pam.d/</code> он <b>игнорируется</b></div>
<div><span class="co-ball">3</span> каталог поставщика <code>/usr/lib/pam.d/</code> (здесь отсутствует): одноимённый файл в <code>/etc/pam.d/</code> имеет приоритет</div>
<div><span class="co-ball">4</span> <code>/etc/security/</code> — собственные файлы параметров отдельных модулей</div>
</div>
</div>
</div>

<div class="mt-2 grid grid-cols-2 gap-3 text-xs">
<div class="p-2 border border-slate-400/40 rounded">
Строка <code>/etc/pam.conf</code>: <code class="font-bold">service type control module-path module-arguments</code>
</div>
<div class="p-2 border border-slate-400/40 rounded">
Строка файла в <code>/etc/pam.d/</code> — та же <b>без поля service</b>: <code class="font-bold">type control module-path module-arguments</code>
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Изначально вся конфигурация жила в одном файле /etc/pam.conf со строками из
пяти полей, первое — имя службы. Современные системы используют каталог
/etc/pam.d: по файлу на службу, имя файла — имя службы, поле service из строки
исчезает. При наличии pam.d файл pam.conf игнорируется — pam.d(5). Третье
место — /usr/lib/pam.d, куда пакеты могут класть свои конфигурации; при
коллизии имён побеждает /etc/pam.d (в Ubuntu 26.04 каталога поставщика нет).
Наконец /etc/security — не правила PAM, а файлы параметров конкретных модулей:
access.conf, faillock.conf, limits.conf и т. д.; мы будем редактировать их
в разделах 4–5.
-->

---

# Параметры модулей и журналирование

<div class="grid grid-cols-2 gap-4 items-start">
<div>

**Файлы параметров** — каталог `/etc/security/`:

<div class="t-table text-xs mt-2">

| Файл | Модуль | Раздел |
|---|---|---|
| `access.conf` | `pam_access` | 4.2 |
| `time.conf` | `pam_time` | 4.3 |
| `limits.conf` | `pam_limits` | 4.4 |
| `pwquality.conf` | `pam_pwquality` | 5 |
| `faillock.conf` | `pam_faillock` | 5 |
| `pam_env.conf` | `pam_env` | — |
| `opasswd` | `pam_pwhistory` (история хешей) | 5 |

</div>

<div class="mt-2 text-xs opacity-80">
Правило в <code>/etc/pam.d/</code> отвечает «<i>какой модуль и когда вызвать</i>»,
файл в <code>/etc/security/</code> — «<i>с какими параметрами он работает</i>»;
аргументы в строке правила имеют приоритет.
</div>

</div>
<div>

**Журналирование** — модули и libpam пишут в syslog
(facility `auth`/`authpriv`):

```text
2026-10-25T19:13:37 srv authprint:
  pam_listfile(authprint:auth):
  Refused user carol for service authprint
```

- Ubuntu: `/var/log/auth.log` (rsyslog) и `journalctl`;
- формат: `модуль(служба:тип): сообщение` — видно,
  **какой модуль какой службы** принял решение;
- неудачные входы, блокировки, ошибки конфигурации
  ищите именно здесь.

</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Разделение ответственности: правило в pam.d говорит, какой модуль вызвать и как
учесть результат; собственный файл модуля в /etc/security — его параметры.
Многие модули настраиваются и так и так: аргументы в строке правила имеют
приоритет над файлом (увидим на pam_pwquality). Правая колонка — где искать
диагностику: syslog, facility auth/authpriv; в Ubuntu — auth.log и journalctl.
Формат сообщений позволяет понять, какой модуль какой службы отказал, —
пример из нашего же демо раздела 7.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="3" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил',
  'Управляющие флаги',
  'Стек модулей',
]" />

---

# Четыре типа правил (группы управления)

Задачи, выполняемые модулями, разделены на **четыре независимые группы
управления** (management groups); поле `type` правила называет группу:

<div class="t-table text-xs mt-2">

| Тип | Вопрос | Что делают модули | Примеры |
|---|---|---|---|
| **auth** | «вы — тот, за кого себя выдаёте?» | запрашивают пароль или иное подтверждение подлинности; могут выдавать «удостоверения» (credentials) | `pam_unix`, `pam_google_authenticator` |
| **account** | «можно ли вам сейчас?» | проверки, не связанные с паролем: срок действия учётной записи, время суток, местоположение, список доступа | `pam_time`, `pam_access`, `pam_nologin` |
| **password** | «как обновить аутентификатор?» | смена пароля; именно здесь проверяется соответствие нового пароля политике | `pam_unix`, `pam_pwquality` |
| **session** | «что сделать до и после сеанса?» | журналирование входа/выхода, переменные окружения, лимиты ресурсов, монтирование каталогов | `pam_limits`, `pam_env`, `pam_motd` |

</div>

<v-click>

<div class="mt-3 grid grid-cols-2 gap-3 text-xs">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Аналогия с проходной (лекция 2): <b>auth</b> — «докажите, что пропуск ваш»;
<b>account</b> — «а действует ли пропуск сегодня?»; <b>session</b> — записать
в журнал и выдать ключ от кабинета; <b>password</b> — замена пропуска.
</div>
<div class="p-2 border border-slate-400/40 rounded">
Один модуль может обслуживать несколько типов: <code>pam_unix</code> реализует
все четыре — проверку пароля, контроль срока его действия по
<code>/etc/shadow</code>, смену пароля и журналирование сеанса.
</div>
</div>

</v-click>

<Refs ids="man-pam man-pam-conf man-pam-unix" />

<!--
Терминология pam(7): четыре независимые группы управления. auth — собственно
аутентификация, диалог с пользователем; account — верификация учётной записи
без пароля: не истёк ли срок, подходит ли время суток, есть ли право доступа
к службе; password — обновление аутентификационных данных; session — настройка
окружения и журналирование. Вернуться к аналогии с проходной из лекции 2.
Подчеркнуть: тип — свойство ПРАВИЛА, а не модуля; pam_unix участвует во всех
четырёх стеках. Если перед типом стоит дефис (-auth), libpam не пишет в журнал
об отсутствии модуля — пригодится для необязательных модулей.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="4" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил',
  'Управляющие флаги',
  'Стек модулей',
]" />

---

# Управляющие флаги: краткая форма

Поле `control` определяет, **как результат модуля влияет на итог всего стека**:

<div class="t-table text-xs mt-2">

| Флаг | Неудача модуля | Успех модуля |
|---|---|---|
| **required** | итог — отказ, но оставшиеся модули **всё равно выполняются** | идём дальше |
| **requisite** | итог — отказ, стек прерывается **немедленно** | идём дальше |
| **sufficient** | игнорируется, идём дальше | если раньше не отказал ни один required — **успех немедленно**, дальнейшие модули не вызываются |
| **optional** | результат важен, только если это **единственное** правило данного типа в стеке | — |
| **include** | подставить все строки данного типа из указанного файла | — |
| **substack** | как include, но `die`/`done` внутри прерывают **только** вложенный стек | — |

</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Почему required не прерывает стек?</b> Чтобы не раскрывать атакующему,
<b>на каком шаге</b> он провалился: оставшиеся модули выполняются, время ответа
и диалог не зависят от места отказа. <code>requisite</code> жертвует этим ради
гарантии: ни один следующий модуль не увидит, например, пароль, введённый
на несуществующем терминале.
</div>

</v-click>

<Refs ids="man-pam-conf pam-sag" />

<!--
Семантика по pam.conf(5). required: неудача учитывается, но стек доходит до
конца — атакующий не узнаёт, где именно провалился. requisite: немедленный
отказ; SAG приводит мотив — не дать модулям ниже по стеку получить пароль при
подозрительных условиях. sufficient: успех достаточен, если до этого не было
неудач required; неудача sufficient просто игнорируется. optional учитывается,
только когда он единственный в стеке. include и substack подставляют строки из
другого файла; разница — в области действия управляющих действий die/done:
substack изолирует их внутри вложенного стека.
-->

---

# Управляющие флаги: подробная форма

Краткие флаги — лишь сокращения. Полная форма задаёт **действие на каждый код
возврата** модуля: `[значение1=действие1 значение2=действие2 …]`

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

**Значения** — коды возврата (<Man p="pam(3)" />): `success`,
`auth_err`, `user_unknown`, `new_authtok_reqd`, `ignore`…
и `default` — «все не перечисленные».

**Действия:**

<div class="t-table text-xs mt-1">

| Действие | Смысл |
|---|---|
| `ignore` | результат не влияет на итог |
| `ok` | записать результат в итог стека |
| `done` | `ok` + немедленно завершить стек (если не было неудач) |
| `bad` | счесть результат неудачей стека (умолчание) |
| `die` | `bad` + немедленно завершить стек |
| `N` (число) | успех: перепрыгнуть следующие N правил |
| `reset` | забыть накопленный итог, начать заново |

</div>

</div>
<div>

**Соответствие кратких флагов** (<Man p="pam.conf(5)" />):

```text
required   [success=ok  new_authtok_reqd=ok
            ignore=ignore default=bad]

requisite  [success=ok  new_authtok_reqd=ok
            ignore=ignore default=die]

sufficient [success=done new_authtok_reqd=done
            default=ignore]

optional   [success=ok  new_authtok_reqd=ok
            default=ignore]
```

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Прыжок <code>N</code> — основной приём Debian/Ubuntu: строка
<code>[success=1 default=ignore]</code> у <code>pam_unix</code> означает
«успех — перепрыгнуть <code>pam_deny</code>», — увидим в разделе 3.1.
</div>

</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<style>
/* Таблица упирается в нижний колонтитул — ужимаем. */
.t-table { font-size: 0.68rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Полный синтаксис: в квадратных скобках пары значение=действие. Значение —
символическое имя кода возврата PAM; default покрывает все не перечисленные.
Действия: ignore/ok/done/bad/die, число N — прыжок через N правил (ноль
запрещён), reset — сброс накопленного состояния. Каждый краткий флаг — макрос
над этим синтаксисом; соответствие приведено дословно по pam.conf(5). Ubuntu
активно использует прыжки — конструкция [success=1 default=ignore] в common-auth
будет разобрана в разделе 3. Как именно libpam хранит и применяет эти действия —
массив actions — раздел 9.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="5" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил',
  'Управляющие флаги',
  'Стек модулей',
]" />

---

# Стек модулей

Правила одного типа в файле службы образуют **стек** (stack): выполняются
**сверху вниз**, итог складывается из результатов по управляющим флагам.

<FieldRecord class="mt-3" size="0.92rem" legendSize="0.75rem" :cols="2"
  :fields="['auth', { t: '[success=1 default=ignore]', hot: true }, 'pam_unix.so', 'nullok']"
  :legend="[
    'тип — группа управления (стек), к которой относится правило',
    { t: 'управляющий флаг — как результат модуля влияет на итог стека', hot: true },
    'модуль: имя .so в каталоге модулей или абсолютный путь',
    'аргументы модуля — его параметры',
  ]"
/>

<div class="grid grid-cols-2 gap-4 mt-3 text-xs">
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Порядок строк важен:</b> стек — не множество, а последовательность; перестановка
строк меняет поведение (пример с <code>pam_faillock</code> — раздел 5).
</div>
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Ошибка в строке = отказ:</b> некорректно оформленное правило libpam превращает
в правило «обязан отказать» — система ошибается в сторону запрета
(<Man p="pam.conf(5)" />; код — раздел 9).
</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Четыре стека службы (auth, account, password, session) выполняются <b>независимо</b>
и в разное время: auth и account — при входе, session — вокруг сеанса,
password — при смене пароля. Приложение запускает каждый стек своим вызовом
API (раздел 7).
</div>

</v-click>

<Refs ids="man-pam-conf pam-sag" />

<!--
Анатомия правила на примере настоящей строки из common-auth Ubuntu: тип,
управляющий флаг, модуль, аргументы. Понятие стека: строки одного типа
выполняются по порядку, сверху вниз; итог определяется флагами. Два
предупреждения: порядок строк значим (вернёмся при разговоре о faillock), а
синтаксически некорректная строка не игнорируется — она становится правилом
«обязан отказать»: PAM ошибается в сторону запрета. Четыре стека службы
независимы; auth+account исполняются при входе, session — вокруг сеанса,
password — только при смене пароля.
-->

---

# Служба other: правила по умолчанию

Имя службы **`other`** зарезервировано: его стеки применяются к службе,
у которой **нет собственного файла** в `/etc/pam.d/`.

<div class="grid grid-cols-[1fr_1.2fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="5" title="Ubuntu Server 26.04 · /etc/pam.d/other" />

<div class="mt-2 text-xs opacity-80">
В Ubuntu <code>other</code> подключает общие файлы <code>common-*</code>
(раздел 3.1): неизвестная служба получает <b>обычную парольную
аутентификацию</b>.
</div>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Руководство администратора Linux-PAM предупреждает:</b> слабая запись
<code>other</code> — уязвимость всей системы, поскольку она действует на каждое
PAM-aware приложение без своего файла. Консервативный вариант по SAG —
запретить всё и записать событие в журнал:
</div>

```text
# /etc/pam.d/other — пример из SAG
auth     required  pam_deny.so
auth     required  pam_warn.so
account  required  pam_deny.so
password required  pam_deny.so
session  required  pam_deny.so
```

<div class="mt-2 text-xs opacity-80">
Выбор Ubuntu — удобство: новая служба «просто работает»; выбор SAG —
принцип «запрещено всё, что не разрешено явно».
</div>

</div>
</div>

<Refs ids="pam-sag man-pam-conf" />

<!--
Служба other — правила по умолчанию для программ без собственного файла.
Это и удобство, и риск: SAG прямо называет слабый other уязвимостью. Ubuntu
подключает в other общие файлы common-* — неизвестное приложение получает
обычную парольную аутентификацию; консервативная рекомендация SAG — pam_deny
во всех четырёх стеках плюс pam_warn для журнала. Этим противопоставлением
закрываем устройство PAM и переходим к реальной конфигурации Ubuntu.
-->

---
layout: section
---

# 3. Конфигурация Ubuntu Server 26.04

<SectionTOC prefix="3" :current="1" :items="[
  'Общие файлы <code>common-*</code>',
  'Файлы служб: <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
]" />

---

# Общие файлы common-*

Debian и Ubuntu выносят повторяющиеся стеки в **общие файлы**, которые файлы служб
подключают директивой `@include`:

<div class="grid grid-cols-[1.2fr_1fr] gap-5 mt-2 items-start">
<div>

<div class="cm-map">
  <div class="cm-svcs">
    <div class="bf-block"><div class="bf-head">login</div></div>
    <div class="bf-block"><div class="bf-head">sshd</div></div>
    <div class="bf-block"><div class="bf-head">su, sudo, passwd…</div></div>
  </div>
  <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
  <div class="bf-block bf-dark cm-common"><div class="bf-head">@include common-*</div><div class="bf-sub">одни и те же общие стеки</div></div>
</div>

<div class="t-table text-xs mt-3">

| Файл | Стек | Содержимое по умолчанию |
|---|---|---|
| `common-auth` | auth | проверка пароля `pam_unix` |
| `common-account` | account | срок действия по `/etc/shadow` |
| `common-password` | password | смена пароля, алгоритм yescrypt |
| `common-session` | session | журналирование, `pam_umask`, `pam_systemd` |
| `common-session-noninteractive` | session | то же для неинтерактивных служб (`cron`) |

</div>

</div>
<div>

<InfoCard icon="info" head="pam-auth-update">

файлы `common-*` собирает утилита <Man p="pam-auth-update(8)"
href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam-auth-update.8.html" />
из **профилей**, которые пакеты кладут в `/usr/share/pam-configs/`. Поэтому
установка пакета с новым модулем может сама включить его в общие стеки —
увидим в разделе 5.

</InfoCard>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Одна правка — все службы:</b> изменение <code>common-auth</code> действует
сразу на вход с консоли, по ssh, на <code>su</code> и <code>sudo</code>.
Это удобно — и ответственно: ошибка блокирует все пути входа одновременно.
</div>

</div>
</div>

<Refs ids="man-pam-auth-update man-pam-conf" />

<style>
/* Таблица упирается в нижний колонтитул — ужимаем. */
.t-table { font-size: 0.68rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
/* Схема «службы → общие файлы» в стиле BlockFlow. */
.cm-map { display: flex; align-items: center; gap: 0; font-size: 0.78rem; text-align: center; }
.cm-svcs { display: flex; flex-direction: column; gap: 0.45em; flex: 1.1; }
.cm-map > .bf-arrow { flex: 0 0 2.2em; }
.cm-common { flex: 1; align-self: stretch; display: flex; flex-direction: column; justify-content: center; }
</style>

<!--
Схема Debian/Ubuntu: общие стеки вынесены в common-* и подключаются @include
из файлов служб. Пять файлов: auth, account, password, session и отдельный
session-noninteractive для служб без терминала. Собирает их pam-auth-update из
профилей пакетов — отсюда «магия» автоматического подключения новых модулей
при установке пакета (покажем вживую на libpam-pwquality). Предупреждение:
правка common-auth действует на все пути входа сразу — и авария тоже.
-->

---

# Разбор common-auth

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="1" title="Ubuntu Server 26.04 · common-auth" fontSize="0.58rem">
  <TCallout :line="2" :col="9" :span="26" :n="1" />
  <TCallout :line="2" :col="41" :span="18" :n="2" />
  <TCallout :line="3" :col="41" :span="11" :n="3" />
  <TCallout :line="4" :col="41" :span="13" :n="4" />
</TerminalCapture>

<div class="grid grid-cols-2 gap-2 mt-3 text-xs">
<div class="p-2 border-l-4 border-teal-600 bg-teal-500/10">
<b>Пароль верный:</b> <code>pam_unix</code> — успех → прыжок через одну строку
(<code>success=1</code>) мимо <code>pam_deny</code> → <code>pam_permit</code> —
<b>вход разрешён</b>
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Пароль неверный:</b> <code>default=ignore</code> — идём дальше →
<code>pam_deny</code> с <code>requisite</code> — <b>немедленный отказ</b>
</div>
</div>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> подробная форма флага: успех — прыжок через 1 правило, остальное — не учитывать</div>
<div><span class="co-ball">2</span> <code>pam_unix</code> проверяет пароль по <code>/etc/shadow</code> (лекция 2)</div>
<div><span class="co-ball">3</span> <code>pam_deny</code> всегда возвращает отказ</div>
<div><span class="co-ball">4</span> <code>pam_permit</code> всегда возвращает успех — фиксирует итог</div>
</div>
</div>

<v-click>

<InfoCard icon="warning" head="nullok" class="mt-2 text-xs">

аргумент разрешает вход с **пустым** паролем — по умолчанию `pam_unix`
его запрещает (<Man p="pam_unix(8)" />). На серверах параметр убирают.

</InfoCard>

</v-click>

</div>
</div>

<Refs ids="man-pam-unix man-pam-rootok man-pam-conf" />

<!--
Первый настоящий файл. Конструкция из трёх строк: pam_unix с прыжком, pam_deny,
pam_permit. Зачем так сложно? Задел на расширение: доменный модуль pam_sss
вставляется между pam_unix и pam_deny, прыжок становится success=2 — логика
«любой из источников подтвердил — вход разрешён» собирается из прыжков.
Два пути: верный пароль перепрыгивает deny и попадает на permit; неверный —
default=ignore ведёт на deny с requisite, немедленный отказ. nullok разрешает
пустые пароли — на серверах убирают. Напомнить: pam_deny и pam_permit —
простейшие модули: безусловные «нет» и «да».
-->

---

# common-account и common-session

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="2" title="common-account" fontSize="0.5rem">
  <TCallout :line="2" :col="9" :span="48" :n="1" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> <code>pam_unix</code> (тип account) проверяет
<b>срок действия</b> пароля и учётной записи по полям <code>/etc/shadow</code>
(лекция 2, раздел 3); <code>new_authtok_reqd=done</code> — «пароль истёк,
но вход разрешить, потребовав смену».
</div>

</div>
<div>

<TerminalCapture src="captures/02-common-files.txt" section="4" title="common-session" fontSize="0.5rem">
  <TCallout :line="5" :col="41" :span="12" :n="2" />
  <TCallout :line="6" :col="25" :span="11" :n="3" />
  <TCallout :line="7" :col="25" :span="14" :n="4" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">2</span> <code>pam_umask</code> — начальная маска прав новых файлов</div>
<div><span class="co-ball">3</span> <code>pam_unix</code> (тип session) журналирует открытие и закрытие сеанса</div>
<div><span class="co-ball">4</span> <code>pam_systemd</code> регистрирует сеанс в <code>systemd-logind</code></div>
</div>
</div>

</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Первая строка <code>common-session</code> — <code>[default=1] pam_permit.so</code>:
технический приём pam-auth-update, выравнивающий прыжки при пересборке файла.
</div>

<Refs ids="man-pam-unix man-pam-conf" />

<!--
Два общих стека покороче. common-account: единственный рабочий модуль —
pam_unix, который сверяет срок действия пароля и учётной записи с полями
shadow; new_authtok_reqd=done пропускает пользователя с истёкшим паролем,
заставляя его сменить пароль. common-session: pam_umask задаёт маску прав,
pam_unix пишет в журнал строки session opened/closed, pam_systemd регистрирует
сеанс в logind (появился при установке openssh/gdm вместе с libpam-systemd).
Первая строка [default=1] pam_permit — служебная заглушка pam-auth-update.
-->

---

# common-password: здесь живёт парольная политика

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="3" title="Ubuntu Server 26.04 · common-password" fontSize="0.56rem">
  <TCallout :line="2" :col="49" :span="11" :n="1" />
  <TCallout :line="2" :col="61" :span="7" :n="2" />
  <TCallout :line="2" :col="69" :span="8" :n="3" />
</TerminalCapture>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Точка подключения политики:</b> модули проверки качества
(<code>pam_pwquality</code>) и истории (<code>pam_pwhistory</code>) вставляются
в этот стек <b>перед</b> <code>pam_unix</code> — политика задаётся один раз
и действует на <code>passwd</code>, <code>chpasswd</code>, смену пароля по ssh —
на всё (раздел 5).
</div>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> стек password выполняется при <b>любой</b> смене пароля; рабочий модуль один — <code>pam_unix</code></div>
<div><span class="co-ball">2</span> <code>obscure</code> — простые встроенные проверки нового пароля: не палиндром, не совпадает со старым с точностью до регистра (<Man p="pam_unix(8)" />)</div>
<div><span class="co-ball">3</span> <code>yescrypt</code> — алгоритм хеширования новых паролей: тот самый <code>$y$</code> из <code>/etc/shadow</code> (лекция 2)</div>
</div>
</div>
</div>

<Refs ids="man-pam-unix man-pam-conf" />

<!--
Последний общий файл — common-password, стек password. По умолчанию один
рабочий модуль pam_unix с двумя интересными аргументами: obscure — встроенные
эвристики качества нового пароля, yescrypt — алгоритм хеширования, который мы
видели в лекции 2 по префиксу $y$. Главное на слайде — зелёная карточка:
common-password есть точка подключения парольной политики; модули качества и
истории вставляются перед pam_unix, и политика действует на любую смену пароля
в системе. Весь раздел 5 построен на этом факте.
-->

---
layout: section
---

# 3. Конфигурация Ubuntu Server 26.04

<SectionTOC prefix="3" :current="2" :items="[
  'Общие файлы <code>common-*</code>',
  'Файлы служб: <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
]" />

---

# Служба login: вход с консоли

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/03-service-files.txt" section="1" title="Ubuntu Server 26.04 · /etc/pam.d/login" fontSize="0.47rem">
  <TCallout :line="2" :col="23" :span="31" :n="1" />
  <TCallout :line="3" :col="23" :span="14" :n="2" />
  <TCallout :line="11" :col="1" :span="20" :n="3" />
  <TCallout :line="13" :col="23" :span="13" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_faildelay</code> — пауза 3 с после неудачной попытки: перебор паролей с клавиатуры замедляется</div>
<div><span class="co-ball">2</span> <code>pam_nologin</code> — при существовании файла <code>/etc/nologin</code> вход разрешён только root (раздел 4.1)</div>
<div><span class="co-ball">3</span> сама проверка пароля — <code>@include common-auth</code>: в файле <code>login</code> о <code>/etc/shadow</code> нет ни строки</div>
<div><span class="co-ball">4</span> <code>pam_limits</code> — лимиты ресурсов сеанса (раздел 4.4); рядом — окружение (<code>pam_env</code>), приветствие (<code>pam_motd</code>), почта (<code>pam_mail</code>)</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
<code>pam_loginuid</code> сообщает ядру идентификатор вошедшего (auid)
для подсистемы аудита.
</div>

</v-click>

</div>
</div>

<Refs ids="man-pam-conf man-pam-nologin man-pam-limits" />

<!--
Файл конкретной службы — login, программа входа с консоли. Он почти целиком
состоит из «обвязки»: faildelay замедляет перебор, nologin закрывает систему
на обслуживание, motd печатает приветствие, limits устанавливает лимиты,
loginuid передаёт ядру auid для аудита. А проверка пароля — одна строка
@include common-auth: логика общая. Это и есть обещанное разделение: файл
службы описывает её особенности, общие файлы — политику аутентификации.
-->

---

# Служба sshd: вход по сети

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/03-service-files.txt" section="2" title="Ubuntu Server 26.04 · /etc/pam.d/sshd" fontSize="0.47rem">
  <TCallout :line="2" :col="1" :span="20" :n="1" />
  <TCallout :line="3" :col="25" :span="14" :n="2" />
  <TCallout :line="12" :col="25" :span="13" :n="3" />
  <TCallout :line="16" :col="1" :span="24" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> проверка пароля — тот же общий стек <code>common-auth</code>, что и у <code>login</code></div>
<div><span class="co-ball">2</span> <code>pam_nologin</code> здесь — в стеке <b>account</b>: сначала пароль, потом проверка «системы закрыты»</div>
<div><span class="co-ball">3</span> <code>pam_limits</code>, <code>pam_env</code>, <code>pam_motd</code> — настройка сеанса</div>
<div><span class="co-ball">4</span> подключены все четыре общих файла — sshd пользуется каждым стеком</div>
</div>

<v-click>

<InfoCard icon="terminal" head="UsePAM yes" class="mt-2 text-xs">

пакет openssh-server в Ubuntu включает PAM (<Man p="sshd_config(5)" />);
диалог модулей с пользователем идёт только через
`KbdInteractiveAuthentication` — важно для второго фактора (раздел 6).

</InfoCard>

</v-click>

</div>
</div>

<Refs ids="man-pam-conf man-sshd-config" />

<!--
sshd подключает все четыре общих файла и добавляет свою обвязку. Отличие от
login: pam_nologin стоит в стеке account — sshd сначала проверяет пароль и лишь
затем «закрыта ли система»; у login тот же модуль стоит в auth с requisite —
до пароля. Такие перестановки — нормальная практика: каждая служба решает,
в каком стеке выполнять проверку. Карточка: PAM в sshd включается директивой
UsePAM yes (умолчание Debian/Ubuntu, не upstream!), а диалог модулей с
пользователем возможен только при KbdInteractiveAuthentication yes — к этому
вернёмся, подключая второй фактор.
-->

---

# Служба gdm-password: графический вход

Графический вход GNOME настраивают файлы `gdm-*`; за вход **по паролю** отвечает
`gdm-password` (рядом — `gdm-autologin`, `gdm-fingerprint`, `gdm-smartcard*`).

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/03-service-files.txt" section="3" title="Ubuntu 26.04 (gdm3) · /etc/pam.d/gdm-password" fontSize="0.47rem">
  <TCallout :line="3" :col="25" :span="44" :n="1" />
  <TCallout :line="4" :col="1" :span="20" :n="2" />
  <TCallout :line="5" :col="25" :span="20" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_succeed_if user != root</code> — графический вход <b>root запрещён</b> политикой Ubuntu</div>
<div><span class="co-ball">2</span> проверка пароля — снова общий <code>common-auth</code>: третья служба с теми же правилами</div>
<div><span class="co-ball">3</span> <code>pam_gnome_keyring</code> — паролем входа разблокируется связка ключей GNOME; флаг <code>optional</code>: неудача не мешает входу</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод по разделу:</b> три разных пути входа — консоль, сеть, графика —
сходятся в одних и тех же общих стеках; меняя <code>common-*</code>,
мы меняем политику всех путей сразу. Этим и пользуемся дальше.
</div>

</v-click>

</div>
</div>

<Refs ids="man-pam-conf man-pam-rootok" />

<!--
Третий путь входа — графический. У GDM семейство файлов gdm-*: password —
обычный вход по паролю, autologin — вход без пароля, fingerprint и smartcard —
другие факторы. В gdm-password: succeed_if запрещает графический вход root —
политика Ubuntu; проверка пароля — всё тот же common-auth; gnome_keyring с
флагом optional разблокирует связку ключей паролем входа — пример модуля,
неудача которого не мешает аутентификации. Вывод раздела: все пути входа
сходятся в common-* — дальше работаем с ними.
-->

---
layout: section
---

# 4. Административные задачи

<SectionTOC prefix="4" :current="1" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 01: запрет входа всем, кроме root

<div class="grid grid-cols-[1fr_1.25fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/04-nologin.txt" section="1" title="demo 01 · настройка">
  <TCallout :line="2" :col="29" :span="25" :n="1" />
  <TCallout :line="4" :col="1" :span="43" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/04-nologin.txt" section="2" lines="1-5" title="demo 01 · попытки входа">
  <TCallout :line="3" :col="1" :span="19" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/04-nologin.txt" section="2" lines="7-11" title="demo 01 · root проходит">
  <TCallout :line="5" :col="1" :span="38" :n="4" />
</TerminalCapture>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_nologin</code> уже подключён в <code>login</code> и <code>sshd</code> — настройка не нужна</div>
<div><span class="co-ball">2</span> «закрыть» систему = создать файл <code>/etc/nologin</code> с сообщением</div>
<div><span class="co-ball">3</span> обычному пользователю печатается сообщение, вход запрещён</div>
<div><span class="co-ball">4</span> root видит то же сообщение, но входит: «модуль не влияет на возможность входа root» (<Man p="pam_nologin(8)" />)</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> типовой приём на время обслуживания: один файл закрывает все
пути входа, использующие <code>pam_nologin</code>; удаление файла открывает их.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/01-nologin.sh</code>. Файл сообщения можно заменить аргументом
<code>file=</code>; вариант ядра systemd — <code>/run/nologin</code> при останове.
</div>

<!--
Первая административная задача из введения: закрыть систему на обслуживание.
pam_nologin уже стоит в login (auth requisite) и sshd (account required) —
администратору достаточно создать /etc/nologin с текстом сообщения. bob после
верного пароля получает сообщение и разрыв соединения, root — то же сообщение,
но вход продолжается: исключение для root зашито в модуль. Удалили файл —
система открыта. Обратить внимание: это соответствует примеру 1 из PAM.pptx;
сообщение «You shall not pass!» — оттуда же.
-->

---
layout: section
---

# 4. Административные задачи

<SectionTOC prefix="4" :current="2" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 02: запрет входа пользователю — pam_access

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/05-access-listfile.txt" section="1" title="demo 02 · правило и подключение">
  <TCallout :line="3" :col="1" :span="9" :n="1" />
  <TCallout :line="7" :col="23" :span="13" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/05-access-listfile.txt" section="2" title="demo 02 · проверка">
  <TCallout :line="3" :col="1" :span="38" :n="3" />
  <TCallout :line="7" :col="1" :span="15" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> правило в <code>/etc/security/access.conf</code>: <code>-:bob:ALL</code> — запретить <code>bob</code> с любых источников (<Man p="pam_access(8)" />)</div>
<div><span class="co-ball">2</span> модуль подключается в стек <b>account</b> службы <code>sshd</code>; в файле Ubuntu уже есть закомментированная строка-образец</div>
<div><span class="co-ball">3</span> пароль <code>bob</code> принят, но account-стек закрывает сеанс</div>
<div><span class="co-ball">4</span> остальных пользователей правило не касается</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Формат правила: <code>разрешение : пользователи : источники</code> —
источником может быть терминал, хост, сеть; так ограничивают,
<b>откуда</b> можно входить от имени учётной записи.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/02-access-listfile.sh</code>.
</div>

<!--
Вторая задача: запретить вход конкретному пользователю, не трогая его учётную
запись. pam_access читает access.conf: правило «минус, bob, ALL» запрещает bob
доступ с любых источников. Модуль ставим в account-стек sshd — Ubuntu даже
держит в файле закомментированный образец строки. Проверка: пароль принят,
сеанс закрыт; alice входит как обычно. Поле источников позволяет точнее:
запретить root вход не с консоли, разрешить группе вход только из локальной
сети и т. п.
-->

---

# Демо 02: запрет по произвольному списку — pam_listfile

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/05-access-listfile.txt" section="3" title="demo 02 · pam_listfile в стеке auth">
  <TCallout :line="1" :col="14" :span="14" :n="1" />
  <TCallout :line="3" :col="39" :span="51" :n="2" />
  <TCallout :line="11" :col="16" :span="17" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> список — обычный текстовый файл: по одному имени в строке</div>
<div><span class="co-ball">2</span> аргументы: <code>item=user</code> — что сравнивать; <code>sense=deny</code> — список запрещающий; <code>onerr=fail</code> — ошибка чтения списка трактуется как отказ</div>
<div><span class="co-ball">3</span> правило стоит в стеке <b>auth</b> с <code>requisite</code> — отказ ещё <b>до</b> проверки пароля</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Сравните:</b> <code>pam_access</code> отказал <b>после</b> верного пароля
(account), <code>pam_listfile</code> — <b>до</b> (auth): клиент видит обычное
«Permission denied», как при неверном пароле. <code>item=</code> принимает
также <code>group</code>, <code>tty</code>, <code>rhost</code>, <code>shell</code>.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/02-access-listfile.sh</code>. <code>sense=allow</code> превращает
список в разрешающий — используем в разделе 7.
</div>

<!--
Тот же запрет другим модулем — pam_listfile, универсальная проверка по списку.
Файл со списком — произвольный, аргументами задаём: что сравнивать (item=user),
смысл списка (sense=deny) и поведение при ошибке чтения (onerr=fail — отказ,
важный выбор по умолчанию в сторону запрета). Поставили в auth с requisite —
отказ происходит до проверки пароля, снаружи неотличим от неверного пароля:
перебор не позволяет даже выяснить, что учётная запись заблокирована. Сравнение
двух модулей показывает выбор стека как инструмент: account — после пароля,
auth — до.
-->

---
layout: section
---

# 4. Административные задачи

<SectionTOC prefix="4" :current="3" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 03: вход по расписанию — pam_time

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/06-time.txt" section="1" title="demo 03 · правило и подключение">
  <TCallout :line="3" :col="1" :span="23" :n="1" />
  <TCallout :line="5" :col="23" :span="11" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/06-time.txt" section="2" title="demo 03 · проверка">
  <TCallout :line="3" :col="1" :span="38" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> правило в <code>/etc/security/time.conf</code>: <code>службы;терминалы;пользователи;время</code>; <code>!Al0000-2400</code> — «кроме всех дней круглосуточно», то есть <b>никогда</b> (<Man p="pam_time(8)" />)</div>
<div><span class="co-ball">2</span> модуль — в стек <b>account</b>: решение «можно ли сейчас» принимается после проверки пароля</div>
<div><span class="co-ball">3</span> вход <code>bob</code> по ssh закрыт в любое время; остальные службы и пользователи не затронуты</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Реалистичное правило: <code>sshd;*;bob;Wk0800-1800</code> — вход по ssh
только в рабочие дни с 8 до 18; синтаксис времён: <code>Wk</code> будни,
<code>Wd</code> выходные, <code>Al</code> все дни, диапазоны объединяются
<code>|</code> и <code>&amp;</code>.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/03-time.sh</code>.
</div>

<!--
Третья задача — ограничение входа по времени. time.conf: четыре поля через
точку с запятой — службы, терминалы, пользователи, интервалы времени.
Для демонстрации используем «запрет всегда»: восклицательный знак — отрицание,
Al0000-2400 — все дни круглосуточно. Модуль снова в account — та же точка, что
pam_access. Реалистичный вариант — ограничение рабочими часами; к root
применять осторожно: правило *;*;root;Wd... из PAM.pptx лишит администратора
входа в выходные — сначала проверяйте на тестовой машине.
-->

---
layout: section
---

# 4. Административные задачи

<SectionTOC prefix="4" :current="4" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 04: лимиты ресурсов сеанса — pam_limits

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/07-limits.txt" section="1" title="demo 04 · лимит в limits.conf">
  <TCallout :line="3" :col="1" :span="28" :n="1" />
  <TCallout :line="5" :col="25" :span="13" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/07-limits.txt" section="2" title="demo 04 · сеанс bob" lines="4-13" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="4" :n="3" />
  <TCallout :line="6" :col="1" :span="25" :n="4" />
  <TCallout :line="8" :col="22" :span="7" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> правило в <code>/etc/security/limits.conf</code>: жёсткий лимит размера файла 1024 КБ для <code>bob</code> (<Man p="pam_limits(8)" />)</div>
<div><span class="co-ball">2</span> <code>pam_limits</code> уже стоит в session-стеке <code>sshd</code> — лимит применяется при открытии сеанса</div>
<div><span class="co-ball">3</span> <code>ulimit -f</code> подтверждает: 1024</div>
<div><span class="co-ball">4</span> запись файла больше лимита убивает процесс сигналом <code>SIGXFSZ</code></div>
<div><span class="co-ball">5</span> файл обрезан ровно на 1 МБ (1 048 576 байт)</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> стек session — место «обустройства» сеанса: лимиты наследуются
всеми процессами пользователя. Так ограничивают и число процессов
(<code>nproc</code>), открытых файлов (<code>nofile</code>), память — защита
от исчерпания ресурсов.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/04-limits.sh</code>. Лимиты действуют и на root
(<Man p="pam_limits(8)" />); мягкие (<code>soft</code>) пользователь может
поднимать до жёстких (<code>hard</code>).
</div>

<!--
Последняя задача раздела — лимиты ресурсов, пример работы session-стека.
Правило в limits.conf: домен (пользователь, группа или *), тип (hard/soft),
ресурс, значение; у нас — жёсткий лимит размера создаваемого файла 1024 КБ.
pam_limits уже стоит в session-стеке sshd и login. В сеансе bob: ulimit -f
показывает лимит; маленький файл создаётся, попытка записать 2 МБ убивает dd
сигналом SIGXFSZ, файл обрезан ровно на мегабайте. Лимиты — не только fsize:
nproc защищает от fork-бомбы, nofile — от исчерпания дескрипторов. Соответствует
примеру 4 из PAM.pptx (там python; здесь dd — тот же эффект).
-->

---
layout: section
---

# 5. Парольная политика
## pam_pwquality · pam_pwhistory · pam_faillock

---

# Демо 05: установка pam_pwquality

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/08-password-policy.txt" section="1" title="demo 05 · до и после установки" fontSize="0.5rem">
  <TCallout :line="6" :col="12" :span="22" :n="1" />
  <TCallout :line="8" :col="49" :span="24" :n="2" />
  <TCallout :line="9" :col="69" :span="26" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> ставим пакет <code>libpam-pwquality</code> — модуль проверки качества паролей</div>
<div><span class="co-ball">2</span> строка <code>pam_pwquality.so retry=3</code> появилась в <code>common-password</code> <b>сама</b>: пакет принёс профиль для <code>pam-auth-update</code> (раздел 3.1)</div>
<div><span class="co-ball">3</span> у <code>pam_unix</code> добавились <code>use_authtok try_first_pass</code>: пароль, уже запрошенный и проверенный <code>pam_pwquality</code>, передаётся дальше по стеку — пользователя не спрашивают дважды</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Модуль вставлен <b>перед</b> <code>pam_unix</code> с флагом <code>requisite</code>:
слабый пароль отклоняется до того, как <code>pam_unix</code> начнёт смену.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-policy.sh</code>.
</div>

<!--
Переходим к парольной политике — главной практической теме. Установка пакета
libpam-pwquality демонстрирует механизм pam-auth-update вживую: строка модуля
появляется в common-password автоматически, причём в правильном месте — перед
pam_unix, с requisite. Заодно у pam_unix появились use_authtok и
try_first_pass — конвенция передачи пароля по стеку: запрашивает и проверяет
качество pwquality, а pam_unix берёт уже готовый токен; пользователь вводит
новый пароль один раз (плюс подтверждение).
-->

---

# Параметры pam_pwquality

Два способа настройки: **аргументы модуля** в строке правила — или центральный файл
`/etc/security/pwquality.conf`; **аргументы имеют приоритет**
(<Man p="pam_pwquality(8)" href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam_pwquality.8.html" />).

<div class="t-table text-xs mt-2">

| Параметр | Что проверяет |
|---|---|
| `minlen=N` | минимальная длина пароля (по умолчанию 8, с учётом «кредитов» классов) |
| `minclass=N` | минимум **классов** символов: строчные, прописные, цифры, прочие |
| `dcredit` / `ucredit` / `lcredit` / `ocredit` | отрицательное значение — «не менее N» цифр / прописных / строчных / прочих символов |
| `dictcheck`, `usercheck` | словарная проверка (cracklib); пароль не содержит имени пользователя |
| `retry=N` | сколько раз предлагать ввести приемлемый пароль (по умолчанию 1) |
| `enforce_for_root` | применять политику и к root (по умолчанию root может задать любой пароль) |

</div>

<v-click>

<div class="mt-3 grid grid-cols-2 gap-3 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Пример политики</b> (демо 05): не короче 10 символов, минимум по 2 цифры,
прописных, строчных и спецсимвола; словарная проверка отключена ради
предсказуемости демонстрации: <code>retry=7 minlen=10 dcredit=-2 ucredit=-2
lcredit=-2 ocredit=-2 dictcheck=0</code>
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Требования ФСТЭК</b> (мера ИАФ.3) выражаются теми же параметрами:
длина ≥ 12 — <code>minlen=12</code>; алфавит ≥ 70 символов — все четыре
класса (26+26+10+спецсимволы): четыре «кредита» по −1.
</div>
</div>

</v-click>

<Refs ids="man-pam-pwquality fstec-md2026" />

<!--
Параметры модуля. Семейство «кредитов»: отрицательное значение — жёсткое
требование «не менее N символов класса»; положительные значения дают скидку к
minlen — отсюда оговорка «с учётом кредитов». dictcheck и usercheck включены по
умолчанию. enforce_for_root важен: без него root не ограничен политикой.
Связка с нормативкой: требования меры ИАФ.3 методического документа ФСТЭК
ложатся на эти параметры напрямую; блокировку и срок смены пароля закрывают
faillock (далее) и chage из лекции 2.
-->

---

# Демо 05: политика в действии

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/08-password-policy.txt" section="3" title="demo 05 · passwd (пароли перечислены в комментарии)" fontSize="0.5rem">
  <TCallout :line="5" :col="15" :span="51" :n="1" />
  <TCallout :line="11" :col="15" :span="40" :n="2" />
  <TCallout :line="13" :col="15" :span="42" :n="3" />
  <TCallout :line="16" :col="1" :span="37" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию</b> (ввод пароля не отображается — значения в комментарии):
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>1234567890</code>: длина достаточна, но нет прописных — отклонён; модуль называет <b>первую</b> непройденную проверку</div>
<div><span class="co-ball">2</span> <code>ABcd%^yuio</code>: нет двух цифр — отклонён</div>
<div><span class="co-ball">3</span> <code>AAbb##44</code>: все классы есть, но короче 10 — отклонён</div>
<div><span class="co-ball">4</span> <code>ABcd%^7890</code>: удовлетворяет всем правилам — принят</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> мы не меняли ни <code>passwd</code>, ни <code>login</code>,
ни <code>sshd</code> — политика настроена один раз в <code>common-password</code>
и действует на любую смену пароля в системе.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-policy.sh</code>; последовательность паролей —
из методички (PAM.pptx, пример 5).
</div>

<!--
Диалог passwd под настроенной политикой. Шесть попыток по порядку: каждая
отклонённая нарушает ровно одно правило, и pwquality сообщает о первой
непройденной проверке — удобно вести аудиторию по правилам. Последний пароль
удовлетворяет всем требованиям и принят. Подчеркнуть вывод: политика живёт в
common-password и действует на passwd, chpasswd, смену пароля по ssh — всё, что
использует стек password.
-->

---

# Демо 05: pam_pwhistory — история паролей

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/08-password-policy.txt" section="4" title="demo 05 · история паролей" fontSize="0.47rem">
  <TCallout :line="3" :col="49" :span="39" :n="1" />
  <TCallout :line="17" :col="1" :span="47" :n="2" />
  <TCallout :line="24" :col="1" :span="17" :n="3" />
</TerminalCapture>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
История наполняется <b>при сменах пароля</b>, пока модуль включён; хеши старых
паролей в <code>opasswd</code> защищают так же строго, как <code>/etc/shadow</code>.
</div>

</v-click>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_pwhistory remember=3</code> — хранить три последних пароля; строка вставлена перед <code>pam_unix</code> (<Man p="pam_pwhistory(8)" />)</div>
<div><span class="co-ball">2</span> попытка вернуть прежний пароль отклонена: «Password has been already used»</div>
<div><span class="co-ball">3</span> хеши старых паролей — в <code>/etc/security/opasswd</code> (0600, root)</div>
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-policy.sh</code>.
</div>

<!--
Второй модуль политики — pam_pwhistory, запрет повторного использования.
Вставляется между pwquality и pam_unix, remember=3 — глубина истории. Смена на
новый пароль проходит, попытка вернуть прежний — отклоняется. Хранилище —
/etc/security/opasswd: хеши старых паролей, права 0600; компрометация файла
даёт материал для перебора старых паролей пользователя, которые люди любят
переиспользовать в других местах, — защищать как shadow.
-->

---

# pam_faillock: блокировка после неудачных попыток

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/09-faillock.txt" section="1" title="demo 06 · faillock.conf и common-auth" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="8" :n="1" />
  <TCallout :line="5" :col="41" :span="23" :n="2" />
  <TCallout :line="6" :col="10" :span="9" :n="3" />
  <TCallout :line="7" :col="41" :span="24" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем конфигурацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> параметры — в <code>/etc/security/faillock.conf</code>: 5 неудач → блокировка на 900 с (<Man p="pam_faillock(8)" />)</div>
<div><span class="co-ball">2</span> <code>preauth</code> — <b>до</b> <code>pam_unix</code>: не заблокирован ли пользователь уже</div>
<div><span class="co-ball">3</span> прыжок <code>pam_unix</code> вырос: <code>success=2</code> — верный пароль перепрыгивает <b>и</b> <code>authfail</code>, <b>и</b> <code>pam_deny</code></div>
<div><span class="co-ball">4</span> <code>authfail</code> — <b>после</b>: записать неудачную попытку</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Ловушка:</b> вставив строку в стек, <b>пересчитайте прыжки</b>: со старым
<code>success=1</code> верный пароль упирался бы в <code>pam_deny</code> —
не вошёл бы ни один пользователь.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/06-faillock.sh</code>. Строка <code>authsucc</code> обнуляет
счётчик после успешного входа.
</div>

<!--
Защита от перебора — pam_faillock. Параметры держим в faillock.conf (сам модуль
рекомендует не задавать их аргументами). Встраивание в common-auth: preauth до
pam_unix проверяет, не заблокирован ли пользователь; authfail после — фиксирует
неудачу; authsucc в конце обнуляет счётчик при успехе. Критическая деталь —
пересчёт прыжка pam_unix с success=1 на success=2: иначе верный пароль попадает
на pam_deny, и вход ломается для всех. Это лучшая иллюстрация тезиса «порядок
строк и прыжки — часть семантики стека».
-->

---

# Демо 06: блокировка в действии

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/09-faillock.txt" section="2" title="demo 06 · пять неудач, затем верный пароль">
  <TCallout :line="3" :col="1" :span="21" :n="1" />
  <TCallout :line="5" :col="1" :span="45" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/09-faillock.txt" section="3" title="demo 06 · счётчик и сброс" lines="1-9" fontSize="0.47rem">
  <TCallout :line="1" :col="3" :span="19" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> пять неудач — пять одинаковых «Permission denied»: модуль ничего не рассказывает атакующему</div>
<div><span class="co-ball">2</span> шестая попытка — с <b>верным</b> паролем: «The account is locked due to 5 failed logins» — блокировка остановила перебор</div>
<div><span class="co-ball">3</span> администратор видит журнал попыток: <code>faillock --user bob</code>; сброс — <code>--reset</code></div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> верный пароль во время блокировки <b>не помогает</b> — именно это
обесценивает перебор. root по умолчанию не блокируется: иначе атакующий мог бы
намеренно «запереть» администратора (отказ в обслуживании).
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/06-faillock.sh</code>. Счётчики — файлы в <code>/var/run/faillock/</code>,
сбрасываются перезагрузкой.
</div>

<!--
Блокировка в действии: пять попыток su с неверным паролем — одинаковые ответы;
затем попытка с верным паролем отклоняется с сообщением о блокировке и временем
до разблокировки. Именно невозможность войти с верным паролем останавливает
перебор. Администратор смотрит счётчик faillock --user и сбрасывает --reset.
Умолчание «root не блокируется» — защита от отказа в обслуживании: атакующий не
должен уметь запереть администратора; even_deny_root включает блокировку и для
root. Вместе pwquality + pwhistory + faillock + chage (лекция 2) покрывают
парольную политику ФСТЭК целиком.
-->

---
layout: section
---

# 6. Двухфакторная аутентификация
## Одноразовые коды TOTP и аппаратные ключи

---

# Факторы аутентификации и одноразовые коды

**Фактор** — независимое подтверждение подлинности: **знание** (пароль),
**владение** (устройство, ключ), **биометрия**. Двухфакторная аутентификация (2FA)
требует подтверждений из **двух разных** категорий.

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-3 items-start">
<div>

<div class="t-table text-xs">

| Механизм | Модуль PAM | Фактор владения |
|---|---|---|
| TOTP (RFC 6238): код из приложения | `pam_google_authenticator` | смартфон с общим секретом |
| HOTP (RFC 4226): код по счётчику | `pam_google_authenticator` (режим `-c`) | токен-генератор |
| FIDO2/U2F: challenge-response | `pam_u2f` | аппаратный USB/NFC-ключ |
| смарт-карта (PKCS#11) | `pam_pkcs11`, `gdm-smartcard` | карта с закрытым ключом |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>TOTP</b>: сервер и устройство делят секрет; код = усечённый
HMAC(секрет, текущее 30-секундное окно). Совпадение кода доказывает
владение устройством, не передавая секрет по сети.
</div>

</div>
<div>

**Почему это задача PAM:** второй фактор нужен сразу
нескольким службам — ssh, консоль, `su`, графический вход.
Модуль добавляется **строкой в стек auth** нужных служб;
сами программы не меняются (раздел 1).

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Пароль перехвачен или подобран — без второго фактора он бесполезен;
по данным отраслевых отчётов MFA отсекает подавляющую часть атак
на учётные записи с утёкшими паролями.
</div>

</div>
</div>

<Refs ids="rfc-6238 google-authenticator pam-u2f gost-58833" />

<!--
Терминология: фактор — независимое подтверждение подлинности; классы —
знание, владение, биометрия; 2FA — два разных класса. Таблица модулей второго
фактора: TOTP/HOTP из google-authenticator-libpam, FIDO2-ключи через pam_u2f,
смарт-карты. Принцип TOTP: общий секрет и часы; код — усечённый HMAC от номера
30-секундного окна; знание кода доказывает владение устройством. Правая
колонка возвращает к мотивации PAM: второй фактор нужен всем службам сразу —
и добавляется он строкой конфигурации, а не правкой программ.
-->

---

# Демо 07: настройка TOTP для пользователя

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/10-totp.txt" section="1" title="demo 07 · google-authenticator (alice)" fontSize="0.5rem">
  <TCallout :line="1" :col="24" :span="22" :n="1" />
  <TCallout :line="5" :col="25" :span="32" :n="2" />
  <TCallout :line="8" :col="1" :span="33" :n="3" />
  <TCallout :line="15" :col="1" :span="10" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> флаги: <code>-t</code> TOTP, <code>-d</code> запрет повтора кода, <code>-r 3 -R 30</code> — не более 3 входов за 30 с, <code>-W</code> — допуск соседних окон</div>
<div><span class="co-ball">2</span> общий секрет; пользователь вносит его в приложение-аутентификатор (QR-код здесь опущен)</div>
<div><span class="co-ball">3</span> резервные (scratch) коды — одноразовые, на случай утраты устройства: хранить отдельно</div>
<div><span class="co-ball">4</span> всё сохранено в <code>~/.google_authenticator</code>, права <code>400</code></div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
Файл с секретом равноценен второму фактору: прочитавший его генерирует
верные коды. Отсюда права <code>400</code> и владелец-пользователь.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/07-totp-ssh.sh</code>; секрет и коды — из одноразового
демо-контейнера.
</div>

<!--
Настройка со стороны пользователя: утилита google-authenticator генерирует
секрет, печатает QR-код для приложения (в транскрипте опущен), подтверждает
настройку введённым кодом и выдаёт резервные одноразовые коды. Все данные —
в файле ~/.google_authenticator с правами 400: это и есть материализованный
второй фактор, его компрометация сводит 2FA к одному фактору. Флаги зафиксированы
в сценарии демо; -W разрешает коды из соседних 30-секундных окон — компенсация
расхождения часов.
-->

---

# Демо 07: второй фактор в sshd

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/10-totp.txt" section="2" title="demo 07 · конфигурация sshd">
  <TCallout :line="3" :col="25" :span="27" :n="1" />
  <TCallout :line="5" :col="1" :span="32" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/10-totp.txt" section="3" title="demo 07 · вход: пароль + код" fontSize="0.5rem">
  <TCallout :line="3" :col="19" :span="18" :n="3" />
  <TCallout :line="8" :col="19" :span="18" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> одна строка после <code>@include common-auth</code>: сначала пароль (<code>pam_unix</code>), затем код; <code>required</code> — без кода входа нет</div>
<div><span class="co-ball">2</span> <code>KbdInteractiveAuthentication yes</code>: диалог PAM-модулей с пользователем идёт через keyboard-interactive (раздел 3.2)</div>
<div><span class="co-ball">3</span> sshd задаёт второй вопрос — «Verification code:»</div>
<div><span class="co-ball">4</span> неверный код → цикл повторяется; верная пара пароль+код впускает</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> ни sshd, ни ssh-клиент не знают о TOTP — новый фактор добавила
строка конфигурации PAM. Это обещание OSF RFC 86.0 в действии.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/07-totp-ssh.sh</code>. Аргумент <code>nullok</code> у модуля
разрешил бы вход ненастроившим TOTP пользователям — этап внедрения.
</div>

<!--
Подключение: одна строка auth required pam_google_authenticator.so после
common-auth — и ssh спрашивает сначала пароль, затем Verification code.
Обязательное условие — KbdInteractiveAuthentication yes, иначе sshd не умеет
вести диалог PAM с клиентом. Неверный код просто перезапускает цикл вопросов —
снаружи не видно, что именно не подошло. Вывод слайда — центральный тезис
лекции: программы не менялись, фактор добавлен конфигурацией. Для поэтапного
внедрения модулю дают nullok — пользователи без файла секрета входят по одному
паролю, пока не настроят TOTP.
-->

---

# Аппаратный ключ: pam_u2f

Одноразовые коды уязвимы к **фишингу в реальном времени**: код можно выманить
и успеть использовать. Аппаратный ключ FIDO2/U2F решает challenge-response
локально и не выдаёт переносимого секрета.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

**Настройка** (по документации Yubico; в демо-стенде
аппаратного ключа нет):

```text
# регистрация ключа пользователем
$ pamu2fcfg > ~/.config/Yubico/u2f_keys

# строка в стек auth нужной службы
auth  required  pam_u2f.so  cue [authfile=…]
```

- проверка — касание ключа (`cue` печатает приглашение);
- `nouserok` — этап внедрения: без зарегистрированного
  ключа вход по прежним правилам.

</div>
<div>

<div class="t-table text-xs">

| Критерий | TOTP | FIDO2/U2F |
|---|---|---|
| секрет на сервере | общий секрет | открытый ключ |
| фишинг-устойчивость | нет: код можно выманить | да: ответ привязан к запросу |
| оборудование | смартфон | USB/NFC-ключ |
| офлайн-вход | да | да |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Для обоих механизмов PAM-сторона одинакова: <b>одна строка в стеке auth</b>;
выбор фактора — вопрос модели угроз и стоимости внедрения.
</div>

</div>
</div>

<Refs ids="pam-u2f rfc-6238" />

<!--
Завершение раздела: альтернатива TOTP — аппаратный ключ. Слабость одноразовых
кодов — фишинг в реальном времени: атакующий выманивает код и немедленно его
использует; TOTP от этого не защищает. U2F/FIDO2 выполняет challenge-response:
ключ подписывает запрос, привязанный к серверу, — выманить «ответ заранее»
нельзя, на сервере хранится только открытый ключ. Настройка по документации
Yubico: pamu2fcfg регистрирует ключ, строка pam_u2f.so в стек auth; живой
демонстрации нет — в контейнере нет USB. Сравнительная таблица — по одинаковым
критериям. PAM-сторона обоих решений одинакова — одна строка конфигурации.
-->

---
layout: section
---

# 7. PAM в собственных программах
## Интерфейс приложения: libpam API и программа authprint

---

# Жизненный цикл PAM-транзакции

Приложение общается с PAM через **транзакцию**: контекст `pam_handle_t`
создаётся `pam_start()`, живёт до `pam_end()` и передаётся в каждый вызов
(<Man p="pam(3)" />).

<BlockFlow class="mt-3 mb-2" size="0.8em" :blocks="[
  { head: 'pam_start()', mono: true, sub: 'служба, пользователь,\nфункция диалога' },
  { head: 'pam_authenticate()', mono: true, fill: 'accent', sub: 'стек auth:\nкто вы?' },
  { head: 'pam_acct_mgmt()', mono: true, fill: 'accent', sub: 'стек account:\nможно ли сейчас?' },
  { head: 'pam_open_session()\n…pam_close_session()', mono: true, sub: 'стек session:\nвокруг сеанса' },
  { head: 'pam_end()', mono: true, sub: 'завершение\nтранзакции' },
]" :arrows="[true, true, true, true]" />

<div class="t-table text-xs mt-3">

| Вызов API | Стек | Назначение |
|---|---|---|
| `pam_authenticate(pamh, flags)` | auth | проверить подлинность пользователя |
| `pam_setcred(pamh, flags)` | auth | выдать/отозвать «удостоверения» (группы, билеты Kerberos) |
| `pam_acct_mgmt(pamh, flags)` | account | срок действия, ограничения доступа |
| `pam_chauthtok(pamh, flags)` | password | смена аутентификатора |
| `pam_open_session` / `pam_close_session` | session | открыть и закрыть сеанс |

</div>

<Refs ids="man-pam3 man-pam-start man-pam-authenticate pam-adg" />

<!--
Интерфейс приложения — шесть основных вызовов вокруг общего контекста.
pam_start создаёт транзакцию: имя службы (= имя файла конфигурации), имя
пользователя (можно NULL — спросят позже), функция диалога. Далее приложение
вызывает стеки: pam_authenticate — auth, pam_acct_mgmt — account, вокруг
сеанса — open/close_session, смена пароля — pam_chauthtok, выдача
удостоверений — pam_setcred. pam_end завершает транзакцию. Полный порядок для
программы входа описан в Application Developers' Guide; нашей программе хватит
authenticate + acct_mgmt.
-->

---

# pam_start: служба, пользователь, диалог

```c
#include <security/pam_appl.h>

int pam_start(const char *service_name, const char *user,
              const struct pam_conv *pam_conversation,
              pam_handle_t **pamh);
int pam_end(pam_handle_t *pamh, int pam_status);
```

<div class="grid grid-cols-2 gap-4 mt-3 text-xs">
<div class="p-3 border border-slate-400/40 rounded">
<b><code>service_name</code></b> — имя службы: по нему libpam откроет
<code>/etc/pam.d/&lt;имя&gt;</code> (раздел 2.2). Компонент пути запрещён;
имя приводится к нижнему регистру. Нет файла — действует <code>other</code>.
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b><code>user</code></b> — кого аутентифицируем; допустим <code>NULL</code> —
тогда модуль запросит имя через диалог (<code>pam_get_user</code>, раздел 8).
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b><code>pam_conversation</code></b> — функция диалога: <b>обратный вызов</b>,
через который модули задают вопросы пользователю (следующий слайд).
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b><code>pamh</code></b> — непрозрачный контекст транзакции; передаётся
во все последующие вызовы. <code>pam_end</code> получает итоговый статус —
его видят модули при выгрузке.
</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Выбор <code>service_name</code> — <b>решение безопасности</b>: программа,
назвавшаяся чужой службой, получит её правила. Поэтому имя службы жёстко
задаётся в коде, а не берётся из ввода пользователя.
</div>

</v-click>

<Refs ids="man-pam-start pam-adg" />

<!--
Сигнатуры из pam_start(3). service_name связывает программу с файлом
конфигурации; libpam отрезает компоненты пути и приводит имя к нижнему
регистру — защита от трюков вида "../". user может быть NULL — имя спросит
первый модуль, которому оно понадобится. pam_conversation — указатель на
структуру с функцией обратного вызова; об этом подробнее дальше. pamh —
непрозрачный указатель, созданный pam_start; все функции API принимают его
первым аргументом. Жёлтая карточка: имя службы определяет применяемые правила,
поэтому оно - константа в коде.
-->

---

# Диалог: struct pam_conv

Модуль не читает терминал сам — **вопросы пользователю задаёт приложение**
через функцию диалога (conversation function, <Man p="pam_conv(3)" />):

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

```c
struct pam_message {          /* от модуля к приложению */
    int msg_style;            /* тип сообщения */
    const char *msg;          /* текст */
};
struct pam_response {         /* ответ приложения */
    char *resp;               /* строка пользователя */
    int resp_retcode;         /* не используется (0) */
};
struct pam_conv {
    int (*conv)(int num_msg,
                const struct pam_message **msg,
                struct pam_response **resp,
                void *appdata_ptr);
    void *appdata_ptr;        /* данные приложения */
};
```

</div>
<div>

<div class="t-table text-xs">

| msg_style | Смысл |
|---|---|
| `PAM_PROMPT_ECHO_OFF` | вопрос, ввод скрыт (пароль) |
| `PAM_PROMPT_ECHO_ON` | вопрос, ввод виден (имя, код) |
| `PAM_ERROR_MSG` | сообщение об ошибке |
| `PAM_TEXT_INFO` | информационный текст |

</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Так достигается независимость модулей от интерфейса: <b>один и тот же</b>
<code>pam_unix</code> спрашивает пароль в консоли (<code>login</code>),
в окне GDM и через сетевой диалог sshd — функцию диалога даёт приложение.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Консольным программам готовую функцию даёт libpam_misc:
<code>misc_conv</code> (<Man p="misc_conv(3)" />) — печать в терминал,
чтение с отключённым эхом для паролей.
</div>

</div>
</div>

<Refs ids="man-pam-conv pam-adg" />

<!--
Ключевая абстракция интерфейса — функция диалога. Модулю нужно спросить пароль,
но он не знает, где работает: в консоли, в графическом окне, по сети. Поэтому
вопросы передаются приложению массивом pam_message, а приложение возвращает
массив pam_response. Четыре типа сообщений: два вопроса (со скрытым и открытым
вводом) и два уведомления. Благодаря этому pam_unix один и тот же в login, GDM
и sshd. Для консольных программ не нужно писать диалог самим — misc_conv из
libpam_misc делает ровно это; им и воспользуемся.
-->

---

# authprint: приложение с парольной защитой

Учебная программа `authprint` печатает строку **только после аутентификации** —
каркас любой «запароленной» операции (аналог проверки в `sudo`):

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

```c
/* assets/src/authprint.c (фрагмент) */
#include <security/pam_appl.h>
#include <security/pam_misc.h>

static struct pam_conv conv = { misc_conv, NULL };

int main(int argc, char *argv[])
{
    const char *service = (argc > 1) ? argv[1]
                                     : "authprint";
    pam_handle_t *pamh = NULL;
    struct passwd *pw = getpwuid(getuid());
    int rc;

    rc = pam_start(service, pw->pw_name, &conv, &pamh);
    if (rc != PAM_SUCCESS) { /* … */ }
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Функция диалога</b> — готовая <code>misc_conv</code>; второй член
структуры — <code>appdata_ptr</code>, модулям он передаётся обратно
в каждый вызов диалога.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Кого аутентифицируем:</b> владельца процесса — имя получаем
по реальному UID (<code>getpwuid(getuid())</code>, лекция 2).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Имя службы</b> по умолчанию — <code>authprint</code>; аргумент
командной строки оставлен для учебных экспериментов со службами
(демо 09) — в боевой программе имя фиксировано.
</div>

</div>
</div>

<Refs ids="man-pam-start man-pam-conv pam-adg" />

<!--
Первая половина authprint — подготовка. Структура pam_conv со стандартной
misc_conv. Пользователь — владелец процесса: getuid + getpwuid, связь с
идентификаторами из лекции 2. Имя службы по умолчанию authprint; возможность
передать его аргументом — учебная, чтобы в демо 09 прогнать ту же программу
через службу mathtest; в реальных программах служба фиксирована (см.
предупреждение прошлого слайда). Программа соответствует
pam_authenticated_printf из методички, переписана и прокомментирована.
-->

---

# authprint: проверка и завершение

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

```c
    /* стек auth: подлинность пользователя */
    rc = pam_authenticate(pamh, 0);

    /* стек account: разрешён ли доступ сейчас */
    if (rc == PAM_SUCCESS)
        rc = pam_acct_mgmt(pamh, 0);

    if (rc == PAM_SUCCESS)
        printf("Authenticated printf :-)\n");
    else
        fprintf(stderr, "authprint failed: %s\n",
                pam_strerror(pamh, rc));

    /* завершение транзакции; rc видят модули */
    if (pam_end(pamh, rc) != PAM_SUCCESS)
        return 1;
    return rc == PAM_SUCCESS ? 0 : 1;
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_authenticate</code> исполняет стек auth службы: по умолчанию
(<code>other</code> → <code>common-auth</code>) <code>misc_conv</code>
спросит пароль, <code>pam_unix</code> сверит его с <code>/etc/shadow</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_acct_mgmt</code> — обязательное продолжение: пароль верен,
но не истёк ли он и не закрыт ли доступ (<code>pam_time</code>,
<code>pam_access</code>…).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_strerror</code> переводит код возврата в текст
(<Man p="pam_strerror(3)" />). Коды: <code>PAM_SUCCESS</code>,
<code>PAM_AUTH_ERR</code>, <code>PAM_USER_UNKNOWN</code>,
<code>PAM_PERM_DENIED</code>, <code>PAM_ACCT_EXPIRED</code>…
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
Диалог с пользователем — <b>внутри</b> <code>pam_authenticate</code>:
приложение не видит пароль и не управляет числом вопросов —
это определяют модули стека.
</div>

</div>
</div>

<Refs ids="man-pam-authenticate man-pam-strerror pam-adg" />

<!--
Вторая половина: два вызова стека и завершение. pam_authenticate запускает стек
auth — только здесь misc_conv получит от pam_unix вопрос «Password:».
pam_acct_mgmt нельзя пропускать: верный пароль не означает действующую учётную
запись — сроки и ограничения проверяет account-стек; забытый acct_mgmt — типовая
ошибка самодельных PAM-приложений. pam_strerror даёт человекочитаемый текст
кода. Красная карточка: приложение никогда не видит сам пароль — диалог идёт
между модулем и функцией диалога; это сознательный дизайн.
-->

---

# Демо 08: сборка и запуск

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/11-authprint.txt" section="1" title="demo 08 · сборка">
  <TCallout :line="1" :col="38" :span="16" :n="1" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/11-authprint.txt" section="2" title="demo 08 · запуск: служба other">
  <TCallout :line="1" :col="3" :span="11" :n="2" />
  <TCallout :line="3" :col="1" :span="24" :n="3" />
  <TCallout :line="7" :col="1" :span="40" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> сборка: заголовки из пакета <code>libpam0g-dev</code>, компоновка с <code>-lpam -lpam_misc</code></div>
<div><span class="co-ball">2</span> файла <code>/etc/pam.d/authprint</code> ещё нет — применяются правила службы <code>other</code> (раздел 2.5): обычный пароль</div>
<div><span class="co-ball">3</span> пароль верен → <code>pam_authenticate</code> и <code>pam_acct_mgmt</code> вернули <code>PAM_SUCCESS</code> — строка напечатана</div>
<div><span class="co-ball">4</span> неверный пароль → <code>PAM_AUTH_ERR</code>; текст дал <code>pam_strerror</code></div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> ~50 строк кода — и программа получает «настоящую» парольную
проверку: с <code>/etc/shadow</code> работает <code>pam_unix</code> (его
SUID-помощник <code>unix_chkpwd</code>), а не наш код.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/08-authprint.sh</code>; исходный код — <code>assets/src/authprint.c</code>.
</div>

<!--
Демонстрация: собираем с -lpam -lpam_misc (заголовки — libpam0g-dev; в
методичке пакет назван libpam-dev — это алиас). Запуск без своего файла
конфигурации: действует other — обычная парольная аутентификация. Верный
пароль — строка напечатана; неверный — Authentication failure через
pam_strerror. Внимание на вывод: наш код не читает /etc/shadow — это делает
pam_unix через свой SUID-помощник unix_chkpwd; программе не нужны привилегии,
чтобы проверить пароль текущего пользователя.
-->

---

# Демо 08: собственная служба authprint

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/11-authprint.txt" section="3" title="demo 08 · /etc/pam.d/authprint" fontSize="0.5rem">
  <TCallout :line="3" :col="37" :span="58" :n="1" />
  <TCallout :line="4" :col="1" :span="20" :n="2" />
  <TCallout :line="13" :col="1" :span="40" :n="3" />
  <TCallout :line="16" :col="55" :span="18" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> свой файл службы: <code>pam_listfile</code> с <code>sense=allow</code> — <b>разрешающий</b> список из демо 02</div>
<div><span class="co-ball">2</span> дальше — обычные общие стеки <code>@include</code></div>
<div><span class="co-ball">3</span> <code>bob</code> в списке — вход разрешён; <code>carol</code> — отказ при верном пароле</div>
<div><span class="co-ball">4</span> отказ записан в syslog: видно модуль, службу и тип стека</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> наша программа администрируется <b>теми же средствами</b>, что
login и sshd: ей можно назначить любой стек — список доступа, политику,
второй фактор — не меняя ни строки кода.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/08-authprint.sh</code>.
</div>

<!--
Кульминация раздела: создаём /etc/pam.d/authprint — и наша программа обретает
собственную политику. Правило pam_listfile с sense=allow — зеркало запрещающего
списка из демо 02: разрешены только перечисленные. bob проходит, carol с верным
паролем получает отказ, и событие ложится в auth.log с именем нашей службы.
Теперь программа - полноправный гражданин PAM: администратор может добавить ей
TOTP из раздела 6 одной строкой. Это и есть смысл использования libpam вместо
самодельной проверки пароля.
-->

---
layout: section
---

# 8. Разработка модуля PAM
## Интерфейс модуля: pam_sm_* и учебный модуль pam_math

---

# Интерфейс модуля: функции pam_sm_*

Модуль — разделяемая библиотека, экспортирующая **сервисные функции** —
зеркало вызовов приложения (<Man p="pam_sm_authenticate(3)" />):

<div class="t-table text-xs mt-2">

| Вызов приложения | Функция модуля | Стек |
|---|---|---|
| `pam_authenticate` | `pam_sm_authenticate` | auth |
| `pam_setcred` | `pam_sm_setcred` | auth |
| `pam_acct_mgmt` | `pam_sm_acct_mgmt` | account |
| `pam_chauthtok` | `pam_sm_chauthtok` (вызывается дважды: preliminary + update) | password |
| `pam_open_session` / `pam_close_session` | `pam_sm_open_session` / `pam_sm_close_session` | session |

</div>

```c
#include <security/pam_modules.h>
int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv);
```

<div class="grid grid-cols-3 gap-3 mt-2 text-xs">
<div class="p-2 border border-slate-400/40 rounded">
<b>Достаточно реализовать функции своего типа:</b> модуль только для стека auth
экспортирует <code>pam_sm_authenticate</code> и <code>pam_sm_setcred</code>.
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b><code>argc/argv</code></b> — те самые module-arguments из строки правила
(<code>max=50</code>); разбирает их сам модуль.
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b><code>flags</code></b>: например, <code>PAM_SILENT</code> — «не выводить
сообщений»; модуль обязан уважать флаги.
</div>
</div>

<Refs ids="man-pam-sm-authenticate pam-mwg" />

<!--
Симметрия интерфейсов: каждому вызову приложения соответствует pam_sm_-функция
модуля; libpam находит её по имени через dlsym (раздел 9). Реализуются только
функции нужных стеков: auth-модулю достаточно pam_sm_authenticate и
pam_sm_setcred. Аргументы argc/argv — слова из строки правила после имени
модуля; соглашения о формате (ключ=значение) — на совести модуля. flags —
модификаторы вызова, PAM_SILENT запрещает вывод. pam_sm_chauthtok вызывается
дважды: сначала проверка выполнимости (PRELIM_CHECK), затем собственно смена.
-->

---

# Сервисные функции для модулей

Модуль работает с транзакцией через API libpam (заголовки
`pam_modules.h`, `pam_ext.h`):

<div class="t-table text-xs mt-2">

| Функция | Назначение |
|---|---|
| `pam_get_user(pamh, &user, prompt)` | имя пользователя: из контекста — или вопросом через диалог (<Man p="pam_get_user(3)" />) |
| `pam_get_item / pam_set_item` | элементы контекста: `PAM_USER`, `PAM_TTY`, `PAM_RHOST`, `PAM_AUTHTOK`… |
| `pam_prompt(pamh, style, &resp, fmt, …)` | вопрос пользователю через функцию диалога приложения |
| `pam_error / pam_info` | сообщение об ошибке / информационный текст |
| `pam_get_authtok` | пароль: уже введённый выше по стеку — или запросить (конвенция `use_authtok`) |
| `pam_get_data / pam_set_data` | приватные данные модуля внутри транзакции |
| `pam_syslog` | запись в системный журнал от имени модуля |

</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Главное правило:</b> модуль не читает терминал и не пишет на него —
весь ввод-вывод идёт <b>через диалог приложения</b> (<code>pam_prompt</code>,
<code>pam_error</code>): только так модуль одинаково работает в консоли,
GDM и sshd (раздел 7).
</div>

</v-click>

<Refs ids="man-pam-get-user pam-mwg" />

<!--
Инструментарий автора модуля. pam_get_user — каноничный способ узнать, кого
аутентифицируем: имя берётся из контекста (его мог задать pam_start или
предыдущий модуль), а при отсутствии запрашивается через диалог. pam_get_item/
set_item — доступ к элементам транзакции, включая PAM_AUTHTOK — пароль, которым
модули делятся по конвенции use_authtok/try_first_pass (раздел 5). pam_prompt,
pam_error, pam_info — обёртки над функцией диалога; pam_syslog — журналирование.
Повторить правило: никакого прямого ввода-вывода.
-->

---

# pam_math: задача и имя пользователя

Учебный модуль: «аутентификация» арифметической задачей. Разбор
`assets/src/pam_math.c` — первая половина:

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-2 items-start">
<div>

```c
#include <security/pam_modules.h>
#include <security/pam_ext.h>

int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                        int argc, const char **argv)
{
    const char *user = NULL;
    char *resp = NULL;
    long max = 100;
    int a, b, rc, i;

    /* module-arguments: поддерживаем max=N */
    for (i = 0; i < argc; i++)
        if (strncmp(argv[i], "max=", 4) == 0)
            max = atol(argv[i] + 4);

    rc = pam_get_user(pamh, &user, NULL);
    if (rc != PAM_SUCCESS)
        return rc;

    srandom((unsigned) (time(NULL) ^ getpid()));
    a = (int) (random() % max);
    b = (int) (random() % max);
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Заголовки модуля: <code>pam_modules.h</code> (интерфейс
<code>pam_sm_*</code>) и <code>pam_ext.h</code>
(<code>pam_prompt</code>, <code>pam_error</code>).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Аргумент правила <code>max=N</code> ограничивает слагаемые — разбор
<code>argv</code> тривиален и целиком на модуле.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_get_user</code> — третий аргумент <code>NULL</code>:
использовать стандартное приглашение «login:», если имя ещё
не известно транзакции.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Код возврата <code>pam_get_user</code> проверяем и <b>пробрасываем</b>:
при <code>PAM_CONV_ERR</code> решение примет стек, а не модуль.
</div>

</div>
</div>

<Refs ids="pam-mwg man-pam-get-user man-pam-sm-authenticate" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Первая половина модуля. Два заголовка: pam_modules.h и pam_ext.h. Обходим argv —
поддержан один аргумент max=N. pam_get_user с NULL-приглашением: если имя уже
есть в транзакции (его передал pam_start из authprint), диалога не будет.
Генерация задачи обычным random — для учебного модуля достаточно;
криптографическая стойкость здесь не требуется, что честно оговорено в
комментарии исходника. Коды возврата сервисных функций пробрасываем наверх —
пусть решает стек.
-->

---

# pam_math: диалог и результат

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

```c
    /* вопрос через диалог приложения;
       ввод отображается: это не пароль */
    rc = pam_prompt(pamh, PAM_PROMPT_ECHO_ON, &resp,
                    "math for %s: %d + %d = ", user, a, b);
    if (rc != PAM_SUCCESS)
        return rc;
    if (resp == NULL)
        return PAM_AUTH_ERR;

    if (atoi(resp) == a + b) {
        rc = PAM_SUCCESS;
    } else {
        pam_error(pamh, "Wrong answer.");
        rc = PAM_AUTH_ERR;
    }
    free(resp);
    return rc;
}

/* auth-модулю обязательна и вторая функция */
int pam_sm_setcred(pam_handle_t *pamh, int flags,
                   int argc, const char **argv)
{
    return PAM_IGNORE;
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_prompt</code> со стилем <code>PAM_PROMPT_ECHO_ON</code>:
вопрос дойдёт до пользователя через <code>misc_conv</code>,
окно GDM или сетевой диалог sshd — модулю всё равно.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Неверный ответ: <code>pam_error</code> отправляет сообщение
(<code>PAM_ERROR_MSG</code>), возврат — <code>PAM_AUTH_ERR</code>;
как это скажется на итоге, решит <b>управляющий флаг</b> правила.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_sm_setcred</code> обязана существовать у auth-модуля;
выдавать нечего — возвращаем <code>PAM_IGNORE</code>.
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
Ответ пользователя — память, выделенная libpam:
освобождаем <code>free(resp)</code>. В настоящих модулях
секреты перед освобождением затирают.
</div>

</div>
</div>

<Refs ids="pam-mwg man-pam-get-user man-pam-sm-authenticate" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Вторая половина. pam_prompt с ECHO_ON — ввод виден, это не секрет. Сравнение
ответа: успех — PAM_SUCCESS, иначе pam_error с сообщением и PAM_AUTH_ERR.
Подчеркнуть разделение ответственности: модуль лишь сообщает СВОЙ результат;
итог стека определит управляющий флаг — required, requisite или подробная
форма. pam_sm_setcred возвращает PAM_IGNORE — «моего мнения нет»; вспомнить
таблицу действий: ignore не влияет на итог. Замечание о free: ответы диалога
освобождает модуль; в боевых модулях секреты затирают до free.
-->

---

# Демо 09: сборка, установка, служба

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/12-pam-math.txt" section="1" title="demo 09 · сборка и установка" fontSize="0.5rem">
  <TCallout :line="1" :col="13" :span="13" :n="1" />
  <TCallout :line="5" :col="30" :span="35" :n="2" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/12-pam-math.txt" section="2" title="demo 09 · служба mathtest: клиент — authprint" fontSize="0.5rem">
  <TCallout :line="2" :col="21" :span="18" :n="3" />
  <TCallout :line="6" :col="1" :span="26" :n="4" />
  <TCallout :line="10" :col="24" :span="1" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> сборка разделяемой библиотеки: <code>-fPIC -shared</code>; имя — <code>pam_math.so</code></div>
<div><span class="co-ball">2</span> установка в каталог модулей (раздел 2.1), права 644, владелец root</div>
<div><span class="co-ball">3</span> служба <code>mathtest</code>: одно правило auth с аргументом <code>max=50</code>; account — <code>pam_permit</code></div>
<div><span class="co-ball">4</span> клиент — <code>authprint mathtest</code> из раздела 7: вопрос модуля пришёл через <code>misc_conv</code>; верный ответ — успех</div>
<div><span class="co-ball">5</span> неверный ответ — «Wrong answer.» и отказ</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Разделы 7 и 8 сомкнулись: наше приложение и наш модуль общаются через libpam,
не зная друг о друге.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/09-pam-math.sh</code>; исходный код — <code>assets/src/pam_math.c</code>.
</div>

<!--
Сборка: -fPIC -shared, получаем pam_math.so; установка в каталог модулей с
правами 644 root. Служба mathtest из двух строк: auth required pam_math.so
max=50, account pam_permit. Тестовый клиент — authprint из раздела 7 с именем
службы mathtest: вопрос «math for bob: 23+14=» пришёл из модуля через libpam и
misc_conv; правильный ответ печатает строку, неверный — Wrong answer и
Authentication failure. Приложение и модуль не знают друг о друге — их связал
конфигурационный файл.
-->

---

# Демо 09: модуль как второй фактор в sshd

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/12-pam-math.txt" section="3" title="demo 09 · pam_math в стеке sshd">
  <TCallout :line="3" :col="25" :span="11" :n="1" />
  <TCallout :line="7" :col="17" :span="25" :n="2" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> строка после <code>@include common-auth</code> — как у TOTP-модуля в разделе 6</div>
<div><span class="co-ball">2</span> ssh задаёт пароль, затем вопрос модуля — диалог дошёл по сети через keyboard-interactive</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> собственный модуль ничем не отличается от «фирменных»:
те же правила, те же стеки, тот же диалог. Весь инструментарий раздела 6
теперь доступен и вашему коду.
</div>

</v-click>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
Знание арифметики — не секрет: <code>pam_math</code> — учебная модель
«второго фактора», а не средство защиты.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/09-pam-math.sh</code>.
</div>

<!--
Финал демонстрации: та же строка, что для google_authenticator в разделе 6,
подключает наш модуль вторым фактором к sshd. Клиент ssh показывает вопрос
модуля после пароля — диалог прошёл по сети через keyboard-interactive, модуль
об этом не знает. Красная карточка обязательна: арифметика — не секрет, модуль
учебный; но каркас — ровно тот, на котором строятся настоящие факторы.
-->

---

# Безопасность модулей PAM

Модуль исполняется **в адресном пространстве привилегированного процесса**
(login, sshd работают от root) и **видит пароли** в открытом виде — это делает
стек PAM привлекательной целью.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

**Вредоносные модули — реальный класс атак:**

- троянизированный `pam_unix.so` или добавленный в стек
  модуль-бэкдор **перехватывает пароли** всех входящих
  и может впускать атакующего по мастер-паролю;
- исследователи Unit 42 (2023) и Nextron (2025, бэкдор
  Plague) описывают семейства вредоносных PAM-модулей,
  годами остававшихся незамеченными;
- установка модуля требует root — это инструмент
  **закрепления** (persistence) после компрометации.

</div>
<div>

**Контрмеры:**

<div class="t-table text-xs">

| Мера | Инструмент |
|---|---|
| контроль целостности `/etc/pam.d/`, каталога модулей | `dpkg -V`, AIDE, auditd-правила на запись |
| модули только из пакетов дистрибутива | подпись репозиториев |
| ревизия стеков после инцидентов | `pam-auth-update`, diff с эталоном |
| журналирование | syslog/auditd: новые модули видны по отказам и записям |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Правка стека PAM и каталога модулей должна быть <b>событием</b>,
которое замечает мониторинг.
</div>

</div>
</div>

<Refs ids="unit42-pam pam-mwg" />

<!--
Оборотная сторона расширяемости. Модуль получает управление внутри
привилегированного процесса и видит пароль открытым текстом (PAM_AUTHTOK).
Вредоносные модули — задокументированный класс: обзор Unit 42 (2023) и бэкдор
Plague (Nextron, 2025) — модули, перехватывающие пароли и впускающие по
мастер-паролю; ставятся после получения root как средство закрепления.
Контрмеры организационно-технические: целостность pam.d и каталога модулей
(dpkg -V, AIDE, auditd), модули только из подписанных репозиториев, ревизия
стеков. Мост к разделу 9: чтобы читать и проверять стеки, нужно понимать, как
libpam их исполняет, — смотрим исходный код.
-->

---
layout: section
---

# 9. Реализация Linux-PAM

<SectionTOC prefix="9" :current="1" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: struct pam_handle

Смотрим Linux-PAM **v1.7.0** — версию из Ubuntu 26.04. Непрозрачный
`pam_handle_t` из раздела 7 внутри libpam определён так:

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-2">
<div>

```c
/* libpam/pam_private.h, строки 153–184 (сокращено) */
struct pam_handle {
    char *authtok;               /* пароль (PAM_AUTHTOK) */
    unsigned caller_is;          /* приложение или модуль */
    struct pam_conv *pam_conversation;  /* диалог */
    char *oldauthtok;
    char *prompt;                /* для pam_get_user() */
    char *service_name;          /* имя службы */
    char *user;                  /* PAM_USER */
    char *rhost; char *ruser; char *tty;
    /* … */
    struct pam_data *data;       /* pam_set_data модулей */
    struct pam_environ *env;     /* окружение PAM */
    struct _pam_fail_delay fail_delay;
    struct service handlers;     /* ЗАГРУЖЕННЫЕ СТЕКИ */
    struct _pam_former_state former; /* resume-состояние */
    const char *mod_name;        /* исполняемый модуль */
    /* … */
};
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Всё, что мы передавали в <code>pam_start</code> и <code>pam_set_item</code>,
лежит здесь: служба, пользователь, функция диалога, терминал, удалённый хост.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>authtok</code> — тот самый пароль, который модули передают друг другу
(<code>use_authtok</code>): он живёт в контексте и затирается по завершении
стека.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>handlers</code> — разобранная конфигурация службы: стеки правил
(следующий слайд); <code>former</code> хранит состояние прерванного стека
(<code>PAM_INCOMPLETE</code>) для событийных приложений.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<code>caller_is</code> различает приложение и модуль: часть API разрешена
только одной из сторон.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L153">libpam/pam_private.h#L153</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Раздел для любознательных: читаем реализацию той версии, что стоит на нашем
стенде. pam_handle — всё состояние транзакции: элементы (служба, пользователь,
терминал…), пароль authtok, окружение, приватные данные модулей, и главное —
handlers: разобранные стеки правил. former — сохранённое состояние для
приложений, которые прерывают стек (PAM_INCOMPLETE) и возобновляют позже.
caller_is охраняет границу приложение/модуль: например, pam_authenticate из
модуля запрещён.
-->

---

# Исходный код: struct handler

<div class="grid grid-cols-2 gap-4 mt-1">
<div>

```c
/* libpam/pam_private.h, строки 53–100 (сокращено) */
struct handler {
    int handler_type;      /* модуль | must-fail | substack */
    int (*func)(pam_handle_t *pamh, int flags,
                int argc, char **argv);
    int actions[_PAM_RETURN_VALUES]; /* и флаг правила */
    int cached_retval; int *cached_retval_p;
    int argc; char **argv; /* аргументы модуля */
    struct handler *next;  /* следующее правило стека */
    char *mod_name;
    int stack_level;       /* глубина substack */
    int grantor;           /* правило, давшее успех */
};

struct handlers {          /* шесть стеков службы */
    struct handler *authenticate, *setcred,
        *acct_mgmt, *open_session,
        *close_session, *chauthtok;
};
struct service {
    struct loaded_module *module;  /* загруженные .so */
    /* … */
    struct handlers conf;   /* правила службы */
    struct handlers other;  /* правила по умолчанию */
};
```

</div>
<div>

<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Каждая строка конфигурации стала узлом <b>односвязного списка</b>:
указатель на функцию модуля, разобранные аргументы и — вместо текста
флага — массив <code>actions</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>actions[i]</code> — действие на код возврата <code>i</code>:
подробная форма флага хранится буквально.
</div>

</div>

```c
/* строки 194–200: кодировка действий */
#define _PAM_ACTION_IS_JUMP(x)  ((x) > 0)   /* N  */
#define _PAM_ACTION_IGNORE      0
#define _PAM_ACTION_OK         (-1)
#define _PAM_ACTION_DONE       (-2)
#define _PAM_ACTION_BAD        (-3)
#define _PAM_ACTION_DIE        (-4)
#define _PAM_ACTION_RESET      (-5)
```

<div class="text-xs p-2 border-l-4 border-sky-500 bg-sky-500/10 mt-2">
Положительное значение — прыжок на N правил; именованные действия —
отрицательные константы. Таблица действий из раздела 2.4 — ровно этот массив.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L53">pam_private.h#L53</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L194">#L194</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Структура правила. func — найденная dlsym-ом функция pam_sm_* (как — в 9.2);
argc/argv — слова аргументов; next — связь в список: стек буквально является
односвязным списком. Главная идея — actions: массив, индексированный кодом
возврата модуля; управляющий флаг строки разворачивается в заполнение этого
массива. Кодировка: 0 — ignore, отрицательные — именованные действия,
положительные — прыжки. handlers — шесть голов списков (по вызовам API);
service хранит два набора: conf — правила службы, other — запасные.
-->

---
layout: section
---

# 9. Реализация Linux-PAM

<SectionTOC prefix="9" :current="2" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: где libpam ищет конфигурацию

Стеки загружаются **лениво**: первый вызов `pam_authenticate` (или другого
диспетчера) вызывает `_pam_init_handlers`, та открывает конфигурацию службы:

<div class="grid grid-cols-2 gap-4 mt-2">
<div>

```c
/* libpam/pam_private.h, строки 28–35 */
#define PAM_CONFIG         "/etc/pam.conf"
#define PAM_CONFIG_D       "/etc/pam.d"
#define PAM_CONFIG_DF      "/etc/pam.d/%s"
#define PAM_CONFIG_DIST_D  "/usr/lib/pam.d"
#define PAM_CONFIG_DIST_DF "/usr/lib/pam.d/%s"
```

```c
/* libpam/pam_handlers.c, строки 293–352 (сокращено) */
static int _pam_open_config_file(pam_handle_t *pamh,
    const char *service, char **path, FILE **file)
{
    const char *const pamd_dirs[] =
        { PAM_CONFIG_DF, PAM_CONFIG_DIST_DF };
    /* … */
    for (i = 0; i < PAM_ARRAY_SIZE(pamd_dirs); i++) {
        asprintf(&p, pamd_dirs[i], service);
        f = fopen(p, "r");
        if (f != NULL) { *path = p; *file = f;
                         return PAM_SUCCESS; }
        /* … */
    }
    return PAM_ABORT;
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Приоритет каталогов из раздела 2.2 — это <b>порядок элементов массива</b>
<code>pamd_dirs</code>: сначала <code>/etc/pam.d/%s</code>, затем
<code>/usr/lib/pam.d/%s</code>; побеждает первый открывшийся файл.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>_pam_init_handlers</code> использует <code>/etc/pam.conf</code>, только
если каталога <code>/etc/pam.d</code> нет (сборочная опция
<code>PAM_READ_BOTH_CONFS</code> — читать оба).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
После файла службы тем же путём разбирается служба
<code>other</code> — заполняются оба набора стеков
(<code>conf</code> и <code>other</code> из 9.1).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Повторный вызов — без повторного разбора:
<code>handlers_loaded</code> делает загрузку однократной
на транзакцию.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L28">pam_private.h#L28</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L293">pam_handlers.c#L293</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L405">#L405 (_pam_init_handlers)</a>.
</div>

<Refs ids="linux-pam-src man-pam-conf" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.55rem !important; line-height: 1.3 !important; }
</style>

<!--
Начало пути: pam_start конфигурацию не читает — только копирует имена; разбор
происходит при первом диспетчерском вызове, в _pam_init_handlers. Пути из
раздела 2.2 зашиты константами; приоритет /etc/pam.d над /usr/lib/pam.d — это
буквально порядок массива pamd_dirs в цикле fopen. pam.conf используется только
при отсутствии pam.d (или в сборке READ_BOTH_CONFS). После службы разбирается
other — отсюда два набора стеков в struct service. handlers_loaded кэширует
результат на время транзакции — но не между процессами: каждый вход читает
конфигурацию заново, поэтому правки pam.d действуют немедленно.
-->

---

# Исходный код: разбор строки правила

`_pam_parse_conf_file` читает файл построчно; поле **type**:

<div class="grid grid-cols-2 gap-4 mt-2">
<div>

```c
/* libpam/pam_handlers.c, строки 116–139 (сокращено) */
if (tok[0] == '-') { /* не журналировать отсутствие */
    handler_type = PAM_HT_SILENT_MODULE;
    ++tok;
}
if (!strcasecmp("auth", tok)) {
    module_type = PAM_T_AUTH;
} else if (!strcasecmp("session", tok)) {
    module_type = PAM_T_SESS;
} else if (!strcasecmp("account", tok)) {
    module_type = PAM_T_ACCT;
} else if (!strcasecmp("password", tok)) {
    module_type = PAM_T_PASS;
} else {
    /* Illegal module type */
    pam_syslog(pamh, LOG_ERR,
        "(%s) illegal module type: %s",
        this_service, tok);
    module_type = … ;        /* PAM_T_AUTH */
    handler_type = PAM_HT_MUST_FAIL;
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Четыре типа из раздела 2.3 — четыре константы <code>PAM_T_*</code>;
дефис перед типом включает «тихую» загрузку (<code>-auth</code>).
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Обещание «ошибка = отказ» выполняется здесь:</b> неизвестный тип не
отбрасывает строку, а создаёт правило <code>PAM_HT_MUST_FAIL</code> —
при исполнении оно вернёт <code>PAM_PERM_DENIED</code>. Опечатка в
<code>/etc/pam.d</code> ломает вход — в сторону запрета.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Тип по умолчанию для сломанной строки — <code>PAM_T_AUTH</code>
с комментарием «most sensitive»: самый чувствительный стек.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Директивы <code>include</code>/<code>substack</code> обрабатываются
рекурсивно: <code>_pam_load_conf_file</code> с ограничением глубины
<code>PAM_SUBSTACK_MAX_LEVEL</code> (16).
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L54">pam_handlers.c#L54 (_pam_parse_conf_file)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L122">#L122</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Разбор строки. Поле type: четыре strcasecmp, дефис-префикс для тихой загрузки.
Самое интересное — ветка else: нераспознанный тип не игнорируется, строка
превращается в правило «обязан отказать» (PAM_HT_MUST_FAIL) в самом
чувствительном стеке auth, с записью в syslog. Это реализация принципа
fail-closed, который мы анонсировали в разделе 2.5: опечатка администратора
ломает вход, а не молча открывает его. include/substack разворачиваются
рекурсией с лимитом глубины 16.
-->

---

# Исходный код: флаг → массив actions

Поле **control** заполняет массив `actions` правила — краткие флаги
разворачиваются в те же действия, что их подробные формы (раздел 2.4):

<div class="grid grid-cols-2 gap-4 mt-2">
<div>

```c
/* libpam/pam_handlers.c, строки 163–199 (сокращено) */
} else if (!strcasecmp("required", tok)) {
    actions[PAM_SUCCESS] = _PAM_ACTION_OK;
    actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_OK;
    actions[PAM_IGNORE] = _PAM_ACTION_IGNORE;
    _pam_set_default_control(actions, _PAM_ACTION_BAD);
} else if (!strcasecmp("requisite", tok)) {
    actions[PAM_SUCCESS] = _PAM_ACTION_OK;
    actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_OK;
    actions[PAM_IGNORE] = _PAM_ACTION_IGNORE;
    _pam_set_default_control(actions, _PAM_ACTION_DIE);
} else if (!strcasecmp("sufficient", tok)) {
    actions[PAM_SUCCESS] = _PAM_ACTION_DONE;
    actions[PAM_NEW_AUTHTOK_REQD] = _PAM_ACTION_DONE;
    _pam_set_default_control(actions, _PAM_ACTION_IGNORE);
} else {
    /* подробная форма: [success=… default=…] */
    _pam_parse_control(actions, tok);
    _pam_set_default_control(actions, _PAM_ACTION_BAD);
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Сравните с таблицей соответствия из раздела 2.4: <code>required</code> =
<code>[success=ok new_authtok_reqd=ok ignore=ignore default=bad]</code> —
код заполняет массив буквально по ней.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>_pam_set_default_control</code> записывает действие во все ещё
не заданные ячейки — реализация слова <code>default</code>.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
После флага читаются имя модуля и аргументы, и правило уходит в
<code>_pam_add_handler</code> — загрузку модуля (следующий слайд).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
В подробной форме действие по умолчанию — <code>bad</code>:
не перечисленный код возврата считается неудачей.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L163">pam_handlers.c#L163</a>.
</div>

<Refs ids="linux-pam-src man-pam-conf" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Поле control. Каждый краткий флаг — явное заполнение ячеек actions: success и
new_authtok_reqd получают ok (или done у sufficient), остальное — через
_pam_set_default_control: bad у required, die у requisite, ignore у sufficient
и optional. Любой другой токен уходит в _pam_parse_control — разбор квадратных
скобок, и default там тоже bad. Таблица эквивалентности из man-страницы — не
аналогия, а точное описание этого кода.
-->

---

# Исходный код: загрузка модуля

`_pam_add_handler` превращает имя `.so` в указатель на функцию:

<div class="grid grid-cols-2 gap-4 mt-2">
<div>

```c
/* libpam/pam_handlers.c, строки 604–700 (сокращено) */
static struct loaded_module *
_pam_load_module(pam_handle_t *pamh,
                 const char *mod_path, int handler_type)
{
    /* уже загружен? ищем по имени */
    /* … */
    mod->dl_handle = _pam_dlopen(mod_path);
    if (mod->dl_handle == NULL) {
        pam_syslog(pamh, LOG_ERR,
            "unable to dlopen(%s): %s", …);
        mod->type = PAM_MT_FAULTY_MOD; /* «сломанный» */
    }
    /* … */
}
```

```c
/* строки 755–800 (сокращено): выбор символа */
case PAM_T_AUTH:
    handler_p = &the_handlers->authenticate;
    sym  = "pam_sm_authenticate";
    sym2 = "pam_sm_setcred";
    break;
/* … */
func = _pam_dlsym(mod->dl_handle, sym);
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Модуль загружается <code>dlopen(3)</code> один раз на транзакцию
(список <code>loaded_module</code>); относительное имя libpam
дополняет путём каталога модулей (раздел 2.1).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Для каждого типа правила — своё имя символа: правило <code>auth</code>
ищет в модуле <code>pam_sm_authenticate</code>. Вот почему наш
<code>pam_math.so</code> обязан экспортировать именно эти имена
(раздел 8).
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
Модуль не нашёлся или без нужного символа? Правило остаётся в стеке
как <b>неисправное</b> (<code>PAM_MT_FAULTY_MOD</code> /
<code>func == NULL</code>) — при исполнении оно даст отказ.
Снова fail-closed.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L604">pam_handlers.c#L604 (_pam_load_module)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L762">#L762 (выбор символа)</a>.
</div>

<Refs ids="linux-pam-src pam-mwg" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Последний шаг разбора — загрузка модуля. _pam_load_module ведёт список уже
загруженных .so и вызывает dlopen один раз; ошибка загрузки не выбрасывает
правило, а помечает модуль неисправным — исполнение даст отказ. Выбор символа
по типу правила: auth → pam_sm_authenticate (и setcred вторым символом),
account → pam_sm_acct_mgmt и т. д.; dlsym возвращает указатель, который ляжет
в handler->func. Теперь понятно всё, что требовалось от pam_math: правильные
имена экспортируемых функций.
-->

---
layout: section
---

# 9. Реализация Linux-PAM

<SectionTOC prefix="9" :current="3" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: pam_authenticate и выбор стека

<div class="grid grid-cols-2 gap-4 mt-1">
<div>

```c
/* libpam/pam_auth.c, строки 14–49 (сокращено) */
int pam_authenticate(pam_handle_t *pamh, int flags)
{
    if (__PAM_FROM_MODULE(pamh))
        return PAM_SYSTEM_ERR;      /* только приложение */

    if (pamh->former.choice == PAM_NOT_STACKED) {
        _pam_sanitize(pamh);        /* стереть authtok   */
        _pam_start_timer(pamh);  /* время неудачи
                                    не зависит от её места */
    }
    retval = _pam_dispatch(pamh, flags,
                           PAM_AUTHENTICATE);
    if (retval != PAM_INCOMPLETE) {
        _pam_sanitize(pamh);
        _pam_await_timer(pamh, retval); /* выждать */
    }
    return retval;
}
```

</div>
<div>

```c
/* libpam/pam_dispatch.c, строки 334–381 (сокращено) */
int _pam_dispatch(pam_handle_t *pamh, int flags, int choice)
{
    if ((retval = _pam_init_handlers(pamh)) != PAM_SUCCESS)
        /* загрузить стеки (раздел 9.2) */ ;

    switch (choice) {
    case PAM_AUTHENTICATE:
        h = pamh->handlers.conf.authenticate; break;
    case PAM_ACCOUNT:
        h = pamh->handlers.conf.acct_mgmt;    break;
    /* … setcred, session, chauthtok … */
    }
    if (h == NULL)      /* у службы нет такого стека */
        h = pamh->handlers.other.authenticate; /* … */

    retval = _pam_dispatch_aux(pamh, flags, h, …);
    /* … */
}
```

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<code>_pam_await_timer</code> — защита от хронометража: libpam выдерживает
паузу при неудаче (по умолчанию её просит <code>pam_unix</code>), и время
ответа не выдаёт, какой модуль отказал.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_auth.c#L14">pam_auth.c#L14</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L334">pam_dispatch.c#L334</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Путь вызова приложения. pam_authenticate: проверка «вызывает приложение, не
модуль», очистка старого authtok, запуск таймера — и _pam_dispatch. Таймер
реализует fail delay: при неудаче библиотека выдерживает запрошенную модулями
паузу, выравнивая время ответа, — защита от перебора и от анализа времени.
_pam_dispatch: догрузить стеки, выбрать голову списка по choice — это таблица
«вызов API - стек» из раздела 7, в коде; при отсутствии стека у службы — стек
other. Сам проход — в _pam_dispatch_aux.
-->

---

# Исходный код: цикл по стеку

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1">
<div>

```c
/* libpam/pam_dispatch.c, строки 34–116 (сокращено) */
static int _pam_dispatch_aux(pam_handle_t *pamh, int flags,
    struct handler *h, …)
{
    int impression = _PAM_UNDEF;         /* «мнение» */
    int status = PAM_MUST_FAIL_CODE;     /* = PERM_DENIED */

    if (h == NULL) {   /* стек пуст — модулей нет */
        pam_syslog(pamh, LOG_ERR,
                   "no modules loaded for `%s' service", …);
        return PAM_MUST_FAIL_CODE;
    }

    for (depth = 0; h != NULL; h = h->next, ++depth) {
        if (h->handler_type == PAM_HT_MUST_FAIL)
            retval = PAM_MUST_FAIL_CODE;  /* битая строка */
        else if (h->func == NULL)
            retval = PAM_MODULE_UNKNOWN;  /* символ не найден */
        else {
            pamh->mod_name = h->mod_name;
            retval = h->func(pamh, flags, h->argc, h->argv);
        }
        /* … INCOMPLETE: сохранить состояние и выйти … */
        action = h->actions[retval];      /* ЧТО ДЕЛАТЬ?   */
        switch (action) { /* следующий слайд */ }
    }
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Исходное состояние итога — <b>отказ</b>: пустой стек, стек из одних
<code>ignore</code>, битые строки — всё даёт
<code>PAM_PERM_DENIED</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Вызов модуля — это вызов <code>h->func</code>: указателя, найденного
<code>dlsym</code> (9.2); на время вызова контекст получает имя модуля —
для <code>pam_syslog</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Результат модуля превращается в действие <b>одним обращением
к массиву</b>: <code>action = h->actions[retval]</code> —
вся семантика флагов уже разложена по ячейкам (9.2).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<code>PAM_INCOMPLETE</code> (диалог не может завершиться сейчас)
сохраняет позицию в <code>pamh->former</code> — приложение
повторит вызов, и стек продолжится с того же места.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L34">pam_dispatch.c#L34 (_pam_dispatch_aux)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L110">#L110 (вызов модуля)</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Сердце PAM — цикл по односвязному списку правил. Два аккумулятора: impression —
«мнение» (не определено / положительное / отрицательное) и status — будущий код
возврата, инициализированный отказом. Битые правила (must-fail, func==NULL)
не вызываются — сразу получают код отказа. Нормальный вызов — h->func(...);
mod_name на время вызова — для журналирования. Ключевая строка слайда:
action = h->actions[retval] — семантика управляющих флагов исполняется одним
индексированием массива. PAM_INCOMPLETE — механизм прерывания для событийных
приложений (GDM): состояние прячется в former, повторный вызов продолжит стек.
-->

---
layout: section
---

# 9. Реализация Linux-PAM

<SectionTOC prefix="9" :current="4" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: применение действия

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1">
<div>

```c
/* libpam/pam_dispatch.c, строки 201–300 (сокращено) */
switch (action) {
case _PAM_ACTION_OK:
case _PAM_ACTION_DONE:
    if (impression == _PAM_UNDEF ||
        (impression == _PAM_POSITIVE
         && status == PAM_SUCCESS)) {
        impression = _PAM_POSITIVE;
        status = retval;             /* успех записан */
    }
    if (impression == _PAM_POSITIVE) {
        if (retval == PAM_SUCCESS) h->grantor = 1;
        if (action == _PAM_ACTION_DONE)
            goto decision_made;      /* done: выходим  */
    }
    break;
case _PAM_ACTION_BAD:
case _PAM_ACTION_DIE:
    if (impression != _PAM_NEGATIVE) {
        impression = _PAM_NEGATIVE;  /* ПЕРВАЯ неудача */
        status = retval;             /* запоминается   */
    }
    if (action == _PAM_ACTION_DIE) goto decision_made;
    break;

case _PAM_ACTION_IGNORE: break;
default:  /* прыжок: пропустить action правил */
    if (_PAM_ACTION_IS_JUMP(action)) { /* … h = h->next … */ }
}
```

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Неудача «липкая»:</b> первая неудача переводит <code>impression</code>
в отрицательное — последующие успехи <b>не могут</b> его перебить
(условие в ветке OK требует «не отрицательного» мнения). Так
<code>required</code> гарантирует отказ, продолжая стек.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>done</code>/<code>die</code> — тот же <code>ok</code>/<code>bad</code>
плюс <code>goto decision_made</code>: немедленный выход;
<code>requisite</code> и <code>sufficient</code> построены на них.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Прыжок <code>N</code> пропускает правила с учётом
<code>stack_level</code>: вложенный <code>substack</code>
пролетается целиком как одно правило.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<code>grantor</code> помечает правило, «давшее» успех, —
след для аудита: кто именно впустил.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L201">pam_dispatch.c#L201</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.55rem !important; line-height: 1.3 !important; }
</style>

<!--
Применение действия — switch. Ветка OK/DONE: успех записывается, только пока
мнение не отрицательное; ветка BAD/DIE: первая неудача фиксирует и мнение, и
статус — последующие успехи и неудачи статус не меняют. Отсюда вся семантика
required: неудача учтена, но стек продолжается, и итог уже не изменить.
done/die добавляют немедленный выход через goto. Прыжки учитывают stack_level —
substack пропускается как единое целое. grantor — пометка правила, принёсшего
успех: libpam может сообщить аудиту, кто именно впустил.
-->

---

# Исходный код: страховка на выходе

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-1">
<div>

```c
/* libpam/pam_dispatch.c, строки 303–317 */
    /* Sanity check */
    if ( status == PAM_SUCCESS
         && impression != _PAM_POSITIVE ) {
        D(("caught on sanity check -- "
           "this is probably a config error!"));
        status = PAM_MUST_FAIL_CODE;
    }

    /* We have made a decision about the modules
       executed */
    return status;
}
```

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Итог раздела — инварианты libpam:</b> вернуть успех может только стек,
в котором <b>хотя бы одно не-ignore правило явно дало успех</b>; любая
двусмысленность — пустой стек, битая строка, незагрузившийся модуль,
рассогласование статуса — разрешается <b>отказом</b>.
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Последний рубеж: если к концу стека статус «успех», а положительного
мнения нет (например, стек состоял из одних <code>ignore</code>), —
итог принудительно заменяется отказом.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Комментарий в коде честен: такая ситуация — «probably a config
error» — ошибка конфигурации, и libpam ошибается в безопасную
сторону.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Для <code>setcred</code>/<code>close_session</code> стек исполняется
по «замороженной цепочке» (<code>cached_retval</code>): те же модули
и решения, что при <code>authenticate</code>/<code>open_session</code>, —
симметрия выдачи и отзыва.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L303">pam_dispatch.c#L303</a>.
</div>

<Refs ids="linux-pam-src" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.6rem !important; line-height: 1.35 !important; }
</style>

<!--
Финальные строки _pam_dispatch_aux — санитарная проверка: статус «успех» без
положительного впечатления заменяется отказом. Вместе с must-fail правилами,
faulty-модулями и инициализацией отказом это складывается в систему инвариантов
fail-closed, которую мы наблюдали всю лекцию со стороны конфигурации. Упомянуть
frozen chain: setcred и close_session повторяют решения парного стека по
кэшированным результатам — выдача и отзыв удостоверений симметричны. На этом
реализация замкнулась: от строки конфигурации до возврата в приложение.
-->

---
layout: section
---

# Источники

---
routeAlias: refs
---

# Источники

<SourcesList class="mt-4" />

<div class="text-xs opacity-70 mt-3">
Нумерация сквозная для всей лекции; ссылки «[n]» внизу слайдов ведут сюда и
подсвечивают источник. Точные версии и особенности системы — локальные
man-страницы Ubuntu Server 26.04 (Linux-PAM 1.7.0); фрагменты исходного кода —
Linux-PAM v1.7.0.
</div>
