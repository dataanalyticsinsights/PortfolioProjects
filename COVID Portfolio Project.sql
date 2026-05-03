-- ProjectTitle: COVID-19 Data Analysis Using SQL. MySQL
-- ProblemStatement: The goal of this project was to clean, analyze, and extract meaningful insights about infection rates, death rates, and vaccination progress across countries and continents.
-- Approach:Instead of jumping straight into analysis, I structured the work in 4 stages: Data Understanding, Data Cleaning, Data Transformation & Analysis, Data Structuring for Reuse

USE PortfolioProject;
-- Initial exploration of datasets to understand structure and columns
-- View CovidDeaths table
SELECT * 
FROM CovidDeaths
ORDER BY location, date;

-- View CovidVaccinations table
SELECT * 
FROM CovidVaccinations
ORDER BY location, date;

-- Selecting relevant columns and removing non-country records
-- Select specific columns
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Where continent is not null
ORDER BY location, date;

-- Calculating death percentage to understand severity of COVID-19 per country
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

-- Analyzing Uganda as a case study to track infection and death trends
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

-- Breaking down things by continent
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

-- Aggregating global daily cases and deaths to analyze overall pandemic trends
SELECT date,
       SUM(CAST(new_cases AS DOUBLE)) AS TotalCases,
       SUM(CAST(new_deaths AS DOUBLE)) AS TotalDeaths,
       (SUM(CAST(new_deaths AS DOUBLE)) / NULLIF(SUM(CAST(new_cases AS DOUBLE)),0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Calculating overall global totals for cases, deaths, and death percentage
SELECT 
    SUM(CAST(new_cases AS DOUBLE)) AS TotalCases,
    SUM(CAST(new_deaths AS DOUBLE)) AS TotalDeaths,
    (SUM(CAST(new_deaths AS DOUBLE)) / NULLIF(SUM(CAST(new_cases AS DOUBLE)),0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

-- Combining deaths and vaccination data to enable deeper analysis
SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- Calculating cumulative vaccinations per country over time using window functions
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

-- Using CTE to simplify rolling vaccination analysis and calculate percentage of population vaccinated 
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(NULLIF(NULLIF(vac.new_vaccinations, ''), 'NULL') AS DOUBLE)) 
            OVER (
                PARTITION BY dea.location 
                ORDER BY dea.location, dea.date
            ) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / CAST(NULLIF(NULLIF(Population, ''), 'NULL') AS DOUBLE)) * 100 AS PercentPeopleVaccinated
FROM PopvsVac
ORDER BY Location, Date;

-- TEMP TABLE. Storing intermediate vaccination calculations for further analysis and reuse
USE PortfolioProject;

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date TEXT,
    Population DOUBLE,
    New_vaccinations DOUBLE,
    RollingPeopleVaccinated DOUBLE
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    CAST(NULLIF(NULLIF(dea.population, ''), 'NULL') AS DOUBLE) AS Population,
    CAST(NULLIF(NULLIF(vac.new_vaccinations, ''), 'NULL') AS DOUBLE) AS New_vaccinations,
    SUM(CAST(NULLIF(NULLIF(vac.new_vaccinations, ''), 'NULL') AS DOUBLE)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS PercentPeopleVaccinated
FROM PercentPopulationVaccinated
ORDER BY Location, Date;

-- Creating a reusable view for visualization tool such as Tableau
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



