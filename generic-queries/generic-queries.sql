---------------------------------------------------------------------------------------------------------
--bundle check
select bundle_date, deploy_bundle_label, deploy_predecessor, deploy_svn_branch, deployed_date, deploy_status, deploy_region, userid, deploy_type, prd_target_date
from priv_st.deploy_log where deploy_bundle_label like '%dp2_pag_%' order by bundle_date asc

select * from priv_st.deploy_log where deploy_bundle_label like '%lli_erate_auto_nc_%' order by bundle_date asc
select deploy_bundle_label, prd_target_date from priv_st.deploy_log where deploy_bundle_label like '%lli_erate_auto_nc_31%'
---------------------------------------------------------------------------------------------------------
--bv_path test
select pkg_os_object_io.fn_object_bv_path_get(1, 
                                              1, 
                                              462775772269, --object id
                                              '31408737') from dual; --bv path id

--get text value from vll                                     
select pkg_os_reference_lookup.fn_get_lookup_text(1, 
                                                  1, 
                                                  462775772269, --object id
                                                  28920705, --bv id
                                                  2) from dual;  --value from vll                                           

--bv set
begin pkg_os_object_io.sp_object_bv_set(1,
                                        1,
                                        462825996969, --object id
                                        27995005, --bv id
                                        null); --value you want to set for bv
end;

--rule test
select pkg_os_expression.fn_evaluate_expression(1, 1, 745862495586 , 11237037 ) from dual;


--lookup list text get - lookup_list_id, enum from list
select pkg_os_lookup.fn_lookup_list_text_get(5050401, f.feature_jurisdiction_set_id) from dual;

select pkg_os_lookup.fn_lookup_list_short_text_get( 5323105, 2) from dual;
---------------------------------------------------------------------------------------------------------

--user_source, all_source check
select * from user_source where lower(text) like '%dm_household_named_insured%'
select * from user_source where text like '%13466737%'
select * from all_source where text like '%13466737%'

---------------------------------------------------------------------------------------------------------
--months between check
select months_between(
         to_date('05/17/2024' , 'mm/dd/yyyy'),
         to_date('01/28/1952' , 'mm/dd/yyyy')
       ) / 12 as age_years
from dual;


--checking dates between days
select (abs(trunc(months_between(to_date('20211102000100', 'yyyymmddhh24miss'), to_date('2023112500100' , 'yyyymmddhh24miss')) *30))) num_of_days from dual

--checking dates between months
select abs(trunc(months_between(to_date('20230730000100', 'yyyymmddhh24miss'), to_date('20221103000100', 'yyyymmddhh24miss')))) num_of_months from dual
---------------------------------------------------------------------------------------------------------

--delete objects
declare

type grades_arr is varray(20) of number;

ids_arr grades_arr;

begin

ids_arr := grades_arr(754800262546,
            754800262566,
            754800262586); --object ids that should be deleted

for i in 1.. ids_arr.count_loop
priv_api.pkg_os_object.sp_object_delete(1, 1, null, ids_arr(i), null, null, false);

end loop;

end;
---------------------------------------------------------------------------------------------------------
--   Name: Bran Todorovic
--   Date: 05/29/2026
--   Project: Production Support
--   Rally ID: DE108896 - pure online error
--	 Comment: Updating policy expiration date

--hot fix script example
declare
v_dm char(1) := 't';
begin
priv_api.pkg_os_object_io.sp_object_bv_set(1, 1, 739793584009, 499, to_char( to_date ('20270214000100','yyyymmddhh24miss'), 'yyyymmddhh24miss') ); -- expiration date
priv_api.pkg_os_datamart.sp_datamart_update_row(1, 1, 739793584009, v_dm); 
end;
/
---------------------------------------------------------------------------------------------------------
--query to get xml attributes related to cell names on ui, bv ids, per product id
with xsa_data as
 (select xsa.xml_schema_attribute_id,
         xsa.xml_schema_object_id,
         xso.xml_object_type_id as object_type_id,
         pkg_os_object_type.fn_object_type_name_get(xso.xml_object_type_id, 1, 1) as object_type_name,
         xso.xml_schema_object_tag as xml_object_type_tag_name,
         xsa.attribute_logical_data_type_id as data_type,
         xsa.attribute_tag as tag,
         xsa.attribute_bv_path as bv_path,
         xsa.attribute_skip_tf as skip_tf,
         xsa.attribute_list_id as list_id,
         xsa.xml_schema_id,
         xsa.xml_schema_version_id,
         xsa.inclusion_rule_id,
         priv_api.pkg_os_bv.fn_bv_path_bv_get(xsa.attribute_bv_path) as business_variable_id
    from priv_md.xml_schema_attribute xsa
    left join priv_md.xml_schema_object xso
      on xso.xml_schema_object_id = xsa.xml_schema_object_id
   where xsa.xml_schema_id = 52537), --policydwc xml schema id
plc_data as
 (select priv_api.pkg_os_bv.fn_bv_path_bv_get(plc.cell_business_variable_path) as business_variable_id,
         max(plc.b_cell_label) as cell_label_name
    from priv_md.page_layout_cell plc
   where plc.pd_product_id = 71533 --domestic workers comp
   group by priv_api.pkg_os_bv.fn_bv_path_bv_get(plc.cell_business_variable_path))
