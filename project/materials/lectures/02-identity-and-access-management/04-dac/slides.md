---
theme: default
title: Механизмы разграничения доступа ОС Linux
author: OSSec
addons: [../../../theme]
layout: cover
colorSchema: light
duration: 90min
mdc: true
selectable: true
transition: slide-left
defaults:
  class: lecture-dac
---

# Лекция 4

## Механизмы разграничения доступа ОС Linux

<!--
Сквозные правила деки: номер слайда — в правом нижнем углу (тема);
внизу каждого слайда (кроме демо) — блок «Источники: [n]» (<Refs ids="…"/>,
номера по sources.json, клик ведёт на слайд routeAlias: refs и подсвечивает
источник); упоминания man-страниц — ссылки (<Man p="name(sec)"/>).
Демонстрационная среда — Ubuntu Server 26.04 LTS (одноразовый контейнер,
hostname srv, пользователи bob/alice/carol/dave; каталоги демонстраций
смонтированы на ext4 — см. assets/captures/README.md). Фрагменты ядра — v6.18.
-->

---
layout: default
---

# План лекции

<div class="grid grid-cols-2 gap-x-8 mt-4 plan-list">
<div>

1. **Введение** — дискреционная модель управления доступом
2. **Классическая модель Unix** — триплеты прав, специальные биты, umask
3. **Реализация в ядре Linux** — структура `inode`, проверки прав в VFS
4. **Ограничения классической модели** — задачи, которые триплеты не решают

</div>
<div>

5. **Дополнительные атрибуты файлов** — `chattr`: immutable, append-only
6. **Расширенные атрибуты xattr** — метаданные «ключ–значение»
7. **Списки контроля доступа** — POSIX ACL: записи, маска, наследование

<div class="mt-4 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Сквозной пример: сервер Ubuntu 26.04 (хост <code>srv</code>), пользователи
<code>bob</code>, <code>alice</code>, <code>carol</code>, <code>dave</code>;
разделы 2, 5–7 сопровождаются демонстрациями
(<code>assets/demos/01–16</code>).
</div>

</div>
</div>

<style>
.plan-list li { margin: 0.45em 0; }
</style>

<!--
Семь разделов. Центральный вывод лекции: классическая дискреционная модель
Unix остаётся ядром разграничения доступа в Linux, однако на практике её
дополняют три механизма — дополнительные атрибуты файлов, расширенные
атрибуты и списки контроля доступа, — каждый из которых решает свой класс
задач и имеет собственные ограничения. Разделы 1–2 вводят модель и её
механизмы, раздел 3 показывает реализацию в ядре, раздел 4 формулирует
ограничения, разделы 5–7 разбирают дополняющие механизмы. Лекция опирается
на материал лекции 2: пользователи и группы, идентификаторы процесса.
-->

---
layout: section
---

# 1. Введение
## Дискреционная модель управления доступом

---

# Права на объект назначает его владелец

**Избирательное (дискреционное) управление доступом** (discretionary access
control, DAC) — управление доступом субъектов к объектам на основе списков
управления доступом или матрицы доступа; права на объект определяет его
владелец.

<div class="grid grid-cols-2 gap-3 mt-3">
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>Владелец ресурса</b><br/>
пользователь, создавший ресурс, становится его владельцем и устанавливает,
кто и какие действия может выполнять с этим ресурсом
</div>
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>Делегирование прав</b><br/>
владелец может передавать права доступа другим пользователям
или группам пользователей
</div>
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>Контроль действий</b><br/>
для каждой пары «субъект–объект» явно определяются допустимые операции:
чтение, запись, выполнение
</div>
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>Идентификация</b><br/>
все субъекты и объекты однозначно идентифицированы — в Unix
идентификаторами служат UID и GID (лекция 2)
</div>
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10">
Модель разрабатывалась в 1970-х годах для организации многопользовательской
работы; требования защищённости выводились из задачи <b>разделения</b>
пользователей, а не из современной модели угроз.
</div>

</v-click>

<Refs ids="dac-wiki kerrisk-tlpi" />

<!--
Определение дискреционной модели: доступ субъектов к объектам управляется на
основе прав, назначаемых владельцем объекта. Четыре принципа: владелец,
делегирование, контроль действий, идентификация. Подчеркнуть связь с
лекцией 2: идентификация субъектов уже построена — UID/GID; эта лекция
отвечает на следующий вопрос: как идентифицированным субъектам
разграничивается доступ к объектам. Янтарное замечание — исторический
контекст: модель 1970-х, задача — многопользовательская работа; свойства
защиты от современных атак из неё не следуют автоматически.
-->

---

# Unix реализует смешанный вариант дискреционной модели

Возможны несколько подходов к построению дискреционного управления доступом:

<div class="t-table mt-3">

| Подход | Кто назначает права |
|---|---|
| Владелец | каждый объект имеет привязанного субъекта-**владельца**; именно он устанавливает права доступа |
| Суперпользователь | выделенный субъект устанавливает права владения для всех остальных субъектов системы |
| Передача прав | субъект, обладающий правом доступа, может передать это право любому другому субъекту |
| **Смешанный** | владельцы устанавливают права на свои объекты, **и** суперпользователь может изменять права и владельца любого объекта |

</div>

<v-click>

<div class="mt-4 p-3 border-l-4 border-teal-500 bg-teal-500/10">
В Unix реализован <b>смешанный вариант</b>: права на файл задаёт владелец,
однако суперпользователь <code>root</code> игнорирует результаты проверок и
может изменить права и владельца любого объекта. Вследствие этого ограничить
действия <code>root</code> средствами самой модели невозможно — к этому
ограничению мы вернёмся в разделе 4.
</div>

</v-click>

<Refs ids="dac-wiki kerrisk-tlpi" />

<!--
Таксономия подходов к построению DAC. В Unix — смешанный вариант: и владельцы,
и всевластный суперпользователь. Это проектное решение 1970-х имеет прямое
следствие для безопасности: политика, которую нельзя навязать root, не
защищает от компрометации root. Заложить мост к разделу 4 (ограничения) и
разделу 5 (атрибут i, который ограничивает даже root, но вводится уже другим
механизмом).
-->

---

# Субъекты — процессы, объекты — файлы

**Субъект доступа** — программа (процесс), запущенная от имени некоторого
пользователя: права процесса определяются идентификаторами его пользователя
(лекция 2 — эффективный UID, список групп). Объекты доступа различаются по
типу — тип показывает первый символ вывода `ls -l`:

<div class="t-table text-xs mt-2">

| Тип (`ls`) | Объект | Замечание |
|:---:|---|---|
| `-` | обычный файл | содержимое и метаданные |
| `d` | каталог | «файл-список»: имена и ссылки на inode |
| `l` | символическая ссылка | права `rwxrwxrwx` фиктивны — действуют права целевого файла |
| `c` | символьное устройство | поток байтов: терминал, `/dev/null` |
| `b` | блочное устройство | обмен блоками: диск, DVD-привод |
| `p`, `s` | именованный канал, сокет | механизмы IPC (лекция 2, раздел 2.1) |

</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Права доступа хранятся в метаданных объекта, поэтому единые правила
разграничения действуют для всех перечисленных типов объектов — файловый
интерфейс унифицирует доступ к устройствам и механизмам IPC.
</div>

<Refs ids="nemeth shotts" />

<!--
Субъект — не пользователь, а процесс, действующий от имени пользователя:
проверки прав используют идентификаторы процесса. Таблица типов объектов —
повторение из лекции 2, расширенное замечанием о символических ссылках: их
права фиктивны, проверяются права целевого файла. Единообразие файлового
интерфейса — причина, по которой одна модель прав покрывает устройства,
каналы и сокеты.
-->

---

# Девять битов: три категории субъектов, три вида прав

Права доступа (режим, *file mode*) записываются **триплетами прав**
(permissions triplet) — по одному на каждую категорию субъектов:

<div class="grid grid-cols-[1.2fr_1fr] gap-5 mt-3 items-start">
<div>

<div class="tri-scheme">
  <div class="tri-cell"><div class="tri-head">владелец<br/><b>user</b></div><div class="tri-bits">r w x</div></div>
  <div class="tri-cell"><div class="tri-head">группа владельцев<br/><b>group</b></div><div class="tri-bits">r w x</div></div>
  <div class="tri-cell"><div class="tri-head">остальные<br/><b>other</b></div><div class="tri-bits">r w x</div></div>
</div>

<div class="mt-3">

- **чтение** (read, `r`) — содержимое объекта можно читать;
- **запись** (write, `w`) — содержимое можно изменять;
- **выполнение** (execute, `x`) — файл можно исполнить как программу.

</div>

</div>
<div>

**Категории субъектов:**

1. **владелец** (user) — единственный пользователь, обозначенный
   владельцем файла;
2. **группа** (group) — пользователи, входящие в группу владельцев
   файла;
3. **остальные** (other) — прочие пользователи системы.

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Категории <b>не пересекаются при проверке</b>: для конкретного процесса
действует ровно один триплет — первый подходящий по порядку
«владелец → группа → остальные» (раздел 2.2).
</div>

</div>
</div>

<Refs ids="kerrisk-tlpi rh-dac" />

