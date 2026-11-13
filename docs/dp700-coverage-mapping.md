# DP-700 Exam Objective Coverage Mapping

This document maps every project file to the official DP-700 exam skill areas.

**Exam:** DP-700: Implementing Data Engineering Solutions Using Microsoft Fabric  
**Study Guide:** [learn.microsoft.com/credentials/certifications/resources/study-guides/dp-700](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-700)

---

## Domain 1: Implement and Manage an Analytics Solution (30–35%)

### 1.1 Configure Microsoft Fabric workspace settings

| Objective | Covered In |
|---|---|
| Configure Spark workspace settings | `docs/setup-guide.md` → Step 3 |
| Configure OneLake workspace settings | `07-security-governance/rbac_configuration.md` § OneLake |
| Configure domain workspace settings | `docs/setup-guide.md` → Step 1 |
| Configure Apache Airflow workspace settings | `09-airflow/README.md`, `09-airflow/dags/retail_sales_dag.py` |

### 1.2 Implement lifecycle management

| Objective | Covered In |
|---|---|
| Version control configuration (Git integration) | `README.md`, `.github/workflows/validate.yml` |
| Deployment pipelines (Dev → Test → Prod) | `10-deployment-pipeline/deployment_config.md` |
| Database projects | `02-data-warehouse/sql/` — all DDL scripts |

### 1.3 Configure security and governance

| Objective | Covered In |
|---|---|
| Workspace-level access controls | `07-security-governance/rbac_configuration.md` § 1 |
| Item-level access controls | `07-security-governance/rbac_configuration.md` § 6 |
| Row-level security (RLS) | `07-security-governance/rbac_configuration.md` § 3 |
| Column-level security | `07-security-governance/rbac_configuration.md` § 5 |
| Dynamic data masking (DDM) | `07-security-governance/rbac_configuration.md` § 4 |
| Sensitivity labels | `07-security-governance/rbac_configuration.md` § 7 |
| Audit logs | `07-security-governance/rbac_configuration.md` § 8 |
| OneLake folder-level access | `07-security-governance/rbac_configuration.md` § 2 |

### 1.4 Orchestrate processes

| Objective | Covered In |
|---|---|
| Choose between Dataflow Gen2, pipelines, notebooks | `03-pipelines/README.md`, `04-dataflows/README.md` |
| Schedule triggers | `03-pipelines/pipeline_definitions/master_pipeline.json` § triggers |
| Event-based triggers | `03-pipelines/pipeline_definitions/incremental_load_pipeline.json` § StorageEventTrigger |
| Parameters and dynamic expressions | `03-pipelines/pipeline_definitions/master_pipeline.json` § parameters |
| Pipeline activity dependencies | `03-pipelines/pipeline_definitions/master_pipeline.json` § dependsOn |
| Apache Airflow DAG orchestration | `09-airflow/dags/retail_sales_dag.py` — BranchPythonOperator, HttpSensor, XCom |

---

## Domain 2: Ingest and Transform Data (30–35%)

### 2.1 Design loading patterns

| Objective | Covered In |
|---|---|
| Full load pattern | `01-lakehouse/notebooks/01_bronze_raw_ingestion.ipynb` — `load_mode=full` |
| Incremental load pattern (watermark-based) | `01-lakehouse/notebooks/01_bronze_raw_ingestion.ipynb` — `load_mode=incremental` |
| Dimensional model preparation | `01-lakehouse/notebooks/03_gold_aggregation.ipynb` — star schema Gold tables |
| Streaming data patterns | `05-realtime-analytics/kql/01_create_eventhouse_tables.kql` |

### 2.2 Batch data processing

| Objective | Covered In |
|---|---|
| Medallion architecture (Bronze/Silver/Gold) | `01-lakehouse/notebooks/` — all three notebooks |
| Choose Lakehouse vs Data Warehouse | `architecture/solution-architecture.md` |
| PySpark transformations | `01-lakehouse/notebooks/02_silver_transformation.ipynb` |
| T-SQL transformations | `02-data-warehouse/sql/05_analytical_queries.sql` |
| OneLake shortcuts and mirroring | `01-lakehouse/shortcuts/shortcuts-config.md` |
| Data profiling | `01-lakehouse/notebooks/02_silver_transformation.ipynb` — `_dq_*` columns |
| Deduplication | `01-lakehouse/notebooks/02_silver_transformation.ipynb` — window dedup |
| Aggregation | `01-lakehouse/notebooks/03_gold_aggregation.ipynb` |
| Delta MERGE (SCD Type 1) | `01-lakehouse/notebooks/02_silver_transformation.ipynb` — MERGE operations |
| Dataflow Gen2 | `04-dataflows/README.md`, `04-dataflows/dataflow_gen2/` |
| OPTIMIZE / ZORDER | `01-lakehouse/notebooks/01_bronze_raw_ingestion.ipynb` — § 6 |
| Delta time travel (versionAsOf, timestampAsOf) | `01-lakehouse/notebooks/04_delta_time_travel.ipynb` — § 2, 3 |
| RESTORE (rollback bad write) | `01-lakehouse/notebooks/04_delta_time_travel.ipynb` — § 4 |
| Schema evolution (mergeSchema, ALTER TABLE) | `01-lakehouse/notebooks/04_delta_time_travel.ipynb` — § 5 |
| V-ORDER (Fabric write optimization) | `01-lakehouse/notebooks/04_delta_time_travel.ipynb` — § 6 |
| VACUUM (storage reclamation) | `01-lakehouse/notebooks/04_delta_time_travel.ipynb` — § 7 |

