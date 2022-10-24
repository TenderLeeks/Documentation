# Nginx 配置文件

## 基本配置格式

```shell
<section>{
    <directive> <parameters>;
}
```

每一个指令行由分号结束，大括号{}表示一个新的上下文。

## Nginx 全局配置参数

全局配置指令

| 模块                 | 配置项                                      | 说明                                       |
| ------------------ | ---------------------------------------- | ---------------------------------------- |
| main模块             | user                                     | 配置worker进程的用户和组，如果忽略group，则group等于指定的用户的所属组 |
| worker_processes   | 指定worker进程的启动数量，可将其设置为可用的CPU内核数，若为auto为自动检测 |                                          |
| error_log          | 所有错误的写入文件，第二个参数指定错误的级别（debug，info，notice，warn，error，crit，alert，emerg） |                                          |
| pid                | 设置主进程IP的文件                               |                                          |
| events模块           | use                                      | 用于设置使用什么样的连接方法                           |
| worker_connections | 用于配置一个工作进程能够接受的并发连接最大数。包括客户连接和向上游服务器的连接。 |                                          |

## 使用 include 文件

include文件可以在任何地方以增强配置文件的可读性，使用include文件要确保被包含文件自身正确的nginx语法，即配置指令和块，然后指定这些文件的路径。

`include /etc/nginx/mime.types;`

若使用通配符则表示通配的多个文件，若没有给定全路径则依据主配置文件路径进行搜索。

`include /etc/nginx/conf.d/*.conf`

测试配置文件(包括include的配置文件)语法：

`nginx -t -c {path-to-nginx.conf}`

## 配置说明

### main模块

```shell
# main模块类似main函数包含其他子模块，非模块配置项(包括模块内)分号结尾，子模块配置花括号结尾
user nobady;   # 一般按默认设置
pid /var/run/nginx.pid;  # 进程标识符存放路径，一般按默认设置
worker_processes auto;  # nginx对外提供web服务时的worder进程数，可将其设置为可用的CPU内核数，auto为自动检测
worker_rlimit_nofile 100000;  # 更改worker进程的最大打开文件数限制
error_log logs/error.log  info;  # 错误日志存放路径
keepalive_timeout 60;  # keepalive_timeout 60;
events{
  # 见events模块
}
http{  # 见http模块
  server{ 
    ...
    location /{
     
    }
  }
}
mail{
  # 见mail模块
}
```

### events模块

```shell
events {
  worker_connections 2048;  # 设置可由一个worker进程同时打开的最大连接数
  multi_accept on;  # 告诉nginx收到一个新连接通知后接受尽可能多的连接
  use epoll;  # 设置用于复用客户端线程的轮询方法。Linux 2.6+：使用epoll；*BSD：使用kqueue。
}
```

### http模块

```shell
http {  # http模块
    server {  # server模块，http服务上的虚拟主机， server 当做对应一个域名进行的配置
        listen          80;  # 配置监听端口
        server_name     www.leeks.com; # 配置访问域名
        access_log      logs/leeks.access.log main;  # 指定日志文件的存放路径
        index index.html;    # 默认访问页面
        root  /var/www/leeks.com/htdocs;  # root 是指将本地的一个文件夹作为所有 url 请求的根路径
        upstream backend {   # 反向代理的后端机器，实现负载均衡
            ip_hash;    # 指明了我们均衡的方式是按照用户的 ip 地址进行分配
            server backend1.example.com;
            server backend2.example.com;
            server backend3.example.com;
            server backend4.example.com;
        }
        location / {  # location 是在一个域名下对更精细的路径进行配置
            proxy_pass http://backend;  # 反向代理到后端机器
        }
    }
 
    server {
        listen          80;
        server_name     www.Androidj.com;
        access_log      logs/androidj.access.log main;
        location / {
            index index.html;
            root  /var/www/androidj.com/htdocs;
        }
    }
}
```

### mail模块

```shell
mail {
    auth_http  127.0.0.1:80/auth.php;
    pop3_capabilities  "TOP"  "USER";
    imap_capabilities  "IMAP4rev1"  "UIDPLUS";
 
    server {
        listen     110;
        protocol   pop3;
        proxy      on;
    }
    server {
        listen      25;
        protocol    smtp;
        proxy       on;
        smtp_auth   login plain;
        xclient     off;
    }
}
```