<style>
.tri-scheme { display: flex; gap: 0.6em; }
.tri-cell { flex: 1; border: 1px solid var(--slidev-theme-primary, #2b90b6); border-radius: 6px; overflow: hidden; text-align: center; }
.tri-head { font-size: 0.7rem; padding: 0.3em 0.2em; background: rgba(43,144,182,0.12); line-height: 1.25; }
.tri-bits { font-family: var(--slidev-code-font-family, monospace); font-size: 1.4rem; letter-spacing: 0.18em; padding: 0.25em 0; }
</style>

<!--
Девять атрибутов = три триплета по три права. Смысл r/w/x для файлов очевиден,
для каталогов — нет, этому посвящён следующий раздел. Ключевая деталь в
янтарной рамке: категории проверяются по порядку и выбирается ровно один
триплет — отсюда неожиданные эффекты, когда права владельца меньше прав
группы. Это тезис-мост к алгоритму проверки (раздел 2.2).
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="1" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# Для файлов и каталогов права читаются по-разному

<div class="t-table text-xs mt-2">

| Право | Файлы | Каталоги |
|:---:|---|---|
| `r` | разрешает открытие и чтение файла (в т.ч. копирование — содержимое нужно прочитать) | разрешает получить **список имён** файлов каталога; содержимое и метаданные файлов требуют ещё `x` |
| `w` | разрешает запись в файл и его усечение; **не** даёт права переименовать или удалить файл | разрешает создание, удаление и переименование файлов в каталоге — **только вместе с** `x` |
| `x` | позволяет исполнить файл как программу | разрешает «проход» через каталог (`cd`), доступ к метаданным его файлов; также называется правом **поиска** (search) |

</div>

<div class="grid grid-cols-2 gap-3 mt-3">
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Удаление файла — операция над каталогом.</b> Право <code>w</code> на сам
файл не требуется: достаточно <code>w</code> и <code>x</code> на каталог,
который хранит имя файла.
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Путь проверяется целиком.</b> Для доступа к <code>/home/bob/file.txt</code>
нужно право <code>x</code> на <code>/</code>, <code>/home</code> и
<code>/home/bob</code>; для относительного пути — только на каталоги,
входящие в него.
</div>
</div>

<Refs ids="nemeth shotts kerrisk-tlpi rh-dac" />

<!--
Таблица интерпретации прав. Два следствия, которые чаще всего удивляют:
удаление файла регулируется правами каталога, а не файла; и право x
требуется на каждый компонент пути — в ядре это отдельная проверка при
разрешении пути (увидим в разделе 3.4, функция may_lookup). Для
относительного пути проверяются только каталоги, явно или неявно входящие
в путь: находясь в /home/bob/sub1 и обращаясь к ../sub2/f, нужны права на
/home/bob и /home/bob/sub2, но не на / и /home.
-->

---

# Демо 01: бинарному файлу достаточно x

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/01-file-perms.txt" section="1" title="bob@srv · ELF без права чтения" fontSize="0.55rem">
  <TCallout :line="2" :col="3" :span="10" :n="1" />
  <TCallout :line="5" :col="1" :span="12" :n="2" />
  <TCallout :line="8" :col="1" :span="25" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> копии <code>/bin/ls</code> оставлены только биты исполнения: режим <code>0111</code></div>
<div><span class="co-ball">2</span> запуск бинарного файла ELF выполняется успешно — право <code>r</code> для этого не требуется</div>
<div><span class="co-ball">3</span> прочитать тот же файл нельзя: загрузку кода выполняет ядро при <code>execve(2)</code>, а не процесс пользователя</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Копия названа <code>ls</code>, а не <code>ls-copy</code>: coreutils
Ubuntu 26.04 — единый multi-call бинарный файл, выбирающий программу
по <code>argv[0]</code>.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/01-file-perms.sh</div>

<Refs ids="man-execve kerrisk-tlpi" />

<!--
Право x без r для ELF: исполнение выполняется успешно, чтение — нет. Причина:
код загружает ядро в ходе execve, процессу пользователя дескриптор файла не
выдаётся. Деталь про multi-call binary объяснить устно: /bin/ls в Ubuntu
26.04 — тонкая обёртка над единым coreutils, который диспетчеризуется по
argv[0]; переименованная копия отвечает «unknown program», поэтому копия в
демонстрации сохраняет имя ls.
-->

---

# Демо 01: скрипту нужны и r, и x

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/01-file-perms.txt" section="2" title="bob@srv · скрипты: bash и python" fontSize="0.5rem">
  <TCallout :line="4" :col="1" :span="31" :n="1" />
  <TCallout :line="6" :col="1" :span="9" :n="2" />
  <TCallout :line="14" :col="1" :rows="3" :span="40" :n="3" />
  <TCallout :line="20" :col="1" :span="18" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> скрипт с режимом <code>0111</code> не исполняется: интерпретатору нужно <b>прочитать</b> текст программы</div>
<div><span class="co-ball">2</span> после <code>chmod 0555</code> (чтение + исполнение) запуск успешен — даже без шебанга: bash исполняет такой файл сам</div>
<div><span class="co-ball">3</span> python-код без шебанга достаётся тому же bash — синтаксические ошибки</div>
<div><span class="co-ball">4</span> первая строка-<b>шебанг</b> <code>#!/usr/bin/python3</code> указывает ядру интерпретатор — запуск успешен</div>
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/01-file-perms.sh</div>

<Refs ids="man-execve kerrisk-tlpi" />

<!--
Скрипт — текстовый файл: право x разрешает execve, но затем интерпретатор
открывает файл на чтение обычным open — требуется r. Отличие от ELF
принципиально и позже объяснит, почему setuid на скриптах игнорируется
(раздел 2.3) и почему при ACL права r и x могут быть выданы разными
правилами (раздел 7.2). Шебанг обрабатывает ядро в sys_execve: извлекает
путь интерпретатора и перезапускает execve для него.
-->

---

# Демо 02: r и x на каталоге действуют совместно

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-dir-perms.txt" section="1" title="bob@srv · r без x" fontSize="0.5rem">
  <TCallout :line="8" :col="1" :span="10" :n="1" />
  <TCallout :line="11" :col="1" :span="26" :n="2" />
  <TCallout :line="15" :col="1" :span="31" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/02-dir-perms.txt" section="2" title="bob@srv · x без r" fontSize="0.5rem" padBottom="0.4em">
  <TCallout :line="5" :col="1" :span="10" :n="4" />
  <TCallout :line="7" :col="1" :span="45" :n="5" />
  <TCallout :line="9" :col="1" :span="6" :n="6" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> режим <code>0400</code>: только чтение каталога</div>
<div><span class="co-ball">2</span> имена видны, метаданные (inode) недоступны — знаки <code>?</code></div>
<div><span class="co-ball">3</span> содержимое файла недоступно даже при правах на сам файл</div>
<div><span class="co-ball">4</span> режим <code>0100</code>: только «проход»</div>
<div><span class="co-ball">5</span> список имён получить нельзя</div>
<div><span class="co-ball">6</span> доступ по известному имени работает</div>
</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/02-dir-perms.sh</div>

<Refs ids="kerrisk-tlpi shotts" />

<!--
Каталог — «файл-список»: r даёт чтение списка имён, x — проход к inode
файлов. По отдельности права дают два несимметричных режима: r без x —
видны имена, но ни метаданные, ни содержимое недоступны (ls показывает
знаки вопроса); x без r — имена перечислить нельзя, но файл с известным
именем полностью доступен. Второй режим применяют для общедоступных
каталогов, где содержимое выдаётся только знающим имя файла.
-->

---

# Демо 02: запись в каталог требует права прохода

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/02-dir-perms.txt" section="3" title="bob@srv · w без x и w с x" fontSize="0.5rem">
  <TCallout :line="5" :col="1" :span="10" :n="1" />
  <TCallout :line="6" :col="1" :rows="8" :span="43" :n="2" />
  <TCallout :line="15" :col="1" :rows="6" :span="30" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> каталогу оставлено только право записи: <code>d-w-------</code></div>
<div><span class="co-ball">2</span> создание, копирование, переименование и удаление завершаются отказом: операции записи в каталог требуют доступа к метаданным, то есть права <code>x</code></div>
<div><span class="co-ball">3</span> при <code>0700</code> те же операции выполняются успешно</div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> право <code>w</code> на каталог действует только в сочетании
с <code>x</code>; право <code>w</code> на сам файл не участвует
в операциях создания, переименования и удаления.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/02-dir-perms.sh</div>

<Refs ids="kerrisk-tlpi nemeth" />

<!--
Право w на каталог без x бесполезно: любая операция изменения списка файлов
обращается к метаданным и требует права прохода. В ядре это видно по флагам
проверки MAY_WRITE | MAY_EXEC в may_create и may_delete — покажем в разделе
3.3. Повторить тезис о том, что rm/mv регулируются каталогом, а не файлом.
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="2" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# Проверка прав: первое подходящее правило решает

Ядро проверяет права при каждом системном вызове, получающем **путь** к файлу;
в проверках участвуют идентификаторы процесса (эффективные UID и GID, список
дополнительных групп — лекция 2).

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-3 items-start">
<div>

1. Процесс **привилегирован** (эффективный UID 0 или соответствующие
   capabilities) → полный доступ.
2. Эффективный UID процесса **равен UID владельца** файла → действует
   **первый** триплет.
3. Эффективный GID или любая дополнительная группа процесса **совпадает
   с группой** файла → действует **второй** триплет.
4. Иначе → действует **третий** триплет (остальные).

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Проверки выполняются <b>по порядку и прекращаются</b> на первом подходящем
правиле. Если права группы шире прав владельца, владелец получит
<b>меньше</b> прав, чем участники группы, — правило владельца уже выбрано.
</div>

</div>
<div>

<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Проверка выполняется при открытии.</b> Получив дескриптор через
<code>open()</code>, последующие <code>read()</code>, <code>write()</code>,
<code>mmap()</code> по этому дескриптору <b>права не проверяют</b> —
изменение режима файла на открытый дескриптор не действует.
</div>

<v-click>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
В ядре проверка привилегированности выполняется <b>после</b> обычных
проверок — чтобы не вычислять capabilities, когда доступ и так разрешён
(раздел 3.2, <code>generic_permission</code>).
</div>

</v-click>

</div>
</div>

<Refs ids="kerrisk-tlpi man-open" />

<!--
Алгоритм по Керриску, р. 15.4.3. Два важных следствия. Первое: порядок
строгий, правило выбирается одно — триплеты не объединяются; парадокс
«владелец с меньшими правами, чем группа» реален. Второе: проверка
привязана к open; выданный дескриптор не перепроверяется — отсюда классы
атак TOCTOU и практика передачи дескрипторов. Замечание о порядке проверки
привилегий — оптимизация в ядре, подтвердим кодом generic_permission.
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="3" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# setuid: процесс получает UID владельца файла

Бит **setuid** (`04000`, SUID) выполняет единственную функцию: исполняемый
файл запускается с **эффективным UID владельца файла**, кто бы его ни запустил.

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/03-setuid.txt" section="1" title="bob@srv · setuid-root в /usr/bin" fontSize="0.55rem">
  <TCallout :line="8" :col="4" :span="1" :n="1" />
  <TCallout :line="4" :col="14" :span="4" :n="2" />
</TerminalCapture>

</div>
<div>

- в выводе `ls` setuid показан символом **`s`** вместо `x` в первом
  триплете <span class="co-ball">1</span>;
- заглавная **`S`** означает: setuid установлен, а права `x` у владельца
  **нет**;
- файлы с владельцем `root` <span class="co-ball">2</span> называют
  **setuid-root**: их запуск даёт процесс с эффективным UID 0.

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Так обычный пользователь меняет собственный пароль: <code>passwd</code> —
setuid-root и потому может записать «чужой» для него файл
<code>/etc/shadow</code> (лекция 2).
</div>

<div class="mt-2 p-2 border-l-4 border-red-500 bg-red-500/10 text-xs">
Каждая setuid-root программа — часть <b>поверхности атаки</b>: ошибка в ней
исполняется с привилегиями суперпользователя.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/03-setuid.sh</div>

<Refs ids="rh-suid kerrisk-tlpi" />

<!--
Определение setuid и нотация s/S. Список setuid-root программ базовой
системы — su, mount/umount, passwd, chsh/chfn, gpasswd, sudo: у каждой
есть законная причина работать с euid 0. Связка с лекцией 2: смена пароля
пользователем — запись в /etc/shadow, доступный только root. Красная
рамка — тезис о поверхности атаки: исторически значительная часть
локальных повышений привилегий — ошибки в setuid-программах.
-->

---

# Демо 03: эффективный UID следует за владельцем файла

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/03-setuid.txt" section="2" title="bob@srv · без setuid" fontSize="0.5rem" />

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Программа <code>userinfo.c</code> печатает <code>getuid()</code> и
<code>geteuid()</code> — реальный и эффективный UID процесса
(исходный код: <code>assets/src/userinfo.c</code>).
</div>

</div>
<div>

<TerminalCapture src="captures/03-setuid.txt" section="3" title="bob@srv · с setuid" fontSize="0.5rem" padBottom="0.4em">
  <TCallout :line="4" :col="1" :span="10" :n="1" />
  <TCallout :line="7" :col="36" :span="12" :n="2" />
  <TCallout :line="10" :col="36" :span="12" :n="3" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> файл передан пользователю <code>alice</code>, установлен setuid: <code>-rwsr-xr-x</code>&ensp;
<span class="co-ball">2</span> запуск от <code>bob</code>: реальный UID — <code>bob</code>, эффективный — <code>alice</code>&ensp;
<span class="co-ball">3</span> запуск от <code>carol</code>: эффективный UID снова <code>alice</code> — определяется владельцем файла, а не запускающим
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/03-setuid.sh · assets/src/userinfo.c</div>

<Refs ids="rh-suid kerrisk-tlpi" />

<!--
Слева контроль: без setuid реальный и эффективный UID совпадают с
запустившим. Справа эксперимент: после chown alice + chmod u+s эффективный
UID всегда alice — у процесса появляются права alice на время исполнения.
Механизм наследования идентификаторов при execve разобран в лекции 2
(раздел 2.4): euid перезаписывается UID владельца файла при установленном
setuid, сохранённый UID получает копию нового euid.
-->

---

# Демо 03: заглавная S — setuid без права исполнения

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/03-setuid.txt" section="4" title="bob@srv · бит s при снятом x владельца" fontSize="0.55rem">
  <TCallout :line="3" :col="4" :span="1" :n="1" />
  <TCallout :line="5" :col="1" :span="50" :n="2" />
  <TCallout :line="8" :col="36" :span="12" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> <code>ls</code> показывает <code>S</code>: setuid есть, права исполнения у владельца нет</div>
<div><span class="co-ball">2</span> владелец <code>alice</code> запустить файл <b>не может</b> — в её триплете нет <code>x</code></div>
<div><span class="co-ball">3</span> остальные запускают файл по своим триплетам, и эффективным UID становится владелец <code>alice</code></div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Бит setuid и право исполнения — <b>независимые атрибуты</b>: setuid
определяет, <i>от чьего имени</i> исполнять, триплеты — <i>кому</i>
разрешён запуск.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/03-setuid.sh</div>

<Refs ids="rh-suid" />

<!--
Любопытный угловой случай: setuid установлен, а права x у владельца нет.
Владелец запустить файл не может (его собственный триплет запрещает), а
прочие пользователи могут — и получают эффективный UID владельца. Вывод в
голубой рамке: два ортогональных вопроса — кому разрешён запуск (триплеты)
и от чьего имени он выполняется (setuid).
-->

---

# setuid на скриптах игнорируется

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/03-setuid.txt" section="5" title="bob@srv · setuid-скрипт" fontSize="0.55rem">
  <TCallout :line="9" :col="4" :span="1" :n="1" />
  <TCallout :line="11" :col="1" :span="13" :n="2" />
</TerminalCapture>

</div>
<div>

<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1.5">
<div><span class="co-ball">1</span> скрипт принадлежит <code>alice</code>, бит <code>s</code> установлен</div>
<div><span class="co-ball">2</span> тем не менее <code>id</code> показывает <code>uid=1001(bob)</code> — эффективный UID <b>не изменился</b></div>
</div>
</div>

<div class="mt-3 p-3 border-l-4 border-red-500 bg-red-500/10">
Для скриптов (файлов с шебангом) ядро Linux <b>игнорирует</b> setuid- и
setgid-биты: исполнение скрипта — это два разнесённых во времени действия,
<code>execve(2)</code> интерпретатора и чтение файла, — и между ними файл
можно подменить.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/03-setuid.sh</div>

<Refs ids="unix-se-setuid kerrisk-tlpi man-execve" />

<!--
Setuid-скрипты запрещены со времён классических атак на Unix: между execve,
который поднимает привилегии, и открытием скрипта интерпретатором файл по
тому же пути может быть подменён (гонка, вариант TOCTOU). Поэтому ядро
просто не применяет setuid к файлам с шебангом. Механика двухшагового
исполнения скриптов подробно разобрана в разделе 7.2 на исходном коде bash.
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="4" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# setgid: группа файла вместо группы запустившего

Бит **setgid** (`02000`, SGID) в выводе `ls` занимает позицию `x` **второго**
триплета и выполняет три функции:

<div class="grid grid-cols-[1fr_1.15fr] gap-4 mt-2 items-start">
<div>

1. на исполняемом файле — процесс получает **эффективный GID группы
   владельцев** файла (аналогично setuid);
2. на каталоге — новые файлы наследуют **группу каталога**,
   а не первичную группу создателя;
3. на неисполняемом файле — включает принудительную блокировку
   (mandatory locking; исторический режим).

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> файл передан группе <code>carol</code>,
бит установлен: <code>-rwxr-sr-x</code>&ensp;
<span class="co-ball">2</span> у процесса <code>bob</code> эффективный
GID — <code>carol</code>, от какого бы пользователя ни шёл запуск
</div>

</div>
<div>

<TerminalCapture src="captures/04-setgid.txt" section="2" title="bob@srv · setgid на исполняемом файле" fontSize="0.5rem">
  <TCallout :line="4" :col="7" :span="1" :n="1" />
  <TCallout :line="7" :col="38" :span="12" :n="2" />
</TerminalCapture>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/04-setgid.sh · assets/src/groupinfo.c</div>

<Refs ids="rh-suid kerrisk-tlpi" />

<!--
Симметричный setuid механизм для групп. Программа groupinfo печатает
getgid/getegid. Функция 3 — принудительная блокировка файлов (setgid без
группового x) — историческая, упоминаем для полноты по Керриску, р. 51.4.
Главная практическая функция сегодня — вторая: наследование группы каталога,
следующий слайд.
-->

---

# Демо 04: setgid на каталоге — общие файлы проекта

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/04-setgid.txt" section="3" title="bob@srv · наследование группы каталога" fontSize="0.55rem">
  <TCallout :line="5" :col="7" :span="1" :n="1" />
  <TCallout :line="11" :col="20" :span="5" :n="2" />
  <TCallout :line="12" :col="20" :span="5" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> каталог <code>shared</code>: группа <code>carol</code>, режим <code>2775</code> (<code>drwxrwsr-x</code>)</div>
<div><span class="co-ball">2</span> файл, созданный <code>bob</code>, получает группу <b>каталога</b> — <code>carol</code>, а не первичную группу создателя</div>
<div><span class="co-ball">3</span> файл от <code>carol</code> — та же группа</div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> setgid-каталог + групповое право записи — классический
способ организовать общий каталог проекта: все созданные файлы
принадлежат группе команды и доступны её участникам по второму триплету.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/04-setgid.sh</div>

<Refs ids="rh-suid nemeth" />

<!--
Польза setgid-каталога: без него каждый файл получает первичную группу
создателя, и коллеги по проекту не попадают во второй триплет. С setgid
группа наследуется от каталога — права группы работают предсказуемо для
всей команды. Ограничение подхода — одна группа на каталог; более гибкое
решение дадут ACL-списки по умолчанию (раздел 7.4).
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="5" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# sticky-бит: удалять чужое в общем каталоге нельзя

Бит **sticky** (`01000`, символ `t` в третьем триплете) на каталоге означает:
непривилегированный пользователь удаляет и переименовывает только **свои**
файлы — даже имея право `w` на каталог.

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/05-sticky.txt" section="2" title="bob@srv · каталог без sticky" fontSize="0.5rem">
  <TCallout :line="8" :col="14" :span="5" :n="1" />
  <TCallout :line="11" :col="1" :span="31" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/05-sticky.txt" section="3" title="bob@srv · /tmp со sticky (drwxrwxrwt)" fontSize="0.5rem" padBottom="0.4em">
  <TCallout :line="4" :col="14" :span="5" :n="3" />
  <TCallout :line="6" :col="1" :span="52" :n="4" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span><span class="co-ball">2</span> в собственном каталоге <code>bob</code> удаляет файл <code>alice</code> свободно</div>
<div><span class="co-ball">3</span><span class="co-ball">4</span> в <code>/tmp</code> (<code>drwxrwxrwt</code>) файл <code>alice</code> удалить нельзя: <code>Operation not permitted</code></div>
</div>
</div>

</div>
</div>

<v-click>

<HistoryNote class="mt-2 text-xs">
Изначально sticky-бит «закреплял» код часто используемых программ в области
подкачки для быстрого запуска — отсюда название. Для файлов современный
Linux его игнорирует; осталась только семантика защиты от удаления
на каталогах.
</HistoryNote>

</v-click>

<div class="text-xs opacity-70 mt-2">См. assets/demos/05-sticky.sh</div>

<Refs ids="kerrisk-tlpi rh-suid" />

<!--
Мотивация: общий каталог /tmp с правами записи для всех. Без sticky право w
на каталог позволяет удалить любой файл (операция над каталогом, слайд 2.1).
Sticky добавляет условие: удаление и переименование — только владельцу файла,
владельцу каталога или root. Слева контрольный случай: в каталоге без sticky
bob удаляет файл alice. Справа: /tmp — rm отвечает Operation not permitted.
Историческая справка о названии — в рамке.
-->

---
layout: section
---

# 2. Классическая модель Unix

<SectionTOC prefix="2" :current="6" :items="[
  'Права файлов и каталогов',
  'Алгоритм проверки прав',
  'Бит setuid',
  'Бит setgid',
  'sticky-бит',
  'Маска umask',
]" />

---

# umask: маска всегда отключаемых прав

Права нового файла задаёт аргумент `mode` вызова `open()`/`mkdir()`,
**ослабленный** маской процесса: `mode & ~umask`. Маска наследуется
от родительской оболочки и управляется утилитой `umask`.

<div class="grid grid-cols-[1.1fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/06-umask.txt" section="1" title="bob@srv · umask 022 и 077" fontSize="0.5rem">
  <TCallout :line="2" :col="1" :span="4" :n="1" />
  <TCallout :line="8" :col="1" :span="10" :n="2" />
  <TCallout :line="19" :col="1" :span="10" :n="3" />
</TerminalCapture>

</div>
<div>

<div class="t-table text-xs">

| Вызов | Аргумент mode | Итог при umask 022 |
|---|---|---|
| `open()` | `0666` | `0644` — `rw-r--r--` |
| `mkdir()` | `0777` | `0755` — `rwxr-xr-x` |

</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> маска <code>022</code>: группе и остальным всегда снимается право записи</div>
<div><span class="co-ball">2</span> файл создан с <code>0644</code> = <code>0666 &amp; ~022</code></div>
<div><span class="co-ball">3</span> при <code>umask 077</code> новый файл — <code>0600</code>: доступ только владельцу</div>
</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Маска <b>только снимает</b> биты — добавить права она не может. Значение
зависит от конфигурации: в демонстрационном контейнере bash задаёт
<code>022</code>; login-сеансы Ubuntu с «личными» группами используют
<code>002</code>.
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/06-umask.sh</div>

<Refs ids="kerrisk-tlpi man-chmod" />

<!--
umask — атрибут процесса: какие биты прав всегда отключать при создании
файлов и каталогов. Стандартные mode: 0666 для open, 0777 для mkdir;
итоговые права — поразрядное И с инверсией маски. Подчеркнуть
направленность: маска запрещающая. Область применимости значения по
умолчанию: 022 — классика (и наш контейнер), 002 — login-сеансы Ubuntu,
где у каждого пользователя личная группа. В разделе 7.4 увидим, что при
наличии ACL-списка по умолчанию umask при создании не используется.
-->

---
layout: section
---

# 3. Реализация в ядре Linux

<SectionTOC prefix="3" :current="1" :items="[
  'Хранение: структура inode',
  'Проверка триплетов прав',
  'Удаление и создание файла',
  'Открытие файла',
]" />

