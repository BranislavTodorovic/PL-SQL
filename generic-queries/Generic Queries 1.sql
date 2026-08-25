---------------------------------------------------------------------------------------------------------
--Bundle check
select BUNDLE_DATE, DEPLOY_BUNDLE_LABEL, DEPLOY_PREDECESSOR, DEPLOY_SVN_BRANCH, DEPLOYED_DATE, DEPLOY_STATUS, DEPLOY_REGION, USERID, DEPLOY_TYPE, PRD_TARGET_DATE
from priv_st.deploy_log where deploy_bundle_label like '%DP2_PAG_%' order by bundle_date asc

select * from priv_st.deploy_log where deploy_bundle_label like '%LLI_ERATE_AUTO_NC_%' order by bundle_date asc
select DEPLOY_BUNDLE_LABEL, PRD_TARGET_DATE from priv_st.deploy_log where deploy_bundle_label like '%LLI_ERATE_AUTO_NC_31%'
---------------------------------------------------------------------------------------------------------
--bv_path test
select pkg_os_object_io.fn_object_bv_path_get(1, 
                                              1, 
                                              462775772269, --object id
                                              '31408737') from dual; --bv path id

--get text value from VLL                                     
select pkg_os_reference_lookup.fn_get_lookup_text(1, 
                                                  1, 
                                                  462775772269, --object id
                                                  28920705, --bv id
                                                  2) from dual;  --value from VLL                                           

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
         to_date('05/17/2024' , 'MM/DD/YYYY'),
         to_date('01/28/1952' , 'MM/DD/YYYY')
       ) / 12 as age_years
from dual;


--checking dates between days
select (abs(trunc(months_between(to_date('20211102000100', 'YYYYMMDDHH24MISS'), to_date('2023112500100' , 'YYYYMMDDHH24MISS')) *30))) num_of_days from dual


--checking dates between months
select abs(trunc(months_between(to_date('20230730000100', 'YYYYMMDDHH24MISS'), to_date('20221103000100', 'YYYYMMDDHH24MISS')))) num_of_months from dual
---------------------------------------------------------------------------------------------------------

--Delete objects
declare

type grades_arr is varray(20) of number;

ids_arr grades_arr;

begin

ids_arr := grades_arr(754800262546,
            754800262566,
            754800262586); --Object ids that should be deleted

for i in 1.. ids_arr.count_loop
priv_api.pkg_os_object.sp_object_delete(1, 1, null, ids_arr(i), null, null, false);

end loop;

end;
---------------------------------------------------------------------------------------------------------
--   Name: Bran Todorovic
--   Date: 05/29/2026
--   Project: Production Support
--   Rally ID: DE108896 - PURE Online Error
--	 Comment: Updating policy expiration date

--HOT FIX script example
declare
v_dm char(1) := 'T';
begin
priv_api.pkg_os_object_io.sp_object_bv_set(1, 1, 739793584009, 499, to_char( to_date ('20270214000100','YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS') ); -- expiration date
priv_api.pkg_os_datamart.sp_datamart_update_row(1, 1, 739793584009, v_dm); 
end;
/
---------------------------------------------------------------------------------------------------------
--Query to get XML attributes related to cell names on UI, BV IDs, per Product ID
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
   where xsa.xml_schema_id = 52537), --PolicyDWC XML Schema ID
