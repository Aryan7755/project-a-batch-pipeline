-- Day 2 - Hive Setup & External Table DDL
-- Hive container: apache/hive:4.0.0, networked to hadoop-sandbox via hadoop-net

## 1. Run Hive container (config mounted from host to point at real HDFS)
-- core-site.xml on host (hive-config/core-site.xml) contains:
--   fs.defaultFS = hdfs://172.20.0.2:9000   (the hadoop-sandbox container's hadoop-net IP)

docker run -d --name hive-server --network hadoop-net -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 -v C:\Users\aryan\project-a-batch-pipeline\hive-config\core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml apache/hive:4.0.0

## 2. Connect via Beeline
docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000

## 3. Create database
CREATE DATABASE IF NOT EXISTS project_a;
USE project_a;

## 4. Create external table over HDFS data
CREATE EXTERNAL TABLE IF NOT EXISTS orders_cleaned (
    order_id      STRING,
    customer_id   STRING,
    product       STRING,
    quantity      INT,
    unit_price    DOUBLE,
    order_date    DATE,
    region        STRING,
    status        STRING,
    total_amount  DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 'hdfs://172.20.0.2:9000/project_a/warehouse/orders/'
TBLPROPERTIES ("skip.header.line.count"="1");

## 5. Verify table
SHOW TABLES;
DESCRIBE FORMATTED orders_cleaned;

## 6. IMPORTANT: use Tez engine, not MapReduce
-- MapReduce engine does not honor skip.header.line.count in this Hive version,
-- causing the CSV header row to be read as a data row. Tez respects it correctly.
SET hive.execution.engine=tez;

## 7. Verification queries (results confirmed to match Day 1 Pandas output)
SELECT COUNT(*) AS total_rows FROM orders_cleaned;
-- Result: 1962 (matches Day 1 cleaned CSV exactly)

SELECT * FROM orders_cleaned LIMIT 5;

SELECT region, COUNT(*) AS order_count, ROUND(SUM(total_amount), 2) AS revenue
FROM orders_cleaned
GROUP BY region
ORDER BY revenue DESC;
-- Result:
-- South | 582 | 1155101.46
-- North | 561 | 1123653.85
-- East  | 541 | 1071437.21
-- West  | 278 | 579455.41

## NOTE ON EXTERNAL VS MANAGED TABLES:
-- We used EXTERNAL TABLE because our Python pipeline (not Hive) owns the
-- data lifecycle. Dropping this table removes only the Hive metadata;
-- the underlying files stay in HDFS. A MANAGED table would instead copy
-- the data into Hive's own warehouse directory, and DROP TABLE would
-- permanently delete it -- wrong choice here since an external process
-- (our cleaning script) produces and updates this data.
