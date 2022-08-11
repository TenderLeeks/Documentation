# Redis配置详解

```bash
# Redis 配置文件示例

# 注意单位: 当需要配置内存大小时, 可能需要指定像1k,5GB,4M等常见格式
#
# 1k => 1000 bytes
# 1kb => 1024 bytes
# 1m => 1000000 bytes
# 1mb => 1024*1024 bytes
# 1g => 1000000000 bytes
# 1gb => 1024*1024*1024 bytes
#
# 单位是对大小写不敏感的 1GB 1Gb 1gB 是相同的。
```

## 网络配置

```shell
# 指定redis只接收来自于该IP地址的请求，如果不进行设置，那么将处理所有请求
bind 127.0.0.1 -::1

# 是否开启保护模式，默认开启。
# 配置里没有指定bind和密码，开启该参数后，redis只会本地进行访问，拒绝外部访问。要是开启了密码和bind，可以开启。否则最好关闭，设置为 no
protected-mode yes

# redis监听的端口号
port 6379

# 此参数确定了TCP连接中已完成队列(完成三次握手之后)的长度， 当然此值必须不大于Linux系统定义的/proc/sys/net/core/somaxconn值，默认是511，而Linux的默认参数值是128。当系统并发量大并且客户端速度缓慢的时候，可以将这二个参数一起参考设定。该内核参数默认值一般是128，对于负载很大的服务程序来说大大的不够。一般会将它修改为2048或者更大。在/etc/sysctl.conf中加:net.core.somaxconn = 2048，然后在终端中执行sysctl -p
tcp-backlog 511

# 此参数为设置客户端空闲时间超过timeout，服务端会断开连接，为0则服务端不会主动断开连接，不能小于0
timeout 0

# tcp keepalive参数。如果设置不为0，就使用配置tcp的SO_KEEPALIVE值，使用keepalive有两个好处:检测挂掉的对端。降低中间设备出问题而导致网络看似连接却已经与对端端口的问题。在Linux内核中，设置了keepalive，redis会定时给对端发送ack。检测到对端关闭需要两倍的设置值。
tcp-keepalive 300

# 是否在后台执行，yes：后台运行；no：不是后台运行
daemonize yes

# redis的进程文件
pidfile /var/run/redis_6379.pid

# 指定了服务端日志的级别。级别包括：debug，verbose，notice，warn
loglevel notice

# 指定了记录日志的文件。空字符串的话，日志会打印到标准输出设备。后台运行的redis标准输出是/dev/null
logfile ""

# 数据库的数量，默认使用的数据库是0。可以通过”SELECT 【数据库序号】“命令选择一个数据库，序号从0开始
databases 16

# 是否打开记录syslog功能
syslog-enabled no

# syslog的标识符。
syslog-ident redis

# 日志的来源、设备
syslog-facility local0
```

## 快照配置

```shell
# RDB核心规则配置 save <指定时间间隔> <执行指定次数更新操作>，满足条件就将内存中的数据同步到硬盘中。官方出厂配置默认是 900秒内有1个更改，300秒内有10个更改以及60秒内有10000个更改，则将内存中的数据快照写入磁盘。若不想用RDB方案，可以把 save "" 的注释打开，下面三个注释
# save ""
save 900 1
save 300 10
save 60 10000
 
# 当RDB持久化出现错误后，是否依然进行继续进行工作，yes：不能进行工作，no：可以继续进行工作，可以通过info中的rdb_last_bgsave_status了解RDB持久化是否有错误
stop-writes-on-bgsave-error yes
 
# 配置存储至本地数据库时是否压缩数据，默认为yes。Redis采用LZF压缩方式，但占用了一点CPU的时间。若关闭该选项，但会导致数据库文件变的巨大。建议开启。
rdbcompression yes
 
# 是否校验rdb文件;从rdb格式的第五个版本开始，在rdb文件的末尾会带上CRC64的校验和。这跟有利于文件的容错性，但是在保存rdb文件的时候，会有大概10%的性能损耗，所以如果你追求高性能，可以关闭该配置
rdbchecksum yes
 
# 指定本地数据库文件名，一般采用默认的 dump.rdb
dbfilename dump.rdb
 
# 数据目录，数据库的写入会在这个目录。rdb、aof文件也会写在这个目录
dir /usr/local/redis/var
```

## 复制