---

# Единая таблица прав не подходит файловой системе

Казалось бы, права можно хранить одной таблицей «объекты × субъекты».
Такое решение не выдерживает трёх практических возражений:

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-2 items-start">
<div>

1. **Масштаб и стоимость поиска.** Файлов — миллионы (см. счётчик inode
   справа); каждая проверка прав требовала бы поиска по таблице, тогда как
   запросы вида «все файлы пользователя» редки.
2. **Единая точка отказа.** Повреждение одного файла-таблицы уничтожает
   важнейшие метаданные всей файловой системы.
3. **Монтирование.** Иерархия Linux собирается из нескольких файловых
   систем, точки монтирования меняются — абсолютный путь не может служить
   идентификатором файла в таблице.

<div class="mt-2 p-3 border-l-4 border-teal-500 bg-teal-500/10">
Поэтому атрибуты доступа хранятся <b>рядом с каждым файлом</b> — в структуре
метаданных <b>inode</b>, вместе с размером, временными метками и счётчиком
ссылок.
</div>

</div>
<div>

<TerminalCapture src="captures/07-inodes.txt" title="сервер · счётчик inode корневой ФС" fontSize="0.52rem" />

<v-click>

<HistoryNote class="mt-3 text-xs">
Контрпример существует: NTFS хранит метаданные в единой Master File Table
(<code>$MFT</code>). Однако Windows не строит единой иерархии — экземпляры
NTFS монтируются отдельными томами, и модель доступа там иная.
</HistoryNote>

</v-click>

</div>
</div>

<Refs ids="kerrisk-tlpi nemeth" />

<!--
Мысленный эксперимент с таблицей «объекты × субъекты» и три возражения:
стоимость поиска при миллионах inode (на учебном сервере занято более
четырёх миллионов), единая точка отказа, и невозможность адресовать файл
путём при переменных точках монтирования. Историческая рамка: NTFS с её
MFT — реальная система с табличным хранением, но без единой иерархии
монтирования. Вывод: метаданные хранятся по-файлово в inode.
-->

---

# VFS: права и владельцы лежат в структуре inode

Детали конкретных файловых систем (ext4, btrfs, FAT, …) скрыты за единым
интерфейсом — **виртуальной файловой системой** (VFS). Базовые метаданные
любого файла VFS хранит в структуре `inode`:

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

```c
struct inode {
    umode_t             i_mode;        /* 1 */
    unsigned short      i_opflags;
    kuid_t              i_uid;         /* 2 */
    kgid_t              i_gid;         /* 2 */
    unsigned int        i_flags;       /* 4 */

#ifdef CONFIG_FS_POSIX_ACL
    struct posix_acl    *i_acl;        /* 3 */
    struct posix_acl    *i_default_acl;
#endif
    ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/fs.h#L793">include/linux/fs.h#L793</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/include/linux/uidgid_types.h#L7">uidgid_types.h#L7</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>i_mode</code> — 16-битное поле (<code>unsigned short</code>): тип файла, специальные биты и триплеты прав</div>
<div><span class="co-ball">2</span> <code>i_uid</code>, <code>i_gid</code> — 32-битные идентификаторы владельца и группы (обёртки <code>kuid_t</code>/<code>kgid_t</code> над <code>uid_t</code>/<code>gid_t</code>)</div>
<div><span class="co-ball">3</span> указатели на ACL-списки — уже в базовой структуре (раздел 7)</div>
<div><span class="co-ball">4</span> <code>i_flags</code> — в т.ч. дополнительные атрибуты файла (раздел 5)</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Специфические метаданные конкретной ФС инкапсулируются рядом — в структуре
<code>{fstype}_inode</code>, ссылающейся на общий <code>inode</code> VFS.
</div>

</div>
</div>

<Refs ids="linux-kernel kerrisk-tlpi" />

<!--
VFS унифицирует работу с десятками файловых систем; inode — центральная
структура метаданных. Для нашей темы важны три группы полей: i_mode
(права и тип), i_uid/i_gid (владельцы), и — забегая вперёд — указатели
на posix_acl и флаги i_flags: оба «дополнительных» механизма лекции уже
присутствуют в базовой структуре ядра. Это удобная карта всей лекции в
одной структуре.
-->

---

# i_mode: шестнадцать битов на тип и права

```c
#define S_IFMT  00170000   /* 1 — маска типа файла */
#define S_IFSOCK 0140000   /* сокет        */  #define S_IFREG  0100000   /* обычный файл */
#define S_IFLNK  0120000   /* симв. ссылка */  #define S_IFDIR  0040000   /* каталог      */
#define S_IFBLK  0060000   /* блочное устр.*/  #define S_IFCHR  0020000   /* символьное   */
#define S_ISUID  0004000   /* 2 — setuid */
#define S_ISGID  0002000   /* 2 — setgid */
#define S_ISVTX  0001000   /* 2 — sticky (saved text — историческое имя) */

#define S_IRWXU 00700      /* 3 — триплет владельца: S_IRUSR | S_IWUSR | S_IXUSR */
#define S_IRWXG 00070      /* 3 — триплет группы    */
#define S_IRWXO 00007      /* 3 — триплет остальных */
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/include/uapi/linux/stat.h#L9">include/uapi/linux/stat.h#L9</a>
</div>

<div class="grid grid-cols-3 gap-3 mt-2 text-xs">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">1</span> старшие 4 бита — <b>тип файла</b>; макросы
<code>S_ISREG(m)</code>, <code>S_ISDIR(m)</code> сравнивают
<code>m&nbsp;&amp;&nbsp;S_IFMT</code> с константой
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">2</span> три специальных бита — восьмеричные
<code>04000</code>, <code>02000</code>, <code>01000</code>: те самые
«4», «2», «1» первой цифры <code>chmod 4755</code>
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
<span class="co-ball">3</span> девять младших битов — триплеты прав;
восьмеричная запись режима читается прямо из определений
</div>
</div>

<Refs ids="linux-kernel" />

<!--
Раскладка i_mode повторяет то, что студенты уже видели в выводе ls, но в
битах: тип файла, специальные биты, три триплета. Обратить внимание на
имя S_ISVTX — «saved text», след исторического назначения sticky-бита.
Восьмеричные константы объясняют цифровую форму chmod: 4755 = setuid +
rwxr-xr-x.
-->

---
layout: section
---

# 3. Реализация в ядре Linux

<SectionTOC prefix="3" :current="2" :items="[
  'Хранение: структура inode',
  'Проверка триплетов прав',
  'Удаление и создание файла',
  'Открытие файла',
]" />

---

# generic_permission: триплеты прежде привилегий

Для файловых систем без собственной функции проверки ядро вызывает общую
`generic_permission()`:

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

```c
int generic_permission(struct mnt_idmap *idmap,
                       struct inode *inode, int mask)
{
    int ret;

    /* Do the basic permission checks. */
    ret = acl_permission_check(idmap, inode, mask);  /* 1 */
    if (ret != -EACCES)
        return ret;

    if (S_ISDIR(inode->i_mode)) {
        /* DACs are overridable for directories */
        if (!(mask & MAY_WRITE))
            if (capable_wrt_inode_uidgid(idmap, inode,
                         CAP_DAC_READ_SEARCH))        /* 2 */
                return 0;
        if (capable_wrt_inode_uidgid(idmap, inode,
                         CAP_DAC_OVERRIDE))           /* 2 */
            return 0;
        return -EACCES;
    }
    ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L464">fs/namei.c#L464</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> сначала — проверка триплетов и ACL в <code>acl_permission_check</code></div>
<div><span class="co-ball">2</span> и только при отказе (<code>-EACCES</code>) — проверка привилегий: capability <code>CAP_DAC_OVERRIDE</code> («игнорировать DAC») или <code>CAP_DAC_READ_SEARCH</code> («читать и искать всюду»)</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Порядок — оптимизация: вычисление capabilities дороже, чем сравнение битов,
и не нужно, когда доступ разрешён триплетами. Это кодовое подтверждение
замечания из раздела 2.2.
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10">
«Полный доступ root» в ядре выражен точнее: не UID 0, а наличие
конкретных capabilities у процесса.
</div>

</div>
</div>

<Refs ids="linux-kernel man-capabilities" />

<style>
.slidev-code { font-size: 0.6rem !important; line-height: 1.3 !important; }
</style>

<!--
generic_permission — общая проверка POSIX-подобной ФС. Две идеи. Первая:
триплеты проверяются первыми, привилегии — только при отказе (оптимизация).
Вторая: «привилегированность» в ядре гранулярна — это capabilities
CAP_DAC_OVERRIDE и CAP_DAC_READ_SEARCH, а не сравнение euid с нулём;
подробно о capabilities — в следующей лекции.
-->

---

# acl_permission_check: владелец → группа → остальные

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

```c
static int acl_permission_check(struct mnt_idmap *idmap,
                                struct inode *inode, int mask)
{
    unsigned int mode = inode->i_mode;
    vfsuid_t vfsuid;

    /* Common cheap case: everybody has the requested rights */
    if (!((mask & 7) * 0111 & ~mode)) {               /* 1 */
        if (no_acl_inode(inode))
            return 0;
        ...
    }
    /* Are we the owner? If so, ACL's don't matter */
    vfsuid = i_uid_into_vfsuid(idmap, inode);
    if (likely(vfsuid_eq_kuid(vfsuid, current_fsuid()))) { /* 2 */
        mask &= 7;
        mode >>= 6;                                   /* 3 */
        return (mask & ~mode) ? -EACCES : 0;
    }
    /* Do we have ACL's? */ ...
    if (mask & (mode ^ (mode >> 3))) {                /* 4 */
        vfsgid_t vfsgid = i_gid_into_vfsgid(idmap, inode);
        if (vfsgid_in_group_p(vfsgid))
            mode >>= 3;                               /* 5 */
    }
    /* Bits in 'mode' clear that we require? */
    return (mask & ~mode) ? -EACCES : 0;              /* 6 */
}
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L381">fs/namei.c#L381</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> быстрый путь: если запрошенные биты установлены во <b>всех</b> триплетах, владельца и группу можно не выяснять</div>
<div><span class="co-ball">2</span> проверка владельца — сравнение с <code>current_fsuid()</code>: в проверках файловых прав используется <b>FSUID</b> процесса (в обычных процессах равен эффективному UID)</div>
<div><span class="co-ball">3</span> владелец совпал: первый триплет сдвигается на место младших битов, прочие правила <b>не рассматриваются</b></div>
<div><span class="co-ball">4</span> если права группы отличаются от прав остальных — ищем группу файла в списке групп процесса</div>
<div><span class="co-ball">5</span> группа найдена: второй триплет перезаписывает третий</div>
<div><span class="co-ball">6</span> финальное сравнение по третьему (или подменённому) триплету</div>
</div>

</div>
</div>

<Refs ids="linux-kernel kerrisk-tlpi" />

<style>
/* Код не помещается при базовом размере — ужимаем (как в лекции 2). */
.slidev-code { font-size: 0.58rem !important; line-height: 1.3 !important; }
</style>

<!--
Сердце проверки. Алгоритм раздела 2.2 читается прямо из битовых операций:
быстрый путь (все триплеты дают права), затем владелец (mode >>= 6 — сдвиг
первого триплета), затем группа (mode >>= 3), затем остальные. Проверка
владельца завершает алгоритм независимо от результата — парадокс «владелец
с меньшими правами» виден в коде. FSUID — четвёртый идентификатор процесса
из лекции 2 (раздел 2.4): исторический атрибут для файловых серверов, в
обычных процессах синхронизирован с euid. Вызовы check_acl для ACL-правил
пропущены — вернёмся в разделе 7.
-->

---
layout: section
---

# 3. Реализация в ядре Linux

<SectionTOC prefix="3" :current="3" :items="[
  'Хранение: структура inode',
  'Проверка триплетов прав',
  'Удаление и создание файла',
  'Открытие файла',
]" />

---

# Удаление файла: may_delete проверяет каталог

Напомним (раздел 2.1): для удаления нужны `w` и `x` **на каталог**. Проверки
удаления собраны в `may_delete()`, которую вызывает `vfs_unlink()`:

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

