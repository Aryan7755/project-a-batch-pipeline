# Day 2 - HDFS Setup Commands (apache/hadoop:3.5.0 via Docker)

## 1. Pull and run the HDFS container
docker pull apache/hadoop:3.5.0
docker run -itd --name hadoop-sandbox -p 9870:9870 -p 8088:8088 apache/hadoop:3.5.0
docker exec -it hadoop-sandbox bash

## 2. Configure core-site.xml (inside container)
export HADOOP_HOME=/opt/hadoop
cat > $HADOOP_HOME/etc/hadoop/core-site.xml << 'EOF'
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://172.20.0.2:9000</value>
  </property>
</configuration>
EOF

## 3. Configure hdfs-site.xml (fixes DataNode advertising wrong IP in Docker)
cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml << 'EOF'
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/tmp/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/tmp/hdfs/datanode</value>
  </property>
  <property>
    <name>dfs.datanode.use.datanode.hostname</name>
    <value>false</value>
  </property>
  <property>
    <name>dfs.client.use.datanode.hostname</name>
    <value>false</value>
  </property>
  <property>
    <name>dfs.datanode.address</name>
    <value>0.0.0.0:9866</value>
  </property>
  <property>
    <name>dfs.datanode.http.address</name>
    <value>0.0.0.0:9864</value>
  </property>
  <property>
    <name>dfs.datanode.ipc.address</name>
    <value>0.0.0.0:9867</value>
  </property>
  <property>
    <name>dfs.datanode.hostname</name>
    <value>172.20.0.2</value>
  </property>
</configuration>
EOF

## 4. Set up passwordless SSH (required by Hadoop start scripts)
apt-get update && apt-get install -y openssh-server openssh-client vim
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
service ssh start
ssh localhost

## 5. Fix log directory ownership (root vs hadoop user permission conflict)
sudo chown -R hadoop:users /opt/hadoop/logs

## 6. Format NameNode (only needed first time / after wiping data dirs)
mkdir -p /tmp/hdfs/namenode /tmp/hdfs/datanode
hdfs namenode -format -force

## 7. Start HDFS daemons
$HADOOP_HOME/sbin/start-dfs.sh
jps
# Expect: NameNode, DataNode, SecondaryNameNode

## 8. IMPORTANT: disconnect container from default bridge network
# (Docker's default bridge network causes /etc/hosts to have two IPs for the
#  same hostname, which makes the DataNode advertise an unreachable address
#  to other containers like Hive. Run this from the HOST, not inside container.)
docker network create hadoop-net
docker network connect hadoop-net hadoop-sandbox
docker network disconnect bridge hadoop-sandbox

## 9. Verify HDFS is healthy
hdfs dfsadmin -report
# Check "Live datanodes" shows the hadoop-net IP (e.g. 172.20.0.2), not 127.0.0.1

## 10. Load data into HDFS
# From HOST machine:
docker cp data/processed/orders_cleaned.csv hadoop-sandbox:/tmp/orders_cleaned.csv

# Inside container:
hdfs dfs -mkdir -p /project_a/raw
hdfs dfs -mkdir -p /project_a/warehouse/orders
hdfs dfs -put /tmp/orders_cleaned.csv /project_a/warehouse/orders/
hdfs dfs -ls /project_a/warehouse/orders/
hdfs dfs -cat /project_a/warehouse/orders/orders_cleaned.csv | head -5

## 11. Practice HDFS CLI commands
hdfs dfs -mkdir /practice_dir
hdfs dfs -put /tmp/orders_cleaned.csv /practice_dir/test.csv
hdfs dfs -ls /practice_dir
hdfs dfs -get /practice_dir/test.csv /tmp/downloaded_test.csv
hdfs dfs -rm /practice_dir/test.csv
hdfs dfs -rmdir /practice_dir
