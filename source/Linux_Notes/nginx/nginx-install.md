# 部署NGINX服务

## 源码编译安装

```bash
# CentOS 依赖包安装
$ yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel openldap openldap-devel openldap-clients openldap-servers libtool make pcre pcre-devel automake cmake unzip net-tools vim lrzsz lsof

# Ubuntu 依赖包安装
$ apt-get install -y build-essential

# 编译 zlib
$ wget http://zlib.net/zlib-1.2.11.tar.gz
$ tar -zxf zlib-1.2.11.tar.gz
$ cd zlib-1.2.11
$ ./configure --prefix=/usr/local
$ make clean
$ make -j8
$ make install

# 编译 pcre  https://ftp.pcre.org/pub/pcre/
$ tar -zxf pcre-8.44.tar.gz
$ cd pcre-8.44
$ ./configure --prefix=/usr/local
$ make clean -j2
$ make -j8
$ make install

# 编译 luajit  http://luajit.org/download.html
$ tar -zxf luajit-2.0.tar.gz
$ cd luajit-2.0
$ make clean -j2
$ make -j8
$ make install PREFIX=/usr/local/luajit
$ export LUAJIT_LIB=/usr/local/luajit/lib
$ export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0
$ export LUA_LIB=/usr/local/lua/lib
$ export LUA_INC=/usr/local/lua/include
$ export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH

# 编译 Nginx，下载：https://nginx.org/en/download.html
$ tar -zxf nginx-1.17.10.tar.gz
$ cd nginx-1.17.10
$ make clean -j4

$ ./configure --prefix=/opt/nginx \
	--with-pcre \
	--with-zlib=/tmp/zlib-1.2.11 \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_slice_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-stream_ssl_preread_module

$ make -j8
$ make install

$ ln -s /opt/nginx/sbin/nginx /usr/bin/nginx
$ ln -s /usr/local/luajit/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
$ useradd nginx -s /sbin/nologin -M
```

---

## Ubuntu 编译安装 tengine

```bash
# 更新升级apt-get
$ sudo apt-get update -y
$ sudo apt-get upgrade -y

# 下载 http://tengine.taobao.org/download.html
$ wget http://tengine.taobao.org/download/tengine-2.3.3.tar.gz -P /tmp
$ tar -zxf /tmp/tengine-2.3.3.tar.gz

# 安装PCRE库，
# PCRE(Perl Compatible Regular Expressions)是一个 Perl 库，包括 perl 兼容的正则表达式库。nginx rewrite 依赖于 PCRE 库，所以在安装 Tengine 前一定要先安装 PCRE。
$ sudo apt-get install -y libpcre3 libpcre3-dev

# 安装Zlib库，Zlib 是提供资料压缩用的函数库，当 Tengine 想启用 gzip 压缩的时候就需要使用到 Zlib。
$ sudo apt-get install -y zlib1g-dev

# 安装OpenSSL 库，OpenSSL 是一个强大的安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能及 SSL 协议，并提供丰富的应用程序供测试或其它目的使用。安装 OpenSSL 主要是为了让 Tengine 支持 HTTPS 的访问请求。
$ sudo apt-get install -y openssl libssl-dev

$ sudo apt-get install -y build-essential

# 生成makefile，这里选择了编译 HTTP/2 需要的 ngx_http_v2_module 模块。Tengine 默认将安装在 `/usr/local/nginx` 目录。你可以用 `--prefix` 来指定你想要的安装目录。
$ cd /tmp/tengine-2.3.3
$ sudo ./configure --prefix=/opt/nginx \
--with-http_v2_module \
--add-module=modules/ngx_http_upstream_check_module \
--add-module=modules/mod_config \
--add-module=modules/ngx_backtrace_module \
--add-module=modules/ngx_debug_pool \
--add-module=modules/ngx_debug_timer \
--add-module=modules/ngx_http_concat_module \
--add-module=modules/ngx_http_footer_filter_module \
--add-module=modules/ngx_http_proxy_connect_module \
--add-module=modules/ngx_http_reqstat_module \
--add-module=modules/ngx_http_slice_module \
--add-module=modules/ngx_http_sysguard_module \
--add-module=modules/ngx_http_trim_filter_module \
--add-module=modules/ngx_http_upstream_consistent_hash_module \
--add-module=modules/ngx_http_upstream_dynamic_module \
--add-module=modules/ngx_http_upstream_dyups_module \
--add-module=modules/ngx_http_upstream_session_sticky_module \
--add-module=modules/ngx_http_upstream_vnswrr_module \
--add-module=modules/ngx_http_user_agent_module \
--add-module=modules/ngx_multi_upstream_module \
--add-module=modules/ngx_slab_stat \
--with-pcre --with-http_ssl_module --with-http_realip_module \
--with-http_addition_module --with-http_sub_module --with-http_dav_module \
--with-http_flv_module --with-http_mp4_module --with-http_gunzip_module \
--with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module \
--with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream \
--with-stream_ssl_module --with-http_slice_module --with-file-aio --with-stream_ssl_preread_module

# 编译安装
$ sudo make -j4
$ sudo make install

# 开机自启动
$ sudo tee /lib/systemd/system/nginx.service << EOF
Description=nginx - high performance web server
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/opt/nginx/sbin/nginx -c /opt/nginx/conf/nginx.conf
ExecReload=/opt/nginx/sbin/nginx -s reload
ExecStop=/opt/nginx/sbin/nginx -s stop
[Install]
WantedBy=multi-user.target
EOF

$ useradd nginx -s /sbin/nologin -M

# 使配置生效
$ sudo systemctl daemon-reload
# 设置开机启动
$ sudo systemctl enable nginx.service

# 启动
$ sudo /opt/nginx/sbin/nginx
# 或者
$ sudo systemctl start nginx.service

# 重启
$ sudo /opt/nginx/sbin/nginx -s reload
# 或者
$ sudo systemctl reload nginx.service

# 停止
$ sudo /opt/nginx/sbin/nginx -s stop
# 或者
$ sudo systemctl stop nginx.service
```

