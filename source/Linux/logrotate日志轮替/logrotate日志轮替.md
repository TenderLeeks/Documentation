# logrotate日志轮替

Logrotate 程序是一个日志文件管理工具。用于分割日志文件，压缩转存、删除旧的日志文件，并创建新的日志文件。

## Logrotate配置文件介绍
Linux系统默认安装logrotate，默认的配置文件：

- `/etc/logrotate.conf`
- `/etc/logrotate.d/`
- `logrotate.conf`：为主配置文件
- `logrotate.d`：为配置相关子系统，用于隔离每个应用配置



Logrotate是基于cron来运行的，其脚本是 `/etc/cron.daily/logrotate`，日志轮转是系统自动完成的。实际运行时，Logrotate会调用配置文件 `/etc/logrotate.conf`。可以在`/etc/logrotate.d`目录里放置自定义好的配置文件，用来覆盖Logrotate的缺省值。

```shell
$ cat /etc/cron.daily/logrotate
#!/bin/sh

# skip in favour of systemd timer
if [ -d /run/systemd/system ]; then
    exit 0
fi

# this cronjob persists removals (but not purges)
if [ ! -x /usr/sbin/logrotate ]; then
    exit 0
fi

/usr/sbin/logrotate /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit $EXITVALUE
```

如果等不及cron自动执行日志轮转，想手动强制切割日志，需要加-f参数；不过正式执行前最好通过Debug选项来验证一下（-d参数），这对调试也很重要：

```shell
$ logrotate -f /etc/logrotate.d/nginx
$ logrotate -d -f /etc/logrotate.d/nginx
```

logrotate命令格式如下：

```shell
logrotate [OPTION...] <configfile>
-d, --debug  # debug模式，测试配置文件是否有错误。
-f, --force  # 强制转储文件。
-m, --mail=command  # 压缩日志后，发送日志到指定邮箱。
-s, --state=statefile  # 使用指定的状态文件。
-v, --verbose  # 显示转储过程。
```

```shell
# 根据日志切割设置进行操作，并显示详细信息：
$ logrotate -v /etc/logrotate.conf

# 根据日志切割设置进行执行，并显示详细信息,但是不进行具体操作，debug模式
$ logrotate -d /etc/logrotate.conf

# 查看各log文件的具体执行情况
$ cat /var/lib/logrotate.status
```

## Logrotater日志文件切割策略
查看 `logrotate.conf` 配置：

```shell
$ cat /etc/logrotate.conf

weekly  # 默认每一周执行一次rotate轮转工作
su root adm  # 默认使用 adm 组，因为这是所属组
rotate 4  # 保留多少个日志文件(轮转几次).默认保留四个.就是指定日志文件删除之前轮转的次数，0 指没有备份
create  # 自动创建新的日志文件，新的日志文件具有和原来的文件相同的权限；因为日志被改名,因此要创建一个新的来继续存储之前的日志
dateext  # 这个参数很重要！就是切割后的日志文件以当前日期为格式结尾，如xxx.log-20131216这样,如果注释掉,切割出来是按数字递增,即前面说的 xxx.log-1这种格式
compress  # 是否通过gzip压缩转储以后的日志文件，如xxx.log-20131216.gz ；如果不需要压缩，注释掉就行
include /etc/logrotate.d  # 导入/etc/logrotate.d/ 目录中的各个应用配置
```

Logrotate中其他可配置参数，具体如下：

