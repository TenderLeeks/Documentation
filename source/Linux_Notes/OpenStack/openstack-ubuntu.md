# Ubuntu 22.04 安装 OpenStack 服务

## OpenStack 安装指南

本文是参考官方文档进行环境安装部署：[官方文档链接](https://docs.openstack.org/install-guide/)

## 环境配置

官方链接：https://docs.openstack.org/install-guide/environment.html



必须使用具有管理权限的帐户来配置每个节点。以用户身份运行命令`root`或配置`sudo` 实用程序。

系统硬件最低要求：

- 控制器节点：1 个处理器、4 GB 内存和 5 GB 存储空间
- 计算节点：1 个处理器、2 GB 内存和 10 GB 存储空间

随着 OpenStack 服务和虚拟机数量的增加，对最佳性能的硬件要求也在增加。如果在启用其他服务或虚拟机后性能下降，请考虑向您的环境添加硬件资源。

### 安全

官方链接：https://docs.openstack.org/install-guide/environment-security.html

OpenStack 服务支持各种安全方法，包括密码、策略和加密。此外，包括数据库服务器和消息代理在内的支持服务支持密码安全。

为了简化安装过程，本指南仅在适用的情况下介绍密码安全。您可以手动创建安全密码，但服务配置文件中的数据库连接字符串不能接受“@”等特殊字符。[我们建议您使用诸如pwgen](https://sourceforge.net/projects/pwgen/)之类的工具 或通过运行以下命令来生成它们：

```bash
$ openssl rand -hex 10
```

对于 OpenStack 服务，本指南用于`SERVICE_PASS`引用服务帐户密码和`SERVICE_DBPASS`引用数据库密码。

下表提供了需要密码的服务列表及其在指南中的相关参考。

| 密码名称                 | 描述                           |
| ------------------------ | ------------------------------ |
| 数据库密码（未使用变量） | 数据库的 root 密码             |
| **ADMIN_PASS**           | 用户admin的密码                |
| **CINDER_DBPASS**        | 块存储服务的数据库密码         |
| **CINDER_PASS**          | 块存储服务用户 `cinder` 的密码 |
| **DASH_DBPASS**          | 仪表板的数据库密码             |
| **DEMO_PASS**            | 用户`demo`密码                 |
| **GLANCE_DBPASS**        | 图片服务的数据库密码           |
| **GLANCE_PASS**          | 图像服务用户`glance`的密码     |
| **KEYSTONE_DBPASS**      | 身份服务的数据库密码           |
| **METADATA_SECRET**      | 元数据代理的秘密               |
| **NEUTRON_DBPASS**       | 网络服务的数据库密码           |
| **NEUTRON_PASS**         | 网络服务用户`neutron`的密码    |
| **NOVA_DBPASS**          | 计算服务的数据库密码           |
| **NOVA_PASS**            | 计算服务用户`nova`的密码       |
| **PLACEMENT_PASS**       | 配售服务用户`placement`的密码  |
| **RABBIT_PASS**          | RabbitMQ用户`openstack`的密码  |

OpenStack 和支持服务在安装和操作期间需要管理权限。在某些情况下，服务会对主机进行修改，这可能会干扰 Ansible、Chef 和 Puppet 等部署自动化工具。例如，一些 OpenStack 服务添加了一个根包装器，`sudo`这可能会干扰安全策略。 有关详细信息，请参阅 [Pike 的计算服务文档](https://docs.openstack.org/nova/pike/admin/root-wrap-reference.html)、 [Queens 的计算服务文档](https://docs.openstack.org/nova/queens/admin/root-wrap-reference.html)或 [Rocky 的计算服务文档。](https://docs.openstack.org/nova/rocky/admin/root-wrap-reference.html)

网络服务采用内核网络参数的默认值并修改防火墙规则。为避免在初始安装期间出现大多数问题，我们建议在您的主机上使用受支持发行版的库存部署。但是，如果您选择自动部署您的主机，请在继续下一步之前查看应用于它们的配置和策略。

### 主机联网

官方链接：https://docs.openstack.org/install-guide/environment-networking.html

**⚠️警告：重新配置网络接口将中断网络连接。我们建议对这些过程使用本地终端会话。**

#### 控制器节点

查询网关命令：`route -n`

##### 配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：192.168.67.19

   网络掩码：255.255.255.0（或/24）

   默认网关：192.168.64.1

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， **eth1**或**ens3**。

   Ubuntu系统编辑`/etc/network/interfaces`文件以包含以下内容：

   ```bash
   # 提供商网络接口
   auto INTERFACE_NAME
   iface INTERFACE_NAME inet manual
   up ip link set dev $IFACE up
   down ip link set dev $IFACE down
   ```

   在 Ubuntu 系统中，`/etc/network/interfaces` 文件用于配置网络接口的设置。这个文件定义了系统中网络接口的配置参数，以便系统能够正确地管理网络连接。每个网络接口都在文件中用一组配置行来表示。下面是给定配置的解释：

   - `auto INTERFACE_NAME`：这一行指示系统在启动时自动激活指定的网络接口。`INTERFACE_NAME` 应该替换为实际的网络接口名称，比如 `eth0` 或 `wlan0`。

   - `iface INTERFACE_NAME inet manual`：这一行定义了接口的配置。`INTERFACE_NAME` 应该替换为实际的网络接口名称。`inet manual` 表示该接口将会由手动配置管理，而不是通过 DHCP 自动获取网络设置。

   - `up ip link set dev $IFACE up`：这一行在接口启动时运行指定的命令。`$IFACE` 是一个特殊的变量，它会被实际的接口名称替换。`ip link set dev $IFACE up` 这个命令会将指定的网络接口置为启用状态，使其能够传输和接收数据。

   - `down ip link set dev $IFACE down`：这一行在接口关闭时运行指定的命令。与上面类似，`$IFACE` 会被实际的接口名称替换。`ip link set dev $IFACE down` 这个命令会将指定的网络接口置为禁用状态，从而停止数据的传输和接收。

   综上所述，这个配置片段的含义是：

   - 在系统启动时，自动激活某个指定的网络接口。
   - 指定该接口将由手动配置管理，而不会通过 DHCP 自动获取网络设置。
   - 在接口启动时，将该接口置为启用状态。
   - 在接口关闭时，将该接口置为禁用状态。
   - 这种配置方式通常用于一些特定的网络设置，例如需要手动配置 IP 地址、子网掩码和网关等情况。

3. 重新启动系统以激活更改。

##### 配置名称解析

1. 将节点的主机名设置为`controller`。

   ```bash
   hostnamectl set-hostname controller
   ```

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   192.168.67.19       controller
   
   # compute1
   192.168.67.25       compute1
   
   # block1
   192.168.67.26       block1
   
   # object1
   192.168.67.27       object1
   
   # object2
   192.168.67.28       object2
   ```

   ⚠️警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**

#### 计算节点

##### 配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：192.168.67.25

   网络掩码：255.255.255.0（或/24）

   默认网关：192.168.64.1

   其他计算节点应使用 192.168.67.35、192.168.67.45 等。

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， **eth1**或**ens3**。

   对于Ubuntu系统编辑`/etc/network/interfaces`文件以包含以下内容：

   ```bash
   # The provider network interface
   auto INTERFACE_NAME
   iface  INTERFACE_NAME inet manual
   up ip link set dev $IFACE up
   down ip link set dev $IFACE down
   ```

3. 重新启动系统以激活更改。

##### 配置名称解析

1. 将节点的主机名设置为`compute1`。

   ```bash
   hostnamectl set-hostname compute1
   ```

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   192.168.67.19       controller
   
   # compute1
   192.168.67.25       compute1
   
   # block1
   192.168.67.26       block1
   
   # object1
   192.168.67.27       object1
   
   # object2
   192.168.67.28       object2
   ```

   ⚠️警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**

#### 验证连通性

我们建议您在进一步操作之前验证到 Internet 和节点之间的网络连接。

1. 从控制器节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 docs.openstack.org
   PING static01.opendev.org (23.253.245.150) 56(84) bytes of data.
   64 bytes from static01.opendev.org (23.253.245.150): icmp_seq=1 ttl=43 time=247 ms
   64 bytes from static.opendev.org (23.253.245.150): icmp_seq=2 ttl=43 time=246 ms
   64 bytes from static.opendev.org (23.253.245.150): icmp_seq=3 ttl=43 time=246 ms
   64 bytes from static.opendev.org (23.253.245.150): icmp_seq=4 ttl=43 time=247 ms
   
   --- static01.opendev.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3000ms
   rtt min/avg/max/mdev = 246.015/246.565/247.338/0.534 ms
   ```

2. 从控制器节点，测试对计算节点上管理界面的访问 ：

   ```bash
   # ping -c 4 compute1
   PING compute1 (192.168.67.25) 56(84) bytes of data.
   64 bytes from compute1 (192.168.67.25): icmp_seq=1 ttl=64 time=1.44 ms
   64 bytes from compute1 (192.168.67.25): icmp_seq=2 ttl=64 time=0.545 ms
   64 bytes from compute1 (192.168.67.25): icmp_seq=3 ttl=64 time=0.902 ms
   64 bytes from compute1 (192.168.67.25): icmp_seq=4 ttl=64 time=0.735 ms
   
   --- compute1 ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3005ms
   rtt min/avg/max/mdev = 0.545/0.905/1.439/0.333 ms
   ```

3. 从计算节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 docs.openstack.org
   PING static01.opendev.org (23.253.245.150) 56(84) bytes of data.
   64 bytes from static01.opendev.org (23.253.245.150): icmp_seq=1 ttl=48 time=187 ms
   64 bytes from static01.opendev.org (23.253.245.150): icmp_seq=2 ttl=48 time=188 ms
   64 bytes from static01.opendev.org (23.253.245.150): icmp_seq=3 ttl=48 time=190 ms
   64 bytes from static01.opendev.org (23.253.245.150): icmp_seq=4 ttl=48 time=187 ms
   
   --- static01.opendev.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3003ms
   rtt min/avg/max/mdev = 186.573/187.578/189.616/1.241 ms
   ```

4. 从*计算节点，测试对**控制器*节点上管理界面的访问 ：

   ```bash
   # ping -c 4 controller
   PING controller (192.168.67.19) 56(84) bytes of data.
   64 bytes from controller (192.168.67.19): icmp_seq=1 ttl=64 time=0.772 ms
   64 bytes from controller (192.168.67.19): icmp_seq=2 ttl=64 time=0.780 ms
   64 bytes from controller (192.168.67.19): icmp_seq=3 ttl=64 time=0.693 ms
   64 bytes from controller (192.168.67.19): icmp_seq=4 ttl=64 time=0.654 ms
   
   --- controller ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3003ms
   rtt min/avg/max/mdev = 0.654/0.724/0.780/0.053 ms
   ```

   

### 网络时间协议 (NTP)

官方链接：https://docs.openstack.org/install-guide/environment-ntp.html

要在节点之间正确同步服务，您可以安装 `Chrony`，它是[NTP](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Time-Protocol-NTP)的一个实现。我们建议您配置控制器节点以引用更准确的（较低层）服务器和其他节点以引用控制器节点。

#### 控制器节点

在**控制器节点**上执行这些步骤。

```bash
# 安装软件包
apt install -y chrony

# 备份NTP服务的原始配置文件
mv /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak

# 编辑该 chrony.conf 文件并根据您的环境的需要添加、更改或删除以下项。
# 对于 Ubuntu，编辑 /etc/chrony/chrony.conf 文件

vim /etc/chrony/chrony.conf
----------
# server NTP_SERVER iburst
server ntp.ubuntu.com iburst
# server ntp.aliyun.com iburst
# 替换 NTP_SERVER 为合适的更准确（下层）NTP 服务器的主机名或 IP 地址。该配置支持多个server密钥。

# 默认情况下，控制器节点通过公共服务器池同步时间。但是，您可以选择配置替代服务器，例如您的组织提供的服务器。

# 要使其他节点能够连接到控制器节点上的 chrony 守护进程，请将此密钥添加到上述同 chrony.conf 文件中
allow 192.168.0.0/16
-----------

# 重启 NTP 服务
service chrony restart
```

#### 其他节点

其他节点参考控制器节点进行时钟同步。在所有其他节点上执行这些步骤。

```bash
# 安装软件包
apt install -y chrony

# 备份NTP服务的原始配置文件
mv /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak

# 配置chrony.conf文件并注释掉或删除除一个server键以外的所有键。将其更改为引用控制器节点。
# 编辑 /etc/chrony/chrony.conf 文件
vim /etc/chrony/chrony.conf
---------
server controller iburst

# 注释掉该行。pool 2.debian.pool.ntp.org offline iburst
---------

# 重新启动 NTP 服务
service chrony restart
```

#### 验证操作

我们建议您先验证 NTP 同步，然后再继续。一些节点，特别是那些引用控制器节点的节点，可能需要几分钟才能同步。

1. *在控制器*节点上运行此命令：

   ```bash
   $ chronyc sources
   
   MS Name/IP address         Stratum Poll Reach LastRx Last sample               
   ===============================================================================
   ^* 203.107.6.88                  2   8   377   234  +2265us[+2849us] +/-   15ms
   ```

   **Name/IP address**栏中的内容应表示一台或多台NTP服务器的主机名或IP地址。MS栏中的内容应为当前同步NTP服务的服务器标明。

2. 在所有其他节点上运行相同的命令：

   ```bash
   $ chronyc sources
   
   MS Name/IP address         Stratum Poll Reach LastRx Last sample               
   ===============================================================================
   ^* controller                    3   6   377    29    -85us[ -203us] +/-   17ms
   ```

   **Name/IP address**栏中的内容应表示控制器节点的主机名。



### OpenStack 软件包

官方链接：https://docs.openstack.org/install-guide/environment-packages.html

由于不同的发布计划，发行版将 OpenStack 包作为发行版的一部分或使用其他方法发布。在所有节点上执行这些过程。

此处描述的 OpenStack 包的设置需要在所有节点上完成：控制器、计算和块存储节点。

⚠️警告：在继续之前，您的主机必须包含可用于您的分发的最新版本的基本安装包。

禁用或删除任何自动更新服务，因为它们会影响您的 OpenStack 环境。

#### 适用于 Ubuntu 的 OpenStack 软件包

**适用于 Ubuntu 20.04 LTS 的 OpenStack Yoga：**

```bash
add-apt-repository cloud-archive:yoga
```

**示例安装**

```bash
apt install -y nova-compute
```

**客户端安装**

```bash
apt install -y python3-openstackclient
```

### 适用 Ubuntu 的 SQL数据库

大多数 OpenStack 服务使用 SQL 数据库来存储信息。数据库通常在控制器节点上运行。本指南中的过程根据发行版使用 MariaDB 或 MySQL。OpenStack 服务还支持其他 SQL 数据库，包括 [PostgreSQL](https://www.postgresql.org/)。

如果您在 OpenStack 服务上看到或 出现错误日志消息，请验证最大连接数设置是否适用于您的环境。在 MariaDB 中，您可能还需要更改 [open_files_limit](https://mariadb.com/kb/en/library/server-system-variables/#open_files_limit) 配置。`Too many connectionsToo many open files`

从 Ubuntu 16.04 开始，MariaDB 被更改为使用“unix_socket Authentication Plugin”。现在使用用户凭据 (UID) 执行本地身份验证，默认情况下不再使用密码身份验证。这意味着 root 用户不再使用密码来本地访问服务器。

从 Ubuntu 18.04 开始，**`mariadb-server`**默认存储库中不再提供该软件包。要成功安装，请**`Universe`**在 Ubuntu 上启用存储库。

```bash
# 安装软件包
# 从 Ubuntu 20.04 开始，安装软件包
apt install -y mariadb-server python3-pymysql

# 创建和编辑 /etc/mysql/mariadb.conf.d/99-openstack.cnf 文件并完成以下操作
# 创建一个[mysqld]section，将key设置bind-address 为controller节点的管理IP地址，
# 以允许其他节点通过管理网络访问。设置附加键以启用有用的选项和 UTF-8 字符集：
vim /etc/mysql/mariadb.conf.d/99-openstack.cnf
-----------
[mysqld]
bind-address = 192.168.67.19

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
-----------

# 重启数据库服务
service mysql restart

# 运行下面这个命令设置root密码，设置完成后还会有一些初始化操作，根据提示一路Y就可以了
mysql_secure_installation
```

### 适用 Ubuntu 的消息队列

OpenStack 使用[消息队列](https://docs.openstack.org/install-guide/common/glossary.html#term-message-queue)来协调服务之间的操作和状态信息。消息队列服务通常在控制器节点上运行。OpenStack 支持多种消息队列服务，包括[RabbitMQ](https://www.rabbitmq.com/)、 [Qpid](https://qpid.apache.org/)和[ZeroMQ](http://zeromq.org/)。但是，大多数打包 OpenStack 的发行版都支持特定的消息队列服务。本指南实现了 RabbitMQ 消息队列服务，因为大多数发行版都支持它。如果您更喜欢实现不同的消息队列服务，请查阅与其相关的文档。

**消息队列在控制器节点上运行。**

```bash
# 安装包
apt install -y rabbitmq-server

# 添加openstack用户，替换 RABBIT_PASS 为合适的密码。
rabbitmqctl add_user openstack RABBIT_PASS

# 允许 openstack用户进行配置、写入和读取访问
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```



### 适用 Ubuntu 的内存缓存

服务的身份服务认证机制使用 Memcached 来缓存令牌。memcached 服务通常在控制器节点上运行。对于生产部署，我们建议启用防火墙、身份验证和加密的组合来保护它。

```bash
# 安装软件包，对于 Ubuntu 18.04 和更新版本，请使用
apt install -y memcached python3-memcache

# 编辑/etc/memcached.conf文件并将服务配置为使用控制器节点的管理 IP 地址。这是为了允许其他节点通过管理网络访问，更改具有.-l 127.0.0.1
vim /etc/memcached.conf
----------
-l 192.168.67.19
----------

# 重启 Memcached 服务：
service memcached restart
```

### 适用 Ubuntu 的 Etcd

OpenStack 服务可能会使用 Etcd，一种分布式可靠的键值存储，用于分布式键锁定、存储配置、跟踪服务活跃度等场景。

**etcd 服务在控制器节点上运行。**

1. 安装 etcd 包

   ```bash
   apt install -y etcd
   ```

   从 Ubuntu 18.04 开始，etcd默认存储库中不再提供该软件包。要成功安装，请Universe在 Ubuntu 上启用存储库。

2. 编辑`/etc/default/etcd`文件，并将`ETCD_INITIAL_CLUSTER`、`ETCD_INITIAL_ADVERTISE_PEER_URLS`、`ETCD_ADVERTISE_CLIENT_URLS`、`ETCD_LISTEN_CLIENT.URLS`设置为控制器节点的管理IP地址，以使其他节点能够通过管理网络进行访问：

   ```bash
   vim /etc/default/etcd
   -----------
   ETCD_NAME="controller"
   ETCD_DATA_DIR="/var/lib/etcd/default"
   ETCD_INITIAL_CLUSTER_STATE="new"
   ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
   ETCD_INITIAL_CLUSTER="controller=http://192.168.67.19:2380"
   ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.67.19:2380"
   ETCD_ADVERTISE_CLIENT_URLS="http://192.168.67.19:2379"
   ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
   ETCD_LISTEN_CLIENT_URLS="http://192.168.67.19:2379"
   ```

3. 启用并重启 etcd 服务

   ```bash
   systemctl enable etcd
   systemctl restart etcd
   ```



## 安装 OpenStack 服务

官方链接：https://docs.openstack.org/install-guide/openstack-services.html

### Yoga 的最小部署

您至少需要安装以下服务。按照下面指定的顺序安装服务：

- 身份服务–[keystone installation for Yoga](https://docs.openstack.org/keystone/yoga/install/)

- 图像服务–[glance installation for Yoga](https://docs.openstack.org/glance/yoga/install/)

- 安置服务– [placement installation for Yoga](https://docs.openstack.org/placement/yoga/install/)

- 计算服务–[nova installation for Yoga](https://docs.openstack.org/nova/yoga/install/)

- 网络服务–[neutron installation for Yoga](https://docs.openstack.org/neutron/yoga/install/)

我们建议您在安装最低部署服务后，也安装以下组件：

- 仪表板–[horizon installation for Yoga](https://docs.openstack.org/horizon/yoga/install/)

- 砌块储存服务–[cinder installation for Yoga](https://docs.openstack.org/cinder/yoga/install/)



## 安装 Keystone

官方链接：https://docs.openstack.org/keystone/yoga/install/

OpenStack 系统由几个单独安装的关键服务组成。这些服务根据您的云需求协同工作，包括计算、身份、网络、图像、块存储、对象存储、遥测、编排和数据库服务。您可以单独安装这些项目中的任何一个，并将它们配置为独立的或连接的实体。

本节介绍如何在控制器节点上安装和配置代号为 keystone 的 OpenStack Identity 服务。出于可扩展性目的，此配置部署 Fernet 令牌和 Apache HTTP 服务器来处理请求。

### 身份服务概述

OpenStack Identity服务为管理身份验证、授权和服务目录提供了单点集成。

Identity服务通常是用户与之交互的第一个服务。一旦经过认证，最终用户可以使用其身份访问其他OpenStack服务。同样，其他OpenStack服务利用Identity服务来确保用户是他们所说的人，并发现其他服务在部署中的位置。Identity服务还可以与一些外部用户管理系统（如LDAP）集成。

用户和服务可以通过使用由Identity服务管理的服务目录来查找其他服务。顾名思义，服务目录是OpenStack部署中可用服务的集合。每个服务可以有一个或多个端点，每个端点可以是三种类型之一：admin、internal或public。在生产环境中，出于安全原因，不同的端点类型可能位于向不同类型的用户公开的不同网络上。例如，公共API网络可能在互联网上可见，因此客户可以管理他们的云。管理API网络可能仅限于管理云基础设施的组织内的运营商。内部API网络可能仅限于包含OpenStack服务的主机。此外，OpenStack支持多个区域的可扩展性。为简单起见，本指南将管理网络用于所有端点类型和默认RegionOne区域。在Identity服务中创建的区域、服务和端点一起构成了部署的服务目录。部署中的每个OpenStack服务都需要一个服务条目，其中包含存储在Identity服务中的相应端点。这都可以在安装和配置Identity服务后完成。

Identity服务包含以下组件：

- **Server**

  集中式服务器使用RESTful接口提供身份验证和授权服务。

- **Drivers**

  驱动程序或服务后端集成到集中服务器。它们用于访问OpenStack外部存储库中的身份信息，并且可能已经存在于部署OpenStack的基础架构中（例如，SQL数据库或LDAP服务器）。

- **Modules**

  中间件模块在使用Identity服务的OpenStack组件的地址空间中运行。这些模块拦截服务请求，提取用户凭据，并将其发送到集中服务器进行授权。中间件模块和OpenStack组件之间的集成使用Python Web服务器网关接口。

### 数据库配置

```bash
# 使用数据库访问客户端以 root 用户身份连接到数据库服务器
mysql -u root -p
Enter password: 123456

# 创建keystone数据库
MariaDB [(none)]> CREATE DATABASE keystone;

# 创建一个keystone用户并设置密码也是 KEYSTONE_DBPASS，专门用于访问keystone数据库
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'KEYSTONE_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';

# 退出mysql
exit;
```

### 安装和配置组件

```bash
apt install -y keystone

# 编辑 /etc/keystone/keystone.conf 文件并完成以下操作，修改如下两处配置：
vim /etc/keystone/keystone.conf
----------
[database]
# ...
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone

[token]
# ...
provider = fernet
```

同步配置到keystone数据库

```bash
su -s /bin/sh -c "keystone-manage db_sync" keystone
```

初始化Fernet密钥存储库

```bash
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

启动Identity服务，运行keystone API

```bash
# 这个 ADMIN_PASS 就是keystone的初始密码，你可以设置成别的。
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
```

到此，keystone的三个接口就运行起来了，web server是apache服务器。

### 配置 Apache HTTP 服务器

```bash
vim /etc/apache2/apache2.conf
----------
ServerName controller
----------
# ServerName如果该条目尚不存在，则需要添加该条目。

# 重启apache服务
service apache2 restart

# 设置环境变量，# ADMIN_PASS 就是之前运行API时候的 bootstrap-password
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
```

### 创建域、项目、用户和角色

Identity服务为每个OpenStack服务提供身份验证服务。身份验证服务使用域、项目、用户和角色的组合。

```bash
# 创建新域
openstack domain create --description "An Example Domain" example

# 创建service 项目
openstack project create --domain default --description "Service Project" service

# 创建myproject项目
openstack project create --domain default --description "Demo Project" myproject

# 创建myuser用户，为了方便记忆，密码也设置成 myuser
openstack user create --domain default --password-prompt myuser

# 创建myrole角色
openstack role create myrole

# 添加myrole角色到myproject项目和myuser用户
openstack role add --project myproject --user myuser myrole
```

### 验证keystone是否安装成功

在控制器节点上执行这些命令。

```bash
# 取消设置临时变量OS_AUTH_URL和OS_PASSWORD 环境变量
unset OS_AUTH_URL OS_PASSWORD

# 用admin用户尝试获取一个token
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue
# 随后提示输入密码，就是之前设置的 ADMIN_PASS


# 用myuser用户尝试获取一个token
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name myproject --os-username myuser token issue
# 密码是 myuser

+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2016-02-12T20:15:39.014479Z                                     |
| id         | gAAAAABWvi9bsh7vkiby5BpCCnc-JkbGhm9wH3fabS_cY7uabOubesi-Me6IGWW |
|            | yQqNegDDZ5jw7grI26vvgy1J5nCVwZ_zFRqPiz_qhbq29mgbQLglbkq6FQvzBRQ |
|            | JcOzq3uwhzNxszJWmzGC7rJE_H0A_a3UFhqv8M4zMRYSbS2YF0MyFmp_U       |
| project_id | ed0b60bf607743088218b0a533d5943f                                |
| user_id    | 58126687cbcc4888bfa9ab73a2256f27                                |
+------------+-----------------------------------------------------------------+
```

### 创建脚本

在controller上编写两个凭证文件

为**admin**和**demo**项目以及用户创建客户端环境脚本。本指南的后续部分将参考这些脚本来为客户端操作加载适当的凭据。

```bash
vim ~/admin-openrc
# 将 ADMIN_PASS 替换为您在Identity服务中为admin用户选择的密码。
----------
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
----------

vim ~/demo-openrc
# 将 DEMO_PASS 替换为您在Identity服务中为demo用户选择的密码。
----------
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=myuser
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
----------
```

### 加载admin-openrc

```bash
. admin-openrc

# 请求身份验证令牌
openstack token issue
+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2023-03-02T07:43:22+0000                                        |
| id         | gAAAAABWvjYj-Zjfg8WXFaQnUd1DMYTBVrKw4h3fIagi5NoEmh21U72SrRv2trl |
|            | JWFYhLi2_uPR31Igf6A8mH2Rw9kv_bxNo1jbLNPLGzW_u5FC7InFqx0yYtTwa1e |
|            | eq2b0f6-18KZyQhs7F3teAta143kJEWuNEYET-y7u29y0be1_64KYkM7E       |
| project_id | 343d245e850143a096806dfaefa9afdc                                |
| user_id    | ac3377633149401296f6c0d92d79dc16                                |
+------------+-----------------------------------------------------------------+
```

到此，所有的keystone安装结束了，官方文档后面的部分是说明如何安装keystone的。

## glance 安装教程

官方链接：https://docs.openstack.org/glance/yoga/install/

### Image服务概述

Image服务（扫视）使用户能够发现、注册和检索虚拟机映像。它提供了一个RESTAPI，使您能够查询虚拟机映像元数据并检索实际映像。您可以将通过Image服务提供的虚拟机映像存储在各种位置，从简单的文件系统到OpenStack object storage等对象存储系统。

重要的：

为了简单起见，本指南介绍了将Image服务配置为使用文件后端，该文件将上载并存储在托管Image服务的控制器节点上的目录中。默认情况下，此目录为/var/lib/show/images/。

在继续之前，请确保控制器节点在此目录中至少有几GB的可用空间。请记住，由于文件后端通常位于控制器节点的本地，因此通常不适合多节点快速部署。

有关其他后端要求的信息，请参阅[配置参考](https://docs.openstack.org/glance/yoga/configuration/index.html)。



OpenStack Image服务是基础设施即服务（IaaS）的核心。它接受来自最终用户或OpenStack Compute组件的磁盘或服务器映像和元数据定义的API请求。它还支持在各种存储库类型上存储磁盘或服务器映像，包括OpenStack对象存储。

OpenStack Image服务上运行许多周期性进程以支持缓存。复制服务通过群集确保一致性和可用性。其他定期流程包括审计员、更新者和收割者。

OpenStack Image服务包括以下组件：

1. **glance-api**

   接受图像发现、检索和存储的图像API调用。

   Pike版本中的一个OpenStack社区目标是通过WSGI部署控制平面API端点。然而，正如目前所构成的那样，扫视api不适合在这样的配置中运行。相反，我们建议Glance以传统方式作为独立服务器运行。有关更多信息，请参阅Pike和Queens版本的概览发行说明中的“已知问题”部分。

2. **Database**

   存储图像元数据，您可以根据自己的喜好选择数据库。大多数部署使用MySQL或SQLite。

3. **Storage repository for image files**

   支持各种存储库类型，包括普通文件系统（或任何安装在glass api控制器节点上的文件系统）、对象存储、RADOS块设备、VMware数据存储和HTTP。请注意，某些存储库仅支持只读使用。

4. **Metadata definition service**

   供供应商、管理员、服务和用户有意义地定义自己的自定义元数据的通用API。该元数据可用于不同类型的资源，如图像、工件、卷、口味和聚合。定义包括新属性的键、描述、约束以及它可以关联的资源类型。

### 数据库配置

```bash
mysql -u root -p
Enter password: 123456

MariaDB [(none)]> CREATE DATABASE glance;

# 用合适的密码替换 GLANCE_DBPASS
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';

exit;
```

加载 admin 用户（在keystone安装时创建）

```bash
. ~/admin-openrc
```

创建glance用户和项目

```bash
# 创建glance用户，密码也设置成 GLANCE_PASS
openstack user create --domain default --password-prompt glance

# 将admin角色添加到glance用户和 service项目中
openstack role add --project service --user glance admin

# 创建glance服务实体
openstack service create --name glance --description "OpenStack Image" image

# 创建图像服务 API 端点
openstack endpoint create --region RegionOne image public http://controller:9292

openstack endpoint create --region RegionOne image internal http://controller:9292

openstack endpoint create --region RegionOne image admin http://controller:9292
```

设置资源限制（可选操作，建议先跳过）

```bash
# 如果决定在Glance中使用per-tenant配额，则必须首先在Keystone中注册限额
openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 1000 --region RegionOne image_size_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 1000 --region RegionOne image_stage_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 100 --region RegionOne image_count_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 100 --region RegionOne image_count_uploading

```

确保在**glance-api.conf**文件中也设置了**use_keystone_quotas=True**。

### 安装和配置Glance

```bash
apt install -y glance

# 编辑 /etc/glance/glance-api.conf 文件并完成以下操作
vim /etc/glance/glance-api.conf
-----------
# 请注意，如果启用此功能，则必须已创建如上所述的注册限制
[DEFAULT]
use_keystone_quotas = True

[database]
# ... 原先这个database组下的已经有的所有配置删除或注释掉!!!
# 我注释了一行backend
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance

[keystone_authtoken]
# 将 GLANCE_PASS 替换为您在Identity服务中为 glance 用户选择的密码
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
# ...
flavor = keystone

# 注释掉或删除 [keystone_authtoken] 部分中的任何其他选项

[glance_store]
# 在 [glance_store] 部分，配置本地文件系统存储和映像文件的位置
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

# 在 [oslo_limit] 部分，配置对 keystone 的访问
[oslo_limit]
auth_url = http://controller:5000
auth_type = password
user_domain_id = default
username = MY_SERVICE
system_scope = all
password = MY_PASSWORD
endpoint_id = ENDPOINT_ID
region_name = RegionOne
```

给MY_SERVICE添加读权限

```bash
openstack role add --user MY_SERVICE --user-domain Default --system all reader
```

同步配置到数据库

```bash
su -s /bin/sh -c "glance-manage db_sync" glance
```

重启glance服务

```bash
service glance-api restart
```

### 验证是否安装成功

Ubuntu Cloud Images：https://cloud-images.ubuntu.com/

```bash
. ~/admin-openrc
# 下载一个cirros镜像用于测试，大小12M

apt -y install wget
# wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -O ~/cirros-0.4.0-x86_64-disk.img 
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img


glance image-create --name "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --visibility=public

+------------------+------------------------------------------------------+
| Field            | Value                                                |
+------------------+------------------------------------------------------+
| checksum         | 133eae9fb1c98f45894a4e60d8736619                     |
| container_format | bare                                                 |
| created_at       | 2015-03-26T16:52:10Z                                 |
| disk_format      | qcow2                                                |
| file             | /v2/images/cc5c6982-4910-471e-b864-1098015901b5/file |
| id               | cc5c6982-4910-471e-b864-1098015901b5                 |
| min_disk         | 0                                                    |
| min_ram          | 0                                                    |
| name             | cirros                                               |
| owner            | ae7a98326b9c455588edd2656d723b9d                     |
| protected        | False                                                |
| schema           | /v2/schemas/image                                    |
| size             | 13200896                                             |
| status           | active                                               |
| tags             |                                                      |
| updated_at       | 2015-03-26T16:52:10Z                                 |
| virtual_size     | None                                                 |
| visibility       | public                                               |
+------------------+------------------------------------------------------+

# 确认上传镜像并验证属性
glance image-list

+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| 38047887-61a7-41ea-9b49-27987d5e8bb9 | cirros | active |
+--------------------------------------+--------+--------+
```



## 安装 placement

**以下操作在controller节点上执行。Plancement是一个API和端口管理服务**

在Stein发布之前，放置代码与计算REST API代码（Nova-API）一起位于Nova中。确保此文档的发布版本与要部署的发布版本匹配。

Placement作为数据模型上的web服务运行。安装包括创建必要的数据库，安装和配置web服务。这是一个简单的过程，但有很多步骤可以将放置与OpenStack云的其余部分集成。

其他一些OpenStack服务（特别是nova）需要放置，因此它应该在其他服务之前安装，但在Identity（keystone）之后安装。

### 数据库配置

```bash
mysql -u root -p
Enter password: 123456

# 创建 placement 数据库
MariaDB [(none)]> CREATE DATABASE placement;

# 授予对数据库的适当访问权限
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
  
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
# 将 PLACEMENT_DBPASS 替换为合适的密码

exit;
```

创建项目和用户

```bash
. ~/admin-openrc

# 创建一个 Placement 服务用户，密码 PLACEMENT_PASS
openstack user create --domain default --password-prompt placement

# 将admin用户添加到 placement
openstack role add --project service --user placement admin

# 在服务目录中创建 Placement API 条目
openstack service create --name placement --description "Placement API" placement

# 创建 Placement API 服务端点
openstack endpoint create --region RegionOne placement public http://controller:8778

openstack endpoint create --region RegionOne placement internal http://controller:8778

openstack endpoint create --region RegionOne placement admin http://controller:8778
```

### 安装和配置 placement

```bash
apt install -y placement-api

# 编辑 /etc/placement/placement.conf 文件并完成以下操作
vim /etc/placement/placement.conf
-----------
[placement_database]
# ...
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement

[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_PASS

# 注释掉或删除 [keystone_authtoken] 部分中的任何其他选项
# user_name、password、project_domain_name 和 user_domain_name 的值需要与您的 keystone 配置同步
```

同步配置到数据库

```bash
su -s /bin/sh -c "placement-manage db sync" placement
```

重启apache 服务

```bash
service apache2 restart
```

### 验证placement是否安装成功

在进行这些调用之前，您需要以管理员身份向身份服务进行身份验证。有许多不同的方法可以做到这一点，具体取决于您的系统设置方式。如果你没有 admin-openrc 文件，你会有类似的东西。

```bash
. ~/admin-openrc

placement-status upgrade check

+-------------------------------------------+
| Upgrade Check Results                     |
+-------------------------------------------+
| Check: Missing Root Provider IDs          |
| Result: Success                           |
| Details: None                             |
+-------------------------------------------+
| Check: Incomplete Consumers               |
| Result: Success                           |
| Details: None                             |
+-------------------------------------------+
| Check: Policy File JSON to YAML Migration |
| Result: Success                           |
| Details: None                             |
+-------------------------------------------+
```

测试placementAPI

```bash
# 安装pip3
apt -y install python3-pip
# 升级pip3
pip3 install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/

# 安装 osc-placement 插件，或从您的发行版安装 python3-osc-placement
pip3 install osc-placement -i https://mirrors.aliyun.com/pypi/simple/


# 列出可用的资源类别和特征
openstack --os-placement-api-version 1.2 resource class list --sort-column name
+----------------------------+
| name                       |
+----------------------------+
| DISK_GB                    |
| IPV4_ADDRESS               |
| ...                        |


openstack --os-placement-api-version 1.6 trait list --sort-column name
+---------------------------------------+
| name                                  |
+---------------------------------------+
| COMPUTE_DEVICE_TAGGING                |
| COMPUTE_NET_ATTACH_INTERFACE          |
| ...                                   |



```

## 安装 nova

官方链接：https://docs.openstack.org/nova/yoga/install/

**nova组件在controller和compute1上都要安装。**

### 在controller上安装nova

#### 配置数据库

```bash
mysql -u root -p
Enter Password：123456

# 创建 nova_api、nova 和 nova_cell0 数据库
MariaDB [(none)]> CREATE DATABASE nova_api;
MariaDB [(none)]> CREATE DATABASE nova;
MariaDB [(none)]> CREATE DATABASE nova_cell0;

# 替换 NOVA_DBPASS 为合适的密码
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

exit;
```

创建项目、用户、角色

```bash
. ~/admin-openrc

# 创建nova用户，密码是 NOVA_PASS
openstack user create --domain default --password-prompt nova

# 将nova用户添加到admin组中变成管理员
openstack role add --project service --user nova admin

# 创建服务实体
openstack service create --name nova \
  --description "OpenStack Compute" compute

# 创建计算 API 服务
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1
```

#### 安装和配置 nova

```bash
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler

# 编辑 /etc/nova/nova.conf 文件并完成以下操作
vim /etc/nova/nova.conf
--------------
[DEFAULT]
# ... 由于打包错误，请从[DEFAULT]部分删除log_dir选项。
my_ip = 192.168.67.19
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/

[api_database]
# ... 该组中已有的配置全部注释掉
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

[database]
# ... 该组中已有的配置全部注释掉
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova

[api]
# ... 该组中已有的配置全部注释掉
auth_strategy = keystone

[keystone_authtoken]
# ... 该组中已有的配置全部注释掉
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[vnc]
enabled = true
# ...
server_listen = $my_ip
server_proxyclient_address = $my_ip

[glance]
# ...
api_servers = http://controller:9292

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp

[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS
```

将配置同步到数据库中

```bash
su -s /bin/sh -c "nova-manage api_db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

su -s /bin/sh -c "nova-manage db sync" nova
```

#### 验证是否安装成功

```bash
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

+-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
|  Name |                 UUID                 |                   Transport URL                    |                     Database Connection                      | Disabled |
+-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
| cell0 | 00000000-0000-0000-0000-000000000000 |                       none:/                       | mysql+pymysql://nova:****@controller/nova_cell0?charset=utf8 |  False   |
| cell1 | f690f4fd-2bc5-4f15-8145-db561a7b9d3d | rabbit://openstack:****@controller:5672/nova_cell1 | mysql+pymysql://nova:****@controller/nova_cell1?charset=utf8 |  False   |
+-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
```

#### 重启服务

```bash
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
```

至此，controller的nova计算服务完成



### 在compute1上安装nova

下面我们在compute1节点上安装nova服务，这个很重要，因为像compute1这种计算节点就是用来运行很多云服务器的，所以nova对于计算节点至关重要。

**以下命令请在compute1节点上执行！！**

#### 安装配置nova

```bash
apt install -y nova-compute

# 编辑 /etc/nova/nova.conf 文件并完成以下操作
vim /etc/nova/nova.conf
---------
[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
# 为计算节点上管理网络接口的 IP 地址
my_ip = 192.168.67.25

[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[vnc]
# ...
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
# ...
api_servers = http://controller:9292

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp

[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS
```

检查计算节点compute1是否支持cpu虚拟化。

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

如果上面这条命令返回1或者大于1，则说明cpu支持虚拟化不需要做额外配置，上面的配置就够了。
如果上面的命令返回0，则虚拟机不支持虚拟化。解决方法有两个

1. 虚拟机关机，然后打开KVM虚拟化功能，在开机。

2. 让compute1节点使用qemu而不是KVM，进行如下配置

   ```bash
   vim /etc/nova/nova-compute.conf
   ----------
   # 把文件中的 virt_type=kvm 修改成 virt_type=qemu
   [libvirt]
   # ...
   virt_type = qemu
   ```

   **注意，以上这个配置只有命令返回0的时候做，返回大于0的（支持虚拟化的）无须进行，直接跳过。**

#### 重启nova服务

```bash
service nova-compute restart
```

如果`nova-compute`服务启动失败，请检查 `/var/log/nova/nova-compute.log`。

该错误消息可能表明控制器节点上的防火墙阻止访问端口 5672。配置防火墙以打开控制器节点上的端口 5672 并重新启动计算节点上的服务。`AMQP server on controller:5672 is unreachable nova-compute`

### 将compute1加到cell数据库

**以下步骤在controller节点执行！！！**

```bash
. ~/admin-openrc

openstack compute service list --service nova-compute

+----+-------+--------------+------+-------+---------+----------------------------+
| ID | Host  | Binary       | Zone | State | Status  | Updated At                 |
+----+-------+--------------+------+-------+---------+----------------------------+
| 1  | node1 | nova-compute | nova | up    | enabled | 2017-04-14T15:30:44.000000 |
+----+-------+--------------+------+-------+---------+----------------------------+


# 让controller节点同步刚发现compute节点的，同步到nova的cell数据库
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

Found 2 cell mappings.
Skipping cell0 since it does not contain hosts.
Getting computes from cell 'cell1': 41f48e02-21a5-48f1-b32b-d1fb9c61b4b5
Checking host mapping for compute host 'controller': 49aa1d82-2ac2-4a78-91d9-9479ff44a20c
Creating host mapping for compute host 'controller': 49aa1d82-2ac2-4a78-91d9-9479ff44a20c
Checking host mapping for compute host 'compute1': db36385a-5006-4865-8281-294437b34adc
Creating host mapping for compute host 'compute1': db36385a-5006-4865-8281-294437b34adc
Found 2 unmapped computes in cell: 41f48e02-21a5-48f1-b32b-d1fb9c61b4b5

# 每次添加新的计算节点 ，如compute2 ，compute3 ......
# 都需要在controller上执行这个nova-manage cell_v2 discover_hosts命令！
# 或者你可以一劳永逸，配置一个定时器，让controller定时去发现计算节点
vim /etc/nova/nova.conf
---------
[scheduler]
discover_hosts_in_cells_interval = 300

```

至此，两台机器都安装完成了nova服务，并将计算节点添加到了控制节点。

### 最后的验证操作

**在控制器节点上执行这些命令。**

```bash
. ~/admin-openrc

# 列出服务组件以验证每个进程的成功启动和注册
openstack compute service list

+----+--------------------+------------+----------+---------+-------+----------------------------+
| Id | Binary             | Host       | Zone     | Status  | State | Updated At                 |
+----+--------------------+------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler     | controller | internal | enabled | up    | 2016-02-09T23:11:15.000000 |
|  2 | nova-conductor     | controller | internal | enabled | up    | 2016-02-09T23:11:16.000000 |
|  3 | nova-compute       | compute1   | nova     | enabled | up    | 2016-02-09T23:11:20.000000 |
+----+--------------------+------------+----------+---------+-------+----------------------------+

# 列出身份服务中的 API 端点以验证与身份服务的连接
openstack catalog list

+-----------+-----------+-----------------------------------------+
| Name      | Type      | Endpoints                               |
+-----------+-----------+-----------------------------------------+
| keystone  | identity  | RegionOne                               |
|           |           |   public: http://controller:5000/v3/    |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:5000/v3/  |
|           |           | RegionOne                               |
|           |           |   admin: http://controller:5000/v3/     |
|           |           |                                         |
| glance    | image     | RegionOne                               |
|           |           |   admin: http://controller:9292         |
|           |           | RegionOne                               |
|           |           |   public: http://controller:9292        |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:9292      |
|           |           |                                         |
| nova      | compute   | RegionOne                               |
|           |           |   admin: http://controller:8774/v2.1    |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:8774/v2.1 |
|           |           | RegionOne                               |
|           |           |   public: http://controller:8774/v2.1   |
|           |           |                                         |
| placement | placement | RegionOne                               |
|           |           |   public: http://controller:8778        |
|           |           | RegionOne                               |
|           |           |   admin: http://controller:8778         |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:8778      |
|           |           |                                         |
+-----------+-----------+-----------------------------------------+

# 列出图像服务中的图像以验证与图像服务的连接
openstack image list

+--------------------------------------+-------------+-------------+
| ID                                   | Name        | Status      |
+--------------------------------------+-------------+-------------+
| 9a76d9f9-9620-4f2e-8c69-6c5691fae163 | cirros      | active      |
+--------------------------------------+-------------+-------------+

# 检查单元格和放置 API 是否正常工作，以及其他必要的先决条件是否已到位
nova-status upgrade check

+--------------------------------------------------------------------+
| Upgrade Check Results                                              |
+--------------------------------------------------------------------+
| Check: Cells v2                                                    |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Placement API                                               |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Cinder API                                                  |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Policy Scope-based Defaults                                 |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Policy File JSON to YAML Migration                          |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Older than N-1 computes                                     |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+

```



## 安装Neutron

官方链接：https://docs.openstack.org/neutron/yoga/install/

最复杂也是难度最高的就是网络配置了，Neutron是openstack的网络组件。

OpenStack Networking (neutron) 允许您创建由其他 OpenStack 服务管理的接口设备并将其附加到网络。可以实施插件以适应不同的网络设备和软件，为 OpenStack 架构和部署提供灵活性。

它包括以下组件：

- **neutron-server**

  接受 API 请求并将其路由到适当的 OpenStack Networking 插件以进行操作。

- **OpenStack Networking plug-ins and agents**

  插入和拔出端口、创建网络或子网以及提供 IP 寻址。这些插件和代理因特定云中使用的供应商和技术而异。OpenStack Networking 附带用于 Cisco 虚拟和物理交换机、NEC OpenFlow 产品、Open vSwitch、Linux 桥接和 VMware NSX 产品的插件和代理。常见的代理是 L3（第 3 层）、DHCP（动态主机 IP 寻址）和插件代理。

- **Messaging queue**

  大多数 OpenStack 网络安装使用它在 neutron 服务器和各种代理之间路由信息。还充当数据库来存储特定插件的网络状态。

OpenStack Networking 主要与 OpenStack Compute 交互，为其实例提供网络和连接。



网卡和主机名解析已经做过了，请查看环境配置中的主机联网配置。



### 安装和配置控制节点controller网络

#### 数据库配置

```bash
mysql -u root -p
Enter Password：123456

# 创建neutron数据库
MariaDB [(none)] CREATE DATABASE neutron;


# 授予对neutron数据库的适当访问权限，替换 NEUTRON_DBPASS 为合适的密码
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';

exit;
```

创建用户和角色

```bash
. ~/admin-openrc

# 创建 neutron 用户，密码为 NEUTRON_PASS
openstack user create --domain default --password-prompt neutron
# 把neutron用户加到admin组
openstack role add --project service --user neutron admin

# 实例化服务
$ openstack service create --name neutron \
  --description "OpenStack Networking" network

# 创建网络服务 API 端点
openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696

# 如果遇到了Multiple service matches found for 'network', use an ID to be more specific.
# openstack service list
# openstack service  delete  <ID号>    删除多余的服务

```

然后官方文档给出了两个网络架构：公网架构option1和私网架构option2。其中私网架构包含了公网架构的所有功能，也比公网架构多两个组件。所以本文档选择部署option2私网架构。

#### 安装和配置neutron

```bash
apt install -y neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

# 编辑 /etc/neutron/neutron.conf 文件并完成以下操作
vim /etc/neutron/neutron.conf
------------
[DEFAULT]
# ...
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[database]
# ... database组中已有的配置注释掉
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS


[nova]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp
```

#### 配置ml2组件

ML2 插件使用 Linux 桥接机制为实例构建第 2 层（桥接和交换）虚拟网络基础设施。

```bash
# 编辑 /etc/neutron/plugins/ml2/ml2_conf.ini 文件并完成以下操作
vim /etc/neutron/plugins/ml2/ml2_conf.ini
---------
[ml2]
# ...
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security

[ml2_type_flat]
# ...
flat_networks = provider

[ml2_type_vxlan]
# ...
vni_ranges = 1:1000

[securitygroup]
# ...
enable_ipset = true
```

#### 配置Linux网桥代理

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

```bash
# 编辑 /etc/neutron/plugins/ml2/linuxbridge_agent.ini 文件并完成以下操作
vim /etc/neutron/plugins/ml2/linuxbridge_agent.ini
-----------
[linux_bridge]
# 这里的PROVIDER_INTERFACE_NAME是 203.0.113.0/24 网段的网口名称，你需要根据你自己的实际填写。
# physical_interface_mappings = provider:enp1s0f0
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

[vxlan]
enable_vxlan = true
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
l2_population = true

[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

```

然后通过sysctl命令验证你的Ubuntu linux系统内核是否支持linux网桥。相当于支持VMware里面的桥接模式。
返回1表示支持网桥模式。一般情况下都是1，除非你的cpu很老。如果不是1，自行百度解决

```bash
sysctl net.bridge.bridge-nf-call-iptables
# net.bridge.bridge-nf-call-iptables = 1

sysctl net.bridge.bridge-nf-call-ip6tables
# net.bridge.bridge-nf-call-ip6tables = 1
```

#### 配置layer-3三层交换机代理

第 3 层 (L3) 代理为自助虚拟网络提供路由和 NAT 服务。

```bash
# 编辑 /etc/neutron/l3_agent.ini 文件并完成以下操作
vim /etc/neutron/l3_agent.ini
-----------
[DEFAULT]
# ...
interface_driver = linuxbridge
```

#### 配置DHCP代理

DHCP 代理为虚拟网络提供 DHCP 服务。

```bash
# 编辑 /etc/neutron/dhcp_agent.ini 文件并完成以下操作
vim /etc/neutron/dhcp_agent.ini
------------
[DEFAULT]
# ...
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
```

#### 配置元数据代理

```bash
# 编辑 /etc/neutron/metadata_agent.ini 文件并完成以下操作
vim /etc/neutron/metadata_agent.ini
----------
[DEFAULT]
# ...
nova_metadata_host = controller
# 这是设置一个密码 METADATA_SECRET ，下一步会用到
metadata_proxy_shared_secret = METADATA_SECRET
```

再次配置nova，将上面的密码加入到nova

```bash
# 编辑 /etc/nova/nova.conf 文件并执行以下操作
vim /etc/nova/nova.conf
-------------
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
# 这里用到了上一步的密码
metadata_proxy_shared_secret = METADATA_SECRET
```

#### 同步配置到数据库

```bash
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

```

#### 重启nova和neutron

```bash
service nova-api restart

# 重启neutron组件
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

# 重启3层交换机
service neutron-l3-agent restart
```

controller的组件就配置结束了。

### 安装和配置计算节点compute网络

计算节点处理实例的连接和安全组。

#### 配置neutron

```bash
apt install -y neutron-linuxbridge-agent

# 编辑 /etc/neutron/neutron.conf 文件并完成以下操作
vim /etc/neutron/neutron.conf
------------
[DEFAULT]
# ... 不要把core_plugin = ml2注释了，有用的
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone

[keystone_authtoken]
# ... 已有的配置注释掉
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp

```

#### 配置Linux网桥

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

```bash
# 编辑 /etc/neutron/plugins/ml2/linuxbridge_agent.ini 文件并完成以下操作
vim /etc/neutron/plugins/ml2/linuxbridge_agent.ini
------------
[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

[vxlan]
enable_vxlan = true
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
l2_population = true

[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

```

然后通过sysctl命令验证你的Ubuntu linux系统内核是否支持linux网桥。相当于支持VMware里面的桥接模式。
返回1表示支持网桥模式。一般情况下都是1，除非你的cpu很老。如果不是1，自行百度解决

```bash
sysctl net.bridge.bridge-nf-call-iptables
# net.bridge.bridge-nf-call-iptables = 1

sysctl net.bridge.bridge-nf-call-ip6tables
# net.bridge.bridge-nf-call-ip6tables = 1
```

#### 配置compute节点上的nova组件

```bash
# 编辑 /etc/nova/nova.conf 文件并完成以下操作
vim /etc/nova/nova.conf
------------
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
```

#### 重启nova和neutron服务

```bash
service nova-compute restart
service neutron-linuxbridge-agent restart
```



### 验证neutron在controller和compute1上是否安装成功

方法就是列出本机的neutron网络组件。controller上应该有四个，compute1上应该有一个。

```bash
. admin-openrc

# 在controller上执行
openstack network agent list

+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
| ID                                   | Agent Type         | Host       | Availability Zone | Alive | State | Binary                    |
+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
| f49a4b81-afd6-4b3d-b923-66c8f0517099 | Metadata agent     | controller | None              | True  | UP    | neutron-metadata-agent    |
| 27eee952-a748-467b-bf71-941e89846a92 | Linux bridge agent | controller | None              | True  | UP    | neutron-linuxbridge-agent |
| 08905043-5010-4b87-bba5-aedb1956e27a | Linux bridge agent | compute1   | None              | True  | UP    | neutron-linuxbridge-agent |
| 830344ff-dc36-4956-84f4-067af667a0dc | L3 agent           | controller | nova              | True  | UP    | neutron-l3-agent          |
| dd3644c9-1a3a-435a-9282-eb306b4b0391 | DHCP agent         | controller | nova              | True  | UP    | neutron-dhcp-agent        |
+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+


# 列出加载的扩展以验证进程是否成功启动 neutron-server
openstack extension list --network

+---------------------------+---------------------------+----------------------------+
| Name                      | Alias                     | Description                |
+---------------------------+---------------------------+----------------------------+
| Default Subnetpools       | default-subnetpools       | Provides ability to mark   |
|                           |                           | and use a subnetpool as    |
|                           |                           | the default                |
| Availability Zone         | availability_zone         | The availability zone      |
|                           |                           | extension.                 |
| Network Availability Zone | network_availability_zone | Availability zone support  |
|                           |                           | for network.               |
| Port Binding              | binding                   | Expose port bindings of a  |
|                           |                           | virtual port to external   |
|                           |                           | application                |
| agent                     | agent                     | The agent management       |
|                           |                           | extension.                 |
| Subnet Allocation         | subnet_allocation         | Enables allocation of      |
|                           |                           | subnets from a subnet pool |
| DHCP Agent Scheduler      | dhcp_agent_scheduler      | Schedule networks among    |
|                           |                           | dhcp agents                |
| Neutron external network  | external-net              | Adds external network      |
|                           |                           | attribute to network       |
|                           |                           | resource.                  |
| Neutron Service Flavors   | flavors                   | Flavor specification for   |
|                           |                           | Neutron advanced services  |
| Network MTU               | net-mtu                   | Provides MTU attribute for |
|                           |                           | a network resource.        |
| Network IP Availability   | network-ip-availability   | Provides IP availability   |
|                           |                           | data for each network and  |
|                           |                           | subnet.                    |
| Quota management support  | quotas                    | Expose functions for       |
|                           |                           | quotas management per      |
|                           |                           | tenant                     |
| Provider Network          | provider                  | Expose mapping of virtual  |
|                           |                           | networks to physical       |
|                           |                           | networks                   |
| Multi Provider Network    | multi-provider            | Expose mapping of virtual  |
|                           |                           | networks to multiple       |
|                           |                           | physical networks          |
| Address scope             | address-scope             | Address scopes extension.  |
| Subnet service types      | subnet-service-types      | Provides ability to set    |
|                           |                           | the subnet service_types   |
|                           |                           | field                      |
| Resource timestamps       | standard-attr-timestamp   | Adds created_at and        |
|                           |                           | updated_at fields to all   |
|                           |                           | Neutron resources that     |
|                           |                           | have Neutron standard      |
|                           |                           | attributes.                |
| Neutron Service Type      | service-type              | API for retrieving service |
| Management                |                           | providers for Neutron      |
|                           |                           | advanced services          |
| resources: subnet,        |                           | more L2 and L3 resources.  |
| subnetpool, port, router  |                           |                            |
| Neutron Extra DHCP opts   | extra_dhcp_opt            | Extra options              |
|                           |                           | configuration for DHCP.    |
|                           |                           | For example PXE boot       |
|                           |                           | options to DHCP clients    |
|                           |                           | can be specified (e.g.     |
|                           |                           | tftp-server, server-ip-    |
|                           |                           | address, bootfile-name)    |
| Resource revision numbers | standard-attr-revisions   | This extension will        |
|                           |                           | display the revision       |
|                           |                           | number of neutron          |
|                           |                           | resources.                 |
| Pagination support        | pagination                | Extension that indicates   |
|                           |                           | that pagination is         |
|                           |                           | enabled.                   |
| Sorting support           | sorting                   | Extension that indicates   |
|                           |                           | that sorting is enabled.   |
| security-group            | security-group            | The security groups        |
|                           |                           | extension.                 |
| RBAC Policies             | rbac-policies             | Allows creation and        |
|                           |                           | modification of policies   |
|                           |                           | that control tenant access |
|                           |                           | to resources.              |
| standard-attr-description | standard-attr-description | Extension to add           |
|                           |                           | descriptions to standard   |
|                           |                           | attributes                 |
| Port Security             | port-security             | Provides port security     |
| Allowed Address Pairs     | allowed-address-pairs     | Provides allowed address   |
|                           |                           | pairs                      |
| project_id field enabled  | project-id                | Extension that indicates   |
|                           |                           | that project_id field is   |
|                           |                           | enabled.                   |
+---------------------------+---------------------------+----------------------------+
```



## 安装Horizon

Dashboard 仪表板所需的唯一核心服务是身份服务。您可以将仪表板与其他服务结合使用，例如图像服务、计算和网络。您还可以在具有对象存储等独立服务的环境中使用仪表板。

本节假设使用 Apache HTTP 服务器和 Memcached 服务正确安装、配置和操作身份服务。

### 系统要求

Horizon 的 Ussuri 版本具有以下依赖项。

- Python 3.6 or 3.7
- Django 3.2
  - Django 支持政策记录在[Django 支持](https://docs.openstack.org/horizon/yoga/contributor/policies/supported-software.html#django-support)中。
- 可访问的[keystone](https://docs.openstack.org/keystone/latest/)端点
- 所有其他服务都是可选的。从 Stein 版本开始，Horizon 支持以下服务。如果配置了服务的 keystone 端点，horizon 会检测到它并自动启用它的支持。
  - [cinder](https://docs.openstack.org/cinder/latest/)：块存储
  - [glance](https://docs.openstack.org/glance/latest/)：图像管理
  - [neutron](https://docs.openstack.org/neutron/latest/)(https://docs.openstack.org/neutron/latest/)：网络
  - [nova](https://docs.openstack.org/nova/latest/)：计算
  - [swift](https://docs.openstack.org/swift/latest/)：对象存储
  - Horizon 还通过插件支持许多其他 OpenStack 服务。有关详细信息，请参阅[插件注册表](https://docs.openstack.org/horizon/yoga/install/plugin-registry.html#install-plugin-registry)。



### 安装配置

仪表板所需的唯一核心服务是身份服务。您可以将仪表板与其他服务结合使用，例如图像服务、计算和网络。您还可以在具有对象存储等独立服务的环境中使用仪表板。

本节假设使用 Apache HTTP 服务器和 Memcached 服务正确安装、配置和操作身份服务。

```bash
apt install -y openstack-dashboard

# 编辑 /etc/openstack-dashboard/local_settings.py 文件并完成以下操作
vim /etc/openstack-dashboard/local_settings.py
----------
OPENSTACK_HOST = "controller"
# * 表示允许任何外部主机访问Horizon，但是这样不安全，生产环境请写几台机器用户访问Horizon。
ALLOWED_HOSTS = ['*']
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
# 这个是Python的语法，字符串格式化输出。
OPENSTACK_KEYSTONE_URL = "http://%s/identity/v3" % OPENSTACK_HOST
# 通过 ip:5000可以访问Horizon，如果想换其他端口，则修改配置中的5000

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
# 通过仪表板创建的用户配置为默认域 Default
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
# 新注册用户的默认角色和权限为普通用户
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

# 配置时区
TIME_ZONE = "TIME_ZONE"
# TIME_ZONE = "shanghai"


vim /etc/apache2/conf-available/openstack-dashboard.conf
--------------
WSGIApplicationGroup %{GLOBAL}

```

### 重启apache服务

```bash
systemctl reload apache2.service
```

### 验证是否安装成功

验证仪表板的操作。

使用 Web 浏览器访问仪表板，网址为 `http://controller:5000/horizon`。

使用`admin`或`demo`用户和`default`域凭据进行身份验证。

### 下一步

安装并配置仪表板后，您可以完成以下任务：

- 为用户提供公共 IP 地址、用户名和密码，以便他们可以通过 Web 浏览器访问仪表板。如果出现任何 SSL 证书连接问题，请将服务器 IP 地址指向域名，并授予用户访问权限。

- 自定义您的仪表板。有关详细信息，请参阅[自定义和配置仪表板](https://docs.openstack.org/horizon/yoga/admin/customize-configure.html)。

- 设置会话存储。有关详细信息，请参阅[为仪表板设置会话存储](https://docs.openstack.org/horizon/yoga/admin/sessions.html)。

- 要将 VNC 客户端与仪表板一起使用，浏览器必须支持 HTML5 Canvas 和 HTML5 WebSockets。

  有关支持 noVNC 的浏览器的详细信息，请参阅 [README](https://github.com/novnc/noVNC/blob/master/README.md)。

### 手动安装

https://docs.openstack.org/horizon/yoga/install/from-source.html

### 插件

有许多用于各种有用功能的地平线插件。您可以通过安装相应的 horizon 插件来获得对它们的仪表板支持。

插件注册表

https://docs.openstack.org/horizon/yoga/install/plugin-registry.html

## 安装Cinder（非必要）

### 安装指南

块存储服务（cinder）为来宾实例提供块存储设备。提供和使用存储的方法由块存储驱动程序确定，或者在多后端配置的情况下由驱动程序确定。有多种可用的驱动程序：NAS/SAN、NFS、iSCSI、Ceph 等。

Block Storage API 和调度程序服务通常在控制器节点上运行。根据使用的驱动程序，卷服务可以在控制器节点、计算节点或独立存储节点上运行。

先决条件

本文档专门介绍了 Cinder Block Storage 服务的安装。在遵循本指南之前，您需要使用 [OpenStack 安装指南](https://docs.openstack.org/install-guide/)中的说明准备您的 OpenStack 环境。

一旦能够在您的 OpenStack 环境中“启动一个实例”，请按照以下说明将 Cinder 添加到基础环境中。



本节介绍如何为块存储服务安装和配置存储节点。为简单起见，此配置引用一个具有空本地块存储设备的存储节点。说明使用`/dev/sdb`，但您可以为您的特定节点替换不同的值。

[该服务使用LVM](https://docs.openstack.org/cinder/yoga/common/glossary.html#term-Logical-Volume-Manager-LVM)驱动程序在此设备上提供逻辑卷 ，并通过[iSCSI](https://docs.openstack.org/cinder/yoga/common/glossary.html#term-iSCSI-Qualified-Name-IQN)传输将它们提供给实例。您可以按照这些说明稍作修改，以使用额外的存储节点水平扩展您的环境。



### 安装和配置控制器节点

本节介绍如何在控制节点上安装和配置代号为cinder的Block Storage服务。此服务至少需要一个额外的存储节点来为实例提供卷。



先决条件

在安装和配置 Block Storage 服务之前，您必须创建数据库、服务凭证和 API 端点。

1. 要创建数据库，请完成以下步骤：

   1. 使用数据库访问客户端以`root`用户身份连接到数据库服务器：

      ```bash
      # mysql
      
      ```

   2. 创建`cinder`数据库：

      ```bash
      MariaDB [(none)]> CREATE DATABASE cinder;
      
      ```

   3. 授予对`cinder`数据库的适当访问权限：

      ```bash
      MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
        IDENTIFIED BY 'CINDER_DBPASS';
      MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
        IDENTIFIED BY 'CINDER_DBPASS';
      ```

      替换`CINDER_DBPASS`为合适的密码。

2. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

3. 要创建服务凭证，请完成以下步骤：

   1. 创建`cinder`用户：

      ```bash
      $ openstack user create --domain default --password-prompt cinder
      
      User Password:
      Repeat User Password:
      +---------------------+----------------------------------+
      | Field               | Value                            |
      +---------------------+----------------------------------+
      | domain_id           | default                          |
      | enabled             | True                             |
      | id                  | 9d7e33de3e1a498390353819bc7d245d |
      | name                | cinder                           |
      | options             | {}                               |
      | password_expires_at | None                             |
      +---------------------+----------------------------------+
      ```

   2. `admin`为用户添加角色`cinder`：

      ```bash
      $ openstack role add --project service --user cinder admin
      
      ```

   3. 创建`cinderv3`服务实体：

      ```bash
      $ openstack service create --name cinderv3 \
        --description "OpenStack Block Storage" volumev3
      
      +-------------+----------------------------------+
      | Field       | Value                            |
      +-------------+----------------------------------+
      | description | OpenStack Block Storage          |
      | enabled     | True                             |
      | id          | ab3bbbef780845a1a283490d281e7fda |
      | name        | cinderv3                         |
      | type        | volumev3                         |
      +-------------+----------------------------------+
      ```

      从 Xena 版本开始，块存储服务只需要一个服务实体。对于以前的版本，请查阅该特定版本的文档。

4. 创建 Block Storage 服务 API 端点：

   ```bash
   $ openstack endpoint create --region RegionOne \
     volumev3 public http://controller:8776/v3/%\(project_id\)s
   
   +--------------+------------------------------------------+
   | Field        | Value                                    |
   +--------------+------------------------------------------+
   | enabled      | True                                     |
   | id           | 03fa2c90153546c295bf30ca86b1344b         |
   | interface    | public                                   |
   | region       | RegionOne                                |
   | region_id    | RegionOne                                |
   | service_id   | ab3bbbef780845a1a283490d281e7fda         |
   | service_name | cinderv3                                 |
   | service_type | volumev3                                 |
   | url          | http://controller:8776/v3/%(project_id)s |
   +--------------+------------------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     volumev3 internal http://controller:8776/v3/%\(project_id\)s
   
   +--------------+------------------------------------------+
   | Field        | Value                                    |
   +--------------+------------------------------------------+
   | enabled      | True                                     |
   | id           | 94f684395d1b41068c70e4ecb11364b2         |
   | interface    | internal                                 |
   | region       | RegionOne                                |
   | region_id    | RegionOne                                |
   | service_id   | ab3bbbef780845a1a283490d281e7fda         |
   | service_name | cinderv3                                 |
   | service_type | volumev3                                 |
   | url          | http://controller:8776/v3/%(project_id)s |
   +--------------+------------------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     volumev3 admin http://controller:8776/v3/%\(project_id\)s
   
   +--------------+------------------------------------------+
   | Field        | Value                                    |
   +--------------+------------------------------------------+
   | enabled      | True                                     |
   | id           | 4511c28a0f9840c78bacb25f10f62c98         |
   | interface    | admin                                    |
   | region       | RegionOne                                |
   | region_id    | RegionOne                                |
   | service_id   | ab3bbbef780845a1a283490d281e7fda         |
   | service_name | cinderv3                                 |
   | service_type | volumev3                                 |
   | url          | http://controller:8776/v3/%(project_id)s |
   +--------------+------------------------------------------+
   
   ```



安装和配置组件

1. 安装软件包：

   ```bash
   # apt install cinder-api cinder-scheduler
   
   ```

2. 编辑`/etc/cinder/cinder.conf`文件并完成以下操作：

   1. 在`[database]`部分中，配置数据库访问：

      ```bash
      [database]
      # ...
      connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
      ```

      替换`CINDER_DBPASS`为您为块存储数据库选择的密码。

   2. 在`[DEFAULT]`部分中，配置`RabbitMQ` 消息队列访问：

      ```bash
      [DEFAULT]
      # ...
      transport_url = rabbit://openstack:RABBIT_PASS@controller
      ```

      替换为您在 中`RABBIT_PASS`为帐户选择的密码 。`openstackRabbitMQ`

   3. 在`[DEFAULT]`和`[keystone_authtoken]`部分，配置身份服务访问：

      ```bash
      [DEFAULT]
      # ...
      auth_strategy = keystone
      
      [keystone_authtoken]
      # ...
      www_authenticate_uri = http://controller:5000
      auth_url = http://controller:5000
      memcached_servers = controller:11211
      auth_type = password
      project_domain_name = default
      user_domain_name = default
      project_name = service
      username = cinder
      password = CINDER_PASS
      ```

      替换为您在身份服务中`CINDER_PASS`为用户选择的密码。`cinder`

      注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

   4. 在该`[DEFAULT]`部分中，配置选项`my_ip`以使用控制器节点的管理接口 IP 地址：

      ```bash
      [DEFAULT]
      # ...
      my_ip = 10.0.0.11
      ```

3. 在`[oslo_concurrency]`部分中，配置锁定路径：

   ```bash
   [oslo_concurrency]
   # ...
   lock_path = /var/lib/cinder/tmp
   ```

4. 填充块存储数据库：

   ```bash
   # su -s /bin/sh -c "cinder-manage db sync" cinder
   
   ```



配置计算以使用块存储

1. 编辑该`/etc/nova/nova.conf`文件并向其中添加以下内容：

   ```bash
   [cinder]
   os_region_name = RegionOne
   ```

完成安装

1. 重新启动计算 API 服务：

   ```bash
   # service nova-api restart
   
   ```

2. 重启块存储服务：

   ```bash
   # service cinder-scheduler restart
   # service apache2 restart
   
   ```

   

### 安装和配置存储节点



先决条件

在存储节点上安装和配置块存储服务之前，您需要准备存储设备。

在存储节点上执行这些步骤。

1. 安装支持的实用程序包：

   ```bash
   # apt install lvm2 thin-provisioning-tools
   
   ```

   一些发行版默认包含 LVM。

2. 创建 LVM 物理卷`/dev/sdb`：

   ```bash
   # pvcreate /dev/sdb
   
   Physical volume "/dev/sdb" successfully created
   ```

3. 创建 LVM 卷组`cinder-volumes`：

   ```bash
   # vgcreate cinder-volumes /dev/sdb
   
   Volume group "cinder-volumes" successfully created
   ```

   Block Storage 服务在这个卷组中创建逻辑卷。

4. 只有实例可以访问块存储卷。但是，底层操作系统管理与卷关联的设备。默认情况下，LVM 卷扫描工具会扫描 `/dev`包含卷的块存储设备的目录。如果项目在其卷上使用 LVM，则扫描工具会检测到这些卷并尝试缓存它们，这可能会导致底层操作系统和项目卷出现各种问题。您必须重新配置 LVM 以仅扫描包含卷组的设备`cinder-volumes`。编辑 `/etc/lvm/lvm.conf`文件并完成以下操作：

   - 在该`devices`部分中，添加一个接受该 `/dev/sdb`设备并拒绝所有其他设备的过滤器：

     ```bash
     devices {
     ...
     filter = [ "a/sdb/", "r/.*/"]
     ```

     过滤器数组中的每一项都以`a`for **accept**或 `r`for **reject**开头，并包含设备名称的正则表达式。`r/.*/`该阵列必须以拒绝任何剩余设备结尾。您可以使用**vgs -vvvv**命令来测试过滤器。

     警告：如果您的存储节点在操作系统磁盘上使用 LVM，您还必须将关联的设备添加到过滤器中。例如，如果`/dev/sda`设备包含操作系统：

     ```bash
     filter = [ "a/sda/", "a/sdb/", "r/.*/"]
     
     ```

     同样，如果您的计算节点在操作系统磁盘上使用 LVM，您还必须修改 `/etc/lvm/lvm.conf`这些节点上文件中的过滤器以仅包含操作系统磁盘。例如，如果`/dev/sda` 设备包含操作系统：

     ```bash
     filter = [ "a/sda/", "r/.*/"]
     
     ```



安装和配置组件

1. 安装软件包：

   ```bash
   # apt install cinder-volume tgt
   
   ```

2. 编辑`/etc/cinder/cinder.conf`文件并完成以下操作：

   - 在`[database]`部分中，配置数据库访问：

     ```bash
     [database]
     # ...
     connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
     ```

     替换`CINDER_DBPASS`为您为块存储数据库选择的密码。

   - 在`[DEFAULT]`部分中，配置`RabbitMQ` 消息队列访问：

     ```bash
     [DEFAULT]
     # ...
     transport_url = rabbit://openstack:RABBIT_PASS@controller
     ```

     替换为您在 中`RABBIT_PASS`为帐户选择的密码。`openstackRabbitMQ`

   - 在`[DEFAULT]`和`[keystone_authtoken]`部分，配置身份服务访问：

     ```bash
     [DEFAULT]
     # ...
     auth_strategy = keystone
     
     [keystone_authtoken]
     # ...
     www_authenticate_uri = http://controller:5000
     auth_url = http://controller:5000
     memcached_servers = controller:11211
     auth_type = password
     project_domain_name = default
     user_domain_name = default
     project_name = service
     username = cinder
     password = CINDER_PASS
     ```

     替换为您在身份服务中`CINDER_PASS`为用户选择的密码 。`cinder`

     注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

   - 在`[DEFAULT]`部分中，配置`my_ip`选项：

     ```bash
     [DEFAULT]
     # ...
     my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS
     ```

     替换`MANAGEMENT_INTERFACE_IP_ADDRESS`为存储节点上管理网络接口的 IP 地址，对于 [示例架构](https://docs.openstack.org/install-guide/overview.html#example-architecture)中的第一个节点，通常为 10.0.0.41 。

   - 在`[lvm]`部分中，使用 LVM 驱动程序、`cinder-volumes`卷组、iSCSI 协议和适当的 iSCSI 服务配置 LVM 后端：

     ```bash
     [lvm]
     # ...
     volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
     volume_group = cinder-volumes
     target_protocol = iscsi
     target_helper = tgtadm
     ```

   - 在该`[DEFAULT]`部分中，启用 LVM 后端：

     ```bash
     [DEFAULT]
     # ...
     enabled_backends = lvm
     ```

     后端名称是任意的。例如，本指南使用驱动程序的名称作为后端的名称。

   - 在该`[DEFAULT]`部分中，配置图像服务 API 的位置：

     ```bash
     [DEFAULT]
     # ...
     glance_api_servers = http://controller:9292
     ```

   - 在`[oslo_concurrency]`部分中，配置锁定路径：

     ```bash
     [oslo_concurrency]
     # ...
     lock_path = /var/lib/cinder/tmp
     ```

     

完成安装

1. 重新启动 Block Storage 卷服务及其依赖项：

   ```bash
   # service tgt restart
   # service cinder-volume restart
   ```





### 安装和配置备份服务

（可选）安装和配置备份服务。为简单起见，此配置使用 Block Storage 节点和 Object Storage (swift) 驱动程序，因此取决于 [Object Storage 服务](https://docs.openstack.org/swift/latest/install/)。

在安装和配置备份服务之前，您必须先安装和配置[存储节点。](https://docs.openstack.org/cinder/yoga/configuration/block-storage/config-options.html#cinder-storage)



安装和配置组件

在 Block Storage 节点上执行这些步骤。

1. 安装软件包：

   ```bash
   # apt install cinder-backup
   
   ```

2. 编辑`/etc/cinder/cinder.conf`文件并完成以下操作：

   - 在`[DEFAULT]`部分中，配置备份选项：

     ```bash
     [DEFAULT]
     # ...
     backup_driver = cinder.backup.drivers.swift.SwiftBackupDriver
     backup_swift_url = SWIFT_URL
     ```

     替换`SWIFT_URL`为对象存储服务的 URL。可以通过显示对象存储 API 端点来找到 URL：

     ```bash
     $ openstack catalog show object-store
     
     ```

完成安装

重启块存储备份服务：

```bash
# service cinder-backup restart

```



### 验证 Cinder 运行

验证块存储服务的操作。

在控制器节点上执行这些命令。

1. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

2. 列出服务组件以验证每个进程是否成功启动：

   ```bash
   $ openstack volume service list
   
   +------------------+------------+------+---------+-------+----------------------------+
   | Binary           | Host       | Zone | Status  | State | Updated_at                 |
   +------------------+------------+------+---------+-------+----------------------------+
   | cinder-scheduler | controller | nova | enabled | up    | 2016-09-30T02:27:41.000000 |
   | cinder-volume    | block@lvm  | nova | enabled | up    | 2016-09-30T02:27:46.000000 |
   | cinder-backup    | controller | nova | enabled | up    | 2016-09-30T02:27:41.000000 |
   +------------------+------------+------+---------+-------+----------------------------+
   ```

   