```  shell
# 复制选项，slave复制对应的master。
# replicaof <masterip> <masterport>

# 如果master设置了requirepass，那么slave要连上master，需要有master的密码才行。masterauth就是用来配置master的密码，这样可以在连上master后进行认证。
# masterauth <master-password>

# 当从库同主机失去连接或者复制正在进行，从机库有两种运行方式：1) 如果slave-serve-stale-data设置为yes(默认设置)，从库会继续响应客户端的请求。2) 如果slave-serve-stale-data设置为no，INFO,replicaOF, AUTH, PING, SHUTDOWN, REPLCONF, ROLE, CONFIG,SUBSCRIBE, UNSUBSCRIBE,PSUBSCRIBE, PUNSUBSCRIBE, PUBLISH, PUBSUB,COMMAND, POST, HOST: and LATENCY命令之外的任何请求都会返回一个错误”SYNC with master in progress”。
replica-serve-stale-data yes

# 作为从服务器，默认情况下是只读的（yes），可以修改成NO，用于写（不建议）
# replica-read-only yes

# 是否使用socket方式复制数据。目前redis复制提供两种方式，disk和socket。如果新的slave连上来或者重连的slave无法部分同步，就会执行全量同步，master会生成rdb文件。有2种方式：disk方式是master创建一个新的进程把rdb文件保存到磁盘，再把磁盘上的rdb文件传递给slave。socket是master创建一个新的进程，直接把rdb文件以socket的方式发给slave。disk方式的时候，当一个rdb保存的过程中，多个slave都能共享这个rdb文件。socket的方式就的一个个slave顺序复制。在磁盘速度缓慢，网速快的情况下推荐用socket方式。
repl-diskless-sync no

# diskless复制的延迟时间，防止设置为0。一旦复制开始，节点不会再接收新slave的复制请求直到下一个rdb传输。所以最好等待一段时间，等更多的slave连上来
repl-diskless-sync-delay 5

# slave根据指定的时间间隔向服务器发送ping请求。时间间隔可以通过 repl_ping_slave_period 来设置，默认10秒。
# repl-ping-slave-period 10

# 复制连接超时时间。master和slave都有超时时间的设置。master检测到slave上次发送的时间超过repl-timeout，即认为slave离线，清除该slave信息。slave检测到上次和master交互的时间超过repl-timeout，则认为master离线。需要注意的是repl-timeout需要设置一个比repl-ping-slave-period更大的值，不然会经常检测到超时
# repl-timeout 60

# 是否禁止复制tcp链接的tcp nodelay参数，可传递yes或者no。默认是no，即使用tcp nodelay。如果master设置了yes来禁止tcp nodelay设置，在把数据复制给slave的时候，会减少包的数量和更小的网络带宽。但是这也可能带来数据的延迟。默认我们推荐更小的延迟，但是在数据量传输很大的场景下，建议选择yes
repl-disable-tcp-nodelay no

# 复制缓冲区大小，这是一个环形复制缓冲区，用来保存最新复制的命令。这样在slave离线的时候，不需要完全复制master的数据，如果可以执行部分同步，只需要把缓冲区的部分数据复制给slave，就能恢复正常复制状态。缓冲区的大小越大，slave离线的时间可以更长，复制缓冲区只有在有slave连接的时候才分配内存。没有slave的一段时间，内存会被释放出来，默认1m
# repl-backlog-size 1mb

# master没有slave一段时间会释放复制缓冲区的内存，repl-backlog-ttl用来设置该时间长度。单位为秒。
# repl-backlog-ttl 3600

# 当master不可用，Sentinel会根据slave的优先级选举一个master。最低的优先级的slave，当选master。而配置成0，永远不会被选举
replica-priority 100

# redis提供了可以让master停止写入的方式，如果配置了min-replicas-to-write，健康的slave的个数小于N，mater就禁止写入。master最少得有多少个健康的slave存活才能执行写命令。这个配置虽然不能保证N个slave都一定能接收到master的写操作，但是能避免没有足够健康的slave的时候，master不能写入来避免数据丢失。设置为0是关闭该功能
# min-replicas-to-write 3

# 延迟小于min-replicas-max-lag秒的slave才认为是健康的slave
# min-replicas-max-lag 10
 
# 设置1或另一个设置为0禁用这个特性。
# 将其中一个或另一个设置为 0 会禁用该功能。
# 默认情况下，min-replicas-to-write 设置为 0（禁用功能），min-replicas-max-lag 设置为 10。
```



## 其他

