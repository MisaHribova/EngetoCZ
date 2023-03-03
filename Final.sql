-- view pro cerpani dat:

CREATE OR REPLACE VIEW v_misa_hribova_final_sql_projest_table_one AS 
SELECT
		payroll.*,
		prices.category_code,
		prices.product_type,
		prices.avg_price_kc,
		prices.price_value,
		prices.price_unit,
		GDP.GDP_Czechia,
		GDP.gini_Czechia
FROM 
	(
		SELECT
			cp.payroll_year,
			avg (value) AS avg_month_income_kc,
			cp.industry_branch_code,
			cpib.name AS branch
		FROM czechia_payroll cp 
		LEFT JOIN 
			czechia_payroll_industry_branch cpib 
			ON cp.industry_branch_code = cpib.code 
		WHERE cp.calculation_code = 200 
		AND cp.unit_code = 200 
		AND cp.value_type_code = 5958 
		AND cp.industry_branch_code IS NOT NULL
		GROUP BY cp.industry_branch_code, cp.payroll_year 
		) payroll
	LEFT JOIN 
			(	
		SELECT
			cp.category_code,
			cpc.name AS product_type,
			YEAR (date_from) AS years,
			round (avg (value), 2) AS avg_price_kc,
			cpc.price_value,
			cpc.price_unit 
		FROM czechia_price cp
		LEFT JOIN czechia_price_category cpc 
			ON cp.category_code = cpc.code
		GROUP BY cp.category_code, YEAR (date_from)
		) prices	
	ON payroll.payroll_year = prices.years
	LEFT JOIN 
		(
		SELECT
			e.`year`,
			e.country,
			e.GDP AS GDP_Czechia,
			e.gini AS gini_Czechia
		FROM economies e 
		WHERE e.country = 'czech republic'
		) GDP
	ON payroll.payroll_year = GDP.`year`
  ORDER BY payroll.industry_branch_code, payroll.payroll_year;
  
 SELECT *
 FROM v_misa_hribova_final_sql_projest_table_one vmhfspto;
 
 
-- 	UKOL C 1:  Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 
-- predpoklad: v prubehu let mzdy porostou, vyjimkou by dle meho nazoru mohl byt rok 2008/2009, kdy vetsina zamestnavatelu mzdy zmrazila
 
SELECT
	payroll.payroll_year,
	payroll_following.payroll_year AS payroll_year_following,
	payroll.industry_branch_code,
	payroll.branch,
	-- payroll_following.avg_month_income_kc - payroll.avg_month_income_kc AS avg_month_increase_kc,
	round ((payroll_following.avg_month_income_kc - payroll.avg_month_income_kc) * 100 / payroll.avg_month_income_kc, 		2) AS avg_month_increase_procenta
FROM 
	(
	SELECT DISTINCT
	 	payroll_year,
	 	avg_month_income_kc,
	 	industry_branch_code,
	 	branch
	FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
	) payroll
LEFT JOIN 
	(
	SELECT DISTINCT
	 	payroll_year,
	 	avg_month_income_kc,
	 	industry_branch_code,
	 	branch
	FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
	) payroll_following
ON payroll.payroll_year + 1 = payroll_following.payroll_year
-- ON payroll.payroll_year + 21 = payroll_following.payroll_year
	AND payroll.industry_branch_code = payroll_following.industry_branch_code
WHERE round ((payroll_following.avg_month_income_kc - payroll.avg_month_income_kc) * 100 / payroll.avg_month_income_kc, 2) < 0
-- GROUP BY payroll.industry_branch_code
ORDER BY payroll.industry_branch_code, payroll.payroll_year
-- ORDER BY round ((payroll_following.avg_month_income_kc - payroll.avg_month_income_kc) * 100 / payroll.avg_month_income_kc, 		2) DESC
;

