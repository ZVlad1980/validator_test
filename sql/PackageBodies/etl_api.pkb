create or replace package body etl_api is

  G_UNIT_NAME constant varchar2(30) := $$PLSQL_UNIT;
  
  
  /**
   * Процедура put - обвертка для вывода сообщений
   */
  procedure put(
    p_message varchar2,
    p_eol     boolean default true
  ) is
  begin
    if p_eol then
      dbms_output.put_line(p_message);
    else
      dbms_output.put(p_message);
    end if;
  end;

  /**
   * Процедура show_errors отображает описание ошибки
   */
  procedure show_errors(
    p_line    int,
    p_message varchar2
  ) is
  begin
    put(rpad('-', 40, '-'));
    put('(Error) ' || G_UNIT_NAME || '(' || p_line || '): ' || p_message);
    put('  Error stack: ' || chr(10) || dbms_utility.format_error_stack);
    put('  Backtrace: ' || chr(10) || dbms_utility.format_error_backtrace);
    put('  Call stack: ' || chr(10) || dbms_utility.format_call_stack);
  end show_errors;
  
  /**
   * Функция get_error_id возвращает ID ошибки по ее имени,
   *  Если ошибка по имени не найдена - создает новую
   */
  function get_error_id(
    p_err_nm varchar2
  ) return errors.err_id%type is
    l_result errors.err_id%type;
  begin
    
    begin
      select err.err_id
      into   l_result
      from   errors err
      where  err.err_nm = p_err_nm;
    exception
      when no_data_found then
        insert into errors(err_id, err_nm)
          values(errors_seq.nextval, p_err_nm)
          returning err_id into l_result;
    end;
    
    return l_result;
  
  exception
    when others then
      show_errors($$PLSQL_LINE, 'get_error_id(' || p_err_nm || ')');
      raise;
  end;
  
  /**
   * Функция get_cursor возвращает курсор валидации данных
   */
  function get_cursor(
     p_base_table     varchar2,
     p_base_col       varchar2,
     p_validate_table varchar2,
     p_validate_col   varchar2,
     p_join_col       varchar2,
     p_validate_stmt  varchar2,
     p_err_id         errors.err_id%type
  ) return     sys_refcursor is
    l_result   sys_refcursor;
    l_cmp_stmt varchar2(1024);
    l_query    varchar2(32767);
  begin
    l_cmp_stmt := 
      case
        when p_validate_stmt is null then
          p_base_table || '.' || p_base_col
          || ' = '
          || p_validate_table || '.' || p_validate_col
        else
          p_validate_stmt
      end;
    
    l_query := '
select ' || p_base_table || '.id_xref id_xref,
       ''' || upper(p_base_table) || ''' xref_table_name,
       to_char(' || p_validate_table || '.' || p_validate_col || ') src_key_val,
       ex.err_id,
       case
         when not(' || l_cmp_stmt || ') then
           ''Y''
       end is_error
from   ' || p_base_table     || ',
       ' || p_validate_table || ',
       exceptions ex
where  ex.err_id(+) = :err_id
and    ex.xref_table_name(+) = ''' || upper(p_base_table) || '''
and    ex.id_xref(+) = ' || p_base_table || '.id_xref
and    ' || p_base_table || '.' || p_join_col || ' = ' || p_validate_table || '.' || p_join_col
;
    
    l_query := 'select t.id_xref,
       t.xref_table_name,
       t.src_key_val,
       t.err_id,
       t.is_error
