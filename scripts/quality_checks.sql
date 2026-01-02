-- ======================================================================
/*
--QUALITY CHECKS
	crm_cust_info
	crm_prd_info
	crm_sales_details
	erp_cust_az12
	erp_loc_a101
	erp_px_cat_g1v2
*/
-- ======================================================================
-- ======================================================================
-- crm_cust_info
-- ======================================================================
-- Check for nulls or duplicates in Primary Key
-- Expectation: No Results
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT
cst_id,
cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Data Standardization & Consistency
-- gender
SELECT DISTINCT cst_gender
FROM bronze.crm_cust_info

-- marital status
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

-- ======================================================================
-- crm_prd_info
-- ======================================================================
-- Check for NULLS or DUPLICATES in Primary Key
-- Expectation: No Results
SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT
prd_id,
prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLS or NEGATIVE numbers
-- Expectation: No Results
SELECT 
prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invalid Data Orders
SELECT 
*
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT 
*
FROM silver.crm_prd_info

-- ======================================================================
-- crm_sales_details
-- ======================================================================
-- Check for Invalid Dates

SELECT
NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LENGTH(sls_ship_dt::text) != 8 
OR sls_ship_dt > 20501231
OR sls_ship_dt < 19001231

-- Check for Invalid Date Orders
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
/*
-- Check Data Consistency between SALES , QUANTITY AND PRICE
	SALES  = QUANTITY * PRICE
	Values must be not NULL, ZERO OR NEGATIVE

Business Rules (So my rules):
	1. If Sales is negative, zero, or NULL, derive it using Quantity * Price.
	2. If Price is zero or NULL, calculate it using Sales / Quantity.
	3. If Price is negative, convert it to a positive value.
*/

SELECT DISTINCT 
sls_sales AS old_sales,
sls_quantity,
sls_price AS old_price,

CASE WHEN sls_sales <= 0 OR sls_sales IS NULL or sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0 
	 	THEN sls_sales / NULLIF(sls_quantity, 0)
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-- ======================================================================
-- erp_cust_az12
-- ======================================================================
-- Identify Out-of-range Dates

SELECT 
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1926-01-01' OR bdate > CURRENT_DATE 

-- Data Standardization & Consistency

SELECT DISTINCT 
gen,
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'unknown'
END AS gen
FROM silver.erp_cust_az12


-- ======================================================================
-- erp_loc_a101
-- ======================================================================
-- Changing key


SELECT 
REPLACE(cid, '-', '') AS cid,
cntry
FROM silver.erp_loc_a101


-- Data Standardization & Consistency

SELECT DISTINCT 
CASE 
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) LIKE 'US%' THEN 'United States' 
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'unknown'
	ELSE TRIM(cntry)
END AS cntry
FROM silver.erp_loc_a101
ORDER BY cntry

-- ======================================================================
-- erp_px_cat_g1v2
-- ======================================================================
-- Check unwanted spaces

SELECT
*
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)


-- Data Standardization & Consistency

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2
