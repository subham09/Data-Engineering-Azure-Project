# Setup Guide
## Retail Sales Analytics Platform on Microsoft Fabric

---

## Prerequisites

- [ ] Microsoft Fabric capacity (Trial, F2, or higher)
- [ ] Microsoft 365 account with Microsoft Fabric enabled by your tenant admin
- [ ] Fabric Workspace created with at least **Contributor** role
- [ ] Python 3.9+ installed locally (for data generation scripts)
- [ ] Git installed locally

---

## Step 1: Create the Fabric Workspace

1. Go to [app.fabric.microsoft.com](https://app.fabric.microsoft.com)
2. Click **Workspaces** → **+ New workspace**
3. Name: `RetailSalesAnalytics`
4. License mode: **Fabric capacity** (select your capacity)
5. Advanced settings:
   - OneLake storage: enabled
   - Spark settings: default (can tune later)
6. Click **Apply**

---

## Step 2: Create the Lakehouse

1. Inside your workspace, click **+ New item** → **Lakehouse**
2. Name: `RetailSalesLakehouse`
3. Once created, you'll see the Lakehouse explorer with `Files/` and `Tables/`

**Upload sample data:**
1. In the Lakehouse explorer, navigate to `Files/`
2. Create a folder: `raw`
3. Upload all files from `data/sample/`:
   - `customers.csv`
   - `products.csv`
   - `orders.csv`
   - `order_items.csv`

---

## Step 3: Import and Run Notebooks

1. In your workspace, click **+ New item** → **Notebook**
2. For each notebook in `01-lakehouse/notebooks/`:
   - Click **Import notebook** → upload the `.ipynb` file
   - Or create a new notebook and paste the cell contents

**Run order:**
```
01_bronze_raw_ingestion.ipynb   →  (run first)
02_silver_transformation.ipynb  →  (run after bronze completes)
03_gold_aggregation.ipynb       →  (run after silver completes)
```

**Set the default Lakehouse:**
- In each notebook, click **Add lakehouse** → select `RetailSalesLakehouse`

---

## Step 4: Create the Data Warehouse

1. Click **+ New item** → **Warehouse**
2. Name: `RetailSalesDW`
3. Open the SQL editor and run scripts in order:
   ```
   02-data-warehouse/sql/01_create_schema.sql
   02-data-warehouse/sql/02_create_tables.sql
   02-data-warehouse/sql/03_load_dimension_tables.sql
   02-data-warehouse/sql/04_load_fact_tables.sql
   ```
4. Verify with:
   ```sql
   SELECT 'dim.customer' AS tbl, COUNT(*) AS rows FROM dim.customer UNION ALL
   SELECT 'dim.product',         COUNT(*)         FROM dim.product  UNION ALL
   SELECT 'fact.orders',         COUNT(*)         FROM fact.orders  UNION ALL
   SELECT 'fact.order_items',    COUNT(*)         FROM fact.order_items;
   ```

---

## Step 5: Create the Data Pipeline

1. Click **+ New item** → **Data pipeline**
2. Name: `PL_Master_RetailSalesLoad`
3. Build the pipeline with these activities (in order):
   - **Lookup**: Get watermark from `staging.watermark`
   - **Set Variable**: Set `WatermarkDate`
   - **Notebook**: Run `01_bronze_raw_ingestion` — pass `load_mode` and `watermark_date` parameters
   - **Notebook**: Run `02_silver_transformation`
   - **Notebook**: Run `03_gold_aggregation`
   - **Script**: Execute DW load stored procedures
4. Add a **Schedule trigger**: Daily at 6:00 AM UTC

Reference: `03-pipelines/pipeline_definitions/master_pipeline.json` for the full structure.

---

## Step 6: Create the Eventhouse (Real-Time Analytics)

1. Click **+ New item** → **Eventhouse**
2. Name: `RetailEventsDB`
3. Open the KQL editor and run:
   ```
   05-realtime-analytics/kql/01_create_eventhouse_tables.kql
   ```
4. Create an **Eventstream** to simulate order events:
   - **+ New item** → **Eventstream**
   - Name: `ES_OrderEvents`
   - Source: **Custom endpoint** (for testing) or connect to your event source
   - Destination: **KQL Database** → `RetailEventsDB` → table `OrderEvents`

---

## Step 7: Create the Semantic Model

1. In the Lakehouse or Warehouse, click **New semantic model**
2. Name: `RetailSalesSemanticModel`
3. Select tables:
   - From Gold Lakehouse: `dim_customer`, `dim_product`, `dim_date`, `fact_orders`, `fact_order_items`
   - Or from DW: `dim.customer`, `dim.product`, `dim.date`, `fact.orders`
4. Define relationships:
   - `fact_orders[customer_id]` → `dim_customer[customer_id]`
   - `fact_orders[order_date_key]` → `dim_date[date_key]`
   - `fact_order_items[product_id]` → `dim_product[product_id]`
5. Add measures (DAX):
   ```dax
   Total Revenue = SUM(fact_orders[total_amount])
   Order Count = COUNTROWS(fact_orders)
   Avg Order Value = DIVIDE([Total Revenue], [Order Count])
   ```

---

## Step 8: Apply Security Settings

Follow `07-security-governance/rbac_configuration.md` to:
- Assign workspace roles (Admin / Member / Contributor / Viewer)
- Configure OneLake folder-level access
- Apply Dynamic Data Masking on PII columns in the DW
- Set up Row-Level Security in the Semantic Model
- Apply sensitivity labels

---

## Step 9: Validate the Solution

Run these validation checks:

```sql
-- DW row counts
SELECT 'dim_customer' AS tbl, COUNT(*) AS rows FROM dim.customer UNION ALL
SELECT 'dim_product',          COUNT(*)         FROM dim.product  UNION ALL
SELECT 'fact_orders',          COUNT(*)         FROM fact.orders;

-- Data freshness
SELECT MAX(order_date) AS latest_order FROM fact.orders;

-- Revenue sanity check
SELECT SUM(total_amount) AS total_revenue FROM fact.orders WHERE status = 'Delivered';
```

```kql
// Eventhouse — confirm events flowing
OrderEvents
| where EventTimestamp > ago(1h)
| count
```

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Notebook can't find Lakehouse tables | Check that Lakehouse is attached as default; run Bronze notebook first |
| DW can't query Lakehouse tables | Ensure Lakehouse is in the same workspace; use cross-item querying |
| Eventstream not delivering to Eventhouse | Check Eventstream destination config; verify table name matches |
| Pipeline fails on incremental load | Ensure `staging.watermark` table exists; run full load first |
| Spark session timeout | Increase session timeout in notebook settings or use V-Order optimization |

---

## Cost Optimization Tips

- Use **Pause** on your Fabric capacity when not in use (trial capacities auto-pause)
- For development, use **starter pools** instead of custom Spark pools
- Schedule pipelines during off-peak hours to reduce CU consumption
- Enable **OneLake caching** for frequently queried Gold tables
- Use **materialized views** in Eventhouse instead of re-running aggregation queries
