# mysql常用命令

## 数据库操作

```mysql
# 修改用户密码（mysql5.7版本）
mysql > UPDATE mysql.user SET authentication_string=PASSWORD("password") WHERE user='root';
mysql > set password for root@localhost = password('password');

# 设置 root 远程连接密码
mysql > GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by 'password' WITH GRANT OPTION;

# mysql 8.0 版本
mysql > use mysql;
mysql > update user set authentication_string='' where user='root';  # 将root密码设置为空
mysql > alter user 'root'@'localhost' identified by 'newpassword';  # 设置新的root密码
mysql > flush privileges;
mysql > update user set host = '%' where user = 'root';
mysql > alter user 'root'@'%' identified by 'root123456' password expire never; # 设置远程密码
mysql > flush privileges;

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

数据库对象的格式为`<database>.<table>`。`<database>.*`：表示授权数据库对象该数据库的所有表；`*.*`：表示授权数据库对象为所有数据库的所有表。

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

权限列表

| 权限             | 说明                           | 服务使用给予情况 |
| ---------------- | ------------------------------ | ---------------- |
| Select           | 可对其下所有表进行查询         | 建议给予         |
| Insert           | 可对其下所有表进行插入         | 建议给予         |
| Update           | 可对其下所有表进行更新         | 建议给予         |
| Delete           | 可对其下所有表进行删除         | 建议给予         |
| Create           | 可在此数据库下创建表或索引     | 建议给予         |
| Drop             | 可删除此数据库及数据库下所有表 | 不建议给予       |
| Grant            | 赋予权限选项                   | 不建议给予       |
| References       | 未来MySQL特性的占位符          | 不建议给予       |
| Index            | 可对其下所有表进行索引         | 建议给予         |
| Alter            | 可对其下所有表进行更改         | 建议给予         |
| Create_tmp_table | 创建临时表                     | 不建议给予       |
| Lock_tables      | 可对其下所有表进行锁定         | 不建议给予       |
| Create_view      | 可在此数据下创建视图           | 建议给予         |
| Show_view        | 可在此数据下查看视图           | 建议给予         |
| Create_routine   | 可在此数据下创建存储过程       | 不建议给予       |
| Alter_routine    | 可在此数据下更改存储过程       | 不建议给予       |
| Execute          | 可在此数据下执行存储过程       | 不建议给予       |
| Event            | 可在此数据下创建事件调度器     | 不建议给予       |
| Trigger          | 可在此数据下创建触发器         | 不建议给予       |


## 数据表管理

```mysql
# 创建表
create table 表名(
    列名  类型  是否可以为空，
    列名  类型  是否可以为空
)ENGINE=InnoDB DEFAULT CHARSET=utf8

# 查看数据库全部表
mysql > show tables;

# 查看表所有内容
mysql > select * from 表名;

# 查看表结构
mysql > desc table_name;

# 增加表字段
mysql > alter table table_name add `column_name` decimal(10,4) NOT NULL DEFAULT '0.0000' COMMENT 'Remark';

# 修改字段
mysql > ALTER TABLE `db_name`.`table_name` MODIFY COLUMN `column_name` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL AFTER `deleted_at`;

# 删除数据
mysql > delete from `db_name`.`table_name` where id = 1;

# 删除表
mysql > drop table table_name;

# 清空表内容
mysql > truncate table db_name;
# 或
mysql > delete from db_name;

# 添加列  
mysql > alter table 表名 add 列名 类型
mysql > alter table 表名 add 列名 类型 after `列名`

# 删除列   
mysql > alter table 表名 drop column 列名

# 修改列
mysql > alter table 表名 modify column 列名 类型;  -- 类型
mysql > alter table 表名 change 原列名 新列名 类型; -- 列名，类型

# 添加主键
mysql > alter table 表名 add primary key(列名);

# 删除主键
mysql > alter table 表名 drop primary key;
mysql > alter table 表名  modify  列名 int, drop primary key;

# 修改主键：先删除后添加
mysql > alter table 表名 drop primary key;
mysql > alter table 表名 add primary key(列名);

# 添加外键
mysql > alter table 从表 add constraint 外键名称（形如：FK从表主表） foreign key 从表(外键字段) references 主表(主键字段);

# 删除外键
mysql > alter table 表名 drop foreign key 外键名称

# 修改默认值：
mysql > ALTER TABLE testalter_tbl ALTER i SET DEFAULT 1000;

