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



## 使用二进制压缩包安装

下载二进制包请使用此[链接](https://www.percona.com/downloads/)查找

```shell
$ wget https://downloads.percona.com/downloads/Percona-XtraBackup-2.4/Percona-XtraBackup-2.4.25/binary/tarball/percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12.tar.gz

$ tar -zxf percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12.tar.gz -C /opt
$ mv /opt/percona-xtrabackup-2.4.25-Linux-x86_64.glibc2.12 /opt/percona-xtrabackup-2.4.25
```

## 设置连接权限

*Percona XtraBackup*需要能够连接到数据库服务器并在创建备份时、在某些情况下准备时以及在恢复时对服务器和datadir执行操作。为此，必须满足其执行的特权和权限要求。

权限是指允许系统用户在数据库服务器中进行的操作。**它们是在数据库服务器上设置的，仅适用于数据库服务器中的用户**。

权限是允许用户在系统上执行操作的权限，例如在某个目录上读取、写入或执行或启动/停止系统服务。**它们是在系统级别设置的，仅适用于系统用户**。

无论使用*xtrabackup*还是 innobackupex，都涉及到两个参与者：调用程序*的用户 - 系统用户*- 以及在数据库服务器中执行操作的用户 -*数据库用户*。请注意，这些是不同位置的不同用户，即使他们可能具有相同的用户名。





