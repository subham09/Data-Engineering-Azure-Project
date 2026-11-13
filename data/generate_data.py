"""
generate_data.py
Generates realistic synthetic retail e-commerce datasets for the
Microsoft Fabric DP-700 portfolio project.

Output:
    data/sample/customers.csv      ~10,000 rows
    data/sample/products.csv       ~500 rows
    data/sample/orders.csv         ~50,000 rows
    data/sample/order_items.csv    ~120,000 rows

Usage:
    pip install faker
    python data/generate_data.py
"""

import csv
import random
import os
from datetime import date, timedelta, datetime
from faker import Faker

random.seed(42)
fake = Faker("en_US")
Faker.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "sample")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Constants ─────────────────────────────────────────────────────────────────

NUM_CUSTOMERS   = 10_000
NUM_PRODUCTS    = 500
NUM_ORDERS      = 50_000
START_DATE      = date(2022, 1, 1)
END_DATE        = date(2024, 12, 31)

SEGMENTS        = ["Premium", "Standard", "Basic"]
SEGMENT_WEIGHTS = [0.20,      0.55,       0.25]

CATEGORIES = {
    "Electronics":  ["Audio", "Peripherals", "Wearables", "Accessories", "Cameras"],
    "Apparel":      ["Tops", "Bottoms", "Outerwear", "Activewear"],
    "Footwear":     ["Athletic", "Casual", "Outdoor", "Formal"],
    "Sports":       ["Fitness", "Recovery", "Outdoor", "Team Sports"],
    "Kitchen":      ["Cookware", "Appliances", "Drinkware", "Storage"],
    "Health":       ["Supplements", "Vitamins", "Snacks", "Personal Care"],
    "Home":         ["Lighting", "Decor", "Furniture", "Cleaning"],
    "Bags":         ["Travel", "Everyday", "Sports"],
    "Accessories":  ["Eyewear", "Jewelry", "Watches"],
}

BRANDS = [
    "SoundPro", "SpeedStep", "FlexFit", "HydroMax", "PowerTech",
    "StyleEase", "ChefMaster", "BrightHome", "NutriPro", "TypePro",
    "PackMaster", "FitTech", "BrewMaster", "ClearView", "TechEdge",
    "PureLife", "SwiftMove", "ComfortZone", "GreenLeaf", "IronCore",
]

CHANNELS        = ["Web", "Mobile", "App"]
CHANNEL_WEIGHTS = [0.55,  0.30,    0.15]

PAYMENT_METHODS = ["Credit Card", "Debit Card", "PayPal", "Apple Pay", "Google Pay"]
PAY_WEIGHTS     = [0.45,          0.20,         0.20,     0.10,        0.05]

SHIPPING        = ["Standard", "Express", "Overnight"]
SHIP_WEIGHTS    = [0.65,       0.28,      0.07]
SHIPPING_COSTS  = {"Standard": 5.99, "Express": 12.99, "Overnight": 24.99}

ORDER_STATUSES = {
    "Delivered":  0.82,
    "Shipped":    0.08,
    "Processing": 0.05,
    "Cancelled":  0.05,
}

US_STATES = [
    ("New York", "NY"), ("California", "CA"), ("Texas", "TX"),
    ("Florida", "FL"), ("Illinois", "IL"), ("Pennsylvania", "PA"),
    ("Ohio", "OH"), ("Georgia", "GA"), ("Michigan", "MI"),
    ("Washington", "WA"), ("Arizona", "AZ"), ("Colorado", "CO"),
    ("Tennessee", "TN"), ("North Carolina", "NC"), ("Indiana", "IN"),
    ("Massachusetts", "MA"), ("Virginia", "VA"), ("Nevada", "NV"),
    ("Oregon", "OR"), ("Minnesota", "MN"),
]

COUPON_CODES = [None] * 70 + [
    "SAVE10", "SAVE15", "SAVE20", "FLASH20", "VIP15",
    "VIP25", "FIRST5", "NEW5", "MARCH10", "SUMMER15",
    "FALL10", "WINTER20", "BDAY10", "LOYALTY5", "MEMBER10",
]

# ── Helpers ───────────────────────────────────────────────────────────────────

def rand_date(start: date, end: date) -> date:
    return start + timedelta(days=random.randint(0, (end - start).days))

def weighted_choice(choices, weights):
    return random.choices(choices, weights=weights, k=1)[0]

def round2(x):
    return round(x, 2)

# ── 1. Generate Customers ─────────────────────────────────────────────────────

print(f"Generating {NUM_CUSTOMERS:,} customers...")
customers = []
for i in range(1, NUM_CUSTOMERS + 1):
    dob      = rand_date(date(1960, 1, 1), date(2002, 12, 31))
    reg_date = rand_date(date(2020, 1, 1), END_DATE)
    state_city = random.choice(US_STATES)
    city     = fake.city()
    segment  = weighted_choice(SEGMENTS, SEGMENT_WEIGHTS)
    gender   = random.choice(["M", "F"])

    if gender == "F":
        first = fake.first_name_female()
    else:
        first = fake.first_name_male()
    last = fake.last_name()

    customers.append({
        "customer_id":       f"C{i:05d}",
        "first_name":        first,
        "last_name":         last,
        "email":             f"{first.lower()}.{last.lower()}{random.randint(1,99)}@{random.choice(['gmail.com','yahoo.com','outlook.com','email.com'])}",
        "phone":             f"+1-{random.randint(200,999)}-{random.randint(100,999)}-{random.randint(1000,9999)}",
        "date_of_birth":     dob.isoformat(),
        "gender":            gender,
        "city":              city,
        "state":             state_city[1],
        "country":           "USA",
        "postal_code":       f"{random.randint(10000,99999)}",
        "segment":           segment,
        "registration_date": reg_date.isoformat(),
        "is_active":         "true" if random.random() > 0.05 else "false",
    })

