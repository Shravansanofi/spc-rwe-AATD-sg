---====================---
---Feasibility Analysis
---====================---

---===============================================---
---Table 1: AATD-related Emphysema Patients Cohort
---===============================================---


---===================================================================---
---1.1 Patients observable in the database on or after January 1, 2016
---===================================================================---

SELECT * FROM PRJ_XPLR_MKTSCAN_STD_A_STG.MARKETSCAN_STD_A_MED_AND_RX_CONTINUOUS_ENROLLMENT_30D_GAP_FOR_REQUESTS_202503
LIMIT 10
;


---Descriotion : Here we are looking into the data table below
---"PRJ_XPLR_MKTSCAN_STD_A_STG.MARKETSCAN_STD_A_MED_AND_RX_CONTINUOUS_ENROLLMENT_30D_GAP_FOR_REQUESTS_202503" and listing the distinct patients
---who have enrolled in the insurance after '2016-01-01'

CREATE OR REPLACE TABLE PRJ_XPLR_MKTSCAN_STD_A_STG.AATD_EMP_PATS_OBSRV_SG_1 AS
SELECT DISTINCT ENROLID 
FROM PRJ_XPLR_MKTSCAN_STD_A_STG.MARKETSCAN_STD_A_MED_AND_RX_CONTINUOUS_ENROLLMENT_30D_GAP_FOR_REQUESTS_202503
WHERE CONT_ENR_START_DT >= '2016-01-01';

SELECT COUNT(DISTINCT ENROLID) AS PATS
FROM PRJ_XPLR_MKTSCAN_STD_A_STG.AATD_EMP_PATS_OBSRV_SG_1;

--PATS
--95443760


---===================================================================================================---
---1.2 Patients with ≥1 inpatient claim OR ≥2 outpatient claims (≥30 days apart and ≤365 days between) 
---with a diagnosis of AATD (ICD-10-CM: E88.01)
---===================================================================================================---

SELECT * FROM PRJ_XPLR_MKTSCAN_STD_A_STG.marketscan_std_a_diagnosis_events_all_insurances_pos_for_requests_202503 LIMIT 10;

SELECT DISTINCT POS_CATEGORY FROM PRJ_XPLR_MKTSCAN_STD_A_STG.marketscan_std_a_diagnosis_events_all_insurances_pos_for_requests_202503 LIMIT 10;


CREATE OR REPLACE TABLE PRJ_XPLR_MKTSCAN_STD_A_STG.AATD_EMP_PATS_IP_OP_CLAIMS_SG_1 AS
WITH BASE_PATIENTS AS (
    SELECT DISTINCT ENROLID
    FROM PRJ_XPLR_MKTSCAN_STD_A_STG.AATD_EMP_PATS_OBSRV_SG_1
),

AATD_CLAIMS AS (
    SELECT ENROLID, DX_DT, POS_CATEGORY
    FROM PRJ_XPLR_MKTSCAN_STD_A_STG.MARKETSCAN_STD_A_DIAGNOSIS_EVENTS_ALL_INSURANCES_POS_FOR_REQUESTS_202503
    WHERE DX LIKE 'E8801%'
      AND ENROLID IN (SELECT ENROLID FROM BASE_PATIENTS)
),

-- PATIENTS WITH >=1 INPATIENT CLAIM
INPATIENT AS (
    SELECT ENROLID, DX_DT
    FROM AATD_CLAIMS
    WHERE POS_CATEGORY IN ('ip')
),

-- PATIENTS WITH >=2 OUTPATIENT CLAIMS (>=30 DAYS APART AND <=365 DAYS BETWEEN)
OUTPATIENT_PAIRS AS (
    SELECT DISTINCT A.ENROLID, A.DX_DT
    FROM AATD_CLAIMS A
    JOIN AATD_CLAIMS B
      ON A.ENROLID = B.ENROLID
     AND A.POS_CATEGORY IN ('op', 'er', 'ltc', 'other')
     AND B.POS_CATEGORY IN ('op', 'er', 'ltc', 'other')
     AND B.DX_DT > A.DX_DT
     AND DATEDIFF(DAY, A.DX_DT, B.DX_DT) BETWEEN 30 AND 365
),
FINAL1 AS(
-- Combine both criteria
SELECT DISTINCT ENROLID, DX_DT
FROM INPATIENT
UNION ALL
SELECT DISTINCT ENROLID, DX_DT
FROM OUTPATIENT_PAIRS
)
SELECT ENROLID, MIN (DX_DT) AS AATD_IDX_DT
FROM FINAL1
GROUP BY ENROLID
;




SELECT COUNT(*) AS COUNT, COUNT(DISTINCT ENROLID) AS PATS
FROM PRJ_XPLR_MKTSCAN_STD_A_STG.AATD_EMP_PATS_IP_OP_CLAIMS_SG_1;

--COUNT	PATS
--9799	9799


