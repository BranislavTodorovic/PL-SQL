create table PRIV_ST.DM_GRADE_REASON
(
  REASON_ID                  NUMBER not null,
  DRAGON_OBJECT_ID           NUMBER,
  OBJECT_TYPE_ID             NUMBER(12),
  HOUSEHOLD_ID               NUMBER,
  POLICY_ID                  NUMBER,
  POLICY_TRX_ID              NUMBER,
  POLICY_TRX_POLICY_ID       NUMBER,
  TRX_TYPE_ID                NUMBER,
  TEMPLATE_PHO_LOCATION_ID   NUMBER,
  POLICY_NUMBER              VARCHAR2(50),
  LOCATION_FULL_ADDRESS      VARCHAR2(500),
  LOCATION_ADDRESS_LINE_1    VARCHAR2(100),
  LOCATION_INSURED_CITY      VARCHAR2(100),
  LOCATION_INSURED_ZIP       VARCHAR2(10),
  GRADE_ORDER_DATE           DATE,
  LOB_ID                     NUMBER,
  JURISDICTION_ID            NUMBER,
  PROP_TYPE                  NUMBER,
  TIV                        NUMBER,
  GRADE                      VARCHAR2(10),
  REASON_PRIORITY            NUMBER,
  REASON                     VARCHAR2(500),
  AGGREGATION_SCORE          VARCHAR2(50), 
  NON_CAT_GRADE              VARCHAR2(10),
  CAT_SCORE                  VARCHAR2(50),
  PERIL_1                    VARCHAR2(100),
  PERIL_2                    VARCHAR2(100)
)
tablespace DATAMART_DATA
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate indexes 
create index PRIV_ST.DM_GRADE_REASON_I1 on PRIV_ST.DM_GRADE_REASON (DRAGON_OBJECT_ID)
  tablespace MART_INDX
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index PRIV_ST.DM_GRADE_REASON_I2 on PRIV_ST.DM_GRADE_REASON (HOUSEHOLD_ID)
  tablespace MART_INDX
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index PRIV_ST.DM_GRADE_REASON_I3 on PRIV_ST.DM_GRADE_REASON (POLICY_TRX_ID)
  tablespace MART_INDX
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index PRIV_ST.DM_GRADE_REASON_I4 on PRIV_ST.DM_GRADE_REASON (POLICY_TRX_POLICY_ID)
  tablespace MART_INDX
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );  
-- Create/Recreate primary, unique and foreign key constraints 
alter table PRIV_ST.DM_GRADE_REASON
  add constraint DM_GRADE_REASON_PK primary key (REASON_ID)
  using index 
  tablespace MART_INDX
  pctfree 10
  initrans 20
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  )
/ 

/* --Grant/Revoke object privileges
grant select, references on PRIV_ST.DM_GRADE_REASON to PRIVDEV; 
grant select, insert, update, delete, references on PRIV_ST.DM_GRADE_REASON to PRIV_API with grant option; 
grant select, insert, update, delete, references on PRIV_ST.DM_GRADE_REASON to PRIV_ARC with grant option; 
grant select, references on PRIV_ST.DM_GRADE_REASON to PRIV_MD; 
grant select, references on PRIV_ST.DM_GRADE_REASON to PRIV_MGMT; 

--Create the synonym 
create or replace synonym DM_GRADE_REASON
for PRIV_ST.DM_GRADE_REASON; */
  
select * from PRIV_ST.DM_GRADE_REASON

alter table DM_GRADE_REASON ADD PROP_TYPE_NAME varchar2(500);
alter table DM_GRADE_REASON ADD LC360_GRADE_IND number;






