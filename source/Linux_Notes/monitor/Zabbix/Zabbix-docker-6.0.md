# 使用Docker安装Zabbix 6.0

最新版本安装请参照[Zabbix官方文档](https://www.zabbix.com/documentation/current/zh/manual/installation)

## 安装环境配置

```shell
$ zabbix_pwd="3ZBTY4UjYXxb8J9j" && \
  root_pwd="2wApkfuGQycTjxsnwVLs" && \
  zabbix_server_name="Hoopox Zabbix Server" && \
  server_dir="/opt/zabbix" && \
  mkdir -p ${server_dir}/server/{alertscripts,externalscripts,modules} && \
  mkdir -p ${server_dir}/agent2/modules
```

## 创建专用网络

创建专用于 Zabbix 组件容器的网络

```shell
$ docker network create --subnet 172.20.0.0/16 \
  --ip-range 172.20.100.0/20 zabbix-net
```

## 启动MySQL服务实例

启动空的`MySQL`服务器实例

```shell
$ docker run -v /etc/localtime:/etc/localtime \
      --name mysql-server -t \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD=${zabbix_pwd} \
      -e MYSQL_ROOT_PASSWORD=${root_pwd} \
      --network=zabbix-net \
      --restart unless-stopped \
      -d mysql:8.0 \
      --character-set-server=utf8 --collation-server=utf8_bin \
      --default-authentication-plugin=mysql_native_password
```

## 启动 Zabbix Java 网关实例

```shell
$ docker run -v /etc/localtime:/etc/localtime \
      --name zabbix-java-gateway -t \
      --network=zabbix-net \
      --restart unless-stopped \
      -d zabbix/zabbix-java-gateway:ubuntu-6.0-latest
```

## 启动 Zabbix Web Service 服务

[参考文档](https://github.com/zabbix/zabbix-docker/tree/6.2/Dockerfiles/web-service/ubuntu)

```shell
$ docker run -v /etc/localtime:/etc/localtime \
      --name zabbix-web-service -t \
      -e ZBX_ALLOWEDIP="zabbix-server-mysql" \
      -v /opt/zabbix/web-service:/etc/zabbix \
      --cap-add=SYS_ADMIN --network=zabbix-net \
      -d zabbix/zabbix-web-service:ubuntu-6.0-latest
```



## 启动 Zabbix server 实例

启动`Zabbix server`实例，并将其关联到已创建的`MySQL server`实例

```shell
# /var/lib/docker/volumes/zabbix-server-volume
$ docker volume create zabbix-server-volume
$ docker run -v /etc/localtime:/etc/localtime \
      --name zabbix-server-mysql -t \
      --link zabbix-web-service:zabbix-web-service \
      -e DB_SERVER_HOST="mysql-server" \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD=${zabbix_pwd} \
      -e MYSQL_ROOT_PASSWORD=${root_pwd} \
      -e ZBX_JAVAGATEWAY="zabbix-java-gateway" \
      -e ZBX_STARTREPORTWRITERS="2" \
      -e ZBX_WEBSERVICEURL="http://zabbix-web-service:10053/report" \
      -v zabbix-server-volume:/etc/zabbix \
      -v ${server_dir}/server/alertscripts:/usr/lib/zabbix/alertscripts \
      -v ${server_dir}/server/externalscripts:/usr/lib/zabbix/externalscripts \
      -v ${server_dir}/server/modules:/usr/lib/zabbix/modules \
      --network=zabbix-net \
      -p 10051:10051 \
      --restart unless-stopped \
      -d zabbix/zabbix-server-mysql:ubuntu-6.0-latest
```

```shell
# 使用以下命令查看docker参数信息
$ docker inspect zabbix-server-mysql
$ cp -a /var/lib/docker/volumes/zabbix-server-volume/_data/zabbix_server.conf /opt/zabbix/server/etc/zabbix_server.conf
$ docker run -v /etc/localtime:/etc/localtime \
      --name zabbix-server-mysql -t \
      -e DB_SERVER_HOST="mysql-server" \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD=********* \
      -e MYSQL_ROOT_PASSWORD=********* \
      -e ZBX_JAVAGATEWAY="zabbix-java-gateway" \
      -v /opt/zabbix/server/etc/zabbix_server.conf:/etc/zabbix/zabbix_server.conf \
      -v /opt/zabbix/server/alertscripts:/usr/lib/zabbix/alertscripts \
      -v /opt/zabbix/server/externalscripts:/usr/lib/zabbix/externalscripts \
      -v /opt/zabbix/server/modules:/usr/lib/zabbix/modules \
      --network=zabbix-net \
      -p 10051:10051 \
      --restart unless-stopped \
      -d zabbix/zabbix-server-mysql:ubuntu-6.0-latest

```

| Volumes                         | 描述                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| /usr/lib/zabbix/alertscripts    | 用于自定义告警脚本。即 zabbix_server.conf 中的 AlertScriptsPath 参数。 |
| /usr/lib/zabbix/externalscripts | 用于外部检查。即 zabbix_server.conf 中的 ExternalScripts 参数。 |
| /var/lib/zabbix/modules         | 允许通过 LoadModule 功能加载额外的模块以扩展 Zabbix server。 |
| /var/lib/zabbix/enc             | 用于存放 TLS 相关的文件。这些文件名使用 ZBX_TLSCAFILE, ZBX_TLSCRLFILE, ZBX_TLSKEY_FILE ，ZBX_TLSPSKFILE 等环境变量指定。 |
| /var/lib/zabbix/ssl/certs       | 用于存放客户端认证的 SSL 客户端认证文件。即 [zabbix_server.conf] 中的 SSLCertLocation 参数。 |
| /var/lib/zabbix/ssl/keys        | 用于存放客户端认证的 SSL 私钥文件。即 zabbix_server.conf 中的 SSLKeyLocation 参数。 |
| /var/lib/zabbix/ssl/ssl_ca      | 用于存放 SSL 服务器证书认证的证书颁发机构(CA)文件。即 zabbix_server.conf 中的 SSLCALocation 参数。 |
| /var/lib/zabbix/snmptraps       | 用于存放 snmptraps.log 文件。它可由 zabbix-snmptraps 容器共享，并在创建 Zabbix server 新实例时使用 Docker 的 --volumes-from 选项继承。可以通过共享 volume ，并将 ZBX_ENABLE_SNMP_TRAPS 环境变量切换为 'true' 以启用 SNMP trap 处理功能。 |
| /var/lib/zabbix/mibs            | 允许添加新的 MIB 文件。它不支持子目录，所有的 MIB 文件必须位于 /var/lib/zabbix/mibs 下。 |




## 启动 Zabbix Web 界面

启动`Zabbix Web`界面，并将其关联到已创建的`MySQL server`和`Zabbix server`实例，默认用户名：`Admin` 密码：`zabbix`

```shell
$ docker run -v /etc/localtime:/etc/localtime \
      --name zabbix-web-nginx-mysql -t \
      -e ZBX_SERVER_HOST="zabbix-server-mysql" \
      -e DB_SERVER_HOST="mysql-server" \
      -e MYSQL_DATABASE="zabbix" \
      -e MYSQL_USER="zabbix" \
      -e MYSQL_PASSWORD=${zabbix_pwd} \
      -e MYSQL_ROOT_PASSWORD=${root_pwd} \
      -e ZBX_SERVER_NAME="${zabbix_server_name}" \
      --network=zabbix-net \
      -p 8080:8080 \
      --restart unless-stopped \
      -d zabbix/zabbix-web-nginx-mysql:ubuntu-6.0-latest
```

- `ZBX_SERVER_NAME`：Web 界面右上角显示的安装名称。

| Volumes        | 描述                                                         |
| -------------- | ------------------------------------------------------------ |
| /etc/ssl/nginx | 允许为 Zabbix Web 接口启用 HTTPS。这个 volume 必须包含为 Nginx SSL 连接装备的 ssl.crt 和 ssl.key 两个文件。 |



## 启动 Zabbix agent2 服务

1. `Zabbix server`主机安装`Zabbix agent2`服务

   ```shell
   # /var/lib/docker/volumes/zabbix-agent2-volume
   $ docker volume create zabbix-agent2-volume
   $ docker run -v /etc/localtime:/etc/localtime \
         --name zabbix-agent2 \
         -v zabbix-agent2-volume:/etc/zabbix \
         -e ZBX_HOSTNAME="zabbix-server" \
         -e ZBX_SERVER_HOST="zabbix-server-mysql" \
         -p 10050:10050 \
         -e ZBX_SERVER_PORT=10051 \
         -v ${server_dir}/agent2/modules:/var/lib/zabbix/modules \
         --privileged \
         --network=zabbix-net \
         --restart unless-stopped \
         -d zabbix/zabbix-agent2:ubuntu-6.0-latest
   
   # 查询 zabbix agent2 ip
   $ docker inspect zabbix-agent2 | grep -w "IPAddress"
   ```

2. 其他主机安装`Zabbix agent2`服务

   ```shell
   $ docker volume create zabbix-agent2-volume
   $ docker run -v /etc/localtime:/etc/localtime \
         --name zabbix-agent2 \
         -v zabbix-agent2-volume:/etc/zabbix \
         -e ZBX_HOSTNAME="zabbix-agent-01" \
         -e ZBX_SERVER_HOST="192.168.66.40" \
         -p 10050:10050 \
         -e ZBX_SERVER_PORT=10051 \
         -v ${server_dir}/agent2/modules:/var/lib/zabbix/modules \
         --privileged \
         --restart unless-stopped \
         -d zabbix/zabbix-agent2:ubuntu-6.0-latest
   ```

| Volumes                     | 描述                                                         |
| --------------------------- | ------------------------------------------------------------ |
| /etc/zabbix/zabbix_agentd.d | 允许包含 *.conf 文件并使用  UserParameter 扩展 Zabbix agent。 |
| /var/lib/zabbix/modules     | 允许加载其它 module 并使用 LoadModule 功能扩展 Zabbix agent。 |
| /var/lib/zabbix/enc         | 用于存放 TLS 相关的文件。这些文件名使用 ZBX_TLSCAFILE, ZBX_TLSCRLFILE, ZBX_TLSKEY_FILE ，ZBX_TLSPSKFILE 等环境变量指定。 |




## 解决 Zabbix 图形界面乱码问题

```shell
# 下载楷体字库
$ wget https://raw.githubusercontent.com/TenderLeeks/Documentation/main/source/tools/monitor/Zabbix/fonts/simkai.ttf

# 下载黑体字库(建议使用此种字体)
$ wget https://raw.githubusercontent.com/TenderLeeks/Documentation/main/source/tools/monitor/Zabbix/fonts/msyh.ttf

$ mv simkai.ttf DejaVuSans.ttf
$ chmod 644 DejaVuSans.ttf
$ docker cp DejaVuSans.ttf zabbix-web-nginx-mysql:/usr/share/zabbix/assets/fonts
```

## 安装 Zabbix proxy 服务

```shell
$ docker run --name zabbix-proxy-mysql \
      -e DB_SERVER_HOST="mysql-server" \
      -e MYSQL_USER="user" \
      -e MYSQL_PASSWORD="some-password" \
      -e ZBX_HOSTNAME=some-hostname \
      -e ZBX_SERVER_HOST=some-zabbix-server \
      -d zabbix/zabbix-proxy-mysql:ubuntu-6.0-latest
```

## 其他信息

```shell
# 查看 volume 信息
$ docker volume ls
$ docker volume inspect zabbix-agent2-volume
```

