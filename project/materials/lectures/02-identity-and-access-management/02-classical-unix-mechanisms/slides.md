---
theme: default
title: Классические механизмы управления пользователями в ОС Unix
author: OSSec
addons: [../../../theme]
layout: cover
colorSchema: light
duration: 90min
mdc: true
selectable: true
transition: slide-left
defaults:
  class: lecture-iam
---

# Лекция 2

## Классические механизмы управления пользователями в ОС Unix

<!--
Новая версия лекции. Слайды постепенно переносятся из
02-classical-unix-mechanisms_old/slides.md.

Сквозные правила деки: номер слайда — в правом нижнем углу (тема);
внизу каждого слайда (кроме демо) — блок «Источники: [n]» (<Refs ids="…"/>,
номера по sources.json, клик ведёт на слайд routeAlias: refs и подсвечивает
источник); упоминания man-страниц — ссылки (<Man p="name(sec)"/>).
-->

---
layout: default
---

# План лекции

<!--
Зарезервировано: план заполняется в конце, когда все разделы перенесены.
-->

---
layout: section
---

# 1. Введение
## Основные понятия IAM и монитор обращений

---

# Управление идентификацией и доступом: основные понятия

**IAM** (Identity and Access Management, управление идентификацией и доступом) —
совокупность процессов и механизмов, обеспечивающих идентификацию, аутентификацию
и авторизацию субъектов доступа.

<BlockFlow class="mt-3" :blocks="[
  { head: 'Идентификация', q: 'кто вы?', sub: '«Я — Иванов»', fill: 'dark' },
  { head: 'Аутентификация', q: 'докажите!', sub: '«Вот моё удостоверение»', fill: 'dark' },
  { head: 'Авторизация', q: 'разрешён ли доступ? (лекция 3)', sub: '«Проходите в бухгалтерию»', fill: 'accent' },
]" />

<v-click>

<div class="grid grid-cols-2 gap-2 mt-3 text-xs">
<div class="p-2 border border-slate-400/40 rounded">
<b>Субъект доступа</b> <span class="float-right text-amber-600">РД Гостехкомиссии, 1992, п. 6</span><br/>
<i>«Лицо или процесс, действия которого регламентируются правилами разграничения доступа».</i>
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b>Объект доступа</b> <span class="float-right text-amber-600">РД Гостехкомиссии, 1992, п. 7</span><br/>
<i>«Единица информационного ресурса автоматизированной системы, доступ к которой
регламентируется правилами разграничения доступа».</i>
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b>Идентификация</b> <span class="float-right text-amber-600">ГОСТ Р 58833-2020, п. 3.24</span><br/>
<i>«Действия по присвоению субъектам и объектам доступа идентификаторов и/или по сравнению
предъявляемого идентификатора с перечнем присвоенных идентификаторов».</i>
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b>Аутентификация</b> <span class="float-right text-amber-600">ГОСТ Р 58833-2020, п. 3.4</span><br/>
<i>«Действия по проверке подлинности субъекта доступа и/или объекта доступа, а также по проверке
принадлежности субъекту/объекту доступа предъявленного идентификатора и аутентификационной информации».</i>
</div>
</div>

</v-click>

<Refs ids="gost-58833 rd-terms" />

<!--
Аналогия с проходной. Каждый шаг отвечает на свой вопрос: идентификация — «кто вы?»,
аутентификация — «докажите», авторизация — «разрешён ли доступ?» (лекция 3). Примеры ответов —
«Я — Иванов», «Вот моё удостоверение», «Проходите в бухгалтерию». Определения — из
РД Гостехкомиссии 1992 г. и ГОСТ Р 58833-2020. Сегодня — парольная односторонняя
аутентификация; многофакторная и взаимная — в лекции о PAM.
-->

---

# Монитор обращений: куда встроены механизмы защиты

<BlockFlow class="mt-4 mb-4" :blocks="[
  { head: 'Субъект', sub: 'процесс с UID и GID\nпользователя' },
  { head: 'Монитор обращений', fill: 'dark', flex: '2.2',
    sub: 'перехватывает каждое обращение:\nразрешено ли субъекту это действие с этим объектом?' },
  { head: 'Объект', sub: 'файл, устройство,\nпамять, процесс' },
]" :arrows="['обращение', { label: 'разрешено', color: '#2e7d5b' }]" />

**Чтобы принять решение, монитору нужно знать:**

<div class="grid grid-cols-3 gap-3 mt-2">
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 rounded">
<b>Кто обращается?</b><br/>
идентификация и аутентификация — <b>эта лекция</b>: монитор должен достоверно знать субъекта
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Что разрешено?</b><br/>
правила разграничения доступа — авторизация, <b>лекция 3</b>
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Что произошло?</b><br/>
запись событий в журнал — журналы входов, <b>раздел 5</b>
</div>
</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-sky-500 bg-sky-500/10">
Требования к монитору (Андерсон, 1972; TCSEC): <b>вызывается всегда</b> (ни одно обращение
не проходит мимо), <b>защищён от изменения</b>, <b>достаточно мал</b>, чтобы его можно было
проанализировать. В профиле защиты ОС ФСТЭК России это отдельная функция безопасности —
«монитор обращений» (FPT_MTR_EXT.1).
</div>

</v-click>

<Refs ids="anderson tcsec fstec-pz-a4" />

<!--
Монитор обращений (reference monitor) — концепция из отчёта Андерсона (1972): механизм,
который перехватывает каждое обращение субъекта к объекту и проверяет его по правилам
разграничения доступа. Субъект в Linux — всегда процесс: он работает с UID и GID
пользователя, и именно их монитор видит при проверке. Чтобы схема работала, монитору нужно
достоверно знать, кто перед ним, — это дают идентификация и аутентификация (эта лекция);
затем нужны правила — авторизация (лекция 3); решения записываются в журнал (раздел 5).
-->

---

# Краткая история: от открытых паролей к модульной аутентификации

<Timeline height="12em" :items="[
  { year: '1960-е', head: 'CTSS (MIT)', text: 'первые пароли для входа в систему разделения времени' },
  { year: '1971', head: 'Unix V1', text: '/etc/passwd: пароли сначала в открытом виде' },
  { year: '1979', head: 'crypt и соль', text: 'Моррис и Томпсон: медленное хеширование (DES) и соль' },
  { year: '1980-е', head: 'NIS', text: 'Sun, «Yellow Pages»: сетевая база пользователей' },
  { year: '1988', head: 'Червь Морриса', text: 'перебор по словарю: хеши из читаемого passwd', hot: true },
  { year: '~1987–90', head: 'Shadow-пароли', text: 'хеш выносится в /etc/shadow (0640, root)' },
  { year: '1995', head: 'PAM и NSS', text: 'OSF RFC 86.0: модульные методы аутентификации и источники данных' },
  { year: '2000-е', head: 'LDAP, AD, SSSD', text: 'централизованные каталоги учётных записей' },
]" />

<v-click>

<HistoryNote class="mt-2">
Пароли скомпрометировали почти сразу: в 1966 г. из-за ошибки администратора CTSS
файл паролей попал в сообщение дня, а охотники за машинным временем научились его
распечатывать. Урок повторился в 1988-м — уже с перебором хешей по словарю.
</HistoryNote>

</v-click>

<v-click>

<div class="mt-2">
Классические механизмы — <b>файловые</b>: <code>/etc/passwd</code>, <code>/etc/group</code>,
<code>/etc/shadow</code>, <code>/etc/gshadow</code>. Они остаются базовым уровнем даже при
использовании сетевых каталогов.
</div>

</v-click>

<Refs ids="morris-thompson morris-worm shadow-howto osf-rfc86" />

<!--
Историю парольной аутентификации Моррис и Томпсон рассказывают в статье 1979 г.:
CTSS в MIT — первая система с паролями; инцидент 1966 г. (файл паролей оказался
в message of the day) — первая известная утечка. В Unix V1 пароли хранились в
/etc/passwd открыто; к 1979-му — медленный crypt на основе DES и 12-битная соль.
NIS (Sun, 1980-е) вынес базу пользователей в сеть. Червь Морриса (1988) подбирал
пароли по словарю к хешам из общедоступного passwd — это ускорило переход на
shadow (конец 1980-х). OSF RFC 86.0 (1995) дал PAM; вместе с NSS это сделало
методы аутентификации и источники учётных данных модульными; дальше —
централизованные каталоги: LDAP, Active Directory, SSSD.
-->

---
layout: section
---

# 2. Идентификация

<SectionTOC prefix="2" :current="1" :items="[
  'Субъекты и объекты',
  'Файл паролей <code>/etc/passwd</code>',
  'Файл групп <code>/etc/group</code>',
  'Идентификаторы процесса',
  'Реализация в ядре Linux',
]" />

---

# Субъекты и объекты в Linux

<div class="grid grid-cols-[1.15fr_1fr] gap-5">
<div class="so-left">

<BlockFlow class="mb-2" size="0.88em" :blocks="[
  { head: 'Пользователь', sub: 'bob (UID 1001)' },
  { head: 'Процесс', sub: 'работает с UID/GID\nпользователя' },
  { head: 'Объект', sub: 'файл, каталог,\nустройство, процесс' },
]" />

- **Субъект** — пользователь или группа; действует от их имени всегда **процесс**.
- **Объекты** — почти всё в Linux видно как файл; тип показывает первая буква вывода `ls -l`:
  - `-` — обычный файл
  - `d` — каталог
  - `c` — символьное устройство (`/dev`)
  - `l` — символьная ссылка
  - `p` — именованный канал (FIFO)
  - `s` — unix-сокет
- Даже процессы и параметры ядра — файлы: каталоги `/proc` (<Man p="proc(5)" />) и `/sys`.
- У каждого объекта есть владелец и права доступа — о них в лекции 3.

</div>
<div>

<TerminalCapture src="captures/14-object-types.txt" section="1" title="Ubuntu Server 26.04 · сеанс пользователя bob" fontSize="0.52rem" />

<div class="text-xs opacity-70 mt-1">
Почему идентификаторов <code>Uid</code> и <code>Gid</code> по четыре — раздел 2.4.
</div>

</div>
</div>

<Refs ids="rd-terms man-credentials man-proc" />

<style>
/* Компактный список слева: без него колонка упирается в нижний колонтитул. */
.so-left li { margin: 0.14em 0; line-height: 1.45; }
.so-left ul ul { margin: 0.15em 0 0.15em 1.2em; }
</style>

<!--
Объекты в Linux почти всегда видны как файлы: обычные файлы, каталоги, устройства в /dev,
символьные ссылки, именованные каналы, unix-сокеты; процессы — каталоги в /proc, параметры
ядра — файлы в /sys. Тип объекта показывает первая буква вывода ls -l. Субъекты —
пользователи и группы, но действует от их имени всегда процесс: он получает UID и GID
пользователя. У фонового sleep пользователя bob в /proc видны Uid и Gid 1001.
Правило наследования идентификаторов при fork — в разделе 2.4.
-->

---

# Пользователи и группы идентифицируются числами UID и GID

<div class="grid grid-cols-[1.15fr_1fr] gap-6">
<div>

- В Linux определены **пользователи** (учётные записи) и **группы** пользователей.
- Каждый пользователь уникально идентифицируется числом — **идентификатором пользователя (UID)**.
- Несколько пользователей могут образовывать **группу**; каждая группа уникально идентифицируется числом — **идентификатором группы (GID)**.
- Группы нужны для **единых правил доступа** сразу для множества пользователей: доступ к каталогу проекта даётся группе `project`, а не каждому сотруднику отдельно (лекция 3).
- Пользователь может состоять **в нескольких группах** одновременно.
- Учётная запись — не обязательно человек: службы работают от имени **псевдопользователей** (раздел 2.2).

</div>
<div>

<div class="ug-map">
  <div class="ug-row">
    <div class="bf-block ug-u"><div class="bf-head">bob</div><div class="bf-sub">UID 1001</div></div>
    <div class="ug-links">
      <div class="ug-link">
        <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
        <div class="bf-block"><div class="bf-head">bob · личная</div><div class="bf-sub">GID 1001</div></div>
      </div>
      <div class="ug-link">
        <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
        <div class="bf-block"><div class="bf-head">project · общая</div><div class="bf-sub">GID 1010</div></div>
      </div>
    </div>
  </div>
  <div class="ug-row">
    <div class="bf-block ug-u"><div class="bf-head">carol</div><div class="bf-sub">UID 1002</div></div>
    <div class="ug-links">
      <div class="ug-link">
        <div class="bf-arrow"><div class="bf-arrow-line"></div><div class="bf-arrow-tip"></div></div>
        <div class="bf-block"><div class="bf-head">carol · личная</div><div class="bf-sub">GID 1002</div></div>
      </div>
    </div>
  </div>
</div>

<div class="text-xs opacity-70 mt-2 text-center">
<code>bob</code> состоит в двух группах
</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Имя — для людей, число — для ядра:</b> внутри ОС пользователь и группа определяются
идентификаторами. Сопоставление «имя ↔ число» хранится в базах учётных записей —
разделы 2.2 и 2.3.
</div>

<Refs ids="man-credentials man-group" />

<style>
/* Диаграмма «пользователь → группы» в стиле BlockFlow (слайд «Субъекты и объекты»). */
.ug-map { display: flex; flex-direction: column; gap: 0.9em; margin-top: 0.5em; font-size: 0.78rem; text-align: center; }
.ug-row { display: flex; align-items: center; }
.ug-u { flex: 0 0 7.5em; align-self: stretch; }
.ug-links { display: flex; flex-direction: column; gap: 0.55em; flex: 1; min-width: 0; }
.ug-link { display: flex; align-items: center; }
.ug-link .bf-arrow { flex: 0 0 2.4em; }
.ug-link .bf-block { flex: 1; }
</style>

<!--
Базовые понятия до деталей. Каждый пользователь уникально идентифицируется числом UID,
каждая группа — числом GID. Группы нужны, чтобы задавать единые правила доступа сразу
для многих: каталог проекта открывают группе project, а не каждому сотруднику отдельно.
Справа: у bob две группы — личная и project. Учётные записи заводят не только людям:
службы работают от имени псевдопользователей — подробно в разделе 2.2.
-->

---

# UID и GID: диапазон значений отражает роль учётной записи

<div class="flex gap-1 mt-1 text-center text-xs">
<div class="flex-[1.4]"><div class="py-2 rounded bg-red-600 text-white font-bold text-sm">0</div><b>root</b><br/>суперпользователь</div>
<div class="flex-[1.7]"><div class="py-2 rounded bg-slate-700 text-white font-bold text-sm">1–99</div><b>системные</b><br/>одинаковы во всех Debian/Ubuntu</div>
<div class="flex-[2]"><div class="py-2 rounded bg-slate-700 text-white font-bold text-sm">100–999</div><b>системные</b><br/>создаются пакетами</div>
<div class="flex-[3]"><div class="py-2 rounded bg-sky-600 text-white font-bold text-sm">1000–59999</div><b>пользователи</b><br/>люди: <code>bob</code>, <code>carol</code>…</div>
<div class="flex-[2.4]"><div class="py-2 rounded bg-slate-500 text-white font-bold text-sm">60000–65533</div><b>резерв</b><br/>60000–64999 выделяет Debian; выше — резерв</div>
<div class="flex-[1.2]"><div class="py-2 rounded bg-slate-700 text-white font-bold text-sm">65534</div><b>nobody</b><br/>«никто»</div>
</div>

