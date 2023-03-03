-- ukol c. 5 Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

-- co je gini???

-- pouziju pro to dotaz z predchoziho ukolu a spojim s tabulkou pro hdp (economies), nejdrive opet potrebuji vypocitat procentualni rozdil mezi dvema po sobe nasledujicimi roky

SELECT
	a.rok,
	a.rok_nasledujici,
	odvetvi,
	payroll_rozdil_procenta,
	product,
	price_rodil_procenta,
	GDP_rozdil_procenta,
	payroll_rozdil_procenta - GDP_rozdil_procenta,
	price_rodil_procenta - GDP_rozdil_procenta
FROM 
	(
	SELECT
		payroll.payroll_year AS rok,
		payroll.payroll_year_nasledujici AS rok_nasledujici,
		payroll.odvetvi AS odvetvi,
		payroll.payroll_rozdil_procenta AS payroll_rozdil_procenta,
		prices.name AS product,
		prices.mezirocni_rozdil_procenta AS price_rodil_procenta,
		prices.mezirocni_rozdil_procenta - payroll.payroll_rozdil_procenta AS rozdil_price_payroll
	FROM 
		(
		SELECT
			Y.payroll_year AS payroll_year,
			Y_nasledujici.payroll_year AS payroll_year_nasledujici,
			cpib.name AS odvetvi,
			Y_nasledujici.prumer_rok - Y.prumer_rok AS payroll_rozdil_kc,
			round ((Y_nasledujici.prumer_rok - Y.prumer_rok) * 100 / Y.prumer_rok, 2) AS payroll_rozdil_procenta
		FROM 
			(
			SELECT
				cp.payroll_year,
				sum (value) AS prumer_rok,
				cp.industry_branch_code 
			FROM czechia_payroll cp 
			WHERE cp.calculation_code = 200 
			AND cp.unit_code = 200 
			AND cp.value_type_code = 5958 
			AND cp.industry_branch_code IS NOT NULL
			GROUP BY cp.industry_branch_code, cp.payroll_year 
			) Y	
		LEFT JOIN 
			(
			SELECT
				cp.payroll_year,
				sum (value) AS prumer_rok,
				cp.industry_branch_code 
			FROM czechia_payroll cp 
			WHERE cp.calculation_code = 200 
			AND cp.unit_code = 200 
			AND cp.value_type_code = 5958 
			AND cp.industry_branch_code IS NOT NULL
			GROUP BY cp.industry_branch_code, cp.payroll_year 
			) Y_nasledujici
			ON Y.payroll_year = Y_nasledujici.payroll_year - 1 
			AND Y.industry_branch_code = Y_nasledujici.industry_branch_code
		LEFT JOIN czechia_payroll_industry_branch cpib 
			ON Y.industry_branch_code = cpib.code
		WHERE Y.payroll_year NOT IN (2020,2021)
		) payroll
	LEFT JOIN 
		(
		SELECT
			cpc.name AS name,
			cpc.price_value AS unit,
			cpc.price_unit AS price,
			YEAR (Y.date_from) AS rok,
			YEAR (YY.date_from) AS rok_nasledujici,
			ROUND (( YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc   )* 100 /Y.prumer_rok_kc , 2 ) AS 							mezirocni_rozdil_procenta
		FROM 
			(
			SELECT 
				cp.category_code,
				round (avg (cp.value), 2) AS prumer_rok_kc,
				cp.date_from 
			FROM czechia_price cp 
			GROUP BY cp.category_code, YEAR (cp.date_from)
			) Y
		LEFT JOIN
			(
			SELECT 
				cp.category_code,
				round (avg (cp.value), 2) AS prumer_rok_nasledujici_kc,
				cp.date_from 
			FROM czechia_price cp 
			GROUP BY cp.category_code, YEAR (cp.date_from)
			) YY
			ON Y.category_code = YY.category_code
				AND YEAR (YY.date_from)  = YEAR (Y.date_from) +1
		LEFT JOIN czechia_price_category cpc 
			ON Y.category_code = cpc.code
		) prices
	ON payroll.payroll_year = prices.rok AND payroll.payroll_year_nasledujici = prices.rok_nasledujici
	WHERE prices.mezirocni_rozdil_procenta IS NOT NULL 
	ORDER BY rok, odvetvi
	) a
LEFT JOIN
	(
	SELECT
		current_year.country,
		current_year.rok,
		following_year.rok_nasledujici,
		current_year.current_GDP,
		following_year.following_year_GDP,
		round ((following_year.following_year_GDP - current_year.current_GDP) * 100 / current_year.current_GDP, 2) AS 			GDP_rozdil_procenta
	FROM 
		(
		SELECT 
			*,
			e.`year` AS rok,
			e.GDP AS current_GDP
		FROM economies e 
		WHERE country = 'czech republic'
		) current_year
	LEFT JOIN 
		(
		SELECT 
			*,
			e.`year` AS rok_nasledujici,
			e.GDP AS following_year_GDP
		FROM economies e 
		WHERE country = 'czech republic'
		) following_year
	ON current_year.YEAR + 1 = following_year.YEAR
	) b 
ON a.rok = b.rok AND a.rok_nasledujici = b.rok_nasledujici
ORDER BY a.rok, odvetvi

-- okay, stvorila jsem monstrum a takhle to fungovat nebude. zvytvorimjenom jeden pohled s potrebnymi cisly, a sadu SQL dotazu