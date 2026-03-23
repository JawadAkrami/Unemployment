-- ====================================================================================
-- Project: Local Area Unemployment Statistics (LAUS) from 1990 to 2024
-- Description:
-- 	 • SQL queries for cleaning, validating, and analyzing unemployment trends.

-- Assumptions:
--   • Unemployment rate is used instead of raw unemployment counts for comparability.
--   • Small labor markets may produce unusually high unemployment rates.
--   • Some analyses filter very small labor forces to reduce volatility.
-- ====================================================================================


-- ===============================================================================================================================
-- 														Introduction 															  
-- ===============================================================================================================================
/*
This project analyzes the Local Area Unemployment Statistics (LAUS) dataset from 1990–2024. It explores unemployment patterns 
across different geographic levels in the United States. The dataset includes labor force statistics such as employment, 
unemployment counts, and unemployment rates for states, metropolitan areas, counties, and sub-county places.

The analysis focuses on identifying long-term unemployment trends, volatility across geographic levels, economic shocks and 
their impact on the unemployment, and regional disparities. SQL is used to clean and normalize the dataset, validate data 
quality, and perform analysis to uncover meaningful labor market insights.
*/



-- =============================================================================================================================
-- 														Normalization of Data
-- =============================================================================================================================

-- Converting columns name to snake_case format
ALTER TABLE unemployment RENAME COLUMN `Area Name` TO area_name,
						 RENAME COLUMN `Area Type` TO area_type,
                         RENAME COLUMN Year TO year,
                         RENAME COLUMN Month TO month,
						 RENAME COLUMN `Seasonally Adjusted(Y/N)` TO seasonally_adjusted_Y_or_N,
                         RENAME COLUMN Status TO status,
						 RENAME COLUMN `Labor Force` TO labor_force,
                         RENAME COLUMN Employment TO employment,
                         RENAME COLUMN Unemployment TO unemployment,
						 RENAME COLUMN `Unemployment Rate` TO unemployment_rate;



-- =============================================================================================================================
-- 														Duplicate Records
-- =============================================================================================================================

SELECT area_name, year, month, COUNT(*)
FROM unemployment
GROUP BY area_name, year, month
HAVING COUNT(*) > 1;

/* There are no duplicate values.
Note: The dataset contains only 'Annual' values in the month column,
indicating that all records are yearly aggregates rather than monthly data.
*/


-- =============================================================================================================================
-- 														Missing NULL Handling
-- =============================================================================================================================


SELECT 
	SUM(employment IS NULL), 
    SUM(unemployment IS NULL),
    SUM(unemployment_rate IS NULL),
    SUM(labor_force IS NULL)
FROM unemployment;
-- There are zero NULL values in this dataset.



-- =============================================================================================================================
-- 														Analytical Questions
-- =============================================================================================================================

-- 1. How many distinct areas and area types exist?
SELECT COUNT(DISTINCT area_name)
FROM unemployment ;

SELECT COUNT(DISTINCT area_type)
FROM unemployment;
/* There are 1021 distinct areas and 4 area types.*/


-- 2. Are there missing or inconsistent unemployment rates?
SELECT 
	MIN(unemployment_rate),
	MAX(unemployment_rate)
FROM unemployment;

SELECT
  MIN(unemployment_rate) AS min_rate,
  MAX(unemployment_rate) AS max_rate
FROM unemployment
WHERE labor_force >= 1000;

SELECT
  area_name,
  year,
  labor_force,
  unemployment_rate
FROM unemployment
WHERE unemployment_rate >= 40
  AND labor_force >= 1000
ORDER BY unemployment_rate DESC;
/* Initial validation using MIN() and MAX() confirmed that all unemployment rates fall 
within the valid 0–100% range, indicating no obvious data entry errors.

However, extremely high unemployment rates can occur in very small labor markets, where 
small changes in employment can produce large percentage swings.

To verify this, observations with labor force sizes below 1000 were excluded, reducing 
the impact of volatility in small areas. After filtering, unemployment rates ranged between 0% and 
approximately 50%, which is consistent with expected labor market behavior during economic 
shocks such as recessions.

Therefore, the dataset does not contain invalid unemployment rate values.
*/


