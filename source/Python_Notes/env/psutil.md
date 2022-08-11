# psutil 模块

## 介绍

psutil是个跨平台库，能够轻松实现获取系统运行的进程和系统利用率，包括CPU、内存、磁盘、网络等信息。

它主要应用于信息监控，分析和限制系统资源及进程的管理。它实现了同等命令命令行工具提供的功能，如：ps、top、lsof、netstat、ifconfig、who、df、kill、free、nice、ionice、iostat、iotop、uptime、pidof、tty、taskset、pmap等。目前支持32位和64位的linux、windows、OS X、FreeBSD和Sun Solaris等操作系统。

## 安装

1. 源码安装

   ```shell
   $ git clone https://github.com/giampaolo/psutil.git
   $ cd psutil
   $ python3 setup.py install
   ```

2. pip安装

   ```shell
   $ pip3 install psutil
   ```

## CPU 信息

1. 查看CPU信息

   ```python
   >>> import psutil
   >>> psutil.cpu_times(percpu=False)
   scputimes(user=257864.4, nice=0.0, system=382961.57, idle=2384577.89, iowait=78.37, irq=0.0, softirq=17.42, steal=0.0, guest=0.0, guest_nice=0.0)
   ```

   `user`：用户进程花费的时间

   `nice`：用户模式执行Niced优先级进程花费的时间

   `system`：内核模式进程花费的时间

   `idle`：闲置时间

   `iowait`：等待I/O完成的时间

   `irq`：处理硬件中断的时间

   `softirq`：处理软件中断的时间

   `steal`：虚拟化环境中运行的其他操作系统花费的时间

   `guest`：在linux内核的控制下为客户端操作系统运行虚拟CPU所花费的时间

   `guest_nice`：虚拟机运行niced所花费的时间

2. 查看CPU逻辑信息

   ```python
   >>> psutil.cpu_times(percpu=True)
   [scputimes(user=61122.76, nice=0.0, system=106636.26, idle=210787.57), 
    scputimes(user=8661.66, nice=0.0, system=6204.89, idle=363578.25), 
    scputimes(user=57444.58, nice=0.0, system=90562.7, idle=230437.83), 
    scputimes(user=8630.91, nice=0.0, system=6148.36, idle=363665.45), 
    scputimes(user=54203.25, nice=0.0, system=83824.53, idle=240417.24), 
    scputimes(user=8674.24, nice=0.0, system=5916.32, idle=363854.04), 
    scputimes(user=50596.66, nice=0.0, system=78025.76, idle=249822.47), 
    scputimes(user=8734.55, nice=0.0, system=5769.61, idle=363940.25)]
   ```

3. 用户占CPU的时间比

   ```python
   >>> psutil.cpu_times().user 
   258169.89
   ```

4. CPU逻辑和物理的数量

   ```python
   # 逻辑数量
   >>> psutil.cpu_count(logical=True)
   8
   # 物理数量
   >>>psutil.cpu_count(logical=False)
   4
   ```

5. CPU统计信息

   ```python
   >>> psutil.cpu_stats()  
   scpustats(ctx_switches=315927, interrupts=1210000, soft_interrupts=869793082, syscalls=2680562)
   ```

   `ctx_switches`：启动后的上下问切换次数

   `interrupts`：自启动以来的中断次数

   `soft_interrupts`：启动后的软件中断数量

   `syscalls`：启动以来的系统调用次数，在linux上始终为0

## 内存信息

1. 获取内存完整信息

   ```python
   >>> mem = psutil.virtual_memory()  # 以字节返回内存使用情况的统计信息
   >>> mem
   svmem(total=34359738368, available=12255588352, percent=64.3, used=16028160000, free=1210048512, active=11025838080, inactive=10960617472, wired=5002321920)
   ```

   `total`：总物理内存

   `available`：可用的内存

   `used`：使用的内存

   `free`：完全没有使用的内存

   `active`：当前正在使用的内存

   `inactive`：标记为未使用的内存

   `buffers`：缓存文件系统元数据使用的内存

   `cached`：缓存各种文件的内存

   `shared`：可以被多个进程同时访问的内存

   `slab`：内核数据结构缓存的内存

