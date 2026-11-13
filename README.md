# Microsoft Fabric DP-700 Portfolio Project
## Retail Sales Analytics Platform

![Microsoft Fabric](https://img.shields.io/badge/Microsoft%20Fabric-DP--700-0078D4?style=for-the-badge&logo=microsoft)
![Azure](https://img.shields.io/badge/Azure-Data%20Engineering-0078D4?style=for-the-badge&logo=microsoftazure)
![PySpark](https://img.shields.io/badge/PySpark-3.x-E25A1C?style=for-the-badge&logo=apachespark)
![SQL](https://img.shields.io/badge/T--SQL-Fabric%20DW-CC2927?style=for-the-badge&logo=microsoftsqlserver)
![KQL](https://img.shields.io/badge/KQL-Eventhouse-0078D4?style=for-the-badge&logo=microsoft)
![Airflow](https://img.shields.io/badge/Apache%20Airflow-Fabric-017CEE?style=for-the-badge&logo=apacheairflow)
![CI](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?style=for-the-badge&logo=githubactions)

---

## Overview

This repository contains an end-to-end **Retail Sales Analytics Platform** built entirely on **Microsoft Fabric**, demonstrating proficiency in all skill areas covered by the **DP-700: Implementing Data Engineering Solutions Using Microsoft Fabric** certification.

The project implements a production-grade analytics solution for a fictional e-commerce retailer, covering batch data processing, real-time event streaming, dimensional modeling, semantic layers, and operational monitoring.

---

## Architecture

```
                        ┌─────────────────────────────────────────────────────────┐
                        │                  Microsoft Fabric Workspace              │
                        │                                                         │
  ┌──────────┐          │  ┌──────────────────────────────────────────────────┐   │
  │ Source   │          │  │                    OneLake                        │   │
  │ Systems  │          │  │                                                  │   │
  │          │  Pipeline│  │  ┌──────────┐   ┌──────────┐   ┌──────────┐    │   │
  │ CSV/API  ├─────────►│  │  │  Bronze  │──►│  Silver  │──►│   Gold   │    │   │
  │ REST API │          │  │  │  (Raw)   │   │ (Cleaned)│   │(Aggregated│   │   │
  │ DB Src   │          │  │  └──────────┘   └──────────┘   └──────────┘    │   │
  └──────────┘          │  │                                                  │   │
                        │  │              Lakehouse (Delta Lake)               │   │
                        │  └──────────────────────────────────────────────────┘   │
                        │                         │                               │
  ┌──────────┐          │                         ▼                               │
  │  Real-   │          │  ┌─────────────────────────────────────────────────┐   │
  │  Time    │ Eventstr.│  │         Fabric Data Warehouse                    │   │
  │  Events  ├─────────►│  │   (Dimensional Model: Star Schema)               │   │
  │          │          │  └─────────────────────────────────────────────────┘   │
  └──────────┘          │                         │                               │
                        │                         ▼                               │
                        │  ┌─────────────────────────────────────────────────┐   │
                        │  │       Semantic Model + Power BI Reports          │   │
                        │  │           (DirectLake Mode)                      │   │
                        │  └─────────────────────────────────────────────────┘   │
                        │                                                         │
                        │  ┌──────────────────┐   ┌─────────────────────────┐   │
                        │  │   Eventhouse      │   │  Monitoring & Alerts    │   │
                        │  │   (KQL Database)  │   │  (Fabric Monitor Hub)   │   │
                        │  └──────────────────┘   └─────────────────────────┘   │
                        └─────────────────────────────────────────────────────────┘
```

---

## DP-700 Exam Coverage

| Skill Area | Weight | Project Coverage |
|---|---|---|
| Implement and Manage Analytics Solution | 30-35% | Workspace config, security, deployment pipelines, orchestration |
| Ingest and Transform Data | 30-35% | Medallion architecture, Dataflows Gen2, PySpark notebooks, T-SQL |
| Monitor and Optimize Analytics Solution | 30-35% | Monitor hub queries, performance optimization, error handling |

---

## Project Structure

```
retail-sales-analytics-fabric/
├── README.md                          # This file
├── architecture/
│   └── solution-architecture.md       # Detailed architecture documentation
├── 01-lakehouse/                      # Medallion Architecture (Bronze/Silver/Gold)
│   ├── README.md
│   ├── notebooks/
│   │   ├── 01_bronze_raw_ingestion.ipynb
│   │   ├── 02_silver_transformation.ipynb
│   │   └── 03_gold_aggregation.ipynb
│   └── shortcuts/
│       └── shortcuts-config.md
├── 02-data-warehouse/                 # Fabric Data Warehouse
│   ├── README.md
│   └── sql/
│       ├── 01_create_schema.sql
│       ├── 02_create_tables.sql
│       ├── 03_load_dimension_tables.sql
│       ├── 04_load_fact_tables.sql
│       └── 05_analytical_queries.sql
├── 03-pipelines/                      # Data Pipeline Orchestration
│   ├── README.md
│   └── pipeline_definitions/
│       ├── master_pipeline.json
│       └── incremental_load_pipeline.json
├── 04-dataflows/                      # Dataflow Gen2 Transformations
│   ├── README.md
│   └── dataflow_gen2/
│       └── customer_dim_dataflow.json
├── 05-realtime-analytics/             # Eventhouse + KQL
│   ├── README.md
│   └── kql/
│       ├── 01_create_eventhouse_tables.kql
│       ├── 02_streaming_queries.kql
│       └── 03_windowing_analytics.kql
├── 06-semantic-model/                 # Power BI Semantic Model (DirectLake)
│   ├── README.md
│   └── model/
│       └── dax_measures.dax           # Full DAX measure library (30+ measures)
├── 07-security-governance/            # RBAC, RLS, DDM, Sensitivity Labels
│   ├── README.md
│   └── rbac_configuration.md
├── 08-monitoring/                     # Monitoring & Optimization
│   ├── README.md
│   └── monitoring_queries.kql
├── 09-airflow/                        # Apache Airflow Orchestration
│   ├── README.md
│   └── dags/
│       └── retail_sales_dag.py        # Airflow DAG with branching + Fabric API
├── 10-deployment-pipeline/            # Dev → Test → Prod Lifecycle
│   ├── README.md
│   └── deployment_config.md
├── .github/
│   └── workflows/
│       └── validate.yml               # GitHub Actions CI (Python, SQL, KQL, CSV)
├── data/
│   ├── generate_data.py               # Synthetic data generator (10K+ rows)
│   ├── sample/                        # Sample CSV datasets
│   │   ├── customers.csv
│   │   ├── products.csv
│   │   ├── orders.csv
│   │   └── order_items.csv
│   └── schemas/
│       └── data_dictionary.md
└── docs/
    ├── setup-guide.md                 # Step-by-step setup instructions
    └── dp700-coverage-mapping.md      # Maps each file to DP-700 objectives
```

---

## Dataset

The project uses a synthetic **Retail E-Commerce** dataset:

| Table | Rows | Description |
|---|---|---|
| `customers` | ~10,000 | Customer demographics and segments |
| `products` | ~500 | Product catalog with categories |
| `orders` | ~50,000 | Order headers with status and dates |
| `order_items` | ~120,000 | Line items with quantities and prices |

---

## Technologies Used

| Technology | Purpose |
|---|---|
| **Microsoft Fabric Lakehouse** | Delta Lake storage for medallion layers |
| **Apache Spark (PySpark)** | Large-scale data transformation |
| **Fabric Data Warehouse** | Star schema dimensional model |
| **T-SQL** | Warehouse queries and stored procedures |
| **Data Pipelines** | Orchestration, scheduling, incremental loads |
| **Dataflow Gen2** | Low-code ETL with Power Query M |
| **Eventhouse (KQL Database)** | Real-time analytics |
| **KQL (Kusto Query Language)** | Time-series and streaming queries |
| **Semantic Model** | DirectLake Power BI model with 30+ DAX measures |
| **OneLake Shortcuts** | Cross-workspace data federation |
| **Apache Airflow** | Fabric-managed Airflow DAG with Fabric REST API integration |
| **Deployment Pipelines** | Dev → Test → Prod promotion with deployment rules |
| **Delta Time Travel** | RESTORE, schema evolution, V-ORDER, VACUUM |
| **GitHub Actions** | CI validation for notebooks, SQL, KQL, and sample data |

---

## Key Concepts Demonstrated

### Medallion Architecture
- **Bronze Layer**: Raw ingestion from CSV, REST APIs, and databases — no transformations, schema-on-read
- **Silver Layer**: Cleaned, deduplicated, type-cast, standardized data with schema enforcement
- **Gold Layer**: Business-ready aggregated tables for reporting and analytics

### Incremental Loading
- Watermark-based incremental loads using pipeline parameters
- Delta Lake `MERGE` operations for upserts (SCD Type 1)
- Change Data Capture (CDC) pattern implementation

### Real-Time Analytics
- Eventstream ingestion from simulated order events
- KQL windowing functions (tumbling, sliding, session windows)
- Streaming aggregations with real-time dashboards

### Security & Governance
- Workspace roles (Admin, Member, Contributor, Viewer)
- Row-Level Security (RLS) on the semantic model
- Dynamic Data Masking (DDM) on PII columns
- OneLake folder-level access control
- Sensitivity labels on Lakehouse items

---

## Getting Started

See [docs/setup-guide.md](docs/setup-guide.md) for step-by-step instructions to deploy this solution in your own Microsoft Fabric workspace.

**Prerequisites:**
- Microsoft Fabric capacity (F2 or higher, or trial)
- Microsoft 365 account with Fabric enabled
- Basic familiarity with PySpark, SQL, and Power BI

---

## Certification Reference

This project maps to the **DP-700 exam objectives** as documented in [docs/dp700-coverage-mapping.md](docs/dp700-coverage-mapping.md).

Official study guide: [learn.microsoft.com/credentials/certifications/resources/study-guides/dp-700](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-700)

---

## Author

**Subham** | Microsoft Fabric DP-700 Certified Data Engineer

---

*Built as a portfolio project to demonstrate hands-on proficiency in Microsoft Fabric data engineering.*