参考链接：

- http://tengine.taobao.org/
- http://tengine.taobao.org/changelog_cn.html#2_3_3
- http://tengine.taobao.org/download.html
- https://www.cnblogs.com/tinywan/p/6534151.html
- https://www.cnblogs.com/JC-0527/p/14237651.html

---

## 使用 Docker 安装 Nginx

```bash
$ docker pull nginx:latest
$ mkdir -p /opt/nginx/{conf.d,logs,web}
$ vim /opt/nginx/nginx.conf
$ mkdir -p /opt/nginx/conf.d/ssl-cert
$ docker run -it -p 80:80 -p 443:443 --name nginx \
-v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf \
-v /opt/nginx/conf.d:/etc/nginx/conf.d \
-v /opt/nginx/web:/opt/nginx/web \
-v /opt/nginx/logs:/var/log/nginx \
-v /etc/localtime:/etc/localtime -d nginx

$ docker exec nginx sh -c 'nginx -t'
$ docker exec nginx sh -c 'nginx -s reload'

# docker配置文件内容
user nginx;	
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;

#error_log logs/error.log;
#pid logs/nginx.pid;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
  use epoll;
  worker_connections 65535;
  accept_mutex off;
  multi_accept off;
}

http {
  server_tokens off;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;

  log_format json  '{"客户端IP":"$proxy_add_x_forwarded_for", '
      '"请求开始时间":"$time_iso8601", '
      '"服务端Url":"$host$uri", '
      '"请求Url":"$http_referer", '
      '"接口名或工程名":"$uri", '
      '"服务端IP":"$server_addr", '
      '"Post-body":"$request_body", '
      '"Get-body":"$request", '
      '"返回状态码":"$status", '
      '"请求大小-字节":$body_bytes_sent, '
      '"整个请求总时间":$request_time, '
      '"Upstream响应时间":$upstream_response_time, '
      '"真正提供服务的地址": "$upstream_addr", '
      '"客户端浏览器信息": "$http_user_agent", '
      '"客户端地址": "$remote_addr", '
      '"客户端用户名称": "$remote_user"'
      '}';

  log_format main '"$proxy_add_x_forwarded_for", "$time_iso8601", '
      '"$host$uri", "$http_referer", "$uri", "$server_addr", '
      '"$request_body", "$request", "$status", '
      '"$body_bytes_sent", "$request_time", "$upstream_response_time", '
      '"$upstream_addr", "$http_user_agent", "$remote_addr", "$remote_user"';

  #access_log  logs/access.log  json;
  access_log  /var/log/nginx/access.log  json;
  #access_log  logs/access.log  main;
  #access_log  /dev/null;
  keepalive_timeout 30;
  client_header_timeout 10;
  client_body_timeout 10;
  reset_timedout_connection on;
  send_timeout 10;
  include mime.types;
  default_type application/octet-stream;
  charset UTF-8;
  gzip on;
  gzip_disable "msie6";
  gzip_proxied any;
  gzip_min_length 1k;
  gzip_comp_level 5;
  gzip_vary on;
  gzip_buffers 16 8k;
  gzip_types text/plain application/x-javascript text/css application/xml application/json text/javascript text/xml;
  open_file_cache max=102400 inactive=20s;
  open_file_cache_valid 30s;
  open_file_cache_min_uses 1;
  types_hash_max_size 2048;
  client_header_buffer_size 4k;
  client_max_body_size 64m;
  include conf.d/*.conf;
}
```