# 删除默认值：
mysql > ALTER TABLE testalter_tbl ALTER i DROP DEFAULT;

# 调整表结构字段顺序
mysql > alter table <table_name> modify <字段1> varchar(10) after <字段2>;
mysql > alter table <table_name> modify id int(10) unsigned auto_increment first;
```

创建表：

- 默认值，创建列时可以指定默认值，当插入数据时如果未主动设置，则自动添加默认值
- 自增，如果为某列设置自增列，插入数据时无需设置此列，默认将自增（表中只能有一个自增列）注意：1、对于自增列，必须是索引（含主键）2、对于自增可以设置步长和起始值
- 主键，一种特殊的唯一索引，不允许有空值，如果主键使用单个列，则它的值必须唯一，如果是多列，则其组合必须唯一。

## 表内容操作

### 增

```mysql
mysql > insert into 表 (列名,列名...) values (值,值,...)
mysql > insert into 表 (列名,列名...) values (值,值,...),(值,值,值...)
mysql > insert into 表 (列名,列名...) select (列名,列名...) from 表

# 例：
mysql > insert into tab1(name,email) values('xxxx','xxxxx@163.com')
```

### 删

```mysql
mysql > delete from 表                                      # 删除表里全部数据
mysql > delete from 表 where id＝1 and name＝'zhangyanlin'   # 删除ID =1 和name='zhangyanlin' 那一行数据
```

### 改

```mysql
mysql > update 表 set name ＝ 'zhangyanlin' where id>1
```

### 查

```mysql
mysql > select * from 表
mysql > select * from 表 where id > 1
mysql > select nid,name,gender as gg from 表 where id > 1
```

### 条件判断

**where**

```mysql
mysql > select * from <table> where id >1 and name!='huwh' and num =12;
mysql > select * from <table> where id between 5 and 6;
mysql > select * from <table> where id in (11,22,33);
mysql > select * from <table> where id not in (11,22,33);
mysql > select * from <table> where id in (select nid from <table>)
```

**通配符like**

```mysql
mysql > select * from <table> where name like 'hu%';   #hu开头
mysql > select * from <table> where name like 'hu_'    #hu开头后接一个字符
```

**限制limit**

```mysql
mysql > select * from <table> limit 5;   #前5行
mysql > select * from <table> limit 4,5  #从第四行开始的5行
mysql > select * from <table> limit 5 offset 4;#从第四行开始的5行
```

**排序asc，desc**

```mysql
mysql > select * from <table> order by 列 asc;            #跟据“列”从小到大排序（不指定默认为从小到大排序）
mysql > select * from <table> order by 列 desc;           #根据“列”从大到小排序
mysql > select * from <table> order by 列1 desc,列2 asc;  #根据“列1”从大到小排序，如果相同则按“列2”从小到大排序
```

**分组group by**

group by 必须在where之后，order by之前。

```mysql
mysql > select num,from <table> group by num;     
mysql > select num,nid from <table> group by num,nid;
mysql > select num from <table> where nid > 10 group by num,nid order nid desc;
mysql > select num,nid,count(*),sum(score),max(score) from <table> group by num;
mysql > select num from <table> group by num having max(id) > 10;
mysql > select num from <table> group by num;
```



## 数据备份还原

```shell
# 备份单个数据库
# 格式：mysqldump -u 用户名 -p 数据库名 > 文件名
$ mysqldump -uroot -p -P3306 db_name > file.sql

# 同时备份多个数据库，例如 database1，database2
$ mysqldump -u user_name -p123456 --databases database1 database2 > file.sql

# 备份全部数据库
$ mysqldump -u user_name -p123456 --all-databases > file.sql

# 备份单表
# 格式：mysqldump -u 用户名 -p 数据库名 表名> 文件名
$ mysqldump -h 172.21.32.4 -u root -p db_name table_name > back_table.sql

# 备份多表
$ mysqldump -h 172.21.32.4 -u root -p db_name table_name1 table_name2 …… > back_table.sql

# 导出数据库表结构
# -d 没有数据 –add-drop-table 在每个create语句之前增加一个drop table
$ mysqldump -uroot -p -d db_name > file.sql

# 带语言参数导出
$ mysqldump -uroot -p –default-character-set=latin1 –set-charset=gbk –skip-opt database > file.sql

# 导入单个数据库
$ mysql -uroot -p db_name < file.sql

# 导入多个数据库
$ mysql -u root –p < [备份文件的保存路径]
```



## 参数设置

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

   

## Binlog 日志

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

