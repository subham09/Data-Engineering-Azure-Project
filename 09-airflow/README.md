# 09 — Apache Airflow Orchestration

**Fabric Item:** Apache Airflow (Job Scheduler)  
**DP-700 Skill:** Implement and Manage Analytics Solution > Configure Apache Airflow workspace settings

---

## Overview

Microsoft Fabric includes a **managed Apache Airflow** environment (powered by Azure Data Factory Managed Airflow). This provides a Kubernetes-native Airflow that integrates with your Fabric workspace without any infrastructure management.

This section demonstrates using Airflow as an **alternative to Data Pipelines** for orchestration, covering the exam objective: *"Choose between Dataflow Gen2, pipelines, and notebooks"*.

---

## When to Use Airflow vs. Data Pipelines

| Capability | Data Pipeline | Apache Airflow |
|---|---|---|
| Visual drag-and-drop UI | Yes | No (code-first) |
| Complex DAG dependencies | Limited | Native |
| Branching / conditional logic | Basic | Full Python |
| External system integration | Via connectors | 600+ providers |
| Dynamic task generation | No | Yes |
| SLA monitoring | No | Built-in |
| Backfill historical runs | Manual | `airflow dags backfill` |
| Team familiarity | Low-code teams | Python engineers |

**Rule of thumb:** Use **Data Pipelines** for straightforward Fabric-to-Fabric orchestration. Use **Airflow** when you need complex branching, external system integration, or your team already uses Airflow.

---

## DAG: `retail_sales_fabric_pipeline`

**File:** `dags/retail_sales_dag.py`

### What it does
1. Runs daily at 06:00 UTC
2. **Branches** based on day of week:
   - Sundays → full reload
   - Mon–Sat → incremental load
3. Triggers the Fabric pipeline `PL_Master_RetailSalesLoad` via **Fabric REST API**
4. **Polls** the pipeline run status every 60 seconds
5. Validates success / routes to failure notification

### DAG Graph
```
start
  └─► determine_load_mode
        ├─► set_full_load ──────┐
        └─► set_incremental_load┤
                                └─► join_branch
                                        └─► trigger_fabric_pipeline
                                                └─► poll_pipeline_status
                                                        └─► validate_pipeline_success
                                                                ├─► notify_success ──► end
                                                                └─► notify_failure ──► end
```

---

## Setup in Microsoft Fabric

1. **Enable Airflow**: Workspace Settings → Data Engineering → Apache Airflow → Enable
2. **Upload DAG**: Place `dags/retail_sales_dag.py` in the Airflow DAGs folder (sync from Git or upload directly)
3. **Configure connection**: Airflow UI → Admin → Connections → Add:
   ```
   Connection ID : fabric_api
   Connection Type: HTTP
   Host          : api.fabric.microsoft.com
   Password      : <your Bearer token or Service Principal secret>
   ```
4. **Set variables**: Airflow UI → Admin → Variables:
   ```
   fabric_workspace_id = <your workspace GUID>
   fabric_pipeline_id  = <your pipeline item GUID>
   load_mode           = incremental
   ```

---

## Key Airflow Concepts Shown

| Concept | Implementation |
|---|---|
| `BranchPythonOperator` | Route to full vs incremental load based on weekday |
| `SimpleHttpOperator` | Call Fabric REST API to trigger pipeline |
| `HttpSensor` | Poll pipeline run status until terminal state |
| `TriggerRule.ONE_SUCCESS` | Join branches regardless of which branch ran |
| `TriggerRule.ONE_FAILED` | Failure notification fires on any upstream failure |
| `mode="reschedule"` | Sensor frees worker slot while polling (efficient) |
| `max_active_runs=1` | Prevent overlapping pipeline runs |
| `Variable.get()` | Externalize config — no hardcoded IDs in DAG |
| `XCom` | Pass load mode between tasks |
| `doc_md` | DAG documentation rendered in Airflow UI |
