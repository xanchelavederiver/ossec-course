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

<CodeSnippet src="snippets/cred-struct.h" title="include/linux/cred.h" tag="Linux v6.18">
  <TCallout :line="3" :col="9" :span="6" :rows="8" :n="1" />
  <TCallout :line="12" :col="9" :span="30" :n="2" />
</CodeSnippet>

- Все идентификаторы процесса живут в одной структуре **`struct cred`** — вместе с capabilities, keyrings и ссылкой на user namespace (строки 121–140 опущены).
- `task_struct` каждого процесса держит указатель на **неизменяемый** `cred`: смена идентификаторов — это подготовка новой копии (`prepare_creds`) и её атомарная фиксация (`commit_creds`).

</div>
<div>

<CodeSnippet src="snippets/uidgid_types.h" title="include/linux/uidgid_types.h" />

<CodeSnippet src="snippets/cred-group_info.h" title="include/linux/cred.h" />

<div class="text-xs mt-2">
<div><span class="co-ball">1</span> поля идентификаторов — не «сырые» числа, а обёртки <code>kuid_t</code>/<code>kgid_t</code> над <code>uid_t</code>/<code>gid_t</code>: система типов не даёт перепутать UID пространства ядра с UID из пользовательского пространства</div>
<div class="mt-1"><span class="co-ball">2</span> вторичные группы хранятся отдельной структурой <code>group_info</code> — счётчик ссылок и массив GID переменной длины</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
Linux v6.18 (LTS):
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/cred.h#L111">include/linux/cred.h#L111</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/uidgid_types.h#L7">uidgid_types.h#L7</a>.
</div>

<Refs ids="linux-kernel man-credentials" />

<!--
Подраздел «реализация в ядре»: смотрим, как то, что мы видели в /proc, определено в ядре.
Comments в struct cred дословно повторяют терминологию credentials(7): real/saved/effective/VFS;
именно эти поля показывают /proc/PID/status и ps (демо 03). kuid_t/kgid_t — приём
«типобезопасной обёртки»: внутри лишь uid_t val, но присвоить kuid_t «сырое» число без
явного преобразования (make_kuid/from_kuid) компилятор не позволит — защита от смешения
отображений user namespace.
-->

---

# Исходный код ядра: выбор эффективного UID

<div class="grid grid-cols-2 gap-4">
<div>

<CodeSnippet src="snippets/cred-current.h" title="include/linux/cred.h" tag="Linux v6.18">
  <TCallout :line="3" :col="9" :span="20" :n="1" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/sys-getuid.c" title="kernel/sys.c">
  <TCallout :line="10" :col="52" :span="14" :n="2" />
</CodeSnippet>

</div>
</div>

<div class="mt-3">

<span class="co-ball">1</span> Макросы <code>current_uid()</code>/<code>current_euid()</code> выбирают поле <code>uid</code>/<code>euid</code> из <code>cred</code> **текущего**
процесса — <span class="co-ball">2</span> так реализованы системные вызовы <Man p="getuid(2)" /> и <Man p="geteuid(2)" />.
Проверки привилегий (`capable()`) используют euid, а проверки доступа к файлам — `current_fsuid()` (следующий слайд).

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

# Исходный код ядра: DAC-проверка по fsuid

<div class="grid grid-cols-[1.25fr_1fr] gap-4">
<div>

<CodeSnippet src="snippets/namei-acl_permission_check.c" title="fs/namei.c" tag="Linux v6.18">
  <TCallout :line="9" :col="43" :span="15" :n="1" />
  <TCallout :line="20" :col="21" :span="25" :n="2" />
</CodeSnippet>

<div class="text-xs opacity-70 mt-1">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L381">fs/namei.c#L381</a>
(сравнение с fsuid — строка 411).
</div>

</div>
<div>

Классическая DAC-проверка прав доступа — `acl_permission_check()`;
она выполняется почти при каждом обращении к файлу.

<div class="text-xs mt-2">
<div><span class="co-ball">1</span> «владелец ли я?» — UID владельца файла сравнивается с <b>fsuid</b> процесса, а не с реальным UID</div>
<div class="mt-1"><span class="co-ball">2</span> членство в группе — по fsgid и вторичным группам процесса (<code>group_info</code>)</div>
</div>

<div class="mt-2">

fsuid следует за euid: каждое изменение euid выравнивает fsuid, а развести их может
только <Man p="setfsuid(2)" /> — исторически он нужен файловым серверам (NFS).
Отсюда правило раздела 2.4: **доступ к файлам определяет эффективный UID**.

</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Полный алгоритм — порядок «владелец → группа → остальные», ACL,
привилегия <code>CAP_DAC_OVERRIDE</code> — в лекции о разграничении доступа.
</div>

</div>
</div>

<Refs ids="linux-kernel man-credentials" />

<!--
Замыкаем линию euid/fsuid: в разделе 2.4 мы говорили «эффективный UID используется при
проверке прав доступа» — вот место, где это буквально происходит. Строго говоря, ядро
сравнивает с fsuid, но fsuid принудительно следует за euid (credentials(7)), так что для
обычных процессов это одно и то же; комментарий к generic_permission() прямо объясняет
замысел: "We use 'fsuid' for this, letting us set arbitrary permissions for filesystem
access without changing the 'normal' uids which are used for other things" (fs/namei.c,
строки 450–452). Детали алгоритма (быстрый путь mask*0111, сдвиги mode >>= 6 / >>= 3,
ACL) здесь сознательно не разбираем — это материал лекции 4.
-->

---

# Исходный код ядра: наследование при `fork`

<div class="grid grid-cols-2 gap-4">
<div>

<CodeSnippet src="snippets/fork-copy_process.c" title="kernel/fork.c" tag="Linux v6.18">
  <TCallout :line="8" :col="18" :span="26" :n="1" />
</CodeSnippet>

<CodeSnippet src="snippets/cred-prepare_creds.c" title="kernel/cred.c">
  <TCallout :line="8" :col="9" :span="38" :n="4" />
</CodeSnippet>

<div class="text-xs mt-1">
<div><span class="co-ball">1</span> создание процесса (<code>copy_process</code>) наследует учётные данные вызовом <code>copy_creds</code></div>
<div class="mt-1"><span class="co-ball">4</span> наследование из <Man p="credentials(7)" /> — это один <code>memcpy</code>: <b>побайтовая копия</b> всех UID/GID, capabilities и групп</div>
</div>

<div class="text-xs opacity-70 mt-1">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/fork.c#L2046">fork.c#L2046</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/cred.c#L290">cred.c#L290</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/kernel/cred.c#L219">cred.c#L219</a>.
</div>

</div>
<div>

<CodeSnippet src="snippets/cred-copy_creds.c" title="kernel/cred.c">
  <TCallout :line="10" :col="17" :span="26" :n="2" />
  <TCallout :line="17" :col="15" :span="16" :n="3" />
  <TCallout :line="21" :col="9" :span="39" :n="5" />
</CodeSnippet>

<div class="text-xs mt-1">
<div><span class="co-ball">2</span> поток (<code>CLONE_THREAD</code>) копии не получает — он разделяет <code>cred</code> своего процесса</div>
<div class="mt-1"><span class="co-ball">3</span> для нового процесса готовится копия <code>cred</code> родителя (слева внизу)</div>
<div class="mt-1"><span class="co-ball">5</span> копия фиксируется в <code>task_struct</code> потомка</div>
</div>

</div>
</div>

<Refs ids="linux-kernel man-credentials" />

<!--
Вся «магия» наследования — memcpy в prepare_creds. Отсюда же видно отличие потока от
процесса: CLONE_THREAD не копирует cred вообще. Это код, который выполнился в демо 04
между строками «after seteuid(ruid)» и «child after fork».
-->

---

# Исходный код ядра: setuid-бит при `execve`

<div class="grid grid-cols-[1.3fr_1fr] gap-4">
<div>

<CodeSnippet src="snippets/exec-bprm_fill_uid.c" title="fs/exec.c" tag="Linux v6.18">
  <TCallout :line="6" :col="9" :span="18" :n="1" />
  <TCallout :line="15" :col="9" :span="32" :n="2" />
  <TCallout :line="23" :col="17" :span="44" :n="3" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/commoncap-fix-ids.c" title="commoncap.c · cap_bprm_creds_from_file()">
  <TCallout :line="1" :col="9" :span="35" :rows="2" :n="4" />
</CodeSnippet>

<div class="text-xs mt-2">
<div><span class="co-ball">1</span> <code>mode</code> объявлен в прологе функции — локальная копия режима файла</div>
<div class="mt-1"><span class="co-ball">2</span> …и заполняется из inode исполняемого файла (<code>i_mode</code>) — те самые биты режима, включая setuid/setgid</div>
<div class="mt-1"><span class="co-ball">3</span> единственное изменение при setuid-запуске: euid := владелец файла (<code>vfsuid</code> прочитан из того же inode)</div>
<div class="mt-1"><span class="co-ball">4</span> затем сохранённый UID и fsuid выравниваются по новому euid — итог алгоритма из раздела 2.4</div>
</div>

<div class="mt-2">

Здесь же видно, когда setuid-бит игнорируется: монтирование с `nosuid`
и режим `no_new_privs` (<Man p="prctl(2)" />).

</div>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
Linux v6.18:
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/exec.c#L1534">exec.c#L1534</a>
(вызывается из execve(2); присваивание euid — строка 1577) ·
<a href="https://github.com/torvalds/linux/blob/v6.18/security/commoncap.c#L953">commoncap.c#L953</a>.
</div>

<Refs ids="linux-kernel man-execve" />

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
    'период неактивности после истечения срока действия до блокировки пароля',
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
<b>Вывод:</b> хеш пароля — значение детерминированной хеш-функции от <code>пароль||соль</code>. Нет соли (или соль
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

# 4. Управление пользователями
## CRUD и значения по умолчанию

<SectionTOC prefix="4" :current="1" :items="[
  'Команды: создание, изменение, удаление',
  'Значения по умолчанию',
  'Конфигурация окружения пользователя',
]" />

<!--
Раздел связывает уже изученные файлы учётных записей (разделы 2–3) с практикой
администрирования: какими командами заводят и правят записи, какие умолчания
определяют свойства новой учётной записи и где именно задаётся окружение
пользователя. Подзаголовок обозначает две сквозные темы: CRUD — полный жизненный
цикл записи — и значения по умолчанию, которые незаметно, но повсеместно влияют
на безопасность создаваемых учётных записей.
-->

---

# Учётные записи: создать, изменить, удалить

<div>

Жизненный цикл учётной записи — это **CRUD**: создание (*create*), чтение
(*read* — <Man p="getent(1)" />, <Man p="id(1)" />, разделы 2.1–2.2), изменение
(*update*) и удаление (*delete*). Низкоуровневые POSIX-утилиты пакета
**shadow-utils** правят `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`
согласованно и под блокировкой.

</div>

<div class="t-table text-xs mt-2">

| Команда | Действие | Ключевые опции |
|---|---|---|
| <Man p="useradd(8)" /> | создать запись | `-m` создать дом и скопировать skel · `-G` вторичные группы · `-s` оболочка · `-r` системная (UID < `UID_MIN`) · `-D` показать/изменить умолчания |
| <Man p="usermod(8)" /> | изменить запись | `-aG` **добавить** во вторичные группы (без `-a` — заменить!) · `-g` сменить первичную группу · `-L`/`-U` заблокировать/снять блокировку · `-l` переименовать · `-s` сменить оболочку |
| <Man p="userdel(8)" /> | удалить запись | `-r` удалить дом и почтовый ящик · `-f` принудительно |

</div>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Ловушка <code>usermod -G</code>:</b> без <code>-a</code> ключ <code>-G</code>
<b>замещает</b> весь список вторичных групп — пользователь молча теряет прежнее
членство (например, в <code>sudo</code>). Для добавления — всегда
<code>usermod -aG группа пользователь</code>.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Высокоуровневая обёртка:</b> в Debian/Ubuntu для людей рекомендуют
<Man p="adduser(8)" /> / <code>addgroup</code> — интерактивные скрипты поверх
<code>useradd</code> с политикой в <code>adduser.conf(5)</code>. <code>useradd</code>
остаётся основой для скриптов и автоматизации.
</div>
</div>

<Refs ids="man-useradd man-usermod man-userdel man-adduser" />

<!--
CRUD как рамка: создание, чтение (уже пройдено — getent/id и файлы учётных записей),
изменение, удаление. Ключевой инструмент — shadow-utils: правят текстовые базы
согласованно, с блокировкой (passwd.lock и т. п.), не позволяя двум редакторам
испортить файл. По таблице: useradd заводит запись (с -m — дом и skel), usermod
правит, userdel удаляет (с -r — вместе с домом). Отдельно подчёркиваем две вещи.
Первая — классическая ошибка: usermod -G без -a перезаписывает список вторичных
групп, и администратор нечаянно выкидывает пользователя, например, из sudo; правильно
usermod -aG. Вторая — в Debian/Ubuntu поверх низкоуровневых утилит есть adduser/addgroup:
интерактивные обёртки с политикой в adduser.conf, их рекомендуют для ручного
заведения людей, тогда как useradd — для автоматизации.
-->

---

# Группы: создать, изменить, назначить членов

<div>

Группы правятся теми же средствами. Важно различать **первичную** группу (поле 4
`/etc/passwd`, одна на пользователя) и **вторичные** (список членов в `/etc/group`,
раздел 2.3).

</div>

<div class="t-table text-xs mt-2">

| Команда | Действие | Ключевые опции |
|---|---|---|
| <Man p="groupadd(8)" /> | создать группу | `-g GID` задать идентификатор · `-r` системная группа (GID < `GID_MIN`) |
| <Man p="groupmod(8)" /> | изменить группу | `-n` переименовать · `-g` сменить GID |
| <Man p="groupdel(8)" /> | удалить группу | нельзя удалить **первичную** группу существующего пользователя |
| <Man p="gpasswd(1)" /> | членство и управление | `-a`/`-d` добавить/убрать члена · `-A` назначить администраторов · `-M` задать весь список членов |

</div>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
<b>Первичная vs вторичная:</b> первичную меняют <code>usermod -g</code> (запись в
<code>/etc/passwd</code>); вторичное членство — <code>gpasswd -a</code> или
<code>usermod -aG</code> (запись в <code>/etc/group</code>). Сменить первичную группу
<b>сеанса</b> позволяет <Man p="newgrp(1)" /> (раздел 3.4).
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>UPG (User Private Group):</b> при <code>USERGROUPS_ENAB yes</code> (раздел 4.2)
<code>useradd</code> заводит для каждого пользователя одноимённую первичную группу,
а <code>userdel</code> удаляет её вместе с записью. Это схема по умолчанию в
Debian/Ubuntu.
</div>
</div>

<Refs ids="man-groupadd man-groupmod man-groupdel man-gpasswd" />

<!--
Группы — те же CRUD-утилиты. Красная нить: различать первичную группу (одна,
хранится в 4-м поле /etc/passwd) и вторичные (членство — в /etc/group). groupadd/mod/del
создают, переименовывают, удаляют; groupdel защищён — не даст удалить первичную группу
живого пользователя. gpasswd заведует членством и администраторами группы, а также
паролем группы (раздел 3.4). Два акцента: как и чем меняется первичное против вторичного
членства (usermod -g против gpasswd -a / usermod -aG; newgrp меняет первичную группу
только текущего сеанса); и схема UPG — при USERGROUPS_ENAB yes каждому пользователю
заводится своя одноимённая группа, это умолчание Ubuntu, к нему вернёмся в демо 07.
-->

---
layout: section
---

# 4. Управление пользователями
## CRUD и значения по умолчанию

<SectionTOC prefix="4" :current="2" :items="[
  'Команды: создание, изменение, удаление',
  'Значения по умолчанию',
  'Конфигурация окружения пользователя',
]" />

---

# `login.defs`: умолчания для новых записей

<div class="grid grid-cols-[1.3fr_1fr] gap-4 items-start">
<div>

<Man p="login.defs(5)" /> задаёт общесистемные умолчания для **создаваемых**
записей. Параметры старения пароля и хеширования (`PASS_*`, `ENCRYPT_METHOD`) —
в разделе 3; здесь — влияющие на саму учётную запись.

<div class="t-table text-xs mt-2">

| Параметр | Назначение |
|---|---|
| `UID_MIN` / `UID_MAX` | диапазон UID обычных пользователей (1000–60000); системным (`-r`) — ниже |
| `GID_MIN` / `GID_MAX` | то же для GID групп |
| `HOME_MODE` | права нового домашнего каталога (Ubuntu `0750`, прежде `0755`) |
| `USERGROUPS_ENAB` | `yes` → `useradd` создаёт одноимённую первичную группу (UPG) |
| `SUB_UID_*`&nbsp;/&nbsp;`SUB_GID_*` | диапазоны subordinate-id (`/etc/subuid`) для user namespaces |

</div>

</div>
<div>

<TerminalCapture src="captures/07-user-defaults.txt" section="Умолчания login.defs" title="Ubuntu Server 26.04 · login.defs" fontSize="0.5rem">
  <TCallout :line="2" :col="17" :span="4" :n="1" />
  <TCallout :line="7" :col="17" :span="3" :n="2" />
</TerminalCapture>

<div class="text-xs opacity-70 mt-1">
<span class="co-ball">1</span> права нового дома — <code>0750</code> ·<br/>
<span class="co-ball">2</span> UPG включена по умолчанию
</div>

</div>
</div>

<Refs ids="man-logindefs debian-policy" />