<div class="text-xs opacity-60 mt-1">
Диапазоны UID — Debian Policy, п. 9.2.2 (показаны основные); Ubuntu наследует их,
границы обычных пользователей — <code>UID_MIN</code>/<code>UID_MAX</code> в <Man p="login.defs(5)" />
</div>

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/15-identification-basics.txt" section="1" title="Ubuntu Server 26.04 · команда id" />

</div>

<InfoCard icon="id-card" head="Команда id">

показывает числа и — в скобках — имена (<Man p="id(1)" />); сопоставление
«имя ↔ число» хранится в <code>/etc/passwd</code> и <code>/etc/group</code>.

</InfoCard>
</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-red-500 bg-red-500/10">
<b>UID 0 = root</b>: «привилегированные процессы (эффективный UID 0) обходят все проверки
прав ядра» — <Man p="capabilities(7)" />. Поэтому вход под root строго ограничивают.
</div>

</v-click>

<Refs ids="debian-policy man-id man-capabilities" />

<!--
Диапазоны UID задаёт Debian Policy, п. 9.2.2: 0 — root; 1–99 — системные, одинаковые во всех
системах; 100–999 — системные, создаются пакетами; 1000–59999 — люди; 60000–64999 выделяет
проект Debian по мере необходимости, 65000–65533 зарезервированы; 65534 — nobody.
UID 0 — root: привилегированные процессы обходят все проверки прав ядра, поэтому вход
под root строго ограничивают.
-->

---

# Специальные пользователи: каждой службе — своя учётная запись

<div>

Не каждая учётная запись принадлежит человеку: большинство строк базы пользователей
Ubuntu Server 26.04 — **служебные** записи. Устройство таких «псевдопользователей» —
в разделе 2.2; назначение типичных записей:

</div>

<div class="t-table text-xs mt-2">

| Пользователь | UID | Назначение |
|---|---|---|
| `root` | 0 | Суперпользователь: владелец системных файлов; процессы с UID 0 обходят проверки прав ядра |
| `daemon`, `bin`, `sys` | 1–3 | Исторические записи первых Unix (владение системными каталогами); сохраняются ради совместимости |
| `www-data` | 33 | От его имени веб-сервер (nginx, Apache) обслуживает запросы: компрометация сайта не даёт прав root |
| `_apt` | 42 | Непривилегированная загрузка пакетов: скачивая файлы, `apt` сбрасывает права root |
| `systemd-network`, `systemd-resolve` | 998, 995 | Сетевые службы systemd: настройка интерфейсов и DNS-резолвер |
| `sshd` | 994 | Разделение привилегий OpenSSH: обработка сетевого трафика до аутентификации идёт без прав root |
| `nobody` | 65534 | Минимальная «общая» идентичность: процессы без своей записи, неизвестные UID в NFS |

</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Принцип наименьших привилегий:</b> каждая служба работает под собственной учётной
записью, чтобы её компрометация не давала доступа к чужим данным и не требовала root.
UID из диапазона 100–999 назначаются при установке пакета и различаются между системами.
</div>

</v-click>

<Refs ids="debian-policy man-capabilities" />

<!--
Большинство записей в системе — служебные. root (UID 0) — владелец системных файлов,
его процессы обходят проверки прав. daemon/bin/sys — наследие первых Unix. Современные
примеры: www-data — веб-сервер, _apt — непривилегированная загрузка пакетов,
systemd-network и systemd-resolve — сетевые службы systemd, sshd — разделение привилегий
OpenSSH (сетевой код до аутентификации работает без root). nobody — минимальная общая
идентичность. Смысл — принцип наименьших привилегий: компрометация одной службы не даёт
чужих данных. UID 100–999 назначаются при установке пакетов и от системы к системе
различаются.
-->

---

# Первичная и вторичные группы

<div class="grid grid-cols-2 gap-4">
<InfoCard icon="user" head="Первичная группа">

- одна у каждого пользователя: поле GID в `/etc/passwd`;
- в Debian/Ubuntu по умолчанию — личная группа с тем же именем;
- группа-владелец новых файлов пользователя.

</InfoCard>
<InfoCard icon="users" head="Вторичные (дополнительные) группы">

- определены в файле `/etc/group`;
- «используются для проверки прав доступа к файлам» — <Man p="credentials(7)" />;
- задают единые правила доступа для множества пользователей.

</InfoCard>
</div>

<div class="grid grid-cols-[1.5fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/15-identification-basics.txt" section="2" title="Ubuntu Server 26.04 · группы трёх пользователей">
  <TCallout :line="2" :col="15" :span="13" :n="1" />
  <TCallout :line="4" :col="33" :span="39" :n="2" />
  <TCallout :line="6" :col="33" :span="18" :n="3" />
  <TCallout :line="12" :col="16" :span="9" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>gid=1001(bob)</code> — первичная группа: её GID — 4-е поле строки <code>/etc/passwd</code></div>
<div><span class="co-ball">2</span> <code>groups=…</code> — все группы процесса; вторичные у <code>alice</code> — <code>adm</code> и <code>project</code></div>
<div><span class="co-ball">3</span> у <code>carol</code> вторичных групп нет — только личная</div>
<div><span class="co-ball">4</span> вторичные члены группы перечислены в 4-м поле <code>/etc/group</code></div>
</div>
</div>
</div>

<Refs ids="man-credentials man-group" />

<!--
У каждого пользователя одна первичная группа — её GID записан в /etc/passwd; от имени этой
группы создаются новые файлы. Вторичных групп может быть много — они определены в файле
/etc/group. Ядро проверяет права по всем группам процесса. Контраст на примере: у bob
вторичная группа project, у alice — adm и project, у carol вторичных нет.
-->

---
layout: section
---

# 2. Идентификация

<SectionTOC prefix="2" :current="2" :items="[
  'Субъекты и объекты',
  'Файл паролей <code>/etc/passwd</code>',
  'Файл групп <code>/etc/group</code>',
  'Идентификаторы процесса',
  'Реализация в ядре Linux',
]" />

---

# `/etc/passwd`: назначение и формат

<div>

**`/etc/passwd`** — основная локальная **база учётных записей**: по ней система
сопоставляет имя входа с UID и узнаёт параметры учётной записи — первичную группу,
домашний каталог, оболочку (<Man p="passwd(5)" />). Имя историческое: когда-то здесь
хранились и пароли.

Формат: текстовый файл; **одна строка — одна учётная запись**; строка — **7 полей**,
разделённых двоеточием `:`. Поле не может содержать `:`; пустое поле — значение не задано.

</div>

<FieldRecord class="mt-3" size="1rem" legendSize="0.78rem" :cols="2"
  :fields="['bob', { t: 'x', hot: true }, '1001', '1001', '', '/home/bob', '/bin/bash']"
  :legend="[
    'имя пользователя (login name)',
    { t: 'признак наличия пароля', hot: true },
    'UID — идентификатор пользователя',
    'GID — идентификатор первичной группы пользователя',
    'комментарий (GECOS): ФИО, телефон — здесь пусто',
    'домашний каталог',
    'командный интерпретатор (оболочка)',
  ]"
/>

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-3 items-start">
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Поле 2 — признак наличия пароля</b>
<div class="mt-1 space-y-1">
<div><code>x</code> — хеш пароля хранится в <code>/etc/shadow</code> (раздел 3)</div>
<div class="text-red-600"><i>пусто</i> — пароль не установлен: вход <b>без пароля</b> (<Man p="passwd(5)" />)</div>
</div>
</div>
<div>

<TerminalCapture src="captures/16-etc-passwd.txt" section="2" title="Ubuntu Server 26.04 · поле 2" />

</div>
</div>

<Refs ids="man-passwd" />

<!--
Определение: /etc/passwd — основная локальная база учётных записей; по ней система
сопоставляет имя входа с UID и узнаёт параметры учётной записи. Название историческое —
когда-то файл хранил и пароли. Формат: одна строка — одна учётная запись, семь полей
через двоеточие. Поле 2 — признак наличия пароля: x — хеш лежит в /etc/shadow (раздел 3);
пустое поле — пароля нет, вход без пароля. Поля 3 и 4 — UID и GID первичной группы,
последнее поле — программа, которую запустит вход.
-->

---

# Пример `/etc/passwd`

<div class="grid grid-cols-[1.45fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/16-etc-passwd.txt" section="1" title="Ubuntu Server 26.04 · cat /etc/passwd" fontSize="0.42rem" highlight="20,26-28">
  <TCallout :line="2" :col="78" :n="1" />
  <TCallout :line="3" :col="78" :n="2" />
  <TCallout :line="14" :col="78" :n="3" />
  <TCallout :line="24" :col="78" :n="4" />
  <TCallout :line="26" :col="78" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>root</code> — суперпользователь: UID 0, дом <code>/root</code>, настоящая оболочка</div>
<div><span class="co-ball">2</span> <code>daemon</code>, <code>bin</code>, <code>sys</code>… — системные записи, одинаковые во всех Debian/Ubuntu (UID 1–99)</div>
<div><span class="co-ball">3</span> <code>www-data</code>, <code>_apt</code> — псевдопользователи служб: вместо оболочки — «запрещающий» <code>nologin</code></div>
<div><span class="co-ball">4</span> <code>systemd-*</code>, <code>sshd</code> — псевдопользователи, созданные пакетами (UID 100–999)</div>
<div><span class="co-ball">5</span> люди (выделены): <code>ubuntu</code>, <code>bob</code>, <code>carol</code>, <code>alice</code> — UID ≥ 1000, оболочка <code>bash</code>, дом в <code>/home</code></div>
</div>
</div>
</div>

<Refs ids="man-passwd debian-policy" />

<!--
Реальный файл с демонстрационного сервера. Сверху вниз: root; системные записи первых Unix с UID 1–99,
одинаковые во всех Debian/Ubuntu; псевдопользователи служб — www-data, _apt — с
«запрещающей» оболочкой nologin; записи, созданные пакетами при установке (systemd-*,
sshd) с UID из диапазона 100–999; и люди — ubuntu, bob, carol, alice — UID от 1000,
настоящая оболочка и домашний каталог в /home. Термин «псевдопользователь» и приёмы
их создания — на следующем слайде.
-->

---

# Псевдопользователи и «запрещающие» оболочки

<div>

**Псевдопользователь** — служебная учётная запись: она владеет файлами, от её имени
работают процессы, но интерактивный вход человека не предполагается.

Отдельного признака «служебная запись» в `/etc/passwd` нет — псевдопользователя создают,
заполняя поля обычной записи так, чтобы вход был невозможен. Типичные приёмы:

</div>

<div class="t-table text-xs mt-2">

| Приём | Как используется |
|---|---|
| `/usr/sbin/nologin`<br/>в 7-м поле | Вместо оболочки при входе запускается <Man p="nologin(8)" />: печатает «This account is currently not available» (или содержимое `/etc/nologin.txt`) и завершается с ненулевым кодом. Так оформлено большинство служебных записей Ubuntu: `sshd:x:994:…:/run/sshd:/usr/sbin/nologin` |
| `/bin/false`<br/>в 7-м поле | «Оболочка» молча завершается с кодом 1 — вход не удаётся; классический приём до появления `nologin`, например `useradd -r -s /bin/false backup-agent` |
| `/bin/true`<br/>в 7-м поле | Завершается с кодом 0: вход «успешен», но ничего не выполняется — редкие случаи, когда вызывающей программе важен лишь успешный код возврата |
| `/nonexistent`<br/>в 6-м поле | Несуществующий домашний каталог: службе негде (и незачем) хранить «домашние» файлы — `_apt:x:42:65534::/nonexistent:/usr/sbin/nologin` |

</div>

<Refs ids="man-nologin man-passwd" />

<!--
Псевдопользователь — обычная запись в /etc/passwd, поля которой заполнены так, чтобы
интерактивный вход был невозможен: «запрещающая» оболочка в 7-м поле (nologin — вежливое
сообщение и ненулевой код; /bin/false — молча код 1; /bin/true — код 0 для редких случаев,
когда важен успешный возврат) и несуществующий домашний каталог в 6-м. Примеры — из
реального файла с предыдущего слайда. Заметим: nologin и блокировка пароля не мешают
root запускать службы от имени такой записи.
-->

---

# Права доступа к `/etc/passwd`

<div class="grid grid-cols-[1fr_1.2fr] gap-4 items-center">
<div>

<TerminalCapture src="captures/16-etc-passwd.txt" section="3" title="Ubuntu Server 26.04 · права на базы учётных записей" />

</div>
<div>

**`0644` — читают все:** множество программ отображают UID в имена (`ls -l`, `ps`, `stat`).
**Пишет только root**; свои поля пользователь меняет через setuid-утилиты <Man p="passwd(1)" />,
<Man p="chsh(1)" />, <Man p="chfn(1)" />.

</div>
</div>

**Файл читает любой пользователь — что тогда хранить во 2-м поле?**

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<v-click>
<div>
<b class="text-red-600">Пароль в открытом виде: утечка неизбежна</b>
<div class="mt-1 p-2 border border-slate-400/40 rounded">
Так хранила пароли CTSS (MIT) — первая система с парольным входом; уже в 1966 г.
её файл паролей оказался распечатанным на терминале каждого входящего.
Подробно об этом инциденте — раздел 3.1.
</div>
</div>
</v-click>
<v-click>
<div>
<b class="text-red-600">Хеш пароля: приглашение к перебору</b>
<HistoryNote label="Исторический экскурс · червь Морриса, 1988" class="mt-1">
Червь Морриса (2 ноября 1988 г., поражено ~10 % тогдашней сети) копировал хеши из
общедоступного <code>/etc/passwd</code> и подбирал пароли офлайн: вариации имени учётной
записи, встроенный словарь из 432 слов, затем <code>/usr/dict/words</code> — со своей
быстрой реализацией <code>crypt</code>. Подобранный пароль открывал соседние машины.
</HistoryNote>
</div>
</v-click>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> секрету не место в общедоступном файле. Во 2-м поле остаётся <code>x</code>,
а хеш вынесен в <code>/etc/shadow</code> с правами <code>0640 root:shadow</code> — раздел 3.
</div>

</v-click>

<Refs ids="morris-thompson corbato morris-worm" />

<!--
Права: 0644 — файл читают все, потому что множество программ превращают UID в имена;
пишет только root, пользователь меняет свои поля через setuid-утилиты. Отсюда вопрос:
что хранить во 2-м поле общедоступного файла? Открытый текст — утечка неизбежна:
первой это показала CTSS в 1966 г., когда файл паролей распечатался входящим вместо
«сообщения дня»; детали инцидента — в разделе 3.1. Хранение хешей тоже небезопасно: червь Морриса 1988 г. вёл перебор
по словарю к скопированным из passwd хешам (вариации имени, 432 встроенных слова, /usr/dict/words,
быстрый crypt) — Spafford, 1988. Вывод: x в поле 2, хеш — в /etc/shadow (раздел 3).
-->

---

# Демо 01: привилегии определяются UID, а не именем

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/01-passwd-uid-zero.txt" section="1" title="demo 01 · до: исходная запись alice">
  <TCallout :line="2" :col="9" :span="4" :n="1" />
  <TCallout :line="5" :col="1" :span="15" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/01-passwd-uid-zero.txt" section="2" title="demo 01 · после: третье поле подменено">
  <TCallout :line="1" :col="30" :span="10" :n="3" />
  <TCallout :line="4" :col="9" :span="1" :n="4" />
  <TCallout :line="7" :col="1" :span="11" :n="5" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1.5 mt-1">
