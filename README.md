# Conspects 4 semester

Здесь располагается честная попытка автора репозитория ~~начать учиться~~ вести конспект. 

Речь идёт о четвёртом семестре КТ ИТМО, следующих курсах:

- Технологии программирования, оно же Java Advanced
- Программирование на видеокартах
- Что-нибудь ещё, если захочется...

### 
Устройство репозитория

- Некоторое место занимают файлы gradle. Так надо, для одновременной компиляции всего во всех вариантах
- Стили для всего конспекта (пока что только `header.typ`). 
- `mode.txt` для общения gradle с документом.
- Собственно исходники конспектов в sources
- Скомпилированные конспекты в нескольких темах: 
  - dev -- Белый на чёрном
  - dark -- Светлый на тёмном
  - sepia -- Чёрный на тёплом светлом
  - regular -- Чёрный на белом
  - print -- Вариант для печати (оттенки серого даже в рисунках, длина страницы А4)

  -- соответственно, в output/<соответствующий вариант>. 

### Как это собирать локально

Для этого в системе должен быть установлен typst. Соответственно, можно запустить сборку через 

```
./gradlew typst-compile
```

Как это работает? Не спрашивайте, сэр Генри, не спрашивайте.

      
Сначала для каждого исходникак через typst query получаем список возможных режимов (записанных в `#metadata(modes.keys()) #label("available-modes")`), потом по очереди пишем имя режима в mode.txt и компилируем в соответствующую папку. В пределах этого проекта этот список постоянен (см. выше), но в принципе работать будет и по-другому. Feel free утащить в свой проект, когда-нибудь у меня руки дойдут запилить gradle plugin... Да...
