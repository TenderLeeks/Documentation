# 磁盘命令

## 判断磁盘是SSD或HDD盘

**1、没有使用raid方案**

0表示SSD，1表示HDD

```bash
$ lsblk -d -o name,rota
NAME ROTA
vda     1
vdb     1
vdc     0
```

**2、使用raid方案**

下载工具

```bash
wget https://raw.githubusercontent.com/eLvErDe/hwraid/master/wrapper-scripts/megaclisas-status
```

执行检测命令

```bash
$ megaclisas-status
-- Controller information --
-- ID | H/W Model | RAM    | Temp | BBU    | Firmware
c0    | SAS3508 | 2048MB | 55C  | Good   | FW: 50.6.3-0109

-- Array information --
-- ID | Type   |    Size |  Strpsz | Flags | DskCache |   Status |  OS Path | CacheCade |InProgress
c0u0  | RAID-1 |   1089G |  256 KB | RA,WB |  Default |  Optimal | /dev/sda | None      |None
c0u1  | RAID-5 |   2616G |  256 KB | RA,WB |  Default |  Optimal | /dev/sdb | None      |None

-- Disk information --
-- ID   | Type | Drive Model                                 | Size     | Status          | Speed    | Temp | Slot ID  | LSI ID
c0u0p0  | HDD  | TOSHIBA AL15SEB120N 080710R0A0LJFDWG        | 1.089 TB | Online, Spun Up | 12.0Gb/s | 27C  | [134:4]  | 0
c0u0p1  | HDD  | TOSHIBA AL15SEB120N 080710S0A10SFDWG        | 1.089 TB | Online, Spun Up | 12.0Gb/s | 28C  | [134:5]  | 5
c0u1p0  | SSD  | HUAWEI HWE52SS3960L005N3248033GSN10L5002816 | 893.1 Gb | Online, Spun Up | 12.0Gb/s | 29C  | [134:0]  | 2
c0u1p1  | SSD  | HUAWEI HWE52SS3960L005N3248033GSN10L5002799 | 893.1 Gb | Online, Spun Up | 12.0Gb/s | 30C  | [134:1]  | 4
c0u1p2  | SSD  | HUAWEI HWE52SS3960L005N3248033GSN10L5002805 | 893.1 Gb | Online, Spun Up | 12.0Gb/s | 29C  | [134:2]  | 1
c0u1p3  | SSD  | HUAWEI HWE52SS3960L005N3248033GSN10L5002797 | 893.1 Gb | Online, Spun Up | 12.0Gb/s | 29C  | [134:3]  | 3
```

## 解决umount target is busy挂载盘卸载不掉问题

问题描述:

由于有进程占用目录，因此无法umount目录，需要先将占用进程杀死，再umount目录。

```bash
$ umount /data
umount: /data: target is busy.
```

查看目录占用进程：

```bash
$ fuser -mv /mnt/
                     USER        PID ACCESS COMMAND
/mnt:                root     kernel mount /mnt
                     root      13830 ..c.. bash
```

杀死目录占用进程

```bash
4 fuser -kv /mnt/
                     USER        PID ACCESS COMMAND
/mnt:                root     kernel mount /mnt
                     root      13830 ..c.. bash
# 检查目录占用进程                     
$ fuser -mv /mnt/   
$ umount /mnt
```

fuser命令参数说明

```bash
-k,--kill kill 　　processes accessing the named file
-m,--mount 　　 show all processes using the named filesystems or block device
-v,--verbose 　　 verbose output
```

## 挂载磁盘

```bash
$ fdisk -l
# 执行  fdisk /dev/xvdb 对磁盘分区，需要依次输入 “n” ，"p"，"1"，两次回车，"wq"：
$ fdisk /dev/vdc
# 格式化
$ mkfs.ext4 /dev/vdc1
$ blkid /dev/xvdb
$ echo 'UUID=4993a375-d69a-44e6-87cb-ca4b09584e2e /data ext4 defaults 0 0' >> /etc/fstab
$ mount -a
$ df -lh
```

