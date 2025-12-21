/*
=============================================================
init-database.sql postgreSQL
=============================================================
Script Purpose:
    Set up the Data Warehouse environment in PostgreSQL:
      A) Create the project database: 'datawarehouse'
      B) Create core schemas inside that database:
           - bronze
           - silver
           - gold

How to run (pgAdmin):
    Step 1 (Database creation):
        - Connect to a maintenance database (usually 'postgres')
        - Run Section A

    Step 2 (Schema initialization):
        - Connect to the target database: 'DataWarehouse'
        - Run Section B

Notes:
    - PostgreSQL does not support switching databases inside a plain SQL script
      in pgAdmin.
    - Section A does NOT drop the database. If it already exists, PostgreSQL
      will return an error.
    - Section B is safe to re-run (uses IF NOT EXISTS).
=============================================================
*/

-- =============================================================
-- Section A: Create the database (run while connected to 'postgres')
-- =============================================================

CREATE DATABASE DataWarehouse;

-- =============================================================
-- Section B: Create schemas (run while connected to 'datawarehouse')
-- =============================================================

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
