-- ============================================================
-- Script: 04_load_fact_tables.sql
-- Purpose: Load fact tables with incremental pattern
-- Fabric Item: Data Warehouse (RetailSalesDW)
-- DP-700 Skill: Ingest and Transform Data > Design Loading Patterns
-- ============================================================

-- ============================================================
-- Parameters (passed from Data Pipeline)
-- ============================================================
DECLARE @LoadMode       VARCHAR(20) = 'incremental';  -- 'full' | 'incremental'
DECLARE @WatermarkDate  DATE        = '2024-01-01';   -- Min order_date to load

-- ============================================================
-- 1. Load fact.orders
-- ============================================================
IF @LoadMode = 'full'
BEGIN
    TRUNCATE TABLE fact.orders;
    PRINT 'fact.orders truncated for full load';
END

-- Delete rows that will be reloaded (avoid duplicates on incremental)
DELETE FROM fact.orders
WHERE order_date >= @WatermarkDate;

INSERT INTO fact.orders (
    order_id, customer_id, order_date_key, ship_date_key,
    order_date, ship_date, delivery_date, status,
    payment_method, shipping_method, channel, coupon_code,
    shipping_cost, discount_amount, subtotal, tax_amount, total_amount,
    days_to_ship, days_to_deliver, has_discount, dw_inserted_at
)
SELECT
    fo.order_id,
    fo.customer_id,
    dd_order.date_key                       AS order_date_key,
    dd_ship.date_key                        AS ship_date_key,
    fo.order_date,
    fo.ship_date,
    fo.delivery_date,
    fo.status,
    fo.payment_method,
    fo.shipping_method,
    fo.channel,
    fo.coupon_code,
    CAST(fo.shipping_cost   AS DECIMAL(10,2)),
    CAST(fo.discount_amount AS DECIMAL(10,2)),
    CAST(fo.subtotal        AS DECIMAL(12,2)),
    CAST(fo.tax_amount      AS DECIMAL(10,2)),
    CAST(fo.total_amount    AS DECIMAL(12,2)),
    fo.days_to_ship,
    fo.days_to_deliver,
    CAST(fo.has_discount AS BIT),
    GETDATE()
FROM RetailSalesLakehouse.gold.fact_orders fo
LEFT JOIN dim.date dd_order ON fo.order_date = dd_order.full_date
LEFT JOIN dim.date dd_ship  ON fo.ship_date  = dd_ship.full_date
WHERE fo.order_date >= @WatermarkDate;

PRINT CONCAT('fact.orders loaded: ',
    (SELECT COUNT(*) FROM fact.orders WHERE order_date >= @WatermarkDate), ' rows');

-- ============================================================
-- 2. Load fact.order_items
-- ============================================================
IF @LoadMode = 'full'
BEGIN
    TRUNCATE TABLE fact.order_items;
END

DELETE FROM fact.order_items
WHERE order_date >= @WatermarkDate;

INSERT INTO fact.order_items (
    order_item_id, order_id, product_id, customer_id,
    order_date_key, order_date, channel,
    quantity, unit_price, discount_pct, line_total, dw_inserted_at
)
SELECT
    fi.order_item_id,
    fi.order_id,
    fi.product_id,
    fi.customer_id,
    dd.date_key                             AS order_date_key,
    fi.order_date,
    fi.channel,
    fi.quantity,
    CAST(fi.unit_price   AS DECIMAL(10,2)),
    CAST(fi.discount_pct AS DECIMAL(5,2)),
    CAST(fi.line_total   AS DECIMAL(12,2)),
    GETDATE()
FROM RetailSalesLakehouse.gold.fact_order_items fi
LEFT JOIN dim.date dd ON fi.order_date = dd.full_date
WHERE fi.order_date >= @WatermarkDate;

PRINT CONCAT('fact.order_items loaded: ',
    (SELECT COUNT(*) FROM fact.order_items WHERE order_date >= @WatermarkDate), ' rows');

-- ============================================================
-- 3. Update watermark (stored in a config table)
-- ============================================================
-- NOTE: In Fabric pipelines, the new watermark is passed back
-- to the pipeline via a Lookup activity reading this table.
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='staging' AND TABLE_NAME='watermark')
BEGIN
    CREATE TABLE staging.watermark (
        table_name      VARCHAR(100) NOT NULL,
        last_load_date  DATE         NOT NULL,
        updated_at      DATETIME2    NOT NULL DEFAULT GETDATE()
    );
END

MERGE INTO staging.watermark AS target
USING (SELECT 'fact.orders' AS table_name, CAST(GETDATE() AS DATE) AS last_load_date) AS source
ON target.table_name = source.table_name
WHEN MATCHED THEN UPDATE SET
    target.last_load_date = source.last_load_date,
    target.updated_at     = GETDATE()
WHEN NOT MATCHED THEN INSERT (table_name, last_load_date)
VALUES (source.table_name, source.last_load_date);

PRINT 'Watermark updated.';