# ── 2. Generate Products ──────────────────────────────────────────────────────

print(f"Generating {NUM_PRODUCTS:,} products...")
products = []
product_ids = []
for i in range(1, NUM_PRODUCTS + 1):
    category    = random.choice(list(CATEGORIES.keys()))
    subcategory = random.choice(CATEGORIES[category])
    brand       = random.choice(BRANDS)
    base_price  = round2(random.uniform(9.99, 499.99))
    cost_pct    = random.uniform(0.30, 0.60)
    cost        = round2(base_price * cost_pct)
    created     = rand_date(date(2018, 1, 1), date(2021, 12, 31))
    pid         = f"P{i:04d}"
    product_ids.append(pid)

    products.append({
        "product_id":     pid,
        "product_name":   f"{brand} {subcategory} {fake.word().title()} {random.randint(100,999)}",
        "category":       category,
        "subcategory":    subcategory,
        "brand":          brand,
        "unit_price":     base_price,
        "cost_price":     cost,
        "stock_quantity": random.randint(0, 1000),
        "weight_kg":      round2(random.uniform(0.05, 5.0)),
        "is_active":      "true" if random.random() > 0.08 else "false",
        "created_date":   created.isoformat(),
    })

# ── 3. Generate Orders + Order Items ─────────────────────────────────────────

print(f"Generating {NUM_ORDERS:,} orders with line items...")

# Skew: Premium customers order more
customer_weights = []
for c in customers:
    w = {"Premium": 4, "Standard": 2, "Basic": 1}[c["segment"]]
    customer_weights.append(w)

customer_ids = [c["customer_id"] for c in customers]

orders      = []
order_items = []
item_seq    = 1

for i in range(1, NUM_ORDERS + 1):
    order_id    = f"ORD-{i:06d}"
    customer    = random.choices(customers, weights=customer_weights, k=1)[0]
    cid         = customer["customer_id"]
    order_date  = rand_date(START_DATE, END_DATE)
    channel     = weighted_choice(CHANNELS, CHANNEL_WEIGHTS)
    payment     = weighted_choice(PAYMENT_METHODS, PAY_WEIGHTS)
    shipping    = weighted_choice(SHIPPING, SHIP_WEIGHTS)
    ship_cost   = SHIPPING_COSTS[shipping]
    coupon      = random.choice(COUPON_CODES)
    status      = weighted_choice(list(ORDER_STATUSES.keys()), list(ORDER_STATUSES.values()))

    # Dates
    if status in ("Delivered", "Shipped"):
        ship_days     = random.randint(1, 3)
        deliver_days  = ship_days + random.randint(2, 7)
        ship_date     = (order_date + timedelta(days=ship_days)).isoformat()
        delivery_date = (order_date + timedelta(days=deliver_days)).isoformat() if status == "Delivered" else ""
    else:
        ship_date     = ""
        delivery_date = ""

    # Line items: 1–4 per order
    num_items = random.choices([1, 2, 3, 4], weights=[0.55, 0.28, 0.12, 0.05])[0]
    chosen_products = random.sample(product_ids, min(num_items, len(product_ids)))

    subtotal = 0.0
    for pid in chosen_products:
        product    = products[int(pid[1:]) - 1]
        qty        = random.choices([1, 2, 3], weights=[0.75, 0.20, 0.05])[0]
        unit_price = float(product["unit_price"])
        disc_pct   = random.choices([0, 5, 10, 15, 20], weights=[0.60, 0.15, 0.12, 0.08, 0.05])[0]
        line_total = round2(unit_price * qty * (1 - disc_pct / 100))
        subtotal  += line_total

        order_items.append({
            "order_item_id": f"OI-{item_seq:07d}",
            "order_id":      order_id,
            "product_id":    pid,
            "quantity":      qty,
            "unit_price":    unit_price,
            "discount_pct":  disc_pct,
            "line_total":    line_total,
        })
        item_seq += 1

    subtotal        = round2(subtotal)
    discount_amount = round2(subtotal * random.uniform(0, 0.1)) if coupon else 0.0
    tax_rate        = random.choice([0.06, 0.07, 0.08, 0.09, 0.10])
    tax_amount      = round2((subtotal - discount_amount) * tax_rate)
    total_amount    = round2(subtotal - discount_amount + tax_amount + ship_cost) if status != "Cancelled" else 0.0

    orders.append({
        "order_id":        order_id,
        "customer_id":     cid,
        "order_date":      order_date.isoformat(),
        "ship_date":       ship_date,
        "delivery_date":   delivery_date,
        "status":          status,
        "payment_method":  payment,
        "shipping_method": shipping,
        "shipping_cost":   ship_cost if status != "Cancelled" else 0.0,
        "discount_amount": discount_amount,
        "subtotal":        subtotal,
        "tax_amount":      tax_amount,
        "total_amount":    total_amount,
        "coupon_code":     coupon or "",
        "channel":         channel,
    })

# ── 4. Write CSVs ─────────────────────────────────────────────────────────────

def write_csv(filename, rows, fieldnames):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Written: {path}  ({len(rows):,} rows)")

write_csv("customers.csv",   customers,   list(customers[0].keys()))
write_csv("products.csv",    products,    list(products[0].keys()))
write_csv("orders.csv",      orders,      list(orders[0].keys()))
write_csv("order_items.csv", order_items, list(order_items[0].keys()))

print(f"\nDone. Total order items: {len(order_items):,}")
print("Run 'pip install faker' first if you haven't already.")
