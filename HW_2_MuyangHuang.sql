/*---------- Big Data in Medicine (HBDS_5020) Module 2 Lab 2 - Muyang Huang ----------*/


/*--------------------
Question 1 (1 point)

1.1 Summarize the total number of rows, total number of inpatient claims, and unique number of inpatient claims. (0.5 points)
1.2 Calculate the average number of inpatient claims per person by year of admission; order the table by year of admission (ascending order). (0.5 points)
--------------------*/

-- 1.1 Summarize the total number of rows, total number of inpatient claims, and unique number of inpatient claims. (0.5 points)

SELECT
	COUNT(*) AS total_rows,
	COUNT(CLM_ID) AS total_inpatient_claims,
	COUNT(DISTINCT CLM_ID) AS unique_beneficiaries
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1;

/*----------
Output:
66773	66773	66705

Answer: The total number of rows, total number of inpatient claims, and unique number of inpatient claims were 66,773, 66,773 and 66,705, respectively.
----------*/

-- 1.2 Calculate the average number of inpatient claims per person by year of admission; order the table by year of admission (ascending order). (0.5 points)

SELECT 
    YEAR(CLM_ADMSN_DT) AS admission_year,
    ROUND(COUNT(CLM_ID) / COUNT(DISTINCT DESYNPUF_ID), 3) AS avg_claims_per_person
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
GROUP BY admission_year
ORDER BY admission_year ASC;

/*----------
Output:
2007	1.046
2008	1.746
2009	1.341
2010	1.159

Answer: The average number of inpatient claims per person by year of admission is 1.046, 1.746, 1.341, and 1.159 for the year 2007, 2008, 2009, and 2010, respectively.
----------*/


/*--------------------
Question 2 (1 point)

The table contains a variable called “CLM_UTLZTN_DAY_CNT,” which, in the codebook, is defined as “claim utilization day count.” There are four date-related variables in the data set, “CLM_FROM_DT,” “CLM_THRU_DT,” “CLM_ADMSN_DT,” and “NCH_BENE_DSCHRG_DT.” Check if “CLM_UTLZTN_DAY_CNT” is derived from:

2.1 The difference (in days) between “CLM_FROM_DT” and “CLM_THRU_DT” (0.5 points)
2.2 The difference (in days) between “CLM_ADMSN_DT” and “NCH_BENE_DSCHRG_DT” (0.5 points)

You can check the above two statements by calculating the number of rows in the table with “CLM_UTLZTN_DAY_CNT” different from the difference defined in 2.1 or 2.2.
--------------------*/

-- 2.1 The difference (in days) between “CLM_FROM_DT” and “CLM_THRU_DT” (0.5 points)

SELECT COUNT(*) AS mismatch_count_1
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
WHERE CLM_UTLZTN_DAY_CNT <> DATEDIFF(CLM_THRU_DT, CLM_FROM_DT);

/*----------
Output:
3546

Answer: The difference (in days) between “CLM_FROM_DT” and “CLM_THRU_DT” is 3,546.
----------*/

-- 2.2 The difference (in days) between “CLM_ADMSN_DT” and “NCH_BENE_DSCHRG_DT” (0.5 points)

SELECT COUNT(*) AS mismatch_count_2
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
WHERE CLM_UTLZTN_DAY_CNT <> DATEDIFF(NCH_BENE_DSCHRG_DT, CLM_ADMSN_DT);

/*----------
Output:
3664

Answer: The difference (in days) between “CLM_ADMSN_DT” and “NCH_BENE_DSCHRG_DT” is 3,664. Since neither is 0, “CLM_UTLZTN_DAY_CNT” might not be calculated the way we expected.
----------*/


/*--------------------
Question 3 (1.5 points)

The hospital length of stay (LOS) is an important indicator of the efficiency of hospital management. LOS is defined as the number of days between admission date and discharge date.

3.1 Summarize the average total LOS by year of admission; order the table by year of admission (ascending order). (1 point) [Hint: First calculate the total LOS for each patient. (0.5 points)]
3.2 Comment on your results. (0.5 points)
--------------------*/

SELECT 
    admission_year,
    ROUND(AVG(LOS_each), 3) AS avg_LOS
FROM (
	SELECT 
		YEAR(CLM_ADMSN_DT) AS admission_year,
		SUM(DATEDIFF(NCH_BENE_DSCHRG_DT, CLM_ADMSN_DT)) AS LOS_each,
		DESYNPUF_ID
	FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
	WHERE CLM_ADMSN_DT IS NOT NULL AND NCH_BENE_DSCHRG_DT IS NOT NULL
	GROUP BY admission_year, DESYNPUF_ID
	) AS subquery
