from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as spark_sum, count as spark_count, round as spark_round

spark = SparkSession.builder \
    .appName("Day4-OrdersTransform") \
    .config("spark.jars", "/opt/hadoop/spark-3.5.7-bin-hadoop3/jars/postgresql-42.7.3.jar") \
    .getOrCreate()

# Read the cleaned CSV directly from HDFS (same data our Hive external table points to)
df = spark.read.csv(
    "hdfs://172.20.0.2:9000/project_a/warehouse/orders/orders_cleaned.csv",
    header=True,
    inferSchema=True
)

print(f"Row count: {df.count()}")
df.show(5)
df.printSchema()

# Transformation: aggregate revenue by region (same business query as Day 2, now in Spark)
region_summary = df.groupBy("region").agg(
    spark_count("*").alias("order_count"),
    spark_round(spark_sum("total_amount"), 2).alias("revenue")
).orderBy(col("revenue").desc())

print("Region summary:")
region_summary.show()

# Write the transformed result to PostgreSQL
region_summary.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://postgres-target:5432/analytics_db") \
    .option("dbtable", "region_summary") \
    .option("user", "postgres") \
    .option("password", "postgrespass") \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

print("Write to PostgreSQL complete.")
spark.stop()