```shell
# requirepass配置可以让用户使用AUTH命令来认证密码，才能使用其他命令。这让redis可以使用在不受信任的网络中。为了保持向后的兼容性，可以注释该命令，因为大部分用户也不需要认证。使用requirepass的时候需要注意，因为redis太快了，每秒可以认证15w次密码，简单的密码很容易被攻破，所以最好使用一个更复杂的密码
# requirepass foobared

# 把危险的命令给修改成其他名称。比如CONFIG命令可以重命名为一个很难被猜到的命令，这样用户不能使用，而内部工具还能接着使用
# rename-command CONFIG b840fc02d524045429941cc15f59e41cb7be6c52
# 设置成一个空的值，可以禁止一个命令
# rename-command CONFIG ""

# 设置能连上redis的最大客户端连接数量。默认是10000个客户端连接。由于redis不区分连接是客户端连接还是内部打开文件或者和slave连接等，所以maxclients最小建议设置到32。如果超过了maxclients，redis会给新的连接发送’max number of clients reached’，并关闭连接
# maxclients 10000

# redis配置的最大内存容量。当内存满了，需要配合maxmemory-policy策略进行处理。注意slave的输出缓冲区是不计算在maxmemory内的。所以为了防止主机内存使用完，建议设置的maxmemory需要更小一些
maxmemory 122000000
# 内存容量超过maxmemory后的处理策略。
# volatile-lru：利用LRU算法移除设置过过期时间的key。
# volatile-random：随机移除设置过过期时间的key。
# volatile-ttl：移除即将过期的key，根据最近过期时间来删除（辅以TTL）
# allkeys-lru：利用LRU算法移除任何key。
# allkeys-random：随机移除任何key。
# noeviction：不移除任何key，只是返回一个写错误。
# 上面的这些驱逐策略，如果redis没有合适的key驱逐，对于写命令，还是会返回错误。redis将不再接收写请求，只接收get请求。写命令包括：set setnx setex append incr decr rpush lpush rpushx lpushx linsert lset rpoplpush sadd sinter sinterstore sunion sunionstore sdiff sdiffstore zadd zincrby zunionstore zinterstore hset hsetnx hmset hincrby incrby decrby getset mset msetnx exec sort。
# maxmemory-policy noeviction

# lru检测的样本数。使用lru或者ttl淘汰算法，从需要淘汰的列表中随机选择sample个key，选出闲置时间最长的key移除
# maxmemory-samples 5

# 是否开启salve的最大内存
# replica-ignore-maxmemory yes

# 以非阻塞方式释放内存
# 使用以下配置指令调用了
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no

# Redis 默认不开启。它的出现是为了弥补RDB的不足（数据的不一致性），所以它采用日志的形式来记录每个写操作，并追加到文件中。Redis 重启的会根据日志文件的内容将写指令从前到后执行一次以完成数据的恢复工作默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了。但是redis如果中途宕机，会导致可能有几分钟的数据丢失，根据save来策略进行持久化，Append Only File是另一种持久化方式，可以提供更好的持久化特性。Redis会把每次写入的数据在接收后都写入 appendonly.aof 文件，每次启动时Redis都会先把这个文件的数据读入内存里，先忽略RDB文件。若开启rdb则将no改为yes
appendonly no

# 指定本地数据库文件名，默认值为 appendonly.aof
appendfilename "appendonly.aof"

# aof持久化策略的配置
# no表示不执行fsync，由操作系统保证数据同步到磁盘，速度最快
# always表示每次写入都执行fsync，以保证数据同步到磁盘
# everysec表示每秒执行一次fsync，可能会导致丢失这1s数据
# appendfsync always
appendfsync everysec
# appendfsync no

#在aof重写或者写入rdb文件的时候，会执行大量IO，此时对于everysec和always的aof模式来说，执行fsync会造成阻塞过长时间，no-appendfsync-on-rewrite字段设置为默认设置为no。如果对延迟要求很高的应用，这个字段可以设置为yes，否则还是设置为no，这样对持久化特性来说这是更安全的选择。设置为yes表示rewrite期间对新写操作不fsync,暂时存在内存中,等rewrite完成后再写入，默认为no，建议yes。Linux的默认fsync策略是30秒。可能丢失30秒数据
no-appendfsync-on-rewrite no

# aof自动重写配置。当目前aof文件大小超过上一次重写的aof文件大小的百分之多少进行重写，即当aof文件增长到一定大小的时候Redis能够调用bgrewriteaof对日志文件进行重写。当前AOF文件大小是上次日志重写得到AOF文件大小的二倍（设置为100）时，自动启动新的日志重写过程。
auto-aof-rewrite-percentage 100

# 设置允许重写的最小aof文件大小，避免了达到约定百分比但尺寸仍然很小的情况还要重写
auto-aof-rewrite-min-size 64mb

# aof文件可能在尾部是不完整的，当redis启动的时候，aof文件的数据被载入内存。重启可能发生在redis所在的主机操作系统宕机后，尤其在ext4文件系统没有加上data=ordered选项（redis宕机或者异常终止不会造成尾部不完整现象。）出现这种现象，可以选择让redis退出，或者导入尽可能多的数据。如果选择的是yes，当截断的aof文件被导入的时候，会自动发布一个log给客户端然后load。如果是no，用户必须手动redis-check-aof修复AOF文件才可以
aof-load-truncated yes

# 加载redis时，可以识别AOF文件以“redis”开头。
# 字符串并加载带前缀的RDB文件，然后继续加载AOF尾巴
aof-use-rdb-preamble yes

# 如果达到最大时间限制（毫秒），redis会记个log，然后返回error。当一个脚本超过了最大时限。只有SCRIPT KILL和SHUTDOWN NOSAVE可以用。第一个可以杀没有调write命令的东西。要是已经调用了write，只能用第二个命令杀
lua-time-limit 5000

# 集群开关，默认是不开启集群模式
# cluster-enabled yes

# 集群配置文件的名称，每个节点都有一个集群相关的配置文件，持久化保存集群的信息。这个文件并不需要手动配置，这个配置文件有Redis生成并更新，每个Redis集群节点需要一个单独的配置文件，请确保与实例运行的系统中配置文件名称不冲突
# cluster-config-file nodes-6379.conf

# 节点互连超时的阀值。集群节点超时毫秒数
# cluster-node-timeout 15000

# 在进行故障转移的时候，全部slave都会请求申请为master，但是有些slave可能与master断开连接一段时间了，导致数据过于陈旧，这样的slave不应该被提升为master。该参数就是用来判断slave节点与master断线的时间是否过长。判断方法是：
# 比较slave断开连接的时间和(node-timeout * slave-validity-factor) + repl-ping-slave-period
# 如果节点超时时间为三十秒, 并且slave-validity-factor为10,假设默认的repl-ping-slave-period是10秒，即如果超过310秒slave将不会尝试进行故障转移
# cluster-replica-validity-factor 10

# master的slave数量大于该值，slave才能迁移到其他孤立master上，如这个参数若被设为2，那么只有当一个主节点拥有2 个可工作的从节点时，它的一个从节点会尝试迁移
# cluster-migration-barrier 1

# 默认情况下，集群全部的slot有节点负责，集群状态才为ok，才能提供服务。设置为no，可以在slot没有全部分配的时候提供服务。不建议打开该配置，这样会造成分区的时候，小分区的master一直在接受写请求，而造成很长时间数据不一致
# cluster-require-full-coverage yes

# *群集公告IP
# *群集公告端口
# *群集公告总线端口
# Example:
#
# cluster-announce-ip 192.168.1.111
# cluster-announce-port 6379
# cluster-announce-bus-port 6379


# slog log是用来记录redis运行中执行比较慢的命令耗时。当命令的执行超过了指定时间，就记录在slow log中，slog log保存在内存中，所以没有IO操作。
# 执行时间比slowlog-log-slower-than大的请求记录到slowlog里面，单位是微秒，所以1000000就是1秒。注意，负数时间会禁用慢查询日志，而0则会强制记录所有命令。
slowlog-log-slower-than 10000

# 慢查询日志长度。当一个新的命令被写进日志的时候，最老的那个记录会被删掉。这个长度没有限制。只要有足够的内存就行。你可以通过 SLOWLOG RESET 来释放内存
slowlog-max-len 128

# 延迟监控功能是用来监控redis中执行比较缓慢的一些操作，用LATENCY打印redis实例在跑命令时的耗时图表。只记录大于等于下边设置的值的操作。0的话，就是关闭监视。默认延迟监控功能是关闭的，如果你需要打开，也可以通过CONFIG SET命令动态设置
latency-monitor-threshold 0

# 键空间通知使得客户端可以通过订阅频道或模式，来接收那些以某种方式改动了 Redis 数据集的事件。因为开启键空间通知功能需要消耗一些 CPU ，所以在默认配置下，该功能处于关闭状态。
# notify-keyspace-events 的参数可以是以下字符的任意组合，它指定了服务器该发送哪些类型的通知：
# K 键空间通知，所有通知以 __keyspace@__ 为前缀
# E 键事件通知，所有通知以 __keyevent@__ 为前缀
# g DEL 、 EXPIRE 、 RENAME 等类型无关的通用命令的通知
# $ 字符串命令的通知
# l 列表命令的通知
# s 集合命令的通知
# h 哈希命令的通知
# z 有序集合命令的通知
# x 过期事件：每当有过期键被删除时发送
# e 驱逐(evict)事件：每当有键因为 maxmemory 政策而被删除时发送
# A 参数 g$lshzxe 的别名
# 输入的参数中至少要有一个 K 或者 E，否则的话，不管其余的参数是什么，都不会有任何 通知被分发。详细使用可以参考http://redis.io/topics/notifications
notify-keyspace-events ""

# 数据量小于等于hash-max-ziplist-entries的用ziplist，大于hash-max-ziplist-entries用hash
hash-max-ziplist-entries 512

# value大小小于等于hash-max-ziplist-value的用ziplist，大于hash-max-ziplist-value用hash
hash-max-ziplist-value 64

# -5:最大大小：64 KB<--不建议用于正常工作负载
# -4:最大大小：32 KB<--不推荐
# -3:最大大小：16 KB<--可能不推荐
# -2:最大大小：8kb<--良好
# -1:最大大小：4kb<--良好
list-max-ziplist-size -2

# 0:禁用所有列表压缩
# 1：深度1表示“在列表中的1个节点之后才开始压缩，
# 从头部或尾部
# 所以：【head】->node->node->…->node->【tail】
# [头部]，[尾部]将始终未压缩；内部节点将压缩。
# 2:[头部]->[下一步]->节点->节点->…->节点->[上一步]->[尾部]
# 2这里的意思是：不要压缩头部或头部->下一个或尾部->上一个或尾部，
# 但是压缩它们之间的所有节点。
# 3:[头部]->[下一步]->[下一步]->节点->节点->…->节点->[上一步]->[上一步]->[尾部]
list-compress-depth 0

# 数据量小于等于set-max-intset-entries用iniset，大于set-max-intset-entries用set
set-max-intset-entries 512

# 数据量小于等于zset-max-ziplist-entries用ziplist，大于zset-max-ziplist-entries用zset
zset-max-ziplist-entries 128

# value大小小于等于zset-max-ziplist-value用ziplist，大于zset-max-ziplist-value用zset
zset-max-ziplist-value 64

# value大小小于等于hll-sparse-max-bytes使用稀疏数据结构（sparse），大于hll-sparse-max-bytes使用稠密的数据结构（dense）。一个比16000大的value是几乎没用的，建议的value大概为3000。如果对CPU要求不高，对空间要求较高的，建议设置到10000左右。
hll-sparse-max-bytes 3000

# 宏观节点的最大流/项目的大小。在流数据结构是一个基数
# 树节点编码在这项大的多。利用这个配置它是如何可能#大节点配置是单字节和
# 最大项目数，这可能包含了在切换到新节点的时候
# appending新的流条目。如果任何以下设置来设置
# ignored极限是零，例如，操作系统，它有可能只是一集，通过设置限制最大#纪录到最大字节0和最大输入到所需的值
stream-node-max-bytes 4096
stream-node-max-entries 100

# Redis将在每100毫秒时使用1毫秒的CPU时间来对redis的hash表进行重新hash，可以降低内存的使用。当你的使用场景中，有非常严格的实时性需要，不能够接受Redis时不时的对请求有2毫秒的延迟的话，把这项配置为no。如果没有这么严格的实时性要求，可以设置为yes，以便能够尽可能快的释放内存
activerehashing yes

# 对客户端输出缓冲进行限制可以强迫那些不从服务器读取数据的客户端断开连接，用来强制关闭传输缓慢的客户端。
# 对于normal client，第一个0表示取消hard limit，第二个0和第三个0表示取消soft limit，normal client默认取消限制，因为如果没有寻问，他们是不会接收数据的。
client-output-buffer-limit normal 0 0 0

# 对于slave client和MONITER client，如果client-output-buffer一旦超过256mb，又或者超过64mb持续60秒，那么服务器就会立即断开客户端连接。
client-output-buffer-limit replica 256mb 64mb 60

# 对于pubsub client，如果client-output-buffer一旦超过32mb，又或者超过8mb持续60秒，那么服务器就会立即断开客户端连接
client-output-buffer-limit pubsub 32mb 8mb 60

# 这是客户端查询的缓存极限值大小
# client-query-buffer-limit 1gb

# 在redis协议中，批量请求，即表示单个字符串，通常限制为512 MB。但是您可以更改此限制。
# proto-max-bulk-len 512mb

# redis执行任务的频率为1s除以hz
hz 10

# 当启用动态赫兹时，实际配置的赫兹将用作作为基线，但实际配置的赫兹值的倍数
# 在连接更多客户端后根据需要使用。这样一个闲置的实例将占用很少的CPU时间，而繁忙的实例将反应更灵敏
dynamic-hz yes

# 在aof重写的时候，如果打开了aof-rewrite-incremental-fsync开关，系统会每32MB执行一次fsync。这对于把文件写入磁盘是有帮助的，可以避免过大的延迟峰值
aof-rewrite-incremental-fsync yes

# 在rdb保存的时候，如果打开了rdb-save-incremental-fsync开关，系统会每32MB执行一次fsync。这对于把文件写入磁盘是有帮助的，可以避免过大的延迟峰值
rdb-save-incremental-fsync yes

# 已启用活动碎片整理
# activedefrag yes
# 启动活动碎片整理的最小碎片浪费量
# active-defrag-ignore-bytes 100mb
# 启动活动碎片整理的最小碎片百分比
# active-defrag-threshold-lower 10
# 我们使用最大努力的最大碎片百分比
# active-defrag-threshold-upper 100
# 以CPU百分比表示的碎片整理的最小工作量
# active-defrag-cycle-min 5
# 在CPU的百分比最大的努力和碎片整理
# active-defrag-cycle-max 75
# 将从中处理的set/hash/zset/list字段的最大数目
# 主词典扫描
# active-defrag-max-scan-fields 1000
```



