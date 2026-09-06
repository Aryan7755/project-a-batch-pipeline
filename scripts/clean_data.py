"""
clean_data.py
-------------
Day 1 deliverable: Reads raw messy orders data and produces a clean,
analysis-ready CSV.

Cleaning steps performed:
1. Load raw CSV
2. Standardize column names
3. Remove exact duplicate rows
4. Handle missing values (customer_id, quantity, status)
5. Standardize string casing/whitespace (region, status, product)
6. Parse inconsistent date formats into a single standard format
7. Fix data types (quantity -> int, order_date -> datetime)
8. Add a derived column (total_amount) to prove transformation logic
9. Save cleaned output + print a data quality summary
"""

import pandas as pd
import numpy as np

RAW_PATH = "data/raw/orders_raw.csv"
CLEAN_PATH = "data/processed/orders_cleaned.csv"


def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    print(f"Loaded {len(df)} rows, {len(df.columns)} columns from {path}")
    return df


def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]
    return df


def drop_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    before = len(df)
    df = df.drop_duplicates()
    print(f"Removed {before - len(df)} exact duplicate rows")
    return df


def clean_text_columns(df: pd.DataFrame) -> pd.DataFrame:
    # Strip whitespace and standardize casing for categorical text columns
    for col in ["region", "status", "product"]:
        df[col] = df[col].astype(str).str.strip().str.title()
        df[col] = df[col].replace("Nan", np.nan)  # restore true NaN after str cast
    return df


def parse_dates(df: pd.DataFrame) -> pd.DataFrame:
    def try_parse(date_str):
        for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%m-%d-%Y"):
            try:
                return pd.to_datetime(date_str, format=fmt)
            except (ValueError, TypeError):
                continue
        return pd.NaT

    df["order_date"] = df["order_date"].apply(try_parse)
    unparsed = df["order_date"].isna().sum()
    if unparsed:
        print(f"⚠️  Warning: {unparsed} dates could not be parsed")
    return df


def handle_missing_values(df: pd.DataFrame) -> pd.DataFrame:
    # customer_id missing -> can't attribute the order, drop those rows
    before = len(df)
    df = df.dropna(subset=["customer_id"])
    print(f"Dropped {before - len(df)} rows with missing customer_id")

    # quantity missing -> assume 1 (common real-world business rule)
    df["quantity"] = (
        df["quantity"].astype(str).str.strip().replace("nan", np.nan)
    )
    df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce")
    missing_qty = df["quantity"].isna().sum()
    df["quantity"] = df["quantity"].fillna(1).astype(int)
    print(f"Filled {missing_qty} missing quantity values with default 1")

    # status missing -> mark explicitly as Unknown rather than silently dropping
    missing_status = df["status"].isna().sum()
    df["status"] = df["status"].fillna("Unknown")
    print(f"Filled {missing_status} missing status values with 'Unknown'")

    return df


def add_derived_columns(df: pd.DataFrame) -> pd.DataFrame:
    df["total_amount"] = (df["quantity"] * df["unit_price"]).round(2)
    return df


def data_quality_report(df: pd.DataFrame) -> None:
    print("\n--- Data Quality Report ---")
    print(f"Final row count: {len(df)}")
    print(f"Null counts:\n{df.isnull().sum()}")
    print(f"Date range: {df['order_date'].min()} to {df['order_date'].max()}")
    print(f"Unique customers: {df['customer_id'].nunique()}")
    print(f"Unique statuses: {df['status'].unique().tolist()}")
    print(f"Unique regions: {df['region'].unique().tolist()}")


def main():
    df = load_data(RAW_PATH)
    df = standardize_columns(df)
    df = drop_duplicates(df)
    df = clean_text_columns(df)
    df = parse_dates(df)
    df = handle_missing_values(df)
    df = add_derived_columns(df)

    data_quality_report(df)

    df.to_csv(CLEAN_PATH, index=False)
    print(f"\n✅ Cleaned data saved to {CLEAN_PATH}")


if __name__ == "__main__":
    main()