GROUP BY admission_year
ORDER BY admission_year ASC;

/*----------
Output:
2007	11.870
2008	10.043
2009	7.713
2010	6.356

Answer: The data shows a decline in the average LOS from 11.870 days in 2007 to about 10.043 in 2008, then a significant sharp decline to about 7.713 days in 2009, with a slight further decrease to 6.356 days in 2010. This significant drop suggests potential changes in hospital efficiency, medical advancements, or healthcare policies promoting shorter stays.
----------*/


/*--------------------
Question 4 (2 points)

Last time, we looked at patients who had chronic condition depression in the 2008 beneficiary summary table. Among those who had depression as a chronic condition in 2008:

4.1 Create a temporary table of beneficiaries with a chronic condition of depression in 2008. How many rows are there in this temporary table? (0.5 points)
4.2 How many unique patients had a depression-related hospitalization in 2008? (0.5 points)
4.3 Summarize the number of unique patients with a depression-related hospitalization by year of admission; order the table by year of admission (ascending order). (1 point)

A depression-related claim can be defined as having a depression-related admitting diagnosis or claim diagnosis. The CMS Chronic Condition Warehouse (CCW) uses the following ICD-9 codes to define depression: “29620”, “29621”, “29622”, “29623”, “29624”, “29625”, “29626”, “29630”, “29631”, “29632”, “29633”, “29634”, “29635”, “29636”, “29651”, “29652”, “29653”, “29654”, “29655”, “29656”, “29660”, “29661”, “29662”, “29663”, “29664”, “29665”, “29666”, “29689”, “2980”, “3004”, “3091”, “311”
--------------------*/

-- 4.1 Create a temporary table of beneficiaries diagnosed with a chronic condition of depression in 2008. How many rows are there in this temporary table? (0.5 points)

CREATE TEMPORARY TABLE temp_depression_beneficiaries AS
SELECT *
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
WHERE YEAR(CLM_ADMSN_DT) = 2008
AND (
	ADMTNG_ICD9_DGNS_CD IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
							'29630', '29631', '29632', '29633', '29634', '29635', '29636',
							'29651', '29652', '29653', '29654', '29655', '29656', '29660',
							'29661', '29662', '29663', '29664', '29665', '29666', '29689',
							'2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_1 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_2 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_3 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_4 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_5 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_6 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_7 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_8 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_9 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_10 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
);

SELECT COUNT(*) AS num_rows
FROM temp_depression_beneficiaries;

/*----------
Output:
2578

Answer: There are 2,578 rows in this temporary table.
----------*/

-- 4.2 How many unique patients had a depression-related hospitalization in 2008? (0.5 points)

SELECT COUNT(DISTINCT DESYNPUF_ID) AS num_rows
FROM temp_depression_beneficiaries;

/*----------
Output:
2390

Answer: 2,390 unique patients had a depression-related hospitalization in 2008.
----------*/

-- 4.3 Summarize the number of unique patients with a depression-related hospitalization by year of admission; order the table by year of admission (ascending order). (1 point)

SELECT YEAR(CLM_ADMSN_DT) AS admission_year, 
       COUNT(DISTINCT DESYNPUF_ID) AS unique_patients
FROM DE1_0_2008_to_2010_Inpatient_Claims_Sample_1
WHERE ADMTNG_ICD9_DGNS_CD IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
							  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
							  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
							  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
							  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_1 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_2 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_3 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_4 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_5 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_6 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_7 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_8 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_9 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
    OR ICD9_DGNS_CD_10 IN ('29620', '29621', '29622', '29623', '29624', '29625', '29626',
						  '29630', '29631', '29632', '29633', '29634', '29635', '29636',
					   	  '29651', '29652', '29653', '29654', '29655', '29656', '29660',
						  '29661', '29662', '29663', '29664', '29665', '29666', '29689',
						  '2980', '3004', '3091', '311')
GROUP BY admission_year
ORDER BY admission_year ASC;

/*----------
Output:
2007	26
2008	2390
2009	2288
2010	1236

Answer: The number of unique patients with a depression-related hospitalization by year of admission is 26, 2,390, 2,288, and 1,236 for the year 2007, 2008, 2009, and 2010, respectively.
----------*/


/*--------------------
Question 5 (4.5 points)

Again, among those who had depression as a chronic condition in 2008:

5.1 Summarize the average total claim payment amount by beneficiaries’ race. (1 point) [Hint: first calculate the total claim payment amount for depression-related hospitalization for each patient. (0.5 points)] Make sure to rename the racial groups by the actual names of the racial categories. (0.5 points)
5.2 Comment on your findings. Note that when referring to race groups, use the names of the race groups, instead of their coded values. (0.5 points)
5.3 Repeat 5.1-5.2 for total LOS. (1.5 points + 0.5 points)
5.4 Compare the distributions of claim payment amount and of LOS you obtained in 5.1 and 5.3, and come up with a research hypothesis. (0.5 points)
--------------------*/

