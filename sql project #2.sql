-- ukol 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- pouziju dotaz z prvniho ukolu, kde jsem si zjistila prumerne mzdy v jednotlivych odvetvi a vyberu si pouze roky 2000 a 2020 a ty budu porovnavat s cenami mleka a chleba
-- nakonec jsem se rozhodla vybrat roky 2006 a 2018, protoze data k cen potravin mam za obdobi 2006 az 2018
-- z tabulky czechia price jsem si vypocitala prumerne ceny potravin pro kazdy rok (uprimne jsem neporovnavala kolik mereni kazdy rok probehlo, spocitala jsem proste prumer podle roku ve sloupecku date from) a nasledne vyfiltrovala maslo a chleb a roky 2006 a 2018
-- spojila jsem si to s dotaze z predchoziho ukolu, ktery jsem mirne poupravila, abych dostala pouze roky 2006 a 2018

SELECT *,
	b.prumer_rok_kc / a.avg_price_per_unit AS possibility
FROM 
	(
	SELECT
		ROUND ( avg (cp.value), 2 ) AS avg_price_per_unit,
		cp.category_code,
		cp.date_from 
	FROM czechia_price cp
	WHERE cp.category_code IN (111301,114201)
		AND YEAR (cp.date_from) IN (2006,2018)
	GROUP BY YEAR (cp.date_from), cp.category_code 
	) a
LEFT JOIN
	(
	SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok_kc,
		cp.industry_branch_code
	FROM czechia_payroll cp
	WHERE cp.calculation_code = 200 
		AND cp.unit_code = 200 
		AND cp.value_type_code = 5958 
		AND cp.industry_branch_code IS NOT NULL
		AND cp.payroll_year IN (2006,2018)
	GROUP BY cp.industry_branch_code, cp.payroll_year
	ORDER BY cp.payroll_year, cp.industry_branch_code
	) b
	ON YEAR (a.date_from) = b.payroll_year
	
-- timto dotazem jsem si kontrolovala spravne spocitany prumer	
	SELECT
		avg (value),
		date_from,
		category_code 
	FROM czechia_price cp 
	WHERE category_code = 114201
		AND YEAR (date_from) = 2018
	
-- cely vytvoreny dotaz chci poupravit tak, aby se mi objevily nazvy potravin a odvetvi

SELECT 
	income.payroll_year,
	cpib.name AS industry,
	round ( income.prumer_rok_kc / prices.avg_price_per_unit, 0 ) AS possibility,
	cpc.price_unit AS unit,
	cpc.name	 AS product,
	income.prumer_rok_kc,
	prices.avg_price_per_unit	
FROM 
	(
	SELECT
		ROUND ( avg (cp.value), 2 ) AS avg_price_per_unit,
		cp.category_code,
		cp.date_from 
	FROM czechia_price cp
	WHERE cp.category_code IN (111301,114201)
		AND YEAR (cp.date_from) IN (2006,2018)
	GROUP BY YEAR (cp.date_from), cp.category_code 
	) prices
LEFT JOIN
	(
	SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok_kc,
		cp.industry_branch_code
	FROM czechia_payroll cp
	WHERE cp.calculation_code = 200 
		AND cp.unit_code = 200 
		AND cp.value_type_code = 5958 
		AND cp.industry_branch_code IS NOT NULL
		AND cp.payroll_year IN (2006,2018)
	GROUP BY cp.industry_branch_code, cp.payroll_year
	ORDER BY cp.payroll_year, cp.industry_branch_code
	) income
	ON YEAR (prices.date_from) = income.payroll_year
LEFT JOIN czechia_price_category cpc 
	ON prices.category_code = cpc.code
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON income.industry_branch_code = cpib.code 
ORDER BY income.payroll_year, industry, product;
	
-- view
CREATE OR REPLACE VIEW v_misa_hribova_milk_and_bread AS
SELECT 
	income.payroll_year,
	cpib.name AS industry,
	round ( income.prumer_rok_kc / prices.avg_price_per_unit, 0 ) AS possibility,
	cpc.price_unit AS unit,
	cpc.name	 AS product
FROM 
	(
	SELECT
		ROUND ( avg (cp.value), 2 ) AS avg_price_per_unit,
		cp.category_code,
		cp.date_from 
	FROM czechia_price cp
	WHERE cp.category_code IN (111301,114201)
		AND YEAR (cp.date_from) IN (2006,2018)
	GROUP BY YEAR (cp.date_from), cp.category_code 
	) prices
LEFT JOIN
	(
	SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok_kc,
		cp.industry_branch_code
	FROM czechia_payroll cp
	WHERE cp.calculation_code = 200 
		AND cp.unit_code = 200 
		AND cp.value_type_code = 5958 
		AND cp.industry_branch_code IS NOT NULL
		AND cp.payroll_year IN (2006,2018)
	GROUP BY cp.industry_branch_code, cp.payroll_year
	ORDER BY cp.payroll_year, cp.industry_branch_code
	) income
	ON YEAR (prices.date_from) = income.payroll_year
LEFT JOIN czechia_price_category cpc 
	ON prices.category_code = cpc.code
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON income.industry_branch_code = cpib.code 
ORDER BY income.payroll_year, industry, product;

SELECT *
FROM v_misa_hribova_milk_and_bread vmhmab 
ORDER BY possibility 

-- jako prvni a posledni srovnatelne obdobi jsem si vybrala roky 2006 a 2018. V roce 2006 si nejmene chleba i mleka mohli dovolit zamestnanci v pohostinstvi, naopak nejvice v peneznictvi a pojistovnictvi. V roce 2018 
	