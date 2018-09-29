set serveroutput on
set linesize 120
set pagesize 80

prompt
prompt FIRST SCAN
prompt
column system format a20
column title format a30
prompt PRODUCT_XREF
select * from product_xref;

column author format a30
prompt AUTHORS
select a.id_xref, substr(a.author, 1, 30) author, a.end_date from authors a;

begin
  etl_api.validate_data(
    p_base_table     => 'PRODUCT_XREF',
    p_base_col       => 'OUT_OF_PRINT_DATE',
    p_validate_table => 'AUTHORS',
    p_validate_col   => 'END_DATE',
    p_join_col       => 'ID_XREF',
    p_err_nm         => 'E_AT_DATE_END'
  );
  commit;
end;
/
column error_nm format a50
select * from   errors
; 
column xref_table_name format a30
column src_key_val format a30
select * from   exceptions
;
--заменим end_date:
-- в одной строке на другую не корректную дату
-- в другой на корректную
merge into authors aa
using (
        select rownum rn, a.id_xref, pr.out_of_print_date end_date
        from   authors a,
               product_xref pr
        where  a.id_xref = pr.id_xref
        and    a.end_date <> pr.out_of_print_date
      ) u
on    (aa.id_xref = u.id_xref and rn < 3)
when matched then
  update set
    aa.end_date = case rn when 1 then u.end_date - 2 when 2 then u.end_date else aa.end_date end
;
commit;
prompt
prompt SECOND SCAN
prompt
prompt AUTHORS
select a.id_xref, substr(a.author, 1, 30) author, a.end_date from authors a
;
begin
  etl_api.validate_data(
    p_base_table     => 'PRODUCT_XREF',
    p_base_col       => 'OUT_OF_PRINT_DATE',
    p_validate_table => 'AUTHORS',
    p_validate_col   => 'END_DATE',
    p_join_col       => 'ID_XREF',
    p_err_nm         => 'E_AT_DATE_END',
    p_validate_stmt  => 'product_xref.out_of_print_date = authors.end_date'
  );
  commit;
end;
/
select * from errors
; 
select * from exceptions
;