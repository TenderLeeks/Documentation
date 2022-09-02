# 安装和配置

## 安装

```shell
# 使用 HomeBrew 安装 SSDB
$ brew install ssdb

# 编译安装 SSDB
$ wget --no-check-certificate https://github.com/ideawu/ssdb/archive/master.zip -P /tmp
$ cd /tmp && unzip master.zip && cd ssdb-master
$ make && sudo make install
```

## 配置

参考文档：

- https://ssdb.io/docs/zh_cn/config.html

```shell
$ mkdir -p /opt/ssdb/var
$ cp -a /usr/local/ssdb/ssdb.conf /opt/ssdb/ssdb.conf
```

### 注意

- 自带配置文件 `ssdb.conf` 和从服务器配置文件 `ssdb_slave.conf`。
- 必须手动创建 var 文件夹，否则执行 `ssdb-server` 的时候会提示 `'./var' is not a directory or not exists!`。
- **SSDB 的配置文件使用一个 TAB 来表示一级缩进, 不要使用空格来缩进, 无论你用1个, 2个, 3个, 4个, 5个, 6个, 7个, 8个或者无数个空格都不行!**

### 重要

- 一定要记得修改你的 Linux 内核参数, 关于 `max open files(最大文件描述符数)`的内容, 请参考 [[1\]](http://www.ideawu.net/blog/archives/740.html).否则, 你会在 log.txt 看到 `Too many open files` 类似的错误, 或者在客户端看到 `Connection reset by peer` 错误.
- 使用这个 [c1000k](https://github.com/ideawu/c1000k) 工具来测试你的系统最多支持多少并发连接.

### 监听网络端口

```shell
server:
	ip: 127.0.0.1
	port: 8888
```

- 默认的配置文件监听 `127.0.0.1` 本地回路网络, 所以无法从其它机器上连接此 SSDB 服务器. 如果你希望从其它机器上连接 SSDB 服务器, 必须把 `127.0.0.1` 改为 `0.0.0.0`。
- 同时, 利用配置文件的 `deny, allow` 指令限制可信的来源 IP 访问。
- **警告：**如果不做网络限制便监听 `0.0.0.0` IP 可能导致被任意机器访问到你的数据, 这很可能是一个安全问题! 你可以结合操作系统的 iptables 来限制网络访问。

### 只读模式

```shell
server:
	readonly: yes|no
```

SSDB 可以工作在只读模式下, 在只读模式下, 所有的写操作命令都会被服务端拒绝:

```shell
ssdb 127.0.0.1:8888> set a 2
client_error: Forbidden Command: set
(0.000 sec)
```

默认配置文件不设置此选项, 那表示可读可写。

### 同步和复制

参考：https://ssdb.io/docs/zh_cn/replication.html

### 日志配置

参考：https://ssdb.io/docs/zh_cn/logs.html

- **`logger.level` 日志级别**

  支持的日志级别有: `debug, info, warn, error, fatal`.

  一般, 建议你将 `logger.level` 设置为 `debug` 级别.

- **`logger.output` 日志输出**

  可直接写相对路径或者绝对路径, 如果相对路径, 则是相对配置文件所在的目录.

  如果你想输出日志到终端屏幕, 编辑 ssdb.conf, 将

  ```shell
  logger:
  	output: log.txt
  # 修改为
  logger:
  	output: stdout
  ```

- **`logger.rorate.size` 日志循环和清理**

  设置日志拆分时的大小, 单位为字节数. 按照默认的配置, 日志会按 1000MB 大小进行切分, 切分后的文件名格式如: `log.txt.20150723-230422`.

  **切分后的日志文件不会自动被清理, 你需要自己写 crontab 脚本来清理。**

### 日志分析

一般, 建议你将 `logger.level` 设置为 `debug` 级别.

1. 请求处理

   ```shell
   2014-06-18 11:01:40.335 [DEBUG] serv.cpp(395): w:0.393,p:5.356, req: set a 1, resp: ok 1
   ```

   - `w:0.393` 请求的排队时间, 毫秒
   - `p:5.356` 请求的处理时间, 毫秒
   - `req:...` 请求内容
   - `resp:...` 响应内容

2. 找出慢请求

   ```shell
   $ tail -f log.txt | grep -w resp | grep '[wp]:[1-9][0-9]\{0,\}\.'
   # 或者
   $ cat log.txt | grep -w resp | grep '[wp]:[1-9][0-9]\{0,\}\.'
   ```

   这些命令用于找出排队时间, 或者处理时间大于等于 1 毫秒的请求.

   **找出大于 10 毫秒的请求:**

   ```shell
   $ cat log.txt | grep -w resp | grep '[wp]:[1-9][0-9]\{1,\}\.'
   
   ```

   **找出大于 100 毫秒的请求:**

   ```shell
   $ cat log.txt | grep -w resp | grep '[wp]:[1-9][0-9]\{2,\}\.'
   
   ```

3. SSDB 在工作中

   ssdb-server 会每隔 5 分钟输出这样的一条 log

   ```shell
   2014-06-18 11:18:03.600 [INFO ] ssdb-server.cpp(215): ssdb working, links: 0
   2014-06-18 11:23:03.631 [INFO ] ssdb-server.cpp(215): ssdb working, links: 0
   ```

   - `links: 0` 当前的连接数

### LevelDB 配置

- **`leveldb.cache_size` 内存缓存大小, 单位 MB**

​		一般地, 这个数字越大, 性能越好, 你可设置为物理内存的一半. 如果你的机器内存较小, 那就把它改小, 最小值是 16。

- **`leveldb.block_size` 不用关心**
- **`leveldb.write_buffer_size` 写缓冲区大小, 单位 MB**

​		如果你的机器内存小, 那就把它改小, 否则改大. 它应该在这个范围内: `[4, 128]`;

- **`leveldb.compaction_speed`**

​		一般情况下, 不用关心. 如果你的硬盘性能非常差, 同时, 你的数据几乎不变动, 也没有什么新数据写入, 可以把它改小(最好大于 50)。

- **`leveldb.compression` 压缩硬盘上的数据**

​		最好设置为 `yes`! 如果是 `yes`, 一般你能存储 10 倍硬盘空间的数据, 而且性能会更好。

### 内存占用

一个 ssdb-server 实例占用的内存**瞬时**(有可能, 而且即使达到, 也只是持续短时间)最高达到(MB):

```shell
cache_size + write_buffer_size * 66 + 32
```

这是对于压缩选项没有开启的情况. 如果 `compression: yes`, 计算公式是:

```shell
cache_size + 10 * write_buffer_size * 66 + 32
```

你可以调整配置参数, 限制 ssdb-server 的内存占用。

对于一般负载的实例来说, 物理内存的**持续**占用是:

```shell
cache_size + write_buffer_size * 4 + 32

```

根据实际经验, 使用默认配置的实例, 会占用约 1GB 的内存. 这个经验你可以参考。

### 设置内存占用上限?

很抱歉, SSDB 无法设置内存占用上限. SSDB占用的内存大小, 和下列因素相关:

1. `cache_size` 参数配置, 这是最主要的因素.
2. 客户端连接的数量, 一般来说, 每一个连接要占用 2MB 的内存, 但也和连接的使用繁忙度请求响应的大小等有关.
3. 文件缓存, 虽然是被 ssdb-server 进程占用, 但是可被操作系统回收的, 可能会占用数十 GB.
4. SSDB 的繁忙程度, 服务越繁忙, SSDB 会倾向于使用更多的内存, 以提高响应速度.

总体来说, `cache_size` 参数是你可以控制的, 后面的因素你无法控制. 例如, 在一个比较空闲的 SSDB 上, 如果物理内存是 16G, 而你设置 `cache_size` 是 8000(8G), 那么你通过 top 命令会看到 ssdb-server 进程占用 RES 内存可能在 12G 左右. 如果是一个比较繁忙的实例, RES 可能达到 15G.

## ssdb.conf

注：默认的 SSDB 配置文件

注：参考 [Configuration - SSDB](https://www.zhengjie.com/link?target=http%3A%2F%2Fssdb.io%2Fdocs%2Fconfig.html)

```shell
# ssdb-server config
# MUST indent by TAB!

# relative to path of this file, directory must exists
work_dir = ./var
pidfile = ./var/ssdb.pid

server:
	ip: 127.0.0.1
	port: 8888
	# bind to public ip
	#ip: 0.0.0.0
	# format: allow|deny: all|ip_prefix
	# multiple allows or denys is supported
	#deny: all
	#allow: 127.0.0.1
	#allow: 192.168
	# auth password must be at least 32 characters
	#auth: very-strong-password

replication:
	binlog: yes
	# Limit sync speed to *MB/s, -1: no limit
	sync_speed: -1
	slaveof:
		# to identify a master even if it moved(ip, port changed)
		# if set to empty or not defined, ip:port will be used.
		#id: svc_2
		# sync|mirror, default is sync
		#type: sync
		#ip: 127.0.0.1
		#port: 8889

logger:
	level: debug
	output: log.txt
	rotate:
		size: 1000000000

leveldb:
	cache_size: 500
    # in MB
	# in KB
	block_size: 32
	# in MB
	write_buffer_size: 64
	# in MB
	compaction_speed: 1000
	# yes|no
	compression: yes
```

**注意：**

- `leveldb.cache_size` 默认的内存缓存大小为 `500 MB`，最小值 `16 MB`。
- `leveldb.write_buffer_size` 默认值为 `64 MB`，取值范围 `[4, 128]`。
- `compression: yes` 时，`ssdb-server` 实例占用的内存瞬间最高达到(MB): `cache_size + 10 * write_buffer_size * 66 + 32`，也就是说如果 `cache_size` 为 500 MB，`write_buffer_size` 为 64 MB，则最高内存占用大概为 `500 MB + 10 * 64 MB * 66 + 32 MB = 42772 MB`，大约为 `41.77 GB`；如果机器内存小，建议把 `write_buffer_size` 改小，范围为 `[4, 128]`；当 `write_buffer_size` 为 `4` 的时候，占用的内存大概为 `500 MB + 10 * 4 MB * 66 + 32 MB = 3172 MB`，`3.10 GB`。
- `compression: no` 时，`ssdb-server` 实例占用的内存瞬间最高达到(MB): `cache_size + write_buffer_size * 66 + 32`。
- 偶尔通过 `ssdb-cli` 使用命令 `compact` 可以减少内存占用（压缩内存，`Compress`）。
- 建议把 `logger.level` 改为 `error`，否则会在 `var/` 的父目录下产生一个或多个很大的 `log.txt` 文件。
- 值得注意的是配置文件里面的缩进符号都是 t，不能使用`空格/4个空格`否则 `SSDB Server` 无法启动。
- 建议配置 `server.auth` 的值以提高安全性。

## ssdb_slave.conf

注：默认的 SSDB 从服务器配置文件

```shell
# ssdb-server config

# relative to path of this file, must exist
work_dir = ./var_slave
pidfile = ./var_slave/ssdb.pid

server:
    ip: 127.0.0.1
    port: 8889

replication:
    binlog: yes
    # Limit sync speed to *MB/s, -1: no limit
    sync_speed: -1
    slaveof:
        # to identify a master even if it moved(ip, port changed)
        # if set to empty or not defined, ip:port will be used.
        id: svc_1
        # sync|mirror, default is sync
        type: sync
        ip: 127.0.0.1
        port: 8888
        #auth: password

logger:
    level: debug
    output: log_slave.txt
    rotate:
        size: 1000000000

leveldb:
    # in MB
    cache_size: 500
    # in KB
    block_size: 32
    # in MB
    write_buffer_size: 64
    # in MB
    compaction_speed: 200
    # yes|no
    compression: no
```

注：`replication.slaveof` 允许配置 `auth`，也就是 `master SSDB Server` 的 `server.auth` 的值。