plc_data as
 (select priv_api.pkg_os_bv.fn_bv_path_bv_get(plc.cell_business_variable_path) as business_variable_id,
         max(plc.b_cell_label) as cell_label_name
    from priv_md.page_layout_cell plc
   where plc.pd_product_id = 71533 --Domestic Workers Comp
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
--Renewal ReRate view
select * from priv_st.object o where o.object_id = 746199132599
    select count(*)
   -- into v_count
    from policy_renewal_rerate_vw v
    where v.policy_image_id = 123232;

--view example
select * from POLICY_RENEWAL_RERATE_VW
select dtx.policy_image_id
from priv_st.dragon_policy dp
inner join priv_st.dragon_policy_trx dtx on dtx.policy_id = dp.policy_id
inner join priv_st.dragon_household dh on dh.household_id = dp.household_id
AND  dtx.policy_trx_status_id = 15402 --PolicyTransactionCreated
and  dtx.POLICY_TRX_TYPE_ID = 8 --Renewal
AND dp.policy_state_id = 71 --Active
and dp.line_of_business not in (13733,13833,14537,14037) --HS,ES,Primary Flood, COC
and dh.household_country = 'United States'
and (extract(year from dtx.POLICY_TRX_EFF_DATE) = extract(year from sysdate) or extract(year from dtx.POLICY_TRX_EFF_DATE - 1) = extract(year from sysdate - 1))
and trunc(dtx.POLICY_TRX_EFF_DATE) between trunc(sysdate - 45) and trunc(sysdate + 45)    
and (select count(1) 
     from priv_st.dm_underwriting_referral 
     where parent_object_id = dtx.policy_image_id
     and UW_TRIGGER_RELEVANT = 1
     and OVERRIDDEN = 2) = 0
---------------------------------------------------------------------------------------------------------

select * /* PRIV_SERVICE_PERF_LOG_ID,operation_label,session_user_name, (response_end_Date - request_start_Date) * 24 * 3600 as total_time_seconds,trim((request_end_Date - request_start_Date) * 24 * 3600) as request_create_seconds,
(response_end_Date - response_start_Date) * 24 * 3600 as resp_store_seconds,
(web_Service_end_Date - web_service_start_Date) * 24 * 3600 as call_time_seconds,
request_start_Date, request_end_Date, response_start_Date, response_end_Date, web_service_start_Date, web_Service_end_Date, request_xml_payload, response_xml_payload */
from priv_st.PRIV_SERVICE_PERF_LOG where last_updt_date > sysdate -10-- and to_char(last_updt_date,'MM/DD/YYYY HH24:MI') = '12/20/2021 10:02' -- and session_id in (738288105369) -- request_Start_date > to_date('11222021115900','MMDDYYYYHH24MISS')
--and priv_service_perf_log_id > 569416
and operation_label = 'NADA Auto Market Value'
--and session_user_name is not null
--and session_id in (738338007299)
--and context_object_id in ( 739301434599,739301433799)
--and request_start_date < to_date('11222021155500','MMDDYYYYHH24MISS')
--group by operation_label
and exception_stack_trace is not null
order by PRIV_SERVICE_PERF_LOG_id desc


--Perf log & External queue job status
select * from priv_st.priv_service_perf_log pf
where upper(pf.operation_label) like '%RISKMETER_REPORT_QUEUE%' --RISKMETER
--where pf.context_object_id = 765722355429
order by REQUEST_START_DATE desc


--External_queue_job_status
select * from priv_st.external_queue_job_status eqjs
where eqjs.queue_name = 'policy-carrier-rules-sapiens-queue'
and eqjs.household_id = 67522679419
order by eqjs.created_date desc;

select * from priv_st.external_queue_job_status 
where upper(queue_name) like '%RISKMETER_REPORT_QUEUE%' 
order by job_id desc;
--------------------------------------------------------------------------------
--TPR Report
select * from priv_st.ods_tpr_report_order tpr
where tpr.tpr_report_type = 'AutoCLUE'
and tpr.household_id = 346490377219
order by TPR_ORDER_DATE desc-- check AutoClue reports for household
--------------------------------------------------------------------------------
-----Scheduler script-----
begin                                 
    dbms_scheduler.create_job
    (
      job_name      =>  'lc360_1',
      job_type      =>  'PLSQL_BLOCK',
      job_action    =>  'begin priv_api.pkg_pv_custom_backfill_03.sp_lc360_sf_inspection(747724801579, 747724801579); end;',
      start_date    =>  sysdate,
      enabled       =>  true,
      auto_drop     =>  false,
      comments      =>  'one-time backfill ');
      commit;
end;
/


select * from priv_st.system_log sl where sl.user_session_id = 720795761879 and sl.program_name = 'PKG_PV_CUSTOM_BACKFILL.covid_object_change' order by sl.log_sequence desc

select * from priv_st.system_log sl where sl.user_session_id = 720795761879 order by sl.log_sequence desc

select STATE, dba.start_date, dba.end_date from dba_scheduler_jobs dba where job_name like '%CHG_SUM5%' order by last_start_date

select * from dba_scheduler_jobs dba where job_name like '%CHG_SUM5%' order by last_start_date --PA009746008

--------------------------------------------------------------------------------
/* Query to determine how many incident rules are associated with the specified BV and product */
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
   and r.b_rule_pseudo_code like '%21854601%' --Incident Points Discarded - Indicator
   and t.last_pd_filing_id is null
 order by t.tpr_incident_rule_id asc
 --------------------------------------------------------------------------------
--CLOB updada example
declare
v_clob_txt clob := 
'The policy referenced below has been Canceled. Please contact your underwriter or PURE Broker Services at (888) 813-PURE (7873) or brokerservices@pureinsurance.com if you have questions or need assistance. Member: Phillips Peter Account: 87890043419 Policy #: CO032595900';
begin
update priv_st.long_string set long_string_text = v_clob_txt where long_string_id = 49700606;
end; 
/
declare
v_clob_txt clob := 
'The policy referenced below has been Canceled. Please contact your underwriter or PURE Broker Services at (888) 813-PURE (7873) or brokerservices@pureinsurance.com if you have questions or need assistance. Member: Phillips Peter Account: 87890043419 Policy #: HO032355900';
begin
update priv_st.long_string set long_string_text = v_clob_txt where long_string_id = 49700255;
end;
/

------------------------------------------------------------------------------------------
--Feature
select * from priv_md.feature f where f.feature_id in (1100037, 1073737)
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
   and f.feature_insurance_line_id = 21 -- Collection LOB
 order by fv.nb_effective_date, fv.renewal_effective_date asc;
 
 select pkg_cs_feature.sp_check_feature_version(1, 1, 462692813289, 'Home Surplus ROL' , 'v1' ) from dual;
 
 select pkg_cs_feature.sp_check_feature_version(1, 1, pkg_pv_custom_rules_02.fn_get_prev_basic_trans(1, 1, 461937862399), 'BCEG', 'v1') from dual;
------------------------------------------------------------------------------------------
--system attribute
select * from system_attribute_values where ATTRIBUTE_value like '%https://api.purehnw.dev/spatial-v2/corelogic%'
select * from system_attribute_values where ATTRIBUTE_value like '%https://qa-api.aws.purehnw.app/drglocationsearch-can-v2/import%'
select * from priv_api.system_attribute_values sav where upper(sav.ATTRIBUTE_NAME) like '%PRIV_DRAGON_URL_DOCUMENT%'
select * from priv_api.system_attribute_values where ATTRIBUTE_NAME like '%PRIV_GOOGLE_MAPS%'
select * from priv_st.installation

--update priv_st.installation set LOGGING_LEVEL = 4 where INSTALLATION_ID = 9
select * from priv_st.actor_type_set_values at where at.actor_type_set_id = 10105

SELECT * FROM TIV_NON_CA_LOC_AGG_MNGMNT_VW WHERE POLICYQUOTE_PRODUCT_ID = 72333 and POLICYQUOTE_ID = 462486810799
SELECT * FROM AGGREGATION_ZONE_CURRENT_TIV where JURISDICTION_ID = 9 and zone_name = 'CLAY'
select * from dm_aggregate_management where JURISDICTION_ID = 9
select * from priv_md.action_button ab where ab.action_button_id = 727901
SELECT * FROM priv_md.object_datamart od where od.datamart_id = 42037
select * from priv_md.action_result ar where ar.action_result_id = 1582039 --in (1584939, 1585039, 1621539) --needs to be fixed
select * from priv_md.action_result ar where ar.action_result_id = 1540137
select * from priv_md.action_result ar where ar.ACTION_RESULT_ID = 565133 --1543337
select * from priv_md.action_rule ar where ar.ACTION_RULE_ID in (9921833)
select * from priv_md.dap_job_submission dp where dp.dap_job_submission_id in (42839, 41539, 40939)

/* UPDATE priv_md.action_result ar
SET --ar.RESULT_ACTION_ID = 1328237, ----result action: 1318139 1585039
    ar.RESULT_OBJECT_PATH = '27834002.211405.28555404.27919402490.452.24.629' -- 27834002.211405.28555404.27919402490.452.24.629
  --  ar.ACTION_RESULT_MESSAGE = null
WHERE ar.action_result_id = 1543337;  

UPDATE priv_md.action_rule ar
SET ar.ACTIVE_TF = 'F' --should be T - turned off in priv_md QA
WHERE ar.action_rule_id = 9921833; */

select distinct(ar.ACTION_ID) 
from priv_md.action_rule ar 
where ar.action_rule_type_id = 1
and ar.pd_product_id in (72333)
and ar.active_tf = 'T' 
and ar.last_pd_filing_id is null

/*UPDATE dap_job_submission d
SET d.wait_page_timeout = 120 --should be 120 for both
WHERE d.dap_job_submission_id in (41539, 40939)*/
------------------------------------------------------------------------------------------
--System log
delete from priv_st.system_log where user_session_id = 462825996789

select * from priv_st.system_log sl
where sl.user_session_id = 462863078289
--and lower(sl.description) like '%executed action -%' --PolicyQuote ID
order by sl.log_sequence asc

select distinct upper(PROGRAM_NAME) FROM priv_st.system_log sl
where sl.user_session_id = 750793624516
--and lower(sl.description) like '%executed action -%' --PolicyQuote ID
order by PROGRAM_NAME asc

select * from priv_st.system_log where user_session_id = 462348969729 order by LOG_SEQUENCE desc
------------------------------------------------------------------------------------------

--External Rating log check
select * from priv_st.sl_service_op_log sso
where lower(sso.OPERATION_LABEL) like '%externalrate%'
--and sso.context_object_id = 774367563639 --PolicyQuote/PTP
and lower(sso.request_xml_payload) like '%<value>personal auto</value>%'
and sso.request_xml_payload like '%<value>NC</value>%'
order by sso.TIME_STAMP desc

select * from priv_st.sl_service_op_log sso
where lower(sso.OPERATION_LABEL) like '%externalrate%'
--and sso.context_object_id = 463298440479 --PolicyQuote/PTP
--and lower(sso.request_xml_payload) like '%<value>course</value>%'
--and sso.request_xml_payload like '%<value>KY</value>%'
and priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, sso.context_object_id, '26806004') = 14037 --COC
and sso.time_stamp >= trunc(sysdate) - 1
order by sso.TIME_STAMP desc

