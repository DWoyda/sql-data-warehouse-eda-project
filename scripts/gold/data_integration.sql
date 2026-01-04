-- DATA INTEGRATION CHECK
-- Purpose:
--     Validate and reconcile the gender attribute between CRM and ERP systems.
--     Rule applied:
--         - CRM is treated as the primary source.
--         - If CRM gender = 'unknown', fallback to ERP value.
--         - If both are missing, assign 'unknown'.
--
-- Output:
--     Shows distinct combinations of gender values from CRM, ERP,
--     and the final integrated gender used in the Gold dimension.

SELECT DISTINCT 
	ci.cst_gender,
	ca.gen,
	CASE WHEN ci.cst_gender != 'unknown' THEN ci.cst_gender
		 ELSE COALESCE(ca.gen, 'unknown')
	END AS new_gen
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS cl
ON		  ci.cst_key = cl.cid
ORDER BY 1, 2