```shell
compress  # 当进行日志轮替时，对旧的日志进行gzip压缩
nocompress  # 不做gzip压缩处理
copytruncate  # 用于还在打开中的日志文件，把当前日志备份并截断；是先拷贝再清空的方式，拷贝和清空之间有一个时间差，可能会丢失部分日志数据。
nocopytruncate  # 备份日志文件不过不截断
create mode owner group  # 建立新日志，同时指定新日志的权限与所有者和所属组.如create 0600 root utmp
nocreate  # 不建立新的日志文件
delaycompress  # 和compress一起使用时，转储的日志文件到下一次转储时才压缩
nodelaycompress  # 覆盖 delaycompress 选项，转储同时压缩。
missingok  # 如果日志不存在，则忽略该日志的警告信息
errors address  # 专储时的错误信息发送到指定的Email 地址
ifempty  # 即使日志文件为空文件也做轮转，这个是logrotate的缺省选项。
notifempty  # 如果曰志为空文件，則不进行日志轮替
mail address  # 当进行日志轮替时.输出内存通过邮件发送到指定的邮件地址
nomail  # 转储时不发送日志文件
olddir directory  # 转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
noolddir  # 转储后的日志文件和当前日志文件放在同一个目录下
sharedscripts  # 运行postrotate脚本，作用是在所有日志都轮转后统一执行一次脚本。如果没有配置这个，那么每个日志轮转后都会执行一次脚本
prerotate  # 在logrotate转储之前需要执行的指令，例如修改文件的属性等动作；必须独立成行
# prerotate/cndscript	 在曰志轮替之前执行脚本命令。endscript标识prerotate脚本结束
postrotate  # 在logrotate转储之后需要执行的指令，例如重新启动 (kill -HUP) 某个服务！必须独立成行
# postrotate/endscript 在日志轮替之后执行脚本命令。endscripi标识postrotate脚本结束
daily  # 日志的轮替周期是毎天
weekly  # 日志的轮替周期是每周
monthly  # 日志的轮控周期是每月
rotate 15  # 保留的日志文件的个数。0指没有备份
dateext  # 使用日期作为日志轮替文件的后缀，如secure-20130605
dateformat .%s  # 配合dateext使用，紧跟在下一行出现，定义文件切割后的文件名，必须配合dateext使用，只支持 %Y %m %d %s 这四个参数
minsize 10M  # 日志轮替的最小值。也就是日志一定要达到这个最小值才会进行轮持，否则就算时间达到也不进行轮替
size 10M  # 日志只有大于指定大小才进行日志轮替，而不是按照时间轮替，如size 100k
# 当日志文件 >= log-size 的时候就转储。 以下为合法格式：（其他格式的单位大小写没有试过）
# size = 5 或 size 5 （>= 5 个字节就转储）
# size = 100k 或 size 100k
# size = 100M 或 size 100M
```

- prerotate 和 postrotate 主要用于在日志轮替的同时执行指定的脚本，一般用于日志轮替之后重启服务。这里强调一下，如果你的日志是写入 rsyslog 服务的配置文件的，那么把新日志加入 logrotate 后，一定要重启 rsyslog 服务，否则你会发现，虽然新日志建立了，但数据还是写入了旧的日志当中。那是因为虽然 logrotate 知道日志轮替了，但是 rsyslog 服务并不知道。

- 同理，如果采用源码包安装了 apache、Nginx 等服务，则需要重启 apache 或 Nginx 服务，同时还要重启 rsyslog 服务，否则日志也不能正常轮替。
- 不过，这里有一个典型应用就是给予特定的日志加入 chattr 的 a 属性。如果系统文件加入了 a 属性，那么这个文件就只能增加数据，而不能删除和修改已有的数据，root 用户也不例外。
- 因此，我们会给重要的日志文件加入 a 属性，这样就可以保护日志文件不被恶意修改。不过，一旦加入了 a 属性，那么在进行日志轮替时，这个日志文件是不能被改名的，当然也就不能进行日志轮替了。我们可以利用 prerotate 和 postrotate 参数来修改日志文件的 chattr 的 a 属性。

## Linux文件操作机制

目录也是文件，文件里存着文件名和对应的 inode 编号。通过这个 inode 编号可以查到文件的元数据和文件内容。文件的元数据有引用计数、操作权限、拥有者 ID、创建时间、最后修改时间等等。文件件名并不在元数据里而是在目录文件中。因此文件改名、移动，都不会修改文件，而是修改目录文件。

进程每新打开一个文件，系统会分配一个新的文件描述符给这个文件。文件描述符对应着一个文件表。表里面存着文件的状态信息（`O_APPEND`/`O_CREAT`/`O_DIRECT`…）、当前文件位置和文件的 inode 信息。系统会为每个进程创建独立的文件描述符和文件表，不同进程是不会共用同一个文件表。正因为如此，不同进程可以同时用不同的状态操作同一个文件的不同位置。文件表中存的是 inode 信息而不是文件路径，所以文件路径发生改变不会影响文件操作。

