-- Looking at the covid deaths data
SELECT *
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths
FROM public."CovidDeaths"
ORDER BY 1, 2;

-- Looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE location LIKE '%States%'
ORDER BY 1, 2;

-- Percentage of population got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS covid_percentage
FROM public."CovidDeaths"
WHERE location LIKE 'Vietnam'
ORDER BY 1, 2;

-- Find countries with the highest infection rate compared to poplation
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM public."CovidDeaths"
GROUP BY location, population
ORDER BY 4 DESC;

-- Highest infection rate ordered by date
SELECT location, population, date, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM public."CovidDeaths"
GROUP BY location, population, date
ORDER BY 5 DESC;

-- The countries with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS totaldeathcount
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

-- Death count by continent
SELECT continent, MAX(cast(total_deaths as int)) AS max_death_count
FROM public."CovidDeaths"
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC;

-- Death count by specific continents
SELECT location, SUM(cast(new_deaths AS int)) AS total_deaths_count
FROM public."CovidDeaths"
WHERE continent is null
AND location in ('Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC;

-- Global data
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS deathpercentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL AND new_cases > 0
-- GROUP BY date
ORDER BY 1, 2;

-- Looking at the covid vaccinations data and join 2 tables 

WITH PopVsVac (continent, location, date, population, new_vaccinations, rollongpeoplevaccinated)
AS (
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (
		PARTITION BY death.location
		ORDER BY death.location, death.date) AS rollingpeoplevaccinated
FROM public."CovidVaccinations" vac
JOIN public."CovidDeaths" death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null
	)
SELECT * FROM PopVsVac;


-- TEMP TABLE
DROP TABLE if exists PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated 
(
continent character varying,
location character varying,
date date,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (
		PARTITION BY death.location
		ORDER BY death.location, death.date) AS rollingpeoplevaccinated
FROM public."CovidVaccinations" vac
JOIN public."CovidDeaths" death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null;

SELECT *, (rollingpeoplevaccinated/population)*100 AS roll_pp_vac_rate
FROM PercentPopulationVaccinated;


-- Creating view to store data for visualization
CREATE VIEW percent_pop_vac AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (
		PARTITION BY death.location
		ORDER BY death.location, death.date) AS rollingpeoplevaccinated
FROM public."CovidVaccinations" vac
JOIN public."CovidDeaths" death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null;

SELECT * FROM percent_pop_vac;