<!--
login.defs — «политика по умолчанию» для создаваемых записей. Явно отделяем то, что
уже разобрано в разделе 3 (PASS_* и ENCRYPT_METHOD — старение и хеширование), от
параметров, формирующих саму запись. По таблице: диапазоны UID_MIN/UID_MAX и
GID_MIN/GID_MAX отделяют «людей» от системных записей (ниже UID_MIN — для -r);
HOME_MODE задаёт права нового домашнего каталога (в Ubuntu ужесточён до 0750 — чужой
дом не прочитать; раньше было 0755), а если он не задан — применяется UMASK;
USERGROUPS_ENAB yes включает схему UPG; SUB_UID/SUB_GID — диапазоны для user namespaces
(rootless-контейнеры). На терминале — реальные значения из образа 26.04.
-->

---

# Собственные умолчания `useradd` и каталог-шаблон `skel`

<div class="grid grid-cols-[1fr_1.05fr] gap-4 items-start">
<div>

Часть умолчаний хранится не в `login.defs`, а в `/etc/default/useradd` — их
показывает и меняет `useradd -D`. Среди них — **оболочка по умолчанию** и
**каталог-шаблон** `SKEL`.

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Оболочка по умолчанию — <code>/bin/sh</code>, не <code>bash</code>.</b> Если не указать
<code>-s</code> (и не воспользоваться <code>adduser</code>), новый пользователь получит
<code>/bin/sh</code> (в Ubuntu — <code>dash</code>).
</div>

<div class="mt-2 text-xs">

Каталог-шаблон копируется в домашний каталог при создании (`useradd -m`):

- **`SKEL=/etc/skel`** — локальный шаблон администратора (`.bashrc`, `.profile`,
  `.bash_logout`);
- **`USRSKEL=/usr/etc/skel`** — поставляемый дистрибутивом шаблон (нововведение
  `shadow` 4.17 в духе разделения `/usr` ↔ `/etc`); оба каталога объединяются.

</div>

</div>
<div>

<TerminalCapture src="captures/07-user-defaults.txt" section="Умолчания useradd" title="Ubuntu Server 26.04 · useradd -D" fontSize="0.5rem">
  <TCallout :line="7" :col="7" :span="7" :n="1" />
  <TCallout :line="8" :col="6" :span="9" :n="2" />
  <TCallout :line="9" :col="9" :span="13" :n="3" />
</TerminalCapture>

<div class="text-xs opacity-70 mt-1">
<span class="co-ball">1</span> оболочка по умолчанию ·
<span class="co-ball">2</span> локальный шаблон ·<br/>
<span class="co-ball">3</span> шаблон дистрибутива
</div>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>skel — чувствительное место:</b> что лежит в шаблоне, попадёт в домашний каталог
<b>каждого</b> будущего пользователя. Подмена файла в <code>skel</code> = закладка во
все новые учётные записи (раздел 4.3).
</div>

</div>
</div>

<Refs ids="man-useradd shadow-maint" />

<!--
Второй источник умолчаний — /etc/default/useradd, его показывает useradd -D. Два
практически важных пункта. Первый: SHELL=/bin/sh — то есть «голый» useradd без -s
создаёт пользователя с /bin/sh (в Ubuntu это dash), а не bash; привычный bash даёт
adduser или явный -s. Второй: SKEL и новый USRSKEL. При useradd -m содержимое
каталога-шаблона копируется в новый дом. Исторически это /etc/skel; в shadow 4.17
добавлен /usr/etc/skel для шаблонов, поставляемых дистрибутивом (логика разделения
неизменяемого /usr и настраиваемого /etc), и оба объединяются. Отсюда прямое следствие
для безопасности: skel тиражируется во все новые домашние каталоги, поэтому закладка в
нём — это закладка во всех будущих пользователей; это мост к разделу про окружение.
-->

---

# Демо 07: создание со значениями по умолчанию

<div class="grid grid-cols-[1.55fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/07-user-defaults.txt" section="Создание пользователя" title="demo 07 · useradd -m ossec-demo1" fontSize="0.52rem">
  <TCallout :line="3" :col="15" :span="9" :n="1" />
  <TCallout :line="5" :col="15" :span="4" :n="2" />
  <TCallout :line="7" :col="1" :span="10" :n="3" />
  <TCallout :line="9" :col="1" :span="31" :n="4" />
  <TCallout :line="11" :col="13" :span="1" :n="5" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/07-user-defaults.txt" section="Создание группы" title="demo 07 · groupadd" fontSize="0.52rem">
  <TCallout :line="3" :col="14" :span="4" :n="6" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> UID и GID — из диапазона с <code>UID_MIN</code>: <code>1001</code></div>
<div><span class="co-ball">2</span> заведена одноимённая первичная группа (UPG)</div>
<div><span class="co-ball">3</span> дом — <code>0750</code> (<code>HOME_MODE</code>)</div>
<div><span class="co-ball">4</span> в дом скопированы файлы из <code>skel</code></div>
<div><span class="co-ball">5</span> поле пароля — <code>!</code>: запись создана <b>заблокированной</b></div>
<div><span class="co-ball">6</span> отдельная группа получает GID <code>1002</code></div>
</div>
</div>

</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> одна команда без опций применила сразу несколько умолчаний
(<code>login.defs</code> и <code>/etc/default/useradd</code>). Запись создана без
пароля — до <code>passwd</code>/<code>chpasswd</code> вход невозможен.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/07-user-defaults.sh</code>.
</div>

<!--
Демо показывает умолчания в действии. useradd -m ossec-demo1 без единой опции: ядро
выдаёт UID/GID из диапазона UID_MIN (1001); USERGROUPS_ENAB yes заводит одноимённую
первичную группу; дом создан с правами 0750 (HOME_MODE) и заполнен из skel; поле пароля
в shadow — «!», то есть запись заблокирована, войти нельзя, пока админ не задаст пароль
(passwd/chpasswd). Отдельная группа groupadd получает следующий свободный GID. Главная
мысль: «пустая» команда на деле несёт политику — значения по умолчанию определяют
свойства записи, и их стоит осознанно настраивать.
-->

---

# Демо 08: изменение умолчаний → иной результат

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/08-change-defaults.txt" section="До" title="demo 08 · до: стоковые умолчания" fontSize="0.5rem">
  <TCallout :line="3" :col="44" :span="7" :n="1" />
  <TCallout :line="5" :col="1" :span="10" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/08-change-defaults.txt" section="После" title="demo 08 · после: изменены умолчания" fontSize="0.5rem">
  <TCallout :line="7" :col="44" :span="9" :n="3" />
  <TCallout :line="9" :col="1" :span="10" :n="4" />
  <TCallout :line="11" :col="31" :span="2" :n="5" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1 mt-1">
<div><span class="co-ball">1</span> оболочка <code>demo1</code> — <code>/bin/sh</code> (умолчание)</div>
<div><span class="co-ball">3</span> у <code>demo2</code> — уже <code>/bin/bash</code> (сменили <code>SHELL</code>)</div>
<div><span class="co-ball">2</span> дом <code>demo1</code> — <code>0750</code></div>
<div><span class="co-ball">4</span> дом <code>demo2</code> — <code>0700</code> (сменили <code>HOME_MODE</code>)</div>
<div class="col-span-2"><span class="co-ball">5</span> поле <code>inactive</code> в <code>shadow</code> = <code>30</code> — следствие <code>useradd -D -f 30</code></div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> та же команда <code>useradd -m</code> даёт разные учётные записи — свойства
задаются <b>умолчаниями</b>. Умолчание — это политика: ослабленное значение незаметно
распространяется на все будущие записи.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/08-change-defaults.sh</code>.
</div>

<!--
Демо-контраст: до и после изменения умолчаний. Слева — demo1, созданный на стоковых
значениях: оболочка /bin/sh, дом 0750. Затем меняем умолчания: useradd -D -s /bin/bash -f 30
правит /etc/default/useradd, а sed — HOME_MODE в login.defs на 0700. Справа — demo2,
созданный той же командой useradd -m: теперь оболочка /bin/bash, дом 0700, а поле inactive
в shadow равно 30 (следствие -f 30). Вывод, важный для защиты: умолчание — это тихая
политика. Ослабив его один раз (например, HOME_MODE 0755 или слабый ENCRYPT_METHOD),
администратор распространит ослабление на все записи, которые будут созданы потом.
-->

---
layout: section
---

# 4. Управление пользователями
## CRUD и значения по умолчанию

<SectionTOC prefix="4" :current="3" :items="[
  'Команды: создание, изменение, удаление',
  'Значения по умолчанию',
  'Конфигурация окружения пользователя',
]" />

---

# Окружение пользователя: какие файлы и кто их читает

<div>

**Окружение** учётной записи складывается из двух независимых механизмов: PAM
устанавливает переменные для всего сеанса входа ещё **до** оболочки, а оболочка
при запуске выполняет свои стартовые файлы. Важно различать их — и различать
**login**-оболочку (вход, `ssh`, `su -`) и **интерактивную не-login** (терминал в
уже открытом сеансе).

</div>

<div class="t-table text-xs mt-2">

| Файл | Кто и когда читает | Назначение |
|---|---|---|
| `/etc/environment` | PAM-модуль <Man p="pam_env(8)" /> при входе (login, ssh, `su -`) — **не оболочка** | системные переменные (`PATH`, `LANG`); только `КЛЮЧ=значение`, без подстановок оболочки |
| `/etc/profile` + `/etc/profile.d/*.sh` | любая **login**-оболочка (sh-совместимая) | общесистемная инициализация входа; Ubuntu отсюда подключает `/etc/bash.bashrc` |
| `/etc/bash.bashrc` | любая **интерактивная** bash-оболочка | общесистемные настройки bash (приглашение, алиасы) |
| `~/.profile` / `~/.bash_profile` / `~/.bash_login` | **login**-оболочка пользователя (bash берёт первый существующий) | личная инициализация входа; Ubuntu-овский `~/.profile` подключает `~/.bashrc` |
| `~/.bashrc` | каждая **интерактивная не-login** bash-оболочка | личные алиасы, функции, приглашение, `PATH` |
| `~/.bash_logout` | при выходе из login-оболочки | очистка сеанса |

</div>

<Refs ids="man-bash man-pam-env man-environ" />

<!--
Ключевое различие, которое студенты часто путают. Во-первых, два независимых слоя:
pam_env читает /etc/environment и выставляет переменные на весь PAM-сеанс ещё до запуска
оболочки (поэтому /etc/environment — не скрипт: только КЛЮЧ=значение, без подстановок),
а оболочка отдельно исполняет свои стартовые файлы. Во-вторых, тип оболочки: login-оболочка
(вход на консоль, ssh, su -) читает /etc/profile и затем первый существующий из
~/.bash_profile, ~/.bash_login, ~/.profile; интерактивная не-login (новый терминал в
графическом сеансе, su без дефиса) — /etc/bash.bashrc и ~/.bashrc. В Ubuntu цепочки
связаны: /etc/profile подключает /etc/bash.bashrc, а ~/.profile подключает ~/.bashrc,
поэтому на практике ~/.bashrc выполняется почти всегда — это и делает его излюбленной
целью. Источник порядка — раздел INVOCATION в bash(1).
-->

---

# Атаки через файлы окружения: исполнение при входе

<div>

Стартовые файлы **исполняются как код** при каждом входе или запуске оболочки.
Отсюда принцип, параллельный разделу 2.2 («запись в `/etc/passwd` = root»): **право
записи в стартовый файл = исполнение кода от имени его владельца** — это
закрепление (persistence) и, если владелец привилегирован, повышение привилегий.
Техника каталогизирована как **MITRE ATT&CK T1546.004**.