select * from priv_api.VW_RETRY_CALL_TO_COHERENT
------------------------------------------------------------------------------------------
--AJAX refresh
begin pkg_os_wf_client_rules.sp_ui_rule_input_update(); commit; end;
------------------------------------------------------------------------------------------
--Lock session
select * from priv_st.wf_tmp_object_lock w where w.object_id = 462841238849 --PolicyQuote/PTP
delete from priv_st.wf_tmp_object_lock w where w.object_id = 462841238849 --PolicyQuote/PTP
------------------------------------------------------------------------------------------
--Rating tables
select * from priv_md.pc_coverage pc where pc.pc_coverage_id = 1731237
select * from priv_md.pr_coverage_factor pf where pf.pr_coverage_factor_id in (5038133)
select * from priv_md.pr_coverage_factor_value pfv where pfv.pr_coverage_factor_value_id in (9068333)
select * from priv_md.pc_attribute pc where pc.PC_ATTRIBUTE_ID in (1941237, 1941337, 1941437, 1941537)
select * from priv_st.pr_coverage_premium
select * from priv_md.pr_coverage_relationship pr where pr.pr_coverage_relationship_id = 1046835
select * from priv_st.pr_coverage_factor_premium pcf where pcf.policy_id = 749525107739
select * from priv_st.dragon_transaction_stats dts where dts.policy_image_id = 753900707676 order by COVERAGE_NAME asc
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
   and dpt.policy_trx_eff_date >= to_date('09142026000001', 'mmddyyyyhh24miss') --to_date('01/15/2026', 'MM/DD/YYYY')
   and (dpt.policy_trx_status_id = 106 or dpt.policy_trx_status_id = 35502)
   and cp.pc_coverage_id = 220206 --356321
   and cp.premium_amount <= 0