2. 获取内存总数

   ```python
   >>> mem.total
   34359738368
   ```

3. 获取已使用内存

   ```python
   >>> mem.used
   16028160000
   ```

4. 获取空闲内存

   ```python
   >>> mem.free  
   1210048512
   ```

5. 获取swap内存信息

   ```python
   >>> psutil.swap_memory()
   sswap(total=4294967296, used=2988965888, free=1306001408, percent=69.6, sin=54874046464, sout=1968377856)
   ```

   `total`：以字节为单位的总交换内存

   `used`：以字节为单位使用交换内存

   `free`：以字节为单位的可用交换内存

   `percent`：使用百分比

   `sin`：系统从磁盘交换的字节数

   `sout`：系统从磁盘换出的字节数



## 磁盘信息

1. 获取磁盘完整信息

   ```python
   # 返回所有安装的磁盘分区作为名称元组的列表，包括设备，安装点和文件系统类型，类似于Unix上的‘df’命令.
   >>> psutil.disk_partitions(all=False)
   ```

2. 获取分区使用情况

   `psutil.disk_usage(path)`：将有关包含给定路径的分区的磁盘使用情况统计信息返回为指定元组，包括以字节表示的，总共，已使用和空闲的空间以及百分比使用率，如果路径存在则引发OSError。

   ```python
   >>> psutil.disk_usage('/')
   sdiskusage(total=499963174912, used=122209394688, free=377753780224, percent=24.4)
   ```

   `total`：总的大小（字节）

   `used`：已使用的大小（字节）

   `free`：空闲的大小（字节）

   `percent`：使用百分比

3. 获取单个分区的IO信息

   ```python
   >>> psutil.disk_io_counters(perdisk=True)
   {'disk0': sdiskio(read_count=9104860, write_count=37789237, read_bytes=134798548992, write_bytes=541411799040, read_time=5935725, write_time=6429279)}
   ```

   `psutil.disk_io_counters(perdisk=False,nowrap=True)` ：将系统范围的磁盘I/0统计作为命名元组返回，包括以下字段：

   - `read_count`：读取次数

   - `write_count`：写入次数

   - `read_bytes`：读取的字节数

   - `write_bytes`：写入的字节数

   - `read_time`：从磁盘读取的时间（以毫秒为单位）

   - `write_time`：写入磁盘的时间（毫秒为单位）

   - `busy_time`：花费在实际I/O上的时间

   - `read_merged_count`：合并读取的数量

   - `write_merged_count`：合并写入次数

   `perdisk`为True时返回物理磁盘相同的信息；`nowrap`为True它将检测并调整函数调用中的新值。



## 网络信息

`psutil.net_io_counters(pernic=False,nowrap=True)`：将系统范围的网络I/O统计信息作为命名元组返回，包括以下属性：

- `bytes_sent`：发送的字节数
- `bytes_recv`：收到的字节数
- `packets_sent`：发送的数据包数量
- `packets_recv`：接收的数据包数量
- `errin`：接收时的错误总数
- `errout`：发送时的错误总数
- `dropin`：丢弃的传入数据包总数
- `dripout`：丢弃的传出数据包总数（在OSX和BSD上始终为0）

如果pernic为True网络接口上安装的每个网络接口返回相同的信息，nowrap为True时将检测并调整函数调用中的这些数字，将旧值添加到新值，保证返回的数字将增加或不变，但不减少，net_io_counters.cache_clear()可用于使nowrap缓存失效。

```python
>>> psutil.net_io_counters(pernic=False,nowrap=True)
snetio(bytes_sent=7796237312, bytes_recv=7733955584, packets_sent=39699582, packets_recv=46477285, errin=0, errout=1372, dropin=359873877988372, dropout=0)

>>> psutil.net_io_counters(pernic=True,nowrap=True)
```



