# Batch Data Pipeline with Hadoop Ecosystem & Airflow Orchestration

**Status:** 🚧 In Progress (Day 1/5)

## Overview
An end-to-end batch ETL pipeline that ingests raw order data, cleans and
transforms it, and (over the coming days) will move through Hadoop (HDFS,
Hive, Sqoop), Spark, and Airflow orchestration.

## Architecture (target, by Day 5)
```
MySQL (source) --[Sqoop]--> HDFS --[Hive]--> PySpark (transform) --> PostgreSQL
                                                     ^
                                            Orchestrated by Airflow
```

## Progress Log

### Day 1 — Python + SQL Refresh ✅
- Set up project repo structure
- Generated a realistic messy synthetic dataset (`data/raw/orders_raw.csv`)
  simulating common upstream data issues: duplicates, nulls, inconsistent
  date formats, inconsistent text casing
- Wrote `scripts/clean_data.py`: a Pandas-based cleaning pipeline that:
  - Removes duplicate rows
  - Standardizes column names and text casing
  - Parses multiple inconsistent date formats into one standard format
  - Handles missing values with explicit, documented business rules
  - Derives a new `total_amount` column
  - Prints a data quality report

**Run it:**
```bash
pip install -r requirements.txt
python3 scripts/generate_raw_data.py   # generates data/raw/orders_raw.csv
python3 scripts/clean_data.py          # produces data/processed/orders_cleaned.csv
```

**Result:** 2,060 raw rows → 1,962 clean rows (60 duplicates removed, 38 rows
with missing customer_id dropped, all other nulls handled with explicit rules).

### Day 2 — Hadoop (HDFS + Hive) — *coming next*
### Day 3 — Sqoop — *coming next*
### Day 4 — PySpark — *coming next*
### Day 5 — Airflow orchestration — *coming next*

## Tech Stack
- Python, Pandas
- (Upcoming) Hadoop HDFS, Hive, Sqoop, PySpark, PostgreSQL, Apache Airflow

## Folder Structure
```
project-a-batch-pipeline/
├── data/
│   ├── raw/            # raw synthetic input data
│   └── processed/      # cleaned output
├── scripts/            # cleaning & pipeline scripts
├── notebooks/          # exploration notebooks
├── dags/               # Airflow DAGs (Day 5)
├── docs/               # architecture diagrams
└── requirements.txt
```
