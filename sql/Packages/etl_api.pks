create or replace package etl_api is

  -- Author  : ACER E15
  -- Created : 29.09.2018 7:04:58
  -- Purpose : 

  /**
   * Процедура validate_data выполняет проверку данных таблицы по эталонным данным
   *   Все данные которые не совпадают с эталоном и занести в EXCEPTIONS вместе с данными 
   *     несоответствия (код ошибки, значение из входной таблицы) 
   *   После каждого разбора производится еще один цикл полного сравнения-сканирования всех данных из 
   *     входной таблицы.
   *   Если после обработки и рескана входной таблицы ошибка изменилась либо устранена, 
   *     то данные в EXCEPTIONS следует изменить либо удалить.
   * Наличие занесенной ошибки в EXCEPTIONS определяется по полям ID_XREF+XREF_TABLE_NAME +ERR_ID+SRC_KEY_VAL.
   *
   * p_base_table     - Имя эталонной таблицы
   * p_base_col       - эталонное поле для сравнения
   * p_validate_table - Имя входной таблицы
   * p_validate_col   - поле для сравнения во входной таблице
   * p_join_col       - Join Constraint: ID_XREF либо OBJ_ID (Пример: PRODUCT_XREF.ID_XREF=AUTHORS.ID_XREF)
   * p_err_nm         - Имя ошибки ERR_NM
   * p_validate_stmt  - Необязательный. Сравнительный Constraint определяющий совпадение с эталоном (Пример: PRODUCT_XREF.OUT_OF_PRINT_DATE = AUTHORS.END_DATE)
   *                    Если Constraint не выполнен, то входные данные не совпадают с эталоном.
   *                    Сравнительный Constraint может быть сложным и состоять из нескольких сравнений по нескольким полям.
   *                    Если не задан - констрейнт будет p_base_col = p_validate_col
   * 
   */
  procedure validate_data(
     p_base_table     varchar2,
     p_base_col       varchar2,
     p_validate_table varchar2,
     p_validate_col   varchar2,
     p_join_col       varchar2,
     p_err_nm         varchar2,
     p_validate_stmt  varchar2 default null
  );
  
end etl_api;
/