select xsa.xml_schema_attribute_id,
       xsa.xml_schema_object_id,
       xsa.object_type_id,
       xsa.object_type_name,
       xsa.xml_object_type_tag_name,
       xsa.data_type,
       xsa.tag,
       xsa.bv_path,
       xsa.business_variable_id,
       plc.cell_label_name,
       xsa.skip_tf,
       xsa.list_id,
       xsa.xml_schema_id,
       xsa.xml_schema_version_id,
       xsa.inclusion_rule_id
  from xsa_data xsa
  left join plc_data plc
    on plc.business_variable_id = xsa.business_variable_id
 order by xsa.xml_schema_attribute_id;
---------------------------------------------------------------------------------------------------------
--renewal rerate view
select * from priv_st.object o where o.object_id = 746199132599
    select count(*)
   -- into v_count
    from policy_renewal_rerate_vw v
    where v.policy_image_id = 123232;

--view example
select * from policy_renewal_rerate_vw
select dtx.policy_image_id
from priv_st.dragon_policy dp
inner join priv_st.dragon_policy_trx dtx on dtx.policy_id = dp.policy_id
inner join priv_st.dragon_household dh on dh.household_id = dp.household_id
and  dtx.policy_trx_status_id = 15402 --policytransactioncreated
and  dtx.policy_trx_type_id = 8 --renewal
and dp.policy_state_id = 71 --active
and dp.line_of_business not in (13733,13833,14537,14037) --hs,es,primary flood, coc
and dh.household_country = 'united states'
and (extract(year from dtx.policy_trx_eff_date) = extract(year from sysdate) or extract(year from dtx.policy_trx_eff_date - 1) = extract(year from sysdate - 1))
and trunc(dtx.policy_trx_eff_date) between trunc(sysdate - 45) and trunc(sysdate + 45)    
and (select count(1) 
     from priv_st.dm_underwriting_referral 
     where parent_object_id = dtx.policy_image_id
     and uw_trigger_relevant = 1
     and overridden = 2) = 0
---------------------------------------------------------------------------------------------------------

select * /* priv_service_perf_log_id,operation_label,session_user_name, (response_end_date - request_start_date) * 24 * 3600 as total_time_seconds,trim((request_end_date - request_start_date) * 24 * 3600) as request_create_seconds,
(response_end_date - response_start_date) * 24 * 3600 as resp_store_seconds,
(web_service_end_date - web_service_start_date) * 24 * 3600 as call_time_seconds,
request_start_date, request_end_date, response_start_date, response_end_date, web_service_start_date, web_service_end_date, request_xml_payload, response_xml_payload */
from priv_st.priv_service_perf_log where last_updt_date > sysdate -10-- and to_char(last_updt_date,'mm/dd/yyyy hh24:mi') = '12/20/2021 10:02' -- and session_id in (738288105369) -- request_start_date > to_date('11222021115900','mmddyyyyhh24miss')
--and priv_service_perf_log_id > 569416
and operation_label = 'nada auto market value'
--and session_user_name is not null
--and session_id in (738338007299)
--and context_object_id in ( 739301434599,739301433799)
--and request_start_date < to_date('11222021155500','mmddyyyyhh24miss')
--group by operation_label
and exception_stack_trace is not null
order by priv_service_perf_log_id desc


--perf log & external queue job status
select * from priv_st.priv_service_perf_log pf
where upper(pf.operation_label) like '%riskmeter_report_queue%' --riskmeter
--where pf.context_object_id = 765722355429
order by request_start_date desc


--external_queue_job_status
select * from priv_st.external_queue_job_status eqjs
where eqjs.queue_name = 'policy-carrier-rules-sapiens-queue'
and eqjs.household_id = 67522679419
order by eqjs.created_date desc;

select * from priv_st.external_queue_job_status 
where upper(queue_name) like '%riskmeter_report_queue%' 
order by job_id desc;
--------------------------------------------------------------------------------
--tpr report
select * from priv_st.ods_tpr_report_order tpr
where tpr.tpr_report_type = 'autoclue'
and tpr.household_id = 346490377219
order by tpr_order_date desc-- check autoclue reports for household
--------------------------------------------------------------------------------
-----scheduler script-----
begin                                 
    dbms_scheduler.create_job
    (
      job_name      =>  'lc360_1',
      job_type      =>  'plsql_block',
      job_action    =>  'begin priv_api.pkg_pv_custom_backfill_03.sp_lc360_sf_inspection(747724801579, 747724801579); end;',
      start_date    =>  sysdate,
      enabled       =>  true,
      auto_drop     =>  false,
      comments      =>  'one-time backfill ');
      commit;
end;
/


select state, dba.start_date, dba.end_date from dba_scheduler_jobs dba where job_name like '%chg_sum5%' order by last_start_date

select * from dba_scheduler_jobs dba where job_name like '%chg_sum5%' order by last_start_date --pa009746008

