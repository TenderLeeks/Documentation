# 启动

创建服务启动脚本

```shell
$ tee /opt/ssdb/ssdb.sh <<-'EOF'
#!/bin/bash

ssdb_bin=/usr/local/ssdb/ssdb-server
config=/opt/ssdb/ssdb.conf

start() {
  $ssdb_bin ${config} -s restart -d
}

stop() {
  $ssdb_bin ${config} -s stop -d
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart}"
    ;;
esac
exit $RETVAL
EOF
```

服务自启动配置

```shell
$ tee /etc/systemd/system/ssdb.service <<EOF
[Unit]
Description=ssdb-server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/ssdb/ssdb-server /opt/ssdb/ssdb.conf -s restart -d
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

$ systemctl daemon-reload
$ systemctl enable ssdb.service
```

**注意：**

- 加上 -d 选项之后，SSDB 默认 daemon 方式启动。

- 执行 `ssdb-server` 必须使用管理员权限，否则会提示 `error opening log file: log.txt`。

- 启动之后，将自动生成如下目录结构：

  ```shell
  $ tree ssdb
  ssdb/
  ├── log.txt
  ├── ssdb.conf
  ├── ssdb.sh
  └── var
      ├── data
      │   ├── 000062.ldb
      │   ├── CURRENT
      │   ├── LOCK
      │   ├── LOG
      │   ├── LOG.old
      │   └── MANIFEST-000055
      ├── meta
      │   ├── 000017.log
      │   ├── CURRENT
      │   ├── LOCK
      │   ├── LOG
      │   ├── LOG.old
      │   └── MANIFEST-000016
      └── ssdb.pid
  ```

- `ssdb-server` 的选项：

  ```shell
  ssdb-server 1.9.8
  Copyright (c) 2012-2015 ssdb.io
  
  Usage:
      /usr/local/ssdb/ssdb-server [-d] /path/to/ssdb.conf [-s start|stop|restart]
  Options:
      -d    run as daemon
      -s    option to start|stop|restart the server
      -h    show this message
  ```

  