<div><span class="co-ball">1</span> 3-е поле строки <code>alice</code> — UID <code>1001</code>: обычный пользователь</div>
<div><span class="co-ball">2</span> <code>id</code> подтверждает: <code>uid=1001(alice)</code></div>
<div><span class="co-ball">3</span> root заменяет 3-е поле на <code>0</code>; имя записи не меняется</div>
<div><span class="co-ball">4</span> в строке теперь UID <code>0</code> — как у <code>root</code></div>
<div><span class="co-ball">5</span> <code>uid=0(root)</code>: для ядра <code>alice</code> — суперпользователь</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> запись в <code>/etc/passwd</code> равносильна получению прав root — поэтому
обычным пользователям файл доступен <b>только на чтение</b> (<code>0644</code>: пишет лишь root).
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/01-passwd-uid-zero.sh</code>. Уже запущенные процессы подмена UID в файле не затрагивает.
</div>

<!--
Демо: сначала исходное состояние — строка alice в /etc/passwd (UID 1001) и вывод id;
затем root заменяет третье поле на 0 — и id показывает uid=0(root), хотя имя не менялось.
Привилегии определяются числовым UID, а не именем. Транскрипт снят в отдельном контейнере:
alice там создана первой (UID 1001). Вывод: запись в /etc/passwd эквивалентна root-доступу —
поэтому обычным пользователям файл доступен только на чтение. Полный сценарий —
demos/01-passwd-uid-zero.sh.
-->

---
layout: section
---

# 2. Идентификация

<SectionTOC prefix="2" :current="3" :items="[
  'Субъекты и объекты',
  'Файл паролей <code>/etc/passwd</code>',
  'Файл групп <code>/etc/group</code>',
  'Идентификаторы процесса',
  'Реализация в ядре Linux',
]" />

---

# `/etc/group`: назначение и формат

<div>

**`/etc/group`** — локальная **база групп**: определяет группы системы — по ней система
сопоставляет имя группы с GID и узнаёт **состав** группы, то есть вторичное членство
пользователей (<Man p="group(5)" />). Вместе с `/etc/passwd` файл полностью задаёт
принадлежность пользователя к группам (раздел 2.1).

Формат: текстовый файл; **одна строка — одна группа**; строка — **4 поля**,
разделённых двоеточием `:`. Поле не может содержать `:`; пустое поле — значение не задано.

</div>

<FieldRecord class="mt-3" size="1rem" legendSize="0.78rem" :cols="2"
  :fields="['project', { t: 'x', hot: true }, '1010', 'bob,alice']"
  :legend="[
    'имя группы (group name)',
    { t: 'признак наличия пароля группы', hot: true },
    'GID — идентификатор группы',
    'члены группы — те, для кого она вторичная, — через запятую',
  ]"
/>

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-3 items-start">
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Поле 2 — признак наличия пароля группы</b>
<div class="mt-1 space-y-1">
<div><code>x</code> — хеш пароля группы хранится в <code>/etc/gshadow</code> (раздел 3)</div>
<div><i>пусто</i> — пароль группы не задан (<Man p="group(5)" />)</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Первичная группа пользователя задаётся <b>не здесь</b>, а 4-м полем <code>/etc/passwd</code>;
имя пользователя не обязано присутствовать в списке членов своей первичной группы —
в примере список личной группы <code>bob</code> пуст.
</div>

</div>
<div>

<TerminalCapture src="captures/15-identification-basics.txt" section="2" lines="7-12" title="Ubuntu Server 26.04 · строки /etc/group" />

</div>
</div>

<Refs ids="man-group" />

<!--
Определение: /etc/group — локальная база групп: определяет группы системы, сопоставляет
имя группы с GID и перечисляет членов, то есть вторичное членство пользователей; вместе
с /etc/passwd файл полностью задаёт принадлежность пользователя к группам. Формат —
как у passwd: одна строка — одна группа, четыре поля через двоеточие. Поле 2 — признак
наличия пароля группы: x — хеш в /etc/gshadow (раздел 3), пусто — пароль не задан;
на практике пароли групп применяются редко. Поле 4 — члены группы через запятую: для
них группа вторичная. Первичная группа задаётся не здесь, а GID-полем /etc/passwd,
поэтому список личной группы bob пуст.
-->

---

# Демо 02: первичная и вторичные группы

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/02-group-membership.txt" section="1" title="demo 02 · членство bob в двух базах" fontSize="0.6rem">
  <TCallout :line="2" :col="29" :span="43" :n="1" />
  <TCallout :line="5" :col="9" :span="10" :n="2" />
  <TCallout :line="8" :col="1" :span="11" :n="3" />
  <TCallout :line="11" :col="12" :span="4" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>groups=…</code> — все группы <code>bob</code>: первичная <code>bob</code> и вторичные <code>adm</code>, <code>sudo</code>, <code>users</code></div>
<div><span class="co-ball">2</span> вторичное членство записано в 4-м поле строк <code>/etc/group</code></div>
<div><span class="co-ball">3</span> личная группа <code>bob</code>: список членов пуст — первичное членство здесь не хранится</div>
<div><span class="co-ball">4</span> первичная группа — GID из 4-го поля <code>/etc/passwd</code></div>
</div>
</div>

<v-click>

<InfoCard icon="warning" fill="amber" head="Группа sudo" class="mt-2 text-xs">

членство в группе `sudo` (GID 27) даёт право выполнять команды от имени root —
состав этой группы нужно контролировать.

</InfoCard>

</v-click>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> членство в группах описано двумя файлами: первичная группа — GID
в <code>/etc/passwd</code>, вторичные — списки в <code>/etc/group</code>. <code>id bob</code>
читает базу; уже открытый сеанс изменения состава групп не увидит — нужен новый вход.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/02-group-membership.sh</code>.
</div>

<!--
Демо: членство bob записано в двух базах. id bob: gid — первичная группа, groups —
полный список. В /etc/group bob перечислен в 4-м поле строк adm, sudo, users — это его
вторичные группы; список личной группы bob пуст, потому что первичное членство в
/etc/group не записывается — его задаёт GID в /etc/passwd. Транскрипт снят отдельным
сценарием (bob 1001, группы adm/sudo/users). Попутно: членство в sudo (GID 27) даёт
право выполнять команды от имени root — состав группы нужно контролировать. Изменения
состава групп действуют после нового входа. Полный сценарий —
demos/02-group-membership.sh.
-->

---
layout: section
---

# 2. Идентификация

<SectionTOC prefix="2" :current="4" :items="[
  'Субъекты и объекты',
  'Файл паролей <code>/etc/passwd</code>',
  'Файл групп <code>/etc/group</code>',
  'Идентификаторы процесса',
  'Реализация в ядре Linux',
]" />

---

# Четыре идентификатора процесса определяют его привилегии

<div>

Субъект для монитора обращений — **процесс** (раздел 2.1). Процесс идентифицируется с помощью
UID пользователя, GID его первичной и дополнительных групп. Причём для каждого процесса 
в учётных данных (credentials, <Man p="credentials(7)" />) определены по четыре вида UID и GID:

</div>

<div class="t-table text-xs mt-2">

| Идентификатор | Название | Назначение |
|---|---|---|
| **ruid** / rgid | real — реальный | кто запустил процесс: наследуется от родителя и хранит «настоящего» пользователя |
| **euid** / egid | effective — эффективный | по нему ядро проверяет привилегии процесса; euid 0 — права root |
| **suid** / sgid | saved — сохранённый | копия euid на момент запуска программы: позволяет временно сбросить привилегии и затем вернуть их |
| **fsuid** / fsgid | filesystem — файловый | использовался в проверках доступа к файлам; сейчас всегда совпадает с euid, <Man p="setfsuid(2)" /> — исторический |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
В <code>/proc/PID/status</code> строки <code>Uid:</code> и <code>Gid:</code> содержат четыре
колонки <b>именно в этом порядке</b>: real, effective, saved, filesystem (<Man p="proc(5)" />).
Строка <code>Groups:</code> — вторичные группы процесса (раздел 2.3).
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
У обычного процесса все четыре значения совпадают. Расходятся они после запуска
<b>setuid/setgid-программы</b> (например, <code>passwd</code>) или системных вызовов
изменения идентификаторов — далее в этом разделе.
</div>

<Refs ids="man-credentials man-proc kerrisk-tlpi" />

<!--
Терминология: у процесса не один UID, а четыре (и столько же GID) — часть его учётных
данных. Решения о правах ядро принимает по effective (для файлов — по filesystem, который
сегодня совпадает с effective). Real хранит, кто запустил. Saved — копия euid на момент
запуска программы: нужен, чтобы программа могла временно понизить привилегии и вернуть их
(демо 04). Порядок колонок Uid:/Gid: в /proc/PID/status — real, effective, saved,
filesystem; это ответ на вопрос со слайда «Субъекты и объекты» (раздел 2.1).
-->

---

# Демо 03: идентификаторы процесса в `/proc`

<div class="grid grid-cols-[1fr_1.3fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/03-process-credentials.txt" section="1" title="demo 03 · оболочка root">
  <TCallout :line="3" :col="9" :span="25" :n="1" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/03-process-credentials.txt" section="2" title="demo 03 · процесс пользователя bob">
  <TCallout :line="5" :col="9" :span="28" :n="2" />
  <TCallout :line="10" :col="10" :span="22" :n="3" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> у оболочки root все четыре идентификатора — 0; порядок колонок: real, effective, saved, filesystem</div>
<div><span class="co-ball">2</span> фоновый <code>sleep</code> пользователя <code>bob</code>: четыре значения 1001 — у обычного процесса они совпадают</div>
<div><span class="co-ball">3</span> те же идентификаторы по отдельности показывает <code>ps</code> (столбцы <code>RUID</code>…<code>FSUID</code>, <code>RGID</code>…<code>FSGID</code>)</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> пока процесс не запускал setuid-программ и не менял идентификаторы сам,
все четыре значения равны UID вошедшего пользователя и просто наследуются.
Когда они расходятся — следующий слайд.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/03-process-credentials.sh</code>.
</div>

<!--
Сначала root-оболочка: grep по /proc/$$/status — четыре нуля в Uid и Gid. Затем фоновый
sleep пользователя bob: четыре 1001. Пока все значения совпадают; те же числа по
отдельности выводит ps (ruid,euid,suid,fsuid). Способы, которыми значения могут
разойтись, — следующий слайд.
-->

---

# euid расходится с ruid в двух сценариях

<div>

В демонстрации все четыре идентификатора совпадали. Ядро изменяет euid независимо
от ruid только в двух точках — других способов «разойтись» у идентификаторов нет:

</div>

<div class="t-table text-xs mt-2">

| Механизм | Момент срабатывания | Кто управляет |
|---|---|---|
| **setuid/setgid-бит** на исполняемом файле | запуск программы: при <Man p="execve(2)" /> ядро делает euid/egid равным владельцу/группе файла | владелец файла или root заранее помечает файл: `chmod u+s`, `chmod g+s` |
| **системные вызовы** <Man p="setuid(2)" />, <Man p="seteuid(2)" />, <Man p="setresuid(2)" /> и их GID-аналоги | в любой момент работы: процесс меняет собственные идентификаторы | ядро: привилегированному процессу — любые значения, остальным — лишь перестановка своих (следующий слайд) |

</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Типовые сценарии, требующие euid&nbsp;≠&nbsp;ruid:</b>
<div class="mt-1 space-y-1">
<div>– <b>доступ пользователя к защищённому объекту</b>: <Man p="passwd(1)" /> с euid 0 пишет в <code>/etc/shadow</code>, а по ruid определяет, чей пароль менять (демо далее);</div>
<div>– <b>выполнение команд от имени другого пользователя</b>: setuid-root-программы <code>su</code> и <code>sudo</code> (раздел 7);</div>
<div>– <b>доступ через группу файла</b>: setgid-программа <Man p="chage(1)" /> читает <code>/etc/shadow</code> с egid группы <code>shadow</code>, не включая в неё пользователей (раздел 3);</div>
<div>– <b>временное понижение привилегий</b>: привилегированный процесс опускает euid до ruid на время опасных операций и затем возвращает — слайд «Безопасное программирование».</div>
</div>
</div>

<Refs ids="man-credentials man-execve man-setuid kerrisk-tlpi" />

<!--
До сих пор идентификаторы совпадали. Разойтись euid и ruid могут ровно двумя путями:
setuid/setgid-бит на исполняемом файле (срабатывает внутри execve: euid становится
равным владельцу файла) и системные вызовы семейства set*uid — их правила на следующем
слайде. fork не в счёт: он лишь копирует потомку уже разошедшийся набор родителя.
Сценарии: passwd (euid даёт запись в shadow, ruid говорит, чей пароль менять), su и
sudo (смена пользователя), setgid-программы для доступа через группу файла (chage
и expiry в Ubuntu 26.04 — setgid shadow; wall с 24.04 setgid-бита лишён,
CVE-2024-28085), временное понижение привилегий
привилегированной программой — развитие в слайде о безопасном программировании.
Демонстрация расхождения на примере passwd — после него.
-->

---

# Системные вызовы изменения идентификаторов

<div>

Процесс не может произвольно «стать» другим пользователем: идентификаторы хранит ядро,
а менять их позволяют лишь системные вызовы со строгими правилами (<Man p="credentials(7)" />).

</div>

<div class="t-table text-xs mt-2">

| Вызов | Привилегированный процесс (euid 0) | Непривилегированный процесс |
|---|---|---|
| <Man p="setuid(2)" />&nbsp;`(u)` | устанавливает **все три** (ruid, euid, suid) в `u` — переход необратим | устанавливает **только euid**; `u` обязан совпадать с ruid или suid |
| <Man p="seteuid(2)" />&nbsp;`(u)` | устанавливает euid в любое значение | устанавливает euid; `u` — только своё ruid или suid: «переключение» между уже имеющимися значениями |
| <Man p="setresuid(2)" />&nbsp;`(r,e,s)` | задаёт все три независимо; `-1` — «не менять» | каждое новое значение — одно из текущих ruid/euid/suid; `-1` — «не менять» |

</div>

<div class="text-xs opacity-70 mt-1">
У каждого вызова есть GID-аналог: <Man p="setgid(2)" />, <Man p="setegid(2)" />,
<Man p="setresgid(2)" />. «Привилегированный» — строго: имеющий capability
<code>CAP_SETUID</code> (<Man p="capabilities(7)" />); классически это euid 0.
</div>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Ключевое правило:</b> непривилегированный процесс не может получить <b>чужой</b>
идентификатор — только переставлять <b>свои</b> ruid/euid/suid. Новые UID появляются
у процесса лишь двумя путями: вход в систему и запуск setuid-программ.
</div>

<Refs ids="man-setuid man-seteuid man-setresuid man-credentials" />

<!--
Менять идентификаторы можно только через системные вызовы, и для непривилегированного
процесса выбор строго ограничен: любой из вызовов разрешает лишь значения из его
собственного набора ruid/euid/suid. setuid у привилегированного процесса — необратимый
переход (затирает все три), у непривилегированного — меняет только euid. seteuid меняет
только euid. setresuid задаёт все три явно и поэтому рекомендуется для надёжного сброса.
Следствие: получить чужой UID процесс может только через логин или setuid-программу.
-->

