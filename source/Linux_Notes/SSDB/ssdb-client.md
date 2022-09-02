# SSDB 客户端

**注：ssdb-cli 是用 Python 写的一个 SSDB client**

## 安装
要修改 `tools/ssdb-cli` 文件内的 DIR 的值为标准路径（到 ssdb-cli 所在的文件夹的标准路径，之后再用命令 `ln -s /usr/local/src/ssdb-1.9.2/tools/ssdb-cli /usr/local/bin/` 软连接到环境变量 PATH 包含的路径，就可以直接执行 `ssdb-cli` 了，否则会提示 `/usr/local/bin/ssdb-cli: line 11: /usr/local/bin/deps/cpy/cpy: No such file or directory`。

## ssdb-cli 使用

连接到 SSDB Server：

```shell
$ ssdb-cli -p 8888
ssdb (cli) - ssdb command line tool.
Copyright (c) 2012-2015 ssdb.io

'h' or 'help' for help, 'q' to quit.

ssdb 127.0.0.1:8888> 
```

更多 ssdb-cli 选项

```shell
Usage:
 ssdb-cli [-h] [HOST] [-p] [PORT]

Options:
 -h 127.0.0.1
     ssdb server hostname/ip address
 -p 8888
     ssdb server port
 -v --help
     show this message
 -n [info, dbsize, replication, write_read]
     choose nagios probe
 -w INT
     set nagios WARN level
 -c INT
     set nagios CRITICAL level

Examples:
 ssdb-cli
 ssdb-cli 8888
 ssdb-cli 127.0.0.1 8888
 ssdb-cli -h 127.0.0.1 -p 8888
 ssdb-cli -h 127.0.0.1 -p 8888 -n dbsize -w 500000 -c 600000
 ssdb-cli -h 127.0.0.1 -p 8888 -n replication
 ssdb-cli -h 127.0.0.1 -p 8888 -n write_read
 ssdb-cli -n info
```

## 命令

获取 SSDB 状态

```shell
$ ssdb 127.0.0.1:8888> info
version
    1.9.2
links
    1
total_calls
    4
dbsize
    0
binlogs
        capacity : 20000000
        min_seq  : 0
        max_seq  : 1
serv_key_range
        kv  : "" - ""
        hash: "" - ""
        zset: "" - ""
        list: "" - ""
data_key_range
        kv  : "key1" - "key1"
        hash: "" - ""
        zset: "" - ""
        list: "" - ""
leveldb.stats
                                   Compactions
    Level  Files Size(MB) Time(sec) Read(MB) Write(MB)
    --------------------------------------------------

17 result(s) (0.001 sec)

```

导出 SSDB

注：不建议使用该方式导出整个数据库，导出速度很慢而且导出的文件占用很多磁盘空间

```shell
export backup.ssdb
```


更多命令
参考 [SSDB - 命令](https://www.zhengjie.com/link?target=http%3A%2F%2Fssdb.io%2Fdocs%2Fzh_cn%2Fcommands%2Findex.html)

