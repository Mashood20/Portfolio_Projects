
SELECT * 
FROM Portfolio1..CovidDeaths
-- WHERE continent is not null
ORDER BY 3, 4

SELECT * 
FROM Portfolio1..CovidVaccinations
ORDER BY 3, 4

SELECT Location, Date, total_cases, new_cases, total_deaths, population 
FROM Portfolio1..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Looking at total cases vs total deaths.
-- Shows likelihood of dying if get covid  in your country. 
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolio1..CovidDeaths
WHERE Location like '%states%'
AND continent is not null
ORDER BY 1, 2

-- Looking at Total cases vs Population
-- Shows what percentage of population got covid
SELECT Location, Date, total_cases, Population, (total_cases/Population)*100 as CasesPercentage
FROM Portfolio1..CovidDeaths
WHERE Location like '%states%'
AND continent is not null
ORDER BY 1, 2

-- Looking at countries with highest Infection rate compared to population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/Population)*100 as HighestPercentageAffected
FROM Portfolio1..CovidDeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY HighestPercentageAffected DESC


-- Looking at countries with highest Death rate compared to population
SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM Portfolio1..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Lets break things down by continent
-- Showing continets with highest death count
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM Portfolio1..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Total New deaths and Total new cases everyday and the percentage of  total new deaths compared to total new cases

SELECT Date, SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT)) * 100 
    END AS PercentageOfNewDeaths
FROM Portfolio1..CovidDeaths
GROUP BY Date
ORDER BY Date


-- Looking at population and people got vaccinated

SELECT  dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as Int)) OVER (partition by dea.Location order by dea.Date) as RollingPeopleVaccinated 
FROM Portfolio1..CovidDeaths dea
JOIN Portfolio1..CovidVaccinations vac
    ON dea.Location = vac.LOCATION
    AND dea.Date = vac.Date
WHERE dea.continent is not null
ORDER BY 2, 3

-- USE CTE
With PopvsVac(Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT  dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as Int)) OVER (partition by dea.Location order by dea.Date) as RollingPeopleVaccinated 
FROM Portfolio1..CovidDeaths dea
JOIN Portfolio1..CovidVaccinations vac
    ON dea.Location = vac.LOCATION
    AND dea.Date = vac.Date
WHERE dea.continent is not null
-- ORDER BY 2, 3
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT)/Population)*100
FROM PopvsVac


-- TEMPTABLE
DROP TABLE if EXISTS #PercentageOfPeopleVaccinated
CREATE TABLE #PercentageOfPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date DATETIME,
Population NUMERIC,
NewVaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT into #PercentageOfPeopleVaccinated
SELECT  dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as Int)) OVER (partition by dea.Location order by dea.Date) as RollingPeopleVaccinated 
FROM Portfolio1..CovidDeaths dea
JOIN Portfolio1..CovidVaccinations vac
    ON dea.Location = vac.LOCATION
    AND dea.Date = vac.Date
WHERE dea.continent is not null

SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT)/Population)*100
FROM #PercentageOfPeopleVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentageOfPeopleVaccinated AS
WITH VaccinationData AS (
    SELECT 
        dea.continent, 
        dea.Location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM 
        Portfolio1..CovidDeaths dea
    JOIN 
        Portfolio1..CovidVaccinations vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    continent, 
    Location, 
    date, 
    population, 
    new_vaccinations, 
    RollingPeopleVaccinated,
    (CAST(RollingPeopleVaccinated AS FLOAT) / population) * 100 AS VaccinationPercentage
FROM 
    VaccinationData;
