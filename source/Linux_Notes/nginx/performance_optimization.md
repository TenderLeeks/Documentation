# Nginx 性能优化

1. 简介

   在大多数情况下，一个常规安装的Nginx对网站来说已经能很好地工作了。然而如果想挤压出Nginx的性能，就需要了解哪些指令会影响Nginx性能，在本文中将解释Nginx的哪些设置可以微调。需要注意一点，这是一个简单的预览——那些可以通过微调来提高性能设置的概述，不同的环境可能情况不太一样。

   **对于Nginx的调优，可以大致从如下指令着手：**

   > worker_processes 
   > worker_connections
   > Buffers
   > Timeouts
   > Gzip Compression
   > Static File Caching
   > logging

2. worker_processes

   - `worker_processes` 表示工作进程的数量，一般情况设置成CPU核的数量即可，一个cpu配置多于一个worker数，对Nginx而言没有任何益处，另外不要忘了设置 `worker_cpu_affinity`，这个配置用于将 `worker process` 与指定 cpu 核绑定，降低由于多CPU核切换造成的寄存器等现场重建带来的性能损耗。 
   - `grep processor /proc/cpuinfo | wc -l` 这个命令会告诉你当前机器是多少核，输出为2即表示2核。

3. worker_connections

   配置表示每个工作进程的并发连接数，默认设置为1024。

   ```nginx
   worker_processes 1;
   worker_connections 1024;
   ```

4. Buffers

   `Buffers`：另一个很重要的参数为buffer，如果buffer太小，Nginx会不停的写一些临时文件，这样会导致磁盘不停的去读写，现在我们先了解设置buffer的一些相关参数： 

   - `client_body_buffer_size`: 允许客户端请求的最大单个文件字节数。

   - `client_header_buffer_size`: 用于设置客户端请求的Header头缓冲区大小，大部分情况1KB大小足够。

   - `client_max_body_size`: 设置客户端能够上传的文件大小，默认为1m。

   - `large_client_header_buffers`: 该指令用于设置客户端请求的Header头缓冲区大小。

     具体可参考配置如下：

     ```nginx
     client_body_buffer_size 10K;
     client_header_buffer_size 1k;
     client_max_body_size 8m;
     large_client_header_buffers 2 1k;
     ```

5. Timeouts

   - `client_header_timeout`和 `client_body_timeout` 设置请求头和请求体(各自)的超时时间，如果没有发送请求头和请求体，Nginx服务器会返回408错误或者 request time out。 

   - `keepalive_timeout` 给客户端分配 keep-alive 链接超时时间。服务器将在这个超时时间过后关闭链接，我们将它设置低些可以让 Nginx 持续工作的时间更长。

   -  `send_timeout` 指定客户端的响应超时时间。这个设置不会用于整个转发器，而是在两次客户端读取操作之间。如果在这段时间内，客户端没有读取任何数据，Nginx就会关闭连接。
     具体可参考配置如下：

     ```nginx
     client_body_timeout 12;
     client_header_timeout 12;
     keepalive_timeout 15;
     send_timeout 10;
     ```

6. Gzip Compression

   开启Gzip，gzip可以帮助Nginx减少大量的网络传输工作，另外要注意 gzip_comp_level 的设置，太高的话，Nginx服务会浪费CPU的执行周期。
   具体可参考配置如下：

   ```nginx
   gzip on;
   gzip_comp_level 2;
   gzip_min_length 1000;
   gzip_proxied expired no-cache no-store private auth;
   gzip_types text/plain application/x-javascript text/xml text/css application/xml;
   ```

7. Static File Caching

   ```nginx
   location ~* .(jpg|jpeg|png|gif|ico|css|js)$ {
       expires 365d;
   }
   # 以上的文件类型可以根据Nginx服务器匹配增加或减少。
   ```

8. logging

   `access_log` 设置Nginx是否将存储访问日志。关闭这个选项可以让读取磁盘IO操作更快。 可以修改配置文件将该功能关闭：

   ```nginx
   access_log off;
   ```

 