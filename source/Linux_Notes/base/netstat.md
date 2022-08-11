# netstat 命令

## 简介

`netstat`是控制台命令,是一个监控`TCP/IP`网络的非常有用的工具，它可以显示路由表、实际的网络连接以及每一个网络接口设备的状态信息。

`netstat`用于显示与IP、TCP、UDP和ICMP协议相关的统计数据，一般用于检验本机各端口的网络连接情况。

## 输出信息描述

执行`netstat`后输出如下：

```tex
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0    368 elasticsearch-1:ssh     TenderLeksdeMBP.l:54501 ESTABLISHED
tcp6       0      0 elasticsearch-1:35240   192.168.67.44:9300      ESTABLISHED
tcp6       0      0 elasticsearch-1:9300    192.168.67.44:56924     ESTABLISHED
tcp6       0      0 elasticsearch-1:51748   192.168.66.40:9300      ESTABLISHED
tcp6       0      0 elasticsearch-1:9300    192.168.66.40:33220     ESTABLISHED
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags       Type       State         I-Node   Path
unix  2      [ ]         DGRAM                    21334    /run/user/1000/systemd/notify
unix  3      [ ]         DGRAM                    11054    /run/systemd/notify
unix  10     [ ]         DGRAM                    11067    /run/systemd/journal/socket
unix  2      [ ]         DGRAM                    11069    /run/systemd/journal/syslog
unix  8      [ ]         DGRAM                    11151    /run/systemd/journal/dev-log
unix  2      [ ]         DGRAM                    2460091  @00070
unix  3      [ ]         DGRAM                    113859   
```

netstat的输出结果可以分为两个部分：

- `Active Internet connections`：称为有源TCP连接，其中"Recv-Q"和"Send-Q"指%0A的是接收队列和发送队列。这些数字一般都应该是0。如果不是则表示软件包正在队列中堆积。这种情况只能在非常少的情况见到。

- `Active UNIX domain sockets`：称为有源Unix域套接口(和网络套接字一样，但是只能用于本机通信，性能可以提高一倍)。

  列信息：

  - `Proto`：显示连接使用的协议。
  - `RefCnt`：表示连接到本套接口上的进程号。
  - `Types`：显示套接口的类型。
  - `State`：显示套接口当前的状态。
  - `Path`：表示连接到套接口的其它进程使用的路径名。

## 常见参数

- `-a` ：(all)显示所有选项，默认不显示LISTEN相关。
- `-t`：(tcp)仅显示tcp相关选项。
- `-u`：(udp)仅显示udp相关选项。
- `-n`：拒绝显示别名，能显示数字的全部转化成数字。 
- `-l`：仅列出有在 Listen (监听) 的服務状态。
- `-p`：显示建立相关链接的程序名。
- `-r`：显示路由信息，路由表。
- `-e`：显示扩展信息，例如uid等。
- `-s`：按各个协议进行统计。
- `-c`：每隔一个固定时间，执行该netstat命令。
- `LISTEN`和`LISTENING`的状态只有用`-a`或者`-l`才能看到。

## 常用命令示例

1. 显示所有端口 (包括监听和未监听的)

   显示所有端口：`netstat -a`

   显示所有TCP端口：`netstat -at`

   显示所有UDP端口：`netstat -au`

2. 显示所有处于监听状态的Sockets

   只显示监听端口：`netstat -l`

   只显示所有监听TCP端口：`netstat -lt`

   只显示所有UDP端口：`netstat -lu`

   只显示所有监听UNIX端口：`netstat -lx`

3. 显示每个协议的统计信息

   显示所有端口的统计信息：`netstat -s`

   显示TCP端口的统计信息：`netstat -st`

   显示UDP端口的统计信息：`netstat -su`

4. 显示PID和进程名：`netstat -p`

   `netstat -p`可以与其它开关一起使用，就可以添加 `PID/进程名称` 到`netstat`输出中，这样`debugging`的时候可以很方便的发现特定端口运行的程序。

   ```shell
   $ netstat -pt
   Active Internet connections (w/o servers)
   Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
   tcp        0    208 elasticsearch-1:ssh     TenderLeksdeMBP.l:54501 ESTABLISHED 24184/sshd: ubuntu  
   tcp6       0      0 elasticsearch-1:35240   192.168.67.44:9300      ESTABLISHED 13691/java
   tcp6       0      0 elasticsearch-1:9300    192.168.67.44:56924     ESTABLISHED 13691/java
   ```

