# 部署Redis 服务

```shell
# 自定义环境变量
$ echo -e "export REDIS_HOME=/opt/redis" > /etc/profile.d/redis.sh
$ source /etc/profile

$ export REDIS_VERSION='redis-6.2.1'
$ wget http://download.redis.io/releases/${REDIS_VERSION}.tar.gz
$ tar -xvzf ${REDIS_VERSION}.tar.gz -C /opt
$ mv /opt/${REDIS_VERSION} ${REDIS_HOME}
$ cd ${REDIS_HOME}
$ make
$ cp redis.conf redis.conf.bak
$ vim redis.conf
#############################################
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised no
pidfile /opt/redis/run/redis_6379.pid
loglevel notice
logfile "/opt/redis/log/server-out.log"
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ./
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
replica-priority 100
#requirepass PASSWORD  # 设置redis密码
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
#############################################

$ mkdir log run
# 启动服务
$ ${REDIS_HOME}/src/redis-server ${REDIS_HOME}/redis.conf
# 查看服务
$ netstat -nlpt
$ ps -ef|grep redis
```



