-- FOREIGN KEY & DATA MODEL INTEGRITY CHECK
--
-- Purpose:
--     Verify that every fact record in gold.fact_sales correctly links 
--     to existing dimension records (customers and products).
--
-- What this query detects:
--     - Missing customer_key in dim_customers  
--     - Missing product_key in dim_products  
--     These are called "orphaned fact rows" — facts that cannot be joined 
--     to their dimensions, breaking the star-schema integrity.
--
-- Expected Result:
--     No returned rows.
--     If the query returns any rows, they represent data quality issues 
--     that must be investigated (missing dimension members, incorrect keys,
--     or errors in ETL logic).
--
-- Why this matters:
--     - Ensures referential integrity in the analytical model.
--     - Prevents broken joins in BI tools (Power BI, Tableau, Looker).
--     - Guarantees correctness of aggregated metrics and coherent reporting.

SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

SELECT 
  *
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS cu
    ON f.customer_key = cu.customer_key
LEFT JOIN gold.dim_products AS pr
    ON f.product_key = pr.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL  
