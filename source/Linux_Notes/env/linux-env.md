# Linux 相关部署环境

## php72 环境

1. 配置 PHP72 环境

   ```shell
   $ yum install epel-release
   $ cd /opt/
   $ yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
   $ yum install yum-utils -y
   $ yum update -y
   $ yum install php72 -y
   $ php72 -v
   $ yum install php72-php-fpm php72-php-gd \
         php72-php-json php72-php-mbstring \
         php72-php-mysqlnd php72-php-xml \
         php72-php-xmlrpc php72-php-opcache -y
   
   $ systemctl enable php72-php-fpm.service
   $ systemctl start php72-php-fpm.service
   $ systemctl status php72-php-fpm.service
   $ cd /etc/opt/remi/php72/php-fpm.d/
   $ cd /etc/opt/remi/php72
   $ echo '<?php phpinfo(); ?>' | php 2>&1 |grep -i error_log
   
   
   # Ubuntu
   $ sudo apt-get install php7.2 php7.2-fpm php7.2-mysql
   ```

2. 配置 phpredis 环境

   ```shell
   $ php72 -info | grep redis
   $ php72 -m | grep redis
   
   # yum list php
   # yum remove php.x86_64
   $ rpm -qa | grep php
   $ rpm -e php-cli-5.4.16-48.el7.x86_64
   $ rpm -e php-common-5.4.16-48.el7.x86_64
   $ rpm -e php-mysql-5.4.16-48.el7.x86_64
   $ rpm -e php-pdo-5.4.16-48.el7.x86_64
   
   $ yum install -y php72-php-devel pcre-devel
   $ cd /tmp
   $ wget https://github.com/phpredis/phpredis/archive/refs/tags/5.3.4.tar.gz
   $ tar -zxf 5.3.4.tar.gz && cd phpredis-5.3.4/
   $ /opt/remi/php72/root/usr/bin/phpize
   $ ./configure  --with-php-config=/opt/remi/php72/root/usr/bin/php-config
   $ make && make install
   
   $ cd /etc/opt/remi/php72/php.d/
   $ echo "extension=/opt/remi/php72/root/usr/lib64/php/modules/redis.so" > \    
       /etc/opt/remi/php72/php.d/redis.ini
   
   $ systemctl restart php72-php-fpm.service
   $ php72 -m | grep redis
   ```

## 设置 GitHub 代理

```shell
$ git config --global url."https://hub.fastgit.org".insteadOf https://github.com
```

## GoLang 环境

```shell
# 下载地址：https://golang.google.cn/dl/
$ sudo chmod 777 /etc/profile.d
# 默认安装版本为：1.17.3
# 默认安装目录为用户家目录，安装其他目录请确保执行用户对路径有操作权限
# 命令示例：sh golang_install.sh --help

# 安装
$ bash <(curl -s "https://raw.githubusercontent.com/TenderLeeks/Documentation/main/scripts/golang.sh") --install
# 国内请使用以下命令
$ bash <(curl -s "https://gitee.com/ken200930/Documentation/raw/main/scripts/golang.sh") --install

# 卸载
$ bash <(curl -s "https://raw.githubusercontent.com/TenderLeeks/Documentation/main/scripts/golang.sh") --uninstall
# 国内请使用以下命令
$ bash <(curl -s "https://gitee.com/ken200930/Documentation/raw/main/scripts/golang.sh") --uninstall

# 设置golang代理
$ export GOPROXY=https://goproxy.cn
$ export GOPROXY=https://athens.azurefd.net
```

## node 环境

```shell
# 下载地址：https://nodejs.org/dist
$ sudo chmod 777 /etc/profile.d
$ NODE_VERSION="v16.9.1"  # 默认安装版本为：v16.9.1
$ DIR="/opt"  # 安装目录，确保用户有DIR目录权限，默认安装目录为用户家目录

# 命令示例：sh node_install.sh install_all ${NODE_VERSION} ${DIR}
# 安装
$ bash <(curl -s "https://raw.githubusercontent.com/TenderLeeks/Documentation/main/scripts/node_install.sh") install

# 安装 yarn pm2 cnpm apidoc 等
$ bash <(curl -s "https://raw.githubusercontent.com/TenderLeeks/Documentation/main/scripts/node_install.sh") install_all

# 卸载
$ bash <(curl -s "https://raw.githubusercontent.com/TenderLeeks/Documentation/main/scripts/node_install.sh") uninstall


# node版本管理工具(其他方法)
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
$ nvm install v14
```



```shell
# Pm2 常用命令
$ cnpm install pm2 -g
$ pm2 list
$ pm2 log
$ pm2 stop ${SERVER_NAME}
$ pm2 delete ${SERVER_NAME}
$ pm2 start cnpm --name "${SERVER_NAME}" -- run start
```



## Ubuntu18.04 设置开机自启动服务

Ubuntu-18.04不能像ubuntu14一样通过编辑rc.local来设置开机启动脚本，通过下列简单设置后，可以使rc.local重新发挥作用。

1. 编辑rc-local.service文件

   ```shell
   $ vim /etc/systemd/system/rc-local.service
   # 在rc-local.service文件中加入以下内容
   [Install]  
   WantedBy=multi-user.target  
   Alias=rc-local.service
   ```

   一般启动文件需要三个组成部分

   > [Unit]段: 启动顺序与依赖关系
   >
   > [Service] 段: 启动行为,如何启动，启动类型
   >
   > [Install] 段: 定义如何安装这个配置文件，即怎样做到开机启动

