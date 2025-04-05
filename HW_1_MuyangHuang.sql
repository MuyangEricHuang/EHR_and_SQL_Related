/*---------- Big Data in Medicine (HBDS_5020) Module 2 Lab 1 - Muyang Huang ----------*/


/*--------------------
1. Summarize the total number of rows, unique number of beneficiaries, unique number of 
states, and unique number of counties in the file. (1 point)
--------------------*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT DESYNPUF_ID) AS unique_beneficiaries,
    COUNT(DISTINCT SP_STATE_CODE) AS unique_states,
    COUNT(DISTINCT BENE_COUNTY_CD ) AS unique_counties
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1;

/*----------
Output:
116352	116352	52	307

Answer: The total number of rows, unique number of beneficiaries, unique number of state
s, and unique number of counties in the file were 116,352, 116,352, 52, and 307, respectively.
----------*/


/*--------------------
2. Medicare is for people 65 or older or with a disability/End-Stage Renal Disease/ALS. 
Let’s explore the age of the beneficiaries on the last day of year 2008.
    ・2.1 Summarize the minimum, maximum, and average age of all the beneficiaries. (1 point)
    ・2.2 How many beneficiaries were under 65 years? (0.5 points)
    ・2.3 How many beneficiaries died in 2008? (0.5 points)
--------------------*/

-- 2.1 Summarize the minimum, maximum, and average age of all the beneficiaries.

SELECT 
    MIN(TIMESTAMPDIFF(YEAR, STR_TO_DATE(BENE_BIRTH_DT, '%Y%m%d'), '2008-12-31')) AS min_age,
    MAX(TIMESTAMPDIFF(YEAR, STR_TO_DATE(BENE_BIRTH_DT, '%Y%m%d'), '2008-12-31')) AS max_age,
    AVG(TIMESTAMPDIFF(YEAR, STR_TO_DATE(BENE_BIRTH_DT, '%Y%m%d'), '2008-12-31')) AS avg_age
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1;

/*----------
Output:
25	99	71.6472

Answer: The minimum, maximum, and average age of all the beneficiaries were 25, 99, and 
71.6472, respectively.
----------*/

-- 2.2 How many beneficiaries were under 65 years on December 31, 2008?

SELECT COUNT(*) AS beneficiaries_under_65
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
WHERE TIMESTAMPDIFF(YEAR, STR_TO_DATE(BENE_BIRTH_DT, '%Y%m%d'), '2008-12-31') < 65;

/*----------
Output:
19120

Anwer: There were 19,120 beneficiaries under 65 years on December 31, 2008.
----------*/

-- 2.3 How many beneficiaries died in 2008?

SELECT COUNT(*) AS deceased_in_2008
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
WHERE BENE_DEATH_DT IS NOT NULL AND STR_TO_DATE(BENE_DEATH_DT, '%Y%m%d') BETWEEN '2008-01-01' AND '2008-12-31';

/*----------
Output:
1814

Anwer: There were 1,814 beneficiaries died in 2008.
----------*/


/*--------------------
3. Summarize the number of and the percentage of beneficiaries who had depression by sex. (0.5 points)
    ・Create a table with three columns: sex, count, percent (0.5 points)
    ・Format the percentage as “xx.xx%” (0.5 points)
--------------------*/

