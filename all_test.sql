set serveroutput on
set pause off
set linesize 120
set pagesize 80

@@test/build_test_data.sql

spool author_validate  
prompt ================================================
prompt Validate AUTHORS
prompt ================================================
@@test/author_validate.sql
spool off

spool objtree_validate
prompt ================================================
prompt Validate OBJTREE
prompt ================================================
@@test/objtree_validate.sql
spool off

prompt All srcipts complete
exit