`psutil.net_connections(kind='inet')`：返回系统范围的套接字链接，命令元组列表返回，每个命名元组提供了7个属性：

- `fd`：套接字文件描述符。
- `family`：地址系列，AF_INET， AF_INET6 或AF_UNIX。
- `type`：地址类型，SOCK_STREAM或 SOCK_DGRAM。
- `laddr`：本地地址作为命名元组或 AF_UNIX套接字的情况。对于UNIX套接字，请参阅下面的注释。
- `raddr`：远程地址是指定的元组，或者是UNIX套接字的绝对地址。当远程端点未连接时，您将获得一个空元组（AF_INET *）或（AF_UNIX）。对于UNIX套接字，请参阅下面的注释。
- `status`：表示TCP连接的状态。
- `pid`：打开套接字的进程的PID，如果是可检索的，否则None。在某些平台（例如Linux）上，此字段的可用性根据进程权限而变化（需要root）。

kind参数的值包括：

- `inet`：ipv4和ipv6
- `inet4`：ipv4
- `inet6`：ipv6
- `tcp`：TCP
- `tcp4`：TCP over ipv4
- `tcp6`：TCP over ipv6
- `udp`：UDP
- `dup4`：基于ipv4的udp
- `cpu6`：基于ipv6的udp
- `Unix`：UNIX套接字（udp和TCP协议）
- `all`：所有可能的家庭和协议的总和

```python
>>> psutil.net_connections(kind='tcp')

>>> psutil.net_connections(kind='inet4')
```

`psutil.net_if_addrs()`：以字典的方式返回系统上的每个网络接口的关联地址。

```python
>>> psutil.net_if_addrs()
```

`psutil.net_if_stats()`：将安装在系统上的网络接口的信息作为字典返回，其中包括isup是否启动，duplex双工模式，speed速率，mtu最大传输单位，以字节表示。

```python
>>> psutil.net_if_stats()
```



## 进程信息

```python
>>> psutil.pids()  # 列出所有进程PID
[0, 1, 112, 113, ...]

>>> p = psutil.Process(1)  # 实例化一个Process对象，参数为进程PID
>>> p.name()  # 进程名
'launchd'

>>> p.exe()  # 进程bin路径
'/sbin/launchd'

>>> p.cwd()  # 进程工作目录绝对路径
>>> p.cmdline()  # 进程启动的命令行
>>> p.ppid()  # 父进程ID
>>> p.parent()  # 父进程
>>> p.children()  # 子进程列表
>>> p.status()  # 进程状态
'running'

>>> p.username() # 进程用户名
>>> p.create_time()  # 进程创建时间，时间戳格式
1658052057.22174

>>> p.terminal()  # 进程终端
>>> p.uids()  # 进程UID信息
puids(real=0, effective=0, saved=0)

>>> p.gids()  # 进程GID信息
puids(real=0, effective=0, saved=0)

>>> p.cpu_times()  # 进程CPU时间信息，包括user、system的CPU时间
>>> p.cpu_affinity()  # get进程CPU亲和度，如果设置进程CPU亲和度，将CPU号作为参数即可
>>> p.memory_info()  # 进程内存rss、vms信息
>>> p.io_counters()  # 进程IO信息包括读写IO数及字节数
>>> p.connections()  # 返回发开进程socket的namedutples列表，包括fs、family、laddr等信息
>>> p.num_threads()  # 进程开启的线程数
>>> p.memory_percent()  # 进程内存利用率
>>> p.open_files() # 进程打开的文件
>>> p.connections() # 进程相关网络连接
>>> p.num_threads() # 进程的线程数量
>>> p.threads() # 所有线程信息
>>> p.environ() # 进程环境变量
>>> p.terminate() # 结束进程
```

`psutil.process_iter(attrs=None,ad_value=None)`：返回一个迭代器process，为本地机器上的所有正在运行的进程生成一个类实例。

`psutil.pid_exists(pid)`：检查给定的PID是否存在于当前进程列表中。

