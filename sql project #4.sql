-- ukol c 4 Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- rozhodla jsem se pouzit dotaz z ukolu cislo jedna a poupravit ho tak, abych krome mezirocniho rozdilu mezd v kc videla i rozdil v procentech. I tentokrat budu pracovat pouze s prepoctenym poctem zamestnancu.
-- a tuhle tabulku se pokusim spojit s tabulkou, kterou jsem si vytvorila v ukolu c. 3 (spojim ji na zaklade roku a roku nasledujicim, abych videla procentualni rozdil mezi mzdou a cenou potravin)

SELECT
	payroll.payroll_year AS rok,
	payroll.payroll_year_nasledujici AS rok_nasledujici,
	payroll.odvetvi,
	payroll.payroll_rozdil_procenta,
	prices.name AS product,
	prices.mezirocni_rozdil_procenta AS price_rodil_procenta,
	prices.mezirocni_rozdil_procenta - payroll.payroll_rozdil_procenta AS rozdil
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
	AND prices.mezirocni_rozdil_procenta -	payroll.payroll_rozdil_procenta >= 10
ORDER BY rok

-- dotaz si ulozim jako view a s tim budu dal pracovat. Vzhledem k tomu, ze v podstate kazdy rok doslo k tomu, ze alsepon v nekterem z odvetvi je rozdil mezi narustem/poklesem mezd a narustem cen vetsi nez 10 procent, zkusim spocitat, kolika odvetvi rocne se toto tyka, poporipade jake odvetvi se necasteji vykytuje v teto tabulce.

CREATE OR REPLACE VIEW v_misa_hribova_mzdy_vs_inflace_4 AS
SELECT
	payroll.payroll_year AS rok,
	payroll.payroll_year_nasledujici AS rok_nasledujici,
	payroll.odvetvi,
	payroll.payroll_rozdil_procenta,
	prices.name AS product,
	prices.mezirocni_rozdil_procenta AS price_rodil_procenta,
	prices.mezirocni_rozdil_procenta - payroll.payroll_rozdil_procenta AS rozdil
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
	AND prices.mezirocni_rozdil_procenta - payroll.payroll_rozdil_procenta >= 10
ORDER BY rok;

SELECT
	COUNT(rok),
	rok,
	rok_nasledujici 
FROM v_misa_hribova_mzdy_vs_inflace_4 vmhmvi 
GROUP BY rok 
ORDER BY COUNT(rok) DESC

-- nejvetsi rozdil mezi narustem/poklesem mezd a narustem cen doslo z roku 2007 na rok 2008, coz jsem predpokladala. Naopak tomu bylo z roku 2013 na rok 2014

SELECT
	odvetvi,
	count (odvetvi)
FROM v_misa_hribova_mzdy_vs_inflace_4 vmhmvi 
GROUP BY odvetvi 
ORDER BY count (odvetvi)

SELECT *
FROM v_misa_hribova_mzdy_vs_inflace_4 vmhmvi 
WHERE odvetvi = 'Zemědělství, lesnictví, rybářství'

SELECT *
FROM v_misa_hribova_mzdy_vs_inflace_4 vmhmvi 
WHERE odvetvi = 'Peněžnictví a pojišťovnictví'

-- byla jsem prekvapena, ze nejmene se vyskytuje v tabulce Zemědělství, lesnictví, rybářství, naopak nejvice Peněžnictví a pojišťovnictví(toto bylo s nejvetsi pravdepodobnosti zbusobeno vyraznym poklesem mezd ,ezi roky 2012 a 2013)

SELECT
	product,
	count (product)
FROM v_misa_hribova_mzdy_vs_inflace_4 vmhmvi 
GROUP BY product 
ORDER BY 	count (product)

-- cena piva a sunkoveho salamu nejvice koresponduje s narustem mezd :-) nejhure na tom je mouka a maslo.