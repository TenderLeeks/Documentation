# Redis 介绍

## redis是什么？

Redis是一个开源（BSD许可），内存存储的数据结构服务器，可用作数据库，高速缓存和消息队列代理。它支持字符串、哈希表、列表、集合、有序集合，位图，hyperloglogs等数据类型。内置复制、Lua脚本、LRU收回、事务以及不同级别磁盘持久化功能，同时通过Redis Sentinel提供高可用，通过Redis Cluster提供自动分区。

Redis是一个开源的使用ANSI C语言编写、遵守BSD协议、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。

## 为什么使用redis？

**redis的特点**

1. Redis支持数据的持久化，可以将内存中的数据保持在磁盘中，重启的时候可以再次加载进行使用。
2. Redis不仅仅支持简单的key-value类型的数据，同时还提供list，set，zset，hash等数据结构的存储。
3. Redis支持数据的备份，即master-slave模式的数据备份。

**redis的优势**

1. 性能极高 – Redis能读的速度是110000次/s,写的速度是81000次/s 。
2. 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
3. 原子 – Redis的所有操作都是原子性的，同时Redis还支持对几个操作全并后的原子性执行。
4. 丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性。

**redis与其他key-value存储有什么不同**

1. Redis有着更为复杂的数据结构并且提供对他们的原子性操作，Redis的数据类型都是基于基本数据结构的同时对程序员透明，无需进行额外的抽象。
2. Redis运行在内存中但是可以持久化到磁盘，所以在对不同数据集进行高速读写时需要权衡内存，应为数据量不能大于硬件内存。
3. 相比在磁盘上相同的复杂的数据结构，在内存中操作起来非常简单，这样Redis可以做很多内部复杂性很强的事情。
4. 在磁盘格式方面他们是紧凑的以追加的方式产生的，因为他们并不需要进行随机访问。

## 如何使用redis？

**redis的数据类型**

<table border="1" cellpadding="10" cellspacing="10">
  <thead>
    <tr><th>数据类型</th><th>概念</th><th>常用命令</th></tr>
  </thead>
    <tbody>
      <tr><td>String(字符串)</td><td>key-value型</td><td>SET ，GET</td></tr>
      <tr><td>Hash(哈希)</td><td>field-value,适用于存储对象类型（对象名-对象属性值）</td><td>HMSET，HEGTALL</td></tr>
      <tr><td>List(列表)</td><td>string类型的有序列表，按照插入顺序排序</td><td>lpush，lrange</td></tr>
      <tr><td>Set(集合)</td><td>string类型的无序集合</td><td>sadd，smembers</td></tr>
      <tr><td>zset(sorted set：有序集合)</td><td>string类型元素的集合,且不允许重复的成员。每个元素关联一个double值来进行排序，double值可以重复但元素不能重复。</td><td>zadd，ZRANGEBYSCORE</td></tr>
  </tbody>
</table>

## Redis数据持久化、数据备份、数据的故障恢复

### redis持久化的意义----redis故障恢复

- 在实际的生产环境中，很可能会遇到redis突然挂掉的情况，比如redis的进程死掉了、电缆被施工队挖了（支付宝例子）等等，总之一定会遇到各种奇葩的现象导致redis死掉，这时候放在redis内存中的数据就会全部丢失，这些数据可能服务很多的系统或者服务，当然，我们可以重新启动redis，重启之后，如果redis没有持久化，redis中的数据就会全部丢失。

- 如果通过持久化将数据搞一份到磁盘，然后定期的同步和备份到云存储服务上去，那么就可以保证数据不会全部丢失，还是可以恢复一部分数据的。

### 持久化的两大机制（RDB和AOF）

- RDB：对redis数据执行周期性的持久化

- AOF:将每条命令写入日志，以append-only的模式写入一个日志文件中，在redis重启的时候，可以通过回放AOF的写入指令来重新构建整个数据集

- 是否实用持久化要看具体的业务场景：

- 如果只是想让redis仅仅作为纯内存的缓存，那么可以禁止RDB和AOF。

- 故障恢复大致思路：

  通过RDB或AOF，都可以将redis内存中的数据持久化到磁盘上来，然后可以将数据备份到阿里云，如果redis挂了，服务器中内存和磁盘的数据就都丢了，这时候可以将阿里云中的备份文件拷贝至指定目录下，然后重启redis，redis就会自动根据持久化数据文件去恢复内存中的数据，继续对外提供服务。如果同时室友了RDB和AOF两种持久化机制，那么在重启的时间建议使用AOF的方式重新构建数据，因为AOF中的数据更加完整。

### 剖析RDB和AOF

