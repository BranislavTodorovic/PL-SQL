--HS CA - Query to find places where premium accounting rollup is not equal to the sum of the premium coverages
SELECT
  --DP.POLICY_LINES, POL.POLICY_NUMBER, POL.POLICY_TRANSACTION_ID, ROLL.ACCOUNTING_TOTAL_ROLLUP, CALC.TOTAL_COVERAGE_SUM, ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM DIFFERENCE
  DP.POLICY_LINES, POL.POLICY_NUMBER, POL.TRX_TYPE, pol.object_state_id, /*pol.ostate,/*POL.SERVICING_BROKER_NUMBER,*/ POL.POLICY_IMAGE_ID, POL.POLICY_TRANSACTION_ID, /*POL.DATE_CREATED, POL.TRX_DATE_PROCESSED, POL.TRX_DATE_EFFECTIVE,*/ ROLL.ACCOUNTING_TOTAL_ROLLUP, CALC.TOTAL_COVERAGE_SUM, ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM DIFFERENCE
FROM
  (SELECT DISTINCT PT.POLICY_NUMBER, 
  PT.TRX_TYPE, 
  --priv_api.pkg_cs_privdev.fn_lookup_list_text_get  (50170, o.object_state_id, 1, 1) as oState,/*PT.Servicing_Broker_Number,*/ 
  object_state_id,
  DTS.POLICY_IMAGE_ID, DTS.POLICY_TRANSACTION_ID, PT.DATE_CREATED, PT.TRX_DATE_PROCESSED, PT.TRX_DATE_EFFECTIVE
  FROM PRIV_ST.DRAGON_TRANSACTION_STATS DTS JOIN PRIV_ST.ODS_POLICY_TRANSACTION PT ON (DTS.POLICY_TRANSACTION_ID = PT.POLICY_TRANSACTION_ID)
  /**/JOIN PRIV_ST.Object O ON (o.object_id = PT.POLICY_TRANSACTION_ID and O.OBJECT_TYPE_ID = 629)
  WHERE DTS.COVERAGE_NAME = 'Accounting Rollup - Premium') POL
  LEFT OUTER JOIN 
  (SELECT PT1.POLICY_NUMBER, PT1.POLICY_TRANSACTION_ID, SUM(DTS1.CURRENT_AMOUNT/**/) ACCOUNTING_TOTAL_ROLLUP
  FROM PRIV_ST.DRAGON_TRANSACTION_STATS DTS1 JOIN PRIV_ST.ODS_POLICY_TRANSACTION PT1 ON (DTS1.POLICY_TRANSACTION_ID = PT1.POLICY_TRANSACTION_ID)
  WHERE DTS1.COVERAGE_NAME = 'Accounting Rollup - Premium'
  GROUP BY PT1.POLICY_NUMBER, PT1.POLICY_TRANSACTION_ID) ROLL ON   
    (POL.POLICY_NUMBER = ROLL.POLICY_NUMBER AND POL.POLICY_TRANSACTION_ID = ROLL.POLICY_TRANSACTION_ID)
  LEFT OUTER JOIN  
  (SELECT PT2.POLICY_NUMBER, PT2.POLICY_TRANSACTION_ID, SUM(DTS2.Current_Amount/**/) TOTAL_COVERAGE_SUM
  FROM PRIV_ST.DRAGON_TRANSACTION_STATS DTS2 JOIN PRIV_ST.ODS_POLICY_TRANSACTION PT2 ON (DTS2.POLICY_TRANSACTION_ID = PT2.POLICY_TRANSACTION_ID)
  WHERE 
  (
  ((SUBSTR(PT2.POLICY_NUMBER, 1, 2) = 'HO' OR SUBSTR(PT2.POLICY_NUMBER, 1, 2) = 'HX' OR SUBSTR(PT2.POLICY_NUMBER, 1, 2) = 'HS')
  AND trim(DTS2.COVERAGE_NAME) NOT IN (
    'Accounting Rollup - Premium', 'Accounting Rollup - Surplus Contribution', 'Accounting Rollup - Surcharge', 'Accounting Rollup - Fees', 'Accounting Rollup - Taxes', 
    'Accounting Rollup - Commissions', --'Reporting - Wind and Non Wind Surcharges', jmm to match stats
    'Grand Total Premium', 'Total Premium', 'Manuscript Endorsements Total', 'Premium Adjustment Total',
    'Non Wind/Wind Final Premium', 'Location Premium', 'Optional Coverages Premium', 'Total Location Premium',
    'Florida Hurricane CAT Fund Assessment - Home', 'Florida CEA Fund Assessment', 'Capital Contribution', '2005 LA Fair Plan Emergency Assessment - Home', 'Excess Flood',
    'Reset Coverage', 'Bureau Rate - Policy', 'Bureau Rate - Location', 'Multiplicative Premium - Policy', 'Multiplicative Premium - Location',
	'Healthy Homes Fund Surcharge','Reporting - Total Earthquake Premium','Reporting - Total Earthquake Premium'
    ,'Reporting - Total Flood Premium', 'Minimum Rate On Line'
   , 'Reporting - Total Premium Except Flood and Earthquake', 'Reporting - Total Flood Premium'
   , 'Non Wind/Wind Final Premium Calculated', 'Reporting - Total Earthquake Premium' 
    ,'Reporting - Basic Earthquake Coverage', 'Reporting - Earthquake Coverage Premium', 'Total Earthquake Commission', 
	'Reporting - Basic Earthquake Coverage Commission' ,'Workers Compensation Coverage', 'Reporting - Broad Earthquake Coverage Commission', 
	'Reporting - Earthquake Premium', 'Special Terms and Conditions Total' --CA
    , 'Reporting - Total Commission Except Earthquake' , 'Reporting - Total Premium Except Earthquake' --CA
    , 'Minimum Rate On Line Option 1', 'Minimum Rate On Line Option 2', 'Fire Safety Surcharge', 'Loss Limitation Total'
    , 'Other Structures On the Res Prem Increased Limits - HO 04 48 Total', 'Specific Structures Away From the Res Prem - HO 04 92 Total', 
	'Additional Insured - Student Living Away From the Res Prem - HO 05 27 Total', 'Structures Rented to Others - HO 04 40 Total'
    , 'Section II - Liability Coverage Extension Total', 'County Tax', 'Fire and Allied Perils and County Tax', 'Casualty Only County Tax', 
	'Casualty Only City Tax', 'City Tax', 'Municipality Tax and State Surcharge'
    , 'Reporting - Kentucky State Surcharge', 'Reporting - Municipality Tax total for the location', 'Fire and Allied Perils City Tax', 'Hazard Mitigation Fee'
    , 'West Virginia Surcharge Pursuant to Section 33-3-33 - Home', 'JIA Surcharge', 'Mine Subsidence Coverage', 'State Mandated Fee'
    , 'California Surplus Lines Stamping Fee - Inspection Fee','California Surplus Lines Stamping Fee - Inspection Fee per Location',
	'California Surplus Lines Stamping Fee - Policy Premium'
    ,'California Surplus Lines Tax - Inspection Fee', 'California Surplus Lines Tax - Inspection Fee per Location', 'California Surplus Lines Tax - Policy Premium'
    , 'Collections Final Premium', 'Collections Total Premium Before adjustments', 'Inspection Fee', 'Inspection Fee per Location', 'PSE Surplus Contribution'
    ,'Reporting - Minimum Earned Premium', 'Reporting - Total Earthquake Commission', 'Total Location Premium including Collections' ,
	'Liability Extension' --,'Liability Extension Surcharge'
    , 'E&S Florida Premium Tax - Inspection Fee', 'E&S Florida Premium Tax - Inspection Fee per Location', 'E&S Florida Premium Tax - Policy Premium', 
	'E&S Florida Premium Tax - Surplus Lines Broker Fee'
    , 'EMPA Surcharge', 'Florida Stamping Fee - Broker Fee', 'Reporting - Location Inspection Fee', 'Reporting - Location Premium Before', 
	'Reporting - Location Premium Final ROL'
    , 'Reporting - Non Wind Premium Final', 'Reporting - Non-Wind Premium Final ROL', 'Reporting - Total Location Premium Before', 
	'Reporting - Total Location Premium Final ROL'
    , 'Reporting - Wind Premium Final ROL', 'Stamping Fee - Inspection Fee', 'Stamping Fee - Inspection Fee per Location', 'Stamping Fee - Policy Premium', 
	'Surplus Lines Broker Fee'
    , 'Reporting - Wind Premium Final', 'E&S Florida Premium Tax - PSE Surplus Contribution', 'Non-Wind Premium Adjustment Total', 
	'E&S California Premium Tax - Surplus Lines Broker Fee'
    , 'Fine Art', 'Wine', 'Worldwide Jewelry', 'Coins, Silver, Stamps, Furs,Musical Instruments', 'Collectibles', 'Taxable Premium'
  -- ,  'Fine Art - Scheduled', 'Worldwide Jewelry - Blanket', 'Collectibles - Scheduled'
 --   , 'Worldwide Jewelry - Scheduled', 'Coins, Silver, Stamps, Furs,Musical Instruments - Scheduled', 'Coins, Silver, Stamps, Furs, Musical Instruments - Blanket', 'Fine Art - Blanket'
  --  , 'Misc. Valuable Items', 'Wine - Blanket', 'Wine - Scheduled', 'Bank Vaulted Jewelry', 'Collectibles - Blanket' , 'Collectibles'   , 'Fine Art' 
   -- , 'Wind Premium' --WY Only
    /*,'Reporting - Wind and Non Wind Surcharges'This is FL HO only*/))

  )    
  GROUP BY PT2.POLICY_NUMBER, PT2.POLICY_TRANSACTION_ID) CALC ON 
    (POL.POLICY_NUMBER = CALC.POLICY_NUMBER AND POL.POLICY_TRANSACTION_ID = CALC.POLICY_TRANSACTION_ID)
  LEFT OUTER JOIN PRIV_ST.DRAGON_POLICY DP ON (SUBSTR(POL.POLICY_NUMBER, 1, 9) = SUBSTR(DP.POLICY_NUMBER, 1, 9))
