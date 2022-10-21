-- Ananlyzing total cases vs total deaths
-- Shows likelihood of dying if you contracted covid in Canada on a certain date


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM "CovidDeaths"
WHERE location like '%Canada%'
order by 1,2;


-- Analyzing total cases vs population
-- Shows what percentage of the population of Canada have contracted covid


SELECT location, date, population, total_cases, (total_cases/population)*100 as CasesRatio
FROM "CovidDeaths"
WHERE location like '%Canada%'
order by 1,2;


-- Analyzing countries with highest infection rate compared to their population


SELECT location, population, MAX(total_cases) as HighestCaseCount, MAX((total_cases/population))*100 as HighestCaseRatio
FROM "CovidDeaths"
WHERE total_cases IS NOT NULL
AND continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestCaseRatio desc;


-- Showing countries with highest death count per population


SELECT location, MAX(total_deaths) as TotalDeathCount
FROM "CovidDeaths"
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc;


-- Showing Continents with highest death count


SELECT location, MAX(total_deaths) as TotalDeathCount
FROM "CovidDeaths"
WHERE continent IS NULL
AND total_deaths IS NOT NULL
AND location NOT LIKE '%income'
GROUP BY location
ORDER BY TotalDeathCount desc;


-- Global Analysis of covid deaths by date


SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathRatio
FROM "CovidDeaths"
WHERE continent IS NOT NULL
AND total_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2;


-- Analyzing aggregate vaccinations across the world using CTE


WITH PopvsVac (continent, location, date, population, new_vaccinations, aggregate_Vaccinations)
as
(
SELECT ded.continent, ded.location, ded.date, ded.population, vac.new_vaccinations, 
 SUM(vac.new_vaccinations) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) as aggregate_vaccinations
FROM "CovidDeaths" ded
JOIN "CovidVaccinations" vac
	ON ded.location = vac.location
	AND ded.date = vac.date
WHERE ded.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
)

SELECT *, (aggregate_vaccinations/population)*100 as aggregate_vaccination_ratio
FROM PopvsVac


-- Analyzing aggregate vaccinations across the world using temporary table


DROP TABLE IF EXISTS percent_vaccinated;

CREATE TABLE percent_vaccinated
(
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
aggregate_vaccinations NUMERIC
);

INSERT INTO percent_vaccinated(
SELECT ded.continent, ded.location, ded.date, ded.population, vac.new_vaccinations, 
 SUM(vac.new_vaccinations) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) as aggregate_vaccinations
FROM "CovidDeaths" ded
JOIN "CovidVaccinations" vac
	ON ded.location = vac.location
	AND ded.date = vac.date
WHERE ded.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
);

SELECT *, (aggregate_vaccinations/population)*100 as aggregate_vaccination_ratio
FROM percent_vaccinated;


-- Creating views for data visualization


DROP VIEW IF EXISTS covid_cases_canada;
CREATE VIEW covid_cases_canada AS
SELECT location, date, population, total_cases, (total_cases/population)*100 as case_ratio
FROM "CovidDeaths"
WHERE location like '%Canada%'
order by 1,2;


DROP VIEW IF EXISTS country_infection_rate;
CREATE VIEW country_infection_rate AS
SELECT location, population, MAX(total_cases) as HighestCaseCount, MAX((total_cases/population))*100 as highest_case_ratio
FROM "CovidDeaths"
WHERE total_cases IS NOT NULL
AND continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_case_ratio desc;


DROP VIEW IF EXISTS country_death_count;
CREATE VIEW country_death_count as
SELECT location, MAX(total_deaths) as total_death_count
FROM "CovidDeaths"
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc;


DROP VIEW IF EXISTS covid_deaths;
CREATE VIEW covid_deaths as
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_ratio
FROM "CovidDeaths"
WHERE continent IS NOT NULL
AND total_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2;


DROP VIEW IF EXISTS percent_vaccinated;
CREATE VIEW percent_vaccinated as
SELECT ded.continent, ded.location, ded.date, ded.population, vac.new_vaccinations, 
 SUM(vac.new_vaccinations) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) as aggregate_vaccinations
FROM "CovidDeaths" ded
JOIN "CovidVaccinations" vac
	ON ded.location = vac.location
	AND ded.date = vac.date
WHERE ded.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
