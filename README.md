# SQL Data Warehouse + EDA + Power BI Sales Dashboard

End-to-end analytics project demonstrating how to build a small **SQL data warehouse** (Bronze/Silver/Gold), model a **star schema**, run **EDA**, and deliver a **Power BI** sales dashboard for monitoring.

---

## Executive Summary

This project builds a lightweight SQL data warehouse (Bronze → Silver → Gold) and a Power BI dashboard to monitor sales performance.  
The dashboard shows **€29.35M** total sales (rounded to **€29.4M** in the KPI card), with sales heavily concentrated in the **Bikes** category (**€28.3M**).  
The strongest year in the dataset is **2013** (**€16.34M**), while **2010** and **2014** contain only partial periods (dataset starts **2010-12-29** and ends **2014-01-28**).

---

## Business Problem

Sales stakeholders need a reliable “single source of truth” for revenue monitoring and product/category performance.  
This project answers the following questions:
- How much revenue did we generate and how does it evolve over time?
- Which categories and products drive results (and concentration risk)?
- What is the activity scale (orders, customers, quantity) behind revenue trends?

---

## Dashboard Preview (Power BI)

<p align="center">
  <img src="docs/dashboard-overview.png" width="1100">
</p>

**Dashboard scope (1 page – Sales Overview):**
- KPI cards: Total Sales, Nr. Customers, Nr. Orders, Total Quantity
- Trend: Sales per year
- Breakdown: Sales by category
- Top 10 products by sales
- Slicers: date range + country

---

## Results (Key Findings)

**Headline KPIs (dashboard):**
- **Total Sales:** **€29.4M** (KPI card, rounded)  
  - Control sum from yearly totals: **€29,351,258** (~€29.35M)
- **Nr. Customers:** **~18.5k** (displayed as **18,484K**)  
- **Nr. Orders:** **~27.7k** (displayed as **27,657K**)  
- **Total Quantity:** **60k**

**Sales concentration:**
- **Top category:** **Bikes — €28.3M** (dominant share of revenue)
- **Top product:** **Mountain-200 Black-46 — €1.37M**

**Time trend (Sales per year):**
- **2010:** €43,419 *(data starts 2010-12-29 — partial year)*
- **2011:** €7,075,088
- **2012:** €5,842,231
- **2013:** €16,344,878 *(peak year)*
- **2014:** €45,642 *(data ends 2014-01-28 — partial year)*

---

## Business Recommendations

1) **Category concentration monitoring**
- Bikes dominate revenue; track whether growth depends on one category.
- Suggested action: add a KPI for category revenue share and monitor changes monthly/quarterly.

2) **Product portfolio focus**
- Top products (e.g., Mountain-200 variants) drive a large part of results.
- Suggested action: monitor Top-N products over time and compare performance by country.

3) **Trend interpretation with partial-year caution**
- 2010 and 2014 are incomplete periods; year-over-year comparisons should exclude partial years or normalize by time coverage.
- Suggested action: default reporting to full years (2011–2013) or add a “coverage note” in the dashboard.

---

## High-Level Architecture

This project follows a **Medallion / Layered** approach:

- **Bronze:** raw ingested data (as-is)
- **Silver:** cleaned and standardized data
- **Gold:** business-ready model for analytics (star schema)

Gold is the layer consumed by **Power BI** for reporting.

<p align="center">
  <img src="docs/data_architecture.png" width="1100">
</p>

---

## Dataset and Model

### Data source
- **Source format:** CSV files
- **Loaded into:** SQL data warehouse (Bronze → Silver → Gold)

### Data domains
- **`source_crm`:** customer-related and sales-related entities
- **`source_erp`:** product/master data and operational attributes

### Gold layer (star schema)

**Fact table**
- `gold.fact_sales`
- **Grain (granularity):** one row represents one sales line / transaction line  
  (one `order_number` can appear in multiple rows — one order can contain multiple products)

**Dimensions**
- `gold.dim_customers`
- `gold.dim_products`

**Relationships**
- `gold.fact_sales[customer_key]` → `gold.dim_customers[customer_key]`
- `gold.fact_sales[product_key]` → `gold.dim_products[product_key]`

> With this model, dimension filters (e.g., country, category) correctly filter the fact table in Power BI.

### Date range
- **2010-12-29 → 2014-01-28** *(partial coverage for 2010 and 2014)*

---

## KPIs (report aggregations)

KPI values are calculated in Power BI using standard aggregations over `gold.fact_sales`  
### Repository structure

```text

sql-data-warehouse-eda-project/
├─ bi/
│  └─ *.pbix
├─ dataset/
│  ├─ source_crm/
│  └─ source_erp/
├─ docs/
│  ├─ dashboard_overview.png
│  └─ data_architecture.png
├─ eda/
│  ├─ 01_eda_basic.sql
│  └─ 02_eda_advanced.sql
├─ reports/
│  ├─ gold_view_custimers.sql
│  └─ gold_view_products.sql
├─ scripts/
│  ├─ bronze/                                  # raw data
│  ├─ silver/                                  # cleaned/standardized data 
│  ├─ gold/                                    # business ready
│  └─ 00init_database.sql                      # database init  
├─ test/
│  ├─ foreign_key_integration.sql
│  └─ quality_checks_silver.sql
├─ LICENSE
└─ README.md

```
## License

This project is licensed under the **MIT License**.  
See [LICENSE](LICENSE) for details.
