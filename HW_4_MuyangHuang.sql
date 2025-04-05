/*---------- Big Data in Medicine (HBDS_5020) Module 2 Lab 4 - Muyang Huang (muh4003) ----------*/

-- =========================================================
-- Question 1 (5 points)
-- =========================================================

/*----------
1.1 How many patients had complete coverage of Part A and Part B in each year (2008, 2009, and 2010)? [Hint: Use the BENE_HI_CVRAGE_TOT_MONS (Part A coverage) and BENE_SMI_CVRAGE_TOT_MONS (Part B coverage) fields] (1 point)
----------*/

SELECT 
    YEAR,
    COUNT(DISTINCT DESYNPUF_ID) AS total_patients
FROM (
    SELECT '2008' AS YEAR, DESYNPUF_ID 
    FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
    WHERE BENE_HI_CVRAGE_TOT_MONS = 12 AND BENE_SMI_CVRAGE_TOT_MONS = 12
    UNION ALL
    SELECT '2009' AS YEAR, DESYNPUF_ID 
    FROM DE1_0_2009_Beneficiary_Summary_File_Sample_1
    WHERE BENE_HI_CVRAGE_TOT_MONS = 12 AND BENE_SMI_CVRAGE_TOT_MONS = 12
    UNION ALL
    SELECT '2010' AS YEAR, DESYNPUF_ID 
    FROM DE1_0_2010_Beneficiary_Summary_File_Sample_1
    WHERE BENE_HI_CVRAGE_TOT_MONS = 12 AND BENE_SMI_CVRAGE_TOT_MONS = 12
) AS combined
GROUP BY YEAR
ORDER BY YEAR;

/*
Output:
2008	97,112
2009	104,046
2010	97,319

Answer: There were 97,112, 104,046, and 97,319 patients had complete coverage of Part A and Part B in 2008, 2009, and 2010, respectively.
*/

/*----------
1.2 How many patients maintained complete coverage of Part A and Part B for all three years (2008–2010)? (1 point)
----------*/

DROP TABLE IF EXISTS temp_1_2;
CREATE TEMPORARY TABLE temp_1_2 AS
SELECT b2008.DESYNPUF_ID
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 b2008
INNER JOIN DE1_0_2009_Beneficiary_Summary_File_Sample_1 b2009
    ON b2008.DESYNPUF_ID = b2009.DESYNPUF_ID
INNER JOIN DE1_0_2010_Beneficiary_Summary_File_Sample_1 b2010
    ON b2008.DESYNPUF_ID = b2010.DESYNPUF_ID
WHERE
    b2008.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2008.BENE_SMI_CVRAGE_TOT_MONS = 12
    AND b2009.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2009.BENE_SMI_CVRAGE_TOT_MONS = 12
    AND b2010.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2010.BENE_SMI_CVRAGE_TOT_MONS = 12;

SELECT COUNT(DISTINCT DESYNPUF_ID) AS total_patients
FROM temp_1_2;

/*
Output:
86,821

Answer: There were 86,821 patients maintained a complete coverage of Part A and Part B for all three years (2008–2010).
*/

/*----------
1.3 Among those with complete coverage in all three years, how many patients were hospitalized in 2009 with a diagnosis of suicidal ideation (ICD-9 code V62.84)? [Hint: Use the ICD9_DGNS_CD_1 – ICD9_DGNS_CD_10 (Claim Diagnosis Code 1 – Claim Diagnosis Code 10 fields)] (1 point)
----------*/

SELECT COUNT(DISTINCT ip2009.DESYNPUF_ID) AS total_patients
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 b2008
INNER JOIN DE1_0_2009_Beneficiary_Summary_File_Sample_1 b2009 
    ON b2008.DESYNPUF_ID = b2009.DESYNPUF_ID
INNER JOIN DE1_0_2010_Beneficiary_Summary_File_Sample_1 b2010 
    ON b2008.DESYNPUF_ID = b2010.DESYNPUF_ID