2. 创建文件rc.local

   **Ubuntu-18.04 默认是没有 /etc/rc.local 这个文件的，需要自己创建**

   ```shell
   $ vim /etc/rc.local
   
   # 将下列内容复制进rc.local文件
   #!/bin/sh -e
   #
   # rc.local
   # This script is executed at the end of each multiuser runlevel.
   # Make sure that the script will "exit 0" on success or any other
   # value on error.
   # In order to enable or disable this script just change the execution
   # bits.
   # By default this script does nothing.
   sudo echo "在这里行写入你需自启动服务的脚本" > /usr/local/rc.local.log
   exit 0
   ```

3. 给rc.local加上权限

   ```shell
   $ chmod +x /etc/rc.local
   ```

4. 服务管理

   ```shell
   $ systemctl enable rc-local
   $ systemctl start rc-local.service  # 启动服务
   $ systemctl status rc-local.service  # 检查状态
   ```

5. 查看日志文件

   ```shell
   $ tail -n 10 /usr/local/rc.local.log
   ```

   

## 系统时间同步

```shell
$ vim /var/spool/cron/root
# 同步系统时间-腾讯云
*/10 * * * * /usr/sbin/ntpdate time1.cloud.tencent.com >/dev/null 2>&1
# 同步系统时间-阿里云
*/10 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1
# 阿里云内网
* * * * * /usr/sbin/ntpdate ntp.cloud.aliyuncs.com >/dev/null 2>&1

# 修改时区
$ tzselect
$ rm -f /etc/localtime
$ ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
$ date
```

## 系统sudo权限设置

```tex
sudo权限：/bin/whoami 为只读用户，/bin/*,/sbin/* 为root权限

设置常规权限
ALL,!/bin/bash,!/bin/su,!/bin/vim /etc/sudoers,!/usr/bin/vim /etc/sudoers,!/usr/sbin/visudo,!/usr/bin/sudo -i,!/bin/chmod 777 /etc/*,!/bin/chmod 777 *,!/bin/chmod 777,!/bin/chmod -R 777 *,!/bin/rm /,!/bin/rm /srv,!/bin/rm /data,!/bin/rm /opt,!/bin/rm /*,!/bin/rm /etc,!/bin/rm /etc/*,!/bin/rm /root,!/bin/rm /root/*,!/bin/rm /bin,!/bin/rm /bin/*,!/bin/rm /usr/bin,!/bin/rm /usr/bin/*,!/bin/rm /usr/sbin,!/bin/rm /usr/sbin/*,!/usr/bin/passwd,!/bin/passwd,!/bin/kill
```



```shell
$ visudo

root    ALL=(ALL:ALL) ALL

# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL

# See sudoers(5) for more information on "#include" directives:

#includedir /etc/sudoers.d
ubuntu  ALL=(ALL:ALL) NOPASSWD: ALL
deploy ALL=(ALL) NOPASSWD: ALL
dev ALL=(ALL) NOPASSWD: ALL
ops ALL=(ALL) NOPASSWD: ALL
wh ALL=(ALL) NOPASSWD: /bin/whoami
```

## 添加系统用户

```shell
$ groupadd deploy; useradd deploy -m -s /bin/bash -d /home/deploy -g deploy
$ useradd guest -m -s /bin/bash -d /home/guest -g deploy
```

参数说明：

```shell
-s /sbin/nologin设置不能登陆-s /bin/false(老方法) 也行
-d 设置用户主目录
-g 用户组
-m 创建用户目录
更改用户登录权限
在增加了-s /sbin/nologin参数后，那么这个帐号就不能登陆了，如果想要恢复登陆使用
usermod -s /bin/bash username
禁用用户登录权限
usermod -s /sbin/nologin username
```

## Java JDK 环境

```shell
# 根据操作系统选择下载JDK版本，官方下载链接：https://www.oracle.com/java/technologies/downloads/#java11
$ export DIR="/opt"
$ export NAME="jdk-11.0.14"
$ tar -zxf jdk-11.0.14_linux-x64_bin.tar.gz -C ${DIR}
# 解压后的目录中是没有jre配置，增加jre配置执行命令
$ ${DIR}/${NAME}/bin/jlink --module-path jmods --add-modules \
    java.desktop --output ${DIR}/${NAME}/jre

$ tee /etc/profile.d/java-11.sh << EOF
export JAVA_HOME=${DIR}/${NAME}
export PATH=\${JAVA_HOME}/bin:\${JAVA_HOME}/jre/bin:\$PATH
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JAVA_HOME}/jre/lib
EOF

$ source /etc/profile
```

## 安装 .NET 6.0 SDK

[官方文档](https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-6.0.400-linux-x64-binaries)

```shell
# 下载源码
$ wget https://download.visualstudio.microsoft.com/download/pr/cd0d0a4d-2a6a-4d0d-b42e-dfd3b880e222/008a93f83aba6d1acf75ded3d2cfba24/dotnet-sdk-6.0.400-linux-x64.tar.gz -P /tmp

$ mkdir -p /opt/dotnet && tar zxf /tmp/dotnet-sdk-6.0.400-linux-x64.tar.gz -C /opt/dotnet

$ echo -e "export DOTNET_ROOT=/opt/dotnet\nexport PATH=\$PATH:/opt/dotnet" >> /etc/profile

```



