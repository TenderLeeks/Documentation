# 自建 Sentry 平台系统

[官方文档](https://develop.sentry.dev/self-hosted/)

## 下载源代码

在官方[GitHub仓库](https://github.com/getsentry/self-hosted/releases)下载最新版本源代码

```shell
$ wget https://github.com/getsentry/self-hosted/archive/refs/tags/22.7.0.tar.gz -P /tmp
```

## 安装配置

```shell
# 安装 docker
$ apt-get install -y docker.io

# 安装 docker-compose 最新版本，使用版本需要大于 v2.0
# 查看 版本：https://github.com/docker/compose/releases
# https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-linux-x86_64
$ curl -L https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose
$ chmod +x /usr/bin/docker-compose
$ docker-compose -v

$ tar -zxf /tmp/22.7.0.tar.gz -C /opt
$ cd /opt/self-hosted-22.7.0/
$ ./install.sh

# 是否创建账户
Would you like to create a user account now? [Y/n]: Y
Email: *********
Password:/usr/local/lib/python3.8/getpass.py:91: GetPassWarning: Can not control echo on the terminal.
  passwd = fallback_getpass(prompt, stream)
Warning: Password input may be echoed.
 ********
Repeat for confirmation:
Warning: Password input may be echoed.
 ********
Added to organization: sentry
Should this user have Super Admin role? (This grants them all permissions available) [y/N]: y

User created: ken.yu@aelf.io
Creating missing DSNs
Correcting Group.num_comments counter

...

-----------------------------------------------------------------

You're all done! Run the following command to get Sentry running:

  docker-compose up -d

-----------------------------------------------------------------

$ docker-compose up -d

$ docker ps
CONTAINER ID   IMAGE                                    COMMAND                  CREATED          STATUS                     PORTS                                   NAMES
24c7f700460a   nginx:1.22.0-alpine                      "/docker-entrypoint.…"   4 minutes ago    Up 2 minutes               0.0.0.0:9000->80/tcp, :::9000->80/tcp   sentry-self-hosted-nginx-1
b01fcb13f794   getsentry/relay:22.7.0                   "/bin/bash /docker-e…"   4 minutes ago    Up 2 minutes               3000/tcp                                sentry-self-hosted-relay-1
0ba69362b70f   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-cron-1
7832bfd0868d   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-ingest-consumer-1
5ea373680909   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes (healthy)     9000/tcp                                sentry-self-hosted-web-1
b14c2902e07e   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-worker-1
67ab6b5a8c0e   snuba-cleanup-self-hosted-local          "/entrypoint.sh '*/5…"   4 minutes ago    Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-cleanup-1
05fb7e5be4a9   snuba-cleanup-self-hosted-local          "/entrypoint.sh '*/5…"   4 minutes ago    Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-transactions-cleanup-1
efdeecbe05c0   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-post-process-forwarder-1
1578f4f0f826   symbolicator-cleanup-self-hosted-local   "/entrypoint.sh '55 …"   4 minutes ago    Up 4 minutes               3021/tcp                                sentry-self-hosted-symbolicator-cleanup-1
7ad0293bcf3f   maxmindinc/geoipupdate:v4.7.1            "/usr/bin/geoipupdat…"   4 minutes ago    Exited (1) 4 minutes ago                                           sentry-self-hosted-geoipupdate-1
0acf2c9c5844   sentry-cleanup-self-hosted-local         "/entrypoint.sh '0 0…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-sentry-cleanup-1
40923795fb36   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-subscription-consumer-transactions-1
126b27a5374d   sentry-self-hosted-local                 "/etc/sentry/entrypo…"   4 minutes ago    Up 3 minutes               9000/tcp                                sentry-self-hosted-subscription-consumer-events-1
efd107c0d8b9   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-transactions-consumer-1
086468f7e39e   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-outcomes-consumer-1
ee3c74b06276   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-subscription-consumer-events-1
023035a6d188   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-replacer-1
a4642ebfe93f   tianon/exim4                             "docker-entrypoint.s…"   10 minutes ago   Up 4 minutes               25/tcp                                  sentry-self-hosted-smtp-1
73f0f2917102   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-consumer-1
284e7edf93a1   memcached:1.6.9-alpine                   "docker-entrypoint.s…"   10 minutes ago   Up 4 minutes (healthy)     11211/tcp                               sentry-self-hosted-memcached-1
5bab2e42b8f1   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-sessions-consumer-1
ac48c04d648a   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-api-1
8221efcdee62   postgres:9.6                             "/opt/sentry/postgre…"   10 minutes ago   Up 4 minutes (healthy)     5432/tcp                                sentry-self-hosted-postgres-1
3c3e7c68de58   getsentry/snuba:22.7.0                   "./docker_entrypoint…"   10 minutes ago   Up 3 minutes               1218/tcp                                sentry-self-hosted-snuba-subscription-consumer-transactions-1
78e2d551c6c8   getsentry/symbolicator:0.5.1             "/bin/bash /docker-e…"   10 minutes ago   Up 4 minutes               3021/tcp                                sentry-self-hosted-symbolicator-1
033b2502cf19   confluentinc/cp-kafka:5.5.0              "/etc/confluent/dock…"   12 minutes ago   Up 3 minutes (healthy)     9092/tcp                                sentry-self-hosted-kafka-1
1e105fafcee8   confluentinc/cp-zookeeper:5.5.0          "/etc/confluent/dock…"   12 minutes ago   Up 4 minutes (healthy)     2181/tcp, 2888/tcp, 3888/tcp            sentry-self-hosted-zookeeper-1
85b535bb6f19   redis:6.2.4-alpine                       "docker-entrypoint.s…"   12 minutes ago   Up 4 minutes (healthy)     6379/tcp                                sentry-self-hosted-redis-1
1be75549c86e   clickhouse-self-hosted-local             "/entrypoint.sh"         12 minutes ago   Up 4 minutes (healthy)     8123/tcp, 9000/tcp, 9009/tcp            sentry-self-hosted-clickhouse-1
```

## 登录平台

Sentry 默认绑定到端口`9000`。

![](img/login.png)

![](img/welcome.png)



