# OpenVPN 服务使用配置

## 源码下载信息

1. OpenVPN软件版本
   * [GitHub地址](https://github.com/OpenVPN/openvpn)
   * 文档使用版本：openvpn-2.4.10.tar.gz

2. easy-rsa软件版本
   - [GitHub地址](https://github.com/OpenVPN/easy-rsa)
   - 文档使用版本：easy-rsa-3.0.7.tar.gz

3. 客户端安装
   - [官网](https://openvpn.net/) 下载地址
   - 如果widows安装软件在官方访问失败，那么可以从如下[地址](https://www.techspot.com/downloads/5182-openvpn.html)下载

## 系统配置

1. 允许IP转发

   原因：从客户端访问server端局域网其他主机需要通过VPN机器中转。

   ```shell
   $ vim /etc/sysctl.conf
   # Controls IP packet forwarding
   net.ipv4.ip_forward = 1	
   $ sysctl -p
   ```
   
2. iptables 配置

   **只需添加配置，不需要启动iptables服务**

   原因：客户端连接VPN后，默认分配的10.8.0.0/24网段地址，不能直接访问server端局域网其他主机【这两台是172.21.0.0/24网段】，因此需要在iptables进行nat配置。

   ```shell
   # 执行以下命令
   $ iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
   $ iptables -t nat -A POSTROUTING -s 10.252.252.0/24 -o eth0 -j MASQUERADE
   $ iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
   $ iptables -t nat -A POSTROUTING -s 175.41.214.38/32 -o eth0 -j MASQUERADE
   $ iptables -t nat -A POSTROUTING -s 123.56.233.208/32 -o eth0 -j MASQUERADE
   $ iptables-save > /etc/sysconfig/iptables
   $ iptables -L -n -t nat
   
   Chain PREROUTING (policy ACCEPT)
   target     prot opt source               destination 
   
   Chain INPUT (policy ACCEPT)
   target     prot opt source               destination 
   
   Chain OUTPUT (policy ACCEPT)
   target     prot opt source               destination 
   
   Chain POSTROUTING (policy ACCEPT)
   target     prot opt source               destination 
   MASQUERADE  all  --  10.8.0.0/24          0.0.0.0/0
   ```

   **删除上面的iptables配置信息命令如下**。 (此命令不需要执行)

   作用：对比正常的访问和异常的访问

   ```shell
   $ iptables -t nat -D POSTROUTING 1
   ```

3. 同步系统时间与硬件时间

   说明：如果时间不同步，那么VPN登录访问就可能存在问题。

   ```shell
   # 定时任务同步系统时间
   $ crontab -l
   */10 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1  # 阿里云设置这个
   */10 * * * * /usr/sbin/ntpdate time1.tencentyun.com >/dev/null 2>&1  # 腾讯云设置这个
   
   # 使用上海时间
   $ ll /etc/localtime
   # 查看硬件时间
   $ hwclock --show
   # 系统时间同步到硬件时间
   $ hwclock --systohc
   ```

## 安装 OpenVPN

1. 安装依赖包

   ```shell
   yum install -y lz4-devel lzo-devel pam-devel openssl-devel systemd-devel sqlite-devel gcc gcc-c++ openssl
   ```

   如果是阿里云和腾讯云等云主机，可能还需要装如下包：

   ```shell
   yum install -y autoconf
   yum install -y automake
   yum install -y libtool libtool-ltdl
   ```

2. 编译 OpenVPN

   从github上下载openvpn源代码包并解压后编译安装，最后建立软连接

   ```shell
   $ cd /tmp
   $ wget https://github.com/OpenVPN/openvpn/archive/v2.4.10.zip
   $ mv v2.4.10.zip openvpn-2.4.10.zip
   $ unzip openvpn-2.4.10.zip
   $ cd openvpn-2.4.10/
   $ autoreconf -i -v -f
   $ ./configure --prefix=/opt/openvpn --enable-lzo --enable-lz4 --enable-crypto --enable-server --enable-plugins --enable-port-share --enable-iproute2 --enable-pf --enable-plugin-auth-pam --enable-pam-dlopen --enable-systemd
   $ make && make install
   $ ln -s /opt/openvpn/sbin/openvpn /usr/local/sbin/openvpn
   ```

3. 配置文件

   ```shell
   $ cp -a /opt/openvpn/lib/systemd/system/openvpn-server@.service /opt/openvpn/lib/systemd/system/openvpn.service
   $ vim /opt/openvpn/lib/systemd/system/openvpn.service
   ### 找到 ExecStart 这行，改为如下
   ExecStart=/opt/openvpn/sbin/openvpn --config server.conf
   ```
   
4. 配置系统服务，并开机自启动

   ```shell
   $ cp -a /opt/openvpn/lib/systemd/system/openvpn.service /usr/lib/systemd/system/openvpn.service
   $ systemctl enable openvpn.service
   ```

## OpenVPN 证书配置

1. 配置 easy-rsa

   ```shell
   $ cd /tmp
   $ wget https://github.com/OpenVPN/easy-rsa/archive/v3.0.7.zip
   $ mv v3.0.7.zip easy-rsa-3.0.7.zip
   $ unzip easy-rsa-3.0.7.zip
   $ mv easy-rsa-3.0.7 /opt/openvpn
   ```

   根据 easy-rsa-3.0.7/easyrsa3/vars.example 文件生成全局配置文件 vars

   ```shell
   $ cd /opt/openvpn/easy-rsa-3.0.7/easyrsa3
   $ cp -a vars.example vars
   ```

   修改vars文件，根据需要去掉注释，并修改对应值；**或者直接在文件末尾追加如下信息：**

   ```shell
   set_var EASYRSA_REQ_COUNTRY     "CN"  # 国家
   set_var EASYRSA_REQ_PROVINCE    "BJ"  # 省
   set_var EASYRSA_REQ_CITY        "BeiJing"  # 城市
   set_var EASYRSA_REQ_ORG "Ystar"  # 组织
   set_var EASYRSA_REQ_EMAIL       "yushuai@ystar.io"  # 邮箱
   set_var EASYRSA_REQ_OU          "Ken"  # 拥有者
   set_var EASYRSA_KEY_SIZE        2048  # 长度
   set_var EASYRSA_ALGO            rsa  # 算法
   set_var EASYRSA_CA_EXPIRE       36500  # CA证书过期时间，单位天
   set_var EASYRSA_CERT_EXPIRE     36500  # 签发证书的有效期是多少天，单位天
   ```

2. 生成服务端和客户端证书

   1. 初始化与创建CA根证书

      ```shell
      $ ./easyrsa init-pki
      ```

      初始化，会在当前目录创建PKI目录，用于存储一些中间变量及最终生成的证书

      ```shell
      $ ./easyrsa build-ca
      ```

      在这部分需要输入PEM密码 PEM pass phrase，输入两次，此密码必须记住，不然以后不能为证书签名。
      还需要输入common name 通用名，如：openvpen，这个你自己随便设置个独一无二的。

   2. 生成服务端证书

      ```shell
      $ ./easyrsa build-server-full server nopass
      ```

      为服务端生成证书对并在本地签名。nopass参数生成一个无密码的证书；在此过程中会让你确认ca密码

      **设置的密码为：xxxx**

      ```shell
      $ ./easyrsa gen-dh
      ```

      创建Diffie-Hellman，确保key穿越不安全网络的命令，时间会有点长，耐心等待

   3. 生成客户端证书

      生成多个客户端证书

      ```shell
      # 无密码，实际应用中不推荐，客户端有密码可提高安全性
      $ ./easyrsa build-client-full client nopass
      # 让你输入密码，后续VPN连接时会使用
      $ ./easyrsa build-client-full ken
      ```
      
      为客户端生成证书对并在本地签名。nopass参数生成一个无密码的证书；在此过程中都会让你确认ca密码
      
      **为了提高安全性，生成ta.key**
      
      ```shell
      $ openvpn --genkey --secret ta.key
      ```
      
      加强认证方式，防攻击。如果配置文件中启用此项(默认是启用的)，就需要执行上述命令，并把ta.key放到/etc/openvpn/server目录。配置文件中服务端第二个参数为0，同时客户端也要有此文件，且client.conf中此指令的第二个参数需要为1。【服务端有该配置，那么客户端也必须要有】
      
   4. 整理服务端证书
   
      ```shell
      $ mkdir -p /etc/openvpn/server/
      $ cp -a pki/ca.crt /etc/openvpn/server/
      $ cp -a pki/private/server.key /etc/openvpn/server/
      $ cp -a pki/issued/server.crt /etc/openvpn/server/
      $ cp -a pki/dh.pem /etc/openvpn/server/
      $ cp -a ta.key /etc/openvpn/server/
      ```

## 服务端配置文件

可以参照源码包中 openvpn-2.4.10/sample/sample-config-files/server.conf 文件

```shell
$ vim /etc/openvpn/server/server.conf
# 服务端的监听地址
local 0.0.0.0
# 监听的端口，默认是1194
port 11194
# 使用的协议，有udp和tcp。建议选择tcp
proto tcp
# 使用三层路由IP隧道(tun)还是二层以太网隧道(tap)。一般都使用tun
dev tun
# ca证书、服务端证书、服务端密钥和密钥交换文件。如果它们和server.conf在同一个目录下则可以不写绝对路径，否则需要写绝对路径调用
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh.pem

# vpn服务端为自己和客户端分配IP的地址池
# 服务端自己获取网段的第一个地址(此处为10.8.0.1)，后为客户端分配其他的可用地址。以后客户端就可以和10.8.0.1进行通信
# 注意：该网段地址池不要和已有网段冲突或重复。其实一般来说是不用改的。除非当前内网使用了10.8.0.0/24的网段
server 10.252.252.0 255.255.255.0

# 使用一个文件记录已分配虚拟IP的客户端和虚拟IP的对应关系
# 以后openvpn重启时，将可以按照此文件继续为对应的客户端分配此前相同的IP。也就是自动续借IP的意思
ifconfig-pool-persist ipp.txt

# vpn服务端向客户端推送vpn服务端内网网段的路由配置，以便让客户端能够找到服务端内网。多条路由就写多个Push指令
push "route 172.21.0.0 255.255.255.0"

push "dhcp-option DNS 10.150.0.51"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 114.114.114.114"
push "route 175.41.214.38 255.255.255.255"
push "route 54.150.235.168 255.255.255.255"
push "route 54.150.20.59 255.255.255.255"
push "route 123.56.239.158 255.255.255.255"
push "route 123.56.233.208 255.255.255.255"

# 让vpn客户端之间可以互相看见对方，即能互相通信。默认情况客户端只能看到服务端一个人
# 默认是注释的，不能客户端之间相互看见
client-to-client

# 允许多个客户端使用同一个VPN帐号连接服务端
# 默认是注释的，不支持多个客户登录一个账号
;duplicate-cn

# 每10秒ping一次，120秒后没收到ping就说明对方挂了
keepalive 10 120

# 加强认证方式，防攻击。如果配置文件中启用此项(默认是启用的)
# 需要执行openvpn --genkey --secret ta.key，并把ta.key放到etc目录
# 服务端第二个参数为0；同时客户端也要有此文件，且client.conf中此指令的第二个参数需要为1
tls-auth /etc/openvpn/server/ta.key 0

# 选择一个密码。如果在服务器上使用了cipher选项，那么您也必须在这里指定它。注意，v2.4客户端/服务器将在TLS模式下自动协商AES-256-GCM
cipher AES-256-CBC

# openvpn 2.4版本的vpn才能设置此选项。表示服务端启用lz4的压缩功能，传输数据给客户端时会压缩数据包
compress lz4-v2
# Push后在客户端也配置启用lz4的压缩功能，向服务端发数据时也会压缩。如果是2.4版本以下的老版本，则使用用comp-lzo指令
push "compress lz4-v2"

# 启用lzo数据压缩格式。此指令用于低于2.4版本的老版本。且如果服务端配置了该指令，客户端也必须要配置
;comp-lzo

# 并发客户端的连接数
max-clients 1000

user nobody
group nobody

# 通过ping得知超时时，当重启vpn后将使用同一个密钥文件以及保持tun连接状态
persist-key
persist-tun
# 在文件中输出当前的连接信息，每分钟截断并重写一次该文件
status openvpn-status.log

# 默认vpn的日志会记录到rsyslog中，使用这两个选项可以改变
# log指令表示每次启动vpn时覆盖式记录到指定日志文件中
# log-append则表示每次启动vpn时追加式的记录到指定日志中
# 但两者只能选其一，或者不选时记录到rsyslog中
log  /opt/openvpn/log/openvpn.log

# 日志记录的详细级别
verb 5

# 沉默的重复信息。最多20条相同消息类别的连续消息将输出到日志
;mute 20
# 当服务器重新启动时，通知客户端，以便它可以自动重新连接。仅在UDP协议是可用
;explicit-exit-notify 1
```

## 启动服务

```shell
$ systemctl start openvpn.service
```

查看进程与端口

```shell
$ ps -ef | grep 'openvpn'
$ netstat -lntup | grep '11194'
```

通过ifconfig命令，也可见多个tun0网卡信息

```shell
tun0: flags=4305<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST>  mtu 1500
        inet 10.8.0.1  netmask 255.255.255.255  destination 10.8.0.2
        inet6 fe80::ede4:8db8:12ac:4571  prefixlen 64  scopeid 0x20<link>
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 100  (UNSPEC)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 144 (144.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

## 客户端证书

1. 客户端配置文件

   ```shell
   $ vim /etc/openvpn/server/client.conf
   
   # 标识这是个客户端
   client
   # 使用三层路由IP隧道(tun)还是二层以太网隧道(tap)。服务端是什么客户端就是什么
   dev tun
   # 使用的协议，有udp和tcp。服务端是什么客户端就是什么
   proto tcp
   # 服务端的地址和端口
   remote 49.232.122.196 11194
   # 一直尝试解析OpenVPN服务器的主机名
   # 在机器上非常有用，不是永久连接到互联网，如笔记本电脑
   resolv-retry infinite
   # 大多数客户机不需要绑定到特定的本地端口号
   nobind
   # 初始化后的降级特权(仅非windows)
   ;user nobody
   ;group nobody
   # 尝试在重新启动时保留某些状态
   persist-key
   persist-tun
   
   # ca证书、客户端证书、客户端密钥
   # 如果它们和client.conf或client.ovpn在同一个目录下则可以不写绝对路径，否则需要写绝对路径调用
   # ca ca.crt
   # cert client.crt
   # key client.key
   # 通过检查certicate是否具有正确的密钥使用设置来验证服务器证书
   remote-cert-tls server
   # 加强认证方式，防攻击。服务端有配置，则客户端必须有
   # tls-auth ta.key 1
   # 选择一个密码。如果在服务器上使用了cipher选项，那么您也必须在这里指定它。注意，v2.4客户端/服务器将在TLS模式下自动协商AES-256-GCM
   cipher AES-256-CBC
   # 服务端用的什么，客户端就用的什么
   # 表示客户端启用lz4的压缩功能，传输数据给客户端时会压缩数据包
   compress lz4-v2
   # 日志级别
   verb 3
   # 沉默的重复信息。最多20条相同消息类别的连续消息将输出到日志
   ;mute 20
   key-direction 1
   ```

2. 发送邮件脚本 mail.py

   ```python
   #!/usr/bin/python
   # -*- coding: UTF-8 -*-
   import yagmail
   import sys
   import os
   from datetime import *
   from_user='xxxxx@xxxx.io'
   from_pwd='*********'
   from_host='smtp.exmail.qq.com'
   from_portt='465'
   #接收人列表
   to_user = sys.argv[1]
   #邮件标题
   title = u'OpenVPN 配置文件信息'
   #抄送人列表
   c_user = ''
   file_pwd = sys.argv[2]
   open_file = sys.argv[3]
   conten1 = 'Hello All:'
   conten2 = f'附件为 OpenVPN 配置文件, 密码为 {file_pwd}, 请妥善保管'
   conten3 = '\n'
   conten4 = 'OpenVPN 客户端下载地址：'
   conten5 = 'windowns: https://ystar-resource-dev-1252223875.cos.ap-beijing.myqcloud.com/openvpn-connect-3.2.2.1455_signed.msi'
   conten6 = 'mac: https://ystar-resource-dev-1252223875.cos.ap-beijing.myqcloud.com/openvpn-connect-3.2.5.2468_signed.dmg'
   contents = [conten1, conten2, conten3, conten4, conten5, conten6]
   #链接邮箱服务器
   yag = yagmail.SMTP(user=from_user, password=from_pwd, host=from_host, port=from_portt)
   # 发送邮件
   yag.send(to_user, title, contents, open_file)
   ```

3. 生成客户端证书脚本 generate_client.sh

   ```shell
   #!/bin/bash
   
   SERVER_DIR=/etc/openvpn/server
   CLIENT_DIR=/opt/openvpn/client-conf
   CRT_DIR=/opt/openvpn/easy-rsa-3.0.7/easyrsa3/pki/issued
   KEY_DIR=/opt/openvpn/easy-rsa-3.0.7/easyrsa3/pki/private
   REQS_DIR=/opt/openvpn/easy-rsa-3.0.7/easyrsa3/pki/reqs
   
   USER_MAIL=${1}
   USER=$(echo ${USER_MAIL} | cut -f1 -d "@")
   USER_NAME=ystar-bingoo-${USER}
   
   CLIENT_FILE=${CLIENT_DIR}/${USER_NAME}.ovpn
   
   USER_PWD=$(cat /proc/sys/kernel/random/uuid | cut -f5 -d "-")
   CA_PWD='ystar'
   
   str=`echo ${USER_MAIL} | gawk '/^([a-zA-Z0-9_\-\.\+]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/{print $0}'`
   
   if [ ! -n "${str}" ]; then
      echo -e "\033[32m********************************************************\033[0m"
      echo -e "\033[32m****** 输入的邮件地址不合法，请重新输入: \033[0m\033[31m${USER_MAIL}\033[0m"
      echo -e "\033[32m********************************************************\033[0m"
      exit 1
   fi
   
   if [ -f ${REQS_DIR}/${USER_NAME}.req ]; then
      echo -e "\033[32m********************************************************\033[0m"
      echo -e "\033[32m****** 文件: \033[0m\033[31m${REQS_DIR}/${USER_NAME}.req\033[0m\033[32m 已存在\033[0m"
      echo -e "\033[32m请重新输入用户名或者删除文件后在执行脚步\033[0m"
      echo -e "\033[32m********************************************************\033[0m"
      echo
      exit 1
   elif [ -f ${CRT_DIR}/${USER_NAME}.crt ]; then
      echo -e "\033[32m********************************************************\033[0m"
      echo -e "\033[32m****** 文件: \033[0m\033[31m${CRT_DIR}/${USER_NAME}.crt\033[0m\033[32m 已存在\033[0m"
      echo -e "\033[32m请重新输入用户名或者删除文件后在执行脚步\033[0m"
      echo -e "\033[32m********************************************************\033[0m"
      echo
      exit 1
   elif [ -f ${KEY_DIR}/${USER_NAME}.key ]; then
      echo -e "\033[32m********************************************************\033[0m"
      echo -e "\033[32m****** 文件: \033[0m\033[31m${KEY_DIR}/${USER_NAME}.key\033[0m\033[32m 已存在\033[0m"
      echo -e "\033[32m请重新输入用户名或者删除文件后在执行脚步\033[0m"
      echo -e "\033[32m********************************************************\033[0m"
      echo
      exit 1
   fi
   
   if [ "x${1}" != "x" ]; then
       echo -e "\033[32m********************************************************\033[0m"
       echo -e "\033[32m****** 生成OpenVPN配置文件密码：\033[0m\033[31m${USER_PWD}\033[0m"
       echo -e "\033[32m****** 请输入上方密码生成配置文件\033[0m"
       echo -e "\033[32m****** CA文件证书密码为：\033[0m\033[31m${CA_PWD}\033[0m"
       echo -e "\033[32m********************************************************\033[0m"
   
       cd /opt/openvpn/easy-rsa-3.0.7/easyrsa3
       # echo -e "${USER_PWD}\n${USER_PWD}\n${CA_PWD}" | /opt/openvpn/easy-rsa-3.0.7/easyrsa3/easyrsa build-client-full ${USER_NAME}
       /opt/openvpn/easy-rsa-3.0.7/easyrsa3/easyrsa build-client-full ${USER_NAME}
       # echo -e "${CA_PWD}" | /opt/openvpn/easy-rsa-3.0.7/easyrsa3/easyrsa build-client-full ${USER_NAME} nopass
   else
       echo -e "\033[32m********************************************************\033[0m"
       echo -e "\033[31m****** Please enter a user name.\033[0m"
       echo -e "\033[32m********************************************************\033[0m"
       exit 1
   fi
   
   if [ -f ${CRT_DIR}/${USER_NAME}.crt ] && [ -f ${KEY_DIR}/${USER_NAME}.key ]; then
       cat ${SERVER_DIR}/client.conf > ${CLIENT_FILE}
       echo -e '<ca>' >> ${CLIENT_FILE}
       cat ${SERVER_DIR}/ca.crt >> ${CLIENT_FILE}
       echo -e '</ca>\n<cert>' >> ${CLIENT_FILE}
       cat ${CRT_DIR}/${USER_NAME}.crt >> ${CLIENT_FILE}
       echo -e '</cert>\n<key>' >> ${CLIENT_FILE}
       cat ${KEY_DIR}/${USER_NAME}.key >> ${CLIENT_FILE}
       echo -e '</key>\n<tls-auth>' >> ${CLIENT_FILE}
       cat ${SERVER_DIR}/ta.key >> ${CLIENT_FILE}
       echo -e '</tls-auth>' >> ${CLIENT_FILE}
       echo -e "\033[32m********************************************************\033[0m"
       echo -e "\033[32m****** \033[0m\033[31msuccessful\033[0m"
       echo -e "\033[32m********************************************************\033[0m"
   
   else
       echo -e "\033[32m********************************************************\033[0m"
       echo "\033[31m******\033[0m\033[32mnot fount file ${CRT_DIR}/${USER_NAME}.crt and ${KEY_DIR}/${USER_NAME}.key"
       echo -e "\033[32m********************************************************\033[0m"
   fi
   
   /opt/python38/bin/python3.8 /opt/openvpn/mail.py ${USER_MAIL} ${USER_PWD} ${CLIENT_FILE}
   ```

## 附录1：[参考文档](http://www.zhangblog.com/2020/05/09/openvpn01/)

## 附录2：Linux 客户端

1. 安装 OpenVPN

   请参照上述步骤安装

2. 配置系统服务，并开机自启动

   ```shell
   $ cp -a /opt/openvpn/lib/systemd/system/openvpn-client@.service /opt/openvpn/lib/systemd/system/openvpn-client.service
   $ vim /opt/openvpn/lib/systemd/system/openvpn-client.service
   ##################################################
   [Service]
   Type=notify
   PrivateTmp=true
   WorkingDirectory=/etc/openvpn/client
   ExecStart=/opt/openvpn/sbin/openvpn --config client.conf
   ##################################################
   
   $ cp -a /opt/openvpn/lib/systemd/system/openvpn-client.service /usr/lib/systemd/system/openvpn-client.service
   $ systemctl enable openvpn-client.service
   ```

3. Client 配置

   备注：文件名 windows为 client.ovpn，Linux为 client.conf

   需要的证书与配置文件如下：

   > 注意路径，在 /etc/openvpn/ 目录下建立了 client 目录
   >
   > ca.crt、client.crt、client.key、ta.key 都是之前创建好的，只有 client.conf 需要单独下载并修改。

   ```shell
   $ ll /etc/openvpn/client
   -rw------- 1 root root 1147 4月  21 15:40 ca.crt
   -rw-r--r-- 1 root root  310 4月  21 15:57 client.conf
   -rw-r--r-- 1 root root 4408 4月  21 15:45 client.crt
   -rw-r--r-- 1 root root 1704 4月  21 15:47 client.key
   -rw------- 1 root root  636 4月  21 15:43 ta.key
   ```
   
4. client.conf 文件内容

   参照源码中 openvpn-2.4.10/sample/sample-config-files/client.conf 文件

   ```shell
   $ cat client.conf
   
   client
   dev tun
   proto tcp
   remote 49.232.122.196 11194
   resolv-retry infinite
   nobind
   
   ;user nobody
   ;group nobody
   
   persist-key
   persist-tun
   
   ca ca.crt
   cert client.crt
   key client.key
   remote-cert-tls server
   tls-auth ta.key 1
   cipher AES-256-CBC
   compress lz4-v2
   log  /opt/openvpn/log/openvpn-client.log
   verb 3
   ;mute 20
   ```

5. 启动服务

   ```shell
   $ systemctl start openvpn-client.service 
   ```