--------------------------------------------------------------------------------
/* query to determine how many incident rules are associated with the specified bv and product */
select bv.business_variable_id,
       bv.business_variable_name,
       t.tpr_incident_counter_id,
       t.tpr_incident_rule_id,
       t.active_tf,
       t.context_object_type_id,
       t.count_business_variable_path,
       t.date_business_variable_id,
       t.last_pd_filing_id,
       t.pd_filing_id,
       t.pd_product_id,
       r.b_rule_desc_text,
       r.b_rule_pseudo_code
  from priv_md.tpr_incident_counter t
 inner join priv_md.rule r
    on t.tpr_incident_rule_id = r.rule_id
 inner join priv_md.business_variable bv
    on bv.business_variable_id = priv_api.pkg_os_bv.fn_bv_path_bv_get(t.count_business_variable_path)
 where (t.pd_product_id is null or t.pd_product_id = 62221)
      --and lower(r.b_rule_desc_text) like '%incident type%'
   and r.b_rule_pseudo_code like '%21854601%' --incident points discarded - indicator
   and t.last_pd_filing_id is null
 order by t.tpr_incident_rule_id asc
 --------------------------------------------------------------------------------
--clob updada example
declare
v_clob_txt clob := 
'the policy referenced below has been canceled. please contact your underwriter or pure broker services at (888) 813-pure (7873) or brokerservices@pureinsurance.com if you have questions or need assistance. member: phillips peter account: 87890043419 policy #: co032595900';
begin
update priv_st.long_string set long_string_text = v_clob_txt where long_string_id = 49700606;
end; 
/
declare
v_clob_txt clob := 
'the policy referenced below has been canceled. please contact your underwriter or pure broker services at (888) 813-pure (7873) or brokerservices@pureinsurance.com if you have questions or need assistance. member: phillips peter account: 87890043419 policy #: ho032355900';
begin
update priv_st.long_string set long_string_text = v_clob_txt where long_string_id = 49700255;
end;
/

------------------------------------------------------------------------------------------
--feature
select * from priv_md.feature f 
where f.feature_id in (1100037, 1073737)
and lower(f.feature_name) like '%external rating%'

select * from priv_md.feature_version fv where fv.feature_id = 1083437
select * from priv_md.feature_version fv where fv.feature_version_id = 1230837

select f.feature_id,
       f.feature_name,
       f.feature_jurisdiction_set_id,
       pkg_os_lookup.fn_lookup_list_text_get(5050401, f.feature_jurisdiction_set_id) as jurisdiction,
       fv.feature_description,
       fv.nb_effective_date,
       fv.renewal_effective_date
  from priv_md.feature f
 inner join priv_md.feature_version fv
    on f.feature_id = fv.feature_id
 --where lower(substr(f.feature_name, 1, 15)) like '%external rating%'
  where lower(f.feature_name) = 'external rating'
   and f.feature_insurance_line_id = 21 -- collection lob
 order by fv.nb_effective_date, fv.renewal_effective_date asc;
 
 select pkg_cs_feature.sp_check_feature_version(1, 1, 462692813289, 'home surplus rol' , 'v1' ) from dual;
 
 select pkg_cs_feature.sp_check_feature_version(1, 1, pkg_pv_custom_rules_02.fn_get_prev_basic_trans(1, 1, 461937862399), 'bceg', 'v1') from dual;
------------------------------------------------------------------------------------------
--system attribute
select * from system_attribute_values where attribute_value like '%https://api.purehnw.dev/spatial-v2/corelogic%'
select * from system_attribute_values where attribute_value like '%https://qa-api.aws.purehnw.app/drglocationsearch-can-v2/import%'
select * from priv_api.system_attribute_values sav where upper(sav.attribute_name) like '%priv_dragon_url_document%'
select * from priv_api.system_attribute_values where attribute_name like '%priv_google_maps%'

/*
--system_attribute script
begin
      pkg_os_system_attribute.update_system_attribute('UW_TECH_DEFAULT'
        ,'PRIVDEV~PRIVQA~PRIVSTAGING~PRIVPROD',
		https://api-internal-test.pureinsurance.com/analytics-dev/v1/excess~https://api-internal-test.pureinsurance.com/analytics-qa/v1/excess~https://api-internal-test.pureinsurance.com/analytics-stg/v1/excess~https://api-internal.pureinsurance.com/analytics/v1/excess' ,
        'UW_TECH_NATIONAL' ,
        'Underwriter Tech National Team default'); --DESCRIPTION OF THE ATTRIBUTE
  end;
/
*/
------------------------------------------------------------------------------------------

--system log
delete from priv_st.system_log where user_session_id = 462825996789

select * from priv_st.system_log sl
where sl.user_session_id = 462863078289
--and lower(sl.description) like '%executed action -%' --policyquote id
order by sl.log_sequence asc

select distinct upper(program_name) from priv_st.system_log sl
where sl.user_session_id = 750793624516
--and lower(sl.description) like '%executed action -%' --policyquote id
order by program_name asc

select * from priv_st.system_log where user_session_id = 462348969729 order by log_sequence desc
------------------------------------------------------------------------------------------

--external rating log check
select * from priv_st.sl_service_op_log sso
where lower(sso.operation_label) like '%externalrate%'
--and sso.context_object_id = 774367563639 --policyquote/ptp
and lower(sso.request_xml_payload) like '%<value>personal auto</value>%'
and sso.request_xml_payload like '%<value>nc</value>%'
order by sso.time_stamp desc