INNER JOIN DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip2009
    ON b2008.DESYNPUF_ID = ip2009.DESYNPUF_ID
WHERE 
    -- Ensure full Part A & Part B coverage for all three years
    b2008.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2008.BENE_SMI_CVRAGE_TOT_MONS = 12
    AND b2009.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2009.BENE_SMI_CVRAGE_TOT_MONS = 12
    AND b2010.BENE_HI_CVRAGE_TOT_MONS = 12 AND b2010.BENE_SMI_CVRAGE_TOT_MONS = 12
    -- Ensure hospitalization occurred in 2009
    AND YEAR(STR_TO_DATE(ip2009.CLM_ADMSN_DT, '%Y%m%d')) = 2009
    -- Check for suicidal ideation (ICD-9 code V62.84) in any diagnosis field
    AND ('V6284' IN (ip2009.ICD9_DGNS_CD_1, ip2009.ICD9_DGNS_CD_2, ip2009.ICD9_DGNS_CD_3, 
                     ip2009.ICD9_DGNS_CD_4, ip2009.ICD9_DGNS_CD_5, ip2009.ICD9_DGNS_CD_6, 
                     ip2009.ICD9_DGNS_CD_7, ip2009.ICD9_DGNS_CD_8, ip2009.ICD9_DGNS_CD_9, 
                     ip2009.ICD9_DGNS_CD_10));

/*
Output:
161

Answer: There were 161 patients hospitalized in 2009 with a diagnosis of suicidal ideation among those with complete coverage in all three years (2008–2010).
*/

/*----------
1.4 Were there patients who had multiple hospitalizations with a diagnosis of suicidal ideation in 2009? If so, what are the demographic and clinical characteristics of those who had their first hospitalization in 2009? (2 points)

    ・Identify whether any patients had multiple hospitalizations for suicidal ideation in 2009.
    ・If multiple hospitalizations occurred, select the first hospitalization as the index event and summarize:
        ・Number of patients by sex
        ・Average age by sex
        ・Average length of stay by sex
    ・Provide a brief commentary on your findings, comparing sex differences in hospitalization rates, age, and LOS.
----------*/

DROP TABLE IF EXISTS temp_1_4;

CREATE TEMPORARY TABLE temp_1_4 AS
SELECT 
    ip.DESYNPUF_ID,
    STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d') AS admission_date,
    STR_TO_DATE(ip.NCH_BENE_DSCHRG_DT, '%Y%m%d') AS discharge_date
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
WHERE 
    YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
    AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                     ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                     ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                     ip.ICD9_DGNS_CD_10))
    AND ip.DESYNPUF_ID IN (SELECT DESYNPUF_ID FROM temp_1_2);

SELECT 
    CASE 
        WHEN b.BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN b.BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown' 
    END AS sex,
    COUNT(DISTINCT selected.DESYNPUF_ID) AS num_patients,
    ROUND(AVG(DATEDIFF(admission_date, STR_TO_DATE(b.BENE_BIRTH_DT, '%Y%m%d')) / 365), 3) AS avg_age,
    ROUND(AVG(LOS), 3) AS avg_length_of_stay
FROM (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY DESYNPUF_ID ORDER BY admission_date) AS ROW_NUM,
        DESYNPUF_ID,
        admission_date,
        ABS(DATEDIFF(admission_date, discharge_date)) AS LOS
    FROM temp_1_4
) AS selected
LEFT JOIN DE1_0_2009_Beneficiary_Summary_File_Sample_1 b
    ON selected.DESYNPUF_ID = b.DESYNPUF_ID   
WHERE ROW_NUM = 1
GROUP BY b.BENE_SEX_IDENT_CD;