## 测试Linux磁盘性能

### 查看磁盘读写io命令

在 Linux 中，可以使用 `iostat` 命令来查看磁盘的读写 I/O 统计信息。`iostat` 可以从 `sysstat` 包中安装，如果你还没有安装可以通过以下命令来安装：

```bash
sudo apt-get install sysstat   # Ubuntu/Debian 系统
sudo yum install sysstat       # CentOS/RHEL 系统
```

安装完成后，可以使用以下命令来查看磁盘的读写 I/O 统计信息：

```bash
iostat -d -x
```

其中 `-d` 选项表示只显示磁盘的统计信息， `-x` 选项表示显示更详细的信息，包括每个分区的平均 I/O 时间、队列长度等。运行该命令后，你将看到如下的输出：

```bash
Linux 5.4.0-72-generic (hostname)    05/12/23    _x86_64_    (4 CPU)

Device        r/s     w/s     rkB/s   wkB/s  rrqm/s  wrqm/s     %util
sda           1.34    0.67    25.32   13.32   0.14     0.29       0.12
sdb           0.00    0.00    0.00    0.00    0.00     0.00       0.00

```

其中，每一列的含义如下：

- `Device`: 磁盘设备的名称。
- `r/s`: 每秒读取的次数。
- `w/s`: 每秒写入的次数。
- `rkB/s`: 每秒读取的数据量（KB）。
- `wkB/s`: 每秒写入的数据量（KB）。
- `rrqm/s`: 每秒合并的读取请求次数。
- `wrqm/s`: 每秒合并的写入请求次数。
- `%util`: 磁盘的利用率。

如果你想查看特定的磁盘设备的统计信息，可以在命令行中指定该设备的名称，例如：

```bash
iostat -d -x /dev/sda
```

这将只显示 `/dev/sda` 磁盘设备的统计信息。

### 查看磁盘读写io性能峰值命令

在 Linux 中，可以使用 `iotop` 命令来查看磁盘的 I/O 性能峰值。`iotop` 可以从 `iotop` 包中安装，如果你还没有安装可以通过以下命令来安装：

```bash
sudo apt-get install iotop   # Ubuntu/Debian 系统
sudo yum install iotop       # CentOS/RHEL 系统

```

安装完成后，可以使用以下命令来查看磁盘的 I/O 性能峰值：

```bash
sudo iotop

```

运行该命令后，你将看到如下的输出：

```bash
Total DISK READ :       0.00 B/s | Total DISK WRITE :       0.00 B/s
Actual DISK READ:       0.00 B/s | Actual DISK WRITE:       0.00 B/s
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND

```

其中，每一列的含义如下：

- `Total DISK READ`: 累计的磁盘读取量。
- `Total DISK WRITE`: 累计的磁盘写入量。
- `Actual DISK READ`: 实际的磁盘读取量。
- `Actual DISK WRITE`: 实际的磁盘写入量。
- `TID`: 线程 ID。
- `PRIO`: 线程的优先级。
- `USER`: 线程所属的用户。
- `DISK READ`: 线程的磁盘读取量。
- `DISK WRITE`: 线程的磁盘写入量。
- `SWAPIN`: 线程的交换入量。
- `IO>`: 线程的 I/O 占用率。
- `COMMAND`: 线程所执行的命令。

通过观察 `IO>` 列，你可以找到当前占用磁盘 I/O 的进程，并了解其占用磁盘 I/O 的情况。同时，你可以按下 `P` 键按进程 I/O 占用率排序，或者按下 `A` 键查看所有进程的 I/O 占用情况。



### 测试 Ubuntu 磁盘 iops 和吞吐量的性能

在 Ubuntu 中，可以使用 `fio` 命令来测试磁盘的 IOPS（每秒输入/输出操作数）和吞吐量性能。

1. 首先，安装 `fio` 命令：

   ```bash
   sudo apt-get update
   sudo apt-get install fio
   ```

