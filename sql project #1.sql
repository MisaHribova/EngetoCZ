-- UKOL C 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT *
FROM czechia_payroll cp 
WHERE industry_branch_code = 'A';

SELECT x.* FROM Engeto_CZ.czechia_payroll_calculation x;

-- rozdil mezi fyzickym a prepoctenymn poctem zamestnancu?????
-- fte - budu pracovat s prepoctenym poctem zamestnancu (prepoctene osoby na plnou pracovni dobu) - vysledek bude vice presny, vzhledem k tomu, ze nekteta odvetvi mohou mit vice castecnych uvazku nez jina

-- nejdrive jsem si spojila vsechny tabulky (To jenom sama pro sebe, aby zjistila, co se deje. Vyzkousela jsem menit odvetvi, rok, kvartal atd, abych se zorientovala v datech, ktera vidim.)

SELECT 
	cp.value,
	cp.payroll_quarter,
	cp.calculation_code,
	cpc.name,
	cp.industry_branch_code,
	cpib.name,
	cp.unit_code,
	cpu.name,
	cp.value_type_code,
	cpvt.name 
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_calculation cpc
	ON cp.calculation_code = cpc.code 
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON cp.industry_branch_code = cpib.code 
LEFT JOIN czechia_payroll_unit cpu 
	ON cp.unit_code = cpu.code 
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code 
WHERE cp.payroll_year = 2020 AND industry_branch_code IN ('e','s')


-- vypocet
-- spocitala jsem si prumernou rocni mzdu v kazdem odvetvi a rozdelila do skupin podle odvetvi a roku. mela jsem nekolik industry brach code null, zbavila jsem se jich

SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok,
		cpu.name AS kc,
		cpib.name AS odvetvi
	FROM czechia_payroll cp 
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code 
	LEFT JOIN czechia_payroll_industry_branch cpib 
		ON cp.industry_branch_code = cpib.code 
	LEFT JOIN czechia_payroll_unit cpu 
		ON cp.unit_code = cpu.code 
	LEFT JOIN czechia_payroll_value_type cpvt 
		ON cp.value_type_code = cpvt.code 
	WHERE cpc.code = 200 AND cpu.code = 200 AND cpvt.code = 5958 AND cp.industry_branch_code IS NOT NULL
	GROUP BY cp.industry_branch_code, cp.payroll_year;

-- spojila jsem dve stejne tabulky podle branch code a payroll year, kde jsem payroll year posunula o radek abych od sebe mohla odecist v jednom roce od roku nasledujiciho

SELECT *,
	b.prumer_rok - a.prumer_rok
FROM 
	(
	SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok,
		cpib.name 
	FROM czechia_payroll cp 
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code 
	LEFT JOIN czechia_payroll_industry_branch cpib 
		ON cp.industry_branch_code = cpib.code 
	LEFT JOIN czechia_payroll_unit cpu 
		ON cp.unit_code = cpu.code 
	LEFT JOIN czechia_payroll_value_type cpvt 
		ON cp.value_type_code = cpvt.code 
	WHERE cpc.code = 200 AND cpu.code = 200 AND cpvt.code = 5958 AND cp.industry_branch_code IS NOT NULL
	GROUP BY cp.industry_branch_code, cp.payroll_year 
	) a	
LEFT JOIN
	(
	SELECT
		cp.payroll_year,
		sum (value) AS prumer_rok,
		cpib.name
	FROM czechia_payroll cp 
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code 
	LEFT JOIN czechia_payroll_industry_branch cpib 
		ON cp.industry_branch_code = cpib.code 
	LEFT JOIN czechia_payroll_unit cpu 
		ON cp.unit_code = cpu.code 
	LEFT JOIN czechia_payroll_value_type cpvt 
		ON cp.value_type_code = cpvt.code 
	WHERE cpc.code = 200 AND cpu.code = 200 AND cpvt.code = 5958 AND cp.industry_branch_code IS NOT NULL
	GROUP BY cp.industry_branch_code, cp.payroll_year 
	) b
	ON a.payroll_year = b.payroll_year - 1 AND a.name = b.name

