# 03 — Data Pipelines

**Fabric Item:** Data Pipeline  
**DP-700 Skill:** Implement and Manage Analytics Solution > Orchestrate processes

---

## Overview

Microsoft Fabric **Data Pipelines** are the primary orchestration tool for batch workflows. Based on Azure Data Factory technology, they support visual drag-and-drop design, conditional branching, parameters, retry policies, and schedule/event-based triggers.

---

## Pipelines in This Project

| File | Description |
|---|---|
| `pipeline_definitions/master_pipeline.json` | Full end-to-end orchestration: Bronze → Silver → Gold → DW load. Daily incremental, weekly full reload. |
| `pipeline_definitions/incremental_load_pipeline.json` | Lightweight pipeline for incremental-only loads (called from master or independently) |

---

## master_pipeline.json — Activity Flow

```
Get Watermark (Lookup)
    └─► Set Watermark Variable
            └─► 01 Bronze Ingestion (Notebook)
                    └─► 02 Silver Transformation (Notebook)
                            └─► 03 Gold Aggregation (Notebook)
                                    └─► Load DW Dimensions (Script)
                                            └─► Load DW Facts (Script)

Any failure ──► On Failure - Send Alert (WebActivity)
```

---

## Key Pipeline Patterns Demonstrated

### Watermark-Based Incremental Load
A `Lookup` activity reads the last successful load date from `staging.watermark` in the DW. This value is set as a pipeline variable and passed as a parameter to each notebook.

### Parameterized Notebooks
All three notebooks accept `load_mode` and `watermark_date` as parameters. The pipeline injects these at runtime — the same notebook handles both full and incremental loads.

### Retry Policies
Each notebook activity is configured with `retry: 2, retryIntervalInSeconds: 60`. Transient Spark failures (e.g., session startup) are automatically retried before alerting.

### Failure Notification
The `On Failure` activity has `dependencyConditions: ["Failed"]` on all pipeline activities. On any failure, a Teams webhook is called with the pipeline name, run ID, and timestamp.

### Schedule Triggers
- **Daily at 06:00 UTC** → incremental load
- **Every Sunday at 02:00 UTC** → full reload

---

## Pipelines vs. Airflow (DP-700 Decision Guide)

| Criteria | Choose Pipeline | Choose Airflow |
|---|---|---|
| Team skill set | Low-code, visual | Python engineers |
| All sources are Fabric-native | Yes | Either |
| Complex dynamic task generation | No | Yes |
| External integrations | Limited | 600+ providers |
| SLA monitoring | No | Built-in |
| Backfill past dates | Manual | `airflow dags backfill` |

See `09-airflow/` for the Airflow alternative.
