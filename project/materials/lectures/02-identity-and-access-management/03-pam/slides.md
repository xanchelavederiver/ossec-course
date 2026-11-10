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
Сквозные правила деки: номер слайда – в правом нижнем углу (тема);
внизу каждого слайда (кроме демо) – блок «Источники: [n]» (<Refs ids="…"/>,
номера по sources.json, клик ведёт на слайд routeAlias: refs и подсвечивает
источник); упоминания man-страниц – ссылки (<Man p="name(sec)"/>).
Демонстрационная среда – Ubuntu Server 26.04 LTS, Linux-PAM 1.7.0;
захваты сняты в одноразовых контейнерах (assets/captures/README.md); раздел 3
дополнительно показывает Rocky Linux 10, Arch Linux и Astra Linux SE 1.8.
Фрагменты исходного кода – <CodeSnippet> по дословным выдержкам из
assets/snippets (Linux-PAM v1.7.0 и программы демо; см. assets/snippets/README.md);
указатель на демо-скрипт – <SrcRef> последней строкой слайда.
-->

---
layout: default
---

# План лекции

<div class="grid grid-cols-2 gap-x-8 mt-4 plan-list">
<div>

1. **Введение** – назначение PAM
2. **Устройство PAM** – библиотека и модули, конфигурация, типы правил и стек, флаги, примеры исполнения, `include` и `substack`
3. **Типичные конфигурации PAM** – Debian/Ubuntu (`common-*`), семейство RHEL (`system-auth`, authselect), Arch Linux
4. **Распространённые модули** – назначение, предоставляемые типы, аргументы
5. **Административные задачи** – `pam_nologin`, `pam_access`, `pam_listfile`, `pam_time`, `pam_limits`

</div>
<div>

6. **Парольная политика** – `pam_pwquality`, `pam_pwhistory`, `pam_faillock`
7. **Двухфакторная аутентификация** – TOTP, аппаратные ключи
8. **PAM в собственных программах** – `libpam` API, программа `authprint`
9. **Разработка модуля PAM** – интерфейс модуля, `pam_math.so`
10. **Реализация Linux-PAM** – структуры, разбор конфигурации, исполнение стека

</div>
</div>

<div class="mt-4 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Сквозной пример: сервер Ubuntu 26.04, пользователи <code>bob</code>, <code>alice</code>,
<code>carol</code>; разделы 5–9 сопровождаются демонстрациями
(<code>assets/demos/01–09</code>).
</div>

<style>
.plan-list li { margin: 0.45em 0; }
</style>

<!--
Десять разделов. Сначала мотивация: какие задачи не решаются классическими
механизмами лекции 2. Затем устройство PAM, типичные конфигурации четырёх
семейств дистрибутивов и словарь распространённых модулей. Разделы 5–7 –
администрирование: типовые задачи, парольная политика, второй фактор.
Разделы 8–9 – программирование: использование libpam в своих программах
и разработка собственного модуля. Раздел 10 – чтение исходного кода Linux-PAM.
-->

---
layout: section
---

# 1. Введение
## Назначение PAM

---

# Недостатки классических механизмов

<div>

Классический механизм аутентификации, разобранный в лекции 2, сводится к 
чтению базы учётных записей, вычислению хеша введённой строки и сравнению с хранимым хешем пароля.
База учётных записей хранится локально и реализована файлами `/etc/passwd`, `/etc/shadow`.

</div>

<div class="grid grid-cols-3 gap-3 text-xs">
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Проверка зашита в код</b><br/><br/>
подключение нового способа аутентификации – например, одноразового кода или ключа FIDO2 – требует
<b>изменения и перекомпиляции</b> каждой программы
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Источник данных фиксирован</b><br/><br/>
аутентифицирующая информация хранится только локально (файл <code>/etc/shadow</code>): проверить пароль 
учётной записи из сетевого каталога (LDAP, Active Directory) эта схема не может
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Политика не централизована</b><br/><br/>
правила сложности пароля, блокировки, времени входа и т.п. пришлось бы
дублировать в каждой программе
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Напоминание (лекция 2, раздел 6, слайды 101–102).</b> Для задач <b>идентификации</b> 
эти проблемы уже решены: NSS выбирает источник сведений об учётных записях
конфигурацией <code>nsswitch.conf</code>, а интерфейс <Man p="getpwnam(3)" /> и код программ
не меняются. Для <b>аутентификации</b> необходим такой же механизм.
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Решение</b> – промежуточный слой:

- **отделить** точку аутентификации (программу) от способов проверки: способы становятся
  **подключаемыми модулями**, которые выбирает администратор, а не разработчик программы;
- **источником аутентифицирующих данных** сделать не только локальные файлы: модуль может
  обращаться к каталогу домена, аппаратному ключу или внешней службе.

</div>

</v-click>

<Refs ids="pam-sag osf-rfc86 man-nsswitch" />

<style>
.slidev-layout ul { margin-top: 0.3em; margin-bottom: 0; }
</style>

<!--
Мост от лекции 2. Классическая схема: каждая программа входа самостоятельно
читает /etc/passwd и /etc/shadow и сверяет хеш. Три следствия. Во-первых,
логика проверки зашита в код: чтобы добавить второй фактор, пришлось бы править
и перекомпилировать login, sshd, su, sudo, passwd – у администратора исходного
кода нет. Во-вторых, источник аутентифицирующих данных фиксирован: предприятию
нужен общий каталог на тысячи машин, а не локальные файлы на каждой. В-третьих,
политику не задать в одном месте. Напомнить слушателям слайды 101–102 лекции 2:
для идентификации ровно эти проблемы – локальность файлов и привязка программ
к ним – решил NSS, подменив источник внутри libc при неизменном интерфейсе.
Для аутентификации нужен аналогичный слой – и он даже старше NSS в Linux:
PAM предложили в 1995 году.
-->

---

# Назначение PAM

<div class="pam-intro">

**PAM** (Pluggable Authentication Modules, подключаемые модули аутентификации) – каркас,
позволяющий PAM-aware приложениям **делегировать** аутентификацию, проверку учётной записи,
смену аутентификатора и управление сеансом независимо настраиваемым **модулям**. Какие модули
и в каком порядке вызываются, выбирает администратор – **без изменения кода и перекомпиляции**
приложений.

</div>

<Timeline height="10.5em" class="mt-1" :items="[
  { year: '1995', head: 'OSF RFC 86.0', text: 'В. Самар и Р. Шемерс (Sun): идея подключаемых модулей аутентификации', hot: true },
  { year: '1996', head: 'Linux-PAM', text: 'реализация для Linux (Э. Морган); первый дистрибутив с PAM – Red Hat Linux 3.0.4' },
  { year: '1997', head: 'XSSO · Solaris 2.6', text: 'The Open Group описывает API PAM в спецификации XSSO; PAM входит в Solaris' },
  { year: '2002', head: 'OpenPAM', text: 'независимая реализация для FreeBSD, позднее macOS' },
  { year: '2008', head: 'Linux-PAM 1.0', text: 'стабильный API; далее – pam_faillock (1.4, 2020), vendordir' },
  { year: '2025', head: 'Linux-PAM 1.7.0', text: 'версия в Ubuntu 26.04 (пакет 1.7.0-5ubuntu3.2)' },
]" />

<div class="grid grid-cols-2 gap-3 mt-1 text-xs">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Идея:</b> приложение вызывает функции библиотеки <code>libpam</code> (<Man p="pam_authenticate(3)" />
и др.); библиотека по <b>названию приложения</b> находит её конфигурацию, загружает перечисленные
там модули, вызывает их по порядку и <b>сводит коды возврата</b> по правилам конфигурации
в единый ответ приложению.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>PAM – не метод аутентификации:</b> сами проверки реализуют модули – <code>pam_unix</code>
(пароли из <code>/etc/shadow</code>, лекция 2), <code>pam_sss</code> (учётные записи каталога),
модули второго фактора (2FA). Одна служба может использовать локальные пароли, другая – каталог,
и одновременно обе – общие правила account и session.
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Обратите внимание:</b> PAM не входит в POSIX. Интерфейс приложений описан в спецификации
X/Open XSSO (1997); реализации – Linux-PAM (Linux), OpenPAM (FreeBSD, macOS), PAM в Solaris –
совместимы по API, но различаются синтаксисом конфигурации и набором модулей. В примерах лекции 
используется Linux-PAM 1.7.0 в Ubuntu Server 26.04.
</div>

<Refs ids="osf-rfc86 pam-sag man-pam xsso openpam linux-pam-src" />

<style>
.pam-intro p { margin: 0.5rem 0; }
</style>

<!--
Определение расширено по сравнению с SAG: PAM – это делегирование четырёх задач
(аутентификация, проверка учётной записи, смена аутентификатора, сеанс)
независимо настраиваемым модулям. Хронология: 1995 – OSF RFC 86.0, Самар и
Шемерс из Sun описывают «unified login» через подключаемые модули; 1996 –
Эндрю Морган начинает Linux-PAM, Red Hat Linux 3.0.4 первым из дистрибутивов
включает его; 1997 – The Open Group публикует предварительную спецификацию
XSSO с API PAM, PAM появляется в Solaris 2.6; 2002 – Даг-Эрлинг Смёргров
пишет OpenPAM для FreeBSD (позднее используется в macOS); 2008 – Linux-PAM
1.0 со стабильным API; 2025 – 1.7.0, версия Ubuntu 26.04. Две карточки –
суть: libpam выбирает конфигурацию по имени службы и сводит результаты
модулей; сам PAM ничего не проверяет – проверяют модули, поэтому разные
службы могут использовать разные источники и при этом разделять общие
правила account и session. Оговорка о стандартах параллельна слайду о NSS в
лекции 2: PAM – не POSIX, а соглашение X/Open; реализации совместимы по API,
но не по конфигурации.
-->

---

# Архитектура PAM: приложение, libpam, модули

<div class="pam-arch mt-4">
  <div class="pa-row">
    <div class="bf-block bf-fill-tint pa-wide">
      <div class="bf-head">PAM-aware приложения</div>
      <div class="bf-sub"><code>login</code> · <code>sshd</code> · <code>sudo</code> · <code>su</code> · <code>passwd</code> · <code>ваша программа</code><br/>вызовы <code>pam_start(3)</code>, <code>pam_authenticate(3)</code>, <code>pam_acct_mgmt(3)</code>, …</div>
    </div>
  </div>
  <div class="pa-link">
    <div class="pa-label pa-left">вызов функции API libpam</div>
    <div class="pa-arrows"><div class="pa-arrow"></div><div class="pa-arrow pa-up"></div></div>
    <div class="pa-label">код возврата → приложение <b>само решает</b>, что делать дальше</div>
  </div>
  <div class="pa-row">
    <div class="bf-block bf-fill-dark pa-wide">
      <div class="bf-head">libpam.so</div>
      <div class="bf-sub">по имени службы выбирает конфигурацию /etc/pam.d/&lt;служба&gt;, загружает модули и исполняет стеки</div>
    </div>
  </div>
  <div class="pa-link">
    <div></div>
    <div class="pa-arrows"><div class="pa-arrow"></div></div>
    <div class="pa-label">вызов функции модуля <code>pam_sm_&lt;операция&gt;()</code></div>
  </div>
  <div class="pa-row pa-mods">
    <div class="bf-block bf-fill-accent"><div class="bf-head bf-mono">auth</div><div class="bf-sub"><code>pam_unix</code> · <code>pam_sss</code> · <code>pam_google_authenticator</code></div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">account</div><div class="bf-sub"><code>pam_access</code> · <code>pam_time</code> · <code>pam_nologin</code></div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">password</div><div class="bf-sub"><code>pam_pwquality</code> · <code>pam_pwhistory</code> · <code>pam_unix</code></div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">session</div><div class="bf-sub"><code>pam_limits</code> · <code>pam_env</code> · <code>pam_systemd</code></div></div>
  </div>
</div>

<div class="grid grid-cols-[1.25fr_1fr] gap-3 mt-4 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Критическая граница:</b> PAM делает только то, о чём просит приложение. Программа,
не вызывающая <Man p="pam_authenticate(3)" />, не исполнит стек auth, сколько бы правил
auth ни содержалось в файле службы. Так, OpenSSH при входе по открытому ключу проверяет ключ
<b>самостоятельно</b>, а к PAM обращается за стеками account и session (раздел 3.2).
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Подсистема работает <b>в пользовательском пространстве</b>: libpam – код внутри процесса
приложения, модули – разделяемые библиотеки; ядро в выборе проверок не участвует (как и в NSS).
Привилегии модуля = привилегии процесса: <code>pam_unix</code> имеет право на чтение <code>/etc/shadow</code>,
потому что <code>login</code> работает с euid 0.
</div>
</div>

<Refs ids="pam-sag man-pam man-pam3 pam-adg" />