- RDB：早上7点，这个时候redis 中有500条数据，这个时候redis会在一定周期内生成一个RDB快照文件，等到了9点的时候redis中有8000条数据，这个时候又在一定的周期内生成了另一个RDB快照文件，这就是RDB持久化机制。
- AOF：redis 中每写入一条指令，就会把这条指令更新到磁盘中的文件中。然而在现代操作系统中，写文件不是直接写磁盘，会先写进os cache，然后在一定时间内再从os cache刷入disk file，对于AOF来说每隔一秒（可配置）调用一次操作系统饿fsync操作强制将os cache中的数据刷入磁盘文件中。但是redis内存中的数据也不是无限增长的，它是定期的根据LRU算法清理一些不常用的数据，这样才能保证AOF不会无限增长，但是如果LRU的清理速度比不上AOF的膨胀速度的时候，这时候当AOF大到一定程度就会进行AOF rewrite操作。AOF rewrite操作就会基于当时redis内存中的数据来重新构造一个更小的AOF文件，然后将旧的AOF文件删除。
- 简单的说，假设redis限定了只能存放10G数据，这时候不断的在redis中写入数据，当达到了10G的数据量的时候，这时候根据LRU清理了一些不常用的数据，清理了5G，这时候又写了5G，这时候AOF文件记录了15G的数据相关的写入指令，假如这个时候AOF已经膨胀了，这个时候redis进行AOF rewrite操作，重新生成了一个新的10G的数据指令的AOF文件，这个时候将继续写入新的AOF文件，将老的AOF文件删除。

### RDB和AOF优缺点

#### RDB优点

- RDB会生成多个数据文件，每个数据文件都代表了某一个时刻中redis的数据，这种多个数据文件的方式，非常适合做冷备，可以将这种完整的数据文件发送到一些远程的安全存储上去，比如阿里云的ODPS分布式存储上，以预定好的备份策略来定期备份redis中的数据。
  - RDB做冷备，生成多个文件，每个文件都代表了某一个时刻的完整的数据快照
  - AOF也可以做冷备，只有一个文件，但是你可以，每隔一定时间，去copy一份这个文件出来
  - 但是RDB更适合做冷备，它的优势是由redis去控制固定时长生成快照文件的事情，比较方便; AOF，还需要自己写一些脚本去做这个事情，需要自己写定时脚本，而且RDB数据做冷备，在最坏的情况下，提供数据恢复的时候，速度比AOF快

- RDB对redis对外提供的读写服务，影响非常小，可以让redis保持高性能，因为redis主进程只需要fork一个子进程，让子进程执行磁盘IO操作来进行RDB持久化即可
  - RDB，每次写，都是直接写redis内存，只是在一定的时候，才会将数据写入磁盘中
  - AOF，每次都是要写文件的，虽然可以快速写入os cache中，但是还是有一定的时间开销的,速度肯定比RDB略慢一些

- 相对于AOF持久化机制来说，直接基于RDB数据文件来重启和恢复redis进程，更加快速

#### RDB缺点

- 如果想要在redis故障时，尽可能少的丢失数据，那么RDB没有AOF好。一般来说，RDB数据快照文件，都是每隔5分钟，或者更长时间生成一次，这个时候就得接受一旦redis进程宕机，那么会丢失最近5分钟的数据，这也是rdb最大的缺点，就是不适合做第一优先的恢复方案，如果你依赖RDB做第一优先恢复方案，会导致数据丢失的比较多。
- RDB每次在fork子进程来执行RDB快照数据文件生成的时候，如果数据文件特别大，可能会导致对客户端提供的服务暂停数毫秒，或者甚至数秒，所以一般不要让RDB的间隔太长，否则每次生成的RDB文件太大了，对redis本身的性能可能会有影响的

#### AOF优点

- AOF可以更好的保护数据不丢失，一般AOF会每隔1秒，通过一个后台线程执行一次fsync操作，最多丢失1秒钟的数据,每隔1秒，就执行一次fsync操作，保证os cache中的数据写入磁盘中，redis进程挂了，最多丢掉1秒钟的数据。
- AOF日志文件以append-only模式写入，所以没有任何磁盘寻址的开销，写入性能非常高，而且文件不容易破损，即使文件尾部破损，也很容易修复。
- AOF日志文件即使过大的时候，出现后台重写操作，也不会影响客户端的读写。因为在rewrite log的时候，会对其中的内容进行压缩，创建出一份需要恢复数据的最小日志出来。再创建新日志文件的时候，老的日志文件还是照常写入。当新的merge后的日志文件ready的时候，再交换新老日志文件即可。
- AOF日志文件的命令通过可读的方式进行记录，这个特性非常适合做灾难性的误删除的紧急恢复。比如某人不小心用flushall命令清空了所有数据，只要这个时候后台rewrite还没有发生，那么就可以立即拷贝AOF文件，将最后一条flushall命令给删了，然后再将该AOF文件放回去，就可以通过恢复机制，自动恢复所有数据

