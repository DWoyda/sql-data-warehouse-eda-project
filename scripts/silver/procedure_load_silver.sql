/* =====================================================================================
Procedure Name: silver.load_silver
Layer: Bronze → Silver
Author: Damian
Description:
    This stored procedure executes the ETL pipeline responsible for loading the
    curated Silver Layer from the raw Bronze Layer.

    The procedure performs a full refresh of all Silver tables by:
      • Truncating each target Silver table
      • Transforming and cleansing incoming Bronze data
      • Standardizing categorical values (gender, marital status, product line, country)
      • Validating and recalculating inconsistent sales metrics
      • Deriving effective end dates using window functions
      • Selecting the most recent record per customer using ROW_NUMBER()
      • Converting integer date formats into proper DATE types
      • Ensuring data quality based on business rules

    Progress and execution time for each table is logged through RAISE NOTICE.
    The procedure is intended to be run on a regular schedule (daily/weekly)
    as part of the automated data ingestion and refinement pipeline.

Parameters:
    None

Returns:
    This procedure does not return values. It performs side-effect operations
    on tables within the "silver" schema.

Usage:
    CALL silver.load_silver();
===================================================================================== */

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time   TIMESTAMP;
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'START SILVER LAYER LOAD (BRONZE → SILVER)';
    RAISE NOTICE '==========================================';

    -------------------------------------------
    -- crm_cust_info
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;

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
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            ELSE 'unknown'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'Female'
            ELSE 'unknown'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    -- crm_prd_info
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.crm_prd_info';

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7, LENGTH(prd_key)),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'unknown'
        END,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
    FROM bronze.crm_prd_info;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    -- crm_sales_details
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8
            THEN NULL ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD') END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) != 8
            THEN NULL ELSE TO_DATE(sls_ship_dt::text, 'YYYYMMDD') END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) != 8
            THEN NULL ELSE TO_DATE(sls_due_dt::text, 'YYYYMMDD') END,
        CASE 
            WHEN sls_sales <= 0 OR sls_sales IS NULL 
                 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        sls_quantity,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0 
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    -- erp_cust_az12
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, length(cid))
             ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE THEN NULL ELSE bdate END,
        CASE 
            WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
            ELSE 'unknown'
        END
    FROM bronze.erp_cust_az12;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    -- erp_loc_a101
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE 
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) LIKE 'US%' THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'unknown'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    -- erp_px_cat_g1v2
    -------------------------------------------
    start_time := clock_timestamp();
    RAISE NOTICE '>> Loading silver.erp_px_cat_g1v2';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    end_time := clock_timestamp();
    RAISE NOTICE '   Done. Duration: % seconds', EXTRACT(SECOND FROM end_time - start_time);

    -------------------------------------------
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'SILVER LAYER LOAD COMPLETED SUCCESSFULLY';
    RAISE NOTICE '==========================================';

END;
$$;
