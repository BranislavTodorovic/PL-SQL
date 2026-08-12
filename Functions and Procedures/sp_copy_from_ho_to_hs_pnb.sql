PROCEDURE sp_copy_from_ho_to_hs_pnb (
        in_session_id           IN object.object_id%TYPE,
        in_transaction_id       IN object.object_id%TYPE,
        in_action_id            IN action.action_id%type,
        in_action_object_id     IN object.object_id%TYPE,
        io_action_outcome_id    IN OUT outcome.outcome_id%type
) as 


    v_policy_id                 object.object_id%type;
    v_excluded_types            pkg_os_object_copy.t_object_type_list;
    v_included_types            pkg_os_object_copy.t_object_type_list;
    v_dm_tf char := 'T';

    v_created_object_id         object.object_id%type;
    v_household_id              object.object_id%type;
    v_quote_id                  object.object_id%type;
    v_quote_name                varchar2(100);
    v_ptp_id                    object.object_id%type;
    v_policy_trx_id             object.object_id%type;
    v_insurance_line_id         NUMBER;
    v_prod_def_id               NUMBER;
    v_jurisdiction_id           NUMBER;
    v_filing_id                 NUMBER;
    v_eff_date                  date;
    v_transaction_type          number;              

/* ================================================================================ */
    v_quotehousehold_id number;
    v_object_list pkg_os_object.t_object_list;
    v_index number;
    v_hh_location_id number;
    v_excluded_types_location    pkg_os_object_copy.t_object_type_list;
    v_included_types_location    pkg_os_object_copy.t_object_type_list;
    out_duplicate_location number;
    
    type t_quote_locations is table of number(12) index by varchar2(500);
    v_quote_locations       t_quote_locations;
    v_location_string       varchar2(500);
    v_quote_hh_location_id number;
/* ================================================================================ */


    v_procedure_name constant system_log.program_name%type := pkg_name || 'sp_copy_from_ho_to_hs_pnb';
    v_session_control pkg_os_session.r_dragon_session_control := pkg_os_session.fn_session_control_get(in_session_id,
                                                                                                       in_transaction_id);

