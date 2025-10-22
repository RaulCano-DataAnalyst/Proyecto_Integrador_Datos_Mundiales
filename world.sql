-- =====================================================================
-- Sección 1: ORIGINAL: contenido tal como se entregó
-- =====================================================================


# Se cambia el estilo de las columnas a snake_case

ALTER TABLE country RENAME COLUMN Name TO country_name;
ALTER TABLE country RENAME COLUMN Continent TO continent;
ALTER TABLE country RENAME COLUMN Region TO region;
ALTER TABLE country RENAME COLUMN SurfaceArea TO surface_area;
ALTER TABLE country RENAME COLUMN IndepYear TO indep_year;
ALTER TABLE country RENAME COLUMN Population TO population;
ALTER TABLE country RENAME COLUMN LifeExpectancy TO life_expectancy;
ALTER TABLE country RENAME COLUMN GNP TO gnp;
ALTER TABLE country RENAME COLUMN GNPOld TO gnp_old;
ALTER TABLE country RENAME COLUMN LocalName TO local_name;
ALTER TABLE country RENAME COLUMN GovernmentForm TO government_form;
ALTER TABLE country RENAME COLUMN HeadOfState TO head_of_state;
ALTER TABLE country RENAME COLUMN Capital TO capital;
ALTER TABLE country RENAME COLUMN Code TO code;
ALTER TABLE country RENAME COLUMN Code2 TO code2;

ALTER TABLE city RENAME COLUMN ID TO id;
ALTER TABLE city RENAME COLUMN Name TO city_name;
ALTER TABLE city RENAME COLUMN CountryCode TO country_code;
ALTER TABLE city RENAME COLUMN District TO district;
ALTER TABLE city RENAME COLUMN Population TO population;

ALTER TABLE countrylanguage RENAME COLUMN CountryCode TO country_code;
ALTER TABLE countrylanguage RENAME COLUMN Language TO language;
ALTER TABLE countrylanguage RENAME COLUMN IsOfficial TO is_official;
ALTER TABLE countrylanguage RENAME COLUMN Percentage TO percentage;
RENAME TABLE countrylanguage TO country_language;

-- PKs
ALTER TABLE country          ADD PRIMARY KEY (code);
ALTER TABLE city             ADD PRIMARY KEY (id);
ALTER TABLE country_language ADD PRIMARY KEY (country_code, language);

-- FKs
ALTER TABLE city
  ADD CONSTRAINT fk_city_country
  FOREIGN KEY (country_code) REFERENCES country(code)
  ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE country_language
  ADD CONSTRAINT fk_lang_country
  FOREIGN KEY (country_code) REFERENCES country(code)
  ON UPDATE CASCADE ON DELETE RESTRICT;
  


/*Ejercicio 1: Escribe una consulta para mostrar el nombre y la población de todos los países del continente europeo.*/

SELECT 
	country_name,
    population
FROM country
WHERE continent = 'Europe';

/*Ejercicio 2: Escribe una consulta para mostrar los nombres y las áreas de superficie de los cinco países más grandes del mundo (en términos de área de superficie).*/

SELECT
	country_name,
    surface_area
FROM country
ORDER BY surface_area DESC
LIMIT 5;

/* Ejercicio 3: Escribe una consulta para calcular la población total de todos los países de cada continente y mostrar el resultado junto con el nombre del continente*/

SELECT
	continent,
    SUM(population) AS total_population
FROM country
GROUP BY continent
ORDER BY total_population DESC;

/*Ejercicio 4: Escribe una consulta para mostrar el nombre de las ciudades y la población de todos los países de Europa, ordenados por población de la ciudad 
de manera descendente.*/

SELECT
	ci.city_name AS city,
    ci.population,
    co.country_name AS country
FROM city ci 
LEFT JOIN country co ON ci.country_code = co.code
WHERE co.continent = 'Europe'
ORDER BY ci.population DESC;

/*Ejercicio 5: Actualiza la población de China (código de país 'CHN') a 1500000000 (1.5 mil millones).*/

-- Demo de actualización SIN dejar cambios
START TRANSACTION;

-- la demo: subir a 1.500.000.000
UPDATE country
SET population = 1500000000
WHERE code = 'CHN';

-- verificación dentro de la transacción
SELECT code, country_name, population
FROM country
WHERE code = 'CHN';

-- cancelar cambios y dejar todo como antes
ROLLBACK;

-- comprobación final (debe volver al valor original)
SELECT code, country_name, population
FROM country
WHERE code = 'CHN';


