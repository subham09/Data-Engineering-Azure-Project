# 10 — Deployment Pipeline (Dev → Test → Prod)

**Fabric Feature:** Deployment Pipelines  
**DP-700 Skill:** Implement and Manage Analytics Solution > Implement lifecycle management

---

## What's Here

| File | Contents |
|---|---|
| `deployment_config.md` | Full architecture, workspace config, promotion checklists, Git branching strategy, deployment rules |

---

## Quick Reference

Fabric Deployment Pipelines provide a **no-code CI/CD** workflow for promoting Fabric items across environments.

**Key concepts tested on DP-700:**
- Workspace-per-environment pattern (Dev / Test / Prod)
- Deployment rules for environment-specific connection overrides
- Which item types can be deployed (Lakehouse, DW, notebooks, pipelines, semantic models, reports)
- Git integration with Azure DevOps / GitHub
- What is promoted (structure) vs what stays in place (data)

See `deployment_config.md` for the full implementation guide.