begin

    /* get policy_id */
    v_policy_id := pkg_os_object_search.fn_object_get_parent_of_type(in_session_id, in_transaction_id, in_action_object_id, 24); -- 24 Policy
    /* get household for policyID */ 
    v_household_id := pkg_os_object_search.fn_object_get_parent_of_type(in_session_id, in_transaction_id, v_policy_id, 319); -- HouseHold




    /* get ptp id */
    select child_image_id into v_ptp_id
    from priv_st.dragon_policy_trx  where policy_trx_id in 
    (
        select MAX(policy_trx_id)
            from priv_st.dragon_policy_trx tr2
                where policy_id = v_policy_id and POLICY_TRX_TYPE_ID not in (4010, 2, 3)  -- TRX_TYPE - ITNR, Cancellation, Reinstatement
                and POLICY_TRX_STATUS_ID = 106    --PolicyTransactionProcessed
                and (select policy_trx_eff_date from priv_st.dragon_policy_trx tr1 where tr1.policy_trx_id = in_action_object_id) >= tr2.policy_trx_eff_date
    );

 
    /* get quote id */  --Need to confirm with Yuriy if we need max
    select MAX(object_id) into v_quote_id from priv_st.object
    where parent_object_id = v_household_id and object_type_id = 53 and object_state_id <> 24; -- Get Quote ID, Not Deleted
    
    /* excluded types */
    v_excluded_types(2465933) := 2465933; --PolicyPHOProgramCyber
    v_excluded_types(375802) := 375802; --PolicyPremiumElement
    v_excluded_types(2240405) := 2240405; --PolicyUnderwritingTriggerDetails
    v_excluded_types(425) := 425; --ObjectTree
    v_excluded_types(325) := 325; --ObjectDocument
    v_excluded_types(383105) := 383105; --PolicyHousehold
    v_excluded_types(2309514) := 2309514; --ObjectCoverageInformation
    v_excluded_types(58) := 58; --Proposal
    v_excluded_types(2297606) := 2297606; --PolicyTransactionCondition
    v_excluded_types(2566435) := 2566435; --DmAllSubjectivity
    v_excluded_types(140) := 140; -- Object Change Descriptor
    


    pkg_os_object_copy.sp_object_clone(in_session_id,
                                       in_transaction_id,
                                       v_ptp_id, -- -> PTPID
                                       v_excluded_types,
                                       v_included_types,
                                       v_created_object_id);

    pkg_os_object.sp_object_transmute(in_session_id, in_transaction_id, v_created_object_id, v_quote_id, 440);   -- policyQuote type id

    /* transaction type NB */
    priv_api.pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_created_object_id, 26590601, 9);

    /* set object state to incomplete */
    priv_api.pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_created_object_id, 210153, 65);


    --  Tell the session that a new object has been created ....
    pkg_os_object_io.sp_object_bv_set(in_session_id,
                                      in_transaction_id,
                                      in_session_id,
                                      pkg_os_constant_bv.gbv_sessionnewobject,
                                      v_created_object_id);


     v_insurance_line_id := 13733; -- HomeSurplusLines
    --Set Insurance Line
    pkg_os_object_io.sp_object_bv_set(in_session_id,
                                      in_transaction_id,
                                      v_created_object_id,
                                      26806004,     -- Policy Insurance Line
                                      v_insurance_line_id);  -- HomeSurplusLines
    
    v_jurisdiction_id := pkg_os_object_io.fn_object_bv_get(in_session_id,
                                                        in_transaction_id,
                                                        v_policy_id,
                                                        pkg_os_constant_bv.gbv_genobjjurisdiction);
    

    v_prod_def_id := fn_get_product_def_id(in_session_id, in_transaction_id, v_jurisdiction_id, v_insurance_line_id);

    -- Set product definition 211636;
    pkg_os_object_io.sp_object_bv_set(in_session_id,
                                      in_transaction_id,
                                      v_created_object_id,
                                      211636,       -- Policy Product Definition ID
                                      v_prod_def_id);


    --Get Product Filing ID
    v_filing_id := pkg_os_product.fn_policy_filing_get(in_session_id,
                                                       in_transaction_id,
                                                       v_created_object_id,
                                                       v_prod_def_id);
    --Set Product Filing ID
    pkg_os_object_io.sp_object_bv_set(in_session_id,
                                      in_transaction_id,
                                      v_created_object_id,
                                      pkg_os_product.gbv_policyratebookfilingid,
                                      v_filing_id);

     --get the quote household
     select object_id 
     into v_quotehousehold_id
     from priv_st.object
     where parent_object_id = v_quote_id
     and object_type_id = 382405;   -- QuoteHousehold
     
     for r_location in (select o.object_id, 
                              upper(replace(listagg(obv.business_variable_value) WITHIN GROUP (ORDER BY obv.business_variable_id),' ','')) AS address_string 
                       from object o
                       inner join object_bv_value obv on obv.object_id = o.object_id
                       where o.parent_object_id = v_quotehousehold_id
                       and o.object_type_id = 450       -- HouseholdLocation
                       and obv.business_variable_id IN( 27846302,   -- _Included_Location Address:Address Line 1
                                                        27846402,   -- _Included_Location Address:Address Line 2
                                                        27846702,   -- _Included_Location Address:Address State
                                                        27846602,   -- _Included_Location Address:Address City
                                                        27846802    -- _Included_Location Address:Address Post Code
                                                        )
                       group by o.object_id)
    loop
        --populate the list
        v_quote_locations(r_location.address_string) := r_location.object_id;
    end loop;    
     
     v_object_list.delete;
     --get all pholocationcoverage objects on the cloned object
     pkg_os_object_search.sp_object_children_of_type_get(in_session_id, in_transaction_id, v_created_object_id, 2261202,v_object_list, null, true, true);

     
     v_index := v_object_list.first;
     while v_index is not null loop
        --get current reference on each phlolocationcoverage --> household location id
        v_hh_location_id := priv_api.pkg_os_object_io.fn_object_bv_get(in_session_id, in_transaction_id, v_object_list(v_index), 26774802);
        
        select distinct location_match_key 
        into v_location_string 
        from dm_household_location_detail 
        where household_location_id = v_hh_location_id;
        
        if v_quote_locations.exists(v_location_string) then
            v_quote_hh_location_id := v_quote_locations(v_location_string);
            
            --object already existed under quote household, set the reference to it
            pkg_os_object_io.sp_object_bv_set (in_session_id, in_transaction_id, v_object_list(v_index), 26774802, v_quote_hh_location_id);
        else
            --clone the existing household location
            pkg_os_object_copy.sp_object_clone(in_session_id,
                                       in_transaction_id,
                                       v_hh_location_id,
                                       v_excluded_types_location,
                                       v_included_types_location,
                                       out_duplicate_location);
             --  Set parent to the quote household ...

             pkg_os_object.sp_object_parent_set(in_session_id, in_transaction_id, out_duplicate_location, v_quotehousehold_id);
             
             -- Set reference on pholocationcoverage
             pkg_os_object_io.sp_object_bv_set (in_session_id,in_transaction_id,v_object_list(v_index),26774802, out_duplicate_location);
            
        end if;
     pkg_os_object_io.sp_object_bv_set (in_session_id, in_transaction_id, v_object_list(v_index), 29921114, 'N');    -- Order property details button clicked indicator 
     v_index := v_object_list.next(v_index);
     end loop;
    

    /* set account reference information to policyQuote Hh */
    pkg_os_object_io.sp_object_bv_set (in_session_id, in_transaction_id, v_created_object_id, 27360105, v_quotehousehold_id);


    pkg_os_logging.sp_log(in_session_id,
                             in_transaction_id,
                             v_procedure_name,
                             '...Created PolicyQuote ID: ' || v_created_object_id);


    
    -- set reference to copied Policy and last transaction (Cancellation or ITNR)
    pkg_os_object_io.sp_object_bv_path_set(in_session_id,
                                           in_transaction_id,
                                           v_created_object_id,-- PolicyQuote
                                           '31492537', -- _Reference_surplusConversionToOriginalHOPolicy
                                           v_policy_id); -- HO Policy ID 
                                           
    pkg_os_object_io.sp_object_bv_path_set(in_session_id,
                                           in_transaction_id,
                                           v_created_object_id,-- PolicyQuote
                                           '31492537.31492637', -- _Reference_policyToLastTransaction
                                           in_action_object_id); -- HO Policy Transaction (ITNR or Cancellation) 
                                                                                 
   -- set HS quote name
   v_quote_name := nvl(pkg_os_object_io.fn_object_bv_path_get(in_session_id,in_transaction_id,v_policy_id, '22067605.27758709'), 'New Quote');
   
   pkg_os_object_io.sp_object_bv_set(in_session_id,
                                     in_transaction_id,
                                     v_created_object_id,-- PolicyQuote
                                     504, -- Policy Date Effective
                                     to_char(trunc(sysdate), 'YYYYMMDDHH24MISS'));   --

   pkg_os_object_io.sp_object_bv_set(in_session_id,
                                     in_transaction_id,
                                     v_created_object_id,-- PolicyQuote
                                     499, -- Policy Date Expiration
                                     to_char(trunc(sysdate + interval '1' year), 'YYYYMMDDHH24MISS'));   -- 


   pkg_os_object_io.sp_object_bv_set(in_session_id,
                                     in_transaction_id,
                                     v_created_object_id,-- PolicyQuote
                                     231, -- Policy Identifier Policy Number
                                     null);   -- 

   pkg_os_object_io.sp_object_bv_set(in_session_id,
                                     in_transaction_id,
                                     v_created_object_id,-- PolicyQuote
                                     29099506, -- Quote Effective Date	
                                     sysdate);   -- 
 
   pkg_os_object_io.sp_object_bv_path_set(in_session_id,
                                          in_transaction_id,
                                          v_created_object_id,-- PolicyQuote
                                          '211319.28931905', -- Quote New PolicyQuote - Name
                                          v_quote_name);   -- 22067605.27758709 

