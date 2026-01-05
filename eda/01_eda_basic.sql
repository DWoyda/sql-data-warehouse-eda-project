/*
================================================================================
Purpose: Exploratory Data Analysis (EDA) script for a star-schema “gold” layer.
It profiles schema metadata, dimensions (customers/products), and fact measures
(sales), and produces quick business KPIs plus ranking/magnitude breakdowns.
================================================================================
*/

-- ============================================================================
-- DATABASE METADATA EXPLORATION (INFORMATION_SCHEMA)
-- Note: these views return objects for the *current database*; filter if needed.
-- ============================================================================
SELECT *
FROM information_schema.tables;

SELECT *
FROM information_schema.columns
WHERE table_name = 'dim_customers'; -- schema not filtered on purpose (works across schemas)

-- ============================================================================
-- DIMENSIONS EXPLORATION
-- ============================================================================

SELECT DISTINCT
    country
FROM gold.dim_customers;

SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;

-- Sales coverage window (how long the dataset spans).
SELECT
    MAX(order_date) AS last_order_date,
    MIN(order_date) AS first_order_date,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) AS range_years
FROM gold.fact_sales;

-- Customer age extremes.
-- Clarification: MAX(birthdate) = youngest (latest birthdate); MIN(birthdate) = oldest.
SELECT
    MIN(birthdate) AS oldest_birthdate,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MIN(birthdate))) AS oldest_customer_age_years,
    MAX(birthdate) AS youngest_birthdate,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAX(birthdate))) AS youngest_customer_age_years
FROM gold.dim_customers;

-- ============================================================================
-- MEASURES EXPLORATION (FACT_SALES)
-- ============================================================================

SELECT
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

SELECT
    SUM(quantity) AS total_items
FROM gold.fact_sales;

SELECT
    ROUND(AVG(price), 2) AS avg_price
FROM gold.fact_sales;

-- Clarification: if order_number repeats per line item, COUNT(order_number) != number of orders.
SELECT
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

SELECT
    COUNT(product_key) AS total_products
FROM gold.dim_products;

SELECT
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers;

SELECT
    COUNT(DISTINCT customer_key) AS total_customers_with_order
FROM gold.fact_sales;

-- ============================================================================
-- KPI SNAPSHOT (single resultset)
-- Note: UNION ALL requires compatible column names/types; keep measure_name/value.
-- ============================================================================
SELECT 'Total Sales'               AS measure_name, SUM(sales_amount)::numeric            AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity'            AS measure_name, SUM(quantity)::numeric                AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price'             AS measure_name, ROUND(AVG(price), 2)::numeric         AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders'          AS measure_name, COUNT(DISTINCT order_number)::numeric AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products'        AS measure_name, COUNT(product_key)::numeric           AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Customers'           AS measure_name, COUNT(customer_key)::numeric          AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total Customers with order'AS measure_name, COUNT(DISTINCT customer_key)::numeric AS measure_value FROM gold.fact_sales;

-- ============================================================================
-- MAGNITUDE BREAKDOWNS
-- ============================================================================

SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

SELECT
    category,
    ROUND(AVG(cost), 2) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

SELECT
    pr.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS pr
    ON f.product_key = pr.product_key
GROUP BY pr.category
ORDER BY total_revenue DESC;

SELECT
    cu.customer_id,
    cu.first_name,
    cu.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS cu
    ON f.customer_key = cu.customer_key
GROUP BY
    cu.customer_id,
    cu.first_name,
    cu.last_name
ORDER BY total_revenue DESC;

SELECT
    cu.country,
    SUM(f.quantity) AS distribution_per_country
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS cu
    ON f.customer_key = cu.customer_key
GROUP BY cu.country
ORDER BY distribution_per_country DESC;

-- ============================================================================
-- RANKING
-- ============================================================================

-- Top 5 products by revenue.
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.dim_products AS p
LEFT JOIN gold.fact_sales AS f
    ON p.product_key = f.product_key
WHERE f.sales_amount IS NOT NULL
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Same result using a window function (useful when you later need ties, partitions, etc.).
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.dim_products AS p
    LEFT JOIN gold.fact_sales AS f
        ON p.product_key = f.product_key
    WHERE f.sales_amount IS NOT NULL
    GROUP BY p.product_name
) AS t
WHERE rank_products <= 5;

-- Bottom 5 products by revenue (excluding NULL sales_amount rows).
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.dim_products AS p
LEFT JOIN gold.fact_sales AS f
    ON p.product_key = f.product_key
WHERE f.sales_amount IS NOT NULL
GROUP BY p.product_name
ORDER BY total_revenue
LIMIT 5;

-- Top 5 products by revenue (cleaner variant).
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Flexible ranking with ties (RANK can return > 5 rows when there are ties in position 5).
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5;

-- Bottom 5 products by revenue.
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue
LIMIT 5;

-- Top 10 customers by revenue.
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 3 customers with the fewest distinct orders (customers with zero orders are not included).
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders
LIMIT 3;
