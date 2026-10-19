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

# Краткая история

<Timeline height="12em" :items="[
  { year: '1960-е', head: 'CTSS (MIT)', text: 'первые пароли для входа в систему разделения времени' },
  { year: '1971', head: 'Unix V1', text: '/etc/passwd: пароли сначала в открытом виде' },
  { year: '1979', head: 'crypt и соль', text: 'Моррис и Томпсон: медленное хэширование (DES) и соль' },
  { year: '1980-е', head: 'NIS', text: 'Sun, «Yellow Pages»: сетевая база пользователей' },
  { year: '1988', head: 'Червь Морриса', text: 'атака по словарю на хэши из читаемого passwd', hot: true },
  { year: '~1987–90', head: 'Shadow-пароли', text: 'хэш выносится в /etc/shadow (0640, root)' },
  { year: '1995', head: 'PAM и NSS', text: 'OSF RFC 86.0: модульные методы аутентификации и источники данных' },
  { year: '2000-е', head: 'LDAP, AD, SSSD', text: 'централизованные каталоги учётных записей' },
]" />

<v-click>

<HistoryNote class="mt-2">
Пароли скомпрометировали почти сразу: в 1966 г. из-за ошибки администратора CTSS
файл паролей попал в сообщение дня, а охотники за машинным временем научились его
распечатывать. Урок повторился в 1988-м — уже со словарным перебором хэшей.
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
пароли по словарю к хэшам из общедоступного passwd — это ускорило переход на
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
Почему идентификаторов <code>Uid</code> и <code>Gid</code> по четыре — подраздел 2.4.
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
Правило наследования идентификаторов при fork — в подразделе 2.4.
-->

---

# Пользователи и группы

<div class="grid grid-cols-[1.15fr_1fr] gap-6">
<div>

- В Linux определены **пользователи** (учётные записи) и **группы** пользователей.
- Каждый пользователь уникально идентифицируется числом — **UID** (User ID).
- Несколько пользователей могут образовывать **группу**; каждая группа уникально идентифицируется числом — **GID** (Group ID).
- Группы нужны для **единых правил доступа** сразу для множества пользователей: доступ к каталогу проекта даётся группе `project`, а не каждому сотруднику отдельно (лекция 3).
- Пользователь может состоять **в нескольких группах** одновременно.
- Учётная запись — не обязательно человек: службы работают от имени **псевдопользователей** (подраздел 2.2).

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
подразделы 2.2 и 2.3.
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
службы работают от имени псевдопользователей — подробно в подразделе 2.2.
-->

---

# UID и GID: числовые идентификаторы

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

# Специальные пользователи: назначение

<div>

Не каждая учётная запись принадлежит человеку: большинство строк базы пользователей
Ubuntu Server 26.04 — **служебные** записи. Механика таких «псевдопользователей» —
в подразделе 2.2; назначение типичных записей:

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
<div><code>x</code> — хэш пароля хранится в <code>/etc/shadow</code> (раздел 3)</div>
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
через двоеточие. Поле 2 — признак наличия пароля: x — хэш лежит в /etc/shadow (раздел 3);
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
Живой файл с демо-сервера. Сверху вниз: root; системные записи первых Unix с UID 1–99,
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
**Пишет только root**; свои поля пользователь меняет через SUID-утилиты <Man p="passwd(1)" />,
<Man p="chsh(1)" />, <Man p="chfn(1)" />.

</div>
</div>

**Файл читает любой пользователь — что тогда хранить во 2-м поле?**

<div class="grid grid-cols-2 gap-3 mt-2 text-xs">
<v-click>
<div>
<b class="text-red-600">Пароль в открытом виде: утечка неизбежна</b>
<HistoryNote label="Исторический экскурс · CTSS, 1966" class="mt-1">
Так хранила пароли CTSS (MIT) — первая система с парольным входом. Редактор создавал
временный файл с фиксированным именем, и когда два администратора одновременно открыли
файл паролей и «сообщение дня», временные файлы поменялись местами: каждому входящему
вместо приветствия распечатывался полный файл паролей.
</HistoryNote>
</div>
</v-click>
<v-click>
<div>
<b class="text-red-600">Хэш пароля: приглашение к перебору</b>
<HistoryNote label="Исторический экскурс · червь Морриса, 1988" class="mt-1">
Червь Морриса (2 ноября 1988 г., поражено ~10 % тогдашней сети) копировал хэши из
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
а хэш вынесен в <code>/etc/shadow</code> с правами <code>0640 root:shadow</code> — раздел 3.
</div>

</v-click>

<Refs ids="morris-thompson corbato morris-worm" />

<!--
Права: 0644 — файл читают все, потому что множество программ превращают UID в имена;
пишет только root, пользователь меняет свои поля через SUID-утилиты. Отсюда вопрос:
что хранить во 2-м поле общедоступного файла? Открытый текст — утечка неизбежна:
история CTSS 1966 г. (Морриса—Томпсона и Корбато): редактор с фиксированным именем
временного файла, два администратора, файл паролей напечатался каждому входящему как
сообщение дня. Хэши — тоже плохо: червь Морриса 1988 г. вёл словарный перебор по
скопированным из passwd хэшам (вариации имени, 432 встроенных слова, /usr/dict/words,
быстрый crypt) — Spafford, 1988. Вывод: x в поле 2, хэш — в /etc/shadow (раздел 3).
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
