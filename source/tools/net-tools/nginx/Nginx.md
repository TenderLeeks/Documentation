# NGINX 服务使用配置

## 编译安装

```shell
# CentOS7 安装依赖包
$ yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel openldap openldap-devel openldap-clients openldap-servers libtool make pcre pcre-devel automake cmake unzip net-tools vim lrzsz lsof

# Ubuntu 系统
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

# 编译 Nginx
$ tar -zxf nginx-1.17.10.tar.gz
$ cd nginx-1.17.10
$ make clean -j4

$ ./configure --prefix=/opt/nginx --with-pcre --with-zlib=/tmp/zlib-1.2.11 --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-stream_ssl_preread_module

$ make -j8
$ make install

$ ln -s /opt/nginx/sbin/nginx /usr/bin/nginx
$ ln -s /usr/local/luajit/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
$ useradd nginx -s /sbin/nologin -M
```



## ubuntu编译安装tengine

```shell
# 下载 http://tengine.taobao.org/download.html
$ cd /tmp
$ wget http://tengine.taobao.org/download/tengine-2.3.3.tar.gz
$ tar -zxf tengine-2.3.3.tar.gz
# 更新升级apt-get
$ sudo apt-get update -y 
$ sudo apt-get upgrade -y 

# 安装PCRE库，
# PCRE(Perl Compatible Regular Expressions)是一个 Perl 库，包括 perl 兼容的正则表达式库。nginx rewrite 依赖于 PCRE 库，所以在安装 Tengine 前一定要先安装 PCRE。
$ sudo apt-get install -y libpcre3 libpcre3-dev

# 安装Zlib库，Zlib 是提供资料压缩用的函数库，当 Tengine 想启用 gzip 压缩的时候就需要使用到 Zlib。
$ sudo apt-get install -y zlib1g-dev

# 安装OpenSSL 库，OpenSSL 是一个强大的安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能及 SSL 协议，并提供丰富的应用程序供测试或其它目的使用。安装 OpenSSL 主要是为了让 Tengine 支持 HTTPS 的访问请求。
$ sudo apt-get install -y openssl libssl-dev

# 生成makefile，这里选择了编译 HTTP/2 需要的 ngx_http_v2_module 模块。Tengine 默认将安装在 `/usr/local/nginx` 目录。你可以用 `--prefix` 来指定你想要的安装目录。
$ cd tengine-2.3.3
$ sudo ./configure --prefix=/opt/nginx --with-http_v2_module \
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
$ sudo make
$ sudo make install

# 开机自启动
$ sudo vim /lib/systemd/system/nginx.service  # nginx.service 文件内添加以下内容
Description=nginx - high performance web server
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/opt/nginx/sbin/nginx -c /opt/nginx/conf/nginx.conf
ExecReload=/opt/nginx/sbin/nginx -s reload
ExecStop=/opt/nginx/sbin/nginx -s stop
[Install]
WantedBy=multi-user.target

# 使配置生效
$ sudo systemctl daemon-reload
# 设置开机启动
$ sudo systemctl enable nginx.service
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.

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

参考文档：

```tex
http://tengine.taobao.org/
http://tengine.taobao.org/changelog_cn.html#2_3_3
http://tengine.taobao.org/download.html
https://www.cnblogs.com/tinywan/p/6534151.html
https://www.cnblogs.com/JC-0527/p/14237651.html
```


## docker 安装nginx

```shell
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



## 主配置

```nginx
user nginx;
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;

error_log logs/error.log;
pid logs/nginx.pid;

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

  access_log  logs/access.log  json;
  #access_log  logs/access.log  main;
  #access_log  /dev/null;

  keepalive_timeout 30;
  client_header_timeout 10;
  client_body_timeout 10;
  reset_timedout_connection on;
  send_timeout 10;

#    limit_conn_zone $binary_remote_addr zone=addr:10m;
#    limit_conn addr 100;
#    limit_conn_zone $server_name zone=perserver:10m;
#    limit_conn perserver 100;

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

  include /opt/nginx/conf/conf.d/*.conf;
}
```