#### AOF缺点

- 对于同一份数据来说，AOF日志文件通常比RDB数据快照文件更大
- AOF开启后，支持的写QPS会比RDB支持的写QPS低，因为AOF一般会配置成每秒fsync一次日志文件，当然，每秒一次fsync，性能也还是很高的，如果你要保证一条数据都不丢，也是可以的，AOF的fsync设置成没写入一条数据，fsync一次，那就完蛋了，redis的QPS大降。
- 以前AOF发生过bug，就是通过AOF记录的日志，进行数据恢复的时候，没有恢复一模一样的数据出来。所以说，类似AOF这种较为复杂的基于命令日志/merge/回放的方式，比基于RDB每次持久化一份完整的数据快照文件的方式，更加脆弱一些，容易有bug。不过AOF就是为了避免rewrite过程导致的bug，因此每次rewrite并不是基于旧的指令日志进行merge的，而是基于当时内存中的数据进行指令的重新构建，这样健壮性会好很多。
- 唯一的比较大的缺点，其实就是做数据恢复的时候，会比较慢，还有做冷备，定期的备份，不太方便，可能要自己手写复杂的脚本去做，做冷备不太合适

#### AOF和RDB数据恢复机制

- AOF，存放的指令日志，做数据恢复的时候，其实是要回放和执行所有的指令日志，来恢复出来内存中的所有数据的
- RDB，就是一份数据文件，恢复的时候，直接加载到内存中即可
- 无论是AOF和RDB，在redis中都以一个文件的形式存在！！！

### RDB和AOF如何选择

- 不要仅仅使用RDB，因为那样会导致你丢失很多数据
- 也不要仅仅使用AOF，因为那样有两个问题，第一，你通过AOF做冷备，没有RDB做冷备，来的恢复速度更快; 第二，RDB每次简单粗暴生成数据快照，更加健壮，可以避免AOF这种复杂的备份和恢复机制的bug
- 综合使用AOF和RDB两种持久化机制，用AOF来保证数据不丢失，作为数据恢复的第一选择; 用RDB来做不同程度的冷备，在AOF文件都丢失或损坏不可用的时候，还可以使用RDB来进行快速的数据恢复

### 如何配置RDB持久化

- redis.conf文件，也就是/etc/redis/6379.conf，去配置持久化
  - 例如：save 60 1000
  - (每隔60s，如果有超过1000个key发生了变更，那么就生成一个新的dump.rdb文件，就是当前redis内存中完整的数据快照，这个操作也被称之为snapshotting，快照
  - 也可以手动调用save或者bgsave命令，同步或异步执行rdb快照生成)
- save可以设置多个，就是多个snapshotting检查点，每到一个检查点，就会去check一下，是否有指定的key数量发生了变更，如果有，就生成一个新的dump.rdb文件

### RDB持久化机制的工作流程

- redis根据配置自己尝试去生成rdb快照文件，fork一个子进程出来，子进程尝试将数据dump到临时的rdb快照文件中，完成rdb快照文件的生成之后，就替换之前的旧的快照文件，dump.rdb，每次生成一个新的快照，都会覆盖之前的老快照。

### 基于RDB持久化机制的数据恢复实验

- 在redis中保存几条数据，立即停掉redis进程，然后重启redis，看看刚才插入的数据还在不在
- 在redis中再保存几条新的数据，用kill -9粗暴杀死redis进程，模拟redis故障异常退出，导致内存数据丢失的场景
- 注意：通过redis-cli SHUTDOWN这种方式去停掉redis，其实是一种安全退出的模式，redis在退出的时候会将内存中的数据立即生成一份完整的rdb快照

### 如何配置AOF持久化