SELECT 
    CASE 
        WHEN BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown'
    END AS sex,
    SUM(CASE WHEN SP_DEPRESSN = 1 THEN 1 ELSE 0 END) AS count,
    CONCAT(ROUND(SUM(CASE WHEN SP_DEPRESSN = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%') AS percent
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
GROUP BY BENE_SEX_IDENT_CD;

/*---------- Alternatively:
SELECT 
    CASE 
        WHEN BENE_SEX_IDENT_CD = 1 THEN 'Male'
        WHEN BENE_SEX_IDENT_CD = 2 THEN 'Female'
        ELSE 'Unknown'
    END AS sex,
    COUNT(*) AS count,
    CONCAT(ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*)
                                      FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1)), 2), '%') AS percent
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
WHERE SP_DEPRESSN = '1'
GROUP BY BENE_SEX_IDENT_CD;
----------*/

/*----------
Output:
Male	10272	19.75%
Female	14568	22.64%

Anwer: The number of and the percentage of beneficiaries who had depression by sex were 
10,272 (19.75%) for male and 14,568 (22.64%) for female in general respectively.
----------*/


/*--------------------
4. Summarize the average number of chronic conditions by whether or not the beneficiary 
was less than 65 (< 65) on the last day of 2008. (0.5 points)
    ・Create an indicator “age_less_than_65” for all beneficiaries; age_less_than_65 = 1
     if age < 65 and age_less_than_65 = 0 if age >= 65 (0.5 points)
    ・Create a table with two columns: age_less_than_65, avg_n_chronic_conditions (0.5 points)
    ・Order the table by age_less_than_65 (in descending order) (0.5 points)
    ・Comment on your results (0.5 points)
--------------------*/

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(BENE_BIRTH_DT, '%Y%m%d'), '2008-12-31') < 65 THEN 1
        ELSE 0
    END AS age_less_than_65,
    AVG(((CASE WHEN SP_ALZHDMTA = 1 THEN 1 ELSE 0 END) + 
    	 (CASE WHEN SP_CHF = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_CHRNKIDN = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_CNCR = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_COPD = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_DEPRESSN = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_DIABETES = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_ISCHMCHT = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_OSTEOPRS = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_RA_OA = 1 THEN 1 ELSE 0 END) + 
         (CASE WHEN SP_STRKETIA = 1 THEN 1 ELSE 0 END))) AS avg_n_chronic_conditions
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
GROUP BY age_less_than_65
ORDER BY age_less_than_65 DESC;

/*----------
Output:
1	2.2214
0	2.2225

Anwer: The results showed that beneficiaries under 65 and those 65 or older have nearly 
the same average number of chronic conditions (approximately 2.22). This challenged my 
expectation that older individuals would have significantly more chronic conditions.The
likely explanation was that Medicare covers people under 65 only if they have severe
health conditions such as disabilities, End-Stage Renal Disease (ESRD) or ALS. As a 
result, the beneficiaries under 65 in this dataset were likely already managing multiple
chronic illnesses, leading to an average count similar to that of older beneficiaries. 
This suggests that age alone is not the primary driver of chronic condition prevalence 
within the Medicare population.
----------*/


/*--------------------
5. Summarize the average total spending by the number of chronic conditions. (0.5 points)
    ・Total spending is defined as the total inpatient, outpatient, and carrier amount
    paid by medicare, beneficiary, and primary payer (0.5 points)
    ・Create a table with two columns: n_chronic_conditions, avg_spending (0.5 points)
    ・Order the table by the number of chronic conditions (in ascending order) (0.5 points)
    ・Round the average spending to two decimal places (0.5 points)
    ・Comment on your results (0.5 points)
--------------------*/

SELECT ((CASE WHEN SP_ALZHDMTA = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_CHF = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_CHRNKIDN = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_CNCR = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_COPD = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_DEPRESSN = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_DIABETES = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_ISCHMCHT = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_OSTEOPRS = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_RA_OA = 1 THEN 1 ELSE 0 END) + 
        (CASE WHEN SP_STRKETIA = 1 THEN 1 ELSE 0 END)) AS n_chronic_conditions,
    ROUND(AVG(MEDREIMB_IP + BENRES_IP + PPPYMT_IP + MEDREIMB_OP + BENRES_OP + PPPYMT_OP +
              MEDREIMB_CAR + BENRES_CAR + PPPYMT_CAR), 2) AS avg_spending
FROM DE1_0_2008_Beneficiary_Summary_File_Sample_1_1
GROUP BY n_chronic_conditions
ORDER BY n_chronic_conditions ASC;

/*----------
Output:
0	273.15
1	1819.52
2	2909.39
3	4227.79
4	6482.8
5	9670.58
6	14544.12
7	20118.34
8	27010.23
9	33974.69
10	41860.03
11	50521.3

Anwer: The results show a clear positive correlation between the number of chronic
conditions and average total spending. Beneficiaries with no chronic conditions have
minimal healthcare costs ($273.15 on average), whereas those with the maximum number of 
chronic conditions (11) incur significantly higher expenses ($50,521.30). This steep 
increase suggests that as chronic conditions accumulate, beneficiaries require more 
frequent and intensive medical interventions, which led to higher inpatient, outpatient,
and carrier costs. The pattern highlights the financial burden of managing multiple
chronic illnesses and underscores the importance of preventive care and chronic disease 
management to potentially reduce healthcare costs within the Medicare system.
----------*/