## upstream 配置

1. 轮询（默认）

   ```nginx
   upstream xxx.xxx.xxx {
     server 127.0.0.1:10086;
     server 127.0.0.2:10086;
   }
   ```

2. 权重，默认 weight=1

   ```nginx
   upstream xxx.xxx.xxx {
     server 127.0.0.1:10086 weight=2;
     server 127.0.0.2:10086 weight=4;
   }
   ```

3. ip_hash

   每一个请求按照访问ip的hash结果分配

   ```nginx
   upstream xxx.xxx.xxx {
     ip_hash;
     server 127.0.0.1:10086;
     server 127.0.0.2:10086;
   }
   ```

4. fair（第三方）

   按后端服务器的响应时间来分配请求。响应时间短的优先分配，后端服务器的响应时间(rt)来分配请求,响应时间短即rt小的后端服务器优先分配请求。如果需要使用这种调度算法,必须下载Nginx的upstr_fair模块。

   ```nginx
   upstream xxx.xxx.xxx{
     server 127.0.0.1:10086;
     server 127.0.0.2:10086;
     fail;
   }
   ```

5. url_hash

   目前用consistent_hash替代url_hash与ip_hash类似,但是按照访问url的hash结果来分配请求,使得每个url定向到同一个后端服务器,主要应用于后端服务器为缓存时的场景下。

   ```nginx
   upstream xxx.xxx.xxx{
     server 127.0.0.1:10086;
     server 127.0.0.2:10086;
     hash $request_uri; 
     hash_method crc32; 
   }
   ```

6. Least_conn

   最少连接数轮询：哪个节点当前的连接数少就分配给哪个节点处理

   ```nginx
   Least_conn;
   ```

7. 其他参数

   ```nginx
   upstream xxx.xxxx.xxxx {
     server 127.0.0.2 down;  # 该节点不可用
     server 127.0.0.3 backup;  # 其他节点挂了后该节点自动上线
     server 127.0.0.4 max_failes=1 fail_timeout=10s weight-5;
     server unix:/tmp/backend3;
     server www.example.com:8080;
     keepalive 32;  # 最多允许32个长连接
     keepalive_timeout 30s;  # 每个长连接保持30秒
     keepalive_requests 100;  # 每个长连接允许100个请求
   }
   # server: 负载均衡后端服务器的IP或域名，不写端口的话默认是80。高并发场景用域名，再通过DNS进行负载均衡 。
   # weight: 后端服务器权重，默认为1，权重越大接收的请求越多。
   # max_fails: 检查节点的健康状态并允许请求失败的次数，达到该次数就将节点下线。默认为1，0表示禁止失败尝试。
   # fail_timeout: max_fails失败次数达到限制后暂停该节点服务的时间，默认是10秒。
   # backup: 热备配置，当服务池中所有服务器均出现问题后会自动上线backup服务器
   # down: 标志服务器不可用，不参与负载均衡。这个参数通常配合IP_HASH使用。
   # max_conns: 限制最大连接数，通常对后端服务器硬件不一致的情况进行配置。
   # keepalive: 限制空闲长连接的最大数量。
   # keepalive_timeout: 空闲长连接的最长保持时间。
   # keepalive_requests: 每个长连接最多可以处理的请求数。
   ```

## server 配置

- `proxy_pass`：指定需要反向代理的服务器地址，可以是一个upstream池。
- `proxy_next_upstream`：如果后端服务器不可用的话自动将请求转发到另一台服务器，默认为on，还可以设置为timeout或者http状态码。
- `proxy_method`：修改用户的method请求。
- `proxy_http_version`：修改用户的http协议版本。
- `proxy_set_header`：修改用户header头部，如客户端真实IP信息，也是配置较多的选项。
- `proxy_set_body`：修改用户包体信息。
- `proxy_send_timeout`：默认60S。
- `proxy_connect_timeout`： 默认60S，Nginx与后端服务器连接超时时间。