2. 然后，创建一个测试文件，可以使用以下命令：

   ```bash
   sudo fio --name=randwrite --ioengine=libaio --iodepth=16 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=1 --runtime=240 --time_based --group_reporting
   ```

   该命令将创建一个名为 `randwrite` 的测试作业，使用 `libaio` 引擎进行 I/O 操作，`iodepth` 参数指定了 I/O 操作队列的深度，`rw` 参数指定了读写模式，`bs` 参数指定了 I/O 操作的块大小，`direct` 参数指定了是否使用直接 I/O 模式，`size` 参数指定了测试文件的大小，`numjobs` 参数指定了测试作业的数量，`runtime` 参数指定了测试运行的时间，`group_reporting` 参数将多个作业的结果合并为一个报告。

   执行完毕后，`fio` 命令会输出测试结果，包括 IOPS、吞吐量等信息。

   需要注意的是，`fio` 命令会在测试期间对磁盘进行大量的 I/O 操作，可能会对磁盘产生一定的负担，因此建议在测试之前备份好重要的数据，并在一个空的目录下进行测试。

3. 除了使用 `fio` 命令外，还可以使用 `hdparm` 命令测试磁盘的性能。

   ```bash
   # 安装 hdparm 命令
   sudo apt-get update
   sudo apt-get install hdparm
   
   # 测试磁盘的读取速度，该命令将测试 /dev/sda 磁盘的读取速度，并输出测试结果。
   sudo hdparm -t /dev/sda
   
   # 测试磁盘的写入速度，该命令将测试 /dev/sda 磁盘的写入速度，并输出测试结果。
   sudo hdparm -Tt /dev/sda
   
   ```

   需要注意的是，`hdparm` 命令仅测试磁盘的读取和写入速度，并不会给磁盘造成过大的负担，但测试结果可能会受到磁盘缓存的影响。因此，在测试之前，最好先清除磁盘缓存，可以使用以下命令：

   ```bash
   # 该命令将清除磁盘缓存，确保测试结果准确。
   sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
   ```



### 使用 `dd` 命令来测试磁盘的性能

在 Linux 中，可以使用 `dd` 命令来测试磁盘的性能。`dd` 命令是一个用于复制文件和转换数据的工具，也可以用来测试磁盘的读写性能。

以下是使用 `dd` 命令测试磁盘写入性能的方法：

1. 首先，创建一个测试文件，可以使用以下命令：

   ```bash
   sudo dd if=/dev/zero of=/tmp/testfile bs=1M count=1000
   ```

   该命令将在 `/tmp` 目录下创建一个名为 `testfile` 的测试文件，文件大小为 1000 MB。

2. 然后，使用以下命令测试磁盘写入性能：

   ```bash
   sudo dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 conv=fdatasync
   ```

   该命令将从 `/dev/zero` 设备中读取数据，并将其写入 `/tmp/testfile` 文件中，`bs` 参数指定了块大小，`count` 参数指定了要写入的块数，`conv=fdatasync` 参数将强制将所有写入缓冲区的数据写入磁盘中，并等待写入操作完成。

   执行完毕后，`dd` 命令会输出测试结果，包括写入速度、花费的时间等信息。

以下是使用 `dd` 命令测试磁盘读取性能的方法：

1. 首先，使用以下命令创建一个测试文件：

   ```bash
   sudo dd if=/dev/urandom of=/tmp/testfile bs=1M count=1000
   ```

   该命令将从 `/dev/urandom` 设备中读取数据，并将其写入 `/tmp/testfile` 文件中，文件大小为 1000 MB。

2. 然后，使用以下命令测试磁盘读取性能：

   ```bash
   sudo dd if=/tmp/testfile of=/dev/null bs=1M count=1000
   ```

   该命令将从 `/tmp/testfile` 文件中读取数据，并将其丢弃，`bs` 参数指定了块大小，`count` 参数指定了要读取的块数。

   执行完毕后，`dd` 命令会输出测试结果，包括读取速度、花费的时间等信息。

需要注意的是，`dd` 命令可能会覆盖已有的数据，因此在测试磁盘性能时要格外小心。建议在一个空的目录下进行测试，避免误操作导致数据丢失。