---

# `fork(2)` и `execve(2)`: правила наследования

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Назначение saved UID:</b> setuid-программа понижает привилегии на время опасных операций —
<code>seteuid(ruid)</code> — и затем возвращает их: <code>seteuid(suid)</code>.
Непривилегированному процессу ядро разрешает установить euid только в ruid или suid
(предыдущий слайд) — без сохранённой копии вернуть привилегии было бы невозможно.
</div>

<div class="grid grid-cols-[1fr_1.35fr] gap-4 mt-3 items-start">
<div>

**Алгоритм ядра** (Керриск, гл. 9; <Man p="execve(2)" />):

```text
при fork():
    потомок получает точные копии
    всех идентификаторов родителя

при execve(P):
    если setuid-бит(P):
        euid ← UID владельца P
    если setgid-бит(P):
        egid ← GID группы P
    suid ← euid    # всегда
    sgid ← egid    # всегда
    ruid, rgid не меняются
```

</div>
<div>

<div class="t-table text-xs">

| Действие | ruid | euid | suid |
|---|---|---|---|
| `fork(2)`: создание потомка | наследуется копия | наследуется копия | наследуется копия |
| `execve(2)`: обычная программа | сохраняется | сохраняется | перезаписывается копией euid |
| `execve(2)`: setuid-программа | сохраняется | становится равным UID владельца файла | перезаписывается копией нового euid |

</div>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>Ловушка:</b> suid перезаписывается при <b>каждом</b> <code>execve</code>. Программа
с временно пониженным euid, запустив другую программу, теряет сохранённые привилегии
насовсем — а с непониженным передаст euid 0 дальше (демо 04).
</div>

</div>
</div>

<Refs ids="man-execve man-credentials kerrisk-tlpi" />

<!--
Два механизма передачи идентификаторов. fork копирует всё. execve: у обычных файлов
euid сохраняется, у setuid-файлов становится равным владельцу; saved UID при каждом
execve перезаписывается копией (нового) euid — в этом и ловушка: временно пониженные
привилегии execve фиксирует навсегда, а непониженные — передаёт запускаемой программе.
Алгоритм — по Керриску (TLPI, гл. 9) и execve(2). «Качели привилегий» seteuid(ruid)/seteuid(suid)
работают благодаря сохранённому UID: непривилегированному euid разрешён только из
множества {ruid, suid}.
-->

---

# Концепция безопасного программирования

<div>

setuid-программы — классический источник уязвимостей: любая ошибка в них исполняется
с правами root. Правила обращения с привилегиями (Керриск, гл. 38):

</div>

<div class="grid grid-cols-[1.1fr_1fr] gap-4 -mt-5 items-start">
<div>

**Держать привилегии минимум времени** — «качели привилегий»:

```c
uid_t euid = geteuid();  /* владелец исполняемого файла */
/* привилегированные операции */

seteuid(getuid());       /* сброс: права пользователя */
/* …разбор ввода, вычисления, файлы… */

seteuid(euid);           /* возврат: права владельца */
/* привилегированные операции */

setuid(getuid());       /* окончательный сброс прав */
```

<div class="mt-1 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Привилегии больше не нужны — <b>сбрасывать насовсем</b>: <code>setuid(getuid())</code>
при euid 0 затирает все три идентификатора; надёжнее явный
<code>setresuid(u,&nbsp;u,&nbsp;u)</code>.
</div>

</div>
<div class="text-xs">

**Типичные ошибки:**

- **не проверен код возврата** вызова `set*uid` — незамеченный отказ сброса привилегий
  оборачивался уязвимостями (sendmail); проверять результат и `getresuid(2)`;
- **временный сброс считают окончательным**: suid наследуется при `fork(2)`
  и перезаписывается только `execve`/`setuid` — потомок вернёт euid 0 (демо 04);
- **оболочка из привилегированного процесса**: `system()`, `popen()` с euid 0 —
  запуск интерпретатора с правами root.

**Лучше вообще без setuid root:** отдельный псевдопользователь службы
(раздел 2.2), файловые capabilities (<Man p="capabilities(7)" />), `sudo` (раздел 7).

</div>
</div>

<Refs ids="kerrisk-tlpi man-setuid man-capabilities" />

<!--
Концепция безопасного программирования с привилегиями — по Керриску (TLPI, гл. 38
Writing Secure Privileged Programs) и Saltzer–Schroeder (принцип наименьших привилегий).
«Качели привилегий»: сбросить euid сразу после старта, возвращать только вокруг привилегированной
операции. Насовсем — setuid(getuid()) или явный setresuid(u,u,u); обязательно проверять
код возврата: у sendmail неудавшийся (из-за лимита) setuid однажды остался незамеченным.
Помнить о наследовании: suid переживает fork — «пониженные» воркеры могут вернуть root.
Современная альтернатива setuid-root — служебные учётные записи, file capabilities, sudo.
-->

---

# Демо 03: setuid-программа работает с чужим euid

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/03-process-credentials.txt" section="3" title="demo 03 · passwd, запущенный bob">
  <TCallout :line="2" :col="4" :span="1" :n="1" />
  <TCallout :line="2" :col="14" :span="4" :n="2" />
  <TCallout :line="8" :col="9" :span="4" :n="3" />
  <TCallout :line="8" :col="17" :span="17" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> у <code>/usr/bin/passwd</code> вместо <code>x</code> — бит <code>s</code> (setuid): «при запуске дать процессу euid владельца файла»</div>
<div><span class="co-ball">2</span> владелец файла — <code>root</code></div>
<div><span class="co-ball">3</span> ruid не изменился: 1001 — по нему <code>passwd</code> знает, чей пароль менять</div>
<div><span class="co-ball">4</span> euid, suid и fsuid стали 0 — процесс действует с правами root; внизу то же показывает <code>ps</code></div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> setuid-программа работает с правами <b>владельца файла</b>, но по ruid «помнит»
реального пользователя — так <Man p="passwd(1)" /> пишет в недоступный остальным
<code>/etc/shadow</code> (раздел 3). Значения — в точности по алгоритму
<Man p="execve(2)" />: euid стал равен владельцу файла, suid — копии нового euid.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/03-process-credentials.sh</code>.
</div>

<!--
Ответ на вопрос «зачем процессу отдельные real и effective»: passwd должен записывать
в недоступный пользователю /etc/shadow, поэтому файл /usr/bin/passwd имеет setuid-бит:
при execve euid (и вслед за ним suid и fsuid) становится равным владельцу файла — root.
ruid остаётся прежним: по нему passwd знает, чей пароль менять. Демонстрация
подтверждает алгоритм execve с предыдущих слайдов.
-->

---

# Демо 04: `fork` наследует все идентификаторы

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/04-uid-inheritance.txt" section="1" title="demo 04 · подготовка: setuid-утилита idprobe" fontSize="0.5rem" />

<div class="mt-2" />

<TerminalCapture src="captures/04-uid-inheritance.txt" section="2" title="demo 04 · idprobe fork (печатает getresuid)">
  <TCallout :line="2" :col="42" :span="13" :n="1" />
  <TCallout :line="3" :col="42" :span="16" :n="2" />
  <TCallout :line="4" :col="32" :span="26" :n="3" />
  <TCallout :line="5" :col="42" :span="6" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> setuid-бит на <code>idprobe</code> дал euid = suid = 0; ruid остался 1001</div>
<div><span class="co-ball">2</span> родитель временно сбросил привилегии: <code>seteuid(ruid)</code> изменил только euid — suid всё ещё 0</div>
<div><span class="co-ball">3</span> потомок после <code>fork</code> — точные копии всех трёх идентификаторов, включая suid = 0</div>
<div><span class="co-ball">4</span> потомку достаточно <code>seteuid(0)</code>, чтобы вернуть права root (родителю — тоже)</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> «сброшенные» через <code>seteuid</code> привилегии не исчезают при
<code>fork</code>: потомок наследует suid = 0 и может вернуть root. Программа, понизившая
euid и запускающая воркеры, не делает их непривилегированными.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/04-uid-inheritance.sh</code> — компилирует <code>idprobe</code> и прогоняет
крайние случаи наследования.
</div>

<!--
Сверху подготовка: сборка idprobe (печатает getresuid), setuid-бит, владелец root.
Запуск bob: setuid-бит дал euid=suid=0. Родитель понизил привилегии (seteuid(ruid))
до fork — потомок унаследовал пониженный euid, но и suid=0 тоже: обоим достаточно
seteuid(0), чтобы вернуть права. Классическая ошибка: программа «сбросила привилегии»
через seteuid и форкает воркеров, считая их непривилегированными.
-->

---

# Демо 04: сброс привилегий — `seteuid` против `setuid`

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/04-uid-inheritance.txt" section="3" title="demo 04 · idprobe drop: пробует открыть /etc/shadow">
  <TCallout :line="4" :col="41" :span="16" :n="1" />
  <TCallout :line="5" :col="22" :span="17" :n="2" />
  <TCallout :line="6" :col="41" :span="6" :n="3" />
  <TCallout :line="8" :col="41" :span="19" :n="4" />
  <TCallout :line="9" :col="12" :span="23" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> временный сброс: <code>seteuid(ruid)</code> изменил только euid; suid хранит 0</div>
<div><span class="co-ball">2</span> проверка делом: открыть <code>/etc/shadow</code> уже нельзя</div>
<div><span class="co-ball">3</span> возврат: <code>seteuid(suid)</code> — euid снова 0, файл открывается</div>
<div><span class="co-ball">4</span> окончательный сброс: <code>setuid(ruid)</code> при euid 0 затёр <b>все три</b> — suid тоже стал 1001</div>
<div><span class="co-ball">5</span> вернуть root нельзя: <code>setuid(0)</code> → <code>Operation not permitted</code></div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> <code>seteuid</code> меняет только euid — сброс обратим, пока suid хранит 0;
<code>setuid</code> у привилегированного процесса заменяет все три идентификатора — так
привилегии сбрасывают «насовсем» (предыдущий слайд).
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/04-uid-inheritance.sh</code>.
</div>

<!--
«Качели привилегий» в действии, с функциональной проверкой — попыткой открыть /etc/shadow
(0640 root:shadow). seteuid(ruid): euid=1001, файл недоступен, но suid хранит 0 —
seteuid(suid) возвращает euid=0, файл снова открывается. setuid(ruid) при euid=0 —
привилегированный вариант вызова: затирает все три идентификатора; setuid(0) после
этого — EPERM, привилегии потеряны окончательно. Эксперимент повторяет exp_3/exp_4
из учебного примера 03_resids_output_ids.c (.sources/misc).
-->

---

# Демо 04: `execve` и оболочки

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/04-uid-inheritance.txt" section="4" title="demo 04 · execve без setuid-бита: запуск id">
  <TCallout :line="3" :col="29" :span="12" :n="1" />
</TerminalCapture>

<div class="mt-2" />

<TerminalCapture src="captures/04-uid-inheritance.txt" section="5" title="demo 04 · крайний случай: bash" padBottom="0.4em">
  <TCallout :line="3" :col="29" :span="16" :n="2" />
  <TCallout :line="7" :col="29" :span="12" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> обычный <code>execve</code> (запуск <code>id</code>) идентификаторы не изменил: <code>euid=0(root)</code> на месте</div>
<div><span class="co-ball">2</span> а после запуска <code>bash</code> euid 0 исчез — оболочка <b>сама</b> выровняла euid по ruid</div>
<div><span class="co-ball">3</span> <code>bash -p</code> (privileged) эффективный UID сохраняет</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> ядро при <code>execve</code> без setuid-бита идентификаторы не трогает;
euid сбрасывает сам <code>bash</code> — защита от случайного запуска привилегированной
оболочки (<Man p="bash(1)" />). Многие «неожиданные» потери привилегий в setuid-обёртках
объясняются именно этим.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/04-uid-inheritance.sh</code>.
</div>

<!--
Первый запуск: execve(id) — ядро ничего не сбрасывает, id честно показывает euid=0(root).
Второй: тот же трюк с bash не работает — при euid ≠ ruid bash сам выравнивает euid по
ruid; это политика оболочки, не ядра; флаг -p (privileged) её отключает — bash(1).
-->

---

# Демо 04: setuid-бит на скрипте игнорируется

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/04-uid-inheritance.txt" section="6" title="demo 04 · крайний случай: скрипт с setuid-битом">
  <TCallout :line="2" :col="1" :span="11" :n="1" />
  <TCallout :line="6" :col="4" :span="1" :n="2" />
  <TCallout :line="9" :col="1" :span="44" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> файл — скрипт: первая строка <code>#!</code> (интерпретируемый файл)</div>
<div><span class="co-ball">2</span> setuid-бит установлен, владелец — root: всё как у <code>idprobe</code></div>
<div><span class="co-ball">3</span> но привилегий нет: в выводе <code>id</code> нет <code>euid=0</code> — бит не сработал</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> для <code>#!</code>-файлов ядро <b>игнорирует setuid/setgid-биты</b>:
исполняется не скрипт, а интерпретатор, и между открытием файла ядром и его чтением
интерпретатором возможна подмена — состояние гонки. Привилегированные обёртки делают
бинарными — или используют <code>sudo</code> (раздел 7).
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/04-uid-inheritance.sh</code>.
</div>

<!--
Исторически setuid-скрипты были источником уязвимостей (гонка между execve и открытием
скрипта интерпретатором), поэтому Linux просто игнорирует setuid/setgid-биты на файлах
с shebang: id внутри скрипта показывает обычные права, хотя бит установлен и владелец —
root.
-->

---
layout: section
---

# 2. Идентификация

<SectionTOC prefix="2" :current="5" :items="[
  'Субъекты и объекты',
  'Файл паролей <code>/etc/passwd</code>',
  'Файл групп <code>/etc/group</code>',
  'Идентификаторы процесса',
  'Реализация в ядре Linux',
]" />

---

# Исходный код ядра: `struct cred`

<div class="grid grid-cols-[1.25fr_1fr] gap-4">
<div>

```c
/* include/linux/cred.h, строки 111–138 (сокращено) */
struct cred {
	atomic_long_t	usage;
	kuid_t		uid;	 /* real UID of the task */
	kgid_t		gid;	 /* real GID of the task */
	kuid_t		suid;	 /* saved UID of the task */
	kgid_t		sgid;	 /* saved GID of the task */
	kuid_t		euid;	 /* effective UID of the task */
	kgid_t		egid;	 /* effective GID of the task */
	kuid_t		fsuid;	 /* UID for VFS ops */
	kgid_t		fsgid;	 /* GID for VFS ops */
	/* … capabilities, keyrings, LSM, user_ns … */
	struct group_info *group_info; /* supplementary groups */
} __randomize_layout;
```

</div>
<div>

- Все идентификаторы процесса живут в одной структуре **`struct cred`** — вместе с capabilities и вторичными группами (`group_info`).
- `task_struct` каждого процесса держит указатель на **неизменяемый** `cred`: смена идентификаторов — это подготовка новой копии (`prepare_creds`) и её атомарная фиксация (`commit_creds`).
- Именно эти поля показывают `/proc/PID/status` и `ps` (демо 03).

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux v6.18 (LTS):
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/cred.h#L111">include/linux/cred.h#L111</a>
(поля uid…fsgid — строки 113–121).
</div>

