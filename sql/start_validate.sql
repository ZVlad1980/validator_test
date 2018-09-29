begin
--  dbms_session.reset_package; return;
  dbms_output.enable(1000000);
  etl_api.validate_data(
    p_base_table     => 'PRODUCT_XREF',
    p_base_col       => 'OUT_OF_PRINT_DATE',
    p_validate_table => 'AUTHORS',
    p_validate_col   => 'END_DATE',
    p_join_col       => 'ID_XREF',
    p_err_nm         => 'E_DATE_END'
  );
  commit;
end;
/
select *
from   errors
/
select *
from   exceptions
/