------------------------------------------------------------------------------------------
--updated query for debugging actions within a User session. This makes use of the new DRAGON_TRANSACTION_ACTIONS table introduced in Core6.
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

--NEW QUERY with ACTION_RESULT_STATE - updated query for debugging actions within a User session
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
  left join priv_st.dragon_transaction_actions dta
    on dta.transaction_id = dt.transaction_id
  left join priv_md.action ca
    on ca.action_id = dt.context_action_id
  left join priv_md.action ra
    on ra.action_id = dt.requested_action_id
  left join priv_md.action da
    on da.action_id = dta.action_id
  left join priv_md.action_result_state ars
    on ars.action_id = dta.action_id
 where dt.user_session_id = 775876571709
 order by dt.transaction_id, dta.timestamp;
 
--History check with object ID
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
 where osh.object_id = 789956893809 --PT ID for post NB trx, PolicyQuote ID for NB
 order by osh.state_change_date desc;
------------------------------------------------------------------------------------------

--Dap tables
SELECT * FROM dap_job_submission d where d.dap_job_submission_id in (41539, 40939)
select * from priv_st.async_batch ab where ab.asynch_batch_type_id = 11533
SELECT * from priv_md.async_job_definition aj where lower(aj.async_job_definition_name) like '%external rating%'

select (AJS.JOB_START_DATE - AJS.JOB_DATE) * 86400 as DIFF, AJS.* 
from priv_st.async_job_status ajs
inner join priv_md.async_job_definition aj
on aj.async_job_definition_id = ajs.async_job_definition_id
and aj.action_id = 619246 --Dap_AsyncJobProcess_Java_Command
--where ajs.async_job_definition_id in (91139, 90539, 91939)
--and ajs.job_object_id = 748562682879 --748562682879
and ajs.job_date >= TO_DATE('2025-03-14 05:00', 'YYYY-MM-DD HH24:MI')
AND ajs.job_date < TO_DATE('2025-03-14 07:00', 'YYYY-MM-DD HH24:MI')
--AND lower(ajs.job_description) like '%external rating%'
order by ajs.job_date desc

select * from priv_st.async_job_status ajs
where ajs.async_job_definition_id in (97037, 96937, 96837)
--where ajs.job_description = 'External Rating Details Request - Renewal'
order by ajs.job_date desc
------------------------------------------------------------------------------------------

--Inner Join BV + OBJECT_BV_VALUE table
select * from object_bv_value ooo, business_variable bv1
where ooo.business_variable_id = bv1.business_variable_id 
--and ooo.object_id in (462356174169, 462356174209, 462327408609)
and bv1.business_variable_name like '%_IN'

select * from business_variable bv1
where bv1.business_variable_name like '%_IN'
--and ooo.object_id in (462356174169, 462356174209, 462327408609)
--and bv1.business_variable_name like '%_IN'
order by bv1.business_variable_id desc

select * from priv_md.business_variable bv where bv.business_variable_id in (28026805)
select * from priv_md.rule r where r.rule_id = 12915139
select * from priv_st.risk_model_block_setup r where r.pd_product_id = 73833 and r.LAST_PD_FILING_ID is null
SELECT * FROM priv_md.outcome o where o.outcome_id = 75739
select * from priv_st.dragon_policy where AGENCY_NUMBER = 14673900

