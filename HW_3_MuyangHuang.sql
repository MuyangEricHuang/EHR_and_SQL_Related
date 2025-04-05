/*---------- Big Data in Medicine (HBDS_5020) Module 2 Lab 3 - Muyang Huang (muh4003) ----------*/


/*--------------------
Question 1 (1 point)

Summarize the names of the top 10 drug ingredients patients were exposed to. Present the results in the order of decreasing frequency.
--------------------*/

SELECT 
    c.concept_name AS drug_ingredient, 
    COUNT(d.drug_concept_id) AS exposure_count
FROM drug_era_1m d
INNER JOIN concept c ON d.drug_concept_id = c.concept_id
WHERE c.domain_id = 'Drug'
GROUP BY c.concept_name
ORDER BY exposure_count DESC
LIMIT 10;

/*----------
Output:
Acetaminophen		24,713
Hydrochlorothiazide	22,791
levothyroxine		17,572
Simvastatin			15,861
Lisinopril			13,764
Lovastatin			13,033
Oxygen				12,575
Propranolol			11,904
Metformin			11,722
Hydrocodone			10,505

Answer: The names of the top 10 drug ingredients patients were exposed to were Acetaminophen (24,713), Hydrochlorothiazide (22,791), levothyroxine (17,572), Simvastatin (15,861), Lisinopril (13,764), Lovastatin (13,033), Oxygen (12,575), Propranolol (11,904), Metformin (11,722), and Hydrocodone (10,505).
----------*/


/*--------------------
Question 2 (3 points)

2.1 How many unique patients were exposed to any of the top 10 drug ingredients identified in Question 1?
2.2 Summarize the number of patients by race. Comment on your result.
2.3 Summarize the number of patients by gender. Comment on your result.

Make sure you use the actual race and gender categories (not concept IDs) in your results.
--------------------*/

-- 2.1 How many unique patients were exposed to any of the top 10 drug ingredients identified in Question 1?

DROP TABLE IF EXISTS temp_2_1;

CREATE TEMPORARY TABLE temp_2_1 AS
SELECT *
FROM drug_era_1m d
INNER JOIN concept c ON d.drug_concept_id = c.concept_id
LEFT JOIN person p ON d.person_id = p.person_id_2
WHERE c.concept_name IN (
	'Acetaminophen', 'Hydrochlorothiazide', 'levothyroxine', 'Simvastatin',
	'Lisinopril', 'Lovastatin', 'Oxygen', 'Propranolol', 'Metformin', 'Hydrocodone'
);

SELECT COUNT(DISTINCT person_id) AS unique_patients
FROM temp_2_1;

/*----------
Output:
144,467

Answer: The number of unique patients that were exposed to any of the top 10 drug ingredients identified in Question 1 is 144,467.
----------*/

-- 2.2 Summarize the number of patients by race. Comment on your result.

CREATE TEMPORARY TABLE race_gender AS
SELECT 
    concept_id, 
    concept_name
FROM concept
WHERE domain_id IN ('Race', 'Gender');

SELECT 
    rg.concept_name AS race, 
    COUNT(DISTINCT t.person_id) AS patient_count
FROM temp_2_1 t
LEFT JOIN race_gender rg ON t.race_concept_id = rg.concept_id
GROUP BY rg.concept_name
ORDER BY patient_count DESC;

/*----------
Output:
White						117,775
Black or African American	15,913
NULL						10,779

Answer: The results indicate a significant disparity in drug exposure among racial groups, with White patients making up the vast majority (117,775) compared to Black or African American patients (15,913) and 10,779 as unknown. This difference may be influenced by various factors, including healthcare access, prescription practices, socioeconomic status, demographic distribution, and disease prevalence among different racial groups in the dataset.
----------*/

-- 2.3 Summarize the number of patients by gender. Comment on your result.

SELECT 
    rg.concept_name AS race, 
    COUNT(DISTINCT t.person_id) AS patient_count
FROM temp_2_1 t
LEFT JOIN race_gender rg ON t.gender_concept_id = rg.concept_id
GROUP BY rg.concept_name
ORDER BY patient_count DESC;