-- 3. What is the average unemployment rate by area type per year?
SELECT 
	area_type, 
    year, 
    ROUND(AVG(unemployment_rate),2) AS avg_unemployment_rate
FROM unemployment
WHERE labor_force >= 1000
GROUP BY area_type, year
ORDER BY area_type, year;
/*
Counties and metropolitan areas generally have higher unemployment rates than states, reflecting 
greater sensitivity to local economic conditions. All area types experienced a significant increase during 
the Great Recession (2009–2011), with peaks around 13–14%. In 2020, unemployment rose again due to the 
COVID-19 pandemic. States consistently show the lowest and most stable unemployment rates, while smaller 
geographic units—such as counties and sub-county places—exhibit higher levels and greater volatility.
*/


-- 4. What are the minimum and maximum unemployment rates by area type per year?"
SELECT 
	area_type, 
    MIN(unemployment_rate) AS min_rate, 
    MAX(unemployment_rate) AS max_rate, 
	year
FROM unemployment
GROUP BY area_type, year
ORDER BY area_type, year;

/* 
States are the stable ones—their rates barely budge within each year. They smooth out all the local ups and downs.

Counties and metropolitan areas tell the real story. In 1992, some counties had 5% unemployment while others were hurting 
at nearly 31%. Within the same year, there are significantly different local labor market conditions.

Sub-county places exhibit the highest variability. Zeros on one end, 100% on the other. At 0%, everyone who wants a job has 
one. At 100%? That's tiny towns with fewer than 90 people—when nobody's working.
*/


-- 5. How has unemployment changed over time for each area?
SELECT 
  area_name,
  year AS period,
  ROUND(AVG(unemployment_rate),2) AS avg_rate
FROM unemployment 
GROUP BY area_name, year
ORDER BY area_name, year;
/*
The results show clear economic cycles in unemployment trends. 
Unemployment rates peaked between 2009 and 2011 during the Great Recession, 
then gradually declined throughout the economic expansion of the 2010s. 
In 2020, unemployment rose again across many areas due to the economic impact 
of the COVID-19 pandemic. The data also shows that smaller geographic areas tend to 
experience greater volatility because unemployment rates in small labor markets are 
more sensitive to economic changes.
*/



-- 6. What is the year-over-year change in unemployment rate?
SELECT
  area_name,
  year,
  ROUND(AVG(unemployment_rate),2) AS avg_rate,
  ROUND(
    AVG(unemployment_rate)
      - LAG(AVG(unemployment_rate)) OVER (
          PARTITION BY area_name ORDER BY year),2) AS yoy_change
FROM unemployment
GROUP BY area_name, year
ORDER BY area_name, year;

/*
Overall, the results show a clear economic cycle:
	• 2010–2019: Gradual improvement (falling unemployment)
	• 2020: Major disruption (sharp rise in unemployment)
	• 2021–2022: Recovery (declining unemployment again)
	• 2023–2024: Stabilization with minor fluctuations
This pattern is consistent across many regions. It indicates that external 
macroeconomic events affected all areas similarly, while differences in 
magnitude - higher spikes in some cities - suggest local economic 
resilience varies by area.
*/


-- 7. Which areas have consistently high unemployment across multiple years?
SELECT 
    area_name,
    ROUND(AVG(unemployment_rate),2) AS avg_rate
FROM unemployment
GROUP BY area_name
ORDER BY avg_rate DESC;

/* Calexico city has the highest average unemployment rate (31.43%) 
among all cities. 
*/


-- 8. During economic downturn years, which area types were most affected?
SELECT
    area_type,
    year,
    ROUND(AVG(unemployment_rate),2) AS avg_rate