- `create`

  这也就是默认的方案，可以通过 create 命令配置文件的权限和属组设置；这个方案的思路是重命名原日志文件，创建新的日志文件。详细步骤如下：

  1. 重命名正在输出日志文件，因为重命名只修改目录以及文件的名称，而进程操作文件使用的是 inode，所以并不影响原程序继续输出日志。
  2. 创建新的日志文件，文件名和原日志文件一样，注意，此时只是文件名称一样，而 inode 编号不同，原程序输出的日志还是往原日志文件输出。
  3. 最后通过某些方式通知程序，重新打开日志文件；由于重新打开日志文件会用到文件路径而非 inode 编号，所以打开的是新的日志文件。

  如上也就是 logrotate 的默认操作方式，也就是 mv+create 执行完之后，通知应用重新在新文件写入即可。mv+create 成本都比较低，几乎是原子操作，如果应用支持重新打开日志文件，如 syslog, nginx, mysql 等，那么这是最好的方式。

  不过，有些程序并不支持这种方式，压根没有提供重新打开日志的接口；而如果重启应用程序，必然会降低可用性，为此引入了如下方式。

- `copytruncate`

  该方案是把正在输出的日志拷 (copy) 一份出来，再清空 (trucate) 原来的日志；详细步骤如下：

  1. 将当前正在输出的日志文件复制为目标文件，此时程序仍然将日志输出到原来文件中，此时，原文件名也没有变。
  2. 清空日志文件，原程序仍然还是输出到预案日志文件中，因为清空文件只把文件的内容删除了，而 inode 并没改变，后续日志的输出仍然写入该文件中。

  如上所述，对于 copytruncate 也就是先复制一份文件，然后清空原有文件。

  通常来说，清空操作比较快，但是如果日志文件太大，那么复制就会比较耗时，从而可能导致部分日志丢失。不过这种方式不需要应用程序的支持即可。

## logrotate 配置文件实例

### Nginx

```shell
$ cat /etc/logrotate.d/nginx
/var/log/nginx/*.log /var/log/nginx/*/*.log {
    daily   # 指定转储周期为每天
    compress   # 通过gzip 压缩转储以后的日志
    delaycompress  # 和compress一起使用时，转储的日志文件到下一次转储时才压缩
    rotate 7   # 保存7天的日志
    missingok  # 如果日志文件丢失，不要显示错误
    notifempty  # 当日志文件为空时，不进行轮转
    dateext  # 使用当期日期作为命名格式，exp: nginx_access.log-20190120
    create 640 root adm
    sharedscripts  # 运行postrotate脚本
    postrotate  # 执行的指令
        [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
    endscript  # 结束指令
}

/opt/nginx/logs/*.log {
    daily
    compress
    rotate 30
    missingok
    notifempty
    dateext
    create 640 root root
    sharedscripts
    postrotate
        [ ! -f /opt/nginx/logs/nginx.pid ] || kill -USR1 `cat /opt/nginx/logs/nginx.pid`
    endscript
}
```

### Zabbix-agent

```shell
$ cat /etc/logrotate.d/zabbix-agent
/var/log/zabbix/zabbix_agentd.log {
	weekly
	rotate 12
	compress
	delaycompress
	missingok
	notifempty
	create 0664 zabbix zabbix
}
```

### Apache

```shell
$ cat /etc/logrotate.d/apache 
/var/log/apache/*.log {
    su root root
    daily
    rotate 7
    missingok
    dateext
    copytruncate
    compress
}
```

### Influxdb

```shell
cat /etc/logrotate.d/influxdb
/var/log/influxdb/access.log {
    daily
    rotate 7
    missingok
    dateext
    copytruncate
    compress
}
```

### Php-fpm

```shell
$ cat /etc/logrotate.d/nginx

/usr/local/php/var/log/*.log {
daily
compress
rotate 7
missingok
notifempty
dateext
sharedscripts
postrotate
    if [ -f /usr/local/php/var/run/php-fpm.pid ]; then
        kill -USR2 `cat /usr/local/php/var/run/php-fpm.pid`
    fi
endscript
}
```