## 主配置文件

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

  # 客户端IP,请求开始时间,
  # 服务端Url,请求Url,接口名或工程名,服务端IP,
  # Post-body,Get-body,返回状态码,
  # 请求大小-字节,整个请求总时间,Upstream响应时间,
  # 真正提供服务的地址,客户端浏览器信息,客户端地址,客户端用户名称
  # 客户端真实IP
  log_format main '"$proxy_add_x_forwarded_for", "$time_iso8601", '
      '"$host$uri", "$http_referer", "$uri", "$server_addr", '
      '"$request_body", "$request", "$status", '
      '"$body_bytes_sent", "$request_time", "$upstream_response_time", '
      '"$upstream_addr", "$http_user_agent", "$remote_addr", "$remote_user", '
      '"$http_x_forwarded_for"';

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

### 限流算法

- 令牌桶算法
  - 令牌以固定的速率产生并放入令牌桶中，当令牌桶放满后，多余的令牌会被抛弃；请求会消耗等比例的令牌。当令牌不够用的时候，请求过来后没有拿到令牌，这个请求就会被拒绝服务。
- 漏桶算法
  - 请求好比是水流一样。水从上面到桶中，从桶中以固定的速度流出。当上面的水流过大，桶中的水没有来得及流出的时候，水就会暂时缓存到水桶中。水流过大，水桶存满后就会溢出（溢出的部分相当于丢弃请求）。
- `漏桶算法`能够强行限制数据的传输速率，而`令牌桶算法`在能够限制数据的平均传输速率外，还允许某种程度的突发传输（比较极端的情况，当桶中的令牌存满桶的时候，流量突增）。

### 限流说明

根据具体业务场景，限流措施选用 `Nginx` 自带的两个模块：连接数限流模块 `ngx_http_limit_conn_module` 和漏桶算法实现请求限流模块`ngx_http_limit_req_module`。

`limit_conn` 用来对某个KEY对应的总的网络连接数进行限流，可以按照如IP、域名维度进行限流。

`limit_req` 用来对某个KEY对应的请求的平均速率进行限流，并有两种用法：平滑模式（delay）和允许突发模式(nodelay)。

### 配置说明

#### ngx_http_limit_req_module

`limit_req` 是漏桶算法实现，用于对指定KEY对应的请求进行限流，比如按照IP维度限制请求速率。

配置示例：

```nginx
http {
  limit_req_zone $binary_remote_addr zone=one:10m rate=2r/s;
  limit_req_zone $http_host zone=perhost:10m rate=2r/s;
  limit_req_log_level error;
  limit_req_status 598;
  
  server {
    location / {
      limit_req zone=one burst=10 nodelay;
      limit_req zone=perhost burst=10 nodelay;
    }
    error_page 597 598 /59x.html;
      location = /59x.html {
        root   html;
    }
  }
}
```

**limit_req**

```nginx
limit_req zone=one burst=5 nodelay;
limit_req zone=perhost burst=5 nodelay;
```

- 配置限流区域、桶容量（突发容量，默认0）、是否延迟模式（默认延迟）。

- `zone=one`：设置使用哪个配置区域来做限制，与上面`limit_req_zone` 里的`name`对应。

- `burst=5`：设置一个大小为5的缓冲区当有大量请求（爆发）过来时，超过了访问频次限制的请求可以先放到这个缓冲区内。如果单个IP在10ms内发送8个请求则会导致1个请求立即处理，5个请求被缓存，2个请求被抛弃。 有5个请求被放到burst队列当中，工作进程每隔500ms(rate=2r/s)取一个请求进行处理，最后一个请求要排队3s才会被处理。

  **注意**：burst的作用是让多余的请求可以先放到队列里，慢慢处理。如果不加nodelay参数，队列里的请求不会立即处理，而是按照rate设置的速度，以毫秒级精确的速度慢慢处理。

- `nodelay`：如果设置，超过访问频次而且缓冲区也满了的时候就会直接返回503，如果没有设置，则所有请求会等待排队。

  nodelay参数允许请求在排队的时候就立即被处理，也就是说只要请求能够进入burst队列，就会立即被后台worker处理，请注意，这意味着burst设置了nodelay时，系统瞬间的QPS可能会超过rate设置的阈值。nodelay参数要跟burst一起使用才有作用。

  当单个ip在10ms中过来6个请求，成功请求率和上面一样，成功5个，失败1个。队列中的请求同时具有了被处理的资格，可以当做 5个请求是同时开始被处理的，花费时间变短了。

  **注意**：虽然设置burst和nodelay能够降低突发请求的处理时间，但是长期来看并不会提高吞吐量的上限，长期吞吐量的上限是由rate决定的，因为nodelay只能保证burst的请求被立即处理，但Nginx会限制队列元素释放的速度，就像是限制了令牌桶中令牌产生的速度。

