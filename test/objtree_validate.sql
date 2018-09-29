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

column title format a30
column system format a15
prompt OBJTREE
select * from objtree o;

begin
--  dbms_session.reset_package; return;
  dbms_output.enable(1000000);
  etl_api.validate_data(
    p_base_table     => 'PRODUCT_XREF',
    p_base_col       => 'SYSTEM',
    p_validate_table => 'OBJTREE',
    p_validate_col   => 'SYSTEM',
    p_join_col       => 'OBJ_ID',
    p_err_nm         => 'E_OT_SYSTEM_END'
  );
  commit;
end;
/
column error_nm format a50
select * from errors
; 
column xref_table_name format a30
column src_key_val format a30
select * from exceptions
;
--заменим system:
-- в одной строке на другое не корректное значение
-- в другой на корректное
merge into objtree oo
using (
        select rownum rn, o.id, pr.system
        from   objtree o,
               product_xref pr
        where  o.obj_id = pr.obj_id
        and    o.system <> pr.system
      ) u
on    (oo.id = u.id and rn < 3)
when matched then
  update set
    oo.system = case rn when 1 then '^' || substr(u.system, 2, 13) when 2 then u.system else oo.system end
;
commit;
prompt
prompt SECOND SCAN
prompt
prompt OBJTREE
select * from objtree
;
begin
--  dbms_session.reset_package; return;
  dbms_output.enable(1000000);
  etl_api.validate_data(
    p_base_table     => 'PRODUCT_XREF',
    p_base_col       => 'SYSTEM',
    p_validate_table => 'OBJTREE',
    p_validate_col   => 'SYSTEM',
    p_join_col       => 'OBJ_ID',
    p_err_nm         => 'E_OT_SYSTEM_END',
    p_validate_stmt  => 'product_xref.system = objtree.system'
  );
  commit;
end;
/
select * from errors
; 
select * from exceptions
;