## include

```bash
################################## INCLUDES ###################################

# 可以在这里包含一个或多个其他的配置文件。如果你有一个适用于所有Redis服务器的标准配置模板
# 但也需要一些每个服务器自定义的设置，这个功能将很有用。被包含的配置文件也可以包含其他配置文件，
# 所以需要谨慎的使用这个功能。
#
# 注意“inclue”选项不能被admin或Redis哨兵的"CONFIG REWRITE"命令重写。
# 因为Redis总是使用最后解析的配置行最为配置指令的值, 你最好在这个文件的开头配置includes来
# 避免它在运行时重写配置。
# 如果相反你想用includes的配置覆盖原来的配置，你最好在该文件的最后使用include
#
# include /path/to/local.conf
# include /path/to/other.conf
```

## GENERAL

```bash
################################ GENERAL  #####################################

# 默认Rdis不会作为守护进程运行。如果需要的话配置成'yes'
# 注意配置成守护进程后Redis会将进程号写入文件/var/run/redis.pid
daemonize no

# 当以守护进程方式运行时，默认Redis会把进程ID写到 /var/run/redis.pid。你可以在这里修改路径。
pidfile /var/run/redis.pid

# 接受连接的特定端口，默认是6379
# 如果端口设置为0，Redis就不会监听TCP套接字。
port 6379

# TCP listen() backlog.
#
# 在高并发环境下你需要一个高backlog值来避免慢客户端连接问题。注意Linux内核默默地将这个值减小
# 到/proc/sys/net/core/somaxconn的值，所以需要确认增大somaxconn和tcp_max_syn_backlog
# 两个值来达到想要的效果。
tcp-backlog 511

# 默认Redis监听服务器上所有可用网络接口的连接。可以用"bind"配置指令跟一个或多个ip地址来实现
# 监听一个或多个网络接口
#
# 示例:
#
# bind 192.168.1.100 10.0.0.1
# bind 127.0.0.1

# 指定用来监听Unix套套接字的路径。没有默认值， 所以在没有指定的情况下Redis不会监听Unix套接字
#
# unixsocket /tmp/redis.sock
# unixsocketperm 755

# 一个客户端空闲多少秒后关闭连接。(0代表禁用，永不关闭)
timeout 0

# TCP keepalive.
#
# 如果非零，则设置SO_KEEPALIVE选项来向空闲连接的客户端发送ACK，由于以下两个原因这是很有用的：
#
# 1）能够检测无响应的对端
# 2）让该连接中间的网络设备知道这个连接还存活
#
# 在Linux上，这个指定的值(单位：秒)就是发送ACK的时间间隔。
# 注意：要关闭这个连接需要两倍的这个时间值。
# 在其他内核上这个时间间隔由内核配置决定
#
# 这个选项的一个合理值是60秒
tcp-keepalive 0

# 指定服务器调试等级
# 可能值：
# debug （大量信息，对开发/测试有用）
# verbose （很多精简的有用信息，但是不像debug等级那么多）
# notice （适量的信息，基本上是你生产环境中需要的）
# warning （只有很重要/严重的信息会记录下来）
loglevel notice

# 指明日志文件名。也可以使用"stdout"来强制让Redis把日志信息写到标准输出上。
# 注意:如果Redis以守护进程方式运行，而设置日志显示到标准输出的话，日志会发送到/dev/null
logfile ""

# 要使用系统日志记录器，只要设置 "syslog-enabled" 为 "yes" 就可以了。
# 然后根据需要设置其他一些syslog参数就可以了。
# syslog-enabled no

# 指明syslog身份
# syslog-ident redis

# 指明syslog的设备。必须是user或LOCAL0 ~ LOCAL7之一。
# syslog-facility local0

# 设置数据库个数。默认数据库是 DB 0，
# 可以通过select <dbid>  (0 <= dbid <= 'databases' - 1 ）来为每个连接使用不同的数据库。
databases 16
```

