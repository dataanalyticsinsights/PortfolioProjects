USE PortfolioProject;

-- View CovidDeaths table
SELECT * 
FROM CovidDeaths
ORDER BY location, date;

SELECT * 
FROM CovidDeaths
Where continent is not null
ORDER BY 3,4

-- View CovidVaccinations table
SELECT * 
FROM CovidVaccinations
ORDER BY location, date;

-- Select specific columns
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Where continent is not null
ORDER BY location, date;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, 
       (total_deaths / NULLIF(total_cases,0)) * 100 AS DeathPercentage
FROM CovidDeaths
ORDER BY location, date;

-- Count total rows
SELECT COUNT(*) AS TotalRows
FROM CovidDeaths;

-- See all unique locations
SELECT DISTINCT location
FROM CovidDeaths
ORDER BY location;

-- Filter for Uganda 
SELECT location, date, total_cases, total_deaths,
       (total_deaths / NULLIF(total_cases,0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Uganda%'
and continent is not null
ORDER BY location, date;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
SELECT location, date, population,total_cases, 
       (total_cases / population) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Uganda%'
ORDER BY location, date;

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population,
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing Countries with Highest Death Count per Population
SELECT location, 
       MAX(CAST(total_deaths AS DOUBLE)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Let's break down things by continent
SELECT continent, 
       MAX(CAST(total_deaths AS DOUBLE)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing Continents with the Highest Death Count per population
SELECT continent,
       MAX(CAST(total_deaths AS DOUBLE)) AS TotalDeathCount,
       MAX(CAST(total_deaths AS DOUBLE) / CAST(population AS DOUBLE)) * 100 AS DeathPercentPopulation
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathPercentPopulation DESC;

-- Global Numbers 
SELECT date,
       SUM(CAST(new_cases AS DOUBLE)) AS TotalCases,
       SUM(CAST(new_deaths AS DOUBLE)) AS TotalDeaths,
       (SUM(CAST(new_deaths AS DOUBLE)) / NULLIF(SUM(CAST(new_cases AS DOUBLE)),0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Overall 
SELECT 
    SUM(CAST(new_cases AS DOUBLE)) AS TotalCases,
    SUM(CAST(new_deaths AS DOUBLE)) AS TotalDeaths,
    (SUM(CAST(new_deaths AS DOUBLE)) / NULLIF(SUM(CAST(new_cases AS DOUBLE)),0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL;


SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- Looking at Total Population vs Population
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS DOUBLE)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- USE CTE 
WITH PopvsVac AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS DOUBLE)) 
            OVER (
                PARTITION BY dea.location 
                ORDER BY dea.date
            ) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / CAST(population AS DOUBLE)) * 100 AS PercentPeopleVaccinated
FROM PopvsVac
ORDER BY location, date;

-- TEMP TABLE
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population DOUBLE,
    New_vaccinations DOUBLE,
    RollingPeopleVaccinated DOUBLE
);
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    CAST(dea.population AS DOUBLE),
    CAST(vac.new_vaccinations AS DOUBLE),
    SUM(CAST(vac.new_vaccinations AS DOUBLE)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date)
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Creating View to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    CAST(dea.population AS DOUBLE) AS population,
    CAST(vac.new_vaccinations AS DOUBLE) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS DOUBLE)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM PortfolioProject.percentpopulationvaccinated;