-- a tady mi nekdo chytre poradil optimalizovat joiny...tohle probehlo formou pokus omyl
	
	SELECT
	Y.payroll_year,
	cpib.name,
	Y_nasledujici.prumer_rok - Y.prumer_rok AS mezirocni_rozdil
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
	ON Y.industry_branch_code = cpib.code;

-- rok 2020 ma hodne velky propad v prumernych mzdach, rok 2021 u nekterych odvetvi chybejici hodnoty 
-- pozila jsem dotaz, ktery jsem si vytvorila na zacatku, abych se zorientovala v tabulkach a vyfiltrovala si data pouze k letum 2020 a 2021
-- chybejici hodnoty u 2021, protoze neexistuje nasledujici sloupec s rokem 2022, takze dbeaver nedokaze vypocitat nasledujici podmiinku Y_nasledujici.prumer_rok - Y.prumer_rok (poterbuji se toho zbavit)
-- extreme zaporne hodnoty u roku 2020 jsou zpusobene tim, ze v roce 2021 mam data poze ke dvema kvartalum, takze se toho zbavim take.

SELECT 
	cp.value,
	cp.payroll_quarter,
	cp.calculation_code,
	cpc.name,
	cp.industry_branch_code,
	cpib.name,
	cp.unit_code,
	cpu.name,
	cp.value_type_code,
	cpvt.name 
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_calculation cpc
	ON cp.calculation_code = cpc.code 
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON cp.industry_branch_code = cpib.code 
LEFT JOIN czechia_payroll_unit cpu 
	ON cp.unit_code = cpu.code 
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code 
WHERE cp.calculation_code = 200 
	AND cp.unit_code = 200 
	AND cp.value_type_code = 5958
	AND cp.payroll_year = 2021

-- finalni dotaz:
CREATE OR REPLACE VIEW v_misa_hribova_mzdy_rodil_2000_to_2020 as 
SELECT
	Y.payroll_year,
	Y.industry_branch_code,
	cpib.name,
	Y_nasledujici.prumer_rok - Y.prumer_rok AS mezirocni_rozdil
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
WHERE Y.payroll_year NOT IN (2020,2021);
	-- AND Y_nasledujici.prumer_rok - Y.prumer_rok LIKE '-%';
	
-- zaver:
-- V prubehu let nepretrzite rostou mzdy pouze v nasledujicich odvetvi: zpracovatelsky prumysl, zdravotni a socialni pece a ostatni cinnosti. Ve vsech ostatnich odvetvi alespon jedenkrat mezirocne mzdy poklesly. Muj predpoklad byl, ze k nejakemu poklesu mezd dojde v letech 2008 a 2009. Ulozila jsem si view a ruzne filtrovala vysledky. K nejvice poklesum doslo v roce 2012. K nejvetsimu poklesu doslo v r 2012 v odvetvi peneznictvi a pojistovnictvi, a to o celych 17936 kc. K naopak nejvetsimu narustu doslo v roce 2018 o 17204 kc a to taktez v peneznictvi a pojistovnictvi. Vseobecne by se dalo rici, ze ve vsech odvetvich mzdy v prubehu let vzrostly. Nejmensi narust zaznamenalo ubytovani, stravovani a pohostinstvi, nejvetsi pak informacni a komunikacni cinnost.


		
	
SELECT *
FROM v_misa_hribova_mzdy_rodil_2000_to_2020 vmhmrt

SELECT *,
	sum (mezirocni_rozdil) AS celkovy_narust
FROM v_misa_hribova_mzdy_rodil_2000_to_2020 vmhmrt
GROUP BY industry_branch_code 
ORDER BY celkovy_narust DESC 
