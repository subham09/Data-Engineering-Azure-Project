# 08 — Monitoring & Optimization

**DP-700 Domain:** Monitor and Optimize an Analytics Solution (30–35%)

---

## Overview

Covers all monitoring and optimization patterns required for DP-700, targeting three Fabric item types: Data Pipelines, Notebooks (Spark), and Eventhouse (KQL).

---

## Files

| File | Content |
|---|---|
| `monitoring_queries.kql` | KQL queries for pipeline monitoring, data freshness, anomaly detection, duplicate detection, capacity monitoring |

---

## Monitoring Strategies

### Pipeline Monitoring
- Monitor run history via **Fabric Monitor Hub** (UI) or Fabric REST API
- Custom logging forwarded to Eventhouse for KQL analysis
- Alert on failure via **Teams webhook** (in pipeline `On Failure` activity)

### Lakehouse / Delta Lake Optimization
```sql
-- Compact small files (run after each incremental load)
OPTIMIZE bronze.orders ZORDER BY (customer_id, order_date)

-- Remove old versions to reclaim storage
VACUUM silver.orders RETAIN 168 HOURS  -- 7 days

-- Check Delta table history
DESCRIBE HISTORY gold.fact_orders LIMIT 10
```

### Data Warehouse Optimization
```sql
-- Identify slow running queries
SELECT TOP 10 *
FROM sys.dm_pdw_exec_requests
WHERE status = 'Running'
ORDER BY total_elapsed_time DESC;

-- Check table statistics (Fabric DW auto-creates these)
SELECT * FROM sys.dm_pdw_nodes_db_table_stats
WHERE object_id = OBJECT_ID('fact.orders');
```

### Eventhouse KQL Optimization
- Use **materialized views** for frequently queried aggregations
- Apply appropriate **retention policies** (short for raw events, longer for aggregates)
- Use **ingestion batching** to balance latency vs throughput
- Use `.show queries` to identify expensive queries

---

## DP-700 Monitoring Coverage

| Objective | Covered In |
|---|---|
| Monitor data ingestion | `monitoring_queries.kql` § 1, 2 |
| Monitor Eventstream health | `monitoring_queries.kql` § 3, 4 |
| Volume-based alerting | `monitoring_queries.kql` § 5 |
| Error rate monitoring | `monitoring_queries.kql` § 6 |
| Duplicate detection | `monitoring_queries.kql` § 7 |
| Slow query identification | `monitoring_queries.kql` § 8 |
| Capacity utilization | `monitoring_queries.kql` § 9 |
| Delta OPTIMIZE | `01-lakehouse/notebooks/01_bronze_raw_ingestion.ipynb` |
| Partitioning strategy | `01-lakehouse/notebooks/03_gold_aggregation.ipynb` |
