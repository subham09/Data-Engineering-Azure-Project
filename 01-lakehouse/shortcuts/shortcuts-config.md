# OneLake Shortcuts Configuration

**DP-700 Skill:** Ingest and Transform Data > Batch Data Processing > OneLake shortcuts and mirroring

---

## What are OneLake Shortcuts?

OneLake shortcuts are **virtual pointers** to data stored in other locations — inside or outside of OneLake — without physically copying the data. They appear as folders in the Lakehouse explorer and can be queried just like native Delta tables.

---

## Shortcut Types

| Type | Use Case | Authentication |
|---|---|---|
| **Internal OneLake shortcut** | Reference data from another workspace/Lakehouse | Workspace identity |
| **Azure Data Lake Storage Gen2 (ADLS Gen2)** | Connect to existing data lake | Managed Identity or SAS |
| **Azure Blob Storage** | Connect to blob containers | Managed Identity or SAS |
| **Amazon S3** | Cross-cloud data access | AWS IAM Role |
| **Google Cloud Storage** | Cross-cloud data access | Service Account |
| **S3-Compatible storage** | MinIO or other S3-compatible stores | Access key |

---

## Shortcuts in This Project

### Shortcut 1: Shared Reference Data (Internal)
```
Source:      Workspace "SharedDataPlatform" / Lakehouse "MasterDataLakehouse"
             └── Tables/gold/dim_geography
Target:      RetailSalesLakehouse / Tables / dim_geography_shared
Purpose:     Reuse centrally-managed geography dimension without data duplication
Type:        Internal OneLake shortcut
```

**How to create in Fabric UI:**
1. Open `RetailSalesLakehouse` → **Tables** → `...` → **New shortcut**
2. Select **Microsoft OneLake**
3. Browse to: `SharedDataPlatform` workspace → `MasterDataLakehouse` → `Tables/gold/dim_geography`
4. Name the shortcut: `dim_geography_shared`

### Shortcut 2: Historical Archive (ADLS Gen2)
```
Source:      Azure Data Lake Storage Gen2
             Account: retaildatalakegen2.dfs.core.windows.net
             Container: historical-archive
             Path: /orders/2019-2022/
Target:      RetailSalesLakehouse / Files / historical_archive
Purpose:     Access pre-migration historical order data without import
Type:        ADLS Gen2 shortcut
Authentication: Workspace Managed Identity
```

---

## Shortcut vs. Mirroring

| Feature | Shortcut | Mirroring |
|---|---|---|
| Data copied? | No — virtual pointer | Yes — replicated to OneLake |
| Latency | Near-zero (reads from source) | Small lag (CDC-based sync) |
| Source changes visible? | Immediately | After next sync cycle |
| Supported sources | OneLake, ADLS, S3, GCS | Azure SQL DB, Cosmos DB, Azure SQL MI, Fabric DW |
| Best for | Large infrequently-changed data | OLTP sources needing analytics access |

### Mirroring Example: Azure SQL Database → Lakehouse
```
Source:      Azure SQL Database (RetailOLTP)
             Tables: dbo.orders, dbo.customers
Target:      RetailSalesLakehouse / Tables / mirrored_orders
Purpose:     Continuously replicate operational data to Lakehouse via CDC
Sync:        Near-real-time (Change Data Capture)
```

**Setup:** Workspace Settings → Mirroring → **+ Mirror Azure SQL Database** → Connect, select tables, configure.

---

## Query Shortcuts in Notebooks

Shortcuts appear as regular Lakehouse tables and files:

```python
# Query shortcut table via Spark (same as any native table)
df_geography = spark.read.table("dim_geography_shared")
df_geography.show()

# Read files from ADLS shortcut
df_historical = (
    spark.read
    .format("parquet")
    .load("Files/historical_archive/orders/2021/")
)
```

---

## Access Control on Shortcuts

- Shortcuts inherit the **target item's permissions** — a user needs Read access to the shortcut's **source** location to query it
- For ADLS shortcuts: the Fabric Managed Identity or Service Principal must have **Storage Blob Data Reader** on the ADLS container
- OneLake folder-level ACLs apply to shortcuts just like native folders