select * from priv_st.sl_service_op_log sso
where lower(sso.operation_label) like '%externalrate%'
--and sso.context_object_id = 463298440479 --policyquote/ptp
--and lower(sso.request_xml_payload) like '%<value>course</value>%'
--and sso.request_xml_payload like '%<value>ky</value>%'
and priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, sso.context_object_id, '26806004') = 14037 --coc
and sso.time_stamp >= trunc(sysdate) - 1
order by sso.time_stamp desc

select * from priv_api.vw_retry_call_to_coherent
------------------------------------------------------------------------------------------
--ajax refresh
begin pkg_os_wf_client_rules.sp_ui_rule_input_update(); commit; end;
------------------------------------------------------------------------------------------
--lock session
select * from priv_st.wf_tmp_object_lock w where w.object_id = 462841238849 --policyquote/ptp
delete from priv_st.wf_tmp_object_lock w where w.object_id = 462841238849 --policyquote/ptp
------------------------------------------------------------------------------------------
--rating tables
select * from priv_md.pc_coverage pc where pc.pc_coverage_id = 1731237
select * from priv_md.pr_coverage_factor pf where pf.pr_coverage_factor_id in (5038133)
select * from priv_md.pr_coverage_factor_value pfv where pfv.pr_coverage_factor_value_id in (9068333)
select * from priv_md.pc_attribute pc where pc.pc_attribute_id in (1941237, 1941337, 1941437, 1941537)
select * from priv_st.pr_coverage_premium
select * from priv_md.pr_coverage_relationship pr where pr.pr_coverage_relationship_id = 1046835
select * from priv_st.pr_coverage_factor_premium pcf where pcf.policy_id = 749525107739
select * from priv_st.dragon_transaction_stats dts where dts.policy_image_id = 753900707676 order by coverage_name asc
select * from priv_md.pr_lookup_mapping pr where pr.pr_lookup_mapping_id = 5347314

--join dragon_policy, dragon_policy_trx, and pr_coverage_premium
select dpt.policy_number,
       cp.policy_id,
       dpt.policy_trx_eff_date,
       dpt.policy_trx_type_id,
       dpt.policy_trx_seq_num,
       dpt.policy_trx_status_name,
       cp.premium_amount
  from priv_st.dragon_policy       dp,
       priv_st.dragon_policy_trx   dpt,
       priv_st.pr_coverage_premium cp
where dp.policy_id = dpt.policy_id
   and dpt.policy_image_id = cp.policy_id
   and dp.line_of_business = 13105 --20
   --and dp.policy_jurisdiction_id = 33
   and dpt.policy_trx_eff_date >= to_date('09/14/2026/000001', 'MM/DD/YYYY/HH24MISS') 
   and (dpt.policy_trx_status_id = 106 or dpt.policy_trx_status_id = 35502)
   and cp.pc_coverage_id = 220206 --356321
   and cp.premium_amount <= 0

------------------------------------------------------------------------------------------
--updated query for debugging actions within a user session. this makes use of the new dragon_transaction_actions table introduced in core6.
select
    dt.transaction_id, dt.transaction_timestamp, dt.elapsed_time,
    dt.context_object_id,
    dt.context_action_id, (select a.action_name from priv_md.action a where a.action_id = dt.context_action_id) as context_action,
    dt.requested_action_id, (select a.action_name from priv_md.action a where a.action_id = dt.requested_action_id) as requested_action,
    dta.timestamp, dta.elapsed_time, dta.outcome_id,
    dta.action_id, (select a.action_name from priv_md.action a where a.action_id = dta.action_id) as dta_action
from
    priv_st.dragon_transaction dt
    left join priv_st.dragon_transaction_actions dta on dta.transaction_id = dt.transaction_id
where dt.user_session_id = 750640864839
order by dt.transaction_id, dta.timestamp;

--new query with action_result_state - updated query for debugging actions within a user session
select dt.transaction_id,
       dt.transaction_timestamp,
       dt.elapsed_time as transaction_elapsed_time,
       dt.context_object_id,
       dt.context_action_id,
       ca.action_name as context_action,
       dt.requested_action_id,
       ra.action_name as requested_action,
       dta.timestamp as action_timestamp,
       dta.elapsed_time as action_elapsed_time,
       dta.outcome_id,
       dta.action_id,
       da.action_name as dta_action,
       ars.current_object_state_id,
       ars.result_object_state_id
  from priv_st.dragon_transaction dt
  left join priv_st.dragon_transaction_actions dta on dta.transaction_id = dt.transaction_id
  left join priv_md.action ca on ca.action_id = dt.context_action_id
  left join priv_md.action ra on ra.action_id = dt.requested_action_id
  left join priv_md.action da on da.action_id = dta.action_id
  left join priv_md.action_result_state ars on ars.action_id = dta.action_id
 where dt.user_session_id = 775876571709
 order by dt.transaction_id, dta.timestamp;
 
--history check with object id
select osh.object_id,
       osh.transaction_id,
       osh.user_session_id,
       osh.session_user_id,
       osh.object_type_id,
       osh.outcome_id,
       o.outcome_name,
       osh.prior_state_id,
       osh.state_id,
       os.object_state_display_name,
       osh.requested_action_id,
       a.action_name,
       a.action_native_command,
       osh.state_change_date,
       usr.user_full_name
  from priv_st.object_state_history osh
  join priv_md.object_state os on osh.state_id = os.object_state_id
  join priv_st.dragon_user usr on osh.session_user_id = usr.user_id
  join priv_md.outcome o on o.outcome_id = osh.outcome_id
  join priv_md.action a on a.action_id = osh.requested_action_id
 where osh.object_id = 789956893809 --pt id for post nb trx, policyquote id for nb
 order by osh.state_change_date desc;
