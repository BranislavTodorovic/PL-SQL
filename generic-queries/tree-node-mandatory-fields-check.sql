declare

    pkg_name varchar2(50) := 'test.';

    v_bv_list      priv_api.pkg_os_object_io.t_bv_table;
    v_bv_path_list priv_api.pkg_os_object_io.t_bv_path_table;
    v_message_list priv_api.pkg_os_message.t_message_list;

    function fn_boolean_stay_false
    (
        in_current_tf in char,
        in_new_tf     in char
    ) return char is
    
    begin
    
        if in_new_tf = 'F'
        then
        
            return 'F';
        
        elsif in_current_tf = 'F'
        then
        
            return 'F';
        
        else
            return 'T';
        
        end if;
    
    end fn_boolean_stay_false;

    function fn_check_mandatory_data
    (
        in_session_id                 in priv_st.object.object_id%type,
        in_transaction_id             in priv_st.object.object_id%type,
        in_current_object_id          in priv_st.object.object_id%type,
        in_bv_list                    in priv_api.pkg_os_object_io.t_bv_table,
        in_bv_path_list               in priv_api.pkg_os_object_io.t_bv_path_table,
        io_message_list               in out priv_api.pkg_os_message.t_message_list,
        in_set_default_tf             in char,
        in_tree_node_id               in priv_md.object_tree_node.object_tree_node_id%type default null,
        in_node_object_type_id        in priv_md.object_type.object_type_id%type default null,
        in_node_enabled_expression_id in priv_st.object.object_id%type default null,
        in_node_visible_expression_id in priv_st.object.object_id%type default null
    ) return char as
    
        v_bv_value priv_st.object_bv_value.business_variable_value%type;
    
        v_bv_index      number := 1;
        v_bv_path_index number := 1;
    
        v_bv_value_list          priv_api.pkg_os_object_io.t_bv_table;
        v_bv_path_value_list     priv_api.pkg_os_object_io.t_bv_path_table;
        v_current_object_type_id priv_md.object_type.object_type_id%type := priv_api.pkg_os_object.fn_object_type_get(in_session_id,
                                                                                                                      in_transaction_id,
                                                                                                                      in_current_object_id);
        v_node_object_id         priv_st.object.object_id%type;
        v_bv_name                priv_md.business_variable.business_variable_name%type;
        v_object_name            priv_md.object_type.object_type_name%type;
    
        v_procedure_name constant priv_st.system_log.program_name%type := pkg_name || 'fn_check_mandatory_data';
    
        v_isvalid_lookup_value    char(1) := 'T';
        v_domain_check_enabled_tf char(1) := 'T';
        v_return_value            char(1) := 'T';
    
        v_object_tree_id               priv_md.object_tree.object_tree_id%type;
        v_domain_check_enabled_rule_id priv_md.object_tree.domain_check_enabled_rule_id%type;
    
        v_session_control priv_api.pkg_os_session.r_dragon_session_control := priv_api.pkg_os_session.fn_session_control_get(in_session_id,
                                                                                                                             in_transaction_id);
        v_node_label      varchar2(100);
        v_tree_node_label varchar2(100);
    
    begin
    
        --  begin OSCORE-2931
    
        if in_tree_node_id is not null
        then
        
            select node_object_tree_id,
                   node_label
            into   v_object_tree_id,
                   v_tree_node_label
            from   priv_md.object_tree_node
            where  object_tree_node_id in (select node_definition_id
                                           from   priv_st.tmp_tree_nodes
                                           where  node_id = in_tree_node_id);
        
            select domain_check_enabled_rule_id
            into   v_domain_check_enabled_rule_id
            from   priv_md.object_tree
            where  object_tree_id = v_object_tree_id;
        
            select node_label
            into   v_node_label
            from   priv_st.tmp_tree_nodes
            where  node_id = in_tree_node_id;
        
            if v_domain_check_enabled_rule_id is not null
            then
            
                v_domain_check_enabled_tf := priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                        in_transaction_id,
                                                                                        in_current_object_id,
                                                                                        v_domain_check_enabled_rule_id);
            
            end if;
        
        end if;
    
        --  end OSCORE-2931
    
        --  SCR 37772: priv_api.pkg_os_tree_validation checks mandatory fields on disabled and non-visible nodes.
        --
        --  If node enabled/visible IDs are not null, then check that the node is enabled and visible.
        --  If the node is not enabled or not visible, then do not check for mandatory cells.
        --
    
        if in_node_enabled_expression_id is not null
           or in_node_visible_expression_id is not null
        then
        
            --
            --  We could be evaluating a child object of the node object.
            --  We want to check the node rules against the node object.
            --
        
            if priv_api.pkg_os_object_search.fn_object_type_equivalent_tf(in_node_object_type_id,
                                                                          v_current_object_type_id) = 'T'
            then
            
                v_node_object_id := in_current_object_id;
            
            else
            
                v_node_object_id := priv_api.pkg_os_object_search.fn_object_get_parent_of_type(in_session_id,
                                                                                               in_transaction_id,
                                                                                               in_current_object_id,
                                                                                               in_node_object_type_id);
            
            end if;
        
            if v_node_object_id is not null
            then
            
                if (in_node_enabled_expression_id is not null and
                   priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                               in_transaction_id,
                                                               v_node_object_id,
                                                               in_node_enabled_expression_id) = 'F')
                   or (in_node_visible_expression_id is not null and
                   priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                  in_transaction_id,
                                                                  v_node_object_id,
                                                                  in_node_visible_expression_id) = 'F')
                then
                
                    --
                    -- The node is either not enabled or not visible.
                    --
                    -- Do not check for mandatory cells.
                
                    return 'T';
                
                end if;
            
            end if;
        
        end if;
    
        /* End of changes for SCR 37772 */
    
        ------------------------------------------------------------------------------------------------------------
        --   For the current object, get all attributes needed. Note, we do not worry about looking
        --   for multiple instances of the current object, because no layout is allowed to have multiple
        --   instances of its target object... it can however, have multiple instances of child objects.
        ------------------------------------------------------------------------------------------------------------
    
        if priv_api.pkg_os_object_io.fn_object_bv_get(in_session_id,
                                                      in_transaction_id,
                                                      in_current_object_id,
                                                      priv_api.pkg_os_constant_bv.gbv_genobjobjectstate) =
           priv_api.pkg_os_constant.gobjstate_destroyed
        then
        
            --
            --  If the object has been destroyed, don't bother checking it ...
            --
        
            return 'T';
        
        else
        
            --
            --  If the object has not been destroyed, get all of the bvs and bv-paths that we need to check, and
            --  check each one in turn.
            --
            --  If any one is null, we immediately return False.
            --
        
            v_bv_value_list := in_bv_list;
        
            priv_api.pkg_os_object_io.sp_object_bv_get(in_session_id,
                                                       in_transaction_id,
                                                       in_current_object_id,
                                                       v_bv_value_list);
        
            v_bv_index := v_bv_value_list.first;
        
            while v_bv_index is not null
            loop
            
                --
                --  Check if the field is Mandatory.
                --
                if v_bv_value_list(v_bv_index).mandatory_tf = 'T'
                    or v_bv_value_list(v_bv_index).mandatory_rule_id is not null
                then
                
                    if ((v_bv_value_list(v_bv_index).mandatory_tf = 'T' or
                        (v_bv_value_list(v_bv_index).mandatory_rule_id is not null and
                         priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                                             in_transaction_id,
                                                                                                                             in_current_object_id,
                                                                                                                             v_bv_value_list(v_bv_index).mandatory_rule_id) = 'T')) and
                       (v_bv_value_list(v_bv_index).business_variable_value is null or
                        (v_bv_value_list(v_bv_index).logical_data_type_id in
                         (priv_api.pkg_os_constant.gtype_list,
                                                                                   priv_api.pkg_os_constant.gtype_boolean,
                                                                                   priv_api.pkg_os_constant.gtype_reference) and v_bv_value_list(v_bv_index).business_variable_value = 0)))
                    
                    then
                    
                        if (v_bv_value_list(v_bv_index).display_rule_id is null or
                            priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                   in_transaction_id,
                                                                                                   in_current_object_id,
                                                                                                   v_bv_value_list(v_bv_index).display_rule_id) = 'T')
                           and
                           (v_bv_value_list(v_bv_index).mandatory_rule_id is null or
                            priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                   in_transaction_id,
                                                                                                   in_current_object_id,
                                                                                                   v_bv_value_list(v_bv_index).mandatory_rule_id) = 'T')
                           and
                           (v_bv_value_list(v_bv_index).readonly_rule_id is null or
                            priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                   in_transaction_id,
                                                                                                   in_current_object_id,
                                                                                                   v_bv_value_list(v_bv_index).readonly_rule_id) = 'F')
                        then
                        
                            if in_set_default_tf = 'T'
                               and v_bv_value_list(v_bv_index).logical_data_type_id in
                               (priv_api.pkg_os_constant.gtype_list,
                                                                priv_api.pkg_os_constant.gtype_boolean,
                                                                priv_api.pkg_os_constant.gtype_reference)
                            
                            then
                            
                                v_bv_value := priv_api.pkg_os_lookup.sp_bv_default_enum_get(in_session_id,
                                                                                            in_transaction_id,
                                                                                            in_current_object_id,
                                                                                            v_bv_index,
                                                                                            v_bv_value_list(v_bv_index).logical_data_type_id);
                            
                                if v_bv_value is null
                                   or v_bv_value is null
                                then
                                
                                    v_return_value := 'F';
                                
                                else
                                
                                    priv_api.pkg_os_object_io.sp_object_bv_set(in_session_id,
                                                                               in_transaction_id,
                                                                               in_current_object_id,
                                                                               v_bv_index,
                                                                               v_bv_value);
                                
                                    if v_session_control.glogging_full
                                    then
                                    
                                        priv_api.pkg_os_logging.sp_log(in_session_id,
                                                                       in_transaction_id,
                                                                       v_procedure_name,
                                                                       ' ... ...... Setting Default Value for:' || v_bv_value_list(v_bv_index).bv_label ||
                                                                       ' to:' || v_bv_value);
                                    
                                    end if;
                                
                                end if;
                            
                            else
                            
                                if v_session_control.glogging_full
                                then
                                
                                    priv_api.pkg_os_logging.sp_log(in_session_id,
                                                                   in_transaction_id,
                                                                   v_procedure_name,
                                                                   ' ... ...... Mandatory BV is NULL:' || v_bv_value_list(v_bv_index).bv_label ||
                                                                   ' Display Rule:' || v_bv_value_list(v_bv_index).display_rule_id);
                                
                                end if;
                            
                                v_return_value := 'F';
                            
                            end if;
                        
                        end if;
                    
                    end if;
                
                end if;
            
                --
                --  Check if the bv value is valid against the Domain for the Lookup List
                --
            
                --  begin OSCORE-2931
                if v_domain_check_enabled_tf = 'T'
                then
                    --  end OSCORE-2931
                
                    v_bv_name     := priv_api.pkg_os_bv.fn_bv_name_get(v_bv_index);
                    v_object_name := priv_api.pkg_os_object.fn_object_name_get(in_session_id,
                                                                               in_transaction_id,
                                                                               in_current_object_id);
                
                    if v_bv_value_list(v_bv_index)
                     .logical_data_type_id in (priv_api.pkg_os_constant.gtype_list,
                                                 priv_api.pkg_os_constant.gtype_boolean,
                                                 priv_api.pkg_os_constant.gtype_reference)
                    then
                    
                        v_isvalid_lookup_value := priv_api.pkg_os_lookup.fn_isvalid_lookup_value(in_session_id,
                                                                                                 in_transaction_id,
                                                                                                 in_current_object_id,
                                                                                                 v_bv_index,
                                                                                                 null,
                                                                                                 v_bv_value_list(v_bv_index).business_variable_value);
                    
                        if v_isvalid_lookup_value = 'F'
                        then
                        
                            dbms_output.put_line(' ...Invalid List Value selected for Business Variable : ' ||
                                                 v_bv_name || ':-' || v_bv_index || ':-' || ' for the Object : ' ||
                                                 v_object_name || ':-' || in_current_object_id);
                        
                            --
                            --  Add the Message to the I/O message List
                            --
                            if v_node_label is not null
                            then
                            
                                priv_api.pkg_os_message.sp_message_add(io_message_list,
                                                                       'The ' || v_tree_node_label || ' ''' ||
                                                                       v_node_label || '''' ||
                                                                       ' will need to be updated or removed');
                            
                            else
                            
                                priv_api.pkg_os_message.sp_message_add(io_message_list,
                                                                       'The ' || v_tree_node_label ||
                                                                       ' will need to be updated or removed');
                            
                            end if;
                        
                        end if;
                    
                    end if;
                
                    --  begin OSCORE-2931
                end if; --        if v_domain_check_enabled_tf    = 'T' then
                --  end OSCORE-2931
            
                v_return_value := fn_boolean_stay_false(v_return_value, v_isvalid_lookup_value);
            
                v_bv_index := v_bv_value_list.next(v_bv_index);
            
            end loop;
        
            ------------------------------------------------------------------------------------------------------------
            --
            --   For this instance, get all the bv paths needed, add them to the cache ...
            --
            ------------------------------------------------------------------------------------------------------------
        
            v_bv_path_value_list := in_bv_path_list;
        
            priv_api.pkg_os_object_io.sp_object_bv_path_get(in_session_id,
                                                            in_transaction_id,
                                                            in_current_object_id,
                                                            v_bv_path_value_list);
        
            v_bv_path_index := v_bv_path_value_list.first;
        
            while v_bv_path_index is not null
            loop
            
                begin
                
                    if v_bv_path_value_list(v_bv_path_index).mandatory_tf = 'T'
                        or v_bv_path_value_list(v_bv_path_index).mandatory_rule_id is not null
                    then
                    
                        if (v_bv_path_value_list(v_bv_path_index).mandatory_tf = 'T' or
                            (v_bv_path_value_list(v_bv_path_index).mandatory_rule_id is not null and
                             to_char(priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                                                                            in_transaction_id,
                                                                                                                                                            in_current_object_id,
                                                                                                                                                            v_bv_path_value_list(v_bv_path_index).mandatory_rule_id)) = 'T'))
                           and
                           (v_bv_path_value_list(v_bv_path_index).business_variable_value is null or
                            (v_bv_path_value_list(v_bv_path_index).logical_data_type_id in
                             (priv_api.pkg_os_constant.gtype_list,
                                                                                                          priv_api.pkg_os_constant.gtype_boolean,
                                                                                                          priv_api.pkg_os_constant.gtype_reference) and v_bv_path_value_list(v_bv_path_index).business_variable_value = 0))
                        
                        then
                        
                            if (v_bv_path_value_list(v_bv_path_index).display_rule_id is null or
                                priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                                 in_transaction_id,
                                                                                                                 in_current_object_id,
                                                                                                                 v_bv_path_value_list(v_bv_path_index).display_rule_id) = 'T')
                               and
                               (v_bv_path_value_list(v_bv_path_index).mandatory_rule_id is null or
                                priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                                 in_transaction_id,
                                                                                                                 in_current_object_id,
                                                                                                                 v_bv_path_value_list(v_bv_path_index).mandatory_rule_id) = 'T')
                               and
                               (v_bv_path_value_list(v_bv_path_index).readonly_rule_id is null or
                                priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                                                                 in_transaction_id,
                                                                                                                 in_current_object_id,
                                                                                                                 v_bv_path_value_list(v_bv_path_index).readonly_rule_id) = 'F')
                            then
                            
                                if in_set_default_tf = 'T'
                                   and v_bv_path_value_list(v_bv_path_index).logical_data_type_id in
                                   (priv_api.pkg_os_constant.gtype_list,
                                                                              priv_api.pkg_os_constant.gtype_boolean,
                                                                              priv_api.pkg_os_constant.gtype_reference)
                                then
                                
                                    v_bv_value := priv_api.pkg_os_lookup.sp_bv_default_enum_get(in_session_id,
                                                                                                in_transaction_id,
                                                                                                in_current_object_id,
                                                                                                priv_api.pkg_os_bv.fn_bv_path_bv_get(v_bv_path_value_list(v_bv_path_index).business_variable_path),
                                                                                                v_bv_path_value_list(v_bv_path_index).logical_data_type_id);
                                
                                    if v_bv_value is null
                                       or v_bv_value is null
                                    then
                                        dbms_output.put_line(' ... ...... Mandatory Cell:' || v_bv_path_value_list(v_bv_path_index).bv_path_label ||
                                                             ' is null ... Rule:' || v_bv_path_value_list(v_bv_path_index).display_rule_id);
                                    
                                        v_return_value := 'F';
                                    
                                    else
                                    
                                        priv_api.pkg_os_object_io.sp_object_bv_path_set(in_session_id,
                                                                                        in_transaction_id,
                                                                                        in_current_object_id,
                                                                                        v_bv_path_value_list(v_bv_path_index).business_variable_path,
                                                                                        v_bv_value);
                                    
                                        dbms_output.put_line(' ... ...... Setting Default Value for:' || v_bv_path_value_list(v_bv_path_index).bv_path_label ||
                                                             ' to:' || v_bv_value);
                                    end if;
                                
                                else
                                
                                    dbms_output.put_line(' ... ...... Mandatory Cell:' || v_bv_path_value_list(v_bv_path_index).bv_path_label ||
                                                         ' is null ... Rule:' || v_bv_path_value_list(v_bv_path_index).display_rule_id);
                                
                                    v_return_value := 'F';
                                
                                end if;
                            
                            end if; -- if the attribute is being displayed ...
                        
                        end if; -- if there is a suspicion of the attribute being null ...
                    
                    end if; -- Is a mandatory field ...
                
                exception
                
                    when others then
                        dbms_output.put_line(' Error when checking for mandatory - BV:' || v_bv_path_value_list(v_bv_path_index).business_variable_path ||
                                             ' Mandatory Rule:' || v_bv_path_value_list(v_bv_path_index).mandatory_rule_id ||
                                             ' Error:' || sqlerrm);
                    
                end;
            
                --  begin OSCORE-2931
                if v_domain_check_enabled_tf = 'T'
                then
                    --  end OSCORE-2931
                
                    --
                    --  Check if the bv value is valid against the Domain for the Lookup List
                    --
                
                    v_bv_name     := priv_api.pkg_os_bv.fn_bv_name_get(priv_api.pkg_os_bv.fn_bv_path_bv_get(v_bv_path_value_list(v_bv_path_index).business_variable_path));
                    v_object_name := priv_api.pkg_os_object.fn_object_name_get(in_session_id,
                                                                               in_transaction_id,
                                                                               in_current_object_id);
                
                    if v_bv_path_value_list(v_bv_path_index)
                     .logical_data_type_id in (priv_api.pkg_os_constant.gtype_list,
                                                 priv_api.pkg_os_constant.gtype_boolean,
                                                 priv_api.pkg_os_constant.gtype_reference)
                    then
                    
                        v_isvalid_lookup_value := priv_api.pkg_os_lookup.fn_isvalid_lookup_value(in_session_id,
                                                                                                 in_transaction_id,
                                                                                                 in_current_object_id,
                                                                                                 priv_api.pkg_os_bv.fn_bv_path_bv_get(v_bv_path_value_list(v_bv_path_index).business_variable_path),
                                                                                                 v_bv_path_value_list(v_bv_path_index).business_variable_path,
                                                                                                 v_bv_path_value_list(v_bv_path_index).business_variable_value);
                    
                        if v_isvalid_lookup_value = 'F'
                        then
                        
                            dbms_output.put_line(' ...Invalid List Value selected for Business Variable : ' ||
                                                 v_bv_name || ':-' ||
                                                 priv_api.pkg_os_bv.fn_bv_path_bv_get(v_bv_path_value_list(v_bv_path_index).business_variable_path) || ':-' ||
                                                 ' for the Object : ' || v_object_name || ':-' || in_current_object_id);
                        
                            --
                            --  Add the Message to the I/O message List
                            --
                        
                            if v_node_label is not null
                            then
                            
                                priv_api.pkg_os_message.sp_message_add(io_message_list,
                                                                       'The ' || v_tree_node_label || ' ''' ||
                                                                       v_node_label || '''' ||
                                                                       ' will need to be updated or removed');
                            
                            else
                            
                                priv_api.pkg_os_message.sp_message_add(io_message_list,
                                                                       'The ' || v_tree_node_label ||
                                                                       ' will need to be updated or removed');
                            
                            end if;
                        
                        end if;
                    
                    end if;
                
                    --  begin OSCORE-2931
                end if; --    if v_domain_check_enabled_tf    = 'T' then
                --  end OSCORE-2931
            
                v_return_value := fn_boolean_stay_false(v_return_value, v_isvalid_lookup_value);
            
                v_bv_path_index := v_bv_path_value_list.next(v_bv_path_index);
            
            end loop;
        
        end if;
   
        return v_return_value;
    
    end fn_check_mandatory_data;

    function fn_node_validate_mandatory
    (
        in_session_id                 in priv_st.object.object_id%type,
        in_transaction_id             in priv_st.object.object_id%type,
        in_current_object_id          in priv_st.object.object_id%type,
        in_action_id                  in priv_md.action.action_id%type,
        io_message_list               in out priv_api.pkg_os_message.t_message_list,
        in_set_default_tf             in char,
        in_tree_node_id               in priv_md.object_tree_node.object_tree_node_id%type default null,
        in_node_object_type_id        in priv_md.object_type.object_type_id%type default null,
        in_node_enabled_expression_id in priv_st.object.object_id%type default null,
        in_node_visible_expression_id in priv_st.object.object_id%type default null
    ) return char is
    
        v_out_valid_tf          char(1) := 'T';
        v_valid_tf              char(1) := 'T';
        v_action_object_type_id priv_md.object_type.object_type_id%type;
        v_base_object_id        priv_st.object.object_id%type;
        v_page_layout_id        priv_md.page_layout.page_layout_id%type;
        v_root_object_id        priv_st.object.object_id%type;
        v_root_object_type_id   priv_md.object_type.object_type_id%type;
    
        v_driver_object_index number;
        v_bv_index            number;
        v_bv_path_index       number := 1;
    
        v_object_list        priv_api.pkg_os_object.t_object_list;
        v_bv_list            priv_api.pkg_os_object_io.t_bv_table;
        v_bv_value_list      priv_api.pkg_os_object_io.t_bv_table;
        v_bv_path_list       priv_api.pkg_os_object_io.t_bv_path_table;
        v_bv_path_value_list priv_api.pkg_os_object_io.t_bv_path_table;
    
        v_current_object_type_id priv_md.object_type.object_type_id%type := priv_api.pkg_os_object.fn_object_type_get(in_session_id,
                                                                                                                      in_transaction_id,
                                                                                                                      in_current_object_id);
        v_jurisdiction_id        priv_md.jurisdiction.jurisdiction_id%type := priv_api.pkg_os_jurisdiction.fn_object_jurisdiction_get(in_session_id,
                                                                                                                                      in_transaction_id,
                                                                                                                                      in_current_object_id);
        v_industry_id            priv_md.industry.industry_id%type := priv_api.pkg_os_industry.fn_object_industry_get(in_session_id,
                                                                                                                      in_transaction_id,
                                                                                                                      in_current_object_id);
        v_actor_type_id          priv_md.actor_type.actor_type_id%type := priv_api.pkg_os_wf_session.fn_actor_type_get(in_session_id,
                                                                                                                       in_transaction_id);
        v_product_id             priv_md.pd_product.pd_product_id%type := priv_api.pkg_os_product.fn_object_product_get(in_session_id,
                                                                                                                        in_transaction_id,
                                                                                                                        in_current_object_id);
        v_filing_id              priv_md.pd_filing.pd_filing_id%type := priv_api.pkg_os_product.fn_policy_filing_get(in_session_id,
                                                                                                                     in_transaction_id,
                                                                                                                     in_current_object_id,
                                                                                                                     v_product_id);
        v_logical_data_type_id   priv_md.business_variable.logical_data_type_id%type;
    
        -- OSDRAGON-13919
        v_program_id priv_md.program.program_id%type := priv_api.pkg_os_program.fn_object_program_get(in_session_id,
                                                                                                      in_transaction_id,
                                                                                                      in_current_object_id);
    
        v_session_control priv_api.pkg_os_session.r_dragon_session_control := priv_api.pkg_os_session.fn_session_control_get(in_session_id,
                                                                                                                             in_transaction_id);
    
        v_procedure_name constant priv_st.system_log.program_name%type := pkg_name || 'fn_node_validate_mandatory';
        v_procedure_start_time date := sysdate;
    
        v_ot_bv_list     priv_api.pkg_os_page_layout.t_ot_bv_detail;
        r_object_type_bv priv_api.pkg_os_page_layout.r_ot_bv_detail;
    
        v_block_list         priv_api.pkg_os_page_layout.t_page_layout_block_list;
        r_driver_object_type priv_md.page_layout_block%rowtype;
        v_product_list       t_obj_type_list;
    
    begin
    
        --
        --  Get the page layout ...
        --
    
        v_page_layout_id := priv_api.pkg_os_action.fn_action_row(in_action_id).page_layout_id;
    
        --
        -- Get the action object type for the page...
        --
        v_action_object_type_id := priv_api.pkg_os_action.fn_action_row(in_action_id).object_type_id;
    
        --
        --  Provide logging information ...
        --
    
        /* dbms_output.put_line('|||||| Validating Mandatory Fields for Page Action:' || in_action_id || ' Jurisdiction:' ||
        v_jurisdiction_id || ' Industry:' || v_industry_id || ' Program: ' || v_program_id || -- OSDRAGON-13919
        ' Actor:' || v_actor_type_id || ' Product:' || v_product_id);*/
    
        --
        --   For all the driver object types present in the layout  ...
        --
        v_product_list := t_obj_type_list();
        v_product_list.extend();
        v_product_list(v_product_list.count) := v_product_id;
    
        v_block_list := priv_api.pkg_os_page_layout.fn_driver_ot_detail_get(in_session_id        => in_session_id,
                                                                            in_transaction_id    => in_transaction_id,
                                                                            in_current_object_id => in_current_object_id,
                                                                            in_action_id         => in_action_id,
                                                                            in_jurisdiction_id   => v_jurisdiction_id,
                                                                            in_product_list      => v_product_list,
                                                                            in_industry_id       => v_industry_id,
                                                                            in_program_id        => v_program_id, -- OSDRAGON-13919
                                                                            in_actor_type_id     => v_actor_type_id);
    
        for v_idx in 1 .. v_block_list.count
        loop
            --dbms_output.put_line('start block list');
            --r_driver_object_type := v_block_list(v_idx);
        
            /*dbms_output.put_line(' ... Considering Object-Type:' || v_block_list(v_idx).block_driver_object_type_id ||
            ' Root Path:' || v_block_list(v_idx).block_root_object_path);*/
        
            --
            --   For the object-type in question, figure out the list of attributes that are needed by the layout ...
            --
        
            v_bv_list      := priv_api.pkg_os_object_io.gnull_bv_table;
            v_bv_path_list := priv_api.pkg_os_object_io.gnull_bv_path_table;
        
            v_bv_path_index := 1;
        
            v_ot_bv_list := priv_api.pkg_os_page_layout.fn_object_type_bv_detail(in_session_id        => in_session_id,
                                                                                 in_transaction_id    => in_transaction_id,
                                                                                 in_current_object_id => in_current_object_id,
                                                                                 in_action_id         => in_action_id,
                                                                                 in_object_type_id    => v_block_list(v_idx).block_driver_object_type_id,
                                                                                 --in_filing_id                  => v_filing_id,
                                                                                 in_jurisdiction_id        => v_jurisdiction_id,
                                                                                 in_product_list           => v_product_list,
                                                                                 in_industry_id            => v_industry_id,
                                                                                 in_program_id             => v_program_id, -- OSDRAGON-13919
                                                                                 in_actor_type_id          => v_actor_type_id,
                                                                                 in_check_path_tf          => 'T',
                                                                                 in_block_root_object_path => v_block_list(v_idx).block_root_object_path);
        
            for v_idx in 1 .. v_ot_bv_list.count
            loop
            
                r_object_type_bv := v_ot_bv_list(v_idx);
            
                v_logical_data_type_id := priv_api.pkg_os_bv.fn_bv_path_data_type_get(nvl(to_char(r_object_type_bv.cell_business_variable_id),
                                                                                          r_object_type_bv.cell_business_variable_path));
            
                if r_object_type_bv.cell_business_variable_id is not null
                then
                
                    v_bv_list(r_object_type_bv.cell_business_variable_id).bv_label := r_object_type_bv.page_layout_cell_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).front_end_type_id := r_object_type_bv.cell_front_end_source_type_id;
                    --          v_bv_list( r_object_type_bv.cell_business_variable_id ).logical_data_type_id   := r_object_type_bv.cell_logical_data_type_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).logical_data_type_id := v_logical_data_type_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).display_rule_id := r_object_type_bv.cell_display_rule_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).mandatory_rule_id := r_object_type_bv.cell_mandatory_rule_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).readonly_rule_id := r_object_type_bv.cell_readonly_rule_id;
                    v_bv_list(r_object_type_bv.cell_business_variable_id).mandatory_tf := r_object_type_bv.cell_mandatory_tf;
                
                else
                
                    v_bv_path_list(v_bv_path_index).business_variable_path := r_object_type_bv.cell_business_variable_path;
                    v_bv_path_list(v_bv_path_index).bv_path_label := r_object_type_bv.page_layout_cell_id;
                    v_bv_path_list(v_bv_path_index).front_end_type_id := r_object_type_bv.cell_front_end_source_type_id;
                    --          v_bv_path_list( v_bv_path_index ).logical_data_type_id      := r_object_type_bv.cell_logical_data_type_id;
                    v_bv_path_list(v_bv_path_index).logical_data_type_id := v_logical_data_type_id;
                    v_bv_path_list(v_bv_path_index).display_rule_id := r_object_type_bv.cell_display_rule_id;
                    v_bv_path_list(v_bv_path_index).mandatory_rule_id := r_object_type_bv.cell_mandatory_rule_id;
                    v_bv_path_list(v_bv_path_index).readonly_rule_id := r_object_type_bv.cell_readonly_rule_id;
                    v_bv_path_list(v_bv_path_index).mandatory_tf := r_object_type_bv.cell_mandatory_tf;
                
                    v_bv_path_index := v_bv_path_index + 1;
                
                end if;
            
            end loop;
        
            /*dbms_output.put_line('... Considering Object-Type:' || v_block_list(v_idx).block_driver_object_type_id ||
            ' Found BVs:' || v_bv_list.count || ' Found BV Paths:' || v_bv_path_list.count);*/
        
            --
            --   Based on the current object, which provides context, find all instances of the object-type in question.
            --
            --   For each object found, add it to the object cache.
            --
        
            v_object_list.delete;
        
            if priv_api.pkg_os_object_search.fn_object_type_equivalent_tf(v_block_list(v_idx).block_driver_object_type_id,
                                                                          v_current_object_type_id) = 'T'
            then
            
                -- dbms_output.put_line('...... Using Current ObjectID:' || in_current_object_id);
            
                v_object_list(1) := in_current_object_id;
            
            else
            
                v_object_list := priv_api.pkg_os_object.gnull_object_list;
            
                if v_block_list(v_idx).block_root_object_path is null
                then
                
                    --dbms_output.put_line('...... Searching Using Current ObjectID:' || in_current_object_id);
                
                    priv_api.pkg_os_object_search.sp_object_children_of_type_get(in_session_id,
                                                                                 in_transaction_id,
                                                                                 in_current_object_id,
                                                                                 v_block_list(v_idx).block_driver_object_type_id,
                                                                                 v_object_list);
                
                else
                
                    v_root_object_id := priv_api.pkg_os_object_io.fn_object_bv_path_get(in_session_id,
                                                                                        in_transaction_id,
                                                                                        in_current_object_id,
                                                                                        v_block_list(v_idx).block_root_object_path);
                
                    v_root_object_type_id := priv_api.pkg_os_object.fn_object_type_get(in_session_id,
                                                                                       in_transaction_id,
                                                                                       v_root_object_id);
                
                    --dbms_output.put_line('...... Searching Using Root ObjectID:' || v_root_object_id);
                
                    if priv_api.pkg_os_object_search.fn_object_type_equivalent_tf(v_root_object_type_id,
                                                                                  v_block_list(v_idx).block_driver_object_type_id) = 'T'
                    
                    then
                    
                        v_object_list(1) := v_root_object_id;
                    
                    else
                    
                        priv_api.pkg_os_object_search.sp_object_children_of_type_get(in_session_id,
                                                                                     in_transaction_id,
                                                                                     v_root_object_id,
                                                                                     v_block_list(v_idx).block_driver_object_type_id,
                                                                                     v_object_list);
                    
                    end if;
                
                end if;
            
                --dbms_output.put_line('...... Found Child Objects:' || v_object_list.count);
            
            end if;
        
            --
            --  Check whether there are sufficient instances of the object in question ... if there are insufficient
            --  instance, the node is by definition incomplete.
            --
            --  If there are sufficient instances, then check whether the mandatory BVs are filled.
            --
        
            if v_object_list.count < v_block_list(v_idx).minimum_instances
            then
            
                v_out_valid_tf := fn_boolean_stay_false(v_out_valid_tf, 'F');
            
            else
            
                --
                --   Add the found instance of this type to the object cache
                --
            
                v_driver_object_index := v_object_list.first;
            
                while v_driver_object_index is not null
                loop
                
                    if v_block_list(v_idx).block_list_filter_rule_id is null
                        or
                        priv_api.pkg_os_exp.fn_evaluate_expression(in_session_id,
                                                                   in_transaction_id,
                                                                   v_object_list(v_driver_object_index),
                                                                   v_block_list(v_idx).block_list_filter_rule_id) = 'T'
                    then
                    
                        -- Add object instance attributes to the cache ...
                    
                        v_valid_tf := fn_check_mandatory_data(in_session_id,
                                                              in_transaction_id,
                                                              v_object_list(v_driver_object_index),
                                                              v_bv_list,
                                                              v_bv_path_list,
                                                              io_message_list,
                                                              in_set_default_tf,
                                                              in_tree_node_id,
                                                              in_node_object_type_id,
                                                              in_node_enabled_expression_id,
                                                              in_node_visible_expression_id);
                    else
                    
                        v_valid_tf := 'T';
                    
                    end if;
                
                    v_out_valid_tf := fn_boolean_stay_false(v_out_valid_tf, v_valid_tf);
                
                    v_driver_object_index := v_object_list.next(v_driver_object_index);
                
                end loop; -- for each object that was found ...
            
            end if;
        
        end loop;
    
        return v_out_valid_tf;
    
    end fn_node_validate_mandatory;

begin
    for r_node in (select ttn.node_assoc_object_id,
                          otn.node_page_action_id,
                          ttn.node_id
                   from   priv_st.tmp_tree_nodes ttn
                   inner  join priv_md.object_tree_node otn on otn.object_tree_node_id = ttn.node_definition_id
                   where  ttn.tree_id in (select distinct tree_id
                                          from   priv_st.tmp_tree_nodes ttn
                                          where  ttn.node_assoc_object_id =   742818994119   --ptp id
                                          )
                   and    ttn.node_completeness_status != 'Complete'
                   and    (otn.node_visible_expression_id is null or
                         priv_api.pkg_os_expression.fn_evaluate_expression(1,
                                                                             1,
                                                                             ttn.node_assoc_object_id,
                                                                             otn.node_visible_expression_id) = 'T'))
    loop
    
        dbms_output.put_line(fn_node_validate_mandatory(in_session_id        => 1,
                                                        in_transaction_id    => 1,
                                                        in_current_object_id => r_node.node_assoc_object_id,
                                                        in_action_id         => r_node.node_page_action_id,
                                                        io_message_list      => v_message_list,
                                                        in_set_default_tf    => 'F',
                                                        in_tree_node_id      => r_node.node_id));
    end loop;
end;
