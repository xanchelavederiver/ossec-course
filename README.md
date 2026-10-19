# БезОС - проект для подготовки материалов

В настоящем репозитории содержатся все исходные для формирования материалов по курсу Безопасность Операционных Систем:

1. презентации для лекций
2. конспекты лекций и доп. материалы
3. методички для ЛР
4. список вопросов к экзамену


## Сборка и запуск презентаций

Требуются Node.js и npm (версии см. в `project/README.md`). Установите
зависимости и соберите все презентации из каталога `project/lectures.json`:

```sh
npm --prefix project ci
make lectures-slides     # также доступен псевдоним make lectures
```

Сборка выполняется в `project/dist/`, затем результат копируется в
`public/lectures/slides/<topic>/<lecture>/`. Каждый каталог содержит
`index.html` и ресурсы презентации. Подробнее об экспорте в PDF и добавлении
лекций см. [инструкцию по презентациям](project/README.md).

### Dev-сервер для отдельной лекции

Лекция задаётся как `<topic>/<lecture>` — идентификаторы темы и лекции из
`project/lectures.json`. Список доступных лекций:

```sh
npm --prefix project run list
```

Запуск dev-сервера Slidev с горячей перезагрузкой:

```sh
make lecture-dev LECTURE=02-identity-and-access-management/03-pam
```

Без `LECTURE` команда выводит список доступных лекций. Адрес и порт можно
переопределить:

```sh
make lecture-dev LECTURE=02-identity-and-access-management/03-pam PORT=3031
make lecture-dev LECTURE=02-identity-and-access-management/03-pam HOST=0.0.0.0 PASSWORD=secret
```

- `PORT` — порт сервера (по умолчанию 3030; если занят, Slidev выберет следующий
  свободный).
- `HOST` — адрес, на котором слушает сервер (по умолчанию `localhost`). Любое
  другое значение включает remote-режим Slidev: презентация становится доступна
  по сети, а режим докладчика — для удалённого управления.
- `PASSWORD` — пароль для режима докладчика в remote-режиме. Без него
  управлять презентацией может любой в сети, поэтому при `HOST` его стоит
  задавать.

Эквивалент без Make
(`--` обязателен, иначе npm не передаст аргумент скрипту):

```sh
npm --prefix project run dev -- 02-identity-and-access-management/03-pam
npm --prefix project run dev -- 02-identity-and-access-management/03-pam --host 0.0.0.0 --port 3031 --password secret
```

Сервер открывает браузер автоматически и по умолчанию доступен на
<http://localhost:3030/> (режим докладчика — `/presenter/`). Редактируемый
файл — `project/materials/lectures/<topic>/<lecture>/slides.md`. Остановка —
`Ctrl+C`.

## Сборка лабораторных работ

Требуются Docker (с запущенным daemon) и GNU Make. Ruby, Asciidoctor,
Asciidoctor PDF, Rouge и плагин Asciidoctor Diagram устанавливаются в образ.

```sh
make labs                # все лабораторные: HTML и PDF
make labs-html           # только HTML
make labs-pdf            # только PDF
make labs-list           # список исходных документов
make labs LAB=01-ex      # одна лабораторная, оба формата
```

Результаты сохраняются в `public/labs/` с сохранением каталогов и имён
исходников: например, `public/labs/01-ex/lab1.html` и `lab1.pdf`.
HTML содержит встроенные изображения и стили; PDF использует шрифты DejaVu
с поддержкой кириллицы. Содержимое `public/` не включается в Git.

Сборщик автоматически находит `.adoc` с заголовком документа `= ...`
в `project/materials/labs/`. Фрагменты для `include::` не должны содержать
заголовок такого уровня. `LAB` принимает имя каталога лабораторной или путь
к `.adoc` относительно `project/materials/labs/`; пути с пробелами нужно
заключать в кавычки. Исходные документы во время сборки доступны только для
чтения, результаты принадлежат запустившему сборку пользователю.

Образ собирается автоматически с использованием кэша Docker. Его конфигурация
и тема PDF находятся в `project/build/labs/`. Дополнительные Ruby-расширения
Asciidoctor размещаются в `project/scripts/asciidoctor/*.rb` и автоматически
загружаются для обоих форматов. Asciidoctor Diagram включает поддержку Graphviz;
для других движков добавьте необходимые пакеты в Dockerfile. Сборка документов
выполняется без сети; загрузка образа и зависимостей нужна при сборке образа.

Для запуска произвольного Ruby-скрипта в том же окружении:

```sh
make labs-ruby ARGS='project/scripts/example.rb'
```
