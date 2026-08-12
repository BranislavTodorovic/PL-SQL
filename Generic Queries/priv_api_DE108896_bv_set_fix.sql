--   Name: Bran Todorovic
--   Date: 05/29/2026
--   Project: Production Support
--   Rally ID: DE108896 - PURE Online Error
--	 Comment: Updating policy expiration date

begin
priv_api.pkg_os_object_io.sp_object_bv_set(1, 1, 739793584009, 499, to_char( to_date ('20270214000100','YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS') ); -- expiration date
end;
/
declare
v_dm char(1) := 'T';
begin
priv_api.pkg_os_datamart.sp_datamart_update_row(1, 1, 739793584009, v_dm); 
end;
/