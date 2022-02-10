# mysql常用命令

## 管理MySQL常用命令

```mysql
# 修改用户密码（mysql5.7版本）
mysql > UPDATE mysql.user SET authentication_string=PASSWORD("password") WHERE user='root';
mysql > set password for root@localhost = password('password');

# 设置 root 远程连接密码
mysql > GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by 'password' WITH GRANT OPTION;

# 创建数据库
mysql > CREATE DATABASE IF NOT EXISTS `db_name` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

# 删除数据库
mysql > drop database db_name;

## 数据库表加读锁
# mysql 加入读锁
mysql > flush tables with read lock;
# 解除 master db 的读锁
mysql > unlock tables;

## MySQL用户只读模式
# 只读模式
mysql > set global read_only=1;
# 取消普通账号的只读模式
mysql > set global read_only=0;

# 查看数据库中 migration 版本
mysql > select * from schema_version order by 2;
```



## 权限管理常用命令

```mysql
# 创建用户并赋权
mysql > grant select, insert, update, delete, alter on `db_name`.* to 'user_name'@'%' identified by 'password';

# 增加用户权限
mysql > grant select, insert, update, delete, alter on `db_name`.* to 'user_name'@'%';

# 移除用户权限
mysql > revoke select on `db_name`.* from 'user_name'@'%';
mysql > revoke all privileges on `db_name`.* from 'user_name'@'%';

# 查看所有用户信息
mysql > select user, host from mysql.user; 

# 查看用户权限
mysql > show grants for 'user_name'@'%'; 

# 删除用户
mysql > drop user 'user_name'@'%';
mysql > delete from mysql.user where user="user_name" and host="%";

# 修改用户密码(mysql5.7版本)
mysql > UPDATE mysql.user SET authentication_string=PASSWORD("password") WHERE user='user_name';

# 刷新权限
mysql > flush privileges;
```



## 数据表管理

```mysql
# 查看表结构
mysql > desc table_name;

# 增加表字段
mysql > alter table table_name add `column_name` decimal(10,4) NOT NULL DEFAULT '0.0000' COMMENT 'Remark';

# 修改字段
mysql > ALTER TABLE `db_name`.`table_name` MODIFY COLUMN `column_name` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL AFTER `deleted_at`;

# 删除数据
mysql > delete from `db_name`.`table_name` where id = 1;

# 清空表内容
mysql > truncate table db_name;
```



## 数据备份还原

```shell
# 备份数据
$ mysqldump -uroot -p -P3306 db_name > file.sql

# 备份单表或多表
$ mysqldump -h 172.21.32.4 -u root -p db_name table_name > back_table.sql
$ mysqldump -h 172.21.32.4 -u root -p db_name table_name1 table_name2 …… > back_table.sql

# 导出数据库表结构
$ mysqldump -uroot -p -d db_name > file.sql

# 导入数据
$ mysql -uroot -p db_name < file.sql
```



## 参数管理

```mysql
# 查询参数值
mysql > SHOW STATUS LIKE '%变量名%';
mysql > SHOW VARIABLES LIKE '%变量名%';
mysql > show variables like '%_log_at_%';

# 临时修改参数
mysql > set GLOBAL sort_buffer_size = 7000000;
mysql > set GLOBAL Max_used_connections=512;

# 查看 mysql 的性能指标
mysql > show status;
mysql > show variables;
mysql > flush status;
```

1. 参数 `innodb_flush_log_at_trx_commit`

   ```mysql
   mysql > show variables like '%innodb_flush_log_at_trx_commit%';
   mysql > set global innodb_flush_log_at_trx_commit=1;
   ```

   参数解释:

   - 0：log buffer将每秒一次地写入log file中，并且log file的flush(刷到磁盘)操作同时进行。该模式下在事务提交的时候，不会主动触发写入磁盘的操作。
   - 1：每次事务提交时MySQL都会把log buffer的数据写入log file，并且flush(刷到磁盘)中去，该模式为系统默认。
   - 2：每次事务提交时MySQL都会把log buffer的数据写入log file，但是flush(刷到磁盘)操作并不会同时进行。该模式下，MySQL会每秒执行一次 flush(刷到磁盘)操作。

   参数修改:

   - 找到mysql配置文件mysql.ini，修改成合适的值，然后重启mysql。

   注意事项

   - 当设置为0，该模式速度最快，但不太安全，mysqld进程的崩溃会导致上一秒钟所有事务数据的丢失。
   - 当设置为1，该模式是最安全的，但也是最慢的一种方式。在mysqld 服务崩溃或者服务器主机crash的情况下，binary log 只有可能丢失最多一个语句或者一个事务。
   - 当设置为2，该模式速度较快，也比0安全，只有在操作系统崩溃或者系统断电的情况下，上一秒钟所有事务数据才可能丢失。

   其他相关

   - 查找资料时候看到其他文章说innodb_flush_log_at_trx_commit和sync_binlog 两个参数是控制MySQL 磁盘写入策略以及数据安全性的关键参数，当两个参数都设置为1的时候写入性能最差，推荐做法是innodb_flush_log_at_trx_commit=2，sync_binlog=500 或1000