/*
Output:
Male	55	71.040	10.164
Female	106	72.380	11.019

Answer: Yes, there were patients who had multiple hospitalizations with a diagnosis of suicidal ideation in 2009. The number of patients by sex was 55 for males and 106 for females. The average age by sex was 71.040 and 72.380 for males and females, respectively. The average length of stay (LOS) by sex is 10.164 days in males and 11.019 days in females. The analysis shows that more females were hospitalized for suicidal ideation in 2009 compared to males, which indicated a higher hospitalization rate among women. However, the average age of hospitalized females was slightly higher than that of males, which suggested potential differences in risk factors or healthcare-seeking behaviors between sexes. Additionally, the average LOS was longer for females compared to males, which may reflect differences in clinical severity, comorbidities, or recovery processes.
*/


-- =========================================================
-- Question 2 (3 points)

-- In this section, you will analyze outpatient visit patterns for patients who were hospitalized due to suicidal ideation in 2009.
-- =========================================================

/*----------
2.1. How many all-cause outpatient visits did this cohort of patients have one year before their index event? Summarize the average number and its standard deviation. (1 point)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        MIN(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) AS index_hosp_date
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID
),
Outpatient_Visits AS (
    -- Count all outpatient visits one year before index hospitalization
    SELECT 
        op.DESYNPUF_ID,
        COUNT(op.CLM_ID) AS num_visits
    FROM DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
    INNER JOIN Suicidal_Hospitalizations h
        ON op.DESYNPUF_ID = h.DESYNPUF_ID
    WHERE 
    	STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN DATE_SUB(h.index_hosp_date, INTERVAL 1 YEAR) 
        AND DATE_SUB(h.index_hosp_date, INTERVAL 1 DAY)
    GROUP BY op.DESYNPUF_ID
)
-- Calculate average and standard deviation
SELECT
	COUNT(*) AS num_patients,
    ROUND(AVG(num_visits), 3) AS avg_visits,
    ROUND(STDDEV(num_visits), 3) AS stddev_visits
FROM Outpatient_Visits;

/*
Output:
157	7.000	4.27

Answer: There were 157 all-cause outpatient visits this cohort of patients have one year before their index event. The average number and its standard deviation were 7.00 and 4.27, respectively.
*/

/*----------
2.2. How many mental health-related outpatient visits (ICD-9 codes 290–319) did this cohort of patients have one year before their index event? Summarize the average number and its standard deviation. (1 point)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        MIN(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) AS index_hosp_date
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID
),
Mental_Health_Visits AS (
    -- Count mental health outpatient visits one year before index hospitalization
    SELECT 
        op.DESYNPUF_ID,
        COUNT(op.CLM_ID) AS num_mental_health_visits
    FROM DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
    INNER JOIN Suicidal_Hospitalizations h
        ON op.DESYNPUF_ID = h.DESYNPUF_ID
    WHERE 
        STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN DATE_SUB(h.index_hosp_date, INTERVAL 1 YEAR) 
        AND DATE_SUB(h.index_hosp_date, INTERVAL 1 DAY)
        AND (
            -- Check if any diagnosis falls within ICD-9 range 290–319
            SUBSTRING(op.ICD9_DGNS_CD_1, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_2, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_3, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_4, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_5, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_6, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_7, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_8, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_9, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_10, 1, 3) BETWEEN '290' AND '319'
        )
    GROUP BY op.DESYNPUF_ID
)
-- Calculate average and standard deviation
SELECT 
	COUNT(*) AS num_patients,
    ROUND(AVG(num_mental_health_visits), 3) AS avg_mental_health_visits,
    ROUND(STDDEV(num_mental_health_visits), 3) AS stddev_mental_health_visits
FROM Mental_Health_Visits;

/*
Output:
78	1.821	1.196

Answer: There were 78 mental health-related outpatient visits (ICD-9 codes 290–319) this cohort of patients have one year before their index event. The average number and its standard deviation were 1.821 and 1.196, respectively.
*/