例：

```nginx
server {
  listen 80;
  server_name xxxxx.cn;
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_method PUT;
    proxy_http_version 1.1;
    proxy_set_header test "var modify by nginx";
  }
}
```

`proxy_pass` "/" 的常见误区。不带 "/" 的话不会修改用户的URL，用户请求的是什么URL就返回什么URL；带 "/" 则相反，会将location指定的URL从用户URL删除掉。

```nginx
# 当用户请求 /a/b/c.html 时，最终返回 http://127.0.0.1:8080/a/b/c.html
location /a/ {
  proxy_pass http://127.0.0.1:8080;
}

# 当用户请求 /a/b/c.html 时，最终返回 http://127.0.0.1:8080/b/c.html
location /a/ {
  proxy_pass http://127.0.0.1:8080/;
}

location /test {
  proxy_pass http://127.0.0.1:81;  # 如果这里写 http://127.0.0.1:81/ 则是将 uri /test/ 替换为了 /
}

```

## 线上配置示例

```nginx
server {
  listen       80;
  listen       443 ssl;
  server_name  www.xxxx.com xxxx.com;

  ssl_certificate       /opt/nginx/conf/ssl-cert/www.xxxx.com.crt;
  ssl_certificate_key   /opt/nginx/conf/ssl-cert/www.xxxx.com.key;
  ssl_session_cache   shared:SSL:10m;
  ssl_session_timeout 10m;
  ssl_protocols SSLv3 SSLv2 TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
  ssl_prefer_server_ciphers on;

  if ($scheme = http) {
    return 301 https://$host$request_uri;
  }

  if ($host = xxxx.com) {
    return 301 https://www.xxxx.com$request_uri;
  }

  client_max_body_size 4M;  # 配置请求体缓存区大小, 不配的话
  client_body_buffer_size 64k;  # 设置客户端请求体最大值

  location /api {
    proxy_pass http://xxx.xxx;
    proxy_redirect  off;
    client_max_body_size 1024M;
    proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Connection "";
    proxy_http_version 1.1;
  }

  location /dapp/ystarvote {
    root   /opt/www/xxx;
    index  index.html index.htm;
    add_header Cache-Control "private, no-store, no-cache";
    proxy_redirect  off;
    proxy_set_header  Host  $host;
    proxy_set_header  X-Real-IP  $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    #一个覆盖所有情况的候选资源：如果 URL 匹配不到任何静态资源，返回同一个 index.html 页面
    try_files $uri $uri/dapp/ystarvote @ystarvote_router;
  }
  location @ystarvote_router {
    rewrite ^.*$ /dapp/ystarvote/index.html last;
  }

  location /dapp/yswap {
    proxy_pass http://xxx.xxx.xxx.xxx;
    proxy_redirect  off;
    client_max_body_size 1024M;
    proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Connection "";
    proxy_http_version 1.1;
  }
}
```

## 跨域配置

```nginx
  location /dapp/yswap {
    proxy_pass http://xxx.xxx.xxx;
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods 'GET,POST,PUT,DELETE,PATCH,OPTIONS';
    add_header Access-Control-Allow-Credentials true;
    add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Accept,Authorization';
  }
```

## 缓存配置

```nginx
server {
  listen       80;
  server_name  -;
  location / {
    root /apps/laikePay/;	
    try_files $uri $uri/ /index.html;
}

  location ^~ /beauty/{
    alias /apps/laikeBeauty/;
    # 以下配置解决 html 不缓存，css和js分别缓存7天和30天
    if ($request_filename ~* .*\.(?:htm|html)$)
    {
      add_header Cache-Control "private, no-store, no-cache";  # 不缓存
    }
    if ($request_filename ~* .*\.(?:js|css)$)
    {
      add_header Cache-Control max-age=604800;  # 缓存7天
    }
    if ($request_filename ~* .*\.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm)$)
    {
      add_header Cache-Control max-age=2592000;  # 缓存1月
    }
    try_files $uri $uri/ /beauty/index.html;
    }
}
```