--------------------------------------------------------------------------------
-- Name: Goran Minic
-- Date: 04/11/2024 
-- Project: Streamline E&S Referral
-- Rally ID: 	US40807: Technical - Send transactions to data mart and workflow changes
-- Reason for Change: To update row in datamart for completed scheduled batch job,
--            Insert row for ITNR and Cancelation copy to HS quote - real time.
-- Code review by Leon 
--------------------------------------------------------------------------------
if in_action_id = 1261637 -- PL_PT_ITNR_CopyToHS_Quote_Scheduled_DB
  then 
   pkg_os_object_io.sp_object_bv_set(in_session_id,
                                     in_transaction_id,
                                     v_created_object_id,-- PolicyQuote
                                     31511537, --  Is this HS quote copied in batch?	
                                     'Y'); 
   update priv_st.dm_refer_hs_quote dr
   set  dr.last_update_date = sysdate,
        dr.hs_policy_quote_id = v_created_object_id,
        dr.status = 'Completed'
   where dr.policy_trx_id = in_action_object_id;
  else
    v_transaction_type := pkg_os_object_io.fn_object_bv_path_get(in_session_id,
                                                                 in_transaction_id,
                                                                 in_action_object_id, -- PolicyTransaction ID
                                                                 '212030'); --Transaction Type
    
      v_eff_date := to_date(pkg_os_object_io.fn_object_bv_path_get(in_session_id,
                                                           in_transaction_id,
                                                           in_action_object_id, -- PolicyTransaction ID
                                                           '212029'), 'YYYYMMDDHH24MISS'); -- Transaction Effective Date	 
    insert into priv_st.dm_refer_hs_quote rhs 
           (rhs.id,
            rhs.policy_id,
            rhs.policy_trx_id,
            rhs.eff_date,
            rhs.last_update_date,
            rhs.hs_policy_quote_id,
            rhs.trx_type_id,
            rhs.status)
     values
           (priv_st.dm_refer_hs_quote_sq.nextval,
            v_policy_id,
            in_action_object_id,
            v_eff_date,
            sysdate,
            v_created_object_id,
            v_transaction_type,
            'Completed'
            );
   end if;                
-- end US40807   
   
    -- action outcome OK
    io_action_outcome_id := pkg_os_constant.goutcome_ok;
                                             
    exception when others then

        pkg_os_logging.sp_log_error(in_session_id,
                                    in_transaction_id,
                                    v_procedure_name,
                                    '...An exception is raised' || substr(sqlerrm, 1, 200));

        pkg_os_logging.sp_log_error(in_session_id,
                                    in_transaction_id,
                                    v_procedure_name,
                                    '...Stack trace' || dbms_utility.format_error_backtrace);
    raise;

end sp_copy_from_ho_to_hs_pnb;