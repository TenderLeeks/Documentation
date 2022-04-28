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