------------------------------------------------------------------------------------------
--DAP tables

select * from dap_job_submission d where d.dap_job_submission_id in (41539, 40939)
select * from priv_st.async_batch ab where ab.asynch_batch_type_id = 11533
select * from priv_md.async_job_definition aj where lower(aj.async_job_definition_name) like '%external rating%'

select (ajs.job_start_date - ajs.job_date) * 86400 as diff, ajs.* 
from priv_st.async_job_status ajs
inner join priv_md.async_job_definition aj
on aj.async_job_definition_id = ajs.async_job_definition_id
and aj.action_id = 619246 --dap_asyncjobprocess_java_command
--where ajs.async_job_definition_id in (91139, 90539, 91939)
--and ajs.job_object_id = 748562682879 --748562682879
and ajs.job_date >= to_date('2025-03-14 05:00', 'yyyy-mm-dd hh24:mi')
and ajs.job_date < to_date('2025-03-14 07:00', 'yyyy-mm-dd hh24:mi')
--and lower(ajs.job_description) like '%external rating%'
order by ajs.job_date desc

select * from priv_st.async_job_status ajs
where ajs.async_job_definition_id in (97037, 96937, 96837)
--where ajs.job_description = 'external rating details request - renewal'
order by ajs.job_date desc

--dap job monitor by session id
select * from priv_st.dap_scheduler_monitor_audit d
where d.session_id = 790223116669
--and d.async_job_definition_id in (90539, 91139, 91939)
order by d.creation_timestamp desc
------------------------------------------------------------------------------------------

--inner join bv + object_bv_value table
select * from object_bv_value ooo, business_variable bv1
where ooo.business_variable_id = bv1.business_variable_id 
--and ooo.object_id in (462356174169, 462356174209, 462327408609)
and bv1.business_variable_name like '%_in'

select * from business_variable bv1
where bv1.business_variable_name like '%_in'
--and ooo.object_id in (462356174169, 462356174209, 462327408609)
--and bv1.business_variable_name like '%_in'
order by bv1.business_variable_id desc

select * from priv_md.business_variable bv where bv.business_variable_id in (28026805)
select * from priv_md.rule r where r.rule_id = 12915139
select * from priv_st.risk_model_block_setup r where r.pd_product_id = 73833 and r.last_pd_filing_id is null
select * from priv_md.outcome o where o.outcome_id = 75739
select * from priv_st.dragon_policy where agency_number = 14673900

select distinct(dp.policy_number)
from priv_st.dragon_policy_trx dpt
inner join priv_st.dragon_policy dp
on dpt.policy_id = dp.policy_id
where dpt.policy_trx_status_id = 106 --processed
and dp.policy_lines = 'home surplus lines - california'
and ((dpt.policy_trx_eff_date >= to_date('05/01/2025' , 'mm/dd/yyyy') and dpt.policy_trx_type_id in (9, 4, 5099)) --nb, endorsement, nb rewrite
or (dpt.policy_trx_eff_date >= to_date('07/01/2025' , 'mm/dd/yyyy') and dpt.policy_trx_type_id = 8)) --renewal
and dp.agency_number <> 14673900 --system validation llc

------------------------------------------------------------------------------------------
--bv trace
insert into priv_st.dragon_variable_trace(trace_id, trace_dragon_variable_id, user_session_id, composite_search_key, trace_logging_level, trace_logging_level_desc)
values (29643514, 29643514 ,null, null, 4, 'ppc override');

------------------------------------------------------------------------------------------
--dragon license
insert into priv_st.dragon_license (license_id, license_state, license_number, license_code, license_category, license_type, partner_id, license_holder_name, admitted_or_surplus, 
license_override_status_text, parent_object_id, license_object_status_text, license_category_enum, license_code_enum, license_type_enum, license_state_enum, license_expiration_date )
values (8786546565, 'wy', '674563485', 'property/casualty', 'agent', 'agency', 3151879419, 'multi state agency', 'admitted and surplus' , 'override active' , 3151879419, ' active', 
1, 5, 1, 52, to_date('20270805 12:01:00 am' , 'yyyymmdd hh24:mi:ss') );

select * from dragon_license dl where dl.admitted_or_surplus = 'admitted and surplus' and dl.license_object_status_text = 'active' and dl.license_state = 'ca'

select * from priv_api.agent_resources
select * from priv_st.dragon_license dl where dl.license_id = 852589658
select * from priv_md.action a where a.action_id = 1303039

------------------------------------------------------------------------------------------
--dragon_user, dragon_user_group, dragon_partner, dragon_household
select * from dragon_household where household_id = 461548968339
select * from priv_st.dragon_policy where policy_number = 'pa201246605'
select * from ppu_fl_0_pr_carrier where jurisdiction_set = 12
select * from vw_user_group_assignment where user_full_name = 'national team' and user_full_name = 'katrina benge'