FROM unemployment
WHERE year IN (2009, 2010, 2011, 2020)
GROUP BY area_type, year
ORDER BY avg_rate DESC;

/*
Counties were the most affected during economic downturn years, consistently
showing the highest average unemployment rates across all area types.

The most severe impact occurred during the Great Recession, with county-level
unemployment peaking at 13.94% in 2010. All area types experienced similarly
elevated unemployment during this period.

A second increase occurred in 2020 due to the COVID-19 pandemic; however,
unemployment rates were notably lower than the levels observed during the
Great Recession. 

Overall, smaller geographic units such as counties tend to experience stronger
impacts during economic downturns.
*/


-- 9. Which area types experienced the largest unemployment spikes?
SELECT 
    area_type,
    year,
    ROUND(AVG(unemployment_rate),2) AS avg_rate,
	ROUND(AVG(unemployment_rate) -
    LAG(AVG(unemployment_rate)) OVER (
        PARTITION BY area_type ORDER BY year
        ),2) AS spike
FROM unemployment
GROUP BY area_type, year
ORDER BY area_type, year, spike DESC;

/* 
All area types saw their largest unemployment spikes in 2020, with the state 
level showing the biggest increase (+6), followed by sub-county places and 
metropolitan areas (~+5) and counties (~+4.8). Smaller spikes also occurred in 
2009 and the early 1990s. Overall, 2020 represents the most severe and widespread 
shock, followed by a strong recovery in 2021–2022 as unemployment declined.
*/


-- 10. Which area types have the highest long-term unemployment?
SELECT
    area_type,
    ROUND(AVG(unemployment_rate),2) AS avg_unemployment
FROM unemployment
GROUP BY area_type
ORDER BY avg_unemployment DESC;
/* 
Counties have the highest average unemployment rate (8.63) over the years.
Followed by Metropolitan Area and Sub-County Place.
State has the lowest average unemployment rate.
*/


-- 11. Which years had the highest overall unemployment?
SELECT 
	year, 
    ROUND(AVG(unemployment_rate),2) AS avg_unemployment
FROM unemployment
GROUP BY year
ORDER BY avg_unemployment DESC
LIMIT 3;
/*
2009, 2010, and 2011 were the years with the highest 
unemployment rates, ranging from 12.75% to 13.62%.
*/


-- 12. Which area types have the most stable employment?
SELECT 
    area_type,
    ROUND(STDDEV(unemployment_rate), 2) AS unemployment_volatility
FROM unemployment
GROUP BY area_type
ORDER BY unemployment_volatility;
/* 
State areas show the lowest standard deviation (2.23), indicating the
most stable unemployment rates over time. In contrast, Sub-County Places 
show the highest volatility (7.68), reflecting larger fluctuations in 
smaller labor markets.
*/


-- ===============================================================================================================================
-- 														Conclusion 															  
-- ===============================================================================================================================
/*
After analyzing 30+ years of unemployment data across various areas, a few interesting patterns really stood out.

Counties take the hardest hits. They show consistently higher unemployment rates than states or metropolitan 
areas — 8.63% on average versus just 5.91% for states. This is likely because a single factory closing in a 
small county can shake up the whole local economy, while states have more diverse industries to absorb those shocks.

The Great Recession was rougher than COVID. 2009–2011 still holds the record for the highest unemployment rates 
(peaking at 13.62% in 2010). While 2020 brought a sudden spike, it didn't quite reach the same heights as the 
financial crisis.

Smaller geographic areas experience greater volatility. Sub-county areas are the most volatile (7.68 standard deviation), 
while states are the most stable (2.23). 
Places like Calexico city averaged over 30% unemployment. This reflects prolonged economic challenges within certain
communities.
*/



-- ===============================================================================================================================
-- 														Reference 															  
-- ===============================================================================================================================
/*
Data Government.2026. Local Area Unemployment Statistics (LAUS), Annual Average.
Retrieved from: https://catalog.data.gov/dataset/local-area-unemployment-statistics-laus-annual-average
*/