## 重写配置

```nginx
server {
  listen       8080;
  server_name xxx.com;

  location / {
    root /usr/share/nginx/html;
    add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
    try_files $uri $uri/ /index.html;
  }

  return 301 https://bb.bb.com/a/b/c;  # 重定向，请求xxx.com时会重定向到https://bb.bb.com/a/b/c

  location / {
    proxy_set_header Host $http_host;
    proxy_set_header  X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    rewrite /(.*)$ /$1 break;
    proxy_pass https://shop97476437.m.youzan.com;
  }
  
  location /api {
    proxy_set_header Host $http_host;
    proxy_set_header  X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    rewrite ^/api/(.*)$ /$1 break;  # 重写
    proxy_pass http://177.7.0.12:8888; # 设置代理服务器的协议和地址
  }

  # 请求 http://xxx.com 是重写到 https://aa.m.com/a/b/c，但是请求的URL不改变
  location = / {
    rewrite / /a/b/c break;
    proxy_pass https://aa.m.com;
  }
  
  location /api/swagger/index.html {
    proxy_pass http://127.0.0.1:8888/swagger/index.html;
  }
}
```

## 限流配置

1. 限流算法

   - 令牌桶算法
     - 令牌以固定的速率产生并放入令牌桶中，当令牌桶放满后，多余的令牌会被抛弃；请求会消耗等比例的令牌。当令牌不够用的时候，请求过来后没有拿到令牌，这个请求就会被拒绝服务。
   - 漏桶算法
     - 请求好比是水流一样。水从上面到桶中，从桶中以固定的速度流出。当上面的水流过大，桶中的水没有来得及流出的时候，水就会暂时缓存到水桶中。水流过大，水桶存满后就会溢出（溢出的部分相当于丢弃请求）。
   - `漏桶算法`能够强行限制数据的传输速率，而`令牌桶算法`在能够限制数据的平均传输速率外，还允许某种程度的突发传输（比较极端的情况，当桶中的令牌存满桶的时候，流量突增）。

