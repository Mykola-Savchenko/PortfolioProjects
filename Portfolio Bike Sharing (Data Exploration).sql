/*
The data was downloaded from an open source: https://divvy-tripdata.s3.amazonaws.com/index.html. 

12 spreadsheets (reflecting each month of the 2022) were merged into a single table for further analysis in Big Query. 
*/


--Let's check out the number of rides that exceed 5 min, to exclude very short rides and mistakes (such as negative ride time).
SELECT COUNT(DISTINCT ride_id)
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5


/* Since we are working with the already merged table, let's look at every month of 2022 and how many rides occur in each of them. 
And we can observe, that members use bike sharing more evenly during the year. 
The difference among months, where users are members, is not so big as among months, where users are casual. */

SELECT FORMAT_TIMESTAMP("%B", started_at) AS month_of_2022, COUNT(ride_id) AS total_rides
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5 and member_casual = --"casual"
"member"
GROUP BY month_of_2022
ORDER BY COUNT (ride_id) DESC


--I would like to have a look on the length of rides, to further explore the data.
SELECT ride_id, started_at, ended_at, TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS trip_length, member_casual
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
ORDER BY trip_length DESC


--Now I would like to return the mean value of the ride length for the types of users. (For visualization)
SELECT ROUND(AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)), 2) AS avg_trip_length_min, member_casual
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE ended_at > started_at AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5 
--To make our results more accurate, we are looking only for trips that last longer than 5 min.
GROUP BY member_casual
ORDER BY avg_trip_length_min DESC

/*
SELECT ROUND(AVG(DATETIME_DIFF(ended_at, started_at, MINUTE)), 2) AS avg_trip_length_min, member_casual
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE ended_at > started_at AND DATETIME_DIFF(ended_at, started_at, MINUTE) >= 5
GROUP BY member_casual
ORDER BY avg_trip_length_min DESC

--Or to see the more accurate time

SELECT AVG(DATETIME(ended_at) - DATETIME(started_at)) AS avg_trip_duration_min, member_casual
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE ended_at > started_at AND DATETIME_DIFF(ended_at, started_at, MINUTE) >= 5
GROUP BY member_casual
ORDER BY avg_trip_duration_min DESC
*/


--The insight into the most popular type of bike could be also handy. We look at the bikes that have the most number of rides and those that have the longest ones. 
SELECT rideable_type, MAX(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS max_trip_duration_min, COUNT(ride_id) AS rides_number
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
GROUP BY rideable_type
ORDER BY COUNT(ride_id)


--Let's find the most popular weekday to start a ride.
SELECT FORMAT_TIMESTAMP("%A", started_at) AS start_day
, COUNT(ride_id) AS total_rides
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >=5
GROUP BY start_day
ORDER BY COUNT (ride_id) DESC


--We could also find the mean ride time for each type of user. (For visualisation)
SELECT ROUND(AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)), 2) AS avg_trip_length_min, member_casual
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE ended_at > started_at AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5
GROUP BY member_casual
ORDER BY avg_trip_length_min DESC


--We could find the most popular day of the week to start a ride for each type of users. (For visualisation)
SELECT FORMAT_TIMESTAMP("%A", started_at) AS start_day
, COUNT(ride_id) AS total_rides
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE member_casual = "casual" AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5
GROUP BY start_day
ORDER BY COUNT (ride_id) DESC

SELECT FORMAT_TIMESTAMP("%A", started_at) AS start_day
, COUNT(ride_id) AS total_rides
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE member_casual = "member" AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) >= 5
GROUP BY start_day
ORDER BY COUNT (ride_id) DESC


--Let's group ride length and see percentage from total rides by type of users. (For visualization)
--for casual:
WITH length_use AS
(
SELECT member_casual 
, CASE 
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 5 AND 30 THEN "short_5_to_30_min"
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 31 AND 120 THEN "medium_31_to_120_min"
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 121 AND 360 THEN "long_2_to_5_h"
        ELSE "very_long_5h_and_more"
        END AS ride_length
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE DATETIME_DIFF(ended_at, started_at, MINUTE) >= 5
)

SELECT ride_length, COUNT(ride_length) AS number_of_rides, ROUND(COUNT(ride_length)/(1609342+368609+29718+8043)*100, 2) AS percent_rides
FROM length_use
WHERE member_casual = 'casual' 
GROUP BY ride_length
ORDER BY number_of_rides DESC


--for member:
WITH length_use AS
(
SELECT member_casual 
, CASE 
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 5 AND 30 THEN "short_5_to_30_min"
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 31 AND 120 THEN "medium_31_to_120_min"
        WHEN  DATETIME_DIFF(ended_at, started_at, MINUTE) BETWEEN 121 AND 360 THEN "long_2_to_5_h"
        ELSE "very_long_5h_and_more"
        END AS ride_length
FROM `deft-epigram-368610.PortfolioBikeSharing.tripdata_full_2022`
WHERE DATETIME_DIFF(ended_at, started_at, MINUTE) >= 5
)

SELECT ride_length, COUNT(ride_length) AS number_of_rides, ROUND(COUNT(ride_length)/(2345966+187230+4594+1963)*100, 2) AS percent_rides
FROM length_use
WHERE member_casual = 'member' 
GROUP BY ride_length
ORDER BY number_of_rides DESC
