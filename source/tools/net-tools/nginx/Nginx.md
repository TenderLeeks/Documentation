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

   