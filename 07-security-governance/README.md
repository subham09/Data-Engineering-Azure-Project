# 07 — Security & Governance

**DP-700 Skill:** Implement and Manage Analytics Solution > Configure security and governance (30–35%)

---

## Overview

Security and governance is one of the heaviest-weighted areas of the DP-700 exam. This section covers every security layer available in Microsoft Fabric.

---

## Files

| File | Contents |
|---|---|
| `rbac_configuration.md` | Complete security setup: workspace roles, OneLake ACLs, RLS, DDM, column-level security, sensitivity labels, audit logging, service principals |

---

## Security Layers at a Glance

```
Microsoft Entra ID (AAD)
        │
        ▼
Fabric Workspace Roles ──────────── Admin / Member / Contributor / Viewer
        │
        ▼
Item-Level Sharing ──────────────── Share individual Lakehouse, DW, reports
        │
        ├─► OneLake Folder ACLs ─── Read/Write/Execute per folder
        │
        ├─► Data Warehouse
        │       ├── Column-Level Security (DENY SELECT on columns)
        │       └── Dynamic Data Masking (email(), partial(), default())
        │
        ├─► Semantic Model
        │       └── Row-Level Security (DAX filter per role)
        │
        └─► Microsoft Purview
                ├── Sensitivity labels (Confidential, Internal, Public)
                └── Audit logs (Microsoft 365 Unified Audit Log)
```

---

## DP-700 Security Objectives Covered

| Objective | Location in rbac_configuration.md |
|---|---|
| Workspace-level access controls | § 1 — Workspace Role Assignments |
| Item-level access controls | § 6 — Item-Level Sharing |
| Row-level security (RLS) | § 3 — RLS on Semantic Model |
| Column-level security | § 5 — Column-Level Security (DW) |
| Dynamic data masking (DDM) | § 4 — DDM on PII columns |
| OneLake folder-level security | § 2 — OneLake Folder ACLs |
| Sensitivity labels | § 7 — Sensitivity Labels |
| Audit logs | § 8 — Audit Logging |
| Service principal auth | § 9 — Service Principal (CI/CD) |