2. 参数 `sync_binlog`

   ```mysql
   mysql > show variables like '%sync_binlog%';
   mysql > set global sync_binlog=0;
   ```

   - MySQL提供一个sync_binlog参数来控制数据库的binlog刷到磁盘上去。
   - 默认，sync_binlog=0，表示MySQL不控制binlog的刷新，由文件系统自己控制它的缓存的刷新。这时候的性能是最好的，但是风险也是最大的。因为一旦系统Crash，在binlog_cache中的所有binlog信息都会被丢失。
   - 如果sync_binlog>0，表示每sync_binlog次事务提交，MySQL调用文件系统的刷新操作将缓存刷下去。最安全的就是sync_binlog=1了，表示每次事务提交，MySQL都会把binlog刷下去，是最安全但是性能损耗最大的设置。这样的话，在数据库所在的主机操作系统损坏或者突然掉电的情况下，系统才有可能丢失1个事务的数据。但是binlog虽然是顺序IO，但是设置sync_binlog=1，多个事务同时提交，同样很大的影响MySQL和IO性能。虽然可以通过group commit的补丁缓解，但是刷新的频率过高对IO的影响也非常大。对于高并发事务的系统来说，“sync_binlog”设置为0和设置为1的系统写入性能差距可能高达5倍甚至更多。
   - 所以很多MySQL DBA设置的sync_binlog并不是最安全的1，而是100或者是0。这样牺牲一定的一致性，可以获得更高的并发和性能。

## 主从常见问题处理

1. 从库报错跳过当前错误

   ```mysql
   mysql > set global sql_slave_skip_counter=1;
   mysql > start slave;
   ```

2. mysqldump 导出的数据再次导入时无法同步到从库的问题

   sql导出时加入--set-gtid-purged=OFF 参数，不加参数的后果是导出的sql文件中有SET @@SESSION.SQL_LOG_BIN= 0 项，导致再到入库中时没有写入binlog文件中，因而没有同步到从库。

   ```shell
   $ mysqldump --set-gtid-purged=OFF -uroot -p db_name > file.sql
   ```

3. MySQL主从添加存储过程后，主从停止报错解决办法

   ```mysql
   # MySQL主从添加存储过程后，主从停止报错解决办法
   mysql > show variables like 'log_bin_trust_function_creators';
   mysql > set global log_bin_trust_function_creators=1;
   
   # 或编缉 my.cnf,添加如下，然后重启
   [mysqld]
   log_bin_trust_routine_creators = 1
   ```

   

## Binlog 管理

1.  查看binlog日志

   ```shell
   $ mysqlbinlog --no-defaults --database=db_name --start-datetime="2019-07-03 13:25:00" --stop-datetime="2019-07-03 13:30:00" /data/db/binlog_/mysql-bin.000967 > /tmp/binlog6.txt
   ```

   如果导出后的文件内容格式如下，需要加入参数：-v --base64-output=DECODE-ROWS

   ```tex
   BINLOG '
   qjwcXRN6grk7oQAAAK/xmTAAAGW6BgAAAAEACnJhaW5ib3dfaHMAFHJlY29yZF9xdWFsaXR5X2No
   ZWNrACYD/v4DAwP+/g8PDwP2D/4DDw8P/gMPDw/+DwMDDw/8AwMD/g8PDzP+bP5s/mz+bJYAlgBY
   Ag8CCAf+bP0CPACWAP5slgAeAJYA/mw8ADwA/QIC/mweAFgClgD8////PydNIYI=
   qjwcXSB6grk7TQEAAPzymTAAAGW6BgAAAAEAAgAm///////QPwD8+FwMAAAkODU2NjNmNDQtOWQ1
   Mi0xMWU5LWE2NTAtNTI1NDQyYjNkMDQwJDE1ZmQ1YTk4LTIxOGEtNGZhMS04MzA5LTA4YTNjMzEw
   OTg4MAAAAAABAAAAJDk3Y2RjY2I0LTFiYmMtNDI4ZS1hMmViLTY1MjljYjc0NWViNwAAAAAJAOiS
   i+S4uei0pAsxODgxNjU2NjYwMRIzMTAyMjYxOTg4MDMwMjM5MTMFc2RqazIzzxhdDOa5luWNl+S4
   reW+rgEyBui+m+S8nyQ3YTQ3ZWQ2NS01YjhhLTQwN2ItOGIwYy1kNDMyZWU4NWU2OTMFMjcxMTGI
   OxxdiDscXSQ5N2NkY2NiNC0xYmJjLTQyOGUtYTJlYi02NTI5Y2I3NDVlYjeRZwjL
   ```

2. 清除 binlog日志

   ```mysql
   # 清除mysql-bin.010之前的日志，不包括mysql-bin.010
   mysql > purge master logs to 'mysql-bin.010';
   
   # 清除2018-06-22 13:00:00前binlog日志
   mysql > purge master logs before '2018-06-22 13:00:00';
   
   # 清除3天前binlog日志before，变量的date自变量可以为'yyyy-mm-dd hh:mm:ss'格式。
   mysql > purge master logs before date_sub( now( ), interval 3 day);
   ```



## 服务负载高排查

```mysql
# 查看
mysql > show processlist;
# 查看耗时的事物信息
mysql > show processlist full;

# 筛选耗时的事物信息
mysql > select id, db, user, host, command, time, state, info from information_schema.processlist where command != 'Sleep' order by time desc limit 10;

mysql > select id, db, user, host, command, time, state from information_schema.processlist where command != 'Sleep' order by time desc limit 10;
```

