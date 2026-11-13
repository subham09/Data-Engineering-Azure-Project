# Data Dictionary
## Retail Sales Analytics Platform

---

## Source Tables (Bronze Layer — Raw CSV)

### customers

| Column | Type | Description | Example |
|---|---|---|---|
| `customer_id` | STRING | Unique customer identifier | `C0001` |
| `first_name` | STRING | Customer first name | `Alice` |
| `last_name` | STRING | Customer last name | `Johnson` |
| `email` | STRING | Email address | `alice.j@email.com` |
| `phone` | STRING | Phone number with country code | `+1-555-0101` |
| `date_of_birth` | STRING (raw) | Birth date YYYY-MM-DD | `1985-03-14` |
| `gender` | STRING | Gender code M/F | `F` |
| `city` | STRING | City of residence | `New York` |
| `state` | STRING | State abbreviation | `NY` |
| `country` | STRING | Country code | `USA` |
| `postal_code` | STRING | Zip/Postal code | `10001` |
| `segment` | STRING | Customer tier: Premium/Standard/Basic | `Premium` |
| `registration_date` | STRING (raw) | Account creation date | `2021-01-15` |
| `is_active` | STRING (raw) | Account active flag | `true` |

### products

| Column | Type | Description | Example |
|---|---|---|---|
| `product_id` | STRING | Unique product identifier | `P001` |
| `product_name` | STRING | Full product name | `Wireless Bluetooth Headphones` |
| `category` | STRING | Top-level category | `Electronics` |
| `subcategory` | STRING | Sub-category | `Audio` |
| `brand` | STRING | Brand name | `SoundPro` |
| `unit_price` | STRING (raw) | Selling price (USD) | `89.99` |
| `cost_price` | STRING (raw) | Cost/COGS (USD) | `42.00` |
| `stock_quantity` | STRING (raw) | Current inventory count | `250` |
| `weight_kg` | STRING (raw) | Product weight in kilograms | `0.35` |
| `is_active` | STRING (raw) | Listed/unlisted flag | `true` |
| `created_date` | STRING (raw) | Date added to catalog | `2020-01-10` |

### orders

| Column | Type | Description | Example |
|---|---|---|---|
| `order_id` | STRING | Unique order identifier | `ORD-10001` |
| `customer_id` | STRING | FK → customers.customer_id | `C0001` |
| `order_date` | STRING (raw) | Date order was placed | `2024-01-05` |
| `ship_date` | STRING (raw) | Date order was shipped (NULL if not shipped) | `2024-01-07` |
| `delivery_date` | STRING (raw) | Date order was delivered (NULL if not delivered) | `2024-01-10` |
| `status` | STRING | Order status: Delivered/Shipped/Cancelled | `Delivered` |
| `payment_method` | STRING | Payment type | `Credit Card` |
| `shipping_method` | STRING | Standard/Express | `Standard` |
| `shipping_cost` | STRING (raw) | Shipping fee (USD) | `5.99` |
| `discount_amount` | STRING (raw) | Dollar discount applied | `10.00` |
| `subtotal` | STRING (raw) | Pre-tax, pre-shipping total | `150.98` |
| `tax_amount` | STRING (raw) | Tax charged | `14.40` |
| `total_amount` | STRING (raw) | Final amount charged | `161.37` |
| `coupon_code` | STRING | Promo code applied (NULL if none) | `SAVE10` |
| `channel` | STRING | Sales channel: Web/Mobile/App | `Web` |

### order_items

| Column | Type | Description | Example |
|---|---|---|---|
| `order_item_id` | STRING | Unique line item identifier | `OI-00001` |
| `order_id` | STRING | FK → orders.order_id | `ORD-10001` |
| `product_id` | STRING | FK → products.product_id | `P001` |
| `quantity` | STRING (raw) | Units ordered | `1` |
| `unit_price` | STRING (raw) | Price at time of order | `89.99` |
| `discount_pct` | STRING (raw) | Line-level discount percentage | `0` |
| `line_total` | STRING (raw) | Extended price after discount | `89.99` |

---

## Silver Layer Additions

Silver tables add the following to Bronze:

| Column Pattern | Description |
|---|---|
| `_dq_*` | Data quality flag (Boolean) — `true` = passes validation |
| `_silver_updated_at` | Timestamp when Silver record was last written |
| `_pipeline_run_id` | Pipeline run ID for lineage tracking |
| `full_name` (customers) | Derived: `first_name + ' ' + last_name` |
| `margin_pct` (products) | Derived: `(unit_price - cost_price) / unit_price * 100` |
| `days_to_ship` (orders) | Derived: `ship_date - order_date` |
| `days_to_deliver` (orders) | Derived: `delivery_date - order_date` |

---

## Gold Layer Additions

Gold tables add business context:

| Column Pattern | Description |
|---|---|
| `date_key` (dim_date) | Integer surrogate key: YYYYMMDD |
| `price_band` (dim_product) | Budget / Mid-Range / Premium / Luxury |
| `order_date_key` (fact_orders) | FK to dim_date.date_key |
| `has_discount` (fact_orders) | Boolean: discount_amount > 0 |
| `ltv_tier` (agg_customer_lifetime) | Bronze / Silver / Gold / Platinum based on lifetime_value |
| `_gold_updated_at` | Timestamp of last Gold write |