```c
static int may_delete(struct mnt_idmap *idmap, struct inode *dir,
                      struct dentry *victim, bool isdir)
{
    struct inode *inode = d_backing_inode(victim);
    ...
    audit_inode_child(dir, victim, AUDIT_TYPE_CHILD_DELETE);

    error = inode_permission(idmap, dir,
                             MAY_WRITE | MAY_EXEC);   /* 1 */
    if (error)
        return error;
    if (IS_APPEND(dir))                               /* 3 */
        return -EPERM;

    if (check_sticky(idmap, dir, inode) ||            /* 2 */
        IS_APPEND(inode) || IS_IMMUTABLE(inode) ||    /* 3 */
        IS_SWAPFILE(inode) || HAS_UNMAPPED_ID(idmap, inode))
        return -EPERM;
    ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L3255">fs/namei.c#L3255</a> ·
вызов: <a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L4650">vfs_unlink, fs/namei.c#L4650</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> триплеты: права <code>MAY_WRITE | MAY_EXEC</code> проверяются на <b>каталоге</b> <code>dir</code> — вызов доходит до <code>acl_permission_check</code> (предыдущий слайд)</div>
<div><span class="co-ball">2</span> <code>check_sticky()</code> — тот самый sticky-бит: не владелец файла и не владелец каталога → отказ</div>
<div><span class="co-ball">3</span> <code>IS_APPEND</code>, <code>IS_IMMUTABLE</code> — проверки <b>дополнительных атрибутов</b> <code>a</code> и <code>i</code> (раздел 5): они дают <code>-EPERM</code> до всякого сравнения UID, поэтому действуют и на root</div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Один фрагмент кода собирает три механизма лекции: триплеты, sticky-бит
и дополнительные атрибуты файла.
</div>

</div>
</div>

<Refs ids="linux-kernel" />

<!--
may_delete — удачное место: здесь встречаются сразу три механизма. Проверка
прав записи и прохода выполняется на каталоге (не на файле!), затем
check_sticky, затем флаги inode: append-only и immutable возвращают EPERM
безусловно — вот почему атрибуты раздела 5 ограничивают даже root: проверка
вообще не смотрит на идентификаторы. Код между проверками сокращён.
-->

---

# Создание файла: may_create — те же права каталога

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

```c
int vfs_create(struct mnt_idmap *idmap, struct inode *dir,
               struct dentry *dentry, umode_t mode, bool want_excl)
{
    int error = may_create(idmap, dir, dentry);       /* 1 */
    if (error)
        return error;
    ...
    mode = vfs_prepare_mode(idmap, dir, mode,
                            S_IALLUGO, S_IFREG);      /* 3 */
    ...
}

static inline int may_create(struct mnt_idmap *idmap,
                             struct inode *dir, struct dentry *child)
{
    audit_inode_child(dir, child, AUDIT_TYPE_CHILD_CREATE);
    if (child->d_inode)
        return -EEXIST;
    if (IS_DEADDIR(dir))
        return -ENOENT;
    ...
    return inode_permission(idmap, dir,
                            MAY_WRITE | MAY_EXEC);    /* 2 */
}
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L3477">fs/namei.c#L3477</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L3307">fs/namei.c#L3307</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> создание начинается с проверки <code>may_create</code></div>
<div><span class="co-ball">2</span> и снова <code>MAY_WRITE | MAY_EXEC</code> на каталоге: создание симметрично удалению</div>
<div><span class="co-ball">3</span> здесь же режиму нового файла применяется <code>umask</code> процесса (раздел 2.6) — внутри <code>vfs_prepare_mode</code></div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Владелец нового файла — FSUID процесса; группа — FSGID либо, при
setgid-каталоге (раздел 2.4), группа каталога.
</div>

</div>
</div>

<Refs ids="linux-kernel" />

<!--
Создание зеркально удалению: may_create требует те же MAY_WRITE | MAY_EXEC
на каталог. Попутно видно, где применяется umask (vfs_prepare_mode) и как
назначаются владельцы нового файла — FSUID/FSGID процесса, а при
setgid-каталоге группа наследуется. Все нити раздела 2 сходятся в одном
месте кода.
-->

---
layout: section
---

# 3. Реализация в ядре Linux

<SectionTOC prefix="3" :current="4" :items="[
  'Хранение: структура inode',
  'Проверка триплетов прав',
  'Удаление и создание файла',
  'Открытие файла',
]" />

---

# Открытие файла: от системного вызова до may_open

Требуемые права зависят от режима открытия (`O_RDONLY`, `O_WRONLY`, …).
Запрос проходит цепочку функций ядра:

<div class="grid grid-cols-[1fr_1.15fr] gap-5 mt-2 items-start">
<div>

<div class="open-chain">
  <div class="bf-block"><div class="bf-head">open(), openat(), openat2()</div><div class="bf-sub">системные функции — user space</div></div>
  <div class="oc-sep">граница ядра</div>
  <div class="bf-block"><div class="bf-head">do_sys_openat2()</div><div class="bf-sub">флаги и режим → struct open_how</div></div>
  <div class="bf-block"><div class="bf-head">do_filp_open() → path_openat()</div><div class="bf-sub">разрешение пути: link_path_walk()</div></div>
  <div class="bf-block"><div class="bf-head">do_open() → may_open()</div><div class="bf-sub">проверки прав для режима открытия</div></div>
  <div class="bf-block bf-dark"><div class="bf-head">inode_permission()</div><div class="bf-sub">→ generic_permission() → acl_permission_check()</div></div>
</div>

</div>
<div>