select DISTINCT(dp.policy_number)
from priv_st.dragon_policy_trx dpt
inner join priv_st.dragon_policy dp
on dpt.policy_id = dp.policy_id
where dpt.POLICY_TRX_STATUS_ID = 106 --Processed
and dp.POLICY_LINES = 'Home Surplus Lines - California'
and ((dpt.POLICY_TRX_EFF_DATE >= to_date('05/01/2025' , 'MM/DD/YYYY') and dpt.policy_trx_type_id in (9, 4, 5099)) --NB, Endorsement, NB Rewrite
or (dpt.POLICY_TRX_EFF_DATE >= to_date('07/01/2025' , 'MM/DD/YYYY') and dpt.policy_trx_type_id = 8)) --Renewal
and dp.AGENCY_NUMBER <> 14673900 --System Validation LLC

------------------------------------------------------------------------------------------
--BV trace
insert into priv_st.dragon_variable_trace(TRACE_ID, TRACE_DRAGON_VARIABLE_ID, USER_SESSION_ID, COMPOSITE_SEARCH_KEY, TRACE_LOGGING_LEVEL, TRACE_LOGGING_LEVEL_DESC)
values (29643514, 29643514 ,null, null, 4, 'PPC Override');

------------------------------------------------------------------------------------------
--DRAGON LICENSE
insert into priv_st.dragon_license (LICENSE_ID, LICENSE_STATE, LICENSE_NUMBER, LICENSE_CODE, LICENSE_CATEGORY, LICENSE_TYPE, PARTNER_ID, LICENSE_HOLDER_NAME, ADMITTED_OR_SURPLUS, 
LICENSE_OVERRIDE_STATUS_TEXT, PARENT_OBJECT_ID, LICENSE_OBJECT_STATUS_TEXT, LICENSE_CATEGORY_ENUM, LICENSE_CODE_ENUM, LICENSE_TYPE_ENUM, LICENSE_STATE_ENUM, LICENSE_EXPIRATION_DATE )
values (8786546565, 'WY', '674563485', 'Property/Casualty', 'Agent', 'Agency', 3151879419, 'MULTI STATE AGENCY', 'Admitted and Surplus' , 'Override active' , 3151879419, ' Active', 
1, 5, 1, 52, to_date('20270805 12:01:00 AM' , 'YYYYMMDD HH24:MI:SS') );

select * from dragon_license dl where dl.ADMITTED_OR_SURPLUS = 'Admitted and Surplus' and dl.LICENSE_OBJECT_STATUS_TEXT = 'Active' AND DL.LICENSE_STATE = 'CA'

select * from priv_api.AGENT_RESOURCES
select * from priv_st.dragon_license dl WHERE DL.LICENSE_ID = 852589658
select * from priv_md.action a where a.action_id = 1303039

------------------------------------------------------------------------------------------
--DRAGON_USER, DRAHGON_USER_GROUP, DRAGON_PARTNER, DRAGON_HOUSEHOLD
select * from DRAGON_HOUSEHOLD where HOUSEHOLD_ID = 461548968339
select * from priv_st.dragon_policy where POLICY_NUMBER = 'PA201246605'
SELECT * FROM PPU_FL_0_PR_CARRIER WHERE JURISDICTION_SET = 12
select * from VW_USER_GROUP_ASSIGNMENT where USER_FULL_NAME = 'National Team' and USER_FULL_NAME = 'Katrina Benge'

select * from priv_st.DRAGON_USER WHERE lower(USER_FULL_NAME) like '%branislav%'
select * from priv_st.DRAGON_USER WHERE PURE_PROGRAMS_USER_ONLY is not null
select * from priv_st.DRAGON_USER_ASSOCIATED_GROUP where DRAGON_USER_ACTOR_TYPE_NAME = 'Underwriting Technician' and DRAGON_USER_NAME = 'National Team'
select * from priv_st.DRAGON_USER_ASSOCIATED_GROUP where DRAGON_USER_NAME = 'National Team' --DRAGON_USER_ID
select * from priv_st.DRAGON_USER where USER_FULL_NAME = 'National Team' --USER_ID
select * from priv_st.DRAGON_USER_ASSOCIATED_GROUP where DRAGON_USER_GROUP_NAME = 'OneshieldSmoke'


SELECT DUAG.DRAGON_USER_ID,DU.USER_FULL_NAME,STATUS_ID USER_STATUS_ID, STATUS_DESC, DU.ACTOR_TYPE_ID, DP.UW_TECHNICIAN,
--DRAGON_USER_GROUP_ID, DRAGON_USER_GROUP_NAME, DU, dsuh.REGION_STATE_ID, dsuh.REGION_STATE,
upper(DU.USER_FULL_NAME) USER_FULL_NAME_UPPER, DU.PURE_PROGRAMS_USER_ONLY
FROM DRAGON_USER_ASSOCIATED_GROUP DUAG
join DRAGON_USER DU
on DUAG.DRAGON_USER_ID = DU.USER_ID
left join DRAGON_PARTNER DP
on DP.UW_TECHNICIAN = DU.USER_FULL_NAME
where USER_FULL_NAME = 'National Team'


