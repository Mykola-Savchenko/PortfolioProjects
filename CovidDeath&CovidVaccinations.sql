/* The data set was downloaded from the open source https://ourworldindata.org/covid-deaths. CovidDeaths and CovidVaccination samples are used for the analysis*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths` 
WHERE continent is NOT NULL
ORDER BY 1,2

/* Total cases vs. Total Deaths in Ukraine.
Shows the death-rate in the country. */

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE location = 'Ukraine' and continent is NOT NULL
ORDER BY 1,2

/* Total cases vs. Population.
Shows the scale of the spread of COVID-19. */

SELECT location, date, population, total_cases, ROUND((total_cases/population)*100,4) AS PercentPeopleInfected
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE location = 'Ukraine' and continent is NOT NULL
ORDER BY 1,2

/* Countries with highest infection rate compared to population. */

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX(total_cases/population)*100,4) AS PercentPopulationInfected
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

/* Counties with the highest deaths count. */

SELECT location, MAX(total_deaths) AS TotalDeathsCount
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC

/* Continents and larger groups of countries with the highest deaths count.
For some reason Continents and groups of countries (i.e. EU, World and Oceania) were included in the "location" column, leaving the "continent" column NULL. That is why we query the same column "location" as in the previous query, but with "continent is NULL" in the WHERE statement. */

SELECT location, MAX(total_deaths) AS TotalDeathsCount
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC

/* Daily number of cases and deaths globally. */

SELECT date, SUM(new_cases) AS NewCasesGlobally, SUM(new_deaths) AS NewDeathsGlobally, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 4) AS DeathPercentage
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths`
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date


/* Total population vs. vaccination (per day). 
Joining CovidDeaths and CovidVaccination. */

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS PeopleVaccinated
FROM `deft-epigram-368610.PortfolioProject.CovidDeaths` CD
  JOIN `deft-epigram-368610.PortfolioProject.CovidVaccination` CV
    ON CD.date = CV.date
    and CD.location = CV.location
WHERE CD.continent is NOT NULL --and CD.location = 'Ukraine'
ORDER BY CD.location

/* Let's use a CTE, to see how many percent the number of vaccinated people constitute from the entire population.
We have to do that since we cannot perform calculation with the "PeopleVaccinated" column at the moment. */

WITH
      VaccinatedPopulation  
    AS 
    (
      SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
      , SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS PeopleVaccinated
      FROM `deft-epigram-368610.PortfolioProject.CovidDeaths` CD
        JOIN `deft-epigram-368610.PortfolioProject.CovidVaccination` CV
          ON CD.date = CV.date
          and CD.location = CV.location
      WHERE CD.continent is NOT NULL
    )

    SELECT *, ROUND((PeopleVaccinated/population)*100,4) AS PeopleVaccinated_percent
    FROM VaccinatedPopulation


/* Creating a View to store the data to visualize it later. */

    CREATE VIEW PortfolioProject.PeopleVaccinated_percent AS 
    SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
      , SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS PeopleVaccinated
      FROM `deft-epigram-368610.PortfolioProject.CovidDeaths` CD
        JOIN `deft-epigram-368610.PortfolioProject.CovidVaccination` CV
          ON CD.date = CV.date
          and CD.location = CV.location
      WHERE CD.continent is NOT NULL