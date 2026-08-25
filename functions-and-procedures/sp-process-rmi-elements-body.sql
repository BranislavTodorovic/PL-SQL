procedure sp_process_rmi_elements(
    in_session_id       in      object.object_id%type,
    in_transaction_id   in      object.object_id%type,
    in_pho_location_id  in      object.object_id%type
) is
    v_procedure_name       CONSTANT system_log.program_name%TYPE := pkg_name || 'sp_process_rmi_elements';

    v_policy_image_id           object.object_id%type := pkg_os_object_io.fn_object_bv_path_get(in_session_id, in_transaction_id, in_pho_location_id, '27857902.27834002.211405'); -- _Parent_PolicyPHO._Parent_PolicyPersonal._Parent_Policy

    v_product_id                pd_product.pd_product_id%type := pkg_os_product.fn_object_product_get(in_session_id, in_transaction_id, v_policy_image_id);

    v_filing_id                 pd_filing.pd_filing_id%type := pkg_os_product.fn_policy_filing_get(in_session_id, in_transaction_id, v_policy_image_id, v_product_id);

    v_object_list               pkg_os_object.t_object_list;
    v_index                     number;

    type tt_element_rec is record (
        element_active          char(1),
        element_id              object.object_id%type,
        system_premium          number(28, 2),
        system_rol              number(28, 2),
        uw_adj_factor           number(28, 4),
        final_premium           number(28, 2),
        final_rol               number(28, 2)
    ); 
       
    type tt_element_map is table of tt_element_rec index by varchar2(150);
    tab_element_map             tt_element_map;

    v_map_index                 varchar2(150);

    v_element_id                object.object_id%type;