/*----------
2.3 Repeat 2.1 and 2.2 by sex. Comment on your findings. (1 point)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        MIN(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) AS index_hosp_date
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID
),
Outpatient_Visits AS (
    -- Count all outpatient visits one year before index hospitalization
    SELECT 
        op.DESYNPUF_ID,
        COUNT(op.CLM_ID) AS num_visits
    FROM DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
    INNER JOIN Suicidal_Hospitalizations h
        ON op.DESYNPUF_ID = h.DESYNPUF_ID
    WHERE 
        STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN DATE_SUB(h.index_hosp_date, INTERVAL 1 YEAR) 
        AND DATE_SUB(h.index_hosp_date, INTERVAL 1 DAY)
    GROUP BY op.DESYNPUF_ID
)
-- Calculate average and standard deviation by sex
SELECT 
    CASE 
        WHEN b.BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN b.BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown' 
    END AS sex,
    COUNT(o.DESYNPUF_ID) AS num_patients,
    ROUND(AVG(o.num_visits), 3) AS avg_outpatient_visits,
    ROUND(STDDEV(o.num_visits), 3) AS stddev_outpatient_visits
FROM Outpatient_Visits o
LEFT JOIN DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 b 
    ON o.DESYNPUF_ID = b.DESYNPUF_ID
GROUP BY b.BENE_SEX_IDENT_CD;

/*
Output 1:
Male	56	6.161	3.755
Female	101	7.465	4.462
*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        MIN(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) AS index_hosp_date
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID
),
Mental_Health_Visits AS (
    -- Count mental health outpatient visits one year before index hospitalization
    SELECT 
        op.DESYNPUF_ID,
        COUNT(op.CLM_ID) AS num_mental_health_visits
    FROM DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
    INNER JOIN Suicidal_Hospitalizations h
        ON op.DESYNPUF_ID = h.DESYNPUF_ID
    WHERE 
        STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN DATE_SUB(h.index_hosp_date, INTERVAL 1 YEAR) 
        AND DATE_SUB(h.index_hosp_date, INTERVAL 1 DAY)
        AND (
            -- Check if any diagnosis falls within ICD-9 range 290–319
            SUBSTRING(op.ICD9_DGNS_CD_1, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_2, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_3, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_4, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_5, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_6, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_7, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_8, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_9, 1, 3) BETWEEN '290' AND '319'
            OR SUBSTRING(op.ICD9_DGNS_CD_10, 1, 3) BETWEEN '290' AND '319'
        )
    GROUP BY op.DESYNPUF_ID
)
-- Calculate average and standard deviation
SELECT 
	CASE 
        WHEN b.BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN b.BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown' 
    END AS sex,
    COUNT(m.DESYNPUF_ID) AS num_patients,
    ROUND(AVG(m.num_mental_health_visits), 3) AS avg_mental_health_visits,
    ROUND(STDDEV(m.num_mental_health_visits), 3) AS stddev_mental_health_visits
FROM Mental_Health_Visits m
LEFT JOIN DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 b 
    ON m.DESYNPUF_ID = b.DESYNPUF_ID
GROUP BY b.BENE_SEX_IDENT_CD;

/*
Output 2:
Male	24	1.667	1.067
Female	54	1.889	1.242

Answer: The findings reveal notable sex differences in outpatient healthcare utilization among patients hospitalized for suicidal ideation in 2009. On average, females had more all-cause outpatient visits (7.47) compared to males (6.16) in the year preceding their hospitalization, which suggested that women may have had greater engagement with the healthcare system. Similarly for mental health-related outpatient visits, females averaged 1.889 visits compared to 1.667 for males, which indicated a slightly higher utilization of mental health services. The standard deviation values suggest that there is variability in outpatient visits within each sex group, with females showed slightly greater variability in both all-cause and mental health-related visits. These findings may point to differences in healthcare-seeking behavior, access to care, or underlying mental health conditions between men and women prior to hospitalization.
*/


