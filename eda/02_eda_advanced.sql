/*
================================================================================
Purpose: Advanced analytics on sales data (gold layer) to understand:
- Change over time (monthly trends)
- Cumulative performance (running totals and running averages)
- Product performance vs historical baseline and prior year
- Category contribution (part-to-whole)
- Segmentation (product cost bands, customer value segments)
================================================================================
*/

-- =============================================================================
-- CHANGE OVER TIME
-- Monthly aggregation of sales, distinct customers, and quantity.
-- Note: output is at (year, month) granularity; there is no day-level detail.
-- =============================================================================
SELECT
    order_year,
    order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM (
    SELECT
        EXTRACT(YEAR  FROM order_date) AS order_year,
        EXTRACT(MONTH FROM order_date) AS order_month,
        sales_amount,
        customer_key,
        quantity
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
) t
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- =============================================================================
-- CUMULATIVE ANALYSIS
-- Running total sales and running average price over months.
-- Clarification: running_avg_price is based on monthly AVG(price) values (unweighted).
-- If you need a revenue-weighted running average price, the definition changes.
-- =============================================================================
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    ROUND(AVG(avg_price) OVER (ORDER BY order_month), 2) AS running_avg_price
FROM (
    SELECT
        DATE_TRUNC('month', order_date)::date AS order_month,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', order_date)
) t
ORDER BY order_month;

-- =============================================================================
-- PERFORMANCE ANALYSIS
-- Yearly product sales compared to:
-- 1) the product's multi-year average (avg_sales)
-- 2) the previous year's sales (previous_sales)
-- =============================================================================
WITH yearly_product_sales AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 2) AS avg_sales,
    ROUND(
        current_sales - AVG(current_sales) OVER (PARTITION BY product_name),
        2
    ) AS diff_avg,
    CASE
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_sales,
    current_sales
      - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_previous,
    CASE
        WHEN LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) IS NULL THEN 'No Prior Year'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS yoy_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- =============================================================================
-- PART TO WHOLE ANALYSIS
-- Category contribution to overall sales.
-- Clarification: percentage_of_total is computed using the sum across categories in this resultset.
-- =============================================================================
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(
        ROUND((total_sales / NULLIF(SUM(total_sales) OVER (), 0)) * 100, 2),
        '%'
    ) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- =============================================================================
-- DATA SEGMENTATION (PRODUCTS)
-- Cost bands for products and how many products fall into each band.
-- =============================================================================
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

-- =============================================================================
-- DATA SEGMENTATION (CUSTOMERS)
/*
Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
-- =============================================================================
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        (
            EXTRACT(YEAR  FROM AGE(MAX(f.order_date), MIN(f.order_date))) * 12
          + EXTRACT(MONTH FROM AGE(MAX(f.order_date), MIN(f.order_date)))
        ) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN lifespan_months >= 12 AND total_spending > 5000  THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;