/*----------
Output:
FEMALE	88,139
MALE	56,328

Answer: The results show that more female patients (88,139) were exposed to the top 10 drug ingredients compared to male patients (56,328). This discrepancy may reflect gender differences in healthcare utilization, prescription trends, or underlying health conditions that require medication (disease prevalence). Women are generally more likely to adhere to prescribed treatments or have higher healthcare-seeking behavior, which could contribute to the higher numbers observed in the dataset.
----------*/


/*--------------------
Question 3 (6 points)

For Question 3, we focus on patients who were exposed to any of the top 10 drug ingredients identified in Question 1.

3.1 Summarize the names of the top 15 drug ingredients these patients were exposed to.
3.2 Repeat Question 1 for top 15 drug ingredients, and compare the two tables you get. Comment on your findings. Why were the two tables the same or different?
3.3 On average, how many drug ingredients were each patient exposed to?
3.4 Summarize the average by gender. Make sure you use the actual gender categories (not concept IDs) in your results.
3.5 Comment on your result and come up with a research hypothesis.
3.6 Test your hypothesis. What is your conclusion? You can assume the number of drug ingredients follows a normal distribution. If you use another software to test your hypothesis, make sure you copy and paste both your code and results.
--------------------*/

-- 3.1 Summarize the names of the top 15 drug ingredients these patients were exposed to.

SELECT 
    c.concept_name AS drug_ingredient, 
    COUNT(d.drug_concept_id) AS exposure_count
FROM drug_era_1m d
INNER JOIN concept c ON d.drug_concept_id = c.concept_id
WHERE
    c.domain_id = 'Drug'
    AND d.person_id IN (SELECT person_id FROM temp_2_1) -- Only patients from temp_2_1
GROUP BY c.concept_name
ORDER BY exposure_count DESC
LIMIT 15;

/*----------
Output:
Acetaminophen		24,713
Hydrochlorothiazide	22,791
levothyroxine		17,572
Simvastatin			15,861
Lisinopril			13,764
Lovastatin			13,033
Oxygen				12,575
Propranolol			11,904
Metformin			11,722
Hydrocodone			10,505
Dipyridamole		1,341
Glyburide			1,148
Furosemide			1,128
Diltiazem			1,120
Amitriptyline		1,105

Answer: The names of the top 15 drug ingredients patients were exposed to were Acetaminophen (24,713), Hydrochlorothiazide (22,791), levothyroxine (17,572), Simvastatin (15,861), Lisinopril (13,764), Lovastatin (13,033), Oxygen (12,575), Propranolol (11,904), Metformin (11,722), Hydrocodone (10,505), Dipyridamole (1,341), Glyburide (1,148), Furosemide	(1,128), Diltiazem (1,120), and Amitriptyline (1,105).
----------*/

-- 3.2 Repeat Question 1 for top 15 drug ingredients, and compare the two tables you get. Comment on your findings. Why were the two tables the same or different?

/*----------
Answer: The two tables are the same for the top 10 drug ingredients because the data used for Question 3.1 includes patients exposed to the top 10 drug ingredients identified in Question 1. Since these top drugs were the most frequently prescribed to all patients, they remain dominant in the subset as well. However, the table in Question 1 has 2,348 rows in total, and we limited the output to the top 10 drug ingredients, but in Question 3.1, we only have 1,975 drug ingredients in total. In Question 1, the results reflect the entire dataset, while in Question 3.2, only patients exposed to at least one of the top 10 drugs were considered. The additional five drugs in Question 3.2 were specific to this subset and had lower overall exposure counts compared to the original top 10. This suggests that patients exposed to the top 10 drugs were also frequently exposed to these additional medications.
----------*/

-- 3.3 On average, how many drug ingredients were each patient exposed to?

SELECT 
    ROUND(AVG(drug_count), 3) AS avg_drug_exposure
FROM (
    SELECT 
        person_id, 
        COUNT(DISTINCT drug_concept_id) AS drug_count
    FROM drug_era_1m
    WHERE person_id IN (SELECT person_id FROM temp_2_1) -- Only patients from temp_2_1
    GROUP BY person_id
) AS patient_drug_counts;

/*----------
Output:
1.794

Answer: On average, each patient were exposed to 1.794 drug ingredients.
----------*/