- AOF持久化，默认是关闭的，默认是打开RDB持久化
- appendonly yes，可以打开AOF持久化机制，在生产环境里面，一般来说AOF都是要打开的，除非你说随便丢个几分钟的数据也无所谓，打开AOF持久化机制之后，redis每次接收到一条写命令，就会写入日志文件中，当然是先写入os cache的，然后每隔一定时间再fsync一下，而且即使AOF和RDB都开启了，redis重启的时候，也是优先通过AOF进行数据恢复的，因为aof数据比较完整
- 可以配置AOF的fsync策略，有三种策略可以选择，一种是每次写入一条数据就执行一次fsync; 一种是每隔一秒执行一次fsync; 一种是不主动执行fsync
  - always: 每次写入一条数据，立即将这个数据对应的写日志fsync到磁盘上去，性能非常非常差，吞吐量很低; 确保说redis里的数据一条都不丢，那就只能这样了
  - everysec: 每秒将os cache中的数据fsync到磁盘，这个最常用的，生产环境一般都这么配置，性能很高，QPS还是可以上万的
  - no: 仅仅redis负责将数据写入os cache就撒手不管了，然后后面os自己会时不时有自己的策略将数据刷入磁盘，不可控了

### AOF持久化的数据恢复实验

- 先仅仅打开RDB，写入一些数据，然后kill -9杀掉redis进程，接着重启redis，发现数据没了，因为RDB快照还没生成
- 打开AOF的开关，启用AOF持久化
- 写入一些数据，观察AOF文件中的日志内容
- kill -9杀掉redis进程，重新启动redis进程，发现数据被恢复回来了，就是从AOF文件中恢复回来的(redis进程启动的时候，直接就会从appendonly.aof中加载所有的日志，把内存中的数据恢复回来)
- 注意：在appendonly.aof文件中，可以看到刚写的日志，它们其实就是先写入os cache的，然后1秒后才fsync到磁盘中，只有fsync到磁盘中了，才是安全的，要不然光是在os cache中，机器只要重启，就什么都没了

### AOF rewrite

AOF工作原理

- redis fork一个子进程
- 子进程基于当前内存中的数据，构建日志，开始往一个新的临时的AOF文件中写入日志
- redis主进程，接收到client新的写操作之后，在内存中的数据继续写入新日志到AOF文件中，同时新的数据也继续写入旧的AOF文件
- redis主进程将内存中的新写进去的日志再次追加到新的AOF文件中
- 用新的日志文件替换掉旧的日志文件


redis中的数据其实有限的，很多数据可能会自动过期，可能会被用户删除，可能会被redis用缓存清除的算法清理掉，redis中的数据会不断淘汰掉旧的，就一部分常用的数据会被自动保留在redis内存中，所以可能很多之前的已经被清理掉的数据，对应的写日志还停留在AOF中，AOF日志文件就一个，会不断的膨胀，到很大很大，所以AOF会自动在后台每隔一定时间做rewrite操作，比如日志里已经存放了针对100w数据的写日志了; redis内存只剩下10万; 基于内存中当前的10万数据构建一套最新的日志，到AOF中; 覆盖之前的老日志; 确保AOF日志文件不会过大，保持跟redis内存数据量一致

redis 2.4之前，还需要手动，开发一些脚本，crontab，通过BGREWRITEAOF命令去执行AOF rewrite，但是redis 2.4之后，会自动进行rewrite操作

注意：

- 在redis.conf中，可以配置rewrite策略
  auto-aof-rewrite-percentage 100 
  auto-aof-rewrite-min-size 64mb
- 比如说上一次AOF rewrite之后，是128mb，然后就会接着128mb继续写AOF的日志，如果发现增长的比例，超过了之前的100%，也就是256mb，就可能会去触发一次rewrite，但是此时还要去跟min-size，64mb去比较，256mb > 64mb，才会去触发rewrite

### AOF破损文件的修复

如果redis在append数据到AOF文件时，机器宕机了，可能会导致AOF文件破损，用redis-check-aof --fix命令来修复破损的AOF文件。

### AOF和RDB同时工作

- 如果RDB在执行snapshotting操作，那么redis不会执行AOF rewrite; 如果redis再执行AOF rewrite，那么就不会执行RDB snapshotting
- 如果RDB在执行snapshotting，此时用户执行BGREWRITEAOF命令，那么等RDB快照生成之后，才会去执行AOF rewrite
- 同时有RDB snapshot文件和AOF日志文件，那么redis重启的时候，会优先使用AOF进行数据恢复，因为其中的日志更完整

### 企业级的持久化的配置策略

- 企业中，RDB的生成策略，用默认的也差不多
- save 60 10000：如果你希望尽可能确保说，RDB最多丢1分钟的数据，那么尽量就是每隔1分钟都生成一个快照，低峰期，数据量很少，也没必要
- AOF一定要打开，fsync，everysec
- auto-aof-rewrite-percentage 100: 就是当前AOF大小膨胀到超过上次100%，上次的两倍       
- auto-aof-rewrite-min-size 64mb: 根据你的数据量来定，16mb，32mb

### 企业级的数据备份方案

