Репозиторий:
/sql  - установочные скрипты
/test - скрипты тестирования
/test/build_test_data.sql  - заливка данных в таблицы PRODUCT_XREF, AUTHORS, OBJTREE
/test/author_validate.sql  - два теста для таблицы AUTHORS
/test/objtree_validate.sql - два теста для таблицы OBJTREE

Сценарий тестирования:
  1. Подготовка данных к тестированию, во входных таблицах AUTHORS и OBJTREE половина записей - не валидные
  2. Первичное сканирование и регистрация ошибок в Exceptions
  3. Исправление данных входной таблицы:
    3а) в одной строке новое не валидное значение
    3б) во второй строке - валидное значение
  4. Вторичное сканирование и корректировка записей в Exceptions
    (* Вторичное сканирование запускается с параметром p_validate_stmt)

install.sql - сценарий установки под sqlplus, подключенный к целевой схеме
all_test.sql - запуск всех тестов

Окружение выполнения задания:
OS: Linux MINT 18
Oracle Database: 12.2.0.1.0

Бизнес задача: Необходимо привести данные в разных входных таблицах в соответсвие с эталонной таблицей.
Для этого нужно вытащить из входных таблиц все данные которые не совпадают с эталоном и занести их в EXCEPTIONS вместе с данными несоответствия (код ошибки, значение из входной таблицы) для дальнейшего разбора ручным либо автоматическим способом.
После каждого разбора производится еще один цикл полного сравнения-сканирования всех данных со входной таблицы.
Если после обработки и рескана входной таблицы ошибка изменилась либо устранена, то данные в EXCEPTIONS следует изменить либо удалить.
Наличие занесенной ошибки в EXCEPTIONS определяется по полям ID_XREF+XREF_TABLE_NAME +ERR_ID+SRC_KEY_VAL.


Необходимо реализовать в виде встроенной процедуры часть процесса связанную со сканированием, сравнением с эталоном и изменение EXCEPTIONS.

В качестве входных параметров процедура должна уметь принимать(для создания динамического query)
1. Имя эталонной таблицы + эталонное поле для сравнения (Пример: PRODUCT_XREF and OUT_OF_PRINT_DATE). Эталонная таблица всегда содержит поле "ID_XREF"
2. Имя входной таблицы + поле для сравнения (Пример: AUTHORS and END_DATE)
3. Join Constraint: ID_XREF либо OBJ_ID (Пример: PRODUCT_XREF.ID_XREF=AUTHORS.ID_XREF)
4. Сравнительный Constraint определяющий совпадение с эталоном (Пример: PRODUCT_XREF.OUT_OF_PRINT_DATE = AUTHORS.END_DATE)
   Если Constraint не выполнен, то входные данные не совпадают с эталоном.
   Сравнительный Constraint может быть сложным и состоять из нескольких сравнений по нескольким полям.
5. Имя ошибки ERR_NM


Эталонная таблица:
CREATE TABLE "PRODUCT_XREF" (
                    "ID_XREF" NUMBER(38,0) NOT NULL ENABLE, 
                    "SYSTEM" CHAR(14 CHAR) NOT NULL ENABLE, 
                    "OBJ_ID" NUMBER(38,0), 
                    "END_DATE" DATE, 
                    "OUT_OF_PRINT_DATE" DATE, 
                    "TITLE"      VARCHAR2(1000 CHAR),
                    CONSTRAINT "PRODUCT_XREF_PK" PRIMARY KEY ("ID_XREF")
)

Таблица ошибок:
CREATE TABLE "ERRORS" (
                    "ERR_ID" NUMBER NOT NULL ENABLE, 
                    "ERR_NM" VARCHAR2(30 CHAR), 
                     CONSTRAINT "ERRORS_PK" PRIMARY KEY ("ERR_ID")
)

Таблица несоответствий :
CREATE TABLE "EXCEPTIONS" (
                    "ID_XREF" NUMBER, 
                    "XREF_TABLE_NAME" VARCHAR2(30 CHAR),
                    "SRC_KEY_VAL" VARCHAR2(255 CHAR),  -- Значение из входной таблицы
                    "ERR_ID" NUMBER NOT NULL ENABLE, 
                    "CREATE_DATE" DATE,
                    CONSTRAINT "EXCEPTIONS_ERR_ID_FK" FOREIGN KEY ("ERR_ID") REFERENCES "ERRORS" ("ERR_ID") ENABLE
)
Фактически уникальный ключ этой таблицы ID_XREF+XREF_TABLE_NAME+ERR_ID


Имя и структуру входной таблицы придумать самостоятельно.
Как примеры:
CREATE TABLE "AUTHORS" (
                     "ID_XREF" NUMBER(38,0) NOT NULL ENABLE, 
                     "AUTHOR"  CHAR(100 CHAR) NOT NULL ENABLE,
                     "END_DATE" DATE
                     CONSTRAINT "AUTHORS_PK" PRIMARY KEY ("ID_XREF")
)
CREATE TABLE "OBJTREE" (
                    "ID" NUMBER(38,0) NOT NULL ENABLE, 
                    "OBJ_ID" NUMBER(38,0),
                    "SYSTEM" CHAR(14 CHAR) NOT NULL ENABLE,
                    "TITLE"      VARCHAR2(1000 CHAR)
                     CONSTRAINT "OBJTREE_PK" PRIMARY KEY ("ID")
)
