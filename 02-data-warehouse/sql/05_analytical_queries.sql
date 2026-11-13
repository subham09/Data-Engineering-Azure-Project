-- ============================================================
-- Script: 05_analytical_queries.sql
-- Purpose: Analytical queries demonstrating DW capabilities
-- Fabric Item: Data Warehouse (RetailSalesDW)
-- DP-700 Skill: Ingest and Transform Data > Batch Data Processing
-- ============================================================

-- ============================================================
-- 1. Monthly Revenue Trend
-- ============================================================
SELECT
    d.year,
    d.month_number,
    d.month_name,
    d.year_month,
    COUNT(DISTINCT fo.order_id)         AS order_count,
    COUNT(DISTINCT fo.customer_id)      AS unique_customers,
    ROUND(SUM(fo.total_amount), 2)      AS total_revenue,
    ROUND(AVG(fo.total_amount), 2)      AS avg_order_value,
    ROUND(SUM(fo.discount_amount), 2)   AS total_discounts,
    ROUND(
        SUM(fo.discount_amount) / NULLIF(SUM(fo.total_amount + fo.discount_amount), 0) * 100
    , 2)                                AS discount_rate_pct
FROM fact.orders fo
JOIN dim.date d ON fo.order_date_key = d.date_key
WHERE fo.status = 'Delivered'
GROUP BY d.year, d.month_number, d.month_name, d.year_month
ORDER BY d.year, d.month_number;

-- ============================================================
-- 2. Top 10 Products by Revenue
-- ============================================================
SELECT TOP 10
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.price_band,
    COUNT(oi.order_item_id)             AS times_ordered,
    SUM(oi.quantity)                    AS units_sold,
    ROUND(SUM(oi.line_total), 2)        AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)        AS avg_selling_price
FROM fact.order_items oi
JOIN dim.product p ON oi.product_id = p.product_id
GROUP BY
    p.product_name, p.category, p.subcategory,
    p.brand, p.price_band
ORDER BY total_revenue DESC;

-- ============================================================
-- 3. Customer Segmentation by LTV
-- ============================================================
SELECT
    c.segment,
    COUNT(DISTINCT fo.customer_id)          AS customer_count,
    ROUND(SUM(fo.total_amount), 2)          AS total_revenue,
    ROUND(AVG(fo.total_amount), 2)          AS avg_order_value,
    ROUND(SUM(fo.total_amount) / COUNT(DISTINCT fo.customer_id), 2) AS avg_ltv
FROM fact.orders fo
JOIN dim.customer c ON fo.customer_id = c.customer_id
WHERE fo.status = 'Delivered'
GROUP BY c.segment
ORDER BY avg_ltv DESC;

-- ============================================================
-- 4. Channel Performance Analysis
-- ============================================================
SELECT
    fo.channel,
    d.year,
    COUNT(fo.order_id)                  AS order_count,
    ROUND(SUM(fo.total_amount), 2)      AS total_revenue,
    ROUND(AVG(fo.total_amount), 2)      AS avg_order_value,
    ROUND(
        CAST(SUM(fo.discount_amount) AS FLOAT) /
        NULLIF(CAST(SUM(fo.total_amount) AS FLOAT), 0) * 100
    , 2)                                AS discount_rate_pct,
    ROUND(AVG(CAST(fo.days_to_deliver AS FLOAT)), 1)  AS avg_delivery_days
FROM fact.orders fo
JOIN dim.date d ON fo.order_date_key = d.date_key
WHERE fo.status = 'Delivered'
GROUP BY fo.channel, d.year
ORDER BY d.year, total_revenue DESC;

-- ============================================================
-- 5. Day-over-Day Sales with Running Total (Window Functions)
-- ============================================================
WITH daily_sales AS (
    SELECT
        fo.order_date,
        d.day_name,
        d.is_weekend,
        COUNT(fo.order_id)              AS order_count,
        ROUND(SUM(fo.total_amount), 2)  AS daily_revenue
    FROM fact.orders fo
    JOIN dim.date d ON fo.order_date_key = d.date_key
    WHERE fo.status = 'Delivered'
    GROUP BY fo.order_date, d.day_name, d.is_weekend
)
SELECT
    order_date,
    day_name,
    is_weekend,
    order_count,
    daily_revenue,
    -- Running total
    ROUND(SUM(daily_revenue) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING), 2)
        AS running_total_revenue,
    -- 7-day moving average
    ROUND(AVG(daily_revenue) OVER (ORDER BY order_date ROWS 6 PRECEDING), 2)
        AS moving_avg_7day,
    -- Day-over-day change
    ROUND(daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date), 2)
        AS dod_change,
    -- DoD % change
    ROUND(
        (daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date)) /
        NULLIF(LAG(daily_revenue, 1) OVER (ORDER BY order_date), 0) * 100
    , 2)                                AS dod_pct_change
FROM daily_sales
ORDER BY order_date;

-- ============================================================
-- 6. Product Category Revenue with % of Total
-- ============================================================
SELECT
    p.category,
    p.subcategory,
    COUNT(DISTINCT oi.order_id)         AS order_count,
    SUM(oi.quantity)                    AS units_sold,
    ROUND(SUM(oi.line_total), 2)        AS category_revenue,
    ROUND(
        SUM(oi.line_total) * 100.0 /
        SUM(SUM(oi.line_total)) OVER ()
    , 2)                                AS pct_of_total_revenue
FROM fact.order_items oi
JOIN dim.product p ON oi.product_id = p.product_id
GROUP BY p.category, p.subcategory
ORDER BY category_revenue DESC;

-- ============================================================
-- 7. Cohort Analysis — Customer First Purchase by Month
-- ============================================================
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM fact.orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
cohorts AS (
    SELECT
        fo.customer_id,
        FORMAT(fi.first_order_date, 'yyyy-MM')  AS cohort_month,
        FORMAT(fo.order_date, 'yyyy-MM')         AS order_month,
        DATEDIFF(MONTH, fi.first_order_date, fo.order_date) AS months_since_first
    FROM fact.orders fo
    JOIN first_orders fi ON fo.customer_id = fi.customer_id
    WHERE fo.status = 'Delivered'
)
SELECT
    cohort_month,
    months_since_first,
    COUNT(DISTINCT customer_id)         AS active_customers,
    ROUND(SUM(COUNT(DISTINCT customer_id)) OVER (PARTITION BY cohort_month), 0) AS cohort_size
FROM cohorts
GROUP BY cohort_month, months_since_first
ORDER BY cohort_month, months_since_first;

-- ============================================================
-- 8. Create Reporting View for Power BI
-- ============================================================
CREATE OR ALTER VIEW mart.vw_sales_summary AS
SELECT
    fo.order_id,
    fo.order_date,
    d.year,
    d.quarter,
    d.month_name,
    d.year_month,
    d.day_name,
    d.is_weekend,
    fo.channel,
    fo.payment_method,
    fo.shipping_method,
    fo.status,
    fo.coupon_code,
    fo.total_amount,
    fo.discount_amount,
    fo.shipping_cost,
    fo.has_discount,
    fo.days_to_deliver,
    c.customer_id,
    c.full_name          AS customer_name,
    c.segment            AS customer_segment,
    c.city,
    c.state,
    c.country,
    NULL                 AS product_id,       -- At order level (not item level)
    NULL                 AS product_name,
    NULL                 AS category
FROM fact.orders fo
JOIN dim.date     d ON fo.order_date_key = d.date_key
JOIN dim.customer c ON fo.customer_id    = c.customer_id;

PRINT 'mart.vw_sales_summary view created.';
