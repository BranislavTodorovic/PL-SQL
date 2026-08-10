with quote_drivers as
 (select distinct ddd.policy_image_id, ddd.policypamdr_id as driver_id
  
    from dm_driver_details ddd
  
   where ddd.policy_image_id = 463580591429 -- Policy Quote / PTP
     --and ddd.policypamdr_id = 463580591639 -- PolicyPAMDriverCoverage
     and ddd.policypamdr_id is not null),

ranked_mvr as
 (select qd.policy_image_id,
         qd.driver_id,
         eqjs.message_response_text,
         
         row_number() over(partition by qd.driver_id
         
         order by nvl(eqjs.last_updated_date, eqjs.created_date) desc nulls last,
         
         eqjs.created_date desc nulls last) as response_rank
  
    from quote_drivers qd
  
    join priv_st.external_queue_job_status eqjs
      on eqjs.dragon_object_id = qd.driver_id
  
   where eqjs.report_name = 'mvr_full_flow'
     and eqjs.message_response_text is not null),

latest_mvr as
 (select rm.policy_image_id, rm.driver_id, rm.message_response_text
  
    from ranked_mvr rm
  
   where rm.response_rank = 1),

soap_data as
 (select lm.policy_image_id,
         lm.driver_id,
         
         json_value(lm.message_response_text,
                    '$.reportContext.rawLnResponseXml' returning clob null on
                    empty null on error) as soap_xml
  
    from latest_mvr lm),

response_data as
 (select sd.policy_image_id, sd.driver_id, response_xml_data.response_xml
  
    from soap_data sd,
         xmltable(xmlnamespaces('http://www.w3.org/2003/05/soap-envelope' as
                                "soap",
                                
                                'http://decisioning.lexisnexis.com/ws/rules/orderhandler' as
                                "ns2"),
                  
                  '/soap:Envelope/soap:Body/ns2:PlaceInteractiveOrderResponse'
                  
                  passing xmltype(sd.soap_xml)
                  
                  columns response_xml clob path 'response/text()') response_xml_data
  
   where sd.soap_xml is not null),

mvr_data as
 (select rd.policy_image_id, rd.driver_id, report_xml_data.mvr_xml
  
    from response_data rd,
         xmltable(xmlnamespaces(default 'http://cp.com/rules/client'),
                  
                  '/result/product_results/motor_vehicle_report'
                  
                  passing xmltype(rd.response_xml)
                  
                  columns mvr_xml clob path 'report/text()') report_xml_data
  
   where rd.response_xml is not null)

select md.policy_image_id,
       md.driver_id,
       
       violation_data.violation_number,
       violation_data.state_violation_code,
       violation_data.violation_description,
       violation_data.violation_type,
       violation_data.violation_suspension_date,
       violation_data.conviction_reinstatement_date,
       violation_data.standard_violation_code,
       violation_data.standard_description,
       violation_data.customer_specific_code,
       violation_data.additional_underwriting

  from mvr_data md,
       xmltable(xmlnamespaces(default 'http://cp.com/rules/client'),
                
                '/mvr_report/report/violations/violation'
                
                passing xmltype(md.mvr_xml)
                
                columns violation_number for ordinality,
                
                state_violation_code varchar2(100) path
                'state_violation_code',
                
                violation_description varchar2(200) path 'description',
                
                violation_type varchar2(100) path 'type',
                
                violation_suspension_date varchar2(30) path
                'violation_suspension_date',
                
                conviction_reinstatement_date varchar2(30) path
                'conviction_reinstatement_date',
                
                standard_violation_code varchar2(100) path
                'standard_violations/standard_violation/code',
                
                standard_description varchar2(500) path
                'standard_violations/standard_violation/description',
                
                customer_specific_code varchar2(100) path
                'standard_violations/standard_violation/customer_specific_code',
                
                additional_underwriting varchar2(1000) path
                'standard_violations/standard_violation/additional_underwriting') violation_data

 where md.mvr_xml is not null
   and violation_data.state_violation_code is not null

 order by md.driver_id, violation_data.violation_number;
