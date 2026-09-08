# Batch Data Pipeline with Hadoop Ecosystem and Airflow Orchestration

**Status:** COMPLETE (5/5 days)

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

### Day 3 - Sqoop (done)

- Set up a MySQL 8.0 container (mysql-source) on hadoop-net with a sample customers table (10 rows)
- Installed Sqoop 1.4.7 inside the hadoop-sandbox container (downloaded from the Apache Attic archive, since Sqoop was retired in 2021)
- Downloaded and configured the MySQL Connector/J 8.0.33 JDBC driver
- Key debugging: Sqoop 1.4.7 (built 2017) has multiple jar version conflicts with Hadoop 3.5.0 - commons-cli, commons-lang3, and commons-io all needed manual resolution. Fixed by using commons-cli 1.4 (compatible with both Sqoop parser and Hadoop GenericOptionsParser) and removing Sqoop bundled commons-lang3/commons-io jars that were older than what Hadoop needs
- Bypassed the sqoop wrapper script and invoked Sqoop directly via java -cp with a manually ordered classpath to control which jar versions load first
- Successfully imported the customers table (10 rows) from MySQL into HDFS at /project_a/raw/customers/ using sqoop import

Commands and full debugging notes: see hive/03_sqoop_setup_and_import.sh

Result: 10/10 records transferred successfully, verified against source MySQL data
### Day 4 - PySpark (done)

- Installed Spark 3.5.7 (bin-hadoop3 build) inside the hadoop-sandbox container - no jar version conflicts this time, unlike Sqoop on Day 3, since this build targets modern Hadoop 3.x directly
- Set up a PostgreSQL 15 container (postgres-target) as the pipeline final destination
- Wrote a PySpark job (scripts/spark_transform.py) that reads orders_cleaned.csv directly from HDFS, groups by region to compute order_count and total revenue, and writes the result to PostgreSQL via JDBC
- Verified row count (1962) and revenue-by-region figures match Day 1 and Day 2 exactly
- Verified the written data by querying PostgreSQL directly

Commands and script: see hive/04_spark_setup_and_transform.sh and scripts/spark_transform.py

Result: region_summary table in PostgreSQL confirmed matching - South 1155101.46, North 1123653.85, East 1071437.21, West 579455.41
### Day 5 - Airflow Orchestration (done)

- Installed Apache Airflow 2.9.3 inside the hadoop-sandbox container using the official constraints file to avoid dependency conflicts
- Initialized the Airflow metadata database and created an admin user
- Wrote a DAG (project_a_pipeline) with two tasks chained together:
  Task 1 (sqoop_import_customers): runs Sqoop codegen then import, dynamically resolving the generated compile directory since it changes path on every run
  Task 2 (spark_transform_orders): runs the Day 4 PySpark transform job
  Dependency: sqoop_import_customers then spark_transform_orders
- Tested both tasks individually using airflow tasks test (executes for real, no scheduler required)
- Both tasks completed with SUCCESS: Sqoop retrieved 10 records, Spark processed 1962 rows and wrote region_summary to PostgreSQL

Commands and DAG: see hive/05_airflow_setup_and_dag.sh and dags/project_a_pipeline.py

Result: full pipeline (MySQL -> Sqoop -> HDFS -> Spark -> PostgreSQL) now orchestrated as a single DAG instead of manually run steps

PROJECT A COMPLETE - full 5-day batch pipeline built and verified end-to-end

## Tech Stack

- Python, Pandas
- Hadoop HDFS, Apache Hive, Sqoop, PySpark, PostgreSQL, Apache Airflow

## Folder Structure

project-a-batch-pipeline contains: data/raw, data/processed, scripts/, hive/, docs/screenshots/, notebooks/, dags/, requirements.txt







