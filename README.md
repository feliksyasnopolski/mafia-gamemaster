# Mafia companion app

Приложение-компаньон для ведущего игры в турнирную (спортивную) Мафию. В разработке.

## Возможности

- [x] Случайно генерирует роли для игроков
- [x] Отслеживает состояние игры
  - [x] Роли игроков
  - [x] Живые и мёртвые игроки
  - [x] Активный (говорящий) игрок
  - [x] Выставленные на голосование игроки
  - [x] Голосования (частично)
    - Показывает порядок голосования
    - Все автоматически голосуют против единственного кандидата
    - Голосование завершается, если исход заранее понятен
    - Все оставшиеся голоса уходят в последнего выставленного игрока
    - Присутствует возможность "попила" стола
  - [x] Завершение игры при кол-ве мафий = кол-ву мирных или кол-ве мафий = 0
  - [x] Отслеживает ничейный исход игры 
- [x] Таймер
- [ ] Отслеживает "Лучший ход"
- [ ] Ведёт лог игры
- [ ] Позволяет поделиться логом игры
- [x] Отслеживает предупреждения игроков (частично)
  - Не производит никаких действий при достижении определённого количества предупреждений
- [x] Позволяет откатиться к предыдущему состоянию игры
- [ ] Составляет таблицу для турнира
- [x] Позволяет писать заметки по ходу игры
- [x] Увеличенные таймеры
- [ ] Внутриигровой плеер для музыки

## Запуск

### Android

Скачать готовую сборку для Android можно в разделе
[Releases](https://github.com/evgfilim1/mafia-companion/releases/). Если не знаете, что выбрать,
сначала попробуйте `arm64` вариант, затем `armeabi`. Если хотите запустить приложение в эмуляторе,
используйте `x86_64`.

### Браузер

Это приложение можно запустить в браузере. Для этого перейдите по ссылке в описании проекта.
Функционал приложения в браузере такой же, как и в Android-сборке. Веб-версия будет работать
без подключения к интернету, если добавить её на главный экран, подробнее см. в справке вашего
браузера или по запросу в поисковике.

Веб-сборка не тестировалась активно, поэтому могут быть ошибки.

### Другие платформы

Сборки для других платформ пока не планируются. Если вы хотите запустить приложение на других
платформах, соберите его самостоятельно с помощью инструментов Flutter.
Подробнее см. в [документации Flutter](https://docs.flutter.dev/).

## Помощь в разработке

Если вы нашли ошибку в приложении, пожалуйста, напишите мне в Telegram или создайте
[issue](https://github.com/evgfilim1/mafia-companion/issues/new).

Приложение написано на языке Dart с использованием фреймворка [Flutter](https://flutter.dev/).
Для начала разработки на Flutter смотрите [документацию](https://docs.flutter.dev/), которая
содержит руководства, примеры, советы по разработке под мобильные платформы и полный
[API-справочник](https://api.flutter.dev/).