select * from priv_st.dragon_user where lower(user_full_name) like '%branislav%'
select * from priv_st.dragon_user where pure_programs_user_only is not null
select * from priv_st.dragon_user_associated_group where dragon_user_actor_type_name = 'underwriting technician' and dragon_user_name = 'national team'
select * from priv_st.dragon_user_associated_group where dragon_user_name = 'national team' --dragon_user_id
select * from priv_st.dragon_user where user_full_name = 'national team' --user_id
select * from priv_st.dragon_user_associated_group where dragon_user_group_name = 'oneshieldsmoke'


select duag.dragon_user_id,du.user_full_name,status_id user_status_id, status_desc, du.actor_type_id, dp.uw_technician,
--dragon_user_group_id, dragon_user_group_name, du, dsuh.region_state_id, dsuh.region_state,
upper(du.user_full_name) user_full_name_upper, du.pure_programs_user_only
from dragon_user_associated_group duag
join dragon_user du
on duag.dragon_user_id = du.user_id
left join dragon_partner dp
on dp.uw_technician = du.user_full_name
where user_full_name = 'national team'


select * from vw_user_group_assignment --where user_full_name = 'national team'
where dragon_user_group_id is not null 
and actor_type_id in (14206,5) 
and (user_status_id = to_number(75) or user_status_id is null) 
and (pure_programs_user_only is null or pure_programs_user_only<>('yes'))
and user_full_name like '%national team%'


select dug.dragon_user_id,du.user_full_name,status_id user_status_id, status_desc,
dragon_user_group_id, dragon_user_group_name, du.actor_type_id, dsuh.region_state_id, dsuh.region_state,
upper(du.user_full_name) user_full_name_upper, du.pure_programs_user_only
from dragon_user_associated_group dug
join dragon_user du
on dug.dragon_user_id = du.user_id
left join dragon_surplus_uw_history dsuh
on dug.dragon_user_group_id=dsuh.uw_group_id and dsuh.end_date is null;


select * from priv_st.dragon_partner 
where uw_group_id is not null 
and uw_group_name is not null 
and uw_primary is not null 
and uw_service_assoc is not null

select * from priv_st.dragon_partner where uw_technician is null --= 'national team'
select * from priv_st.dragon_partner where uw_group_name = 'underwriting group 1' --'underwriting group 2'
select * from priv_api.system_attribute_values where attribute_value like '%https://%'

select user_id, user_full_name, pure_programs_user_only, partner_object_status, uw_technician
from dragon_partner dp
join dragon_user du
on du.user_full_name = dp.uw_technician
where ( pure_programs_user_only is null or pure_programs_user_only <> 'yes')
and user_full_name = 'national team'
and partner_object_status = 'approved'
and uw_technician = 'national team'

-------------------------------------------------------------------------------------------------------------
--how to check if the rule is matching in higher environments using translation_label table
select
r.rule_id,
(select tl.translation_value from priv_md.translation_label tl where tl.translation_key_id = r.rule_pseudo_code) as pseudo_code,
(select tl.translation_value from priv_md.translation_label tl where tl.translation_key_id = r.rule_serialized) as rule_serialized,
(select tl.translation_value from priv_md.translation_label tl where tl.translation_key_id = r.rule_descriptive_text) as rule_desc_text
from priv_md.rule r
where r.rule_id = 8403533

--query to join rule and table with rule to extract rule text and bvs inside the rule
select rm.pd_product_id,
       r.b_rule_desc_text     as source_rule_text,
       r1.b_rule_desc_text    as relevent_rule_text,
       r.b_rule_pseudo_code   as source_rule,
       r1.b_rule_pseudo_code  as relevent_rule
  from priv_md.pc_coverage_rule rm
  left join priv_md.rule r on rm.rule_id = r.rule_id
  left join priv_md.rule r1 on rm.pc_rule_relevant_rule_id = r1.rule_id
 where rm.pd_product_id = 57505 --pd product id
   and rm.last_pd_filing_id is null
   and (lower(r.b_rule_pseudo_code) like '%30309633%' or lower(r1.b_rule_pseudo_code) like '%30309633%')
-------------------------------------------------------------------------------------------------------------
--long string check using feature version id, etc...
select * from priv_st.long_string ls where ls.long_string_id = 68150367
-------------------------------------------------------------------------------------------------------------
--update priv_st.installation set logging_level = 4 where installation_id = 9
select * from priv_st.installation


select * from priv_st.actor_type_set_values at where at.actor_type_set_id = 10105

select * from tiv_non_ca_loc_agg_mngmnt_vw where policyquote_product_id = 72333 and policyquote_id = 462486810799
select * from aggregation_zone_current_tiv where jurisdiction_id = 9 and zone_name = 'clay'
select * from dm_aggregate_management where jurisdiction_id = 9
select * from priv_md.action_button ab where ab.action_button_id = 727901
select * from priv_md.object_datamart od where od.datamart_id = 42037
select * from priv_md.action_result ar where ar.action_result_id = 1582039 --in (1584939, 1585039, 1621539) --needs to be fixed
select * from priv_md.action_result ar where ar.action_result_id = 1540137
select * from priv_md.action_result ar where ar.action_result_id = 565133 --1543337
select * from priv_md.action_rule ar where ar.action_rule_id in (9921833)
select * from priv_md.dap_job_submission dp where dp.dap_job_submission_id in (42839, 41539, 40939)

