# Linux 系统优化

## 系统资源限制优化

```shell
$ cat /proc/sys/fs/file-nr
1440    0       811999
```

第三个数字 `811999` 就是当前系统的全局最大打开文件数(Max Open Files)

用 root 权限修改 `/etc/sysctl.conf` 文件:

```shell
$ vim /etc/sysctl.conf

fs.file-max = 1020000
net.ipv4.ip_conntrack_max = 1020000
net.ipv4.netfilter.ip_conntrack_max = 1020000

$ sysctl -p /etc/sysctl.conf

$ ulimit -n
1024
# 说明当前 Linux 系统的每一个进程只能最多打开 1024 个文件

# 临时修改
ulimit -n 1020000

# 如果不是 root, 可能不能修改超过 1024, 会报错:
# -bash: ulimit: open files: cannot modify limit: Operation not permitted

# 永久修改
# 编辑 /etc/security/limits.conf 文件, 加入如下行:

$ vim /etc/security/limits.conf
*         hard    nofile      1020000
*         soft    nofile      1020000
```

编辑`/etc/security/limits.conf`文件

```shell
root  soft  core      unlimited
root  hard  core      unlimited
root  soft  nproc     1000000
root  hard  nproc     1000000
root  soft  nofile    1000000
root  hard  nofile    1000000
root  soft  memlock   32000
root  hard  memlock   32000
root  soft  msgqueue  8192000
root  hard  msgqueue  8192000
*     soft  core      unlimited
*     hard  core      unlimited
*     soft  nproc     1000000
*     hard  nproc     1000000
*     soft  nofile    1000000
*     hard  nofile    1000000
*     soft  memlock   32000
*     hard  memlock   32000
*     soft  msgqueue  8192000
*     hard  msgqueue  8192000


```

## 内核参数优化

编辑`/etc/sysctl.conf`文件

```shell
# 1：开启严格的反向路径校验。对每个进来的数据包，校验其反向路径是否是最佳路径。如果反向路径不是最佳路径，则直接丢弃该数据包。
#  减少DDoS攻击,校验数据包的反向路径，如果反向路径不合适，则直接丢弃数据包，避免过多的无效连接消耗系统资源。
#  防止IP Spoofing,校验数据包的反向路径，如果客户端伪造的源IP地址对应的反向路径不在路由表中，或者反向路径不是最佳路径，则直接丢弃数据包，不会向伪造IP的客户端回复响应。
net.ipv4.conf.default.rp_filter = 1
# 监听非本机, 避免切换VIP后在启动服务, 用户就会中断请求。
net.ipv4.ip_nonlocal_bind = 1
# 转发
net.ipv4.ip_forward = 1
#处理无源路由的包
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
# tcp_syncookies是一个开关，是否打开SYN Cookie功能，该功能可以防止部分SYN攻击。tcp_synack_retries和tcp_syn_retries定义SYN的重试次数。
net.ipv4.tcp_syncookies = 1
# docker
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
# docker运行时，需要设置为1
fs.may_detach_mounts = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
# net.core.somaxconn 是Linux中的一个kernel参数，表示socket监听（listen）的backlog上限。什么是backlog呢？backlog就是socket的监听队列，当一个请求（request）尚未被处理或建立时，他会进入backlog。而socket server可以一次性处理backlog中的所有请求，处理后的请求不再位于监听队列中。当server处理请求较慢，以至于监听队列被填满后，新来的请求会被拒绝。 
net.core.somaxconn = 20480
net.core.optmem_max = 81920
# tcp_max_syn_backlog 进入SYN包的最大请求队列.默认1024.对重负载服务器,增加该值显然有好处.
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 15
# 在使用 iptables 做 nat 时，发现内网机器 ping 某个域名 ping 的通，而使用 curl 测试不通, 原来是 net.ipv4.tcp_timestamps 设置了为 1 ，即启用时间戳
net.ipv4.tcp_timestamps = 0
# tw_reuse 只对客户端起作用，开启后客户端在1s内回收
net.ipv4.tcp_tw_reuse = 1
# recycle 同时对服务端和客户端启作用。如果服务端断开一个NAT用户“可能”会影响。 当TIMEOUT状态过多时，建议启用
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 1
# Nginx 之类的中间代理一定要关注这个值，因为它对你的系统起到一个保护的作用，一旦端口全部被占用，服务就异常了。 tcp_max_tw_buckets 能帮你降低这种情况的发生概率，争取补救时间。
net.ipv4.tcp_max_tw_buckets = 20000
# 这个值表示系统所能处理不属于任何进程的socket数量，当我们需要快速建立大量连接时，就需要关注下这个值了。 
net.ipv4.tcp_max_orphans = 327680
# 15. 现大量fin-wait-1
#首先，fin发送之后，有可能会丢弃，那么发送多少次这样的fin包呢？fin包的重传，也会采用退避方式，在2.6.358内核中采用的是指数退避，2s，4s，最后的重试次数是由
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syncookies = 1
# KeepAlive的空闲时长，或者说每次正常发送心跳的周期，默认值为7200s（2小时）
net.ipv4.tcp_keepalive_time = 300
# KeepAlive探测包的发送间隔，默认值为75s
net.ipv4.tcp_keepalive_intvl = 30
# 在tcp_keepalive_time之后，没有接收到对方确认，继续发送保活探测包次数，默认值为9（次）
net.ipv4.tcp_keepalive_probes = 3
# 允许超载使用内存，避免内存快到极限报错
# overcommit_memory 0 redis启动前向内核申请maxmemory, 够ok. 不够error.
# 1  redis启动前向内核申请maxmemory,内核不统计内存是否够用, 允许分配redis使用全部内存。
# 2  redis启动前向内核申请maxmemory,内核允许redis使用全部内存+swap空间内存。
vm.overcommit_memory = 1
#
# 0,内存不足启动oom killer. 1内存不足,kernel panic(系统重启) 或oom. 2. 内存不足, 强制kernel panic. (系统重启) 
vm.panic_on_oom=0
vm.swappiness = 10
#net.ipv4.conf.eth1.rp_filter = 0
#net.ipv4.conf.lo.arp_ignore = 1
#net.ipv4.conf.lo.arp_announce = 2
#net.ipv4.conf.all.arp_ignore = 1
#net.ipv4.conf.all.arp_announce = 2
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
# 随机端口的范围
net.ipv4.ip_local_port_range = 10001 65000

# inotify监听文件数量
fs.inotify.max_user_watches=89100

# 文件打开数量
# 所有进程 
fs.file-max=52706963
# 单个进程
fs.nr_open=52706963


```

此参数确定了TCP连接中已完成队列(完成三次握手之后)的长度， 当然此值必须不大于Linux系统定义的`/proc/sys/net/core/somaxconn`值，默认是511，而Linux的默认参数值是128。当系统并发量大并且客户端速度缓慢的时候，可以将这二个参数一起参考设定。该内核参数默认值一般是128，对于负载很大的服务程序来说大大的不够。一般会将它修改为2048或者更大。在`/etc/sysctl.conf`中加:`net.core.somaxconn = 2048`，然后在终端中执行`sysctl -p`



测试系统是否支持百万连接的工具：https://github.com/ideawu/c1000k
