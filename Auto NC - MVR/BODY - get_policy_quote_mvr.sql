create or replace package body mvr_driver_pkg
as

    procedure get_policy_quote_mvr (
        in_action_object_id in number,
        drivers             out nocopy t_driver_mvr_tab
    )
    is
        v_driver_key       varchar2(100);
        v_violation_index  pls_integer;
    begin

        /*
            Clear the output collection before processing starts.
        */
        drivers.delete;


        /*
            Validate the Policy Quote/PTP input value.
        */
        if in_action_object_id is null then

            raise_application_error(
                -20001,
                'in_action_object_id cannot be null'
            );

        end if;


        /*
            Initialize every driver belonging to the Policy Quote/PTP.

            This guarantees that drivers without an MVR response remain
            present in the output collection with violation_count = 0.
        */
        for driver_rec in (
            select distinct
                ddd.policypamdr_id as driver_id

            from dm_driver_details ddd

            where ddd.policy_image_id = in_action_object_id
              and ddd.policypamdr_id is not null

            order by
                ddd.policypamdr_id
        )
        loop

            v_driver_key :=
                to_char(driver_rec.driver_id);

            drivers(v_driver_key).driver_id :=
                driver_rec.driver_id;

            drivers(v_driver_key).violation_count :=
                0;

            drivers(v_driver_key).violations.delete;

        end loop;


        /*
            Stop processing when no drivers were found for the supplied
            Policy Quote/PTP identifier.
        */
        if drivers.count = 0 then

            raise_application_error(
                -20002,
                'no drivers found for action object id '
                || to_char(in_action_object_id)
            );

        end if;


        /*
            Read the latest MVR response for every driver and load all
            violations into the in-memory collection.

            Processing flow:

                Policy Quote/PTP
                    ->
                dm_driver_details
                    ->
                external_queue_job_status
                    ->
                JSON
                    ->
                SOAP XML
                    ->
                response XML
                    ->
                MVR XML
                    ->
                violations
        */
        for violation_rec in (

            with quote_drivers as (
                select distinct
                    ddd.policy_image_id,
                    ddd.policypamdr_id as driver_id

                from dm_driver_details ddd

                where ddd.policy_image_id =
                      in_action_object_id

                  and ddd.policypamdr_id is not null
            ),

            ranked_mvr as (
                select
                    qd.policy_image_id,
                    qd.driver_id,
                    eqjs.message_response_text,

                    row_number() over (
                        partition by
                            qd.driver_id

                        order by
                            nvl(
                                eqjs.last_updated_date,
                                eqjs.created_date
                            ) desc nulls last,

                            eqjs.created_date desc nulls last
                    ) as response_rank

                from quote_drivers qd

                join priv_st.external_queue_job_status eqjs
                  on eqjs.dragon_object_id =
                     qd.driver_id

                where eqjs.message_response_text is not null

                /*
                    Add the report-type condition from the original
                    working query here when the EQJS table contains
                    multiple report types for the same driver.

                    Example:

                    and eqjs.report_name = 'mvr_full_flow'
                */
            ),

            latest_mvr as (
                select
                    rm.policy_image_id,
                    rm.driver_id,
                    rm.message_response_text

                from ranked_mvr rm

                where rm.response_rank = 1
            ),

            soap_data as (
                select
                    lm.policy_image_id,
                    lm.driver_id,

                    json_value(
                        lm.message_response_text,
                        '$.reportContext.rawLnResponseXml'
                        returning clob
                        null on empty
                        null on error
                    ) as soap_xml

                from latest_mvr lm
            ),

            response_data as (
                select
                    sd.policy_image_id,
                    sd.driver_id,
                    soap_result.response_xml

                from soap_data sd

                cross join xmltable(
                    xmlnamespaces(
                        'http://www.w3.org/2003/05/soap-envelope'
                            as "soap",

                        'http://decisioning.lexisnexis.com/ws/rules/orderhandler'
                            as "ns2"
                    ),

                    '/soap:Envelope/soap:Body/ns2:PlaceInteractiveOrderResponse'

                    passing xmltype(sd.soap_xml)

                    columns
                        response_xml clob
                            path 'response/text()'
                ) soap_result

                where sd.soap_xml is not null
            ),

            mvr_data as (
                select
                    rd.policy_image_id,
                    rd.driver_id,
                    mvr_result.mvr_xml

                from response_data rd

                cross join xmltable(
                    xmlnamespaces(
                        default 'http://cp.com/rules/client'
                    ),

                    '/result/product_results/motor_vehicle_report'

                    passing xmltype(rd.response_xml)

                    columns
                        mvr_xml clob
                            path 'report/text()'
                ) mvr_result

                where rd.response_xml is not null
            )

            select
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

            from mvr_data md

            cross join xmltable(
                xmlnamespaces(
                    default 'http://cp.com/rules/client'
                ),

                '/mvr_report/report/violations/violation'

                passing xmltype(md.mvr_xml)

                columns
                    violation_number
                        for ordinality,

                    state_violation_code
                        varchar2(100)
                        path 'state_violation_code',

                    violation_description
                        varchar2(500)
                        path 'description',

                    violation_type
                        varchar2(100)
                        path 'type',

                    violation_suspension_date
                        varchar2(50)
                        path 'violation_suspension_date',

                    conviction_reinstatement_date
                        varchar2(50)
                        path 'conviction_reinstatement_date',

                    standard_violation_code
                        varchar2(100)
                        path 'standard_violations/standard_violation/code',

                    standard_description
                        varchar2(1000)
                        path 'standard_violations/standard_violation/description',

                    customer_specific_code
                        varchar2(100)
                        path 'standard_violations/standard_violation/customer_specific_code',

                    additional_underwriting
                        varchar2(4000)
                        path 'standard_violations/standard_violation/additional_underwriting'
            ) violation_data

            where md.mvr_xml is not null

            order by
                md.driver_id,
                violation_data.violation_number
        )
        loop

            /*
                Get the driver record from the output collection.
            */
            v_driver_key :=
                to_char(violation_rec.driver_id);


            /*
                Increase the violation count for the current driver.

                The new count is also used as the index in the driver's
                violation collection.
            */
            v_violation_index :=
                drivers(v_driver_key).violation_count + 1;


            /*
                Store the current violation in memory.
            */
            drivers(v_driver_key)
                .violations(v_violation_index)
                .violation_number :=
                    violation_rec.violation_number;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .state_violation_code :=
                    violation_rec.state_violation_code;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .violation_description :=
                    violation_rec.violation_description;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .violation_type :=
                    violation_rec.violation_type;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .violation_suspension_date :=
                    violation_rec.violation_suspension_date;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .conviction_reinstatement_date :=
                    violation_rec.conviction_reinstatement_date;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .standard_violation_code :=
                    violation_rec.standard_violation_code;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .standard_description :=
                    violation_rec.standard_description;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .customer_specific_code :=
                    violation_rec.customer_specific_code;

            drivers(v_driver_key)
                .violations(v_violation_index)
                .additional_underwriting :=
                    violation_rec.additional_underwriting;


            /*
                Save the updated number of violations for the driver.
            */
            drivers(v_driver_key).violation_count :=
                v_violation_index;

        end loop;


    exception
        when others then

            /*
                Clear the output collection because a complete and reliable
                result could not be produced.

                Re-raise the original Oracle error to the caller.
            */
            drivers.delete;

            raise;

    end get_policy_quote_mvr;

end mvr_driver_pkg;
/