WHERE   1 = 1
  AND SUBSTR(POL.POLICY_NUMBER, 1, 2) = 'HS'
  --AND POL.servicing_broker_number not in (2052644019, 1130591819)
  --AND (ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM > 1 OR ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM < -1)    
  AND POL.TRX_DATE_PROCESSED >= sysdate - 365 --TO_DATE('01/01/2024', 'mm/dd/yyyy')
  AND POL.TRX_TYPE in ('Renewal', 'New Business', 'New Business Rewrite'/*, 'Endorsement'*/)
  AND pol.object_state_id not in (27502) --PolicyTransactionRolledback
  AND dp.policy_lines = 'Home Surplus Lines - California'
  AND (ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM > 5 OR ROLL.ACCOUNTING_TOTAL_ROLLUP - CALC.TOTAL_COVERAGE_SUM < -5 OR CALC.TOTAL_COVERAGE_SUM IS NULL)
  --AND SUBSTR(DP.POLICY_LINES, 1, 10) = 'Homeowners'
  AND POL.TRX_DATE_PROCESSED >= TO_DATE('03/03/2025', 'mm/dd/yyyy')
  AND POL.TRX_DATE_EFFECTIVE >= TO_DATE('05/01/2025', 'mm/dd/yyyy')
 -- AND POL.POLICY_NUMBER LIKE 'HO24065030%'
 --AND POL.POLICY_TRANSACTION_ID = 761077753659
    --AND DP.POLICY_LINES IS NULL
--ORDER BY trx_date_processed 
--  DP.POLICY_LINES, POL.POLICY_NUMBER, POL.POLICY_TRANSACTION_ID