column author format a30
select a.id_xref, substr(a.author, 1, 30) author, a.end_date from authors a
;
merge into authors aa
using (
        select rownum rn, a.id_xref, pr.out_of_print_date end_date
        from   authors a,
               product_xref pr
        where  a.id_xref = pr.id_xref
        and    a.end_date <> pr.out_of_print_date
      ) u
on    (aa.id_xref = u.id_xref and u.rn < 3)
when matched then
  update set
    aa.end_date = case rn when 1 then u.end_date - 2 when 2 then u.end_date else aa.end_date end
;
commit;
select a.id_xref, substr(a.author, 1, 30) author, a.end_date from authors a
;