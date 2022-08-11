# MySQL 服务部署

## 二进制方式部署MySQL 5.7

查看其他版本请点击官方[地址](https://dev.mysql.com/downloads/mysql/ )

### 安装相关依赖

```shell
# CentOS
$ yum -y install libaio libaio-devel
$ yum -y install numactl.x86_64
# 检查系统中的Mysql或mariadb，如果存在将其卸载
$ rpm -qa | grep mysql
$ rpm -qa | grep mariadb
$ yum -y remove mariadb-libs-5.5.68-1.el7.x86_64

# Ubuntu
$ sudo apt-get update -y
$ sudo apt-get upgrade -y
$ sudo apt-get install -y libaio1
```

### 下载二进制包

```shell
$ export UNZIP_DIR="/opt" && export NAME="mysql-5.7.28"
$ wget https://cdn.mysql.com/archives/mysql-5.7/${NAME}-linux-glibc2.12-x86_64.tar.gz -P /tmp
$ tar -zxf /tmp/${NAME}-linux-glibc2.12-x86_64.tar.gz -C ${UNZIP_DIR}
$ mv ${UNZIP_DIR}/${NAME}-linux-glibc2.12-x86_64/ ${UNZIP_DIR}/${NAME}
```

### 环境配置

```shell
# -M不创建主目录，-s /sbin/nologin不允许登录，-r创建的是系统用户
$ groupadd mysql && useradd -r -g mysql -s /sbin/nologin -M mysql
# 创建数据，日志等目录
$ mkdir -p ${UNZIP_DIR}/${NAME}/{data,log,tmp,conf,var,etc}
$ touch ${UNZIP_DIR}/${NAME}/log/mysql_error.log
# 修改所属主和所属组
$ chown -R mysql.mysql ${UNZIP_DIR}/${NAME}
# 初始化，basedir是程序安装的目录，datadir是mysql数据存放的目录
$ ${UNZIP_DIR}/${NAME}/bin/mysqld \
  --initialize --user=mysql \
  --basedir=${UNZIP_DIR}/${NAME} \
  --datadir=${UNZIP_DIR}/${NAME}/data
```

初始化输出日志内容中最后一行 `root@localhost: 8sMfT?Be&?no` 是root用户的初始密码，如下：

```tex
2021-04-21T11:32:20.506782Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2021-04-21T11:32:26.223027Z 0 [Warning] InnoDB: New log files created, LSN=45790
2021-04-21T11:32:27.122762Z 0 [Warning] InnoDB: Creating foreign key constraint system tables.
2021-04-21T11:32:27.285342Z 0 [Warning] No existing UUID has been found, so we assume that this is the first time that this server has been started. Generating a new UUID: 40055fe4-a295-11eb-85f3-fa4f027b9700.
2021-04-21T11:32:27.316088Z 0 [Warning] Gtid table is not ready to be used. Table 'mysql.gtid_executed' cannot be opened.
2021-04-21T11:32:28.019445Z 0 [Warning] CA certificate ca.pem is self signed.
2021-04-21T11:32:28.358334Z 1 [Note] A temporary password is generated for root@localhost: 8sMfT?Be&?no
```

### 配置文件

```shell
$ tee ${UNZIP_DIR}/${NAME}/conf/my.cnf << EOF
[mysqld]
basedir = ${UNZIP_DIR}/${NAME}
datadir = ${UNZIP_DIR}/${NAME}/data
port = 3306
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
character-set-server = utf8mb4
log-error = ${UNZIP_DIR}/${NAME}/log/mysql_error.log
pid-file = ${UNZIP_DIR}/${NAME}/tmp/mysqld.pid
server-id = 1
log_bin = mysql-bin
sync_binlog = 1
expire_logs_days =7
collation-server = utf8mb4_general_ci
lower_case_table_names = 1
user = mysql
innodb_buffer_pool_size = 4G
innodb_log_file_size = 256M
max_connections = 500
wait_timeout = 3600
interactive_timeout = 3600
skip_name_resolve = 1
[mysql]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
[client]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
EOF
```

### 管理服务

```shell
# 添加环境变量
$ tee /etc/profile.d/mysql.sh << EOF
export PATH=${UNZIP_DIR}/${NAME}/bin:\$PATH
EOF

$ source /etc/profile
$ cp ${UNZIP_DIR}/${NAME}/support-files/mysql.server /etc/init.d/mysqld
$ sed -i "s#conf=/etc/my.cnf#conf=${UNZIP_DIR}/${NAME}/conf/my.cnf#g" /etc/init.d/mysqld
$ sed -i "s#^basedir=#basedir=${UNZIP_DIR}/${NAME}#g" /etc/init.d/mysqld
$ sed -i "s#^datadir=#datadir=${UNZIP_DIR}/${NAME}/data#g" /etc/init.d/mysqld
$ chmod +x /etc/init.d/mysqld
$ chown -R mysql.mysql ${UNZIP_DIR}/${NAME}

# 启动MySQL服务
$ /etc/init.d/mysqld start
# 把MySQL服务添加自启动
$ echo '/etc/init.d/mysqld start' >> /etc/rc.d/rc.local
$ chmod +x /etc/rc.d/rc.local

```

### 初始化root密码

```shell
$ mysql -uroot -p'8sMfT?Be&?no'
mysql> set password for root@localhost=password('root_password');
# 测试新密码登录
$ mysql -uroot -p'root_password'
```

### 遇到问题

```shell
# 问题1
mysql: error while loading shared libraries: libncurses.so.5: cannot open shared object file: No such file or directory
# 解决
$ apt-get install -y libncurses5-dev libncurses5
```



## 部署 MySQL 从库 MySQL 5.7

### 了解主从

1. 主从同步的优点
   - 做数据的热备，作为后备数据库，主数据库服务器故障后，可切换到从数据库继续工作，避免数据丢失。
   - 架构的扩展。业务量越来越大，I/O访问频率过高，单机无法满足，此时做多库的存储，降低磁盘I/O访问的频率，提高单个机器的I/O性能。
   - 读写分离，使数据库能支撑更大的并发。在报表中尤其重要。由于部分报表sql语句非常的慢，导致锁表，影响前台服务。如果前台使用master，报表使用slave，那么报表sql将不会造成前台锁，保证了前台速度。
2. 应用场景
   - 读写分离，提高查询访问性能，有效减少主数据库访问压力。 实时灾备，主数据库出现故障时，可快速切换到从数据库。 数据汇总，可将多个主数据库同步汇总到一个从数据库中，方便数据统计分析。
3. 配置约束
   - 主从库必须保证网络畅通可访问 主库必须开启binlog日志 主从库的server-id必须不同

### master 配置文件

```shell
$ export UNZIP_DIR="/opt" && export NAME="mysql-5.7.28"

# 修改配置文件，编译mysql配置文件，开启bin-log日志，并重启mysqld让配置文件生效
$ tee ${UNZIP_DIR}/${NAME}/conf/my.cnf << EOF
[mysqld]
basedir = ${UNZIP_DIR}/${NAME}
datadir = ${UNZIP_DIR}/${NAME}/data
port = 3306
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
character-set-server = utf8mb4
log-error = ${UNZIP_DIR}/${NAME}/log/mysql_error.log
pid-file = ${UNZIP_DIR}/${NAME}/tmp/mysqld.pid
server-id = 1
log_bin = mysql-bin
sync_binlog = 1
expire_logs_days =7
binlog_format = ROW
collation-server = utf8mb4_general_ci
lower_case_table_names = 1
user = mysql
innodb_buffer_pool_size = 4G
innodb_log_file_size = 256M
max_connections = 500
wait_timeout = 3600
interactive_timeout = 3600
skip_name_resolve = 1
[mysql]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
[client]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
EOF

# 重启 master 服务
$ /etc/init.d/mysqld restart
# 在 master 上创建同步用户
mysql> grant replication slave on *.* to 'slave'@'%' identified by 'passwd.123456';
mysql> flush privileges;
# 锁上 master 数据库表
mysql> flush tables with read lock;
# 查看 master 状态
mysql> show master status \G
*************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 590
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)

# 备份 master 数据，备份主库中的所有数据到从库中，保持当前主库和从库数据一致，主库导出数据
$ mysqldump -uroot -p'' database_name > database_name.sql

# 从库导入来自主库数据
$ mysql -uroot -p database_name < database_name.sql

# 解锁 master 数据库表
mysql> unlock tables;
```

### slave 配置

```shell
$ export UNZIP_DIR="/opt" && export NAME="mysql-5.7.28"
$ tee ${UNZIP_DIR}/${NAME}/conf/my.cnf << EOF
[mysqld]
basedir = ${UNZIP_DIR}/${NAME}
datadir = ${UNZIP_DIR}/${NAME}/data
port = 3306
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
character-set-server = utf8mb4
log-error = ${UNZIP_DIR}/${NAME}/log/mysql_error.log
pid-file = ${UNZIP_DIR}/${NAME}/tmp/mysqld.pid
server-id = 2

read_only = 1
relay-log = slave-relay-bin
relay-log-index = slave-relay-bin.index

collation-server = utf8mb4_general_ci
lower_case_table_names = 1
user = mysql
innodb_buffer_pool_size = 4G
innodb_log_file_size = 256M
max_connections = 500
wait_timeout = 3600
interactive_timeout = 3600
skip_name_resolve = 1
[mysql]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
[client]
socket = ${UNZIP_DIR}/${NAME}/var/mysql.sock
EOF

# 重启 slave 服务
$ /etc/init.d/mysqld restart

# slave 库设置同步用户，master_log_file文件尾主库中 show master status 中的File，master_log_post为主库中Postion的值
mysql> change master to master_host='192.168.1.111',master_user='slave',master_password='passwd.123456',master_log_file='mysql-bin.000001',master_log_pos=590;

# 开启 master slave 复制
mysql> start slave;

# 查看同步状态，当 Slave_IO_Running: Yes  Slave_SQL_Running: Yes 都为 yes 表示同步成功
mysql> show slave status \G
# 在 master 中查看 slave 是否连接
mysql> show processlist \G
```

### 主从命令使用

```shell
# 查看错误
mysql> show warnning;
# 查看主库状态
mysql> show master status \G
# 查看从库状态
mysql> show slave status \G
# 重置主记录信息
mysql> reset master;
# 重置从记录信息
mysql> reset slave;
# 停止始从
mysql> stop slave;
# 启动从
mysql> start slave;
# 清空从所有连接、信息记录
mysql> reset slave all;
# 删除从
mysql> change master to master_host=' ';
```

### 删除主从同步

```shell
# slave 库
mysql> stop slave;
mysql> reset slave all;
mysql> show slave status \G

# 清除从库配置文件的配置
# Master 库
mysql> reset master;

# 清除主库配置文件的配置 清除mysql.user从库账号
mysql> show master status \G
```



## MySQL客户端

### ContOS

```shell
# 添加RPM源
$ rpm -ivh https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
# yum命令搜索
$ yum search mysql-community
# 安装x64位MySQL客户端
$ yum install mysql-community-client.x86_64
```



## docker安装 MySQL 5.7

[docker mysql 镜像仓库](https://hub.docker.com/_/mysql?tab=tags&page=1&ordering=last_updated)

```shell
# 拉取镜像
$ docker pull mysql  # 最新版本
$ docker pull mysql:5.7.36  # 指定版本
# 查看镜像
$ docker images
# 运行容器
$ MYSQL_PORT="3306"
$ MYSQL_NAME="mysql-${MYSQL_PORT}"
$ MYSQL_HOME="/opt/${MYSQL_NAME}"
$ mkdir -p ${MYSQL_HOME}/{conf,logs,data}

# 配置文件
$ tee ${MYSQL_HOME}/conf/my.cnf <<-'EOF'
[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql

symbolic-links=0
skip-host-cache
skip-name-resolve
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci

server-id = 1
lower_case_table_names = 1

log_bin = mysql-bin
sync_binlog = 1
expire_logs_days =7
binlog_format = ROW

innodb_buffer_pool_size = 4G
innodb_log_file_size = 256
max_connections = 500
wait_timeout = 3600
interactive_timeout = 3600
skip_name_resolve = 1

[mysql]

[mysqldump]
quick
quote-names
max_allowed_packet = 16M
EOF

$ cat ${MYSQL_HOME}/conf/my.cnf
$ docker run -itd -p ${MYSQL_PORT}:3306 --name ${MYSQL_NAME} \
-v ${MYSQL_HOME}/conf/my.cnf:/etc/mysql/my.cnf \
-v ${MYSQL_HOME}/logs:/var/log/mysql \
-v ${MYSQL_HOME}/data:/var/lib/mysql \
-v /etc/localtime:/etc/localtime \
-e MYSQL_ROOT_PASSWORD=root123456 mysql:5.7.36
```

参数说明：

```shell
run: 运行一个docker容器
-i：以交互模式运行，通常配合-t
-t：为容器重新分配一个伪输入终端，通常配合-i
-d：后台运行容器
-p：端口映射，格式为主机端口:容器端口
-e MYSQL_ROOT_PASSWORD=123456  初始化root用户的密码
--name：设置容器别名
--character-set-server=utf8mb4 ：设置字符集
--collation-server=utf8mb4_unicode_ci：设置校对集
```

```shell
# 宿主机上备份数据库
$ docker exec 529a4d9afd8e sh -c ' exec mysqldump --all-databases -uroot -p"123456" ' > /mydocker/mysql/all-databases.sql
# 进入容器
$ docker exec -it mysql-latest /bin/bash
# 数据保存到/var/lib/mysql 路径下,exit 退出，将容器data 路径下文件copy到主机下。
$ docker cp mysql-name:/var/lib/mysql/ /my/own/datadir
```

查看日志

```shell
$ docker logs -f 7b57af435c9e
```

遇到错误：

```tex
2022-04-22T06:30:53.788315Z 0 [ERROR] [MY-010095] [Server] Failed to access directory for --secure-file-priv. Please make sure that directory exists and is accessible by MySQL Server. Supplied value : /var/lib/mysql-files
2022-04-22 06:30:53+00:00 [ERROR] [Entrypoint]: Unable to start server.
```

解决：

```shell
$ mkdir -p ${MYSQL_HOME}/mysql-files
$ docker rm <7b57af435c9e>
$ docker run -itd -p ${MYSQL_PORT}:3306 --name ${MYSQL_NAME} \
-v ${MYSQL_HOME}/conf/my.cnf:/etc/mysql/my.cnf \
-v ${MYSQL_HOME}/logs:/var/log/mysql \
-v ${MYSQL_HOME}/data:/var/lib/mysql \
-v ${MYSQL_HOME}/mysql-files:/var/lib/mysql-files \
-v /etc/localtime:/etc/localtime \
-e MYSQL_ROOT_PASSWORD=root123456 mysql
```



## 二进制方式部署MySQL 8.0

### 安装依赖

```shell
$ sudo apt-get update -y
$ sudo apt-get upgrade -y
$ apt-get install libncurses5 libaio1 -y
```

### 下载二进制包

```shell
$ export UNZIP_DIR="/opt" && export MYSQL_VERSION="mysql-8.0.29"

$ wget https://cdn.mysql.com//Downloads/MySQL-8.0/"${MYSQL_VERSION}"-linux-glibc2.12-x86_64.tar.xz

$ tar -xf "${MYSQL_VERSION}"-linux-glibc2.12-x86_64.tar.xz -C "${UNZIP_DIR}"
$ mv "${UNZIP_DIR}"/"${MYSQL_VERSION}"-linux-glibc2.12-x86_64 "${UNZIP_DIR}"/"${MYSQL_VERSION}"
$ cd "${UNZIP_DIR}"/"${MYSQL_VERSION}"
$ mkdir -p "${UNZIP_DIR}"/"${MYSQL_VERSION}"/{data,conf,tmp,var}
```

### 配置文件

请使用此[链接](https://imysql.com/my-cnf-wizard.html)来生成`my.cnf`配置文件

```shell
$ tee "${UNZIP_DIR}"/"${MYSQL_VERSION}"/conf/my.cnf << EOF
[client]
port = 3306
socket = ${UNZIP_DIR}/${MYSQL_VERSION}/var/mysql.sock

[mysql]
no_auto_rehash

[mysqld]
user = mysql
port = 3306
server_id = 1
basedir = ${UNZIP_DIR}/${MYSQL_VERSION}
datadir = ${UNZIP_DIR}/${MYSQL_VERSION}/data
socket = ${UNZIP_DIR}/${MYSQL_VERSION}/var/mysql.sock
pid_file = ${UNZIP_DIR}/${MYSQL_VERSION}/tmp/mysql.pid
character_set_server = UTF8MB4
skip_name_resolve = 1
default_time_zone = "+8:00"
admin_address = '127.0.0.1'
admin_port = 33062

# 性能设置 8G内存
lock_wait_timeout = 3600
open_files_limit = 65535
back_log = 1024
max_connections = 1024
max_connect_errors = 1000000
table_open_cache = 1024
table_definition_cache = 1024
thread_stack = 512K
sort_buffer_size = 4M
join_buffer_size = 4M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
thread_cache_size = 1536
interactive_timeout = 600
wait_timeout = 600
tmp_table_size = 32M
max_heap_table_size = 32M

# log settings
log_timestamps = SYSTEM
log_error = ${UNZIP_DIR}/${MYSQL_VERSION}/data/error.log
log_error_verbosity = 3
slow_query_log = 1
log_slow_extra = 1
slow_query_log_file = ${UNZIP_DIR}/${MYSQL_VERSION}/data/slow.log
long_query_time = 0.1
log_queries_not_using_indexes = 1
log_throttle_queries_not_using_indexes = 60
min_examined_row_limit = 100
log_slow_admin_statements = 1
log_slow_slave_statements = 1
log_bin = ${UNZIP_DIR}/${MYSQL_VERSION}/data/mybinlog
binlog_format = ROW
sync_binlog = 1 # MGR环境中由其他节点提供容错性，可不设置双1以提高本地节点性能
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
binlog_rows_query_log_events = 1
binlog_expire_logs_seconds = 604800
# MySQL 8.0.22前，想启用MGR的话，需要设置binlog_checksum=NONE才行
binlog_checksum = CRC32
gtid_mode = ON
enforce_gtid_consistency = TRUE

# myisam settings
key_buffer_size = 32M
myisam_sort_buffer_size = 128M

# replication settings
relay_log_recovery = 1
slave_parallel_type = LOGICAL_CLOCK
slave_parallel_workers = 4 # 可以设置为逻辑CPU数量的2倍
binlog_transaction_dependency_tracking = WRITESET
slave_preserve_commit_order = 1
slave_checkpoint_period = 2

# innodb settings
transaction_isolation = REPEATABLE-READ
innodb_buffer_pool_size = 5734M
innodb_buffer_pool_instances = 4
innodb_data_file_path = ibdata1:12M:autoextend
innodb_flush_log_at_trx_commit = 1 # MGR环境中由其他节点提供容错性，可不设置双1以提高本地节点性能
innodb_log_buffer_size = 32M
innodb_log_file_size = 1G # 如果线上环境的TPS较高，建议加大至1G以上，如果压力不大可以调小
innodb_log_files_in_group = 3
innodb_max_undo_log_size = 4G
# 根据您的服务器IOPS能力适当调整
# 一般配普通SSD盘的话，可以调整到 10000 - 20000
# 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_open_files = 65535
innodb_flush_method = O_DIRECT
innodb_lru_scan_depth = 4000
innodb_lock_wait_timeout = 10
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_online_alter_log_max_size = 4G
innodb_print_ddl_logs = 1
innodb_status_file = 1

[mysqldump]
quick
EOF
```



```shell
$ groupadd mysql && useradd -r -g mysql -s /sbin/nologin -M mysql
$ chown -R mysql.mysql "${UNZIP_DIR}"/"${MYSQL_VERSION}"

# 初始化带密码的方法
$ "${UNZIP_DIR}"/"${MYSQL_VERSION}"/bin/mysqld \
  --defaults-file="${UNZIP_DIR}"/"${MYSQL_VERSION}"/conf/my.cnf \
  --initialize

# 初始化不带密码的方法
$ "${UNZIP_DIR}"/"${MYSQL_VERSION}"/bin/mysqld \
  --defaults-file="${UNZIP_DIR}"/"${MYSQL_VERSION}"/conf/my.cnf \
  --initialize-insecure

# 启动
$ "${UNZIP_DIR}"/"${MYSQL_VERSION}"/bin/mysqld \
  --defaults-file="${UNZIP_DIR}"/"${MYSQL_VERSION}"/conf/my.cnf &
    
# 连接
$ "${UNZIP_DIR}"/"${MYSQL_VERSION}"/bin/mysql -S \
  "${UNZIP_DIR}"/"${MYSQL_VERSION}"/var/mysql.sock -p
  
# 修改root密码
mysql> use mysql;
mysql> alter user 'root'@'localhost' identified by 'root_password';
# 设置远程密码
mysql> update user set host = '%' where user = 'root';
mysql> use mysql;
mysql> alter user 'root'@'%' identified by 'root_password' password expire never;
mysql> flush privileges;
```

### 连接 MySQL

在Linux平台环境下主要有两种连接方式：一种是TCP/IP连接方式，另一种就是Socket连接（Unix domain socket）。

1. TCP/IP连接是网络中用的最多的一种方式。一般情况下客户端在一台服务器上，而MySQL实例在另一台服务器上，两台机器通过一个TCP/IP网络连接。

   `mysql -uusername -ppassword -Pport -hIP`

   ```shell
   $ mysql -hlocalhost -uroot -P3306 -p
   ```

   通过TCP/IP连接MySQL实例时，MySQL先会检查一张权限表，用来判断发起请求的客户端IP是否允许连接到MySQL实例。该表就是MySQL库下面user表。

2. unix socket连接方式其实不是一个网络协议，所以只能在MySQL客户端和数据库实例在同一台服务器上的情况下使用。可以在配置文件中指定套接字文件的路径，如：`socket=/tmp/mysql.sock`

   `mysql -uusername -p -S /tmp/mysql.sock`

   ```shell
   $ mysql -S "${UNZIP_DIR}"/"${MYSQL_VERSION}"/var/mysql.sock -uroot -p
   ```

### 关闭 MySQL

1. shutdown

   ```mysql
   mysql> shutdown;
   ```

2. mysqladmin

   ```shell
   $ mysqladmin -S "${UNZIP_DIR}"/"${MYSQL_VERSION}"/var/mysql.sock -p shutdown
   ```

   
