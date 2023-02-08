/*1. 
    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims. */

SELECT npi,
	   SUM(total_claim_count) AS total_claims
  FROM prescription
 GROUP BY npi
 ORDER BY total_claims DESC; -- npi '1881634483' has the highest total of claims reported in the prescription table.

SELECT COUNT(DISTINCT npi)
  FROM prescription; -- Sanity checking the total number of npi's represented in the prescription table. 

SELECT nppes_provider_first_name,
	   nppes_provider_last_org_name,
	   specialty_description,
	   SUM(total_claim_count) AS total_claims
  FROM prescription AS script
	   INNER JOIN prescriber AS scribe --Joining prescriber table to bring in relevant nppes_ information
	   USING (npi)
 GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
 ORDER BY total_claims DESC;

/*2. 
    a. Which specialty had the most total number of claims (totaled over all drugs)?
    b. Which specialty had the most total number of claims for opioids?
    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?*/
	
SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
  FROM prescription AS script
	   FULL JOIN prescriber AS scribe
	   USING(npi)
 GROUP BY specialty_description
 ORDER BY SUM(total_claim_count) DESC NULLS LAST; --Family Practice has the highest total number of claims of all specialties represented. 

SELECT COUNT(DISTINCT specialty_description)
FROM prescriber; --Sanity check. 107 specialties represented in the prescriber table. There are 15 specialties with NULL values in the query that are not represented using an INNER JOIN, changed above query to FULL JOIN to compare results and found this. Reformatted query to put NULLS LAST to better represent the answer to the question. This serves to answer Question 2.C as well. 

SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
  FROM prescription AS script
	   INNER JOIN prescriber AS scribe
	   USING (npi)
	   INNER JOIN drug AS drug --joining drug table to bring in information about drug type. 
	   USING(drug_name)
 WHERE drug.opioid_drug_flag = 'Y' --Limiting to only drugs with opioid flags.
 GROUP BY specialty_description
 ORDER BY SUM(total_claim_count) DESC; --Nurse Practicioner has the highest total number of claims for opiod class drugs. 

-- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?*/

SELECT total_claims.specialty_description,
	   total_claims,
	   total_opioid_claims,
	   ROUND(total_opioid_claims/total_claims*100, 2) AS pct_opioid_claims
  FROM
       (SELECT SUM(total_claim_count) AS total_claims, 
	           specialty_description
	      FROM prescription  
		       INNER JOIN drug
		       USING(drug_name)
		       INNER JOIN prescriber
		       USING(npi)
	     GROUP BY specialty_description) AS total_claims --Total claims for all drugs by specialty.
LEFT JOIN
       (SELECT SUM(total_claim_count) AS total_opioid_claims, 
			   specialty_description
	      FROM prescription  
		 	   INNER JOIN drug
			   USING(drug_name)
		 	   INNER JOIN prescriber
		 	   USING(npi)
		 WHERE drug.opioid_drug_flag = 'Y'
         GROUP BY specialty_description) AS total_opioid_claims ---Total opioid drug claims by specialty.
 USING (specialty_description)
 ORDER BY pct_opioid_claims DESC NULLS LAST; 

/*3. 
    a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.*/

SELECT drug.generic_name,
	   SUM(script.total_drug_cost) AS total_drug_cost
  FROM drug
	   LEFT JOIN prescription AS script
	   USING(drug_name)
 GROUP BY drug.generic_name
 ORDER BY total_drug_cost DESC NULLS LAST; --"INSULIN GLARGINE,HUM.REC.ANLOG" has the greatest total drug cost. 

SELECT drug.generic_name,	
	   ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS single_day_cost --Dividing the sum of total drug cost by the sum of total days supplied to get the cost per day.
  FROM drug
	   LEFT JOIN prescription AS script
	   USING(drug_name)
 GROUP BY drug.generic_name
 ORDER BY single_day_cost DESC NULLS LAST; --"C1 ESTERASE INHIBITOR" has the highest single day cost. 

/*4. 
    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.*/
	
SELECT drug_name,
	  (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
  FROM drug; --Classifying drugs.

SELECT 
	  (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type,
	   SUM(total_drug_cost::money) AS total_cost
  FROM drug
 INNER JOIN prescription
 USING drug_name
 GROUP BY drug_type
 ORDER BY total_cost DESC; --More money was spent on opioids than antibiotics.

/*5. 
    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.*/

SELECT COUNT(DISTINCT cbsaname)
  FROM cbsa
       LEFT JOIN fips_county
	   USING(fipscounty)
 WHERE state = 'TN'; --10 CBSAs are in TN, covering 42 different counties.

SELECT cbsa.cbsaname,
	   SUM(population) AS total_pop
  FROM cbsa
       LEFT JOIN population
	   USING(fipscounty)
 GROUP BY cbsa.cbsaname
 ORDER BY total_pop DESC NULLS LAST; --"Nashville-Davidson--Murfreesboro--Franklin, TN" has the highest total population. "Morristown, TN" has the lowest total population. 

SELECT county, population
  FROM population
	   LEFT JOIN fips_county --Left join to keep all population data.
	   USING(fipscounty)
	   LEFT JOIN cbsa --Left join to keep all population data.
	   USING(fipscounty) --Table representing all counties, names, and their cbsa data.
EXCEPT --Used to EXCLUDE the information from the second part of the query, giving us only counties not represented by a cbsa.
SELECT county, population
  FROM population
	   LEFT JOIN fips_county 
	   USING(fipscounty)
	   INNER JOIN cbsa --Inner join to only keep data present in both tables. 
	   USING(fipscounty)  --Table representing ONLY counties with NULL cbsa data
 ORDER BY population DESC; --Sevier is the largest county NOT included in a cbsa.

/*6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.*/

SELECT prescription.drug_name,
	   total_claim_count,
	  (CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'other' END) AS drug_type, --ID'ing whether or not a drug is an opioid.
	   prescriber.nppes_provider_first_name||' '||prescriber.nppes_provider_last_org_name AS provider_name --concatenation of first and last names.
  FROM prescription
	   LEFT JOIN drug
	   ON prescription.drug_name = drug.drug_name
	   LEFT JOIN prescriber
	   ON prescription.npi = prescriber.npi
 WHERE total_claim_count >= 3000;

/*7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.*/
	
SELECT prescriber.npi,
	   drug.drug_name,
	   COALESCE(SUM(total_claim_count), 0) AS total_claims
  FROM prescriber
	   CROSS JOIN drug
	   LEFT JOIN prescription
	   ON prescription.drug_name = drug.drug_name
 WHERE prescriber.specialty_description = 'Pain Management' 
	   AND prescriber.nppes_provider_city = 'NASHVILLE' 
	   AND drug.opioid_drug_flag = 'Y'
 GROUP BY drug.drug_name, prescriber.npi;