```c
SYSCALL_DEFINE3(open, const char __user *, filename,
                int, flags, umode_t, mode)
{
    if (force_o_largefile())
        flags |= O_LARGEFILE;
    return do_sys_open(AT_FDCWD, filename,
                       flags, mode);
}
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/open.c#L1456">fs/open.c#L1456</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L4114">path_openat: fs/namei.c#L4114</a>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Если файл <b>создан</b> в ходе открытия (<code>O_CREAT</code>), проверка
прав на него не выполняется: биты <code>acc_mode</code> сбрасываются —
новый файл уже получил права <code>mode&nbsp;&amp;&nbsp;~umask</code>
и владельца по FSUID процесса.
</div>

</div>
</div>

<Refs ids="linux-kernel man-open" />

<style>
.open-chain { display: flex; flex-direction: column; gap: 0.35em; font-size: 0.72rem; text-align: center; }
.open-chain .bf-block { padding: 0.3em 0.5em; }
.oc-sep { font-size: 0.62rem; opacity: 0.6; border-top: 1px dashed currentColor; margin: 0.15em 1.5em; padding-top: 0.1em; }
</style>

<!--
Карта пути запроса: системные функции open/openat/openat2 — обёртки,
сходящиеся в do_sys_openat2; далее do_filp_open и path_openat, где
разрешается путь; do_open вызывает may_open — проверку прав для режима
открытия; низ цепочки — знакомая inode_permission. Правый фрагмент: сам
syscall тривиален. Голубая рамка — тонкость: созданный в ходе открытия
файл не проверяется (acc_mode = 0), права назначены при создании.
-->

---

# may_open: проверки зависят от типа файла

<div class="grid grid-cols-[1.35fr_1fr] gap-4 mt-1 items-start">
<div>

```c
static int may_open(struct mnt_idmap *idmap, const struct path *path,
                    int acc_mode, int flag)
{
    struct inode *inode = path->dentry->d_inode;
    ...
    switch (inode->i_mode & S_IFMT) {                 /* 1 */
    case S_IFLNK:
        return -ELOOP;
    case S_IFDIR:
        if (acc_mode & MAY_WRITE)
            return -EISDIR;
        ...
    case S_IFREG:
        if ((acc_mode & MAY_EXEC) && path_noexec(path)) /* 2 */
            return -EACCES;
        break;
    }

    error = inode_permission(idmap, inode,
                             MAY_OPEN | acc_mode);    /* 3 */
    if (error)
        return error;

    /* An append-only file must be opened in append mode */
    if (IS_APPEND(inode)) {                           /* 4 */
        if ((flag & O_ACCMODE) != O_RDONLY && !(flag & O_APPEND))
            return -EPERM;
        if (flag & O_TRUNC)
            return -EPERM;
    }
    ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L3527">fs/namei.c#L3527</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/exec.c#L115">path_noexec: fs/exec.c#L115</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> до проверки прав — проверки по <b>типу файла</b> (<code>i_mode &amp; S_IFMT</code>): ссылку открывать нельзя, каталог — только на чтение</div>
<div><span class="co-ball">2</span> <code>path_noexec()</code> — флаги монтирования: на ФС, смонтированной с <code>noexec</code>, исполнение запрещено независимо от триплетов</div>
<div><span class="co-ball">3</span> права режима открытия проверяет знакомая <code>inode_permission()</code></div>
<div><span class="co-ball">4</span> append-only файл (атрибут <code>a</code>, раздел 5) открывается на запись только с <code>O_APPEND</code> и без <code>O_TRUNC</code></div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Опции монтирования — ещё один слой разграничения: <code>noexec</code>,
<code>ro</code>, <code>nosuid</code> действуют на всю файловую систему.
</div>

</div>
</div>

<Refs ids="linux-kernel man-open" />

<style>
.slidev-code { font-size: 0.58rem !important; line-height: 1.3 !important; }
</style>

<!--
may_open: сначала тип файла, затем флаги монтирования (noexec), затем
триплеты через inode_permission, затем — снова дополнительные атрибуты:
append-only режим навязывает O_APPEND и запрещает O_TRUNC. Второе кодовое
свидетельство того, как атрибуты раздела 5 встроены в общий конвейер
проверок.
-->

---

# Право прохода проверяется на каждом компоненте пути

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-1 items-start">
<div>

```c
static int link_path_walk(const char *name, struct nameidata *nd)
{
    ...
    /* At this point we know we have a real path component. */
    for (;;) {                                        /* 1 */
        struct mnt_idmap *idmap = mnt_idmap(nd->path.mnt);
        err = may_lookup(idmap, nd);                  /* 2 */
        if (unlikely(err))
            return err;
        ...
    }
}

static inline int may_lookup(struct mnt_idmap *idmap,
                             struct nameidata *restrict nd)
{
    int err, mask;

    mask = nd->flags & LOOKUP_RCU ? MAY_NOT_BLOCK : 0;
    err = inode_permission(idmap, nd->inode,
                           mask | MAY_EXEC);          /* 3 */
    ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L2441">fs/namei.c#L2441</a> ·
<a href="https://github.com/torvalds/linux/blob/v6.18/fs/namei.c#L1852">may_lookup: fs/namei.c#L1852</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> <code>path_openat()</code> разрешает путь в цикле по компонентам</div>
<div><span class="co-ball">2</span> для каждого каталога пути вызывается <code>may_lookup()</code></div>
<div><span class="co-ball">3</span> которая требует <code>MAY_EXEC</code> — право «прохода» <code>x</code> на этот каталог</div>
</div>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10">
<b>Итого, открытие файла проверяет:</b>
<ul class="mt-1">
<li>право <code>x</code> на каждый каталог пути — <code>link_path_walk()</code>;</li>
<li>тип файла и флаги монтирования — <code>may_open()</code>;</li>
<li>триплеты (и ACL) для режима открытия — <code>inode_permission()</code>;</li>
<li>дополнительные атрибуты файла — <code>IS_APPEND</code>/<code>IS_IMMUTABLE</code>.</li>
</ul>
</div>

</div>
</div>

<Refs ids="linux-kernel" />

<!--
Замыкание раздела: правило «x на каждый компонент пути» из раздела 2.1 в
коде — цикл link_path_walk вызывает may_lookup с MAY_EXEC для каждого
каталога. Итоговая рамка собирает полный конвейер проверок открытия файла.
На этом реализация классической модели прослежена от бита в inode до
системного вызова.
-->

---
layout: section
---

# 4. Ограничения классической модели

---

# Три задачи, которые триплеты не решают

<div class="grid grid-cols-3 gap-3 mt-3">
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>1. Запретить изменение файла всем — включая root</b><br/><br/>
Снятие права <code>w</code> не действует на суперпользователя: результаты
проверок триплетов для него игнорируются. Средствами модели Unix запрет
для <code>root</code> невыразим.
</div>
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>2. Разрешить только дописывание (append-only)</b><br/><br/>
Журналы должны пополняться, но не редактироваться. Право <code>w</code>
неделимо: оно разрешает запись в <b>любое</b> место файла, включая
усечение.
</div>
<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>3. Запретить удаление, разрешив создание</b><br/><br/>
Создание и удаление файлов — одно и то же право <code>w</code> на каталог.
Разделить их (фиксировать набор файлов, разрешая редактирование
содержимого) триплетами нельзя.
</div>
</div>

<v-click>

<div class="mt-4 p-3 border-l-4 border-sky-500 bg-sky-500/10">
Мы уже видели в <code>may_delete()</code> и <code>may_open()</code>, чем
ядро отвечает на эти запросы: флагами <code>IS_IMMUTABLE</code> и
<code>IS_APPEND</code>, которые проверяются <b>до</b> сравнения
идентификаторов. Этот механизм — <b>дополнительные атрибуты файлов</b>,
раздел 5.
</div>

</v-click>

<Refs ids="tevault kerrisk-tlpi" />

<!--
Первая группа ограничений — три задачи целостности: защита от root,
append-only, запрет удаления при разрешённом создании. Все три упираются в
фундамент модели: root вне проверок, право w неделимо, создание и удаление
неразличимы. Отсылка назад к разделу 3: ядро уже показало нам ответ —
IS_IMMUTABLE и IS_APPEND в may_delete/may_open. Интрига раздела 5.
-->

---

# Триплетам не хватает выразительности

Три категории субъектов — владелец, одна группа, остальные — не описывают
реальные коллективы:

<div class="mt-3 space-y-2">
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>i.</b> Пользователю <code>alice</code> — чтение и запись, пользователю
<code>carol</code> — только чтение, прочим — ничего. <i>Второй именованный
пользователь не помещается в схему «владелец + группа + остальные».</i>
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>ii.</b> Файлы проекта: команде разработки <code>dev</code> — чтение и
запись, команде тестирования <code>qa</code> — только чтение. <i>Второй
триплет один — две группы с разными правами не выразить; использовать
<code>other</code> для <code>qa</code> означало бы открыть файлы всем.</i>
</div>
<div class="p-2 border-l-4 border-red-500 bg-red-500/10">
<b>iii.</b> Как в ii, но один тестировщик дополнительно получает запись в
<code>project/unittests/</code>. <i>Права отдельного участника поверх
групповых — за пределами модели.</i>
</div>
</div>

<v-click>

<div class="mt-3 p-3 border-l-4 border-sky-500 bg-sky-500/10">
Обходные приёмы (общие группы на каждое сочетание прав, копии файлов)
не масштабируются и размывают ответственность. Штатное решение —
<b>списки контроля доступа POSIX ACL</b>, раздел 7.
</div>

</v-click>

<Refs ids="kerrisk-tlpi" />

<!--
Вторая группа ограничений — выразительность. Три сценария нарастающей
сложности: второй именованный пользователь, вторая группа, точечные права
поверх групповых. Дать аудитории минуту подумать, почему триплетами нельзя
(вопросы в конспекте): для i нужно два «владельца», для ii второй триплет
один, для iii — комбинация обоих. Мост к разделу 7.
-->

---

# Смежные задачи: за границей разграничения доступа

<div class="grid grid-cols-3 gap-3 mt-3">
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Журналирование данных файла</b><br/><br/>
Журналирование ФС защищает целостность при сбоях, но включать его для всех
файлов дорого. Точечное включение для избранных файлов требует
отдельного флага.
</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Надёжное удаление</b><br/><br/>
ОС удаляет метаданные, а не содержимое: блоки данных остаются на устройстве
до перезаписи. Гарантированное уничтожение — отдельная задача
(и отдельная история — раздел 5.3).
</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10">
<b>Производительность метаданных</b><br/><br/>
Каждое чтение обновляет <code>atime</code> — лишние записи на устройство;
copy-on-write мешает базам данных. Нужны флаги «не обновлять atime»,
«без COW» для конкретных файлов.
</div>
</div>

<div class="mt-4 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Перечисленные задачи решаются не подсистемой разграничения доступа, однако
реализованы тем же механизмом дополнительных атрибутов (<code>j</code>,
<code>s</code>, <code>A</code>, <code>C</code>) и обязаны согласовываться
с действующими правилами доступа.
</div>

<Refs ids="kerrisk-tlpi tevault" />

<!--
Третья группа — задачи, формально не относящиеся к разграничению доступа:
точечное журналирование, надёжное удаление, оптимизация метаданных. Они
попали в лекцию потому, что реализованы тем же механизмом атрибутов файлов
и согласуются с политикой доступа. Честно разделять: это не «ещё права»,
а свойства хранения.
-->

---

# Карта расширений классической модели

<div class="t-table text-xs mt-3">

| Задача | Классическая модель | Решение | Раздел |
|---|:---:|---|:---:|
| Запрет изменения файла даже для root | — | атрибут `i` (immutable) | **5** |
| Только дописывание в журнал | — | атрибут `a` (append-only) | **5** |
| Запрет удаления при разрешённом создании | — | атрибуты `a`/`i` на каталоге | **5** |
| Журналирование, atime, COW, надёжное удаление | — | атрибуты `j`, `A`, `C`, `s` | **5** |
| Метаданные подсистем безопасности (метки, подписи) | — | расширенные атрибуты xattr | **6** |
| Права второму пользователю / второй группе | — | ACL: записи `ACL_USER`, `ACL_GROUP` | **7** |
| Умолчания для создаваемых файлов | `umask`, setgid-каталог | ACL по умолчанию | **7** |
| Исполнение от имени владельца файла | setuid/setgid | (capabilities — следующая лекция) | 2 |

</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Классическая модель остаётся <b>ядром</b> разграничения доступа; механизмы
разделов 5–7 — её расширения, каждое со своей областью применимости
и своими ограничениями.
</div>

<Refs ids="kerrisk-tlpi tevault" />

<!--
Дорожная карта второй половины лекции: каждая строка — задача из предыдущих
слайдов и механизм, который её закрывает. Подчеркнуть центральный тезис
лекции: не «замена» модели, а расширения вокруг неё; у каждого расширения —
своя область применимости и свои ограничения, которые мы будем называть
явно. Последняя строка — анонс capabilities в следующей лекции.
-->

---
layout: section
---

# 5. Дополнительные атрибуты файлов

<SectionTOC prefix="5" :current="1" :items="[
  'Атрибуты и управление ими',
  'Атрибуты i и a на практике',
  'Атрибут s: надёжное удаление',
]" />

---

# Linux file attributes: флаги особых режимов файла

**Дополнительные атрибуты файла** (Linux file attributes) — метаданные,
изменяющие поведение файловых операций: возможность изменения и удаления,
журналирование, обновление `atime` и др. Хранятся в поле `i_flags`
структуры `inode` — отдельно от прав доступа.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Терминологическая ловушка.</b> В литературе сосуществуют:
<ul class="mt-1">
<li>«атрибуты файла» — обычные метаданные (права, временные метки);</li>
<li><b>Linux file attributes</b> (<code>attr</code>) — флаги этого раздела;</li>
<li><b>extended attributes</b> (<code>xattr</code>) — самостоятельный
механизм «ключ–значение» (раздел 6).</li>
</ul>
</div>

</div>
<div>

<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Механизм — <b>нестандартное расширение ядра</b>: впервые появился в ext2;
поддерживается ext3/ext4, btrfs, XFS, JFS, ReiserFS, ZFS — набор доступных
атрибутов зависит от файловой системы.
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10">
Типичные применения: защита конфигураций и журналов от изменения
и удаления, управление форматом хранения (сжатие, COW), поведение
после удаления.
</div>

</div>
</div>

<Refs ids="kerrisk-tlpi nemeth fileattr-wiki tevault" />

<!--
Определение и главное предупреждение: три разных понятия с похожими именами.
Linux file attributes — флаги inode (i_flags, мы видели поле в разделе 3.1);
extended attributes — другой механизм, раздел 6. Механизм нестандартный:
вырос из ext2, покрытие и семантика слегка различаются между ФС — область
применимости каждого атрибута нужно проверять для своей ФС.
-->

---

# Базовый набор атрибутов

<div class="t-table text-xs mt-2">

| Флаг | Атрибут | Константа | Назначение |
|:---:|---|---|---|
| `i` | immutable | `FS_IMMUTABLE_FL` | файл нельзя изменить, переименовать или удалить |
| `a` | append only | `FS_APPEND_FL` | запись — только в конец файла |
| `u` | nounlink | — | нельзя удалить, редактирование разрешено (только ZFS) |
| `s` | secure deletion | `FS_SECRM_FL` | перезапись блоков нулями при удалении (раздел 5.3) |
| `j` | data journaling | `FS_JOURNAL_DATA_FL` | журналирование записей данных файла |
| `A` | no atime update | `FS_NOATIME_FL` | не обновлять время последнего доступа |
| `C` | no copy on write | `FS_NOCOW_FL` | отключить COW (btrfs) |
| `c` | compressed | `FS_COMPR_FL` | прозрачное сжатие (при поддержке ФС) |
| `d` | no dump | `FS_NODUMP_FL` | исключить из резервной копии `dump` |
| `S` | sync updates | `FS_SYNC_FL` | синхронная запись (аналог `mount -o sync`) |
| `D` | dirsync | `FS_DIRSYNC_FL` | синхронное обновление каталога |

</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Атрибуты каталога в основном <b>наследуются</b> создаваемыми в нём файлами;
исключения: <code>D</code> наследуют только подкаталоги, <code>i</code>
не наследуется вовсе — он запрещает само создание записей.
</div>

<Refs ids="man-chattr kerrisk-tlpi" />

<!--
Таблица базовых атрибутов. Для курса главные — верхние строки: i, a (и u в
ZFS) — задачи целостности из раздела 4; s — отдельная история в 5.3; j, A,
C — те самые смежные задачи хранения. Наследование: атрибуты каталога
переходят на новые файлы, кроме D (только подкаталоги) и i (immutable
каталог вообще запрещает новые записи).
-->

---

# Управление: lsattr, chattr и ioctl

<div class="grid grid-cols-[1.15fr_1fr] gap-4 mt-2 items-start">
<div>

Чтение и изменение — утилиты пакета `e2fsprogs`:

```console
$ lsattr file.conf
--------------e------- file.conf
$ sudo chattr +i file.conf    # установить
$ sudo chattr -i file.conf    # снять
$ sudo chattr =ae journal.log # задать ровно эти
```

Программный интерфейс — `ioctl(2)` с запросами `FS_IOC_GETFLAGS` /
`FS_IOC_SETFLAGS`:

```c
int get_flags(int fd, unsigned long *attr) {
    return ioctl(fd, FS_IOC_GETFLAGS, attr);
}
int set_flags(int fd, unsigned long attr) {
    return ioctl(fd, FS_IOC_SETFLAGS, &attr);
}
```

</div>
<div>

**Кто может изменять атрибуты:**

<div class="t-table text-xs mt-2">

| Атрибут | Требование |
|---|---|
| `i`, `a` | привилегированный процесс: capability `CAP_LINUX_IMMUTABLE` |
| остальные | FSUID процесса равен UID владельца файла |

</div>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Атрибут <code>e</code> (extents) в выводе <code>lsattr</code> на ext4
установлен у всех файлов — это признак формата хранения, а не защиты;
снять его нельзя.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Снять <code>i</code>/<code>a</code> может любой процесс с
<code>CAP_LINUX_IMMUTABLE</code> — по умолчанию им владеет root. Атрибуты
защищают от <b>ошибок и небрежности</b>, а не от компрометации
суперпользователя: это граница применимости механизма.
</div>

</div>
</div>

<Refs ids="man-chattr man-ioctl man-capabilities" />

<!--
Интерфейсы: lsattr/chattr поверх ioctl FS_IOC_GET/SETFLAGS (псевдокод из
конспекта, src/01_attrs.c). Права на изменение: для i и a нужна capability
CAP_LINUX_IMMUTABLE — по умолчанию у root. Отсюда честная оценка силы
механизма: root может сначала снять атрибут, затем изменить файл; значит, i
защищает от случайной порчи и от «ленивого» злоумышленника, но не от
полноценной компрометации root. Деталь про e/extents — чтобы вывод lsattr
в демонстрациях не вызывал вопросов.
-->

---
layout: section
---

# 5. Дополнительные атрибуты файлов

<SectionTOC prefix="5" :current="2" :items="[
  'Атрибуты и управление ими',
  'Атрибуты i и a на практике',
  'Атрибут s: надёжное удаление',
]" />

---

# Демо 07: атрибут i — конфигурацию не изменит и root

Защитим файлы `common-*` подсистемы PAM (лекция 3) от изменения:

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/08-chattr-immutable.txt" section="1" title="root@srv · исходное состояние" fontSize="0.5rem">
  <TCallout :line="4" :col="15" :span="1" :n="1" />
  <TCallout :line="12" :col="1" :span="16" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/08-chattr-immutable.txt" section="2" title="root@srv · chattr +i common-*" fontSize="0.45rem" padBottom="0.4em">
  <TCallout :line="4" :col="5" :span="1" :n="3" />
  <TCallout :line="10" :col="1" :rows="6" :span="48" :n="4" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> в «чистой» системе установлен лишь формат-атрибут <code>e</code>&ensp;
<span class="co-ball">2</span> root свободно дописывает строку в конфигурацию&ensp;
<span class="co-ball">3</span> после <code>chattr +i</code> у файлов появился флаг <code>i</code>&ensp;
<span class="co-ball">4</span> теперь запись, удаление и переименование <b>от root</b> завершаются отказом <code>Operation not permitted</code>; чтение и копирование работают
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/08-chattr-immutable.sh</div>

<Refs ids="man-chattr tevault" />

<!--
Задача 1 из раздела 4 решена: после chattr +i файл не изменит даже root —
мы видели причину в коде may_delete/may_open: IS_IMMUTABLE проверяется до
сравнения идентификаторов. Пример намеренно взят из лекции 3 — PAM-конфиги,
порча которых блокирует вход в систему. Чтение и копирование не
ограничиваются. Сброс атрибута показан в капчере (секция 3) и в
демо-скрипте; права на сброс — CAP_LINUX_IMMUTABLE.
-->

---

# Демо 08: атрибут a — журнал только пополняется

Журнал аутентификации `/var/log/auth.log` должен пополняться службами,
но не редактироваться:

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/09-chattr-append.txt" section="2" title="root@srv · chattr +a и новый вход по ssh" fontSize="0.44rem">
  <TCallout :line="3" :col="6" :span="1" :n="1" />
  <TCallout :line="5" :col="1" :span="16" :n="2" />
  <TCallout :line="12" :col="1" :rows="3" :span="40" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/09-chattr-append.txt" section="3" title="root@srv · попытки изменить журнал" fontSize="0.44rem" padBottom="0.4em">
  <TCallout :line="2" :col="1" :rows="6" :span="46" :n="4" />
  <TCallout :line="9" :col="1" :span="38" :n="5" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> атрибут <code>a</code> установлен&ensp;
<span class="co-ball">2</span> вход <code>bob</code> по ssh&ensp;
<span class="co-ball">3</span> службы продолжают дописывать журнал — записи о входе появились&ensp;
<span class="co-ball">4</span> удаление, переименование и усечение от root — <code>Operation not permitted</code>&ensp;
<span class="co-ball">5</span> дописывание в конец (<code>&gt;&gt;</code>) разрешено всем, у кого есть право записи, — след <code>hehehe</code> тоже остаётся в журнале
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/09-chattr-append.sh</div>

<Refs ids="man-chattr tevault" />

<!--
Задача 2 из раздела 4: append-only журнал. Внутри ядра мы это уже видели:
may_open навязывает O_APPEND и запрещает O_TRUNC для IS_APPEND-файлов.
Демонстрация: после +a службы (rsyslog, sshd) продолжают работать — им
достаточно дописывания; усечение, удаление, переименование от root
отклоняются. Нюанс с «hehehe»: дописывание не запрещено, атака на
читаемость журнала возможна, но и сама запись остаётся в журнале.
Ротация журналов с +a требует снятия атрибута — оговорить устно.
-->

---

# Демо 09: атрибут a на каталоге фиксирует файлы

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/10-chattr-dir.txt" section="2" title="bob@srv · +a: удалять нельзя, создавать можно" fontSize="0.47rem">
  <TCallout :line="3" :col="6" :span="1" :n="1" />
  <TCallout :line="5" :col="1" :rows="9" :span="42" :n="2" />
  <TCallout :line="15" :col="1" :rows="2" :span="28" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/10-chattr-dir.txt" section="3" title="bob@srv · +i: структура фиксируется" fontSize="0.47rem" padBottom="0.4em">
  <TCallout :line="4" :col="5" :span="1" :n="4" />
  <TCallout :line="6" :col="1" :rows="6" :span="45" :n="5" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> на каталоге установлен <code>a</code></div>
<div><span class="co-ball">2</span> удаление файлов — отказ для владельцев и для root</div>
<div><span class="co-ball">3</span> создание новых файлов разрешено</div>
<div><span class="co-ball">4</span> атрибут заменён на <code>i</code></div>
<div><span class="co-ball">5</span> запрещено и создание — структура каталога зафиксирована</div>
</div>
</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-teal-500 bg-teal-500/10">
<b>Вывод:</b> задача 3 раздела 4 решена: <code>a</code> на каталоге разделяет
неделимое прежде право <code>w</code> — создавать можно, удалять нельзя;
<code>i</code> фиксирует каталог целиком.
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/10-chattr-dir.sh</div>

<Refs ids="man-chattr" />

<!--
Каталожная семантика a и i: append-only каталог разрешает добавление записей
(новые файлы) и запрещает удаление; immutable запрещает любые изменения
списка. Подчеркнуть: содержимое существующих файлов по-прежнему
редактируемо — атрибут стоит на каталоге, а не на файлах. Удаление самого
каталога с атрибутом тоже невозможно (см. полный транскрипт, секция 4).
-->

---
layout: section
---

# 5. Дополнительные атрибуты файлов

<SectionTOC prefix="5" :current="3" :items="[
  'Атрибуты и управление ими',
  'Атрибуты i и a на практике',
  'Атрибут s: надёжное удаление',
]" />

---

# Атрибут s: проверим заявленное поведение

По документации `chattr(1)`, атрибут `s` (secure deletion) требует при
удалении файла **перезаписать его блоки нулями**; поддержка заявлена лишь
для ext2. Соберём стенд и проверим:

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/11-secure-delete.txt" section="1" title="root@srv · ext2 на loop-устройстве" fontSize="0.45rem" lines="1-19">
  <TCallout :line="5" :col="8" :span="33" :n="1" />
  <TCallout :line="18" :col="27" :span="25" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/11-secure-delete.txt" section="2" title="root@srv · где лежит содержимое файла" fontSize="0.45rem" padBottom="0.4em">
  <TCallout :line="3" :col="1" :span="8" :n="3" />
  <TCallout :line="10" :col="11" :rows="3" :span="40" :n="4" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> файл-образ превращаем в блочное устройство <code>losetup</code></div>
<div><span class="co-ball">2</span> на устройстве создана файловая система <b>ext2</b></div>
<div><span class="co-ball">3</span> <code>debugfs</code> сообщает блок данных файла: 1037</div>
<div><span class="co-ball">4</span> чтение блока напрямую с устройства показывает содержимое файла</div>
</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/11-secure-delete.sh</div>

<Refs ids="man-chattr secure-del-lwn" />

<!--
Методика эксперимента: loop-устройство, ext2 (единственная ФС, для которой
secure delete вообще заявлялся), debugfs находит номер блока данных, dd
читает блок в обход файловой системы. Теперь мы можем проверить, что
останется в блоке после удаления файла с атрибутом s. Техника чтения
устройства в обход ФС сама по себе поучительна: право на файл — не право
на устройство.
-->

---

# Демо 10: данные не перезаписаны

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/11-secure-delete.txt" section="3" title="root@srv · chattr +s, rm и чтение блока" fontSize="0.52rem">
  <TCallout :line="3" :col="1" :span="1" :n="1" />
  <TCallout :line="4" :col="1" :span="21" :n="2" />
  <TCallout :line="8" :col="11" :rows="3" :span="40" :n="3" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> атрибут <code>s</code> установлен</div>
<div><span class="co-ball">2</span> файл удалён, буферы сброшены <code>sync</code></div>
<div><span class="co-ball">3</span> блок 1037 читается с устройства <b>без изменений</b>: данные не перезаписаны нулями</div>
</div>

<div class="mt-3 p-3 border-l-4 border-red-500 bg-red-500/10">
Заявленное поведение не реализовано <b>даже для ext2</b>: атрибут
устанавливается, но не действует.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/11-secure-delete.sh</div>

<Refs ids="secure-del-lwn man-chattr" />

<!--
Кульминация: после rm и sync блок данных нетронут. Атрибут s — редкий случай
«документированной, но никогда не реализованной» функции: утилиты умеют его
ставить, man-страница описывает семантику, ядро его игнорирует. История и
причины — следующий слайд. Методический смысл демонстрации: документации
о свойствах безопасности нужно уметь не верить и проверять.
-->

---

# Secure deletion: не реализовано ни в одной стабильной версии

<HistoryNote class="mt-2">
Флаги <code>EXT2_SECRM_FL</code> и <code>EXT2_UNRM_FL</code> появились в
исходном коде ext2 в конце 1990-х, однако логика перезаписи так и не вошла
ни в одну стабильную версию ядра. Существовали внешние патчи и модули
(Bauer и Priyantha; van Hauser; Openwall; Joukov и др.), но основные
дистрибутивы их не применяли; к переходу на ядро 2.6 функция де-факто
признана устаревшей.
</HistoryNote>

<div class="grid grid-cols-2 gap-4 mt-3">
<div>

**Почему от идеи отказались:**

- журналирование и дисковые кэши не позволяют гарантировать момент
  и место физической записи;
- надёжное стирание магнитных носителей требует многократной перезаписи
  (метод Гутмана);
- переназначение секторов (remapping) и wear-levelling SSD оставляют
  копии данных вне достижимости ФС.

</div>
<div>

<div class="p-3 border-l-4 border-teal-500 bg-teal-500/10">
<b>Практические рекомендации:</b>
<ul class="mt-1">
<li>специализированные инструменты: <code>shred</code>, <code>wipe</code>,
<code>srm</code> — с оговорками о журналировании и SSD;</li>
<li>полнодисковое шифрование (LUKS): уничтожение ключа обесценивает
остаточные данные;</li>
<li>для носителей с высокими требованиями — физическое уничтожение.</li>
</ul>
</div>

</div>
</div>

<Refs ids="secure-del-lwn secure-del-bauer gutmann" />

<!--
История по Corbet (LWN) и статье Bauer/Priyantha: флаги определены, логика
не реализована, патчи существовали вне дерева, к 2.6 тема закрыта. Причины
фундаментальны: между rm и физической записью стоят журнал, кэши,
переназначение секторов и wear-levelling — файловая система не контролирует
устройство. Современный ответ — шифрование всего устройства: гарантированно
уничтожить ключ проще, чем данные. Рекомендации давать с оговоркой о модели
угроз: от кого и какой ценой защищаемся.
-->

---
layout: section
---

# 6. Расширенные атрибуты xattr

---

# xattr: произвольные метаданные «ключ–значение»

**Расширенные атрибуты** (extended attributes, xattr) позволяют связать с
файлом произвольные пары «имя–значение», интерпретируемые ядром, модулями
безопасности (LSM) или прикладными программами.

<div class="grid grid-cols-2 gap-4 mt-3 items-start">
<div>

Каждый атрибут состоит из:

- **имени** с обязательным префиксом пространства имён —
  `user.comment`, `security.selinux`;
- **значения** — произвольного двоичного блока (до единиц килобайт);
- **пространства имён**, определяющего политику доступа к атрибуту.

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Стандартные утилиты (<code>ls</code>, <code>stat</code>) xattr не
показывают; работа с ними — отдельные вызовы
(<code>getxattr</code>/<code>setxattr</code>) и утилиты пакета
<code>attr</code>.
</div>

</div>
<div>

<HistoryNote class="text-xs">
Расширенные атрибуты появились в BSD и IRIX в 1990-х; в Linux — в конце
1990-х вместе с поддержкой ACL. Сегодня xattr — транспорт для меток
SELinux/Smack/AppArmor, файловых capabilities и подписей целостности.
</HistoryNote>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Мотивация та же, что в разделе 4: в девять битов триплетов не вмещаются
ни многоуровневые политики (MAC), ни разграничение полномочий root,
ни контекст безопасности объекта. xattr — <b>место хранения</b> этих
данных; семантику им придают другие подсистемы.
</div>

</div>
</div>

<Refs ids="man-xattr kerrisk-tlpi" />

<!--
xattr — механизм-контейнер: сами по себе атрибуты ничего не разрешают и не
запрещают, они хранят данные, которым семантику придают потребители — LSM,
IMA, ядро (ACL, capabilities). Исторический контекст: BSD/IRIX, в Linux
пришли вместе с ACL — и ACL реализованы поверх xattr, что мы увидим в
разделе 7. Значения — двоичные блоки ограниченного размера; на ext4 все
xattr файла обычно должны умещаться в один блок.
-->

---

# Четыре пространства имён с разной политикой доступа

<div class="t-table text-xs mt-2">

| Пространство | Пример | Доступ | Назначение |
|---|---|---|---|
| `user.` | `user.comment` | владелец файла (обычные права файла) | пользовательские метаданные |
| `trusted.` | `trusted.md5` | только процессы с `CAP_SYS_ADMIN` | данные системных служб |
| `security.` | `security.selinux`, `security.capability` | модули LSM; чтение — по правилам модуля | метки MAC, файловые capabilities, подписи |
| `system.` | `system.posix_acl_access` | только ядро — через специальные вызовы | ACL и другие структуры ядра |

</div>

<div class="grid grid-cols-2 gap-3 mt-3 text-xs">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10">
Пространство имён — <b>часть модели доступа</b>: один механизм хранения
обслуживает и пользовательские заметки (<code>user.</code>), и данные,
которые обычному пользователю нельзя ни читать, ни подделывать
(<code>trusted.</code>, <code>security.</code>).
</div>
<div class="p-2 border-l-4 border-amber-500 bg-amber-500/10">
Листинг <code>getfattr -d</code> по умолчанию показывает <b>только</b>
<code>user.</code> — даже от root; атрибуты других пространств
запрашиваются явно (<code>-n имя</code> или <code>-m шаблон</code>).
</div>
</div>

<Refs ids="man-xattr man-setfattr" />

<!--
Таблица пространств имён из xattr(7). Ключевая идея: политика доступа
привязана к префиксу имени. user — обычные права файла; trusted —
CAP_SYS_ADMIN; security — пишут LSM (и root), читают по правилам модуля;
system — вообще не доступно напрямую, только через специализированные
вызовы вроде setfacl. Практическая мелочь из второй рамки объясняет вывод
следующей демонстрации: getfattr -d молчит о trusted/security.
-->

---

# Демо 11: пространства имён на практике

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/12-xattr.txt" section="1" title="bob@srv · setfattr и getfattr" fontSize="0.47rem">
  <TCallout :line="4" :col="15" :span="12" :n="1" />
  <TCallout :line="7" :col="1" :rows="2" :span="38" :n="2" />
  <TCallout :line="14" :col="1" :rows="3" :span="22" :n="3" />
  <TCallout :line="27" :col="1" :span="37" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> владелец устанавливает <code>user.mylabel</code> без привилегий</div>
<div><span class="co-ball">2</span> запись в <code>trusted.</code> от обычного пользователя — отказ</div>
<div><span class="co-ball">3</span> <code>getfattr -d</code> даже от root показывает только <code>user.</code>; <code>trusted.</code>/<code>security.</code> — по явному запросу <code>-n</code></div>
<div><span class="co-ball">4</span> удаление атрибута — <code>setfattr -x</code></div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Интерфейс одинаков для всех пространств; различается только то,
<b>кому</b> разрешены операции.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/12-xattr.sh</div>

<Refs ids="man-setfattr man-xattr" />

<!--
Живой показ политик: user ставится владельцем свободно, trusted от
непривилегированного пользователя отклоняется, листинг по умолчанию
показывает только user (даже root должен явно назвать trusted/security),
удаление — setfattr -x. Повторить мысль: механизм один, политика — по
префиксу.
-->

---

# Применение: метки LSM, capabilities, целостность

<div class="grid grid-cols-[1fr_1.2fr] gap-4 mt-2 items-start">
<div>

- **SELinux**: контекст безопасности файла — `security.selinux`
  (например, `system_u:object_r:etc_t:s0`); проверяется ядром при каждом
  обращении по загруженной политике.
- **Файловые capabilities**: `security.capability` наделяет исполняемый
  файл долями привилегий root — замена setuid-root
  (следующая лекция).
- **Целостность**: подсистемы IMA/EVM хранят хеши и подписи файлов
  в `security.ima` и `security.evm`.

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
ACL-списки раздела 7 — тоже xattr: <code>system.posix_acl_access</code>
и <code>system.posix_acl_default</code>.
</div>

</div>
<div>

<TerminalCapture src="captures/12-xattr.txt" section="2" title="bob@srv · setcap и security.capability" fontSize="0.55rem" padBottom="0.4em">
  <TCallout :line="2" :col="15" :span="24" :n="1" />
  <TCallout :line="7" :col="1" :span="20" :n="2" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> <code>setcap</code> наделяет файл capability
<code>cap_net_bind_service</code> (привилегированные порты)&ensp;
<span class="co-ball">2</span> «под капотом» это запись атрибута
<code>security.capability</code>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/12-xattr.sh</div>

<Refs ids="man-capabilities selinux-ima man-xattr" />

<!--
Потребители xattr: SELinux (метки контекста — сверяются ядром по политике),
файловые capabilities (гранулированная замена setuid-root — тема следующей
лекции, здесь только транспорт), IMA/EVM (хеши и подписи для контроля
целостности). Демонстрация setcap показывает соответствие: высокоуровневая
команда — это запись security.capability. И мост к разделу 7: ACL тоже
живут в xattr, в пространстве system.
-->

---
layout: section
---

# 7. Списки контроля доступа

<SectionTOC prefix="7" :current="1" :items="[
  'Организация списков',
  'Алгоритм проверки прав',
  'Маска ACL_MASK',
  'Наследование списков',
]" />

---

# Запись ACL: тип тега, квалификатор, права

**Список контроля доступа** (POSIX ACL) — прямое расширение девятибитной
модели: ряд записей, каждая из которых выдаёт триплет прав отдельному
пользователю или группе.

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<div class="t-table text-xs">

| Тип тега | Квалификатор | Права | Текстовая форма |
|---|:---:|:---:|---|
| `ACL_USER_OBJ` | — | `rwx` | `user::rwx` |
| `ACL_USER` | `1003` | `r-x` | `user:alice:r-x` |
| `ACL_GROUP_OBJ` | — | `r-x` | `group::r-x` |
| `ACL_GROUP` | `1010` | `rw-` | `group:dev:rw-` |
| `ACL_MASK` | — | `r-x` | `mask::r-x` |
| `ACL_OTHER` | — | `r--` | `other::r--` |

</div>

</div>
<div class="text-xs">

Каждая запись (ACL entry) состоит из трёх частей:

1. **тип тега** — категория субъектов, к которой относится запись;
2. **тег-квалификатор** — UID или GID конкретного пользователя/группы
   (только для `ACL_USER` и `ACL_GROUP`);
3. **права** — знакомый триплет `rwx`.

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
В текстовой форме запись пишется как
<code>тег:[квалификатор]:права</code>; длинная форма — по записи на
строку, краткая — записи через запятую. Эти формы используют
<Man p="getfacl(1)" /> и <Man p="setfacl(1)" />.
</div>

</div>
</div>

<Refs ids="man-acl kerrisk-tlpi man-setfacl" />

<!--
Структура ACL: записи из трёх частей. Таблица — полный пример списка со
всеми шестью типами тегов; текстовая форма в последнем столбце — то, что
печатает getfacl и принимает setfacl. Квалификатор есть только у
именованных записей ACL_USER/ACL_GROUP — остальным он не нужен. Запись
mask отложим до раздела 7.3.
-->

---

# Шесть типов тегов

<div class="t-table text-xs mt-2">

| Тип тега | Сколько в списке | Кому выдаёт права |
|---|---|---|
| `ACL_USER_OBJ` | ровно одна | владельцу файла — соответствует первому триплету |
| `ACL_USER` | 0 или более | именованному пользователю из квалификатора; не более одной записи на пользователя |
| `ACL_GROUP_OBJ` | ровно одна | группе владельцев — соответствует второму триплету |
| `ACL_GROUP` | 0 или более | именованной группе из квалификатора; не более одной записи на группу |
| `ACL_MASK` | не более одной | верхняя граница прав записей «класса группы»; **обязательна** при наличии `ACL_USER`/`ACL_GROUP` |
| `ACL_OTHER` | ровно одна | всем прочим — соответствует третьему триплету |

</div>

<div class="mt-3 grid grid-cols-2 gap-3">
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Минимальный список</b> — три обязательные записи
(<code>ACL_USER_OBJ</code>, <code>ACL_GROUP_OBJ</code>,
<code>ACL_OTHER</code>): семантически это те же триплеты, хранится он
прямо в <code>i_mode</code>.
</div>
<div class="p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
<b>Расширенный список</b> — добавлены именованные записи и маска;
дополнительные записи хранятся в расширенном атрибуте
<code>system.posix_acl_access</code> (раздел 6).
</div>
</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Инвентаризация типов: три обязательные записи повторяют триплеты; именованные
ACL_USER/ACL_GROUP добавляют выразительность, которой не хватало в разделе
4; mask — страховочный механизм совместимости (раздел 7.3). Различие
минимального и расширенного списков важно и для хранения: минимальный — это
просто i_mode, расширенный добавляет xattr system.posix_acl_access. Прямо
отсюда — демонстрация.
-->

---

# Демо 12: минимальный и расширенный списки

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/13-acl-basics.txt" section="1" title="bob@srv · минимальный ACL" fontSize="0.5rem">
  <TCallout :line="8" :col="1" :rows="3" :span="10" :n="1" />
  <TCallout :line="13" :col="1" :span="44" :n="2" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/13-acl-basics.txt" section="2" title="bob@srv · setfacl добавляет записи" fontSize="0.5rem" padBottom="0.4em">
  <TCallout :line="11" :col="1" :span="14" :n="3" />
  <TCallout :line="13" :col="1" :span="10" :n="4" />
  <TCallout :line="17" :col="11" :span="1" :n="5" />
  <TCallout :line="21" :col="1" :span="24" :n="6" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> у нового файла три записи — минимальный список, эквивалент триплетов&ensp;
<span class="co-ball">2</span> расширенного атрибута нет: минимальный список живёт в <code>i_mode</code>&ensp;
<span class="co-ball">3</span> правило для <code>alice</code> добавлено одной командой&ensp;
<span class="co-ball">4</span> вместе с ним появилась маска&ensp;
<span class="co-ball">5</span> знак <code>+</code> в выводе <code>ls</code> — признак расширенного списка&ensp;
<span class="co-ball">6</span> который хранится в <code>system.posix_acl_access</code>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/13-acl-basics.sh</div>

<Refs ids="man-setfacl man-acl" />

<!--
Демонстрация соответствия: свежий файл — минимальный список (getfacl
показывает три записи, xattr отсутствует). Одна команда setfacl превращает
список в расширенный: именованная запись, автоматически вычисленная маска,
плюс в выводе ls, и — появился xattr system.posix_acl_access. Хранение
прозрачно подтверждает теорию предыдущего слайда.
-->

---
layout: section
---

# 7. Списки контроля доступа

<SectionTOC prefix="7" :current="2" :items="[
  'Организация списков',
  'Алгоритм проверки прав',
  'Маска ACL_MASK',
  'Наследование списков',
]" />

---

# Алгоритм проверки: от владельца к остальным

<div class="grid grid-cols-[1.3fr_1fr] gap-4 mt-2 items-start">
<div>

1. Процесс **привилегирован** → полный доступ
   (исключение — в красной рамке).
2. FSUID процесса = **владелец файла** → действует `ACL_USER_OBJ`,
   проверка **завершается**.
3. FSUID совпал с квалификатором записи **`ACL_USER`** → действуют её
   права `∧ ACL_MASK`, проверка завершается.
4. **Группа файла** есть в списке групп процесса → действует
   `ACL_GROUP_OBJ` `∧ ACL_MASK`, проверка завершается.
5. Квалификатор какой-либо записи **`ACL_GROUP`** есть в списке групп
   процесса → её права `∧ ACL_MASK`.
6. Иначе — права записи `ACL_OTHER`.

</div>
<div>

<div class="p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Исключение для привилегированных:</b> чтобы <b>исполнить</b> файл,
даже root нужен бит <code>x</code> хотя бы в одной записи списка.
</div>

<div class="mt-3 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Шаги проверяются по порядку, и первое <b>подходящее по субъекту</b>
правило решает исход — как и в классической модели. Единственное
отступление: внутри шага 5 перебираются <b>все</b> подходящие записи
<code>ACL_GROUP</code>, пока одна из них не даст запрошенные права.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Знак <code>∧</code> — поразрядное И с маской: эффективные права записей
«класса группы» ограничены <code>ACL_MASK</code> (раздел 7.3).
</div>

</div>
</div>

<Refs ids="kerrisk-tlpi man-acl" />

<!--
Алгоритм ACL повторяет каркас классического: владелец → группа → остальные,
с двумя вставками: именованные пользователи между владельцем и группой,
именованные группы после группы владельцев. Маска накладывается на весь
«класс группы». Два тонких места, которые дальше покажем демонстрациями:
привилегированному процессу для исполнения нужен x хотя бы где-то; и внутри
группового шага перебор продолжается, пока какая-нибудь группа процесса не
даст права, — но прав из разных записей не складывают.
-->

---

# Демо 13: root не исполнит файл без единого x

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="1" title="bob@srv · исполнение и привилегии" fontSize="0.5rem">
  <TCallout :line="8" :col="1" :span="52" :n="1" />
  <TCallout :line="14" :col="1" :span="17" :n="2" />
  <TCallout :line="19" :col="1" :span="26" :n="3" />
  <TCallout :line="21" :col="1" :span="6" :n="4" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> ни одна запись не содержит <code>x</code> — отказ в исполнении даже через <code>sudo</code></div>
<div><span class="co-ball">2</span> добавляем единственный <code>x</code> — группе <code>users</code></div>
<div><span class="co-ball">3</span> <code>bob</code> состоит в <code>users</code>, но запуск запрещён: проверка <b>завершилась</b> на правиле владельца <code>user::rw-</code></div>
<div><span class="co-ball">4</span> root исполняет файл: привилегии + бит <code>x</code> в одной из записей</div>
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/14-acl-algorithm.sh</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Два тонких места алгоритма в одной демонстрации. Первое: правило «root может
всё» для исполнения ослаблено — нужен x хотя бы в одной записи (ядро
отличает «никому не исполняемый» файл от «исполняемого, но не этим
пользователем»). Второе — важнее: bob состоит в users, которой выдан x, но
запуск отклонён, потому что bob — владелец, и проверка завершилась на
ACL_USER_OBJ. Первое подходящее по субъекту правило решает — даже если
дальше по списку есть более щедрое.
-->

---

# Демо 13: правило владельца, маска не применяется

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="2" title="bob@srv · ACL_USER_OBJ" fontSize="0.45rem">
  <TCallout :line="5" :col="1" :span="10" :n="1" />
  <TCallout :line="14" :col="1" :span="26" :n="2" />
  <TCallout :line="25" :col="1" :span="10" :n="3" />
  <TCallout :line="29" :col="1" :span="5" :n="4" />
  <TCallout :line="31" :col="1" :span="26" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> у владельца снято право чтения (<code>--w-r--r--+</code>), остальным чтение разрешено</div>
<div><span class="co-ball">2</span> владелец <code>bob</code> не может прочитать <b>собственный</b> файл — проверка завершилась на <code>user::-w-</code>, щедрые правила дальше по списку не рассматриваются</div>
<div><span class="co-ball">3</span> устанавливаем маску <code>--x</code>: <code>getfacl</code> подсказывает эффективные права <code>#effective:---</code></div>
<div><span class="co-ball">4</span> владелец читает файл: к <code>ACL_USER_OBJ</code> маска <b>не применяется</b></div>
<div><span class="co-ball">5</span> для именованной записи <code>alice</code> маска действует — отказ</div>
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/14-acl-algorithm.sh</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Шаг 2 алгоритма. Контринтуитивный момент: владелец с правами -w- не читает
собственный файл, хотя other разрешает чтение всем, — правило владельца
терминально. Вторая половина — границы действия маски: ACL_USER_OBJ вне
«класса группы», маска его не ограничивает; именованная запись alice
маскируется. Обратить внимание на сервис getfacl: он сам вычисляет и
печатает эффективные права.
-->

---

# Демо 13: именованный пользователь, маска применяется

<div class="grid grid-cols-[1.25fr_1fr] gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="3" title="bob@srv · ACL_USER" fontSize="0.45rem">
  <TCallout :line="8" :col="1" :span="14" :n="1" />
  <TCallout :line="15" :col="1" :span="26" :n="2" />
  <TCallout :line="17" :col="1" :span="5" :n="3" />
  <TCallout :line="19" :col="1" :span="26" :n="4" />
  <TCallout :line="29" :col="1" :rows="2" :span="26" :n="5" />
</TerminalCapture>

</div>
<div class="p-3 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<b>Читаем демонстрацию:</b>
<div class="mt-1 space-y-1.5">
<div><span class="co-ball">1</span> чтение оставлено только записи <code>user:alice:r--</code></div>
<div><span class="co-ball">2</span> владелец <code>bob</code> — отказ (правило владельца)</div>
<div><span class="co-ball">3</span> <code>alice</code> читает файл — сработал шаг 3 алгоритма</div>
<div><span class="co-ball">4</span> <code>carol</code> — отказ по <code>other::---</code></div>
<div><span class="co-ball">5</span> после маски <code>--x</code> эффективные права <code>alice</code> пусты — отказ: к <code>ACL_USER</code> маска применяется</div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Сценарий «права одному пользователю поверх триплетов» (задача i раздела 4)
решается одной записью.
</div>
</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/14-acl-algorithm.sh</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Шаг 3: именованный пользователь. Файл закрыт для всех, кроме записи
user:alice:r--. Три исхода: владелец — отказ (его правило -w-), alice —
чтение, carol — отказ (other). И действие маски: --x обнуляет эффективные
права alice. Первая из задач выразительности раздела 4 закрыта.
-->

---

# Демо 13: группа файла и именованная группа

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="4" title="bob@srv · ACL_GROUP_OBJ" fontSize="0.45rem">
  <TCallout :line="7" :col="3" :span="10" :n="1" />
  <TCallout :line="17" :col="1" :rows="2" :span="9" :n="2" />
  <TCallout :line="20" :col="1" :rows="3" :span="24" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="5" title="bob@srv · ACL_GROUP" fontSize="0.45rem" padBottom="0.4em">
  <TCallout :line="11" :col="1" :span="14" :n="4" />
  <TCallout :line="18" :col="1" :rows="2" :span="9" :n="5" />
  <TCallout :line="21" :col="1" :rows="4" :span="33" :n="6" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> файл передан <code>carol</code>, группа владельцев — <code>bob</code>&ensp;
<span class="co-ball">2</span> процесс <code>bob</code> читает файл по записи <code>group::r--</code>&ensp;
<span class="co-ball">3</span> даже с первичной группой <code>nogroup</code> (<code>sudo -g</code>) доступ идёт по <code>ACL_GROUP_OBJ</code>: группа файла ищется среди <b>всех</b> групп процесса&ensp;
<span class="co-ball">4</span> права только у записи <code>group:bob:rwx</code>&ensp;
<span class="co-ball">5</span> участник группы <code>bob</code> читает файл — шаг 5&ensp;
<span class="co-ball">6</span> процесс без группы <code>bob</code> — отказ по <code>other::---</code>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/14-acl-algorithm.sh</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Шаги 4 и 5. Слева — группа владельцев: право читать получает любой процесс,
в чьём списке групп есть группа файла; смена первичной группы на nogroup
(у которой запись -wx без чтения) ничего не меняет — группа файла
по-прежнему среди дополнительных групп процесса, срабатывает ACL_GROUP_OBJ.
Справа — именованная группа: файл чужой (carol:carol, 0000), но запись
group:bob:rwx открывает его участникам группы bob; процесс nobody без этой
группы получает отказ. Задача ii раздела 4 — две группы с разными правами —
решается двумя записями ACL_GROUP.
-->

---

# Демо 13: подходящих записей несколько — права не складываются

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="6" title="bob@srv · johnny: r, w, x из трёх записей" fontSize="0.43rem" lines="1-25">
  <TCallout :line="3" :col="55" :rows="1" :span="34" :n="1" />
  <TCallout :line="15" :col="1" :rows="3" :span="17" :n="2" />
  <TCallout :line="23" :col="11" :span="9" :n="3" />
  <TCallout :line="25" :col="1" :span="6" :n="4" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/14-acl-algorithm.txt" section="7" title="bob@srv · O_RDWR требует rw в одной записи" fontSize="0.43rem" lines="1-17">
  <TCallout :line="2" :col="27" :span="6" :n="5" />
  <TCallout :line="5" :col="1" :span="46" :n="6" />
  <TCallout :line="12" :col="1" :span="15" :n="7" />
  <TCallout :line="17" :col="1" :span="33" :n="8" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> <code>johnny</code> состоит в трёх группах&ensp;
<span class="co-ball">2</span> каждой группе — один бит&ensp;
<span class="co-ball">3</span><span class="co-ball">4</span> <code>johnny</code> и читает (<code>r</code> от <code>alice</code>), и исполняет (<code>x</code> от <code>dave</code>) файл — <b>в разных операциях</b>&ensp;
<span class="co-ball">5</span><span class="co-ball">6</span> но открытие <code>O_RDWR</code> отклонено: ни одна запись не даёт <code>rw</code> <b>одновременно</b>&ensp;
<span class="co-ball">7</span><span class="co-ball">8</span> после <code>g:alice:rw-</code> открытие успешно
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/14-acl-algorithm.sh · assets/src/file_reader.c</div>

<Refs ids="man-acl kerrisk-tlpi" />

<!--
Самая тонкая демонстрация раздела. На шаге 5 перебираются все записи
ACL_GROUP для групп процесса — поэтому johnny в разных операциях пользуется
разными записями: чтение по alice, исполнение по dave, запись по carol. Но
в рамках одной проверки права не объединяются: open(O_RDWR) требует r и w
в одной записи — отказ, пока какая-нибудь запись не даст оба бита.
file_reader — программа из assets/src, открывающая аргумент с O_RDWR.
-->

---

# Запуск скрипта: x и r проверяются в разные моменты

Как же `johnny` **исполнил** `8.sh`? Для запуска скрипта нужны и `x`, и `r` —
но они проверяются в двух разных операциях:

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

```c
/* bash: выполнение команды ./8.sh */
int shell_execve (char *command, char **args, char **env)
{
  ...
  execve (command, args, env);     /* 1 */
  ...
```

```c
/* ядро обработало шебанг и запустило
   /bin/bash 8.sh; bash читает скрипт: */
static int open_shell_script (char *script_name)
{
  ...
  fd = open (filename, O_RDONLY);  /* 2 */
  ...
```

<div class="text-xs opacity-70 mt-1">
<a href="https://github.com/bminor/bash/blob/master/execute_cmd.c#L6126">bash/execute_cmd.c#L6126</a> ·
<a href="https://github.com/bminor/bash/blob/master/shell.c#L1572">bash/shell.c#L1572</a>
</div>

</div>
<div class="text-xs">

<div class="space-y-1.5">
<div><span class="co-ball">1</span> интерактивный bash вызывает <code>execve("./8.sh", …)</code> — ядро проверяет право <b>исполнения</b>; запись <code>g:dave:--x</code> его даёт</div>
<div><span class="co-ball">2</span> ядро извлекает шебанг и исполняет интерпретатор: <code>execve("/bin/bash", ["bash", "8.sh"], …)</code>; новый процесс bash <b>открывает скрипт на чтение</b> — отдельная проверка права <code>r</code>, её закрывает запись <code>g:alice:r--</code></div>
</div>

<div class="mt-3 p-2 border-l-4 border-teal-500 bg-teal-500/10">
Противоречия с предыдущим слайдом нет: права по-прежнему не складываются
<b>в одной проверке</b> — просто запуск скрипта состоит из <b>двух</b>
проверок, и каждую удовлетворяет своя запись списка.
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Это же двухшаговое исполнение объясняет, почему setuid на скриптах
игнорируется (раздел 2.3): между шагами файл можно подменить.
</div>

</div>
</div>

<Refs ids="bash-src man-execve kerrisk-tlpi" />

<!--
Разрешение кажущегося парадокса из демонстрации: прямой запуск скрипта — два
системных события. Сначала execve самого скрипта (нужен x), ядро читает
шебанг и перезапускает execve интерпретатора; затем интерпретатор обычным
open читает текст скрипта (нужен r). Разные проверки — разные записи ACL
могут их удовлетворить. Бонус: та же механика лежит под запретом
setuid-скриптов и под требованием r для скриптов из демо 01.
-->

---
layout: section
---

# 7. Списки контроля доступа

<SectionTOC prefix="7" :current="3" :items="[
  'Организация списков',
  'Алгоритм проверки прав',
  'Маска ACL_MASK',
  'Наследование списков',
]" />

---

# Зачем маска: chmod не знает про ACL

Программы, не знающие про ACL, управляют правами через `chmod(0700)` —
«закрыть всё, кроме владельца». Без маски согласовать их с ACL нельзя:

<div class="grid grid-cols-[1fr_1fr] gap-4 mt-2 text-xs items-start">
<div>

**Попытка без маски.** Чтобы `chmod 0700` действительно закрыл файл,
пришлось бы обнулить именованные записи:

```
user::rwx         # было: r-x
user:alice:---    # было: r-x  ← потеряно
group::---        # было: r-x
group:dev:---     # было: r-x  ← потеряно
other::---        # было: --x
```

Обратный `chmod 0551` восстановит триплеты, но права `alice` и `dev`
**утрачены безвозвратно**.

</div>
<div>

**С маской.** `chmod` меняет только `ACL_MASK`; именованные записи
сохраняются, меняются их *эффективные* права:

```
user::rwx
user:alice:r-x   #effective:---
group::r-x       #effective:---
group:dev:r-x    #effective:---
mask::---        ← сюда лёг второй триплет
other::---
```

Обратный `chmod 0551` восстанавливает <code>mask::r-x</code> — список
вернулся к исходной семантике.

</div>
</div>

<div class="mt-3 p-2 border-l-4 border-sky-500 bg-sky-500/10">
Назначение <code>ACL_MASK</code> — <b>совместимость</b>: традиционные
операции с триплетами остаются осмысленными для файлов с расширенными
списками, не разрушая сами списки.
</div>

<Refs ids="kerrisk-tlpi man-acl" />

<!--
Мотивирующий пример Керриска: старая программа делает chmod 0700, затем
«восстанавливает» chmod 0551. Без маски единственный способ выполнить
семантику «закрыть всё» — обнулить именованные записи, и восстановить их
нечем. С маской второй триплет отображается на ACL_MASK: именованные записи
не трогаются, только маскируются; обратный chmod возвращает исходное
состояние. Маска — мост совместимости между двумя моделями.
-->

---

# Поведение ACL_MASK: три правила

При наличии маски записи `ACL_USER`, `ACL_GROUP_OBJ` и `ACL_GROUP` образуют
**класс группы**, и:

<div class="grid grid-cols-3 gap-3 mt-2">
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>1.</b> <code>chmod</code> со вторым триплетом изменяет
<b>маску</b>, а не <code>ACL_GROUP_OBJ</code>
</div>
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>2.</b> <code>stat()</code> и <code>ls -l</code> показывают на месте
второго триплета <b>маску</b>
</div>
<div class="p-3 border-l-4 border-sky-500 bg-sky-500/10">
<b>3.</b> эффективные права класса группы = права записи
<code>∧</code> маска; <code>getfacl</code> печатает их как
<code>#effective:</code>
</div>
</div>

<div class="mt-3 p-3 border-l-4 border-red-500 bg-red-500/10">
<b>Обратное не выполняется.</b> После <code>chmod g+rw</code> вывод
<code>ls</code> покажет <code>rw</code> у «группы», однако реальная запись
<code>group::---</code> останется запрещающей: вывод <code>ls</code> для
файла с ACL описывает <b>маску, а не фактические права группы</b>. Полную
картину даёт только <code>getfacl</code>.
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
Маска пересчитывается автоматически при <code>setfacl -m</code>
(объединение прав класса группы), поэтому после изменения записей стоит
проверять её значение: автоматический пересчёт может «открыть» маску шире,
чем ожидалось.
</div>

<Refs ids="kerrisk-tlpi man-acl man-setfacl" />

<!--
Три правила поведения маски: chmod пишет в маску, stat/ls показывают маску,
эффективные права = И с маской. Красная рамка — предел совместимости: ls
может показывать «права группы», которых на самом деле нет (группа
запрещена записью group::---, а ls показывает маску rw) — диагностировать
файлы с плюсом в ls нужно через getfacl. Янтарное замечание — практика:
setfacl пересчитывает маску как ИЛИ прав класса группы, расширяя её.
-->

---

# Демо 14: chmod и маска

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/15-acl-mask.txt" section="2" title="bob@srv · chmod на расширенном списке" fontSize="0.47rem">
  <TCallout :line="8" :col="1" :span="9" :n="1" />
  <TCallout :line="12" :col="1" :span="17" :n="2" />
  <TCallout :line="17" :col="1" :span="30" :n="3" />
  <TCallout :line="19" :col="1" :span="9" :n="4" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/15-acl-mask.txt" section="3" title="bob@srv · маска в выводе ls" fontSize="0.47rem" padBottom="0.4em">
  <TCallout :line="13" :col="1" :span="28" :n="5" />
  <TCallout :line="15" :col="5" :span="3" :n="6" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> у списка появилась маска <code>rwx</code></div>
<div><span class="co-ball">2</span> <code>chmod 0333</code> на файле с ACL…</div>
<div><span class="co-ball">3</span> …записи сохранены, но маскированы (<code>#effective</code>)</div>
<div><span class="co-ball">4</span> второй триплет <code>chmod</code> записан в <b>маску</b></div>
<div><span class="co-ball">5</span> явная смена маски <code>setfacl -m mask::--x</code>…</div>
<div><span class="co-ball">6</span> …отражается во втором «триплете» вывода <code>ls</code>: <code>-rw---xr--+</code></div>
</div>
</div>

</div>
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/15-acl-mask.sh</div>

<Refs ids="man-setfacl man-acl" />

<!--
Оба направления связи chmod ↔ маска: chmod 0333 не разрушил записи
(сохранились с #effective), его второй триплет лёг в маску; и наоборот,
setfacl -m mask::--x немедленно виден в ls как «права группы». На
минимальном списке (секция 1 транскрипта) chmod по-прежнему меняет сам
ACL_GROUP_OBJ — маски там нет.
-->

---
layout: section
---

# 7. Списки контроля доступа

<SectionTOC prefix="7" :current="4" :items="[
  'Организация списков',
  'Алгоритм проверки прав',
  'Маска ACL_MASK',
  'Наследование списков',
]" />

---

# Default ACL: наследуемые списки каталога

**Список по умолчанию** (default ACL) устанавливается на каталог, в проверках
доступа **не участвует** и определяет списки создаваемых внутри объектов:

<div class="grid grid-cols-[1.2fr_1fr] gap-4 mt-2 items-start">
<div>

При создании объекта с запрошенным режимом `mode`:

1. записи default-списка **копируются** в обычный список нового объекта;
2. `umask` **не используется вовсе**;
3. триплет `ACL_USER_OBJ` ограничивается первым триплетом `mode`
   (поразрядное И);
4. при отсутствии маски так же ограничивается `ACL_GROUP_OBJ`,
   при наличии — `ACL_MASK`; именованные записи копируются как есть;
5. `ACL_OTHER` ограничивается третьим триплетом `mode`;
6. подкаталоги дополнительно наследуют **сам default-список** —
   иерархия продолжается.

</div>
<div>

<TerminalCapture src="captures/16-acl-default.txt" section="1" title="bob@srv · setfacl -d" fontSize="0.5rem" padBottom="0.4em">
  <TCallout :line="2" :col="11" :span="2" :n="1" />
  <TCallout :line="8" :col="1" :rows="3" :span="18" :n="2" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> ключ <code>-d</code> — работа со списком по
умолчанию&ensp;
<span class="co-ball">2</span> default-записи видны в <code>getfacl</code>
с префиксом <code>default:</code>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Default-список можно читать как <b>расширение <code>umask</code></b>:
маску максимальных прав для всего поддерева задаёт теперь каталог,
причём отдельно по субъектам.
</div>

</div>
</div>

<Refs ids="kerrisk-tlpi man-acl man-setfacl" />

<!--
Default ACL — третий механизм умолчаний после umask и setgid-каталога.
Правила формирования: default-записи копируются, затем маскируются битами
запрошенного режима (владелец — первым триплетом, группа или маска —
вторым, остальные — третьим); umask при этом не участвует — важное
изменение поведения. Подкаталоги наследуют и сам default-список — иерархия
воспроизводится. Интерпретация «umask на каталог, по субъектам» помогает
запомнить семантику.
-->

---

# Демо 15: наследование вместо umask

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/16-acl-default.txt" section="2" title="bob@srv · файл: default ACL вместо umask" fontSize="0.45rem">
  <TCallout :line="3" :col="1" :span="4" :n="1" />
  <TCallout :line="6" :col="1" :span="10" :n="2" />
  <TCallout :line="17" :col="1" :span="10" :n="3" />
  <TCallout :line="20" :col="1" :rows="3" :span="10" :n="4" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/16-acl-default.txt" section="3" title="bob@srv · подкаталог" fontSize="0.45rem" padBottom="0.4em">
  <TCallout :line="3" :col="1" :span="11" :n="5" />
  <TCallout :line="9" :col="1" :rows="3" :span="18" :n="6" />
</TerminalCapture>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<span class="co-ball">1</span> маска процесса — <code>0022</code>&ensp;
<span class="co-ball">2</span> без default-списка файл получает <code>0644</code> = <code>0666 &amp; ~022</code>&ensp;
<span class="co-ball">3</span> в каталоге со списком <code>u::rwx,g::wx,o::x</code> — права <code>rw--w----</code>: default-записи <code>∧</code> триплеты режима <code>0666</code>, <b>umask не участвует</b>&ensp;
<span class="co-ball">4</span> список файла сформирован из default-списка&ensp;
<span class="co-ball">5</span> подкаталог (<code>mode 0777</code>) копирует default-записи без изменений&ensp;
<span class="co-ball">6</span> и наследует сам default-список — наследование продолжится глубже
</div>

<div class="text-xs opacity-70 mt-2">См. assets/demos/16-acl-default.sh</div>

<Refs ids="man-setfacl kerrisk-tlpi" />

<!--
Контрольный и экспериментальный случаи: тот же umask 022, но в каталоге с
default-списком файл получает rw--w---- — пересечение default-записей с
режимом 0666, без участия umask (иначе группа потеряла бы w). Подкаталог
при mode 0777 получает копию default-записей и сам default-список —
иерархическое наследование. Сопоставить с setgid-каталогом из 2.4: там
наследуется только группа, здесь — вся схема прав.
-->

---

# Демо 15: расширенный default-список; независимость копий

<div class="grid grid-cols-2 gap-4 mt-2 items-start">
<div>

<TerminalCapture src="captures/16-acl-default.txt" section="4" title="bob@srv · default-список с маской" fontSize="0.42rem">
  <TCallout :line="2" :col="17" :span="11" :n="1" />
  <TCallout :line="8" :col="1" :span="9" :n="2" />
  <TCallout :line="18" :col="1" :rows="2" :span="40" :n="3" />
</TerminalCapture>

</div>
<div>

<TerminalCapture src="captures/16-acl-default.txt" section="5" title="bob@srv · списки живут независимо" fontSize="0.42rem" padBottom="0.4em">
  <TCallout :line="1" :col="1" :span="33" :n="4" />
  <TCallout :line="10" :col="1" :rows="5" :span="33" :n="5" />
</TerminalCapture>

<div class="mt-2 p-2 border-l-4 border-amber-500 bg-amber-500/10 text-xs">
<div class="space-y-1">
<div><span class="co-ball">1</span> в default-список добавлена именованная группа</div>
<div><span class="co-ball">2</span> → появилась и default-маска</div>
<div><span class="co-ball">3</span> у созданного файла именованные записи скопированы как есть, маска ограничена режимом <code>0666</code></div>
<div><span class="co-ball">4</span> меняем список унаследовавшего файла…</div>
<div><span class="co-ball">5</span> …default-список родителя не изменился: после создания списки <b>независимы</b></div>
</div>
</div>

</div>
</div>

<div class="mt-2 p-2 border-l-4 border-sky-500 bg-sky-500/10 text-xs">
Наследование — <b>одномоментное копирование</b> при создании: правки
default-списка на существующие объекты не распространяются
(<code>setfacl -R</code> — массово); хранится он в атрибуте
<code>system.posix_acl_default</code>. · См. assets/demos/16-acl-default.sh
</div>

<Refs ids="man-setfacl man-acl" />

<!--
Расширенный default-список: именованная запись тянет за собой default-маску;
при создании файла именованные записи копируются без изменения, а маска
пересекается с режимом — эффективные права видны сразу. Правая колонка —
важное операционное свойство: наследование не «живая связь», а копирование
при создании; правки детей не трогают родителя и наоборот; рекурсивные
изменения — setfacl -R. Хранение в system.posix_acl_default — замыкание
на раздел 6.
-->

---

# Итоги: ядро модели и три её расширения

<div class="t-table text-xs mt-3">

| Механизм | Что добавляет | Границы применимости |
|---|---|---|
| Триплеты, специальные биты, umask | базовое разграничение по владельцу, группе, остальным | три категории субъектов; `root` вне ограничений; право `w` неделимо |
| Дополнительные атрибуты (`chattr`) | режимы файла: immutable, append-only, свойства хранения | снимаются обладателем `CAP_LINUX_IMMUTABLE`; набор зависит от ФС; `s` не реализован |
| Расширенные атрибуты (xattr) | хранение меток LSM, capabilities, подписей, ACL | только контейнер: семантику придают потребители |
| POSIX ACL | права именованным пользователям и группам, наследуемые умолчания | права не складываются в одной проверке; `ls` показывает маску; сложнее аудит |

</div>

<div class="mt-3 p-3 border-l-4 border-teal-500 bg-teal-500/10">
Классическая дискреционная модель остаётся <b>ядром</b> разграничения доступа
Linux — проверки в <code>acl_permission_check()</code> исполняются для
каждого обращения к файлу. Механизмы-расширения снимают её ограничения
точечно, и у каждого есть собственные границы — выбор механизма определяется
задачей и моделью угроз. Разграничение полномочий самого <code>root</code> —
тема следующей лекции (Linux Capabilities).
</div>

<Refs ids="kerrisk-tlpi" />

<!--
Финальный синтез: таблица «механизм — вклад — границы» по всем разделам.
Центральный вывод лекции повторён явно: классическая модель — ядро, восемь
проверок на каждый файловый вызов; расширения точечны, их границы названы.
Открытый хвост — ограничение полномочий root: атрибут i лишь намекнул на
направление, систематическое решение (capabilities) — следующая лекция.
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
подсвечивают источник. Демонстрации выполнены на Ubuntu Server 26.04 LTS;
фрагменты исходного кода ядра — Linux v6.18, точные ссылки на строки — в
подписях под листингами.
</div>