5. 不显示主机，端口和用户名

   当你不想让主机，端口和用户名显示，使用`netstat -n`将会使用数字代替那些名称。

   同样可以加速输出，因为不用进行比对查询。

   ```shell
   $ netstat -an
   ```

   如果只是不想让这三个名称中的一个被显示，使用以下命令

   ```shell
   $ netsat -a --numeric-ports
   $ netsat -a --numeric-hosts
   $ netsat -a --numeric-users
   ```

6. 持续输出netstat信息

   netstat将每隔一秒输出网络信息

   ```shell
   $ netstat -c
   ```

7. 显示系统不支持的地址族（Address Families）

   ```shell
   $ netstat --verbose
   ```

   在输出的末尾，会有如下的信息

   ```tex
   netstat: no support for `AF IPX' on this system.
   netstat: no support for `AF AX25' on this system.
   netstat: no support for `AF X25' on this system.
   netstat: no support for `AF NETROM' on this system.
   netstat: no support for `AF ROSE' on this system.
   ```

8. 显示核心路由信息

   ```shell
   $ netstat -r
   Kernel IP routing table
   Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
   default         Openwrt.lan     0.0.0.0         UG        0 0          0 ens3
   169.254.169.254 192.168.66.2    255.255.255.255 UGH       0 0          0 ens3
   172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 docker0
   172.18.0.0      0.0.0.0         255.255.0.0     U         0 0          0 br-042cf301c513
   172.25.0.0      0.0.0.0         255.255.0.0     U         0 0          0 zt7nne4pq5
   192.168.64.0    0.0.0.0         255.255.252.0   U         0 0          0 ens3
   ```

   **注意：** 使用 netstat -rn 显示数字格式，不查询主机名称。

9. 显示程序运行的端口和指定端口的进程

   ```shell
   # 并不是所有的进程都能找到，没有权限的会不显示，使用 root 权限查看所有的信息。
   $ netstat -ap | grep ssh
   # 运行在指定端口的进程
   $ netstat -an | grep ':80'
   ```

10. 显示网络接口列表

    ```shell
    $ netstat -i
    Kernel Interface table
    Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
    br-042cf  1500     1961      0      0 0        805959      0      0      0 BMRU
    docker0   1500        0      0      0 0             0      0      0      0 BMU
    ens3      1500 100949071      0 2910538 0      45803500      0      0      0 BMRU
    lo       65536  6449493      0      0 0       6449493      0      0      0 LRU
    veth0562  1500        0      0      0 0        802643      0      0      0 BMRU
    veth85da  1500  1068466      0      0 0       2137324      0      0      0 BMRU
    veth934e  1500   128344      0      0 0        948640      0      0      0 BMRU
    vetha9c9  1500        0      0      0 0        802650      0      0      0 BMRU
    vethd3ac  1500  1481109      0      0 0       2001016      0      0      0 BMRU
    zt7nne4p  2800     4528      0      0 0          1057      0      0      0 BMRU
    ```

    显示详细信息，像是 `ifconfig` 使用 `netstat -ie`

    ```shell
    $ netstat -ie
    Kernel Interface table
    br-042cf301c513: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet 172.18.0.1  netmask 255.255.0.0  broadcast 172.18.255.255
            inet6 fe80::42:4aff:fe41:256c  prefixlen 64  scopeid 0x20<link>
            ether 02:42:4a:41:25:6c  txqueuelen 0  (Ethernet)
            RX packets 1961  bytes 5219630 (5.2 MB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 806104  bytes 34150083 (34.1 MB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    
    docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
            inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
            ether 02:42:11:11:1a:00  txqueuelen 0  (Ethernet)
            RX packets 0  bytes 0 (0.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 0  bytes 0 (0.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    ```

11. IP和TCP分析

    ```shell
    # 查看连接某服务端口最多的的IP地址
    $ netstat -nat | grep "10.1.1.10:22" |awk '{print $5}'|awk -F: '{print $1}'|sort|uniq -c|sort -nr|head -20
    # TCP各种状态列表
    $ netstat -nat |awk '{print $6}'
    # 把状态全都取出来,然后使用uniq -c统计，之后再进行排序。
    $ netstat -nat |awk '{print $6}'|sort|uniq -c|sort -rn
    ```

    