-- =========================================================
-- Question 3 (2 points)

-- A key measure of inpatient quality of care is the 30-day readmission rate after discharge. In this section, you will analyze short-term healthcare utilization among patients hospitalized for suicidal ideation in 2009.
-- =========================================================

/*----------
3.1 How many patients in this cohort had a 30-day all-cause hospital readmission? (0.5 points)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        STR_TO_DATE(ip.NCH_BENE_DSCHRG_DT, '%Y%m%d') AS index_discharge_date,
        ip.CLM_ID
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
	GROUP BY ip.DESYNPUF_ID, index_discharge_date, ip.CLM_ID
),
Readmissions AS (
    -- Find hospitalizations within 30 days after index discharge
    SELECT DISTINCT h.DESYNPUF_ID
    FROM Suicidal_Hospitalizations h
    CROSS JOIN DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
        ON h.DESYNPUF_ID = ip.DESYNPUF_ID
    WHERE 
        (STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY))
        AND h.CLM_ID != ip.CLM_ID
)
-- Count number of patients with at least one 30-day readmission
SELECT COUNT(*) AS num_30_day_readmissions FROM Readmissions;

/*
Output:
17

Answer: There were 17 patients in this cohort had a 30-day all-cause hospital readmission.
*/

/*----------
3.2 How many patients in this cohort had any 30-day all-cause outpatient or inpatient revisit? (0.5 points)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        STR_TO_DATE(ip.NCH_BENE_DSCHRG_DT, '%Y%m%d') AS index_discharge_date,
        ip.CLM_ID
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID, index_discharge_date, ip.CLM_ID
),
Revisits AS (
    -- Identify inpatient or outpatient visits within 30 days after index discharge
    SELECT DISTINCT h.DESYNPUF_ID
    FROM Suicidal_Hospitalizations h

    -- Check for inpatient readmissions
    LEFT JOIN DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
        ON h.DESYNPUF_ID = ip.DESYNPUF_ID
        AND STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)
        AND h.CLM_ID != ip.CLM_ID

    -- Check for outpatient visits
    LEFT JOIN DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
        ON h.DESYNPUF_ID = op.DESYNPUF_ID
        AND STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)

    -- Ensure we count patients with at least one revisit (inpatient or outpatient)
    WHERE ip.DESYNPUF_ID IS NOT NULL OR op.DESYNPUF_ID IS NOT NULL
)
-- Count number of patients with at least one inpatient or outpatient revisit
SELECT COUNT(*) AS num_30_day_revisits FROM Revisits;

/*
Output:
70

Answer: There were 70 patients in this cohort had any 30-day all-cause outpatient or inpatient revisit.
*/

/*----------
3.3 How many patients in this cohort had any 30-day mental health-related outpatient or inpatient revisit? (0.5 points)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        STR_TO_DATE(ip.NCH_BENE_DSCHRG_DT, '%Y%m%d') AS index_discharge_date,
        ip.CLM_ID
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID, index_discharge_date, ip.CLM_ID
),
Mental_Health_Revisits AS (
    -- Identify inpatient or outpatient visits within 30 days after index discharge with mental health diagnosis
    SELECT DISTINCT h.DESYNPUF_ID
    FROM Suicidal_Hospitalizations h

    -- Check for inpatient readmissions with mental health ICD-9 codes (290–319)
    LEFT JOIN DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
        ON h.DESYNPUF_ID = ip.DESYNPUF_ID
        AND STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)
        AND (SUBSTRING(ip.ICD9_DGNS_CD_1, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_2, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_3, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_4, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_5, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_6, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_7, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_8, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_9, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(ip.ICD9_DGNS_CD_10, 1, 3) BETWEEN '290' AND '319')
        AND h.CLM_ID != ip.CLM_ID

    -- Check for outpatient visits with mental health ICD-9 codes (290–319)
    LEFT JOIN DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
        ON h.DESYNPUF_ID = op.DESYNPUF_ID
        AND STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)
        AND (SUBSTRING(op.ICD9_DGNS_CD_1, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_2, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_3, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_4, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_5, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_6, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_7, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_8, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_9, 1, 3) BETWEEN '290' AND '319'
             OR SUBSTRING(op.ICD9_DGNS_CD_10, 1, 3) BETWEEN '290' AND '319')

    -- Ensure we count patients with at least one mental health-related revisit
    WHERE ip.DESYNPUF_ID IS NOT NULL OR op.DESYNPUF_ID IS NOT NULL
)
-- Count number of patients with at least one mental health-related inpatient or outpatient revisit
SELECT COUNT(*) AS num_30_day_mental_health_revisits FROM Mental_Health_Revisits;

/*
Output:
14

Answer: There were 14 patients in this cohort had any 30-day mental health-related outpatient or inpatient revisit.
*/