2. 限流配置

   - `limit_req_zone`：用来限制单位时间内的请求数，即速率限制,采用的漏桶算法 "leaky bucket"。

     ```nginx
     # 语法
     limit_req_zone key zone=name:size rate=rate [sync];
     # 示例
     limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
     limit_req_zone $http_host zone=perhost:10m rate=10r/s;
     ```

     `$binary_remote_addr`： 表示通过remote_addr这个标识来做限制，“binary_”的目的是缩写内存占用量，是限制同一客户端ip地址。

     `zone=one:10m`：表示生成一个大小为10M，名字为one的内存区域，用来存储访问的频次信息。

     `rate=10r/s`：表示允许相同标识的客户端的访问频次，这里限制的是每秒10次，还可以有比如30r/m的。

     ```nginx
     limit_req zone=one burst=5 nodelay;
     limit_req zone=perhost burst=5 nodelay;
     ```

     `zone=one`：设置使用哪个配置区域来做限制，与上面`limit_req_zone` 里的`name`对应。

     `burst=5`：设置一个大小为5的缓冲区当有大量请求（爆发）过来时，超过了访问频次限制的请求可以先放到这个缓冲区内。

     `nodelay`：如果设置，超过访问频次而且缓冲区也满了的时候就会直接返回503，如果没有设置，则所有请求会等待排队。

     示例：

     ```nginx
     http {
       limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
       server {
         location /search/ {
           limit_req zone=one burst=5 nodelay;
           limit_req zone=perhost burst=5 nodelay;
         }
       }
     }
     
     # 下面配置可以限制特定UA（比如搜索引擎，爬虫等）的访问
     http{
       limit_req_zone $anti_spider zone=one:10m rate=10r/s;
       limit_req zone=one burst=100 nodelay;
       if ($http_user_agent~ * "googlebot|bingbot|Feedfetcher-Google|YisouSpider|Scrapy") {
         set $anti_spider $http_user_agent;
       }
     }
     ```

     其他参数：

     ```nginx
     # 语法
     limit_req_log_level info | notice | warn | error;
     # 默认
     limit_req_log_level error;
     # 可以配置的模块: http, server, location
     # 设置你所希望的日志级别，当服务器因为频率过高拒绝或者延迟处理请求时可以记下相应级别的日志。 延迟记录的日志级别比拒绝的低一个级别；比如， 如果设置“limit_req_log_level notice”， 延迟的日志就是info级别。
     
     # 语法 
     limit_req_status code;
     # 默认
     limit_req_status 503;
     # 可以配置的模块: http, server, location
     # 设置拒绝请求的返回值 在400~599之间。
     ```

   - `limit_req_conn`：用来限制单个IP的请求数。并非所有的连接都被计数。只有在服务器处理了请求并且已经读取了整个请求头时，连接才被计数。

     ```nginx
     # 语法
     limit_conn_zone key zone=name:size;
     # 注：key的值为 $binary_remote_addr 而不是 $remote_addr
     
     # 语法
     limit_conn zone number;
     # 可以配置的模块: http, server, location
     
     # 一次只允许每个IP地址一个连接
     limit_conn_zone $binary_remote_addr zone=addr:10m;
     server {
       location /download/ {
         limit_conn addr 1;
       }
     }
     
     # limit_conn perip 10 作用的key 是 $binary_remote_addr，表示限制单个IP同时最多能持有10个连接。
     # limit_conn perserver 100 作用的key是 $server_name，表示虚拟主机(server) 同时能处理并发连接的总数。
     limit_conn_zone $binary_remote_addr zone=perip:10m;
     limit_conn_zone $server_name zone=perserver:10m;
     server {
       limit_conn perip 10;
       limit_conn perserver 100;
     }
     
     # 当服务器限制连接数时，设置所需的日志记录级别
     # 语法 
     limit_conn_log_level info | notice | warn | error;
     # 默认
     limit_conn_log_level error;
     # 可以配置的模块: http, server, location
     
     # 设置状态代码以响应被拒绝的请求而返回
     # 语法 
     limit_conn_status code;
     # 默认
     limit_conn_status 503;
     # 可以配置的模块: http, server, location
     ```

   - 配置示例

     1. 限制访问速率

        ```nginx
        # 此配置限制了 1s钟可以处理请求2次，500ms处理一次
        limit_req_zone $binary_remote_addr zone=one:10m rate=2r/s;
        server {
          location / {
            limit_req zone=one;
          }
        }
        ```

     2. burst缓存处理

        ```nginx
        limit_req_zone $binary_remote_addr zone=one:10m rate=2r/s;
        server {
          location / {
            limit_req zone=one burst=4;
          }
        }
        # burst=4指每个key(此处是每个IP)最多允许4个突发请求的到来。如果单个IP在10ms内发送6个请求则会导致1个请求立即处理，4个请求被缓存，1个请求被抛弃。 有4个请求被放到burst队列当中，工作进程每隔500ms(rate=2r/s)取一个请求进行处理，最后一个请求要排队2s才会被处理；
        ```

        注：burst的作用是让多余的请求可以先放到队列里，慢慢处理。如果不加nodelay参数，队列里的请求不会立即处理，而是按照rate设置的速度，以毫秒级精确的速度慢慢处理。

     3. nodelay降低排队时间

        ```nginx
        limit_req_zone $binary_remote_addr zone=one:10m rate=2r/s;
        server {
          location / {
            limit_req zone=one burst=4 nodelay;
          }
        }
        
        # nodelay参数允许请求在排队的时候就立即被处理，也就是说只要请求能够进入burst队列，就会立即被后台worker处理，请注意，这意味着burst设置了nodelay时，系统瞬间的QPS可能会超过rate设置的阈值。nodelay参数要跟burst一起使用才有作用。
        
        # 当单个ip在10ms中过来6个请求，成功请求率和上面一样，成功5个，失败1个。队列中的请求同时具有了被处理的资格，可以当做 5个请求是同时开始被处理的，花费时间变短了。
        ```

        注意：虽然设置burst和nodelay能够降低突发请求的处理时间，但是长期来看并不会提高吞吐量的上限，长期吞吐量的上限是由rate决定的，因为nodelay只能保证burst的请求被立即处理，但Nginx会限制队列元素释放的速度，就像是限制了令牌桶中令牌产生的速度。

     4. 自定义返回值

        ```nginx
        limit_req_zone $binary_remote_addr zone=mylimit:10m rate=2r/s;
        server {
          location / {
            limit_req zone=mylimit burst=4 nodelay;
            limit_req_status 598;
          }
        }
        # 这样设置，当请求因超过设置的阈值，返回的状态码就是 598
        ```

     5. 设置白名单

        限流主要针对外部访问，内网访问相对安全，可以不做限流，通过设置白名单即可。

        ```nginx
          geo $limit {
            default 1;
            10.0.0.0/8 0;
            192.168.0.0/24 0;
            172.20.0.35 0;
          }
          map $limit $limit_key {
            0 "";
            1 $binary_remote_addr;
          }
          limit_req_zone $limit_key zone=myRateLimit:10m rate=10r/s;
        
        # geo 对于白名单(子网或IP都可以) 将返回0，其他IP将返回1。
        # map 将 $limit 转换为 $limit_key，如果是 $limit 是0(白名单)，则返回空字符串；如果是1，则返回客户端实际IP。
        # limit_req_zone 限流的key不再使用 $binary_remote_addr，而是 $limit_key 来动态获取值。如果是白名单，limit_req_zone 的限流key则为空字符串，将不会限流；若不是白名单，将会对客户端真实IP进行限流。
        ```

     6. 限制数据传输速度

        ```nginx
        location /flv/ {
          flv;
          limit_rate_after 20m;
          limit_rate       100k;
        }
        # 这个限制是针对每个请求的，表示客户端下载前20M时不限速，后续限制100kb/s。
        ```

     7. 总体配置示例

        ```nginx
        http {
          limit_conn_zone $binary_remote_addr zone=addr:10m;
          limit_conn_zone $server_name zone=perserver:10m;
          limit_req_zone $binary_remote_addr zone=one:10m rate=500r/s;
          limit_req_zone $http_host zone=perhost:10m rate=1000r/s;
          server {
            location / {
              limit_conn addr 10;
              limit_conn perserver 10;
              limit_req zone=one burst=100 nodelay;
              limit_req zone=perhost burst=100 nodelay;
              limit_req_status 598;
              limit_conn_status 597;
              limit_conn_log_level error;
              limit_req_log_level error;
            }
            error_page 597 598 /59x.html;
              location = /59x.html {
                root   html;
            }
          }
        }
        ```

        

     

## 正向代理配置

```nginx
stream {
  resolver 114.114.114.114 8.8.8.8;
  upstream node1 {
    server 18.178.30.66:32668;
  }

  server {
    listen 32668;
    proxy_connect_timeout 600s;
    proxy_timeout 900s;
    proxy_pass node1;
  }
    
  server {
    listen 443;
    ssl_preread on;
    proxy_connect_timeout 60s;
    proxy_pass $ssl_preread_server_name:$server_port;
  }
}
```



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
   
   $ ./configure --prefix=/opt/nginx --with-pcre --with-zlib=/root/zlib-1.2.11 --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-stream_ssl_preread_module
   
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

   