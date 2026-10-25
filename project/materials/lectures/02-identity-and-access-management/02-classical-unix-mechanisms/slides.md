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
принадлежность пользователя к группам (подраздел 2.1).

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
<div><code>x</code> — хэш пароля группы хранится в <code>/etc/gshadow</code> (раздел 3)</div>
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
наличия пароля группы: x — хэш в /etc/gshadow (раздел 3), пусто — пароль не задан;
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

# Четыре идентификатора процесса

<div>

Субъект для монитора обращений — **процесс** (подраздел 2.1). Ядро хранит в учётных
данных (credentials, <Man p="credentials(7)" />) каждого процесса не один UID,
а **четыре** — и столько же GID:

</div>

<div class="t-table text-xs mt-2">

| Идентификатор | Название | Назначение |
|---|---|---|
| **ruid** / rgid | real — реальный | кто запустил процесс: наследуется от родителя и хранит «настоящего» пользователя |
| **euid** / egid | effective — эффективный | по нему ядро проверяет привилегии процесса; euid 0 — права root |
| **suid** / sgid | saved — сохранённый | копия euid на момент запуска программы: позволяет временно сбросить привилегии и затем вернуть их |
| **fsuid** / fsgid | filesystem — файловый | использовался в проверках доступа к файлам; сейчас всегда следует за euid, <Man p="setfsuid(2)" /> — исторический |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
В <code>/proc/PID/status</code> строки <code>Uid:</code> и <code>Gid:</code> содержат четыре
колонки <b>именно в этом порядке</b>: real, effective, saved, filesystem (<Man p="proc(5)" />).
Строка <code>Groups:</code> — вторичные группы процесса (подраздел 2.3).
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10 text-xs">
У обычного процесса все четыре значения совпадают. Расходятся они после запуска
<b>setuid/setgid-программы</b> (например, <code>passwd</code>) или системных вызовов
изменения идентификаторов — далее в подразделе.
</div>

<Refs ids="man-credentials man-proc kerrisk-tlpi" />

<!--
Терминология: у процесса не один UID, а четыре (и столько же GID) — часть его учётных
данных. Решения о правах ядро принимает по effective (для файлов — по filesystem, который
сегодня совпадает с effective). Real хранит, кто запустил. Saved — копия euid на момент
запуска программы: нужен, чтобы программа могла временно понизить привилегии и вернуть их
(демо 04). Порядок колонок Uid:/Gid: в /proc/PID/status — real, effective, saved,
filesystem; это ответ на вопрос со слайда «Субъекты и объекты» (подраздел 2.1).
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
отдельности выводит ps (ruid,euid,suid,fsuid). Интересно станет на setuid-программе —
следующий слайд.
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
<code>/etc/shadow</code> (раздел 3). Какие значения и когда выставляет ядро — далее.
</div>

</v-click>

<div class="text-xs opacity-70 mt-1">
См. <code>demos/03-process-credentials.sh</code>.
</div>

<!--
Ответ на вопрос «зачем процессу отдельные real и effective»: passwd должен записывать
в недоступный пользователю /etc/shadow, поэтому файл /usr/bin/passwd имеет setuid-бит:
при execve euid (и вслед за ним suid и fsuid) становится равным владельцу файла — root.
ruid остаётся прежним: по нему passwd знает, чей пароль менять. Механика — на следующих
слайдах.
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
у процесса лишь двумя путями: вход в систему (процедура логина — раздел 5) и запуск
setuid-программ.
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
Алгоритм — по Керриску (TLPI, гл. 9) и execve(2). Качели seteuid(ruid)/seteuid(suid)
работают благодаря сохранённому UID: непривилегированному euid разрешён только из
множества {ruid, suid}.
-->

---

# Безопасное программирование: управление привилегиями

<div>

setuid-программы — классический источник уязвимостей: любая ошибка в них исполняется
с правами root. Правила обращения с привилегиями (Керриск, гл. 38):

</div>

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-2 items-start">
<div>

**Держать привилегии минимум времени** — «качели привилегий»:

```c
uid_t euid = geteuid();  /* владелец файла: 0  */

seteuid(getuid());       /* сброс: работаем с
                            правами пользователя */
/* …разбор ввода, вычисления, файлы… */

seteuid(euid);           /* возврат — только вокруг
                            привилегированной операции */
```

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
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
(подраздел 2.2), файловые capabilities (<Man p="capabilities(7)" />), `sudo` (раздел 7).

</div>
</div>

<Refs ids="kerrisk-tlpi man-setuid man-capabilities" />

<!--
Концепция безопасного программирования с привилегиями — по Керриску (TLPI, гл. 38
Writing Secure Privileged Programs) и Saltzer–Schroeder (принцип наименьших привилегий).
Качели: сбросить euid сразу после старта, возвращать только вокруг привилегированной
операции. Насовсем — setuid(getuid()) или явный setresuid(u,u,u); обязательно проверять
код возврата: у sendmail неудавшийся (из-за лимита) setuid однажды остался незамеченным.
Помнить о наследовании: suid переживает fork — «пониженные» воркеры могут вернуть root.
Современная альтернатива setuid-root — служебные учётные записи, file capabilities, sudo.
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
Качели привилегий в действии, с функциональной проверкой — попыткой открыть /etc/shadow
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

- Все идентификаторы процесса живут в одной структуре **`struct cred`** — вместе с capabilities и дополнительными группами (`group_info`).
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

`current_euid()` выбирает поле `euid` из `cred` **текущего** процесса; так реализованы
системные вызовы <Man p="getuid(2)" />/<Man p="geteuid(2)" />. Проверки привилегий
(`capable()`) используют euid-набор, проверки доступа к файлам — `current_fsuid()`.

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
**побайтовую копию** `struct cred` родителя (все UID/GID, capabilities, группы). Поток
внутри процесса cred не копирует, а разделяет.

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
затем suid и fsuid выравниваются по новому euid (алгоритм из подраздела 2.4). Здесь же
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