begin
    pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '!!!Starting element processing for PolicyPHOLocation id: ' || in_pho_location_id);

    tab_element_map.delete;

    -- get existing list elements
    pkg_os_object_search.sp_object_children_of_type_get(in_session_id, in_transaction_id, in_pho_location_id, gObjType_RMIBlockElement, v_object_list);

    -- map the list as it currently is
    v_index := v_object_list.first;
    while v_index is not null loop
        v_map_index :=
            pkg_os_object_io.fn_object_bv_get(in_session_id, in_transaction_id, v_object_list(v_index), gBV_ElementOrder) || ':' ||
            pkg_os_object_io.fn_object_bv_get(in_session_id, in_transaction_id, v_object_list(v_index), gBV_ElementName);
        tab_element_map(v_map_index).element_id := v_object_list(v_index);

        -- We do not know yet if this element is active. Set it to inactive now
        tab_element_map(v_map_index).element_active := 'F';

        pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '...mapped existing element: ' || v_map_index);

        v_index := v_object_list.next(v_index);
    end loop;

    -- get the metadata defs of the elements
    for r_element_def in (
        select SORT_ORDER, LABEL, LAST_PD_FILING_ID, PD_FILING_ID, PD_PRODUCT_ID, ID, SYSTEM_ROL_PATH, SYSTEM_PREMIUM_PATH, final_premium_override, final_rol_override
        from risk_model_block_setup
        where
            (pd_product_id is null or pd_product_id = 0 or pd_product_id = v_product_id)
            and (pd_filing_id is null or pd_filing_id <= v_filing_id)
            and (last_pd_filing_id is null or last_pd_filing_id >= v_filing_id)
    ) loop
        v_map_index := r_element_def.SORT_ORDER || ':' || r_element_def.LABEL;

        pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '...processing element from metadata: ' || v_map_index);

        -- do we have this element already? If not we need to create it now
        v_element_id := null;
        if not tab_element_map.exists(v_map_index) then
            pkg_os_object.sp_object_create(in_session_id, in_transaction_id, gObjType_RMIBlockElement, in_pho_location_id, v_element_id);

            pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_element_id, gBV_ElementName, r_element_def.LABEL);
            pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_element_id, gBV_ElementOrder, r_element_def.SORT_ORDER);
            tab_element_map(v_map_index).element_id := v_element_id;
            pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '......no match, created new id: ' || v_element_id);
        else
            v_element_id := tab_element_map(v_map_index).element_id;
            pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '......match, existing id: ' || v_element_id);
        end if;
        
        -- now we know this element is active
        tab_element_map(v_map_index).element_active := 'T';

        -- set the BVs now
        if r_element_def.SYSTEM_PREMIUM_PATH is not null then
            tab_element_map(v_map_index).system_premium := pkg_os_object_io.fn_object_bv_path_get(in_session_id, in_transaction_id, in_pho_location_id, r_element_def.SYSTEM_PREMIUM_PATH);
    
            pkg_os_object_io.sp_object_bv_set(
                in_session_id, in_transaction_id, v_element_id, gBV_ElementSysPremium,
                tab_element_map(v_map_index).system_premium
            );
           
        end if;
        if r_element_def.SYSTEM_ROL_PATH is not null then
            tab_element_map(v_map_index).system_rol := pkg_os_object_io.fn_object_bv_path_get(in_session_id, in_transaction_id, in_pho_location_id, r_element_def.SYSTEM_ROL_PATH);
            
            pkg_os_object_io.sp_object_bv_set(
                in_session_id, in_transaction_id, v_element_id, gBV_ElementSysROL,
                tab_element_map(v_map_index).system_rol
            );
            
        end if;
 
        tab_element_map(v_map_index).uw_adj_factor := nvl(pkg_os_object_io.fn_object_bv_get(in_session_id, in_transaction_id, v_element_id, gBV_ElementUWAdjFactor), 1);

        -- If we have overrides, use them instead of calculating
        if r_element_def.final_premium_override is not null then
            tab_element_map(v_map_index).final_premium := nvl(pkg_os_object_io.fn_object_bv_path_get(in_session_id, in_transaction_id, in_pho_location_id, r_element_def.final_premium_override), 0);
      
        else
            tab_element_map(v_map_index).final_premium := tab_element_map(v_map_index).system_premium * tab_element_map(v_map_index).uw_adj_factor;
        
        end if;
        if r_element_def.final_rol_override is not null then
            
            tab_element_map(v_map_index).final_rol := nvl(pkg_os_object_io.fn_object_bv_path_get(in_session_id, in_transaction_id, in_pho_location_id, r_element_def.final_rol_override), 0);
        else
            tab_element_map(v_map_index).final_rol := tab_element_map(v_map_index).system_rol * tab_element_map(v_map_index).uw_adj_factor; 
        
        end if;

        pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_element_id, gBV_ElementFinalPremium, tab_element_map(v_map_index).final_premium);
        pkg_os_object_io.sp_object_bv_set(in_session_id, in_transaction_id, v_element_id, gBV_ElementFinalROL, tab_element_map(v_map_index).final_rol);          
        
    end loop;

    -- and now clean up any elements that are no longer active (last filed?)
    v_map_index := tab_element_map.first;
    while v_map_index is not null loop
        if tab_element_map(v_map_index).element_active = 'F' then
            pkg_os_logging.sp_log(in_session_id, in_transaction_id, v_procedure_name, '...deleting unused element: ' || v_map_index);
            pkg_os_object.sp_object_delete(
                in_session_id           =>  in_session_id,
                in_transaction_id       =>  in_transaction_id,
                in_parent_object_id     =>  in_pho_location_id,
                in_object_id            =>  tab_element_map(v_map_index).element_id,
                in_object_type_id       =>  gObjType_RMIBlockElement
                );
        end if;
        v_map_index := tab_element_map.next(v_map_index);
    end loop;
exception
    when others then
        pkg_os_logging.sp_log_error(in_session_id, in_transaction_id, v_procedure_name, sqlerrm);
        pkg_os_logging.sp_log_error(in_session_id, in_transaction_id, v_procedure_name, dbms_utility.format_error_backtrace);
        raise;
end sp_process_rmi_elements;