# Unofficial Profi 5.06 repository 

Mainboard forum: http://zx-pk.ru/threads/21644-plata-protsessora-profi-v5-06.html
Upperboard forum: http://zx-pk.ru/threads/21356-plata-periferii-profi-v5-06.html

## Ветка mega_spi

Данная ветка содержит экспериметнальную прошивку для CPLD и новую реализацию контроллера клавиатуры / мыши.

Отличительные особенности реализации:
- безвейтовость
- работа клавиатуы в турбо-режимах
- работа всех функциональных кнопок
- реализация профиковского стандарта XT клавиатуры и стандартного ZX Spectrum режима
- поддержка мыши (2-,3-кнопочных, со скроллером и без)

Контроллер клавиатуры может быть собран как на дополнительной платке (на базе Atmega328) без доработок платы верхушки, 
так и на базе Atmega8515, на которой изначально был собран контроллер, но с небольшими доработками платы. 

## Принцип работы

Функция контроллера - получить данные от PS/2 клавиатуры и мыши и передать их по последовательному протоколу в виде матрицы 
состояний механической клавиатуры ZX Spectrum + нескольких байт координат от мыши. Всю остальную работу берет на себя CPLD, моментально декодируя 
данные и подставляя готовые состояния при дешифрации порта #FE. Скорость потока от МК к CPLD составляет около 1кГц. Если подключена мышь - скорость потока 
немного снижается, но по ощущениям - это никак не влияет на скорость работы клавиатуры.

## Контроллер на базе Atmega328

Данный контроллер собирается в виде отдельной платки, которая вставляется в панельку вместо Atmega8515. Контроллер выполнен на базе МК Atmega328.
Программирование осуществляется из среды Arduino IDE 1.6.1 или выше. Никакие модификации платы верхушки не требуются.

## Контроллер на базе Atmega8515

Данный контроллер смотрится как родной, но требуются некоторые модификации платы верхушки:
- замена кварца ZQ3 на 16МГц
- добавление 3х подтяжек на 3.3В (резисторов по 10к) на ножках микросхемы 14,15,5. данная модификация крайне необходима, потому как atmega отдает данные, эмуляруя открытый коллектор, 
при этом логическую "1" должны формировать как раз эти подтяжки. 

Программирование контроллера также осуществляется из среды Arduino IDE, но перед этим необходимо доставить дополнительный комплект поддержки железа из https://github.com/MCUdude/MajorCore

## Готовые прошивки
Готовые hex-файлы для прошивки с помощью программатора готовы и доступны из git-репозитария.

Fuse биты для Atmega8515:
Low Fuse	0b10111111
High Fuse	0xD4

Fuse биты для Atmega328:
Low Fuse	0xFF
High Fuse	0xDA
Extended Fuse	0x05
