# Batch Data Pipeline with Hadoop Ecosystem and Airflow Orchestration

**Status:** In Progress (Day 2/5)

## Overview

An end-to-end batch ETL pipeline that ingests raw order data, cleans and transforms it, and moves through Hadoop (HDFS, Hive, Sqoop), Spark, and Airflow orchestration.

## Progress Log

### Day 1 - Python + SQL Refresh (done)

- Set up project repo structure
- Generated a realistic messy synthetic dataset (data/raw/orders_raw.csv) simulating duplicates, nulls, inconsistent date formats, inconsistent text casing
- Wrote scripts/clean_data.py: removes duplicates, standardizes text casing, parses inconsistent date formats, handles missing values, derives total_amount, prints a data quality report

Result: 2,060 raw rows -> 1,962 clean rows (60 duplicates removed, 38 rows with missing customer_id dropped).

### Day 2 - Hadoop HDFS and Hive (done)

- Set up a single-node HDFS cluster using apache/hadoop:3.5.0 in Docker
- Set up Hive (apache/hive:4.0.0) in a separate container on shared Docker network hadoop-net
- Key debugging fix: Docker default bridge network caused /etc/hosts to list two IPs for the same hostname, making the DataNode advertise an unreachable address. Fixed by disconnecting from the default bridge network.
- Pushed orders_cleaned.csv into HDFS at /project_a/warehouse/orders/
- Created a Hive EXTERNAL TABLE (project_a.orders_cleaned) mapped to that HDFS location
- Key debugging fix: MapReduce engine did not honor skip.header.line.count. Switched to Tez engine to fix this.
- Verified with HiveQL: row count 1962 (exact match with Day 1), revenue-by-region matches Day 1 exactly

Commands used: hive/01_hdfs_setup_commands.sh and hive/02_create_external_table.sql

Screenshots: docs/screenshots/hive_total_rows.png and docs/screenshots/hive_revenue_by_region.png

Key concept - External vs Managed tables: External table data is owned by our pipeline, DROP TABLE only removes metadata. Managed table data is owned by Hive, DROP TABLE deletes data permanently. Used EXTERNAL because the Python script controls the data lifecycle.

### Day 3 - Sqoop - coming next
### Day 4 - PySpark - coming next
### Day 5 - Airflow orchestration - coming next

## Tech Stack

- Python, Pandas
- Hadoop HDFS, Apache Hive
- Upcoming: Sqoop, PySpark, PostgreSQL, Apache Airflow

## Folder Structure

project-a-batch-pipeline contains: data/raw, data/processed, scripts/, hive/, docs/screenshots/, notebooks/, dags/, requirements.txt
