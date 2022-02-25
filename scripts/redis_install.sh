#!/usr/bin/env bash
set -e

VERSION="${1:-6.2.6}"
PORT="${2:-6379}"
DIR="${3:-${HOME}}"
PASSWORD=$4

echo "Redis version is ${VERSION}."
echo "The Redis installation directory is ${DIR}"
echo


function is_exist() {
  if [ -d "${DIR}/redis-${PORT}" ]; then
    echo "exist path ${DIR}/redis-${PORT}, installation failed."
    exit 0
  fi

  if [ "$(netstat -ntlp | grep -c "${PORT}")" -gt 0 ]; then
    echo "exist ${PORT} port, installation failed."
    exit 0
  fi

}

function config() {
  tee "${DIR}"/redis-"${PORT}"/conf/redis.conf <<EOF
protected-mode yes
port ${PORT}
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised no
pidfile ${DIR}/redis-${PORT}/run/redis_${PORT}.pid
loglevel notice
logfile ${DIR}/redis-${PORT}/logs/redis-server.log
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ${DIR}/redis-${PORT}/
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
replica-priority 100
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
EOF

  if [ -n "${PASSWORD}" ]; then
    echo "requirepass ${PASSWORD}" >> "${DIR}"/redis-"${PORT}"/conf/redis.conf
  fi
}

function install() {
  download_dir=/tmp/redis-"${VERSION}"-"$(date +'%Y%m%d-%H%M')"
  mkdir -p "${download_dir}"
  cd "${download_dir}"
  wget https://download.redis.io/releases/redis-"${VERSION}".tar.gz
  tar -xvzf redis-"${VERSION}".tar.gz && cd redis-"${VERSION}"
  make install PREFIX="${DIR}/redis-${PORT}"
  [ $? -eq 0 ] && echo "make error, installation failed"
  mkdir -p "${DIR}"/redis-"${PORT}"/{logs,run,conf}
  config
  echo
  echo "Installed version: redis-${VERSION}"
  echo "Installation path: ${DIR}/redis-${PORT}"
  echo "Port: ${PORT}"
  echo "PassWord: ${PASSWORD}"
  echo "start: systemctl start redis-${PORT}.service"
  echo "stop: systemctl stop redis-${PORT}.service"
  echo "restart: systemctl restart redis-${PORT}.service"
  echo "status: systemctl status redis-${PORT}.service"
  echo
  echo "Successful installation"
}

function do_start() {
  tee /etc/systemd/system/redis-"${PORT}".service <<EOF
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking
ExecStart=${DIR}/redis-${PORT}/bin/redis-server ${DIR}/redis-${PORT}/conf/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable redis-"${PORT}".service
  systemctl start redis-"${PORT}".service
}

is_exist
install
do_start
