# Ubuntu 20.04 部署 OpenStack Yoga 集群版本







## Mariadb集群





```bash
# 安装软件包
apt install mariadb-server python3-pymysql

# 创建并编辑文件
vim /etc/mysql/mariadb.conf.d/99-openstack.cnf
#####################
[mysqld]
bind-address = 192.168.71.57

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
#####################

# 重启服务
service mysql restart

# 运行 mysql_secure_installation 命令确保数据库服务安全。特别是，为数据库root帐户选择合适的密码:
mysql_secure_installation

```







### 安装 MariaDB Server

```bash

apt update -y 

apt install mariadb-server -y

systemctl start mariadb
systemctl status mariadb


# 执行如下命令加固mariadb的安全以及重置其root账号
mysql_secure_installation

# 执行过程中，会进行交互式询问，全部选择"y"即可。
Enter current password for root (enter for none): 
Switch to unix_socket authentication [Y/n] n
Change the root password? [Y/n] Y
New password:
Re-enter new password:
Remove anonymous users? [Y/n] Y
Disallow root login remotely? [Y/n] Y
Remove test database and access to it? [Y/n] Y
Reload privilege tables now? [Y/n] Y
.....


```

### 配置Galera群集

```bash
# 在每个节点服务器上创建galera.cnf配置文件

vim /etc/mysql/conf.d/galera.cnf

[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://node1-ip-address,node2-ip-address,node3-ip-address"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="node1-ip-address"
wsrep_node_name="node1"




####

[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://node1-ip-address,node2-ip-address,node3-ip-address"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="node2-ip-address"
wsrep_node_name="node2"



###
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://node1-ip-address,node2-ip-address,node3-ip-address"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="node3-ip-address"
wsrep_node_name="node3"



```



### 初始化Galera群集

```bash
# 所有节点停止mariadb服务
systemctl stop mariadb

# 在第一个节点上，使用以下命令初始化MariaDB Galera集群
galera_new_cluster

# 使用以下命令检查集群的状态
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

# 首次执行，会提示输入root账号密码，之后你将会看到如下内容：
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+

# 以上同样的步骤在第二个和第三个节点上进行。
# 所有的节点完成以上操作后， Galera集群的初始化工作就已经完成，你可以进行下一步的操作了。




```



### 验证群集复制

```bash
# 在第一个节点上，使用以下命令连接到MariaDB：
mysql -u root -p

MariaDB [(none)]> create database db1;
MariaDB [(none)]> create database db2;

# 在第二个数据库节点上执行如下命令登录数据库服务
mysql -u root -p

MariaDB [(none)]> show databases;

# 正常情况下，你将会看到我们在第一个数据库节点创建的db1和db2已经被复制到第二个节点上：
+--------------------+
| Database           |
+--------------------+
| db1                |
| db2                |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
5 rows in set (0.001 sec)

# 登录第三个节点数据库服务器，执行命令登录数据库命令
mysql -u root -p

MariaDB [(none)]> show databases;

+--------------------+
| Database           |
+--------------------+
| db1                |
| db2                |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
5 rows in set (0.001 sec)

```



