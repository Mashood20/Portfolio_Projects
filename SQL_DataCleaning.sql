-- Data Cleaning Project

SELECT * FROM Portfolio1..NashvilleHousing;


-- Standardize Date Format

UPDATE Portfolio1..NashvilleHousing
SET SaleDate = Convert(Date, SaleDate);


-- Populate PropertyAddress

SELECT * FROM Portfolio1..NashvilleHousing
WHERE PropertyAddress is null


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio1..NashvilleHousing a
JOIN Portfolio1..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio1..NashvilleHousing a
JOIN Portfolio1..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- Breaking the address into individual columns

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM Portfolio1..NashvilleHousing

ALter TABLE Portfolio1..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE Portfolio1..NashvilleHousing
SET PropertySplitAddress =  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALter TABLE Portfolio1..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE Portfolio1..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


-- Breaking the owner address into individual columns with parse method


SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)
FROM Portfolio1..NashvilleHousing


ALter TABLE Portfolio1..NashvilleHousing
ADD OwnersplitAddress NVARCHAR(255)

UPDATE Portfolio1..NashvilleHousing
SET OwnersplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALter TABLE Portfolio1..NashvilleHousing
ADD OwnersplitCity NVARCHAR(255)

UPDATE Portfolio1..NashvilleHousing
SET OwnersplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALter TABLE Portfolio1..NashvilleHousing
ADD OwnersplitState NVARCHAR(255)

UPDATE Portfolio1..NashvilleHousing
SET OwnersplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)


-- Change 'Y' and 'N' to 'YES' and 'NO'

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio1..NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
     WHEN SoldAsVacant = 'N' THEN 'NO'
     ELSE SoldAsVacant
     END
FROM Portfolio1..NashvilleHousing

UPDATE Portfolio1..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
     WHEN SoldAsVacant = 'N' THEN 'NO'
     ELSE SoldAsVacant
     END

-- Remove Duplicates
WITH RowNumCTE AS(
    SELECT *, 
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
        PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
        ORDER BY
            UniqueID
        ) row_num
    FROM Portfolio1..NashvilleHousing
    -- ORDER BY ParcelID
)
DELETE FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused columns
ALTER TABLE Portfolio1..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