## SNAPSHOTTING

```bash
################################ SNAPSHOTTING  ################################
#
# 把数据库存到磁盘上:
#
#   save <seconds> <changes>
#   
#   会在指定秒数和数据变化次数之后把数据库写到磁盘上。
#
#   下面的例子将会进行把数据写入磁盘的操作:
#   900秒（15分钟）之后，且至少1次变更
#   300秒（5分钟）之后，且至少10次变更
#   60秒之后，且至少10000次变更
#
#   注意：你要想不写磁盘的话就把所有 "save" 设置注释掉就行了。
#
#   通过添加一条带空字符串参数的save指令也能移除之前所有配置的save指令
#   像下面的例子：
#   save "" 

save 900 1
save 300 10
save 60 10000

# 默认如果开启RDB快照(至少一条save指令)并且最新的后台保存失败，Redis将会停止接受写操作
# 这将使用户知道数据没有正确的持久化到硬盘，否则可能没人注意到并且造成一些灾难。
#
# 如果后台保存进程能重新开始工作，Redis将自动允许写操作
#
# 然而如果你已经部署了适当的Redis服务器和持久化的监控，你可能想关掉这个功能以便于即使是
# 硬盘，权限等出问题了Redis也能够像平时一样正常工作，
stop-writes-on-bgsave-error yes

# 当导出到 .rdb 数据库时是否用LZF压缩字符串对象？
# 默认设置为 "yes"，因为几乎在任何情况下它都是不错的。
# 如果你想节省CPU的话你可以把这个设置为 "no"，但是如果你有可压缩的key和value的话，
# 那数据文件就会更大了。
rdbcompression yes

# 因为版本5的RDB有一个CRC64算法的校验和放在了文件的最后。这将使文件格式更加可靠但在
# 生产和加载RDB文件时，这有一个性能消耗(大约10%)，所以你可以关掉它来获取最好的性能。
#
# 生成的关闭校验的RDB文件有一个0的校验和，它将告诉加载代码跳过检查
rdbchecksum yes

# 持久化数据库的文件名
dbfilename dump.rdb

# 工作目录
#
# 数据库会写到这个目录下，文件名就是上面的 "dbfilename" 的值。
# 
# 累加文件也放这里。
# 
# 注意你这里指定的必须是目录，不是文件名。
dir ./
```

## REPLICATION

