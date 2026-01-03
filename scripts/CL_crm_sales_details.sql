-- ===========================================
-- CLEAN & LOAD 
-- bronze.crm_sales_details
-- OUTPUT -> silver.crm_sales_details
-- ===========================================
TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details (
	sls_ord_num, 
	sls_prd_key, 
	sls_cust_id, 
	sls_order_dt, 
	sls_ship_dt, 
	sls_due_dt, 
	sls_sales, 
	sls_quantity, 
	sls_price
)
SELECT
sls_ord_num, 
sls_prd_key, 
sls_cust_id,
CASE 
    WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL
    ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD')
END AS sls_order_dt,
CASE 
    WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) != 8 THEN NULL
    ELSE TO_DATE(sls_ship_dt::text, 'YYYYMMDD')
END AS sls_ship_dt,
CASE 
    WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) != 8 THEN NULL
    ELSE TO_DATE(sls_due_dt::text, 'YYYYMMDD')
END AS sls_due_dt,  
CASE WHEN sls_sales <= 0 OR sls_sales IS NULL or sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales,
sls_quantity, 
CASE WHEN sls_price IS NULL OR sls_price <= 0 
	 	THEN sls_sales / NULLIF(sls_quantity, 0)
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;
