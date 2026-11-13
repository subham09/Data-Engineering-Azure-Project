-- ============================================================
-- Script: 03_load_dimension_tables.sql
-- Purpose: Load dimension tables from Lakehouse Gold layer via shortcuts
-- Fabric Item: Data Warehouse (RetailSalesDW)
-- DP-700 Skill: Ingest and Transform Data > Batch Data Processing
-- ============================================================
-- NOTE: In Microsoft Fabric, the Data Warehouse can query Lakehouse
-- tables directly using cross-item querying. These INSERT statements
-- assume the Gold Lakehouse tables are accessible via the warehouse's
-- default lakehouse endpoint or OneLake shortcuts.
-- ============================================================

-- ============================================================
-- 1. Load dim.date from Gold Lakehouse
-- ============================================================
TRUNCATE TABLE dim.date;

INSERT INTO dim.date (
    date_key, full_date, year, quarter, month_number, month_name,
    month_short, week_of_year, day_of_month, day_of_week, day_name,
    is_weekend, year_month, year_quarter
)
SELECT
    date_key,
    full_date,
    year,
    quarter,
    month_number,
    month_name,
    month_short,
    week_of_year,
    day_of_month,
    day_of_week,
    day_name,
    CAST(is_weekend AS BIT),
    year_month,
    year_quarter
FROM RetailSalesLakehouse.gold.dim_date;   -- Cross-lakehouse query

-- ============================================================
-- 2. Load dim.customer — with MERGE for SCD Type 1
-- ============================================================
-- Step 1: Load staging
TRUNCATE TABLE staging.customers_load;

INSERT INTO staging.customers_load
SELECT
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    gender,
    date_of_birth,
    city,
    state,
    country,
    postal_code,
    segment,
    registration_date,
    CAST(is_active AS BIT)
FROM RetailSalesLakehouse.gold.dim_customer;

-- Step 2: MERGE into dim.customer (SCD Type 1 — overwrite on change)
MERGE INTO dim.customer AS target
USING staging.customers_load AS source
ON target.customer_id = source.customer_id

WHEN MATCHED AND (
    target.email           <> source.email OR
    target.segment         <> source.segment OR
    target.is_active       <> source.is_active OR
    target.city            <> ISNULL(source.city, target.city)
) THEN UPDATE SET
    target.first_name         = source.first_name,
    target.last_name          = source.last_name,
    target.full_name          = source.full_name,
    target.email              = source.email,
    target.gender             = source.gender,
    target.date_of_birth      = source.date_of_birth,
    target.city               = source.city,
    target.state              = source.state,
    target.country            = source.country,
    target.postal_code        = source.postal_code,
    target.segment            = source.segment,
    target.registration_date  = source.registration_date,
    target.is_active          = source.is_active,
    target.dw_updated_at      = GETDATE()

WHEN NOT MATCHED BY TARGET THEN INSERT (
    customer_id, first_name, last_name, full_name, email, gender,
    date_of_birth, city, state, country, postal_code, segment,
    registration_date, is_active, dw_inserted_at, dw_updated_at
)
VALUES (
    source.customer_id, source.first_name, source.last_name, source.full_name,
    source.email, source.gender, source.date_of_birth, source.city, source.state,
    source.country, source.postal_code, source.segment, source.registration_date,
    source.is_active, GETDATE(), GETDATE()
);

PRINT CONCAT('dim.customer rows: ', (SELECT COUNT(*) FROM dim.customer));

-- ============================================================
-- 3. Load dim.product — with MERGE for SCD Type 1
-- ============================================================
TRUNCATE TABLE staging.products_load;

INSERT INTO staging.products_load
SELECT
    product_id, product_name, category, subcategory, brand,
    CAST(unit_price AS DECIMAL(10,2)),
    CAST(cost_price AS DECIMAL(10,2)),
    CAST(margin_pct AS DECIMAL(5,2)),
    price_band,
    CAST(weight_kg AS FLOAT),
    CAST(is_active AS BIT),
    created_date
FROM RetailSalesLakehouse.gold.dim_product;

MERGE INTO dim.product AS target
USING staging.products_load AS source
ON target.product_id = source.product_id

WHEN MATCHED AND (
    target.unit_price <> source.unit_price OR
    target.is_active  <> source.is_active
) THEN UPDATE SET
    target.product_name    = source.product_name,
    target.category        = source.category,
    target.subcategory     = source.subcategory,
    target.brand           = source.brand,
    target.unit_price      = source.unit_price,
    target.cost_price      = source.cost_price,
    target.margin_pct      = source.margin_pct,
    target.price_band      = source.price_band,
    target.weight_kg       = source.weight_kg,
    target.is_active       = source.is_active,
    target.dw_updated_at   = GETDATE()

WHEN NOT MATCHED BY TARGET THEN INSERT (
    product_id, product_name, category, subcategory, brand, unit_price,
    cost_price, margin_pct, price_band, weight_kg, is_active, created_date,
    dw_inserted_at, dw_updated_at
)
VALUES (
    source.product_id, source.product_name, source.category, source.subcategory,
    source.brand, source.unit_price, source.cost_price, source.margin_pct,
    source.price_band, source.weight_kg, source.is_active, source.created_date,
    GETDATE(), GETDATE()
);

PRINT CONCAT('dim.product rows: ', (SELECT COUNT(*) FROM dim.product));
