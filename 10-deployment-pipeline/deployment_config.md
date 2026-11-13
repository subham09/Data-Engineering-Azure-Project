# Deployment Pipeline — Dev → Test → Prod
## Lifecycle Management in Microsoft Fabric

**DP-700 Skill:** Implement and Manage Analytics Solution > Implement lifecycle management > Deployment pipelines

---

## Overview

Microsoft Fabric's **Deployment Pipelines** enable a structured promotion workflow across environments, similar to CI/CD for code. Changes are developed in **Dev**, validated in **Test**, and promoted to **Prod** — all without manual item recreation.

---

## Environment Setup

```
┌─────────────────────────────────────────────────────────────┐
│                  Deployment Pipeline                        │
│                                                             │
│  ┌──────────────┐     Deploy      ┌──────────────────────┐  │
│  │     Dev      │ ─────────────► │        Test          │  │
│  │  Workspace   │                 │      Workspace       │  │
│  │              │                 │                      │  │
│  │ (engineers   │                 │ (QA validation,      │  │
│  │  develop &   │                 │  stakeholder review) │  │
│  │  test here)  │                 │                      │  │
│  └──────────────┘                 └──────────────────────┘  │
│                                            │                │
│                                    Deploy  │                │
│                                            ▼                │
│                                   ┌──────────────────────┐  │
│                                   │        Prod          │  │
│                                   │      Workspace       │  │
│                                   │                      │  │
│                                   │  (live data,         │  │
│                                   │   business users)    │  │
│                                   └──────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Workspace Configuration per Environment

### Dev Workspace
```
Name:     RetailSalesAnalytics-Dev
Capacity: F2 (minimum for development)
Access:
  - Data Engineers: Member/Contributor
  - No business users
Items:
  - All Lakehouses, DW, notebooks, pipelines (latest dev versions)
  - Spark settings: smaller cluster size
  - Data: uses sample/synthetic data only
```

### Test Workspace
```
Name:     RetailSalesAnalytics-Test
Capacity: F4
Access:
  - Data Engineers: Contributor
  - QA Team: Viewer + data validation rights
  - Business Stakeholders: Viewer (report validation)
Items:
  - Promoted from Dev via Deployment Pipeline
  - Spark settings: production-equivalent cluster
  - Data: anonymized production data (or full synthetic)
```

### Prod Workspace
```
Name:     RetailSalesAnalytics-Prod
Capacity: F8 or higher
Access:
  - Data Platform Team: Admin
  - Business Users: Viewer
  - No direct contributor access for engineers
Items:
  - Promoted from Test only (no direct edits)
  - Spark settings: production-optimized
  - Data: live production OneLake
```

---

## What Deployment Pipelines Promote

Supported Fabric items that can be deployed:

| Item Type | Notes |
|---|---|
| Lakehouse | Structure (shortcuts, settings) — data stays in source workspace |
| Data Warehouse | Schema (tables, views, stored procedures) |
| Notebooks | Code + default parameters |
| Data Pipelines | Full pipeline definition |
| Dataflow Gen2 | Query + destination config |
| Semantic Model | Model, relationships, measures, RLS |
| Reports | Report layout, visuals |
| Paginated Reports | Full report definition |
| Eventstream | Configuration (not the live stream) |

**Important:** Lakehouses are promoted as **structure only** — each environment has its own data. Connection strings and data source references are updated automatically via deployment rules.

---

## Deployment Rules (Environment-Specific Config)

Deployment rules let you **override specific settings** per environment without changing the item definition. This is how you point each environment at its own data source.

### Example: Pipeline Data Source Override

| Item | Property | Dev Value | Test Value | Prod Value |
|---|---|---|---|---|
| `PL_Master_RetailSalesLoad` | Lakehouse connection | `RetailSalesLakehouse-Dev` | `RetailSalesLakehouse-Test` | `RetailSalesLakehouse-Prod` |
| `RetailSalesSemanticModel` | Lakehouse data source | Dev Lakehouse endpoint | Test Lakehouse endpoint | Prod Lakehouse endpoint |
| `Dataflow Gen2` | Source file path | `Files/raw-dev/` | `Files/raw-test/` | `Files/raw/` |

**Configure deployment rules:**
1. Open Deployment Pipeline → select the stage
2. **Deployment rules** → Add rule
3. Select item → select property → set environment-specific value

---

## Promotion Checklist

### Dev → Test
- [ ] All notebooks run without errors on Dev Lakehouse
- [ ] Pipeline full load completed successfully
- [ ] Row counts match expected ranges
- [ ] No new DQ failures in silver layer
- [ ] Code review completed (Git PR merged)

### Test → Prod
- [ ] Business stakeholders approved report output
- [ ] Performance test: pipeline runs within SLA (< 2h)
- [ ] Security review: RLS filters verified
- [ ] Change request approved by data platform team
- [ ] Rollback plan documented (RESTORE version recorded)
- [ ] Deployment scheduled in off-peak window (weekends)

---

## Git Integration

Fabric supports Git integration (Azure DevOps / GitHub) at the workspace level.

```
Branch Strategy:
  main          ← Production state (protected, PR-only)
  release/test  ← Test state (deployed to Test workspace)
  dev/*         ← Feature branches (engineers work here)

Workflow:
  1. Engineer creates branch: dev/feature-add-returns-data
  2. Develops in Dev workspace (synced to Git branch)
  3. PR: dev/* → release/test → deploys to Test workspace
  4. PR: release/test → main → triggers Prod deployment pipeline
```

**Configure Git integration:**
Workspace Settings → Git integration → Connect to Azure DevOps or GitHub → Select repo and branch.

---

## Setting Up the Deployment Pipeline

1. Open Microsoft Fabric → **Workspaces** → select your workspace
2. Click **Deployment pipelines** (left nav) → **+ New pipeline**
3. Name: `RetailSalesAnalytics-DeployPipeline`
4. Assign workspaces to each stage: Dev / Test / Prod
5. In each stage, click **Deployment rules** → configure connection overrides
6. To deploy: select items → click **Deploy** → confirm

**Tip:** You can deploy individual items (e.g., just a notebook) or all changed items since last deployment.