from   (' || l_query || ') t where t.is_error = ''Y'' or t.err_id is not null'
;
    put('p_err_id: ' || p_err_id);
    put(l_query);
    
    open l_result for l_query
      using p_err_id;
    
    return l_result;
  
  exception
    when others then
      show_errors($$PLSQL_LINE, 'get_cursor');
  end get_cursor;
  
  /**
   */
  procedure validate_data(
    p_cursor   sys_refcursor,
    p_err_id   errors.err_id%type
  ) is
    type t_exceptions is table of exceptions%rowtype;
    
    l_exceptions_new t_exceptions;
    l_exceptions_upd t_exceptions;
    l_exceptions_del t_exceptions;
    
    l_exception_rec exceptions%rowtype;
    l_is_error   varchar2(1);
    
    procedure push_(
      p_collection     in out nocopy t_exceptions,
      p_exception_rec  in out nocopy exceptions%rowtype
    ) is
    begin
      p_collection.extend(1);
      p_collection(p_collection.count) := p_exception_rec;
    end push_;
    
  begin
    l_exceptions_new := t_exceptions();  
    l_exceptions_upd := t_exceptions();  
    l_exceptions_del := t_exceptions();  
    
    loop
      fetch p_cursor
        into l_exception_rec.id_xref,
             l_exception_rec.xref_table_name,
             l_exception_rec.src_key_val,
             l_exception_rec.err_id,
             l_is_error
      ;
      exit when p_cursor%notfound;
      
      if l_is_error is null then
        push_(l_exceptions_del, l_exception_rec);
      elsif l_exception_rec.err_id is null then
        l_exception_rec.err_id := p_err_id;
        push_(l_exceptions_new, l_exception_rec);
      else
        push_(l_exceptions_upd, l_exception_rec);
      end if;
      
    end loop;
    
    forall i in 1..l_exceptions_del.count
      delete from exceptions e
      where  e.id_xref = l_exceptions_del(i).id_xref
      and    e.xref_table_name = l_exceptions_del(i).xref_table_name
      and    e.err_id = l_exceptions_del(i).err_id;
    
    put('Exceptions: delete '  || case when l_exceptions_del.count > 0 then sql%rowcount else 0 end || ' row(s)');
    
    forall i in 1..l_exceptions_upd.count
      update exceptions e
      set    e.src_key_val = l_exceptions_upd(i).src_key_val
      where  e.src_key_val <> l_exceptions_upd(i).src_key_val
      and    e.id_xref = l_exceptions_upd(i).id_xref
      and    e.xref_table_name = l_exceptions_upd(i).xref_table_name
      and    e.err_id = l_exceptions_upd(i).err_id;
    
    put('Exceptions: update '  || case when l_exceptions_upd.count > 0 then sql%rowcount else 0 end || ' row(s)');
    
    forall i in 1..l_exceptions_new.count
      insert into exceptions(
        id_xref,
        xref_table_name,
        src_key_val,
        err_id,
        create_date
      ) values (
        l_exceptions_new(i).id_xref,
        l_exceptions_new(i).xref_table_name,
        l_exceptions_new(i).src_key_val,
        l_exceptions_new(i).err_id,
        sysdate
      ); 
    
    put('Exceptions: add '  || case when l_exceptions_new.count > 0 then sql%rowcount else 0 end || ' row(s)');
    
  exception
    when others then
      show_errors($$PLSQL_LINE, 'validate_data');
      raise;
  end validate_data;
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
  ) is
    l_cursor sys_refcursor;
    l_err_id errors.err_id%type;
  begin
    
    l_err_id := get_error_id(p_err_nm);
    
    l_cursor := get_cursor(
      p_base_table     => p_base_table    ,
      p_base_col       => p_base_col      ,
      p_validate_table => p_validate_table,
      p_validate_col   => p_validate_col  ,
      p_join_col       => p_join_col      ,
      p_validate_stmt  => p_validate_stmt ,
      p_err_id         => l_err_id
    );
    
    validate_data(
      p_cursor => l_cursor,
      p_err_id => l_err_id
    );
    
    close l_cursor;
    
  exception
    when others then
      show_errors($$PLSQL_LINE, 'validate_data');
      
      if l_cursor%isopen then
        close l_cursor;
      end if;
      
      raise;
  end validate_data;
  
end etl_api;
/
