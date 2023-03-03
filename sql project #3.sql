-- ukol c. 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

-- spojila jsem si dve stejne tabulky na zaklade roku mereni (v druhe tabulce jsem vybrala plus jeden rok, podobne jako v predchazejicim ukolu)
-- ze dvou avg hodnot jsem si vypocitala mezirocni narust/pokles
SELECT 
	Y.category_code,
	cpc.name,
	cpc.price_value,
	cpc.price_unit,
	YEAR (Y.date_from) AS rok,
	ROUND (( Y.prumer_rok - Y_plus_one.prumer_rok_predchozi )* 100 /Y_plus_one.prumer_rok_predchozi , 2 ) AS 			procentualni_narust,
	Y.prumer_rok - Y_plus_one.prumer_rok_predchozi AS mezirocni_rozdil
FROM 
	(
	SELECT 
		cp.category_code,
		round (avg (cp.value), 2) AS prumer_rok,
		cp.date_from 
	FROM czechia_price cp 
	GROUP BY cp.category_code, YEAR (cp.date_from)
	) Y
LEFT JOIN
	(
	SELECT 
		cp.category_code,
		round (avg (cp.value), 2) AS prumer_rok_predchozi,
		cp.date_from 
	FROM czechia_price cp 
	GROUP BY cp.category_code, YEAR (cp.date_from)
	) Y_plus_one
	ON Y.category_code = Y_plus_one.category_code
		AND YEAR (Y.date_from) = YEAR (Y_plus_one.date_from) +1
LEFT JOIN czechia_price_category cpc 
	ON Y.category_code = cpc.code
WHERE ROUND (( Y.prumer_rok - Y_plus_one.prumer_rok_predchozi )* 100 /Y_plus_one.prumer_rok_predchozi , 2 ) IS NOT NULL

-- kontrolovala jsem si spravnost vypocitaneho prumeru
SELECT *,
	avg (value)
FROM czechia_price cp 
WHERE category_code = 117101
	AND YEAR (date_from) = 2006
ORDER BY date_from

-- finalni dotaz
CREATE OR REPLACE VIEW v_misa_hribova_mezirocni_narust_3 as
SELECT 
	cpc.code AS code,
	cpc.name AS name,
	cpc.price_value AS unit,
	cpc.price_unit AS price,
	YEAR (Y.date_from) AS rok,
	ROUND (( Y.prumer_rok_kc - Y_plus_one.prumer_rok_predchozi_kc )* 100 /Y_plus_one.prumer_rok_predchozi_kc , 2 ) AS 			mezirocni_rozdil_procenta,
	prumer_rok_kc,
	prumer_rok_predchozi_kc,
	Y.prumer_rok_kc - Y_plus_one.prumer_rok_predchozi_kc AS mezirocni_rozdil_kc
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
		round (avg (cp.value), 2) AS prumer_rok_predchozi_kc,
		cp.date_from 
	FROM czechia_price cp 
	GROUP BY cp.category_code, YEAR (cp.date_from)
	) Y_plus_one
	ON Y.category_code = Y_plus_one.category_code
		AND YEAR (Y.date_from) = YEAR (Y_plus_one.date_from) +1
LEFT JOIN czechia_price_category cpc 
	ON Y.category_code = cpc.code
WHERE ROUND (( Y.prumer_rok_kc - Y_plus_one.prumer_rok_predchozi_kc )* 100 /Y_plus_one.prumer_rok_predchozi_kc , 2 ) IS NOT NULL;


-- zaver: tentokrat jsem si ve finalnim pohledu nechala o neco vice dat. Prislo mi zajimave srovnat nejen procentualni narust/pohles, ale zaroven i ceny jednotlivych potravin. Puvodne jsem chtela porovnat pouze prvni a posledni rok sledovaneho obdobi, ale nakonec mi porislo zajimave se podivat na to, jak se ceny menily v prubehu let postupne. Muj osobni predpoklad byl, ze ceny vsech potravin budou stoupat, bylo pro me velkym prekvapenim, ze nektere ceny klesaly.

SELECT *
FROM v_misa_hribova_mezirocni_narust_3 vmhmn 
ORDER BY mezirocni_rozdil_procenta desc

-- nejvice zdrazily papriky a to v roce 2007 o temer 95% oproti predchozimu roku. K nejvetsimu zlevneni doslo u rajskych jablek a to taktez v roce 2007 o cca 30%. Ze zajimavosti jsem se u techto dvou kategorii chtela podivat na rozdil mezi prvnim a poslednim rokem sledovaneho obdobi...a to se mi nepovedlo. Respektive povedlo tak, ze jsem si v predchozim dotazu upravila podminku v join, kde jsem spojovala roky a misto +1 jsem napsala YEAR (Y.date_from) +12. To bohuzel znamena, ze toto nemuzu vyfiltrovat z pohledu, ktery jsem vytvorila, ale porad mohu odeslat pohled novy.

-- nakonec jsem se jeste zamotala do sloupecku...mela jsem zmatek v tom, co je predchazejici, nasledujici +1 atd. Takze jsem si jeste jednou prejmenovala sloupce a preulozila pohled.

-- nakonec jsem tedy byla schopna zjistit, jaky byl narust/pokles cen mezi prvnim a poslednim rokem. U paprik doslo mezi lety 2006 a 2018 k celkovemu narustu o vice nez 71%. U jablek naopak k celkovemu zlevneni a to o cca 23%. Muj osobni predpoklad v tomto pripade byl, ze mezi lety 2006 a 2018 dojde ke zdrazeni u vsech potravin. Bylo pro me prekvapenim, ze jablka a cukr byla v roce 2018 levnejsi nez v roce 2006.

SELECT *
FROM v_misa_hribova_mezirocni_narust_3 vmhmn 
WHERE code = 117103
ORDER BY rok 

SELECT 
	cpc.code AS code,
	cpc.name AS name,
	cpc.price_value AS unit,
	cpc.price_unit AS price,
	YEAR (Y.date_from) AS rok,
	YEAR (YY.date_from) AS rok_nasledujici,
	ROUND (( YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc   )* 100 /Y.prumer_rok_kc , 2 ) AS 			mezirocni_rozdil_procenta,
	prumer_rok_kc,
	prumer_rok_nasledujici_kc,
	YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc AS mezirocni_rozdil_kc
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
		AND YEAR (YY.date_from)  = YEAR (Y.date_from) +12
LEFT JOIN czechia_price_category cpc 
	ON Y.category_code = cpc.code
WHERE ROUND (( YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc   )* 100 /Y.prumer_rok_kc , 2 ) IS NOT NULL;

CREATE OR REPLACE VIEW v_misa_hribova_mezirocni_narust_3 AS
SELECT 
	cpc.code AS code,
	cpc.name AS name,
	cpc.price_value AS unit,
	cpc.price_unit AS price,
	YEAR (Y.date_from) AS rok,
	YEAR (YY.date_from) AS rok_nasledujici,
	ROUND (( YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc   )* 100 /Y.prumer_rok_kc , 2 ) AS 			mezirocni_rozdil_procenta,
	prumer_rok_kc,
	prumer_rok_nasledujici_kc,
	YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc AS mezirocni_rozdil_kc
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
WHERE ROUND (( YY.prumer_rok_nasledujici_kc - Y.prumer_rok_kc   )* 100 /Y.prumer_rok_kc , 2 ) IS NOT NULL;

SELECT *
FROM v_misa_hribova_mezirocni_narust_3 vmhmn 
WHERE code = 117103
ORDER BY rok 
	

	