```bash
################################# REPLICATION #################################
# 主从同步。通过 slaveof 指令来实现Redis实例的备份。
# 注意，这里是本地从远端复制数据。也就是说，本地可以有不同的数据库文件、绑定不同的IP、监听
# 不同的端口。
#
# slaveof <masterip> <masterport>

# 如果master设置了密码保护（通过 "requirepass" 选项来配置），那么slave在开始同步之前必须
# 进行身份验证，否则它的同步请求会被拒绝。
#
# masterauth <master-password>

# 当一个slave失去和master的连接，或者同步正在进行中，slave的行为有两种可能：
#
# 1) 如果 slave-serve-stale-data 设置为 "yes" (默认值)，slave会继续响应客户端请求，
#    可能是正常数据，也可能是还没获得值的空数据。
# 2) 如果 slave-serve-stale-data 设置为 "no"，slave会回复"正在从master同步
#   （SYNC with master in progress）"来处理各种请求，除了 INFO 和 SLAVEOF 命令。
#
slave-serve-stale-data yes

# 你可以配置salve实例是否接受写操作。可写的slave实例可能对存储临时数据比较有用(因为写入salve
# 的数据在同master同步之后将很容被删除)，但是如果客户端由于配置错误在写入时也可能产生一些问题。
#
# 从Redis2.6默认所有的slave为只读
#
# 注意:只读的slave不是为了暴露给互联网上不可信的客户端而设计的。它只是一个防止实例误用的保护层。
# 一个只读的slave支持所有的管理命令比如config,debug等。为了限制你可以用'rename-command'来
# 隐藏所有的管理和危险命令来增强只读slave的安全性
slave-read-only yes

# slave根据指定的时间间隔向master发送ping请求。
# 时间间隔可以通过 repl_ping_slave_period 来设置。
# 默认10秒。
#
# repl-ping-slave-period 10

# 以下选项设置同步的超时时间
#
# 1）slave在与master SYNC期间有大量数据传输，造成超时
# 2）在slave角度，master超时，包括数据、ping等
# 3）在master角度，slave超时，当master发送REPLCONF ACK pings
# 
# 确保这个值大于指定的repl-ping-slave-period，否则在主从间流量不高时每次都会检测到超时
#
# repl-timeout 60

# 是否在slave套接字发送SYNC之后禁用 TCP_NODELAY ？
#
# 如果你选择“yes”Redis将使用更少的TCP包和带宽来向slaves发送数据。但是这将使数据传输到slave
# 上有延迟，Linux内核的默认配置会达到40毫秒
#
# 如果你选择了 "no" 数据传输到salve的延迟将会减少但要使用更多的带宽
#
# 默认我们会为低延迟做优化，但高流量情况或主从之间的跳数过多时，把这个选项设置为“yes”
# 是个不错的选择。
repl-disable-tcp-nodelay no

# 设置数据备份的backlog大小。backlog是一个slave在一段时间内断开连接时记录salve数据的缓冲，
# 所以一个slave在重新连接时，不必要全量的同步，而是一个增量同步就足够了，将在断开连接的这段
# 时间内slave丢失的部分数据传送给它。
#
# 同步的backlog越大，slave能够进行增量同步并且允许断开连接的时间就越长。
#
# backlog只分配一次并且至少需要一个slave连接
#
# repl-backlog-size 1mb

# 当master在一段时间内不再与任何slave连接，backlog将会释放。以下选项配置了从最后一个
# slave断开开始计时多少秒后，backlog缓冲将会释放。
#
# 0表示永不释放backlog
#
# repl-backlog-ttl 3600

# slave的优先级是一个整数展示在Redis的Info输出中。如果master不再正常工作了，哨兵将用它来
# 选择一个slave提升=升为master。
#
# 优先级数字小的salve会优先考虑提升为master，所以例如有三个slave优先级分别为10，100，25，
# 哨兵将挑选优先级最小数字为10的slave。
#
# 0作为一个特殊的优先级，标识这个slave不能作为master，所以一个优先级为0的slave永远不会被
# 哨兵挑选提升为master
#
# 默认优先级为100
slave-priority 100

# 如果master少于N个延时小于等于M秒的已连接slave，就可以停止接收写操作。
#
# N个slave需要是“oneline”状态
#
# 延时是以秒为单位，并且必须小于等于指定值，是从最后一个从slave接收到的ping（通常每秒发送）
# 开始计数。
#
# This option does not GUARANTEES that N replicas will accept the write, but
# will limit the window of exposure for lost writes in case not enough slaves
# are available, to the specified number of seconds.
#
# 例如至少需要3个延时小于等于10秒的slave用下面的指令：
#
# min-slaves-to-write 3
# min-slaves-max-lag 10
#
# 两者之一设置为0将禁用这个功能。
#
# 默认 min-slaves-to-write 值是0（该功能禁用）并且 min-slaves-max-lag 值是10。
```

## SECURITY

```bash
################################## SECURITY ###################################

# 要求客户端在处理任何命令时都要验证身份和密码。
# 这个功能在有你不信任的其它客户端能够访问redis服务器的环境里非常有用。
#

# 为了向后兼容的话这段应该注释掉。而且大多数人不需要身份验证(例如:它们运行在自己的服务器上)
# 
# 警告：因为Redis太快了，所以外面的人可以尝试每秒150k的密码来试图破解密码。这意味着你需要
# 一个高强度的密码，否则破解太容易了。
#
# requirepass foobared

# 命令重命名
#
# 在共享环境下，可以为危险命令改变名字。比如，你可以为 CONFIG 改个其他不太容易猜到的名字，
# 这样内部的工具仍然可以使用，而普通的客户端将不行。
#
# 例如：
#
# rename-command CONFIG b840fc02d524045429941cc15f59e41cb7be6c52
#
# 也可以通过改名为空字符串来完全禁用一个命令
#
# rename-command CONFIG ""
#
# 请注意：改变命令名字被记录到AOF文件或被传送到从服务器可能产生问题。
```

## LIMITS

```bash
################################### LIMITS ####################################

# 设置最多同时连接的客户端数量。默认这个限制是10000个客户端，然而如果Redis服务器不能配置
# 处理文件的限制数来满足指定的值，那么最大的客户端连接数就被设置成当前文件限制数减32（因
# 为Redis服务器保留了一些文件描述符作为内部使用）
#
# 一旦达到这个限制，Redis会关闭所有新连接并发送错误'max number of clients reached'
#
# maxclients 10000

# 不要用比设置的上限更多的内存。一旦内存使用达到上限，Redis会根据选定的回收策略（参见：
# maxmemmory-policy）删除key
#
# 如果因为删除策略Redis无法删除key，或者策略设置为 "noeviction"，Redis会回复需要更
# 多内存的错误信息给命令。例如，SET,LPUSH等等，但是会继续响应像Get这样的只读命令。
#
# 在使用Redis作为LRU缓存，或者为实例设置了硬性内存限制的时候（使用 "noeviction" 策略）
# 的时候，这个选项通常事很有用的。
#
# 警告：当有多个slave连上达到内存上限的实例时，master为同步slave的输出缓冲区所需
# 内存不计算在使用内存中。这样当驱逐key时，就不会因网络问题 / 重新同步事件触发驱逐key
# 的循环，反过来slaves的输出缓冲区充满了key被驱逐的DEL命令，这将触发删除更多的key，
# 直到这个数据库完全被清空为止
# 
# 总之...如果你需要附加多个slave，建议你设置一个稍小maxmemory限制，这样系统就会有空闲
# 的内存作为slave的输出缓存区(但是如果最大内存策略设置为"noeviction"的话就没必要了)
#
# maxmemory <bytes>

# 最大内存策略：如果达到内存限制了，Redis如何选择删除key。你可以在下面五个行为里选：
# 
# volatile-lru -> 根据LRU算法生成的过期时间来删除。
# allkeys-lru -> 根据LRU算法删除任何key。
# volatile-random -> 根据过期设置来随机删除key。 
# allkeys->random -> 无差别随机删。 
# volatile-ttl -> 根据最近过期时间来删除（辅以TTL） 
# noeviction -> 谁也不删，直接在写操作时返回错误。
# 
# 注意：对所有策略来说，如果Redis找不到合适的可以删除的key都会在写操作时返回一个错误。
#

#       目前为止涉及的命令：set setnx setex append
#       incr decr rpush lpush rpushx lpushx linsert lset rpoplpush sadd
#       sinter sinterstore sunion sunionstore sdiff sdiffstore zadd zincrby
#       zunionstore zinterstore hset hsetnx hmset hincrby incrby decrby
#       getset mset msetnx exec sort
#

# 默认值如下：
#
# maxmemory-policy volatile-lru

# LRU和最小TTL算法的实现都不是很精确，但是很接近（为了省内存），所以你可以用样本量做检测。
# 例如：默认Redis会检查3个key然后取最旧的那个，你可以通过下面的配置指令来设置样本的个数。
#
# maxmemory-samples 3
```

