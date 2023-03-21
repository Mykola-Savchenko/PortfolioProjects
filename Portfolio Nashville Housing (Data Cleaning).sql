/* Data cleaning with SQL. Data set Nashville Housing. */ 


/* I would like to start whith a check out for duplicates. */

WITH CheckDup AS (
SELECT *
      , ROW_NUMBER() OVER (
        PARTITION BY UniqueID_
      ) AS row_number
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
)

SELECT *
FROM CheckDup
WHERE row_number >1

-- According to the result of the query, there are no duplicates. That is if we assume, that a unique ID reflect unique information in rows.
-- I would like to check once more though.

WITH CheckDup AS (
			SELECT *
				, ROW_NUMBER() OVER (
							PARTITION BY PropertyAddress,
											ParcelID,
											SaleDate,
											SalePrice,
											LegalReference
													) AS row_number
			FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
		)

SELECT *
FROM CheckDup
WHERE row_number >1

-- And now we have 103 rows. We could assume that all those are duplicates since the rows have a lot of the same information, that suppose to be unique 
-- (PropertyAddress, LegalReference). It is something that has to be reported to decide what to do with the information.


/* Changing date format in the "SaleDate" column*/

SELECT SaleDate, FORMAT_DATE('%d/%m/%Y', PARSE_DATE('%B %d, %Y', SaleDate)) AS SaleDate
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`

UPDATE `deft-epigram-368610.PortfolioProject.Nashville Housing`
SET SleDate = FORMAT_DATE('%d/%m/%Y', PARSE_DATE('%B %d, %Y', SaleDate))

-- Since DML works only in the paid version of BigQuery, I am unable to change SaleDate column to populate it with the changed date format.
-- So, further I have to use the entire function "FORMAT_DATE(...)" to keep the date format I want to be displayed. 


/* Next let's check the table for NULL values. */

SELECT *
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
WHERE UniqueID_ IS NULL OR ParcelID IS NULL
--There are no NULLs in the "UniqueID_" and ParcelID columns.

SELECT *
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
WHERE PropertyAddress IS NULL
      OR SaleDate IS NULL
      OR OwnerName IS NULL
      OR OwnerAddress IS NULL
      OR Acreage IS NULL
      OR TaxDistrict IS NULL
      OR LandValue IS NULL
      OR BuildingValue IS NULL
      OR TotalValue IS NULL
      OR YearBuilt IS NULL 
      OR Bedrooms IS NULL 
      OR FullBath IS NULL
      OR HalfBath IS NULL

-- There are 32772 Null values across those columns.

-- Let`s see if we could populate some of adresses in the PropertyAddress colum. 
-- Running the query below I found out that some equal parcel ID's can relate to the same address in the PropertyAddress colums, having different unique ID.
-- After that, we could check out again for duplicates, in case we unintentionally created some.

SELECT UniqueID_, ParcelID, PropertyAddress
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`

-- Therefore, we could try to populate ProperyAddress rows if there are multiple equal values in the column ParcelID, which have only one matching value in the Property address.
-- To prove our hypothesis, let's join the table to itself to see if we are right.

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing` A
  JOIN `deft-epigram-368610.PortfolioProject.Nashville Housing` B
  ON A.ParcelID = B.ParcelID
  AND A.UniqueID_ <> B.UniqueID_
WHERE A.PropertyAddress is NULL

-- We were right, and now we can populate 35 rows of PropertyAddres column with correct information. Other NULLs have to be dealt with separately.
-- I would ask senior colleagues how the missing information should be treated.  

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
      , COALESCE (A.PropertyAddress, B.PropertyAddress) -- This is to see with what information we are going to populate our NULL rows.
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing` A
  JOIN `deft-epigram-368610.PortfolioProject.Nashville Housing` B
  ON A.ParcelID = B.ParcelID
  AND A.UniqueID_ <> B.UniqueID_
WHERE A.PropertyAddress is NULL

-- Now we can update our tabe and fill some gaps in the table.

UPDATE A
SET A.PropertyAddress = COALESCE (A.PropertyAddress, B.PropertyAddress)
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing` A
  JOIN `deft-epigram-368610.PortfolioProject.Nashville Housing` B
  ON A.ParcelID = B.ParcelID
  AND A.UniqueID_ <> B.UniqueID_
WHERE A.PropertyAddress is NULL


/* To make our data more clean, we could break out the coulumns with addresses into separate columns (Address, City, State). */

SELECT PropertyAddress
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`

SELECT 
      SUBSTR(PropertyAddress, 1,  STRPOS(PropertyAddress, ',')-1) AS Address
    , SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',')+1) AS City
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`

--Now we can create 2 new columns for Address and City.

ALTER TABLE 'PortfolioProject.Nashville Housing'
ADD PropertySplitAddress STRING

UPDATE 'PortfolioProject.Nashville Housing'
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1,  STRPOS(PropertyAddress, ',')-1)


ALTER TABLE 'PortfolioProject.Nashville Housing'
ADD PropertySplitCity STRING

UPDATE 'PortfolioProject.Nashville Housing'
SET PropertySplitCity = SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',')+1)

--Now the Address and City columns are much more convenient to operate with.

SELECT OwnerAddress
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
ORDER BY OwnerAddress DESC

SELECT OwnerAddress
      , REGEXP_EXTRACT(OwnerAddress, r'(.*?),') AS Street
      , REGEXP_EXTRACT(OwnerAddress, r',(.*?),') AS City
      , RIGHT(OwnerAddress, 2) AS State
FROM `deft-epigram-368610.PortfolioProject.Nashville Housing`
WHERE OwnerAddress IS NOT NULL
ORDER BY City

--Now we have Street, City and State in 3 separate columns, and could uptade our table if needed.

