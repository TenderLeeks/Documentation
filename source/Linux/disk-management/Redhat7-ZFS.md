# Redhat7 配置 ZFS

## 介绍

​		ZFS文件系统的英文名称为ZettabyteFileSystem,也叫动态文件系统（DynamicFileSystem）,是第一个128位文件系统。最初是由Sun公司为Solaris10操作系统开发的文件系统。作为OpenSolaris开源计划的一部分，ZFS于2005年11月发布，被Sun称为是终极文件系统，经历了10年的活跃开发，而最新的开发将全面开放，并重新命名为OpenZFS。

## 特性

​    	ZFS是一种先进的、高度可扩展的文件系统，最初是由Sun Microsystems开发的,现在OpenZFS是项目的一部分。有这么多文件系统可用在Linux上,那自然要问ZFS有什么特别之处。不同于其它文件系统,它不仅是一个文件系统逻辑卷管理器。ZFS使其受欢迎的特性是：

* 数据完整性——数据一致性和完整性通过即写即拷和校验技术保证。

* 存储空间池——可用存储驱动器一起放入称为zpool的单个池。

* 软件RAID ——像发出一个命令一样，建立一个raidz数组。

* 内置的卷管理器——ZFS充当卷管理器。

* Snapshots、克隆、压缩——这些都是一些ZFS提供的高级功能。

  最大单个文件大小为 16 EB（1 EB = 1024 PB）
  最大 256 千万亿（256*1015 ）的 ZB（1 ZB = 1024 EB）的存储



## 专业术语

* Pool：存储驱动器的逻辑分组，它是ZFS的基本构建块，从这里将存储空间分配给数据集。
* Datasets：ZFS文件系统的组件即文件系统、克隆、快照和卷被称为数据集。
* Mirror：一个虚拟设备存储相同的两个或两个以上的磁盘上的数据副本，在一个磁盘失败的情况下,相同的数据是可以用其他磁盘上的镜子。
* Resilvering：在恢复设备时将数据从一个磁盘复制到另一个磁盘的过程。
* Scrub：擦除用于一致性检验在ZFS像在其他文件系统如何使用fsck。

## 安装EPEL仓库

```shell
# RHEL 7
$ wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# RHEL 6
$ wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
# RHEL 5
$ wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-5.repo
```

## 安装内核开发包

```shell
# 先升级 kernel，然后安装 kernel 开发包
$ yum update kernel
$ yum install kernel-devel
# 更新内核后，最好重启系统
```

## 安装zfs源

```shell
$ yum localinstall --nogpgcheck http://download.zfsonlinux.org/epel/zfs-release.el7_3.noarch.rpm

# 查看系统版本号
$ cat /etc/redhat-release
Red Hat Enterprise Linux Server release 7.3 (Maipo)

# 根据系统版本安装yum源
# https://github.com/zfsonlinux/zfs/wiki/RHEL-and-CentOS
# https://zfsonlinux.org/
```

## 安装zfs

```shell
$ yum install zfs -y

# 验证zfs模块插入到内核使用的lsmod命令，如果没有，使用 modprobe 命令手动插入它。
$ lsmod | grep zfs
$ modprobe zfs
$ lsmod | grep zfs
zfs                  3564468  0
zunicode              331170  1 zfs
zavl                   15236  1 zfs
icp                   270148  1 zfs
zcommon                73440  1 zfs
znvpair                89131  2 zfs,zcommon
spl                   102412  4 icp,zfs,zcommon,znvpair

# 检查是否可以使用zfs的命令
$ zfs list
no datasets available

```

## 使用zfs

```shell
# 查看当前存储池挂载状态
$ zfs list
# 查看当前存储池状态
$ zpool status
# 使用 sdb、sdc、sdd 这几块硬盘创建一个名为 senra-zfs的池
$ zpool create senra-zfs sdb sdc sdd
# 可以使用-f启用强制模式，这个在正常的创建中没有必要，如果碰到你要创建raidz或者mirror类型的池，那么这个可以帮助你忽略由于添加的硬盘容量不相等导致的错误提示
# 查看存储池 senra-zfs 的一些信息
$ zpool get all senra-zfs
# 将硬盘 sde 添加到池 senra-zfs 中
$ zpool add senra-zfs sde
# 使用硬盘 sdf 替换 senra-zfs 池中的 sde
$ zpool replace senra-zfs sde sdf
# 检测池 senra-zfs 是否存在问题
$ zpool scrub senra-zfs
# 查看池 senra-zfs 的IO使用状况，可以加 -v 来详细到池所拥有的每块磁盘
zpool iostat senra-zfs
```

