truncate table product_xref;
truncate table authors;
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
           when mod(rownum, 2) = 0 then 1
           else 0
         end
  from   product_xref pr
;
commit
/
