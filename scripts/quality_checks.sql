-- ======================================================================
-- QUALITY CHECKS
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
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LENGTH(sls_order_dt::text) != 8 
OR sls_order_dt > 20501231
OR sls_order_dt < 19001231