-- zaver: v prubehu let mzdy nepretrzite rostly pouze ve ctyrech odvetvi z devatenacti sledovanych a to ve zpracovatelskem prumyslu, doprave a skladovani, zdravotni a socialni peci a v ostatnich cinnostech. Ve vsech ostatnich sledovanych kategoriich mzdy alespon jedenkrat mezirocne poklesly. Pro zajimavost jsem se podivala, ve kterem roce a odvetvi doslo k nejvetsimu poklesu, bylo to v pojistovnictvi mezi lety 2012 a 2013 a to o 8,83%. Jeste me zajimalo, kdy a kde doslo k nejvetsimu narustu - v IT a to o 15,21% mezi lety 2000 a 2001. Jeste jsem se podivala na celkovy narust za cele sledovane obdobi, tj od roku 2000 do roku 2021. Za 21 let mzdy v jednotlivych oborech vzrostly, nejvice ve zdravotnictvi a to o 294,42%. 


-- UKOL C 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- dle dostupnych dat v tabulce jsem se rozhodla porovnat roky 2006 a 2018

-- predpoklad: muj osobni predpoklad je, ze ceny a vyplaty porostou umerne a vetsi rozdily kolik je mozne si koupit chleba a mleka nebudou.

SELECT
	year_2006.product_type,
	year_2006.avg_price_kc AS 2006_avg_price,
	year_2018.avg_price_kc AS 2018_avg_price,
	year_2006.branch,
	year_2006.avg_month_income_kc AS 2006_avg_monthly_income,
	ROUND (year_2006.avg_month_income_kc / year_2006.avg_price_kc, 2) AS 2006_possibility,
	year_2006.price_unit AS unit,
	year_2018.avg_month_income_kc AS 2018_ang_monthly_income,
	ROUND (year_2018.avg_month_income_kc / year_2018.avg_price_kc, 2) AS 2018_possibility,
	year_2018.price_unit AS unit,
	-- round (avg (year_2006.avg_month_income_kc) / year_2006.avg_price_kc, 2) 2006_possibility_everyone,
	-- round (avg (year_2018.avg_month_income_kc) / year_2018.avg_price_kc, 2) 2018_possibility_everyone,
	ROUND (year_2018.avg_month_income_kc / year_2018.avg_price_kc, 2) - ROUND (year_2006.avg_month_income_kc / year_2006.avg_price_kc, 2) AS difference_2018_and_2006
FROM 
	(
	SELECT
		payroll_year,
		avg_month_income_kc,
		industry_branch_code,
		branch,
		category_code,
		product_type,
		avg_price_kc,
		price_value,
		price_unit
	FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
	WHERE category_code IN (114201,111301)
		AND payroll_year = 2006
 	) year_2006
 LEFT JOIN 
	(
	 SELECT
			payroll_year,
			avg_month_income_kc,
			industry_branch_code,
			branch,
			category_code,
			product_type,
			avg_price_kc,
			price_value,
			price_unit 
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
		WHERE category_code IN (114201,111301)
			AND payroll_year = 2018
	) year_2018
ON 	year_2006.category_code = year_2018.category_code
	AND year_2006.industry_branch_code = year_2018.industry_branch_code
-- WHERE year_2006.product_type = 'Mléko polotučné pasterované'
-- WHERE year_2006.product_type = 'Chléb konzumní kmínový'
-- ORDER BY 2006_possibility DESC 
-- ORDER BY 2018_possibility DESC
-- GROUP BY year_2006.product_type
-- ORDER BY difference_2018_and_2006
 ;

-- zaver: vystupem mam tabulku, kde muzu zjistit, kolik litru mleka a kilogramu chleba si mohou koupit zamestnanci jednotlivych oboru v letech 2006 a 2018 (v pripade, ze se rozhodnou celou vyplatu utratit za mleko a chleb...)v roce 2006 si nejvice mleka a chleba mohou dovolit zamestnanci peneznictvi a pojistovnictvi. V roce 2018 uz si nejvice mohli zakoupit zamestnanci IT. Nejmene si mohou dovolit zamestnanci v ubytovani a stravovani a to jak v roce 2006, tak i v roce 2018. Pokud vypocitam prumer pro vsechna odvetvi, kazdy by si mohl zakoupit 1312,98 kg chleba nebo 1465,73 l mleka z jedne prumerne vyplaty napric odvetvymi. V roce 2018 1365,16 kg chleba nebo 1669,6 l mleka. V prumeru to tedy vypada, ze si jednotlivec muze dovolit vice v roce 2018 nez v roce 2006. Ale pokud to opet rozdelim podle odvetvi, nektera jsou na tom hure nez jina. A vseobecne si lide mohou zakoupit mene chleba, narust cen je vyraznejsi nez u mleka.


