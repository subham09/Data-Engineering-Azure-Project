-- ============================================================
-- Script: 02_create_tables.sql
-- Purpose: Create dimension and fact tables in the Fabric Data Warehouse
-- Fabric Item: Data Warehouse (RetailSalesDW)
-- DP-700 Skill: Ingest and Transform Data > Batch Data Processing
-- ============================================================

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- dim.date — Date Dimension
DROP TABLE IF EXISTS dim.date;
CREATE TABLE dim.date (
    date_key        INT           NOT NULL,   -- YYYYMMDD surrogate key
    full_date       DATE          NOT NULL,
    year            SMALLINT      NOT NULL,
    quarter         TINYINT       NOT NULL,
    month_number    TINYINT       NOT NULL,
    month_name      VARCHAR(10)   NOT NULL,
    month_short     CHAR(3)       NOT NULL,
    week_of_year    TINYINT       NOT NULL,
    day_of_month    TINYINT       NOT NULL,
    day_of_week     TINYINT       NOT NULL,   -- 1=Sunday, 7=Saturday
    day_name        VARCHAR(10)   NOT NULL,
    is_weekend      BIT           NOT NULL    DEFAULT 0,
    year_month      CHAR(7)       NOT NULL,   -- YYYY-MM
    year_quarter    VARCHAR(8)    NOT NULL    -- YYYY-Qn
);

-- dim.customer — Customer Dimension
DROP TABLE IF EXISTS dim.customer;
CREATE TABLE dim.customer (
    customer_id         VARCHAR(10)     NOT NULL,
    first_name          VARCHAR(50)     NULL,
    last_name           VARCHAR(50)     NULL,
    full_name           VARCHAR(100)    NULL,
    email               VARCHAR(150)    NULL,
    gender              CHAR(1)         NULL,
    date_of_birth       DATE            NULL,
    city                VARCHAR(100)    NULL,
    state               VARCHAR(50)     NULL,
    country             VARCHAR(50)     NULL,
    postal_code         VARCHAR(10)     NULL,
    segment             VARCHAR(20)     NULL,
    registration_date   DATE            NULL,
    is_active           BIT             NOT NULL    DEFAULT 1,
    dw_inserted_at      DATETIME2       NOT NULL    DEFAULT GETDATE(),
    dw_updated_at       DATETIME2       NOT NULL    DEFAULT GETDATE()
);

-- dim.product — Product Dimension
DROP TABLE IF EXISTS dim.product;
CREATE TABLE dim.product (
    product_id      VARCHAR(10)     NOT NULL,
    product_name    VARCHAR(200)    NULL,
    category        VARCHAR(50)     NULL,
    subcategory     VARCHAR(50)     NULL,
    brand           VARCHAR(50)     NULL,
    unit_price      DECIMAL(10,2)   NULL,
    cost_price      DECIMAL(10,2)   NULL,
    margin_pct      DECIMAL(5,2)    NULL,
    price_band      VARCHAR(30)     NULL,
    weight_kg       FLOAT           NULL,
    is_active       BIT             NOT NULL    DEFAULT 1,
    created_date    DATE            NULL,
    dw_inserted_at  DATETIME2       NOT NULL    DEFAULT GETDATE(),
    dw_updated_at   DATETIME2       NOT NULL    DEFAULT GETDATE()
);

-- dim.channel — Sales Channel Dimension
DROP TABLE IF EXISTS dim.channel;
CREATE TABLE dim.channel (
    channel_id      INT             NOT NULL,
    channel_name    VARCHAR(30)     NOT NULL,
    channel_type    VARCHAR(30)     NULL     -- Digital, Physical, App
);
INSERT INTO dim.channel VALUES (1, 'Web', 'Digital');
INSERT INTO dim.channel VALUES (2, 'Mobile', 'Digital');
INSERT INTO dim.channel VALUES (3, 'App', 'Digital');
INSERT INTO dim.channel VALUES (4, 'Store', 'Physical');
INSERT INTO dim.channel VALUES (-1, 'Unknown', 'Unknown');

-- ============================================================
-- FACT TABLES
-- ============================================================

-- fact.orders — Order Header Fact
DROP TABLE IF EXISTS fact.orders;
CREATE TABLE fact.orders (
    order_id            VARCHAR(20)     NOT NULL,
    customer_id         VARCHAR(10)     NULL,
    order_date_key      INT             NULL,   -- FK -> dim.date
    ship_date_key       INT             NULL,   -- FK -> dim.date
    order_date          DATE            NULL,
    ship_date           DATE            NULL,
    delivery_date       DATE            NULL,
    status              VARCHAR(20)     NULL,
    payment_method      VARCHAR(30)     NULL,
    shipping_method     VARCHAR(20)     NULL,
    channel             VARCHAR(20)     NULL,
    coupon_code         VARCHAR(20)     NULL,
    shipping_cost       DECIMAL(10,2)   NULL,
    discount_amount     DECIMAL(10,2)   NULL,
    subtotal            DECIMAL(12,2)   NULL,
    tax_amount          DECIMAL(10,2)   NULL,
    total_amount        DECIMAL(12,2)   NULL,
    days_to_ship        INT             NULL,
    days_to_deliver     INT             NULL,
    has_discount        BIT             NOT NULL    DEFAULT 0,
    dw_inserted_at      DATETIME2       NOT NULL    DEFAULT GETDATE()
);

-- fact.order_items — Order Line Item Fact
DROP TABLE IF EXISTS fact.order_items;
CREATE TABLE fact.order_items (
    order_item_id   VARCHAR(20)     NOT NULL,
    order_id        VARCHAR(20)     NOT NULL,
    product_id      VARCHAR(10)     NULL,
    customer_id     VARCHAR(10)     NULL,
    order_date_key  INT             NULL,   -- FK -> dim.date
    order_date      DATE            NULL,
    channel         VARCHAR(20)     NULL,
    quantity        INT             NULL,
    unit_price      DECIMAL(10,2)   NULL,
    discount_pct    DECIMAL(5,2)    NULL,
    line_total      DECIMAL(12,2)   NULL,
    dw_inserted_at  DATETIME2       NOT NULL    DEFAULT GETDATE()
);

-- ============================================================
-- STAGING TABLES (used for CTAS / bulk load operations)
-- ============================================================

DROP TABLE IF EXISTS staging.customers_load;
CREATE TABLE staging.customers_load (
    customer_id         VARCHAR(10),
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    full_name           VARCHAR(100),
    email               VARCHAR(150),
    gender              CHAR(1),
    date_of_birth       DATE,
    city                VARCHAR(100),
    state               VARCHAR(50),
    country             VARCHAR(50),
    postal_code         VARCHAR(10),
    segment             VARCHAR(20),
    registration_date   DATE,
    is_active           BIT
);

DROP TABLE IF EXISTS staging.products_load;
CREATE TABLE staging.products_load (
    product_id      VARCHAR(10),
    product_name    VARCHAR(200),
    category        VARCHAR(50),
    subcategory     VARCHAR(50),
    brand           VARCHAR(50),
    unit_price      DECIMAL(10,2),
    cost_price      DECIMAL(10,2),
    margin_pct      DECIMAL(5,2),
    price_band      VARCHAR(30),
    weight_kg       FLOAT,
    is_active       BIT,
    created_date    DATE
);

PRINT 'All tables created successfully.';
