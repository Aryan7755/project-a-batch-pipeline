# Day 3 - Sqoop Setup and Import Commands

## 1. Set up MySQL source container
docker run -d --name mysql-source --network hadoop-net -p 3307:3306 -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=source_db mysql:8.0

## 2. Create customers table and insert sample data
docker exec -it mysql-source mysql -uroot -prootpass source_db -e "CREATE TABLE customers (customer_id VARCHAR(20) PRIMARY KEY, customer_name VARCHAR(100), signup_date DATE, city VARCHAR(50), is_active TINYINT);"

## 3. Download Sqoop 1.4.7 inside hadoop-sandbox container
cd ~ and wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
tar -xzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
export SQOOP_HOME=~/sqoop-1.4.7.bin__hadoop-2.6.0

## 4. Download MySQL JDBC driver into Sqoop lib folder
wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar -P $SQOOP_HOME/lib/

## 5. KEY FIX: Sqoop 1.4.7 (2017) is incompatible with Hadoop 3.5.0 commons-cli 1.9.0
## Download commons-cli 1.4 which works with both Sqoop parser and Hadoop GenericOptionsParser
wget https://repo1.maven.org/maven2/commons-cli/commons-cli/1.4/commons-cli-1.4.jar -P $SQOOP_HOME/lib/

## 6. KEY FIX: remove Sqoop bundled commons-lang3 3.4 (too old for Hadoop metrics system)
mv $SQOOP_HOME/lib/commons-lang3-3.4.jar $SQOOP_HOME/lib/commons-lang3-3.4.jar.bak

## 7. KEY FIX: remove Sqoop bundled commons-io 1.4 (incompatible with Hadoop FileUtil)
mv $SQOOP_HOME/lib/commons-io-1.4.jar $SQOOP_HOME/lib/commons-io-1.4.jar.bak

## 8. Build custom classpath and run Sqoop directly via java (bypasses broken wrapper script classpath ordering)
export MYCP=SQOOP_COMPILE_DIR:$SQOOP_HOME/lib/commons-cli-1.4.jar:$SQOOP_HOME/sqoop-1.4.7.jar:$SQOOP_HOME/lib/*:$(hadoop classpath)
alias sqoop-run=java -cp "$MYCP" org.apache.sqoop.Sqoop

## 9. Test connectivity
sqoop-run list-databases --connect jdbc:mysql://mysql-source:3306 --username root --password rootpass
sqoop-run list-tables --connect jdbc:mysql://mysql-source:3306/source_db --username root --password rootpass

## 10. Import customers table from MySQL into HDFS
sqoop-run import --connect jdbc:mysql://mysql-source:3306/source_db --username root --password rootpass --table customers --target-dir /project_a/raw/customers --m 1

## Result: 10 records imported successfully
## Verify with: hdfs dfs -cat /project_a/raw/customers/part-m-00000

## IMPORTANT NOTE: after generating the customers.java/customers.jar via CodeGen,
## the exact compile directory path (shown in the CodeGenTool log output) must be
## added to the front of MYCP before running the import, otherwise the map task
## fails with ClassNotFoundException: Class customers not found. This is because
## our manual java -cp invocation bypasses the sqoop wrapper scripts automatic
## classpath handling for generated record classes.