详细用法，请查看[文档]()

zfs命令请查看[文档](https://docs.oracle.com/cd/E26926_01/html/E29115/zfs-1m.html)

zpool命令请查看[文档](https://docs.oracle.com/cd/E26926_01/html/E29115/zpool-1m.html)

## zfs 实例应用

1. 创建虚拟磁盘

   ```shell
   # 创建4个虚拟磁盘，每个大小64MB
   $ dd if=/dev/zero of=disk0.img bs=64M count=1;losetup /dev/loop0 ./disk0.img
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.236892 s, 283 MB/s
   $ dd if=/dev/zero of=disk1.img bs=64M count=1;losetup /dev/loop1 ./disk1.img
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.167757 s, 400 MB/s
   $ dd if=/dev/zero of=disk2.img bs=64M count=1;losetup /dev/loop2 ./disk2.img
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.161181 s, 416 MB/s
   $ dd if=/dev/zero of=disk3.img bs=64M count=1;losetup /dev/loop3 ./disk3.img
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.159243 s, 421 MB/s
   ```

2. 创建 ZFS 池

   ```shell
   $ zpool create mypool raidz /dev/loop0 /dev/loop1 /dev/loop2 /dev/loop3
   $ zfs list
   NAME     USED  AVAIL  REFER  MOUNTPOINT
   mypool   109K  83.7M  32.9K  /mypool
   ```

3. 查看存储池的属性

   ```shell
   $ zfs get all mypool
   NAME    PROPERTY              VALUE                  SOURCE
   mypool  type                  filesystem             -
   mypool  creation              Wed Oct  9  3:50 2019  -
   mypool  used                  109K                   -
   ...
   ```

4. 启用zfs压缩

   ```shell
   # 压缩功能默认是关闭的，通过以下命令可以启用压缩功能
   $ zfs create mypool/myzdev1
   $ zfs list
   NAME             USED  AVAIL  REFER  MOUNTPOINT
   mypool           147K  83.6M  32.9K  /mypool
   mypool/myzdev1  32.9K  83.6M  32.9K  /mypool/myzdev1
   $ zfs set compression=on mypool/myzdev1
   $ zfs get all mypool/myzdev1
   NAME            PROPERTY              VALUE                  SOURCE
   mypool/myzdev1  type                  filesystem             -
   mypool/myzdev1  creation              Wed Oct  9  3:52 2019  -
   mypool/myzdev1  used                  32.9K                  -
   ...
   ```

5. 查看压缩

   ```shell
   $ cp python-iniparse-0.4-9.el7.noarch.rpm /mypool/myzdev1
   $ ls -al /mypool/myzdev1/
   total 43
   drwxr-xr-x 2 root root     4 Oct  9 03:56 .
   drwxr-xr-x 3 root root     3 Oct  9 03:52 ..
   -rw-r--r-- 1 root root 39800 Oct  9 03:56 python-iniparse-0.4-9.el7.noarch.rpm
   $ du -ah /mypool/myzdev1/
   40K     /mypool/myzdev1/python-iniparse-0.4-9.el7.noarch.rpm
   42K     /mypool/myzdev1/
   $ zfs get compressratio mypool
   NAME    PROPERTY       VALUE  SOURCE
   mypool  compressratio  1.00x  -
   ```

6. 检查pool池状态

   ```shell
   $ zpool status mypool
     pool: mypool
    state: ONLINE
     scan: none requested
   config:
   
           NAME        STATE     READ WRITE CKSUM
           mypool      ONLINE       0     0     0
             raidz1-0  ONLINE       0     0     0
               loop0   ONLINE       0     0     0
               loop1   ONLINE       0     0     0
               loop2   ONLINE       0     0     0
               loop3   ONLINE       0     0     0
   
   errors: No known data errors
   ```

7. 损坏 ZFS 池

   ```shell
   $ dd if=/dev/zero of=/root/disk3.img bs=64M count=1
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.263811 s, 254 MB/s
   ```

8. 清理并检查池

   ```shell
   $ zpool scrub mypool
   $ zpool status mypool
     pool: mypool
    state: DEGRADED
   status: One or more devices could not be used because the label is missing or
           invalid.  Sufficient replicas exist for the pool to continue
           functioning in a degraded state.
   action: Replace the device using 'zpool replace'.
      see: http://zfsonlinux.org/msg/ZFS-8000-4J
     scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 03:59:31 2019
   config:
   
           NAME        STATE     READ WRITE CKSUM
           mypool      DEGRADED     0     0     0
             raidz1-0  DEGRADED     0     0     0
               loop0   ONLINE       0     0     0
               loop1   ONLINE       0     0     0
               loop2   ONLINE       0     0     0
               loop3   UNAVAIL      0     0     0  corrupted data
   
   errors: No known data errors
   
   $ wc -l /mypool/myzdev1/python-iniparse-0.4-9.el7.noarch.rpm
   137 /mypool/myzdev1/python-iniparse-0.4-9.el7.noarch.rpm
   ```

9. 修复池

   ```shell
   # 当设备发生故障或损坏,我们可以使用replace命令替换它。
   $ dd if=/dev/zero of=disk4.img bs=64M count=1;losetup /dev/loop4 ./disk4.img
   1+0 records in
   1+0 records out
   67108864 bytes (67 MB) copied, 0.239719 s, 280 MB/s
   $ zpool replace mypool /dev/loop3 /dev/loop4
   $ zpool status mypool
     pool: mypool
    state: ONLINE
     scan: resilvered 59K in 0h0m with 0 errors on Wed Oct  9 04:04:26 2019
   config:
   
           NAME        STATE     READ WRITE CKSUM
           mypool      ONLINE       0     0     0
             raidz1-0  ONLINE       0     0     0
               loop0   ONLINE       0     0     0
               loop1   ONLINE       0     0     0
               loop2   ONLINE       0     0     0
               loop4   ONLINE       0     0     0
   
   errors: No known data errors
   $ zpool scrub mypool
   $ zpool status mypool
     pool: mypool
    state: ONLINE
     scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 04:04:47 2019
   config:
   
           NAME        STATE     READ WRITE CKSUM
           mypool      ONLINE       0     0     0
             raidz1-0  ONLINE       0     0     0
               loop0   ONLINE       0     0     0
               loop1   ONLINE       0     0     0
               loop2   ONLINE       0     0     0
               loop4   ONLINE       0     0     0
   
   errors: No known data errors
   ```

10. 添加新磁盘

    ```shell
    $ zpool status
      pool: mypool
     state: ONLINE
      scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 04:04:47 2019
    config:
    
            NAME        STATE     READ WRITE CKSUM
            mypool      ONLINE       0     0     0
              raidz1-0  ONLINE       0     0     0
                loop0   ONLINE       0     0     0
                loop1   ONLINE       0     0     0
                loop2   ONLINE       0     0     0
                loop4   ONLINE       0     0     0
    
    errors: No known data errors
    $ dd if=/dev/zero of=disk5.img bs=64M count=1;losetup /dev/loop5 ./disk5.img
    1+0 records in
    1+0 records out
    67108864 bytes (67 MB) copied, 0.231504 s, 290 MB/s
    $ zpool add mypool spare /dev/loop5
    $ zpool status
      pool: mypool
     state: ONLINE
      scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 04:04:47 2019
    config:
    
            NAME        STATE     READ WRITE CKSUM
            mypool      ONLINE       0     0     0
              raidz1-0  ONLINE       0     0     0
                loop0   ONLINE       0     0     0
                loop1   ONLINE       0     0     0
                loop2   ONLINE       0     0     0
                loop4   ONLINE       0     0     0
            spares
              loop5     AVAIL  
    
    errors: No known data errors
    ```

11. 移除池内磁盘

    ```shell
    $ zpool status
      pool: mypool
     state: ONLINE
      scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 04:04:47 2019
    config:
    
            NAME        STATE     READ WRITE CKSUM
            mypool      ONLINE       0     0     0
              raidz1-0  ONLINE       0     0     0
                loop0   ONLINE       0     0     0
                loop1   ONLINE       0     0     0
                loop2   ONLINE       0     0     0
                loop4   ONLINE       0     0     0
            spares
              loop5     AVAIL  
    
    errors: No known data errors
    $ zpool remove mypool /dev/loop5
    $ zpool status
      pool: mypool
     state: ONLINE
      scan: scrub repaired 0B in 0h0m with 0 errors on Wed Oct  9 04:04:47 2019
    config:
    
            NAME        STATE     READ WRITE CKSUM
            mypool      ONLINE       0     0     0
              raidz1-0  ONLINE       0     0     0
                loop0   ONLINE       0     0     0
                loop1   ONLINE       0     0     0
                loop2   ONLINE       0     0     0
                loop4   ONLINE       0     0     0
    
    errors: No known data errors
    ```

12. 查看存储池IO统计信息

    ```shell
    $ zpool iostat -v mypool
                  capacity     operations     bandwidth
    pool        alloc   free   read  write   read  write
    ----------  -----  -----  -----  -----  -----  -----
    mypool       338K   224M      0      6  3.81K  26.7K
      raidz1     338K   224M      0      6  3.81K  26.7K
        loop0       -      -      0      1  1.10K  7.63K
        loop1       -      -      0      1  1.05K  7.34K
        loop2       -      -      0      1  1.11K  7.62K
        loop4       -      -      0      3  2.49K  18.9K
    ----------  -----  -----  -----  -----  -----  -----
    ```

13. 查看存储池默认挂载点

    ```shell
    # 默认挂载点是以根 / 开始的，可以用下面的命令更改默认挂载点
    $ df -h
    Filesystem             Size  Used Avail Use% Mounted on
    /dev/mapper/rhel-root   13G  2.2G   11G  17% /
    devtmpfs               989M     0  989M   0% /dev
    tmpfs                 1000M     0 1000M   0% /dev/shm
    tmpfs                 1000M  8.5M  992M   1% /run
    tmpfs                 1000M     0 1000M   0% /sys/fs/cgroup
    /dev/vda1             1014M  150M  865M  15% /boot
    tmpfs                  200M     0  200M   0% /run/user/0
    mypool                  84M     0   84M   0% /mypool
    mypool/myzdev1          84M  128K   84M   1% /mypool/myzdev1
    $ zfs umount -a
    $ zfs set mountpoint=/testpoint/myzdev1 mypool/myzdev1
    $ zfs mount -a
    $ df -h
    Filesystem             Size  Used Avail Use% Mounted on
    /dev/mapper/rhel-root   13G  2.2G   11G  17% /
    devtmpfs               989M     0  989M   0% /dev
    tmpfs                 1000M     0 1000M   0% /dev/shm
    tmpfs                 1000M  8.5M  992M   1% /run
    tmpfs                 1000M     0 1000M   0% /sys/fs/cgroup
    /dev/vda1             1014M  150M  865M  15% /boot
    tmpfs                  200M     0  200M   0% /run/user/0
    mypool                  84M     0   84M   0% /mypool
    mypool/myzdev1          84M  128K   84M   1% /testpoint/myzdev1
    ```

14. 创建快照

    ```shell
    $ echo "text1">/testpoint/myzdev1/snapshottest.txt
    $ cat /testpoint/myzdev1/snapshottest.txt
    text1
    $ zfs snapshot mypool/myzdev1@2019-10-9
    $ zfs list -t snapshot
    NAME                       USED  AVAIL  REFER  MOUNTPOINT
    mypool/myzdev1@2019-10-9     0B      -  71.8K  -
    ```

15. 回滚快照

    ```shell
    $ echo "text2">/testpoint/myzdev1/snapshottest.txt
    $ cat /testpoint/myzdev1/snapshottest.txt
    text2
    $ zfs rollback mypool/myzdev1@2019-10-9
    $ cat /testpoint/myzdev1/snapshottest.txt
    text1
    ```

16. 销毁池

    ```shell
    $ zpool destroy mypool
    $ zpool status
    no pools available
    $ cat /testpoint/myzdev1/snapshottest.txt
    cat: /testpoint/myzdev1/snapshottest.txt: No such file or directory
    ```

    

## 示例

```shell
$ fdisk -l
Disk /dev/vda: 16.1 GB, 16106127360 bytes, 31457280 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000ced42

   Device Boot Start End Blocks Id System
/dev/vda1 * 2048 2099199 1048576 83 Linux
/dev/vda2 2099200 31457279 14679040 8e Linux LVM

Disk /dev/vdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

Disk /dev/mapper/rhel-root: 13.4 GB, 13417578496 bytes, 26206208 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

Disk /dev/mapper/rhel-swap: 1610 MB, 1610612736 bytes, 3145728 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

$ zpool create mydata /dev/vdb -m /data

$ zfs create mydata/db

$ zfs set compression=gzip mydata
$ zfs set compression=gzip mydata/db

$ zfs mount data
cannot open 'data': dataset does not exist

$ zfs mount data/db
cannot open 'data/db': dataset does not exist

$ zpool list
NAME     SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
mydata  19.9G   150K  19.9G         -     0%     0%  1.00x  ONLINE  -

$ fdisk -l
Disk /dev/vdc: 4294 MB, 4294967296 bytes, 8388608 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

$ zpool add mydata /dev/vdc -f  

$ zpool list
NAME     SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
mydata  23.8G   195K  23.8G         -     0%     0%  1.00x  ONLINE  -

$ fdisk -l
Disk /dev/vdd: 17.2 GB, 17179869184 bytes, 33554432 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

$ zpool add mydata /dev/vdd -f
$ zpool list
NAME     SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
mydata  39.7G   200K  39.7G         -     0%     0%  1.00x  ONLINE  -

$ zpool status mydata
  pool: mydata
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        mydata      ONLINE       0     0     0
          vdb       ONLINE       0     0     0
          vdc       ONLINE       0     0     0
          vdd       ONLINE       0     0     0

errors: No known data errors

$ zpool iostat -v mydata
              capacity     operations     bandwidth 
pool        alloc   free   read  write   read  write
----------  -----  -----  -----  -----  -----  -----
mydata       165K  39.7G      0      0     69  8.54K
  vdb        120K  19.9G      0      0     23  3.44K
  vdc         34K  3.97G      0      0     60  7.40K
  vdd         11K  15.9G      0      0     83  8.17K
----------  -----  -----  -----  -----  -----  -----

$ df -h
Filesystem             Size  Used Avail Use% Mounted on
/dev/mapper/rhel-root   13G  2.2G   11G  17% /
devtmpfs               989M     0  989M   0% /dev
tmpfs                 1000M     0 1000M   0% /dev/shm
tmpfs                 1000M  8.5M  991M   1% /run
tmpfs                 1000M     0 1000M   0% /sys/fs/cgroup
/dev/vda1             1014M  150M  865M  15% /boot
tmpfs                  200M     0  200M   0% /run/user/0
mydata                  39G  128K   39G   1% /data
mydata/db               39G  128K   39G   1% /data/db

$ echo "text1">>/data/db/snapshottest.txt
$ cat snapshottest.txt                   
text1
text1
text1
text1

$ zfs snapshot mydata/db@$(date +'%Y%m%d%H%M%S')
$ zfs list -t snapshot 
NAME                       USED  AVAIL  REFER  MOUNTPOINT
mydata/db@2019-10-9          0B      -    24K  -
mydata/db@20191009233037     0B      -    24K  -

$ cd /data/db/.zfs/snapshot/
$ ll
total 1
drwxr-xr-x 2 root root 3 Oct  9 23:08 20191009233037
drwxrwxrwx 1 root root 0 Oct  9 23:31 2019-10-9
$ cd 20191009233037
$ ll
total 1
-rw-r--r-- 1 root root 24 Oct  9 23:09 snapshottest.txt

$ cat snapshottest.txt 
text1
text1
text1
text1

$ echo text2 >> snapshottest.txt 
$ cat snapshottest.txt           
text1
text1
text1
text1
text2
text2
text2
text2

$ zfs snapshot mydata/db@$(date +'%Y%m%d%H%M%S')
$ zfs list -t snapshot                                              
NAME                       USED  AVAIL  REFER  MOUNTPOINT
mydata/db@2019-10-9          0B      -    24K  -
mydata/db@20191009233037     0B      -    24K  -
mydata/db@20191009233334     0B      -    24K  -

$ cd /data/db/.zfs/snapshot/
$ ll
total 1
drwxr-xr-x 2 root root 3 Oct  9 23:08 20191009233037
drwxrwxrwx 1 root root 0 Oct  9 23:34 20191009233334
drwxrwxrwx 1 root root 0 Oct  9 23:31 2019-10-9

$ cd 20191009233334
$ ll
total 1
-rw-r--r-- 1 root root 48 Oct  9 23:33 snapshottest.txt
$ cat snapshottest.txt 
text1
text1
text1
text1
text2
text2
text2
text2
```