<Refs ids="linux-kernel man-credentials" />

<!--
Подраздел «реализация в ядре»: смотрим, как то, что мы видели в /proc, определено в ядре.
Comments в struct cred дословно повторяют терминологию credentials(7): real/saved/effective/VFS.
-->

---

# Исходный код ядра: выбор эффективного UID

<div class="grid grid-cols-2 gap-4">
<div>

```c
/* include/linux/cred.h, строки 352–366 */
#define current_cred_xxx(xxx)	\
({				\
	current_cred()->xxx;	\
})

#define current_uid()	(current_cred_xxx(uid))
#define current_euid()	(current_cred_xxx(euid))
/* … */
#define current_fsuid()	(current_cred_xxx(fsuid))
```

</div>
<div>

```c
/* kernel/sys.c, строки 1027–1038 */
SYSCALL_DEFINE0(getuid)
{
	/* Only we change this so SMP safe */
	return from_kuid_munged(
		current_user_ns(), current_uid());
}

SYSCALL_DEFINE0(geteuid)
{
	/* Only we change this so SMP safe */
	return from_kuid_munged(
		current_user_ns(), current_euid());
}
```

</div>
</div>

<div class="mt-3">

`current_uid()`/`current_euid()` выбирает поле `uid`/`euid` из `cred` **текущего** процесса; 
так реализованы системные вызовы <Man p="getuid(2)" />/<Man p="geteuid(2)" /> используют. 
Проверки привилегий (`capable()`) используют euid-набор, проверки доступа к файлам — `current_fsuid()`.

</div>

<div class="text-xs opacity-70 mt-2">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/cred.h#L352">cred.h#L352</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/sys.c#L1033">sys.c#L1033</a>.
</div>

<Refs ids="linux-kernel" />

<!--
Макрос current_cred_xxx — «выбор поля из cred текущего процесса». from_kuid_munged
переводит внутренний kuid_t в число для пользовательского пространства с учётом
user namespace — поэтому в контейнере вы можете видеть другой UID, чем видит ядро.
-->

---

# Исходный код ядра: наследование при `fork`

<div class="grid grid-cols-2 gap-4">
<div>

```c
/* kernel/fork.c, строка 2046:
 * copy_process() — создание процесса */
retval = copy_creds(p, clone_flags);
```

```c
/* kernel/cred.c, строки 206–219:
 * prepare_creds() — копия cred вызывающего */
	old = task->cred;
	memcpy(new, old, sizeof(struct cred));
```

</div>
<div>

```c
/* kernel/cred.c, строки 290–344 (сокращено) */
int copy_creds(struct task_struct *p,
	       u64 clone_flags)
{
	struct cred *new;
	/* поток (CLONE_THREAD):
	 * разделяет cred с родителем */
	if (clone_flags & CLONE_THREAD) {
		p->real_cred =
			get_cred_many(p->cred, 2);
		return 0;
	}
	new = prepare_creds(); /* копия */
	/* … user namespace, keyrings … */
	p->cred = p->real_cred = get_cred(new);
	return 0;
}
```

</div>
</div>

<div class="mt-2">

Наследование из <Man p="credentials(7)" /> — это один `memcpy`: новый процесс получает
**побайтовую копию** `struct cred` родителя (все UID/GID, capabilities, группы). Потоки
процесса используют экземпляр `struct cred` процесса.

</div>

<div class="text-xs opacity-70 mt-1">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/fork.c#L2046">fork.c#L2046</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/cred.c#L290">cred.c#L290</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/cred.c#L219">cred.c#L219</a>.
</div>

<Refs ids="linux-kernel man-credentials" />

<!--
Вся «магия» наследования — memcpy в prepare_creds. Отсюда же видно отличие потока от
процесса: CLONE_THREAD не копирует cred вообще. Это код, который выполнился в демо 04
между строками «after seteuid(ruid)» и «child after fork».
-->

---

# Исходный код ядра: setuid-бит при `execve`

```c
/* fs/exec.c, строки 1534–1584 (сокращено): вызывается из execve(2) */
static void bprm_fill_uid(struct linux_binprm *bprm, struct file *file)
{
	/* Handle suid and sgid on files */
	if (!mnt_may_suid(file->f_path.mnt))	/* nosuid-монтирование */
		return;
	if (task_no_new_privs(current))		/* prctl NO_NEW_PRIVS */
		return;
	if (mode & S_ISUID) {
		bprm->per_clear |= PER_CLEAR_ON_SETID;
		bprm->cred->euid = vfsuid_into_kuid(vfsuid); /* euid := владелец файла */
	}
	/* аналогично S_ISGID → egid */
}
```

```c
/* security/commoncap.c, строки 952–953: cap_bprm_creds_from_file() */
	new->suid = new->fsuid = new->euid;
	new->sgid = new->fsgid = new->egid;
```

<div class="mt-2">

При <Man p="execve(2)" /> setuid-файла ядро меняет **только euid** — на владельца файла;
затем suid и fsuid выравниваются по новому euid (алгоритм из раздела 2.4). Здесь же
видно, когда бит игнорируется: монтирование с `nosuid` и режим `no_new_privs`.

</div>

<div class="text-xs opacity-70 mt-1">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/exec.c#L1534">exec.c#L1534</a>
(присваивание euid — строка 1577) ·
<a href="https://github.com/torvalds/linux/blob/v6.18/security/commoncap.c#L953">commoncap.c#L953</a>.
</div>

<Refs ids="linux-kernel man-execve" />

<style>
/* Два листинга + абзац не помещаются при базовом размере кода — ужимаем код. */
.slidev-code { font-size: 0.64rem !important; line-height: 1.38 !important; }
</style>

<!--
Замыкаем картину демо 03: euid=0 у passwd появился в bprm_fill_uid, а suid=fsuid=euid —
в cap_bprm_creds_from_file. Отсюда же два практических способа «выключить» setuid:
смонтировать ФС с nosuid или установить процессу no_new_privs.
-->

---
layout: section
---

# 3. Парольная аутентификация

<SectionTOC prefix="3" :current="1" :items="[
  'Исторический экскурс',
  'Теневой файл паролей <code>/etc/shadow</code> и групп <code>/etc/gshadow</code>',
  'Хеширование пароля',
  'Парольная политика',
]" />

---

# Пароль появился вместе с разделением времени

<div class="grid grid-cols-[1.25fr_1fr] gap-5">
<div>

- Пока машина выполняла **одну задачу**, доступ к ней ограничивали физически:
  машинный зал, операторы, расписание.
- **CTSS** (Compatible Time-Sharing System; МТИ, руководитель — Ф. Корбато;
  первая демонстрация — ноябрь 1961 г.) — одна из первых влиятельных
  **многопользовательских** систем: за одним мейнфреймом IBM — десятки
  исследователей за отдельными терминалами.
- У каждого пользователя — **личные файлы** и **квота машинного времени**. Общие
  ресурсы потребовали разграничения, а разграничение — достоверного ответа на
  вопрос «кто вошёл?». Решение CTSS — **пароль**, запрашиваемый при входе.

</div>
<div>

<InfoCard icon="key" head="Почему именно пароль">

из трёх факторов аутентификации — знание, предмет, свойство (биометрия) —
только **знание** в 1960-е не требовало дополнительной аппаратуры на каждом
терминале; выбор по экономике, а не по стойкости.

</InfoCard>

<v-click>

<div class="mt-3 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Хранение:</b> пароли лежали <b>открытым текстом</b> в системном файле
<code>UACCNT.SECRET</code>; процедура входа просто сравнивала введённое с хранимым.
Защитой считались права доступа к файлу — укравшему файл ничего «вскрывать»
не требовалось: учётные данные уже готовы к употреблению.
</div>

</v-click>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Достаточно ли прав доступа, чтобы защитить открытый файл паролей? Первые же годы
эксплуатации CTSS дали отрицательный ответ — <b>два задокументированных инцидента</b>
на следующем слайде.
</div>

</v-click>

<Refs ids="ctss-50th corbato morris-thompson" />

<!--
По юбилейному сборнику CTSS (Уолден, Ван Влек, 2011) и статье Морриса—Томпсона.
Контекст: системы разделения времени впервые сделали машину общей — появились личные
файлы и квоты машинного времени, то есть то, что нужно разграничивать; CTSS
(продемонстрирована в ноябре 1961 г., руководитель Корбато) — одна из первых
влиятельных многопользовательских ОС. Пароль выбран по экономике: знание не требует
аппаратуры на терминале. Хранение — открытым текстом в файле UACCNT.SECRET под
служебной учётной записью: вход сравнивал открытые значения, а значит, укравшему файл
не нужно ничего вычислять. Риторический вопрос в конце — мостик к инцидентам 1962 и
1966 гг.
-->

---

# CTSS: открытый файл паролей утёк дважды

<div class="grid grid-cols-2 gap-4 text-xs">
<div class="p-3 border border-slate-400/40 rounded">
<b>1962 · умышленная кража — через побочную службу</b>
<div class="mt-1">
Аспирант Аллан Шерр, исследовавший производительность CTSS, получал лишь
<b>~4 часа машинного времени в семестр</b>. Сначала он, имея доступ к системному коду,
правил учёт потреблённого времени; когда доступ отобрали — воспользовался службой
<b>офлайн-печати</b>: заявка на перфокарте принимала имя учётной записи и файла, и Шерр
заказал распечатку файла паролей <code>UACCNT.SECRET</code>, забрав её из лотка
субботним утром. Механизм входа не пострадал — пароли «унесла» печать. Паролями он
делился с коллегами; признание прозвучало лишь десятилетия спустя, в юбилейном
сборнике CTSS.
</div>
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>1966 · случайное раскрытие — административная ошибка</b>
<div class="mt-1">
Один администратор редактировал файл паролей, второй — «сообщение дня». Редактор
создавал временный файл с <b>предсказуемым именем</b>; файлы поменялись местами —
и каждому входящему вместо приветствия печаталось содержимое файла паролей. Заметивший
это Билл Мэтьюз намеренно <b>остановил мейнфрейм</b>, оборвав раздачу; Том Ван Влек
затем не один час менял пароли — в том числе на второй установке CTSS, которой ошибка
не коснулась: пользователи <b>повторяли пароли</b> между системами.
</div>
</div>
</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10">
<b>Урок:</b> файл с открытыми паролями компрометируется <b>любым</b> путём, которым он
доступен, — печатью, копией, резервной лентой, временным файлом редактора; сам механизм
входа ни в одном инциденте «взламывать» не пришлось, а после утечки неизбежен массовый
сброс паролей. Историю 1966 г. Моррис и Томпсон привели в статье 1979 г. как довод
в пользу отказа от открытого хранения.
</div>

</v-click>

<Refs ids="ctss-50th morris-thompson corbato" />

<!--
Оба инцидента — по воспоминаниям участников в юбилейном сборнике CTSS (2011).
1962: Шерру для диссертационных моделей не хватало квоты (~4 часа процессорного
времени в семестр); после закрытия доступа к учёту времени он получил файл паролей
UACCNT.SECRET (служебная учётная запись M1416) через службу офлайн-печати —
перфокарточная заявка называла учётную запись и файл, проверка прав на печать
не распространялась. Паролями делился; один из получателей вошёл в учётную запись
Фано и оставлял насмешливые сообщения; признался Шерр лишь на юбилейной встрече.
1966: два администратора, редактор с предсказуемым именем временного файла, файл
паролей вместо «сообщения дня»; Билл Мэтьюз остановил машину, Ван Влек менял пароли,
включая вторую установку CTSS — из-за повторного использования паролей. Урок: открытый
файл утекает по побочным путям (печать, копия, лента, temp-файл) при целом механизме
входа; Моррис и Томпсон использовали историю 1966 г. в статье 1979 г.
-->

---

# Ранний Unix: хранить не пароль, а одностороннее преобразование

<div>

Первый Unix повторил схему CTSS — <b>защищённый файл с открытыми паролями</b> — и быстро
убедился, что одних прав доступа мало: привилегированное копирование, временные файлы
и архивные носители всё равно раскрывают содержимое. Ответ (начало 1970-х): хранить
не пароль, а результат <b>одностороннего преобразования</b> — и повторять вычисление
при каждом входе.

</div>

<BlockFlow class="mt-3" :blocks="[
  { head: 'Пароль', sub: 'используется как ключ шифрования' },
  { head: 'Шифрование константы', fill: 'dark', sub: 'код по мотивам шифровальной\nмашины Hagelin M-209' },
  { head: 'Verifier в файле', sub: 'при входе вычисление повторяется\nи результаты сравниваются' },
]" />

<div class="mt-3 text-xs">
Пароль здесь — не сообщение, а <b>ключ</b>, шифрующий известную константу: по результату
ключ не восстановить, оригинал пароля в системе отсутствует. Но у схемы два изъяна:
функция <b>быстрая</b>, и у неё <b>нет соли</b>.
</div>

<v-click>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Экономика несолёного хеша:</b> функция детерминирована, поэтому кандидат
(например, <code>secret123</code>) хешируется <b>один раз</b> — и сравнивается сразу
со всеми записями базы: если этот пароль выбрали 50 пользователей из 1 000, одно
вычисление раскрывает все 50. Словарь «пароль → хеш» можно предвычислить заранее
и переносить между системами с тем же алгоритмом. Соль устраняет именно этот «эффект
масштаба» (раздел 3.3) — хотя подбор <b>одного</b> слабого пароля не останавливают
ни соль, ни одностороннее преобразование.
</div>

</v-click>

<Refs ids="morris-thompson" />

<!--
По Моррису—Томпсону: Unix сначала хранил настоящие пароли в защищённом файле; практика
показала, что ограничение доступа не спасает от привилегированных копий, временных
файлов и архивов. Поэтому Unix перешёл к одностороннему представлению: ранняя схема
построена по мотивам шифровальной машины Hagelin M-209 времён Второй мировой — пароль
использовался как ключ шифрования фиксированной константы, результат хранился как
verifier. Свойство одностороннего преобразования достигнуто, соли нет: одинаковые
пароли дают одинаковые записи. Отсюда экономика атакующего: один кандидат — одно
вычисление против всей базы, предвычисленные словари переносимы. Подчеркнуть и
ограничение: соль защищает не от подбора одного слабого пароля, а от разделения
стоимости атаки между жертвами.
-->

---

# 1979: слабые пароли — и ответ Version 7: соль и медленный `crypt`

<div class="grid grid-cols-2 gap-4">
<div>

**Эксперименты Морриса и Томпсона** с подбором паролей к ранней схеме:

- оптимизированная реализация проверяла кандидата за **~1,25 мс** (PDP-11/70) —
  без соли этого хватало для словарного перебора против всей базы;
- из **3 289** собранных паролей **~86 %** — короткие либо словарные; словарная
  атака нашла около трети **за ~5 минут** машинного времени;
- на одной установке пароли «генерировались случайно» (8 символов: строчные буквы
  и цифры), но у генератора было **мало начальных состояний** — дружественный
  атакующий перечислил все его выходы **за ~1 минуту**.

</div>
<div>

**Ответ Version 7 Unix — `crypt`:**

- **25 итераций** модифицированного DES: проверка намеренно медленная, а серийные
  аппаратные DES-платы к изменённому алгоритму неприменимы;
- **соль 12 бит** (4 096 вариантов), хранится **открыто** рядом с verifier — соль
  не секрет;
