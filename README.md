# Unofficial Profi 5.06 repository 

Mainboard forum: http://zx-pk.ru/threads/21644-plata-protsessora-profi-v5-06.html
Upperboard forum: http://zx-pk.ru/threads/21356-plata-periferii-profi-v5-06.html

## Ветка mega_real_spi

Данная ветка содержит экспериметнальную прошивку для CPLD и новую реализацию контроллера клавиатуры / мыши / RTC.

Отличительные особенности реализации:
- безвейтовость
- работа клавиатуы в турбо-режимах
- работа всех функциональных кнопок
- реализация профиковского стандарта XT клавиатуры и стандартного ZX Spectrum режима
- поддержка мыши (2-,3-кнопочных, со скроллером и без)
- поддержка RTC (только чтение регистров времени и даты)

Контроллер клавиатуры собран на дополнительной платке (на базе Atmega328) без доработок платы верхушки. 

## Принцип работы

Функция контроллера - получить данные от PS/2 клавиатуры и мыши и передать их по SPI протоколу в виде матрицы 
состояний механической клавиатуры ZX Spectrum + нескольких байт координат от мыши. Всю остальную работу берет на себя CPLD, моментально декодируя данные и подставляя готовые состояния при дешифрации порта #FE. Скорость потока от МК к CPLD составляет около 1кГц. Если подключена мышь - скорость потока немного снижается, но по ощущениям - это никак не влияет на скорость работы клавиатуры.

### Специальные клавиши и клавиатурные комбинации
- Scroll Lock: переключает turbo режим, значение сохраняется в энергонезависимой памяти
- Print Screen: переключает раскладку клавиатуры profi / zx spectrum
- Ctrl+Alt+Del: формирует сигнал сброса 
- Ctrl+Alt+Backpace: принудительная переинициализация контроллера
- Ctrl+Alt+Esc: кнопка Magic

### Установка даты и времени RTC часиков верхушки
Так как в контроллере не реализована эмуляция RTC в полной мере (только чтение), для установки времени можно воспользоваться последовательным соединением с контроллером.
Реализованные команды:
- HELP выведет встроенную подсказку
- GET выведет текущее время
- SET YYYY MM DD HH II SS W установит RTC в заданную дату/время/день недели

## Контроллер на базе Atmega328

Данный контроллер собирается в виде отдельной платки, которая вставляется в панельку вместо Atmega8515. Контроллер выполнен на базе МК Atmega328.Программирование осуществляется из среды Arduino IDE 1.6.1 или выше. Никакие модификации платы верхушки не требуются.

## Готовые прошивки
Готовые hex-файлы для прошивки с помощью программатора готовы и доступны из git-репозитария.

Fuse биты для Atmega328:
Low Fuse	0xFF
High Fuse	0xDA
Extended Fuse	0x05

