-- ===========================================
-- CLEAN & LOAD 
-- bronze.crm_cust_info
-- OUTPUT -> silver.crm_cust_info
-- ===========================================
INSERT INTO silver.crm_cust_info (
	cst_id, 
	cst_key, 
	cst_firstname, 
	cst_lastname, 
	cst_marital_status, 
	cst_gender, 
	cst_create_date
)

SELECT
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	ELSE 'unknown'
END cst_gender,
CASE
	WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'Male'
	WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'Female'
	ELSE 'unknown'
END cst_gender,
cst_create_date
FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) AS t 
WHERE flag_last = 1