-- 5.1 Summarize the average total claim payment amount by beneficiaries’ race. (1 point) [Hint: first calculate the total claim payment amount for depression-related hospitalization for each patient. (0.5 points)] Make sure to rename the racial groups by the actual names of the racial categories. (0.5 points)

SELECT 
    CASE 
        WHEN BENE_RACE_CD = 1 THEN 'White'
        WHEN BENE_RACE_CD = 2 THEN 'Black'
        WHEN BENE_RACE_CD = 3 THEN 'Other'
        WHEN BENE_RACE_CD = 5 THEN 'Hispanic'
        ELSE 'Unknown' 
    END AS Race,
    ROUND(AVG(Total_Claim_Payment), 3) AS Avg_Claim_Payment
FROM (
    -- Calculate total claim payment for each beneficiary with depression
    SELECT DISTINCT C.DESYNPUF_ID, SUM(C.CLM_PMT_AMT) AS Total_Claim_Payment
    FROM temp_depression_beneficiaries C
    GROUP BY C.DESYNPUF_ID
) Total_Payments
LEFT JOIN DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 B ON Total_Payments.DESYNPUF_ID = B.DESYNPUF_ID
GROUP BY Race
ORDER BY Avg_Claim_Payment DESC;

/*----------
Output:
Black		8231.536
White		8107.964
Hispanic	7901.961
Other		6838.235

Answer: The average total claim payment amount by beneficiaries’ race is 8,231.536, 8,107.964, 7,901.961, and 6,838.235 for Black, White, Hispanic, and other race, respectively.
----------*/

-- 5.2 Comment on your findings. (0.5 points)

/*----------
Answer: The results indicate that Black beneficiaries had the highest average total claim payment for depression-related hospitalizations in 2008, followed by White beneficiaries, Hispanic beneficiaries, and those categorized as Other. This suggests potential disparities in healthcare costs, which could be influenced by differences in hospital resource utilization, severity of illness at admission, access to preventive care, or variations in treatment patterns across racial groups.
----------*/

-- 5.3 Repeat 5.1-5.2 for total LOS. (1.5 points + 0.5 points)

SELECT 
    CASE 
        WHEN BENE_RACE_CD = 1 THEN 'White'
        WHEN BENE_RACE_CD = 2 THEN 'Black'
        WHEN BENE_RACE_CD = 3 THEN 'Other'
        WHEN BENE_RACE_CD = 5 THEN 'Hispanic'
        ELSE 'Unknown' 
    END AS Race,
    ROUND(AVG(Total_length_of_stay), 3) AS Avg_length_of_stay
FROM (
    -- Calculate total LOS for each beneficiary with depression
    SELECT DISTINCT C.DESYNPUF_ID, SUM(DATEDIFF(C.NCH_BENE_DSCHRG_DT, C.CLM_ADMSN_DT)) AS Total_length_of_stay
    FROM temp_depression_beneficiaries C
    GROUP BY C.DESYNPUF_ID
) Total_LOS
LEFT JOIN DE1_0_2008_Beneficiary_Summary_File_Sample_1_1 B ON Total_LOS.DESYNPUF_ID = B.DESYNPUF_ID
GROUP BY Race
ORDER BY Avg_length_of_stay DESC;

/*----------
Output:
Black		7.431
Other		6.838
White		6.364
Hispanic	6.235

Answer: The results show that Black beneficiaries had the longest average LOS for depression-related hospitalizations in 2008, followed by those in the Other category, White beneficiaries, and Hispanic beneficiaries with the shortest stays. These differences may reflect variations in disease severity at admission, access to outpatient mental health care, social determinants of health, or hospital discharge practices.
----------*/

-- 5.4 Compare the distributions of claim payment amount and of LOS you obtained in 5.1 and 5.3, and come up with a research hypothesis. (0.5 points)

/*----------
Answer: The distributions of claim payment amount and of LOS show a similar pattern, with Black beneficiaries having both the highest average total payment and the longest LOS, while Other beneficiaries had the lowest values in average total payment but had the second longest LOS. However, the overall differences in payments are larger compared to the differences in LOS, which suggested potential variations in cost per day of hospitalization across racial groups.

Research Hypothesis: The Black beneficiaries are more likely to suffer from depression than other beneficiary groups. Racial differences in total claim payments for depression-related hospitalizations are influenced by variations in both hospital LOS and the cost of care per day, which potentially reflected differences in treatment intensity, resource utilization, or healthcare access.
----------*/