-- UKOL C. 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

-- osobne predpoladam, ze vsechny potraviny budou zdrazovat, nemyslim si, ze bude vyraznejsi procentualni narust u nektere z nich

-- data u potravin mam k dispozici mezi lety 2006 - 2018, budu tedy sledovat techto dvanact let

SELECT DISTINCT
	years.product_type,
	years.payroll_year AS years,
	years.avg_price_kc AS avg_price_kc_years,
	years_following.payroll_year AS years_following,
	years_following.avg_price_kc AS avg_price_kc_year_following,
	years.price_value,
	years.price_unit,
	round ( (years_following.avg_price_kc - years.avg_price_kc) * 100 / years.avg_price_kc, 2 ) AS increase_percent,
	CASE WHEN round ( (years_following.avg_price_kc - years.avg_price_kc) * 100 / years.avg_price_kc, 2 ) > 0 THEN 		'increase'
		WHEN round ( (years_following.avg_price_kc - years.avg_price_kc) * 100 / years.avg_price_kc, 2 ) < 0 THEN 			'decrease'
		ELSE 'no_change'
	END AS increase_decrease
	-- count (years.product_type) AS frequency
FROM 
	(
	SELECT DISTINCT 
		payroll_year,
		category_code,
		product_type,
		avg_price_kc,
		price_value,
		price_unit 
	FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
	) years
JOIN 
	(
	SELECT DISTINCT 
		payroll_year,
		category_code,
		product_type,
		avg_price_kc,
		price_value,
		price_unit 
	FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
	) years_following
-- ON years.payroll_year + 1 = years_following.payroll_year
ON years.payroll_year + 12 = years_following.payroll_year
	AND years.category_code = years_following.category_code
	AND years.product_type = years_following.product_type
WHERE years.payroll_year IS NOT NULL
-- GROUP BY years.product_type, increase_decrease 
-- ORDER BY years.product_type, years
ORDER BY increase_percent DESC;

-- zaver: V prubehu dvanacti let doslo ke zdrazeni 24 potravin ze sledovanych 26. u dvou potravin doslo ke zlevneni (a to celkem vyraznemu). K nejpomalejsimu narustu ceny doslo u bananu. Vzhledem k tomu, ze v prubehu let dochazelo ke zdrazovani i zlevnovani jednotlivych potravin, jeste jsem se podivala, kolikrat doslo ke zdrazeni/zlevneni v prubehu let. Banany se celkove osmkrat zlevnily a ctyrikrat zdrazily. Myslim, ze u tohohle ukolu uz by bylo hezke pouzit graf, kde by bylo videt zmeny v prubehu let.


-- UKOL C. 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

SELECT *
FROM v_misa_hribova_final_sql_projest_table_one vmhfspto;

SELECT
	grocery.years,
	grocery.years_following,
	-- income.branch,
	-- income.avg_month_increase_procenta AS payroll_increase,
	round (avg (income.avg_month_increase_procenta), 2) AS avg_income_month_increase_percent,
	grocery.product_type,
	grocery.increase_percent AS prices_increase_percent,
	-- grocery.increase_percent - income.avg_month_increase_procenta AS difference
	round (avg (grocery.increase_percent) - avg (income.avg_month_increase_procenta), 2) AS annual_increase_percent
FROM 
		(
		SELECT
			payroll.payroll_year,
			payroll_following.payroll_year AS payroll_year_following,
			payroll.branch,
			round ((payroll_following.avg_month_income_kc - payroll.avg_month_income_kc) * 100 / 								payroll.avg_month_income_kc, 2) AS avg_month_increase_procenta
		FROM 
			(
			SELECT DISTINCT
			 	payroll_year,
			 	avg_month_income_kc,
			 	industry_branch_code,
			 	branch
			FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
			) payroll
		LEFT JOIN 
			(
			SELECT DISTINCT
			 	payroll_year,
			 	avg_month_income_kc,
			 	industry_branch_code,
			 	branch
			FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
			) payroll_following
		ON payroll.payroll_year + 1 = payroll_following.payroll_year
			AND payroll.industry_branch_code = payroll_following.industry_branch_code
		ORDER BY payroll.industry_branch_code, payroll.payroll_year
		) income