- ограничения, заложенные навсегда: учитываются только **первые 8 символов**,
  стоимость вычисления **фиксирована**.

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>Попутный урок:</b> кажущаяся сложность пароля ничего не стоит, если процедура его
<b>генерации</b> предсказуема.
</div>

</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>К 1979 г. — два слоя защиты:</b> медленная односторонняя функция + соль. Но хеши
и соли по-прежнему лежали в общедоступном <code>/etc/passwd</code> — третий слой
впереди.
</div>

</v-click>

<Refs ids="morris-thompson man-crypt" />

<!--
Левая колонка — экспериментальная часть статьи 1979 г.: оптимизированная реализация
старой схемы — около 1,25 мс на кандидата на PDP-11/70; выборка 3 289 паролей, ~86 %
в легко описываемых категориях (короткие строки, словарные слова), словарная атака
нашла примерно треть за ~5 минут; отдельный случай — «случайные» 8-символьные пароли
от генератора с малым числом начальных состояний: все выходы перечислены примерно
за минуту (подбор был дружественным, без ущерба). Цифры характеризуют выборку, а не
долю реально скомпрометированных учётных записей. Правая колонка — ответ V7: crypt
из 25 итераций модифицированного DES (несовместимость с серийными DES-платами —
намеренная), 12-битная соль хранится открыто, соль не секрет; ограничения — 8 значимых
символов и фиксированная стоимость — позже станут причиной замены алгоритма
(раздел 3.3). Вывод: два слоя из трёх готовы.
-->

---

# Общедоступные хеши: пакет shadow появился до червя Морриса

<div>

Хеши и соли лежали в `/etc/passwd`, который **читаем всеми** (раздел 2.2): любой
локальный пользователь мог скопировать базу и перебирать её **офлайн** — без
ограничений частоты попыток и следов в журналах.

</div>

<div class="grid grid-cols-2 gap-4 mt-2 text-xs">
<div>

<div class="p-3 border border-slate-400/40 rounded">
<b>1987 · Shadow Password Suite</b><br/>
Обнаружив, что пользователь скачал <code>/etc/passwd</code> её системы по UUCP,
Julianne F. Haugh реализовала для SCO Xenix хранение хешей в отдельном закрытом
файле (развивая механизмы AT&T Unix); позднее пакет shadow перенесён в Linux.
Смысл: соль не «сломалась» — система просто <b>сама выдавала</b> атакующему хеши,
с которых начинается перебор.
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Историческое уточнение:</b> механизм shadow <b>существовал до</b> червя Морриса.
Червь не «породил» теневой файл — он сделал опасность читаемых хешей очевидной
и ускорил распространение механизма.
</div>

</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>1988 · червь Морриса (2 ноября)</b>
<div class="mt-1 space-y-1">
<div>— <b>четыре пути</b> распространения: переполнение буфера <code>fingerd</code>,
отладочный режим sendmail, доверенные хосты rsh/rexec — и <b>подбор паролей</b>;</div>
<div>— ступени подбора: пустой пароль → вариации имени учётной записи → встроенный
словарь из <b>432 слов</b> → системный <code>/usr/dict/words</code>; своя ускоренная
реализация <code>crypt</code>;</div>
<div>— соль не остановила: она <b>открыта</b> — червь читал её из записи и пересчитывал
кандидатов; подобранные пароли открывали соседние машины;</div>
<div>— поражено ~6 000 из ~60 000 машин сети; последствия — создание CERT и первый
приговор по закону о компьютерном мошенничестве (1990).</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Итог эволюции:</b> к концу 1980-х сложилась трёхслойная защита — <b>медленная
односторонняя функция</b> + <b>соль</b> + <b>закрытый файл</b>; разделы 3.2 и 3.3
разбирают каждый слой в современном Ubuntu.
</div>

</v-click>

<Refs ids="shadow-maint shadow-howto morris-worm fbi-morris" />

<!--
Завершение исторической дуги. Хеши оставались в world-readable passwd, потому что файл
нужен всем программам для перевода UID в имена; локальный пользователь копирует базу
и перебирает офлайн. 1987: J. F. Haugh после инцидента с копированием passwd по UUCP
пишет Shadow Suite для SCO Xenix (на базе механизмов AT&T); позднее пакет приходит
в Linux — тот самый shadow-utils раздела 3.2. Важная историографическая поправка:
shadow существовал до червя Морриса, червь лишь сделал проблему наглядной и ускорил
внедрение. Червь (подробности в правой колонке — по анализу Спаффорда и данным ФБР):
четыре пути распространения, ступенчатый подбор паролей со своей быстрой реализацией
crypt; соль, будучи открытой, от целевого перебора не защищает — защищал бы закрытый
файл, но он не чинит fingerd, sendmail и доверенные хосты. Масштаб — порядка 6 000 из
60 000 машин (оценка ФБР, точные числа неизвестны). Финальный teal — три слоя защиты,
структура разделов 3.2–3.3.
-->

---
layout: section
---

# 3. Парольная аутентификация

<SectionTOC prefix="3" :current="2" :items="[
  'Исторический экскурс',
  'Теневой файл паролей <code>/etc/shadow</code> и групп <code>/etc/gshadow</code>',
  'Хеширование пароля',
  'Парольная политика',
]" />

---

# `/etc/shadow`: назначение и формат

<div>

**`/etc/shadow`** — **теневой файл паролей**, предназначен для хранения хешей паролей 
и параметров их устаревания (<Man p="shadow(5)" />). На месте пароля в `/etc/passwd` 
помещается признак `x` (раздел 2.2).

Формат: текстовый файл; **одна строка — одна учётная запись**; строка состоит из **9 полей**,
разделённых двоеточием `:`. Все даты и интервалы представлены **в днях**; даты отсчитываются
от 1 января 1970 г.

</div>

<FieldRecord class="mt-3" size="0.82rem" legendSize="0.72rem" :cols="3"
  :fields="['bob', { t: '$y$j9T$qqeJ…$vZvV…', hot: true }, '20752', '0', '99999', '7', '', '', '']"
  :legend="[
    'имя пользователя — ссылка на /etc/passwd',
    { t: 'хеш пароля или спец. значение', hot: true },
    'дата последней смены пароля (кол-во дней с 01.01.1970)',
    'мин. число дней между сменами пароля',
    'макс. срок действия пароля',
    'период предупреждения об истечении срока действия пароля',
    'период неактивности после истечения срока действия до блокировки учётной записи',
    'дата блокировки учётной записи (кол-во дней с 01.01.1970)',
    'зарезервировано',
  ]"
/>

<div class="grid grid-cols-2 gap-4 mt-3 items-start text-xs">
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Поле 2 — специальные значения</b> (<Man p="shadow(5)" />)
<div class="mt-1 space-y-1">
<div><code>*</code> или <code>!</code> — вход <b>по паролю</b> невозможен</div> (т.к. результат <code>crypt</code> не может начинаться с этих символов)
<div><code>!хеш</code> — пароль заблокирован, прежний хеш сохранён (см. раздел 3.4)</div>
<div class="text-red-600"><i>пусто</i> — пароль не требуется (см. раздел 3.4)</div>
</div>
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Поля 3–8 — политика устаревания</b><br/>
Задаётся с помощью периодов смены, предупреждения, неактивности и срока учётной записи; управляется
командой <Man p="chage(1)" /> — см. раздел 3.4. <br/><br/>
Значение по умолчанию <code>99999</code> в поле 5 — пароль фактически бессрочный.
</div>
</div>

<Refs ids="man-shadow man-chage" />

<!--
Определение: /etc/shadow — теневой файл паролей, продолжение истории из раздела 2.2:
хеш и политика устаревания вынесены из общедоступного passwd. Формат зеркалит passwd:
одна строка — одна запись, девять полей через двоеточие. Поле 2 — хеш или специальное
значение: * и ! не могут быть результатом crypt, поэтому вход по паролю невозможен;
!хеш — обратимая блокировка; пустое поле — пароль не требуется (опасно — демо 06).
Поля 3–8 — политика устаревания в днях от эпохи; разбор и настройка — раздел 3.4.
-->

---

# Пример `/etc/shadow`

<div class="grid grid-cols-[1.5fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/17-etc-shadow.txt" section="1" title="Ubuntu Server 26.04 · cat /etc/shadow" fontSize="0.4rem" highlight="26-28">
  <TCallout :line="2" :col="6" :span="1" :n="1" />
  <TCallout :line="20" :col="8" :span="1" :n="2" />
  <TCallout :line="21" :col="17" :span="2" :n="3" />
  <TCallout :line="26" :col="5" :span="73" :n="4" />
  <TCallout :line="27" :col="7" :span="1" :n="5" />
  <TCallout :line="28" :col="81" :span="15" :n="6" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем файл:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>root</code>: <code>*</code> — пароль не задан, вход по паролю невозможен (только ключи SSH или <code>su</code>/<code>sudo</code>)</div>
<div><span class="co-ball">2</span> <code>ubuntu</code>: <code>!</code> — пароль не задан при создании записи</div>
<div><span class="co-ball">3</span> псевдопользователи пакетов: <code>!*</code> — вход по паролю невозможен</div>
<div><span class="co-ball">4</span> <code>bob</code> — хеш yescrypt: <code>$y$…</code> (формат хеша описан в разделе 3.3)</div>
<div><span class="co-ball">5</span> <code>carol</code>: <code>!</code> — пароль не задан при создании записи</div>
<div><span class="co-ball">6</span> политика устаревания: смена в день 20752, менять можно сразу (0), срок действия 99999 дней, предупреждать о смене за 7 дней</div>
</div>
</div>
</div>

<Refs ids="man-shadow" />

<!--
Реальный файл с демонстрационного контейнера Ubuntu Server 26.04. У системных записей
и root — *, у записей, созданных без пароля (ubuntu, carol), — !; псевдопользователи
пакетов systemd получают !*. Содержательные строки — у людей с установленным паролем:
хеш yescrypt и поля политики (20752 — день последней смены от 01.01.1970, 0 — менять
можно сразу, 99999 — бессрочно, 7 — предупреждение). Разные написания «вход по паролю
невозможен» (*, !, !*) равнозначны для проверки: ни одно не является допустимым
результатом crypt.
-->

---

# `/etc/gshadow`: назначение и формат

<div>

**`/etc/gshadow`** — теневой файл **групп**, предназначен для хранения хеша пароля группы 
и список её администраторов (<Man p="gshadow(5)" />). **Пароль группы** позволяет 
пользователю, **не состоящему** в группе, временно войти в неё с помощью 
команды <Man p="newgrp(1)" />, предъявив пароль.

Формат: **одна строка — одна группа**; строка состоит из **4 полей**, разделённых `:`.

</div>

<FieldRecord class="mt-3" size="1rem" legendSize="0.78rem" :cols="2"
  :fields="['project', { t: '!', hot: true }, '', 'bob,alice']"
  :legend="[
    'имя группы — ссылка на значения в `/etc/group`',
    { t: 'хеш пароля группы или спец. значение', hot: true },
    'администраторы группы: меняют пароль и состав (`gpasswd -A`)',
    'члены группы — дублирует 4-е поле `/etc/group`',
  ]"
/>

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-2 items-start">
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Поле 2 — пароль группы</b>
<div class="mt-1 space-y-1">
<div>– <i>хеш</i> — <code>newgrp</code> впустит в группу по паролю даже не-члена</div>
<div>– <code>!</code> или <i>пусто</i> — пароль не задан: группа доступна <b>только членам</b>; в Debian/Ubuntu по умолчанию <code>!</code></div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>На практике</b> пароли групп применяются редко: членство (раздел 2.3) надёжнее
общего секрета — его нельзя выдать одному пользователю и отозвать у другого.
Пример использования <code>newgrp</code> — в разделе 3.4.
</div>

</v-click>

</div>
<div>

<TerminalCapture src="captures/17-etc-shadow.txt" section="2" title="Ubuntu Server 26.04 · строки /etc/gshadow">
  <TCallout :line="6" :col="9" :span="1" :n="1" />
  <TCallout :line="6" :col="12" :span="9" :n="2" />
  <TCallout :line="3" :col="6" :span="2" :n="3" />
</TerminalCapture>

<div class="text-xs opacity-70 mt-1">
<span class="co-ball">1</span> пароль группы не задан ·
<span class="co-ball">2</span> члены — как в <code>/etc/group</code> ·
<span class="co-ball">3</span> поле администраторов у всех групп пусто
</div>

</div>
</div>

<Refs ids="man-gshadow man-gpasswd" />

<!--
Определение: gshadow — аналог shadow для групп; из /etc/group сюда вынесен пароль
группы, добавлен список администраторов. Пароль группы проверяет newgrp при смене
первичной группы процесса: зная пароль, в группу может временно войти даже не-член.
Четыре поля: имя, пароль, администраторы (gpasswd -A — могут менять пароль и состав,
не будучи root), члены (дублирует /etc/group). ! или пусто — пароля нет, группа
доступна только членам; это умолчание Debian/Ubuntu. Callout 3: поле администраторов
обычно пусто. На практике пароли групп редки: общий секрет не отзывается персонально.
-->

---

# Права доступа к `/etc/shadow` и `/etc/gshadow`

<div class="grid grid-cols-[1.25fr_1fr] gap-4 items-start">
<div>

<TerminalCapture src="captures/17-etc-shadow.txt" section="3" title="Ubuntu Server 26.04 · сеанс пользователя bob" fontSize="0.5rem">
  <TCallout :line="5" :col="1" :span="24" :n="1" />
  <TCallout :line="7" :col="1" :span="35" :n="2" />
  <TCallout :line="11" :col="4" :span="1" :n="3" />
  <TCallout :line="9" :col="7" :span="1" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>0640 root:shadow</code> — читают только root и группа shadow; у <code>gshadow</code> — те же права</div>
<div><span class="co-ball">2</span> обычному пользователю файл недоступен даже на чтение</div>
<div><span class="co-ball">3</span> <code>passwd</code> и <code>gpasswd</code> — setuid root: процессы запускаются от root, поэтому запись хеша нового пароля доступна</div>
<div><span class="co-ball">4</span> <code>chage</code> — setgid shadow: чтение полей политики без прав root</div>
</div>
</div>
</div>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10">
<b>Принцип разделения:</b> открытые данные учётных записей (<code>/etc/passwd</code>,
<code>/etc/group</code> с правами <code>0644</code>) отделены от секретных
(<code>/etc/shadow</code>, <code>/etc/gshadow</code> с правами <code>0640</code>).
«Файл не должен быть доступен на чтение обычным пользователям» — <Man p="shadow(5)" />:
офлайн-перебор хешей требует сначала заполучить теневой файл паролей.
</div>

<div class="text-xs opacity-70 mt-2">
Свой пароль пользователь изменяет setuid-программой <Man p="passwd(1)" /> (механизм
setuid-бита разобран в разделе 2.4) — чей пароль требуется изменить программа определяет по <code>ruid</code>.
</div>
<div class="text-xs opacity-70 mt-2">
setgid-программа <Man p="chage(1)" /> используется как для чтения, так и для изменения параметров устаревания пароля; 
бит <code>setgid</code> позволяет выполнять чтение непривелегированному пользователю, запись требует прав root.
</div>

<Refs ids="man-shadow man-passwd1 shadow-howto" />