/* Ejercicio 6: Consulta los idiomas oficiales en Sudamérica y gráfica cuántos países comparten cada idioma oficial.*/

SELECT
	cl.language,
    COUNT(*) AS num_countries
FROM country_language cl 
LEFT JOIN country co ON cl.country_code = co.code
WHERE co.continent = 'South America' AND cl.is_official = 'T'
GROUP BY cl.language
ORDER BY num_countries DESC;

/*Ejercicio 7: Obtén todos los países con esperanza de vida > 75 años y crea un histograma de su distribución.*/

SELECT
	country_name AS country,
    life_expectancy
FROM country
WHERE life_expectancy > 75
ORDER BY life_expectancy DESC;


/*Ejercicio 8: Calcula la densidad poblacional de todos los países y muestra un gráfico de dispersión entre superficie y población con el color como función del continente.*/

SELECT
	country_name AS country,
    population,
    surface_area,
    (population / surface_area) AS density,
    continent
FROM country
WHERE population > 0 AND surface_area > 0
ORDER BY density DESC;


/* Ejercicio 9: Visualiza las ciudades con más de 5 millones de habitantes en un gráfico horizontal de barras.*/

SELECT
	city_name AS city,
    population
FROM city
WHERE population > 5000000
ORDER BY population DESC;

/* Ejercicio 10: Gráfica cuántos idiomas se hablan por continente usando un gráfico de pastel.*/

SELECT
	co.continent,
	COUNT(cl.language) AS num_languages
FROM country_language cl
LEFT JOIN country co ON cl.country_code = co.code
GROUP BY co.continent
ORDER BY num_languages DESC;

/*Análisis Estadístico*/

/*Población total por continente*/

SELECT 
    continent, 
    SUM(population) AS num_population 
FROM country 
WHERE population != 0 
GROUP BY continent 
ORDER BY num_population DESC;

/*Correlación entre superficie, población y esperanza de vida*/

SELECT 
    country_name AS country,
    surface_area,
    population,
    life_expectancy
FROM country
WHERE surface_area > 0 AND population > 0 AND life_expectancy IS NOT NULL;

/*Top países por densidad poblacional o menor esperanza de vida*/

SELECT 
    country_name AS country,
    population,
    surface_area,
    life_expectancy,
    (population / surface_area) AS density
FROM country
WHERE surface_area > 0 AND population > 0 AND life_expectancy IS NOT NULL;


-- =====================================================================
-- Sección 2: MEJORAS: índices + vistas
-- =====================================================================

-- 1) ÍNDICES RECOMENDADOS

CREATE INDEX idx_city_countrycode ON city (country_code);
CREATE INDEX idx_country_language_countrycode ON country_language (country_code);
CREATE INDEX idx_country_continent ON country (continent);
CREATE INDEX idx_country_name      ON country (country_name);

-- 2) VISTAS ÚTILES

-- 2.1 Población total por continente

CREATE OR REPLACE VIEW v_population_by_continent AS
SELECT continent, SUM(population) AS total_population
FROM country
GROUP BY continent;

-- 2.2 Densidad poblacional por país (con control división por cero)

CREATE OR REPLACE VIEW v_density AS
SELECT country_name AS country,
       population,
       surface_area,
       CASE WHEN surface_area > 0 THEN population / surface_area ELSE NULL END AS density,
       continent
FROM country;

-- 2.3 Idiomas oficiales por continente (conteo de países)

CREATE OR REPLACE VIEW v_official_languages_by_continent AS
SELECT co.continent AS continent,
       cl.language  AS language,
       COUNT(*)     AS num_countries
FROM country_language cl
JOIN country co ON cl.country_code = co.code
WHERE cl.is_official = 'T'
GROUP BY co.continent, cl.language;

-- 2.4 Países por continente (helper para cobertura)

CREATE OR REPLACE VIEW v_countries_per_continent AS
SELECT continent, COUNT(DISTINCT code) AS countries_in_continent
FROM country
GROUP BY continent;

-- 2.5 Cobertura de idiomas oficiales por continente (% de países)

CREATE OR REPLACE VIEW v_official_language_coverage AS
SELECT lbc.continent,
       lbc.language,
       lbc.num_countries,
       cpc.countries_in_continent,
       ROUND(100.0 * lbc.num_countries / cpc.countries_in_continent, 2) AS coverage_pct
FROM v_official_languages_by_continent lbc
JOIN v_countries_per_continent cpc
  ON lbc.continent = cpc.continent
ORDER BY lbc.continent, lbc.num_countries DESC, lbc.language;

