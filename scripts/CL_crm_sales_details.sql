-- ===========================================
-- CLEAN & LOAD 
-- bronze.crm_sales_details
-- OUTPUT -> silver.crm_sales_details
-- ===========================================

SELECT
sls_ord_num, 
sls_prd_key, 
sls_cust_id, 
sls_order_dt,
CASE 
    WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL
    ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD')
END AS sls_order_dt,
sls_ship_dt, 
sls_due_dt, 
sls_sales, 
sls_quantity, 
sls_price
FROM bronze.crm_sales_details
