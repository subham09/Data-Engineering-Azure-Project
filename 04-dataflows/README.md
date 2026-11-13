# 04 — Dataflow Gen2

**Fabric Item:** Dataflow Gen2  
**DP-700 Skill:** Implement and Manage Analytics Solution > Orchestrate Processes > Choose between Dataflow Gen2, pipelines, and notebooks

---

## Overview

**Dataflow Gen2** is a low-code/no-code ETL tool in Microsoft Fabric based on Power Query. It's ideal for:
- Business analysts and non-engineers building transformations
- Standardized data prep for semantic models
- Simple to moderate transformations without Spark overhead

---

## When to Use Dataflow Gen2 vs. Alternatives

| Tool | Best For | Scale | Code Required |
|---|---|---|---|
| **Dataflow Gen2** | Low-code ETL, simple transforms, small/medium data | Up to ~1GB efficiently | No (Power Query M) |
| **Notebook (PySpark)** | Large-scale transforms, complex logic, ML prep | Petabyte-scale | Yes (Python/Scala) |
| **Data Pipeline** | Orchestration, conditional logic, activity chaining | N/A (orchestrator) | Minimal (JSON) |
| **T-SQL (DW)** | SQL-native transforms inside the warehouse | Large (distributed SQL) | Yes (SQL) |

---

## Dataflow Gen2: Customer Dimension Enrichment

### Purpose
Load and enrich the customer dimension from a CSV source with geography mapping. This shows the Power Query M approach as an alternative to the PySpark notebook method.

### Transformations Applied
1. **Connect to source**: CSV file in OneLake `Files/raw/customers.csv`
2. **Promote headers**: First row as column names
3. **Change types**: `date_of_birth`, `registration_date` → Date; `is_active` → Logical
4. **Replace values**: `"true"` / `"false"` strings → Boolean
5. **Add custom column**: `full_name = [first_name] & " " & [last_name]`
6. **Add conditional column**: `segment_rank` based on segment value
7. **Filter rows**: Remove inactive customers for this dimension slice
8. **Rename columns**: Standardize to lowercase with underscores
9. **Destination**: Lakehouse table `silver.customers_df` (alternative to notebook output)

### Power Query M — Key Snippets

```powerquery
// Step 1: Source connection
Source = Csv.Document(
    AzureStorage.Blobs("https://onelake.dfs.fabric.microsoft.com/...")[Content]{0},
    [Delimiter=",", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.None]
),

// Step 2: Promoted headers
PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

// Step 3: Type changes
ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
    {"date_of_birth",     type date},
    {"registration_date", type date},
    {"is_active",         type logical}
}),

// Step 4: Add full_name derived column
AddedFullName = Table.AddColumn(
    ChangedTypes,
    "full_name",
    each Text.Combine({[first_name], " ", [last_name]}),
    type text
),

// Step 5: Add segment rank
AddedSegmentRank = Table.AddColumn(
    AddedFullName,
    "segment_rank",
    each if [segment] = "Premium" then 1
         else if [segment] = "Standard" then 2
         else 3,
    Int64.Type
),

// Step 6: Filter active customers
FilteredActive = Table.SelectRows(
    AddedSegmentRank,
    each [is_active] = true
)
```

---

## Scheduling Dataflow Gen2

Dataflows can be scheduled independently or triggered from a Data Pipeline:

**Standalone schedule:**
- Dataflow settings → **Schedule** → Set recurrence (e.g., Daily at 7 AM)

**From Data Pipeline:**
- Add a **Dataflow** activity in the pipeline
- Select the Dataflow Gen2 item
- The pipeline waits for Dataflow completion before proceeding

---

## Dataflow Gen2 Limitations to Know (DP-700)

| Limitation | Detail |
|---|---|
| Max source data | ~1GB for best performance (use notebooks for larger data) |
| No row-level streaming | Batch only — not for real-time ingestion |
| Refresh timeout | 3 hours maximum per refresh |
| Incremental refresh | Supported via Power Query incremental refresh settings |
| Output destinations | Lakehouse, Data Warehouse, Azure SQL DB, Fabric datasets |