/*----------
3.4 Summarize the sex of patients who had any 30-day all-cause outpatient or inpatient revisit. (0.5 points)
----------*/

WITH Suicidal_Hospitalizations AS (
    -- Identify first hospitalization for suicidal ideation in 2009
    SELECT 
        ip.DESYNPUF_ID,
        STR_TO_DATE(ip.NCH_BENE_DSCHRG_DT, '%Y%m%d') AS index_discharge_date,
        ip.CLM_ID
    FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
    WHERE 
        YEAR(STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d')) = 2009
        AND ('V6284' IN (ip.ICD9_DGNS_CD_1, ip.ICD9_DGNS_CD_2, ip.ICD9_DGNS_CD_3, 
                         ip.ICD9_DGNS_CD_4, ip.ICD9_DGNS_CD_5, ip.ICD9_DGNS_CD_6, 
                         ip.ICD9_DGNS_CD_7, ip.ICD9_DGNS_CD_8, ip.ICD9_DGNS_CD_9, 
                         ip.ICD9_DGNS_CD_10))
    GROUP BY ip.DESYNPUF_ID, index_discharge_date, ip.CLM_ID
),
Revisits AS (
    -- Identify inpatient or outpatient visits within 30 days after index discharge
    SELECT DISTINCT h.DESYNPUF_ID
    FROM Suicidal_Hospitalizations h

    -- Check for inpatient readmissions
    LEFT JOIN DE1_0_2008_to_2010_Inpatient_Claims_Sample_1 ip
        ON h.DESYNPUF_ID = ip.DESYNPUF_ID
        AND STR_TO_DATE(ip.CLM_ADMSN_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)
        AND h.CLM_ID != ip.CLM_ID

    -- Check for outpatient visits
    LEFT JOIN DE1_0_2008_to_2010_Outpatient_Claims_Sample_1 op
        ON h.DESYNPUF_ID = op.DESYNPUF_ID
        AND STR_TO_DATE(op.CLM_FROM_DT, '%Y%m%d') 
        BETWEEN h.index_discharge_date AND DATE_ADD(h.index_discharge_date, INTERVAL 30 DAY)

    -- Ensure we count patients with at least one revisit (inpatient or outpatient)
    WHERE ip.DESYNPUF_ID IS NOT NULL OR op.DESYNPUF_ID IS NOT NULL
)
-- Count number of patients with at least one mental health-related inpatient or outpatient revisit
SELECT
	CASE 
        WHEN b.BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN b.BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown' 
    END AS sex,
	COUNT(*) AS num_30_day_revisits
FROM Revisits r
LEFT JOIN DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 b 
    ON r.DESYNPUF_ID = b.DESYNPUF_ID
GROUP BY b.BENE_SEX_IDENT_CD;

/*
Output:
Male	22
Female	48

Answer: There were 22 and 48 patients in this cohort who had any 30-day all-cause outpatient or inpatient revisit for males and females, respectively.
*/