### 2.3 Streaming data processing

| Objective | Covered In |
|---|---|
| Eventstream + Eventhouse | `05-realtime-analytics/kql/01_create_eventhouse_tables.kql` |
| Native tables vs OneLake shortcuts | `01-lakehouse/shortcuts/shortcuts-config.md` |
| KQL windowing functions | `05-realtime-analytics/kql/03_windowing_analytics.kql` |
| Tumbling windows | `05-realtime-analytics/kql/03_windowing_analytics.kql` § 1 |
| Sliding windows | `05-realtime-analytics/kql/03_windowing_analytics.kql` § 2 |
| Session windows | `05-realtime-analytics/kql/03_windowing_analytics.kql` § 3 |
| Late-arriving data | `05-realtime-analytics/kql/03_windowing_analytics.kql` § 4 |
| Real-time dashboards | `05-realtime-analytics/kql/02_streaming_queries.kql` |

---

## Domain 3: Monitor and Optimize an Analytics Solution (30–35%)

### 3.1 Monitor Fabric items

| Objective | Covered In |
|---|---|
| Monitor data ingestion | `08-monitoring/monitoring_queries.kql` § 1, 2 |
| Monitor transformation | `08-monitoring/monitoring_queries.kql` § 1 |
| Data freshness checks | `08-monitoring/monitoring_queries.kql` § 2 |
| Alert configuration | `08-monitoring/monitoring_queries.kql` § 5, 6 |
| Eventstream health | `08-monitoring/monitoring_queries.kql` § 3, 4 |

### 3.2 Identify and resolve errors

| Objective | Covered In |
|---|---|
| Pipeline error handling | `03-pipelines/pipeline_definitions/master_pipeline.json` — On Failure activity |
| Notebook retry logic | `03-pipelines/pipeline_definitions/master_pipeline.json` — retry policies |
| Data quality error flags | `01-lakehouse/notebooks/02_silver_transformation.ipynb` — `_dq_*` columns |
| Duplicate detection | `08-monitoring/monitoring_queries.kql` § 7 |

### 3.3 Optimize performance

| Objective | Covered In |
|---|---|
| Delta OPTIMIZE + ZORDER | `01-lakehouse/notebooks/01_bronze_raw_ingestion.ipynb` § 6 |
| Delta table partitioning | `01-lakehouse/notebooks/03_gold_aggregation.ipynb` — `partitionBy` |
| Materialized views (KQL) | `05-realtime-analytics/kql/01_create_eventhouse_tables.kql` § 3 |
| T-SQL query optimization | `02-data-warehouse/sql/05_analytical_queries.sql` — window functions |
| Slow query identification | `08-monitoring/monitoring_queries.kql` § 8 (DW DMVs) |
| Capacity monitoring | `08-monitoring/monitoring_queries.kql` § 9 |
| Ingestion batching policy | `05-realtime-analytics/kql/01_create_eventhouse_tables.kql` § 1 |

---

---

## Domain 1 Additions (New Sections)

### Apache Airflow

| Objective | Covered In |
|---|---|
| Configure Airflow workspace settings | `09-airflow/README.md` § Setup in Microsoft Fabric |
| Choose Airflow vs Pipelines | `09-airflow/README.md` § When to Use |
| DAG branching (full vs incremental) | `09-airflow/dags/retail_sales_dag.py` — `BranchPythonOperator` |
| Trigger Fabric pipeline from Airflow | `09-airflow/dags/retail_sales_dag.py` — `SimpleHttpOperator` |
| Poll job completion | `09-airflow/dags/retail_sales_dag.py` — `HttpSensor` with `mode=reschedule` |

### Deployment Pipelines

| Objective | Covered In |
|---|---|
| Dev / Test / Prod workspace setup | `10-deployment-pipeline/deployment_config.md` § Environment Setup |
| Deployment rules (connection overrides) | `10-deployment-pipeline/deployment_config.md` § Deployment Rules |
| Which item types are deployable | `10-deployment-pipeline/deployment_config.md` § What Pipelines Promote |
| Git integration with workspace | `10-deployment-pipeline/deployment_config.md` § Git Integration |
| Promotion checklists | `10-deployment-pipeline/deployment_config.md` § Promotion Checklist |

---

## Summary Table

| Domain | # Files Covering | Key Technologies |
|---|---|---|
| Implement & Manage Analytics Solution | 10 files | Pipelines, Security, RBAC, DDM, RLS, Airflow, Deployment Pipelines |
| Ingest & Transform Data | 10 files | PySpark, T-SQL, KQL, Delta Lake, Time Travel, V-ORDER, Medallion |
| Monitor & Optimize | 3 files | KQL monitoring, DMVs, Delta OPTIMIZE |
| CI/CD | 1 file | GitHub Actions (Python, SQL, KQL, CSV validation) |

**Total coverage: All DP-700 exam objectives addressed**
