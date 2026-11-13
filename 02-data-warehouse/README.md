# 02 — Fabric Data Warehouse

**Fabric Item:** Warehouse (`RetailSalesDW`)  
**DP-700 Domain:** Ingest and Transform Data

---

## Overview

A **star schema dimensional model** in Microsoft Fabric Data Warehouse (built on distributed SQL engine). Sourced from Gold Lakehouse tables via cross-item querying.

---

## Schema

```
RetailSalesDW
├── dim/
│   ├── dim.date        ← Date dimension (2020–2026)
│   ├── dim.customer    ← Customer dimension with SCD Type 1 MERGE
│   ├── dim.product     ← Product dimension with SCD Type 1 MERGE
│   └── dim.channel     ← Sales channel lookup
├── fact/
│   ├── fact.orders     ← Order header fact (partitioned by order_date)
│   └── fact.order_items ← Line item fact
├── staging/
│   ├── staging.customers_load   ← Intermediate staging for MERGE
│   ├── staging.products_load
│   └── staging.watermark        ← Incremental load watermark
└── mart/
    └── mart.vw_sales_summary    ← Denormalized reporting view for Power BI
```

---

## SQL Scripts

| Script | Purpose |
|---|---|
| `01_create_schema.sql` | Create dim, fact, staging, mart schemas |
| `02_create_tables.sql` | DDL for all tables |
| `03_load_dimension_tables.sql` | MERGE-based SCD Type 1 load for dimensions |
| `04_load_fact_tables.sql` | Incremental fact table load with watermark pattern |
| `05_analytical_queries.sql` | Analytics: trends, top products, cohort analysis, window functions |

---

## Key Patterns Demonstrated

- **MERGE statement** for SCD Type 1 upserts
- **Watermark-based incremental loading** via `staging.watermark`
- **Cross-item query** from Lakehouse Gold tables into DW
- **Window functions**: `LAG()`, `SUM() OVER()`, `ROW_NUMBER()`
- **Reporting view** (`mart.vw_sales_summary`) for Power BI DirectQuery