**limit_req_zone**

```nginx
# 语法
limit_req_zone key zone=name:size rate=rate [sync];
# 示例
limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
limit_req_zone $http_host zone=perhost:10m rate=10r/s;
```

- 配置限流KEY、及存放KEY对应信息的共享内存区域大小、固定请求速率；此处指定的KEY是 `$binary_remote_addr` 表示IP地址；固定请求速率使用rate参数配置，支持10r/s和60r/m，即每秒10个请求和每分钟60个请求，不过最终都会转换为每秒的固定请求速率（10r/s为每100毫秒处理一个请求；60r/m，即每1000毫秒处理一个请求）。
- `$binary_remote_addr`： 表示通过`remote_addr`这个标识来做限制，`binary_`的目的是缩写内存占用量，是限制同一客户端ip地址。
- `zone=one:10m`：表示生成一个大小为10M，名字为one的内存区域，用来存储访问的频次信息。
- `rate=10r/s`：表示允许相同标识的客户端的访问频次，这里限制的是每秒10次，还可以有比如30r/m的。

**limit_req_status**

```nginx
# 语法 
limit_req_status code;
# 默认
limit_req_status 503;
```

- 配置被限流后返回的状态码，默认返回503。
- 可以配置的模块: http, server, location。
- 设置拒绝请求的返回值 在400~599之间。

**limit_req_log_level**

```nginx
# 语法
limit_req_log_level info | notice | warn | error;
# 默认
limit_req_log_level error;
```

- 配置记录被限流后的日志级别，默认error级别。
- 可以配置的模块: http, server, location。
- 设置你所希望的日志级别，当服务器因为频率过高拒绝或者延迟处理请求时可以记下相应级别的日志。 延迟记录的日志级别比拒绝的低一个级别；比如， 如果设置`limit_req_log_level notice`， 延迟的日志就是info级别。

**限制特定UA（比如搜索引擎，爬虫等）的访问**

```nginx
http{
  limit_req_zone $anti_spider zone=one:10m rate=10r/s;
  limit_req zone=one burst=100 nodelay;
  if ($http_user_agent~ * "googlebot|bingbot|Feedfetcher-Google|YisouSpider|Scrapy") {
    set $anti_spider $http_user_agent;
  }
}
```

**注意**

- 使用 `$binary_remote_addr` ，此变量在32位服务器上面占用32字节，在64 位服务器上占用64字节，因此，前面设置10m的zone，在32位服务器上面就能够容纳320000个状态，在64位服务器上面就能容纳160000个状态。

**limit_req 的主要执行过程如下**

1. 请求进入后首先判断最后一次请求时间相对于当前时间（第一次是0）是否需要限流，如果需要限流则执行步骤2，否则执行步骤3。

2. 如果没有配置桶容量（burst），则桶容量为0；按照固定速率处理请求；如果请求被限流，则直接返回相应的错误码（默认503）。

   如果配置了桶容量（burst>0）且延迟模式(没有配置nodelay)；如果桶满了，则新进入的请求被限流；如果没有满则请求会以固定平均速率被处理（按照固定速率并根据需要延迟处理请求，延迟使用休眠实现）。

   如果配置了桶容量（burst>0）且非延迟模式（配置了nodelay）；不会按照固定速率处理请求，而是允许突发处理请求；如果桶满了，则请求被限流，直接返回相应的错误码。

3. 如果没有被限流，则正常处理请求。

4. Nginx会在相应时机进行选择一些（3个节点）限流KEY进行过期处理，进行内存回收。



#### ngx_http_limit_conn_module

`limit_conn`是对某个KEY对应的总的网络连接数进行限流。可以按照IP来限制IP维度的总连接数，或者按照服务域名来限制某个域名的总连接数。但是记住不是每一个请求连接都会被计数器统计，只有那些被Nginx处理的且已经读取了整个请求头的请求连接才会被计数器统计。

配置示例：

