# Day 5 - Airflow Setup Commands

## 1. Install pip inside hadoop-sandbox container
sudo apt-get update && sudo apt-get install -y python3-pip

## 2. Install Airflow 2.9.3 with the official constraints file (avoids dependency conflicts)
pip3 install apache-airflow==2.9.3 --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.9.3/constraints-3.12.txt" --break-system-packages

## 3. Set environment variables and initialize the metadata database
export AIRFLOW_HOME=~/airflow
export PATH=$PATH:~/.local/bin
airflow db init

## 4. Create an admin user
airflow users create --username admin --firstname Aryan --lastname Raj --role Admin --email admin@example.com --password admin123

## 5. Create the DAG file at $AIRFLOW_HOME/dags/project_a_pipeline.py
## (see dags/project_a_pipeline.py in this repo for the full DAG code)
## DAG structure:
##   Task 1: sqoop_import_customers  (BashOperator - runs Sqoop codegen + import)
##   Task 2: spark_transform_orders  (BashOperator - runs spark-submit)
##   Dependency: sqoop_import_customers >> spark_transform_orders

## 6. Verify the DAG parses with no errors
airflow dags list-import-errors

## 7. Test each task individually (runs for real, does not require scheduler/webserver)
airflow tasks test project_a_pipeline sqoop_import_customers 2026-01-01
airflow tasks test project_a_pipeline spark_transform_orders 2026-01-01

## Result: both tasks completed with SUCCESS
##   sqoop_import_customers: Retrieved 10 records, exit code 0
##   spark_transform_orders: 1962 rows processed, region_summary written to PostgreSQL, exit code 0

## Note on the Sqoop task command:
## Because Sqoop CodeGen generates a new compile directory path on every run,
## the DAG command runs codegen first, then dynamically discovers the newest
## compile directory and includes it in the classpath before running the
## actual import. This was necessary because Airflow BashOperator runs each
## task in a fresh shell, so the manual classpath fixes from Day 3 needed to
## be fully scripted rather than run interactively.

## (Optional) Start the Airflow webserver to view the UI:
## airflow webserver --port 8081 &
## Note: requires the container to have port 8081 mapped to the host to
## access from a browser outside the container.