- 写crontab定时调度脚本去做数据备份
- 每小时都copy一份rdb的备份，到一个目录中去，仅仅保留最近48小时的备份
- 每天都保留一份当日的rdb的备份，到一个目录中去，仅仅保留最近1个月的备份
- 每次copy备份的时候，都把太旧的备份给删了
- 每天晚上将当前服务器上所有的数据备份，发送一份到远程的云服务上去

按小时和按天同时备份

每小时copy一次备份，删除48小时前的数据

```shell
$ crontab -l
0 * * * * sh /usr/local/redis/copy/redis_rdb_copy_hourly.sh

$ cat redis_rdb_copy_hourly.sh
#!/bin/sh 
cur_date=`date +%Y%m%d%k`
rm -rf /usr/local/redis/snapshotting/$cur_date
mkdir /usr/local/redis/snapshotting/$cur_date
cp /var/redis/6379/dump.rdb /usr/local/redis/snapshotting/$cur_date
del_date=`date -d -48hour +%Y%m%d%k`
rm -rf /usr/local/redis/snapshotting/$del_date

# 每天copy一次备份
$ crontab -l
0 0 * * * sh /usr/local/redis/copy/redis_rdb_copy_daily.sh
$ cat redis_rdb_copy_daily.sh
#!/bin/sh 
cur_date=`date +%Y%m%d`
rm -rf /usr/local/redis/snapshotting/$cur_date
mkdir /usr/local/redis/snapshotting/$cur_date
cp /var/redis/6379/dump.rdb /usr/local/redis/snapshotting/$cur_date
del_date=`date -d -1month +%Y%m%d`
rm -rf /usr/local/redis/snapshotting/$del_date
```

 每天一次将所有数据上传一次到远程的云服务器上去

### 企业级数据恢复方案

- 如果是redis进程挂掉，那么重启redis进程即可，直接基于AOF日志文件恢复数据
- 如果是redis进程所在机器挂掉，那么重启机器后，尝试重启redis进程，尝试直接基于AOF日志文件进行数据恢复，前提是AOF没有破损，AOF append-only，顺序写入，如果AOF文件破损，那么用redis-check-aof fix修复。
- 如果redis当前最新的AOF和RDB文件出现了丢失/损坏，那么可以尝试基于该机器上当前的某个最新的RDB数据副本进行数据恢复，当前最新的AOF和RDB文件都出现了丢失/损坏到无法恢复，一般不是机器的故障，而是人为。

### 容灾演练

appendonly.aof + dump.rdb，优先用appendonly.aof去恢复数据。

- 如果关闭AOF持久化机制，并且dump.rdb是有数据的，这时候重启redis，发现内存中明显没有恢复数据。
  - 原因：redis启动的时候，自动重新基于内存的数据，生成了一份最新的rdb快照，直接用空的数据，覆盖掉了我们有数据的dump.rdb
- 如果打开AOF，停止redis之后，先删除appendonly.aof，然后将我们的dump.rdb拷贝过去，然后再重启redis，发现依然没有恢复数据
  - 原因：虽然你删除了appendonly.aof，但是因为打开了aof持久化，redis就一定会优先基于aof去恢复，即使文件不在，那就创建一个新的空的aof文件
- 停止redis，暂时在配置中关闭aof，然后拷贝一份rdb过来，再重启redis，这时候内存中的数据恢复成功；假如不小心，再关掉redis，手动修改配置文件，打开aof，再重启redis，数据又没了，因为是空的aof文件，所以所有数据又没了。
  - 在数据安全丢失的情况下，基于rdb冷备，如何完美的恢复数据，同时还保持aof和rdb的双开?
- 停止redis，关闭aof，拷贝rdb备份，重启redis，确认数据恢复，直接在命令行热修改redis配置，打开aof，这个redis就会将内存中的数据对应的日志，写入aof文件中，此时aof和rdb两份数据文件的数据就同步了。
  - 注意：redis config set热修改配置参数，可能配置文件中的实际的参数没有被持久化的修改，再次停止redis，手动修改配置文件，打开aof的命令，再次重启redis
- 如果当前机器上的所有RDB文件全部损坏，那么从远程的云服务上拉取最新的RDB快照回来恢复数据
- 如果是发现有重大的数据错误，比如某个小时上线的程序一下子将数据全部污染了，数据全错了，那么可以选择某个更早的时间点，对数据进行恢复
  - 举个例子，12点上线了代码，发现代码有bug，导致代码生成的所有的缓存数据，写入redis，全部错了，找到一份11点的rdb的冷备，然后按照上面的步骤，去恢复到11点的数据。



[参考文档](https://www.cnblogs.com/z-3FENG/articles/9591784.html)
