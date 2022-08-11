# tomcat9更换运行模式为Apr模式

Tomcat支持三种接收请求的处理方式：BIO、NIO、APR 。

- BIO由于每个请求都要创建一个线程来处理，线程开销比较大，不能再高并发的场景，性能也是最低的。
- NIO是一个基于缓冲区、并能提供非阻塞I/O操作的Java API，比传统的bio更好的并发性能。
- APR（Apache Portable Run-time libraries）简单理解，就是从操作系统级别解决异步IO问题，大幅度的提高服务器的处理和响应性能， 也是Tomcat运行高并发应用的首选模式。

所需软件下载[地址](https://mirrors.cnnic.cn/apache/apr/)    tomcat-native在tomcat的bin下

```tex
* apr
* apr-iconv
* apr-util
* tomcat-native
```

## 依赖安装

```shell
$ yum install -y apr-devel openssl-devel gcc make expat-devel libtool
```

## 软件安装

```shell
$ cd /usr/local/src
$ wget https://mirrors.cnnic.cn/apache/apr/apr-1.6.5.tar.gz
$ tar xf apr-1.6.5.tar.gz
$ cd apr-1.6.5/
$ ./configure --prefix=/usr/local/apr
$ make && make install

$ cd /usr/local/src
$ wget https://mirrors.cnnic.cn/apache/apr/apr-iconv-1.2.2.tar.gz
$ tar xf apr-iconv-1.2.2.tar.gz
$ cd apr-iconv-1.2.2/
$ ./configure --with-apr=/usr/local/apr --prefix=/usr/local/apr-iconv
$ make && make install

$ cd /usr/local/src
$ wget https://mirrors.cnnic.cn/apache/apr/apr-util-1.6.1.tar.gz
$ tar xf apr-util-1.6.1.tar.gz
$ cd apr-util-1.6.1/
$ ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr --with-apr-iconv=/usr/local/apr-iconv/bin/apriconv
$ make && make install

$ cd /srv/tomcat-8080/bin/
$ tar xf tomcat-native.tar.gz
$ cd /srv/tomcat-8080/bin/tomcat-native-1.2.23-src/native
$ ./configure --with-apr=/usr/local/apr --with-java-home=/srv/jdk
$ make && make install

$ echo -e 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/apr/lib\nexport LD_RUN_PATH=$LD_RUN_PATH:/usr/local/apr/lib' >> /etc/profile

$ source /etc/profile
```



## 配置

```shell
$ vim /srv/tomcat-8080/conf/server.xml

<Executor name="tomcatThreadPool" 
          namePrefix="catalina-exec-"
          maxThreads="300" 
          minSpareThreads="30"/>

<Connector executor="tomcatThreadPool" 
               port="8080" 
               protocol="org.apache.coyote.http11.Http11AprProtocol"
               connectionTimeout="20000"
               redirectPort="8443"
               acceptCount="900"
               disableUploadTimeout="true"
               URIEncoding="UTF-8"
               enableLookups="false"
               compression="on"
               compressionMinSize="1024"
               />

<!-- Define an AJP 1.3 Connector on port 8009 --> ##注释掉下面那行，如果不用apache
<!-- <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" /> -->
```



## 测试

```shell
$ /srv/tomcat-8080/bin/catalina.sh run
14-Oct-2019 14:46:05.122 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-apr-8080"]
```

**注：**如果非root用户启动失败，把apr环境变量在当前用户的.bash_profile中写一份

## 配置说明

**Executor重要参数说明：**

- name：共享线程池的名字。这是Connector为了共享线程池要引用的名字，该名字必须唯一。默认值：None；
- namePrefix:在JVM上，每个运行线程都可以有一个name 字符串。这一属性为线程池中每个线程的name字符串设置了一个前缀，Tomcat将把线程号追加到这一前缀的后面。默认值：catalina-exec-；
- maxThreads：该线程池可以容纳的最大线程数。默认值：150；
  maxIdleTime：在Tomcat关闭一个空闲线程之前，允许空闲线程持续的时间(以毫秒为单位)。只有当前活跃的线程数大于minSpareThread的值，才会关闭空闲线程。默认值：60000(一分钟)。
- minSpareThreads：Tomcat应该始终打开的最小不活跃线程数。默认值：4。
- threadPriority：线程的等级。默认是Thread.NORM_PRIORITY

**Connector重要参数说明：**

- maxThreads :Tomcat 使用线程来处理接收的每个请求，这个值表示 Tomcat 可创建的最大的线程数，默认值是 200
- minSpareThreads：最小空闲线程数，Tomcat 启动时的初始化的线程数，表示即使没有人使用也开这么多空线程等待，默认值是 10。
- maxSpareThreads：最大备用线程数，一旦创建的线程超过这个值，Tomcat 就会关闭不再需要的 socket 线程。
- 上边配置的参数，最大线程 500（一般服务器足以），要根据自己的实际情况合理设置，设置越大会耗费内存和 CPU，因为 CPU 疲于线程上下文切换，没有精力提供请求服务了，最小空闲线程数 20，线程最大空闲时间 60 秒，当然允许的最大线程连接数还受制于操作系统的内核参数设置，设置多大要根据自己的需求与环境。当然线程可以配置在“tomcatThreadPool”中，也可以直接配置在“Connector”中，但不可以重复配置。
- URIEncoding：指定 Tomcat 容器的 URL 编码格式，语言编码格式这块倒不如其它 WEB 服务器软件配置方便，需要分别指定。
- connnectionTimeout： 网络连接超时，单位：毫秒，设置为 0 表示永不超时，这样设置有隐患的。通常可设置为 30000 毫秒，可根据检测实际情况，适当修改。
- enableLookups： 是否反查域名，以返回远程主机的主机名，取值为：true 或 false，如果设置为false，则直接返回IP地址，为了提高处理能力，应设置为 false。
- disableUploadTimeout：上传时是否使用超时机制。
- connectionUploadTimeout：上传超时时间，毕竟文件上传可能需要消耗更多的时间，这个根据你自己的业务需要自己调，以使Servlet有较长的时间来完成它的执行，需要与上一个参数一起配合使用才会生效。
- acceptCount：指定当所有可以使用的处理请求的线程数都被使用时，可传入连接请求的最大队列长度，超过这个数的请求将不予处理，默认为100个。
- keepAliveTimeout：长连接最大保持时间（毫秒），表示在下次请求过来之前，Tomcat 保持该连接多久，默认是使用 connectionTimeout 时间，-1 为不限制超时。
- maxKeepAliveRequests：表示在服务器关闭之前，该连接最大支持的请求数。超过该请求数的连接也将被关闭，1表示禁用，-1表示不限制个数，默认100个，一般设置在100~200之间。
- compression：是否对响应的数据进行 GZIP 压缩，off：表示禁止压缩；on：表示允许压缩（文本将被压缩）、force：表示所有情况下都进行压缩，默认值为off，压缩数据后可以有效的减少页面的大小，一般可以减小1/3左右，节省带宽。
- compressionMinSize：表示压缩响应的最小值，只有当响应报文大小大于这个值的时候才会对报文进行压缩，如果开启了压缩功能，默认值就是2048。
- compressableMimeType：压缩类型，指定对哪些类型的文件进行数据压缩。
- noCompressionUserAgents="gozilla, traviata"： 对于以下的浏览器，不启用压缩。
  如果已经对代码进行了动静分离，静态页面和图片等数据就不需要 Tomcat 处理了，那么也就不需要配置在 Tomcat 中配置压缩了。