<!--
Права с демонстрационного контейнера: 0640 root:shadow на обоих теневых файлах —
читают root и группа shadow, пишет только root; cat от имени bob — Permission denied.
Запись опосредована доверенными setuid-программами: passwd и gpasswd (setuid root);
chage — setgid shadow, ему достаточно чтения. Это замыкает сюжет раздела 2.4: passwd
работает с euid 0, а по ruid знает, чей пароль менять. Вывод — принцип разделения
открытых данных и секрета: чтобы начать офлайн-перебор, атакующему теперь нужен
не любой доступ к системе, а права root или группы shadow.
-->

---
layout: section
---

# 3. Парольная аутентификация

<SectionTOC prefix="3" :current="3" :items="[
  'Исторический экскурс',
  'Теневой файл паролей <code>/etc/shadow</code> и групп <code>/etc/gshadow</code>',
  'Хеширование пароля',
  'Парольная политика',
]" />

---

# Хеширование: проверка пароля без его хранения в открытом виде

<div class="text-xs opacity-70 mb-1">Установка пароля — <Man p="passwd(1)" /></div>

<BlockFlow size="0.8em" :blocks="[
  { head: 'Пароль', sub: 'вводит пользователь' },
  { head: '+ соль', sub: 'случайная, своя для\nкаждого пароля' },
  { head: 'Односторонняя функция', fill: 'dark', sub: 'медленное хеширование —\ncrypt(5)' },
  { head: '/etc/shadow', fill: 'accent', sub: '$алгоритм$параметры\n$соль$хеш' },
]" />

<div class="text-xs opacity-70 mb-1 mt-2">Вход в систему — login, sshd</div>

<BlockFlow size="0.8em" :blocks="[
  { head: 'Введённый пароль', sub: 'кандидат' },
  { head: '+ соль из /etc/shadow', sub: 'из сохранённой строки' },
  { head: 'Односторонняя функция', fill: 'dark', sub: 'та же, с теми же\nпараметрами' },
  { head: 'Сравнение строк', sub: 'совпало → вход разрешён\nиначе — отказ' },
]" />

<v-click>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Односторонняя функция:</b> вычисление хеша пароля выполняется эффективно, восстановление пароля
по хешу возможно только перебором. Система <b>не хранит пароль в открытом виде</b> —
только хэш и параметры его вычисления.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Хеширование — это не шифрование:</b> ключа «расшифровки пароля» не существует. Современные 
хеш-функции намеренно проектируются <b>медленными</b> и/или <b>требовательными к памяти</b>: 
типичная проверка введённого пароля, выполняющаяся несколько раз (до введения правильного пароля), 
занимает доли секунды, в то время как массовый перебор становится нереализуемым.
</div>
</div>

</v-click>

<Refs ids="man-crypt morris-thompson" />

<!--
Принцип из работы Морриса и Томпсона: вместо пароля хранится результат односторонней
функции. Верхняя схема — установка пароля: к паролю добавляется случайная соль,
медленная функция даёт строку-verifier в /etc/shadow. Нижняя — вход: введённый
кандидат хешируется с солью, извлечённой из сохранённой строки, и строки сравниваются.
Пароль в открытом виде не хранится нигде и не передаётся дальше модуля проверки.
Подчеркнуть два отличия от «обычного» хеша: намеренная медленность (стоимость
перебора) и соль (следующий слайд). И это не шифрование: обратной операции нет.
-->

---

# Соль: открытая случайная добавка к паролю

<div>

**Соль** — случайная строка, которую генерируют **при каждой установке пароля**
и присоединяют к нему перед хешированием; хранится **открыто** в той же строке
`/etc/shadow`, что и хеш: `hash = f(пароль, соль)`.

</div>

<div class="grid grid-cols-3 gap-3 mt-3 text-xs">
<div class="p-3 border border-slate-400/40 rounded">
<b>Скрывает совпадения</b><br/>
одинаковые пароли дают <b>разные</b> хеши — у двух пользователей, на двух системах,
для одного и того же пароля. По хешам из украденного <code>/etc/shadow</code> не видно, 
чьи пароли совпадают.
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Обесценивает предвычисления</b><br/>
словарь «пароль → хеш» (радужные таблицы) пришлось бы считать <b>для каждой соли
заново</b>; заготовить таблицы на все соли — непрактично.
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Умножает работу перебора</b><br/>
перебор паролей сразу по всем N записям невозможен — у каждой записи
своя соль, следовательно, работа атакующего растёт с количеством записей.
</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>Что соль не делает:</b> соль и не замедляет перебор <b>одной</b> конкретной
записи — слабый пароль соль не спасёт. Против атаки перебором требуется 
использовать медленную функцию и выбрать качественные пароли.
</div>

</v-click>

<v-click>

<HistoryNote class="mt-2" label="Исторический экскурс · 1979">
Механизм соли ввели Моррис и Томпсон: 12 бит «умножают на 4096» работу проверки одного пароля, 
а составление заранее подготовленных словарей хешей «становится непрактичным».
Соль yescrypt в примерах этой лекции — 22 символа base64 (более 130 бит).
</HistoryNote>

</v-click>

<Refs ids="morris-thompson man-crypt" />

<!--
Детальный разбор механизма соли. Определение: случайная строка, генерируется при
каждой установке пароля, хранится открыто рядом с хешем; хеш — функция пары
(пароль, соль). Три эффекта: скрывает совпадения паролей (между пользователями,
системами и во времени), обесценивает предвычисленные таблицы (на каждую соль —
отдельная таблица), умножает работу словарного перебора по базе на число различных
солей. Явно проговорить ограничение: соль открыта, перебор одной записи она не
замедляет — это задача медленной функции и качества пароля. Исторические числа —
из работы 1979 г.; современная соль yescrypt — 22 символа base64.
-->

---

# Эволюция алгоритмов: стоимость перебора против роста мощностей

<br/>

<Timeline height="11em" :items="[
  { year: '1979', head: 'DES-crypt', text: '25 итераций DES; соль 12 бит; пароль ≤ 8 символов. crypt(5): «не использовать»' },
  { year: '1994 · $1$', head: 'MD5-crypt', text: 'П.-Х. Камп, FreeBSD: снял лимит длины пароля; стоимость фиксирована — устарел' },
  { year: '1997 · $2b$', head: 'bcrypt', text: 'Провос и Мазьер, OpenBSD 2.1 (статья USENIX 1999): параметр стоимости растёт вместе с «железом»' },
  { year: '2007 · $5$ $6$', head: 'SHA-crypt', text: 'У. Дреппер, glibc: SHA-256/512, параметр rounds; по умолчанию в Ubuntu 14.04–20.04' },
  { year: '2009 · 2015', head: 'scrypt · Argon2', text: 'память как второй ресурс защиты — против GPU и спецустройств; Argon2 — победитель конкурса PHC (RFC 9106)' },
  { year: 'сегодня · $y$', head: 'yescrypt', text: 'развитие scrypt: стоимость по процессору и памяти; по умолчанию в Debian 11+, Fedora 35+, Ubuntu 22.04+', hot: true },
]" />

<br/>

<div class="grid grid-cols-[1.3fr_1fr] gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Каждый следующий алгоритм — ответ на удешевление перебора:</b> быстрые реализации
DES, GPGPU, специализированные устройства. Идентификатор <code>$id$</code> в начале хеша
(см. следующий слайд) позволяет старым и новым форматам сосуществовать в одном файле;
тип хеша обновляется при очередной смене пароля — так Ubuntu перешла с SHA-512-crypt
(<code>$6$</code>) на yescrypt в 22.04 LTS без сброса паролей.<br/><br/>
Статусы по <Man p="crypt(5)" />: yescrypt — «рекомендуется», SHA-crypt — «допустимо»,
DES/MD5 — «не использовать».
</div>
<div class="p-2 border border-slate-400/40 rounded">
<b>Отечественные дистрибутивы:</b> хеши на ГОСТ Р 34.11-2012 «Стрибог» —
<code>$gy$</code> (gost-yescrypt, «допустимо, где требуется ГОСТ»); в Astra Linux
по умолчанию — <code>$gost12512hash$</code>.
</div>
</div>

<Refs ids="morris-thompson md5crypt bcrypt scrypt-percival rfc9106 man-crypt ubuntu-hash astra-gost-hash" />

<!--
Логика эволюции: алгоритм должен делать перебор дорогим, а мощности растут — поэтому
DES-crypt (1979, фиксированные 25 итераций и пароль до 8 символов) сменяется
MD5-crypt (1994, снял ограничение длины, но фиксированная стоимость со временем стала
слишком дешёвой), затем bcrypt — первый с настраиваемым параметром стоимости
(«растёт вместе с железом»): появился в OpenBSD 2.1 в 1997 г., формально описан на
USENIX в 1999-м. SHA-crypt (2007–2008, параметр rounds) — умолчание многих Linux,
в Ubuntu — с 14.04 по 20.04. Следующий шаг — память как ресурс защиты: scrypt
(Персиваль, 2009) и Argon2 (победитель Password Hashing Competition 2015; RFC 9106,
вариант Argon2id) дороги не только по процессору, но и по памяти — против GPU и
специализированных устройств. yescrypt развивает scrypt; умолчание Debian 11+,
Fedora 35+, Ubuntu 22.04+ — то есть и нашей Ubuntu Server 26.04. Префикс $id$
позволяет форматам сосуществовать: старый хеш проверяется по-старому, новый пароль
хешируется по-новому — миграция при очередной смене пароля. Контраст для кругозора:
Windows LM/NT-хеши соли не имели вовсе (базу SAM защищали правами доступа и
шифрованием); слабость LM публично показал L0phtCrack (1997). PBKDF2 (RFC 2898, 2000)
используется в macOS (SALTED-SHA512-PBKDF2). Для ГИС с требованиями ГОСТ-криптографии —
gost-yescrypt $gy$; Astra Linux по умолчанию использует $gost12512hash$.
-->

---

# Формат хеша в `/etc/shadow`: самодостаточная строка

<div>

Второе поле `/etc/shadow` — строка **modular crypt format** (<Man p="crypt(5)" />):
поля разделены `$`, первым располагается **идентификатор алгоритма**. Строка пользователя
`bob` из демо-контейнера:

</div>

<FieldRecord class="mt-3" sep="" size="0.9rem"
  :fields="[
    { t: '$y$', hot: true, label: 'идентификатор алгоритма: yescrypt' },
    { t: 'j9T$', label: 'параметры стоимости' },
    { t: 'qqeJEuQm2uJ6Baz8ciP2l0$', label: 'соль хранится в открытом виде' },
    { t: 'vZvVYUhndF7wNaEi…', label: 'результат функции (43 символа)' },
  ]"
/>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-3 border border-slate-400/40 rounded">
<b>Строка самодостаточна:</b> алгоритм, параметры и соль хранятся вместе с хешем,
поэтому проверка не зависит от внешней конфигурации — а в одном файле могут жить
записи разных лет и алгоритмов.
</div>
<div class="p-3 border border-slate-400/40 rounded">
<b>Длина результата фиксирована</b> для данного алгоритма (yescrypt — 43 символа
base64): по длине строки нельзя судить о длине пароля. Разделители и состав полей
зависят от алгоритма — у bcrypt и SHA-crypt формат свой.
</div>
</div>

<div class="mt-2 text-xs opacity-70">
Пример SHA-512-crypt с явным параметром: <code>$6$rounds=100000$CourseSalt$&lt;86 символов&gt;</code>;
применяемый к новым паролям алгоритм задают PAM (лекция 3) или <code>ENCRYPT_METHOD</code>
в <code>login.defs</code> (раздел 3.4).
</div>

<Refs ids="man-crypt man-shadow" />

<!--
Разбор строки bob по полям: $y$ — yescrypt; j9T — закодированные параметры стоимости;
соль 22 символа; результат фиксированной длины 43 символа. Два следствия
самодостаточности: проверка не требует внешней конфигурации, и файл может содержать
хеши разных алгоритмов одновременно — поэтому смена умолчания (например, на
gost-yescrypt) не требует массового сброса паролей: записи мигрируют при очередной
смене. Фиксированная длина результата не выдаёт длину пароля. Формат — соглашение
libxcrypt (modular crypt format), у отдельных алгоритмов свои разделители.
-->

---

# Демо 05: хеш верного пароля совпадает с хранимым в `/etc/shadow`

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/05-password-hashing.txt" section="1" title="demo 05 · mkpasswd пересчитывает хеш bob" fontSize="0.47rem">
  <TCallout :line="2" :col="5" :span="73" :n="1" />
  <TCallout :line="4" :col="28" :span="29" :n="2" />
  <TCallout :line="5" :col="1" :span="73" :n="3" />
  <TCallout :line="7" :col="60" :span="12" :n="4" />
  <TCallout :line="8" :col="31" :span="43" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> хранимая строка <code>bob</code>: алгоритм, параметры, соль, хеш</div>
<div><span class="co-ball">2</span> <code>mkpasswd</code> получает <b>ту же соль</b> с параметрами (<code>-S</code>)</div>
<div><span class="co-ball">3</span> верный пароль воспроизводит строку <b>символ в символ</b></div>
<div><span class="co-ball">4</span> кандидат, отличающийся одним символом…</div>
<div><span class="co-ball">5</span> …даёт совершенно другой результат</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> проверка пароля — это пересчёт с сохранённой солью и сравнение строк;
именно так поступает механизм входа. Обратите внимание: чтобы прочитать хеш, 
понадобились права root (раздел 3.2).
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-hashing.sh</code>; <code>mkpasswd</code> — из пакета whois.
Пароль пользователя bob в примере: <code>Lab-Demo-42!</code>.
</div>

<!--
Демонстрация принципа проверки: mkpasswd с солью из /etc/shadow и верным паролем
воспроизводит хранимую строку символ в символ; пароль, отличающийся одним символом,
даёт совершенно другую строку (лавинный эффект). Это в точности алгоритм login:
пересчитать и сравнить. Подчеркнуть, что хеш пришлось читать с правами root —
права 0640 из раздела 3.2 работают. Пароль Lab-Demo-42! — публичный, учебный;
реальные пароли не передают аргументами командной строки (видны в списке процессов).
-->

---

# Демо 05: хеши пароля без соли совпадают

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/05-password-hashing.txt" section="2" title="demo 05 · «голый» хеш — соли нет" fontSize="0.47rem">
  <TCallout :line="2" :col="1" :span="64" :n="1" />
  <TCallout :line="4" :col="1" :span="64" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/05-password-hashing.txt" section="4" title="demo 05 · фиксированная соль" fontSize="0.47rem">
  <TCallout :line="2" :col="1" :span="73" :n="3" />
  <TCallout :line="4" :col="1" :span="73" :n="4" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1.5 mt-1">
<div><span class="co-ball">1</span> <code>sha256sum</code> — быстрый хеш без соли…</div>
<div><span class="co-ball">3</span> yescrypt с <b>фиксированной</b> солью (<code>-S</code>)…</div>
<div><span class="co-ball">2</span> …тот же пароль — буквально <b>тот же хеш</b></div>
<div><span class="co-ball">4</span> …детерминирован так же: строки совпадают</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> хеш пароля — значение детерминированной хеш-функции от <code>соль||пароль</code>. Нет соли (или соль
общая) и одинаковые пароли дают одинаковые записи: по украденной базе сразу видны
совпадения, а один предвычисленный словарь работает против всей базы.<br/><br/>
Однако детерминизм не недостаток — именно он делает проверку пароля возможной; случайной должна быть соль.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-hashing.sh</code>.
</div>

