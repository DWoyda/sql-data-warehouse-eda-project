-- ===========================================
-- CLEAN & LOAD 
-- bronze.erp_loc_a101
-- OUTPUT -> silver.erp_loc_a101
-- ===========================================
INSERT INTO silver.erp_loc_a101(
cid, 
cntry
)
SELECT 
REPLACE(cid, '-', '') AS cid,
CASE 
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) LIKE 'US%' THEN 'United States' 
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'unknown'
	ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101
