--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT npi) AS prescriber_npi,
	  (SELECT COUNT(DISTINCT npi)
	   FROM prescription) AS prescription_npi,
	   COUNT(DISTINCT npi) - (SELECT COUNT(DISTINCT npi)
								FROM prescription) AS difference_npi
  FROM prescriber; -- 4458 npi's appear in the prescriber table but not the prescription table. 

--2.
    --a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT drug.generic_name
  FROM prescription
	   LEFT JOIN prescriber
	   ON prescription.npi = prescriber.npi
	   LEFT JOIN drug
	   ON prescription.drug_name = drug.drug_name
 WHERE prescriber.specialty_description = 'Family Practice'
 GROUP BY drug.generic_name
 ORDER BY SUM(total_claim_count) DESC
 LIMIT 5;  --"LEVOTHYROXINE SODIUM" "LISINOPRIL" "ATORVASTATIN CALCIUM" "AMLODIPINE BESYLATE" "OMEPRAZOLE"

   --b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT drug.generic_name
  FROM prescription
	   LEFT JOIN prescriber
	   ON prescription.npi = prescriber.npi
	   LEFT JOIN drug
	   ON prescription.drug_name = drug.drug_name
 WHERE prescriber.specialty_description = 'Cardiology' 
 GROUP BY drug.generic_name
 ORDER BY SUM(total_claim_count) DESC
 LIMIT 5; --"ATORVASTATIN CALCIUM" "CARVEDILOL" "METOPROLOL TARTRATE" "CLOPIDOGREL BISULFATE" "AMLODIPINE BESYLATE"

    --c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name
  FROM drug
 WHERE drug_name IN
		(SELECT prescription.drug_name
		   FROM prescription
			    LEFT JOIN prescriber
			    ON prescription.npi = prescriber.npi
		  WHERE prescriber.specialty_description = 'Family Practice'
		  GROUP BY prescription.drug_name
		  ORDER BY SUM(total_claim_count) DESC
		  LIMIT 5) 
        AND drug_name IN
		(SELECT prescription.drug_name
		   FROM prescription
				LEFT JOIN prescriber
				ON prescription.npi = prescriber.npi
		  WHERE prescriber.specialty_description = 'Cardiology'
		  GROUP BY prescription.drug_name
		  ORDER BY SUM(total_claim_count) DESC
		  LIMIT 5)	
 GROUP BY drug.generic_name; --Using subqueries in WHERE clause



(SELECT drug.generic_name
   FROM prescription
	    LEFT JOIN prescriber
	    ON prescription.npi = prescriber.npi
	    LEFT JOIN drug
	    ON prescription.drug_name = drug.drug_name
  WHERE prescriber.specialty_description = 'Cardiology' 
  GROUP BY drug.generic_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5)

INTERSECT

(SELECT drug.generic_name
   FROM prescription
	    LEFT JOIN prescriber
	    ON prescription.npi = prescriber.npi
	    LEFT JOIN drug
	    ON prescription.drug_name = drug.drug_name
  WHERE prescriber.specialty_description = 'Family Practice' 
  GROUP BY drug.generic_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5); --Using set operator INTERSECT



--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
    --a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT prescriber.npi,
	   SUM(total_claim_count),
	   nppes_provider_city
  FROM prescriber
	   INNER JOIN prescription
	   ON prescriber.npi = prescription.npi
 WHERE nppes_provider_city = 'NASHVILLE'
 GROUP BY prescriber.npi, nppes_provider_city
 ORDER BY SUM(total_claim_count) DESC
 LIMIT 5;
    
    --b. Now, report the same for Memphis.

SELECT prescriber.npi,
	   SUM(total_claim_count) AS total_claim_count,
	   nppes_provider_city
  FROM prescriber
	   INNER JOIN prescription
	   ON prescriber.npi = prescription.npi
 WHERE nppes_provider_city = 'MEMPHIS'
 GROUP BY prescriber.npi, nppes_provider_city
 ORDER BY SUM(total_claim_count) DESC
 LIMIT 5;
    
    --c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT prescriber.npi,
	    SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city
   FROM prescriber
		INNER JOIN prescription
		ON prescriber.npi = prescription.npi
  WHERE nppes_provider_city = 'MEMPHIS'
  GROUP BY prescriber.npi, nppes_provider_city
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5)

UNION

(SELECT prescriber.npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city
   FROM prescriber
		INNER JOIN prescription
		ON prescriber.npi = prescription.npi
  WHERE nppes_provider_city = 'NASHVILLE'
  GROUP BY prescriber.npi, nppes_provider_city
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5)

UNION

(SELECT prescriber.npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city
   FROM prescriber
		INNER JOIN prescription
		ON prescriber.npi = prescription.npi
  WHERE nppes_provider_city = 'KNOXVILLE'
  GROUP BY prescriber.npi, nppes_provider_city
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5)

UNION

(SELECT prescriber.npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city
   FROM prescriber
		INNER JOIN prescription
		ON prescriber.npi = prescription.npi
  WHERE nppes_provider_city = 'CHATTANOOGA'
  GROUP BY prescriber.npi, nppes_provider_city
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 5);

--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT fips_county.county, deaths
  FROM overdoses
	   LEFT JOIN fips_county
	   ON fips_county.fipscounty = overdoses.fipscounty
 WHERE deaths > (SELECT AVG(deaths) 
				   FROM overdoses);
						
--5.
    --a. Write a query that finds the total population of Tennessee.

SELECT SUM(population)
  FROM population; --6597381
    
    --b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
	
SELECT county,
	   population,
	   ROUND(population/(SELECT SUM(population)
						   FROM population)*100,2) AS pct_population
  FROM population
       LEFT JOIN fips_county
	   ON population.fipscounty = fips_county.fipscounty
 ORDER BY pct_population DESC;
	
	
	
	