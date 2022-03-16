SELECT * FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT * FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4

-- Select the data I am going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Compare Total Cases vs Total Deaths in UnitedStates
-- Shows probability of dying if you contract COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2

-- Compare Total Cases vs Population in UnitedStates
-- Shows percentage of population contracted COVID
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS ContractionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2

-- Shows which countries have the highest infection rate compared to population overall
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population) * 100 AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectedPopulationPercentage desc

-- Shows which countries have the highest death count
-- Casted total_deaths as INT because the variable type in the data was nvarchar and giving incorrect numbers
-- Used "continent IS NOT NULL" because the query was returning redundent data and values that were not related to countries
SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- Shows TotalDeathCount by continent
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Shows global cases, deaths, and death per case percentage
SELECT SUM(new_cases) AS Cases, SUM(cast(new_deaths AS INT)) AS Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathCasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Show TotalPopulation vs NewVaccinationsPerDay
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(cast(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths
JOIN PortfolioProject..CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	and CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL
ORDER BY 2, 3

-- CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingCountPeopleVaccinated)
as
(
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(cast(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths
JOIN PortfolioProject..CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	and CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL
)

SELECT *, (RollingCountPeopleVaccinated/population) * 100 
FROM PopvsVac

-- Create temporary table for PercentPopulationVaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCountPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(cast(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths
JOIN PortfolioProject..CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	and CovidDeaths.date = CovidVaccinations.date

SELECT *, (RollingCountPeopleVaccinated/population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

-- Create view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(cast(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingCountPeopleVaccinated
FROM PortfolioProject..CovidDeaths
JOIN PortfolioProject..CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	and CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated