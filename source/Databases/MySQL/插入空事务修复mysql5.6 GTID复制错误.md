# 插入空事务修复mysql5.6 GTID复制错误

在从库上误删除数据，导致MySQL主从复制时发生错误，从而MySQL主从复制服务停止；

## 查看MySQL salve状态，发现错误代码：1032

 ```mysql
 mysql> show slave status \G;
 ...
 Replicate_Wild_Do_Table: eoc.%,test.%,mysql.%
 Replicate_Wild_Ignore_Table: 
 Last_Errno: 1032
 Last_Error: Could not execute Delete_rows event on table eoc.eoc_course_rank; Can't find record in 'eoc_course_rank', Error_code: 1032; handler error HA_ERR_END_OF_FILE; the event's master log mysql-bin.000034, end_log_pos 684728241
 Skip_Counter: 0
 Exec_Master_Log_Pos: 684727611
 Relay_Log_Space: 257830925
 ...
 ```

GTID（全局事务标示符） 最初由google实现，在MySQL 5.6中引入。GTID在事务提交时生成，由UUID和事务ID组成。uuid会在第一次启动MySQL时生成，保存在数据目录下的auto.cnf文件里,事务id则从1开始自增。使用GTID的好处主要有两点：

1、不再需要指定传统复制中的 master_log_files和master_log_pos，使主从复制更简单可靠

2、可以实现基于库的多线程复制，减小主从复制的延迟



在传统的主从复制出错时，一般都是设置跳过出错的事务来继续同步：

1. 跳过指定数量的事务

   ```mysql
   mysql> stop slave;
   mysql> SET GLOBAL SQL_SLAVE_SKIP_COUNTER = N ; #跳过N个事务
   mysql> start slave;
   ```

2. 通过my.cnf文件跳过所有错误或指定类型的错误

   ```shell
   # 跳过指定类型的错误
   slave-skip-errors=1053,1146
   
   # 跳过所有错误
   slave-skip-errors=all
   ```

   

但是在使用GTID进行主从复制的数据库中，如果复制过程发生错误，上述方法是不能用的，我们试一下：

```mysql
mysql> set global sql_slave_skip_counter = 1;
ERROR 1858 (HY000): sql_slave_skip_counter can not be set when the server is running with @@GLOBAL.GTID_MODE = ON. Instead, for each transaction that you want to skip, generate an empty transaction with the same GTID as the transaction
```

 提示我们可以生成一个空事务来跳过错误的事务。我们先来看下主库和从库的状态：

```mysql
mysql> show master status \G;
*************************** 1. row ***************************
File: mysql-115-bin.000002
Position: 1273
Binlog_Do_DB: 
Binlog_Ignore_DB: 
Executed_Gtid_Set: 94b06c13-1f09-11e5-97ea-000c29c8caec:1-16
1 row in set (0.00 sec)
```

主库的事务id是1-16，看下从库的同步状态：

```mysql
mysql> show slave status \G;
（省略部分）
Last_SQL_Error: Worker 2 failed executing transaction '' at master log mysql-115-bin.000002, end_log_pos 614; Error 'Can't create database 'bbbb'; database exists' on query. Default database: 'bbbb'. Query: 'create database bbbb'
Retrieved_Gtid_Set: 94b06c13-1f09-11e5-97ea-000c29c8caec:1-16
Executed_Gtid_Set: 94b06c13-1f09-11e5-97ea-000c29c8caec:1-10
```

Retrieved_Gtid_Set项：记录了relay日志从Master获取了binlog日志的位置

Executed_Gtid_Set项：记录本机执行的binlog日志位置,从机上该项中包括主机和从机的binlog日志位置。



第11个事务出现问题，我们插入空事务，跳过该错误：

```mysql
STOP SLAVE;
SET GTID_NEXT="94b06c13-1f09-11e5-97ea-000c29c8caec:11";
BEGIN;
COMMIT;
SET GTID_NEXT="AUTOMATIC";
START SLAVE;
```

无论是使用哪种复制方法，都也可以重新导出主库数据重新配置主从。