<!--
Левый терминал — хеширование без соли (sha256sum как модель): два вычисления одного
пароля дают буквально одинаковый результат; то же будет у двух пользователей с
совпадающими паролями. Правый — yescrypt с фиксированной солью: функция столь же
детерминирована. Важно повернуть вывод правильно: детерминизм — не дефект, без него
проверка пароля была бы невозможна (демо выше); дефект — отсутствие или повторное
использование соли, при котором совпадения паролей видны по базе, а предвычисленный
словарь работает против всех записей сразу.
-->

---

# Демо 05: случайная соль маскирует одинаковые пароли

<div class="grid grid-cols-[1.4fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/05-password-hashing.txt" section="3" title="demo 05 · у bob и alice одинаковый пароль" fontSize="0.47rem">
  <TCallout :line="2" :col="12" :span="22" :n="1" />
  <TCallout :line="3" :col="14" :span="22" :n="2" />
  <TCallout :line="6" :col="8" :span="22" :n="3" />
  <TCallout :line="9" :col="8" :span="22" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> соль <code>bob</code>…</div>
<div><span class="co-ball">2</span> …и соль <code>alice</code> различаются — хеши <b>не совпадают</b>, хотя пароль один</div>
<div><span class="co-ball">3</span> <code>mkpasswd</code> без <code>-S</code> генерирует новую случайную соль…</div>
<div><span class="co-ball">4</span> …каждый вызов — другая соль и другой хеш</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> случайная соль при каждой установке пароля скрывает совпадения:
по <code>/etc/shadow</code> непросто определить, что у <code>bob</code> и <code>alice</code>
один пароль.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/05-password-hashing.sh</code>.
</div>

<!--
Кульминация пары демо: у bob и alice настоящие пароли совпадают (так снят контейнер),
но соли разные — и строки в /etc/shadow не совпадают; mkpasswd без -S каждый раз
генерирует свежую соль и даёт новый verifier. Все эти строки равноправны: любая из
них корректно проверяет тот же пароль, потому что соль читается из самой строки.
Связать с таблицей предыдущих слайдов: соль скрывает совпадения и обесценивает
предвычисления, но перебор одной записи не замедляет.
-->

---
layout: section
---

# 3. Парольная аутентификация

<SectionTOC prefix="3" :current="4" :items="[
  'Исторический экскурс',
  'Теневой файл паролей <code>/etc/shadow</code> и групп <code>/etc/gshadow</code>',
  'Хеширование пароля',
  'Парольная политика',
]" />

---

# Парольная политика: поля устаревания и `login.defs`

<div>

Классическая схема Unix задаёт политику **в самой записи**: поля 3–8 `/etc/shadow`
(устаревание, aging) управляются командой <Man p="chage(1)" />; умолчания для
**новых** записей задаёт <Man p="login.defs(5)" />.

</div>

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<div class="t-table text-xs">

| chage | Поле | login.defs | Смысл |
|---|---|---|---|
| `-d` | 3 lstchg | — | день последней смены; `0` — сменить пароль при следующем входе |
| `-m` | 4 min | `PASS_MIN_DAYS` | менять пароль не чаще, чем раз в N дней |
| `-M` | 5 max | `PASS_MAX_DAYS` | пароль требует смены через N дней |
| `-W` | 6 warn | `PASS_WARN_AGE` | предупреждать за N дней до блокировки |
| `-I` | 7 inact | — | блокировать вход через N дней после истечения срока действия пароля |
| `-E` | 8 expire | — | **абсолютная дата** блокировки учётной записи |

</div>

```text
последняя смена ──(+max)──► пароль истёк ──(+inact)──► вход блокируется
                   предупреждение за warn дней ▲
блокировка учётной записи (-E) — отдельная календарная дата
```

</div>
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="3" title="Ubuntu Server 26.04 · умолчания login.defs" fontSize="0.4rem">
  <TCallout :line="2" :col="17" :span="5" :n="1" />
  <TCallout :line="5" :col="16" :span="8" :n="2" />
</TerminalCapture>

<div class="text-xs opacity-70 mt-1">
<span class="co-ball">1</span> 99999 дней — смена фактически не требуется ·<br/>
<span class="co-ball">2</span> здесь же — алгоритм хеширования для shadow-утилит (раздел 3.3)
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Границы классической схемы:</b> поля shadow управляют только <b>сроками</b>.
Сложность пароля, запрет повторов, блокировка после неудачных попыток — реализуется 
средствами подсистемы PAM (лекция 3).
</div>

</v-click>

</div>
</div>

<Refs ids="man-chage man-logindefs man-shadow" />

<!--
Что настраивается классическими средствами: только жизненный цикл пароля и записи.
Поля 3–8 /etc/shadow per-запись, команда chage; таблица сопоставляет ключи chage,
поля и умолчания login.defs (действуют на создаваемые записи; PASS_* и ENCRYPT_METHOD).
min/max/warn/inact — интервалы в днях, отсчитываемые от последней смены; expire —
календарная дата, не сдвигается сменой пароля. chage -d 0 — классический приём
«сменить пароль при первом входе». Явно обозначить границу: состав и сложность
пароля, история, счётчики неудач — не здесь, а в PAM (лекция 3), чтобы не создавать
ложного ощущения полноты классической политики.
-->

---

# Демо 06: управление устареванием с помощью `chage`

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="1" title="demo 06 · до: политика по умолчанию" fontSize="0.45rem">
  <TCallout :line="2" :col="33" :span="15" :n="1" />
  <TCallout :line="4" :col="1" :span="70" :n="2" />
  <TCallout :line="8" :col="59" :span="5" :rows="3" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="2" title="demo 06 · после chage" fontSize="0.45rem">
  <TCallout :line="1" :col="9" :span="35" :n="4" />
  <TCallout :line="3" :col="39" :span="15" :n="5" />
  <TCallout :line="6" :col="59" :span="12" :n="6" />
  <TCallout :line="8" :col="59" :span="12" :n="7" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1.5 mt-1">
<div><span class="co-ball">1</span> умолчания в записи: <code>0:99999:7</code> и пустые inact/expire</div>
<div><span class="co-ball">4</span> одна команда задаёт все интервалы и дату истечения</div>
<div><span class="co-ball">2</span> <code>chage -l</code> переводит дни в даты: день 20752 — Oct 26, 2026</div>
<div><span class="co-ball">5</span> поля 4–8 заполнены: <code>1:90:7:14:21183</code></div>
<div><span class="co-ball">3</span> поля 4–6 записи: <code>0</code>, <code>99999</code> («never») и <code>7</code></div>
<div><span class="co-ball">6</span> истечение пароля — вычислено: смена + 90 дней</div>
<div></div>
<div><span class="co-ball">7</span> истечение записи — дата из <code>-E</code></div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> политика хранится в самой записи <code>/etc/shadow</code> в днях от начала
эпохи; даты «password expires» и «password inactive» — производные от дня последней
смены, а срок учётной записи — независимая календарная дата.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/06-password-policy.sh</code>. День 20752 — 26.10.2026; 21183 — 31.12.2027.
</div>

<!--
Слева — состояние сразу после установки пароля: 0:99999:7, chage -l показывает never.
Справа — одна команда chage задаёт min=1, max=90, warn=7, inact=14 и expire=2027-12-31;
в записи появляются 1:90:7:14:21183, а chage -l показывает вычисленные даты: истечение
пароля = последняя смена + 90, неактивность + 14, истечение записи — абсолютное.
Подчеркнуть, что сами интервалы смена пароля не переписывает — сдвигаются только
вычисляемые даты (от нового дня последней смены).
-->

---

# Блокировка пароля: `!` перед хешем

<div class="grid grid-cols-2 gap-4">
<div>

**Блокировка пароля** — <code>passwd&nbsp;-l</code> (или `usermod -L`) дописывает `!`
**перед** хешем; строка перестаёт быть допустимым результатом `crypt`, и совпадение
при проверке невозможно — вход по паролю закрыт.

- хеш после `!` **сохраняется**: `passwd -u` (`usermod -U`) возвращает прежний пароль;
- `passwd -S` показывает состояние: `P` — пароль задан, `L` — заблокирован,
  `NP` — пароль не задан;
- то же для групп: `gpasswd -R` добавляет `!` в `/etc/gshadow`, `gpasswd -r` очищает
  поле пароля группы.

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Блокировка пароля ≠ блокировка учётной записи:</b> закрыт только <b>парольный</b>
метод входа. Вход по ключу SSH или иным методам, определённым средставми PAM, продолжит работать. 
Полная блокировка учётной записи выполняется с помощью установления срока записи в прошлом: 
<code>chage -E 0</code> (поле 8), снятие — <code>chage -E -1</code>.
</div>

<v-click>

<div class="mt-2 p-3 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>Пустое поле 2:</b> пароль <b>не требуется</b>. Такое
состояние создаёт <code>passwd -d</code> («удалить пароль») — и при опции
<code>nullok</code> у <code>pam_unix</code> (умолчание Ubuntu) вход происходит
<b>без запроса пароля</b>. Пустых полей в <code>/etc/shadow</code> быть не должно.
</div>

</v-click>

</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Сводка значений поля 2</b> (<Man p="shadow(5)" />): <i>хеш</i> — вход по паролю;
<code>!хеш</code> — заблокирован, обратимо; <code>!</code> / <code>*</code> — пароль
не задан, вход по паролю невозможен; <i>пусто</i> — вход без пароля.
</div>

</v-click>

<Refs ids="man-passwd1 man-shadow man-gpasswd man-chage" />

<!--
Механика блокировки: passwd -l дописывает восклицательный знак перед хешем — строка
больше не является допустимым результатом crypt, поэтому никакой введённый пароль не
даст совпадения. Блокировка обратима: хеш сохранён, passwd -u убирает префикс.
Статусы passwd -S: P/L/NP. Для групп аналогично: gpasswd -R ставит '!', gpasswd -r
удаляет пароль группы (пустое поле — у группы это безопасно: пусто означает «пароля
нет», вход только членам). Две важные оговорки: (1) блокировка пароля не трогает
другие методы аутентификации — для полной блокировки используется срок учётной
записи chage -E 0; (2) пустое поле пароля противоположно блокировке — с nullok у
pam_unix это вход вовсе без пароля; демонстрация — следующий слайд.
-->

---

# Демо 06: блокировка и пустое поле пароля

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="4" title="demo 06 · passwd -l: «!» перед хешем" fontSize="0.45rem">
  <TCallout :line="4" :col="7" :span="75" :n="1" />
  <TCallout :line="6" :col="7" :span="1" :n="2" />
  <TCallout :line="9" :col="1" :span="26" :n="3" />
  <TCallout :line="13" :col="7" :span="1" :n="4" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="5" title="demo 06 · passwd -d: пароль не требуется" fontSize="0.45rem">
  <TCallout :line="2" :col="7" :span="1" :n="5" />
  <TCallout :line="5" :col="1" :span="26" :n="6" />
  <TCallout :line="9" :col="6" :span="2" :n="7" />
  <TCallout :line="11" :col="1" :span="51" :n="8" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1.5 mt-1">
<div><span class="co-ball">1</span> <code>!</code> перед хешем <code>alice</code>; хеш сохранён</div>
<div><span class="co-ball">5</span> у <code>carol</code> пароль не задан (<code>!</code>): вход по паролю невозможен</div>
<div><span class="co-ball">2</span> <code>passwd -S</code>: состояние <code>L</code> (locked)</div>
<div><span class="co-ball">6</span> пароль запрошен — и отвергнут: предъявить нечего</div>
<div><span class="co-ball">3</span> даже <b>верный</b> пароль отвергнут</div>
<div><span class="co-ball">7</span> <code>passwd -d</code> оставил поле <b>пустым</b></div>
<div><span class="co-ball">4</span> <code>passwd -u</code> вернул прежний пароль: <code>P</code></div>
<div><span class="co-ball">8</span> <code>su</code> пустил <b>без запроса пароля</b> (<code>nullok</code>)</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10">
<b>Вывод:</b> <code>!</code> и <i>пусто</i> — противоположные состояния; <code>!</code> 
используется для блокировки входа без пароля. Пустые поля хешей в <code>/etc/shadow</code> 
должны быть заменены на <code>!</code>.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/06-password-policy.sh</code>.
</div>

<!--
Слева блокировка: passwd -l добавил «!» перед хешем alice, passwd -S показывает L,
su с верным паролем — Authentication failure; passwd -u возвращает прежний пароль
без повторного ввода. Справа пустое поле: у carol изначально «!» (пароль не задан,
вход по паролю невозможен — su спрашивает пароль и отказывает), но passwd -d делает
поле пустым — и su пускает вовсе без запроса пароля, потому что в common-auth Ubuntu
у pam_unix включён nullok. Завершить правилом аудита: пустых вторых полей в shadow
быть не должно — одна строка awk находит их все.
-->

---

# Демо 06: пароль группы и `/etc/gshadow`

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-3 items-start">
<div>

<TerminalCapture src="captures/06-password-policy.txt" section="6" title="demo 06 · newgrp: членство против пароля группы" fontSize="0.55rem">
  <TCallout :line="2" :col="9" :span="1" :n="1" />
  <TCallout :line="3" :col="7" :span="27" :n="2" />
  <TCallout :line="6" :col="1" :span="7" :n="3" />
  <TCallout :line="10" :col="1" :span="5" :n="4" />
  <TCallout :line="13" :col="1" :span="25" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем вывод:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>!</code> — пароль группы <code>project</code> не задан (по умолчанию в Ubuntu)</div>
<div><span class="co-ball">2</span> у <code>audit</code> пароль группы задан — в поле 2 хеш (записал <Man p="gpasswd(1)" />)</div>
<div><span class="co-ball">3</span> членство достаточно: <code>newgrp</code> сменил первичную группу <code>bob</code> без пароля</div>
<div><span class="co-ball">4</span> <code>bob</code> — не член <code>audit</code>, но, предъявив пароль группы, сделал её первичной</div>
<div><span class="co-ball">5</span> не-члену <code>carol</code> пароль неизвестен — отказ</div>
</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> с <code>!</code> в <code>/etc/gshadow</code> группа доступна только
членам — это безопасное умолчание. Пароль группы — <b>общий секрет</b>: он открыл
<code>audit</code> не-члену <code>bob</code> и откроет любому, кто его узнал, —
на практике вместо этого пользователя добавляют в группу (раздел 2.3).
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/06-password-policy.sh</code>. Пароль группы <code>audit</code>
в примере: <code>Audit-Demo-7!</code>.
</div>

<!--
Замыкает раздел: поле 2 /etc/gshadow в действии. «!» у project — пароль группы не
задан: newgrp для члена (bob) работает без пароля, меняя первичную группу процесса.
У audit пароль задан (хеш записан gpasswd/chgpasswd): newgrp по верному паролю
впускает даже не-члена — bob сделал audit своей первичной группой; carol пароля
не знает — permission denied. Пароль группы — общий секрет: его нельзя выдать
одному и отозвать у другого, поэтому практика — членство вместо пароля группы.
gpasswd -R/-r из предыдущего слайда управляют этим полем.
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
Нумерация сквозная для всей лекции; ссылки «[n]» внизу слайдов ведут сюда и подсвечивают
источник. Точные версии и особенности системы — локальные man-страницы Ubuntu Server 26.04.
</div>
