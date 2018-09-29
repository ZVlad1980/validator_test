create sequence product_xref_seq;
CREATE TABLE PRODUCT_XREF (
  ID_XREF           NUMBER(38,0) NOT NULL ENABLE, 
  SYSTEM            CHAR(14 CHAR) NOT NULL ENABLE, 
  OBJ_ID            NUMBER(38,0), 
  END_DATE          DATE, 
  OUT_OF_PRINT_DATE DATE, 
  TITLE             VARCHAR2(1000 CHAR),
  CONSTRAINT PRODUCT_XREF_PK
    PRIMARY KEY (ID_XREF)
)
;
--Таблица ошибок:
create sequence errors_seq;
CREATE TABLE ERRORS (
  ERR_ID            NUMBER NOT NULL ENABLE, 
  ERR_NM            VARCHAR2(30 CHAR), 
  CONSTRAINT ERRORS_PK 
    PRIMARY KEY (ERR_ID)
)
;
--Таблица несоответствий :
CREATE TABLE EXCEPTIONS (
  ID_XREF           NUMBER, 
  XREF_TABLE_NAME   VARCHAR2(30 CHAR),
  SRC_KEY_VAL       VARCHAR2(255 CHAR),  -- Значение из входной таблицы
  ERR_ID            NUMBER NOT NULL ENABLE, 
  CREATE_DATE       DATE,
  CONSTRAINT EXCEPTIONS_ERR_ID_FK 
    FOREIGN KEY (ERR_ID) 
    REFERENCES ERRORS (ERR_ID)
    ENABLE
)
;
--Фактически уникальный ключ этой таблицы ID_XREF+XREF_TABLE_NAME+ERR_ID
--Имя и структуру входной таблицы придумать самостоятельно.
--Как примеры:
create sequence authors_seq;
CREATE TABLE AUTHORS (
  ID_XREF           NUMBER(38,0)   NOT NULL ENABLE, 
  AUTHOR            CHAR(100 CHAR) NOT NULL ENABLE,
  END_DATE          DATE,
  CONSTRAINT AUTHORS_PK 
    PRIMARY KEY (ID_XREF)
)
;
create sequence objtree_seq;
CREATE TABLE OBJTREE (
  ID                NUMBER(38,0)  NOT NULL ENABLE, 
  OBJ_ID            NUMBER(38,0),
  SYSTEM            CHAR(14 CHAR) NOT NULL ENABLE,
  TITLE             VARCHAR2(1000 CHAR),
  CONSTRAINT OBJTREE_PK 
    PRIMARY KEY (ID)
)
;
