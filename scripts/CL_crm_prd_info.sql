-- ===========================================
-- CLEAN & LOAD 
-- bronze.crm_prd_info
-- OUTPUT -> silver.crm_prd_info
-- ===========================================
INSERT INTO silver.crm_prd_info (
	prd_id, 
	cat_id, 
	prd_key, 
	prd_nm, 
	prd_cost, 
	prd_line, 
	prd_start_dt, 
	prd_end_dt
)
SELECT
prd_id,  
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm, 
COALESCE(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'unknown'
END AS prd_line,
prd_start_dt, 
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt
FROM bronze.crm_prd_info

/*
-- ==========================================================
-- stare CASE -> trick szybkie CASE juz w zapytaniu 
-- CASE 
	WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'unknown'
-- =========================================================
*/

