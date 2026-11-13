# 05 — Real-Time Analytics (Eventhouse + KQL)

**Fabric Items:** Eventhouse (`RetailEventsDB`), Eventstream (`ES_OrderEvents`)  
**DP-700 Domain:** Ingest and Transform Data > Streaming Data Processing

---

## Overview

Implements real-time order event analytics using Microsoft Fabric's **Eventhouse** (KQL Database) and **Eventstream** for ingestion. Demonstrates all streaming data processing concepts required for DP-700.

---

## Architecture

```
Order Events (simulated)
        │
        ▼
  Eventstream (ES_OrderEvents)
        │  ← near-real-time routing
        ▼
  Eventhouse: RetailEventsDB
  ├── Table: OrderEvents        ← raw events
  ├── Table: PageviewEvents     ← clickstream
  └── Materialized View:
      OrderSummary24h           ← pre-aggregated (auto-refreshed)
```

---

## KQL Scripts

| Script | Purpose | Key Concepts |
|---|---|---|
| `01_create_eventhouse_tables.kql` | Create tables, retention policies, materialized views, update policies | Table creation, ingestion batching, `.create materialized-view` |
| `02_streaming_queries.kql` | Real-time dashboards, funnel analysis, anomaly detection | `ago()`, `bin()`, `render timechart`, `series_decompose_anomalies()` |
| `03_windowing_analytics.kql` | Tumbling, sliding, session windows; late-arriving data; forecast | `bin()`, range join, `row_cumsum()`, `series_decompose_forecast()` |

---

## DP-700 Streaming Concepts Covered

| Concept | Where |
|---|---|
| Tumbling window | `03_windowing_analytics.kql` § 1 |
| Sliding window | `03_windowing_analytics.kql` § 2 |
| Session window | `03_windowing_analytics.kql` § 3 |
| Late-arriving data handling | `03_windowing_analytics.kql` § 4 |
| Materialized views for performance | `01_create_eventhouse_tables.kql` § 3 |
| Ingestion batching policy | `01_create_eventhouse_tables.kql` § 1 |
| Retention policy | `01_create_eventhouse_tables.kql` § 1 |
| Update policy (derived columns) | `01_create_eventhouse_tables.kql` § 4 |
| Anomaly detection | `02_streaming_queries.kql` § 7 |
| Time-series forecasting | `03_windowing_analytics.kql` § 6 |