## APPEND ONLY MODE

```bash
############################## APPEND ONLY MODE ###############################

# 默认情况下，Redis是异步的把数据导出到磁盘上。这种模式在很多应用里已经足够好，但Redis进程
# 出问题或断电时可能造成一段时间的写操作丢失(这取决于配置的save指令)。
#
# AOF是一种提供了更可靠的替代持久化模式，例如使用默认的数据写入文件策略（参见后面的配置）
# 在遇到像服务器断电或单写情况下Redis自身进程出问题但操作系统仍正常运行等突发事件时，Redis
# 能只丢失1秒的写操作。
#
# AOF和RDB持久化能同时启动并且不会有问题。
# 如果AOF开启，那么在启动时Redis将加载AOF文件，它更能保证数据的可靠性。
#
# 请查看 http://redis.io/topics/persistence 来获取更多信息.

appendonly no

# 纯累加文件名字（默认："appendonly.aof"）

appendfilename "appendonly.aof"

# fsync() 系统调用告诉操作系统把数据写到磁盘上，而不是等更多的数据进入输出缓冲区。
# 有些操作系统会真的把数据马上刷到磁盘上；有些则会尽快去尝试这么做。
#
# Redis支持三种不同的模式：
#
# no：不要立刻刷，只有在操作系统需要刷的时候再刷。比较快。
# always：每次写操作都立刻写入到aof文件。慢，但是最安全。
# everysec：每秒写一次。折中方案。 
#
# 默认的 "everysec" 通常来说能在速度和数据安全性之间取得比较好的平衡。根据你的理解来
# 决定，如果你能放宽该配置为"no" 来获取更好的性能(但如果你能忍受一些数据丢失，可以考虑使用
# 默认的快照持久化模式)，或者相反，用“always”会比较慢但比everysec要更安全。
#
# 请查看下面的文章来获取更多的细节
# http://antirez.com/post/redis-persistence-demystified.html 
# 
# 如果不能确定，就用 "everysec"

# appendfsync always
appendfsync everysec
# appendfsync no

# 如果AOF的同步策略设置成 "always" 或者 "everysec"，并且后台的存储进程（后台存储或写入AOF
# 日志）会产生很多磁盘I/O开销。某些Linux的配置下会使Redis因为 fsync()系统调用而阻塞很久。
# 注意，目前对这个情况还没有完美修正，甚至不同线程的 fsync() 会阻塞我们同步的write(2)调用。
#
# 为了缓解这个问题，可以用下面这个选项。它可以在 BGSAVE 或 BGREWRITEAOF 处理时阻止fsync()。
# 
# 这就意味着如果有子进程在进行保存操作，那么Redis就处于"不可同步"的状态。
# 这实际上是说，在最差的情况下可能会丢掉30秒钟的日志数据。（默认Linux设定）
# 
# 如果把这个设置成"yes"带来了延迟问题，就保持"no"，这是保存持久数据的最安全的方式。

no-appendfsync-on-rewrite no

# 自动重写AOF文件
# 如果AOF日志文件增大到指定百分比，Redis能够通过 BGREWRITEAOF 自动重写AOF日志文件。
# 
# 工作原理：Redis记住上次重写时AOF文件的大小（如果重启后还没有写操作，就直接用启动时的AOF大小）
# 
# 这个基准大小和当前大小做比较。如果当前大小超过指定比例，就会触发重写操作。你还需要指定被重写
# 日志的最小尺寸，这样避免了达到指定百分比但尺寸仍然很小的情况还要重写。
#
# 指定百分比为0会禁用AOF自动重写特性。

auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

################################ LUA SCRIPTING  ###############################

# Lua 脚本的最大执行时间，毫秒为单位
#
# 如果达到了最大的执行时间，Redis将要记录在达到最大允许时间之后一个脚本仍然在执行，并且将
# 开始对查询进行错误响应。
#
# 当一个长时间运行的脚本超过了最大执行时间，只有 SCRIPT KILL 和 SHUTDOWN NOSAVE 两个
# 命令可用。第一个可以用于停止一个还没有调用写命名的脚本。第二个是关闭服务器唯一方式，当
# 写命令已经通过脚本开始执行，并且用户不想等到脚本的自然终止。
#
# 设置成0或者负值表示不限制执行时间并且没有任何警告
lua-time-limit 5000
```

## SLOW LOG

```bash
################################## SLOW LOG ###################################

# Redis慢查询日志可以记录超过指定时间的查询。运行时间不包括各种I/O时间，例如：连接客户端，
# 发送响应数据等，而只计算命令执行的实际时间（这只是线程阻塞而无法同时为其他请求服务的命令执
# 行阶段）
# 
# 你可以为慢查询日志配置两个参数:一个指明Redis的超时时间(单位为微秒)来记录超过这个时间的命令
# 另一个是慢查询日志长度。当一个新的命令被写进日志的时候，最老的那个记录从队列中移除。
#
# 下面的时间单位是微秒，所以1000000就是1秒。注意，负数时间会禁用慢查询日志，而0则会强制记录
# 所有命令。
slowlog-log-slower-than 10000

# 这个长度没有限制。只是要主要会消耗内存。你可以通过 SLOWLOG RESET 来回收内存。
slowlog-max-len 128
```

