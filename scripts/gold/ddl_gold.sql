/*
=============================================================
gold_views.sql (PostgreSQL)
=============================================================
Purpose:
    This script creates the Gold layer views for the Data Warehouse.
    The Gold layer represents the presentation layer built on top 
    of the cleansed and standardized Silver tables.

    These views serve as:
        - Business-ready dimension tables (Star Schema).
        - A fact table that joins customer, product, and sales data.
        - A semantic layer for BI tools such as Power BI, Tableau, Looker.

What this script does:
    1. Drops views if they already exist (to avoid conflicts).
    2. Recreates the following views:
        - gold.dim_customers
        - gold.dim_products
        - gold.fact_sales

Usage:
    Run this script after loading Bronze and Silver layers.
    These views should be queried directly by analysts and reporting tools.

=============================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
DROP VIEW IF EXISTS gold.dim_customers CASCADE;

CREATE VIEW gold.dim_customers AS 
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id                           AS customer_id, 
	ci.cst_key                          AS customer_number, 
	ci.cst_firstname                    AS first_name, 
	ci.cst_lastname                     AS last_name,
	cl.cntry                            AS country,
	ci.cst_marital_status               AS marital_status, 
	CASE 
      WHEN ci.cst_gender != 'unknown' THEN ci.cst_gender
		  ELSE COALESCE(ca.gen, 'unknown')
	END AS gender,
	ca.bdate                            AS birthdate,
	ci.cst_create_date                  AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS cl
    ON ci.cst_key = cl.cid


DROP VIEW IF EXISTS gold.dim_products CASCADE;

CREATE VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY prd_id)    AS product_key,
    pn.prd_id                              AS prodcut_id, 
    pn.prd_key                             AS product_number,
    pn.prd_nm                              AS product_name,
    pn.cat_id                              AS category_id,   
    pc.cat                                 AS category,
    pc.subcat                              AS subcategory,
    pc.maintenance                         AS maintenance,
    pn.prd_cost                            AS cost, 
    pn.prd_line                            AS product_line, 
    pn.prd_start_dt                        AS start_date 
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;  -- filter out all historical data

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================

DROP VIEW IF EXISTS gold.fact_sales CASCADE;

CREATE VIEW gold.fact_sales AS 
SELECT
    sd.sls_ord_num       AS order_Number, 
    pr.product_key       AS product_key, 
    cu.customer_key      AS customer_key, 
    sd.sls_order_dt      AS order_date, 
    sd.sls_ship_dt       AS shipping_date, 
    sd.sls_due_dt        AS due_date, 
    sd.sls_sales         AS sales_amount, 
    sd.sls_quantity      AS quantity, 
    sd.sls_price         AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