select * from VW_USER_GROUP_ASSIGNMENT --where user_full_name = 'National Team'
where DRAGON_USER_GROUP_ID is not null 
and ACTOR_TYPE_ID in (14206,5) 
and (USER_STATUS_ID = to_number(75) or USER_STATUS_ID is null) 
and (PURE_PROGRAMS_USER_ONLY is null or PURE_PROGRAMS_USER_ONLY<>('Yes'))
and USER_FULL_NAME like '%National Team%'


SELECT DUG.DRAGON_USER_ID,DU.USER_FULL_NAME,STATUS_ID USER_STATUS_ID, STATUS_DESC,
DRAGON_USER_GROUP_ID, DRAGON_USER_GROUP_NAME, DU.ACTOR_TYPE_ID, dsuh.REGION_STATE_ID, dsuh.REGION_STATE,
upper(DU.USER_FULL_NAME) USER_FULL_NAME_UPPER, DU.PURE_PROGRAMS_USER_ONLY
FROM DRAGON_USER_ASSOCIATED_GROUP DUG
join DRAGON_USER DU
on DUG.DRAGON_USER_ID = DU.USER_ID
left join DRAGON_SURPLUS_UW_HISTORY dsuh
on dug.dragon_user_group_id=dsuh.uw_group_id and dsuh.end_date is null;


select * from priv_st.dragon_partner 
where UW_GROUP_ID is not null 
and UW_GROUP_NAME is not null 
and UW_PRIMARY is not null 
and UW_SERVICE_ASSOC is not null

select * from priv_st.dragon_partner where UW_TECHNICIAN is null --= 'National Team'
select * from priv_st.dragon_partner where UW_GROUP_NAME = 'Underwriting Group 1' --'Underwriting Group 2'
select * from priv_api.system_attribute_values where ATTRIBUTE_value like '%https://%'

select USER_ID, USER_FULL_NAME, PURE_PROGRAMS_USER_ONLY, PARTNER_OBJECT_STATUS, UW_TECHNICIAN
from DRAGON_PARTNER DP
join DRAGON_USER DU
on DU.USER_FULL_NAME = DP.UW_TECHNICIAN
where ( PURE_PROGRAMS_USER_ONLY is null or PURE_PROGRAMS_USER_ONLY <> 'Yes')
and USER_FULL_NAME = 'National Team'
and PARTNER_OBJECT_STATUS = 'Approved'
and UW_TECHNICIAN = 'National Team'

-------------------------------------------------------------------------------------------------------------

select * from priv_st.POLK_VEHICLE
select distinct(LICENSE_STATE) from dragon_license dl where dl.ADMITTED_OR_SURPLUS = 'Admitted and Surplus' and dl.LICENSE_OBJECT_STATUS_TEXT = 'Active'
select * from dragon_license dl where dl.ADMITTED_OR_SURPLUS = 'Admitted and Surplus' and dl.LICENSE_OBJECT_STATUS_TEXT = 'Active' AND DL.LICENSE_STATE = 'AZ'

SELECT * FROM PRIV_md.variable_path_ref vpr where vpr.variable_path_ref_id in (1003227137)
SELECT * FROM PRIV_ST.variable_path vp where vp.variable_path_id in (59640937)
SELECT * FROM PRIV_ST.variable_path_member vpm WHERE VPM.VARIABLE_PATH_MEMBER_ID in (81456637)

SELECT * FROM PRIV_ST.variable_path_member vpm where vpm.VARIABLE_PATH_ID in (59454639, 59454839, 59456439)
SELECT * FROM PRIV_ST.variable_path_ref vpr where vpr.VARIABLE_PATH_ID in (60648437)

select * from priv_api.AGENT_RESOURCES
select * from priv_md.risk_model_block_setup r where r.pd_product_id = 73833
select * from priv_st.dragon_license dl WHERE DL.LICENSE_ID = 852589658
select * from priv_md.xml_schema_attribute x where x.xml_schema_attribute_id = 197024637

insert into priv_st.dm_grade_reason(REASON_ID, LOCATION_FULL_ADDRESS, TIV, AGGREGATION_SCORE, NON_CAT_GRADE, CAT_SCORE, PERIL_1, PERIL_2) 461951916329
values (4, '673 Alta Vista Dr, Gatlinburg, Tennessee 37738', '14500000', 'Very High', 'F', 'Extreme', 'WILDFIRE', 'EARTHQUAKE'); --PT

insert into priv_st.dm_grade_reason(REASON_ID, HOUSEHOLD_ID, POLICY_TRX_POLICY_ID, LOCATION_FULL_ADDRESS, TIV, AGGREGATION_SCORE, NON_CAT_GRADE, CAT_SCORE, PERIL_1, PERIL_2)
values (2, 461918082769, 461940379659, '673 Alta Vista Dr, Gatlinburg, Tennessee 37738', 14500000, 'Very High', 'F', 'Extreme', 'Wildfire', 'Earthquake'); --PolicyQuote