## Event notification

```bash
############################# Event notification ##############################

# Redis 能通知 Pub/Sub 客户端关于键空间发生的事件
# 这个功能文档位于http://redis.io/topics/keyspace-events
#
# 例如：如果键空间事件通知被开启，并且客户端对 0 号数据库的键 foo 执行 DEL 命令时，将通过
# Pub/Sub发布两条消息：
# PUBLISH __keyspace@0__:foo del
# PUBLISH __keyevent@0__:del foo
#
# 可以在下表中选择Redis要通知的事件类型。事件类型由单个字符来标识：
#
# K    键空间通知，以__keyspace@<db>__为前缀
# E    键事件通知，以__keysevent@<db>__为前缀
# g    DEL , EXPIRE , RENAME 等类型无关的通用命令的通知, ...
# $    String命令
# l    List命令
# s    Set命令
# h    Hash命令
# z    有序集合命令
# x    过期事件（每次key过期时生成）
# e    驱逐事件（当key在内存满了被清除时生成）
# A    g$lshzxe的别名，因此”AKE”意味着所有的事件
#
# notify-keyspace-events 带一个由0到多个字符组成的字符串参数。空字符串意思是通知被禁用。
#
# 例子：启用List和通用事件通知：
# notify-keyspace-events Elg
#
# 例子2：为了获取过期key的通知订阅名字为 __keyevent@__:expired 的频道，用以下配置
# notify-keyspace-events Ex
#
# 默认所用的通知被禁用，因为用户通常不需要该特性，并且该特性会有性能损耗。
# 注意如果你不指定至少K或E之一，不会发送任何事件。
notify-keyspace-events ""
```

## ADVANCED CONFIG

```bash
# 当hash只有少量的entry时，并且最大的entry所占空间没有超过指定的限制时，会用一种节省内存的
# 数据结构来编码。可以通过下面的指令来设定限制
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# 与hash似，数据元素较少的list，可以用另一种方式来编码从而节省大量空间。
# 这种特殊的方式只有在符合下面限制时才可以用：
list-max-ziplist-entries 512
list-max-ziplist-value 64

# set有一种特殊编码的情况：当set数据全是十进制64位有符号整型数字构成的字符串时。
# 下面这个配置项就是用来设置set使用这种编码来节省内存的最大长度。
set-max-intset-entries 512

# 与hash和list相似，有序集合也可以用一种特别的编码方式来节省大量空间。
# 这种编码只适合长度和元素都小于下面限制的有序集合：
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# HyperLogLog sparse representation bytes limit. The limit includes the
# 16 bytes header. When an HyperLogLog using the sparse representation crosses
# this limit, it is converted into the dense representation.
#
# A value greater than 16000 is totally useless, since at that point the
# dense representation is more memory efficient.
# 
# The suggested value is ~ 3000 in order to have the benefits of
# the space efficient encoding without slowing down too much PFADD,
# which is O(N) with the sparse encoding. The value can be raised to
# ~ 10000 when CPU is not a concern, but space is, and the data set is
# composed of many HyperLogLogs with cardinality in the 0 - 15000 range.
hll-sparse-max-bytes 3000

# 启用哈希刷新，每100个CPU毫秒会拿出1个毫秒来刷新Redis的主哈希表（顶级键值映射表）。
# redis所用的哈希表实现（见dict.c）采用延迟哈希刷新机制：你对一个哈希表操作越多，哈希刷新
# 操作就越频繁；反之，如果服务器是空闲的，那么哈希刷新就不会完成，哈希表就会占用更多的一些
# 内存而已。
# 
# 默认是每秒钟进行10次哈希表刷新，用来刷新字典，然后尽快释放内存。
#
# 建议：
# 如果你对延迟比较在意，不能够接受Redis时不时的对请求有2毫秒的延迟的话，就用
# "activerehashing no"，如果不太在意延迟而希望尽快释放内存就设置"activerehashing yes"
activerehashing yes

# 客户端的输出缓冲区的限制，可用于强制断开那些因为某种原因从服务器读取数据的速度不够快的客户端，
# （一个常见的原因是一个发布/订阅客户端消费消息的速度无法赶上生产它们的速度）
#
# 可以对三种不同的客户端设置不同的限制：
# normal -> 正常客户端
# slave -> slave和 MONITOR 客户端
# pubsub -> 至少订阅了一个pubsub channel或pattern的客户端
#
# 下面是每个client-output-buffer-limit语法:
# client-output-buffer-limit <class><hard limit> <soft limit> <soft seconds>

# 一旦达到硬限制客户端会立即被断开，或者达到软限制并持续达到指定的秒数（连续的）。
# 例如，如果硬限制为32兆字节和软限制为16兆字节/10秒，客户端将会立即断开
# 如果输出缓冲区的大小达到32兆字节，或客户端达到16兆字节并连续超过了限制10秒，就将断开连接。
#
# 默认normal客户端不做限制，因为他们在不主动请求时不接收数据（以推的方式），只有异步客户端
# 可能会出现请求数据的速度比它可以读取的速度快的场景。
#
# pubsub和slave客户端会有一个默认值，因为订阅者和slaves以推的方式来接收数据
#
# 把硬限制和软限制都设置为0来禁用该功能
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Redis调用内部函数来执行许多后台任务，如关闭客户端超时的连接，清除未被请求过的过期Key等等。
#
# 不是所有的任务都以相同的频率执行，但Redis依照指定的“hz”值来执行检查任务。
#
# 默认情况下，“hz”的被设定为10。提高该值将在Redis空闲时使用更多的CPU时，但同时当有多个key
# 同时到期会使Redis的反应更灵敏，以及超时可以更精确地处理。
#
# 范围是1到500之间，但是值超过100通常不是一个好主意。
# 大多数用户应该使用10这个默认值，只有在非常低的延迟要求时有必要提高到100。
hz 10

# 当一个子进程重写AOF文件时，如果启用下面的选项，则文件每生成32M数据会被同步。为了增量式的
# 写入硬盘并且避免大的延迟高峰这个指令是非常有用的
aof-rewrite-incremental-fsync yes
```

