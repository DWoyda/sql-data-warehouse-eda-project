-- FOREIGN KEY INTEGRITY CHECK (DIMENSIONS)
--
-- Purpose:
--     Validate referential integrity between the fact table and dimension tables.
--
-- What this query checks:
--     - Each record in gold.fact_sales should have a matching customer_key 
--       in gold.dim_customers.
--     - Each record in gold.fact_sales should have a matching product_key
--       in gold.dim_products.
--
-- How to interpret results:
--     - If any columns from dim_customers or dim_products return NULL,
--       it indicates a foreign key mismatch (orphaned fact records).
--     - No NULLs = referential integrity is correct.
--
-- Why this is important:
--     Ensures that the star schema is consistent and prevents broken joins 
--     in BI tools, dashboards, and analytical queries.


SELECT 
  *
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS cu
    ON f.customer_key = cu.customer_key
LEFT JOIN gold.dim_products AS pr
    ON f.product_key = pr.product_key