LEFT JOIN 
		(
		SELECT DISTINCT
			years.product_type,
			years.payroll_year AS years,
			years_following.payroll_year AS years_following,
			round ( (years_following.avg_price_kc - years.avg_price_kc) * 100 / years.avg_price_kc, 2 ) AS 						increase_percent
		FROM 
			(
			SELECT DISTINCT 
				payroll_year,
				category_code,
				product_type,
				avg_price_kc,
				price_value,
				price_unit 
			FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
			) years
		JOIN 
			(
			SELECT DISTINCT 
				payroll_year,
				category_code,
				product_type,
				avg_price_kc,
				price_value,
				price_unit 
			FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
			) years_following
		ON years.payroll_year + 1 = years_following.payroll_year
			AND years.category_code = years_following.category_code
			AND years.product_type = years_following.product_type
		WHERE years.payroll_year IS NOT NULL
		ORDER BY years.product_type, years
		) grocery
ON income.payroll_year = grocery.years
	AND income.payroll_year_following = grocery.years_following
WHERE grocery.product_type IS NOT NULL 
GROUP BY grocery.years, grocery.years_following, grocery.product_type
HAVING (avg (grocery.increase_percent) - avg (income.avg_month_increase_procenta)) >= 10;

-- zaver: dle mych vypoctu jsem nenasla rok, kde by rozdil mezi narustem zprumerovanych mezd a narustem prumernych cen byl vysi nez 10%, takze jsem se podivala na prumerny rocni prijem pro vsecny obory a porovnala je s cenami jednotlivych potravin ve sledovanych letech. Tady jsem vyraznejsi skok (vice nez o 10%) zaznamenala celkem 35x.


-- UKOL C 5: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

-- vzhledem k tomu, ze GDP ukazatel je obecny a vztahuje se na veskere obyvatelstvo jednotlivych zemi, tentokrat si to zjednodussim a budu pocitat s prumernou mzdou za vsechna odvetvi v jednotlivych letech a prumernou cenou za vsechny produkty v jednotlivych letech

-- predpoklad je, ze HDP, ceny a platy by mely rust zhruba stejne...vypocitam si mezirocni narust/pokles mezi temito kategoriemi a bude me zajimat nejvetsi a nejmensi rordil v narustu/poklesu.

SELECT
	GDP.years,
	GDP.years_following,
	GDP.GDP_increase_percent_CZ,
	income.avg_monthly_income_increase_percent,
	prices.prices_increase_percent,
	income.avg_monthly_income_increase_percent - GDP.GDP_increase_percent_CZ AS difference_GDP_income_percent,
	prices.prices_increase_percent - GDP.GDP_increase_percent_CZ AS difference_GDP_prices_percent,
	abs ((income.avg_monthly_income_increase_percent - GDP.GDP_increase_percent_CZ) - (prices.prices_increase_percent - 	GDP.GDP_increase_percent_CZ)) AS absolut_percent
FROM 
	(
	SELECT
		GDP_years.payroll_year AS years,
		GDP_years_following.payroll_year AS years_following,
		ROUND ( (GDP_years_following.GDP_Czechia - GDP_years.GDP_Czechia) * 100 / GDP_years.GDP_Czechia, 2 ) AS 				GDP_increase_percent_CZ
	FROM 
		(
		SELECT DISTINCT 
			payroll_year,
			GDP_Czechia 
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
		) GDP_years
	LEFT JOIN 
		(
		SELECT DISTINCT 
			payroll_year,
			GDP_Czechia 
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto 
		) GDP_years_following
	ON GDP_years.payroll_year + 1 = GDP_years_following.payroll_year
	) GDP
