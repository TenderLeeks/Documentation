# zabbix agent

## 配置 agent

```shell
$ groupadd --system zabbix
$ useradd --system -g zabbix -s /sbin/nologin -c "Zabbix Monitoring System" -M zabbix
$ yum -y install gcc pcre*
$ tar -zxf zabbix-4.4.7.tar.gz
$ cd zabbix-4.4.7/
$ ./configure --prefix=/opt/zabbix-agent --enable-agent
$ make && make install
$ /bin/cp -f misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
$ mkdir -p /opt/zabbix-agent/{log,run,script,var}
$ cd /opt/zabbix-agent/etc
$ mv zabbix_agentd.conf zabbix_agentd.conf.bak
$ cat zabbix_agentd.conf.bak | egrep -v "^#|^$" > zabbix_agentd.conf
$ vim zabbix_agentd.conf 
#####################文件内容#########################
PidFile=/opt/zabbix-agent/run/zabbix_agentd.pid
LogFile=/opt/zabbix-agent/log/zabbix_agentd.log
LogFileSize=0
Server=152.136.228.11
ServerActive=152.136.228.11
Hostname=bj-op-zbxserver-01
HostnameItem=system.hostname
Include=/opt/zabbix-agent/etc/zabbix_agentd.conf.d/*.conf
Timeout=30
#######################################################
$ vim /opt/zabbix-agent/init.agent
########################脚本内容###########################
#!/bin/sh
DAEMON="/opt/zabbix-agent/sbin/zabbix_agentd"
CONFIG="/opt/zabbix-agent/etc/zabbix_agentd.conf"
PIDFILE="/opt/zabbix-agent/run/zabbix_agentd.pid"
NAME="zabbix_agentd"
is_running() {
    [ `pgrep ${NAME} | wc -l` -gt 0  ] || return 1
    return 0
}
is_root() {
    [ "`whoami`" = 'root' ] && return 0
    return 1
}
is_root || { echo "only root can start zabbix daemon."; exit 1; }
wait_pid_exit() {
    count=0
    MAX_WAIT=30
    until ! `is_running` || [ $count -gt $MAX_WAIT ]
    do
        echo -n "."
        sleep 1
        count=`expr $count + 1`
        pkill ${NAME}
    done
    if [ $count -gt $MAX_WAIT ]; then
        echo "killing it forcely after $MAX_WAIT second waiting."
        pkill -9 ${NAME}  2>/dev/null
        sleep 1
    fi
}
start() {
    sudo -u zabbix $DAEMON -c $CONFIG
}
stop() {
    pkill ${NAME}
    wait_pid_exit
}
case "$1" in
    start)
        is_running && { echo "$NAME is already running."; exit 0; }
        start
        echo "zabbix-agent started"
        ;;
    stop)
        is_running || { echo "$NAME isn't running."; exit 0; }
        stop
        echo "zabbix-agent stop"
        ;;
    status)
        if is_running; then
            echo "$NAME is runing (pid=`cat $PIDFILE`)"
        else
            echo "$NAME isn't running"
        fi
        ;;
    reload)
        echo -n "Reloading $NAME..."
        is_running || { echo "$NAME isn't running."; exit 7; }
        pid=`cat $PIDFILE`
        kill -HUP $pid
        return 0
        ;;
    restart)
        is_running && stop
        sleep 1
        start
        if is_running; then
            echo "zabbix-agentd restarted"
        else
            echo "zabbix-agentd failed to restart"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|reload}"
        exit 2
esac
##################################################################
$ chmod +x init.agent 
$ chown -R zabbix.zabbix /opt/zabbix-agent/
$ /opt/zabbix-agent/init.agent start
# 开机自启动
$ echo '/opt/zabbix-agent/init.agent start' >> /etc/rc.local 
```