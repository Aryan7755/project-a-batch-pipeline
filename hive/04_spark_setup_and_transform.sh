# Day 4 - Spark and PostgreSQL Setup Commands

## 1. Set up PostgreSQL target container
docker run -d --name postgres-target --network hadoop-net -p 5433:5432 -e POSTGRES_PASSWORD=postgrespass -e POSTGRES_DB=analytics_db postgres:15

## 2. Download and extract Spark 3.5.7 (pre-built for Hadoop 3) inside hadoop-sandbox container
cd ~
wget https://archive.apache.org/dist/spark/spark-3.5.7/spark-3.5.7-bin-hadoop3.tgz
tar -xzf spark-3.5.7-bin-hadoop3.tgz
export SPARK_HOME=~/spark-3.5.7-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin

## 3. Verify Spark works
pyspark --version

## 4. Download PostgreSQL JDBC driver into Spark jars folder (needed to write to Postgres)
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar -P $SPARK_HOME/jars/

## 5. Run the transform job (see scripts/spark_transform.py for full code)
$SPARK_HOME/bin/spark-submit ~/spark_transform.py

## Job logic:
## - Reads orders_cleaned.csv directly from HDFS (same data as the Hive external table)
## - Groups by region, aggregates order_count and total revenue
## - Writes the result to PostgreSQL table region_summary via JDBC

## Result: 1962 rows read (exact match with Days 1-2), region summary written successfully
## Verify with: docker exec -it postgres-target psql -U postgres -d analytics_db -c "SELECT * FROM region_summary ORDER BY revenue DESC;"

## Note: no jar version conflicts encountered (unlike Sqoop on Day 3) since Spark 3.5.7
## bin-hadoop3 build is designed to be compatible with modern Hadoop 3.x out of the box.
