# 06 — Semantic Model (Power BI DirectLake)

**Fabric Item:** Semantic Model (`RetailSalesSemanticModel`)  
**DP-700 Domain:** Implement and Manage Analytics Solution

---

## Overview

A **DirectLake** semantic model sitting on top of the Gold Lakehouse tables. DirectLake reads Delta files directly from OneLake — no import, no DirectQuery overhead — giving Power BI report-level performance with real-time data freshness.

---

## Star Schema

```
                    dim_date
                       │
                       │ order_date_key
                       │
dim_customer ──── fact_orders ──── (channel, payment_method)
                       │
                       │ order_id
                       │
                  fact_order_items ──── dim_product
```

### Relationships

| From | To | Cardinality | Direction |
|---|---|---|---|
| `fact_orders[customer_id]` | `dim_customer[customer_id]` | Many:1 | Single |
| `fact_orders[order_date_key]` | `dim_date[date_key]` | Many:1 | Single |
| `fact_order_items[order_id]` | `fact_orders[order_id]` | Many:1 | Single |
| `fact_order_items[product_id]` | `dim_product[product_id]` | Many:1 | Single |

---

## DAX Measures

See `model/dax_measures.dax` for the full measure library.

### Core KPIs
| Measure | Description |
|---|---|
| `[Total Revenue]` | Sum of `fact_orders[total_amount]` |
| `[Order Count]` | Count of orders |
| `[Avg Order Value]` | Revenue ÷ Order Count |
| `[Unique Customers]` | Distinct customers who ordered |
| `[Units Sold]` | Sum of `fact_order_items[quantity]` |

### Time Intelligence
| Measure | Description |
|---|---|
| `[Revenue MTD]` | Month-to-date revenue |
| `[Revenue YTD]` | Year-to-date revenue |
| `[Revenue LY]` | Same period last year |
| `[Revenue YoY %]` | Year-over-year growth percentage |
| `[Revenue MoM %]` | Month-over-month growth percentage |

### Advanced
| Measure | Description |
|---|---|
| `[Customer LTV]` | Average lifetime value per customer |
| `[Discount Rate %]` | Discounts as % of gross revenue |
| `[Avg Days to Deliver]` | Mean delivery time |
| `[New Customers]` | Customers with first order in selected period |
| `[Repeat Customer Rate]` | % customers with 2+ orders |

---

## DirectLake vs. Import vs. DirectQuery

| Mode | Data freshness | Performance | Best for |
|---|---|---|---|
| **DirectLake** | Real-time (reads Delta files) | Near-import speed | Fabric Lakehouse / DW |
| **Import** | Scheduled refresh (up to 48x/day) | Fastest (in-memory) | External sources, complex models |
| **DirectQuery** | Real-time | Slowest (live SQL per visual) | When import not feasible |

DirectLake is the **recommended mode** for Fabric-native semantic models.

---

## Setup Instructions

1. In the Lakehouse, click **New semantic model**
2. Name: `RetailSalesSemanticModel`
3. Select tables: `gold.dim_customer`, `gold.dim_product`, `gold.dim_date`, `gold.fact_orders`, `gold.fact_order_items`
4. Define relationships (see table above)
5. Open in **Model view** → add DAX measures from `model/dax_measures.dax`
6. Configure RLS roles (see `07-security-governance/rbac_configuration.md` § 3)
7. Publish to workspace → share with **Viewers**