---

## 编译安装配置

### 通用配置项

| 配置选项                | 说明                                                         |
| ----------------------- | ------------------------------------------------------------ |
| --prefix=<path>         | nginx安装的根路径，所有其他的路径都要依赖与该选项            |
| --sbin-path=<path>      | nginx二进制文件的路径，如果没有指定则会依赖于--prefix        |
| --conf-path=<path>      | 如果在命令行中没有指定配置文件，则通过该配置项去查找配置文件 |
| --error-log-path=<path> | 指定错误文件的路径                                           |
| --pid-path=<path>       | 指定的文件将会写入nginx master进程的pid，通常在/var/run下    |
| --lock-path=<path>      | 共享存储器互斥锁文件的路径                                   |
| --user=<user>           | worker进程运行的用户                                         |
| --group=<group>         | worker进程运行的组                                           |
| --with-file-aio         | 启动异步I/O                                                  |
| --with-debug            | 启用调试日志，生产环境不推荐配置                             |

### 优化配置项

| 配置选项                | 说明                                  |
| ----------------------- | ------------------------------------- |
| --with-cc=<path>        | 如果想设置一个不在默认PATH下的C编译器 |
| --with-cpp=<path>       | 设置C预处理器的相应路径               |
| --with-cc-opt=<options> | 指定必要的include文件路径             |
| --with-ld-opt=<options> | 包含连接器库的路径和运行路径          |
| --with-cpu-opt=<cpu>    | 通过该选项为特定的CPU构建nginx        |

### http模块的配置项

| 配置选项                            | 说明                                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| --without-http-cache                | 在使用upstream模块时，nginx能够配置本地缓存内容，该选项可以禁用缓存 |
| --with-http_perl_module             | nginx配置能够扩展使用perl代码。该项启用这个模块，但会降低性能 |
| --with-perl_modules_path=<path>     | 对于额外嵌入的perl模块，该选项指定该perl解析器的路径         |
| --with-perl=<path>                  | 如果在默认的路径中找不到perl则指定perl（5.6版本以上）的路径  |
| --http-log-path=<path>              | http访问日志的默认路径                                       |
| --http-client-body-temp-path=<path> | 从客户端收到请求后，该项用于作为请求体临时存放的目录         |
| --http-proxy-temp-path=<path>       | 在使用代理后，通过该项设置存放临时文件路径                   |
| --http-fastcgi-temp-path=<path>     | 设置FastCGI临时文件的目录                                    |
| --http-uwsgi-temp-path=<path>       | 设置uWSGI临时文件的目录                                      |
| --http-scgi-temp-path=<path>        | 设置SCGI临时文件的目录                                       |

### 其他模块额外配置项