/* update priv_md.action_result ar
set --ar.result_action_id = 1328237, ----result action: 1318139 1585039
    ar.result_object_path = '27834002.211405.28555404.27919402490.452.24.629' -- 27834002.211405.28555404.27919402490.452.24.629
  --  ar.action_result_message = null
where ar.action_result_id = 1543337;  

update priv_md.action_rule ar
set ar.active_tf = 'f' --should be t - turned off in priv_md qa
where ar.action_rule_id = 9921833; */

select distinct(ar.action_id) 
from priv_md.action_rule ar 
where ar.action_rule_type_id = 1
and ar.pd_product_id in (72333)
and ar.active_tf = 't' 
and ar.last_pd_filing_id is null

select * from priv_st.polk_vehicle
select distinct(license_state) from dragon_license dl where dl.admitted_or_surplus = 'admitted and surplus' and dl.license_object_status_text = 'active'
select * from dragon_license dl where dl.admitted_or_surplus = 'admitted and surplus' and dl.license_object_status_text = 'active' and dl.license_state = 'az'

select * from priv_md.variable_path_ref vpr where vpr.variable_path_ref_id in (1003227137)
select * from priv_st.variable_path vp where vp.variable_path_id in (59640937)
select * from priv_st.variable_path_member vpm where vpm.variable_path_member_id in (81456637)

select * from priv_st.variable_path_member vpm where vpm.variable_path_id in (59454639, 59454839, 59456439)
select * from priv_st.variable_path_ref vpr where vpr.variable_path_id in (60648437)

select * from priv_api.agent_resources
select * from priv_md.risk_model_block_setup r where r.pd_product_id = 73833
select * from priv_st.dragon_license dl where dl.license_id = 852589658
select * from priv_md.xml_schema_attribute x where x.xml_schema_attribute_id = 197024637

insert into priv_st.dm_grade_reason(reason_id, location_full_address, tiv, aggregation_score, non_cat_grade, cat_score, peril_1, peril_2) 461951916329
values (4, '673 alta vista dr, gatlinburg, tennessee 37738', '14500000', 'very high', 'f', 'extreme', 'wildfire', 'earthquake'); --pt

insert into priv_st.dm_grade_reason(reason_id, household_id, policy_trx_policy_id, location_full_address, tiv, aggregation_score, non_cat_grade, cat_score, peril_1, peril_2)
values (2, 461918082769, 461940379659, '673 alta vista dr, gatlinburg, tennessee 37738', 14500000, 'very high', 'f', 'extreme', 'wildfire', 'earthquake'); --policyquote

insert into priv_st.dm_grade_reason(reason_id, dragon_object_id, household_id, policy_trx_policy_id, location_full_address, tiv, aggregation_score, non_cat_grade, cat_score, peril_1, peril_2)
values (1, 461940833009, 461940832859, 461940832789, '670 alta vista dr, gatlinburg, tennessee 37734', 15000000, 'high', 'f', 'moderate', 'wildfire', 'earthquake'); --policyquote 461951916329

insert into priv_st.dm_grade_reason(reason_id, dragon_object_id, household_id, policy_trx_policy_id, location_full_address, tiv, 
aggregation_score, non_cat_grade, cat_score, peril_1, peril_2, grade_order_date, prop_type_name, lc360_grade_ind, reason)
values (6, 745855789679  , 745855776099  , 745855775999, '775 cascade ave, oregon city, oregon 97045', 10500000,
'n/a', 'c', 'n/a', 'n/a', 'n/a', sysdate, 'condo', 2, 'location is not eligible. refer to building guidelines'); --policyquote 461951916329

insert into priv_st.dm_grade_reason(reason_id, household_id, location_full_address, tiv, 
aggregation_score, non_cat_grade, cat_score, peril_1, peril_2, grade_order_date, prop_type_name, reason, policy_number)
values (25, 461927783739, '2970 elderberry dr s, salem, oregon 97302', 15000000,
'extreme', 'f', 'extreme', 'wildfire', 'wildfire', sysdate, 'homeowner', 'n/a', 'ho118903800'); --policyquote 461951916329

select * from priv_st.dm_grade_reason dgr where dgr.dragon_object_id = 745862781366/*dgr.cat_score in ('5','6') and dgr.non_cat_grade = 'c'*/
select * from priv_st.dragon_policy dp where dp.household_id = 774952552019
select * from priv_st.dragon_policy_quote dpq where dpq.policyquote_id = 774952551939
select * from dragon_risk_location
--update priv_st.dm_grade_reason dgr set dgr.non_cat_grade = 'c' where dgr.dragon_object_id = 745862781366

------------------------------------

--procedure for auto creating tasks
declare
begin
pkg_os_wf_task.sp_action_result_tasks(
1,
1,
1038333, --action id
22, --outcome
745882269356); --policy quote id
end;

------------------------------------

select * from priv_st.dragon_task dt 
where dt.task_type = 'underwriting referral - cancellation' 
order by dt.task_created_date desc

select * from priv_st.dragon_task dt
where dt.task_created_date >= trunc(to_date('20210924' , 'yyyymmdd')) 
and dt.task_description like '%services@pureinsurance.com%' 
order by dt.task_last_updated_date 

