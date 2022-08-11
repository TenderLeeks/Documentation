# Percona XtraBackup 8.0

[官方文档](https://docs.percona.com/percona-xtrabackup/8.0/installation.html)

## 介绍

随着*Percona XtraBackup* 8.0 的推出，*Percona XtraBackup* 2.4 将继续支持 MySQL 和 Percona Server 5.6 和 5.7 数据库。由于新的 MySQL 重做日志和数据字典格式，Percona XtraBackup 8.0.x 版本将仅与 MySQL 8.0.x 和即将推出的 Percona Server for MySQL 8.0.x 兼容。

支持的存储引擎

- Percona XtraBackup 可与 MySQL 和 Percona Server 一起使用。它支持 InnoDB、XtraDB 和 MyRocks 存储引擎的完全非阻塞备份。启用了 XtraDB 更改页面跟踪的 Percona Server 支持快速增量备份。
- 此外，它可以通过在备份结束时短暂暂停写入来备份以下存储引擎：MyISAM 和[Merge](https://docs.percona.com/percona-xtrabackup/8.0/glossary.html#term-.MRG)，包括分区表、触发器和数据库选项。InnoDB 表在复制非 InnoDB 数据时仍处于锁定状态。
- MyRocks 存储引擎的支持是在 8.0.6 版本中添加的。MyRocks 存储引擎上的增量备份不能确定较早的完整备份或增量备份是否包含相同的文件。**Percona XtraBackup**每次进行备份时都会复制所有 MyRocks 文件。
- Percona XtraBackup 8.0 不支持 TokuDB 存储引擎。

## 使用二进制压缩包

下载二进制包请使用此[链接](https://www.percona.com/downloads/Percona-XtraBackup-LATEST/)查找

```shell
$ wget https://downloads.percona.com/downloads/Percona-XtraBackup-LATEST/Percona-XtraBackup-8.0.28-20/binary/tarball/percona-xtrabackup-8.0.28-20-Linux-x86_64.glibc2.17.tar.gz

$ tar -zxf percona-xtrabackup-8.0.28-20-Linux-x86_64.glibc2.17.tar.gz -C /opt
$ mv /opt/percona-xtrabackup-8.0.28-20-Linux-x86_64.glibc2.17 /opt/percona-xtrabackup-8.0.28

# 添加环境变量
$ tee /etc/profile.d/xtrabackup-8.0.28.sh << EOF
export PATH=/opt/percona-xtrabackup-8.0.28/bin:\$PATH
EOF
$ source /etc/profile
```

## 设置连接权限

权限是指允许系统用户在数据库服务器中进行的操作。**它们是在数据库服务器上设置的，仅适用于数据库服务器中的用户**。

权限是允许用户在系统上执行操作的权限，例如在某个目录上读取、写入或执行或启动/停止系统服务。**它们是在系统级别设置的，仅适用于系统用户**。

用于连接服务器的数据库用户及其密码由`--user`和`--password`选项指定：

```shell
$ mkdir -p /opt/backups/base/
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=Root_password --backup \
  --defaults-file=/opt/mysql-8.0.29/conf/my.cnf \
  --target-dir=/opt/backups/base
# 或者
$ xtrabackup --socket=/opt/mysql-8.0.29/var/mysql.sock \
  --user=root --password=Root_password --backup \
  --defaults-file=/opt/mysql-8.0.29/conf/my.cnf \
  --target-dir=/opt/backups/base
```

报错信息：

```shell
[ERROR] [MY-011825] [Xtrabackup] Unsupported server version 8.0.29
[ERROR] [MY-011825] [Xtrabackup] Please upgrade PXB, if a new version is available. To continue with risk, use the option --no-server-version-check.
```

提示当前的Percona Xtrabackup(8.0.28-20)不支持MySQL 8.0.29，Percona官方网址，Xtrabackup最新版本为percona-xtrabackup-80-8.0.28-20。而MySQL的官方最新版本为MySQL 8.0.29。

不过，根据官方文档，Percona XtraBackup 8.0.21 开始，新增了`--no-server-version-check` 参数。此参数控制是否将源系统版本与 Percona XtraBackup 版本进行比较。

```shell
--no-server-version-check  # 此选项允许在服务器版本高于（更新）PXB 支持的版本时进行备份
```

该参数检查以下场景：

- 源系统和PXB版本一样，备份继续
- 源系统低于PXB版本，备份继续
- 源系统大于PXB版本，且参数未被覆盖，停止备份并返回错误信息
- 源系统大于PXB版本，参数被覆盖，备份继续

所以我们如果使用参数`--no-server-version-check`备份的话，可能可以备份成功。也可能备份失败，还有可能创建了一个损坏的备份。

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --no-server-version-check \
  --target-dir=/opt/backups/base
```

执行报错：

```shell
[ERROR] [MY-011825] [Xtrabackup] failed to execute query 'LOCK INSTANCE FOR BACKUP' : 1227 (42000) Access denied; you need (at least one of) the BACKUP_ADMIN privilege(s) for this operation
```

需要给执行备份的用户添加`BACKUP_ADMIN`权限

```shell
$ /opt/mysql-8.0.29/bin/mysql -S /opt/mysql-8.0.29/var/mysql.sock -uroot -p
mysql> grant BACKUP_ADMIN on *.* to 'root'@'%';
mysql> flush privileges;
```

执行报错：

```shell
[MY-012530] [InnoDB] Unknown redo log format (5). Please follow the instructions at http://dev.mysql.com/doc/refman/8.0/en/ upgrading-downgrading.html.
[MY-011825] [Xtrabackup] recv_find_max_checkpoint() failed.
```

xtrabackup 备份时需要开一个子进程持续备份 MySQL 的 redo log 重做日志。那现在的状态是 xtrabackup 识别不了 redo log 重做日志，必然也是会备份失败退出的。

**建议PXB使用的版本大于等于MySQL的版本。**

### 权限设置

数据库用户需要对要备份的表或数据库具有以下权限：

- `RELOAD`和（除非 指定了该选项）以便在开始复制文件之前运行，并且 在 使用[备份锁时需要此权限](http://www.percona.com/doc/percona-server/8.0/management/backup_locks.html)`LOCK TABLES`[`--no-lock`](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/xbk_option_reference.html#cmdoption-no-lock)`FLUSH TABLES WITH READ LOCK``FLUSH ENGINE LOGS`
- `BACKUP_ADMIN`查询 performance_schema.log_status 表并运行、 或需要权限。`LOCK INSTANCE FOR BACKUP``LOCK BINLOG FOR BACKUP``LOCK TABLES FOR BACKUP`
- `REPLICATION CLIENT`为了获得二进制日志位置，
- `CREATE TABLESPACE`为了导入表（请参阅[恢复单个表](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/restoring_individual_tables.html#pxb-xtrabackup-table-restoring)），
- `PROCESS`为了运行（这是强制性的），并且可以选择查看在服务器上运行的所有线程（请参阅[处理带有读锁](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/flush-tables-with-read-lock.html#pxb-xtrabackup-flush-tables-with-read-lock)的刷新表），`SHOW ENGINE INNODB STATUS`
- `SUPER`为了在复制环境中启动/停止复制线程，使用[XtraDB Changed Page Tracking](https://www.percona.com/doc/percona-server/8.0/management/changed_page_tracking.html) for [Incremental Backups](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/incremental_backups.html#xb-incremental)和[处理 FLUSH TABLES WITH READ LOCK](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/flush-tables-with-read-lock.html#pxb-xtrabackup-flush-tables-with-read-lock)，
- `CREATE`权限以创建 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.history.html#xtrabackup-history)数据库和表，
- `ALTER`权限以升级 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.history.html#xtrabackup-history)数据库和表，
- `INSERT`特权，以便将历史记录添加到 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.history.html#xtrabackup-history)表中，
- `SELECT`特权，以便使用 [`--incremental-history-name`](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/xbk_option_reference.html#cmdoption-incremental-history-name)或 [`--incremental-history-uuid`](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/xbk_option_reference.html#cmdoption-incremental-history-uuid)为了让功能在[PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.history.html#xtrabackup-history)表中查找`innodb_to_lsn`值 。
- `SELECT`[keyring_component_status 表](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-keyring-component-status-table.html)的权限， 可在使用时查看已安装密钥环组件的属性和状态。

创建具有完整备份所需的最低权限的数据库用户的 SQL 示例如下：

```mysql
mysql> CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY 's3cr%T';
mysql> GRANT BACKUP_ADMIN, PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'bkpuser'@'localhost';
mysql> GRANT SELECT ON performance_schema.log_status TO 'bkpuser'@'localhost';
mysql> GRANT SELECT ON performance_schema.keyring_component_status TO bkpuser@'localhost'
mysql> FLUSH PRIVILEGES;
```

## 完整备份

要创建备份，请使用该 选项运行**xtrabackup 。**`--backup`您还需要指定`--target-dir`选项，即存储备份的位置，如果*InnoDB*数据或日志文件未存储在同一目录中，您可能还需要指定它们的位置。如果目标目录不存在，**xtrabackup**会创建它。如果该目录确实存在并且为空，**则 xtrabackup**将成功。

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/base
```

### 准备备份

使用该选项进行备份后`--backup`，您需要准备它才能恢复它。*数据文件在准备好*之前不是时间点一致的，因为它们是在程序运行时在不同时间复制的，并且在发生这种情况时它们可能已被更改。

如果尝试使用这些数据文件启动 InnoDB，它将检测损坏并停止工作以避免在损坏的数据上运行。该`--prepare`步骤使文件在单个时刻完全一致，因此可以在它们上运行 *InnoDB*。

可以在任何机器上运行*准备操作；*它不需要位于原始服务器或您要还原到的服务器上。可以将备份复制到实用程序服务器并在那里进行准备。

请注意，*Percona XtraBackup* 8.0 只能准备*MySQL* 8.0、*Percona Server for MySQL* 8.0 和*Percona XtraDB Cluster* 8.0 数据库的备份。不支持 8.0 之前的版本。

在*准备*操作期间，**xtrabackup**启动一种经过修改的嵌入式 InnoDB（**xtrabackup**链接的库）。这些修改对于禁用 InnoDB 标准安全检查是必要的，例如抱怨日志文件的大小不合适。此警告不适用于使用备份。这些修改仅适用于 xtrabackup 二进制文件；不需要修改过的*InnoDB*即可使用**xtrabackup**进行备份。

```shell
$ xtrabackup --prepare --target-dir=/opt/backups/base
```

不建议在准备备份时中断 xtrabackup 进程，因为这可能会导致数据文件损坏，备份将变得不可用。如果准备过程被中断，则无法保证备份的有效性。

如果打算将备份作为进一步增量备份的基础，则应`--apply-log-only`在准备备份时使用该选项，否则您将无法对其应用增量备份。

### 恢复备份

警告：

- **在恢复之前需要准备好备份**

```shell
$ xtrabackup --copy-back --target-dir=/opt/backups/base \
  --datadir=/opt/mysql-8.0.28/data
  
$ chown -R mysql.mysql /opt/mysql-8.0.28/data

# 如果不想保存备份，可以使用 --move-back将备份数据移动到datadir的选项。
$ xtrabackup --move-back --target-dir=/opt/backups/base \
  --datadir=/opt/mysql-8.0.28/data
```

在恢复备份之前，**datadir**必须为空。同样重要的是要注意 MySQL 服务器需要在执行还原之前关闭。您无法恢复到正在运行的**mysqld**实例的数据目录（导入部分备份时除外）。

可用于恢复备份的**rsync**命令示例如下所示：

```shell
$ rsync -avrP /data/backup/ /var/lib/mysql/
```

## 增量备份

**xtrabackup**支持增量备份，这意味着它们只能复制自上次备份以来已更改的数据。

MyRocks 存储引擎上的增量备份不能确定较早的完整备份或增量备份是否包含相同的文件。**Percona XtraBackup**每次进行备份时都会复制所有 MyRocks 文件。

可以在每次完整备份之间执行多次增量备份，可以设置备份过程，例如每周一次完整备份和每天一次增量备份，或者每天一次完整备份和每小时一次增量备份。

增量备份之所以有效，是因为每个*InnoDB*页面都包含一个日志序列号或[LSN](https://docs.percona.com/percona-xtrabackup/8.0/glossary.html#term-LSN)。[LSN](https://docs.percona.com/percona-xtrabackup/8.0/glossary.html#term-LSN)是整个数据库的系统版本号。每个页面的[LSN](https://docs.percona.com/percona-xtrabackup/8.0/glossary.html#term-LSN)显示它最近的更改时间。

**注意：**

- 增量备份实际上并不将数据文件与先前备份的数据文件进行比较。因此，在 *部分备份*之后运行增量备份可能会导致数据不一致。
- 增量备份只需读取页面并将其LSN]与上次备份的LSN进行比较。但是，仍然需要完整备份来恢复增量更改；如果没有完整备份作为基础，增量备份就毫无用处。
- 如果知道其LSN，则可以使用该`--incremental-lsn`选项执行增量备份，甚至无需以前的备份。

### 创建增量备份

要进行增量备份，请像往常一样从完整备份开始。**xtrabackup**二进制文件将调用的文件写入备份 `xtrabackup_checkpoints`的目标目录。

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/base

$ cat /opt/backups/base/xtrabackup_checkpoints
backup_type = full-backuped
from_lsn = 0
to_lsn = 18205288
last_lsn = 18205288
flushed_lsn = 18205288
```

在完整备份的基础上进行增量备份

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/inc1 \
  --incremental-basedir=/opt/backups/base

$ cat /opt/backups/inc1/xtrabackup_checkpoints 
backup_type = incremental
from_lsn = 18205288
to_lsn = 18219720
last_lsn = 18222180
flushed_lsn = 18219720
```

`from_lsn`是备份的起始 LSN，对于增量备份，它必须与`to_lsn`前一个/基本备份的（如果它是最后一个检查点）相同。

现在可以将此目录用作另一个增量备份的基础：

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/inc2 \
  --incremental-basedir=/opt/backups/inc1

$ cat /opt/backups/inc2/xtrabackup_checkpoints 
backup_type = incremental
from_lsn = 18219720
to_lsn = 18232409
last_lsn = 18234300
flushed_lsn = 18232409
```

`to_lsn` 在这种情况下，您可以看到（最后一个检查点 LSN）和（最后一个复制的 LSN）之间存在差异`last_lsn`，这意味着在备份过程中服务器上有一些流量。

### 准备增量备份

增量备份的`--prepare`步骤与完整备份的步骤不同。在完整备份中，执行两种类型的操作以使数据库保持一致：从日志文件中针对数据文件重放已提交的事务，以及回滚未提交的事务。在准备增量备份时，必须跳过未提交事务的回滚，因为在备份时未提交的事务可能正在进行中，并且很可能会在下一次增量备份中提交。应该使用该 `--apply-log-only`选项来防止回滚阶段。

**警告：**

- **如果您不使用该** **选项来阻止回滚阶段，那么您的增量备份将毫无用处**。事务回滚后，无法应用进一步的增量备份。`--apply-log-only`

```shell
$ xtrabackup --prepare --apply-log-only --target-dir=/opt/backups/base
```

将第一个增量备份应用于完整备份

```shell
$ xtrabackup --prepare --apply-log-only \
  --target-dir=/opt/backups/base \
  --incremental-dir=/opt/backups/inc1

$ cat /opt/backups/base/xtrabackup_checkpoints 
backup_type = log-applied
from_lsn = 0
to_lsn = 18219720
last_lsn = 18222180
flushed_lsn = 18219720
```

这会将增量文件应用于 中的文件`/opt/backups/base`，从而及时将它们前滚到增量备份的时间。然后它像往常一样将重做日志应用于结果。最终数据在 中 `/opt/backups/base`，而不是在增量目录中。

同样，LSN应该与您之前检查第一次增量备份时看到的一致。如果从 中恢复文件 `/data/backups/base`，您应该会看到数据库在第一次增量备份时的状态。

**警告：**

- *Percona XtraBackup*不支持使用同一个增量备份目录准备两份备份。不要多次`--prepare`使用相同的增量备份目录（–incremental-dir的值）运行。

准备第二次增量备份是一个类似的过程：将增量应用于（修改的）基础备份，您将及时将其数据前滚到第二次增量备份的点：

```shell
$ xtrabackup --prepare --apply-log-only \
  --target-dir=/opt/backups/base \
  --incremental-dir=/opt/backups/inc2

$ cat /opt/backups/base/xtrabackup_checkpoints backup_type = log-applied
from_lsn = 0
to_lsn = 18232409
last_lsn = 18234300
flushed_lsn = 18232409
```

`--apply-log-only`合并除最后一个以外的所有增量时应使用。这就是为什么上一行不包含该 `--apply-log-only`选项的原因。即使`--apply-log-only`在最后一步使用了，备份仍然是一致的，但在这种情况下，服务器将执行回滚阶段。



## 压缩备份

*Percona XtraBackup*支持压缩备份：可以使用`xbstream`压缩或解压缩本地或流式备份。

### 创建压缩备份

为了进行压缩备份，您需要使用以下`--compress` 选项：

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --compress --target-dir=/opt/backups/base1
```

`xtrabackup –compress` 使用 `qpress` 工具，可以通过 `percona-release` 包配置工具安装该工具，如下所示：

```shell
#$ sudo percona-release enable tools
#$ sudo apt update
#$ sudo apt install qpress

$ wget http://www.quicklz.com/qpress-11-linux-x64.tar
$ tar -xf qpress-11-linux-x64.tar -C /opt/percona-xtrabackup-2.4.25/bin
```

如果要加快压缩速度，可以使用并行压缩，可以通过`--compress-threads`选项启用。以下示例将使用2个线程进行压缩：

```shell
$ xtrabackup --defaults-file=/opt/mysql-8.0.28/conf/my.cnf \
  --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --compress --compress-threads=2 \
  --target-dir=/opt/backups/base3
```

### 准备备份

在准备备份之前，您需要解压缩所有文件。 *Percona XtraBackup*已实现`--decompress`可用于解压缩备份的选项。

```shell
$ xtrabackup --decompress --target-dir=/opt/backups/base1
```

`--parallel`可以与 `--decompress`选项一起使用以同时解压缩多个文件。

*Percona XtraBackup*不会自动删除压缩文件。为了清理备份目录，应该使用 `--remove-original`选项。即使它们没有被删除，如果 `--copy-back`或被`--move-back`使用，这些文件也不会被复制/移动到数据目录。

解压缩文件后，您可以使用以下 `--prepare`选项准备备份：

```shell
$ xtrabackup --prepare --target-dir=/opt/backups/base1
```

### 恢复备份

**xtrabackup**有一个`--copy-back`选项，它执行将备份恢复到服务器的datadir目录

```shell
$ xtrabackup --copy-back --target-dir=/opt/backups/base \
  --datadir=/opt/mysql-8.0.28/data
  
$ chown -R mysql.mysql /opt/mysql-8.0.28/data
```

## 限制备份

尽管**xtrabackup**不会阻止您的数据库操作，但任何备份都可能给正在备份的系统增加负载。在没有太多备用 I/O 容量的系统上，限制 **xtrabackup**读取和写入数据的速率可能会有所帮助。您可以使用该 `--throttle`选项执行此操作。此选项限制每秒复制的块数。块 +size 是*10 MB*。

当使用该选项指定时，此选项限制**xtrabackup 每秒**将执行`--backup`的读写操作对的数量 。如果您正在创建增量备份，则限制是每秒读取 I/O 操作的数量。

默认情况下，没有节流，**xtrabackup**尽可能快地读取和写入数据。如果对 IOPS 设置的限制太严格，备份可能会非常慢，以至于它永远无法赶上 InnoDB 正在写入的事务日志，因此备份可能永远无法完成。

## 加密的 InnoDB 表空间备份

具体信息请查看[官方文档](https://docs.percona.com/percona-xtrabackup/8.0/advanced/encrypted_innodb_tablespace_backups.html)

## 加密备份

具体信息请查看[官方文档](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.encrypting.html)



# 自动备份脚本

`vim PerconaXtraBackup.sh`

```shell
#!/bin/bash

# MySQL数据库连接信息
user=root
password=root_password
host="127.0.0.1"

# 备份文件保留时间
LEAVE_DAY_AGO=$(date -d "-30 day" +'%s' )

# 定义备份目录
backup_basedir="/opt/backup_mysql"
# 全量数据目录
full_data_backup="${backup_basedir}/base"
# 增量数据目录
inc_data_backup="${backup_basedir}/inc"

# 定义日志输出
LOG_FILE="${backup_basedir}/log/log_$(date +%Y-%m-%d_%H).log"

# 定义最新备份数据的目录名称
last_name_file="${backup_basedir}/var/last_backup_dir_name"

[ -d ${full_data_backup} ] || mkdir -p ${full_data_backup}
[ -d ${inc_data_backup} ] || mkdir -p ${inc_data_backup}
[ -d "${backup_basedir}/log" ] || mkdir -p "${backup_basedir}/log"
[ -d "${backup_basedir}/var" ] || mkdir -p "${backup_basedir}/var"


function full_backup() {
  DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
  echo "Start backing up full data ..." &>> "${LOG_FILE}"

  # 开始备份全量数据
  xtrabackup --host="${host}" --user="${user}" --password="${password}" \
  --backup --target-dir=${full_data_backup}/base_"${DATE_TIME}" >> "${LOG_FILE}" 2>&1

  if [ "$?" != "0" ]; then
    echo " Backup full data error !" &>> "${LOG_FILE}"
    exit 1;
  else
    echo " end copied! ..." &>>"${LOG_FILE}"
    # shellcheck disable=SC2010
    FILE_NAME=$(ls -lt "${full_data_backup}" |grep - |head -n 1 |awk '{print $9}')
    echo "${full_data_backup}/${FILE_NAME}" > ${last_name_file}
  fi;

  # 删除 ${LEAVE_DAY_AGO} 天前的备份目录及子目录、文件
  files=$(ls ${full_data_backup})
  for file_name in $files
  do
    # shellcheck disable=SC2206
    file=(${file_name:5:10})
    # shellcheck disable=SC2128
    if echo "${file}" | grep -Eq "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}" && date -d "${file}" +%Y%m%d > /dev/null 2>&1; then
      echo "${file_name}" 'format is right date' &>>"${LOG_FILE}"
      file_time=$(date -d "${file}" +'%s' )

      # 校验备份记录是否已过期
      if [ "${file_time}" -lt "${LEAVE_DAY_AGO}" ];then
        rm -rf ${full_data_backup}/"base_${file_name}"*
        echo " remove ${file_name} directory " &>>"${LOG_FILE}"
      else
        echo "${file_name} is valid backup directory" &>>"${LOG_FILE}"
      fi;

    else
      echo "date format is invalid" "${file_name}" &>>"${LOG_FILE}"
    fi;
  done
}


function inc_backup() {
  DATE_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
  echo "increment start copying ..." &>>"${LOG_FILE}"

  # 获取最近一次备份的目录地址
  last_backup_dir_name=$(cat ${last_name_file})

  # 增量备份
  xtrabackup --host="${host}" --user="${user}" --password="${password}" \
  --backup --target-dir=${inc_data_backup}/inc_"${DATE_TIME}" --incremental-basedir="${last_backup_dir_name}" \
  >> "${LOG_FILE}" 2>&1

  if [ "$?" != "0" ]; then
    echo " increment backup data error !" &>>"${LOG_FILE}"
    exit 1;
  else
    echo "increment end copied! ..." &>>"${LOG_FILE}"
    # shellcheck disable=SC2010
    FILE_NAME=$(ls -lt "${inc_data_backup}" |grep - |head -n 1 |awk '{print $9}')
    echo "${inc_data_backup}/${FILE_NAME}" > ${last_name_file}
  fi;

  # 删除 ${LEAVE_DAY_AGO} 天前的备份目录及子目录、文件
  files=$(ls ${inc_data_backup})
  for filename in ${files}
  do
    # shellcheck disable=SC2206
    file=(${filename:4:10})
    # shellcheck disable=SC2128
    if echo "${file}" | grep -Eq "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}" && date -d "${file}" +%Y%m%d > /dev/null 2>&1;then
      echo "${filename} 'format is right date'" &>>"${LOG_FILE}"
      file_time=$(date -d "${file}" +'%s' )

      # 校验备份记录是否已过期
      if [ "${file_time}" -lt "${LEAVE_DAY_AGO}" ];then
        rm -rf ${inc_data_backup}/inc_"${filename}"*
        echo " remove ${filename} directory " &>>"${LOG_FILE}"
      else
        echo "${filename} is valid backup directory" &>>"${LOG_FILE}"
      fi;
    else
      echo "date format is invalid" "${filename}" &>>"${LOG_FILE}"
    fi;
  done
}

case "$1" in
  full)
    full_backup
    ;;
  inc)
    inc_backup
    ;;
  *)
    echo $"Usage: $0 {full|inc}"
    ;;
esac
```

设置定时任务

```shell
$ crontab -l
# 每周日凌晨6点执行全量备份
$ 0 6 * * 7 /bin/bash /opt/backup_mysql/PerconaXtraBackup.sh full
# 每天凌晨1点执行增量备份
$ 0 1 * * * /bin/bash /opt/backup_mysql/PerconaXtraBackup.sh inc
```