</div>

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div>
<b class="text-red-600">Векторы</b>
<div class="mt-1 space-y-1">
<div>• <code>~/.bashrc</code>, <code>~/.profile</code> — доступный на запись дом: код исполняется от имени пользователя при каждом сеансе; если жертва — root, это закрепление в системе</div>
<div>• <code>/etc/profile</code>, <code>/etc/profile.d/*.sh</code>, <code>/etc/bash.bashrc</code> — пишет root: одна закладка исполняется у <b>всех</b> пользователей</div>
<div>• <code>/etc/skel</code> — попадает в <b>каждую новую</b> учётную запись (раздел 4.2)</div>
<div>• подмена <code>PATH</code> в <code>~/.bashrc</code>: доступный на запись каталог в начале <code>PATH</code> → троянские <code>sudo</code>, <code>ls</code> (кража пароля)</div>
<div>• <code>LD_PRELOAD</code> / <code>LD_LIBRARY_PATH</code> → подмена разделяемых библиотек</div>
</div>
</div>
<div>
<b class="text-teal-700">Защита</b>
<div class="mt-1 space-y-1">
<div>• строгие права на дом (<code>HOME_MODE 0750</code>/<code>0700</code>, раздел 4.2) — чужой <code>~/.bashrc</code> недоступен на запись</div>
<div>• контроль целостности стартовых файлов (<Man p="auditd(8)" />, AIDE), сигнал — изменение с последующим необычным процессом при входе</div>
<div>• не ставить доступные на запись каталоги и <code>.</code> в начало <code>PATH</code></div>
<div>• проверять <code>/etc/skel</code> и системные профили при аудите</div>
</div>
</div>
</div>

<Refs ids="mitre-shell-config man-bash man-pam-env" />

<!--
Это кульминация раздела и сквозной идеи лекции. Раз стартовые файлы исполняются как код,
право записи в них эквивалентно исполнению от имени владельца — ровно как запись в
/etc/passwd эквивалентна правам root (раздел 2.2). Отсюда persistence и, если владелец
привилегирован, escalation; техника занесена в MITRE ATT&CK как T1546.004 (Event Triggered
Execution: Unix Shell Configuration Modification), тактики Persistence и Privilege Escalation.
Векторы: пользовательские dotfiles при небрежных правах дома (код от имени пользователя;
если это root — закрепление в системе); системные профили, которые пишет root (одна правка
бьёт по всем); /etc/skel (во все будущие записи); подмена PATH (троянский sudo/ls, в том
числе для кражи пароля); LD_PRELOAD/LD_LIBRARY_PATH для подмены библиотек. Защита зеркальна:
строгие права на дом (возврат к HOME_MODE из 4.2), контроль целостности (auditd/AIDE),
аккуратный PATH без . и записываемых каталогов в начале, аудит skel и системных профилей.
Детали детектирования — по странице техники MITRE. Демонстрация — на следующих слайдах.
-->

---

# Демо 09: кто какой файл читает

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/09-environment-files.txt" section="Системные файлы" title="demo 09 · системные файлы окружения" fontSize="0.46rem" />

<div class="mt-1 text-xs opacity-70">
<code>/etc/environment</code> читает <b>PAM</b> (<code>pam_env</code>), <code>/etc/profile</code>
перебирает <code>/etc/profile.d/*.sh</code>.
</div>

</div>
<div>

<TerminalCapture src="captures/09-environment-files.txt" section="Кто какой файл читает" title="demo 09 · login- vs интерактивная оболочка" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="42" :rows="2" :n="1" />
  <TCallout :line="6" :col="1" :span="42" :n="2" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div><span class="co-ball">1</span> <b>login</b>-оболочка: сработали <code>/etc/profile.d</code> и <code>~/.profile</code> (а тот подключил <code>~/.bashrc</code>)</div>
<div class="mt-1"><span class="co-ball">2</span> <b>интерактивная не-login</b>: только <code>~/.bashrc</code></div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/09-environment-files.sh</code>. В <code>~/.profile</code> и <code>~/.bashrc</code>
временно добавлены строки-маркеры, чтобы увидеть, что и когда выполняется.
</div>

<!--
Демонстрация порядка чтения. Слева — системные файлы: /etc/environment (его читает PAM,
pam_env, а не оболочка) и фрагмент /etc/profile, перебирающий /etc/profile.d/*.sh. Справа
проверяем тип оболочки экспериментально: в ~/.profile, ~/.bashrc и в скрипт profile.d
вставлены строки-маркеры. bash -l (login) печатает маркеры profile.d и ~/.profile, а тот
подключает ~/.bashrc; bash -i (интерактивная не-login) печатает только маркер ~/.bashrc.
Это подтверждает таблицу с предыдущего слайда и объясняет, почему ~/.bashrc — почти
универсально исполняемый файл.
-->

---

# Демо 09: подмена `~/.bashrc`

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/09-environment-files.txt" section="выполнение кода" title="demo 09 · закладка в ~/.bashrc" fontSize="0.46rem">
  <TCallout :line="1" :col="8" :span="34" :n="1" />
  <TCallout :line="7" :col="1" :span="11" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/09-environment-files.txt" section="перехват PATH" title="demo 09 · подмена PATH" fontSize="0.46rem">
  <TCallout :line="3" :col="8" :span="38" :n="3" />
  <TCallout :line="6" :col="1" :span="31" :n="4" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1 mt-1">
<div><span class="co-ball">1</span> атакующий дописал полезную нагрузку в <code>~/.bashrc</code> жертвы</div>
<div><span class="co-ball">3</span> и добавил свой каталог в начало <code>PATH</code></div>
<div><span class="co-ball">2</span> запуск оболочки жертвой создал файл-маркер — <b>от её имени</b></div>
<div><span class="co-ball">4</span> <code>id</code> теперь берётся из подставного каталога — вызов перехвачен</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> право записи в <code>~/.bashrc</code> равносильно исполнению кода от имени
владельца при каждом сеансе — как запись в <code>/etc/passwd</code> равносильна правам root
(раздел 2.2). Отсюда — строгие права на домашние каталоги.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/09-environment-files.sh</code>. Нагрузки учебные: создание файла-маркера
и троянский <code>id</code>, печатающий баннер перед настоящим выводом.
</div>

<!--
Демо-подтверждение атаки T1546.004 на безопасном примере. Слева: атакующий дописывает в
~/.bashrc жертвы полезную нагрузку (здесь — touch файла-маркера); когда жертва запускает
интерактивную оболочку, маркер создаётся от её имени — то есть исполнился чужой код.
Справа: та же точка записи позволяет подменить PATH — каталог ~/.local/bin ставится в
начало, и в нём лежит троянский id; вызов id резолвится в подставной бинарник (command -v
показывает путь в домашнем каталоге), баннер подтверждает перехват, после чего для
правдоподобия вызывается настоящий id. Нагрузки намеренно безвредны. Главный тезис,
замыкающий раздел и перекликающийся с разделом 2.2: контроль над стартовым файлом = код
от имени владельца, поэтому строгие права на домашние каталоги (HOME_MODE) — не
косметика, а граница безопасности.
-->

---
layout: section
---

# 5. Идентификация и парольная аутентификация в приложениях
## Программный интерфейс стандартной библиотеки C

<SectionTOC prefix="5" :current="1" :items="[
  'Чтение учётных записей: passwd и group',
  'Чтение теневого файла shadow',
  'Запрос и проверка пароля: getpass и crypt',
  'Примеры: утилиты login и passwd',
]" />

<!--
Разделы 2–4 описывали учётные базы со стороны администратора: файлы, их формат и команды
управления. Этот раздел меняет точку зрения на программистскую: как те же данные читает
приложение. Стандартная библиотека C предоставляет устоявшийся интерфейс (описан у
Керриска в главе 8), поверх которого построены и системные утилиты — ls, id, su, login.
План: структуры и функции чтения passwd и group, затем shadow, затем запрос и проверка
пароля, и в завершение — как всё это собрано в классических утилитах login и passwd.
-->

---

# `struct passwd`: строка файла становится структурой

Приложения не разбирают `/etc/passwd` самостоятельно: libc возвращает запись
готовой структурой `struct passwd` из заголовочного файла `<pwd.h>` — поля
следуют за полями строки файла.

<div class="grid grid-cols-[1.05fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/pwd-struct.h" title="pwd.h" tag="glibc 2.43">
  <TCallout :line="5" :col="3" :span="16" :n="2" />
</CodeSnippet>

</div>
<div>

<FieldRecord size="0.72rem" legendSize="0.6rem" :cols="1"
  :fields="['bob', { t: 'x', hot: true }, '1001', '1001', '', '/home/bob', '/bin/bash']"
  :legend="[
    'pw_name — имя входа',
    { t: 'pw_passwd — признак «x», а не хеш', hot: true },
    'pw_uid — идентификатор пользователя (uid_t)',
    'pw_gid — GID первичной группы (gid_t)',
    'pw_gecos — комментарий (здесь пусто)',
    'pw_dir — домашний каталог',
    'pw_shell — оболочка',
  ]"
/>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">2</span> В поле <code>pw_passwd</code> приложение увидит лишь
признак <code>x</code>: хеш пароля вынесен в <code>/etc/shadow</code> — за ним
придётся обращаться к <code>struct spwd</code> (раздел 5.2).
</div>

<div class="text-xs opacity-70 mt-2">
glibc 2.43: <a href="https://sourceware.org/git/?p=glibc.git;a=blob;f=nss/pwd.h;hb=glibc-2.43#l49">nss/pwd.h#l49</a>
(устанавливается как <code>/usr/include/pwd.h</code>).
</div>

<Refs ids="man-getpwnam man-passwd glibc-source kerrisk-tlpi" />

<!--
Переход от файла к программному интерфейсу. Слева — дословное определение struct passwd
из glibc 2.43: семь полей, и их порядок в точности повторяет порядок семи полей строки
/etc/passwd (раздел 2.2). Справа — знакомая строка bob, разложенная по полям структуры:
имя, признак пароля, UID, GID первичной группы, GECOS, домашний каталог, оболочка.
Числовые поля уже преобразованы к uid_t/gid_t — приложению не нужно разбирать текст.
Единственное «пустое» место — pw_passwd: со времён выделения shadow (раздел 3) здесь
хранится лишь «x», и это мостик к struct spwd. Комментарий в самой glibc прямо говорит:
hashed passphrase, if shadow database not in use.
-->

---

# Две операции чтения `passwd`: точечный поиск и перебор

<div class="grid grid-cols-2 gap-4 mt-1 items-start">
<div>

**Поиск одной записи** — по имени (вход в систему) или по UID
(например, `ls -l` подписывает владельца файла):

<CodeSnippet src="snippets/pwd-lookup.h" title="pwd.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getpwnam(3)" /> — запись с заданным именем входа;
- <Man p="getpwuid(3)" /> — запись с заданным UID;
- результат — указатель на **статический буфер** (следующий вызов
  перезапишет его) или `NULL`, если записи нет.

</div>

</div>
<div>

**Перебор всех записей** — последовательное чтение базы:

<CodeSnippet src="snippets/pwd-enum.h" title="pwd.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getpwent(3)" /> — очередная запись; при первом вызове открывает базу, в конце возвращает `NULL`;
- `setpwent` — перемотка на начало;
- `endpwent` — закрыть базу по окончании работы.

</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Функции читают не файл, а <b>базу учётных записей</b>: glibc направляет запрос через
NSS (<code>/etc/nsswitch.conf</code>), поэтому ответ может прийти и из сетевого
каталога (LDAP), а не только из <code>/etc/passwd</code>. Для многопоточных программ
предусмотрены реентерабельные варианты <code>getpwnam_r</code> и др.
</div>

<Refs ids="man-getpwnam man-getpwent glibc-source kerrisk-tlpi" />

<!--
Два режима доступа. Точечный поиск: getpwnam — главный инструмент программ входа (от
имени к записи), getpwuid — обратное преобразование UID в имя, им пользуется ls -l,
получив UID владельца от stat(2). Оба возвращают указатель на статическую структуру:
повторный вызов её перезапишет — классическая ловушка; потокобезопасные версии с
суффиксом _r принимают буфер вызывающего. Перебор: триада setpwent/getpwent/endpwent —
курсор по базе; цикл до NULL. Важная оговорка: это интерфейс к базе, а не к файлу —
через NSS те же вызовы прозрачно обслуживают LDAP/NIS, поэтому правильный способ
прочитать «всех пользователей» — именно getpwent, а не чтение /etc/passwd напрямую.
-->

---

# `struct group`: запись о группе и массив членов

Для `/etc/group` (раздел 2.3) интерфейс симметричен: заголовочный файл
`<grp.h>`, структура `struct group` — четыре поля, как в строке файла.

<div class="grid grid-cols-[1.05fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/grp-struct.h" title="grp.h" tag="glibc 2.43">
  <TCallout :line="5" :col="5" :span="16" :n="2" />
  <TCallout :line="7" :col="5" :span="14" :n="4" />
</CodeSnippet>

</div>
<div>

<FieldRecord size="0.72rem" legendSize="0.6rem" :cols="1"
  :fields="['project', { t: 'x', hot: true }, '1010', 'bob,alice']"
  :legend="[
    'gr_name — имя группы',
    { t: 'gr_passwd — признак пароля группы', hot: true },
    'gr_gid — идентификатор группы (gid_t)',
    'gr_mem — члены группы (вторичное членство)',
  ]"
/>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">4</span> Список членов <code>bob,alice</code> становится
<b>массивом строк</b> <code>gr_mem</code>, завершённым элементом <code>NULL</code> —
готовым для обхода циклом.
</div>

</div>
</div>

<div class="mt-2 text-xs">
<span class="co-ball">2</span> <code>gr_passwd</code> — как и в <code>passwd</code>, признак
<code>x</code>: пароль группы, если задан, лежит в <code>/etc/gshadow</code> (раздел 3.4).
Первичное членство здесь не видно — оно задано полем <code>pw_gid</code> записи пользователя.
</div>

<div class="text-xs opacity-70 mt-2">
glibc 2.43: <a href="https://sourceware.org/git/?p=glibc.git;a=blob;f=nss/grp.h;hb=glibc-2.43#l42">nss/grp.h#l42</a>.
</div>

<Refs ids="man-getgrnam man-group glibc-source" />

<!--
Зеркальная картина для групп. Четыре поля строки /etc/group — четыре поля struct group.
Интересных места два. Первое: gr_mem — не строка с запятыми, а уже разобранный массив
указателей на имена, завершённый NULL; обход — простой цикл for до NULL, что мы и
используем в демо 10. Второе: gr_passwd повторяет судьбу pw_passwd — «x» и перенос
настоящего хеша в gshadow (разделы 3.2 и 3.4). Напоминаю разницу членств (раздел 2.1):
в gr_mem видны только вторичные члены; первичная группа пользователя задана его
записью passwd, и чтобы собрать полный состав группы, нужно просмотреть оба файла.
-->

---

# Чтение групп повторяет интерфейс `passwd`

<div class="grid grid-cols-2 gap-4 mt-1 items-start">
<div>

**Поиск одной записи** — по имени или по GID:

<CodeSnippet src="snippets/grp-lookup.h" title="grp.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getgrnam(3)" /> — запись группы по имени;
- <Man p="getgrgid(3)" /> — по идентификатору GID (так `ls -l`
  подписывает группу-владельца файла);
- те же соглашения: статический буфер, `NULL` — записи нет.

</div>

</div>
<div>

**Перебор всех групп:**

<CodeSnippet src="snippets/grp-enum.h" title="grp.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getgrent(3)" /> — очередная запись `struct group`, `NULL` в конце;
- `setgrent` / `endgrent` — перемотка и закрытие базы;
- потоки `passwd` и `group` независимы: вложенный перебор групп внутри
  перебора пользователей допустим (демо 10).

</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Единообразие интерфейса</b> — приём проектирования libc: пары
<code>get*nam</code>/<code>get*id</code> и триады <code>set*ent</code>/<code>get*ent</code>/<code>end*ent</code>
одинаково устроены для <code>passwd</code>, <code>group</code> и, как увидим далее, <code>shadow</code>.
</div>

<Refs ids="man-getgrnam man-getgrent glibc-source kerrisk-tlpi" />

<!--
Интерфейс групп полностью симметричен: getgrnam/getgrgid — точечный поиск, триада
set/get/endgrent — перебор. Стоит проговорить системность: единые соглашения об
именовании и поведении (статический буфер, NULL как «нет записи»/«конец базы»)
повторяются для всех трёх баз — выучив одну, программист знает все. Деталь, которой
воспользуемся в демо: библиотека держит отдельные курсоры для passwd и group, поэтому
внутри цикла getpwent можно безопасно гонять полный цикл getgrent — именно так демо 10
собирает вторичные группы каждого пользователя.
-->

---

# Демо 10: перебор всех пользователей и групп

<div class="grid grid-cols-[1fr_1.05fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/demo10-main.c" title="10-enum-accounts.c" tag="демо 10" fontSize="0.48rem">
  <TCallout :line="8" :col="5" :span="11" :n="1" />
  <TCallout :line="9" :col="11" :span="25" :n="2" />
  <TCallout :line="15" :col="5" :span="11" :n="3" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/demo10-supp.c" title="10-enum-accounts.c" tag="демо 10" fontSize="0.48rem">
  <TCallout :line="8" :col="11" :span="25" :n="4" />
  <TCallout :line="9" :col="27" :span="10" :n="5" />
</CodeSnippet>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем программу:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1 mt-1">
<div><span class="co-ball">1</span> открыть базу учётных записей</div>
<div><span class="co-ball">4</span> для каждого пользователя — полный проход по группам</div>
<div><span class="co-ball">2</span> цикл до <code>NULL</code>: поля берём из <code>struct passwd</code></div>
<div><span class="co-ball">5</span> поиск имени в массиве членов <code>gr_mem</code></div>
<div><span class="co-ball">3</span> закрыть базу по завершении</div>
</div>
</div>

<div class="grid grid-cols-[1fr_1fr] gap-4 mt-2 items-start">
<TerminalCapture src="captures/10-enum-accounts.txt" section="Сборка и запуск" title="demo 10 · сборка" fontSize="0.5rem" />
<div class="text-xs opacity-70">
Программа целиком — <code>demos/10-enum-accounts.c</code>; сборка обычным
<code>gcc</code>, дополнительных библиотек не требуется. Вторая половина
<code>main</code> — такой же цикл <code>getgrent</code> по группам.
</div>
</div>

<!--
Код демо: слева main — заголовок таблицы, триада setpwent/getpwent/endpwent и печать
полей struct passwd (имя, UID, GID первичной группы, оболочка); справа — функция
вторичных групп: на каждого пользователя полный перебор групп getgrent с поиском имени
в NULL-терминированном массиве gr_mem (двойной цикл: группы, затем члены). Это прямое
применение всех шести функций и обеих структур с двух предыдущих слайдов. Подчеркнуть:
никакого ручного разбора «:» — только API; и независимость курсоров passwd/group,
позволяющая вложенный перебор. Сборка — обычный gcc без внешних библиотек.
-->

---

# Демо 10: сводная таблица пользователей и групп

<div class="grid grid-cols-[1.18fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/10-enum-accounts.txt" section="Пользователи" title="demo 10 · вывод, часть 1: пользователи" fontSize="0.44rem">
  <TCallout :line="1" :col="20" :span="9" :n="1" />
  <TCallout :line="21" :col="49" :span="7" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/10-enum-accounts.txt" section="Группы" title="demo 10 · вывод, часть 2: группы" fontSize="0.44rem">
  <TCallout :line="16" :col="25" :span="9" :n="3" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> UID и GID — числовые поля <code>pw_uid</code>/<code>pw_gid</code></div>
<div><span class="co-ball">2</span> вторичные группы <code>bob</code> собраны из массивов <code>gr_mem</code></div>
<div><span class="co-ball">3</span> и наоборот: члены <code>project</code> — его <code>gr_mem</code></div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> «пользователь → группы» и «группа → члены» — один набор данных,
прочитанный двумя семействами функций.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/10-enum-accounts.sh</code>; срез системных групп сокращён до
показательных строк.
</div>

<!--
Результат демо: слева все 22 записи контейнера Ubuntu 26.04 — от root до наших
bob/carol/alice; хорошо видны диапазоны UID из раздела 4.2 (системные до 1000, люди —
с 1000) и «запрещающая» оболочка nologin у псевдопользователей (раздел 2.2). Колонка
SUPPLEMENTARY — результат перебора групп: у bob — project, у alice — adm и project,
у carol пусто. Справа таблица групп: у project в gr_mem — bob и alice (вторичные
члены), а одноимённые первичные группы пользователей пусты — первичное членство
хранится в passwd, что мы обсуждали в разделе 2.3. Длинные списки ubuntu и середина
таблицы групп сокращены многоточием при курировании захвата.
-->

---
layout: section
---

# 5. Идентификация и парольная аутентификация в приложениях
## Программный интерфейс стандартной библиотеки C

<SectionTOC prefix="5" :current="2" :items="[
  'Чтение учётных записей: passwd и group',
  'Чтение теневого файла shadow',
  'Запрос и проверка пароля: getpass и crypt',
  'Примеры: утилиты login и passwd',
]" />

---

# `struct spwd`: теневая запись с политикой устаревания

Для `/etc/shadow` (раздел 3.2) есть своя структура — `struct spwd` из
`<shadow.h>`: девять полей строки, включая весь блок устаревания пароля.

<div class="grid grid-cols-[1.08fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/spwd-struct.h" title="shadow.h" tag="glibc 2.43" fontSize="0.5rem">
  <TCallout :line="5" :col="5" :span="14" :n="2" />
  <TCallout :line="6" :col="5" :span="19" :rows="4" :n="3" />
</CodeSnippet>

</div>
<div>

<FieldRecord size="0.6rem" legendSize="0.55rem" :cols="1"
  :fields="['bob', { t: '$y$j9T$Vm…', hot: true }, '20755', '0', '99999', '7', '', '', '']"
  :legend="[
    'sp_namp — имя входа',
    { t: 'sp_pwdp — хеш пароля (целиком)', hot: true },
    'sp_lstchg — последняя смена, дней от 01.01.1970',
    'sp_min — минимум дней между сменами',
    'sp_max — максимальный срок действия',
    'sp_warn — за сколько дней предупреждать',
    'sp_inact — дней неактивности (пусто → −1)',
    'sp_expire — день истечения записи (пусто → −1)',
    'sp_flag — зарезервировано',
  ]"
/>

</div>
</div>

<div class="mt-2 text-xs">
<span class="co-ball">2</span> Здесь — настоящий хеш в формате <code>$префикс$соль$хеш</code> (раздел 3.3).
<span class="co-ball">3</span> Поля политики устаревания (раздел 3.4) приходят числами
<code>long int</code>; пустые поля строки libc возвращает как <code>−1</code>.
</div>

<div class="text-xs opacity-70 mt-2">
glibc 2.43: <a href="https://sourceware.org/git/?p=glibc.git;a=blob;f=nss/shadow.h;hb=glibc-2.43#l43">nss/shadow.h#l43</a>.
</div>

<Refs ids="man-getspnam man-shadow glibc-source" />

<!--
Третья структура — spwd, девять полей строки shadow один к одному. Два акцента.
Первый: sp_pwdp — в отличие от pw_passwd это настоящий хеш целиком, со всеми
компонентами формата $y$... из раздела 3.3; именно его программа передаст crypt как
setting. Второй: вся политика устаревания из chage (раздел 3.4) доступна программе
числами — дни от эпохи (sp_lstchg = 20755 — день задания пароля), интервалы min/max,
предупреждение warn; пустые поля (inact, expire) превращаются в −1, что нужно явно
обрабатывать. Таким образом программа может не только проверять пароль, но и сама
реализовывать проверку его срока действия — как это делает login.
-->

---

# `getspnam`: чтение `shadow` требует привилегий

<div class="grid grid-cols-2 gap-4 mt-1 items-start">
<div>

**Поиск одной записи** — только по имени (UID в `shadow` нет):

<CodeSnippet src="snippets/spwd-lookup.h" title="shadow.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getspnam(3)" /> — теневая запись по имени входа;
- `NULL` означает и «записи нет», и «нет доступа»: различать
  следует по `errno == EACCES`.

</div>

**Перебор всех записей:**

<CodeSnippet src="snippets/spwd-enum.h" title="shadow.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- <Man p="getspent(3)" /> / `setspent` / `endspent` — та же триада курсора.

</div>

</div>
<div>

<div class="p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
<b>Главное отличие от <code>passwd</code> и <code>group</code>:</b> файл
<code>/etc/shadow</code> читается только root и группой <code>shadow</code>
(раздел 3.2), поэтому обычному процессу <code>getspnam</code> вернёт
<code>NULL</code> с <code>errno = EACCES</code>. Программа проверки пароля
обязана быть привилегированной — отсюда setuid-бит у <code>passwd(1)</code>
и <code>su(1)</code> (раздел 2.4).
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Семейство <code>getsp*</code> — <b>не POSIX</b>: это расширение, восходящее к
SVR4 и закреплённое в glibc; переносимый код ограждают условной компиляцией.
</div>

<div class="mt-2 text-xs">

Структуру и функции остальных теневых файлов повторяет `<gshadow.h>`
(`struct sgrp`, `getsgnam`) — для `/etc/gshadow`.

</div>

</div>
</div>

<Refs ids="man-getspnam glibc-source kerrisk-tlpi" />

<!--
Интерфейс shadow сохраняет форму (getspnam + триада перебора; поиска по UID нет — в
shadow нет числовых идентификаторов), но меняет условия доступа. Права 640
root:shadow на файле (раздел 3.2) превращаются для программы в EACCES из getspnam;
важно, что NULL здесь двузначен — «нет записи» и «нет прав» различаются только по
errno, его нужно обнулять перед вызовом. Прямое следствие для архитектуры: любая
программа, проверяющая пароли сама, должна работать с привилегиями — вот зачем
setuid-бит на passwd(1) (демо 03) и почему пароль у su спрашивает привилегированный
код. Семейство нестандартное — POSIX его не описывает, но в Linux оно есть со времён
внедрения shadow. Для gshadow есть зеркальный <gshadow.h>.
-->

---
layout: section
---

# 5. Идентификация и парольная аутентификация в приложениях
## Программный интерфейс стандартной библиотеки C

<SectionTOC prefix="5" :current="3" :items="[
  'Чтение учётных записей: passwd и group',
  'Чтение теневого файла shadow',
  'Запрос и проверка пароля: getpass и crypt',
  'Примеры: утилиты login и passwd',
]" />

---

# `getpass` и `crypt`: пароль запрашивают и сравнивают хешами

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-1 items-start">
<div>

**Запрос пароля** — с терминала, без отображения ввода:

<CodeSnippet src="snippets/unistd-getpass.h" title="unistd.h" tag="glibc 2.43" fontSize="0.5rem" />

<div class="mt-2 text-xs">

- печатает приглашение и читает строку с <code>/dev/tty</code>,
  **отключив эхо** терминала;
- возвращает статический буфер — после проверки открытый пароль
  следует стереть (<code>explicit_bzero</code>);
- формально объявлена устаревшей (исключена из POSIX), но в glibc
  сохраняется и остаётся наглядной для учебного кода.

</div>

</div>
<div>

**Проверка** — повторное хеширование, как в демо 05:

<CodeSnippet src="snippets/crypt-proto.h" title="crypt.h" tag="libxcrypt 4.5.1" fontSize="0.5rem">
  <TCallout :line="5" :col="4" :span="40" :n="2" />
  <TCallout :line="13" :col="14" :span="5" :n="1" />
</CodeSnippet>

</div>
</div>

<div class="mt-2 text-xs">
<span class="co-ball">1</span> <code>crypt(фраза, setting)</code>: в качестве
<em>setting</em> передают <b>хранимый хеш целиком</b> — из него берутся алгоритм,
параметры и соль (раздел 3.3). <span class="co-ball">2</span> Контракт функции:
результат равен <em>setting</em> ⇔ фраза совпала с исходным паролем — проверка
сводится к <code>strcmp</code>.
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
В современных дистрибутивах <code>crypt</code> реализует отдельная библиотека
<b>libxcrypt</b> (Ubuntu 26.04 — v4.5.1): все схемы от DES до yescrypt;
подключение — <code>-lcrypt</code>, потокобезопасный вариант — <code>crypt_r</code>.
</div>

<div class="text-xs opacity-70 mt-2">
glibc 2.43: <a href="https://sourceware.org/git/?p=glibc.git;a=blob;f=posix/unistd.h;hb=glibc-2.43#l981">posix/unistd.h#l981</a> ·
libxcrypt v4.5.1: <a href="https://github.com/besser82/libxcrypt/blob/v4.5.1/lib/crypt.h.in#L61">lib/crypt.h.in#L61</a>.
</div>

<Refs ids="man-getpass man-crypt3 libxcrypt-source kerrisk-tlpi" />

<!--
Последние два кирпичика аутентификации. getpass решает житейскую, но важную задачу —
прочитать пароль, не показывая его на экране: открывает /dev/tty, выключает эхо через
termios, читает строку, возвращает эхо назад. Из POSIX функцию исключили (статический
буфер, нет контроля длины), но для понимания механизма она идеальна; в промышленном
коде её заменяют readpassphrase или прямая работа с termios. crypt — та самая
односторонняя функция из раздела 3.3, теперь со стороны программы: передаём открытую
фразу и хранимый хеш как setting; библиотека сама извлекает из него префикс алгоритма,
параметры и соль и повторяет вычисление. Дословный комментарий libxcrypt формулирует
контракт: результат равен setting тогда и только тогда, когда фраза та же — значит,
аутентификация сводится к строковому сравнению. Исторически crypt жила в glibc; ныне
это libxcrypt (-lcrypt), один интерфейс от DES до yescrypt.
-->

---

# Демо 11: программа-аутентификатор на 60 строк

<div class="grid grid-cols-[1fr_1.02fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/demo11-lookup.c" title="11-password-auth.c" tag="демо 11" fontSize="0.48rem">
  <TCallout :line="1" :col="11" :span="17" :n="1" />
  <TCallout :line="8" :col="12" :span="17" :n="2" />
  <TCallout :line="14" :col="9" :span="31" :n="3" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/demo11-verify.c" title="11-password-auth.c" tag="демо 11" fontSize="0.48rem">
  <TCallout :line="1" :col="16" :span="21" :n="4" />
  <TCallout :line="5" :col="17" :span="31" :n="5" />
  <TCallout :line="12" :col="9" :span="33" :n="6" />
</CodeSnippet>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем программу:</b>
<div class="grid grid-cols-2 gap-x-6 gap-y-1 mt-1">
<div><span class="co-ball">1</span> идентификация: имя → запись <code>passwd</code></div>
<div><span class="co-ball">4</span> запрос пароля без эха</div>
<div><span class="co-ball">2</span> теневая запись; <code>EACCES</code> — нет привилегий</div>
<div><span class="co-ball">5</span> хеш ввода по хранимому <em>setting</em></div>
<div><span class="co-ball">3</span> дальше работаем с хешем из <code>shadow</code></div>
<div><span class="co-ball">6</span> аутентификация = сравнение строк</div>
</div>
</div>

<div class="grid grid-cols-[1fr_1fr] gap-4 mt-2 items-start">
<TerminalCapture src="captures/11-password-auth.txt" section="Сборка" title="demo 11 · сборка" fontSize="0.5rem" />
<div class="text-xs opacity-70">
Полный текст — <code>demos/11-password-auth.c</code> (по листингу 8-2 Керриска);
<code>-lcrypt</code> подключает libxcrypt. После сравнения открытый пароль
стирается из памяти (<code>explicit_bzero</code>).
</div>
</div>

<!--
Сборка всего раздела в одну программу — учебный аналог login по листингу 8-2 TLPI.
Слева этап идентификации: getpwnam по argv[1] (нет записи — отказ), затем getspnam;
отличаем отсутствие привилегий (EACCES) и подменяем pw_passwd настоящим хешем
sp_pwdp. Справа аутентификация: getpass запрашивает пароль без эха, crypt хеширует
его с хранимым setting, explicit_bzero немедленно стирает открытый текст (компилятор
не вправе выбросить этот вызов, в отличие от memset), strcmp решает исход. Код
возврата различает три случая: успех, неверный пароль, ошибка окружения. -lcrypt —
потому что crypt давно вынесена из glibc в libxcrypt.
-->

---

# Демо 11: проверка пароля в действии

<div class="grid grid-cols-[1.05fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/11-password-auth.txt" section="Верный и неверный пароль" title="demo 11 · сеанс root" fontSize="0.52rem">
  <TCallout :line="3" :col="1" :span="36" :n="1" />
  <TCallout :line="7" :col="1" :span="13" :n="2" />
  <TCallout :line="10" :col="1" :span="21" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/11-password-auth.txt" section="Без привилегий" title="demo 11 · сеанс bob" fontSize="0.52rem">
  <TCallout :line="4" :col="1" :span="33" :n="4" />
  <TCallout :line="6" :col="1" :span="10" :n="5" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> хеши совпали — подлинность подтверждена</div>
<div><span class="co-ball">2</span> неверный пароль: тот же код, другой хеш</div>
<div><span class="co-ball">3</span> отказ ещё на этапе идентификации</div>
<div><span class="co-ball">4</span> <code>getspnam</code> → <code>EACCES</code>: bob не прочтёт хеши</div>
<div><span class="co-ball">5</span> причина — права <code>640 root:shadow</code></div>
</div>
</div>

</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> проверка пароля — привилегированная операция: она требует чтения
<code>/etc/shadow</code>. Непривилегированным программам тот же результат даёт
только setuid-посредник (<code>su</code>, <code>passwd</code>) — или сервис
аутентификации, к которому мы придём в лекции 3.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/11-password-auth.sh</code>. Пароль примера публичный: <code>Lab-Demo-42!</code>.
</div>

<!--
Прогон демо. Сеанс root: верный пароль bob — хеш ввода совпал с хранимым, UID=1001
получен из записи passwd; неверный — Access denied при том же коде программы; имя,
которого нет, отсекается ещё getpwnam — наглядная граница идентификации и
аутентификации (ГОСТ Р 58833-2020, раздел 1). Сеанс bob: та же программа без
привилегий падает на getspnam с EACCES — ls -l показывает причину, 640 root:shadow.
Вывод замыкает линию раздела: раз хеши защищены, проверить пароль может только
привилегированный код; обычным программам нужен посредник — setuid-утилиты (раздел
2.4) или системный сервис аутентификации, разговор о котором (PAM) начнётся в
лекции 3.
-->

---
layout: section
---

# 5. Идентификация и парольная аутентификация в приложениях
## Программный интерфейс стандартной библиотеки C

<SectionTOC prefix="5" :current="4" :items="[
  'Чтение учётных записей: passwd и group',
  'Чтение теневого файла shadow',
  'Запрос и проверка пароля: getpass и crypt',
  'Примеры: утилиты login и passwd',
]" />

---

# `login`: поиск учётной записи пользователя

Классическая реализация входа — `login` из пакета **shadow** (сборка без PAM):
тот же API, что в демо 11, плюс обработка особых значений поля пароля.

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/login-user-lookup.c" title="src/login.c" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="1" :col="17" :span="27" :n="1" />
  <TCallout :line="6" :col="25" :span="29" :n="2" />
  <TCallout :line="13" :col="25" :rows="2" :span="33" :n="3" />
</CodeSnippet>

</div>
<div>

<div class="text-xs space-y-2">
<div><span class="co-ball">1</span> Введённое имя превращается в запись
<code>struct passwd</code>; <code>xgetpwnam</code> — обёртка shadow над
<Man p="getpwnam(3)" />, копирующая запись из статического буфера. Нет записи —
вход провален (но диалог продолжается, чтобы не раскрывать существование имён).</div>
<div><span class="co-ball">2</span> Из записи берётся поле пароля — пока это
«x» из <code>/etc/passwd</code>.</div>
<div><span class="co-ball">3</span> Особые значения до всякой криптографии:
<code>!</code> — запись заблокирована (<code>passwd -l</code>, раздел 3.4),
<code>*</code> — вход по паролю невозможен; сравнение хешей даже не начнётся.</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Флаг <code>failed</code> выставляется молча: решение «пускать или нет» принимается
<b>после</b> диалога, единообразно для всех причин отказа.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/login.c#L847">src/login.c#L847</a>
(ветвь сборки без PAM).
</div>

<Refs ids="shadow-maint kerrisk-tlpi" />

<!--
От учебной программы — к настоящей. Показана ветвь login без PAM из shadow 4.17.4:
исторически именно так входили в Unix-системы, и эта ветвь жива для систем без PAM.
Последовательность в точности как в демо 11: имя → xgetpwnam (внутренняя обёртка
getpwnam, копирующая запись — у библиотек статический буфер, а login обращается к базе
не раз). Два поучительных приёма вокруг. Первый: отказ не прерывает диалог — login
всё равно спросит пароль, чтобы по поведению нельзя было понять, существует ли имя
(борьба с перечислением пользователей). Второй: до криптографии проверяются
административные значения поля пароля — блокировка «!» (раздел 3.4) и «*»; механизм
блокировки учётной записи реализован именно здесь, в логике приложения.
-->

---

# `login`: от признака «x» к хешу из `shadow`

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/login-shadow-auth.c" title="src/login.c" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="1" :col="17" :span="47" :n="1" />
  <TCallout :line="2" :col="25" :span="28" :n="2" />
  <TCallout :line="4" :col="33" :span="28" :n="3" />
  <TCallout :line="10" :col="17" :span="42" :n="4" />
</CodeSnippet>

</div>
<div>

<div class="text-xs space-y-2">
<div><span class="co-ball">1</span> <code>SHADOW_PASSWD_STRING</code> — то самое
<code>"x"</code>: хеш вынесен в теневой файл.</div>
<div><span class="co-ball">2</span> <code>xgetspnam</code> читает запись
<code>struct spwd</code> — <code>login</code> работает с привилегиями root,
доступ к <code>/etc/shadow</code> у него есть.</div>
<div><span class="co-ball">3</span> Дальше сверяться будем с настоящим хешем
<code>sp_pwdp</code> — ровно как подмена <code>pw_passwd</code> в демо 11.</div>
<div><span class="co-ball">4</span> Вся криптография спрятана в одном вызове
<code>pw_auth</code>: вернул 0 — подлинность подтверждена; иначе — журнал
и общий флаг отказа.</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
Неудача фиксируется в системном журнале (<code>SYSLOG</code>) — попытки подбора
пароля оставляют след; к журналированию мы вернёмся в лекции об аудите.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/login.c#L879">src/login.c#L879</a>.
</div>

<Refs ids="shadow-maint" />

<!--
Второй фрагмент login.c: переход от passwd к shadow, дословно повторяющий демо 11,
но с production-деталями. Если в поле пароля «x» (константа SHADOW_PASSWD_STRING) —
читаем теневую запись xgetspnam и далее работаем с sp_pwdp; login запущен с
привилегиями root, так что EACCES ему не грозит — ещё одна иллюстрация тезиса
«проверка пароля привилегированна». Отсутствие теневой записи при «x» в passwd — само
по себе аномалия, и она уходит в журнал. Сам акт проверки инкапсулирован в pw_auth:
нулевой результат — успех; ненулевой — запись в syslog о неверном пароле (след для
аудита и fail2ban-подобных средств) и установка общего флага failed.
-->

---

# `pw_auth`: `getpass` → `crypt` → сравнение

<div class="grid grid-cols-[1.12fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/pwauth-pw_auth.c" title="lib/pwauth.c" tag="shadow 4.17.4" fontSize="0.48rem">
  <TCallout :line="2" :col="1" :span="45" :n="1" />
  <TCallout :line="10" :col="9" :span="25" :n="2" />
  <TCallout :line="13" :col="9" :span="39" :n="3" />
  <TCallout :line="15" :col="17" :span="36" :n="4" />
  <TCallout :line="20" :col="9" :span="18" :n="5" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/encrypt-pw_encrypt.c" title="lib/encrypt.c" tag="shadow 4.17.4" fontSize="0.48rem">
  <TCallout :line="6" :col="9" :span="25" :n="6" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> на вход — хеш (<code>cipher</code>) и имя</div>
<div><span class="co-ball">2</span> запрос пароля (<code>agetpass</code> —
безопасная версия <Man p="getpass(3)" />)</div>
<div><span class="co-ball">3</span> хеширование ввода по хранимому хешу…</div>
<div><span class="co-ball">6</span> …внутри — тот самый <Man p="crypt(3)" /></div>
<div><span class="co-ball">4</span> аутентификация — <code>strcmp</code></div>
<div><span class="co-ball">5</span> открытый пароль стирается из памяти</div>
</div>

</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> от демо на 60 строк до системного <code>login</code> —
один алгоритм: <code>getpwnam → getspnam → getpass → crypt → strcmp</code>.
В Ubuntu 26.04 штатный <code>/usr/bin/login</code> (util-linux) и сборка shadow
с PAM делегируют этот шаг модулям PAM — устройство этого механизма разбирается в лекции 3.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/lib/pwauth.c#L115">lib/pwauth.c#L115</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/lib/encrypt.c#L26">lib/encrypt.c#L26</a>.
</div>

<Refs ids="shadow-maint man-crypt3 util-linux-login" />

<!--
Финальный фрагмент — сердце проверки, функция pw_auth из библиотеки shadow (комментарий
в её заголовке так и гласит: perform getpass/crypt authentication). Пустой хеш — вход
без пароля (поведение связки с nullok мы видели в демо 06); agetpass — внутренняя
безопасная версия getpass (выделяет защищённый буфер, контролирует длину);
pw_encrypt — тонкая обёртка crypt (справа), добавляющая диагностику неподдерживаемых
алгоритмов; strcmp решает исход; erase_pass гарантированно стирает открытый пароль.
Алгоритм тот же, что в нашем демо, — различия только в аккуратности обращения с
памятью и диагностике. Замыкание на современность: в Ubuntu 26.04 /usr/bin/login
собран из util-linux и аутентифицирует через pam_authenticate, и сборка shadow с
USE_PAM делает то же — классический путь, который мы разобрали, стал содержимым
модуля pam_unix. Что такое PAM и как устроены его модули — тема лекции 3.
-->

---

# `passwd`: полномочия задаёт реальный UID

Второй пример — setuid-утилита `passwd` (пакет **shadow**): euid = 0 открывает ей
`/etc/shadow` (раздел 2.4), а «кто вызвал и что ему можно» решает **реальный UID**.

<div class="grid grid-cols-[1.12fr_1fr] gap-4 mt-2 items-start">
<div>

<CodeSnippet src="snippets/passwd-target.c" title="src/passwd.c · main" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="1" :col="9" :span="26" :n="1" />
  <TCallout :line="3" :col="9" :span="21" :n="2" />
  <TCallout :line="17" :col="9" :span="44" :n="3" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/myname-get_my_pwent.c" title="lib/myname.c" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="5" :col="9" :span="23" :n="4" />
  <TCallout :line="13" :col="9" :span="24" :n="5" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> «я root» — это <b>реальный</b> UID 0:
euid из-за setuid-бита всегда 0</div>
<div><span class="co-ball">2</span> своя запись — через <code>get_my_pwent</code>;
имя из аргумента берётся лишь как явная цель</div>
<div><span class="co-ball">4</span> имя от <code>getlogin()</code> принимается,
только если его запись сверилась с ruid; <span class="co-ball">5</span> иначе —
прямо <code>getpwuid(getuid())</code></div>
<div><span class="co-ball">3</span> не-root может работать <b>только со своей</b>
записью: <code>pw_uid</code> цели сравнивается с реальным UID</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L904">src/passwd.c#L904</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/lib/myname.c#L25">lib/myname.c#L25</a>.
</div>

<Refs ids="shadow-maint man-passwd1" />

<!--
Второй пример построен на другой стороне той же механики. login запускается от root и
понижает привилегии; passwd — наоборот, запускается обычным пользователем, а привилегии
получает через setuid-бит (демо 03). Отсюда главный вопрос утилиты — не «есть ли у меня
права» (есть: euid = 0), а «кто меня запустил и на что он уполномочен». Ответ даёт
реальный UID, который setuid-бит не меняет (раздел 2.4): amroot — это getuid() == 0,
а не geteuid(); собственная запись ищется get_my_pwent — getlogin() с контрольной
сверкой pw_uid == ruid (одно имя может делить UID), иначе прямое getpwuid(getuid()).
Финальная проверка полномочий симметрична: если цель — чужая запись (pw_uid != getuid())
и вызвавший не root, утилита завершается. Это образцовая дисциплина для любой
setuid-программы: полномочия выводятся из ruid, а euid используется лишь как ключ к
файлам.
-->

---

# `passwd -S` и `-l`: статус пароля и блокировка

<div class="grid grid-cols-[1.08fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/passwd-print_status.c" title="src/passwd.c · print_status" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="7" :col="9" :span="35" :n="1" />
  <TCallout :line="11" :col="32" :span="23" :n="2" />
</CodeSnippet>

<CodeSnippet class="mt-2" src="snippets/passwd-lock.c" title="src/passwd.c · update_crypt_pw" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="3" :col="9" :span="25" :n="4" />
  <TCallout :line="6" :col="17" :span="29" :n="5" />
</CodeSnippet>

</div>
<div>

<CodeSnippet src="snippets/passwd-pw_status.c" title="src/passwd.c · pw_status" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="3" :col="9" :span="35" :n="3" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> <code>-S</code> — это просто чтение
<code>struct spwd</code> (раздел 5.2) и печать его полей: статус, дата смены,
min/max/warn/inact — формат из демо 06;</div>
<div><span class="co-ball">2</span> <span class="co-ball">3</span> буква статуса
выводится из первого символа хеша: <code>!</code>/<code>*</code> → <code>L</code>,
пустое поле → <code>NP</code>, иначе <code>P</code>;</div>
<div><span class="co-ball">4</span> <span class="co-ball">5</span> блокировка
<code>-l</code> — <b>не криптография</b>: к хешу спереди дописывается
<code>!</code>, и он перестаёт быть корректным хешем.</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Круг замкнулся: именно этот <code>!</code> проверяет <code>login</code>
(<code>'!' == user_passwd[0]</code>) и показывало демо 06 (раздел 3.4);
разблокировка <code>-u</code> просто убирает первый символ.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L453">src/passwd.c#L453</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L439">#L439</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L534">#L534</a>.
</div>

<Refs ids="shadow-maint man-passwd1" />

<!--
Две «нечисловые» операции passwd, обе — прямая работа со строкой хеша. Первая: -S
(статус) — никакой магии, print_status читает теневую запись и печатает поля struct
spwd в одну строку; именно этот вывод мы разбирали в демо 06. Буква статуса — функция
pw_status от одного-единственного аргумента, строки хеша: первый символ '!' или '*'
значит L (заблокирован), пустая строка — NP (пароля нет), всё остальное — P. Вторая:
блокировка -l в update_crypt_pw — к хешу спереди дописывается '!' (xasprintf "!%s"),
после чего строка гарантированно не совпадёт ни с одним результатом crypt: сам хеш
сохранён, но недействителен. Разблокировка -u зеркальна — срезает первый символ (с
защитой: «!» без остатка снимать нельзя, получилась бы запись без пароля). Связать с
проверкой '!' в login и с демо 06 — студент видит один и тот же байт с трёх сторон:
утилита пишет, файл хранит, login проверяет.
-->

---

# `passwd`: смена пароля и новый хеш

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-1 items-start">
<div>

<CodeSnippet src="snippets/passwd-old-verify.c" title="src/passwd.c · new_password" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="3" :col="9" :span="43" :n="1" />
  <TCallout :line="4" :col="17" :span="39" :n="2" />
  <TCallout :line="6" :col="17" :span="42" :n="3" />
  <TCallout :line="10" :col="25" :span="17" :n="4" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">1</span> старый пароль спрашивают только у <b>не-root</b>:
администратору достаточно полномочий ruid = 0</div>
<div><span class="co-ball">2</span> <span class="co-ball">3</span> проверка старого
пароля — знакомое повторное хеширование по хранимому хешу</div>
<div><span class="co-ball">4</span> <code>sleep(1)</code> при неверном пароле —
торможение перебора</div>
</div>

</div>
<div>

<CodeSnippet src="snippets/passwd-new-hash.c" title="src/passwd.c · new_password" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="4" :col="9" :span="36" :n="5" />
  <TCallout :line="5" :col="9" :span="29" :n="6" />
</CodeSnippet>

<CodeSnippet class="mt-2" src="snippets/passwd-update_shadow.c" title="src/passwd.c · update_shadow" tag="shadow 4.17.4" fontSize="0.5rem">
  <TCallout :line="7" :col="9" :span="46" :n="7" />
  <TCallout :line="10" :col="25" :span="34" :n="8" />
</CodeSnippet>

<div class="mt-2 text-xs space-y-1">
<div><span class="co-ball">5</span> <span class="co-ball">6</span> соль — <b>заново</b>,
по <code>ENCRYPT_METHOD</code> из <code>login.defs</code> (раздел 3.3)</div>
<div><span class="co-ball">7</span> новый хеш записывается в поле
<code>sp_pwdp</code> копии теневой записи; <span class="co-ball">8</span> дата смены
<code>sp_lstchg</code> — «сегодня» в днях от эпохи (раздел 3.4)</div>
</div>

</div>
</div>

<v-click>

<div class="mt-1 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Итог раздела:</b> демо 11, <code>login</code> и <code>passwd</code> собраны из одних
вызовов <code>getpw*</code>/<code>getsp*</code>, <code>getpass</code>, <code>crypt</code>:
чтение — сравнение хешей, запись — новая соль и отметка времени, полномочия — реальный UID.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
shadow 4.17.4: <a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L197">src/passwd.c#L197</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L356">#L356</a> ·
<a href="https://github.com/shadow-maint/shadow/blob/4.17.4/src/passwd.c#L642">#L642</a>.
</div>

<Refs ids="shadow-maint man-passwd1 man-crypt3" />

<!--
Смена пароля в new_password — две фазы. Фаза проверки: не-root обязан подтвердить
знание старого пароля — agetpass, pw_encrypt по хранимому хешу (crypt_passwd загружен
из sp_pwdp ранее в main), сравнение строк; root фазу пропускает — его полномочия уже
установлены по ruid. Деталь обороны: при несовпадении — sleep(1), секунда задержки
обесценивает онлайн-перебор. Фаза записи: для нового пароля соль генерируется заново
(crypt_make_salt читает ENCRYPT_METHOD и параметры из login.defs — раздел 3.3), новый
хеш кладётся в crypt_passwd, затем update_shadow дублирует теневую запись, подменяет
sp_pwdp (через тот же update_crypt_pw, что обслуживает -l/-u/-d) и ставит sp_lstchg =
сегодня (gettime()/DAY) — от этой отметки отсчитывается вся политика устаревания
chage. Поучительно, что смена пароля не «обновляет» старый хеш, а строит независимый
новый: прежняя соль нужна только для проверки старого пароля. Итоговый слайд раздела:
один API — три программы; чтение = сравнение хешей, запись = новая соль + отметка
времени, полномочия = реальный UID.
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="1" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

<!--
Разделы 2–5 построили картину «одна машина — свои файлы»: учётные записи в /etc/passwd,
группы в /etc/group, и даже программный интерфейс (раздел 5) мы читали как обёртку над
этими файлами. Последний раздел лекции снимает это упрощение: в действительности вызовы
getpwnam и getaddrinfo идут через подсистему Name Service Switch, которая выбирает
источник данных по конфигурации — локальные файлы, DNS или централизованный каталог
предприятия. План: зачем понадобился такой диспетчер; его архитектура; конфигурация
nsswitch.conf с кодами состояния и действиями; связка с SSSD и каталогами LDAP/AD/IPA;
цена вопроса — производительность и кеши; и границы доверия — безопасность.
-->

---

# Локальные файлы не масштабируются на парк машин

До сих пор источником сведений об учётных записях и именах были **локальные файлы**
— у каждой машины свои:

<div class="t-table text-xs mt-2">

| Файл | Содержимое |
|---|---|
| `/etc/passwd`, `/etc/group` | учётные записи, группы, членство (разделы 2.2–2.3) |
| `/etc/shadow` | хеши паролей и политика устаревания (раздел 3) |
| `/etc/hosts` | соответствие «имя узла → IP-адрес» |
| `/etc/services`, `/etc/protocols` | имена сетевых служб и протоколов |

</div>

<div class="mt-2">

Для отдельной машины схема работает. В организации с сотнями узлов она рушится:

- каждого нового сотрудника пришлось бы **вручную прописывать на всех машинах** — копировать `/etc/passwd`, `/etc/shadow`, `/etc/group` и поддерживать копии согласованными;
- копии неизбежно **расходятся**: на одной машине имя `dave` получает UID 5000, на другой — 5001, и права на общих файловых ресурсах (NFS) указывают не на того субъекта;
- увольнение требует удаления записи **везде и сразу** — забытая копия остаётся действующим входом.

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Вывод из практики:</b> нужен <b>централизованный источник</b> сведений об учётных
записях — одна база на организацию, которую машины опрашивают по сети.
</div>

<Refs ids="man-passwd man-group man-shadow glibc-manual-nss" />

<!--
Постановка проблемы. Всё, что мы изучили, предполагало локальные файлы — и для одной
машины это честная, простая схема. Но представим 500 серверов: завести пользователя —
значит разослать и согласовать три файла на 500 машинах. Главная техническая беда даже
не трудоёмкость, а рассинхронизация идентификаторов: UID — это то, что ядро пишет в
метки владения файлами (раздел 2.1), и если dave на двух машинах имеет разные UID, то
на общем NFS-томе его файлы принадлежат «кому-то другому». Обратная задача — оперативно
отключить уволенного — тоже требует атомарности, которой у ручного копирования нет.
Ответ индустрии — централизованные базы: сначала NIS от Sun, затем LDAP-каталоги.
Но остаётся вторая половина проблемы — следующий слайд.
-->

---

# Вторая половина проблемы: приложения привязаны к файлам

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-start">
<div>

Централизованная база решает вопрос **хранения**, но не вопрос **доступа**: тысячи программ получают сведения через стандартные вызовы libc, разобранные в разделе 5 — <Man p="getpwnam(3)" />, <Man p="getgrnam(3)" />, <Man p="getaddrinfo(3)" />…

Если бы переход на сетевой каталог требовал менять приложения, пришлось бы:

- **переписать** каждую программу под протокол каталога (NIS, LDAP, …) — и повторять это при смене каталога;
- **перекомпилировать и перевыпустить** всё: `login`, `sshd`, `ls`, `id`, собственное ПО организации;
- смириться с тем, что старые бинарные файлы продолжают читать локальные файлы — две картины мира на одной машине.

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Требование к решению:</b> источник данных должен меняться <b>конфигурацией, а не
кодом</b> — без правки и пересборки приложений.
</div>

<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs mt-3">
<b>Точка опоры уже есть:</b> приложения и так не читают файлы напрямую, а вызывают
функции libc (раздел 5). Значит, менять источник можно <b>внутри библиотеки</b> —
интерфейс вызовов останется прежним.
</div>

</div>
</div>

<Refs ids="man-getpwnam man-getgrnam man-getaddrinfo glibc-manual-nss" />

<!--
Хранение — лишь половина задачи. Интерфейс доступа к учётным данным зафиксирован
десятилетиями: getpwnam, getgrnam, getaddrinfo и их родственники из раздела 5. Менять
этот контракт — значит трогать каждую программу: от системных утилит до прикладного ПО,
исходников которого может уже не быть. Это трудоёмко и рискованно: ошибка в переписанном
login стоит дорого. Ключевое наблюдение — приложения уже изолированы от файлов
библиотечным интерфейсом: getpwnam обещает вернуть struct passwd, но нигде не обещает,
что прочитает именно /etc/passwd. Значит, подмену источника можно выполнить в одном
месте — внутри libc, сохранив интерфейс. Именно это и делает NSS.
-->

---

# NSS: источник данных выбирает конфигурация, а не код

**Name Service Switch (NSS)** — подсистема библиотеки C, которая направляет запросы стандартных функций (<Man p="getpwnam(3)" />, <Man p="getgrnam(3)" />, <Man p="getaddrinfo(3)" />, …) настраиваемым **источникам данных**: локальным файлам, DNS, сетевым каталогам.

<Timeline height="10.5em" class="mt-3" :items="[
  { year: '1985', head: 'NIS (Sun)', text: 'первая массовая сетевая база учётных записей («Yellow Pages»)' },
  { year: '1992', head: 'Solaris 2', text: 'nsswitch.conf: единая точка выбора источника для всех баз', hot: true },
  { year: '1997', head: 'glibc 2.0', text: 'схема Solaris перенесена в GNU libc — NSS приходит в Linux' },
  { year: '2009', head: 'SSSD', text: 'демон-посредник к LDAP, Active Directory и FreeIPA с кешем' },
]" />

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Идея:</b> вызов <code>getpwnam("dave")</code> не обязан читать
<code>/etc/passwd</code> — диспетчер в glibc перебирает перечисленные в конфигурации
источники, и ответ может прийти из каталога организации.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<b>Обратная совместимость:</b> локальные файлы остаются одним из источников,
интерфейс функций не меняется — существующие программы работают без пересборки,
ничего «не зная» о каталогах.
</div>
</div>

<Refs ids="glibc-manual-nss man-nsswitch sssd-docs" />

<!--
Решение пришло из Solaris. Sun, автор NIS, столкнулась с зоопарком источников раньше
всех — и в Solaris 2 (1992) ввела nsswitch.conf: одна строка конфигурации на каждую
базу данных, перечисляющая источники по порядку. Схему перенял Ульрих Дреппер с
коллегами в GNU libc 2.0 (1997) — с тех пор NSS есть в каждом дистрибутиве Linux
(руководство glibc прямо называет Solaris 2 образцом). До NSS порядок поиска имён в
Linux задавался ad-hoc файлами вроде /etc/host.conf и перекомпиляцией libc с поддержкой
NIS. Обе цели из постановки задачи достигнуты: источник задаётся конфигурацией, а не
кодом; старые программы работают как раньше, потому что files — лишь один из источников,
а интерфейс getpwnam неизменен. SSSD (2009, проект Red Hat/FreeIPA) — современное
звено той же цепочки: модуль NSS + демон с кешем, скрывающий детали LDAP/AD/IPA
(раздел 6.4).
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="2" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

---

# Три уровня: приложение, диспетчер glibc, модули-источники

<div class="nss-arch mt-1">
  <div class="na-row">
    <div class="bf-block bf-fill-tint na-wide">
      <div class="bf-head">Приложения</div>
      <div class="bf-sub">login · sshd · ls · id · ваша программа — обычные вызовы getpwnam(3), getgrnam(3), getaddrinfo(3)</div>
    </div>
  </div>
  <div class="na-link"><div class="na-arrow"></div><div class="na-label">вызов функции libc — интерфейс раздела 5, без изменений</div></div>
  <div class="na-row">
    <div class="bf-block bf-fill-dark na-wide">
      <div class="bf-head">Диспетчер NSS в glibc</div>
      <div class="bf-sub">читает /etc/nsswitch.conf: какую базу — в каком порядке — у каких источников спрашивать</div>
    </div>
  </div>
  <div class="na-link"><div class="na-arrow"></div><div class="na-label">вызов функции модуля: _nss_&lt;источник&gt;_&lt;функция&gt;()</div></div>
  <div class="na-row na-mods">
    <div class="bf-block bf-fill-accent"><div class="bf-head bf-mono">files</div><div class="bf-sub">/etc/passwd · /etc/hosts и другие файлы</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">dns</div><div class="bf-sub">резолвер DNS (resolv.conf)</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">sss</div><div class="bf-sub">демон SSSD → LDAP, AD, FreeIPA</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">winbind</div><div class="bf-sub">Samba: домены Windows</div></div>
    <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">…</div><div class="bf-sub">resolve, compat, myhostname</div></div>
  </div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Вся схема работает <b>в пользовательском пространстве</b>: диспетчер — код glibc внутри
процесса-приложения, модули — разделяемые библиотеки. Ядро в выборе источника не участвует
(сравните с проверкой прав доступа — раздел 2.5).
</div>

<Refs ids="glibc-manual-nss man-nsswitch" />

<style>
.nss-arch { display: flex; flex-direction: column; font-size: 0.78rem; text-align: center; }
.nss-arch .na-row { display: flex; gap: 0.6em; justify-content: center; }
.nss-arch .na-wide { flex: 0 1 34em; }
.nss-arch .na-mods .bf-block { flex: 1 1 0; }
.nss-arch .na-link { display: flex; align-items: center; justify-content: center; gap: 0.7em; height: 1.6em; }
.nss-arch .na-arrow { width: 2px; height: 1.3em; background: #555; position: relative; }
.nss-arch .na-arrow::after { content: ''; position: absolute; bottom: -4px; left: -3px; border: 4px solid transparent; border-top-color: #555; }
.nss-arch .na-label { font-size: 0.68rem; color: #555; font-style: italic; }
</style>

<!--
Архитектура в один кадр: три уровня. Верхний — обычные приложения с теми же вызовами
libc, что мы разбирали в разделе 5; они не меняются. Средний — диспетчер NSS внутри
glibc: по имени базы данных (passwd, hosts, …) он находит в /etc/nsswitch.conf список
источников и опрашивает их по порядку. Нижний — модули-источники: files читает
классические файлы, dns ходит к серверам DNS, sss — к демону SSSD, за которым каталог
организации, winbind — к Samba. Важная оговорка: всё это — пользовательское
пространство, код внутри самого процесса; ядро предоставляет лишь обычные системные
вызовы (открыть файл, отправить пакет). Поэтому NSS — механизм КАЖДОГО процесса:
и у ls, и у sshd с euid 0 — свои копии той же логики. К последствиям для безопасности
вернёмся в разделе 6.6.
-->

---

# Модуль NSS — разделяемая библиотека с оговорённым именем

<div class="grid grid-cols-[1fr_1.1fr] gap-4 items-start">
<div>

Соглашение связывает **имя источника** в конфигурации с библиотекой и её функциями:

- источник `sss` → библиотека `libnss_sss.so.2`;
- поиск в базе `passwd` по имени → функция `_nss_sss_getpwnam_r()`;
- glibc загружает модуль динамически (<Man p="dlopen(3)" />) при первом обращении.

Модули приносятся пакетами: `files`, `dns`, `compat` — в составе `libc6`; `sss`, `resolve`, `winbind` — пакетами `libnss-sss`, `libnss-resolve`, `libnss-winbind`.

</div>
<div>

<TerminalCapture src="captures/12-nss-hosts.txt" section="Модули NSS" title="Ubuntu 26.04 · модули NSS" fontSize="0.47rem">
  <TCallout :line="6" :col="1" :span="15" :n="1" />
  <TCallout :line="9" :col="1" :span="16" :n="2" />
  <TCallout :line="13" :col="63" :span="19" :n="3" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> источнику <code>sss</code> соответствует <code>libnss_sss.so.2</code></div>
<div><span class="co-ball">2</span> модуль установлен пакетом <code>libnss-sss</code></div>
<div><span class="co-ball">3</span> экспортируемая функция поиска в базе <code>passwd</code></div>
</div>
</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs mt-2">
С glibc 2.34 модули <code>files</code> и <code>dns</code> скомпонованы
<b>внутрь самой libc</b> (быстрее и работает со статической сборкой);
файлы <code>libnss_files.so.2</code> и <code>libnss_dns.so.2</code> сохранены
для совместимости.
</div>

</div>
</div>

<Refs ids="glibc-manual-nss man-nsswitch sssd-docs" />

<!--
Механика уровня модулей. Всё держится на соглашении об именах: встретив в конфигурации
источник sss, glibc берёт libnss_sss.so.2 и ищет в ней _nss_sss_getpwnam_r — имя
склеивается из источника и запрошенной операции (суффикс _r — реентерабельный вариант,
раздел 5.1). В транскрипте: пять модулей стандартного пути Ubuntu 26.04
(/usr/lib/x86_64-linux-gnu); dpkg -S показывает, что sss принесён пакетом libnss-sss;
objdump -T подтверждает экспорт функций поиска. Расширяемость очевидна: новый источник —
это просто новая библиотека с правильными именами, ни glibc, ни приложения менять не
нужно. Оговорка про glibc 2.34: files и dns теперь живут внутри libc (ускорение и
поддержка статической линковки), но файлы-заглушки оставлены — и соглашение для
сторонних модулей неизменно. Какие источники опрашивать — решает /etc/nsswitch.conf,
к нему и переходим.
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="3" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

---

# `/etc/nsswitch.conf`: каждой базе — свой список источников

<div class="grid grid-cols-[1fr_1.05fr] gap-4 items-start">
<div>

Формат — по строке на **базу данных**:

<div class="p-2 bg-gray-100 rounded text-sm font-mono mt-1">
база: источник [действие] источник …
</div>

- источники опрашиваются **слева направо**, пока один из них не даст ответ (точные правила — далее);
- необязательные **действия** в квадратных скобках меняют порядок обхода;
- строка действует на **все** программы: и на `ls`, и на `sshd`, и на `getent`.

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs mt-2">
С glibc 2.33 изменения файла подхватываются работающими процессами
<b>автоматически</b>; раньше конфигурация читалась один раз на процесс.
</div>

</div>
<div>

<TerminalCapture src="captures/12-nss-hosts.txt" section="Конфигурация по умолчанию" title="Ubuntu Server 26.04 · умолчания" fontSize="0.5rem">
  <TCallout :line="3" :col="1" :span="6" :n="1" />
  <TCallout :line="3" :col="17" :span="5" :n="2" />
  <TCallout :line="8" :col="17" :span="9" :n="3" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> база данных (<code>passwd</code> — учётные записи)</div>
<div><span class="co-ball">2</span> единственный источник — локальные файлы</div>
<div><span class="co-ball">3</span> узлы: сначала <code>/etc/hosts</code>, затем DNS</div>
</div>
</div>

</div>
</div>

<Refs ids="man-nsswitch glibc-manual-nss" />

<!--
Центральная конфигурация. Синтаксис минимален: имя базы, двоеточие, упорядоченный
список источников, между которыми могут стоять действия в квадратных скобках. Справа —
файл чистой Ubuntu Server 26.04 (комментарии опущены): учётные базы passwd/group/shadow
читаются только из файлов — ровно та картина, которую мы строили в разделах 2–3; и лишь
hosts уже по умолчанию объединяет два источника — файл и DNS. Источник db — это
предсобранные makedb-базы (/var/lib/misc), ускоряющие поиск в больших services/protocols;
netgroup: nis — исторический след NIS. Существенно, что файл один на систему и действует
на каждый процесс. И деталь, важная для администрирования: с glibc 2.33 файл
перечитывается автоматически — правка вступает в силу без перезапуска служб (но кеши
самих источников никто не сбрасывает — раздел 6.5).
-->

---

# Базы данных NSS и типовые источники

<div class="grid grid-cols-2 gap-4 items-start mt-1">
<div>

**Базы данных** (что спрашивают):

<div class="t-table text-xs mt-1">

| База | Содержимое · интерфейс |
|---|---|
| `passwd` | учётные записи · <Man p="getpwnam(3)" /> |
| `group` | группы и членство · <Man p="getgrnam(3)" /> |
| `shadow` | теневые записи · <Man p="getspnam(3)" /> |
| `initgroups` | вторичные группы · <Man p="getgrouplist(3)" /> |
| `hosts` | имена узлов · <Man p="getaddrinfo(3)" /> |
| `services` | службы и порты · <Man p="getservbyname(3)" /> |
| `netgroup` | сетевые группы · <Man p="innetgr(3)" /> |

</div>

</div>
<div>

**Источники** (кто отвечает):

<div class="t-table text-xs mt-1">

| Источник | Назначение |
|---|---|
| `files` | классические локальные файлы |
| `dns` | резолвер DNS из libc (<Man p="resolv.conf(5)" />) |
| `resolve` | служба systemd-resolved |
| `sss` | SSSD: LDAP, AD, FreeIPA (раздел 6.4) |
| `winbind` | Samba, домены Windows |
| `myhostname` | имя локального узла, `localhost` |
| `compat` | `files` + NIS-совместимый синтаксис `+/-` |
| `db` | предсобранные базы <Man p="makedb(1)" href="https://manpages.ubuntu.com/manpages/noble/man1/makedb.1.html" /> |

</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Не каждый источник обслуживает каждую базу: <code>dns</code> отвечает только за
<code>hosts</code>, <code>sss</code> не хранит <code>services</code>. Источник
работает, лишь когда его модуль установлен — строка в конфигурации сама по себе
ничего не загружает.
</div>

<Refs ids="man-nsswitch glibc-manual-nss nss-resolve sssd-docs" />

<!--
Словарь конфигурации с двух сторон. Слева — базы данных: все знакомые по разделу 5
интерфейсы на месте (passwd/group/shadow), плюс initgroups — отдельная база для
вычисления вторичных групп при входе (именно её использует getgrouplist, и её политика
может отличаться от group!), hosts/services/netgroup — сетевой мир. Справа — источники:
files и dns очевидны; resolve — адаптер к systemd-resolved (на Ubuntu resolved по
умолчанию подключён иначе — через заглушку 127.0.0.53 в resolv.conf, так что строки
resolve в умолчаниях нет); sss и winbind — мосты к каталогам; myhostname гарантирует
разрешение собственного имени узла; compat сохраняет синтаксис +@группа эпохи NIS.
Две оговорки внизу важны на практике: пары «база-источник» поддерживаются не все, и
модуль должен быть установлен — опечатка или отсутствующий пакет превращают источник
в молчаливо пропускаемый (статус UNAVAIL — следующий слайд).
-->

---

# Поиск — конечный автомат: статус ответа решает, продолжать ли

Опрос источников — не простой перебор: каждый источник возвращает **код состояния**,
и для каждого кода определено **действие по умолчанию**.

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-start mt-2">
<div>

<div class="t-table text-xs">

| Код состояния | Смысл | По умолчанию |
|---|---|---|
| `SUCCESS` | запись найдена | **return** — вернуть ответ |
| `NOTFOUND` | источник работает, записи **нет** | continue — следующий источник |
| `UNAVAIL` | источник **недоступен** или не поддерживает базу | continue |
| `TRYAGAIN` | временный сбой (занято, нет ресурсов) | continue |

</div>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>NOTFOUND ≠ UNAVAIL.</b> «Записи нет» — <b>авторитетный отрицательный ответ</b>
работающего источника; «источник недоступен» — отсутствие ответа вообще. Умолчания
их не различают (оба продолжают поиск), но действия из следующего слайда — различают,
и для безопасности это различие ключевое (раздел 6.6).
</div>

</div>
</div>

Проход `hosts: files dns` для имени, которого нет в `/etc/hosts`:

<BlockFlow size="0.8rem" class="mt-2" :blocks="[
  { head: 'getaddrinfo()', sub: 'запрос имени' },
  { head: 'files', mono: true, sub: '/etc/hosts:\nNOTFOUND', fill: 'dark' },
  { head: 'dns', mono: true, sub: 'серверы DNS:\nSUCCESS', fill: 'dark' },
  { head: 'ответ приложению', sub: 'адреса узла', fill: 'green' },
]" :arrows="['база hosts', 'continue', 'return']" />

<Refs ids="man-nsswitch glibc-manual-nss" />

<!--
Ядро семантики NSS. Источник отвечает одним из четырёх кодов, и по коду диспетчер
решает: вернуть результат или спросить следующего. Умолчания естественны: нашли —
отдаём (SUCCESS=return), во всех остальных случаях пробуем дальше. Схема внизу
прослеживает типовой путь: имени нет в /etc/hosts — files честно отвечает NOTFOUND,
поиск продолжается в DNS, там SUCCESS — и ответ уходит приложению; если бы и DNS
ответил NOTFOUND, приложение получило бы ошибку (для getaddrinfo — EAI_NONAME).
Акцент слайда — различие NOTFOUND и UNAVAIL: первое — «я работаю, и такой записи нет»,
второе — «я не смог ответить» (нет модуля, не открылся файл, недоступен демон).
Умолчания оба случая гонят дальше по списку, но хорошая политика должна их различать:
авторитетное «нет» и отказ инфраструктуры — разные события и с точки зрения
корректности, и с точки зрения безопасности. Инструменты управления — действия —
на следующем слайде, а сначала посмотрим на умолчания в деле.
-->

---

# Демо 12: три исхода поиска имени узла

Инструмент — <Man p="getent(1)" />: запрос к базе NSS тем же путём, что у приложений
(`getent hosts` = <Man p="getaddrinfo(3)" />); ключ `-s` ограничивает поиск одним источником.

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/12-nss-hosts.txt" section="Имя есть в /etc/hosts" title="demo 12 · имя в /etc/hosts" fontSize="0.5rem">
  <TCallout :line="6" :col="1" :span="37" :n="1" />
</TerminalCapture>

<TerminalCapture class="mt-3" src="captures/12-nss-hosts.txt" section="Имени нет нигде" title="demo 12 · имени нет нигде" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="1" :n="4" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/12-nss-hosts.txt" section="Имя только в DNS" title="demo 12 · имя только в DNS" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="1" :n="2" />
  <TCallout :line="5" :col="1" :span="21" :n="3" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> <code>files</code> нашёл запись — DNS не опрашивался</div>
<div><span class="co-ball">2</span> только <code>files</code>: NOTFOUND, код выхода 2</div>
<div><span class="co-ball">3</span> полный проход: ответ пришёл из DNS</div>
<div><span class="co-ball">4</span> NOTFOUND в обоих источниках — ошибка поиска</div>
</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">
См. <code>demos/12-nss-hosts.sh</code>. Политика — умолчание Ubuntu: <code>hosts: files dns</code>.
</div>

<!--
Три исхода на живой системе; инструмент — getent, который делает ровно те же вызовы
libc, что приложения, и потому честно показывает картину NSS (в отличие от dig,
говорящего с DNS напрямую мимо NSS, — расхождение их ответов само по себе диагностично).
Сценарий 1: имя intranet.example.test добавлено в /etc/hosts — files отвечает SUCCESS,
действие по умолчанию return, DNS не трогаем; адрес 192.0.2.80 — документационный
(TEST-NET-1). Сценарий 2: example.org в локальном файле нет — getent -s files
подтверждает NOTFOUND (код выхода 2), а полный проход возвращает адреса из DNS: сработал
continue. Сценарий 3: вымышленное имя — оба источника NOTFOUND, приложение получает
отказ. Четвёртый исход — источник недоступен — на следующем слайде.
-->

---

# Демо 12: источник недоступен — поиск продолжается

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/12-nss-hosts.txt" section="Файловый источник недоступен" title="demo 12 · files → UNAVAIL" fontSize="0.47rem">
  <TCallout :line="1" :col="3" :span="20" :n="1" />
  <TCallout :line="4" :col="1" :span="1" :n="2" />
  <TCallout :line="6" :col="1" :span="21" :n="3" />
  <TCallout :line="10" :col="54" :span="9" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> файл сделан нечитаемым — для непривилегированного процесса источник <b>недоступен</b></div>
<div><span class="co-ball">2</span> локальное имя потеряно: UNAVAIL → continue → в DNS его нет</div>
<div><span class="co-ball">3</span> публичное имя находится: поиск прошёл мимо отказавшего источника</div>
<div><span class="co-ball">4</span> <code>strace</code> показывает причину: <code>open("/etc/hosts") = EACCES</code></div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> отказ источника по умолчанию <b>не фатален</b> — поиск «проваливается»
дальше по списку (fail-open). Удобно для живучести; хорошо ли для безопасности —
вопрос политики (раздел 6.6).
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/12-nss-hosts.sh</code> (сеанс пользователя <code>bob</code>; <code>$</code> — его приглашение).
</div>

<!--
Четвёртый исход: источник не отвечает вовсе. Воспроизводим честный UNAVAIL: лишаем
/etc/hosts прав на чтение; для root файл всё равно открылся бы (CAP_DAC_OVERRIDE,
раздел 2.5), поэтому запросы выполняет непривилегированный bob. Модуль files не может
открыть файл — это не «записи нет», а «не смог ответить»: UNAVAIL. Поведение по
умолчанию — continue: локальное имя intranet теперь теряется (в DNS его нет), но
example.org исправно находится через DNS — система «пережила» отказ источника.
strace документирует первопричину: EACCES на openat. Этот сценарий — модель любого
отказа источника: сломанный модуль, упавший демон SSSD, недоступный сервер каталога.
По умолчанию NSS ведёт себя fail-open — продолжает искать в оставшихся источниках;
менять это умолчание или нет — решают действия, наша следующая тема.
-->

---

# Действия `[СТАТУС=действие]` переопределяют умолчания

Между источниками можно вписать **действие** — реакцию на код состояния источника
**слева** от него:

<div class="p-2 bg-gray-100 rounded text-sm font-mono mt-1">
[СТАТУС=действие] &nbsp;·&nbsp; [!СТАТУС=действие] &nbsp;(<b>!</b> — «любой статус, кроме…»)
</div>

<div class="t-table text-xs mt-2">

| Действие | Эффект |
|---|---|
| `return` | завершить поиск: вернуть результат или «не найдено» |
| `continue` | перейти к следующему источнику |
| `merge` | только `group`, glibc ≥ 2.24: объединить списки членов одноимённых групп (демо 13) |

</div>

<div class="text-sm mt-2">

- `hosts: files [NOTFOUND=return] dns` — локальный файл **авторитетен**: имени нет в `/etc/hosts` → DNS не спрашивается;
- `hosts: resolve [!UNAVAIL=return] files dns` — ответ systemd-resolved окончателен (и «найдено», и «не найдено»); резерв — только при недоступности службы;
- `group: files [SUCCESS=merge] sss` — найденная группа **дополняется** членами одноимённой группы каталога.

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Политика задаётся на базу целиком: продумывайте её для <b>всех</b> статусов, а не
только для «нашлось/не нашлось» — цена ошибки в демо 13.
</div>

<Refs ids="man-nsswitch glibc-manual-nss nss-resolve" />

<!--
Язык тонкой настройки. Синтаксис: в квадратных скобках статус (или его отрицание
через !), знак равенства, действие. Действий три: return, continue и специализированное
merge для группы (появилось в glibc 2.24; работает только для точечного поиска группы,
не для перебора getgrent, и дубликаты членов не устраняет). Разбор примеров: первый
делает локальный файл авторитетным — это сознательный отказ от DNS для имён, которых
нет в hosts: подходит изолированным стендам, но неуместен в общем случае. Второй —
строка из документации systemd: resolve объявляется главным (его NOTFOUND тоже
окончателен — «!UNAVAIL=return» значит «вернись при любом статусе, кроме недоступности»),
а падение службы не парализует систему. Третий — содержательное объединение групп из
двух источников. Существенно: действие относится к предыдущему источнику. И главное
правило проектирования политик — думать обо всех четырёх статусах; чем это кончается,
когда думают только об «available/unavailable», покажет демо 13.
-->

---

# Демо 13: одна функция — два источника

Для демонстраций развёрнут каталог LDAP с пользователем `dave` и подключён SSSD
(устройство — раздел 6.4); локальный пользователь `bob` — из `/etc/passwd`.

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Файлы или каталог" title="demo 13 · passwd: files sss" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="1" :n="1" />
  <TCallout :line="6" :col="1" :span="52" :n="2" />
  <TCallout :line="9" :col="1" :span="1" :n="3" />
  <TCallout :line="14" :col="31" :span="34" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> в файле <code>/etc/passwd</code> пользователя <code>dave</code> <b>нет</b></div>
<div><span class="co-ball">2</span> <code>getpwnam</code> его находит — запись пришла из каталога (<code>*</code> в поле пароля: хеша здесь нет)</div>
<div><span class="co-ball">3</span> <code>-s files</code> — NOTFOUND: подтверждаем, что файлы ни при чём</div>
<div><span class="co-ball">4</span> и вторичные группы (<code>initgroups</code>) собраны из каталога</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> приложения (и <code>getent</code>, и <code>id</code>, и <code>login</code>) не отличают локального
пользователя от каталожного — обещание NSS выполнено: источник сменился,
интерфейс — нет.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/13-nss-sssd.sh</code>; политика — <code>passwd: files sss</code>.
</div>

<!--
Первая демонстрация связки с каталогом — пока как с «чёрным ящиком»: есть LDAP-сервер
с записью dave (UID 5000) и локальный bob (UID 1001); политика passwd: files sss.
Читаем: grep подтверждает, что в файле dave отсутствует; getent passwd dave тем не
менее возвращает полноценную запись — все семь полей на месте, но в поле пароля «*»:
источник отдаёт только идентификационные данные, хеш пароля через NSS не раздаётся
(к этой границе вернёмся через два слайда). Изоляция источников ключом -s доказывает
маршрут: files — NOTFOUND, sss — SUCCESS. Наконец id dave показывает и вторичные
группы из каталога — работает база initgroups. Польза для администратора: getent -s —
первый инструмент диагностики «кто мне это ответил».
-->

---

# Демо 13: ловушка `[!UNAVAIL=return]` — NOTFOUND тоже прерывает поиск

Замысел политики: «спрашивать каталог, файлы — только если SSSD недоступен»:

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Ловушка" title="demo 13 · passwd: sss [!UNAVAIL=return] files" fontSize="0.5rem">
  <TCallout :line="2" :col="17" :span="27" :n="1" />
  <TCallout :line="7" :col="1" :span="1" :n="2" />
  <TCallout :line="9" :col="1" :span="1" :n="3" />
  <TCallout :line="13" :col="1" :span="33" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> каталог — первым; <code>files</code> — «резерв»</div>
<div><span class="co-ball">2</span> каталог работает и отвечает про <code>root</code> NOTFOUND → <b>return</b>: до файлов поиск не дошёл — <code>root</code> «исчез»</div>
<div><span class="co-ball">3</span> исчезли <b>все</b> локальные записи (<code>bob</code>)</div>
<div><span class="co-ball">4</span> парадокс: SSSD остановлен (UNAVAIL) — и только теперь файлы снова видны</div>
</div>
</div>

</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> «кроме UNAVAIL» включает и NOTFOUND — авторитетное «нет» каталога
обрывает поиск, и локальные записи видны, <b>только пока каталог лежит</b>. Правильный
порядок для учётных баз — <code>files sss</code>: локальные записи (включая <code>root</code>
для аварийного входа) разрешаются всегда и без сети.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/13-nss-sssd.sh</code>.
</div>

<!--
Поучительная ошибка конфигурирования. Замысел звучит разумно: «основной источник —
каталог, файлы — аварийный резерв». Но [!UNAVAIL=return] возвращает управление при
ЛЮБОМ статусе, кроме недоступности, — в том числе при NOTFOUND. Каталог предприятия
про root, bob и прочие локальные записи честно отвечает «не найдено» — и это «не
найдено» становится окончательным ответом всей системы: пока SSSD жив, локальных
пользователей не существует. Демонстрация доводит до парадокса: останавливаем SSSD —
sss возвращает UNAVAIL, запрет не срабатывает, и root «воскресает». Такая политика
ломает аварийный вход (root должен разрешаться без сети!) и усложняет диагностику.
Мораль дублирует предыдущие слайды: проектируя действия, перебирайте все статусы.
Для учётных баз каноничен порядок files sss — локальное первым; а когда действительно
нужно расширить ответы каталогом, есть осмысленный инструмент — merge, следующий слайд.
-->

---

# Демо 13: `[SUCCESS=merge]` объединяет членов группы

Группа `developers` (GID 5100) существует **в обоих источниках**: локально — с членом
`bob`, в каталоге — с членом `dave`:

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Объединение групп" title="demo 13 · group: files [SUCCESS=merge] sss" fontSize="0.47rem">
  <TCallout :line="2" :col="19" :span="3" :n="1" />
  <TCallout :line="5" :col="12" :span="4" :n="2" />
  <TCallout :line="10" :col="19" :span="3" :n="3" />
  <TCallout :line="12" :col="31" :span="25" :n="4" />
  <TCallout :line="14" :col="19" :span="8" :n="5" />
</TerminalCapture>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> локальный список членов: <code>bob</code></div>
<div><span class="co-ball">2</span> каталожный список: <code>dave</code></div>
<div><span class="co-ball">3</span> умолчания: <code>files</code> ответил SUCCESS → return, <code>dave</code> потерян</div>
<div><span class="co-ball">4</span> включаем <code>merge</code>…</div>
<div><span class="co-ball">5</span> …и списки объединены</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Осмысленное применение действий</b> для учётных данных: локальные и
централизованные членства складываются, а не вытесняют друг друга. Родственный
приём — <code>initgroups: files [SUCCESS=continue] sss</code>: вторичные группы
пользователя собираются из обоих источников.
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/13-nss-sssd.sh</code>. Требование <code>merge</code>: одинаковые имя и GID записи в обоих источниках.
</div>

<!--
Полезный, а не поучительный пример действий. Сюжет типичен для гибридной инфраструктуры:
группе developers нужны и локальный технологический пользователь bob, и каталожный dave.
С умолчаниями получить обоих нельзя: files находит группу первым, SUCCESS=return — и
каталожные члены отброшены (п. 3); поменять источники местами — потеряются локальные.
merge решает именно эту задачу: при SUCCESS поиск продолжается, и список членов
одноимённой группы следующего источника приклеивается к ответу. Ограничения дисциплины
ради: имя и GID должны совпадать (иначе это разные группы — и правильно, что не
сливаются), дубликаты членов не устраняются, на перебор getgrent действие не
распространяется. Родственный паттерн из документации SSSD — initgroups:
files [SUCCESS=continue] sss — тем же способом собирает вторичные группы пользователя
из двух миров. Вот ответ на вопрос «зачем действия администратору учётных записей»:
не экзотика, а штатный инструмент гибридных сред.
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="4" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

---

# Централизованные каталоги: LDAP, Active Directory, FreeIPA

<div class="grid grid-cols-[1.25fr_1fr] gap-4 items-start">
<div>

<div class="t-table text-xs mt-1">

| Система | Что это |
|---|---|
| **LDAP** | открытый протокол доступа к каталогам (RFC 4511) и класс серверов (OpenLDAP, 389 DS). Каталог — дерево записей с атрибутами; классы `posixAccount` и `posixGroup` (RFC 2307) хранят поля `passwd` и `group` |
| **Active Directory** | каталог Microsoft: LDAP + Kerberos + собственные расширения; фактический стандарт корпоративных сетей Windows |
| **FreeIPA** | открытый аналог для Linux-сред: 389 Directory Server + MIT Kerberos + DNS + центр сертификации, единое управление |

</div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs mt-2">
Запись каталога — «та же строка <code>passwd</code>, разложенная по атрибутам»:
<code>uidNumber</code> ↔ UID, <code>gidNumber</code> ↔ GID,
<code>homeDirectory</code>, <code>loginShell</code> — см. транскрипт.
</div>

</div>
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Каталог LDAP" title="demo 13 · запись posixAccount" fontSize="0.47rem">
  <TCallout :line="7" :col="14" :span="12" :n="1" />
  <TCallout :line="12" :col="1" :span="15" :n="2" :rows="2" />
  <TCallout :line="14" :col="1" :span="25" :n="3" :rows="2" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> класс POSIX-учётной записи (RFC 2307)</div>
<div><span class="co-ball">2</span> атрибуты UID и GID — поля 3–4 <code>passwd</code></div>
<div><span class="co-ball">3</span> дом и оболочка — поля 6–7</div>
</div>
</div>

</div>
</div>

<Refs ids="rfc4511 rfc2307 ms-adds freeipa" />

<!--
Знакомство с «другой стороной» sss. LDAP — и протокол (RFC 4511), и семейство серверов;
данные организованы деревом записей с атрибутами, а схема RFC 2307 отображает в них
знакомые поля passwd/group: uidNumber, gidNumber, homeDirectory, loginShell, memberUid.
В транскрипте — запись dave из лабораторного OpenLDAP (команда ldapsearch): это ровно
тот источник, из которого getent доставал запись на предыдущих слайдах. Active
Directory — тот же LDAP-каталог в основе, плюс Kerberos для аутентификации и
расширения Microsoft; в организациях со смешанной инфраструктурой Linux-машины часто
подключаются именно к AD. FreeIPA — открытая интеграционная сборка той же идеи для
Linux: 389 DS, MIT Kerberos, DNS и CA под единой консолью. Для NSS различия между
ними скрыты: со стороны nsswitch.conf всё это — источник sss.
-->

---

# SSSD — посредник между NSS и каталогом

**SSSD** (System Security Services Daemon) — системный демон: модуль `libnss_sss`
передаёт ему запросы, а он общается с каталогом, **кеширует** ответы и переживает
обрывы сети (режим offline).

<div class="sssd-flow mt-2">
  <div class="bf-block bf-fill-tint"><div class="bf-head">приложение</div><div class="bf-sub">getpwnam("dave")</div></div>
  <div class="sf-h"></div>
  <div class="bf-block bf-fill-dark"><div class="bf-head">glibc · NSS</div><div class="bf-sub">passwd: files sss</div></div>
  <div class="sf-h"></div>
  <div class="bf-block bf-fill-tint"><div class="bf-head bf-mono">libnss_sss</div><div class="bf-sub">UNIX-сокет</div></div>
  <div class="sf-h"></div>
  <div class="bf-block bf-fill-accent"><div class="bf-head">демон SSSD</div><div class="bf-sub">кеш · офлайн-режим · sssd.conf</div></div>
  <div class="sf-h"></div>
  <div class="bf-block bf-fill-tint"><div class="bf-head">каталог</div><div class="bf-sub">LDAP · AD · FreeIPA</div></div>
</div>

<div class="grid grid-cols-[1fr_1.1fr] gap-4 mt-3 items-start">
<div>

- один демон обслуживает **все** процессы машины — каталог не атакуется тысячей прямых подключений;
- поставщики данных (`id_provider`): `ldap`, `ad`, `ipa`, `proxy`;
- пакет `sssd` при установке **сам дописывает** `sss` в `nsswitch.conf`.

</div>
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Подключение sss" title="demo 13 · sssd.conf и nsswitch.conf" fontSize="0.4rem">
  <TCallout :line="5" :col="12" :span="8" :n="1" />
  <TCallout :line="8" :col="1" :span="18" :n="2" />
  <TCallout :line="20" :col="17" :span="9" :n="3" :rows="3" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> два ответчика: <code>nss</code> и <code>pam</code> (следующий слайд) ·
<span class="co-ball">2</span> поставщик — LDAP (в лаборатории без TLS; в эксплуатации TLS обязателен) ·
<span class="co-ball">3</span> учётные базы: сначала файлы, затем каталог
</div>

<Refs ids="sssd-docs man-nsswitch" />

<style>
/* Горизонтальная схема «приложение → … → каталог» в стиле BlockFlow; стили слайда-схемы 6.2 здесь недоступны — блок стилей в Slidev послайдовый. */
.sssd-flow { display: flex; align-items: stretch; font-size: 0.72rem; text-align: center; }
.sssd-flow .bf-block { flex: 1 1 0; }
.sssd-flow .sf-h { flex: 0 0 1.5em; position: relative; height: 2px; background: #555; align-self: center; }
.sssd-flow .sf-h::after { content: ''; position: absolute; right: -4px; top: -3px; border: 4px solid transparent; border-left-color: #555; }
</style>

<!--
Почему между NSS и каталогом нужен демон, а не «просто модуль libnss_ldap» (такой
исторически был)? Три причины. Первая — соединения: модуль работает внутри каждого
процесса, и без посредника каждый ls держал бы собственную LDAP-сессию; SSSD
мультиплексирует запросы всех процессов через локальный UNIX-сокет. Вторая — кеш и
офлайн-режим: ноутбук без сети продолжает узнавать своего пользователя. Третья —
единая точка конфигурации и безопасности: TLS, Kerberos, выбор поставщика (ldap/ad/ipa)
настраиваются в одном sssd.conf с правами 600 root:root. В транскрипте — лабораторная
конфигурация демо 13: поставщик ldap, база поиска dc=example,dc=test; выделенные строки
nsswitch.conf пакет sssd добавил при установке сам. Честная оговорка: в лаборатории
канал к slapd без TLS (ldap_id_use_start_tls = false) — в эксплуатации так нельзя,
о чём говорит и имя второй опции (…never_use_in_production).
-->

---

# Получение сведений — ещё не аутентификация

NSS отвечает на вопрос **«кто такой `dave`?»** (UID, группы, дом, оболочка) — это
**идентификация** (раздел 1). Проверку подлинности — **аутентификацию** — NSS
не выполняет: поле пароля из `sss` приходит как `*`, хеши через NSS не раздаются.

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-2 items-start">
<div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Разделение в SSSD:</b> ответчик <code>nss</code> выдаёт идентификационные данные
(этот раздел), ответчик <code>pam</code> проверяет аутентификаторы по каталогу или
Kerberos — с ним работает подсистема <b>PAM</b>, предмет лекции 3.
</div>

<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs mt-3">
<b>Итог раздела 6.4:</b> каталог хранит записи; SSSD доставляет и кеширует; NSS
отдаёт их приложениям через неизменный интерфейс; аутентификацию выполняет PAM.
Ни один уровень не заменяет другой.
</div>

</div>
<div>

**Диагностика по границе NSS/PAM:**

<div class="t-table text-xs mt-1">

| Симптом | Где искать |
|---|---|
| `getent` находит, вход не работает | PAM, пароль/билет Kerberos, политика учётной записи |
| вход настроен, `getent` не находит | `nsswitch.conf`, ответчик `nss` SSSD, связь с каталогом |
| пользователь «виден» при недоступном каталоге | кеш SSSD, офлайн-режим (раздел 6.5) |
| членство в группах устарело | кеш, база `initgroups` |

</div>

</div>
</div>

<Refs ids="gost-58833 sssd-docs glibc-manual-nss" />

<!--
Критически важная граница — возвращаемся к паре определений ГОСТ Р 58833-2020 из
раздела 1. Всё, что делал NSS в этом разделе, — идентификация: сопоставление имени
записи и её атрибутов. Подлинность никто не проверял: getent passwd dave работает без
пароля, и в поле пароля — «*». Проверка аутентификаторов идёт другим путём: PAM →
ответчик pam SSSD → LDAP bind или Kerberos; даже внутри одного демона эти пути
логически разделены. Отсюда диагностическая таблица: если getent пользователя видит,
а вход не пускает — проблема в аутентификационной цепочке (PAM, пароль, билет), не в
NSS; если наоборот — чинить нужно именно NSS-путь. Две нижние строки — про кеш:
пользователь, «живущий» при лежащем каталоге, и устаревшее членство в группах — это
нормальная (и настраиваемая) работа кеша SSSD, тема следующего раздела. Мост к
лекции 3 переброшен: там та же модульность, что NSS дал идентификации, появится у
аутентификации — PAM.
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="5" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

---

# Задержку определяет источник, а диспетчер — почти ничего

Сам диспетчер дёшев: разбор конфигурации и вызов функции модуля. Стоимость запроса
складывается **в источнике** — и вызовы libc **синхронны**: поток приложения
блокируется до ответа.

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

**Что определяет задержку:**

- **порядок источников**: медленный источник в начале списка задерживает каждый запрос, «проваливающийся» дальше;
- **отрицательные поиски**: запрос несуществующего имени проходит **весь** список — худший случай повторяется чаще, чем кажется;
- **деградация без отказа**: перегруженный сервер каталога или DNS не даёт UNAVAIL — он даёт тайм-ауты и хвостовые задержки;
- **повторы резолвера**: `timeout`/`attempts` в <Man p="resolv.conf(5)" /> умножаются на число серверов.

</div>
<div>

**Кеши — на каждом уровне:**

<div class="t-table text-xs mt-1">

| Уровень | Кеширует |
|---|---|
| SSSD | записи каталога; офлайн-режим; быстрый mmap-кеш в `/var/lib/sss/mc` |
| systemd-resolved | ответы DNS (с учётом TTL) |
| <Man p="nscd(8)" /> | ответы libc-баз; в Ubuntu не ставится по умолчанию — роль занял SSSD |
| приложения | собственные кеши (и собственные резолверы!) |

</div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs mt-2">
Кеш ускоряет и повышает живучесть, но <b>усложняет диагноз</b>: данные в каталоге уже
правильные, а приложение читает устаревший слой. Измеряйте полный путь запроса
приложения, а не ответ сервера.
</div>

</div>
</div>

<Refs ids="glibc-manual-nss man-resolvconf man-nscd sssd-docs" />

<!--
Цена абстракции. Диспетчер добавляет микроскопически мало; важны свойства источников.
files — локальное чтение; dns и sss — сеть со всеми её режимами отказа. Синхронность —
архитектурное свойство интерфейса: getpwnam не вернётся, пока источник не ответит или
не истечёт тайм-аут, поэтому зависший каталог означает зависшие приложения (это
регулярно проявляется как «sudo думает 25 секунд» при недоступном DNS). Четыре фактора
слева — типовые причины медленных поисков; отдельно подчеркнём отрицательные: именно
их чаще всего генерируют автоматика и опечатки, и именно они проходят список до конца.
Ответ инженерии — кеширование, но слоёное: SSSD (включая быстрый mmap-кеш, который
читается модулем даже без демона — увидим в демо), resolved со своим DNS-кешем,
исторический nscd (в современных Ubuntu не используется по умолчанию), и поверх всего —
кеши самих приложений, включая программы с собственными резолверами (Go-бинарники,
браузеры), которые вообще могут ходить мимо NSS. Следствие для диагностики в амбер-боксе:
смотреть нужно полный путь.
-->

---

# Демо 13: кеш `sss` отвечает и при остановленной службе

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-1 items-start">
<div>

<TerminalCapture src="captures/13-nss-sssd.txt" section="Кеш sss в действии" title="demo 13 · быстрый кеш /var/lib/sss/mc" fontSize="0.5rem">
  <TCallout :line="3" :col="3" :span="10" :n="1" />
  <TCallout :line="5" :col="1" :span="4" :n="2" />
  <TCallout :line="8" :col="1" :span="30" :n="3" />
  <TCallout :line="11" :col="1" :span="1" :n="4" />
</TerminalCapture>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1">
<div><span class="co-ball">1</span> демон SSSD остановлен…</div>
<div><span class="co-ball">2</span> …а <code>dave</code> по-прежнему находится: <code>libnss_sss</code> читает <b>mmap-кеш</b> напрямую, без демона</div>
<div><span class="co-ball">3</span> файлы кеша: <code>passwd</code>, <code>group</code>, <code>initgroups</code></div>
<div><span class="co-ball">4</span> кеш очищен — только теперь источник даёт UNAVAIL и запись «пропала»</div>
</div>
</div>

<v-click>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод:</b> кеш — часть контракта живучести: машина переживает отказ каталога.
Обратная сторона — устаревание: изменения в каталоге доходят с задержкой TTL, а
«луковица» кешей затрудняет поиск того слоя, который ещё помнит старое
(штатная очистка — <code>sss_cache -E</code>, не удаление файлов).
</div>

</v-click>

</div>
</div>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/13-nss-sssd.sh</code>.
</div>

<!--
Кеш из таблицы предыдущего слайда — вживую, и сразу самый неожиданный его слой. У SSSD
их два: основной кеш в базе демона (/var/lib/sss/db, отдаёт ответчик nss) и быстрый
mmap-кеш (/var/lib/sss/mc), который модуль libnss_sss отображает в память и читает
БЕЗ обращения к демону. Поэтому остановка SSSD не делает источник недоступным: п. 2 —
запись dave продолжает находиться. Только удалив файлы кеша (в учебном контейнере;
штатный инструмент — sss_cache), получаем честный UNAVAIL и «исчезновение» записи.
Этот опыт объясняет строку диагностической таблицы 6.4 «пользователь виден при
недоступном каталоге» — и показывает цену: пока жив кеш, изменения и блокировки в
каталоге сюда не доехали. Важная граница: кешируются идентификационные данные; офлайн-
аутентификация по кешированным аутентификаторам — отдельный механизм с отдельной
настройкой (cache_credentials) и отдельными рисками — лекция 3.
-->

---
layout: section
---

# 6. Name Service Switch
## Единый интерфейс к базам учётных данных и имён

<SectionTOC prefix="6" :current="6" :items="[
  'От локальных файлов к NSS',
  'Архитектура NSS',
  'Конфигурация: nsswitch.conf',
  'SSSD и централизованные каталоги',
  'Производительность и кеширование',
  'Безопасность NSS',
]" />

---

# Граница доверия: модуль NSS исполняется в каждом процессе

Модуль NSS — **исполняемый код** в адресном пространстве **вызывающего процесса** (раздел 6.2) — в том числе привилегированного: `sshd`, `sudo`, `cron` тоже вызывают `getpwnam`.

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

**Следствия:**

- запись в `/etc/nsswitch.conf` или подмена `libnss_*.so.2` = исполнение кода **в каждом процессе** — готовый механизм закладки (persistence);
- злонамеренный модуль видит память и полномочия процесса;
- то же относится к `sssd.conf` и прочей конфигурации источников.

</div>
<div>

**Меры защиты:**

- модули — только из доверенных пакетов; неиспользуемые — удалить;
- `nsswitch.conf` и каталоги модулей пишет только root; контроль целостности (AIDE) — как для `/etc/passwd`;
- обновления резолвера — приоритетные (слайд об атаках);
- setuid-программы: загрузчик игнорирует `LD_LIBRARY_PATH`, но **системный** каталог модулей — общая точка доверия.

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Границы доверия NSS шире, чем кажутся:</b> ответ источника влияет на то,
<b>куда соединится</b> программа (базы <code>hosts</code>) и <b>кем будет считаться</b>
субъект (базы <code>passwd</code>/<code>group</code>). Неверный или навязанный ответ — не «ошибка поиска»,
а смещение точки принятия решений безопасности.
</div>

<Refs ids="glibc-manual-nss man-nsswitch" />

<!--
Раздел безопасности открываем с архитектурного факта 6.2: NSS — код в чужих процессах.
Это не плагин одного приложения, а слой ВСЕХ приложений, включая работающие с
привилегиями. Отсюда ценность nsswitch.conf и каталога модулей для атакующего: одна
строка конфигурации — и его библиотека исполняется везде; известный приём закрепления
в системе. Защита симметрична угрозе: доверенные источники пакетов, минимизация
модулей, права и контроль целостности на конфигурацию — ровно как мы защищали
/etc/passwd, плюс дисциплина обновлений (уязвимость в резолвере — уязвимость всех
программ сразу, увидим на слайде об атаках). Оговорка про setuid: загрузчик в
«безопасном режиме» игнорирует переменные окружения вроде LD_LIBRARY_PATH, так что
подсунуть модуль через окружение нельзя — но системный каталог модулей остаётся общей
точкой доверия. Амбер-бокс расширяет картину: NSS стоит на границах, где решается,
куда подключаться и кто есть кто, — компрометация ответа смещает сами решения
безопасности, а не только «ломает поиск».
-->

---

# Коллизии идентичностей: одно имя — два источника

Локальная запись и запись каталога могут носить **одно имя** с **разными UID** —
или один UID при разных именах. Какой субъект «победит», решает порядок источников.

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-2 items-start">
<div>

При `passwd: files sss`:

- поиск по **имени**: побеждает локальная запись — каталожный тёзка невидим;
- поиск по **UID** (например, `ls -l`): тоже идёт по списку — владелец файла может «переименоваться» при смене политики;
- `useradd`/`groupadd` проверяют занятость имени **через NSS**: каталожное имя блокирует создание локального (в демо 13 группу `developers` пришлось заводить при отключённом `sss`).

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Риск:</b> совпадение имени локальной и каталожной записи — это два субъекта с
разными полномочиями под одной вывеской: администратор даёт доступ «пользователю
dave», не контролируя, которому из двух.
</div>

<div class="p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs mt-3">
<b>Политика пространств имён:</b> разделить диапазоны UID/GID (локальные — до 10000,
каталожные — выше), запретить совпадения имён организационно, проверять коллизии в
<b>обе стороны</b>: <code>getent passwd имя</code> и <code>getent passwd UID</code>.
</div>

</div>
</div>

<Refs ids="man-nsswitch sssd-docs man-useradd" />

<!--
Класс проблем, не существовавший в мире одних файлов: источников стало несколько, и
пространства имён могут пересечься. Сценарии: подрядчик завёл локального dave на
сервере, затем организация подключила AD с doменным dave — теперь на этом сервере
«dave» означает другого субъекта, чем на остальных; или наоборот — локальный UID 5000
исторически занят, а каталог раздаёт свои UID с 5000 — и ls -l подписывает файлы
чужим именем. Порядок источников детерминирует победителя (files первым — локальная
запись затмевает каталожную), но затмение — не решение: второй субъект никуда не
делся. Отметим и наблюдение из демо 13: утилиты управления записями проверяют
занятость имени через getent, то есть каталог «бронирует» имена и для локального
администрирования. Лечится дисциплиной: непересекающиеся диапазоны идентификаторов
(вспомните UID_MIN/UID_MAX из раздела 4.2 и min_id/max_id в sssd.conf), запрет
дубликатов имён, и регулярная проверка коллизий в обе стороны — по имени и по числу.
-->

---

# Отказ источника: fail-open или fail-closed — выбор политики

Что делать, когда источник **не ответил**? Оба ответа законны — но выбор должен
быть **сознательным**:

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Fail-open (умолчание NSS):</b> UNAVAIL → continue — поиск уходит к следующему
источнику.
<div class="mt-1">
<b>+</b> живучесть: машина работает при отказе каталога/резолвера;<br>
<b>−</b> ответ даёт источник с <b>другими гарантиями</b>: запасной DNS-путь может
не проверять DNSSEC и игнорировать split-DNS, «запасные» учётные данные — быть
устаревшими.
</div>
</div>

</div>
<div>

<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Fail-closed:</b> <code>[UNAVAIL=return]</code> — при отказе источника поиск прерывается.
<div class="mt-1">
<b>+</b> никакой деградации гарантий «втихую»;<br>
<b>−</b> отказ инфраструктуры превращается в отказ в обслуживании — вплоть до
невозможности входа администратора.
</div>
</div>

</div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Практический компромисс</b> для учётных баз: <code>files</code> — первым и
безусловно (локальные аварийные записи работают всегда, вспомните ловушку демо 13);
строгость — на уровне источников-«авторитетов» (<code>resolve [!UNAVAIL=return]</code>);
и обязательные <b>учения</b>: как ведёт себя вход, <code>sudo</code> и приложения при выключенном
каталоге — проверено заранее, а не во время инцидента.
</div>

<div class="mt-2 text-xs">
NSS даёт лишь <b>грубые</b> рычаги (четыре статуса, три действия) — он не заменяет
ни авторизацию, ни полноценную политику доверия; тонкие правила живут в источниках
(SSSD, resolved) и в PAM (лекция 3).
</div>

<Refs ids="man-nsswitch glibc-manual-nss sssd-docs" />

<!--
Обобщение линии, начатой демо 12 (источник недоступен) и демо 13 (ловушка). Поведение
при отказе — не данность, а политика. Fail-open — умолчание NSS и правильный выбор
для живучести, но с оговоркой о гарантиях: два источника одной базы — это два разных
контура доверия, и тихий переход на запасной меняет свойства ответа (классический
пример — VPN с внутренним DNS: отказ resolved не должен уводить корпоративные имена
на публичный резолвер). Fail-closed честнее к гарантиям, но оплачивается доступностью —
и ловушка из демо 13 показала, как неаккуратная строгость отрезает аварийный вход.
Компромисс в teal-боксе — распространённая практика: локальные файлы вне подозрений и
первыми, строгость точечно там, где источник объявлен авторитетным, и обязательные
учения отказа. Последний абзац удерживает масштаб: NSS — диспетчер с грубыми рычагами;
просить от него полноценную политику доверия не нужно — для неё есть источники и PAM.
-->

---

# Атаки: NSS разбирает недоверенные данные в каждом процессе

Резолвер и парсеры NSS — часть libc, то есть **каждого** процесса; их входные данные
(ответы DNS, записи источников) часто **контролирует противник**.

<div class="t-table text-xs mt-2">

| Атака | Механизм |
|---|---|
| **GHOST** · CVE-2015-0235 | переполнение буфера в `__nss_hostname_digits_dots()` (путь <Man p="gethostbyname(3)" />): длинное «имя узла» перезаписывает память; эксплуатировалось удалённо через почтовый сервер Exim. Ошибка исправлена в glibc 2.18 (2013) — но дистрибутивы годами несли старые версии |
| CVE-2015-7547 | переполнение стекового буфера в <Man p="getaddrinfo(3)" /> при разборе **ответа DNS** длиннее 2048 байт (парные запросы A/AAAA): вредоносный DNS-сервер или перехват трафика → выполнение кода в любом приложении, резолвящем имена (обнаружено Google и Red Hat, 2016) |
| Закладка-модуль NSS | строка в `nsswitch.conf` + библиотека `libnss_*.so.2` = исполнение кода в каждом процессе (предыдущий слайд); обнаружение — контроль целостности конфигурации и каталогов модулей |
| Навязывание ответа | подмена `/etc/hosts`, отравление DNS-кеша, ложный сервер каталога без TLS: жертва соединяется с узлом противника или «видит» чужие учётные данные |

</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
<b>Вывод раздела:</b> NSS — удачная абстракция с 30-летней историей: интерфейс
пережил смену эпох от файлов до облачных каталогов. Но это <b>инфраструктура
доверия</b>: её конфигурация, модули и источники требуют той же дисциплины защиты,
что и сами учётные базы, — а проверку подлинности она по-прежнему оставляет
другим (PAM — лекция 3).
</div>

<Refs ids="qualys-ghost google-cve-2015-7547 man-gethostbyname man-getaddrinfo" />

<!--
Завершаем раздел конкретикой. Общая черта первых двух строк: уязвим код libc, который
исполняется в каждом процессе и разбирает данные, пришедшие от противника. GHOST
(Qualys, январь 2015) — переполнение в служебной функции пути gethostbyname: четыре
байта перезаписи хватило для удалённой эксплуатации через Exim; поучительна хронология —
баг починили в 2.18 ещё в 2013-м, но «стабильные» дистрибутивы несли уязвимую libc
годами: обновление резолвера — не рутина, а приоритет. CVE-2015-7547 (Google/Red Hat,
2016) — стековое переполнение в getaddrinfo при разборе DNS-ответа свыше 2048 байт;
триггер — обычный резолвинг имени, атакующему достаточно управлять DNS-сервером или
трафиком; уязвимы были ssh, sudo, curl — всё, что резолвит имена. Третья строка —
не уязвимость, а свойство архитектуры, повторяем её как сценарий закрепления. Четвёртая —
атаки на данные, а не код: от школьной подмены hosts до ложного LDAP без TLS (вспомните
лабораторную оговорку в 6.4). Финальный вывод собирает раздел 6: абстракция удалась —
интерфейс раздела 5 не менялся 30 лет при полной смене источников; но NSS — часть
доверенной вычислительной базы, и к его файлам, модулям и каналам применима вся
дисциплина лекции; аутентификацию же он честно оставляет PAM — переходим к источникам.
-->

---
layout: section
---

# Источники

---
routeAlias: refs
---

# Источники

<SourcesList class="mt-4" :to="30" />

<div class="text-xs opacity-70 mt-3">
Нумерация сквозная для всей лекции; ссылки «[n]» внизу слайдов ведут сюда и подсвечивают
источник. Точные версии и особенности системы — локальные man-страницы Ubuntu Server 26.04.
</div>

---
routeAlias: refs2
refsFrom: 31
---

# Источники (продолжение)

<SourcesList class="mt-4" :from="31" :to="60" />

---
routeAlias: refs3
refsFrom: 61
---

# Источники (окончание)

<SourcesList class="mt-4" :from="61" />