### 其他

```shell
$ cat /etc/logrotate.d/nohup
/opt/app/gateway/nohup_logs/nohup.out {
    su deploy deploy
    copytruncate
    daily
    compress
    rotate 30
    missingok
    notifempty
    dateext
}

$ cat /etc/logrotate.d/heco
/opt/heco/logs/chain.log {
    copytruncate
    daily
    compress
    rotate 30
    missingok
    notifempty
    dateext
}
```



## USR1 信号解释

USR1 亦通常被用来告知应用程序重载配置文件；例如，向 Apache HTTP 服务器发送一个 USR1 信号将导致以下步骤的发生：停止接受新的连接，等待当前连接停止，重新载入配置文件，重新打开日志文件，重启服务器，从而实现相对平滑的不关机的更改。

对于 USR1 和 2 都可以用户自定义的，在 POSIX 兼容的平台上，SIGUSR1 和 SIGUSR2 是发送给一个进程的信号，它表示了用户定义的情况。它们的符号常量在头文件 signal.h 中定义。在不同的平台上，信号的编号可能发生变化，因此需要使用符号名称。

```shell
$ kill -HUP pid
$ killall -HUP pName
```

其中 pid 是进程标识，pName 是进程的名称。

如果想要更改配置而不需停止并重新启动服务，可以使用上面两个命令。在对配置文件作必要的更改后，发出该命令以动态更新服务配置。根据约定，当你发送一个挂起信号 (信号 1 或 HUP) 时，大多数服务器进程 (所有常用的进程) 都会进行复位操作并重新加载它们的配置文件。

## Logrotater日志切割轮询
由于Logrotate是基于cron运行的，所以这个日志轮转的时间是由cron控制的，具体可以查询cron的配置文件/etc/anacrontab，过往的老版本的文件为（/etc/crontab）

查看轮转文件：`/etc/anacrontab`

```shell
$ cat /etc/anacrontab

SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
RANDOM_DELAY=45
START_HOURS_RANGE=3-22
1   5   cron.daily      nice run-parts /etc/cron.daily
7   25  cron.weekly     nice run-parts /etc/cron.weekly
@monthly 45 cron.monthly        nice run-parts /etc/cron.monthly
```

```shell
$ cat /etc/crontab 
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
```

使用anacrontab轮转的配置文件，日志切割的生效时间是在凌晨3点到22点之间，而且随机延迟时间是45分钟，但是这样配置无法满足我们在现实中的应用

现在的需求是将切割时间调整到每天的晚上12点，即每天切割的日志是前一天的0-24点之间的内容，操作如下：

```shell
$ mv /etc/anacrontab /etc/anacrontab.bak

# 使用 crontab 来作为日志轮转的触发容器来修改 Logrotate 默认执行时间
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/

# run-parts
01 * * * * root run-parts /etc/cron.hourly
59 23 * * * root run-parts /etc/cron.daily
22 4 * * 0 root run-parts /etc/cron.weekly
42 4 1 * * root run-parts /etc/cron.monthly
```



## 解决logrotate无法自动轮询日志的办法
现象说明：

使用logrotate轮询nginx日志，配置好之后，发现nginx日志连续两天没被切割，检查后确定配置文件一切正常。

强行启动记录文件维护操作，纵使logrotate指令认为没有需要，应该有可能是logroate认为nginx日志太小，不进行轮询。
故需要强制轮询，即在 `/etc/cron.daily/logrotate` 脚本中将 -t 参数替换成 -f 参数

```shell
$ cat /etc/cron.daily/logrotate 

#!/bin/sh
/usr/sbin/logrotate /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -f logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit 0

# 最后最后重启下cron服务：
$ /etc/init.d/crond restart
Stopping crond: [ OK ]
Starting crond: [ OK ]
```

## logrotate 常见问题

```shell
# 查看 logrotate 执行状态 
$ cat /var/lib/logrotate/logrotate.status

# 如果想了解执行过程可以添加 - v
$ logrotate -v /etc/logrotate.d/nginx

# 特殊情况下添加 - f 强制执行 
$ logrotate -f -v /etc/logrotate.d/nginx
```

