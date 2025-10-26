# БезОС - проект для подготовки материалов

В настоящем репозитории содержатся все исходные для формирования материалов по курсу Безопасность Операционных Систем:

1. презентации для лекций (`asciidoc` to `reveal.js`)
2. конспекты лекций и доп. материалы
3. методички для ЛР
4. список вопросов к экзамену


## Сборка и запуск презентаций

```bash
$ cd project
$ npm install
$ npm run build
$ npm run serve
```

Для удобства создания презентаций удобнее запускать сервер с автосборкой и авто перезагрузкой:
```bash
$ npm run serve-dev
```


```bash
gem install asciidoctor-pdf

gem install rouge
gem install pygments.rb
gem install coderay

gem install text-hyphen

gem install asciidoctor-pdf-mathjax
```
