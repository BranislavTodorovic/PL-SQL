with dev1_list as
 (select distinct mt1.mapi_table_id, mt1.mapi_table_row_id, ms1.scr_number
    from priv_mapi.mapi_transaction mt1
   inner join priv_mapi.mapi_session ms1
      on ms1.mapi_session_id = mt1.mapi_session_id
   where ms1.mapi_repository_id != 7233 /* Not new repository */
     and mt1.mapi_transaction_date > to_date('2024-06-01', 'yyyy-mm-dd')),

leons_list as
 (select distinct mt1.mapi_table_id, mt1.mapi_table_row_id, ms1.scr_number
    from priv_mapi.mapi_transaction mt1
   inner join priv_mapi.mapi_session ms1
      on ms1.mapi_session_id = mt1.mapi_session_id
   where ms1.mapi_repository_id = 7233 /* New repository */
     and mt1.mapi_transaction_date > to_date('2024-06-01', 'yyyy-mm-dd'))

select dev1_list.mapi_table_id,
       mtab.mapi_table_name,
       dev1_list.mapi_table_row_id,
       listagg(dev1_list.scr_number, ',') within group(order by dev1_list.scr_number) as dev1_scr,
       listagg(leons_list.scr_number, ',') within group(order by leons_list.scr_number) as leons_scr
  from dev1_list
 inner join leons_list
    on leons_list.mapi_table_id = dev1_list.mapi_table_id
   and leons_list.mapi_table_row_id = dev1_list.mapi_table_row_id
 inner join priv_mapi.mapi_table mtab
    on mtab.mapi_table_id = dev1_list.mapi_table_id
 where mtab.mapi_schema_type_id = 201 /* Metadata */
 group by dev1_list.mapi_table_id,
          mtab.mapi_table_name,
          dev1_list.mapi_table_row_id
 order by mapi_table_name, mapi_table_row_id