-- 3.4 Summarize the average by gender. Make sure you use the actual gender categories (not concept IDs) in your results.

SELECT 
    rg.concept_name AS gender, 
    ROUND(AVG(pdc.drug_count), 3) AS avg_drug_exposure
FROM (
    -- Count unique drug ingredients per patient
    SELECT 
        p.gender_concept_id,
        COUNT(DISTINCT d.drug_concept_id) AS drug_count
    FROM drug_era_1m d
    LEFT JOIN person p ON d.person_id = p.person_id_2
    WHERE d.person_id IN (SELECT person_id FROM temp_2_1) -- Only patients from temp_2_1
    GROUP BY d.person_id, p.gender_concept_id -- Include gender_concept_id in grouping
) AS pdc
LEFT JOIN race_gender rg ON pdc.gender_concept_id = rg.concept_id
GROUP BY rg.concept_name
ORDER BY avg_drug_exposure DESC;

/*----------
Output:
FEMALE	1.813
MALE	1.763

Answer: On average, each patient was exposed to 1.763 and 1.813 drug ingredients for males and females, respectively.
----------*/

-- 3.5 Comment on your result and come up with a research hypothesis.

/*----------
Answer: The data indicates that, on average, female patients (1.813 drug ingredients per patient) were exposed to slightly more drug ingredients than male patients (1.763 drug ingredients per patient). While the difference is small, it could be influenced by factors such as differences in healthcare-seeking behavior, disease prevalence, or prescribing patterns between genders.

Research Hypothesis: There is a statistically significant difference in the average number of drug ingredients exposed to between male and female patients.
Null Hypothesis (H0): The mean number of drug ingredients exposed to is the same for male and female patients.
Alternative Hypothesis (H1): The mean number of drug ingredients exposed to differs between male and female patients.
----------*/

-- 3.6 Test your hypothesis. What is your conclusion? You can assume the number of drug ingredients follows a normal distribution. If you use another software to test your hypothesis, make sure you copy and paste both your code and results.

/*----------
Codes and output in R:

> # Load library
> library(dplyr)
> library(readr)
> 
> # Load data
> drug_era <- read_csv("drug_era_1m.csv")
> person <- read_csv("person.csv")
> concept <- read_csv("concept.csv")
> 
> top_10_drug_ids <- drug_era %>%
+     count(drug_concept_id, sort = TRUE) %>%
+     top_n(10, n) %>%
+     pull(drug_concept_id)
> 
> temp_2_1 <- drug_era %>%
+     filter(drug_concept_id %in% top_10_drug_ids) %>%
+     distinct(person_id)
> 
> # Merge gender information
> gender_map <- concept %>%
+     filter(domain_id == "Gender") %>%
+     select(concept_id, gender = concept_name)
> 
> # Prepare final dataset
> final_df <- drug_era %>%
+     inner_join(temp_2_1, by = "person_id") %>%
+     inner_join(person, by = c("person_id" = "person_id_2")) %>%
+     left_join(gender_map, by = c("gender_concept_id" = "concept_id")) %>%
+     group_by(person_id, gender) %>%
+     summarise(drug_count = n_distinct(drug_concept_id), .groups = "drop")
> 
> # Perform a t-test to compare drug exposure between genders
> t.test(drug_count ~ gender, data = final_df)

	Welch Two Sample t-test

data:  drug_count by gender
t = 9.5597, df = 122463, p-value < 2.2e-16
alternative hypothesis: true difference in means between group FEMALE and group MALE is not equal to 0
95 percent confidence interval:
 0.03937715 0.05968809
sample estimates:
mean in group FEMALE   mean in group MALE 
            1.812830             1.763297 

> 

Answer: The codes run a t-test to check if the difference in drug exposure between genders is statistically significant. The results of the Welch Two Sample t-test indicate a statistically significant difference in the average number of drug ingredients exposed to between males and females (p-value < 2.2e-16). The mean number of drug ingredients for females (1.813) is slightly higher than for males (1.763), with a 95% confidence interval for the difference between 0.039 and 0.060. Although the difference is small, it suggests that on average, females are prescribed or exposed to a slightly greater variety of medications than males. Given the large sample size, even minor differences become statistically significant.
----------*/
