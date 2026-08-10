create or replace package mvr_driver_pkg
as

    /*
        Stores one MVR violation.
    */
    type t_violation is record (
        violation_number                pls_integer,
        state_violation_code            varchar2(100),
        violation_description           varchar2(500),
        violation_type                  varchar2(100),
        violation_suspension_date       varchar2(50),
        conviction_reinstatement_date   varchar2(50),
        standard_violation_code         varchar2(100),
        standard_description            varchar2(1000),
        customer_specific_code          varchar2(100),
        additional_underwriting         varchar2(4000)
    );


    /*
        Stores all violations for one driver.
    */
    type t_violation_tab is table of t_violation
        index by pls_integer;


    /*
        Stores one driver and all MVR violations for that driver.
    */
    type t_driver_mvr is record (
        driver_id          number,
        violation_count    pls_integer,
        violations         t_violation_tab
    );


    /*
        Stores all drivers belonging to one Policy Quote/PTP.

        The collection key is policypamdr_id converted to varchar2.
    */
    type t_driver_mvr_tab is table of t_driver_mvr
        index by varchar2(100);


    /*
        Loads MVR violations for all drivers belonging to one
        Policy Quote/PTP.

        in_action_object_id represents:
            dm_driver_details.policy_image_id
    */
    procedure get_policy_quote_mvr (
        in_action_object_id in number,
        drivers             out nocopy t_driver_mvr_tab
    );

end mvr_driver_pkg;
/