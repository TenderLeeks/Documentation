# 常见问题

## 插入空事务修复mysql5.6 GTID复制错误

在从库上误删除数据，导致MySQL主从复制时发生错误，从而MySQL主从复制服务停止；

### 查看MySQL salve状态，发现错误代码：1032

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



## MySQL编码utf8升级utf8mb4

首先将我们数据库默认字符集由 `utf8` 更改为 `utf8mb4`，然后将表默认字符集也更改为utf8mb4，最后再把存储表情的字段默认字符集也做相应的调整。 

```mysql
# 修改数据库
mysql > ALTER DATABASE database_name CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
# 修改表
mysql > ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# 修改表字段
mysql > ALTER TABLE table_name CHANGE column_name column_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

修改MySQL配置文件，新增如下参数：

```shell
[client]
default-character-set = utf8mb4
[mysql]
default-character-set = utf8mb4
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect='SET NAMES utf8mb4'
```

解释：

- `character_set_server`：默认的内部操作字符集

- `character_set_client`：客户端来源数据使用的字符集

- `character_set_connection`：连接层字符集

- `character_set_results`：查询结果字符集

- `character_set_database`：当前选中数据库的默认字符集

- `character_set_system`：系统元数据(字段名等)字符集

- 还有以 `collation_` 开头的同上面对应的变量，用来描述字符序。



检查环境变量 和测试 SQL 如下：

```mysql
mysql > SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%' OR Variable_name LIKE 'collation%';
```

**注意：MySQL版本必须为5.5.3以上版本，否则不支持字符集utf8mb4**



建议：

- 建议普通表使用utf8， 如果这个表需要支持emoji就使用utf8mb4

- 新建mysql库或者表的时候还有一个排序规则

- utf8_unicode_ci比较准确，utf8_general_ci速度比较快。通常情况下 utf8_general_ci的准确性就够我们用的了，在我看过很多程序源码后，发现它们大多数也用的是utf8_general_ci，所以新建数据 库时一般选用utf8_general_ci就可以了

- 如果是utf8mb4那么对应的就是 utf8mb4_general_ci utf8mb4_unicode_ci



`utf8_unicode_ci` 与 `utf8_general_ci` 的区别

当前，utf8_unicode_ci校对规则仅部分支持Unicode校对规则算法。一些字符还是不能支持。并且，不能完全支持组合的记号。这主要影响越南和俄罗斯的一些少数民族语言，如：Udmurt 、Tatar、Bashkir和Mari。

utf8_unicode_ci的最主要的特色是支持扩展，即当把一个字母看作与其它字母组合相等时。例如，在德语和一些其它语言中‘ß’等于‘ss’

utf8_general_ci是一个遗留的校对规则，不支持扩展。它仅能够在字符之间进行逐个比较。这意味着utf8_general_ci校对规则进行的比较速度很快，但是与使用utf8_unicode_ci的校对规则相比，比较正确性较差



例如，使用utf8_general_ci和utf8_unicode_ci两种 校对规则下面的比较相等：

Ä = A

Ö = O

Ü = U

两种校对规则之间的区别是，对于utf8_general_ci下面的等式成立：ß = s

但是，对于utf8_unicode_ci下面等式成立：ß = ss

对于一种语言仅当使用utf8_unicode_ci排序做的不好时，才执行与具体语言相关的utf8字符集 校对规则。例如，对于德语和法语，utf8_unicode_ci工作的很好，因此不再需要为这两种语言创建特殊的utf8校对规则。

utf8_general_ci也适用与德语和法语，除了‘ß’等于‘s’，而不是‘ss’之外。如果你的应用能够接受这些，那么应该使用utf8_general_ci，因为它速度快。否则，使用utf8_unicode_ci，因为它比较准确。



案例 

```mysql
CREATE TABLE test_session (
  sessionId varchar(255) NOT NULL,
  userId int(10) unsigned DEFAULT NULL,
  createAt datetime DEFAULT NULL
)
```

执行上面的代码会报一个错误：Specified key was too long; max key length is 767 bytes

当使用utf8mb4编码后，主键id的长度设置255，太长，只能设置小于191的

报错原因：utf8编码下，255长度的varchar长度约767，更改成utf8mb4后，最大只能支持191长度

max key length is 767 bytes

utf8: 767/3=255.6666666666667

utf8mb4: 767/4=191.75

数据库连接的配置

数据库连接参数中: 

characterEncoding=utf8会被自动识别为utf8mb4，也可以不加这个参数，会自动检测。 

而autoReconnect=true是必须加上的。