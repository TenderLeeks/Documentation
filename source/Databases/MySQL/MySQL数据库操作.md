# 数据库操作

## 修改数据库用户密码(mysql5.7版本)

```mysql
mysql > UPDATE mysql.user SET authentication_string=PASSWORD("VLdYY3ClgmICqI7j") WHERE user='root';
mysql > set password for root@localhost = password('VLdYY3Clgm%ICqI7j');
```

## 给远程连接的root设置秘密

```mysql
mysql > GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by 'Root#2021' WITH GRANT OPTION;
```
## 查询MySQL进程

```mysql
mysql > select id, db, user, host, command, time,state, info from information_schema.processlist where command != 'Sleep' order by time desc limit 10;
mysql > select id, db, user, host, command, time,state from information_schema.processlist where command != 'Sleep' order by time desc limit 10;

```
## 创建数据库

```mysql
mysql > CREATE DATABASE IF NOT EXISTS `xworld` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```
## 用户权限

```mysql
# 创建用户并赋权
mysql > grant select, insert, update, delete, alter on `库名`.* to '用户名'@'%' identified by '密码';
# 增加用户权限
mysql > grant select, insert, update, delete, alter on `库名`.* to '用户名'@'%';
# 刷新权限
mysql > flush privileges;
# 查看用户权限
mysql > show grants for '用户名'@'%'; 
# 移除用户权限
mysql > revoke select on `db_name`.* from 'username'@'%';
mysql > revoke all privileges on `db_name`.* from 'username'@'%';
# 查看所有用户
mysql > select user,host from mysql.user; 
# 修改数据库用户密码(mysql5.7版本)
mysql > UPDATE mysql.user SET authentication_string=PASSWORD("RPbbdsQ0b963ffhq") WHERE user='username';
# 删除用户
mysql > drop user 'username'@'%';
mysql > delete from mysql.user where user="username" and host="%";
# 删除数据库
mysql > drop database db_name;
```

## MySQL表加读锁

```mysql
# mysql加入读锁
mysql > flush tables with read lock;
# 解除master db的读锁
mysql > unlock tables;
```



## 数据备份还原

```shell
# MySQL备份数据
mysqldump -uroot -p -P3306 库名 > file.sql
# 备份单表或多表
mysqldump -h 172.21.32.4 -u root -p 库名 表名 > back_table.sql
mysqldump -h 172.21.32.4 -u root -p 库名 表名1 表名2…… > back_table.sql
# 导出数据库表结构
mysqldump -uroot -p -d 库名 > file.sql
# 导入数据
mysql -uroot -p 库名 < file.sql
```

## MySQL表操作

```mysql
# 查看表结构
mysql > desc 表名;
# 增加表字段
mysql > alter table 表名 add `列名` decimal(10,4) NOT NULL DEFAULT '0.0000' COMMENT '备注';
# 修改字段
mysql > ALTER TABLE `库名`.`表名` MODIFY COLUMN `列名` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL AFTER `deleted_at`;
# 删除数据
mysql > delete from ystar_uid.sp_kyc_ocr where id = 74;
```

## 修改MySQL参数配置

```mysql
mysql > set GLOBAL sort_buffer_size = 7000000;
mysql > set GLOBAL Max_used_connections=512;
```

## MySQL用户只读模式

```mysql
# 只读模式
mysql > set global read_only=1;
# 取消普通账号的只读模式
mysql > set global read_only=0;
```



## 从库报错跳过当前错误

```mysql
mysql > set global sql_slave_skip_counter=1;
mysql > start slave;
```

## 清除MySQL binlog日志

```mysql
# 清除mysql-bin.010之前的日志，不包括mysql-bin.010
mysql > purge master logs to 'mysql-bin.010';
# 清除2018-06-22 13:00:00前binlog日志
mysql > purge master logs before '2018-06-22 13:00:00';
# 清除3天前binlog日志before，变量的date自变量可以为'yyyy-mm-dd hh:mm:ss'格式。
mysql > purge master logs before date_sub( now( ), interval 3 day);
```

## 清空表内容

```mysql
mysql > truncate table tablename;
```

## 查看参数命令

```mysql
mysql > show variables like '%_log_at_%';
```

## 查看binlog日志

```shell
./bin/mysqlbinlog --no-defaults --database=rainbow_hs --start-datetime="2019-07-03 13:25:00" --stop-datetime="2019-07-03 13:30:00" /data/db/binlog_/mysql-bin.000967 > /tmp/binlog6.txt
```

导出后的文件内容格式如下，需要加入参数：-v --base64-output=DECODE-ROWS

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

## MySQL dump 导出的数据再次导入时不同步到从库，问题解决

sql导出时加入--set-gtid-purged=OFF 参数，不加参数的后果是导出的sql文件中有SET @@SESSION.SQL_LOG_BIN= 0 项，导致再到入库中时没有写入binlog文件中，因而没有同步到从库

```shell
mysqldump --set-gtid-purged=OFF -uroot -pxxxxxxxxxxx dataname > xxxxxxx.sql
```