insert into priv_st.dm_grade_reason(REASON_ID, DRAGON_OBJECT_ID, HOUSEHOLD_ID, POLICY_TRX_POLICY_ID, LOCATION_FULL_ADDRESS, TIV, AGGREGATION_SCORE, NON_CAT_GRADE, CAT_SCORE, PERIL_1, PERIL_2)
values (1, 461940833009, 461940832859, 461940832789, '670 Alta Vista Dr, Gatlinburg, Tennessee 37734', 15000000, 'High', 'F', 'Moderate', 'Wildfire', 'Earthquake'); --PolicyQuote 461951916329

insert into priv_st.dm_grade_reason(REASON_ID, DRAGON_OBJECT_ID, HOUSEHOLD_ID, POLICY_TRX_POLICY_ID, LOCATION_FULL_ADDRESS, TIV, 
AGGREGATION_SCORE, NON_CAT_GRADE, CAT_SCORE, PERIL_1, PERIL_2, GRADE_ORDER_DATE, PROP_TYPE_NAME, LC360_GRADE_IND, REASON)
values (6, 745855789679  , 745855776099  , 745855775999, '775 Cascade Ave, Oregon City, Oregon 97045', 10500000,
'N/A', 'C', 'N/A', 'N/A', 'N/A', sysdate, 'Condo', 2, 'Location is not eligible. Refer to building guidelines'); --PolicyQuote 461951916329

insert into priv_st.dm_grade_reason(REASON_ID, HOUSEHOLD_ID, LOCATION_FULL_ADDRESS, TIV, 
AGGREGATION_SCORE, NON_CAT_GRADE, CAT_SCORE, PERIL_1, PERIL_2, GRADE_ORDER_DATE, PROP_TYPE_NAME, REASON, POLICY_NUMBER)
values (25, 461927783739, '2970 Elderberry Dr S, Salem, Oregon 97302', 15000000,
'Extreme', 'F', 'Extreme', 'Wildfire', 'Wildfire', sysdate, 'Homeowner', 'N/A', 'HO118903800'); --PolicyQuote 461951916329

select * from priv_st.dm_grade_reason dgr where dgr.dragon_object_id = 745862781366/*dgr.CAT_SCORE in ('5','6') and dgr.NON_CAT_GRADE = 'C'*/
select * from priv_st.dragon_policy dp where dp.HOUSEHOLD_ID = 774952552019
select * from priv_st.DRAGON_POLICY_QUOTE dpq where dpq.policyquote_id = 774952551939
select * from dragon_risk_location
--update priv_st.dm_grade_reason dgr set dgr.NON_CAT_GRADE = 'C' where dgr.dragon_object_id = 745862781366

------------------------------------

--procedure for auto creating tasks
declare
begin
pkg_os_wf_task.sp_action_result_tasks(
1,
1,
1038333, --action id
22, --outcome
745882269356); --policy quote ID
end;

------------------------------------

begin pkg_os_object_io.sp_object_bv_set(1, 
                                        1, 
                                        461950044099, --Task Object ID
                                        27499104, --BV ID
                                        'The policy referenced below has been Canceled. 
                                        Please contact your underwriter or PURE Broker Services at (888) 813-PURE (7873) or brokerservices@pureinsurance.com if you have questions or need assistance. 
                                        Member: Phillips Peter Account: 461940433219 Policy #: HO118864400'); 
end;

begin pkg_os_object_io.sp_object_bv_set(1, 
                                        1, 
                                        462003853659, 
                                        29836814, 
                                        null); 
end;

select * from priv_st.dragon_task dt where dt.TASK_TYPE = 'Underwriting Referral - Cancellation' order by TASK_CREATED_DATE desc--where dt.task_id = 461950044099
select * from priv_st.long_string ls where ls.long_string_id = 69884533
select * from priv_st.long_string ls where ls.long_string_id = 68150367
select * from priv_md.pd_filing pf where pf.pd_filing_id = 127483337

select pkg_cs_address_standardization.fn_is_bad_location(1, 1, 461979540819) from dual;
select * from VW_BOR_AGENCY_TRANSFER_DETAILS WHERE POLICY_ID = 751287619666


select * from priv_st.action_integration_log ail where AIL.POLICY_TRANSACTION_POLICY_ID = 461939313339

select * from VW_ER_COVERAGE_CODES
select * from vw_er_input_values

-----------------------------------------------------------------------------------------------
select pkg_cs_functions.fn_bceg_year_exists(1001, 1001, 461937233059, 461937290689) from dual;

select pkg_cs_functions.fn_bceg_exists(1001, 1001, 461937235749, '2012', '04') from dual --461937080919

select pkg_cs_functions.fn_bceg_year_closest_is(1001, 1001, '2012', 461937233059, 461937290689 , '04'  ) from dual --461937080919


select pkg_pv_custom_rules_01.fn_is_bceg_yrcompare_tf (1 , 1 , 461935938559 ) from dual;

select pkg_pv_custom_rules_02.fn_default_bceg_renewal (1 , 1 , 461935938559 ) from dual;

select pkg_pv_custom_rules_01.fn_bceg_min_yr(1, 1, 461938040879) from dual;

select pkg_cs_functions.fn_bceg_year_closest_get(1, 1, 461936042709, 461937080919) from dual;


select * from priv_st.lookup_lIST LL where ll.LOOKUP_LIST_ID = 5053501

select * from priv_st.action_rule ar where ar.action_rule_id in (836906)

select * from priv_st.pd_transaction_set pd where pd.pd_transaction_set_id in (4805)

select * from priv_st.pd_property pp where pp.PD_PROPERTY_ID = 467033
select * from priv_st.pd_property_type ppt where ppt.PD_PROPERTY_TYPE_ID = 27633


select * from priv_st.page_layout_cell plc where plc.page_layout_cell_id = 21627535
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 752896097339, '27992205.29795214') from dual --_Reference_Head of Household
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214') from dual --Reference_Current ISO Report
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214.29911514') from dual --PPCVal
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748779, '28033605.211345.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214.29965814') from dual --DwellPPC
select priv_api.pkg_os_object_io.fn_object_bv_path_get(1, 1, 743067748829, '26774802.29916214.29916014.29919014.29905014.29905914.29906514.29909614.29910214.29918214') from dual --Reference_reference to PPC report object