```nginx
http {
  limit_conn_zone $binary_remote_addr zone=addr:10m;
  limit_conn_zone $server_name zone=perserver:10m;
  limit_conn_log_level error;
  limit_conn_status 597;
  
  server {
    location / {
      limit_conn addr 10;
      limit_conn perserver 10;
    }
    error_page 597 598 /59x.html;
      location = /59x.html {
        root   html;
    }
  }
}
```

**limit_conn**

```nginx
# 语法
limit_conn zone number;

# 作用的key 是 $binary_remote_addr，表示限制单个IP同时最多能持有10个连接。
limit_conn addr 10;

# 作用的key是 $server_name，表示虚拟主机(server) 同时能处理并发连接的总数。
limit_conn perserver 10;
```

- 要配置存放KEY和计数器的共享内存区域和指定KEY的最大连接数；此处指定的最大连接数是10，表示Nginx最多同时并发处理10个连接。
- 可以配置的模块: http, server, location。

**limit_conn_zone**

```nginx
# 语法
limit_conn_zone key zone=name:size;
# 注：key的值为 $binary_remote_addr 而不是 $remote_addr
```

- 用来配置限流KEY、及存放KEY对应信息的共享内存区域大小；此处的KEY是`$binary_remote_addr`其表示IP地址，也可以使用如`$server_name`作为KEY来限制域名级别的最大连接数。

**limit_conn_status**

```nginx
# 语法 
limit_conn_status code;
# 默认
limit_conn_status 503;
```

- 配置被限流后返回的状态码，默认返回503。
- 可以配置的模块: http, server, location。

**limit_conn_log_level**

```nginx
# 语法 
limit_conn_log_level info | notice | warn | error;
# 默认
limit_conn_log_level error;
```

- 配置记录被限流后的日志级别，默认error级别。
- 可以配置的模块: http, server, location。

 **limit_conn 的主要执行过程如下**

1. 请求进入后首先判断当前`limit_conn_zone`中相应KEY的连接数是否超出了配置的最大连接数。

2. 如果超过了配置的最大大小，则被限流，返回`limit_conn_status`定义的错误状态码。

   否则相应KEY的连接数加1，并注册请求处理完成的回调函数。

3. 进行请求处理。

4. 在结束请求阶段会调用注册的回调函数对相应KEY的连接数减1。 

**注意**

- limt_conn可以限流某个KEY的总并发/请求数，KEY可以根据需要变化。



#### 设置白名单

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
```

- geo 对于白名单(子网或IP都可以) 将返回0，其他IP将返回1。
- map 将 $limit 转换为 $limit_key，如果是 $limit 是0(白名单)，则返回空字符串；如果是1，则返回客户端实际IP。
- limit_req_zone 限流的key不再使用 $binary_remote_addr，而是 $limit_key 来动态获取值。如果是白名单，limit_req_zone 的限流key则为空字符串，将不会限流；若不是白名单，将会对客户端真实IP进行限流。

#### 限制数据传输速度

这个限制是针对每个请求的，表示客户端下载前20M时不限速，后续限制100kb/s。

```nginx
location /flv/ {
  flv;
  limit_rate_after 20m;
  limit_rate       100k;
}
```

#### 配置参考

```nginx
http {
  limit_conn_zone $binary_remote_addr zone=addr:10m;
  limit_conn_zone $server_name zone=perserver:10m;
  limit_conn_log_level error;
  limit_conn_status 597;
  
  limit_req_zone $binary_remote_addr zone=one:10m rate=2r/s;
  limit_req_zone $http_host zone=perhost:10m rate=2r/s;
  limit_req_log_level error;
  limit_req_status 598;
  
  server {
    location / {
      limit_conn addr 10;
      limit_conn perserver 10;
      limit_req zone=one burst=10 nodelay;
      limit_req zone=perhost burst=10 nodelay;
    }
    
    error_page 597 598 /59x.html;
      location = /59x.html {
        root   html;
    }
  }
}
```

**Cloudflare 使用 proxy status 域名解析**

```nginx
  limit_req_zone $http_x_forwarded_for zone=one:10m rate=10r/s;
  limit_req zone=one burst=300 nodelay;
```

**Cloudflare 使用 proxy status 域名解析，并且使用 AWS ALB 负载均衡器**

网络配置中有负载均衡，并且是双 NGINX 实例，限制数需要除以2.

```nginx
  limit_req_zone $binary_remote_addr zone=one:10m rate=5r/s;
  limit_req zone=one burst=150 nodelay;

  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 162.0.0.0/8;
  real_ip_header X-Forwarded-For;
  real_ip_recursive on;
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