select distinct e.email_reply_to_address
from priv_st.email e
where e.email_reply_to_address like '%services@pureinsurance.com%'

-----------------------------------------------------------------------------------------------
select * from vw_er_coverage_codes
select * from vw_er_input_values

select pkg_cs_functions.fn_bceg_year_exists(1001, 1001, 461937233059, 461937290689) from dual;

select pkg_cs_functions.fn_bceg_exists(1001, 1001, 461937235749, '2012', '04') from dual --461937080919

select pkg_cs_functions.fn_bceg_year_closest_is(1001, 1001, '2012', 461937233059, 461937290689 , '04'  ) from dual --461937080919

select pkg_pv_custom_rules_01.fn_is_bceg_yrcompare_tf (1 , 1 , 461935938559 ) from dual;

select pkg_pv_custom_rules_02.fn_default_bceg_renewal (1 , 1 , 461935938559 ) from dual;

select pkg_pv_custom_rules_01.fn_bceg_min_yr(1, 1, 461938040879) from dual;

select pkg_cs_functions.fn_bceg_year_closest_get(1, 1, 461936042709, 461937080919) from dual;

select * from priv_md.pd_filing pf where pf.pd_filing_id = 127483337

select pkg_cs_address_standardization.fn_is_bad_location(1, 1, 461979540819) from dual;

select * from vw_bor_agency_transfer_details where policy_id = 751287619666

select * from priv_st.lookup_list ll where ll.lookup_list_id = 5053501

select * from priv_st.action_rule ar where ar.action_rule_id in (836906)

select * from priv_md.action_result_task art

select * from priv_st.pd_transaction_set pd where pd.pd_transaction_set_id in (4805)

select * from priv_st.pd_property pp where pp.pd_property_id = 467033
select * from priv_st.pd_property_type ppt where ppt.pd_property_type_id = 27633


select * from priv_st.page_layout_cell plc where plc.page_layout_cell_id = 21627535
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 752896097339, '27992205.29795214') from dual --_reference_head of household
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214') from dual --reference_current iso report
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214.29911514') from dual --ppcval
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214.29965814') from dual --dwellppc
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748829, '26774802.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214') from dual --reference_reference to ppc report object


select priv_api.pkg_pv_custom_rules.fn_pure_claim_loss_tf(1, 1, 635842359857, 2379907, 'auto-at-fault') from dual; --excess
select priv_api.pkg_pv_custom_rules.fn_pure_claim_loss_tf(1, 1, 635842359857, 2380107, 'auto-at-fault') from dual; --auto
      
    
select * from priv_st.ods_tpr_report_order tpr
where tpr.tpr_report_type = 'autoclue'
and tpr.household_id = 346490377219
order by tpr_order_date desc-- check autoclue reports for household


select * from priv_st.jurisdiction_set where jurisdiction_set_id = 20133

select * from priv_st.dragon_household

select * from priv_st.dm_all_incident

select * from priv_st.pd_renewal_mod_rule where pd_renewal_mod_rule_id = 479014

select * from priv_st.pd_initialization_group where initialization_group_id = 692635

select * from priv_st.dragon_policy where policy_number = 'pa198777106'

select * from priv_st.pc_coverage_rule where pc_coverage_rule_id in (2404135, 2403735)

select pkg_pv_nada.fn_get_renewal_agv ( 1   , 1  , 465871150159  ) from dual 

select pkg_os_lookup.fn_lookup_list_short_text_get( 5323105, 3) from dual;

select * from priv_st.page_layout_block where page_layout_block_id = 736607

select * from priv_st.page_layout_cell where page_layout_cell_id = 12425314

select * from priv_st.ods_tpr_report_order

select distinct dpt.policy_id from priv_st.dragon_policy_trx dpt
inner join priv_st.dragon_policy dp
on dp.policy_id = dpt.policy_id
where trunc(dpt.policy_trx_image_eff_date) >= to_date('20220313' , 'yyyymmdd')
and trunc(dpt.policy_trx_process_date) < trunc(dpt.policy_trx_image_eff_date) and dpt.policy_trx_type_id = 8
and dp.policy_lob_id = 19
and dp.policy_jurisdiction_id = 16

select * from priv_st.dragon_policy

select * from priv_st.action_rule where action_rule_id = 11295332

select * from priv_md.pc_coverage where pc_coverage_id = 1274933

select * from priv_st.rule where rule_id = 12737637

select * from priv_st.pd_filing where pd_filing_id = 105

select * from priv_st.jurisdiction_set where jurisdiction_set_id = 28135

select * from priv_st.action_overload where action_overload_id = 3835

select * from priv_st.action_validation where action_validation_id in (33514, 57933) 

select * from priv_api.uw_reassign_surplus_brokers

select * from priv_md.tr_object_bv_transform tr where tr.tr_object_bv_transform_id = 14150437

select * from ods_mgu_location_coverage where mgu_policy_id = 750957782639 and location_coverage_id = 750957782679 

select * from priv_st.action_integration_log where lower(ai_name) like '%predictive analytics%'
select distinct(ai_name) from priv_st.action_integration_log

select * from priv_st.action_integration_log where policy_transaction_policy_id = 745929171986 order by ai_log_timestamp desc