select priv_api.pkg_pv_custom_rules.fn_pure_claim_loss_tf(1, 1, 635842359857, 2379907, 'Auto-At-Fault') from dual; --excess
select priv_api.pkg_pv_custom_rules.fn_pure_claim_loss_tf(1, 1, 635842359857, 2380107, 'Auto-At-Fault') from dual; --auto
      
    
select * from priv_st.ods_tpr_report_order tpr
where tpr.tpr_report_type = 'AutoCLUE'
and tpr.household_id = 346490377219
order by TPR_ORDER_DATE desc-- check AutoClue reports for household


select * from priv_st.jurisdiction_set where JURISDICTION_SET_ID = 20133

select * from priv_st.dragon_household

select * from priv_st.DM_ALL_INCIDENT

select * from priv_st.pd_renewal_mod_rule where pd_renewal_mod_rule_id = 479014

select * from priv_st.pd_initialization_group where INITIALIZATION_GROUP_ID = 692635

select * from priv_st.dragon_policy where policy_number = 'PA198777106'

select * from priv_st.pc_coverage_rule where pc_coverage_rule_id in (2404135, 2403735)

select pkg_pv_nada.fn_get_renewal_agv ( 1   , 1  , 465871150159  ) from dual 

select pkg_os_lookup.fn_lookup_list_short_text_get( 5323105, 3) from dual;

select * from priv_st.page_layout_block where page_layout_block_id = 736607

select * from priv_st.page_layout_cell where page_layout_cell_id = 12425314

select * from priv_st.ODS_TPR_REPORT_ORDER

select distinct dpt.POLICY_ID from priv_st.dragon_policy_trx dpt
inner join priv_st.dragon_policy dp
on dp.policy_id = dpt.POLICY_ID
where trunc(dpt.POLICY_TRX_IMAGE_EFF_DATE) >= to_date('20220313' , 'YYYYMMDD')
and trunc(dpt.POLICY_TRX_PROCESS_DATE) < trunc(dpt.POLICY_TRX_IMAGE_EFF_DATE) and dpt.POLICY_TRX_TYPE_ID = 8
and dp.POLICY_LOB_ID = 19
and dp.POLICY_JURISDICTION_ID = 16

select * from priv_st.dragon_policy

select * from priv_st.action_rule where action_rule_id = 11295332

select * from priv_md.pc_coverage where PC_COVERAGE_ID = 1274933

select * from priv_st.rule where rule_id = 12737637

select * from priv_st.pd_filing where pd_filing_id = 105

select * from priv_st.jurisdiction_set where jurisdiction_set_id = 28135

select * from priv_st.action_overload where ACTION_OVERLOAD_ID = 3835

select * from priv_st.action_validation where action_validation_id in (33514, 57933) 

select * from priv_api.UW_REASSIGN_SURPLUS_BROKERS

select * from priv_st.dragon_task where TASK_CREATED_DATE >= trunc(to_date('20210924' , 'YYYYMMDD')) 
order by TASK_LAST_UPDATED_DATE and TASK_DESCRIPTION like '%services@pureinsurance.com%' 

select * from priv_md.tr_object_bv_transform tr where tr.tr_object_bv_transform_id = 14150437

select * from ODS_MGU_LOCATION_COVERAGE where mgu_policy_id = 750957782639 and location_coverage_id = 750957782679 

select * from priv_st.action_integration_log where lower(AI_NAME) like '%predictive analytics%'
select distinct(AI_NAME) from priv_st.action_integration_log

select * from priv_st.action_integration_log where POLICY_TRANSACTION_POLICY_ID = 745929171986 order by AI_LOG_TIMESTAMP desc

select distinct EMAIL_REPLY_TO_ADDRESS from priv_st.email where EMAIL_REPLY_TO_ADDRESS like '%services@pureinsurance.com%'