LEFT JOIN 
	(
	SELECT
		income_years.payroll_year AS years,
		income_years_following.payroll_year AS years_following,
		round ( (income_years_following.avg_income_CZ - income_years.avg_income_CZ) * 100 / 									income_years.avg_income_CZ, 2 ) AS avg_monthly_income_increase_percent
	FROM 
		(
		SELECT
			payroll_year,
			round ( avg (avg_month_income_kc), 2 ) AS avg_income_CZ
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
		GROUP BY payroll_year 
		) income_years
	LEFT JOIN 
		(
		SELECT
			payroll_year,
			round ( avg (avg_month_income_kc), 2 ) AS avg_income_CZ
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
		GROUP BY payroll_year 
		) income_years_following
	ON income_years.payroll_year + 1 = income_years_following.payroll_year
	) income
ON GDP.years = income.years 
	AND GDP.years_following = income.years_following
LEFT JOIN 
	(
	SELECT
		prices_years.payroll_year AS years,
		prices_years_following.payroll_year AS years_following,
		round ((prices_years_following.prices_years_following - prices_years.prices_years) * 100 / 							prices_years.prices_years, 2) AS prices_increase_percent
	FROM 
		(
		SELECT
			payroll_year,
			sum (avg_price_kc) AS prices_years
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
		GROUP BY payroll_year 
		) prices_years
	LEFT JOIN 
		(
		SELECT
			payroll_year,
			sum (avg_price_kc) AS prices_years_following
		FROM v_misa_hribova_final_sql_projest_table_one vmhfspto
		GROUP BY payroll_year 
		) prices_years_following
	ON prices_years.payroll_year + 1 = prices_years_following.payroll_year
	) prices
ON GDP.years = prices.years 
	AND GDP.years_following = prices.years_following
WHERE prices.prices_increase_percent IS NOT NULL;
	
SELECT *
FROM v_misa_hribova_final_sql_projest_table_one vmhfspto;

-- zaver: v idealnim pripade by procenta ve sloupcich difference_GDP_income_percent a difference_GDP_prices_percent mela byt rovna 0, to by znamenalo, ze vsechno jde postupne. Podivame se na celkovy procentuelni rozdil mezi difference_GDP_income_percent a difference_GDP_prices_percent, cim nizsi cislo, tim stabilnejsi rok, cim vyssi rozdim, tim vetsi vykyv. V tomhle pripade by bylo hezke mit graf, protoze je velky rozdil, pokud vzrostou platy a klesnou ceny a nebo naopak. K nejvyraznejsimu narusru HDP doslo z roku 2006 na 2007, doslo zaroven i k narustu cen a platu. Podle meho vypoctu absolutni rozdil je 0.12, takze se jedna o velice stabilni narust ve vsech kategoriich a dalo by se tedy rict, ze vyraznejsi narust ovlivnil jak platy, tak ceny. Naopak nejvyraznejsi pokled HDP byl z roku 2008 na 2009, tentyz tok doslo k mirnemu narustu prijmu, ale k celkem velkemu poklesu cen, takze absolutni rozdil je temer 9,5%. Z hlediska spotrebitele bych rekla, ze toto je pozitivni zmena. Vubec nejstabilnesim rokem bylo obdobi 2009/2010.

-- tabulka pro porovnani HDP a gini evropskych statu:

CREATE OR REPLACE VIEW v_misa_hribova_final_sql_projest_table_two AS 
SELECT
	economies.YEAR,
	europe.country,
	economies.GDP,
	economies.gini,
	czechia.GDP AS GDP_czechia,
	czechia.gini AS czechia_gini
FROM 
		(
		SELECT
			country
		FROM countries c 
		WHERE continent = 'Europe'
		) europe
	LEFT JOIN 
		(
		SELECT *
		FROM economies e 
		) economies
	ON europe.country = economies.country
	LEFT JOIN 
		(
		SELECT *
		FROM economies e 
		WHERE country = 'Czech Republic'	
		) czechia
	ON economies.YEAR = czechia.YEAR
WHERE economies.YEAR IS NOT NULL 
	AND czechia.GDP IS NOT NULL 
	AND czechia.gini IS NOT NULL 
	AND europe.country != 'Czech Republic'
ORDER BY economies.YEAR;

SELECT *
FROM v_misa_hribova_final_sql_projest_table_two vmhfsptt;


