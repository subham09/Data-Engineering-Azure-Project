# Security & Governance Configuration
## Retail Sales Analytics Platform — Microsoft Fabric

**DP-700 Skill:** Implement and Manage Analytics Solution > Configure Security and Governance

---

## 1. Workspace Role Assignments

Microsoft Fabric workspaces use four built-in roles. The principle of least privilege is applied.

| Role | Assigned To | Permissions |
|---|---|---|
| **Admin** | Data Platform Team | Full control: manage access, configure settings, deploy items |
| **Member** | Senior Data Engineers | Create/edit/delete all items, share with external users |
| **Contributor** | Data Engineers | Create/edit items, cannot share or manage access |
| **Viewer** | Business Analysts, BI Developers | Read-only: view reports, query semantic models |

```
Workspace: RetailSalesAnalytics
├── Admins:
│   └── data-platform-team@company.com
├── Members:
│   └── senior-de-group@company.com
├── Contributors:
│   ├── de-team@company.com
│   └── dataflows-service-principal (for automated Dataflow Gen2 runs)
└── Viewers:
    ├── bi-team@company.com
    └── business-analysts@company.com
```

---

## 2. OneLake Folder-Level Access Control

OneLake supports POSIX-style ACLs at the folder level. Applied to the Lakehouse.

```
RetailSalesLakehouse (OneLake)
├── Files/
│   ├── raw/                    → Contributor: DE Team only
│   │                             (source CSV files — restricted write)
│   └── exports/                → Contributor: All engineers
└── Tables/
    ├── bronze/                 → Contributor: DE Team only
    │                             (raw data — no external read)
    ├── silver/                 → Read: BI Team, Analysts
    │                             Write: DE Team only
    └── gold/                   → Read: All workspace members
                                  Write: DE Team only
```

**How to configure (Fabric UI):**
1. Open Lakehouse → `...` menu → **Manage OneLake data access**
2. Select folder → **Add role assignment**
3. Choose permission level: Read / Write / Execute
4. Assign to AAD users, groups, or service principals

---

## 3. Row-Level Security (RLS) — Semantic Model

RLS restricts what rows a report viewer can see based on their identity.

**Use case:** Regional managers see only their region's orders.

### DAX RLS Role Definition

```dax
-- Role: RegionManager
-- Applied to table: fact_orders

[Region] = LOOKUPVALUE(
    dim_user[Region],
    dim_user[Email],
    USERPRINCIPALNAME()
)
```

**Setup in Power BI / Semantic Model:**
1. Open Semantic Model in Fabric workspace
2. **Modeling** tab → **Manage roles**
3. Create role `RegionManager` with the DAX filter above
4. Test with **View as role** before publishing
5. Assign users/groups to the role from **Security** settings

---

## 4. Dynamic Data Masking (DDM) — Data Warehouse

DDM obscures PII data from unauthorized users without changing stored values.

```sql
-- Apply Dynamic Data Masking on PII columns in dim.customer
ALTER TABLE dim.customer
ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');
-- email() mask: shows first letter and domain: a***@company.com

ALTER TABLE dim.customer
ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'partial(2,"XXX-XXX-",4)');
-- Shows: +1-XXX-XXX-0101

ALTER TABLE dim.customer
ALTER COLUMN date_of_birth ADD MASKED WITH (FUNCTION = 'default()');
-- Shows: 1900-01-01 (default mask for dates)

-- Grant UNMASK to privileged roles
GRANT UNMASK ON dim.customer TO [data-platform-team@company.com];
GRANT UNMASK ON dim.customer TO [senior-de-group@company.com];

-- Analysts and BI team see masked values — no special grant needed
```

---

## 5. Column-Level Security — Data Warehouse

Restrict access to sensitive columns (e.g., cost_price).

```sql
-- Deny BI analysts from seeing cost/margin data
DENY SELECT ON dim.product (cost_price, margin_pct)
TO [bi-team@company.com];

-- Create a view that omits sensitive columns for analysts
CREATE VIEW mart.vw_products_public AS
SELECT
    product_id,
    product_name,
    category,
    subcategory,
    brand,
    unit_price,
    price_band,
    is_active
    -- cost_price and margin_pct intentionally omitted
FROM dim.product;

GRANT SELECT ON mart.vw_products_public TO [bi-team@company.com];
```

---

## 6. Item-Level Sharing

Individual Fabric items (notebooks, pipelines, lakehouses) can be shared independently.

```
Lakehouse: RetailSalesLakehouse
├── Shared with "BI Team" group → ReadAll permission (can query all tables)
└── NOT shared with external guests

Data Warehouse: RetailSalesDW
├── Shared with "BI Team" → ReadData (execute SELECT queries)
├── SQL analytics endpoint → accessible to Power BI Desktop via XMLA

Semantic Model: RetailSalesSemanticModel
├── Build permission → BI Team (can create new reports)
└── Read permission → All workspace viewers
```

---

## 7. Sensitivity Labels

Microsoft Purview sensitivity labels classify and protect data assets.

| Item | Label | Justification |
|---|---|---|
| `bronze.customers` | **Confidential — PII** | Contains raw email, phone, DOB |
| `silver.customers` | **Confidential — PII** | Cleaned but still contains PII |
| `gold.dim_customer` | **Confidential — PII** | PII retained for analytics |
| `gold.fact_orders` | **Internal** | Order data, no direct PII |
| `RetailSalesDW` | **Confidential** | Contains aggregated PII-adjacent data |
| `Semantic Model` | **Internal** | Aggregated metrics, no raw PII |

**Apply labels:**
1. Open item in Fabric workspace
2. **Settings** → **Sensitivity label**
3. Select from your organization's label taxonomy
4. Labels propagate to downstream items (Power BI reports, exports)

---

## 8. Audit Logging

All Fabric workspace activities are captured in the Microsoft 365 audit log.

**Key events to monitor:**
- `FabricPipelineRunCompleted` — Pipeline executions
- `LakehouseFileUploaded` — Data uploads to OneLake
- `SemanticModelRefreshCompleted` — Report data refreshes
- `WorkspaceMemberAdded/Removed` — Access changes
- `ItemPermissionChanged` — Sharing events

**Query audit logs (PowerShell / REST API):**
```powershell
# Search audit logs via Microsoft Purview
Search-UnifiedAuditLog `
  -StartDate (Get-Date).AddDays(-7) `
  -EndDate (Get-Date) `
  -RecordType PowerBI `
  -Operations "FabricPipelineRunCompleted","LakehouseFileUploaded" `
  | Export-Csv audit_log.csv -NoTypeInformation
```

---

## 9. Service Principal Authentication (for CI/CD)

Pipelines and deployment scripts authenticate via a service principal (not user credentials).

```json
{
  "service_principal": {
    "name": "sp-retail-analytics-fabric",
    "role": "Contributor",
    "scopes": ["workspace:RetailSalesAnalytics"],
    "credential_store": "Azure Key Vault (kv-retail-analytics)",
    "secret_name": "sp-fabric-client-secret",
    "rotation_policy": "90 days"
  }
}
```

**Never** store service principal credentials in notebooks, pipeline JSON, or Git repositories.
