/*
===============================================================================
Customer Report.
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    - Core attributes: customer name, customer number, and age
    - Customer segmentation: classifies customers as VIP, Regular, or New based on lifespan and total spend
    - Age grouping: assigns customers to standard age bands for demographic analysis
    - Customer-level aggregates:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (months)
    - Key KPIs:
        - recency (months since last order)
        - average order value (AOV)
        - average monthly spend
    - Intended use: a dashboard-ready semantic layer view for BI reporting and ad-hoc analysis
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
DROP VIEW IF EXISTS gold.report_customers;

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,

        /* age in full years */
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS age

    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,

        /* lifespan in full months */
        (
            EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12
          + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
        ) AS lifespan

    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    /* age groups */
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    /* customer segments */
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    last_order_date,

    /* recency in months */
    (
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order_date)) * 12
      + EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date))
    ) AS recency,

    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    /* Compute average order value (AOV) */
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,

    /* Compute average monthly spend */
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;
