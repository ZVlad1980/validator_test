truncate table product_xref;
truncate table authors;
truncate table objtree;
truncate table exceptions;
delete from errors;

insert into product_xref(
  id_xref,
  system,
  obj_id,
  end_date,
  out_of_print_date,
  title
) select product_xref_seq.nextval,
         substr(o.object_type, 1, 14),
         o.object_id,
         trunc(o.created),
         trunc(o.created) + 10,
         o.object_name
  from   user_objects o
  where  rownum <= 10
;
insert into authors(
  id_xref,
  author,
  end_date
) select authors_seq.nextval,
         initcap(substr(pr.title, 1, 100)),
         pr.out_of_print_date + case
           when mod(rownum, 2) = 0 then 1 --в каждой второй записи изменим дату
           else 0
         end
  from   product_xref pr
;
insert into objtree(
  id    ,
  obj_id,
  system,
  title 
) select objtree_seq.nextval,
         pr.obj_id,
         case
           when mod(rownum, 2) = 0 then '$' || substr(pr.system, 2, 13) --каждой второй записи заменим первый символ на знак доллара
           else pr.system
         end,
         pr.title
  from   product_xref pr
;
commit
/
declare
  procedure gather_stats(
    p_table_name varchar2
  ) is
  begin
    dbms_stats.gather_table_stats(
      user,
      p_table_name,
      cascade => true
    );
  end gather_stats;
begin
  for t in (select table_name
            from   user_tables ut
            where  ut.table_name in (
                     'PRODUCT_XREF',
                     'AUTHORS',
                     'OBJTREE'
                   )
           ) loop
    gather_stats(t.table_name);
  end loop;
end;
/