

-- 1.
--The data in the "SaleDate" column for the date contains a time field that is not necessary/relevant. 
--In this section, a new column is created to store the data from the "SaleDate" column, excluding the time field.

--Create a new column to store the date in the desired format. 
ALTER TABLE HousingData
ADD FechaCorregida Date;


-- Add the data to the new column:
UPDATE HousingData
SET FechaCorregida = CONVERT(Date,SaleDate);


-----------------------------------------------------------------------------------------------------------------------------------------
--2. 
/*
With the following command, the goal is to assign a value to the "PropertyAddress" column for those rows where the value is NULL in that column. 
This is possible because all rows with the same value in the "ParcelID" column also have the same value in the "PropertyAddress" column. 
Therefore, if two rows A and B have the same "ParcelID" but row A has a NULL "PropertyAddress," a value can be assigned by copying the "PropertyAddress" data from row B.
*/

UPDATE a 

--If the data in the 'PropertyAddress' column of table 'a' is NULL, SET the same value as the 'PropertyAddress' column in table 'b':
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)

From HousingData a
JOIN HousingData b
	
	--Join the rows with the same "ParcelID" but a different "UniqueID":
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]

--Include only the rows with a NULL "ProperyAddress":
WHERE a.PropertyAddress IS NULL;



-------------------------------------------------------------------------------------------------------------------------------------
--3.
/*
The values in the "PropertyAddress" column are composed of two elements: the address and the city. 
These two elements are separated by a comma. 
To enhance the usability of the data in the "PropertyAddress" column, 
a new column is created to store only the addresses, and another column is created to store only the cities.
*/


--Create the column for the addresses
ALTER TABLE HousingData
Add PropertySplitAddress Nvarchar(255);

--Create the column for the cities
ALTER TABLE HousingData
Add PropertySplitCity Nvarchar(255);



UPDATE HousingData
--The "PropertySplitAddress" column is updated with a SUBSTRING of the "PropertyAddress" column.
--The SUBSTRING starts at index 1 and ends at the index preceding the comma, which is obtained using "CHARINDEX(',', PropertyAddress) - 1.
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );

UPDATE HousingData
--The "PropertySplitCity" column is updated with a SUBSTRING of the "PropertyAddress" column. 
--The SUBSTRING starts at the index following the comma, obtained using "CHARINDEX(',', PropertyAddress) + 1,"
-- and ends at the last index of the string, calculated by determining the length of the string with "LEN(PropertyAddress)."
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as City
From HousingData;

---------------------------------------------------------------------------------------------------------------------
--4. 
/*
Here, we separate the address, city, and state from each row in the "OwnerAddress" column. 
For this purpose, the PARSENAME function is used, which returns a part of an object that is separated by dots. 
The REPLACE function replaces the commas in the "OwnerAddress" object with dots, enabling the use of PARSENAME.
*/


--Create the column for the addresses
ALTER TABLE HousingData
Add OwnerSplitAddress Nvarchar(255);

--Update the column
UPDATE HousingData
--PARSENAME returns the third part of the "OwnerAddress" object, corresponding to the address
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);


--Create the column for the cities
ALTER TABLE HousingData
Add OwnerSplitCity Nvarchar(255);

--Update the column 
Update HousingData
--PARSENAME returns the second part of the "OwnerAddress" object, corresponding to the city.
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);


--Create the column for the States 
ALTER TABLE HousingData
Add OwnerSplitState Nvarchar(255);

--Update the column
Update HousingData
--PARSENAME returns the second part of the "OwnerAddress" object, corresponding to the state.
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

---------------------------------------------------------------------------------------
--5.With the following command, the goal is to standardize the "SoldAsVacant" column. 
--The column contains four values: N, No, Y, Yes. The command replaces the values "N" with "No" and the values "Y" with "Yes."


Update HousingData
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

--Make sure that only the values "Yes" and "No" exist after the update. 
SELECT DISTINCT(SoldAsVacant) FROM HousingData; 

---------------------------------------------------------------------------------------
/*6. The following command is designed to eliminate duplicate rows. 
The command includes a Common Table Expression (CTE) that partitions the table based on a combination of columns whose values should be unique for each row. 
Therefore, if a partition has more than one row, it indicates that those rows are duplicates. 
Since the CTE assigns a number to each row in the partition, eliminating duplicate rows simply involves removing those with a number greater than 1.
*/

WITH CTE AS(
SELECT *,
	ROW_NUMBER() OVER ( --ROW_NUMBER  assigns a different number to each row of the partition
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM HousingData
)
DELETE 
FROM CTE
WHERE row_num > 1; --Delete the rows whose value in the "row_num" column is greater than 1.


-------------------------------------------------------------------------------------------
--7. Remove those columns that are not relevant for the analysis.

ALTER TABLE HousingData
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate; 