`psutil.wait_procs(procs,timeout=None,callback=None)`：等待process终止实例列表的便捷函数，返回一个元组，指示哪些进程已经消失，哪些进程还活着。

`class psutil.Popen(*args,**kwargs)`：它启动一个子进程，并完全像使用subprocess.Popen一样处理，它还提供了所有psutil.Process类的方法。Popen类的作用是获取用户启动的应用程序进程信息，以便跟踪程序进程的运行状态。

```python
>>> import psutil
>>> from subprocess import PIPE
>>> p = psutil.Popen(["/usr/bin/python","-c", "print('hello world')"], stdout=PIPE)
>>> p.name()
>>> p.username()
>>> p.communicate()
```

进程过滤实例

```python
>>> import psutil
>>> from pprint import pprint as pp

# 根据进程名查看系统中的进程名与pid
>>> pp([p.info for p in psutil.process_iter(attrs=['pid','name']) if 'python' in p.info['name']])
>>> pp([p.info for p in psutil.process_iter(attrs=['pid','name']) if 'mysql' in p.info['name']])

# 所有用户进程
>>> import getpass
>>> pp([(p.pid,p.info['name']) for p in psutil.process_iter(attrs=['name','username']) if p.info['username'] == getpass.getuser()])

# 查看积极运行的进程：
>>> pp([(p.pid,p.info) for p in psutil.process_iter(attrs=['name','status']) if p.info['status'] == psutil.STATUS_RUNNING])

# 使用日志文件的进程
>>> import os,psutil

>>> for p in psutil.process_iter(attrs=['name','open_files']):
    ...:     for file in p.info['open_files'] or []:
    ...:         if os.path.splitext(file.path)[1] == '.log':
    ...:             print("%-5s %-10s %s" % (p.pid,p.info['name'][:10],file.path
    ...: ))
    ...:             

# 消耗超过5M内存的进程：
>>> pp([(p.pid,p.info['name'],p.info['memory_info'].rss) for p in psutil.pro
    ...: cess_iter(attrs=['name','memory_info']) if p.info['memory_info'].rss > 5
    ...:  * 1024 * 1024])

# 消耗量最大的3个进程
>>> pp([(p.pid, p.info) for p in sorted(psutil.process_iter(attrs=['name', 'memory_percent']), key=lambda p: p.info['memory_percent'])][-3:])

# 消耗最多CPU时间的前3个进程
>>> pp([(p.pid, p.info['name'], sum(p.info['cpu_times'])) for p in sorted(ps
    ...: util.process_iter(attrs=['name', 'cpu_times']), key=lambda p: sum(p.info
    ...: ['cpu_times'][:2]))][-3:])

# 导致最多I/O的前3个进程
>>> pp([(p.pid, p.info['name']) for p in sorted(psutil.process_iter(attrs=['
    ...: name', 'io_counters']), key=lambda p: p.info['io_counters'] and p.info['
    ...: io_counters'][:2])][-3:])

# 前3个进程打开最多的文件描述符：
>>> pp([(p.pid, p.info) for p in sorted(psutil.process_iter(attrs=['name', 'num_fds']), key=lambda p: p.info['num_fds'])][-3:])
```



## 其他系统信息

1. 系统启动时间戳

   ```python
   >>> import psutil, time
   >>> psutil.boot_time()
   1658052096.0
   
   ```

2. 格式化时间

   ```python
   >>> time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(psutil.boot_time())) 
   '2022-07-17 18:01:36'
   ```

3. 返回当前链接的系统用户

   ```python
   >>> psutil.users() 
   [suser(name='root', terminal='console', host=None, started=1658109440.0, pid=180), 
    suser(name='root', terminal='ttys000', host=None, started=1659319680.0, pid=47034)]
   
   ```

   

## 参考文献

[官方文档](https://psutil.readthedocs.io/en/latest/)

[python3之模块psutil系统性能信息](https://www.cnblogs.com/zhangxinqi/p/9106265.html)