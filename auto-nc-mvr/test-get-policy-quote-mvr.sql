declare
    v_drivers       mvr_driver_pkg.t_driver_mvr_tab;
    v_driver_key    varchar2(100);
    v_violation_no  pls_integer;
begin

    /*
        Replace this value with the Policy Quote/PTP identifier.

        The value represents:
            dm_driver_details.policy_image_id
    */
    mvr_driver_pkg.get_policy_quote_mvr(
        in_action_object_id => 123456789,
        drivers             => v_drivers
    );


    dbms_output.put_line(
        'Total drivers: ' || v_drivers.count
    );

    dbms_output.put_line(
        '----------------------------------------'
    );


    v_driver_key := v_drivers.first;

    while v_driver_key is not null
    loop

        dbms_output.put_line(
            'Driver ID: '
            || v_drivers(v_driver_key).driver_id
        );

        dbms_output.put_line(
            'Violation count: '
            || v_drivers(v_driver_key).violation_count
        );


        /*
            Get the first violation for the current driver.
        */
        v_violation_no :=
            v_drivers(v_driver_key).violations.first;


        if v_violation_no is null then

            dbms_output.put_line(
                'No violations found.'
            );

        end if;


        while v_violation_no is not null
        loop

            dbms_output.put_line(
                '  Violation number: '
                || v_drivers(v_driver_key)
                            .violations(v_violation_no)
                            .violation_number
            );

            dbms_output.put_line(
                '  State violation code: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .state_violation_code,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Description: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .violation_description,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Type: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .violation_type,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Suspension date: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .violation_suspension_date,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Conviction/reinstatement date: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .conviction_reinstatement_date,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Standard violation code: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .standard_violation_code,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Standard description: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .standard_description,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Customer-specific code: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .customer_specific_code,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  Additional underwriting: '
                || nvl(
                       v_drivers(v_driver_key)
                           .violations(v_violation_no)
                           .additional_underwriting,
                       'NULL'
                   )
            );

            dbms_output.put_line(
                '  --------------------------------------'
            );


            /*
                Move to the next violation for the current driver.
            */
            v_violation_no :=
                v_drivers(v_driver_key)
                    .violations
                    .next(v_violation_no);

        end loop;


        dbms_output.put_line(
            '========================================'
        );


        /*
            Move to the next driver.
        */
        v_driver_key :=
            v_drivers.next(v_driver_key);

    end loop;

exception
    when others then

        dbms_output.put_line(
            'Error: ' || sqlerrm
        );

        raise;

end;
/