默认没有安装这些模块，可以通过--with-<module-name>_module来启用相应的模块功能。

| 配置选项                        | 说明                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| --with-http_ssl_module          | 如果需要对流量进行加密，可以使用该选项，再URLs中开始部分将会是https(需要OpenSSL库) |
| --with-http_realip_module       | 如果nginx在七层负载均衡器或者其他设备之后，它们将Http头中的客户端IP地址传递，则需要启用该模块，再多个客户处于一个IP地址的情况下使用 |
| --with-http_addition_module     | 该模块作为输出过滤器，使能够在请求经过一个location前或后时在该location本身添加内容 |
| --with-http_xslt_module         | 该模块用于处理XML响应转换，基于一个或多个XSLT格式            |
| --with-http_image_filter_module | 该模块被作为图像过滤器使用，在将图像投递到客户之前进行处理（需要libgd库） |
| --with-http_geoip_module        | 使用该模块，能够设置各种变量以便在配置文件中的区段使用，基于地理位置查找客户端IP地址 |
| --with-http_sub_module          | 该模块实现替代过滤，在响应中用一个字符串替代另一个字符串     |
| --with-heep_dav_module          | 启用这个模块将激活使用WebDAV的配置指令。                     |
| --with-http_flv_module          | 如果需要提供Flash流媒体视频文件，那么该模块将会提供伪流媒体  |
| --with-http_mp4_module          | 这个模块支持H.264/AAC文件伪流媒体                            |
| --with-http_gzip_static_module  | 当被调用的资源没有.gz结尾格式的文件时，如果想支持发送预压缩版本的静态文件，那么使用该模块 |
| --with-http_gunzip_module       | 对于不支持gzip编码的客户，该模块用于为客户解压缩预压缩内容   |
| --with-http_random_index_module | 如果你想提供从一个目录中随机选择文件的索引文件，那么该模块需要激活 |
| --with-http_secure_link_module  | 该模块提供一种机制，它会将一个哈希值链接到一个URL中，因此只有那些使用正确密码能够计算链接 |
| --with-http_stub_status_module  | 启用这个模块后会收集Nginx自身的状态信息。输出的状态信息可以使用RRDtool或类似的东西绘制成图 |



## 添加新的module模块

1. 查看已安装的模块

   ```shell
   $ nginx -V
   ```

   输出信息

   ```shell
   nginx version: nginx/1.17.10
   built by gcc 9.3.1 20200408 (Red Hat 9.3.1-2) (GCC) 
   built with OpenSSL 1.0.2k-fips  26 Jan 2017
   TLS SNI support enabled
   configure arguments: --prefix=/opt/nginx --with-pcre --with-zlib=/root/zlib-1.2.11 --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-stream_ssl_preread_module
   ```

2. 加入需要安装的模块，重新编译

   ```shell
   $ cd nginx-1.17.10
   $ make clean -j4
   
   $ ./configure --prefix=/opt/nginx \
   	--with-pcre --with-zlib=/root/zlib-1.2.11 
   	--with-http_ssl_module 
   	--with-http_realip_module \
   	--with-http_addition_module \
   	--with-http_sub_module \
   	--with-http_dav_module \
   	--with-http_flv_module \
   	--with-http_mp4_module \
   	--with-http_gunzip_module \
   	--with-http_gzip_static_module \
   	--with-http_random_index_module \
   	--with-http_secure_link_module \
   	--with-http_stub_status_module \
   	--with-http_auth_request_module \
   	--with-threads --with-stream \
   	--with-stream_ssl_module \
   	--with-http_slice_module \
   	--with-file-aio \
   	--with-http_v2_module \
   	--with-stream_ssl_preread_module
   
   $ make -j4
   ```

   **注意：千万不要make install，不然就真的覆盖**

3. 替换 nginx 二进制文件

   ```shell
   # 备份原来的nginx执行程序
   $ mv /opt/nginx/sbin/nginx /opt/nginx/sbin/nginx.bak
   # 将新编译的nginx执行程序复制到/usr/local/nginx/sbin/目录下
   $ cp -a objs/nginx /opt/nginx/sbin/
   ```

   