<style>
.pam-arch { display: flex; flex-direction: column; font-size: 0.78rem; text-align: center; }
.pam-arch .pa-row { display: flex; gap: 0.6em; justify-content: center; }
.pam-arch .pa-wide { flex: 0 1 36em; }
.pam-arch .pa-mods .bf-block { flex: 1 1 0; justify-content: flex-start; }
/* Three columns: label | arrows | label – the arrows sit on the axis of the blocks. */
.pam-arch .pa-link { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; column-gap: 0.7em; height: 2.5em; }
.pam-arch .pa-arrows { display: flex; gap: 0.5em; justify-content: center; }
/* Shorter than the row, so the heads stay clear of the blocks above and below. */
.pam-arch .pa-arrow { width: 2px; height: 1.5em; background: #555; position: relative; }
.pam-arch .pa-arrow::after { content: ''; position: absolute; bottom: -4px; left: -3px; border: 4px solid transparent; border-top-color: #555; }
.pam-arch .pa-arrow.pa-up::after { bottom: auto; top: -4px; border-top-color: transparent; border-bottom-color: #555; }
.pam-arch .pa-label { font-size: 0.68rem; color: #555; font-style: italic; text-align: left; }
.pam-arch .pa-label.pa-left { text-align: right; }
</style>

<!--
Архитектура в один кадр, по образцу слайда о NSS из лекции 2. Верхний уровень –
PAM-aware приложения: они вызывают функции API libpam – pam_start, затем
pam_authenticate, pam_acct_mgmt и т. д. (раздел 8). Средний уровень – libpam:
по имени службы выбирает файл конфигурации, подгружает перечисленные модули и
исполняет стеки. Нижний уровень – модули четырёх групп управления; один модуль
(pam_unix) может участвовать в нескольких. Стрелка вверх – код возврата: libpam
не впускает пользователя сама, она лишь сообщает приложению итог, а решение
принимает приложение. Отсюда критическая граница (амбер): PAM исполняет только
те стеки, о которых приложение попросило. Нет вызова pam_authenticate – нет
стека auth; OpenSSH при входе по ключу проверяет ключ своими средствами и
зовёт PAM только для account и session – важно для второго фактора (раздел 7).
Второе замечание повторяет вывод лекции 2 о NSS: всё это пользовательское
пространство внутри процесса, и модуль имеет ровно те привилегии, что и
процесс, – поэтому pam_unix может читать /etc/shadow из login с euid 0, а из
непривилегированной программы вынужден вызывать помощника unix_chkpwd.
-->

---

# Типичные задачи PAM

<div>

Классические механизмы выполняют парольную аутентификацию, всё остальное – задачи модульного слоя:

</div>

<div class="t-table text-xs mt-2">

| Задача администратора | Классические механизмы | PAM |
|---|---|---|
| Единая политика сложности и истории паролей | логику пришлось бы дублировать в программах | <DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" />, <Man p="pam_pwhistory(8)" /> – **раздел 6** |
| Блокировка учётной записи после N неудач | – | <Man p="pam_faillock(8)" /> – **раздел 6** |
| Второй фактор: одноразовый код, аппаратный ключ | – | `pam_google_authenticator`, <DebianMan p="pam_u2f(8)" pkg="libpam-u2f" /> – **раздел 7** |
| Учётные записи из каталога домена (AD, FreeIPA) | NSS + служба sssd | <Man p="pam_sss(8)" href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam_sss.8.html" /> + служба sssd |
| Запрет входа: всем, по списку, по времени | частично («запрещающие» оболочки) | <Man p="pam_nologin(8)" />, <Man p="pam_access(8)" />, <Man p="pam_listfile(8)" />, <Man p="pam_time(8)" /> – **раздел 5** |
| Лимиты ресурсов сеанса пользователя | – | <Man p="pam_limits(8)" /> – **раздел 5** |
| Собственная проверка в своей программе | `libc` API | `libpam` API – **раздел 8** |
| Разработка собственного метода проверки пароля | писать с нуля | `libpam` API – **раздел 9** |

</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10">
Через PAM проходит <b>почти каждый вход в систему</b>: консоль, ssh, графический
сеанс, <code>su</code>/<code>sudo</code>, смена пароля. Ошибка в его конфигурации
равносильна отказу в обслуживании – или открытой двери в ОС.
</div>

</v-click>

<Refs ids="pam-sag man-pam" />

<!--
Мотивационная таблица: колонка «классические механизмы» почти пуста – эти
задачи либо не решаются файлами passwd/shadow вообще, либо требуют дублирования
логики в каждой программе. Каждая строка правой колонки – конкретный модуль, и
почти каждый мы увидим в работе: разделы 5–7 – административные демонстрации,
разделы 8–9 – программирование. Предупреждение внизу задаёт тон лекции: PAM –
критическая точка системы, через неё проходит каждый вход.
-->

---

# Пример использования: вход с консоли и SSH

<div class="login-lanes mt-2">
  <div class="ll-lane">
    <div class="bf-block bf-fill-dark ll-label"><div class="bf-head">Консоль</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">agetty</div><div class="bf-sub">открывает терминал, спрашивает имя</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">login</div><div class="bf-sub">запрашивает пароль<br/>(эхо отключено)</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-amber"><div class="bf-head">PAM</div><div class="bf-sub">auth + account: пароль и учётная запись; session: окружение, лимиты</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">UID/GID</div><div class="bf-sub">из записи passwd – локальной или из каталога домена (NSS)</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">оболочка</div><div class="bf-sub">/bin/bash из 7-го поля passwd</div></div>
  </div>
  <div class="ll-lane mt-2">
    <div class="bf-block bf-fill-dark ll-label"><div class="bf-head">SSH</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">sshd</div><div class="bf-sub">ключ хоста: сервер доказывает клиенту свою подлинность</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">sshd-session</div><div class="bf-sub">ключ или пароль клиента</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-amber"><div class="bf-head">PAM</div><div class="bf-sub">auth – только при вводе пароля; account и session – всегда</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">права</div><div class="bf-sub">переход на UID/GID пользователя</div></div>
    <div class="ll-arrow"></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head">оболочка</div><div class="bf-sub">или команда пользователя</div></div>
  </div>
</div>

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/13-login-paths.txt" section="1" title="Ubuntu Server 26.04 · настройки sshd по умолчанию" fontSize="0.5rem" class="!mt-0">
  <TCallout :line="4" :col="1" :span="10" :n="1" />
  <TCallout :line="5" :col="1" :span="33" :n="2" />
  <TCallout :line="8" :col="1" :span="31" :n="3" />
</TerminalCapture>

</div>
<div class="text-xs space-y-1.5">
<div><span class="co-ball">1</span> <code>UsePAM yes</code> – Ubuntu включает PAM в sshd<br/>(в сборке OpenSSH «из коробки» PAM выключен)</div>
<div><span class="co-ball">2</span> root – только по ключу: пароль root по сети не принимается</div>
<div><span class="co-ball">3</span> диалог модулей с пользователем идёт через <code>KbdInteractiveAuthentication</code> – по умолчанию выключен; для второго фактора его придётся включить (раздел 7)</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
В OpenSSH 10 сеанс обслуживает отдельный процесс <code>sshd-session</code> – именно его
название встречается в журналах аутентификации.
</div>

<Refs ids="man-login man-agetty man-sshd man-sshd-config man-pam" />

<style>
.login-lanes { font-size: 0.72rem; text-align: center; padding: 0.6em 0.7em; border: 1.5px dashed var(--ossec-line); border-radius: 8px; }
.login-lanes .ll-lane { display: flex; align-items: stretch; gap: 0; }
/* Heads on one line across the lane: content starts at the top of equal-height blocks. */
.login-lanes .ll-lane .bf-block { flex: 1 1 0; display: flex; flex-direction: column; justify-content: flex-start; padding: 0.3em 0.45em; }
.login-lanes .ll-label { flex: 0 0 5.5em; margin-right: 0.6em; justify-content: center; }
.login-lanes .ll-arrow { flex: 0 0 1.4em; align-self: center; height: 2px; background: #7c8aa0; position: relative; margin: 0 0.2em; }
.login-lanes .ll-arrow::after { content: ''; position: absolute; right: -2px; top: -4px; border: 5px solid transparent; border-left-color: #7c8aa0; }
</style>

<!--
Пример типового использования PAM – два пути входа. Консоль: agetty открывает
терминал и спрашивает имя, запускает login; login через PAM проверяет пароль и
учётную запись (стеки auth и account), открывает сеанс (session), затем
устанавливает UID и GID – по записи passwd, которая благодаря NSS может прийти
и из каталога домена, – и запускает оболочку из седьмого поля. SSH: сначала
сервер доказывает клиенту подлинность ключом хоста, затем клиент
аутентифицируется ключом или паролем; при вводе пароля sshd обращается к стеку
auth, а account и session проходятся при любом методе – ровно та критическая
граница с предыдущего слайда. Терминал: sshd -T печатает действующую
конфигурацию. UsePAM yes – выбор Debian/Ubuntu, а не upstream-умолчание
OpenSSH; root по сети – только по ключу; KbdInteractiveAuthentication по
умолчанию выключен, и это ограничивает диалог модулей с пользователем – к этому
вернёмся при подключении второго фактора. В OpenSSH 10 за сеанс отвечает
отдельный процесс sshd-session, который и виден в журналах.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="1" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# PAM-aware программы и библиотека libpam

<div>

PAM представляет собой библиотеку `libpam.so` и систему модулей – динамически
подгружаемых библиотек `pam_*.so`. <br/>
**PAM-aware** – программа, скомпонованная с `libpam.so` и делегирующая ей
процедуру аутентификации. Проверить, использует ли приложение PAM, можно с помощью `ldd`:

</div>

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="1" title="Ubuntu Server 26.04 · ldd и пакет libpam" fontSize="0.5rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="11" :n="1" />
  <TCallout :line="3" :col="9" :span="16" :n="2" />
  <TCallout :line="11" :col="20" :span="16" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>libpam.so.0</code> – ядро PAM: разбор конфигурации и исполнение стека модулей</div>
<div><span class="co-ball">2</span> <code>libpam_misc.so.0</code> – вспомогательная библиотека: готовая функция диалога <Man p="misc_conv(3)" /> (раздел 8)</div>
<div><span class="co-ball">3</span> версия: Linux-PAM <b>1.7.0</b> (пакет <code>libpam0g</code>)</div>
</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<code>libpam</code> загружает модули с помощью <Man p="dlopen(3)" /> при первом обращении
службы; сами способы проверки реализованы <b>в модулях</b>, поэтому внедрение поддержки
нового способа аутентификации требует создания новой разделяемой библиотеки <code>pam_*.so</code> 
и добавления строки конфигурации, а не пересборки программ.
</div>

<Refs ids="man-pam pam-sag linux-pam-src" />

<!--
Две составляющие PAM: библиотека libpam и модули – разделяемые объекты pam_*.so.
Термин PAM-aware: программа доверяет аутентификацию libpam. ldd показывает две
библиотеки: libpam – ядро (разбор конфигурации, исполнение стека), libpam_misc –
небольшая добавка для консольных приложений с готовой функцией диалога.
Версию см. по пакету: 1.7.0 в Ubuntu 26.04. Модули подгружаются динамически
через dlopen при первом обращении службы; поэтому новый способ аутентификации –
это новый файл на диске плюс строка конфигурации, а не пересборка программ.
-->

---

# Каталог модулей

<div class="grid grid-cols-[1fr_1.4fr] gap-4 items-start">
<div>

<div class="mb-2">Путь к каталогу модулей зависит от дистрибутива:</div>

<div class="t-table text-xs">

| Семейство | Каталог модулей |
|---|---|
| Debian, Ubuntu | `/usr/lib/<triplet>/security`, напр. `/usr/lib/x86_64-linux-gnu/security` |
| RHEL, Fedora, РЕД ОС | `/usr/lib64/security` |
| умолчания Linux-PAM | `/lib/security`, `/lib64/security` |

</div>

</div>
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="2" title="Ubuntu Server 26.04 · модули PAM" fontSize="0.5rem" class="!mt-0" />

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<Man p="pam.conf(5)" />: относительный путь модуля в правиле отсчитывается
от каталога модулей; на практике в правилах пишут только
имя файла – <code>pam_unix.so</code>, а полный путь нужен лишь модулю вне этого каталога.
</div>

<div class="mt-2">

В Ubuntu Server 26.04 предустановлены **45 модулей** – с ними работает большая часть примеров лекции.
Пакеты добавляют свои модули (`pam_pwquality.so`, `pam_google_authenticator.so` – разделы 6–7).

</div>

<Refs ids="man-pam-conf linux-pam-src redos-pam rhel-pam" />

<!--
Каталог модулей. В Debian/Ubuntu – мультиархитектурный путь с triplet,
в семействе Red Hat (и в РЕД ОС) – /usr/lib64/security, upstream-умолчание –
/lib/security. Поэтому инструкции «положите модуль в /lib/security» из старых
руководств на современных системах не работают – путь нужно проверять.
45 модулей уже в базовой поставке Ubuntu Server 26.04; в правилах пишется
только имя .so, полный путь нужен лишь для модулей вне каталога по умолчанию.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="2" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# Расположение файлов конфигурации PAM

<div class="grid grid-cols-[1fr_1.25fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/01-pam-locations.txt" section="3" title="Ubuntu Server 26.04 · конфигурация PAM" fontSize="0.5rem" class="!mt-0">
  <TCallout :line="1" :col="6" :span="11" :n="1" />
  <TCallout :line="12" :col="41" :span="13" :n="2" />
  <TCallout :line="13" :col="6" :span="15" :n="3" />
  <TCallout :line="15" :col="6" :span="14" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="t-table text-xs">

| Расположение | Назначение |
|---|---|
| <span class="co-ball">1</span> `/etc/pam.d/` | основной каталог: политики служб под управлением администратора, **по файлу на службу** |
| <span class="co-ball">2</span> `/etc/pam.conf` | старый единый файл конфигурации |
| <span class="co-ball">3</span> `/usr/lib/pam.d/` | политики пакетов (`polkit-1`, `systemd-user`); просматривается **всегда** (Linux-PAM ≥ 1.2) |
| `<vendordir>/pam.d/` | дополнительный каталог поставщика – только в сборках с опцией `vendordir` |
| <span class="co-ball">4</span> `/etc/security/` | файлы параметров отдельных модулей |
| `/usr/lib/<triplet>/security/`, `/usr/lib64/security/` | модули `pam_*.so` (см. слайд 11) |

</div>

</div>
</div>

<div class="tight mt-1 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Linux-PAM поддерживает две формы конфигурации – единый файл и каталог с файлом на службу;
каталожная форма используется во всех современных дистрибутивах. Детали зависят от сборки: в Ubuntu 26.04,
RHEL 10 и Arch <code>libpam</code> собран без <code>vendordir</code>. Каталог <code>/usr/share/pam/</code> в Ubuntu –
место хранения шаблонов <code>pam-auth-update</code> для файлов <code>common-*</code> (раздел 3.1).
</div>

<div class="tight mt-1 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Назначение <code>vendordir</code>:</b> умолчания дистрибутива лежат в <code>/usr</code> и обновляются
с пакетами, в <code>/etc</code> остаются только правки администратора – основа систем с неизменяемым корнем
и «сброса настроек» очисткой <code>/etc</code>. Опция сборки <code>vendordir=&lt;dir&gt;</code> образует <b>два</b>
каталога: <code>&lt;dir&gt;/pam.d/</code> – третье место поиска политик, <code>&lt;dir&gt;/security/</code> – запасные
файлы параметров модулей.<br/>
Например, openSUSE собирает <code>libpam</code> с <code>vendordir=/usr/etc</code>: <Man p="pam_limits(8)" /> читает
<code>/etc/security/limits.conf</code>, а при его отсутствии – <code>/usr/etc/security/limits.conf</code>; каталог политик
<code>/usr/etc/pam.d/</code> (2019–2024) упразднён в пользу <code>/usr/lib/pam.d/</code>.
</div>

<Refs ids="man-pam-conf pam-sag linux-pam-src man-pam-limits opensuse-pam opensuse-pam-changes" />

<style>
.t-table { font-size: 0.68rem !important; }
.t-table td, .t-table th { padding-top: 0.2em !important; padding-bottom: 0.2em !important; }
.tight { line-height: 1.35; }
</style>

<!--
Где искать конфигурацию. Слева – реальное состояние Ubuntu 26.04, справа –
таблица расположений. Основной каталог /etc/pam.d: по файлу на службу, имя
файла – имя службы. /etc/pam.conf – исторический единый файл; он есть на диске,
но при наличии каталога pam.d игнорируется. /usr/lib/pam.d – каталог политик
поставщика: пакеты кладут туда файлы по умолчанию, оставляя /etc/pam.d
администратору; libpam просматривает его всегда (константа PAM_CONFIG_DIST_D,
с версии 1.2). В Ubuntu 26.04 там два файла – polkit-1 из polkitd и
systemd-user из systemd; в минимальном контейнере без этих пакетов каталога
нет. Сборочная опция vendordir добавляет ещё один каталог поставщика
(PAM_CONFIG_DIST2_D = vendordir/pam.d) и запасной каталог параметров
модулей vendordir/security; Ubuntu, RHEL и Arch собирают libpam без неё –
проверяется командой strings по libpam.so.0. Каталог /usr/share/pam в Ubuntu
– шаблоны pam-auth-update, libpam его не читает. openSUSE: vendordir=/usr/etc
с 2019 г.; политики поставщика перенесены в /usr/lib/pam.d в 2022 г., каталог
/usr/etc/pam.d удалён в 2024 г., а /usr/etc/security для pam_limits и других
модулей остался. /etc/security – не правила PAM, а файлы параметров
конкретных модулей. Порядок, в котором libpam перебирает эти места, –
следующий слайд.
-->

---

# Приоритет файлов конфигурации

<div class="grid grid-cols-[1fr_1.15fr] gap-5 items-start">
<div>

<div class="prec-chain">
  <div class="bf-block bf-fill-accent"><div class="bf-head bf-mono">/etc/pam.d/&lt;служба&gt;</div><div class="bf-sub">файл администратора</div></div>
  <div class="pc-link"><div></div><div class="pc-arrow"></div><div class="pc-label">файла нет</div></div>
  <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">/usr/lib/pam.d/&lt;служба&gt;</div><div class="bf-sub">файл поставщика</div></div>
  <div class="pc-link"><div></div><div class="pc-arrow"></div><div class="pc-label">файла нет и сборка с vendordir</div></div>
  <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">&lt;vendordir&gt;/pam.d/&lt;служба&gt;</div><div class="bf-sub">второй каталог поставщика</div></div>
  <div class="pc-link"><div></div><div class="pc-arrow"></div><div class="pc-label">файла нет – или в нём нет правил нужного типа</div></div>
  <div class="bf-block bf-fill-amber"><div class="bf-head bf-mono">…/other</div><div class="bf-sub">конфигурация по умолчанию (ищется тем же порядком)</div></div>
</div>

</div>
<div class="prec-text">

Правила поиска (<Man p="pam.d(5)" href="https://man7.org/linux/man-pages/man5/pam.d.5.html" />, `_pam_init_handlers` в `pam_handlers.c`):

1. при наличии хотя бы одного каталога `pam.d` файл `/etc/pam.conf` **не читается** (опция `read-both-confs` выключена по умолчанию);
2. файл службы ищется по **названию** в `/etc/pam.d/`, `/usr/lib/pam.d/`, `<vendordir>/pam.d/` – берётся **первый найденный**, файл администратора приоритетнее **одноимённого** файла поставщика;
3. затем тем же порядком читается файл `other`: его правила действуют для каждого **типа**, для которого в файле службы правил нет, – и когда файла службы нет вовсе;
4. вместо названия приложение может передать **абсолютный путь** к файлу политики.

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Альтернативы, а не слои:</b> файлы разных каталогов не объединяются – локальный файл
<b>замещает</b> одноимённый файл поставщика целиком, а не дополняет или переопределяет 
заданные в нём значения.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Приложение может указать <code>libpam</code> иной каталог конфигурации – с помощью вызова
<code>pam_start_confdir</code> (<Man p="pam_start(3)" />); этот механизм применяют для тестирования 
политики, не затрагивая <code>/etc/pam.d</code>.
</div>

<Refs ids="man-pam-conf man-pam-start linux-pam-src" />

<style>
.prec-chain { display: flex; flex-direction: column; font-size: 0.76rem; text-align: center; }
/* Three columns: (empty) | arrow | label – the arrow sits on the axis of the blocks. */
.prec-chain .pc-link { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; column-gap: 0.6em; height: 2.1em; }
.prec-chain .pc-arrow { width: 2px; height: 1.4em; background: #555; position: relative; }
.prec-chain .pc-arrow::after { content: ''; position: absolute; bottom: -4px; left: -3px; border: 4px solid transparent; border-top-color: #555; }
.prec-chain .pc-label { font-size: 0.66rem; color: #555; font-style: italic; text-align: left; }
.prec-text > p:first-child { margin-top: 0; }
.prec-text ol { font-size: 0.78rem; }
.prec-text li { margin: 0.1em 0; line-height: 1.35; }
.slidev-layout ol { margin-top: 0.3em; }
</style>

<!--
Порядок поиска – по коду _pam_init_handlers (Linux-PAM 1.7.0). Каталожный
режим включается, если существует хотя бы один из каталогов /etc/pam.d,
/usr/lib/pam.d или vendordir/pam.d; тогда /etc/pam.conf не читается вовсе
(опция сборки read-both-confs по умолчанию выключена). Файл службы ищется по
массиву pamd_dirs: /etc/pam.d/<служба>, /usr/lib/pam.d/<служба>,
vendordir/pam.d/<служба> – побеждает первый открывшийся. Затем тем же
порядком всегда читается файл other, и его правила попадают во второй набор
стеков; при диспетчеризации libpam берёт стек other для того типа, для
которого в файле службы нет ни одного правила, – поэтому other работает не
только для служб без файла, но и для «неполных» файлов. Имя, начинающееся с
«/», трактуется как путь к файлу политики. Главное предостережение: это
альтернативы, а не слои – libpam берёт первый найденный файл целиком и не
объединяет его с остальными; скопировав файл поставщика в /etc/pam.d и
отредактировав одну строку, администратор берёт на себя весь файл, включая
будущие обновления поставщика. pam_start_confdir позволяет приложению читать
политику из произвольного каталога – удобный способ тестировать конфигурацию.
В исходном коде всё это – массив pamd_dirs (раздел 10).
-->

---

# Каталог /etc/pam.d: одноимённые файлы служб

<div>

По соглашению название конфигурационного файла должно совпадать с названием **службы**; 
в каждом файле заданы правила только для этой службы.

</div>

<div class="grid grid-cols-[1fr_1.3fr] gap-4 items-start">
<div>

<div class="t-table text-xs">

| Файл службы | Назначение |
|---|---|
| `login` | вход с локального терминала |
| `sshd` | сервер OpenSSH |
| `sudo`, `su` | повышение привилегий, смена пользователя |
| `passwd` | смена пароля |
| `cron` | служба исполнения задач по расписанию |
| `other` | запасная политика: для служб без своего файла и для типов, не заданных в файле службы |
| `common-*` | общие файлы Debian/Ubuntu (раздел 3.1) |

</div>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Важно:</b> название службы задаёт <b>приложение</b> при вызове <Man p="pam_start(3)" />,
оно не обязано совпадать с именем исполняемого файла.<br/>
Например, имена исполняемых файлов классических служб FTP и Telnet – <code>/usr/sbin/in.ftpd</code>
и <code>/usr/sbin/in.telnetd</code>, в то время как политика задана в файлах
<code>/etc/pam.d/ftp</code> и <code>/etc/pam.d/telnet</code>.<br/>
Также в большинстве современных дистрибутивов используется PAM-aware сборка <code>sudo</code>, <b>изменяющая название службы</b>
в случае запуска интерактивного режима <code>sudo -i</code>.
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Имена файлов служб задаются в <b>нижнем регистре</b>. Набор файлов в конкретной ОС зависит от установленных
пакетов и служб.
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Общие файлы и запасной файл политики являются воплощением принципа <b>разделения ответственности</b>:
файл службы описывает <b>особенности службы</b>, общие файлы –
<b>политику аутентификации</b> системы (раздел 3).
</div>

</div>
</div>

<Refs ids="man-pam-conf man-pam-start pam-sag" />

<!--
Каталог pam.d – по файлу на службу. Таблица типичных файлов: login, sshd,
sudo и su, passwd, cron, other, плюс общие файлы Debian/Ubuntu common-*.
Ключевой факт, который часто упускают: имя службы – параметр pam_start, его
выбирает приложение; OpenSSH называет себя sshd, а не ssh. Поэтому при разборе
проблемы первым делом нужно узнать, под каким именем приложение обращается к
PAM, – в разделе 8 мы увидим это на собственной программе. Имена файлов – в
нижнем регистре. Набор файлов зависит от установленных пакетов: пакет приносит
свой файл службы при установке.
-->

---

# Имя службы выбирает приложение: sudo

<div>

`sudo` обращается к PAM под именем `sudo`, но для **оболочки входа** (`sudo -i`) может назвать себя
иначе – `sudo-i` – и получить отдельную политику:

</div>

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/sudo-pam-service.c" lang="c" title="plugins/sudoers/auth/pam.c" tag="sudo 1.9.17p2" fontSize="0.5rem" class="!mt-0">
  <TCallout :line="9" :col="40" :span="16" :n="1" />
  <TCallout :line="10" :col="13" :span="39" :n="2" />
  <TCallout :line="12" :col="18" :span="21" :n="3" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> условие – режим оболочки входа (ключ <code>-i</code>);</div>
<div><span class="co-ball">2</span> имя берётся из параметров sudoers <code>pam_login_service</code> или <code>pam_service</code>;</div>
<div><span class="co-ball">3</span> выбранное имя передаётся в <Man p="pam_start(3)" /> – дальше решает только оно.</div>
</div>

</div>
<div class="text-xs space-y-2">

<CodeSnippet src="snippets/sudo-rs-pam-service.rs" lang="rust" title="src/sudo/pam.rs" tag="sudo-rs 0.2.13" fontSize="0.5rem" class="!mt-0" />

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Условие подмены.</b> Служба <code>sudo-i</code> выбирается, когда выполнены <b>оба</b> условия: запрошена
оболочка входа (<code>sudo -i</code>) <b>и</b> sudo собран с опцией <code>--with-pam-login</code> – она делает
<code>sudo-i</code> умолчанием параметра <code>pam_login_service</code>. Без опции умолчание – значение
<code>pam_service</code>, то есть <code>sudo</code>. Администратор может переопределить оба имени в sudoers
(<code>Defaults pam_service=…</code>, <code>pam_login_service=…</code>; sudo ≥ 1.8.8).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
В Ubuntu 26.04 оба варианта используют <code>sudo-i</code>: пакет <code>sudo</code> 1.9.17p2 собран с
<code>--with-pam --with-pam-login</code>, а <code>sudo-rs</code> 0.2.13 (команда <code>sudo</code> по умолчанию) –
с возможностью <code>pam-login</code>. Файлы <code>/etc/pam.d/sudo</code> и <code>/etc/pam.d/sudo-i</code>
ставит общий пакет <code>sudo-common</code>.
</div>

</div>
</div>

<Refs ids="man-pam-start sudo-src man-sudoers sudo-rs-src" />

<!--
Пример того, что имя службы – решение приложения. В sudo (plugins/sudoers/
auth/pam.c, sudo_pam_init2) имя выбирается одной условной конструкцией: если
запрошена оболочка входа (MODE_LOGIN_SHELL, ключ -i), берётся
def_pam_login_service, иначе def_pam_service; в 1.9.x есть и третий вариант –
pam_askpass_service для режима -A. Умолчания параметров задаются при сборке:
pam_service = sudo всегда, а pam_login_service = sudo-i только при configure
--with-pam-login, иначе оно совпадает с pam_service. Значит, подмена имени –
не свойство PAM и не свойство sudo вообще, а свойство конкретной сборки и
конфигурации sudoers. Ubuntu 26.04: debian/rules пакета sudo содержит
--with-pam --with-pam-login; команда sudo по умолчанию – sudo-rs 0.2.13 (через
alternatives), собранная с cargo-возможностью pam-login, и в её коде та же
развилка: LaunchType::Login → sudo-i, иначе sudo. Файлы sudo и sudo-i в
/etc/pam.d принадлежат пакету sudo-common, общему для обеих реализаций;
sudo-i добавляет pam_limits и pam_env (чтение /etc/default/locale) и затем
подключает common-* через @include – раздел 2.6.
-->

---

# Служба other: правила по умолчанию

<div>

Имя службы **`other`** зарезервировано: её правила применяются к службе, у которой **нет собственного файла**
ни в одном из каталогов конфигурации, а также к каждому **типу правил**, не заданному в файле службы.

</div>

<div class="grid grid-cols-[1fr_1.2fr] gap-x-4 gap-y-3 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="5" title="Ubuntu Server 26.04 · /etc/pam.d/other" class="!mt-0" />

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
В Ubuntu <code>other</code> подключает общие файлы <code>common-*</code>
(раздел 3.1): неизвестная служба получает <b>обычную парольную
аутентификацию</b>.
</div>
<div>

<CodeSnippet src="snippets/sag-other.conf" lang="text" title="/etc/pam.d/other" tag="пример SAG" :numbers="false" class="!mt-0" />

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Руководство администратора Linux-PAM предупреждает:</b> слабая запись
<code>other</code> – уязвимость всей системы, поскольку она действует на каждое
PAM-aware приложение без своего файла. Консервативный вариант по SAG –
запретить всё (<Man p="pam_deny(8)" /> всегда возвращает отказ) и записать событие в журнал.
</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Выбор Ubuntu – удобство: новая служба «просто работает»; выбор SAG –
принцип «запрещено всё, что не разрешено явно». Всегда проверяйте <b>фактическое</b> содержимое файла.
</div>

<Refs ids="pam-sag man-pam-conf man-pam-rootok" />

<!--
Служба other – правила по умолчанию для программ без собственного файла.
Это и удобство, и риск: SAG прямо называет слабый other уязвимостью. Ubuntu
подключает в other общие файлы common-* – неизвестное приложение получает
обычную парольную аутентификацию; консервативная рекомендация SAG – pam_deny
во всех четырёх стеках плюс pam_warn для журнала. Дистрибутивы поступают
по-разному, поэтому содержимое other всегда нужно проверять, а не предполагать.
-->

---

# Параметры модулей и журналирование

<div class="grid grid-cols-[1.1fr_1fr] gap-4 items-start">
<div>

<div class="text-xs mb-1"><b>Файлы параметров</b> – каталог <code>/etc/security/</code>:</div>

<div class="t-table text-xs">

| Модуль | Файлы параметров | Раздел |
|---|---|---|
| <Man p="pam_access(8)" /> | <Man p="access.conf(5)" />, `access.d/` | 5.2 |
| <Man p="pam_time(8)" /> | <Man p="time.conf(5)" /> | 5.3 |
| <Man p="pam_limits(8)" /> | <Man p="limits.conf(5)" />, `limits.d/` | 5.4 |
| <DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" /> | <DebianMan p="pwquality.conf(5)" pkg="libpwquality-common" />, `pwquality.conf.d/` | 6 |
| <Man p="pam_pwhistory(8)" /> | `pwhistory.conf`, `opasswd` (история хешей) | 6 |
| <Man p="pam_faillock(8)" /> | <Man p="faillock.conf(5)" /> | 6 |
| <Man p="pam_env(8)" /> | `pam_env.conf` и `/etc/environment` | – |

</div>

</div>
<div>

<div class="text-xs mb-1"><b>Журналирование</b> – syslog, facility <code>auth</code>/<code>authpriv</code>:</div>

<CodeSnippet src="snippets/auth-log-listfile.txt" lang="text" title="/var/log/auth.log" tag="демо 08" :numbers="false" class="!mt-0">
  <TCallout :line="2" :col="3" :span="28" :n="1" />
</CodeSnippet>

<div class="mt-1 text-xs space-y-0.5">
<div>- Ubuntu: <code>/var/log/auth.log</code> (rsyslog) и <code>journalctl</code>;</div>
<div>- <span class="co-ball">1</span> формат <code>модуль(служба:тип): сообщение</code> – видно, <b>какой модуль какой службы</b> принял решение;</div>
<div>- неудачные входы, блокировки, ошибки конфигурации ищите именно здесь.</div>
</div>

</div>
</div>

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-3 items-start">
<div>

<CodeSnippet src="snippets/ex-two-layers.txt" lang="text" title="два уровня конфигурации" tag="пример" :numbers="false" class="!mt-0" />

</div>
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Два уровня:</b> правило в <code>/etc/pam.d/</code> отвечает «<i>когда и как вызвать
модуль</i>», файл в <code>/etc/security/</code> – «<i>что модуль делает, когда вызван</i>».
Многие модули принимают те же параметры аргументами в строке правила; аргументы имеют приоритет.
</div>
</div>

<Refs ids="man-pam-conf pam-sag man-pam-faillock" />

<style>
.t-table { font-size: 0.7rem !important; }
.t-table td, .t-table th { padding-top: 0.15em !important; padding-bottom: 0.15em !important; }
</style>

<!--
Разделение ответственности: правило в pam.d говорит, какой модуль вызвать и как
учесть результат; собственный файл модуля в /etc/security – его параметры.
Таблица расширена каталогами-дополнениями (access.d, limits.d, pwquality.conf.d) –
пакеты и администратор кладут туда отдельные файлы, не редактируя основной.
Пример с faillock показывает оба уровня: строка preauth в стеке auth включает
модуль, а deny/fail_interval/unlock_time в faillock.conf задают его поведение;
те же параметры можно указать аргументами в строке правила, и они имеют
приоритет (увидим на pam_pwquality). Правая колонка – где искать диагностику:
syslog, facility auth/authpriv; в Ubuntu – auth.log и journalctl. Формат
сообщений позволяет понять, какой модуль какой службы отказал, – пример из
нашего же демо раздела 8.
-->

---

# Формат правила: единый файл /etc/pam.conf

<div>

Строка единого файла состоит из **пяти полей**, разделённых пробелами; первое
поле – название службы:

</div>

<FieldRecord class="mt-3" sep="" size="0.95rem" legendSize="0.78rem" :cols="2"
  :fields="[{ t: 'login', hot: true }, 'auth', 'required', 'pam_unix.so', { t: 'nullok' }]"
  :legend="[
    { t: 'service – название службы, к которой относится правило', hot: true },
    'type – тип правила: auth, account, password, session',
    'control – управляющий флаг: как результат модуля влияет на итог проверки',
    'module-path – название модуля или абсолютный путь',
    'module-arguments – аргументы модуля (могут отсутствовать)',
  ]"
/>

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<CodeSnippet src="snippets/ex-pamconf.txt" lang="text" title="/etc/pam.conf" tag="пример" :numbers="false" class="!mt-0" />

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Одна строка на правило; правила разных служб перемешаны в одном файле, и порядок строк
<b>внутри службы и типа</b> задаёт порядок выполнения проверок.
</div>

</div>
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Linux-PAM читает <code>/etc/pam.conf</code>, только если каталог <code>/etc/pam.d/</code> отсутствует
(или в сборке с <code>PAM_READ_BOTH_CONFS</code>). Файл в Ubuntu лежит на диске, но не действует.
</div>

<Refs ids="man-pam-conf pam-sag" />

<style>
/* Slide styles are scoped: reach into the component with :deep(). */
.field-record :deep(.fr-row) { justify-content: center; }
.field-record :deep(.fr-cell + .fr-cell) { margin-left: 0.6em; }
</style>

<!--
Исходная форма конфигурации – единый файл pam.conf с пятипольными строками.
Разбор полей по образцу разбора /etc/passwd в лекции 2: служба, тип,
управляющий флаг, модуль, аргументы. Пример показывает, как выглядят правила
трёх служб в одном файле: при десятках служб и четырёх стеках у каждой файл
становится необозримым – отсюда переход к каталогу. Оговорка: pam.conf
читается только при отсутствии pam.d (или в специальной сборке), так что в
Ubuntu он присутствует как памятник, но не исполняется; увидим это в коде
_pam_init_handlers в разделе 10.
-->

---

# Формат правила: файлы /etc/pam.d/&lt;служба&gt;

<div>

В каталожной форме поле службы **исчезает** – его заменяет имя файла; остаются четыре поля:

</div>

<FieldRecord class="mt-3" sep="" size="0.95rem" legendSize="0.78rem" :cols="2"
  :fields="['auth', { t: '[success=1 default=ignore]', hot: true }, 'pam_unix.so', 'nullok']"
  :legend="[
    'type – тип правила: auth, account, password, session',
    { t: 'control – управляющий флаг: как результат модуля влияет на итог проверки', hot: true },
    'module-path – название модуля или абсолютный путь',
    'module-arguments – аргументы модуля (могут отсутствовать)',
  ]"
/>


<div class="grid grid-cols-[1fr_1.1fr] gap-4 mt-3 items-start">
<div>

<CodeSnippet src="snippets/ex-pamd-files.txt" lang="text" title="то же – три файла в /etc/pam.d/" tag="пример" :numbers="false" fontSize="0.5rem" class="!mt-0" />

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Пример строки – из <code>common-auth</code> Ubuntu: подробная форма флага в квадратных скобках
(раздел 2.4). Правила <b>одного типа</b> в файле образуют <b>стек</b> (раздел 2.3).
</div>

</div>
</div>

<Refs ids="man-pam-conf man-pam-unix pam-sag" />

<style>
/* Slide styles are scoped: reach into the component with :deep(). */
.field-record :deep(.fr-row) { justify-content: center; }
.field-record :deep(.fr-cell + .fr-cell) { margin-left: 0.6em; }
</style>

<!--
Каталожная форма: имя файла заменяет поле службы, остаются четыре поля.
Разбираем настоящую строку из common-auth Ubuntu: тип auth, управляющий флаг в
подробной форме (квадратные скобки – раздел 2.4), модуль pam_unix, аргумент
nullok. Те же три правила предыдущего слайда теперь лежат в трёх файлах.
Предостережение про nullok: аргумент корректен, но разрешает пустые пароли –
на серверах его убирают. Директива @include – способ Debian разделять общие
правила между службами; общий механизм include/substack – раздел 2.6.
-->

---

# Детали синтаксиса строки правила

<CodeSnippet src="snippets/ex-syntax.txt" lang="text" title="/etc/pam.d/<служба>" tag="пример" :numbers="false" fontSize="0.5rem" class="mt-1">
  <TCallout :line="1" :col="1" :span="59" :n="1" />
  <TCallout :line="3" :col="46" :span="1" :n="2" />
  <TCallout :line="5" :col="62" :span="22" :n="3" />
  <TCallout :line="6" :col="1" :span="8" :n="4" />
</CodeSnippet>

<div class="grid grid-cols-2 gap-x-5 gap-y-1.5 mt-3 text-xs">
<div><span class="co-ball">1</span> пустые строки и <b>комментарии</b> от <code>#</code> до конца строки игнорируются; поля разделяются любым числом пробелов и табуляций</div>
<div><span class="co-ball">3</span> аргумент, содержащий пробелы, заключают в <b>квадратные скобки</b> – в данном случае так обозначается группировка аргумента, а не подробная форма флага</div>
<div><span class="co-ball">2</span> правило можно <b>продолжить</b> на следующей строке, поставив <code>\</code> перед концом строки</div>
<div><span class="co-ball">4</span> <b>дефис</b> перед типом подавляет запись в журнал об отсутствии модуля; правило не отключается, флаг остаётся <code>optional</code></div>
</div>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Аргументы передаются модулю как есть:</b> их не интерпретирует оболочка – конвейеры,
подстановки команд и переменных недоступны; смысл каждого аргумента определяет сам модуль
(<code>debug</code>, <code>quiet</code>, <code>nullok</code>, <code>retry=N</code>… – смотрите его man-страницу).
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Названия модулей и аргументы чувствительны к регистру; ключевые слова типа и флага <code>libpam</code>
принимает в любом регистре, но принято писать строчными. Названия файлов служб – строчными.
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Четыре детали синтаксиса на одном примере. Комментарии и пустые строки
игнорируются – поэтому прыжки N считают правила, а не строки (раздел 2.4).
Продолжение строки – обратная косая черта перед переводом строки. Квадратные
скобки в поле аргументов группируют аргумент с пробелами – не путать с
подробной формой управляющего флага: это две разные роли одних скобок.
Дефис перед типом – частый вопрос: он лишь подавляет сообщение в журнал,
если модуль не установлен (типично для pam_systemd в контейнерах без systemd);
правило остаётся правилом, а флаг остаётся optional. Аргументы передаются
модулю как есть – оболочка в разборе не участвует, и универсального языка
аргументов нет: каждый модуль определяет свои; nullok у pam_unix и nullok у
другого модуля могут значить разное или не существовать вовсе.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="3" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# Четыре типа правил (группы управления)

<div>

Задачи, выполняемые модулями, разделены на **четыре независимые группы управления**
(англ. _management groups_); поле `type` правила называет группу, а приложение запускает каждую
группу **своим вызовом API**:

</div>

<div class="t-table text-xs mt-2">

| Тип | Вызов API | Вопрос | Назначение модулей | Примеры модулей |
|---|---|---|---|---|
| **auth** | <Man p="pam_authenticate(3)" /> | «вы – тот, за кого себя выдаёте?» | запрашивают пароль или иное подтверждение подлинности; <Man p="pam_setcred(3)" /> выдаёт и снимает «удостоверения» (credentials) | <Man p="pam_unix(8)" />, <Man p="pam_sss(8)" href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam_sss.8.html" />, <Man p="pam_google_authenticator(8)" href="https://manpages.ubuntu.com/manpages/bionic/man8/pam_google_authenticator.8.html" /> |
| **account** | <Man p="pam_acct_mgmt(3)" /> | «можно ли вам сейчас?» | проверки, не связанные с паролем: срок действия учётной записи, время суток, источник входа, список доступа | <Man p="pam_time(8)" />, <Man p="pam_access(8)" />, <Man p="pam_nologin(8)" /> |
| **password** | <Man p="pam_chauthtok(3)" href="https://man7.org/linux/man-pages/man3/pam_chauthtok.3.html" /> | «как обновить аутентификатор?» | смена пароля; также проверяется соответствие нового пароля политике | <Man p="pam_unix(8)" />, <DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" />, <Man p="pam_pwhistory(8)" pkg="libpam-pwhistory" /> |
| **session** | <Man p="pam_open_session(3)" /> /<br/><Man p="pam_close_session(3)" /> | «что сделать до и после сеанса?» | журналирование входа и выхода, переменные окружения, лимиты ресурсов, регистрация сеанса | <Man p="pam_limits(8)" />, <Man p="pam_env(8)" />, <Man p="pam_systemd(8)" /> |

</div>

<v-click>

<div class="mt-3 grid grid-cols-2 gap-3 text-xs">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Аналогия с проходной (лекция 2):
<ul class="analogy mt-1">
<li><b>auth</b> – «докажите, что пропуск ваш»;</li>
<li><b>account</b> – «а действует ли пропуск сегодня?»;</li>
<li><b>session</b> – записать в журнал и выдать ключ от кабинета;</li>
<li><b>password</b> – замена пропуска.</li>
</ul>
</div>
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Тип – свойство правила, а не модуля:</b> <code>pam_unix</code> реализует все четыре
группы – проверку пароля, контроль срока действия по <code>/etc/shadow</code>, смену пароля
и журналирование сеанса.
</div>
</div>

</v-click>

<Refs ids="man-pam man-pam-conf man-pam-authenticate man-pam-session man-pam-unix" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
.analogy { list-style: square; margin: 0.2em 0 0 1.1em; padding: 0; }
.analogy li { margin: 0.1em 0; }
</style>

<!--
Терминология pam(7): четыре независимые группы управления, и у каждой – свой
вызов API, которым приложение её запускает: pam_authenticate для auth,
pam_acct_mgmt для account, pam_chauthtok для password, pam_open_session и
pam_close_session для session; pam_setcred тоже относится к группе auth и
устанавливает или снимает удостоверения. auth – собственно аутентификация,
диалог с пользователем; account – верификация учётной записи без пароля: не
истёк ли срок, подходит ли время суток, есть ли право доступа к службе;
password – обновление аутентификационных данных; session – настройка окружения
и журналирование. Вернуться к аналогии с проходной из лекции 2. Подчеркнуть:
тип – свойство ПРАВИЛА, а не модуля; pam_unix участвует во всех четырёх стеках.
-->

---

# Пример: группы управления

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-start">
<div>

<CodeSnippet src="snippets/ex-types.txt" lang="text" title="политика одной службы: четыре стека" tag="пример" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="4" :n="1" />
  <TCallout :line="5" :col="1" :span="7" :rows="2" :n="2" />
  <TCallout :line="9" :col="1" :span="8" :rows="2" :n="3" />
  <TCallout :line="13" :col="1" :span="7" :rows="2" :n="4" />
</CodeSnippet>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Поле <code>type</code> разбивает файл службы на четыре стека, и каждый из них приложение
запускает отдельным вызовом. Флаг <code>required</code> здесь единственный – «результат
обязателен»; другие флаги и их семантика – раздел 2.4.
</div>

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<div><span class="co-ball">1</span> <b>auth</b> – установить подлинность: <code>pam_unix</code> запрашивает
пароль и сверяет хеш с <code>/etc/shadow</code>. Только этот стек ведёт диалог «введите пароль».</div>
<div class="mt-1.5"><span class="co-ball">2</span> <b>account</b> – решить, допустим ли вход <i>сейчас</i>: срок действия
учётной записи и пароля (<code>pam_unix</code>), кому и откуда разрешено (<code>pam_access</code>).
Пароль здесь не спрашивается – подлинность уже установлена.</div>
<div class="mt-1.5"><span class="co-ball">3</span> <b>password</b> – обновить аутентификатор: <code>pam_pwquality</code>
оценивает новый пароль, <code>pam_unix</code> записывает его хеш. Стек исполняется только при смене пароля.</div>
<div class="mt-1.5"><span class="co-ball">4</span> <b>session</b> – подготовить сеанс и завершить его: лимиты ресурсов
(<code>pam_limits</code>), запись об открытии и закрытии (<code>pam_unix</code>).</div>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_unix</code> используется во всех четырёх стеках и в каждом выполняют разные операции – тип задаёт
<b>правило</b>, а модуль лишь предоставляет функцию для этого типа.
</div>
</div>
</div>

<Refs ids="man-pam-conf man-pam-unix man-pam-access man-pam-limits pam-sag" />

<!--
Один файл службы, четыре стека – по стеку на группу управления; флаг везде
required, чтобы внимание осталось на типах, а не на потоке управления (флаги –
раздел 2.4). auth: pam_unix ведёт диалог и сверяет хеш – единственный стек,
который спрашивает пароль. account: подлинность уже установлена, решается
допуск здесь и сейчас – срок действия по /etc/shadow и правила access.conf;
напомнить, что при входе по ключу OpenSSH стек auth не вызывается, а account –
да. password: pam_pwquality оценивает новый пароль, pam_unix записывает хеш;
стек работает только при смене пароля. session: лимиты на входе, запись
opened/closed при открытии и закрытии – одна строка на обе фазы. Итог – мысль
предыдущего слайда на живом примере: pam_unix присутствует во всех четырёх
стеках и в каждом выполняет другую функцию, потому что тип – свойство правила.
-->

---

# Стек модулей – последовательность правил одного типа

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

**Стек** (англ. _stack_) – упорядоченный набор правил **одной службы и одного типа**.

Вызов <Man p="pam_authenticate(3)" /> в программе приводит к исполнению всех правил типа **auth**,
указанных в конфигурационном файле данной службы (включая все правила, добавленные с помощью `include`).
Правила исполняются в порядке объявления, **сверху вниз**.
Результатом исполнения функции <Man p="pam_authenticate(3)" /> является **единый** статус – объединение
результатов индивидуальных проверок правил стека.

Аналогично, вызовы <Man p="pam_acct_mgmt(3)" />, <Man p="pam_chauthtok(3)" href="https://man7.org/linux/man-pages/man3/pam_chauthtok.3.html" /> 
и <Man p="pam_open_session(3)" /> / <Man p="pam_close_session(3)" /> приводят к исполнению правил
стека **account**, **password** и **session**, соответственно.

</div>
<div class="text-xs space-y-2">

<CodeSnippet src="snippets/ex-stack.txt" lang="text" title="стек auth" tag="пример" :numbers="false">
  <TCallout :line="1" :col="1" :span="4" :rows="4" :n="1" />
  <TCallout :line="1" :col="7" :span="10" :rows="4" :n="2" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> один тип – один стек; четыре правила исполняются по порядку</div>
<div><span class="co-ball">2</span> флаг каждого правила решает, как учесть результат модуля и продолжать ли</div>
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Порядок строк важен:</b> стек – не множество, а последовательность; перестановка
строк меняет поведение (пример с <Man p="pam_faillock(8)" /> – раздел 6).
</div>
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
Четыре стека службы (auth, account, password, session) выполняются <b>независимо</b>
и в разное время – каждый своим вызовом API.
</div>

</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Понятие стека: правила одного типа одной службы, в порядке записи, включая
подставленные include. Это не глобальный список всех строк PAM: вызов
pam_authenticate видит только правила auth своей службы. Пример – стек из
четырёх правил: pam_env, pam_nologin, pam_unix, pam_deny. Два предупреждения:
порядок строк значим (вернёмся при разговоре о faillock), а синтаксически
некорректная строка не игнорируется – она становится правилом «обязан
отказать»: PAM ошибается в сторону запрета. Четыре стека службы независимы.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="4" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# Управляющие флаги: краткая форма

<div>

Поле `control` определяет, **как результат модуля влияет на итог всего стека**. Четыре
классических флага:

</div>

<div class="t-table text-xs mt-2">

| Флаг | Успех модуля | Неудача модуля |
|---|---|---|
| **required** | учесть результат, продолжить | **запомнить неудачу**, продолжить исполнение стека |
| **requisite** | учесть результат, продолжить | **запомнить неудачу**, стек прервать **немедленно** |
| **sufficient** | завершить стек **успехом**, если ранее не записано ни одной<br/>неигнорируемой неудачи | неудача **игнорируется**, продолжить |
| **optional** | учитывается, только если нет более сильного результата в стеке | обычно игнорируется |

</div>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Почему required не прерывает стек?</b> Чтобы не раскрывать атакующему,
<b>на каком шаге</b> произошла ошибка: оставшиеся модули выполняются, время ответа
и диалог не зависят от места отказа. <code>requisite</code> также жертвует этим ради
гарантии: ни один следующий модуль не получит информацию (например, пароль, введённый
при подозрительных условиях).
</div>

<div class="sub-box mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">

Кроме флагов поле `control` принимает две **директивы подстановки** – задают способ
включения правил из другого файла (раздел 2.6):

<div class="t-table sub-table mt-1">

| Директива | Что подставляется | Прерывание стека и прыжки |
|---|---|---|
| **include** `файл` | правила из файла – на место строки | действуют на **весь** стек |
| **substack** `файл` | то же, но как **вложенный стек**: его итог учитывается как результат одного правила | **не выходят** за пределы подстека |

</div>

</div>


<Refs ids="man-pam-conf pam-sag" />

<style>
.t-table { font-size: 0.68rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
.sub-box p { margin: 0 0 0.4em; line-height: 1.4; }
.sub-table :deep(table) { margin: 0; }
</style>

<!--
Семантика по pam.conf(5). required: неудача учитывается, но стек доходит до
конца – атакующий не узнаёт, где именно провалился. requisite: немедленный
отказ; SAG приводит мотив – не дать модулям ниже по стеку получить пароль при
подозрительных условиях. sufficient: успех достаточен, если до этого не было
неудач required; неудача sufficient просто игнорируется. optional учитывается,
только когда он единственный в стеке. include и substack подставляют строки из
другого файла – о них отдельно в разделе 2.6. Таблица – сводка для обычных
исходов; точные правила для каждого кода даёт подробная форма.
-->

---

# Пример: простые флаги

<div class="grid grid-cols-[1.1fr_1fr] gap-4 items-start">
<div>

<CodeSnippet src="snippets/ex-flags.txt" lang="text" title="фрагменты стеков" tag="примеры" :numbers="false" fontSize="0.5rem" class="!mt-0">
  <TCallout :line="2" :col="10" :span="8" :rows="2" :n="1" />
  <TCallout :line="6" :col="10" :span="9" :n="2" />
  <TCallout :line="10" :col="10" :span="10" :rows="2" :n="3" />
  <TCallout :line="15" :col="10" :span="8" :n="4" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> неудача <code>pam_unix</code> не мешает <code>pam_nologin</code> выполниться – но может иметь побочные эффекты (счётчики, журнал)</div>
<div><span class="co-ball">2</span> «система закрыта» – пароль не спрашивается вовсе; однако сравнительно небольшое время работы выдаёт, <b>какая</b> проверка отказала</div>
<div><span class="co-ball">3</span> <code>sufficient</code> удобен для проверки условия «любой из» (логическое ИЛИ), но <b>опасно</b>, если ниже стоит обязательный второй фактор</div>
<div><span class="co-ball">4</span> несмотря на <code>optional</code>, модуль всё равно <b>выполняется</b> (побочные эффекты остаются)</div>
</div>

</div>
<div>

<div class="t-table text-xs">

| Вопрос | required | requisite |
|---|---|---|
| Неудача делает итог неуспешным? | да | да |
| Следующие правила после неудачи исполняются? | **да** | **нет** |
| Позднейший успех исправляет неудачу? | нет | нет |
| Назначение | все обязательные проверки выполняются | быстрый отказ по предусловию |

</div>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>sufficient перед обязательным фактором</b> – одна из наиболее типичных ошибок конфигурации:
верный пароль завершает стек успехом, и строка второго фактора не исполняется
(раздел 7). Замена <code>required</code> на <code>sufficient</code> «чтобы заработало» =
обход проверки, а не настройка.
</div>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>optional ≠ «неважно»</b>: единственное правило типа в стеке решает итог – будучи единственным правило
<code>auth optional pam_unix.so</code> разрешит вход
</div>

</div>
</div>

<Refs ids="man-pam-conf pam-sag man-pam-nologin" />

<style>
.t-table { font-size: 0.68rem !important; }
.t-table td, .t-table th { padding-top: 0.33em !important; padding-bottom: 0.33em !important; }
</style>

<!--
Четыре фрагмента. required (1): обе проверки выполняются; первая неудача
решает итог, но у второго модуля могут быть побочные эффекты – запись в
журнал, инкремент счётчика. requisite (2): при закрытой системе pam_nologin
отказывает до запроса пароля – быстро, но путь ответа выдаёт, какая именно
проверка отказала. sufficient (3): механизм альтернатив – локальный пароль или
каталог; опасен, если ниже стоит обязательный фактор: успех завершает стек
раньше него. optional (4): результат обычно не учитывается, но модуль
выполняется, а если он единственный в стеке – его успех решает всё. Таблица
справа формализует разницу required/requisite четырьмя вопросами; обе формы
проваливают стек и ни одна не прощает неудачу – различие только в том,
исполняются ли следующие правила. Два предупреждения: sufficient перед
обязательным фактором и «optional значит неважно» – обе ошибки встретим в
разделе о безопасности.
-->

---

# Подробная форма флага: значение = действие

<div>

Простые флаги являются сокращениями, полная форма задаёт **действие на каждый код возврата**
модуля:

</div>

<FieldRecord class="mt-3" sep="" size="0.95rem" legendSize="0.78rem" :cols="3"
  :fields="['[', { t: 'success=ok', hot: true }, 'auth_err=die', '…', 'default=ignore', ']']"
  :legend="[
    'открывающая скобка – начало поля control',
    { t: 'пара «код возврата = действие»: слева – код (success), справа – действие (ok)', hot: true },
    'при auth_err – записать неудачу и прервать стек (die)',
    'другие пары – их число произвольно, по одной на интересующий код',
    'default – все не перечисленные коды: здесь – не учитывать',
    'закрывающая скобка – конец поля',
  ]"
/>

<div class="mt-1 text-xs opacity-80">
Пары разделяются пробелами и заключаются в <b>квадратные скобки</b>: <code>[success=ok auth_err=die default=ignore]</code> – это одно поле <code>control</code>.
</div>

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-3 items-start">
<div>

<CodeSnippet src="snippets/ex-ext-syntax.txt" lang="text" title="подробная форма в правиле" tag="примеры" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="8" :span="6" :n="1" badge="tl" />
  <TCallout :line="2" :col="15" :span="6" :n="2" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> слева <code>ignore</code> – <b>код возврата</b> <code>PAM_IGNORE</code>: «модуль просит не учитывать результат»</div>
<div><span class="co-ball">2</span> справа <code>ignore</code> – <b>действие</b>: не записывать этот результат в итог</div>
</div>

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Два пространства имён.</b> Слева от «=» – селектор кода возврата
(<code>success</code>, <code>auth_err</code>, <code>user_unknown</code>, … или <code>default</code>),
справа – действие (<code>ignore</code>, <code>bad</code>, <code>die</code>, <code>ok</code>,
<code>done</code>, число <code>N</code>, <code>reset</code>). Одно и то же слово
<code>ignore</code> по разные стороны означает разное – они не взаимозаменяемы.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Тип правила перед скобками пишется как обычно: <code>auth [success=done auth_err=bad default=ignore] pam_unix.so</code>;
такая строка читается «успех – завершить стек, ошибка проверки пароля – неудача, прочее – не учитывать».
</div>
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<style>
.field-record :deep(.fr-row) { justify-content: center; }
.field-record :deep(.fr-cell + .fr-cell) { margin-left: 0.45em; }
</style>

<!--
Полный синтаксис: в квадратных скобках пары значение=действие. Разбор
единственной строки по полям: скобки, пара success=ok, пара auth_err=die,
default для всех прочих кодов. Главный источник путаницы – слово ignore: слева
от знака равенства это код возврата PAM_IGNORE, которым модуль сам просит не
учитывать его результат; справа – действие «не записывать результат в итог».
Пример [ignore=ignore success=ok default=bad] читается так: если модуль вернул
PAM_IGNORE – отбросить, если успех – записать, всё прочее – неудача. Селекторы и
действия – два разных словаря. Пробелы внутри скобок допустимы: libpam
воспринимает всё в скобках как одно поле control.
-->

---

# Коды возврата модулей

<div>

Определённые в PAM результаты операций модуля – коды возврата соответствующих функций `libpam` – заданы 
именованными константами (<Man p="pam(3)" />); в подробной форме они записываются **строчными именами без префикса** `PAM_`:

</div>

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div class="t-table text-xs">

| Константа | Имя во флаге | Смысл |
|---|---|---|
| `PAM_SUCCESS` | `success` | операция выполнена |
| `PAM_AUTH_ERR` | `auth_err` | аутентификация не пройдена |
| `PAM_PERM_DENIED` | `perm_denied` | доступ запрещён |
| `PAM_USER_UNKNOWN` | `user_unknown` | пользователь неизвестен **этому модулю** |
| `PAM_AUTHINFO_UNAVAIL` | `authinfo_unavail` | источник данных недоступен |
| `PAM_MAXTRIES` | `maxtries` | исчерпаны попытки |
| `PAM_NEW_AUTHTOK_REQD` | `new_authtok_reqd` | пароль нужно сменить |
| `PAM_ACCT_EXPIRED` | `acct_expired` | срок учётной записи истёк |
| `PAM_AUTHTOK_ERR` | `authtok_err` | ошибка работы с аутентификатором |
| `PAM_IGNORE` | `ignore` | модуль просит не учитывать его результат |
| `PAM_MODULE_UNKNOWN` | `module_unknown` | модуль не найден или не распознан |
| `PAM_SYSTEM_ERR` | `system_err` | системная ошибка |

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Код может нести <b>больше</b>, чем «да/нет»: <code>new_authtok_reqd</code> означает «пароль
необходимо сменить», а не «всё выполнено»; <code>user_unknown</code> – «этот модуль
пользователя не знает», что при нескольких источниках не равно отказу.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Прочие документированные имена: <code>open_err</code>, <code>symbol_err</code>, <code>service_err</code>,
<code>cred_insufficient</code>, <code>cred_expired</code>, <code>session_err</code>, <code>conv_err</code>,
<code>authtok_expired</code>, <code>try_again</code>, <code>abort</code>, <code>incomplete</code>… –
полный список в <Man p="pam.conf(5)" />.
</div>
<div class="opacity-80">
Как именно флаг отображает каждый код в действие – следующий слайд.
</div>
</div>
</div>

<Refs ids="man-pam3 man-pam-conf" />

<style>
.t-table { font-size: 0.64rem !important; }
.t-table td, .t-table th { padding-top: 0.12em !important; padding-bottom: 0.12em !important; }
</style>

<!--
Коды возврата – словарь, которым разговаривают модуль и libpam. Таблица –
наиболее употребительные константы и их имена в подробной форме флага:
success, auth_err, perm_denied, user_unknown, authinfo_unavail, maxtries,
new_authtok_reqd, acct_expired, authtok_err, ignore, module_unknown,
system_err. Два замечания о семантике: new_authtok_reqd – не успех и не отказ,
а требование действия; user_unknown – локальное незнание модуля, а при
нескольких источниках учётных записей это нормальный ответ одного из них.
Остальные имена перечислены в pam.conf(5). Следующий слайд – как флаг
сопоставляет каждому коду действие.
-->

---

# Действия подробной формы

<div class="grid grid-cols-[1fr_1.25fr] gap-4 items-start">
<div class="t-table text-xs">

| Действие | Влияние на итог | Ход исполнения |
|---|---|---|
| `ignore` | результат не учитывается | продолжить |
| `bad` | записать неудачу; ранние неудачи не стираются | продолжить |
| `die` | записать неудачу | **остановить** стек |
| `ok` | принять результат, не перекрывая записанной неудачи | продолжить |
| `done` | как `ok` | завершить стек, если записанных неудач нет |
| `N` | в стеках auth/account/password/open_session – как `ignore` | **перепрыгнуть** следующие N правил |
| `reset` | **стереть** накопленное состояние | продолжить |

</div>
<div>

<CodeSnippet src="snippets/ex-ext-actions.txt" lang="text" title="по примеру на действие" tag="примеры" :numbers="false" fontSize="0.47rem">
  <TCallout :line="5" :col="8" :span="9" :n="1" />
  <TCallout :line="6" :col="8" :span="13" :n="2" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1.5">
<div><span class="co-ball">1</span> <b>прыжок</b> считает <b>правила</b>, а не строки файла: комментарии и пустые строки не в счёт; вложенный <code>substack</code> – одно правило; <code>0</code> ведёт себя как <code>ignore</code>. Вставка правила между прыжком и его целью меняет, что именно пропускается</div>
<div><span class="co-ball">2</span> <b>reset</b> стирает и ранее записанную обязательную неудачу – самое опасное действие: применять только после полной трассировки стека</div>
</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Итог стека складывается из <b>первой решающей</b> неудачи: <code>bad</code> и <code>die</code> не
перезаписывают её, <code>ok</code> и <code>done</code> не перекрывают; <code>done</code> завершает стек
досрочно лишь при чистом итоге. Прыжок в <code>pam_setcred</code> и <code>pam_close_session</code>
может учитываться иначе – <Man p="pam.conf(5)" />.
</div>

<Refs ids="man-pam-conf pam-sag man-pam-succeed-if" />

<style>
.t-table { font-size: 0.64rem !important; }
.t-table td, .t-table th { padding-top: 0.15em !important; padding-bottom: 0.15em !important; }
</style>

<!--
Семь действий в двух измерениях: что происходит с накопленным итогом и что с
ходом исполнения. ignore – отбросить результат, идти дальше (но модуль
выполнился, побочные эффекты остались). bad – записать неудачу, идти дальше;
die – записать и остановиться. ok – принять, не перекрывая записанной
неудачи; done – то же плюс досрочное завершение, если итог чист. Число N –
прыжок через N правил: для стеков auth, account, password и open_session его
вклад в итог подобен ignore; для setcred и close_session pam.conf(5)
оговаривает иной учёт – поэтому прыжок нельзя описывать как чисто «изменение
счётчика команд». reset – стирание накопленного состояния, включая ранее
записанную обязательную неудачу, – единственный способ «простить» отказ, и
потому опасный. Прыжки считают правила, а не строки; substack – одно правило;
ноль равносилен ignore; вставка строки между прыжком и целью смещает цель –
при каждой правке стека с прыжками нужно пересчитывать их заново (раздел 6,
faillock: success=1 → success=2).
-->

---

# Умолчания и эквиваленты кратких флагов

<CodeSnippet src="snippets/ex-default.txt" lang="text" title="default и эквиваленты" tag="примеры" :numbers="false" fontSize="0.47rem">
  <TCallout :line="1" :col="32" :span="14" :n="1" />
  <TCallout :line="2" :col="7" :span="27" :n="2" />
  <TCallout :line="3" :col="7" :span="24" :n="3" />
  <TCallout :line="4" :col="7" :span="58" :n="4" />
</CodeSnippet>

<CodeSnippet src="snippets/pam-conf-controls.txt" lang="text" title="pam.conf(5): соответствие кратких флагов" tag="Linux-PAM 1.7.0" :numbers="false" fontSize="0.47rem" class="mt-2">
  <TCallout :line="1" :col="59" :span="11" :n="5" />
  <TCallout :line="2" :col="59" :span="11" :n="6" />
  <TCallout :line="3" :col="14" :span="34" :n="7" />
</CodeSnippet>

<div class="text-xs space-y-1">
<div><span class="co-ball">1</span> <code>default</code> покрывает все не перечисленные коды: здесь – <code>ignore</code></div>
<div><span class="co-ball">2</span> <b>если <code>default</code> опущен</b>, не перечисленный код получает <code>bad</code> – способ подстраховать администратора, неподумавшего о результатах наподобие <code>user_unknown</code> или <code>authinfo_unavail</code></div>
<div><span class="co-ball">3</span> <code>[success=ok default=bad]</code> – <b>не</b> то же, что <code>required</code>: теряется особая обработка <code>new_authtok_reqd</code> и <code>ignore</code></div>
<div><span class="co-ball">4</span> точный эквивалент <code>required</code> – дословно по <Man p="pam.conf(5)" /></div>
<div><span class="co-ball">5</span> <span class="co-ball">6</span> required и requisite различаются только действием по умолчанию: <code>bad</code> против <code>die</code></div>
<div><span class="co-ball">7</span> sufficient: успех завершает стек (<code>done</code>), прочее – <code>ignore</code></div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Прыжок <code>N</code> – основной приём Debian/Ubuntu: <code>[success=1 default=ignore]</code> у
<Man p="pam_unix(8)" /> означает «успех – перепрыгнуть <Man p="pam_deny(8)" />»; разбор – пример D (раздел 2.5) и раздел 3.1.
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Правило умолчания: default сопоставляет действие всем не перечисленным кодам.
Коварная деталь: если default опущен, не перечисленные коды получают bad –
и модуль, вернувший user_unknown или authinfo_unavail, провалит стек, хотя
администратор, возможно, рассчитывал его пропустить. Эквиваленты кратких
флагов – не приблизительные аналогии, а точные определения pam.conf(5):
required и requisite различаются лишь действием по умолчанию, sufficient –
done на успех и ignore на всё прочее; у всех трёх особая обработка
new_authtok_reqd (принимается как успех) и у required/requisite – ignore. Поэтому
[success=ok default=bad] – НЕ required: пользователь с истёкшим паролем получит
отказ вместо требования сменить пароль. Debian строит common-auth на прыжках –
разберём в примере D и в разделе 3.
-->

---

# Стек – не логическое И и не ИЛИ

<div>

Каждый модуль возвращает код; **управляющий флаг** решает, записать ли результат в итог
или отбросить, и что делать дальше – продолжить, остановиться, перепрыгнуть правила или
сбросить накопленное состояние.

</div>

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-2 items-start">
<div>

<div class="t-table text-xs">

| Правило | Флаг | Результат модуля | Накопленный итог |
|---|---|---|---|
| A | `required` | неудача | **неудача** записана |
| B | `required` | успех | неудача сохраняется |
| C | `sufficient` | успех | не может ни стереть неудачу, ни завершить стек досрочно |
| | | **итог стека** | **неудача** |

</div>

<div class="mt-2 text-xs opacity-80">
Будь стек логическим «И», достаточно было бы одного отказа без исполнения остальных;
будь он «ИЛИ» – успех C означал бы успех стека. Ни то ни другое не верно.
</div>

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Три правила накопленного итога:</b>
<div class="mt-1 space-y-1">
<div>① успех <b>не стирает</b> ранее записанную (не отброшенную) неудачу;</div>
<div>② неудача модуля <b>не обязательно</b> проваливает стек – это решает его флаг;</div>
<div>③ некоторые действия <b>прерывают</b> стек до того, как позднейшие модули выполнятся.</div>
</div>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Единственное действие, стирающее записанную неудачу, – явный <code>reset</code> (предыдущие слайды).
Свойство «позднейший успех не отменяет ранней неудачи» – важная гарантия безопасности PAM.
</div>
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<!--
Итог раздела 2.4: стек – не булево выражение. Трассируем пример: A
required провалился – неудача записана; B required успешен – ничего не стирает;
C sufficient успешен – но sufficient завершает стек досрочно лишь при
отсутствии ранее записанных неудач, поэтому и он не спасает: итог – неудача.
Три правила накопленного итога: успех не стирает неудачу; неудача не
обязательно фатальна – решает флаг; действия потока управления могут вовсе не
дать модулю выполниться. Единственный способ забыть неудачу – явный reset, и
именно поэтому он опасен. Это свойство и делает PAM пригодным для безопасности:
обязательную проверку нельзя «перекрыть» позднейшим успехом.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="5" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# Исполнение стека «на бумаге» и pamtester

Лучший способ понять PAM – **исполнить стек вручную**, отслеживая две величины:
**накопленный итог** и **номер следующего правила**. Проверить трассировку позволяет
утилита `pamtester`: она открывает PAM-транзакцию для указанной службы и пользователя и
выполняет одну операцию.

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-3 items-start">
<div>

<div class="t-table text-xs">

| Служба | Стек auth | Что демонстрирует |
|---|---|---|
| `demo-a` | два `required` | оба модуля выполняются при любом исходе |
| `demo-b` | `requisite`, затем `required` | немедленная остановка стека |
| `demo-c` | `required` условие, `sufficient`, `required deny` | sufficient не спасает после неудачи |
| `demo-d` | `[success=1 default=ignore]`, `requisite deny`, `required permit` | числовой прыжок – схема Debian |
| `demo-e` | `[success=2 default=ignore]`, …, `required permit` | прыжок через два модуля – обход проверки |

</div>

</div>
<div class="text-xs space-y-2">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Лабораторная среда:</b> Ubuntu Server 26.04, пакет <code>pamtester</code>; пять учебных
служб <code>/etc/pam.d/demo-a</code> … <code>demo-e</code>; <code>bob</code> – член группы
<code>operators</code>, <code>carol</code> – нет. Вызов:
<code>pamtester &lt;служба&gt; &lt;пользователь&gt; authenticate</code>.
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pamtester</code> исполняет выбранную операцию, но не гарантирует, что приложение передаст
те же элементы транзакции и вызовет те же операции. У проверок есть <b>побочные эффекты</b>:
растут счётчики неудач, открываются сеансы, <code>chauthtok</code> меняет пароль.
</div>
</div>
</div>

<SrcRef>См. <code>demos/00-stack-examples.sh</code>.</SrcRef>

<Refs ids="pam-sag pamtester man-pam-conf" />

<style>
.t-table { font-size: 0.66rem !important; }
</style>

<!--
Методика раздела: исполняем стек на бумаге – две переменные, накопленный итог и
индекс следующего правила, – а затем сверяем с реальностью при помощи pamtester.
Утилита открывает транзакцию pam_start для названной службы и пользователя и
вызывает одну операцию – здесь authenticate, то есть pam_authenticate. Пять
учебных служб demo-a…demo-e покрывают пять конструкций: два required,
requisite, sufficient после неудачи, прыжок Debian и опасный прыжок через два
модуля. Оговорка: pamtester проверяет стек, но не приложение – настоящий sshd
может передавать другие элементы (rhost, tty) и вызывать другие операции; и
проверки не бесплатны: faillock считает неудачи, session открывает сеансы,
chauthtok меняет пароль. Сценарий 00-stack-examples.sh воспроизводит все пять
примеров на одноразовой машине.
-->

---

# Примеры A и B: два required против requisite

<div class="grid grid-cols-2 gap-4 items-start">
<div>

<TerminalCapture src="captures/14-stack-examples.txt" section="1" title="demo-a · оба модуля выполняются" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="8" :rows="2" :n="1" />
  <TCallout :line="6" :col="1" :span="9" :n="2" />
  <TCallout :line="7" :col="1" :span="29" :n="3" />
</TerminalCapture>

<div class="t-table text-xs mt-2">

| `pam_unix` | `pam_nologin` | Итог |
|---|---|---|
| успех | успех | успех |
| успех | неудача | неудача |
| неудача | успех | неудача |
| неудача | неудача | неудача |

</div>

</div>
<div>

<TerminalCapture src="captures/14-stack-examples.txt" section="2" title="demo-b · пароль не запрашивается" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="9" :n="4" />
  <TCallout :line="7" :col="1" :span="29" :n="5" />
  <TCallout :line="13" :col="1" :span="9" :n="6" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> оба правила <code>required</code>; файл <code>/etc/nologin</code> закрывает систему для всех, кроме root</div>
<div><span class="co-ball">2</span> запрос пароля – свидетельство, что <code>pam_unix</code> <b>выполнился</b>…</div>
<div><span class="co-ball">3</span> …и <code>pam_nologin</code> выполнился тоже: при любом пароле итог – отказ (таблица)</div>
<div><span class="co-ball">4</span> <code>requisite</code> первым: при отказе стек прерывается</div>
<div><span class="co-ball">5</span> сообщение есть, запроса пароля <b>нет</b> – до <code>pam_unix</code> дело не дошло</div>
<div><span class="co-ball">6</span> без <code>/etc/nologin</code> стек проходит до конца и запрашивает пароль</div>
</div>
</div>

</div>
</div>

<SrcRef>См. <code>demos/00-stack-examples.sh</code>.</SrcRef>

<Refs ids="man-pam-conf man-pam-nologin man-pam-unix pamtester" />

<!--
Пример A. Стек из двух required; создаём /etc/nologin, чтобы pam_nologin
отказывал bob. С верным паролем pamtester всё равно запрашивает пароль –
значит pam_unix выполнился, – затем печатает сообщение nologin и отказ; с
неверным паролем картина та же. Таблица исходов: итог успешен, только если
успешны оба; при этом оба модуля выполняются при любом исходе первого.
Пример B. Те же два модуля, но pam_nologin стоит первым с requisite: при
закрытой системе выводится сообщение, а запроса пароля нет вовсе – стек
прерван до pam_unix. Удаляем /etc/nologin – стек проходит до конца, пароль
запрашивается, вход успешен. Разница между A и B видна невооружённым глазом:
есть ли приглашение Password.
-->

---

# Пример C: sufficient после неудачи не спасает

<div class="grid grid-cols-[1.1fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/14-stack-examples.txt" section="3" title="demo-c · член группы и посторонний" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="8" :n="1" />
  <TCallout :line="2" :col="43" :span="28" :n="1" />
  <TCallout :line="3" :col="9" :span="10" :n="2" />
  <TCallout :line="4" :col="9" :span="8" :n="3" />
  <TCallout :line="10" :col="12" :span="27" :n="4" />
  <TCallout :line="14" :col="12" :span="22" :n="5" />
</TerminalCapture>

</div>
<div class="text-xs">

<div class="t-table">

| Шаг | bob ∈ operators | carol ∉ operators |
|---|---|---|
| ① `pam_succeed_if` (`required`) | успех | **неудача записана** |
| ② `pam_unix` (`sufficient`) | успех → стек завершён **успехом** | успех – но стереть неудачу или завершить стек он **не может** |
| ③ `pam_deny` (`required`) | не достигнут | неудача |
| итог | **успех** | **неудача** |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10">
<div class="space-y-1">
<div><span class="co-ball">4</span> верный пароль члена группы – вход разрешён: <code>sufficient</code> сработал при чистом итоге</div>
<div><span class="co-ball">5</span> верный пароль carol – отказ: записанную неудачу условия <b>не отменяет</b> даже успешный <code>sufficient</code></div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Так строится правило «только члены группы, и только по паролю»: обязательное условие
<b>перед</b> <code>sufficient</code>, безусловный отказ <b>после</b>.
</div>

</div>
</div>

<SrcRef>См. <code>demos/00-stack-examples.sh</code>.</SrcRef>

<Refs ids="man-pam-conf man-pam-succeed-if man-pam-rootok" />

<style>
.t-table { font-size: 0.64rem !important; }
.t-table td, .t-table th { padding-top: 0.15em !important; padding-bottom: 0.15em !important; }
</style>

<!--
Пример C: три правила – обязательное условие членства в группе
(pam_succeed_if, required), sufficient pam_unix, required pam_deny. Для bob,
члена operators, с верным паролем: условие успешно, пароль успешен, sufficient
завершает стек до pam_deny – успех. Для carol с верным паролем: условие
провалено и неудача записана; pam_unix успешен, но sufficient не может ни
стереть записанную неудачу, ни завершить стек; pam_deny выполняется – отказ.
Это и есть практическое следствие правила «успех не стирает неудачу»: так
строится политика «только члены группы» – условие перед sufficient, deny после.
-->

---

# Пример D: числовой прыжок (схема Debian)

<div class="grid grid-cols-[1.1fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/14-stack-examples.txt" section="4" title="demo-d · success=1" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="26" :n="1" />
  <TCallout :line="3" :col="9" :span="9" :n="2" />
  <TCallout :line="4" :col="9" :span="8" :n="3" />
  <TCallout :line="7" :col="12" :span="27" :n="4" />
  <TCallout :line="11" :col="12" :span="22" :n="5" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Это ровно <code>common-auth</code> Ubuntu (раздел 3.1) без аргумента <code>nullok</code>.
Задел на расширение: модуль каталога вставляется между <code>pam_unix</code> и
<code>pam_deny</code>, а прыжок становится <code>success=2</code> (раздел 6, faillock).
</div>

</div>
<div class="text-xs">

<div class="grid grid-cols-2 gap-2">
<div class="p-2 border-l-4 border-teal-600 bg-teal-500/10">
<b>Верный пароль</b> <span class="co-ball">4</span>
<div class="mt-1 space-y-0.5">
<div><code>pam_unix</code>: success → прыжок через 1 правило</div>
<div><code>pam_deny</code>: <b>пропущен</b></div>
<div><code>pam_permit</code>: success</div>
<div><b>итог: успех</b></div>
</div>
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Неверный пароль</b> <span class="co-ball">5</span>
<div class="mt-1 space-y-0.5">
<div><code>pam_unix</code>: auth_err → <code>ignore</code>, продолжить</div>
<div><code>pam_deny</code>: неудача, <code>requisite</code> → <b>стоп</b></div>
<div><code>pam_permit</code>: не достигнут</div>
<div><b>итог: неудача</b></div>
</div>
</div>
</div>

<div class="mt-2 space-y-1">
<div><span class="co-ball">1</span> подробная форма: успех – прыжок, всё прочее – не учитывать</div>
<div><span class="co-ball">2</span> <Man p="pam_deny(8)" /> всегда отказывает; <code>requisite</code> делает отказ немедленным</div>
<div><span class="co-ball">3</span> <Man p="pam_permit(8)" /> всегда успешен – он лишь <b>фиксирует</b> итог, которого достиг прыжок</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>pam_permit</code> всегда успешен, но на пути отказа <b>не исполняется</b> – его защищает
поток управления. Уберите <code>success=1</code> или поменяйте строки местами – поведение
изменится радикально. Правило с <code>pam_permit</code> никогда не является самостоятельной проверкой.
</div>

</div>
</div>

<SrcRef>См. <code>demos/00-stack-examples.sh</code>.</SrcRef>

<Refs ids="man-pam-conf man-pam-rootok pam-sag" />

<!--
Пример D – конструкция Debian. Верный пароль: pam_unix успешен, success=1 –
прыжок через одно правило, pam_deny пропущен, pam_permit успешен, итог – успех.
Неверный пароль: auth_err попадает под default=ignore – продолжаем, pam_deny с
requisite – немедленный отказ, pam_permit не достигнут. Почему так сложно?
Задел на расширение: между pam_unix и pam_deny вставляется второй источник
(pam_sss) или учёт неудач (faillock authfail), а прыжок пересчитывается –
success=2; логика «любой подтвердивший – вход разрешён» собирается из прыжков.
Предупреждение: pam_permit всегда успешен и безопасен лишь потому, что путь
отказа до него не доходит; уберите прыжок – и permit станет дырой.
-->

---

# Пример E: прыжок через два модуля

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/14-stack-examples.txt" section="5" title="demo-e · опасная конфигурация" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="26" :n="1" />
  <TCallout :line="3" :col="41" :span="14" :rows="2" :n="2" />
  <TCallout :line="8" :col="12" :span="22" :n="3" />
  <TCallout :line="10" :col="1" :span="37" :n="4" />
  <TCallout :line="11" :col="12" :span="27" :n="5" />
</TerminalCapture>

</div>
<div class="text-xs">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Читаем:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> при успехе условия – прыжок через <b>два</b> правила</div>
<div><span class="co-ball">2</span> пропускаются и проверка пароля, и проверка <code>/etc/nologin</code></div>
<div><span class="co-ball">3</span> carol не в группе: условие → <code>ignore</code>, <code>pam_unix</code> отвергает неверный пароль – отказ</div>
<div><span class="co-ball">4</span> для bob <b>пароль не запрошен вовсе</b>…</div>
<div><span class="co-ball">5</span> …и аутентификация успешна: членство в группе заменило пароль</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Намеренно небезопасный пример:</b> прыжок создаёт <b>обход аутентификации</b>
для целой группы. Любая перестановка или вставка правил в стеке с числовыми прыжками
требует <b>повторного разбора</b> потока управления; <MitreAttack t="T1556" /> –
модификация процесса аутентификации.
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод раздела 2.5:</b> итог стека определяют не имена модулей, а отображение кодов
возврата в действия и путь, по которому исполнение дошло – или не дошло – до каждого правила.
</div>

</div>
</div>

<SrcRef>См. <code>demos/00-stack-examples.sh</code>.</SrcRef>

<Refs ids="man-pam-conf man-pam-succeed-if pam-sag" />

<!--
Пример E – тот же приём, что в D, но прыжок на два правила перескакивает и
pam_unix, и pam_nologin. Для carol вне группы условие даёт ignore, pam_unix
отвергает неверный пароль – отказ, как и положено. Для bob условие успешно –
и pamtester даже не спрашивает пароль: проверка пароля пропущена, pam_permit
фиксирует успех. Членство в группе стало заменой аутентификации – классический
обход, MITRE ATT&CK T1556 «Modify Authentication Process». Мораль: прыжки
считают правила, и любая вставка или перестановка в таком стеке требует
пересчёта; а итог стека определяет не список модулей, а путь исполнения.
Это и есть вывод раздела 2.5 перед переходом к include и substack.
-->

---
layout: section
---

# 2. Устройство PAM

<SectionTOC prefix="2" :current="6" :items="[
  'Библиотека и модули',
  'Файлы конфигурации',
  'Типы правил и стек модулей',
  'Управляющие флаги',
  'Примеры исполнения стека',
  'include и substack: повторное использование правил',
]" />

---

# include: подстановка правил другого файла

<div>

Директива `include` подставляет в стек правила **того же типа** из указанного файла –
так общие правила разделяются между службами:

</div>

<div class="grid grid-cols-[1fr_auto_1fr_auto_1.1fr] gap-3 mt-3 items-center">
<div>

<CodeSnippet src="snippets/ex-include-parent.txt" lang="text" title="/etc/pam.d/<служба>" tag="родитель" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="7" :span="7" :n="1" />
</CodeSnippet>

</div>
<div class="inc-plus">+</div>
<div>

<CodeSnippet src="snippets/ex-include-child.txt" lang="text" title="/etc/pam.d/common-auth" tag="включаемый файл" :numbers="false" fontSize="0.5rem" />

</div>
<div class="inc-plus">=</div>
<div>

<CodeSnippet src="snippets/ex-include-effective.txt" lang="text" title="эффективный стек auth" tag="результат" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="17" :span="11" :n="2" />
</CodeSnippet>

</div>
</div>

<div class="grid grid-cols-2 gap-3 mt-4 text-xs">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">1</span> <code>include</code> берёт из <code>common-auth</code> только правила типа
<code>auth</code>; <span class="co-ball">2</span> они встают на место директивы – стек ведёт себя так,
будто строки написаны прямо в файле службы. <b>Аналогия – макрос:</b> директива раскрывается
в текст включаемого файла, как макрос препроцессора – в своё определение.
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Включённые правила участвуют в потоке управления родителя:</b> <code>done</code> или
<code>die</code> внутри включённого файла завершает <b>весь</b> стек службы, а прыжок
<code>N</code> может перескочить через правила родителя, следующие за директивой.
</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<style>
.inc-plus { font-size: 1.6rem; font-weight: 700; color: var(--ossec-muted); }
</style>

<!--
include – механизм повторного использования: директива подставляет в стек
правила того же типа из другого файла. Пример: родитель с pam_env, include
common-auth и pam_nologin; common-auth содержит pam_unix; эффективный стек –
env, unix, nologin. Ключевое свойство: включённые правила ничем не отличаются
от написанных в самом файле – они участвуют в потоке управления родителя:
done или die внутри включённого файла завершит весь стек, а прыжок может
перескочить через правила родителя, стоящие после директивы. Именно это
свойство делает include удобным и опасным одновременно. Аналогия для
аудитории – макрос: include раскрывается в текст, никакой границы между
«своими» и «чужими» правилами после подстановки нет. У include две формы
записи – следующий слайд.
-->

---

# Две формы include: `тип include` и `@include`

<div>

Типизированная директива – часть синтаксиса Linux-PAM с версии 0.80 (2005). Debian с 2003 г. добавляет
патчем вторую, **бестиповую** форму `@include`; её наследуют Ubuntu, Astra Linux и другие производные:

</div>

<div class="grid grid-cols-[1fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-common-files.txt" section="5" title="Ubuntu Server 26.04 · /etc/pam.d/other – форма @include" fontSize="0.5rem" class="!mt-0" />

</div>
<div>

<CodeSnippet src="snippets/ex-include-typed.txt" lang="text" title="то же в стандартной записи" tag="эквивалент" :numbers="false" fontSize="0.5rem" class="!mt-0" />

</div>
</div>

<div class="t-table text-xs mt-3">

| Признак | `@include файл` | `тип include файл` |
|---|---|---|
| Поля правила | два: директива и файл | три: тип, `include`, файл (поле модуля занимает имя файла) |
| Какие строки берёт | **все** строки файла – каждая попадает в стек своего типа | только правила **указанного типа** |
| Поток управления | как у `include`: `done`, `die` и прыжки действуют на весь стек службы | то же |
| Где работает | только `libpam` с патчем Debian: Debian, Ubuntu, Astra Linux | любой Linux-PAM ≥ 0.80: RHEL, Arch, openSUSE и Debian тоже |
| Появилась | pam 0.76-13.1 (Debian, август 2003) – до upstream-директивы | Linux-PAM 0.80 (июль 2005) |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Сокращение Debian <code>@include</code></b> – соглашение дистрибутива, а не общий механизм PAM: патч
<code>031_pam_include</code> не принят upstream, в <code>libpam</code> RHEL и Arch строки <code>@include</code> нет.
Переносить его на другие системы нельзя – использовать следует типизированные <code>include</code> и <code>substack</code>.
В Ubuntu 26.04 <code>common-*</code> подключаются именно так – со всеми следствиями подстановки без границы (далее, раздел 3).
</div>

<Refs ids="man-pam-conf pam-sag debian-pam-include man-pam-auth-update linux-pam-src" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Две формы одной директивы. Стандартная – четырёхпольная строка «тип include
файл»: появилась в Linux-PAM 0.80 (июль 2005) и подставляет из файла только
правила указанного типа. Форма @include – патч Debian (031_pam_include, автор
Jan Christoph Nordholz; «Upstream status: not yet submitted»): введена в пакете
pam 0.76-13.1 в августе 2003 г., раньше upstream-директивы, – отсюда и само
соглашение common-*. В коде патча @include разбирается как include с «любым»
типом: берутся все строки файла, каждая встаёт в стек своего типа; по потоку
управления это обычный include без границы. Слева – реальный /etc/pam.d/other
Ubuntu 26.04, справа – его запись стандартным синтаксисом. Главное для
переноса знаний: в libpam RHEL и Arch строки @include нет (проверено strings),
такая строка там – ошибка разбора; Astra Linux как производная Debian
использует @include. Поэтому учим типизированные include и substack, а
@include читаем как «include для всех типов».
-->

---

# substack: граница потока управления

<div>

`substack` тоже подставляет правила указанного типа, но вводит **границу**: вложенный стек
исполняется как единое целое.

</div>

<div class="grid grid-cols-[1fr_1.2fr] gap-4 mt-2 items-start">
<div class="text-xs space-y-2">
<div class="font-semibold">Отличия <code>include</code> и <code>substack</code>:</div>
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<div class="space-y-1">
<div>① <code>done</code> и <code>die</code> завершают <b>вложенный</b> стек, а не стек службы;</div>
<div>② прыжок <code>N</code> внутри вложенного стека не может выйти за его пределы;</div>
<div>③ для прыжков <b>родителя</b> весь вложенный стек считается <b>одним правилом</b>;</div>
<div>④ <code>reset</code> внутри возвращает состояние <b>на момент входа</b> во вложенный стек, а не стирает историю родителя.</div>
</div>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Результаты вложенных правил <b>по-прежнему входят</b> в накопленный итог службы:
<code>substack</code> – граница управления, а не «песочница», глушащая неудачи.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Аналогия:</b> <code>include</code> – макрос, <code>substack</code> – вызов подпрограммы: у неё
собственный поток управления, а наружу возвращается один результат.
</div>
</div>
<div class="t-table text-xs">

| Поведение | `include` | `substack` |
|---|---|---|
| Подставляет правила другого файла | да | да |
| Берёт только правила своего типа | да | да |
| `done` во включённом завершает родителя | **да** | нет |
| `die` во включённом завершает родителя | **да** | нет |
| Прыжок изнутри может попасть на правила родителя | возможно | нет |
| Считается одним правилом для прыжков родителя | нет | **да** |
| Ограниченная область `reset` | нет | **да** |

</div>
</div>

<Refs ids="man-pam-conf pam-sag" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
substack загружает те же правила, что и include, но исполняет их как единое
целое с границей управления: done и die завершают только вложенный стек,
прыжки изнутри не выходят наружу, для прыжков родителя вложенный стек – одно
правило, reset внутри откатывает состояние лишь к моменту входа. При этом
результаты вложенных правил входят в общий итог: substack не глушит неудачи,
он лишь не даёт вложенному файлу управлять потоком родителя. Таблица сводит
различия по семи признакам – четыре строки различаются, и все они про поток
управления. Аналогия в пару к предыдущему слайду: include – макрос (текст
раскрывается на месте), substack – вызов подпрограммы (свой поток управления,
один возвращаемый результат).
-->

---

# include vs substack: проверка общих правил

<div class="grid grid-cols-2 gap-4 items-start">
<div>

<CodeSnippet src="snippets/ex-substack-include.txt" lang="text" title="вариант 1 · include" tag="небезопасно" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="7" :span="7" :n="1" />
  <TCallout :line="6" :col="7" :span="10" :n="2" />
</CodeSnippet>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<span class="co-ball">1</span> <span class="co-ball">2</span> верный пароль → <code>sufficient</code> при чистом итоге
завершает <b>весь</b> стек службы: <code>pam_nologin</code> <b>не исполняется</b>, закрытая на
обслуживание система впускает пользователя.
</div>

</div>
<div>

<CodeSnippet src="snippets/ex-substack-substack.txt" lang="text" title="вариант 2 · substack" tag="корректно" :numbers="false" fontSize="0.5rem">
  <TCallout :line="2" :col="7" :span="8" :n="3" />
</CodeSnippet>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<span class="co-ball">3</span> успешный <code>sufficient</code> завершает только вложенный стек и возвращает
управление родителю: <code>pam_nologin</code> <b>исполняется</b>. Для проверок, специфичных для
службы и стоящих <b>после</b> общей аутентификации, нужен именно <code>substack</code>.
</div>

</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
В Ubuntu 26.04 <code>common-auth</code> подключается через <code>@include</code> – то есть по варианту 1.
Debian компенсирует это устройством самих общих файлов: <code>common-auth</code> завершается
<code>pam_permit</code>/<code>pam_deny</code> без <code>sufficient</code>, а служебные проверки вроде
<code>pam_nologin</code> в <code>login</code> стоят <b>до</b> включения с флагом <code>requisite</code> (раздел 3).
</div>

<Refs ids="man-pam-conf pam-sag man-pam-auth-update" />

<!--
Почему разница важна. Вариант 1: служба включает общий файл primary-auth с
sufficient pam_unix, а затем ставит собственную проверку pam_nologin. При
верном пароле sufficient завершает весь стек – pam_nologin не исполняется, и
закрытая на обслуживание система впускает пользователя. Вариант 2: substack –
успех sufficient завершает лишь вложенный стек, управление возвращается
родителю, pam_nologin исполняется. Правило: специфичные для службы ограничения
после общей аутентификации требуют substack. Ubuntu собирает все службы через
@include (предыдущий слайд) – поэтому в разделе 3 полезно смотреть на
common-auth, помня о варианте 1: Debian компенсирует это тем, что общий файл
заканчивается pam_permit/pam_deny без sufficient, а служебные проверки вроде
pam_nologin в login стоят ДО include с requisite.
-->

---
layout: section
---

# 3. Типичные конфигурации PAM

<SectionTOC prefix="3" :current="1" :items="[
  'Debian и Ubuntu: общие файлы <code>common-*</code>',
  'Debian и Ubuntu: файлы служб <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
  'Семейство RHEL: <code>system-auth</code> и authselect',
  'Arch Linux: цепочка включений <code>system-*</code>',
  'Astra Linux Special Edition',
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
| `common-auth` | auth | проверка пароля <Man p="pam_unix(8)" /> |
| `common-account` | account | срок действия по `/etc/shadow` |
| `common-password` | password | смена пароля, алгоритм yescrypt |
| `common-session` | session | журналирование, `pam_umask`, <Man p="pam_systemd(8)" /> |
| `common-session-noninteractive` | session | то же для неинтерактивных служб (`cron`) |

</div>

</div>
<div>

<InfoCard icon="info" head="pam-auth-update">

файлы `common-*` собирает утилита <Man p="pam-auth-update(8)"
href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam-auth-update.8.html" />
из **профилей**, которые пакеты кладут в `/usr/share/pam-configs/`. Поэтому
установка пакета с новым модулем может сама включить его в общие стеки –
увидим в разделе 6.

</InfoCard>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Одна правка – все службы:</b> изменение <code>common-auth</code> действует
сразу на вход с консоли, по ssh, на <code>su</code> и <code>sudo</code>.
Это удобно – и ответственно: ошибка блокирует все пути входа одновременно.
</div>

</div>
</div>

<Refs ids="man-pam-auth-update man-pam-conf" />

<style>
/* Таблица упирается в нижний колонтитул – ужимаем. */
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
профилей пакетов – отсюда «магия» автоматического подключения новых модулей
при установке пакета (покажем вживую на libpam-pwquality). Предупреждение:
правка common-auth действует на все пути входа сразу – и авария тоже.
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
<b>Пароль верный:</b> <Man p="pam_unix(8)" /> – успех → прыжок через одну строку
(<code>success=1</code>) мимо <Man p="pam_deny(8)" /> → <Man p="pam_permit(8)" /> –
<b>вход разрешён</b>
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Пароль неверный:</b> <code>default=ignore</code> – идём дальше →
<code>pam_deny</code> с <code>requisite</code> – <b>немедленный отказ</b>
</div>
</div>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> подробная форма флага: успех – прыжок через 1 правило, остальное – не учитывать</div>
<div><span class="co-ball">2</span> <code>pam_unix</code> проверяет пароль по <code>/etc/shadow</code> (лекция 2)</div>
<div><span class="co-ball">3</span> <code>pam_deny</code> всегда возвращает отказ</div>
<div><span class="co-ball">4</span> <code>pam_permit</code> всегда возвращает успех – фиксирует итог</div>
</div>
</div>

<v-click>

<InfoCard icon="warning" head="nullok" class="mt-2 text-xs">

аргумент разрешает вход с **пустым** паролем – по умолчанию `pam_unix`
его запрещает (<Man p="pam_unix(8)" />). На серверах параметр убирают.

</InfoCard>

</v-click>

</div>
</div>

<Refs ids="man-pam-unix man-pam-rootok man-pam-conf" />

<!--
Первый настоящий файл. Конструкция из трёх строк: pam_unix с прыжком, pam_deny,
pam_permit. Зачем так сложно? Задел на расширение: доменный модуль pam_sss
вставляется между pam_unix и pam_deny, прыжок становится success=2 – логика
«любой из источников подтвердил – вход разрешён» собирается из прыжков.
Два пути: верный пароль перепрыгивает deny и попадает на permit; неверный –
default=ignore ведёт на deny с requisite, немедленный отказ. nullok разрешает
пустые пароли – на серверах убирают. Напомнить: pam_deny и pam_permit –
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
<span class="co-ball">1</span> <Man p="pam_unix(8)" /> (тип account) проверяет
<b>срок действия</b> пароля и учётной записи по полям <code>/etc/shadow</code>
(лекция 2, раздел 3); <code>new_authtok_reqd=done</code> – «пароль истёк,
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
<div><span class="co-ball">2</span> <code>pam_umask</code> – начальная маска прав новых файлов</div>
<div><span class="co-ball">3</span> <code>pam_unix</code> (тип session) журналирует открытие и закрытие сеанса</div>
<div><span class="co-ball">4</span> <Man p="pam_systemd(8)" /> регистрирует сеанс в <code>systemd-logind</code></div>
</div>
</div>

</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Первая строка <code>common-session</code> – <code>[default=1] pam_permit.so</code>:
технический приём pam-auth-update, выравнивающий прыжки при пересборке файла.
</div>

<Refs ids="man-pam-unix man-pam-conf" />

<!--
Два общих стека покороче. common-account: единственный рабочий модуль –
pam_unix, который сверяет срок действия пароля и учётной записи с полями
shadow; new_authtok_reqd=done пропускает пользователя с истёкшим паролем,
заставляя его сменить пароль. common-session: pam_umask задаёт маску прав,
pam_unix пишет в журнал строки session opened/closed, pam_systemd регистрирует
сеанс в logind (появился при установке openssh/gdm вместе с libpam-systemd).
Первая строка [default=1] pam_permit – служебная заглушка pam-auth-update.
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
(<DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" />) и истории (<Man p="pam_pwhistory(8)" />) вставляются
в этот стек <b>перед</b> <Man p="pam_unix(8)" /> – политика задаётся один раз
и действует на <code>passwd</code>, <code>chpasswd</code>, смену пароля по ssh –
на всё (раздел 6).
</div>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> стек password выполняется при <b>любой</b> смене пароля; рабочий модуль один – <code>pam_unix</code></div>
<div><span class="co-ball">2</span> <code>obscure</code> – простые встроенные проверки нового пароля: не палиндром, не совпадает со старым с точностью до регистра (<Man p="pam_unix(8)" />)</div>
<div><span class="co-ball">3</span> <code>yescrypt</code> – алгоритм хеширования новых паролей: тот самый <code>$y$</code> из <code>/etc/shadow</code> (лекция 2)</div>
</div>
</div>
</div>

<Refs ids="man-pam-unix man-pam-conf" />

<!--
Последний общий файл – common-password, стек password. По умолчанию один
рабочий модуль pam_unix с двумя интересными аргументами: obscure – встроенные
эвристики качества нового пароля, yescrypt – алгоритм хеширования, который мы
видели в лекции 2 по префиксу $y$. Главное на слайде – зелёная карточка:
common-password есть точка подключения парольной политики; модули качества и
истории вставляются перед pam_unix, и политика действует на любую смену пароля
в системе. Весь раздел 6 построен на этом факте.
-->

---
layout: section
---

# 3. Типичные конфигурации PAM

<SectionTOC prefix="3" :current="2" :items="[
  'Debian и Ubuntu: общие файлы <code>common-*</code>',
  'Debian и Ubuntu: файлы служб <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
  'Семейство RHEL: <code>system-auth</code> и authselect',
  'Arch Linux: цепочка включений <code>system-*</code>',
  'Astra Linux Special Edition',
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
<div><span class="co-ball">1</span> <code>pam_faildelay</code> – пауза 3 с после неудачной попытки: перебор паролей с клавиатуры замедляется</div>
<div><span class="co-ball">2</span> <Man p="pam_nologin(8)" /> – при существовании файла <code>/etc/nologin</code> вход разрешён только root (раздел 5.1)</div>
<div><span class="co-ball">3</span> сама проверка пароля – <code>@include common-auth</code>: в файле <code>login</code> о <code>/etc/shadow</code> нет ни строки</div>
<div><span class="co-ball">4</span> <Man p="pam_limits(8)" /> – лимиты ресурсов сеанса (раздел 5.4); рядом – окружение (<Man p="pam_env(8)" />), приветствие (<Man p="pam_motd(8)" />), почта (<code>pam_mail</code>)</div>
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
Файл конкретной службы – login, программа входа с консоли. Он почти целиком
состоит из «обвязки»: faildelay замедляет перебор, nologin закрывает систему
на обслуживание, motd печатает приветствие, limits устанавливает лимиты,
loginuid передаёт ядру auid для аудита. А проверка пароля – одна строка
@include common-auth: логика общая. Это и есть обещанное разделение: файл
службы описывает её особенности, общие файлы – политику аутентификации.
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
<div><span class="co-ball">1</span> проверка пароля – тот же общий стек <code>common-auth</code>, что и у <code>login</code></div>
<div><span class="co-ball">2</span> <Man p="pam_nologin(8)" /> здесь – в стеке <b>account</b>: сначала пароль, потом проверка «системы закрыты»</div>
<div><span class="co-ball">3</span> <Man p="pam_limits(8)" />, <Man p="pam_env(8)" />, <Man p="pam_motd(8)" /> – настройка сеанса</div>
<div><span class="co-ball">4</span> подключены все четыре общих файла – sshd пользуется каждым стеком</div>
</div>

<v-click>

<InfoCard icon="terminal" head="UsePAM yes" class="mt-2 text-xs">

пакет openssh-server в Ubuntu включает PAM (<Man p="sshd_config(5)" />);
диалог модулей с пользователем идёт только через
`KbdInteractiveAuthentication` – важно для второго фактора (раздел 7).

</InfoCard>

</v-click>

</div>
</div>

<Refs ids="man-pam-conf man-sshd-config" />

<!--
sshd подключает все четыре общих файла и добавляет свою обвязку. Отличие от
login: pam_nologin стоит в стеке account – sshd сначала проверяет пароль и лишь
затем «закрыта ли система»; у login тот же модуль стоит в auth с requisite –
до пароля. Такие перестановки – нормальная практика: каждая служба решает,
в каком стеке выполнять проверку. Карточка: PAM в sshd включается директивой
UsePAM yes (умолчание Debian/Ubuntu, не upstream!), а диалог модулей с
пользователем возможен только при KbdInteractiveAuthentication yes – к этому
вернёмся, подключая второй фактор.
-->

---

# Служба gdm-password: графический вход

Графический вход GNOME настраивают файлы `gdm-*`; за вход **по паролю** отвечает
`gdm-password` (рядом – `gdm-autologin`, `gdm-fingerprint`, `gdm-smartcard*`).

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
<div><span class="co-ball">1</span> <code>pam_succeed_if user != root</code> – графический вход <b>root запрещён</b> политикой Ubuntu</div>
<div><span class="co-ball">2</span> проверка пароля – снова общий <code>common-auth</code>: третья служба с теми же правилами</div>
<div><span class="co-ball">3</span> <code>pam_gnome_keyring</code> – паролем входа разблокируется связка ключей GNOME; флаг <code>optional</code>: неудача не мешает входу</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Итог для Debian/Ubuntu:</b> три разных пути входа – консоль, сеть, графика –
сходятся в одних и тех же общих стеках; меняя <code>common-*</code>,
мы меняем политику всех путей сразу. Другие семейства решают ту же задачу иначе.
</div>

</v-click>

</div>
</div>

<Refs ids="man-pam-conf man-pam-rootok" />

<!--
Третий путь входа – графический. У GDM семейство файлов gdm-*: password –
обычный вход по паролю, autologin – вход без пароля, fingerprint и smartcard –
другие факторы. В gdm-password: succeed_if запрещает графический вход root –
политика Ubuntu; проверка пароля – всё тот же common-auth; gnome_keyring с
флагом optional разблокирует связку ключей паролем входа – пример модуля,
неудача которого не мешает аутентификации. Вывод раздела: все пути входа
сходятся в common-* – дальше работаем с ними; но сначала посмотрим, как ту же
задачу решают другие семейства дистрибутивов.
-->

---
layout: section
---

# 3. Типичные конфигурации PAM

<SectionTOC prefix="3" :current="3" :items="[
  'Debian и Ubuntu: общие файлы <code>common-*</code>',
  'Debian и Ubuntu: файлы служб <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
  'Семейство RHEL: <code>system-auth</code> и authselect',
  'Arch Linux: цепочка включений <code>system-*</code>',
  'Astra Linux Special Edition',
]" />

---

# Семейство RHEL: общая политика в system-auth и password-auth

RHEL, Fedora, Rocky Linux, AlmaLinux – и РЕД ОС с той же пакетной базой – держат общие стеки
не в `common-*`, а в **двух файлах**: `system-auth` для локальных служб и `password-auth` для сетевых.

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="10 · system-auth" title="Rocky Linux 10.2 · /etc/pam.d/system-auth" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="1" :span="25" :n="1" />
  <TCallout :line="7" :col="6" :span="29" :rows="2" :n="2" />
  <TCallout :line="10" :col="10" :span="26" :n="3" />
  <TCallout :line="11" :col="56" :span="11" :n="4" />
  <TCallout :line="15" :col="1" :span="8" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> файл <b>сгенерирован</b> утилитой authselect – ручная правка будет перезаписана (следующие слайды)</div>
<div><span class="co-ball">2</span> вместо прыжков Debian – пара <code>sufficient</code> + <code>required pam_deny</code>: успех <Man p="pam_unix(8)" /> завершает стек, иначе отказ (раздел 2.4)</div>
<div><span class="co-ball">3</span> <code>pam_pwquality</code> с <code>requisite</code> стоит в стеке password <b>по умолчанию</b> – без установки пакетов</div>
<div><span class="co-ball">4</span> <code>use_authtok</code>: pam_unix берёт пароль, уже проверенный pam_pwquality (раздел 4.3)</div>
<div><span class="co-ball">5</span> ведущий дефис: отсутствие модуля systemd не ломает вход (раздел 2.2)</div>
</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Задержка <code>pam_faildelay</code> и окружение <code>pam_env</code> включены в сам общий стек, а не в файлы
служб, как в Ubuntu; <code>pam_succeed_if service in crond</code> освобождает cron от записи сеанса в журнал.
</div>

<Refs ids="rhel-pam rocky-pam authselect man-pam-conf" />

<!--
Второе большое семейство. Общая политика собрана в system-auth; password-auth –
её двойник для сетевых служб (sshd), по умолчанию идентичный. Стиль правил
другой: вместо [success=1 default=ignore] здесь классическая пара sufficient +
required pam_deny – семантически то же самое, разобрали в разделе 2.4.
Важное отличие от Ubuntu: pam_pwquality уже стоит в стеке password, а pam_unix
получает проверенный пароль через use_authtok. Строка с дефисом – pam_systemd
может отсутствовать (контейнер без systemd), и это не ошибка. Заголовок файла
честно предупреждает: сгенерировано authselect, руками не править.
-->

---

# Файлы служб RHEL: password-auth через substack

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="10 · sshd" title="Rocky Linux 10.2 · /etc/pam.d/sshd" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="12" :span="26" :n="1" />
  <TCallout :line="3" :col="12" :span="22" :n="2" />
  <TCallout :line="4" :col="25" :span="15" :rows="2" :n="3" />
  <TCallout :line="17" :col="1" :span="4" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="t-table text-xs">

| Общий файл | Подключают | Содержимое |
|---|---|---|
| `system-auth` | `login`, `su`, `sudo`, `passwd`… | четыре стека |
| `password-auth` | `sshd`, `remote` | копия для сетевых служб |
| `postlogin` | службы входа | `pam_umask`, `pam_lastlog` |
| `smartcard-auth`, `fingerprint-auth` | графический вход | другие факторы |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>substack</code>, а не <code>include</code>: прыжки внутри <code>password-auth</code> не выходят в файл службы (раздел 2.6)</div>
<div><span class="co-ball">2</span> <code>postlogin</code> – второй общий файл, тоже сгенерированный</div>
<div><span class="co-ball">3</span> обвязка службы: <code>pam_sepermit</code> (SELinux) и <Man p="pam_nologin(8)" /> – в стеке account, как у Ubuntu</div>
<div><span class="co-ball">4</span> оба общих файла по умолчанию совпадают: разделение – задел на разную политику для локального и сетевого входа</div>
</div>
</div>

</div>
</div>

<Refs ids="rhel-pam man-pam-conf man-sshd-config" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Файл sshd в Rocky – та же идея, что в Ubuntu: обвязка службы плюс подключение
общих стеков. Но подключение через substack: прыжки внутри password-auth
остаются внутри него – именно тот случай, который мы разбирали в разделе 2.6.
Таблица: какие файлы считаются общими и кто их подключает. system-auth –
локальные службы, password-auth – сетевые; diff показывает, что по умолчанию
они совпадают. Разделение сделано на вырост: политику для удалённого входа
(например, обязательный второй фактор) можно ужесточить отдельно.
-->

---

# authselect: готовые профили вместо правки стеков

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="текущий профиль" title="Rocky Linux 10.2 · authselect" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="63" :span="34" :rows="2" :n="1" />
  <TCallout :line="5" :col="1" :span="17" :n="2" />
  <TCallout :line="8" :col="3" :span="7" :rows="3" :n="3" />
  <TCallout :line="12" :col="1" :span="16" :rows="5" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> файлы в <code>/etc/pam.d</code> – символические ссылки на результат генерации в <code>/etc/authselect/</code></div>
<div><span class="co-ball">2</span> <b>профиль</b> – согласованный набор <code>system-auth</code>, <code>password-auth</code>, <code>postlogin</code>, <code>nsswitch.conf</code>; в RHEL 10 по умолчанию <code>local</code>, в RHEL 8–9 – <code>sssd</code></div>
<div><span class="co-ball">3</span> три профиля поставщика: локальные учётные записи, домен через SSSD, домен Windows через winbind</div>
<div><span class="co-ball">4</span> <b>функции</b> профиля включают готовые фрагменты: блокировка, история паролей, <code>pam_access</code>, создание домашнего каталога, запрет пустых паролей</div>
</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
authselect появился в RHEL 8 на смену authconfig; он не настраивает сами службы
(SSSD, Kerberos) – только стеки PAM и NSS, которые к ним обращаются.
</div>

<Refs ids="rhel10-authselect authselect rhel-pam" />

<!--
Генератор семейства RHEL. Идея противоположна pam-auth-update: не собирать
файл из фрагментов пакетов, а выбрать один целостный профиль и включить в нём
функции. Файлы в /etc/pam.d – ссылки на /etc/authselect, где лежит результат.
Профилей три: local (RHEL 10 по умолчанию), sssd (умолчание RHEL 8–9 – даже
для локальных пользователей), winbind. Функции – именованные фрагменты:
with-faillock добавляет pam_faillock в auth и account, with-pwhistory –
pam_pwhistory в password, without-nullok убирает nullok. Для аудита
достаточно двух команд: authselect current и authselect list-features.
-->

---

# authselect: смена профиля и свой профиль

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="смена профиля" title="Rocky Linux 10.2 · authselect select / check / create-profile" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="1" :col="21" :span="26" :n="1" />
  <TCallout :line="2" :col="1" :span="16" :n="2" />
  <TCallout :line="11" :col="1" :span="31" :n="3" />
  <TCallout :line="12" :col="14" :span="39" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> профиль и функции задаются одной командой; <code>--force</code> нужен, если файлы в <code>/etc/pam.d</code> были изменены вручную</div>
<div><span class="co-ball">2</span> прежняя конфигурация сохраняется в резервной копии – откат одной командой <code>authselect backup-restore</code></div>
<div><span class="co-ball">3</span> <code>check</code> сверяет файлы с профилем: расхождение – признак ручной правки <b>или постороннего вмешательства</b></div>
<div><span class="co-ball">4</span> нестандартная политика – через <b>собственный профиль</b> на основе поставщика: правятся файлы в <code>/etc/authselect/custom/</code>, затем <code>select custom/custom-security</code></div>
</div>
</div>

<v-click>

<InfoCard icon="info" head="pam-auth-update против authselect" class="mt-2 text-xs">

Debian **складывает** `common-*` из профилей пакетов: установили `libpam-pwquality` –
модуль в стеке. RHEL **выбирает** профиль целиком: модуль включает функция
профиля или свой профиль, а не пакет.

</InfoCard>

</v-click>

</div>
</div>

<Refs ids="rhel10-authselect authselect unit42-pam" />

<!--
Рабочий цикл: select выбирает профиль и функции (здесь – sssd с блокировкой);
предыдущая конфигурация уходит в резервную копию; check подтверждает, что файлы
соответствуют профилю. Это ещё и инструмент контроля целостности: вредоносные
PAM-модули (отчёт Unit 42 в списке источников) добавляют себя именно правкой
стеков, и authselect check такую правку заметит. Для нестандартной политики –
собственный профиль на основе поставщика. Карточка фиксирует главное отличие
двух генераторов: аддитивная сборка Debian против выбора целостного профиля.
-->

---
layout: section
---

# 3. Типичные конфигурации PAM

<SectionTOC prefix="3" :current="4" :items="[
  'Debian и Ubuntu: общие файлы <code>common-*</code>',
  'Debian и Ubuntu: файлы служб <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
  'Семейство RHEL: <code>system-auth</code> и authselect',
  'Arch Linux: цепочка включений <code>system-*</code>',
  'Astra Linux Special Edition',
]" />

---

# Arch Linux: политика как цепочка включений

Генераторов нет: файлы пакета `pambase` правят вручную, а общая политика собрана **слоями**, каждый подключает следующий.

<div class="grid grid-cols-[1fr_1.25fr] gap-4 mt-1 items-start">
<div>

<div class="t-table text-xs">

| Служба | подключает | → | → |
|---|---|---|---|
| `login` | `system-local-login` | `system-login` | `system-auth` |
| `sshd` | `system-remote-login` | `system-login` | `system-auth` |
| `sudo`, `su` | `system-auth` | | |

</div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="Arch Linux · other" title="Arch Linux · /etc/pam.d/other" fontSize="0.45rem" class="mt-2">
  <TCallout :line="3" :col="22" :span="11" :rows="2" :n="5" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="цепочка включений" title="Arch Linux (pam 1.7.3) · файлы служб" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="21" :span="19" :n="1" />
  <TCallout :line="7" :col="21" :span="12" :n="2" />
  <TCallout :line="13" :col="25" :span="18" :n="3" />
  <TCallout :line="18" :col="33" :span="11" :n="4" />
</TerminalCapture>

</div>
</div>

<div class="grid grid-cols-2 gap-3 mt-1 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span>–<span class="co-ball">4</span> файл службы состоит из одних <code>include</code>:
действующие правила видны, только если развернуть граф включений до конца.
<span class="co-ball">5</span> <code>other</code> – консервативный пример из руководства Linux-PAM (раздел 2.2);
в Ubuntu <code>other</code> подключает <code>common-*</code>.
</div>
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Зачем слои:</b> правка <code>system-remote-login</code> затрагивает только удалённый вход,
<code>system-login</code> – любой интерактивный вход, <code>system-auth</code> – ещё и
<code>sudo</code>, <code>su</code>, <code>passwd</code>. Чем ниже слой, тем шире последствия ошибки.
</div>
</div>

<Refs ids="archwiki-pam pam-sag man-pam-conf" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Третья схема – без генератора. Arch поставляет файлы в пакете pambase и
ожидает ручной правки, но раскладывает общую политику по слоям: system-auth
(собственно проверки), system-login (всё для интерактивного входа: shells,
nologin, access, motd, systemd), и два тонких файла-переходника для локального
и удалённого входа. sshd и login состоят из одних include – отсюда правило
аудита: разворачивать цепочку до конца, иначе половина правил не видна.
Отдельно other: Arch взял консервативный вариант из SAG дословно – deny + warn,
тогда как Ubuntu для неизвестной службы применяет общие стеки.
-->

---

# Arch Linux: system-auth с блокировкой pam_faillock по умолчанию

<div class="grid grid-cols-[1.5fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="Arch Linux · system-auth" title="Arch Linux (pam 1.7.3) · /etc/pam.d/system-auth" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="61" :span="7" :n="1" />
  <TCallout :line="3" :col="1" :span="5" :n="2" />
  <TCallout :line="4" :col="12" :span="23" :n="3" />
  <TCallout :line="5" :col="61" :span="8" :n="4" />
  <TCallout :line="8" :col="61" :span="8" :n="5" />
  <TCallout :line="12" :col="40" :span="11" :n="6" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <Man p="pam_faillock(8)" /> <code>preauth</code> – до пароля: учётная запись уже заблокирована?</div>
<div><span class="co-ball">2</span> дефис и прыжок через два правила: пользователь systemd-homed минует <code>pam_unix</code> и учёт неудач</div>
<div><span class="co-ball">3</span> <code>[success=1 default=bad]</code>: верный пароль перепрыгивает <code>authfail</code>; <code>try_first_pass</code> – пароль берётся у предыдущего модуля</div>
<div><span class="co-ball">4</span> <code>[default=die] … authfail</code> – неудача засчитана, стек завершён</div>
<div><span class="co-ball">5</span> <code>authsucc</code> – успех сбрасывает счётчик</div>
<div><span class="co-ball">6</span> <Man p="pam_time(8)" /> уже в стеке account: достаточно заполнить <code>time.conf</code></div>
</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Та же трёхстрочная схема faillock, которую в разделе 6 мы будем подключать к Ubuntu вручную,
в Arch входит в поставку; параметры – в <code>/etc/security/faillock.conf</code> (раздел 2.2: два слоя настройки).
</div>

<Refs ids="archwiki-pam man-pam-faillock man-pam-conf" />

<!--
Нижний слой Arch – system-auth. Он интересен тем, что блокировка после
неудачных попыток включена из коробки: preauth до пароля, authfail после
неудачи с default=die, authsucc после успеха. Между ними – pam_unix с прыжком
через authfail при успехе и систем-homed с дефисом и прыжком через два правила.
Это буквально та конфигурация, которую мы будем собирать руками на Ubuntu в
разделе 6 – полезно увидеть её целиком заранее. pam_time в account – правило
есть, а ограничений в time.conf по умолчанию нет; достаточно дописать файл.
-->

---
layout: section
---

# 3. Типичные конфигурации PAM

<SectionTOC prefix="3" :current="5" :items="[
  'Debian и Ubuntu: общие файлы <code>common-*</code>',
  'Debian и Ubuntu: файлы служб <code>login</code>, <code>sshd</code>, <code>gdm-password</code>',
  'Семейство RHEL: <code>system-auth</code> и authselect',
  'Arch Linux: цепочка включений <code>system-*</code>',
  'Astra Linux Special Edition',
]" />

---

# Astra Linux SE 1.8: схема Debian с политикой блокировки по умолчанию

Astra Linux Special Edition построена на Debian 12: те же `common-*`, `@include`
и pam-auth-update – но профили поставщика **заранее включают** политику безопасности.

<div class="grid grid-cols-[1.5fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="SE 1.8 · common-auth" title="Astra Linux SE 1.8.7 · common-auth" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="9" :span="26" :n="1" />
  <TCallout :line="3" :col="65" :span="24" :n="2" />
  <TCallout :line="4" :col="57" :span="29" :n="3" />
  <TCallout :line="5" :col="9" :span="26" :n="4" />
</TerminalCapture>

<TerminalCapture src="captures/15-distro-stacks.txt" section="SE 1.8 · common-account" title="Astra Linux SE 1.8.7 · common-account" fontSize="0.45rem" class="mt-2">
  <TCallout :line="3" :col="62" :span="23" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файлы:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_localuser</code>: для пользователя <b>не из локальных файлов</b> прыжок через два правила – учёт неудач только для локальных учётных записей</div>
<div><span class="co-ball">2</span> члены группы <code>astra-admin</code> минуют <code>preauth</code>: администратора нельзя заблокировать перебором</div>
<div><span class="co-ball">3</span> <Man p="pam_faillock(8)" />: блокировка после 8 неудач, счётчик на пользователя, событие в аудит</div>
<div><span class="co-ball">4</span> верный пароль перепрыгивает <code>authfail</code> и <code>pam_deny</code> – схема Debian с прыжком 2 (раздел 2.5, пример E)</div>
<div><span class="co-ball">5</span> в account – <Man p="pam_listfile(8)" />: учётные записи из <code>/etc/users.blocked</code> отклоняются с сообщением; файл по умолчанию пуст</div>
</div>
</div>
</div>

<Refs ids="astra-wiki-lock astra-redbook astra-repo man-pam-auth-update" />

<!--
Отечественный дистрибутив из семейства Debian: контейнерный образ Astra Linux
SE 1.8.7 (libpam 1.5.2 с патчами Astra). Файлы common-* собраны тем же
pam-auth-update, но из профилей поставщика faillock.preauth, faillock.authfail,
listfile, pwquality – поэтому блокировка после неудачных попыток и список
заблокированных учётных записей есть сразу. Разбор common-auth – хорошее
упражнение на раздел 2: pam_localuser выводит доменных пользователей из-под
учёта (их блокирует домен), astra-admin минует preauth, pam_unix при успехе
прыгает через authfail и deny. Параметры (deny=8) меняет графическая утилита
политик учётных записей; документация Astra – в списке источников.
-->

---

# Astra Linux SE 1.8: ГОСТ-хеш пароля и проверки сеанса

<TerminalCapture src="captures/15-distro-stacks.txt" section="SE 1.8 · common-password" title="Astra Linux SE 1.8.7 · common-password" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="66" :span="24" :n="1" />
  <TCallout :line="3" :col="69" :span="26" :n="2" />
  <TCallout :line="3" :col="96" :span="10" :n="3" />
</TerminalCapture>

<TerminalCapture src="captures/15-distro-stacks.txt" section="SE 1.8 · common-session" title="Astra Linux SE 1.8.7 · common-session" fontSize="0.45rem" class="mt-2">
  <TCallout :line="7" :col="25" :span="11" :n="4" />
  <TCallout :line="7" :col="96" :span="28" :n="5" />
</TerminalCapture>

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_pwquality</code> с <code>requisite</code> в поставке: минимум 8 символов, 3 отличия от старого пароля, 3 попытки</div>
<div><span class="co-ball">2</span> <code>use_authtok try_first_pass</code> – конвенция передачи пароля по стеку (раздел 4.3)</div>
<div><span class="co-ball">3</span> <code>gost12_512</code>: хеш ГОСТ Р 34.11-2012 «Стрибог», префикс <code>$gost12512hash$</code> в <code>/etc/shadow</code> (лекция 2) – аргумент патченного pam_unix Astra</div>
</div>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<div class="space-y-1.5">
<div><span class="co-ball">4</span> <Man p="pam_exec(8)" /> в стеке session запускает внешнюю программу при открытии сеанса</div>
<div><span class="co-ball">5</span> сценарий предупреждает о нехватке места в <code>/</code>, <code>/var</code> и домашнем каталоге – пример расширения PAM без модуля на C (раздел 9)</div>
</div>
</div>
</div>

<Refs ids="astra-gost-hash astra-repo man-pam-env man-pam-unix" />

<!--
Два оставшихся общих файла. common-password: pam_pwquality с базовой политикой
уже включён, а pam_unix получил нестандартный аргумент gost12_512 – алгоритм
хеширования ГОСТ Р 34.11-2012, который мы видели в лекции 2 по префиксу
$gost12512hash$. Это аргумент патченного Astra pam_unix: на Ubuntu он вызвал бы
предупреждение «unrecognized option» – увидим в разделе 4.3. common-session:
pam_exec запускает сценарий проверки свободного места – пример того, что
расширить PAM можно и без собственного модуля, если задача простая.
-->

---

# Astra Linux SE 1.8: модули PARSEC в файлах служб

<div class="grid grid-cols-[1.45fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="SE 1.8 · sshd" title="Astra Linux SE 1.8.7 · /etc/pam.d/sshd" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="8" :col="18" :span="22" :n="1" />
  <TCallout :line="16" :col="25" :span="17" :rows="2" :n="2" />
  <TCallout :line="18" :col="18" :span="17" :n="3" />
</TerminalCapture>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>pam_parsec_mac</code> – мандатные метки PARSEC (конфиденциальность и целостность) для сеанса; <code>stub</code> – заглушка до общих стеков</div>
<div><span class="co-ball">2</span> <code>pam_parsec_cap</code> и <code>pam_parsec_aud</code> – привилегии PARSEC и параметры аудита пользователя</div>
<div><span class="co-ball">3</span> рабочий вызов <code>pam_parsec_mac</code> – после общих стеков, перед <code>pam_selinux open</code></div>
</div>
</div>

<TerminalCapture src="captures/15-distro-stacks.txt" section="модули PARSEC" title="Astra Linux SE 1.8.7 · откуда модули" fontSize="0.45rem" class="mt-2">
  <TCallout :line="6" :col="1" :span="28" :n="4" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<span class="co-ball">4</span> Модули PARSEC лежат в <code>/usr/lib/security</code>, а строки в <code>login</code>, <code>sshd</code>, <code>su</code>
добавляет сценарий пакета <code>parsec-mac</code>, а не pam-auth-update: при аудите их не найти в <code>common-*</code>.
Полный состав зависит от уровня защищённости (базовый, усиленный, максимальный) – см. документацию Astra.
</div>

<Refs ids="astra-wiki-ipc astra-redbook astra-repo" />

<!--
Главная особенность Astra – подсистема безопасности PARSEC: мандатное
управление доступом и контроль целостности, расширенные привилегии и аудит.
С PAM она связана тремя модулями, которые пакеты PARSEC вписывают прямо в
файлы служб: pam_parsec_mac устанавливает метку сеанса (вызывается дважды –
заглушка до общих стеков и рабочий вызов после), pam_parsec_cap выдаёт
привилегии, pam_parsec_aud – параметры аудита. Для аудита конфигурации важно:
этих строк нет в common-*, и лежат модули не в мультиархитектурном каталоге, а
в /usr/lib/security. Набор включённых механизмов зависит от выбранного уровня
защищённости – подробности в документации Astra из списка источников.
-->

---

# Четыре схемы – одна библиотека и одна семантика стека

<div class="t-table text-xs mt-2">

| | Debian, Ubuntu | Astra Linux SE | RHEL, Fedora, Rocky, РЕД ОС | Arch Linux |
|---|---|---|---|---|
| Общие файлы | `common-auth`, `-account`, `-password`, `-session` | те же `common-*` | `system-auth`, `password-auth`, `postlogin` | `system-auth` → `system-login` → `system-{local,remote}-login` |
| Подключение | `@include` | `@include` | `substack`, `include` | `include` |
| Кто собирает | pam-auth-update из профилей пакетов | pam-auth-update + сценарии пакетов PARSEC | authselect: профиль + функции | вручную, файлы пакета `pambase` |
| Блокировка по умолчанию | нет | `pam_faillock deny=8`, `/etc/users.blocked` | функция `with-faillock` | `pam_faillock` в `system-auth` |
| Качество пароля | нет (`obscure`) | `pam_pwquality` + хеш ГОСТ | `pam_pwquality` | нет |
| Служба `other` | `@include common-*` | `@include common-*` | `pam_deny` | `pam_deny` + `pam_warn` |

</div>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод по разделу:</b> дистрибутивы различаются не семантикой стека, а соглашениями –
где лежит общая политика и кто её генерирует. Те же четыре типа, флаги и прыжки.
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Перед правкой:</b> найти генератор (pam-auth-update, authselect) – иначе правка будет перезаписана.
<b>Перед аудитом:</b> развернуть граф включений службы до последнего файла.
</div>
</div>

<Refs ids="pam-sag man-pam-auth-update authselect archwiki-pam astra-redbook" />

<!--
Сводка раздела. Четыре колонки – четыре соглашения, но библиотека одна и
семантика стека одна: типы, флаги, прыжки, include. Различия – в том, где лежит
общая политика, кто её генерирует и что включено по умолчанию: Ubuntu
поставляется без блокировки и проверки качества, Astra и Arch – с блокировкой,
RHEL – с pam_pwquality и функциями authselect. Два практических правила:
перед правкой найти генератор, иначе изменения исчезнут при следующей
пересборке; перед аудитом развернуть граф включений до конца. Дальше по
программе – сами модули, из которых эти стеки состоят.
-->

---
layout: section
---

# 4. Распространённые модули PAM

<SectionTOC prefix="4" :current="1" :items="[
  'Обзор модулей по назначению',
  'Предоставляемые типы: функции <code>pam_sm_*</code>',
  'Аргументы модулей',
]" />

---

# Модули проверки и управления доступом

<div class="t-table text-xs mt-1">

| Модуль | Назначение | Типы | В лекции |
|---|---|---|---|
| <Man p="pam_unix(8)" /> | пароль, срок действия, смена пароля, запись сеанса – по `/etc/passwd` и `/etc/shadow` | все четыре | 3, 6 |
| `pam_sss` | учётные записи и пароли домена через SSSD (LDAP, Kerberos, FreeIPA, AD) | все четыре | – |
| <Man p="pam_deny(8)" />, <Man p="pam_permit(8)" /> | безусловный отказ и безусловный успех – «замыкают» стек | все четыре | 2.4, 3 |
| <Man p="pam_faillock(8)" /> | счётчик неудачных попыток и временная блокировка | auth, account | 6 |
| <Man p="pam_nologin(8)" /> | при наличии `/etc/nologin` вход разрешён только root | auth, account | 5.1 |
| <Man p="pam_securetty(8)" /> | вход root только с терминалов, перечисленных в `/etc/securetty` | auth | 4.2 |
| <Man p="pam_wheel(8)" /> | `su` только членам группы `wheel` (`sudo`) | auth, account | – |
| <Man p="pam_access(8)" /> | политика по пользователю, группе, хосту и терминалу: `access.conf` | все четыре | 5.2 |
| <Man p="pam_listfile(8)" /> | разрешить или запретить по списку из файла | все четыре | 5.2, 3.5 |
| <Man p="pam_time(8)" /> | ограничение по времени суток и дням недели: `time.conf` | account | 5.3 |
| <Man p="pam_succeed_if(8)" /> | условие на атрибуты пользователя – ветвление стека прыжками | все четыре | 2.5, 3 |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Модули проверки (<code>pam_unix</code>, <code>pam_sss</code>) отвечают «тот ли это пользователь», модули политики
(<code>pam_access</code>, <code>pam_time</code>, <code>pam_faillock</code>…) – «можно ли ему сейчас»: типы auth и account в действии.
</div>

<Refs ids="pam-sag man-pam-unix sssd man-pam-faillock man-pam-access man-pam-securetty" />

<style>
.t-table { font-size: 0.72rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Обзор модулей начинаем с тех, что решают, пускать или нет. Первая группа –
источники учётных данных: pam_unix для локальных файлов и pam_sss для домена;
обе реализуют все четыре типа. Вторая – «замыкающие» pam_deny и pam_permit.
Третья – модули политики: блокировка, nologin, securetty, wheel, access, time,
listfile, succeed_if – почти все мы увидим в работе в разделе 5. Столбец
«Типы» – по man-страницам Linux-PAM 1.7.0; как проверить его самостоятельно,
покажем в разделе 4.2.
-->

---

# Модули сеанса, смены пароля и служебные

<div class="t-table text-xs mt-1">

| Модуль | Назначение | Типы | В лекции |
|---|---|---|---|
| <Man p="pam_env(8)" /> | переменные окружения из `/etc/environment`, `pam_env.conf` | auth, session | 3 |
| <Man p="pam_limits(8)" /> | лимиты ресурсов сеанса: `limits.conf` | session | 5.4 |
| <Man p="pam_systemd(8)" /> | регистрация сеанса в systemd-logind | session | 3 |
| <Man p="pam_mkhomedir(8)" /> | создать отсутствующий домашний каталог (доменные пользователи) | session | – |
| <Man p="pam_keyinit(8)" />, <Man p="pam_loginuid(8)" /> | связка ключей ядра для сеанса; auid для подсистемы аудита | session | 3 |
| <Man p="pam_umask(8)" />, <Man p="pam_motd(8)" /> | маска прав новых файлов; сообщение дня | session | 3 |
| <DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" /> | качество нового пароля: длина, классы символов, словарь | password | 6 |
| <Man p="pam_pwhistory(8)" /> | запрет повторного использования прежних паролей | password | 6 |
| <Man p="pam_exec(8)" /> | запуск внешней программы на любом этапе | все четыре | 3.5 |
| <Man p="pam_warn(8)" /> | запись в журнал сведений о вызове: служба, пользователь, хост | все четыре | 2.2, 3.4 |
| <Man p="pam_faildelay(8)" /> | задержка после неудачной попытки | auth | 3 |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Таблица – ориентир, а не спецификация.</b> Модуль не обязан поддерживать все типы, а одноимённые
модули разных версий Linux-PAM различаются (<code>pam_tally2</code> → <code>pam_faillock</code>,
<code>pam_lastlog</code> → <code>pam_lastlog2</code>). Решают локальная man-страница и сам файл <code>.so</code> – раздел 4.2.
</div>

<Refs ids="pam-sag man-pam-env man-pam-limits man-pam-systemd man-pam-pwquality man-pam-pwhistory" />

<style>
.t-table { font-size: 0.72rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Вторая половина обзора – модули, которые ничего не решают, а обустраивают
сеанс или участвуют в смене пароля. Стек session: окружение, лимиты,
регистрация в logind, домашний каталог, связка ключей, auid, umask, motd.
Стек password: pam_pwquality и pam_pwhistory – раздел 6. Служебные: pam_exec
(видели в Astra), pam_warn (видели в other Arch), pam_faildelay. Предупреждение
внизу – мост к разделу 4.2: таблица составлена по документации 1.7.0, а в
другой системе модуль может называться иначе или поддерживать другие типы.
pam_tally2 удалён в Linux-PAM 1.5, pam_lastlog объявлен устаревшим.
-->

---
layout: section
---

# 4. Распространённые модули PAM

<SectionTOC prefix="4" :current="2" :items="[
  'Обзор модулей по назначению',
  'Предоставляемые типы: функции <code>pam_sm_*</code>',
  'Аргументы модулей',
]" />

---

# Типы модуля видны по его символам pam_sm_*

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/16-module-args.txt" section="Символы" title="Ubuntu Server 26.04 · экспортируемые функции pam_securetty" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="20" :span="19" :rows="3" :n="1" />
</TerminalCapture>

<TerminalCapture src="captures/16-module-args.txt" section="Какие типы" title="Ubuntu Server 26.04 · функции pam_sm_* по модулям" fontSize="0.47rem" class="mt-2">
  <TCallout :line="8" :col="17" :span="9" :n="2" />
  <TCallout :line="9" :col="17" :span="26" :n="3" />
  <TCallout :line="10" :col="17" :span="9" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="t-table text-xs">

| Тип правила | Функции модуля |
|---|---|
| auth | `pam_sm_authenticate`, `pam_sm_setcred` |
| account | `pam_sm_acct_mgmt` |
| password | `pam_sm_chauthtok` |
| session | `pam_sm_open_session`, `pam_sm_close_session` |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> <Man p="pam_securetty(8)" /> экспортирует функции auth (и account), но не session</div>
<div><span class="co-ball">2</span> <Man p="pam_time(8)" /> – только account</div>
<div><span class="co-ball">3</span> <Man p="pam_limits(8)" /> – только session</div>
<div><span class="co-ball">4</span> <Man p="pam_pwhistory(8)" /> – только password</div>
</div>
</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Модуль – разделяемая библиотека с функциями стандартных имён (раздел 9); libpam ищет
нужную по имени типа через <Man p="dlsym(3)" /> ещё при загрузке конфигурации (раздел 10).
</div>

<Refs ids="pam-mwg man-pam-sm-authenticate man-pam-securetty linux-pam-src" />

<!--
Как проверить утверждение «модуль поддерживает такие-то типы», не доверяя
таблице? Посмотреть экспортируемые символы: nm -D показывает функции
pam_sm_*, а соответствие функций типам фиксировано интерфейсом модуля.
pam_securetty экспортирует authenticate, setcred и acct_mgmt – но не
open/close_session; pam_time – только acct_mgmt; pam_limits – только сеанс;
pam_pwhistory – только chauthtok. Любопытно: man-страница pam_securetty
говорит «только auth», а символ acct_mgmt в библиотеке есть – ещё один довод
проверять по месту. Что произойдёт, если написать правило типа, которого
модуль не предоставляет, – следующий слайд.
-->

---

# Правило с неподдерживаемым типом: PAM_MODULE_UNKNOWN

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/16-module-args.txt" section="не предоставляет" title="Ubuntu Server 26.04 · pam_securetty в стеке session" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="2" :col="1" :span="7" :n="1" />
  <TCallout :line="4" :col="12" :span="17" :n="2" />
  <TCallout :line="6" :col="29" :span="45" :n="3" />
</TerminalCapture>

<TerminalCapture src="captures/16-module-args.txt" section="module_unknown" title="Ubuntu Server 26.04 · module_unknown=ignore" fontSize="0.47rem" class="mt-2">
  <TCallout :line="2" :col="21" :span="21" :n="4" />
  <TCallout :line="4" :col="12" :span="17" :n="5" />
  <TCallout :line="8" :col="25" :span="13" :n="6" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> правило session для модуля, у которого нет функций сеанса</div>
<div><span class="co-ball">2</span> результат правила – код <code>PAM_MODULE_UNKNOWN</code>; с <code>required</code> стек неуспешен</div>
<div><span class="co-ball">3</span> libpam сообщает об этом в журнал ещё при загрузке конфигурации, а не при вызове</div>
<div><span class="co-ball">4</span> <code>module_unknown=ignore</code> пропускает правило – так Ubuntu защищает <code>pam_selinux</code> в <code>login</code> и <code>sshd</code> (раздел 3.2)</div>
<div><span class="co-ball">5</span> но стек из одних пропущенных правил <b>не имеет результата</b> – libpam отвечает отказом</div>
<div><span class="co-ball">6</span> <code>pam_permit</code> даёт стеку результат – ради этого Debian завершает каждый <code>common-*</code> строкой <code>pam_permit</code> (раздел 3.1)</div>
</div>
</div>
</div>

<SrcRef>См. <code>demos/00-module-args.sh</code>.</SrcRef>

<Refs ids="man-pam-conf man-pam-rootok linux-pam-src" />

<!--
Эксперимент на pamtester. Правило session для pam_securetty: при загрузке
конфигурации libpam не находит pam_sm_open_session и пишет об этом в журнал;
при вызове правило даёт PAM_MODULE_UNKNOWN, с required стек проваливается –
pamtester печатает «Module is unknown». Действие module_unknown=ignore
пропускает правило – но тогда стек не содержит ни одного результата, и libpam
отвечает отказом: пустой результат – не успех. Отсюда загадочная строка
pam_permit в конце каждого common-* Debian («prime the stack») и
module_unknown=ignore у pam_selinux в Ubuntu: модуль может отсутствовать.
Общий принцип fail-closed: неизвестно – значит отказ.
-->

---
layout: section
---

# 4. Распространённые модули PAM

<SectionTOC prefix="4" :current="3" :items="[
  'Обзор модулей по назначению',
  'Предоставляемые типы: функции <code>pam_sm_*</code>',
  'Аргументы модулей',
]" />

---

# Аргументы модулей: соглашения вместо словаря

Поля после имени модуля libpam передаёт модулю как `argv`, не разбирая; общего словаря нет, но многие модули следуют **соглашениям**:

<div class="t-table text-xs mt-1">

| Аргумент | Соглашение | Где определён |
|---|---|---|
| `debug` | подробные сообщения в журнал (syslog) | почти все модули |
| `quiet`, `silent` | не печатать сообщения пользователю | `pam_succeed_if`, `pam_faillock`, `pam_lastlog`… |
| `try_first_pass` | взять пароль, уже введённый в стеке; если его нет – спросить | `pam_unix`, `pam_sss`, `pam_pwquality`… |
| `use_first_pass` | только ранее введённый пароль; если его нет – отказ без запроса | те же |
| `use_authtok` | стек password: новый пароль, уже проверенный предыдущим модулем | `pam_unix`, `pam_pwhistory` |
| `nullok` | разрешить пустой пароль | `pam_unix` |
| `retry=N`, `minlen=N`, `deny=N`… | числовые параметры политики | `pam_pwquality`, `pam_faillock` |
| файл настроек | имя своё у каждого: `conf=` (`pam_faillock`, `pam_limits`), `accessfile=` (`pam_access`), `conffile=` (`pam_env`) | |

</div>

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Два токена:</b> <code>PAM_AUTHTOK</code> – текущий пароль (в стеке password – новый),
<code>PAM_OLDAUTHTOK</code> – прежний при смене. Модули обмениваются ими через элементы транзакции
(<Man p="pam_get_item(3)" />): <code>pam_pwquality</code> проверяет, а <code>pam_unix</code> хеширует один и тот же пароль.
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Аргумент значим только там, где документирован: <code>nullok</code> у <code>pam_pwquality</code> или
<code>minlen</code> у <code>pam_unix</code> – не ошибка синтаксиса, а проигнорированное слово.
Сверяйтесь с man-страницей <b>установленной</b> версии модуля.
</div>
</div>

<Refs ids="man-pam-conf man-pam-unix man-pam-get-authtok pam-sag" />

<style>
.t-table { font-size: 0.66rem !important; }
.t-table td, .t-table th { padding-top: 0.18em !important; padding-bottom: 0.18em !important; }
</style>

<!--
Четвёртое поле правила – аргументы модуля. libpam передаёт их модулю как есть;
никакого общего языка нет, но за тридцать лет сложились соглашения: debug,
quiet, семейство first_pass и use_authtok для передачи пароля по стеку,
nullok, числовые параметры политики. Даже имя параметра «файл настроек» у
каждого модуля своё. Карточка про два токена объясняет, как пароль «ходит» по
стеку: модули кладут его в элемент транзакции PAM_AUTHTOK и берут оттуда –
отсюда одна подсказка «Пароль:» на три модуля. Предупреждение справа: опечатка
или чужой аргумент – не синтаксическая ошибка, модуль его просто не поймёт.
-->

---

# Первый пароль в стеке: pam_get_authtok

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/pam_get_authtok-first.c" lang="c" title="libpam/pam_get_authtok.c" tag="v1.7.0" fontSize="0.47rem" class="!mt-0">
  <TCallout :line="6" :col="3" :span="48" :n="1" />
  <TCallout :line="11" :col="12" :span="35" :n="2" />
  <TCallout :line="19" :col="13" :span="20" :n="3" />
</CodeSnippet>

</div>
<div>

<TerminalCapture src="captures/16-module-args.txt" section="use_first_pass" title="Ubuntu Server 26.04 · два pam_unix, use_first_pass, try_first_pass" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="5" :col="1" :span="9" :n="4" />
  <TCallout :line="11" :col="12" :span="22" :n="5" />
  <TCallout :line="18" :col="1" :span="9" :n="6" />
</TerminalCapture>

</div>
</div>

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> заполненный <code>PAM_AUTHTOK</code> возвращается сразу – <b>повторный запрос не нужен</b>;
<span class="co-ball">2</span> <code>use_first_pass</code> запрещает спрашивать: при пустом элементе – <span class="co-ball">3</span> <code>PAM_AUTH_ERR</code>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">4</span> два <code>pam_unix</code> подряд – одна подсказка: в 1.7 поведение <code>try_first_pass</code> у pam_unix – умолчание;
<span class="co-ball">5</span> <code>use_first_pass</code> первым в стеке – отказ без вопроса; <span class="co-ball">6</span> <code>try_first_pass</code> первым – обычный диалог
</div>
</div>

<SrcRef>См. <code>demos/00-module-args.sh</code>; <code>pam_unix_auth.c:153</code> вызывает <code>pam_get_authtok</code>.</SrcRef>

<Refs ids="man-pam-get-authtok man-pam-unix linux-pam-src" />

<!--
Механика «первого пароля» в коде. Модули Linux-PAM получают пароль через
библиотечную функцию pam_get_authtok: если элемент PAM_AUTHTOK уже заполнен
предыдущим модулем, она возвращает его без диалога; если пуст – спрашивает
пользователя, кроме случая use_first_pass, когда возвращается ошибка.
Поэтому в 1.7.0 два pam_unix подряд задают один вопрос даже без try_first_pass
– аргумент сохранён для совместимости и для модулей с иной реализацией.
Эксперимент справа: use_first_pass первым в стеке – отказ без подсказки, в
журнале «could not identify password»; try_first_pass – обычный диалог.
Практический вывод: порядок модулей в стеке определяет, кто спрашивает пароль.
-->

---

# nullok, незнакомый аргумент и debug на практике

<div class="grid grid-cols-2 gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/16-module-args.txt" section="nullok" title="Ubuntu Server 26.04 · пустой пароль" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="2" :col="7" :span="2" :n="1" />
  <TCallout :line="7" :col="12" :span="22" :n="2" />
  <TCallout :line="12" :col="37" :span="6" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/16-module-args.txt" section="Неизвестный" title="Ubuntu Server 26.04 · foo=bar и debug" fontSize="0.45rem" class="!mt-0">
  <TCallout :line="7" :col="48" :span="29" :n="4" />
  <TCallout :line="15" :col="48" :span="23" :n="5" />
</TerminalCapture>

</div>
</div>

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>NP</code> – у alice нет пароля (<Man p="passwd(1)" />)</div>
<div><span class="co-ball">2</span> без <code>nullok</code> пустой пароль отвергается – в журнале обычная «authentication failure»</div>
<div><span class="co-ball">3</span> с <code>nullok</code> вход без вопроса; в <code>common-auth</code> Ubuntu этот аргумент стоит по умолчанию (раздел 3.1)</div>
</div>
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<div class="space-y-1.5">
<div><span class="co-ball">4</span> незнакомый аргумент не ломает стек: модуль пишет предупреждение и работает дальше – опечатка в <code>nullok</code> останется незамеченной без чтения журнала</div>
<div><span class="co-ball">5</span> <code>debug</code> добавляет строки о ходе проверки – первое средство при отладке стека</div>
</div>
</div>
</div>

<SrcRef>См. <code>demos/00-module-args.sh</code>.</SrcRef>

<Refs ids="man-pam-unix man-pam-conf" />

<!--
Три аргумента pam_unix в деле. nullok: учётная запись без пароля (NP в
passwd -S) без аргумента отвергается, с ним – успех без вопроса; напомним,
что Ubuntu держит nullok в common-auth по умолчанию, а на серверах его убирают.
Незнакомый аргумент: модуль лишь предупреждает в журнале и продолжает –
значит, опечатка в имени аргумента не остановит вход, но и не включит то, что
вы хотели; после любой правки стека читайте журнал. debug – дополнительные
строки о ходе проверки. На этом с устройством и словарём PAM закончено;
дальше – административные задачи на живой системе.
-->

---
layout: section
---

# 5. Административные задачи

<SectionTOC prefix="5" :current="1" :items="[
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
<div><span class="co-ball">1</span> <Man p="pam_nologin(8)" /> уже подключён в <code>login</code> и <code>sshd</code> – настройка не нужна</div>
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

<SrcRef>
См. <code>demos/01-nologin.sh</code>. Файл сообщения можно заменить аргументом
<code>file=</code>; вариант ядра systemd – <code>/run/nologin</code> при останове.
</SrcRef>

<!--
Первая административная задача из введения: закрыть систему на обслуживание.
pam_nologin уже стоит в login (auth requisite) и sshd (account required) –
администратору достаточно создать /etc/nologin с текстом сообщения. bob после
верного пароля получает сообщение и разрыв соединения, root – то же сообщение,
но вход продолжается: исключение для root зашито в модуль. Удалили файл –
система открыта. Обратить внимание: это соответствует примеру 1 из PAM.pptx;
сообщение «You shall not pass!» – оттуда же.
-->

---
layout: section
---

# 5. Административные задачи

<SectionTOC prefix="5" :current="2" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 02: запрет входа пользователю – pam_access

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
<div><span class="co-ball">1</span> правило в <code>/etc/security/access.conf</code>: <code>-:bob:ALL</code> – запретить <code>bob</code> с любых источников (<Man p="pam_access(8)" />)</div>
<div><span class="co-ball">2</span> модуль подключается в стек <b>account</b> службы <code>sshd</code>; в файле Ubuntu уже есть закомментированная строка-образец</div>
<div><span class="co-ball">3</span> пароль <code>bob</code> принят, но account-стек закрывает сеанс</div>
<div><span class="co-ball">4</span> остальных пользователей правило не касается</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Формат правила: <code>разрешение : пользователи : источники</code> –
источником может быть терминал, хост, сеть; так ограничивают,
<b>откуда</b> можно входить от имени учётной записи.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/02-access-listfile.sh</code>.
</SrcRef>

<!--
Вторая задача: запретить вход конкретному пользователю, не трогая его учётную
запись. pam_access читает access.conf: правило «минус, bob, ALL» запрещает bob
доступ с любых источников. Модуль ставим в account-стек sshd – Ubuntu даже
держит в файле закомментированный образец строки. Проверка: пароль принят,
сеанс закрыт; alice входит как обычно. Поле источников позволяет точнее:
запретить root вход не с консоли, разрешить группе вход только из локальной
сети и т. п.
-->

---

# Демо 02: запрет по произвольному списку – pam_listfile

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
<div><span class="co-ball">1</span> список – обычный текстовый файл: по одному имени в строке</div>
<div><span class="co-ball">2</span> аргументы: <code>item=user</code> – что сравнивать; <code>sense=deny</code> – список запрещающий; <code>onerr=fail</code> – ошибка чтения списка трактуется как отказ</div>
<div><span class="co-ball">3</span> правило стоит в стеке <b>auth</b> с <code>requisite</code> – отказ ещё <b>до</b> проверки пароля</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Сравните:</b> <Man p="pam_access(8)" /> отказал <b>после</b> верного пароля
(account), <Man p="pam_listfile(8)" /> – <b>до</b> (auth): клиент видит обычное
«Permission denied», как при неверном пароле. <code>item=</code> принимает
также <code>group</code>, <code>tty</code>, <code>rhost</code>, <code>shell</code>.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/02-access-listfile.sh</code>. <code>sense=allow</code> превращает
список в разрешающий – используем в разделе 8.
</SrcRef>

<!--
Тот же запрет другим модулем – pam_listfile, универсальная проверка по списку.
Файл со списком – произвольный, аргументами задаём: что сравнивать (item=user),
смысл списка (sense=deny) и поведение при ошибке чтения (onerr=fail – отказ,
важный выбор по умолчанию в сторону запрета). Поставили в auth с requisite –
отказ происходит до проверки пароля, снаружи неотличим от неверного пароля:
перебор не позволяет даже выяснить, что учётная запись заблокирована. Сравнение
двух модулей показывает выбор стека как инструмент: account – после пароля,
auth – до.
-->

---
layout: section
---

# 5. Административные задачи

<SectionTOC prefix="5" :current="3" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 03: вход по расписанию – pam_time

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
<div><span class="co-ball">1</span> правило в <code>/etc/security/time.conf</code>: <code>службы;терминалы;пользователи;время</code>; <code>!Al0000-2400</code> – «кроме всех дней круглосуточно», то есть <b>никогда</b> (<Man p="pam_time(8)" />)</div>
<div><span class="co-ball">2</span> модуль – в стек <b>account</b>: решение «можно ли сейчас» принимается после проверки пароля</div>
<div><span class="co-ball">3</span> вход <code>bob</code> по ssh закрыт в любое время; остальные службы и пользователи не затронуты</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Реалистичное правило: <code>sshd;*;bob;Wk0800-1800</code> – вход по ssh
только в рабочие дни с 8 до 18; синтаксис времён: <code>Wk</code> будни,
<code>Wd</code> выходные, <code>Al</code> все дни, диапазоны объединяются
<code>|</code> и <code>&amp;</code>.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/03-time.sh</code>.
</SrcRef>

<!--
Третья задача – ограничение входа по времени. time.conf: четыре поля через
точку с запятой – службы, терминалы, пользователи, интервалы времени.
Для демонстрации используем «запрет всегда»: восклицательный знак – отрицание,
Al0000-2400 – все дни круглосуточно. Модуль снова в account – та же точка, что
pam_access. Реалистичный вариант – ограничение рабочими часами; к root
применять осторожно: правило *;*;root;Wd... из PAM.pptx лишит администратора
входа в выходные – сначала проверяйте на тестовой машине.
-->

---
layout: section
---

# 5. Административные задачи

<SectionTOC prefix="5" :current="4" :items="[
  'Запрет входа всем: <code>pam_nologin</code>',
  'Запрет по спискам: <code>pam_access</code> и <code>pam_listfile</code>',
  'Ограничение по времени: <code>pam_time</code>',
  'Лимиты ресурсов: <code>pam_limits</code>',
]" />

---

# Демо 04: лимиты ресурсов сеанса – pam_limits

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
<div><span class="co-ball">2</span> <code>pam_limits</code> уже стоит в session-стеке <code>sshd</code> – лимит применяется при открытии сеанса</div>
<div><span class="co-ball">3</span> <code>ulimit -f</code> подтверждает: 1024</div>
<div><span class="co-ball">4</span> запись файла больше лимита убивает процесс сигналом <code>SIGXFSZ</code></div>
<div><span class="co-ball">5</span> файл обрезан ровно на 1 МБ (1 048 576 байт)</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> стек session – место «обустройства» сеанса: лимиты наследуются
всеми процессами пользователя. Так ограничивают и число процессов
(<code>nproc</code>), открытых файлов (<code>nofile</code>), память – защита
от исчерпания ресурсов.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/04-limits.sh</code>. Лимиты действуют и на root
(<Man p="pam_limits(8)" />); мягкие (<code>soft</code>) пользователь может
поднимать до жёстких (<code>hard</code>).
</SrcRef>

<!--
Последняя задача раздела – лимиты ресурсов, пример работы session-стека.
Правило в limits.conf: домен (пользователь, группа или *), тип (hard/soft),
ресурс, значение; у нас – жёсткий лимит размера создаваемого файла 1024 КБ.
pam_limits уже стоит в session-стеке sshd и login. В сеансе bob: ulimit -f
показывает лимит; маленький файл создаётся, попытка записать 2 МБ убивает dd
сигналом SIGXFSZ, файл обрезан ровно на мегабайте. Лимиты – не только fsize:
nproc защищает от fork-бомбы, nofile – от исчерпания дескрипторов. Соответствует
примеру 4 из PAM.pptx (там python; здесь dd – тот же эффект).
-->

---
layout: section
---

# 6. Парольная политика
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
<div><span class="co-ball">1</span> ставим пакет <code>libpam-pwquality</code> – модуль проверки качества паролей</div>
<div><span class="co-ball">2</span> строка <code>pam_pwquality.so retry=3</code> появилась в <code>common-password</code> <b>сама</b>: пакет принёс профиль для <code>pam-auth-update</code> (раздел 3.1)</div>
<div><span class="co-ball">3</span> у <Man p="pam_unix(8)" /> добавились <code>use_authtok try_first_pass</code>: пароль, уже запрошенный и проверенный <DebianMan p="pam_pwquality(8)" pkg="libpam-pwquality" />, передаётся дальше по стеку – пользователя не спрашивают дважды</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Модуль вставлен <b>перед</b> <code>pam_unix</code> с флагом <code>requisite</code>:
слабый пароль отклоняется до того, как <code>pam_unix</code> начнёт смену.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/05-password-policy.sh</code>.
</SrcRef>

<!--
Переходим к парольной политике – главной практической теме. Установка пакета
libpam-pwquality демонстрирует механизм pam-auth-update вживую: строка модуля
появляется в common-password автоматически, причём в правильном месте – перед
pam_unix, с requisite. Заодно у pam_unix появились use_authtok и
try_first_pass – конвенция передачи пароля по стеку: запрашивает и проверяет
качество pwquality, а pam_unix берёт уже готовый токен; пользователь вводит
новый пароль один раз (плюс подтверждение).
-->

---

# Параметры pam_pwquality

Два способа настройки: **аргументы модуля** в строке правила – или центральный файл
`/etc/security/pwquality.conf`; **аргументы имеют приоритет**
(<Man p="pam_pwquality(8)" href="https://manpages.ubuntu.com/manpages/noble/en/man8/pam_pwquality.8.html" />).

<div class="t-table text-xs mt-2">

| Параметр | Что проверяет |
|---|---|
| `minlen=N` | минимальная длина пароля (по умолчанию 8, с учётом «кредитов» классов) |
| `minclass=N` | минимум **классов** символов: строчные, прописные, цифры, прочие |
| `dcredit` / `ucredit` / `lcredit` / `ocredit` | отрицательное значение – «не менее N» цифр / прописных / строчных / прочих символов |
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
длина ≥ 12 – <code>minlen=12</code>; алфавит ≥ 70 символов – все четыре
класса (26+26+10+спецсимволы): четыре «кредита» по −1.
</div>
</div>

</v-click>

<Refs ids="man-pam-pwquality fstec-md2026" />

<!--
Параметры модуля. Семейство «кредитов»: отрицательное значение – жёсткое
требование «не менее N символов класса»; положительные значения дают скидку к
minlen – отсюда оговорка «с учётом кредитов». dictcheck и usercheck включены по
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
<b>Читаем демонстрацию</b> (ввод пароля не отображается – значения в комментарии):
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>1234567890</code>: длина достаточна, но нет прописных – отклонён; модуль называет <b>первую</b> непройденную проверку</div>
<div><span class="co-ball">2</span> <code>ABcd%^yuio</code>: нет двух цифр – отклонён</div>
<div><span class="co-ball">3</span> <code>AAbb##44</code>: все классы есть, но короче 10 – отклонён</div>
<div><span class="co-ball">4</span> <code>ABcd%^7890</code>: удовлетворяет всем правилам – принят</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> мы не меняли ни <code>passwd</code>, ни <code>login</code>,
ни <code>sshd</code> – политика настроена один раз в <code>common-password</code>
и действует на любую смену пароля в системе.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/05-password-policy.sh</code>; последовательность паролей –
из методички (PAM.pptx, пример 5).
</SrcRef>

<!--
Диалог passwd под настроенной политикой. Шесть попыток по порядку: каждая
отклонённая нарушает ровно одно правило, и pwquality сообщает о первой
непройденной проверке – удобно вести аудиторию по правилам. Последний пароль
удовлетворяет всем требованиям и принят. Подчеркнуть вывод: политика живёт в
common-password и действует на passwd, chpasswd, смену пароля по ssh – всё, что
использует стек password.
-->

---

# Демо 05: pam_pwhistory – история паролей

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
<div><span class="co-ball">1</span> <code>pam_pwhistory remember=3</code> – хранить три последних пароля; строка вставлена перед <Man p="pam_unix(8)" /> (<Man p="pam_pwhistory(8)" />)</div>
<div><span class="co-ball">2</span> попытка вернуть прежний пароль отклонена: «Password has been already used»</div>
<div><span class="co-ball">3</span> хеши старых паролей – в <code>/etc/security/opasswd</code> (0600, root)</div>
</div>
</div>
</div>

<SrcRef>
См. <code>demos/05-password-policy.sh</code>.
</SrcRef>

<!--
Второй модуль политики – pam_pwhistory, запрет повторного использования.
Вставляется между pwquality и pam_unix, remember=3 – глубина истории. Смена на
новый пароль проходит, попытка вернуть прежний – отклоняется. Хранилище –
/etc/security/opasswd: хеши старых паролей, права 0600; компрометация файла
даёт материал для перебора старых паролей пользователя, которые люди любят
переиспользовать в других местах, – защищать как shadow.
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
<div><span class="co-ball">1</span> параметры – в <code>/etc/security/faillock.conf</code>: 5 неудач → блокировка на 900 с (<Man p="pam_faillock(8)" />) – защита от подбора пароля (<MitreAttack t="T1110.001" />)</div>
<div><span class="co-ball">2</span> <code>preauth</code> – <b>до</b> <Man p="pam_unix(8)" />: не заблокирован ли пользователь уже</div>
<div><span class="co-ball">3</span> прыжок <code>pam_unix</code> вырос: <code>success=2</code> – верный пароль перепрыгивает <b>и</b> <code>authfail</code>, <b>и</b> <Man p="pam_deny(8)" /></div>
<div><span class="co-ball">4</span> <code>authfail</code> – <b>после</b>: записать неудачную попытку</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Ловушка:</b> вставив строку в стек, <b>пересчитайте прыжки</b>: со старым
<code>success=1</code> верный пароль упирался бы в <code>pam_deny</code> –
не вошёл бы ни один пользователь.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/06-faillock.sh</code>. Строка <code>authsucc</code> обнуляет
счётчик после успешного входа.
</SrcRef>

<Refs ids="man-pam-faillock" />

<!--
Защита от перебора – pam_faillock. Параметры держим в faillock.conf (сам модуль
рекомендует не задавать их аргументами). Встраивание в common-auth: preauth до
pam_unix проверяет, не заблокирован ли пользователь; authfail после – фиксирует
неудачу; authsucc в конце обнуляет счётчик при успехе. Критическая деталь –
пересчёт прыжка pam_unix с success=1 на success=2: иначе верный пароль попадает
на pam_deny, и вход ломается для всех. Это лучшая иллюстрация тезиса «порядок
строк и прыжки – часть семантики стека».
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
<div><span class="co-ball">1</span> пять неудач – пять одинаковых «Permission denied»: модуль ничего не рассказывает атакующему</div>
<div><span class="co-ball">2</span> шестая попытка – с <b>верным</b> паролем: «The account is locked due to 5 failed logins» – блокировка остановила перебор</div>
<div><span class="co-ball">3</span> администратор видит журнал попыток: <code>faillock --user bob</code>; сброс – <code>--reset</code></div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> верный пароль во время блокировки <b>не помогает</b> – именно это
обесценивает перебор. root по умолчанию не блокируется: иначе атакующий мог бы
намеренно «запереть» администратора (отказ в обслуживании).
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/06-faillock.sh</code>. Счётчики – файлы в <code>/var/run/faillock/</code>,
сбрасываются перезагрузкой.
</SrcRef>

<!--
Блокировка в действии: пять попыток su с неверным паролем – одинаковые ответы;
затем попытка с верным паролем отклоняется с сообщением о блокировке и временем
до разблокировки. Именно невозможность войти с верным паролем останавливает
перебор. Администратор смотрит счётчик faillock --user и сбрасывает --reset.
Умолчание «root не блокируется» – защита от отказа в обслуживании: атакующий не
должен уметь запереть администратора; even_deny_root включает блокировку и для
root. Вместе pwquality + pwhistory + faillock + chage (лекция 2) покрывают
парольную политику ФСТЭК целиком.
-->

---
layout: section
---

# 7. Двухфакторная аутентификация
## Одноразовые коды TOTP и аппаратные ключи

---

# Факторы аутентификации и одноразовые коды

**Фактор** – независимое подтверждение подлинности: **знание** (пароль),
**владение** (устройство, ключ), **биометрия**. Двухфакторная аутентификация (2FA)
требует подтверждений из **двух разных** категорий.

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-3 items-start">
<div>

<div class="t-table text-xs">

| Механизм | Модуль PAM | Фактор владения |
|---|---|---|
| TOTP (<Rfc n="6238" />): код из приложения | `pam_google_authenticator` | смартфон с общим секретом |
| HOTP (<Rfc n="4226" />): код по счётчику | `pam_google_authenticator` (режим `-c`) | токен-генератор |
| FIDO2/U2F: challenge-response | <DebianMan p="pam_u2f(8)" pkg="libpam-u2f" /> | аппаратный USB/NFC-ключ |
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
нескольким службам – ssh, консоль, `su`, графический вход.
Модуль добавляется **строкой в стек auth** нужных служб;
сами программы не меняются (раздел 1).

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Пароль перехвачен или подобран – без второго фактора он бесполезен;
по данным отраслевых отчётов MFA отсекает подавляющую часть атак
на учётные записи с утёкшими паролями.
</div>

</div>
</div>

<Refs ids="rfc-6238 google-authenticator pam-u2f gost-58833" />

<!--
Терминология: фактор – независимое подтверждение подлинности; классы –
знание, владение, биометрия; 2FA – два разных класса. Таблица модулей второго
фактора: TOTP/HOTP из google-authenticator-libpam, FIDO2-ключи через pam_u2f,
смарт-карты. Принцип TOTP: общий секрет и часы; код – усечённый HMAC от номера
30-секундного окна; знание кода доказывает владение устройством. Правая
колонка возвращает к мотивации PAM: второй фактор нужен всем службам сразу –
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
<div><span class="co-ball">1</span> флаги: <code>-t</code> TOTP, <code>-d</code> запрет повтора кода, <code>-r 3 -R 30</code> – не более 3 входов за 30 с, <code>-W</code> – допуск соседних окон</div>
<div><span class="co-ball">2</span> общий секрет; пользователь вносит его в приложение-аутентификатор (QR-код здесь опущен)</div>
<div><span class="co-ball">3</span> резервные (scratch) коды – одноразовые, на случай утраты устройства: хранить отдельно</div>
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

<SrcRef>
См. <code>demos/07-totp-ssh.sh</code>; секрет и коды – из одноразового
демо-контейнера.
</SrcRef>

<!--
Настройка со стороны пользователя: утилита google-authenticator генерирует
секрет, печатает QR-код для приложения (в транскрипте опущен), подтверждает
настройку введённым кодом и выдаёт резервные одноразовые коды. Все данные –
в файле ~/.google_authenticator с правами 400: это и есть материализованный
второй фактор, его компрометация сводит 2FA к одному фактору. Флаги зафиксированы
в сценарии демо; -W разрешает коды из соседних 30-секундных окон – компенсация
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
<div><span class="co-ball">1</span> одна строка после <code>@include common-auth</code>: сначала пароль (<Man p="pam_unix(8)" />), затем код; <code>required</code> – без кода входа нет</div>
<div><span class="co-ball">2</span> <code>KbdInteractiveAuthentication yes</code>: диалог PAM-модулей с пользователем идёт через keyboard-interactive (раздел 3.2)</div>
<div><span class="co-ball">3</span> sshd задаёт второй вопрос – «Verification code:»</div>
<div><span class="co-ball">4</span> неверный код → цикл повторяется; верная пара пароль+код впускает</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> ни sshd, ни ssh-клиент не знают о TOTP – новый фактор добавила
строка конфигурации PAM. Это обещание OSF RFC 86.0 в действии.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/07-totp-ssh.sh</code>. Аргумент <code>nullok</code> у модуля
разрешил бы вход не настроившим TOTP пользователям – этап внедрения.
</SrcRef>

<!--
Подключение: одна строка auth required pam_google_authenticator.so после
common-auth – и ssh спрашивает сначала пароль, затем Verification code.
Обязательное условие – KbdInteractiveAuthentication yes, иначе sshd не умеет
вести диалог PAM с клиентом. Неверный код просто перезапускает цикл вопросов –
снаружи не видно, что именно не подошло. Вывод слайда – центральный тезис
лекции: программы не менялись, фактор добавлен конфигурацией. Для поэтапного
внедрения модулю дают nullok – пользователи без файла секрета входят по одному
паролю, пока не настроят TOTP.
-->

---

# Аппаратный ключ: pam_u2f

Одноразовые коды уязвимы к **фишингу в реальном времени** (<MitreAttack t="T1111" />): код можно выманить
и успеть использовать. Аппаратный ключ FIDO2/U2F решает challenge-response
локально и не выдаёт переносимого секрета.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

**Настройка** (по документации Yubico; в демо-стенде
аппаратного ключа нет):

<TerminalCapture content="$ pamu2fcfg > ~/.config/Yubico/u2f_keys     # регистрация ключа" title="пользователь · регистрация ключа" />

<CodeSnippet code="auth  required  pam_u2f.so  cue [authfile=…]" lang="text" title="/etc/pam.d/&lt;служба&gt;" tag="стек auth" :numbers="false" class="mt-2" />

- проверка – касание ключа (`cue` печатает приглашение);
- `nouserok` – этап внедрения: без зарегистрированного
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
выбор фактора – вопрос модели угроз и стоимости внедрения.
</div>

</div>
</div>

<Refs ids="pam-u2f rfc-6238" />

<!--
Завершение раздела: альтернатива TOTP – аппаратный ключ. Слабость одноразовых
кодов – фишинг в реальном времени: атакующий выманивает код и немедленно его
использует; TOTP от этого не защищает. U2F/FIDO2 выполняет challenge-response:
ключ подписывает запрос, привязанный к серверу, – выманить «ответ заранее»
нельзя, на сервере хранится только открытый ключ. Настройка по документации
Yubico: pamu2fcfg регистрирует ключ, строка pam_u2f.so в стек auth; живой
демонстрации нет – в контейнере нет USB. Сравнительная таблица – по одинаковым
критериям. PAM-сторона обоих решений одинакова – одна строка конфигурации.
-->

---
layout: section
---

# 8. PAM в собственных программах
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
| <Man p="pam_open_session(3)" /> / `pam_close_session` | session | открыть и закрыть сеанс |

</div>

<Refs ids="man-pam3 man-pam-start man-pam-authenticate pam-adg" />

<!--
Интерфейс приложения – шесть основных вызовов вокруг общего контекста.
pam_start создаёт транзакцию: имя службы (= имя файла конфигурации), имя
пользователя (можно NULL – спросят позже), функция диалога. Далее приложение
вызывает стеки: pam_authenticate – auth, pam_acct_mgmt – account, вокруг
сеанса – open/close_session, смена пароля – pam_chauthtok, выдача
удостоверений – pam_setcred. pam_end завершает транзакцию. Полный порядок для
программы входа описан в Application Developers' Guide; нашей программе хватит
authenticate + acct_mgmt.
-->

---

# Порядок вызовов приложения при входе

<div class="grid grid-cols-[1fr_1.1fr] gap-5 items-start">
<div>

<div class="life-chain mt-1">
  <div class="bf-block bf-fill-tint lc-step"><div class="bf-head bf-mono">pam_start(служба, пользователь, диалог)</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-accent lc-step"><div class="bf-head bf-mono">pam_authenticate()</div><div class="bf-sub">стек auth</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-accent lc-step"><div class="bf-head bf-mono">pam_acct_mgmt()</div><div class="bf-sub">стек account</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-tint lc-step lc-opt"><div class="bf-head bf-mono">pam_chauthtok()</div><div class="bf-sub">стек password – если account потребовал сменить пароль</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-tint lc-step"><div class="bf-head bf-mono">pam_setcred(ESTABLISH)</div><div class="bf-sub">стек auth: выдать удостоверения</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-accent lc-step"><div class="bf-head bf-mono">pam_open_session()</div><div class="bf-sub">стек session</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-amber lc-step"><div class="bf-head">приложение выполняет свою работу</div><div class="bf-sub">запускает оболочку, выполняет команду</div></div>
  <div class="lc-arrow"></div>
  <div class="bf-block bf-fill-accent lc-step"><div class="bf-head bf-mono">pam_close_session() · pam_setcred(DELETE) · pam_end()</div></div>
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
Последовательность <b>иллюстративна, а не обязательна</b>: приложение вправе опускать операции,
менять порядок некоторых из них или аутентифицировать пользователя <b>другим протоколом</b>,
обращаясь к PAM только за account и session, – как OpenSSH при входе по ключу.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Каждый вызов исполняет <b>только свой стек</b>: правила auth не исполняются оттого, что открыт
сеанс; стек password вызывается лишь при смене пароля – поэтому четыре стека службы
независимы и работают в разное время.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Код возврата <code>new_authtok_reqd</code> из стека account («пароль истёк») – не отказ: приложение
обязано вызвать <code>pam_chauthtok</code> и лишь затем продолжить вход (<code>login</code>
так и делает; раздел 3.1).
</div>

<div class="opacity-80">
Эту последовательность (без смены пароля) реализует программа <code>authprint</code> далее в разделе.
</div>

</div>
</div>

<Refs ids="man-pam3 man-pam-start man-pam-authenticate man-pam-session pam-adg" />

<style>
.life-chain { display: flex; flex-direction: column; font-size: 0.7rem; text-align: center; }
.life-chain .lc-step { padding: 0.25em 0.5em; }
.life-chain .lc-step .bf-head { font-size: 0.95em; }
.life-chain .lc-opt { border-style: dashed; }
.life-chain .lc-arrow { align-self: center; width: 2px; height: 0.75em; background: #555; position: relative; }
.life-chain .lc-arrow::after { content: ''; position: absolute; bottom: -4px; left: -3px; border: 4px solid transparent; border-top-color: #555; }
</style>

<!--
Как четыре группы складываются во вход в систему. pam_start создаёт транзакцию:
имя службы, имя пользователя, функция диалога. Затем pam_authenticate (стек
auth), pam_acct_mgmt (account); если account вернул new_authtok_reqd – пароль
истёк, – приложение вызывает pam_chauthtok (password) и только потом
продолжает; pam_setcred выдаёт удостоверения (группы, билеты Kerberos);
pam_open_session открывает сеанс; приложение делает свою работу; при выходе –
pam_close_session, снятие удостоверений, pam_end. Три оговорки. Схема
иллюстративна: приложение может пропускать шаги и даже аутентифицировать
другим протоколом, обращаясь к PAM только за account и session, – OpenSSH с
ключом. Каждый вызов исполняет только свой стек – стеки независимы и работают в
разное время. И new_authtok_reqd – пример кода возврата, который не является ни
успехом, ни отказом: он требует от приложения действия. Код этой
последовательности – программа authprint на следующих слайдах.
-->

---

# pam_start: служба, пользователь, диалог

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/pam_appl-start.h" title="security/pam_appl.h" tag="Linux-PAM 1.7.0">
  <TCallout :line="2" :col="11" :span="24" :n="1" />
  <TCallout :line="2" :col="37" :span="16" :n="2" />
  <TCallout :line="3" :col="11" :span="39" :n="3" />
  <TCallout :line="4" :col="11" :span="19" :n="4" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/include/security/pam_appl.h#L22">libpam/include/security/pam_appl.h#L22</a>.
</div>

</div>
<div class="text-xs space-y-1.5">

<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">1</span> <b><code>service_name</code></b> – имя службы: по нему libpam откроет
<code>/etc/pam.d/&lt;имя&gt;</code> (раздел 2.2). Компонент пути запрещён;
имя приводится к нижнему регистру. Нет файла – действует <code>other</code>.
</div>
<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">2</span> <b><code>user</code></b> – кого аутентифицируем; допустим <code>NULL</code> –
тогда модуль запросит имя через диалог (<Man p="pam_get_user(3)" />, раздел 9).
</div>
<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">3</span> <b><code>pam_conversation</code></b> – функция диалога: <b>обратный вызов</b>,
через который модули задают вопросы пользователю (следующий слайд).
</div>
<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">4</span> <b><code>pamh</code></b> – непрозрачный контекст транзакции; передаётся
во все последующие вызовы. <Man p="pam_end(3)" /> получает итоговый статус –
его видят модули при выгрузке.
</div>

</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Выбор <code>service_name</code> – <b>решение безопасности</b>: программа,
назвавшаяся чужой службой, получит её правила. Поэтому имя службы жёстко
задаётся в коде, а не берётся из ввода пользователя.
</div>

</v-click>

<Refs ids="man-pam-start pam-adg" />

<!--
Сигнатуры из pam_start(3). service_name связывает программу с файлом
конфигурации; libpam отрезает компоненты пути и приводит имя к нижнему
регистру – защита от трюков вида "../". user может быть NULL – имя спросит
первый модуль, которому оно понадобится. pam_conversation – указатель на
структуру с функцией обратного вызова; об этом подробнее дальше. pamh –
непрозрачный указатель, созданный pam_start; все функции API принимают его
первым аргументом. Жёлтая карточка: имя службы определяет применяемые правила,
поэтому оно - константа в коде.
-->

---

# Диалог: struct pam_conv

Модуль не читает терминал сам – **вопросы пользователю задаёт приложение**
через функцию диалога (conversation function, <Man p="pam_conv(3)" />):

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/pam_types-conv.h" title="security/_pam_types.h" tag="Linux-PAM 1.7.0" fontSize="0.5rem">
  <TCallout :line="2" :col="5" :span="14" :n="1" />
  <TCallout :line="7" :col="5" :span="11" :n="2" />
  <TCallout :line="14" :col="5" :span="11" :n="3" />
  <TCallout :line="16" :col="5" :span="18" :n="4" />
</CodeSnippet>

<div class="mt-1 text-xs space-y-0.5">
<div><span class="co-ball">1</span> сообщение модуля приложению: тип и текст</div>
<div><span class="co-ball">2</span> ответ приложения – строка, введённая пользователем</div>
<div><span class="co-ball">3</span> функция диалога: массив вопросов → массив ответов</div>
<div><span class="co-ball">4</span> данные приложения, возвращаемые в каждый вызов <code>conv</code></div>
</div>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/include/security/_pam_types.h#L254">libpam/include/security/_pam_types.h#L254</a>.
</div>

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
<Man p="pam_unix(8)" /> спрашивает пароль в консоли (<code>login</code>),
в окне GDM и через сетевой диалог sshd – функцию диалога даёт приложение.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Консольным программам готовую функцию даёт libpam_misc:
<code>misc_conv</code> (<Man p="misc_conv(3)" />) – печать в терминал,
чтение с отключённым эхом для паролей.
</div>

</div>
</div>

<Refs ids="man-pam-conv pam-adg" />

<!--
Ключевая абстракция интерфейса – функция диалога. Модулю нужно спросить пароль,
но он не знает, где работает: в консоли, в графическом окне, по сети. Поэтому
вопросы передаются приложению массивом pam_message, а приложение возвращает
массив pam_response. Четыре типа сообщений: два вопроса (со скрытым и открытым
вводом) и два уведомления. Благодаря этому pam_unix один и тот же в login, GDM
и sshd. Для консольных программ не нужно писать диалог самим – misc_conv из
libpam_misc делает ровно это; им и воспользуемся.
-->

---

# authprint: приложение с парольной защитой

Учебная программа `authprint` печатает строку **только после аутентификации** –
каркас любой «запароленной» операции (аналог проверки в `sudo`):

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/authprint-start.c" title="authprint.c" tag="демо 08" fontSize="0.5rem">
  <TCallout :line="4" :col="31" :span="19" :n="1" />
  <TCallout :line="8" :col="50" :span="11" :n="2" />
  <TCallout :line="14" :col="10" :span="18" :n="3" />
  <TCallout :line="21" :col="10" :span="45" :n="4" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <b>Функция диалога</b> – готовая <Man p="misc_conv(3)" />; второй член
структуры – <code>appdata_ptr</code>, модулям он передаётся обратно
в каждый вызов диалога.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">2</span> <b>Имя службы</b> по умолчанию – <code>authprint</code>; аргумент
командной строки оставлен для учебных экспериментов со службами
(демо 09) – в боевой программе имя фиксировано.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> <b>Кого аутентифицируем:</b> владельца процесса – имя получаем
по реальному UID (<code>getpwuid(getuid())</code>, лекция 2).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">4</span> <Man p="pam_start(3)" /> связывает службу, пользователя и диалог
в контекст <code>pamh</code>; при ошибке – текст через <Man p="pam_strerror(3)" />.
</div>

</div>
</div>

<SrcRef>
Программа целиком – <code>assets/src/authprint.c</code>.
</SrcRef>

<Refs ids="man-pam-start man-pam-conv pam-adg" />

<!--
Первая половина authprint – подготовка. Структура pam_conv со стандартной
misc_conv. Пользователь – владелец процесса: getuid + getpwuid, связь с
идентификаторами из лекции 2. Имя службы по умолчанию authprint; возможность
передать его аргументом – учебная, чтобы в демо 09 прогнать ту же программу
через службу mathtest; в реальных программах служба фиксирована (см.
предупреждение прошлого слайда). Программа соответствует
pam_authenticated_printf из методички, переписана и прокомментирована.
-->

---

# authprint: проверка и завершение

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/authprint-end.c" title="authprint.c" tag="демо 08" fontSize="0.5rem">
  <TCallout :line="2" :col="10" :span="25" :n="1" />
  <TCallout :line="6" :col="14" :span="22" :n="2" />
  <TCallout :line="11" :col="51" :span="22" :n="3" />
  <TCallout :line="14" :col="9" :span="17" :n="4" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <Man p="pam_authenticate(3)" /> исполняет стек auth службы: по умолчанию
(<code>other</code> → <code>common-auth</code>) <Man p="misc_conv(3)" />
спросит пароль, <Man p="pam_unix(8)" /> сверит его с <code>/etc/shadow</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">2</span> <Man p="pam_acct_mgmt(3)" /> – обязательное продолжение: пароль верен,
но не истёк ли он и не закрыт ли доступ (<Man p="pam_time(8)" />,
<Man p="pam_access(8)" />…).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> <code>pam_strerror</code> переводит код возврата в текст
(<Man p="pam_strerror(3)" />). Коды: <code>PAM_SUCCESS</code>,
<code>PAM_AUTH_ERR</code>, <code>PAM_USER_UNKNOWN</code>,
<code>PAM_PERM_DENIED</code>, <code>PAM_ACCT_EXPIRED</code>…
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">4</span> <code>pam_end</code> закрывает транзакцию; итоговый
<code>rc</code> получают модули при выгрузке.
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
Диалог с пользователем – <b>внутри</b> <code>pam_authenticate</code>:
приложение не видит пароль и не управляет числом вопросов –
это определяют модули стека.
</div>

</div>
</div>

<SrcRef>
Программа целиком – <code>assets/src/authprint.c</code>.
</SrcRef>

<Refs ids="man-pam-authenticate man-pam-strerror pam-adg" />

<!--
Вторая половина: два вызова стека и завершение. pam_authenticate запускает стек
auth – только здесь misc_conv получит от pam_unix вопрос «Password:».
pam_acct_mgmt нельзя пропускать: верный пароль не означает действующую учётную
запись – сроки и ограничения проверяет account-стек; забытый acct_mgmt – типовая
ошибка самодельных PAM-приложений. pam_strerror даёт человекочитаемый текст
кода. Красная карточка: приложение никогда не видит сам пароль – диалог идёт
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
<div><span class="co-ball">2</span> файла <code>/etc/pam.d/authprint</code> ещё нет – применяются правила службы <code>other</code> (раздел 2.5): обычный пароль</div>
<div><span class="co-ball">3</span> пароль верен → <Man p="pam_authenticate(3)" /> и <Man p="pam_acct_mgmt(3)" /> вернули <code>PAM_SUCCESS</code> – строка напечатана</div>
<div><span class="co-ball">4</span> неверный пароль → <code>PAM_AUTH_ERR</code>; текст дал <Man p="pam_strerror(3)" /></div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> ~50 строк кода – и программа получает «настоящую» парольную
проверку: с <code>/etc/shadow</code> работает <Man p="pam_unix(8)" /> (его
SUID-помощник <Man p="unix_chkpwd(8)" />), а не наш код.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/08-authprint.sh</code>; исходный код – <code>assets/src/authprint.c</code>.
</SrcRef>

<!--
Демонстрация: собираем с -lpam -lpam_misc (заголовки – libpam0g-dev; в
методичке пакет назван libpam-dev – это алиас). Запуск без своего файла
конфигурации: действует other – обычная парольная аутентификация. Верный
пароль – строка напечатана; неверный – Authentication failure через
pam_strerror. Внимание на вывод: наш код не читает /etc/shadow – это делает
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
<div><span class="co-ball">1</span> свой файл службы: <Man p="pam_listfile(8)" /> с <code>sense=allow</code> – <b>разрешающий</b> список из демо 02</div>
<div><span class="co-ball">2</span> дальше – обычные общие стеки <code>@include</code></div>
<div><span class="co-ball">3</span> <code>bob</code> в списке – вход разрешён; <code>carol</code> – отказ при верном пароле</div>
<div><span class="co-ball">4</span> отказ записан в syslog: видно модуль, службу и тип стека</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> наша программа администрируется <b>теми же средствами</b>, что
login и sshd: ей можно назначить любой стек – список доступа, политику,
второй фактор – не меняя ни строки кода.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/08-authprint.sh</code>.
</SrcRef>

<!--
Кульминация раздела: создаём /etc/pam.d/authprint – и наша программа обретает
собственную политику. Правило pam_listfile с sense=allow – зеркало запрещающего
списка из демо 02: разрешены только перечисленные. bob проходит, carol с верным
паролем получает отказ, и событие ложится в auth.log с именем нашей службы.
Теперь программа - полноправный гражданин PAM: администратор может добавить ей
TOTP из раздела 7 одной строкой. Это и есть смысл использования libpam вместо
самодельной проверки пароля.
-->

---
layout: section
---

# 9. Разработка модуля PAM
## Интерфейс модуля: pam_sm_* и учебный модуль pam_math

---

# Интерфейс модуля: функции pam_sm_*

Модуль – разделяемая библиотека, экспортирующая **сервисные функции** –
зеркало вызовов приложения (<Man p="pam_sm_authenticate(3)" />):

<div class="t-table text-xs mt-2">

| Вызов приложения | Функция модуля | Стек |
|---|---|---|
| <Man p="pam_authenticate(3)" /> | `pam_sm_authenticate` | auth |
| <Man p="pam_setcred(3)" /> | `pam_sm_setcred` | auth |
| <Man p="pam_acct_mgmt(3)" /> | `pam_sm_acct_mgmt` | account |
| <Man p="pam_chauthtok(3)" /> | `pam_sm_chauthtok` (вызывается дважды: preliminary + update) | password |
| <Man p="pam_open_session(3)" /> / `pam_close_session` | `pam_sm_open_session` / `pam_sm_close_session` | session |

</div>

<div class="w-3/5 mt-2">
<CodeSnippet src="snippets/pam_modules-sm.h" title="security/pam_modules.h" tag="Linux-PAM 1.7.0">
  <TCallout :line="1" :col="45" :span="9" :n="1" />
  <TCallout :line="2" :col="25" :span="27" :n="2" />
</CodeSnippet>
</div>

<div class="grid grid-cols-3 gap-3 mt-2 text-xs">
<div class="p-2 border border-slate-400/40 rounded">
<b>Достаточно реализовать функции своего типа:</b> модуль только для стека auth
экспортирует <code>pam_sm_authenticate</code> и <code>pam_sm_setcred</code>.
</div>
<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">1</span> <b><code>flags</code></b>: например, <code>PAM_SILENT</code> – «не выводить
сообщений»; модуль обязан уважать флаги.
</div>
<div class="p-2 border border-slate-400/40 rounded">
<span class="co-ball">2</span> <b><code>argc/argv</code></b> – те самые module-arguments из строки правила
(<code>max=50</code>); разбирает их сам модуль.
</div>
</div>

<Refs ids="man-pam-sm-authenticate pam-mwg" />

<!--
Симметрия интерфейсов: каждому вызову приложения соответствует pam_sm_-функция
модуля; libpam находит её по имени через dlsym (раздел 10). Реализуются только
функции нужных стеков: auth-модулю достаточно pam_sm_authenticate и
pam_sm_setcred. Аргументы argc/argv – слова из строки правила после имени
модуля; соглашения о формате (ключ=значение) – на совести модуля. flags –
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
| `pam_get_user(pamh, &user, prompt)` | имя пользователя: из контекста – или вопросом через диалог (<Man p="pam_get_user(3)" />) |
| `pam_get_item / pam_set_item` | элементы контекста: `PAM_USER`, `PAM_TTY`, `PAM_RHOST`, `PAM_AUTHTOK`… |
| `pam_prompt(pamh, style, &resp, fmt, …)` | вопрос пользователю через функцию диалога приложения |
| `pam_error / pam_info` | сообщение об ошибке / информационный текст |
| <Man p="pam_get_authtok(3)" /> | пароль: уже введённый выше по стеку – или запросить (конвенция `use_authtok`) |
| `pam_get_data / pam_set_data` | приватные данные модуля внутри транзакции |
| <Man p="pam_syslog(3)" /> | запись в системный журнал от имени модуля |

</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Главное правило:</b> модуль не читает терминал и не пишет на него –
весь ввод-вывод идёт <b>через диалог приложения</b> (<Man p="pam_prompt(3)" />,
<Man p="pam_error(3)" />): только так модуль одинаково работает в консоли,
GDM и sshd (раздел 8).
</div>

</v-click>

<Refs ids="man-pam-get-user pam-mwg" />

<!--
Инструментарий автора модуля. pam_get_user – каноничный способ узнать, кого
аутентифицируем: имя берётся из контекста (его мог задать pam_start или
предыдущий модуль), а при отсутствии запрашивается через диалог. pam_get_item/
set_item – доступ к элементам транзакции, включая PAM_AUTHTOK – пароль, которым
модули делятся по конвенции use_authtok/try_first_pass (раздел 6). pam_prompt,
pam_error, pam_info – обёртки над функцией диалога; pam_syslog – журналирование.
Повторить правило: никакого прямого ввода-вывода.
-->

---

# pam_math: задача и имя пользователя

Учебный модуль: «аутентификация» арифметической задачей. Разбор
`assets/src/pam_math.c` – первая половина:

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/pam_math-auth1.c" title="pam_math.c" tag="демо 09" fontSize="0.5rem">
  <TCallout :line="1" :col="1" :span="33" :rows="2" :n="1" />
  <TCallout :line="14" :col="13" :span="27" :n="2" />
  <TCallout :line="18" :col="10" :span="31" :n="3" />
  <TCallout :line="20" :col="9" :span="10" :n="4" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> Заголовки модуля: <code>pam_modules.h</code> (интерфейс
<code>pam_sm_*</code>) и <code>pam_ext.h</code>
(<Man p="pam_prompt(3)" />, <Man p="pam_error(3)" />).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">2</span> Аргумент правила <code>max=N</code> ограничивает слагаемые – разбор
<code>argv</code> тривиален и целиком на модуле.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> <Man p="pam_get_user(3)" /> – третий аргумент <code>NULL</code>:
использовать стандартное приглашение «login:», если имя ещё
не известно транзакции.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">4</span> Код возврата <code>pam_get_user</code> проверяем и <b>пробрасываем</b>:
при <code>PAM_CONV_ERR</code> решение примет стек, а не модуль.
</div>

</div>
</div>

<SrcRef>
Модуль целиком – <code>assets/src/pam_math.c</code>.
</SrcRef>

<Refs ids="pam-mwg man-pam-get-user man-pam-sm-authenticate" />


<!--
Первая половина модуля. Два заголовка: pam_modules.h и pam_ext.h. Обходим argv –
поддержан один аргумент max=N. pam_get_user с NULL-приглашением: если имя уже
есть в транзакции (его передал pam_start из authprint), диалога не будет.
Генерация задачи обычным random – для учебного модуля достаточно;
криптографическая стойкость здесь не требуется, что честно оговорено в
комментарии исходника. Коды возврата сервисных функций пробрасываем наверх –
пусть решает стек.
-->

---

# pam_math: диалог и результат

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/pam_math-auth2.c" title="pam_math.c" tag="демо 09" fontSize="0.5rem">
  <TCallout :line="3" :col="27" :span="18" :n="1" />
  <TCallout :line="13" :col="9" :span="33" :n="2" />
  <TCallout :line="17" :col="5" :span="11" :n="3" />
  <TCallout :line="25" :col="5" :span="18" :n="4" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <Man p="pam_prompt(3)" /> со стилем <code>PAM_PROMPT_ECHO_ON</code>:
вопрос дойдёт до пользователя через <Man p="misc_conv(3)" />,
окно GDM или сетевой диалог sshd – модулю всё равно.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">2</span> Неверный ответ: <Man p="pam_error(3)" /> отправляет сообщение
(<code>PAM_ERROR_MSG</code>), возврат – <code>PAM_AUTH_ERR</code>;
как это скажется на итоге, решит <b>управляющий флаг</b> правила.
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<span class="co-ball">3</span> Ответ пользователя – память, выделенная libpam:
освобождаем <code>free(resp)</code>. В настоящих модулях
секреты перед освобождением затирают.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">4</span> <code>pam_sm_setcred</code> обязана существовать у auth-модуля;
выдавать нечего – возвращаем <code>PAM_IGNORE</code>.
</div>

</div>
</div>

<SrcRef>
Модуль целиком – <code>assets/src/pam_math.c</code>.
</SrcRef>

<Refs ids="pam-mwg man-pam-get-user man-pam-sm-authenticate" />


<!--
Вторая половина. pam_prompt с ECHO_ON – ввод виден, это не секрет. Сравнение
ответа: успех – PAM_SUCCESS, иначе pam_error с сообщением и PAM_AUTH_ERR.
Подчеркнуть разделение ответственности: модуль лишь сообщает СВОЙ результат;
итог стека определит управляющий флаг – required, requisite или подробная
форма. pam_sm_setcred возвращает PAM_IGNORE – «моего мнения нет»; вспомнить
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

<TerminalCapture src="captures/12-pam-math.txt" section="2" title="demo 09 · служба mathtest: клиент – authprint" fontSize="0.5rem">
  <TCallout :line="2" :col="21" :span="18" :n="3" />
  <TCallout :line="6" :col="1" :span="26" :n="4" />
  <TCallout :line="10" :col="24" :span="1" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> сборка разделяемой библиотеки: <code>-fPIC -shared</code>; имя – <code>pam_math.so</code></div>
<div><span class="co-ball">2</span> установка в каталог модулей (раздел 2.1), права 644, владелец root</div>
<div><span class="co-ball">3</span> служба <code>mathtest</code>: одно правило auth с аргументом <code>max=50</code>; account – <Man p="pam_permit(8)" /></div>
<div><span class="co-ball">4</span> клиент – <code>authprint mathtest</code> из раздела 8: вопрос модуля пришёл через <Man p="misc_conv(3)" />; верный ответ – успех</div>
<div><span class="co-ball">5</span> неверный ответ – «Wrong answer.» и отказ</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Разделы 7 и 8 сомкнулись: наше приложение и наш модуль общаются через libpam,
не зная друг о друге.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/09-pam-math.sh</code>; исходный код – <code>assets/src/pam_math.c</code>.
</SrcRef>

<!--
Сборка: -fPIC -shared, получаем pam_math.so; установка в каталог модулей с
правами 644 root. Служба mathtest из двух строк: auth required pam_math.so
max=50, account pam_permit. Тестовый клиент – authprint из раздела 8 с именем
службы mathtest: вопрос «math for bob: 23+14=» пришёл из модуля через libpam и
misc_conv; правильный ответ печатает строку, неверный – Wrong answer и
Authentication failure. Приложение и модуль не знают друг о друге – их связал
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
<div><span class="co-ball">1</span> строка после <code>@include common-auth</code> – как у TOTP-модуля в разделе 7</div>
<div><span class="co-ball">2</span> ssh задаёт пароль, затем вопрос модуля – диалог дошёл по сети через keyboard-interactive</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> собственный модуль ничем не отличается от «фирменных»:
те же правила, те же стеки, тот же диалог. Весь инструментарий раздела 7
теперь доступен и вашему коду.
</div>

</v-click>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
Знание арифметики – не секрет: <code>pam_math</code> – учебная модель
«второго фактора», а не средство защиты.
</div>

</v-click>

</div>
</div>

<SrcRef>
См. <code>demos/09-pam-math.sh</code>.
</SrcRef>

<!--
Финал демонстрации: та же строка, что для google_authenticator в разделе 7,
подключает наш модуль вторым фактором к sshd. Клиент ssh показывает вопрос
модуля после пароля – диалог прошёл по сети через keyboard-interactive, модуль
об этом не знает. Красная карточка обязательна: арифметика – не секрет, модуль
учебный; но каркас – ровно тот, на котором строятся настоящие факторы.
-->

---

# Безопасность модулей PAM

Модуль исполняется **в адресном пространстве привилегированного процесса**
(login, sshd работают от root) и **видит пароли** в открытом виде – это делает
стек PAM привлекательной целью.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

**Вредоносные модули – реальный класс атак:**

- троянизированный `pam_unix.so` или добавленный в стек
  модуль-бэкдор **перехватывает пароли** всех входящих
  и может впускать атакующего по мастер-паролю;
- исследователи Unit 42 (2023) и Nextron (2025, бэкдор
  Plague) описывают семейства вредоносных PAM-модулей,
  годами остававшихся незамеченными;
- установка модуля требует root – это инструмент
  **закрепления** (persistence, <MitreAttack t="T1556.003" />) после компрометации.

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
Вредоносные модули – задокументированный класс: обзор Unit 42 (2023) и бэкдор
Plague (Nextron, 2025) – модули, перехватывающие пароли и впускающие по
мастер-паролю; ставятся после получения root как средство закрепления.
Контрмеры организационно-технические: целостность pam.d и каталога модулей
(dpkg -V, AIDE, auditd), модули только из подписанных репозиториев, ревизия
стеков. Мост к разделу 10: чтобы читать и проверять стеки, нужно понимать, как
libpam их исполняет, – смотрим исходный код.
-->

---
layout: section
---

# 10. Реализация Linux-PAM

<SectionTOC prefix="10" :current="1" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: struct pam_handle

Смотрим Linux-PAM **v1.7.0** – версию из Ubuntu 26.04. Непрозрачный
`pam_handle_t` из раздела 8 внутри libpam определён так:

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-2">
<div>

<CodeSnippet src="snippets/pam_private-handle.h" title="libpam/pam_private.h" tag="Linux-PAM 1.7.0" fontSize="0.5rem">
  <TCallout :line="2" :col="5" :span="14" :n="1" />
  <TCallout :line="3" :col="5" :span="19" :n="2" />
  <TCallout :line="7" :col="5" :span="19" :rows="5" :n="3" />
  <TCallout :line="18" :col="5" :span="24" :n="4" />
  <TCallout :line="19" :col="5" :span="32" :n="5" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L153">libpam/pam_private.h#L153</a>.
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <code>authtok</code> – тот самый пароль, который модули передают друг другу
(<code>use_authtok</code>): он живёт в контексте и затирается по завершении
стека.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">2</span> <code>caller_is</code> различает приложение и модуль: часть API разрешена
только одной из сторон.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> Всё, что мы передавали в <Man p="pam_start(3)" /> и <Man p="pam_set_item(3)" />,
лежит здесь: служба, пользователь, функция диалога, терминал, удалённый хост.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">4</span> <code>handlers</code> – разобранная конфигурация службы: стеки правил
(следующий слайд); <span class="co-ball">5</span> <code>former</code> хранит состояние прерванного стека
(<code>PAM_INCOMPLETE</code>) для событийных приложений.
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Раздел для любознательных: читаем реализацию той версии, что стоит на нашем
стенде. pam_handle – всё состояние транзакции: элементы (служба, пользователь,
терминал…), пароль authtok, окружение, приватные данные модулей, и главное –
handlers: разобранные стеки правил. former – сохранённое состояние для
приложений, которые прерывают стек (PAM_INCOMPLETE) и возобновляют позже.
caller_is охраняет границу приложение/модуль: например, pam_authenticate из
модуля запрещён.
-->

---

# Исходный код: struct handler

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-1">
<div>

<CodeSnippet src="snippets/pam_private-handler.h" title="libpam/pam_private.h" tag="Linux-PAM 1.7.0" fontSize="0.47rem">
  <TCallout :line="3" :col="5" :span="11" :n="1" />
  <TCallout :line="4" :col="5" :span="32" :n="2" />
  <TCallout :line="10" :col="5" :span="21" :n="3" />
  <TCallout :line="17" :col="5" :span="31" :rows="6" :n="4" />
  <TCallout :line="28" :col="5" :span="21" :rows="2" :n="5" />
</CodeSnippet>

</div>
<div>

<div class="text-xs space-y-1">
<div><span class="co-ball">1</span> функция модуля, найденная <Man p="dlsym(3)" /> (раздел 10.2)</div>
<div><span class="co-ball">2</span> вместо текста флага – массив действий: <code>actions[i]</code> – действие на код возврата <code>i</code>; подробная форма флага хранится буквально</div>
<div><span class="co-ball">3</span> каждая строка конфигурации – узел <b>односвязного списка</b>: стек и есть список</div>
<div><span class="co-ball">4</span> шесть голов списков – по одной на вызов API</div>
<div><span class="co-ball">5</span> два набора стеков: правила службы и правила <code>other</code></div>
</div>

<CodeSnippet src="snippets/pam_private-actions.h" title="libpam/pam_private.h" tag="Linux-PAM 1.7.0" class="mt-2" fontSize="0.5rem" />

<div class="text-xs p-2 border-l-4 border-sky-500 bg-sky-500/10 mt-2">
Положительное значение – прыжок на N правил; именованные действия –
отрицательные константы. Таблица действий из раздела 2.4 – ровно этот массив.
</div>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L53">pam_private.h#L53</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L194">#L194</a>.
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Структура правила. func – найденная dlsym-ом функция pam_sm_* (как – в 9.2);
argc/argv – слова аргументов; next – связь в список: стек буквально является
односвязным списком. Главная идея – actions: массив, индексированный кодом
возврата модуля; управляющий флаг строки разворачивается в заполнение этого
массива. Кодировка: 0 – ignore, отрицательные – именованные действия,
положительные – прыжки. handlers – шесть голов списков (по вызовам API);
service хранит два набора: conf – правила службы, other – запасные.
-->

---
layout: section
---

# 10. Реализация Linux-PAM

<SectionTOC prefix="10" :current="2" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: где libpam ищет конфигурацию

Стеки загружаются **лениво**: первый вызов <Man p="pam_authenticate(3)" /> (или другого
диспетчера) вызывает `_pam_init_handlers`, та открывает конфигурацию службы:

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2">
<div>

<CodeSnippet src="snippets/pam_private-config.h" title="libpam/pam_private.h" tag="Linux-PAM 1.7.0" fontSize="0.45rem">
  <TCallout :line="1" :col="28" :span="15" :n="1" />
</CodeSnippet>

<CodeSnippet src="snippets/pam_handlers-open.c" title="libpam/pam_handlers.c" tag="Linux-PAM 1.7.0" fontSize="0.45rem" class="mt-1">
  <TCallout :line="7" :col="37" :span="35" :n="2" />
  <TCallout :line="19" :col="13" :span="19" :n="3" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <code>_pam_init_handlers</code> использует <code>/etc/pam.conf</code>, только
если нет ни одного каталога <code>pam.d</code> (сборочная опция
<code>PAM_READ_BOTH_CONFS</code> – читать оба).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">2</span> Приоритет каталогов из раздела 2.2 – это <b>порядок элементов массива</b>
<code>pamd_dirs</code>: сначала <code>/etc/pam.d/%s</code>, затем
<code>/usr/lib/pam.d/%s</code>; <span class="co-ball">3</span> побеждает первый открывшийся файл.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
После файла службы тем же путём разбирается служба
<code>other</code> – заполняются оба набора стеков
(<code>conf</code> и <code>other</code> из 9.1).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Повторный вызов – без повторного разбора:
<code>handlers_loaded</code> делает загрузку однократной
на транзакцию.
</div>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_private.h#L28">pam_private.h#L28</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L292">pam_handlers.c#L292</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L405">#L405 (_pam_init_handlers)</a>.
</div>

</div>
</div>

<Refs ids="linux-pam-src man-pam-conf" />


<!--
Начало пути: pam_start конфигурацию не читает – только копирует имена; разбор
происходит при первом диспетчерском вызове, в _pam_init_handlers. Пути из
раздела 2.2 зашиты константами; приоритет /etc/pam.d над /usr/lib/pam.d – это
буквально порядок массива pamd_dirs в цикле fopen. pam.conf используется только
при отсутствии pam.d (или в сборке READ_BOTH_CONFS). После службы разбирается
other – отсюда два набора стеков в struct service. handlers_loaded кеширует
результат на время транзакции – но не между процессами: каждый вход читает
конфигурацию заново, поэтому правки pam.d действуют немедленно.
-->

---

# Исходный код: разбор строки правила

`_pam_parse_conf_file` читает файл построчно; поле **type**:

<div class="grid grid-cols-[1.6fr_1fr] gap-4 mt-2">
<div>

<CodeSnippet src="snippets/pam_handlers-type.c" title="libpam/pam_handlers.c" tag="Linux-PAM 1.7.0" fontSize="0.44rem">
  <TCallout :line="1" :col="17" :span="18" :n="1" />
  <TCallout :line="19" :col="53" :span="11" :n="2" />
  <TCallout :line="20" :col="21" :span="32" :n="3" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L54">pam_handlers.c#L54 (_pam_parse_conf_file)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L118">#L118</a>.
</div>

</div>
<div class="text-xs space-y-1.5">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Четыре типа из раздела 2.3 – четыре константы <code>PAM_T_*</code>;
<span class="co-ball">1</span> дефис перед типом включает «тихую» загрузку (<code>-auth</code>).
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">2</span> Тип по умолчанию для сломанной строки – <code>PAM_T_AUTH</code>
с комментарием «most sensitive»: самый чувствительный стек.
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<span class="co-ball">3</span> <b>Обещание «ошибка = отказ» выполняется здесь:</b> неизвестный тип
создаёт правило <code>PAM_HT_MUST_FAIL</code> – при исполнении оно вернёт
<code>PAM_PERM_DENIED</code>. Опечатка в <code>/etc/pam.d</code> ломает вход – в сторону запрета.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Директивы <code>include</code>/<code>substack</code> обрабатываются
рекурсивно: <code>_pam_load_conf_file</code> с ограничением глубины
<code>PAM_SUBSTACK_MAX_LEVEL</code> (16).
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Разбор строки. Поле type: четыре strcasecmp, дефис-префикс для тихой загрузки.
Самое интересное – ветка else: нераспознанный тип не игнорируется, строка
превращается в правило «обязан отказать» (PAM_HT_MUST_FAIL) в самом
чувствительном стеке auth, с записью в syslog. Это реализация принципа
fail-closed, который мы анонсировали в разделе 2.5: опечатка администратора
ломает вход, а не молча открывает его. include/substack разворачиваются
рекурсией с лимитом глубины 16.
-->

---

# Исходный код: флаг → массив actions

Поле **control** заполняет массив `actions` правила – краткие флаги
разворачиваются в те же действия, что их подробные формы (раздел 2.4):

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2">
<div>

<CodeSnippet src="snippets/pam_handlers-control.c" title="libpam/pam_handlers.c" tag="Linux-PAM 1.7.0" fontSize="0.47rem">
  <TCallout :line="3" :col="17" :span="51" :rows="4" :n="1" />
  <TCallout :line="26" :col="17" :span="33" :n="2" />
  <TCallout :line="28" :col="51" :span="15" :n="3" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L163">pam_handlers.c#L163</a>.
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> Сравните с таблицей соответствия из раздела 2.4: <code>required</code> =
<code>[success=ok new_authtok_reqd=ok ignore=ignore default=bad]</code> –
код заполняет массив буквально по ней.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<code>_pam_set_default_control</code> записывает действие во все ещё
не заданные ячейки – реализация слова <code>default</code>.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">2</span> Подробная форма <code>[…]</code> разбирается <code>_pam_parse_control</code>;
<span class="co-ball">3</span> действие по умолчанию в ней – <code>bad</code>:
не перечисленный код возврата считается неудачей.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
После флага читаются имя модуля и аргументы, и правило уходит в
<code>_pam_add_handler</code> – загрузку модуля (следующий слайд).
</div>

</div>
</div>

<Refs ids="linux-pam-src man-pam-conf" />


<!--
Поле control. Каждый краткий флаг – явное заполнение ячеек actions: success и
new_authtok_reqd получают ok (или done у sufficient), остальное – через
_pam_set_default_control: bad у required, die у requisite, ignore у sufficient
и optional. Любой другой токен уходит в _pam_parse_control – разбор квадратных
скобок, и default там тоже bad. Таблица эквивалентности из man-страницы – не
аналогия, а точное описание этого кода.
-->

---

# Исходный код: загрузка модуля

`_pam_add_handler` превращает имя `.so` в указатель на функцию:

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2">
<div>

<CodeSnippet src="snippets/pam_handlers-load.c" title="libpam/pam_handlers.c" tag="Linux-PAM 1.7.0" fontSize="0.46rem">
  <TCallout :line="4" :col="5" :span="39" :n="1" />
  <TCallout :line="11" :col="26" :span="21" :n="2" />
  <TCallout :line="15" :col="13" :span="30" :n="4" />
</CodeSnippet>

<CodeSnippet src="snippets/pam_handlers-sym.c" title="libpam/pam_handlers.c" tag="Linux-PAM 1.7.0" fontSize="0.46rem" class="mt-1">
  <TCallout :line="4" :col="9" :span="28" :n="3" />
  <TCallout :line="10" :col="18" :span="31" :n="5" />
</CodeSnippet>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <span class="co-ball">2</span> Модуль загружается <code>dlopen(3)</code> один раз на транзакцию
(список <code>loaded_module</code>); относительное имя libpam
дополняет путём каталога модулей (раздел 2.1).
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> Для каждого типа правила – своё имя символа: правило <code>auth</code>
ищет в модуле <code>pam_sm_authenticate</code>. Вот почему наш
<code>pam_math.so</code> обязан экспортировать именно эти имена
(раздел 9).
</div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
Модуль не нашёлся или без нужного символа? Правило остаётся в стеке
как <b>неисправное</b> (<span class="co-ball">4</span> <code>PAM_MT_FAULTY_MOD</code> /
<span class="co-ball">5</span> <code>func == NULL</code>) – при исполнении оно даст отказ.
Снова fail-closed.
</div>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L604">pam_handlers.c#L604 (_pam_load_module)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_handlers.c#L759">#L759 (выбор символа)</a>.
</div>

</div>
</div>

<Refs ids="linux-pam-src pam-mwg" />


<!--
Последний шаг разбора – загрузка модуля. _pam_load_module ведёт список уже
загруженных .so и вызывает dlopen один раз; ошибка загрузки не выбрасывает
правило, а помечает модуль неисправным – исполнение даст отказ. Выбор символа
по типу правила: auth → pam_sm_authenticate (и setcred вторым символом),
account → pam_sm_acct_mgmt и т. д.; dlsym возвращает указатель, который ляжет
в handler->func. Теперь понятно всё, что требовалось от pam_math: правильные
имена экспортируемых функций.
-->

---
layout: section
---

# 10. Реализация Linux-PAM

<SectionTOC prefix="10" :current="3" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: pam_authenticate и выбор стека

<div class="grid grid-cols-2 gap-4 mt-1">
<div>

<CodeSnippet src="snippets/pam_auth-authenticate.c" title="libpam/pam_auth.c" tag="Linux-PAM 1.7.0" fontSize="0.46rem">
  <TCallout :line="4" :col="9" :span="23" :n="1" />
  <TCallout :line="11" :col="9" :span="23" :n="2" />
  <TCallout :line="16" :col="14" :span="44" :n="3" />
  <TCallout :line="20" :col="9" :span="31" :n="4" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/pam_dispatch-select.c" title="libpam/pam_dispatch.c" tag="Linux-PAM 1.7.0" fontSize="0.46rem">
  <TCallout :line="3" :col="19" :span="24" :n="5" />
  <TCallout :line="12" :col="9" :span="37" :n="6" />
  <TCallout :line="23" :col="13" :span="38" :n="7" />
</CodeSnippet>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="grid grid-cols-2 gap-x-6 gap-y-0.5">
<div><span class="co-ball">1</span> вызывать стек может только приложение, не модуль</div>
<div><span class="co-ball">5</span> догрузить стеки (раздел 10.2)</div>
<div><span class="co-ball">2</span> <span class="co-ball">4</span> время ответа при неудаче не зависит от того, какой модуль отказал</div>
<div><span class="co-ball">6</span> выбор головы списка по вызову API</div>
<div><span class="co-ball">3</span> проход по стеку – в <code>_pam_dispatch</code></div>
<div><span class="co-ball">7</span> у службы нет такого стека – стек <code>other</code></div>
</div>
</div>

<div class="mt-1 text-xs">
<code>_pam_await_timer</code> – защита от хронометража: libpam выдерживает
паузу при неудаче (по умолчанию её просит <Man p="pam_unix(8)" />).
</div>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_auth.c#L14">pam_auth.c#L14</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L334">pam_dispatch.c#L334</a>.
</div>

<Refs ids="linux-pam-src" />


<!--
Путь вызова приложения. pam_authenticate: проверка «вызывает приложение, не
модуль», очистка старого authtok, запуск таймера – и _pam_dispatch. Таймер
реализует fail delay: при неудаче библиотека выдерживает запрошенную модулями
паузу, выравнивая время ответа, – защита от перебора и от анализа времени.
_pam_dispatch: догрузить стеки, выбрать голову списка по choice – это таблица
«вызов API - стек» из раздела 8, в коде; при отсутствии стека у службы – стек
other. Сам проход – в _pam_dispatch_aux.
-->

---

# Исходный код: цикл по стеку

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1">
<div>

<CodeSnippet src="snippets/pam_dispatch-loop.c" title="libpam/pam_dispatch.c" tag="Linux-PAM 1.7.0" fontSize="0.46rem">
  <TCallout :line="6" :col="9" :span="26" :n="1" />
  <TCallout :line="10" :col="31" :span="28" :n="2" />
  <TCallout :line="12" :col="58" :span="11" :n="3" />
  <TCallout :line="26" :col="13" :span="48" :n="4" />
  <TCallout :line="30" :col="13" :span="35" :n="5" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L34">pam_dispatch.c#L34 (_pam_dispatch_aux)</a> ·
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L110">#L110 (вызов модуля)</a>.
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> <span class="co-ball">2</span> Исходное состояние итога – <b>отказ</b>: пустой стек, стек из одних
<code>ignore</code>, битые строки – всё даёт
<code>PAM_PERM_DENIED</code>.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">3</span> проход по односвязному списку правил;
<span class="co-ball">4</span> вызов модуля – это вызов <code>h->func</code>: указателя, найденного
<Man p="dlsym(3)" /> (9.2); на время вызова контекст получает имя модуля –
для <Man p="pam_syslog(3)" />.
</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">5</span> Результат модуля превращается в действие <b>одним обращением
к массиву</b> – вся семантика флагов уже разложена по ячейкам (9.2);
в обычном стеке <code>cached_retval</code> равен <code>retval</code>.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<code>PAM_INCOMPLETE</code> (диалог не может завершиться сейчас)
сохраняет позицию в <code>pamh->former</code> – приложение
повторит вызов, и стек продолжится с того же места.
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Сердце PAM – цикл по односвязному списку правил. Два аккумулятора: impression –
«мнение» (не определено / положительное / отрицательное) и status – будущий код
возврата, инициализированный отказом. Битые правила (must-fail, func==NULL)
не вызываются – сразу получают код отказа. Нормальный вызов – h->func(...);
mod_name на время вызова – для журналирования. Ключевая строка слайда:
action = h->actions[retval] – семантика управляющих флагов исполняется одним
индексированием массива. PAM_INCOMPLETE – механизм прерывания для событийных
приложений (GDM): состояние прячется в former, повторный вызов продолжит стек.
-->

---
layout: section
---

# 10. Реализация Linux-PAM

<SectionTOC prefix="10" :current="4" :items="[
  'Основные структуры',
  'Разбор конфигурации',
  'Исполнение стека',
  'Применение результата',
]" />

---

# Исходный код: применение действия

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-1">
<div>

<CodeSnippet src="snippets/pam_dispatch-ok.c" title="libpam/pam_dispatch.c" tag="Linux-PAM 1.7.0" fontSize="0.43rem">
  <TCallout :line="6" :col="18" :span="24" :n="1" />
  <TCallout :line="17" :col="21" :span="15" :n="4" />
  <TCallout :line="21" :col="21" :span="19" :n="3" />
</CodeSnippet>

<div class="mt-1 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs leading-snug">
<div>
<div><span class="co-ball">1</span> успех записывается, только пока мнение не отрицательное</div>
<div><span class="co-ball">2</span> <b>неудача «липкая»</b>: первая неудача фиксирует мнение и статус – так <code>required</code> гарантирует отказ, продолжая стек</div>
<div><span class="co-ball">3</span> <code>done</code>/<code>die</code> = <code>ok</code>/<code>bad</code> + немедленный выход; на них построены <code>sufficient</code> и <code>requisite</code></div>
<div><span class="co-ball">4</span> <code>grantor</code> помечает правило, «давшее» успех, – след для аудита</div>
<div><span class="co-ball">5</span> прыжок <code>N</code> учитывает <code>stack_level</code>: <code>substack</code> пропускается как одно правило</div>
</div>
</div>

</div>
<div>

<CodeSnippet src="snippets/pam_dispatch-bad.c" title="libpam/pam_dispatch.c" tag="Linux-PAM 1.7.0" fontSize="0.43rem">
  <TCallout :line="5" :col="17" :span="27" :n="2" />
  <TCallout :line="13" :col="17" :span="19" :n="3" />
  <TCallout :line="21" :col="18" :span="27" :n="5" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L201">pam_dispatch.c#L201</a>.
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Применение действия – switch. Ветка OK/DONE: успех записывается, только пока
мнение не отрицательное; ветка BAD/DIE: первая неудача фиксирует и мнение, и
статус – последующие успехи и неудачи статус не меняют. Отсюда вся семантика
required: неудача учтена, но стек продолжается, и итог уже не изменить.
done/die добавляют немедленный выход через goto. Прыжки учитывают stack_level –
substack пропускается как единое целое. grantor – пометка правила, принёсшего
успех: libpam может сообщить аудиту, кто именно впустил.
-->

---

# Исходный код: страховка на выходе

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-1">
<div>

<CodeSnippet src="snippets/pam_dispatch-sanity.c" title="libpam/pam_dispatch.c" tag="Linux-PAM 1.7.0" fontSize="0.5rem">
  <TCallout :line="2" :col="10" :span="52" :n="1" />
  <TCallout :line="3" :col="39" :span="32" :n="2" />
  <TCallout :line="4" :col="9" :span="28" :n="3" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux-PAM v1.7.0:
<a href="https://github.com/linux-pam/linux-pam/blob/v1.7.0/libpam/pam_dispatch.c#L309">pam_dispatch.c#L309</a>.
</div>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Итог раздела – инварианты libpam:</b> вернуть успех может только стек,
в котором <b>хотя бы одно не-ignore правило явно дало успех</b>; любая
двусмысленность – пустой стек, битая строка, незагрузившийся модуль,
рассогласование статуса – разрешается <b>отказом</b>.
</div>

</div>
<div class="text-xs space-y-2">

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<span class="co-ball">1</span> Последний рубеж: если к концу стека статус «успех», а положительного
мнения нет (например, стек состоял из одних <code>ignore</code>), –
<span class="co-ball">3</span> итог принудительно заменяется отказом.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">2</span> Комментарий в коде честен: такая ситуация – «probably a config
error» – ошибка конфигурации, и libpam ошибается в безопасную
сторону.
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Для <code>setcred</code>/<code>close_session</code> стек исполняется
по «замороженной цепочке» (<code>cached_retval</code>): те же модули
и решения, что при <code>authenticate</code>/<code>open_session</code>, –
симметрия выдачи и отзыва.
</div>

</div>
</div>

<Refs ids="linux-pam-src" />


<!--
Финальные строки _pam_dispatch_aux – санитарная проверка: статус «успех» без
положительного впечатления заменяется отказом. Вместе с must-fail правилами,
faulty-модулями и инициализацией отказом это складывается в систему инвариантов
fail-closed, которую мы наблюдали всю лекцию со стороны конфигурации. Упомянуть
frozen chain: setcred и close_session повторяют решения парного стека по
кешированным результатам – выдача и отзыв удостоверений симметричны. На этом
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

<SourcesList class="mt-4" :to="24" />

<div class="text-xs opacity-70 mt-3">
Нумерация сквозная для всей лекции; ссылки «[n]» внизу слайдов ведут сюда и
подсвечивают источник. Точные версии и особенности системы – локальные
man-страницы Ubuntu Server 26.04 (Linux-PAM 1.7.0); фрагменты исходного кода –
Linux-PAM v1.7.0.
</div>

---
routeAlias: refs2
refsFrom: 25
---

# Источники (продолжение)

<SourcesList class="mt-4" :from="25" :to="42" />

---
routeAlias: refs3
refsFrom: 43
---

# Источники (окончание)

<SourcesList class="mt-4" :from="43" />
