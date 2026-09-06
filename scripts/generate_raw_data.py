"""
generate_raw_data.py
---------------------
Generates a synthetic, intentionally messy "orders" dataset to simulate
real-world raw data coming from an upstream MySQL/CDC source.

Issues deliberately injected (mirrors real pipelines):
- Duplicate rows
- Missing values (nulls)
- Inconsistent date formats
- Inconsistent casing in string columns
- Wrong data types (numbers stored as strings, stray whitespace)
"""

import pandas as pd
import numpy as np
import random

random.seed(42)
np.random.seed(42)

N = 2000  # number of base rows

customers = [f"CUST{i:04d}" for i in range(1, 301)]
products = ["Laptop", "Mouse", "Keyboard", "Monitor", "Headphones", "Webcam", "Charger", "Tablet"]
regions = ["North", "South", "East", "West", "north", "SOUTH", " East "]
statuses = ["Completed", "Pending", "Cancelled", "completed", "PENDING", None]

rows = []
for i in range(1, N + 1):
    order_id = f"ORD{i:05d}"
    customer_id = random.choice(customers)
    product = random.choice(products)
    quantity = random.choice([1, 2, 3, 4, 5, None])
    unit_price = round(random.uniform(10, 1500), 2)

    # inconsistent date formats — mirrors real messy upstream data
    date_formats = [
        lambda d: d.strftime("%Y-%m-%d"),
        lambda d: d.strftime("%d/%m/%Y"),
        lambda d: d.strftime("%m-%d-%Y"),
    ]
    base_date = pd.Timestamp("2025-01-01") + pd.Timedelta(days=random.randint(0, 240))
    order_date = random.choice(date_formats)(base_date)

    region = random.choice(regions)
    status = random.choice(statuses)

    # inject some nulls in customer_id
    if random.random() < 0.02:
        customer_id = None

    # store quantity/price as string sometimes (simulating CSV export quirks)
    if random.random() < 0.15 and quantity is not None:
        quantity = str(quantity) + " "  # stray whitespace

    rows.append({
        "order_id": order_id,
        "customer_id": customer_id,
        "product": product,
        "quantity": quantity,
        "unit_price": unit_price,
        "order_date": order_date,
        "region": region,
        "status": status,
    })

df = pd.DataFrame(rows)

# Inject duplicate rows (~3%)
dup_frac = 0.03
dupes = df.sample(frac=dup_frac, random_state=1)
df = pd.concat([df, dupes], ignore_index=True)

# Shuffle rows
df = df.sample(frac=1, random_state=7).reset_index(drop=True)

output_path = "data/raw/orders_raw.csv"
df.to_csv(output_path, index=False)

print(f"✅ Generated {len(df)} rows (including duplicates) -> {output_path}")
print("\nSample rows:")
print(df.head(8).to_string())
print("\nNull counts per column:")
print(df.isnull().sum())
print(f"\nDuplicate rows: {df.duplicated().sum()}")
