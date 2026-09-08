from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "aryan",
    "retries": 1,
}

SQOOP_CMD = r"""
export HADOOP_HOME=/opt/hadoop
export SQOOP_HOME=/opt/hadoop/sqoop-1.4.7.bin__hadoop-2.6.0
rm -rf /tmp/sqoop-hadoop/compile/*
hdfs dfs -rm -r -skipTrash /project_a/raw/customers 2>/dev/null

# Run codegen first to know the exact compile dir, then import using it
java -cp "$SQOOP_HOME/lib/commons-cli-1.4.jar:$SQOOP_HOME/sqoop-1.4.7.jar:$SQOOP_HOME/lib/*:$(hadoop classpath)" \
  org.apache.sqoop.Sqoop codegen \
  --connect jdbc:mysql://mysql-source:3306/source_db \
  --username root --password rootpass --table customers

COMPILE_DIR=$(find /tmp/sqoop-hadoop/compile -maxdepth 1 -type d -newer $SQOOP_HOME/lib/commons-cli-1.4.jar | tail -1)

java -cp "$COMPILE_DIR:$SQOOP_HOME/lib/commons-cli-1.4.jar:$SQOOP_HOME/sqoop-1.4.7.jar:$SQOOP_HOME/lib/*:$(hadoop classpath)" \
  org.apache.sqoop.Sqoop import \
  --connect jdbc:mysql://mysql-source:3306/source_db \
  --username root --password rootpass \
  --table customers --target-dir /project_a/raw/customers --m 1
"""

with DAG(
    dag_id="project_a_pipeline",
    default_args=default_args,
    description="Sqoop MySQL to HDFS, then Spark transform HDFS to PostgreSQL",
    schedule_interval=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["project_a", "batch_pipeline"],
) as dag:

    sqoop_import = BashOperator(
        task_id="sqoop_import_customers",
        bash_command=SQOOP_CMD,
    )

    spark_transform = BashOperator(
        task_id="spark_transform_orders",
        bash_command=(
            "export SPARK_HOME=/opt/hadoop/spark-3.5.7-bin-hadoop3 && "
            "$SPARK_HOME/bin/spark-submit /opt/hadoop/spark_transform.py"
        ),
    )

    sqoop_import >> spark_transform
