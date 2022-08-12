# Percona XtraBackup 2.4

[官方文档](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html)

## 介绍

`Percona XtraBackup`是基于MySQL的服务器的开源热备份实用程序，在备份期间不会锁定您的数据库。

它可以备份*MySQL* 5.1 [[1\]](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html#n-1)、5.5、5.6 和 5.7 服务器上的*InnoDB*、XtraDB 和*MyISAM*表中的 数据，以及带有 XtraDB的*Percona Server for MySQL 。*

***Percona XtraBackup* 2.4 不支持备份在*MySQL* 8.0、*Percona Server for MySQL* 8.0 或 Percona XtraDB Cluster 8.0 中创建的数据库。**

`Percona XtraBackup`是世界上唯一一款开源、免费的*MySQL热备份软件，可为InnoDB和 XtraDB 数据库执行非阻塞备份。使用*Percona XtraBackup，您可以获得以下好处：

- 快速可靠地完成备份
- 备份期间不间断的事务处理
- 节省磁盘空间和网络带宽
- 自动备份验证
- 恢复时间更快，正常运行时间更长

*支持 InnoDB、Percona XtraDB Cluster 和HailDB*存储引擎的非阻塞备份。此外，Percona XtraBackup 可以通过在备份结束时短暂暂停写入来备份以下存储引擎：MyISAM、Merge <.MRG>和Archive <.ARM>，包括分区表、触发器和数据库选项。InnoDB 表在复制非 InnoDB 数据时仍处于锁定状态。启用 Percona XtraDB Cluster 更改页面跟踪的 Percona Server 支持快速增量备份。

**Percona XtraBackup 2.4 仅支持 Percona XtraDB Cluster 5.7。Percona XtraBackup 2.4 不支持 MyRocks 存储引擎或 TokuDB 存储引擎。*Percona XtraBackup*与 MariaDB 10.3 及更高版本不兼容。**

特点：

- 在不暂停数据库的情况下创建热 InnoDB 备份
- 对 MySQL 进行增量备份
- 将压缩的 MySQL 备份流式传输到另一台服务器
- 在 MySQL 服务器之间在线移动表
- 轻松创建新的 MySQL 复制副本
- 在不增加服务器负载的情况下备份 MySQL
- 备份锁是Percona Server 5.6+ 中可用的轻量级替代方案。Percona XtraBackup 自动使用它们来复制非 InnoDB 数据，以避免阻塞修改 InnoDB 表的 DML 查询。`FLUSH TABLES WITH READ LOCK`
- Percona XtraBackup 根据每秒 IO 操作数执行节流。
- Percona XtraBackup 会跳过二级索引页并在准备好紧凑备份时重新创建它们。
- Percona XtraBackup 甚至可以从完整备份中导出单个表，无论 InnoDB 版本如何。
- 使用 Percona XtraBackup 导出的表可以导入 Percona Server 5.1、5.5 或 5.6+，或 MySQL 5.6+。



## 使用二进制压缩包

下载二进制包请使用此[链接](https://www.percona.com/downloads/)查找

```shell
$ wget https://downloads.percona.com/downloads/Percona-XtraBackup-2.4/Percona-XtraBackup-2.4.25/binary/tarball/percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12.tar.gz

$ tar -zxf percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12.tar.gz -C /opt
$ mv /opt/percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12 /opt/percona-xtrabackup-2.4.25

# 添加环境变量
$ tee /etc/profile.d/xtrabackup-2.4.25.sh << EOF
export PATH=/opt/percona-xtrabackup-2.4.25/bin:\$PATH
EOF
$ source /etc/profile
```

## 设置连接权限

*Percona XtraBackup*需要能够连接到数据库服务器并在创建备份时、在某些情况下准备时以及在恢复时对服务器和datadir执行操作。为此，必须满足其执行的特权和权限要求。

权限是指允许系统用户在数据库服务器中进行的操作。**它们是在数据库服务器上设置的，仅适用于数据库服务器中的用户**。

权限是允许用户在系统上执行操作的权限，例如在某个目录上读取、写入或执行或启动/停止系统服务。**它们是在系统级别设置的，仅适用于系统用户**。

无论使用*xtrabackup*还是 innobackupex，都涉及到两个参与者：调用程序*的用户 - 系统用户*- 以及在数据库服务器中执行操作的用户 -*数据库用户*。请注意，这些是不同位置的不同用户，即使他们可能具有相同的用户名。

### 连接到服务器

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backup/
```

如果不使用`xtrabackup –user`选项，*Percona XtraBackup* 将假定数据库用户的名称是执行它的系统用户。

### 其他连接选项

| 选项              | 描述                                         |
| ----------------- | -------------------------------------------- |
| -P, --port=#      | 使用 TCP/IP 连接到数据库服务器时使用的端口。 |
| -S, --socket=name | 连接到本地数据库时使用的套接字。             |
| -H, --host=name   | 使用 TCP/IP 连接到数据库服务器时使用的主机。 |


在多个服务器实例的情况下，必须指定正确的连接参数（port、socket、host），以便 xtrabackup 与正确的服务器通信。

### 所需的权限和特权

连接到服务器后，为了执行备份，您需要在服务器的 datadir 中的文件系统级别具有 READ 和 EXECUTE 权限。

数据库用户需要对要备份的表/数据库具有以下权限：

- `RELOAD`和`LOCK TABLES`（除非指定了 –no-lock <innobackupex –no-lock> 选项）以便在开始复制文件之前和开始复制文件，并且 在使用[备份锁](http://www.percona.com/doc/percona-server/5.6/management/backup_locks.html)时需要此权限 。
- `REPLICATION CLIENT`为了获得二进制日志位置。
- `CREATE TABLESPACE`为了导入表（请参阅[恢复单个表](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/restoring_individual_tables_ibk.html#imp-exp-ibk)）。
- `PROCESS`为了运行（这是强制性的），并且可以选择查看在服务器上运行的所有线程（请参阅[改进的 FLUSH TABLES WITH READ LOCK 处理](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/improved_ftwrl.html#improved-ftwrl)）。
- `SUPER`为了在复制环境中启动/停止副本线程，请使用[XtraDB Changed Page Tracking](https://www.percona.com/doc/percona-server/5.6/management/changed_page_tracking.html) for [Incremental Backups](https://docs.percona.com/percona-xtrabackup/2.4/xtrabackup_bin/incremental_backups.html#xb-incremental)和[改进 FLUSH TABLES WITH READ LOCK 处理](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/improved_ftwrl.html#improved-ftwrl)。
- `CREATE`权限以创建 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/storing_history.html#xtrabackup-history)数据库和表。
- `ALTER`权限以升级 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/storing_history.html#xtrabackup-history)数据库和表。
- `INSERT`权限，以便将历史记录添加到 [PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/storing_history.html#xtrabackup-history)表。
- `SELECT`特权，以便使用 innobackupex –incremental-history-name或 innobackupex –incremental-history-uuid以便该功能在[PERCONA_SCHEMA.xtrabackup_history](https://docs.percona.com/percona-xtrabackup/2.4/innobackupex/storing_history.html#xtrabackup-history)表中查找`innodb_to_lsn`值 。

创建具有完整备份所需的最低权限的数据库用户的 SQL 示例如下：

```mysql
mysql> CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY 's3cret';
mysql> GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'bkpuser'@'localhost';
mysql> FLUSH PRIVILEGES;
```

## 完整备份

### 创建备份

要创建备份，请使用xtrabackup –backup选项运行xtrabackup 。您还需要指定xtrabackup –target-dir 选项，这是存储备份的位置，如果*InnoDB*数据或日志文件未存储在同一目录中，您可能还需要指定它们的位置。如果目标目录不存在，xtrabackup 会创建它。如果该目录确实存在并且为空，则 xtrabackup 将成功。xtrabackup 不会覆盖现有文件。

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backup/
```

### 准备备份

使用`xtrabackup –backup`选项进行备份后，您首先需要对其进行准备以恢复它。数据文件在准备好之前不是时间点一致的，因为它们在程序运行时在不同时间被复制，并且在发生这种情况时它们可能已经被更改。如果您尝试使用这些数据文件启动 InnoDB，它将检测损坏并自行崩溃以防止您在损坏的数据上运行。xtrabackup –prepare步骤使文件在单个时刻完全一致，因此您可以在它们上运行*InnoDB*。

```shell
$ xtrabackup --prepare --target-dir=/opt/backup/
```

不建议在准备备份时中断 xtrabackup 进程，因为这可能会导致数据文件损坏，备份将变得不可用。如果准备过程被中断，则无法保证备份的有效性。

如果打算将备份作为进一步增量备份的基础，则应在准备备份时使用`xtrabackup –apply-log-only`选项，否则您将无法对其应用增量备份。

### 恢复备份

为方便起见，xtrabackup 二进制文件有一个`xtrabackup –copy-back` 选项，它将备份复制到服务器的datadir：

```shell
$ xtrabackup --copy-back --target-dir=/opt/backup \
  --datadir=/opt/mysql-5.7.28/data
  
$ chown -R mysql.mysql /opt/mysql-5.7.28/data
```

如果不想保存备份，可以使用`xtrabackup –move-back`选项将备份的数据移动到datadir。

```shell
$ xtrabackup --move-back --target-dir=/opt/backup/ \
  --datadir=/opt/mysql-5.7.28/data
  
$ chown -R mysql.mysql /opt/mysql-5.7.28/data
```

在恢复备份之前，`datadir`必须为空。同样重要的是要注意 MySQL 服务器需要在执行还原之前关闭。您无法恢复到正在运行的mysqld实例的数据目录（导入部分备份时除外）。

如果不想使用上述任何选项，可以另外使用 rsync或cp来恢复文件。

```shell
$ rsync -avrP /opt/backup/ /var/lib/mysql/
```

应该检查恢复的文件是否具有正确的所有权和权限。

```shell
$ chown -R mysql:mysql /var/lib/mysql
```

## 增量备份

xtrabackup 工具和 innobackupex 工具都支持增量备份。增量备份仅备份自上次备份以来已更改的数据。

可以在每个完整备份之间进行多个增量备份。例如，可以每周进行一次完整备份，每天进行一次增量备份，或者每天进行一次完整备份，每小时进行一次增量备份。

增量备份之所以有效，是因为每个*InnoDB*页面都包含一个日志序列号 ( LSN )。LSN是整个数据库的系统版本号。每个页面的LSN显示它最近的更改时间。

注意：

- **增量备份不会将数据文件与之前备份的数据文件进行比较。因此，在*部分备份*之后运行增量备份可能会导致数据不一致。**
- **增量备份读取页面并将其LSN与上次备份的LSN进行比较。必须拥有完整备份才能恢复增量更改。如果没有完整备份作为基础，增量备份将毫无用处。**
- **如果知道它的LSN ，您可以使用–incremental-lsn选项执行增量备份，甚至不需要以前的备份。**

### 创建增量备份

要进行增量备份，请像往常一样从完整备份开始。xtrabackup 二进制文件将名为`xtrabackup_checkpoints`的文件写入备份的目标目录。该文件包含一行显示 ，这是备份结束时 `to_lsn`数据库的LSN 。

```shell
# 完整备份
$ mkdir /opt/backups
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/base

$ cat /opt/backups/base/xtrabackup_checkpoints 
backup_type = full-backuped
from_lsn = 0
to_lsn = 2637693
last_lsn = 2637702
compact = 0
recover_binlog_info = 0
flushed_lsn = 2637702

# 有了完整备份，可以根据它进行增量备份
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/inc1 \
  --incremental-basedir=/opt/backups/base
  
$ cat /opt/backups/inc1/xtrabackup_checkpoints
backup_type = incremental
from_lsn = 2637693
to_lsn = 2640041
last_lsn = 2640050
compact = 0
recover_binlog_info = 0
flushed_lsn = 2640050
```

`/opt/backups/inc1/` 目录现在应该包含 delta 文件，例如 `ibdata1.delta` 和 `test/table1.ibd.delta`。这些代表自 LSN 2637693 以后的变化。

`from_lsn`是备份的起始 LSN，对于增量备份，它必须与`to_lsn`前一个/基本备份的（如果它是最后一个检查点）相同。

现在可以将此目录用作另一个增量备份的基础：

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --target-dir=/opt/backups/inc2 \
  --incremental-basedir=/opt/backups/inc1

$ cat /opt/backups/inc2/xtrabackup_checkpoints 
backup_type = incremental
from_lsn = 2640041
to_lsn = 2642983
last_lsn = 2642992
compact = 0
recover_binlog_info = 0
flushed_lsn = 2642992
```

`to_lsn` 在这种情况下，您可以看到（最后一个检查点 LSN）和（最后一个复制的 LSN）之间存在差异`last_lsn`，这意味着在备份过程中服务器上有一些流量。

### 合并增量备份

增量备份的`xtrabackup –prepare`步骤与完整备份的步骤不同。在完整备份中，执行两种类型的操作以使数据库保持一致：从日志文件中针对数据文件重放已提交的事务，以及回滚未提交的事务。在准备增量备份时，您必须跳过未提交事务的回滚，因为在备份时未提交的事务可能正在进行中，并且很可能会在下一次增量备份中提交。您应该使用 `xtrabackup –apply-log-only`选项来防止回滚阶段。

注意：

- **如果您不使用** xtrabackup –apply-log-only **选项来防止回滚阶段，那么您的增量备份是无用的**。事务回滚后，无法应用进一步的增量备份。

从创建的完整备份开始，可以对其进行合并，然后对其应用增量差异。

```shell
# 基础备份和增量备份目录
/opt/backups/base
/opt/backups/inc1
/opt/backups/inc2
```

要准备基本备份，需要运行`xtrabackup –prepare`，但要防止回滚阶段：

```shell
$ xtrabackup --prepare --apply-log-only --target-dir=/opt/backups/base
```

即使操作跳过了回滚阶段，此备份也可以安全地[恢复。](https://docs.percona.com/percona-xtrabackup/2.4/backup_scenarios/full_backup.html#restoring-a-backup)如果你恢复它并启动*MySQL*，*InnoDB*会检测到回滚阶段没有执行，它会在后台执行。此操作与启动时的崩溃恢复相同。此外，MySQL 会通知您数据库未正常关闭。

要将第一个增量备份应用于完整备份，请运行以下命令：

```shell
$ xtrabackup --prepare --apply-log-only \
  --target-dir=/opt/backups/base \
  --incremental-dir=/opt/backups/inc1
```

这会将增量文件应用于`/opt/backups/base`中的文件，从而及时将它们前滚到增量备份的时间。然后它像往常一样将重做日志应用于结果。最终数据在 `/opt/backups/base`中，而不是在增量目录中。

同样，LSN 应该与您之前检查第一次增量备份时看到的一致。如果您从 /data/backups/base恢复文件，您应该会看到数据库在第一次增量备份时的状态。

**警告：**

- `Percona XtraBackup` 不支持使用同一个增量备份目录准备两份备份。不要对同一个增量备份目录（ `-incremental-dir`的值）多次运行`xtrabackup –prepare`。

准备第二次增量备份也是一个类似的过程：将增量应用于（修改的）基础备份，将其数据前滚到第二次增量备份的点：

```shell
$ xtrabackup --prepare --target-dir=/opt/backups/base \
  --incremental-dir=/opt/backups/inc2
```

注意：

- 合并除最后一个增量之外的所有增量时，应使用 `xtrabackup –apply-log-only`选项。这就是上个命令中不包含 `xtrabackup –apply-log-only` 选项的原因。
- 即使在最后一步使用了 `xtrabackup –apply-log-only`，备份仍然是一致的，但在这种情况下，服务器将执行回滚阶段。

## 压缩备份

`Percona XtraBackup`支持压缩备份：可以使用 `xbstream` 压缩或解压缩本地或流式备份。

### 创建压缩备份

为了进行压缩备份，您需要使用`xtrabackup –compress`选项：

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --compress --target-dir=/opt/backups/base
```

`xtrabackup –compress` 使用 `qpress` 工具，可以通过 `percona-release` 包配置工具安装该工具，如下所示：

```shell
#$ sudo percona-release enable tools
#$ sudo apt update
#$ sudo apt install qpress

$ wget http://www.quicklz.com/qpress-11-linux-x64.tar
$ tar -xf qpress-11-linux-x64.tar -C /opt/percona-xtrabackup-2.4.25/bin
```

如果要加快压缩速度，可以使用并行压缩，可以使用`xtrabackup –compress-threads`选项启用。以下示例将使用四个线程进行压缩：

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup --compress \
  --compress-threads=4 --target-dir=/opt/backups/base
```

### 准备备份

在准备备份之前，您必须解压缩所有文件。 *Percona XtraBackup*实现了 `xtrabackup –decompress`选项，可用于解压缩备份。

```shell
$ xtrabackup --decompress --target-dir=/opt/backups/base
```

`xtrabackup –parallel`可以与 `xtrabackup –decompress`选项一起使用以同时解压缩多个文件。

*Percona XtraBackup*不会自动删除压缩文件。要清理备份目录，请使用 `xtrabackup –remove-original`选项。如果文件没有被删除，如果使用`xtrabackup –copy-back`或`xtrabackup –move-back`，它们不会被复制或移动到数据目录。

解压缩文件后，您可以使用 `xtrabackup –prepare`选项准备备份：

```shell
$ xtrabackup --prepare --target-dir=/opt/backups/base
```

现在`/opt/backups/base`中的文件已准备好供服务器使用。

### 恢复备份

xtrabackup 有一个`xtrabackup –copy-back`选项，它执行将备份恢复到服务器的datadir：

```shell
$ xtrabackup --copy-back --target-dir=/opt/backups/base --datadir=/opt/mysql-5.7.28/data
$ chown -R mysql.mysql /opt/mysql-5.7.28/data
```



## 加密备份

*Percona XtraBackup*已实现对加密备份的支持。它可用于使用 xbstream 选项加密/解密本地或流式备份（不支持流式 tar 备份），以便为备份添加另一层保护。加密是通过`libgcrypt`库完成的。

### 创建加密备份

要进行加密备份，需要指定以下选项（选项 `xtrabackup –encrypt-key`和`xtrabackup –encrypt-key-file` 是互斥的，只需要提供其中一个即可）：

- `--encrypt=ALGORITHM`： 当前支持的算法是 `AES128`，`AES192`和`AES256`
- `--encrypt-key=ENCRYPTION_KEY`：使用适当长度的加密密钥。不建议在对机器进行不受控制的访问的情况下使用此选项作为命令行，因此可以将密钥视为进程信息的一部分。
- `--encrypt-key-file=KEYFILE`：可以从中读取适当长度的原始密钥的文件的名称。该文件必须是一个简单的二进制（或文本）文件，其中包含要使用的密钥。

`xtrabackup –encrypt-key`选项和 `xtrabackup –encrypt-key-file`选项都可用于指定加密密钥。可以使用以下命令生成加密密钥：

```shell
$ openssl rand -base64 24
# 输出结果如下：
v298A8VUsyK25vmxeZ/YFjuuRtoVVMD/
```

1. 使用`–encrypt-key`选项

   使用`xtrabackup –encrypt-ke`y的 xtrabackup 命令示例 应如下所示：

   ```shell
   $ xtrabackup --host=127.0.0.1 --user=root \
     --password=root_password --backup \
     --target-dir=/opt/backups/base-encryption \
     --encrypt=AES256 --encrypt-key="v298A8VUsyK25vmxeZ/YFjuuRtoVVMD/"
   ```

2. 使用`–encrypt-key-file`选项

   使用`xtrabackup –encrypt-key-file`的 xtrabackup 命令示例 应如下所示：

   ```shell
   $ echo -n "v298A8VUsyK25vmxeZ/YFjuuRtoVVMD/" > /opt/backups/keyfile
   
   $ xtrabackup --host=127.0.0.1 --user=root \
     --password=root_password --backup \
     --target-dir=/opt/backups/base-encryption1 \
     --encrypt=AES256 --encrypt-key-file=/opt/backups/keyfile
   ```

### 优化加密过程

加密备份引入了两个选项，可用于加速加密过程。它们是 `xtrabackup –encrypt-threads`和 `xtrabackup –encrypt-chunk-size`。

通过使用 `xtrabackup –encrypt-threads`选项，可以指定多个线程用于并行加密。

选项 `xtrabackup –encrypt-chunk-size`可用于指定每个加密线程的工作加密缓冲区的大小（以字节为单位）（默认为 64K）。

### 解密加密备份

*Percona XtraBackup* `xtrabackup –decrypt`选项已实现，可用于解密备份：

```shell
$ xtrabackup --decrypt=AES256 \
  --encrypt-key="v298A8VUsyK25vmxeZ/YFjuuRtoVVMD/" \
  --target-dir=/opt/backups/base-encryption1
```

*Percona XtraBackup*不会自动删除加密文件。为了清理备份目录，用户应该删除*.xbcrypt 文件。在*Percona XtraBackup* 2.4.6中，`xtrabackup –remove-original` 选项已实现，您可以使用它在解密后删除加密文件。要在解密后删除文件，您应该运行：

```shell
$ xtrabackup --decrypt=AES256 \
  --encrypt-key="v298A8VUsyK25vmxeZ/YFjuuRtoVVMD/" \
  --target-dir=/opt/backups/base-encryption --remove-original
```

`xtrabackup –parallel`可以与 `xtrabackup –decrypt`选项一起使用以同时解密多个文件。

### 准备加密备份

备份解密后，可以使用`xtrabackup –prepare`选项以与标准完整备份相同的方式准备它们：

```shell
$ xtrabackup --prepare --target-dir=/opt/backups/base-encryption
```

### 恢复加密备份

xtrabackup 有一个`xtrabackup –copy-back`选项，它执行将备份恢复到服务器的datadir：

```shell
$ xtrabackup --copy-back --target-dir=/opt/backups/base-encryption --datadir=/opt/mysql-5.7.28/data
$ chown -R mysql.mysql /opt/mysql-5.7.28/data
```

## Percona XtraBackup 用户手册

*Percona XtraBackup*是一组以下工具：

- `innobackupex`：innobackupex 是 xtrabackup 的符号链接。 innobackupex 仍然支持 2.2 版本所做的所有功能和语法，但现在已弃用，并将在下一个主要版本中删除
- `xtrabackup`：一个已编译的 C 二进制文件，它提供了使用 MyISAM、InnoDB 和 XtraDB 表备份整个 MySQL 数据库实例的功能。
- `xbcrypt`：用于加密和解密备份文件的实用程序。
- `xbstream`：允许将文件流式传输到/从 xbstream 格式提取文件的实用程序。
- `xbcloud`：用于从/向云下载和上传全部或部分 xbstream 存档的实用程序。

Percona XtraBackup 2.3 发布后，推荐的备份方法是使用 xtrabackup 脚本。

## 限制备份

尽管 xtrabackup 不会阻止您的数据库操作，但任何备份都可能给正在备份的系统增加负载。在没有太多备用 I/O 容量的系统上，限制 xtrabackup 读取和写入数据的速率可能会有所帮助。您可以使用`xtrabackup –throttle` 选项来执行此操作。此选项限制每秒复制的块数。块大小为*10 MB*。

```shell
$ xtrabackup --host=127.0.0.1 --user=root \
  --password=root_password --backup \
  --throttle=2 --target-dir=/opt/backup/
```

默认情况下没有节流，xtrabackup 以最快的速度读写数据。如果对 IOPS 设置的限制太严格，备份可能会变慢，以至于它永远无法赶上 InnoDB 正在写入的事务日志，并且备份可能永远不会完成。
