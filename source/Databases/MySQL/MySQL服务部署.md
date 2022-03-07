# MySQL 服务

## 二进制方式部署服务端

查看其他版本请点击官方[地址](https://dev.mysql.com/downloads/mysql/ )

1. 安装

   ```shell
   # 下载对应的版本源码
   $ export UNZIP_DIR="/opt" && export NAME="mysql-5.7.28"
   $ cd /tmp && wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
   $ tar -zxf mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz -C ${UNZIP_DIR} && cd ${UNZIP_DIR}
   $ mv mysql-5.7.28-linux-glibc2.12-x86_64/ ${NAME}
   
   # 安装相关依赖
   $ yum -y install libaio libaio-devel
   $ yum -y install numactl.x86_64
   # 检查系统中的Mysql或mariadb，如果存在将其卸载
   $ rpm -qa | grep mysql
   $ rpm -qa | grep mariadb
   $ yum -y remove mariadb-libs-5.5.68-1.el7.x86_64
   
   # Ubuntu 需安装libaio1
   $ apt-get install -y libaio1
   
   # -M不创建主目录，-s /sbin/nologin不允许登录，-r创建的是系统用户
   $ groupadd mysql && useradd -r -g mysql -s /sbin/nologin -M mysql
   # 创建数据，日志等目录
   $ mkdir -p ${UNZIP_DIR}/${NAME}/{data,log,tmp,etc}
   $ touch ${UNZIP_DIR}/${NAME}/log/mysql_error.log
   # 修改所属主和所属组
   $ chown -R mysql.mysql ${UNZIP_DIR}/${NAME}
   # 初始化
   # basedir 是程序安装的目录
   # datadir 是mysql数据存放的目录
   $ ${UNZIP_DIR}/${NAME}/bin/mysqld --initialize --user=mysql --basedir=${UNZIP_DIR}/${NAME} --datadir=${UNZIP_DIR}/${NAME}/data
   # 输出内容，其中最后一行中 root@localhost: 8sMfT?Be&?no 是root用户的初始密码
   2021-04-21T11:32:20.506782Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
   2021-04-21T11:32:26.223027Z 0 [Warning] InnoDB: New log files created, LSN=45790
   2021-04-21T11:32:27.122762Z 0 [Warning] InnoDB: Creating foreign key constraint system tables.
   2021-04-21T11:32:27.285342Z 0 [Warning] No existing UUID has been found, so we assume that this is the first time that this server has been started. Generating a new UUID: 40055fe4-a295-11eb-85f3-fa4f027b9700.
   2021-04-21T11:32:27.316088Z 0 [Warning] Gtid table is not ready to be used. Table 'mysql.gtid_executed' cannot be opened.
   2021-04-21T11:32:28.019445Z 0 [Warning] CA certificate ca.pem is self signed.
   2021-04-21T11:32:28.358334Z 1 [Note] A temporary password is generated for root@localhost: 8sMfT?Be&?no
   ```

2. 配置文件内容

   ```shell
   $ tee ${UNZIP_DIR}/${NAME}/etc/my.cnf << EOF
   [mysqld]
   basedir = ${UNZIP_DIR}/${NAME}
   datadir = ${UNZIP_DIR}/${NAME}/data
   port = 3306
   socket = /var/lib/mysql/mysql.sock
   character-set-server = utf8mb4
   log-error = ${UNZIP_DIR}/${NAME}/log/mysql_error.log
   pid-file = ${UNZIP_DIR}/${NAME}/tmp/mysqld.pid
   server-id = 1
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
   socket = /var/lib/mysql/mysql.sock
   [client]
   socket = /var/lib/mysql/mysql.sock
   EOF
   
   $ cat ${UNZIP_DIR}/${NAME}/etc/my.cnf
   ```

3. 服务管理

   ```shell
   $ chown -R mysql.mysql ${UNZIP_DIR}/${NAME}
   $ mkdir /var/lib/mysql
   $ chown -R mysql.mysql /var/lib/mysql
   $ tee /etc/profile.d/mysql.sh << EOF
   export PATH=${UNZIP_DIR}/${NAME}/bin:\$PATH
   EOF
   $ cat /etc/profile.d/mysql.sh
   $ source /etc/profile
   $ ln -s ${UNZIP_DIR}/${NAME}/etc/my.cnf /etc/my.cnf
   $ cp ${UNZIP_DIR}/${NAME}/support-files/mysql.server /etc/init.d/mysqld
   $ chmod +x /etc/init.d/mysqld
   $ vim /etc/init.d/mysqld
   ################修改一下内容###########################
   basedir=/opt/mysql-5.7.28
   datadir=/opt/mysql-5.7.28/data
   ######################################################
   # 启动MySQL服务
   $ /etc/init.d/mysqld start
   # 把MySQL服务添加自启动
   $ echo '/etc/init.d/mysqld start' >> /etc/rc.d/rc.local
   $ chmod +x /etc/rc.d/rc.local
   
   # 初始化root密码
   mysql -uroot -p'hMfl7<<Foh>f'
   mysql> set password for root@localhost=password('6#R@a7e2mSALMUg3');
   # 测试新密码登录
   mysql -uroot -p'6#R@a7e2mSALMUg3'
   ```
   
   

## 部署 MySQL 从库

1. 了解主从

   * 主从同步的优点

     > 做数据的热备，作为后备数据库，主数据库服务器故障后，可切换到从数据库继续工作，避免数据丢失。
     >
     > 架构的扩展。业务量越来越大，I/O访问频率过高，单机无法满足，此时做多库的存储，降低磁盘I/O访问的频率，提高单个机器的I/O性能。
     >
     > 读写分离，使数据库能支撑更大的并发。在报表中尤其重要。由于部分报表sql语句非常的慢，导致锁表，影响前台服务。如果前台使用master，报表使用slave，那么报表sql将不会造成前台锁，保证了前台速度。

   * 应用场景

     > 读写分离，提高查询访问性能，有效减少主数据库访问压力。 实时灾备，主数据库出现故障时，可快速切换到从数据库。 数据汇总，可将多个主数据库同步汇总到一个从数据库中，方便数据统计分析。

   * 配置约束

     > 主从库必须保证网络畅通可访问 主库必须开启binlog日志 主从库的server-id必须不同

2. master 配置

   ```shell
   # 修改配置文件，编译mysql配置文件，开启bin-log日志，并重启mysqld让配置文件生效
   [mysqld]
   basedir = /opt/mysql-5.7.28
   datadir = /opt/mysql-5.7.28/data
   port = 3306
   socket = /var/lib/mysql/mysql.sock
   character-set-server = utf8mb4
   log-error = /opt/mysql-5.7.28/log/mysql_error.log
   pid-file = /opt/mysql-5.7.28/tmp/mysqld.pid
   server-id = 1
   collation-server = utf8mb4_general_ci
   lower_case_table_names = 1
   user = mysql
   
   log_bin = mysql-bin  # 开启及设置二进制日志文件名称
   sync_binlog = 1
   expire_logs_days =7  # 二进制日志自动删除/过期的天数。默认值为0，表示不自动删除。
   
   binlog_format = ROW
   
   innodb_buffer_pool_size = 4G
   innodb_log_file_size = 256M
   
   max_connections = 500
   wait_timeout = 3600
   interactive_timeout = 3600
   skip_name_resolve = 1
   [mysql]
   socket = /var/lib/mysql/mysql.sock
   [client]
   socket = /var/lib/mysql/mysql.sock
   
   # 重启 master 服务
   $ /etc/init.d/mysqld restart
   # 在 master 上创建同步用户
   mysql> grant replication slave on *.* to 'slave'@'%' identified by 'Ystar.123456';
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
   $ mysqldump -uroot -p'6#R@a7e2mSALMUg3' bingoo_db > /opt/bingoo_db.sql
   $ mysqldump -uroot -p'6#R@a7e2mSALMUg3' ystar_adpoints > /opt/ystar_adpoints.sql
   $ mysqldump -uroot -p'6#R@a7e2mSALMUg3' ystar_invite > /opt/ystar_invite.sql
   $ mysqldump -uroot -p'6#R@a7e2mSALMUg3' ystar_uid > /opt/ystar_uid.sql
   
   # 从库导入来自主库数据
   $ /opt/mysql-5.7.28/bin/mysql -uroot -p'6#R@a7e2mSALMUg3' bingoo_db < /opt/bingoo_db.sql
   $ /opt/mysql-5.7.28/bin/mysql -uroot -p'6#R@a7e2mSALMUg3' ystar_adpoints < /opt/ystar_adpoints.sql
   $ /opt/mysql-5.7.28/bin/mysql -uroot -p'6#R@a7e2mSALMUg3' ystar_invite < /opt/ystar_invite.sql
   $ /opt/mysql-5.7.28/bin/mysql -uroot -p'6#R@a7e2mSALMUg3' ystar_uid < /opt/ystar_uid.sql
   
   # 解锁 master 数据库表
   mysql> unlock tables;
   ```

3. slave 配置

   ```shell
   # 配置文件
   [mysqld]
   basedir = /opt/mysql-5.7.28
   datadir = /opt/mysql-5.7.28/data
   port = 3306
   socket = /var/lib/mysql/mysql.sock
   character-set-server = utf8mb4
   log-error = /opt/mysql-5.7.28/log/mysql_error.log
   pid-file = /opt/mysql-5.7.28/tmp/mysqld.pid
   server-id = 2
   collation-server = utf8mb4_general_ci
   lower_case_table_names = 1
   user = mysql
   
   read_only = 1
   relay-log = slave-relay-bin
   relay-log-index = slave-relay-bin.index
   
   innodb_buffer_pool_size = 4G
   innodb_log_file_size = 256M
   
   max_connections = 500
   wait_timeout = 3600
   interactive_timeout = 3600
   skip_name_resolve = 1
   [mysql]
   socket = /var/lib/mysql/mysql.sock
   [client]
   socket = /var/lib/mysql/mysql.sock
   
   # 重启 slave 服务
   $ /etc/init.d/mysqld restart
   # slave 库设置同步用户，master_log_file文件尾主库中 show master status 中的File，master_log_post为主库中Postion的值
   mysql> change master to master_host='192.168.1.189',master_user='slave',master_password='Ystar.123456',master_log_file='mysql-bin.000001',master_log_pos=590;
   
   # 开启 master slave 复制
   mysql> start slave;
   
   # 查看同步状态，当 Slave_IO_Running: Yes  Slave_SQL_Running: Yes 都为 yes 表示同步成功
   mysql> show slave status \G
   # 在 master 中查看 slave 是否连接
   mysql> show processlist \G
   ```

4. 主从命令使用

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

5. 删除主从同步

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

   

## 部署MySQL客户端

```shell
# 添加RPM源
$ rpm -ivh https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
# yum命令搜索
$ yum search mysql-community
# 安装x64位MySQL客户端
$ yum install mysql-community-client.x86_64
```



## docker安装MySQL

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

