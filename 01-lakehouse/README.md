# 01 — Lakehouse (Medallion Architecture)

**Fabric Item:** Lakehouse (`RetailSalesLakehouse`)  
**DP-700 Domain:** Ingest and Transform Data

---

## Overview

Implements a **three-layer Medallion Architecture** on Microsoft Fabric Lakehouse using Delta Lake format stored in OneLake.

```
OneLake
└── RetailSalesLakehouse/
    └── Tables/
        ├── bronze/     ← Raw ingestion (schema-on-read, no transformations)
        ├── silver/     ← Cleaned, typed, deduplicated, validated
        └── gold/       ← Business-ready: star schema dimensions, facts, aggregates
```

---

## Notebooks

| Notebook | Layer | Description | Key Concepts |
|---|---|---|---|
| `01_bronze_raw_ingestion.ipynb` | Bronze | CSV → Delta, explicit schema, audit columns | Full + incremental loads, Delta write modes |
| `02_silver_transformation.ipynb` | Silver | Type casting, dedup, DQ flags, Delta MERGE | SCD Type 1, window functions, MERGE |
| `03_gold_aggregation.ipynb` | Gold | Star schema dims/facts, aggregations, OPTIMIZE | Partitioning, Z-order, date dimension generation |

## Run Order
```
1 → 2 → 3 (sequential — each layer depends on the previous)
```

---

## Schema Layout

### Bronze Tables (raw strings — no type casting)
- `bronze.customers` — 14 cols + 5 audit cols
- `bronze.products` — 11 cols + 5 audit cols
- `bronze.orders` — 15 cols + 5 audit cols
- `bronze.order_items` — 7 cols + 5 audit cols

### Silver Tables (typed + validated)
- `silver.customers` — typed + `full_name` derived + DQ flags
- `silver.products` — typed + `margin_pct` derived + DQ flags
- `silver.orders` — typed + `days_to_ship`, `days_to_deliver` + DQ flags
- `silver.order_items` — typed + DQ flags

### Gold Tables (business-ready)
- `gold.dim_customer`, `gold.dim_product`, `gold.dim_date`
- `gold.fact_orders`, `gold.fact_order_items`
- `gold.agg_sales_daily`, `gold.agg_customer_lifetime`
