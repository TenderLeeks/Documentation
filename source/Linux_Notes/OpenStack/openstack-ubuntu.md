# OpenStack

## OpenStack 安装指南

https://docs.openstack.org/install-guide/





## 环境

- 控制器节点：1 个处理器、4 GB 内存和 5 GB 存储空间
- 计算节点：1 个处理器、2 GB 内存和 10 GB 存储空间



随着 OpenStack 服务和虚拟机数量的增加，对最佳性能的硬件要求也在增加。如果在启用其他服务或虚拟机后性能下降，请考虑向您的环境添加硬件资源。



为了尽量减少混乱并为 OpenStack 提供更多资源，我们建议您对 Linux 发行版进行最小安装。此外，您必须在每个节点上安装 64 位版本的分发版。



每个节点上的单个磁盘分区适用于大多数基本安装。但是，对于具有块存储等可选服务的安装，您应该考虑使用[逻辑卷管理器 (LVM) 。](https://docs.openstack.org/install-guide/common/glossary.html#term-Logical-Volume-Manager-LVM)

出于首次安装和测试的目的，许多用户选择将每个主机构建为[虚拟机 (VM)](https://docs.openstack.org/install-guide/common/glossary.html#term-virtual-machine-VM)。VM 的主要优势包括：

- 一台物理服务器可以支持多个节点，每个节点具有几乎任意数量的网络接口。
- 能够在整个安装过程中定期“快照”并在出现问题时“回滚”到工作配置。



但是，VM 会降低您的实例的性能，特别是如果您的管理程序和/或处理器不支持嵌套 VM 的硬件加速。





## 安全

https://docs.openstack.org/install-guide/environment-security.html



OpenStack 服务支持各种安全方法，包括密码、策略和加密。此外，包括数据库服务器和消息代理在内的支持服务支持密码安全。

为了简化安装过程，本指南仅在适用的情况下介绍密码安全。您可以手动创建安全密码，但服务配置文件中的数据库连接字符串不能接受“@”等特殊字符。[我们建议您使用诸如pwgen](https://sourceforge.net/projects/pwgen/)之类的工具 或通过运行以下命令来生成它们：

```bash
$ openssl rand -hex 10
```

对于 OpenStack 服务，本指南用于`SERVICE_PASS`引用服务帐户密码和`SERVICE_DBPASS`引用数据库密码。

下表提供了需要密码的服务列表及其在指南中的相关参考。



密码

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



## 主机联网

https://docs.openstack.org/install-guide/environment-networking.html

在为您选择部署的体系结构的每个节点上安装操作系统后，您必须配置网络接口。我们建议您禁用任何自动网络管理工具，并为您的发行版手动编辑适当的配置文件。有关如何在您的发行版上配置网络的更多信息，请参阅文档。

所有节点都需要 Internet 访问以用于管理目的，例如软件包安装、安全更新、[DNS](https://docs.openstack.org/install-guide/common/glossary.html#term-Domain-Name-System-DNS)和 [NTP](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Time-Protocol-NTP)。在大多数情况下，节点应该通过管理网络接口访问互联网。为了突出网络分离的重要性，示例架构为管理网络使用[专用地址空间](https://tools.ietf.org/html/rfc1918)，并假设物理网络基础设施通过[NAT](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Address-Translation-NAT) 或其他方法提供互联网访问。示例架构使用提供商（外部）网络的可路由 IP 地址空间，并假设物理网络基础设施提供直接互联网访问。

在提供商网络架构中，所有实例都直接连接到提供商网络。在自助服务（专用）网络架构中，实例可以附加到自助服务或提供商网络。自助服务网络可以完全驻留在 OpenStack 中，也可以通过提供商网络使用[NAT提供某种级别的外部网络访问。](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Address-Translation-NAT)

示例架构假设使用以下网络：

- 使用网关 10.0.0.1 在 10.0.0.0/24 上进行管理

  此网络需要一个网关来为所有节点提供 Internet 访问以用于管理目的，例如软件包安装、安全更新、[DNS](https://docs.openstack.org/install-guide/common/glossary.html#term-Domain-Name-System-DNS)和 [NTP](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Time-Protocol-NTP)。

- 提供商位于 203.0.113.0/24 上，网关为 203.0.113.1

  该网络需要一个网关来提供对 OpenStack 环境中实例的 Internet 访问。

您可以修改这些范围和网关以与您的特定网络基础设施一起使用。

网络接口名称因发行版而异。传统上，接口使用`eth`后跟一个序列号。为涵盖所有变体，本指南将第一个接口称为编号最小的接口，将第二个接口称为编号最大的接口。

除非您打算使用此示例体系结构中提供的确切配置，否则您必须修改此过程中的网络以匹配您的环境。除 IP 地址外，每个节点还必须按名称解析其他节点。例如，`controller`名称必须解析为`10.0.0.11`控制器节点上管理接口的 IP 地址。



**警告：重新配置网络接口将中断网络连接。我们建议对这些过程使用本地终端会话。**

### 控制器节点

#### 配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：10.0.0.11

   网络掩码：255.255.255.0（或/24）

   默认网关：10.0.0.1

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， *eth1*或*ens224*。

   对于Ubuntu：

   - 编辑`/etc/network/interfaces`文件以包含以下内容：

     ```bash
     # The provider network interface
     auto INTERFACE_NAME
     iface INTERFACE_NAME inet manual
     up ip link set dev $IFACE up
     down ip link set dev $IFACE down
     ```

   对于 RHEL 或 CentOS：

   - 编辑`/etc/sysconfig/network-scripts/ifcfg-INTERFACE_NAME`文件以包含以下内容：

     不要更改`HWADDR`和`UUID`键。

     ```bash
     DEVICE=INTERFACE_NAME
     TYPE=Ethernet
     ONBOOT="yes"
     BOOTPROTO="none"
     ```

   对于SUSE：

   - 编辑`/etc/sysconfig/network/ifcfg-INTERFACE_NAME`文件以包含以下内容：

     ```bash
     STARTMODE='auto'
     BOOTPROTO='static'
     ```

3. 重新启动系统以激活更改。

#### 配置名称解析

1. 将节点的主机名设置为`controller`。

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   10.0.0.11       controller
   
   # compute1
   10.0.0.31       compute1
   
   # block1
   10.0.0.41       block1
   
   # object1
   10.0.0.51       object1
   
   # object2
   10.0.0.52       object2
   ```

警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**

### 计算节点

#### 配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：10.0.0.31

   网络掩码：255.255.255.0（或/24）

   默认网关：10.0.0.1

   其他计算节点应使用 10.0.0.32、10.0.0.33 等。

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， *eth1*或*ens224*。

   对于Ubuntu：

   - 编辑`/etc/network/interfaces`文件以包含以下内容：

     ```bash
     # The provider network interface
     auto INTERFACE_NAME
     iface  INTERFACE_NAME inet manual
     up ip link set dev $IFACE up
     down ip link set dev $IFACE down
     ```

   对于 RHEL 或 CentOS：

   - 编辑`/etc/sysconfig/network-scripts/ifcfg-INTERFACE_NAME`文件以包含以下内容：

     不要更改`HWADDR`和`UUID`键。

     ```bash
     DEVICE=INTERFACE_NAME
     TYPE=Ethernet
     ONBOOT="yes"
     BOOTPROTO="none"
     ```

   对于SUSE：

   - 编辑`/etc/sysconfig/network/ifcfg-INTERFACE_NAME`文件以包含以下内容：

     ```bash
     STARTMODE='auto'
     BOOTPROTO='static'
     ```

3. 重新启动系统以激活更改。

#### 配置名称解析

1. 将节点的主机名设置为`compute1`。

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   10.0.0.11       controller
   
   # compute1
   10.0.0.31       compute1
   
   # block1
   10.0.0.41       block1
   
   # object1
   10.0.0.51       object1
   
   # object2
   10.0.0.52       object2
   ```

警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**



### 验证连通性

我们建议您在进一步操作之前验证到 Internet 和节点之间的网络连接。

1. 从*控制器*节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 docs.openstack.org
   PING files02.openstack.org (23.253.125.17) 56(84) bytes of data.
   64 bytes from files02.openstack.org (23.253.125.17): icmp_seq=1 ttl=43 time=125 ms
   64 bytes from files02.openstack.org (23.253.125.17): icmp_seq=2 ttl=43 time=125 ms
   64 bytes from files02.openstack.org (23.253.125.17): icmp_seq=3 ttl=43 time=125 ms
   64 bytes from files02.openstack.org (23.253.125.17): icmp_seq=4 ttl=43 time=125 ms
   
   
   --- files02.openstack.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3004ms
   rtt min/avg/max/mdev = 125.192/125.282/125.399/0.441 ms
   ```

2. 从*控制器节点，测试对计算节点上管理界面的访问 ：

   ```bash
   # ping -c 4 compute1
   
   PING compute1 (10.0.0.31) 56(84) bytes of data.
   64 bytes from compute1 (10.0.0.31): icmp_seq=1 ttl=64 time=0.263 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=2 ttl=64 time=0.202 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=3 ttl=64 time=0.203 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=4 ttl=64 time=0.202 ms
   
   --- compute1 ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3000ms
   rtt min/avg/max/mdev = 0.202/0.217/0.263/0.030 ms
   ```

3. 从*计算*节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 openstack.org
   
   PING openstack.org (174.143.194.225) 56(84) bytes of data.
   64 bytes from 174.143.194.225: icmp_seq=1 ttl=54 time=18.3 ms
   64 bytes from 174.143.194.225: icmp_seq=2 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=3 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=4 ttl=54 time=17.4 ms
   
   --- openstack.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3022ms
   rtt min/avg/max/mdev = 17.489/17.715/18.346/0.364 ms
   ```

4. 从*计算节点，测试对**控制器*节点上管理界面的访问 ：

   ```bash
   # ping -c 4 controller
   
   PING controller (10.0.0.11) 56(84) bytes of data.
   64 bytes from controller (10.0.0.11): icmp_seq=1 ttl=64 time=0.263 ms
   64 bytes from controller (10.0.0.11): icmp_seq=2 ttl=64 time=0.202 ms
   64 bytes from controller (10.0.0.11): icmp_seq=3 ttl=64 time=0.203 ms
   64 bytes from controller (10.0.0.11): icmp_seq=4 ttl=64 time=0.202 ms
   
   --- controller ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3000ms
   rtt min/avg/max/mdev = 0.202/0.217/0.263/0.030 ms
   ```

   

## 网络时间协议 (NTP)

要在节点之间正确同步服务，您可以安装 Chrony，它是[NTP](https://docs.openstack.org/install-guide/common/glossary.html#term-Network-Time-Protocol-NTP)的一个实现。我们建议您配置控制器节点以引用更准确的（较低层）服务器和其他节点以引用控制器节点。

### 控制器节点

在控制器节点上执行这些步骤。

1. 安装软件包：

   对于Ubuntu：

   ```bash
   # apt install chrony
   
   ```

   对于 RHEL 或 CentOS：

   ```bash
   # yum install chrony
   
   ```

   对于SUSE：

   ```bash
   # zypper install chrony
   
   ```

2. 编辑该`chrony.conf`文件并根据您的环境的需要添加、更改或删除以下项。

   对于 RHEL、CentOS 或 SUSE，编辑文件`/etc/chrony.conf`：

   ```bash
   server NTP_SERVER iburst
   
   ```

   对于 Ubuntu，编辑`/etc/chrony/chrony.conf`文件：

   ```bash
   server NTP_SERVER iburst
   
   ```

   替换`NTP_SERVER`为合适的更准确（下层）NTP 服务器的主机名或 IP 地址。该配置支持多个`server`密钥。

   > 默认情况下，控制器节点通过公共服务器池同步时间。但是，您可以选择配置替代服务器，例如您的组织提供的服务器。

3. 要使其他节点能够连接到控制器节点上的 chrony 守护进程，请将此密钥添加到上述同一`chrony.conf`文件中：

   ```bash
   allow 10.0.0.0/24
   
   ```

   如有必要，请替换`10.0.0.0/24`为您的子网的描述。

4. 重启 NTP 服务：

   对于Ubuntu：

   ```bash
   # service chrony restart
   
   ```

   对于 RHEL、CentOS 或 SUSE：

   ```bash
   # systemctl enable chronyd.service
   # systemctl start chronyd.service
   ```

   



### 其他节点

其他节点参考控制器节点进行时钟同步。在所有其他节点上执行这些步骤。

1. 安装软件包。

   对于Ubuntu：

   ```bash
   # apt install chrony
   
   ```

   对于 RHEL 或 CentOS：

   ```bash
   # yum install chrony
   
   ```

   对于SUSE：

   ```bash
   # zypper install chrony
   
   ```

2. 配置`chrony.conf`文件并注释掉或删除除一个`server`键以外的所有键。将其更改为引用控制器节点。

   对于 RHEL、CentOS 或 SUSE，编辑文件`/etc/chrony.conf`：

   ```bash
   server controller iburst
   
   ```

   对于 Ubuntu，编辑`/etc/chrony/chrony.conf`文件：

   ```bash
   server controller iburst
   
   ```

3. 注释掉该行。`pool 2.debian.pool.ntp.org offline iburst`

4. 重新启动 NTP 服务。

   对于Ubuntu：

   ```bash
   # service chrony restart
   
   ```

   对于 RHEL、CentOS 或 SUSE：

   ```bash
   # systemctl enable chronyd.service
   # systemctl start chronyd.service
   ```

   





### 验证操作

我们建议您先验证 NTP 同步，然后再继续。一些节点，特别是那些引用控制器节点的节点，可能需要几分钟才能同步。

1. *在控制器*节点上运行此命令：

   ```bash
   # chronyc sources
   
     210 Number of sources = 2
     MS Name/IP address         Stratum Poll Reach LastRx Last sample
     ===============================================================================
     ^- 192.0.2.11                    2   7    12   137  -2814us[-3000us] +/-   43ms
     ^* 192.0.2.12                    2   6   177    46    +17us[  -23us] +/-   68ms
   ```

   `Name/IP address`栏中的内容应表示一台或多台NTP 服务器的主机名或IP 地址。*MS*栏中的内容应为当前同步NTP服务的服务器标明 。

2. *在所有其他*节点上运行相同的命令：

   ```bash
   # chronyc sources
   
     210 Number of sources = 1
     MS Name/IP address         Stratum Poll Reach LastRx Last sample
     ===============================================================================
     ^* controller                    3    9   377   421    +15us[  -87us] +/-   15ms
   
   ```

   `Name/IP address`栏中的内容应表示控制器节点的主机名。



## OpenStack 软件包

https://docs.openstack.org/install-guide/environment-packages.html

由于不同的发布计划，发行版将 OpenStack 包作为发行版的一部分或使用其他方法发布。在所有节点上执行这些过程。

此处描述的 OpenStack 包的设置需要在所有节点上完成：控制器、计算和块存储节点。

警告：在继续之前，您的主机必须包含可用于您的分发的最新版本的基本安装包。

禁用或删除任何自动更新服务，因为它们会影响您的 OpenStack 环境。

### 适用于 Ubuntu 的 OpenStack 软件包

https://docs.openstack.org/install-guide/environment-packages-ubuntu.html

Ubuntu 随每个 Ubuntu 版本发布 OpenStack。Ubuntu LTS 版本每两年提供一次。来自 Ubuntu 临时版本的 OpenStack 包通过 Ubuntu Cloud Archive 提供给之前的 Ubuntu LTS。

此处描述的存档启用需要在所有运行 OpenStack 服务的节点上完成。



**适用于 Ubuntu 20.04 LTS 的 OpenStack Yoga：**

```bash
# add-apt-repository cloud-archive:yoga

```

示例安装

```bash
# apt install nova-compute

```

客户端安装

```bash
# apt install python3-openstackclient

```



##  SQL数据库

大多数 OpenStack 服务使用 SQL 数据库来存储信息。数据库通常在控制器节点上运行。本指南中的过程根据发行版使用 MariaDB 或 MySQL。OpenStack 服务还支持其他 SQL 数据库，包括 [PostgreSQL](https://www.postgresql.org/)。



如果您在OpenStack服务上看到“连接太多”或“打开文件太多”错误日志消息，请验证最大数量的连接设置是否适用于您的环境。在MariaDB中，您可能还需要更改`open_files_flimit`配置。



### Ubuntu 的 SQL 数据库

从Ubuntu 16.04开始，MariaDB被改为使用`unix_socket Authentication Plugin`。现在使用用户凭据（UID）执行本地身份验证，默认情况下不再使用密码身份验证。这意味着根用户不再使用密码对服务器进行本地访问。



从Ubuntu 18.04开始，默认存储库中不再提供**mariadb-server**包。要成功安装，请在Ubuntu上启用**Universe**存储库。



1. 安装软件包：

   - 从 Ubuntu 20.04 开始，安装软件包：

     ```bash
     # apt install mariadb-server python3-pymysql
     
     ```

   - 从 Ubuntu 18.04 或 16.04 开始，安装软件包：

     ```bash
     # apt install mariadb-server python-pymysql
     
     ```

2. 创建和编辑`/etc/mysql/mariadb.conf.d/99-openstack.cnf`文件并完成以下操作：

   - 创建一个`[mysqld]`section，将key设置`bind-address` 为controller节点的管理IP地址，以允许其他节点通过管理网络访问。设置附加键以启用有用的选项和 UTF-8 字符集：

     ```bash
     [mysqld]
     bind-address = 10.0.0.11
     
     default-storage-engine = innodb
     innodb_file_per_table = on
     max_connections = 4096
     collation-server = utf8_general_ci
     character-set-server = utf8
     ```

3. 重启数据库服务：

   ```bash
   # service mysql restart
   
   ```

4. 通过运行脚本保护数据库服务`mysql_secure_installation` 。特别是，为数据库 `root`帐户选择一个合适的密码：

   ```bash
   # mysql_secure_installation
   
   ```



## 消息队列

OpenStack 使用[消息队列](https://docs.openstack.org/install-guide/common/glossary.html#term-message-queue)来协调服务之间的操作和状态信息。消息队列服务通常在控制器节点上运行。OpenStack 支持多种消息队列服务，包括[RabbitMQ](https://www.rabbitmq.com/)、 [Qpid](https://qpid.apache.org/)和[ZeroMQ](http://zeromq.org/)。但是，大多数打包 OpenStack 的发行版都支持特定的消息队列服务。本指南实现了 RabbitMQ 消息队列服务，因为大多数发行版都支持它。如果您更喜欢实现不同的消息队列服务，请查阅与其相关的文档。

消息队列在控制器节点上运行。

### Ubuntu 的消息队列

1. 安装包：

   ```bash
   # apt install rabbitmq-server
   
   ```

2. 添加`openstack`用户：

   ```bash
   # rabbitmqctl add_user openstack RABBIT_PASS
   
   Creating user "openstack" ...
   ```

   替换`RABBIT_PASS`为合适的密码。

3. 允许 `openstack`用户进行配置、写入和读取访问：

   ```bash
   # rabbitmqctl set_permissions openstack ".*" ".*" ".*"
   
   Setting permissions for user "openstack" in vhost "/" ...
   ```

   

## 内存缓存

服务的身份服务认证机制使用 Memcached 来缓存令牌。memcached 服务通常在控制器节点上运行。对于生产部署，我们建议启用防火墙、身份验证和加密的组合来保护它。

### 适用于 Ubuntu 的内存缓存

1. 安装软件包：

   对于 18.04 之前的 Ubuntu 版本，请使用：

   ```bash
   # apt install memcached python-memcache
   
   ```

   对于 Ubuntu 18.04 和更新版本，请使用：

   ```bash
   # apt install memcached python3-memcache
   
   ```

2. 编辑`/etc/memcached.conf`文件并将服务配置为使用控制器节点的管理 IP 地址。这是为了允许其他节点通过管理网络访问：

   ```bash
   -l 10.0.0.11
   
   ```

   更改具有 `-l 127.0.0.1` 的现有行。

3. 重启 Memcached 服务：

   ```bash
   # service memcached restart
   
   ```

   

## Etcd

OpenStack 服务可能会使用 Etcd，一种分布式可靠的键值存储，用于分布式键锁定、存储配置、跟踪服务活跃度等场景。

etcd 服务在控制器节点上运行。

### 适用于 Ubuntu 的 Etcd

1. 安装`etcd`包：

   ```bash
   # apt install etcd
   
   ```

   从 Ubuntu 18.04 开始，`etcd`默认存储库中不再提供该软件包。要成功安装，请`Universe`在 Ubuntu 上启用存储库。

2. 编辑`/etc/default/etcd`文件，并将`etcd_IINITIAL_CLUSTER`、`etcd_INITIAL_ADVERTISE_PEER_URLS`、`etcd_ADVERTISE_CLIENT_URLS`、`ETCT_LISTEN_CLIENT.URLS`设置为控制器节点的管理IP地址，以使其他节点能够通过管理网络进行访问：

   ```bash
   ETCD_NAME="controller"
   ETCD_DATA_DIR="/var/lib/etcd"
   ETCD_INITIAL_CLUSTER_STATE="new"
   ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
   ETCD_INITIAL_CLUSTER="controller=http://10.0.0.11:2380"
   ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.11:2380"
   ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.11:2379"
   ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
   ETCD_LISTEN_CLIENT_URLS="http://10.0.0.11:2379"
   ```

3. 启用并重启 etcd 服务：

   ```bash
   # systemctl enable etcd
   # systemctl restart etcd
   ```

   



## 安装 OpenStack 服务



### Yoga 的最小部署

您至少需要安装以下服务。按照下面指定的顺序安装服务：

身份服务–[keystone installation for Yoga](https://docs.openstack.org/keystone/yoga/install/)

图像服务–[glance installation for Yoga](https://docs.openstack.org/glance/yoga/install/)

安置服务– [placement installation for Yoga](https://docs.openstack.org/placement/yoga/install/)

计算服务–[nova installation for Yoga](https://docs.openstack.org/nova/yoga/install/)

网络服务–[neutron installation for Yoga](https://docs.openstack.org/neutron/yoga/install/)



我们建议您在安装最低部署服务后，也安装以下组件：

仪表板–[horizon installation for Yoga](https://docs.openstack.org/horizon/yoga/install/)

砌块储存服务–[cinder installation for Yoga](https://docs.openstack.org/cinder/yoga/install/)





## Keystone 安装教程

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





### 安装和配置

本节介绍如何在控制器节点上安装和配置OpenStack Identity服务（代码为keystone）。出于可扩展性的目的，此配置部署Fernet令牌和Apache HTTP服务器来处理请求。

继续之前，请确保已完成[Openstack安装指南](https://docs.openstack.org/install-guide/environment-packages-ubuntu.html#finalize-the-installation)中的必备安装步骤。





#### 先决条件

在安装和配置Identity服务之前，必须创建数据库。

1. 使用数据库访问客户端以 root 用户身份连接到数据库服务器：

   ```bash
   # mysql
   
   ```

2. 创建keystone数据库：

   ```bash
   MariaDB [(none)]> CREATE DATABASE keystone;
   
   ```

3. 允许正确访问keystone数据库：

   ```bash
   MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
   IDENTIFIED BY 'KEYSTONE_DBPASS';
   MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
   IDENTIFIED BY 'KEYSTONE_DBPASS';
   ```

   用合适的密码替换`KEYSTONE_DBPASS`。

4. 退出数据库访问客户端。



#### 安装和配置组件

默认配置文件因分布而异。您可能需要添加这些部分和选项，而不是修改现有的部分和选项。此外，配置片段中的省略号（…）指示您应该保留的潜在默认配置选项。

本指南使用带有mod_wsgi的Apache HTTP服务器来处理端口5000上的Identity服务请求。默认情况下，keystone服务仍然侦听该端口。该包为您处理所有Apache配置（包括Apache中mod_wsgi apache2模块和keystone配置的激活）。

1. 运行以下命令以安装软件包：

   ```bash
   # apt install keystone
   
   ```

2. 编辑`/etc/keystone/keystone.conf`文件并完成以下操作：

   - 在[**database**]部分，配置数据库访问：

     ```bash
     [database]
     # ...
     connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
     ```

     用为数据库选择的密码替换`KEYSTONE_DBPASS`。

     注释掉或删除[database]部分中的任何其他连接选项。

   - 在[**token**]部分，配置Fernet令牌提供程序：

     ```bash
     [token]
     # ...
     provider = fernet
     ```

3. 填充Identity服务数据库：

   ```bash
   # su -s /bin/sh -c "keystone-manage db_sync" keystone
   
   ```

4. 初始化Fernet密钥存储库：

   **--keystone-user**和**--keystone-group**标志用于指定将用于运行keystone的操作系统的user/group。这些设置允许在另一个操作系统user/group下运行keystone。在下面的示例中，我们称用户和组为keystone。

   ```bash
   # keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
   # keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
   
   ```

5. 启动Identity服务：

   在Queens发布之前，keystone需要在两个单独的端口上运行，以适应Identity v2 API，后者通常在端口35357上运行单独的admin-only服务。删除v2 API后，keystone可以在所有接口的同一端口上运行。

   ```bash
   # keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
     --bootstrap-admin-url http://controller:5000/v3/ \
     --bootstrap-internal-url http://controller:5000/v3/ \
     --bootstrap-public-url http://controller:5000/v3/ \
     --bootstrap-region-id RegionOne
   ```

   将ADMIN_PASS替换为适合管理用户的密码。



#### 配置 Apache HTTP 服务器

1. 编辑/etc/apache2/apache2.conf文件并配置ServerName选项以引用控制器节点：

   ```bash
   ServerName controller
   
   ```

   如果ServerName条目不存在，则需要添加该条目。

SSL

安全部署应将web服务器配置为使用SSL或在SSL终止符之后运行。



#### 完成安装

1. 重新启动Apache服务：

   ```bash
   # service apache2 restart
   
   ```

2. 通过设置适当的环境变量来配置管理帐户：

   ```bash
   $ export OS_USERNAME=admin
   $ export OS_PASSWORD=ADMIN_PASS
   $ export OS_PROJECT_NAME=admin
   $ export OS_USER_DOMAIN_NAME=Default
   $ export OS_PROJECT_DOMAIN_NAME=Default
   $ export OS_AUTH_URL=http://controller:5000/v3
   $ export OS_IDENTITY_API_VERSION=3
   ```

   此处显示的这些值是从**keystone-manage**引导创建的默认值。

   将ADMIN_PASS替换为[keystone-install-configure-ubuntu](https://docs.openstack.org/keystone/yoga/install/keystone-install-ubuntu.html#keystone-install-configure-ubuntu)中**keystone-manage**引导命令中使用的密码。



### 创建域、项目、用户和角色

Identity服务为每个OpenStack服务提供身份验证服务。身份验证服务使用域、项目、用户和角色的组合。

1. 尽管本指南中的 **keystone-manage** 引导步骤中已经存在 "default" 域，但创建新域的正式方法是：

   ```bash
   $ openstack domain create --description "An Example Domain" example
   
   +-------------+----------------------------------+
   | Field       | Value                            |
   +-------------+----------------------------------+
   | description | An Example Domain                |
   | enabled     | True                             |
   | id          | 2f4f80574fd84fe6ba9067228ae0a50c |
   | name        | example                          |
   | tags        | []                               |
   +-------------+----------------------------------+
   ```

2. 本指南使用的服务项目包含添加到环境中的每个服务的唯一用户。创建服务项目：

   ```bash
   $ openstack project create --domain default \
     --description "Service Project" service
   
   +-------------+----------------------------------+
   | Field       | Value                            |
   +-------------+----------------------------------+
   | description | Service Project                  |
   | domain_id   | default                          |
   | enabled     | True                             |
   | id          | 24ac7f19cd944f4cba1d77469b2a73ed |
   | is_domain   | False                            |
   | name        | service                          |
   | parent_id   | default                          |
   | tags        | []                               |
   +-------------+----------------------------------+
   ```

3. 常规（non-admin）任务应使用非特权项目和用户。例如，本指南创建myproject项目和myuser用户。

   - 创建myproject项目：

     ```bash
     $ openstack project create --domain default \
       --description "Demo Project" myproject
     
     +-------------+----------------------------------+
     | Field       | Value                            |
     +-------------+----------------------------------+
     | description | Demo Project                     |
     | domain_id   | default                          |
     | enabled     | True                             |
     | id          | 231ad6e7ebba47d6a1e57e1cc07ae446 |
     | is_domain   | False                            |
     | name        | myproject                        |
     | parent_id   | default                          |
     | tags        | []                               |
     +-------------+----------------------------------+
     ```

     为此项目创建其他用户时，不要重复此步骤。

   - 创建myuser用户：

     ```bash
     $ openstack user create --domain default \
       --password-prompt myuser
     
     User Password:
     Repeat User Password:
     +---------------------+----------------------------------+
     | Field               | Value                            |
     +---------------------+----------------------------------+
     | domain_id           | default                          |
     | enabled             | True                             |
     | id                  | aeda23aa78f44e859900e22c24817832 |
     | name                | myuser                           |
     | options             | {}                               |
     | password_expires_at | None                             |
     +---------------------+----------------------------------+
     ```

   - 创建myrole角色：

     ```bash
     $ openstack role create myrole
     
     +-----------+----------------------------------+
     | Field     | Value                            |
     +-----------+----------------------------------+
     | domain_id | None                             |
     | id        | 997ce8d05fc143ac97d83fdfb5998552 |
     | name      | myrole                           |
     +-----------+----------------------------------+
     ```

   - 将myrole角色添加到myproject项目和myuser用户：

     ```bash
     $ openstack role add --project myproject --user myuser myrole
     
     ```

     此命令不提供输出。

可以重复此过程以创建其他项目和用户。





### 验证操作

在安装其他服务之前，请验证Identity服务的操作。

在控制器节点上执行这些命令。



1. 取消设置临时OS_AUTH_URL和OS_PASSWORD环境变量：

   ```bash
   $ unset OS_AUTH_URL OS_PASSWORD
   
   ```

2. 作为**admin**用户，请求身份验证令牌：

   ```bash
   $ openstack --os-auth-url http://controller:5000/v3 \
     --os-project-domain-name Default --os-user-domain-name Default \
     --os-project-name admin --os-username admin token issue
   
   Password:
   +------------+-----------------------------------------------------------------+
   | Field      | Value                                                           |
   +------------+-----------------------------------------------------------------+
   | expires    | 2016-02-12T20:14:07.056119Z                                     |
   | id         | gAAAAABWvi7_B8kKQD9wdXac8MoZiQldmjEO643d-e_j-XXq9AmIegIbA7UHGPv |
   |            | atnN21qtOMjCFWX7BReJEQnVOAj3nclRQgAYRsfSU_MrsuWb4EDtnjU7HEpoBb4 |
   |            | o6ozsA_NmFWEpLeKy0uNn_WeKbAhYygrsmQGA49dclHVnz-OMVLiyM9ws       |
   | project_id | 343d245e850143a096806dfaefa9afdc                                |
   | user_id    | ac3377633149401296f6c0d92d79dc16                                |
   +------------+-----------------------------------------------------------------+
   ```

   此命令使用**admin**用户的密码。

3. 与前面创建的myuser用户一样，请求身份验证令牌：

   ```bash
   $ openstack --os-auth-url http://controller:5000/v3 \
     --os-project-domain-name Default --os-user-domain-name Default \
     --os-project-name myproject --os-username myuser token issue
   
   Password:
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

   



### 创建 OpenStack 客户端环境脚本

前几节使用了环境变量和命令选项的组合，通过openstack客户端与Identity服务交互。为了提高客户端操作的效率，OpenStack支持简单的客户端环境脚本，也称为OpenRC文件。这些脚本通常包含所有客户端的通用选项，但也支持唯一选项。有关更多信息，请参阅[OpenStack最终用户指南](https://docs.openstack.org/user-guide/common/cli_set_environment_variables_using_openstack_rc.html)。







#### 创建脚本

为**admin**和**demo**项目以及用户创建客户端环境脚本。本指南的后续部分将参考这些脚本来为客户端操作加载适当的凭据。

客户端环境脚本的路径是不受限制的。为了方便起见，您可以将脚本放置在任何位置，但要确保它们可以访问，并且位于适合您部署的安全位置，因为它们确实包含敏感凭据。

1. 创建并编辑**admin-openrc**文件，并添加以下内容：

   OpenStack客户端还支持使用clouds.yaml文件。有关更多信息，请参阅os客户端配置。

   ```bash
   export OS_PROJECT_DOMAIN_NAME=Default
   export OS_USER_DOMAIN_NAME=Default
   export OS_PROJECT_NAME=admin
   export OS_USERNAME=admin
   export OS_PASSWORD=ADMIN_PASS
   export OS_AUTH_URL=http://controller:5000/v3
   export OS_IDENTITY_API_VERSION=3
   export OS_IMAGE_API_VERSION=2
   ```

   将ADMIN_PASS替换为您在Identity服务中为**admin**用户选择的密码。

2. 创建并编辑 demo-openrc 文件，并添加以下内容：

   ```bash
   export OS_PROJECT_DOMAIN_NAME=Default
   export OS_USER_DOMAIN_NAME=Default
   export OS_PROJECT_NAME=myproject
   export OS_USERNAME=myuser
   export OS_PASSWORD=DEMO_PASS
   export OS_AUTH_URL=http://controller:5000/v3
   export OS_IDENTITY_API_VERSION=3
   export OS_IMAGE_API_VERSION=2
   ```

   将DEMO_PASS替换为您在Identity服务中为**demo**用户选择的密码。





#### 使用脚本

要作为特定项目和用户运行客户端，只需在运行客户端之前加载相关的客户端环境脚本。例如：

1. 加载**admin-openrc**文件，用Identity服务的位置、**admin**项目和用户凭据填充环境变量：

   ```bash
   $ . admin-openrc
   
   ```

2. 请求身份验证令牌：

   ```bash
   $ openstack token issue
   
   +------------+-----------------------------------------------------------------+
   | Field      | Value                                                           |
   +------------+-----------------------------------------------------------------+
   | expires    | 2016-02-12T20:44:35.659723Z                                     |
   | id         | gAAAAABWvjYj-Zjfg8WXFaQnUd1DMYTBVrKw4h3fIagi5NoEmh21U72SrRv2trl |
   |            | JWFYhLi2_uPR31Igf6A8mH2Rw9kv_bxNo1jbLNPLGzW_u5FC7InFqx0yYtTwa1e |
   |            | eq2b0f6-18KZyQhs7F3teAta143kJEWuNEYET-y7u29y0be1_64KYkM7E       |
   | project_id | 343d245e850143a096806dfaefa9afdc                                |
   | user_id    | ac3377633149401296f6c0d92d79dc16                                |
   +------------+-----------------------------------------------------------------+
   ```

   



## glance 安装教程

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



### 安装和配置

本节介绍如何在控制器节点上安装和配置Image服务（代码为“扫视”）。为了简单起见，此配置将图像存储在本地文件系统上。

#### 先决条件

在安装和配置Image服务之前，必须创建数据库、服务凭据和API端点。

1. 要创建数据库，请完成以下步骤：

   - 使用数据库访问客户端以**root**用户身份连接到数据库服务器：

     ```bash
     # mysql
     
     ```

   - 创建**glance**数据库：

     ```bash
     MariaDB [(none)]> CREATE DATABASE glance;
     
     ```

   - 授予对**glance**数据库的正确访问权限：

     ```bash
     MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
       IDENTIFIED BY 'GLANCE_DBPASS';
     MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
       IDENTIFIED BY 'GLANCE_DBPASS';
     ```

     用合适的密码替换GLANCE_DBPASS。

   - 退出数据库访问客户端。

2. 获取**admin**凭据以访问admin-only CLI命令：

   ```bash
   $ . admin-openrc
   
   ```

3. 要创建服务凭据，请完成以下步骤：

   - 创建**glance**用户：

     ```bash
     $ openstack user create --domain default --password-prompt glance
     
     User Password:
     Repeat User Password:
     +---------------------+----------------------------------+
     | Field               | Value                            |
     +---------------------+----------------------------------+
     | domain_id           | default                          |
     | enabled             | True                             |
     | id                  | 3f4e777c4062483ab8d9edd7dff829df |
     | name                | glance                           |
     | options             | {}                               |
     | password_expires_at | None                             |
     +---------------------+----------------------------------+
     ```

   - 将**admin**角色添加到**glance**用户和**service**项目：

     ```bash
     $ openstack role add --project service --user glance admin
     
     ```

     此命令不提供输出。

   - 创建**glance**服务实体：

     ```bash
     $ openstack service create --name glance \
       --description "OpenStack Image" image
     
     +-------------+----------------------------------+
     | Field       | Value                            |
     +-------------+----------------------------------+
     | description | OpenStack Image                  |
     | enabled     | True                             |
     | id          | 8c2c7f1b9b5049ea9e63757b5533e6d2 |
     | name        | glance                           |
     | type        | image                            |
     +-------------+----------------------------------+
     ```

4. 创建映像服务API端点：

   ```bash
   $ openstack endpoint create --region RegionOne \
     image public http://controller:9292
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | 340be3625e9b4239a6415d034e98aace |
   | interface    | public                           |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | 8c2c7f1b9b5049ea9e63757b5533e6d2 |
   | service_name | glance                           |
   | service_type | image                            |
   | url          | http://controller:9292           |
   +--------------+----------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     image internal http://controller:9292
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | a6e4b153c2ae4c919eccfdbb7dceb5d2 |
   | interface    | internal                         |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | 8c2c7f1b9b5049ea9e63757b5533e6d2 |
   | service_name | glance                           |
   | service_type | image                            |
   | url          | http://controller:9292           |
   +--------------+----------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     image admin http://controller:9292
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | 0c37ed58103f4300a84ff125a539032d |
   | interface    | admin                            |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | 8c2c7f1b9b5049ea9e63757b5533e6d2 |
   | service_name | glance                           |
   | service_type | image                            |
   | url          | http://controller:9292           |
   +--------------+----------------------------------+
   ```

5. 注册配额限制（可选）：

   如果您决定在Glance中使用per-tenant配额，则必须首先在Keystone中注册限额：

   ```bash
   $ openstack --os-cloud devstack-system-admin registered limit create \
     --service glance --default-limit 1000 --region RegionOne image_size_total
   
   +---------------+----------------------------------+
   | Field         | Value                            |
   +---------------+----------------------------------+
   | default_limit | 1000                             |
   | description   | None                             |
   | id            | 9cedfc5de80345a9b13ed00c2b5460f2 |
   | region_id     | RegionOne                        |
   | resource_name | image_size_total                 |
   | service_id    | e38c84a2487f49fd9864193bdc8a3174 |
   +---------------+----------------------------------+
   
   $ openstack --os-cloud devstack-system-admin registered limit create \
     --service glance --default-limit 1000 --region RegionOne image_stage_total
   
   +---------------+----------------------------------+
   | Field         | Value                            |
   +---------------+----------------------------------+
   | default_limit | 1000                             |
   | description   | None                             |
   | id            | 5a68712b6ba6496d823d0c66e5e860b9 |
   | region_id     | RegionOne                        |
   | resource_name | image_stage_total                |
   | service_id    | e38c84a2487f49fd9864193bdc8a3174 |
   +---------------+----------------------------------+
   
   $ openstack --os-cloud devstack-system-admin registered limit create \
     --service glance --default-limit 100 --region RegionOne image_count_total
   
   +---------------+----------------------------------+
   | Field         | Value                            |
   +---------------+----------------------------------+
   | default_limit | 100                              |
   | description   | None                             |
   | id            | beb91b043296499f8e6268f29d8b2749 |
   | region_id     | RegionOne                        |
   | resource_name | image_count_total                |
   | service_id    | e38c84a2487f49fd9864193bdc8a3174 |
   +---------------+----------------------------------+
   
   $ openstack --os-cloud devstack-system-admin registered limit create \
     --service glance --default-limit 100 --region RegionOne image_count_uploading
   
   +---------------+----------------------------------+
   | Field         | Value                            |
   +---------------+----------------------------------+
   | default_limit | 100                              |
   | description   | None                             |
   | id            | fc29649c047a45bf9bc03ec4a7bcb8af |
   | region_id     | RegionOne                        |
   | resource_name | image_count_uploading            |
   | service_id    | e38c84a2487f49fd9864193bdc8a3174 |
   +---------------+----------------------------------+
   ```

   确保在**glance-api.conf**文件中也设置了**use_keystone_quotas=True**。

#### 安装和配置组件

默认配置文件因分布而异。您可能需要添加这些部分和选项，而不是修改现有的部分和选项。此外，配置片段中的省略号（…）指示您应该保留的潜在默认配置选项。

1. 安装软件包：

   ```bash
   # apt install glance
   
   ```

2. 编辑**/etc/glance/glance-api.conf**文件并完成以下操作：

   - 在[**database**]部分，配置数据库访问：

     ```bash
     [database]
     # ...
     connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
     ```

     用为图像服务数据库选择的密码替换GLANCE_DBPASS。

   - 在**[keystone_authtoken]**和**[paste_deploy]**部分中，配置Identity服务访问：

     ```bash
     [keystone_authtoken]
     # ...
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
     ```

     将**GLANCE_PASS**替换为您在Identity服务中为**glance**用户选择的密码。

     注释掉或删除`[keystone_authtoken]`部分中的任何其他选项。

   - 在`[glance_store]`部分，配置本地文件系统存储和映像文件的位置：

     ```bash
     [glance_store]
     # ...
     stores = file,http
     default_store = file
     filesystem_store_datadir = /var/lib/glance/images/
     ```

   - 在`[oslo_limit]`部分，配置对`keystone`的访问：

     ```bash
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

     确保MY_SERVICE帐户具有对系统范围资源的读取器访问权限（如限制）：

     ```bash
     $ openstack role add --user MY_SERVICE --user-domain Default --system all reader
     
     ```

     有关配置统一限制客户端的更多信息，请参阅[oslo_limit文档](https://docs.openstack.org/oslo.limit/latest/user/usage.html#configuration)。

   - 在`[DEFAULT]`部分，可以选择启用每个租户配额：

     ```bash
     [DEFAULT]
     use_keystone_quotas = True
     ```

     请注意，如果启用此功能，则必须已创建如上所述的注册限制。

3. 填充Image服务数据库：

   ```bash
   # su -s /bin/sh -c "glance-manage db_sync" glance
   
   ```

   忽略此输出中的任何弃用消息。

#### 完成安装

重新启动Image服务：

```bash
# service glance-api restart

```

### 验证操作

Ubuntu Cloud Images：https://cloud-images.ubuntu.com/



使用CirOS验证Image服务的操作，[CirOS](http://launchpad.net/cirros)是一个小型Linux映像，可帮助您测试OpenStack部署。

有关如何下载和构建映像的更多信息，请参阅[OpenStack虚拟机映像指南](https://docs.openstack.org/image-guide/)。有关如何管理图像的信息，请参阅[OpenStack最终用户指南](https://docs.openstack.org/user-guide/common/cli-manage-images.html)。



在控制器节点上执行这些命令。

1. 获取**admin**凭据以访问 admin-only CLI命令：

   ```bash
   $ . admin-openrc
   
   ```

2. 下载源镜像：

   ```bash
   $ wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
   
   ```

   如果您的发行版不包含wget，请安装它。

3. 使用[QCOW2](https://docs.openstack.org/glance/yoga/glossary.html#term-QEMU-Copy-On-Write-2-QCOW2)磁盘格式、[裸](https://docs.openstack.org/glance/yoga/glossary.html#term-bare)容器格式和公共可见性将图像上载到图像服务，以便所有项目都可以访问它：

   ```bash
   $ glance image-create --name "cirros" \
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
   ```

   有关**glance**参数的信息，请参阅《OpenStack用户指南》中的 [Image service (glance) command-line client](https://docs.openstack.org/python-glanceclient/latest/cli/details.html)。

   有关映像的磁盘和容器格式的信息，请参阅《OpenStack虚拟机映像指南》中的[Disk and container formats for images](https://docs.openstack.org/image-guide/image-formats.html)。

   OpenStack动态生成ID，因此您将在示例命令输出中看到不同的值。

4. 确认上传镜像并验证属性：

   ```bash
   $ glance image-list
   
   +--------------------------------------+--------+--------+
   | ID                                   | Name   | Status |
   +--------------------------------------+--------+--------+
   | 38047887-61a7-41ea-9b49-27987d5e8bb9 | cirros | active |
   +--------------------------------------+--------+--------+
   ```

   





## placement 安装教程

在Stein发布之前，放置代码与计算REST API代码（Nova-API）一起位于Nova中。确保此文档的发布版本与要部署的发布版本匹配。

### 步骤概述

1. 部署API服务

   Placement提供了一个放置api WSGI脚本，用于在Apache、nginx或其他支持WSGI的web服务器上运行服务。根据用于部署OpenStack的打包解决方案，WSGI脚本可能位于/usr/bin或/usr/local/bin中。

   放置api作为标准的WSGI脚本，提供了大多数WSGI服务器期望找到的模块级应用程序属性。这意味着可以在许多不同的服务器上运行它，从而在面对不同的部署场景时提供灵活性。常见的场景包括：

   - [apache2](http://httpd.apache.org/) with [mod_wsgi](https://modwsgi.readthedocs.io/)
   - apache2 with [mod_proxy_uwsgi](http://uwsgi-docs.readthedocs.io/en/latest/Apache.html)
   - [nginx](http://nginx.org/) with [uwsgi](http://uwsgi-docs.readthedocs.io/en/latest/Nginx.html)
   - nginx with [gunicorn](http://gunicorn.org/)

   在所有这些场景中，应用程序的主机、端口和装载路径（或前缀）由web服务器的配置控制，而不是由放置应用程序的配置（placement.conf）控制。

   当placement首次添加到DevStack时，它使用了mod_wsgi样式。后来它被更新为使用mod_proxy_uwsgi。查看这些变化有助于理解相关选项。

   DevStack被配置为在http或https（80或443）的默认端口上的/placement处托管placement，具体取决于是否使用TLS。需要使用默认端口。

   默认情况下，放置应用程序将从/etc/placement/placement.conf获取其设置的配置，例如数据库连接URL。可以通过在启动应用程序的进程环境中设置OS_placement_CONFIG_DIR来更改配置文件所在的目录。在oslo.config的最新版本中，还可以在环境中设置配置选项。

   当将uwsgi用于前端（例如apache2或nginx）时，需要确保uwsgi进程正在运行。在DevStack中，这是通过systemd完成的。这是管理uwsgi的多种不同方法之一。

   本文档避免声明放置服务的一组安装说明。这是因为拥有WSGI应用程序的主要目的是使部署尽可能灵活。因为放置API服务本身是无状态的（所有状态都在数据库中），所以可以在负载平衡解决方案后面部署任意数量的服务器，以实现健壮和简单的扩展。如果您熟悉安装通用WSGI应用程序（使用上面常见场景列表中的链接），这些技术将在这里适用。

2. 同步数据库

   放置服务使用自己的数据库，在配置的placement_database部分中定义。必须设置placement_database.connection选项，否则服务将无法启动。命令行工具放置管理可用于将数据库表迁移到正确的形式，包括创建它们。连接选项所描述的数据库必须已经存在，并且定义了适当的访问控制。

   同步的另一个选项是在配置中将placement_database.sync_on_startup设置为True。这将在放置web服务启动时执行任何丢失的数据库迁移。选择自动同步还是使用命令行工具取决于环境和部署工具的约束。

   警告：

   在Stein版本中，放置代码是从nova中提取的。如果要升级以使用提取的布局，则需要将布局数据从nova_api数据库迁移到布局数据库。您可以在放置库中找到可能有助于此的示例脚本：mysql-migrate-db.sh和postgresql-migrate.db.sh。另请参阅升级说明。

   当升级到Stein时，可以选择与其他OpenStack服务同时升级到提取的位置，但这不是必需的。nova代码将在其Stein版本中继续提供一份安置服务副本。但是，此副本将在Train中删除，并在升级到Train之前切换到提取的版本（可能借助上述脚本）。

3. 创建帐户并更新服务目录

   在Keystone中创建具有管理员角色的安置服务用户。

   放置API是一个单独的服务，因此应该在服务目录中的放置服务类型下注册。放置的客户端，例如nova计算节点中的资源跟踪器，将使用服务目录来查找放置端点。

   有关创建服务用户和目录项的示例，请参阅配置用户和端点。

   

   Devstack在默认HTTP端口（80）上使用/placement前缀设置放置服务，而不是使用独立端口。

### 安装程序包

本节提供有关从Linux发行包安装位置的说明。

警告：这些安装文档正在进行中。所提到的一些分发包还不可用，因此说明将不起作用。

放置服务提供了一个用于跟踪资源提供程序库存和使用情况的HTTP API。更多详情请参见放置概述。



Placement作为数据模型上的web服务运行。安装包括创建必要的数据库，安装和配置web服务。这是一个简单的过程，但有很多步骤可以将放置与OpenStack云的其余部分集成。

其他一些OpenStack服务（特别是nova）需要放置，因此它应该在其他服务之前安装，但在Identity（keystone）之后安装。

#### 先决条件

在安装和配置放置服务之前，必须创建数据库、服务凭据和API端点。

创建数据库

使用数据库访问客户端以 root 用户身份连接到数据库服务器：

```bash
# mysql

```

创建**placement**数据库：

```bash
MariaDB [(none)]> CREATE DATABASE placement;

```

授予对数据库的适当访问权限：

```bash
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';

```

将 PLACEMENT_DBPASS 替换为合适的密码。



配置用户和端点

获取**admin**凭据以获取对 admin-only 的 CLI 命令的访问权限：

```bash
$ . admin-openrc

```

使用您选择的 PLACEMENT_PASS 创建一个 Placement 服务用户：

```bash
$ openstack user create --domain default --password-prompt placement

User Password:
Repeat User Password:
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | fa742015a6494a949f67629884fc7ec8 |
| name                | placement                        |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

将 Placement 用户添加到具有管理员角色的服务项目：

```bash
$ openstack role add --project service --user placement admin

```

此命令不提供任何输出。

在服务目录中创建 Placement API 条目：

```bash
$ openstack service create --name placement \
  --description "Placement API" placement

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Placement API                    |
| enabled     | True                             |
| id          | 2d1a27022e6e4185b86adac4444c495f |
| name        | placement                        |
| type        | placement                        |
+-------------+----------------------------------+
```

创建 Placement API 服务端点：

根据您的环境，端点的URL将因端口（可能是8780而不是8778，或者根本没有端口）和主机名而异。您负责确定正确的URL。

```bash
$ openstack endpoint create --region RegionOne \
  placement public http://controller:8778

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 2b1b2637908b4137a9c2e0470487cbc0 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2d1a27022e6e4185b86adac4444c495f |
| service_name | placement                        |
| service_type | placement                        |
| url          | http://controller:8778           |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
  placement internal http://controller:8778

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 02bcda9a150a4bd7993ff4879df971ab |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2d1a27022e6e4185b86adac4444c495f |
| service_name | placement                        |
| service_type | placement                        |
| url          | http://controller:8778           |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
  placement admin http://controller:8778

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 3d71177b9e0f406f98cbff198d74b182 |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2d1a27022e6e4185b86adac4444c495f |
| service_name | placement                        |
| service_type | placement                        |
| url          | http://controller:8778           |
+--------------+----------------------------------+
```



安装和配置组件

默认配置文件因分布而异。您可能需要添加这些部分和选项，而不是修改现有的部分和选项。此外，配置片段中的省略号（…）指示您应该保留的潜在默认配置选项。

安装软件包：

```bash
# apt install placement-api

```

编辑 /etc/placement/placement.conf 文件并完成以下操作：

在 [placement_database] 部分，配置数据库访问：

```bash
[placement_database]
# ...
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
```

将 PLACEMENT_DBPASS 替换为您为放置数据库选择的密码。

在 [api] 和 [keystone_authtoken] 部分，配置身份服务访问：

```bash
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

```

将 PLACEMENT_PASS 替换为您在身份服务中为放置用户选择的密码。

注释掉或删除 [keystone_authtoken] 部分中的任何其他选项。

user_name、password、project_domain_name 和 user_domain_name 的值需要与您的 keystone 配置同步。

填充放置数据库：

```bash
# su -s /bin/sh -c "placement-manage db sync" placement

```

忽略此输出中的任何弃用消息。



完成安装

重新加载 Web 服务器以进行调整以获得新的放置配置设置。

```bash
# service apache2 restart

```

### 验证安装

在进行这些调用之前，您需要以管理员身份向身份服务进行身份验证。有许多不同的方法可以做到这一点，具体取决于您的系统设置方式。如果你没有 admin-openrc 文件，你会有类似的东西。



获取管理员凭据以获取对仅限管理员的 CLI 命令的访问权限：

```bash
$ . admin-openrc

```

执行状态检查以确保一切正常：

```bash
$ placement-status upgrade check
+----------------------------------+
| Upgrade Check Results            |
+----------------------------------+
| Check: Missing Root Provider IDs |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
| Check: Incomplete Consumers      |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
```

针对放置 API 运行一些命令：

安装 osc-placement 插件：

此示例使用 PyPI 和 pip，但如果您使用的是分发包，则可以从其存储库安装该包。随着迁移到 python3，您将需要指定 pip3 或从您的发行版安装 python3-osc-placement。

```bash
$ pip3 install osc-placement

```

列出可用的资源类别和特征：

```bash
$ openstack --os-placement-api-version 1.2 resource class list --sort-column name
+----------------------------+
| name                       |
+----------------------------+
| DISK_GB                    |
| IPV4_ADDRESS               |
| ...                        |

$ openstack --os-placement-api-version 1.6 trait list --sort-column name
+---------------------------------------+
| name                                  |
+---------------------------------------+
| COMPUTE_DEVICE_TAGGING                |
| COMPUTE_NET_ATTACH_INTERFACE          |
| ...                                   |
```









## nova 安装教程

### 计算服务概述

https://docs.openstack.org/nova/yoga/install/get-started-compute.html

使用 OpenStack Compute 来托管和管理云计算系统。OpenStack Compute 是基础架构即服务 (IaaS) 系统的主要部分。主要模块是用 Python 实现的。

OpenStack Compute 与 OpenStack Identity 交互以进行身份验证、OpenStack Placement 以进行资源库存跟踪和选择、OpenStack Image 服务以提供磁盘和服务器映像，以及 OpenStack Dashboard 以提供用户和管理界面。图片访问受项目和用户限制；每个项目的配额是有限的（例如，实例数）。OpenStack Compute 可以在标准硬件上水平扩展，并下载图像以启动实例。

OpenStack Compute 由以下区域及其组件组成：

`nova-api` service

接受并响应最终用户计算 API 调用。该服务支持 OpenStack Compute API。它执行一些策略并启动大多数编排活动，例如运行实例。

`nova-api-metadata` service

接受来自实例的元数据请求。有关详细信息，请参阅 [元数据服务](https://docs.openstack.org/nova/yoga/admin/metadata-service.html)。

`nova-compute` service

通过管理程序 API 创建和终止虚拟机实例的工作守护程序。例如：

- 用于 KVM 或 QEMU 的 libvirt
- 用于 VMware 的 VMwareAPI

处理相当复杂。基本上，守护进程从队列中接受操作并执行一系列系统命令，例如启动 KVM 实例并更新其在数据库中的状态。

`nova-scheduler` service

从队列中获取虚拟机实例请求并确定它在哪个计算服务器主机上运行。

`nova-conductor` module

调解`nova-compute`服务和数据库之间的交互。它消除了服务对云数据库的直接访问 `nova-compute`。该`nova-conductor`模块水平缩放。但是，请勿将其部署在`nova-compute`服务运行的节点上。有关详细信息，请参阅[配置选项](https://docs.openstack.org/nova/yoga/configuration/config.html)`conductor`中的部分 。

`nova-novncproxy` daemon

提供用于通过 VNC 连接访问正在运行的实例的代理。支持基于浏览器的 novnc 客户端。

`nova-spicehtml5proxy` daemon

提供代理以通过 SPICE 连接访问正在运行的实例。支持基于浏览器的 HTML5 客户端。

The queue

在守护进程之间传递消息的中心枢纽。通常使用 [RabbitMQ](https://www.rabbitmq.com/)实现，但 [也可以使用其他选项](https://docs.openstack.org/oslo.messaging/yoga/admin/drivers)。

SQL database

存储云基础架构的大多数构建时和运行时状态，包括：

- 可用实例类型
- 使用实例
- 可用网络
- 项目

理论上，OpenStack Compute 可以支持 SQLAlchemy 支持的任何数据库。常见的数据库有用于测试和开发工作的 SQLite3、MySQL、MariaDB 和 PostgreSQL。



### 安装和配置控制器节点

https://docs.openstack.org/nova/yoga/install/controller-install-ubuntu.html

先决条件

在安装和配置计算服务之前，您必须创建数据库、服务凭证和 API 端点。

1. 要创建数据库，请完成以下步骤：

   - 使用数据库访问客户端以`root`用户身份连接到数据库服务器：

     ```bash
     # mysql
     
     ```

   - 创建`nova_api`、`nova`和`nova_cell0`数据库：

     ```bash
     MariaDB [(none)]> CREATE DATABASE nova_api;
     MariaDB [(none)]> CREATE DATABASE nova;
     MariaDB [(none)]> CREATE DATABASE nova_cell0;
     
     ```

   - 授予对数据库的适当访问权限：

     ```bash
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
     ```

     替换`NOVA_DBPASS`为合适的密码。

2. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

3. 创建计算服务凭证：

   - 创建`nova`用户：

     ```bash
     $ openstack user create --domain default --password-prompt nova
     
     User Password:
     Repeat User Password:
     +---------------------+----------------------------------+
     | Field               | Value                            |
     +---------------------+----------------------------------+
     | domain_id           | default                          |
     | enabled             | True                             |
     | id                  | 8a7dbf5279404537b1c7b86c033620fe |
     | name                | nova                             |
     | options             | {}                               |
     | password_expires_at | None                             |
     +---------------------+----------------------------------+
     ```

   - `admin`为用户添加角色`nova`：

     ```bash
     $ openstack role add --project service --user nova admin
     
     ```

     此命令不提供任何输出。

   - 创建`nova`服务实体：

     ```bash
     $ openstack service create --name nova \
       --description "OpenStack Compute" compute
     
     +-------------+----------------------------------+
     | Field       | Value                            |
     +-------------+----------------------------------+
     | description | OpenStack Compute                |
     | enabled     | True                             |
     | id          | 060d59eac51b4594815603d75a00aba2 |
     | name        | nova                             |
     | type        | compute                          |
     +-------------+----------------------------------+
     ```

4. 创建计算 API 服务端点：

   ```bash
   $ openstack endpoint create --region RegionOne \
     compute public http://controller:8774/v2.1
   
   +--------------+-------------------------------------------+
   | Field        | Value                                     |
   +--------------+-------------------------------------------+
   | enabled      | True                                      |
   | id           | 3c1caa473bfe4390a11e7177894bcc7b          |
   | interface    | public                                    |
   | region       | RegionOne                                 |
   | region_id    | RegionOne                                 |
   | service_id   | 060d59eac51b4594815603d75a00aba2          |
   | service_name | nova                                      |
   | service_type | compute                                   |
   | url          | http://controller:8774/v2.1               |
   +--------------+-------------------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     compute internal http://controller:8774/v2.1
   
   +--------------+-------------------------------------------+
   | Field        | Value                                     |
   +--------------+-------------------------------------------+
   | enabled      | True                                      |
   | id           | e3c918de680746a586eac1f2d9bc10ab          |
   | interface    | internal                                  |
   | region       | RegionOne                                 |
   | region_id    | RegionOne                                 |
   | service_id   | 060d59eac51b4594815603d75a00aba2          |
   | service_name | nova                                      |
   | service_type | compute                                   |
   | url          | http://controller:8774/v2.1               |
   +--------------+-------------------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     compute admin http://controller:8774/v2.1
   
   +--------------+-------------------------------------------+
   | Field        | Value                                     |
   +--------------+-------------------------------------------+
   | enabled      | True                                      |
   | id           | 38f7af91666a47cfb97b4dc790b94424          |
   | interface    | admin                                     |
   | region       | RegionOne                                 |
   | region_id    | RegionOne                                 |
   | service_id   | 060d59eac51b4594815603d75a00aba2          |
   | service_name | nova                                      |
   | service_type | compute                                   |
   | url          | http://controller:8774/v2.1               |
   +--------------+-------------------------------------------+
   ```

5. 安装 Placement 服务并配置用户和端点：

   - 有关详细信息，请参阅[放置服务安装指南。](https://docs.openstack.org/placement/yoga/install/install-ubuntu.html#configure-user-and-endpoints)



安装和配置组件



默认配置文件因发行版而异。您可能需要添加这些部分和选项，而不是修改现有部分和选项。`...`此外，配置片段中的省略号 ( ) 表示您应该保留的潜在默认配置选项。



1. 安装软件包：

   ```bash
   # apt install nova-api nova-conductor nova-novncproxy nova-scheduler
   
   ```

2. 编辑`/etc/nova/nova.conf`文件并完成以下操作：

   - 在`[api_database]`和`[database]`部分，配置数据库访问：

     ```bash
     [api_database]
     # ...
     connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api
     
     [database]
     # ...
     connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova
     ```

     替换`NOVA_DBPASS`为您为计算数据库选择的密码。

   - 在`[DEFAULT]`部分中，配置`RabbitMQ`消息队列访问：

     ```bash
     [DEFAULT]
     # ...
     transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/
     ```

     替换为您 在 中`RABBIT_PASS`为帐户选择的密码。`openstackRabbitMQ`

   - 在`[api]`和`[keystone_authtoken]`部分，配置身份服务访问：

     ```bash
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
     ```

     替换为您在身份服务中`NOVA_PASS`为用户选择的密码。`nova`

     注释掉或删除该`[keystone_authtoken]` 部分中的任何其他选项。

   - 在该`[DEFAULT]`部分中，配置选项`my_ip`以使用控制器节点的管理接口 IP 地址：

     ```bash
     [DEFAULT]
     # ...
     my_ip = 10.0.0.11
     ```

   - 配置**/etc/nova/nova.conf**`[neutron]`的部分。 有关详细信息，请参阅[网络服务安装指南。](https://docs.openstack.org/neutron/yoga/install/controller-install-ubuntu.html#configure-the-compute-service-to-use-the-networking-service)

   - 在该`[vnc]`部分中，配置 VNC 代理以使用控制器节点的管理接口 IP 地址：

     ```bash
     [vnc]
     enabled = true
     # ...
     server_listen = $my_ip
     server_proxyclient_address = $my_ip
     ```

   - 在该`[glance]`部分中，配置图像服务 API 的位置：

     ```bash
     [glance]
     # ...
     api_servers = http://controller:9292
     ```

   - 在`[oslo_concurrency]`部分中，配置锁定路径：

     ```bash
     [oslo_concurrency]
     # ...
     lock_path = /var/lib/nova/tmp
     ```

   - 由于打包错误，请`log_dir`从该 `[DEFAULT]`部分中删除该选项。

   - 在`[placement]`部分中，配置对 Placement 服务的访问：

     ```bash
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

     替换为您为安装 [Placement](https://docs.openstack.org/placement/yoga/install/)`PLACEMENT_PASS`时创建的服务用户选择的密码 。注释掉或删除该部分中的任何其他选项。`placement``[placement]`

3. 填充`nova-api`数据库：

   ```bash
   # su -s /bin/sh -c "nova-manage api_db sync" nova
   
   ```

4. 注册`cell0`数据库：

   ```bash
   # su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
   
   ```

5. 创建`cell1`单元格：

   ```bash
   # su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
   
   ```

6. 填充 nova 数据库：

   ```bash
   # su -s /bin/sh -c "nova-manage db sync" nova
   
   ```

7. 验证 nova cell0 和 cell1 是否正确注册：

   ```bash
   # su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
   +-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
   |  Name |                 UUID                 |                   Transport URL                    |                     Database Connection                      | Disabled |
   +-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
   | cell0 | 00000000-0000-0000-0000-000000000000 |                       none:/                       | mysql+pymysql://nova:****@controller/nova_cell0?charset=utf8 |  False   |
   | cell1 | f690f4fd-2bc5-4f15-8145-db561a7b9d3d | rabbit://openstack:****@controller:5672/nova_cell1 | mysql+pymysql://nova:****@controller/nova_cell1?charset=utf8 |  False   |
   +-------+--------------------------------------+----------------------------------------------------+--------------------------------------------------------------+----------+
   ```

完成安装

重新启动计算服务：

```bash
# service nova-api restart
# service nova-scheduler restart
# service nova-conductor restart
# service nova-novncproxy restart
```

### 安装和配置计算节点

该服务支持多个管理程序来部署实例或虚拟机 (VM)。为简单起见，此配置在支持虚拟机硬件加速的计算节点上使用 Quick EMUlator (QEMU) 管理程序和基于内核的 VM (KVM) 扩展。在传统硬件上，此配置使用通用 QEMU 管理程序。您可以按照这些说明稍作修改，以使用额外的计算节点水平扩展您的环境。

本节假定您正在按照本指南中的说明逐步配置第一个计算节点。如果要配置额外的计算节点，请以与[示例体系结构](https://docs.openstack.org/nova/yoga/install/overview.html#overview-example-architectures)部分中的第一个计算节点类似的方式准备它们。每个额外的计算节点都需要一个唯一的 IP 地址。



安装和配置组件

默认配置文件因发行版而异。您可能需要添加这些部分和选项，而不是修改现有部分和选项。`...`此外，配置片段中的省略号 ( ) 表示您应该保留的潜在默认配置选项。

1. 安装软件包：

   ```bash
   # apt install nova-compute
   
   ```

2. 编辑`/etc/nova/nova.conf`文件并完成以下操作：

   - 在`[DEFAULT]`部分中，配置`RabbitMQ`消息队列访问：

     ```bash
     [DEFAULT]
     # ...
     transport_url = rabbit://openstack:RABBIT_PASS@controller
     ```

     替换为您 在 中`RABBIT_PASS`为帐户选择的密码。`openstackRabbitMQ`

   - 在`[api]`和`[keystone_authtoken]`部分，配置身份服务访问：

     ```bash
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
     ```

     替换为您在身份服务中`NOVA_PASS`为用户选择的密码。`nova`

     注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

   - 在`[DEFAULT]`部分中，配置`my_ip`选项

     ```bash
     [DEFAULT]
     # ...
     my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS
     ```

     替换`MANAGEMENT_INTERFACE_IP_ADDRESS`为计算节点上管理网络接口的 IP 地址，对于[示例架构](https://docs.openstack.org/nova/yoga/install/overview.html#overview-example-architectures)中的第一个节点，通常为 10.0.0.31 。

   - 配置**/etc/nova/nova.conf**`[neutron]`的部分。 有关详细信息，请参阅[网络服务安装指南。](https://docs.openstack.org/neutron/yoga/install/compute-install-ubuntu.html#configure-the-compute-service-to-use-the-networking-service)

   - 在`[vnc]`部分中，启用和配置远程控制台访问：

     ```bash
     [vnc]
     # ...
     enabled = true
     server_listen = 0.0.0.0
     server_proxyclient_address = $my_ip
     novncproxy_base_url = http://controller:6080/vnc_auto.html
     ```

     服务器组件监听所有IP地址，代理组件只监听计算节点的管理接口IP地址。基本 URL 指示您可以使用 Web 浏览器访问此计算节点上实例的远程控制台的位置。

     如果用于访问远程控制台的 Web 浏览器驻留在无法解析`controller`主机名的主机上，则必须替换 `controller`为控制器节点的管理接口 IP 地址。

   - 在该`[glance]`部分中，配置图像服务 API 的位置：

     ```bash
     [glance]
     # ...
     api_servers = http://controller:9292
     ```

   - 在`[oslo_concurrency]`部分中，配置锁定路径：

     ```bash
     [oslo_concurrency]
     # ...
     lock_path = /var/lib/nova/tmp
     ```

   - 在`[placement]`部分中，配置 Placement API：

     ```bash
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

     替换为您在身份服务中`PLACEMENT_PASS`为用户选择的密码 。`placement`注释掉该`[placement]`部分中的任何其他选项。





完成安装

1. 确定您的计算节点是否支持虚拟机的硬件加速：

   ```bash
   $ egrep -c '(vmx|svm)' /proc/cpuinfo
   
   ```

   如果此命令返回值，则您的计算节点支持通常不需要额外配置的硬件加速。`one or greater`

   如果此命令返回值为`zero`，则您的计算节点不支持硬件加速，您必须配置`libvirt`为使用 QEMU 而不是 KVM。

   - 编辑文件`[libvirt]`中的部分，`/etc/nova/nova-compute.conf`如下所示：

     ```bash
     [libvirt]
     # ...
     virt_type = qemu
     ```

2. 重新启动计算服务：

   ```bash
   # service nova-compute restart
   
   ```





如果`nova-compute`服务启动失败，请检查 `/var/log/nova/nova-compute.log`。该错误消息可能表明控制器节点上的防火墙阻止访问端口 5672。配置防火墙以打开控制器节点上的端口 5672 并重新启动 计算节点上的服务。`AMQP server on controller:5672 is unreachable``nova-compute`



将计算节点添加到单元数据库

**在控制器**节点上运行以下命令。

1. 获取管理员凭据以启用仅限管理员的 CLI 命令，然后确认数据库中有计算主机：

   ```bash
   $ . admin-openrc
   
   $ openstack compute service list --service nova-compute
   +----+-------+--------------+------+-------+---------+----------------------------+
   | ID | Host  | Binary       | Zone | State | Status  | Updated At                 |
   +----+-------+--------------+------+-------+---------+----------------------------+
   | 1  | node1 | nova-compute | nova | up    | enabled | 2017-04-14T15:30:44.000000 |
   +----+-------+--------------+------+-------+---------+----------------------------+
   ```

2. 发现计算主机：

   ```bash
   # su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
   
   Found 2 cell mappings.
   Skipping cell0 since it does not contain hosts.
   Getting compute nodes from cell 'cell1': ad5a5985-a719-4567-98d8-8d148aaae4bc
   Found 1 computes in cell: ad5a5985-a719-4567-98d8-8d148aaae4bc
   Checking host mapping for compute host 'compute': fe58ddc1-1d65-4f87-9456-bc040dc106b3
   Creating host mapping for compute host 'compute': fe58ddc1-1d65-4f87-9456-bc040dc106b3
   ```

当您添加新的计算节点时，您必须在控制器节点上运行以注册这些新的计算节点。或者，您可以在中设置适当的间隔 ：`nova-manage cell_v2 discover_hosts``/etc/nova/nova.conf`

```bash
[scheduler]
discover_hosts_in_cells_interval = 300
```

### 验证操作

在控制器节点上执行这些命令。

1. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

2. 列出服务组件以验证每个进程的成功启动和注册：

   ```bash
   $ openstack compute service list
   
   +----+--------------------+------------+----------+---------+-------+----------------------------+
   | Id | Binary             | Host       | Zone     | Status  | State | Updated At                 |
   +----+--------------------+------------+----------+---------+-------+----------------------------+
   |  1 | nova-scheduler     | controller | internal | enabled | up    | 2016-02-09T23:11:15.000000 |
   |  2 | nova-conductor     | controller | internal | enabled | up    | 2016-02-09T23:11:16.000000 |
   |  3 | nova-compute       | compute1   | nova     | enabled | up    | 2016-02-09T23:11:20.000000 |
   +----+--------------------+------------+----------+---------+-------+----------------------------+
   ```

   此输出应指示在控制器节点上启用的两个服务组件和在计算节点上启用的一个服务组件。

3. 列出身份服务中的 API 端点以验证与身份服务的连接：

   下面的端点列表可能因 OpenStack 组件的安装而异。

   ```bash
   $ openstack catalog list
   
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
   
   ```

   忽略此输出中的任何警告。

4. 列出图像服务中的图像以验证与图像服务的连接：

   ```bash
   $ openstack image list
   
   +--------------------------------------+-------------+-------------+
   | ID                                   | Name        | Status      |
   +--------------------------------------+-------------+-------------+
   | 9a76d9f9-9620-4f2e-8c69-6c5691fae163 | cirros      | active      |
   +--------------------------------------+-------------+-------------+
   ```

5. 检查单元格和放置 API 是否正常工作，以及其他必要的先决条件是否已到位：

   ```bash
   # nova-status upgrade check
   
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

   



## neutron 安装教程

网络服务安装指南

### 网络服务概述

OpenStack Networking (neutron) 允许您创建由其他 OpenStack 服务管理的接口设备并将其附加到网络。可以实施插件以适应不同的网络设备和软件，为 OpenStack 架构和部署提供灵活性。

它包括以下组件：

- **neutron-server**

  接受 API 请求并将其路由到适当的 OpenStack Networking 插件以进行操作。

- **OpenStack Networking plug-ins and agents**

  插入和拔出端口、创建网络或子网以及提供 IP 寻址。这些插件和代理因特定云中使用的供应商和技术而异。OpenStack Networking 附带用于 Cisco 虚拟和物理交换机、NEC OpenFlow 产品、Open vSwitch、Linux 桥接和 VMware NSX 产品的插件和代理。常见的代理是 L3（第 3 层）、DHCP（动态主机 IP 寻址）和插件代理。

- **Messaging queue**

  大多数 OpenStack 网络安装使用它在 neutron 服务器和各种代理之间路由信息。还充当数据库来存储特定插件的网络状态。

OpenStack Networking 主要与 OpenStack Compute 交互，为其实例提供网络和连接。



### 主机联网

https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html

在为您选择部署的体系结构的每个节点上安装操作系统后，您必须配置网络接口。我们建议您禁用任何自动网络管理工具，并为您的发行版手动编辑适当的配置文件。有关如何在您的发行版上配置网络的更多信息，请参阅[文档](https://help.ubuntu.com/lts/serverguide/network-configuration.html)。

#### 控制器节点

配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：10.0.0.11

   网络掩码：255.255.255.0（或/24）

   默认网关：10.0.0.1

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， *eth1*或*ens224*。

- 编辑`/etc/network/interfaces`文件以包含以下内容：

  ```bash
  # The provider network interface
  auto INTERFACE_NAME
  iface INTERFACE_NAME inet manual
  up ip link set dev $IFACE up
  down ip link set dev $IFACE down
  ```

  重新启动系统以激活更改。



配置名称解析

1. 将节点的主机名设置为`controller`。

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   10.0.0.11       controller
   
   # compute1
   10.0.0.31       compute1
   
   # block1
   10.0.0.41       block1
   
   # object1
   10.0.0.51       object1
   
   # object2
   10.0.0.52       object2
   ```

   警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**

#### 计算节点

配置网络接口

1. 将第一个接口配置为管理接口：

   IP地址：10.0.0.31

   网络掩码：255.255.255.0（或/24）

   默认网关：10.0.0.1

   其他计算节点应使用 10.0.0.32、10.0.0.33 等。

2. 提供者接口使用没有分配 IP 地址的特殊配置。将第二个接口配置为提供者接口：

   替换`INTERFACE_NAME`为实际的接口名称。例如， *eth1*或*ens224*。

   ```bash
   # The provider network interface
   auto INTERFACE_NAME
   iface  INTERFACE_NAME inet manual
   up ip link set dev $IFACE up
   down ip link set dev $IFACE down
   ```

   重新启动系统以激活更改

配置名称解析

1. 将节点的主机名设置为`compute1`。

2. 编辑`/etc/hosts`文件以包含以下内容：

   ```bash
   # controller
   10.0.0.11       controller
   
   # compute1
   10.0.0.31       compute1
   
   # block1
   10.0.0.41       block1
   
   # object1
   10.0.0.51       object1
   
   # object2
   10.0.0.52       object2
   ```

   警告：一些发行版在文件中添加了一个无关条目`/etc/hosts` ，将实际主机名解析为另一个环回 IP 地址，例如`127.0.1.1`. 您必须注释掉或删除此条目以防止出现名称解析问题。 **不要删除 127.0.0.1 条目。**



#### 验证连通性

我们建议您在进一步操作之前验证到 Internet 和节点之间的网络连接。

1. 从*控制器*节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 openstack.org
   
   PING openstack.org (174.143.194.225) 56(84) bytes of data.
   64 bytes from 174.143.194.225: icmp_seq=1 ttl=54 time=18.3 ms
   64 bytes from 174.143.194.225: icmp_seq=2 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=3 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=4 ttl=54 time=17.4 ms
   
   --- openstack.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3022ms
   rtt min/avg/max/mdev = 17.489/17.715/18.346/0.364 ms
   ```

2. 从*控制器节点，测试对**计算*节点上管理界面的访问 ：

   ```bash
   # ping -c 4 compute1
   
   PING compute1 (10.0.0.31) 56(84) bytes of data.
   64 bytes from compute1 (10.0.0.31): icmp_seq=1 ttl=64 time=0.263 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=2 ttl=64 time=0.202 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=3 ttl=64 time=0.203 ms
   64 bytes from compute1 (10.0.0.31): icmp_seq=4 ttl=64 time=0.202 ms
   
   --- compute1 ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3000ms
   rtt min/avg/max/mdev = 0.202/0.217/0.263/0.030 ms
   ```

3. 从*计算*节点，测试对 Internet 的访问：

   ```bash
   # ping -c 4 openstack.org
   
   PING openstack.org (174.143.194.225) 56(84) bytes of data.
   64 bytes from 174.143.194.225: icmp_seq=1 ttl=54 time=18.3 ms
   64 bytes from 174.143.194.225: icmp_seq=2 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=3 ttl=54 time=17.5 ms
   64 bytes from 174.143.194.225: icmp_seq=4 ttl=54 time=17.4 ms
   
   --- openstack.org ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3022ms
   rtt min/avg/max/mdev = 17.489/17.715/18.346/0.364 ms
   ```

4. 从*计算节点，测试对**控制器*节点上管理界面的访问 ：

   ```bash
   # ping -c 4 controller
   
   PING controller (10.0.0.11) 56(84) bytes of data.
   64 bytes from controller (10.0.0.11): icmp_seq=1 ttl=64 time=0.263 ms
   64 bytes from controller (10.0.0.11): icmp_seq=2 ttl=64 time=0.202 ms
   64 bytes from controller (10.0.0.11): icmp_seq=3 ttl=64 time=0.203 ms
   64 bytes from controller (10.0.0.11): icmp_seq=4 ttl=64 time=0.202 ms
   
   --- controller ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3000ms
   rtt min/avg/max/mdev = 0.202/0.217/0.263/0.030 ms
   ```



### 安装和配置控制节点

先决条件

在配置 OpenStack Networking (neutron) 服务之前，您必须创建数据库、服务凭证和 API 端点。

1. 要创建数据库，请完成以下步骤：

   - 使用数据库访问客户端以`root`用户身份连接到数据库服务器：

     ```bash
     $ mysql -u root -p
     
     ```

   - 创建`neutron`数据库：

     ```bash
     MariaDB [(none)] CREATE DATABASE neutron;
     
     ```

   - 授予对`neutron`数据库的适当访问权限，替换 `NEUTRON_DBPASS`为合适的密码：

     ```bash
     MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
       IDENTIFIED BY 'NEUTRON_DBPASS';
     MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
       IDENTIFIED BY 'NEUTRON_DBPASS';
     ```

2. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

3. 要创建服务凭证，请完成以下步骤：

   - 创建`neutron`用户：

     ```bash
     $ openstack user create --domain default --password-prompt neutron
     
     User Password:
     Repeat User Password:
     +---------------------+----------------------------------+
     | Field               | Value                            |
     +---------------------+----------------------------------+
     | domain_id           | default                          |
     | enabled             | True                             |
     | id                  | fdb0f541e28141719b6a43c8944bf1fb |
     | name                | neutron                          |
     | options             | {}                               |
     | password_expires_at | None                             |
     +---------------------+----------------------------------+
     ```

   - `admin`为用户添加角色`neutron`：

     ```bash
     $ openstack role add --project service --user neutron admin
     
     ```

   - 创建`neutron`服务实体：

     ```bash
     $ openstack service create --name neutron \
       --description "OpenStack Networking" network
     
     +-------------+----------------------------------+
     | Field       | Value                            |
     +-------------+----------------------------------+
     | description | OpenStack Networking             |
     | enabled     | True                             |
     | id          | f71529314dab4a4d8eca427e701d209e |
     | name        | neutron                          |
     | type        | network                          |
     +-------------+----------------------------------+
     
     ```

4. 创建网络服务 API 端点：

   ```bash
   $ openstack endpoint create --region RegionOne \
     network public http://controller:9696
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | 85d80a6d02fc4b7683f611d7fc1493a3 |
   | interface    | public                           |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | f71529314dab4a4d8eca427e701d209e |
   | service_name | neutron                          |
   | service_type | network                          |
   | url          | http://controller:9696           |
   +--------------+----------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     network internal http://controller:9696
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | 09753b537ac74422a68d2d791cf3714f |
   | interface    | internal                         |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | f71529314dab4a4d8eca427e701d209e |
   | service_name | neutron                          |
   | service_type | network                          |
   | url          | http://controller:9696           |
   +--------------+----------------------------------+
   
   $ openstack endpoint create --region RegionOne \
     network admin http://controller:9696
   
   +--------------+----------------------------------+
   | Field        | Value                            |
   +--------------+----------------------------------+
   | enabled      | True                             |
   | id           | 1ee14289c9374dffb5db92a5c112fc4e |
   | interface    | admin                            |
   | region       | RegionOne                        |
   | region_id    | RegionOne                        |
   | service_id   | f71529314dab4a4d8eca427e701d209e |
   | service_name | neutron                          |
   | service_type | network                          |
   | url          | http://controller:9696           |
   +--------------+----------------------------------+
   ```



配置网络选项



您可以使用选项 1 和 2 表示的两种体系结构之一来部署网络服务。

选项 1 部署了最简单的架构，它只支持将实例附加到提供商（外部）网络。没有自助服务（专用）网络、路由器或浮动 IP 地址。只有`admin`特权用户或其他特权用户可以管理提供商网络。

选项 2 使用支持将实例附加到自助服务网络的第 3 层服务增强选项 1。该`demo`用户或其他非特权用户可以管理自助服务网络，包括在自助服务网络和提供商网络之间提供连接的路由器。此外，浮动 IP 地址使用来自外部网络（例如 Internet）的自助服务网络提供与实例的连接。

自助服务网络通常使用覆盖网络。诸如 VXLAN 之类的覆盖网络协议包括额外的标头，这些标头会增加开销并减少可用于有效负载或用户数据的空间。在不了解虚拟网络基础结构的情况下，实例会尝试使用 1500 字节的默认以太网最大传输单元 (MTU) 发送数据包。网络服务通过 DHCP 自动为实例提供正确的 MTU 值。但是，某些云映像不使用 DHCP 或忽略 DHCP MTU 选项，需要使用元数据或脚本进行配置。

选择以下网络选项之一来配置特定于它的服务。之后，返回此处并继续 [配置元数据代理](https://docs.openstack.org/neutron/yoga/install/controller-install-ubuntu.html#neutron-controller-metadata-agent-ubuntu)。

- [网络选项 1：供应商网络](https://docs.openstack.org/neutron/yoga/install/controller-install-option1-ubuntu.html)
- [网络选项 2：自助服务网络](https://docs.openstack.org/neutron/yoga/install/controller-install-option2-ubuntu.html)



配置元数据代理

元数据代理向实例提供配置信息，例如凭据。

- 编辑`/etc/neutron/metadata_agent.ini`文件并完成以下操作：

  - 在部分中`[DEFAULT]`，配置元数据主机和共享密钥：

    ```bash
    [DEFAULT]
    # ...
    nova_metadata_host = controller
    metadata_proxy_shared_secret = METADATA_SECRET
    ```

    替换`METADATA_SECRET`为适合元数据代理的密码。



配置计算服务以使用网络服务



必须安装 Nova 计算服务才能完成此步骤。[有关详细信息，请参阅文档网站](https://docs.openstack.org/)安装指南部分 下的计算安装指南 。

- 编辑`/etc/nova/nova.conf`文件并执行以下操作：

  - 在该`[neutron]`部分中，配置访问参数、启用元数据代理并配置机密：

    ```bash
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
    metadata_proxy_shared_secret = METADATA_SECRET
    ```

    替换为您 在身份服务中`NEUTRON_PASS`为用户选择的密码。`neutron`

    替换`METADATA_SECRET`为您为元数据代理选择的密码。

    请参阅[计算服务配置指南](https://docs.openstack.org/nova/yoga/configuration/config.html#neutron) 以获取完整的选项集，包括在必要时覆盖服务目录端点 URL。

完成安装

1. 填充数据库：

   ```bash
   # su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
     --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
   ```

   稍后会为网络填充数据库，因为该脚本需要完整的服务器和插件配置文件。

2. 重新启动计算 API 服务：

   ```bash
   # service nova-api restart
   
   ```

3. 重新启动网络服务。

   对于两个网络选项：

   ```bash
   # service neutron-server restart
   # service neutron-linuxbridge-agent restart
   # service neutron-dhcp-agent restart
   # service neutron-metadata-agent restart
   ```

   对于网络选项 2，还要重新启动第 3 层服务：

   ```bash
   # service neutron-l3-agent restart
   
   ```

#### 网络选项 1：供应商网络

*在控制器*节点上安装和配置网络组件。

安装组件

```bash
# apt install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-dhcp-agent \
  neutron-metadata-agent
```

配置服务器组件

Networking 服务器组件配置包括数据库、身份验证机制、消息队列、拓扑更改通知和插件。

默认配置文件因发行版而异。您可能需要添加这些部分和选项，而不是修改现有部分和选项。`...`此外，配置片段中的省略号 ( ) 表示您应该保留的潜在默认配置选项。

- 编辑`/etc/neutron/neutron.conf`文件并完成以下操作：

  - 在`[database]`部分中，配置数据库访问：

    ```bash
    [database]
    # ...
    connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
    ```

    替换`NEUTRON_DBPASS`为您为数据库选择的密码。

    注释掉或删除`connection`该部分中的任何其他选项 `[database]`。

  - 在该`[DEFAULT]`部分中，启用 Modular Layer 2 (ML2) 插件并禁用其他插件：

    ```bash
    [DEFAULT]
    # ...
    core_plugin = ml2
    service_plugins =
    ```

  - 在`[DEFAULT]`部分中，配置`RabbitMQ` 消息队列访问：

    ```bash
    [DEFAULT]
    # ...
    transport_url = rabbit://openstack:RABBIT_PASS@controller
    ```

    替换`RABBIT_PASS`为您为 RabbitMQ 中的帐户选择的密码 `openstack`。

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
    username = neutron
    password = NEUTRON_PASS
    ```

    替换为您 在身份服务中`NEUTRON_PASS`为用户选择的密码。`neutron`

    注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

  - 在`[DEFAULT]`和`[nova]`部分中，配置 Networking 以通知 Compute 网络拓扑更改：

    ```bash
    [DEFAULT]
    # ...
    notify_nova_on_port_status_changes = true
    notify_nova_on_port_data_changes = true
    
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
    ```

    替换为您 在身份服务中`NOVA_PASS`为用户选择的密码。`nova`

- 在`[oslo_concurrency]`部分中，配置锁定路径：

  ```bash
  [oslo_concurrency]
  # ...
  lock_path = /var/lib/neutron/tmp
  ```

  

配置模块化第 2 层（ML2）插件

ML2 插件使用 Linux 桥接机制为实例构建第 2 层（桥接和交换）虚拟网络基础设施。

- 编辑`/etc/neutron/plugins/ml2/ml2_conf.ini`文件并完成以下操作：

  - 在该`[ml2]`部分中，启用平面和 VLAN 网络：

    ```bash
    [ml2]
    # ...
    type_drivers = flat,vlan
    ```

  - 在`[ml2]`部分中，禁用自助服务网络：

    ```bash
    [ml2]
    # ...
    tenant_network_types =
    ```

  - 在该`[ml2]`部分中，启用 Linux 桥接机制：

    ```bash
    [ml2]
    # ...
    mechanism_drivers = linuxbridge
    ```

    配置 ML2 插件后，删除选项中的值 `type_drivers`会导致数据库不一致。

  - 在该`[ml2]`部分中，启用端口安全扩展驱动程序：

    ```bash
    [ml2]
    # ...
    extension_drivers = port_security
    ```

  - 在`[ml2_type_flat]`部分中，将提供者虚拟网络配置为平面网络：

    ```bash
    [ml2_type_flat]
    # ...
    flat_networks = provider
    ```

  - 在该`[securitygroup]`部分中，启用 ipset 以提高安全组规则的效率：

    ```bash
    [securitygroup]
    # ...
    enable_ipset = true
    ```



配置 Linux 网桥代理

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

- 编辑`/etc/neutron/plugins/ml2/linuxbridge_agent.ini`文件并完成以下操作：

  - 在`[linux_bridge]`部分中，将提供商虚拟网络映射到提供商物理网络接口：

    ```bash
    [linux_bridge]
    physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
    ```

    替换`PROVIDER_INTERFACE_NAME`为底层提供者物理网络接口的名称。 有关详细信息，请参阅[主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在`[vxlan]`部分中，禁用 VXLAN 覆盖网络：

    ```bash
    [vxlan]
    enable_vxlan = false
    ```

  - 在该`[securitygroup]`部分中，启用安全组并配置 Linux bridge iptables 防火墙驱动程序：

    ```bash
    [securitygroup]
    # ...
    enable_security_group = true
    firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    ```

  - `sysctl`通过验证以下所有值都设置为，确保您的 Linux 操作系统内核支持网桥过滤器`1`：

    ```bash
    net.bridge.bridge-nf-call-iptables
    net.bridge.bridge-nf-call-ip6tables
    ```

    要启用网桥支持，通常`br_netfilter`需要加载内核模块。查看您的操作系统文档以获取有关启用此模块的更多详细信息。



配置 DHCP 代理

DHCP 代理为虚拟网络提供 DHCP 服务。

- 编辑`/etc/neutron/dhcp_agent.ini`文件并完成以下操作：

  - 在该`[DEFAULT]`部分中，配置 Linux 桥接接口驱动程序、Dnsmasq DHCP 驱动程序并启用隔离元数据，以便提供商网络上的实例可以通过网络访问元数据：

    ```bash
    [DEFAULT]
    # ...
    interface_driver = linuxbridge
    dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
    enable_isolated_metadata = true
    ```





创建供应商网络

按照一般安装指南中的[提供商网络文档](https://docs.openstack.org/install-guide/launch-instance-networks-provider.html)进行操作。

返回*网络控制器节点配置*。

#### 网络选项 2：自助服务网络

https://docs.openstack.org/neutron/yoga/install/controller-install-option2-ubuntu.html

*在控制器*节点上安装和配置网络组件。



安装组件

```bash
# apt install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent
```

配置服务器组件

- 编辑`/etc/neutron/neutron.conf`文件并完成以下操作：

  - 在`[database]`部分中，配置数据库访问：

    ```bash
    [database]
    # ...
    connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
    ```

    替换`NEUTRON_DBPASS`为您为数据库选择的密码。

    注释掉或删除`connection`该部分中的任何其他选项 `[database]`。

  - 在该`[DEFAULT]`部分中，启用模块化第 2 层 (ML2) 插件、路由器服务和重叠 IP 地址：

    ```bash
    [DEFAULT]
    # ...
    core_plugin = ml2
    service_plugins = router
    allow_overlapping_ips = true
    ```

  - 在`[DEFAULT]`部分中，配置`RabbitMQ` 消息队列访问：

    ```bash
    [DEFAULT]
    # ...
    transport_url = rabbit://openstack:RABBIT_PASS@controller
    ```

    替换`RABBIT_PASS`为您为 RabbitMQ 中的帐户选择的密码 `openstack`。

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
    username = neutron
    password = NEUTRON_PASS
    ```

    替换为您 在身份服务中`NEUTRON_PASS`为用户选择的密码。`neutron`

    注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

  - 在`[DEFAULT]`和`[nova]`部分中，配置 Networking 以通知 Compute 网络拓扑更改：

    ```bash
    [DEFAULT]
    # ...
    notify_nova_on_port_status_changes = true
    notify_nova_on_port_data_changes = true
    
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
    ```

    替换为您 在身份服务中`NOVA_PASS`为用户选择的密码。`nova`

- 在`[oslo_concurrency]`部分中，配置锁定路径：

  ```bash
  [oslo_concurrency]
  # ...
  lock_path = /var/lib/neutron/tmp
  ```



配置模块化第 2 层（ML2）插件

ML2 插件使用 Linux 桥接机制为实例构建第 2 层（桥接和交换）虚拟网络基础设施。

- 编辑`/etc/neutron/plugins/ml2/ml2_conf.ini`文件并完成以下操作：

  - 在该`[ml2]`部分中，启用平面、VLAN 和 VXLAN 网络：

    ```bash
    [ml2]
    # ...
    type_drivers = flat,vlan,vxlan
    ```

  - 在`[ml2]`部分中，启用 VXLAN 自助服务网络：

    ```bash
    [ml2]
    # ...
    tenant_network_types = vxlan
    ```

  - 在该`[ml2]`部分中，启用 Linux 网桥和第 2 层填充机制：

    ```bash
    [ml2]
    # ...
    mechanism_drivers = linuxbridge,l2population
    ```

    配置 ML2 插件后，删除选项中的值 `type_drivers`会导致数据库不一致。

    Linux 网桥代理仅支持 VXLAN 覆盖网络。

  - 在该`[ml2]`部分中，启用端口安全扩展驱动程序：

    ```bash
    [ml2]
    # ...
    extension_drivers = port_security
    ```

  - 在`[ml2_type_flat]`部分中，将提供者虚拟网络配置为平面网络：

    ```bash
    [ml2_type_flat]
    # ...
    flat_networks = provider
    ```

  - 在该`[ml2_type_vxlan]`部分中，为自助服务网络配置 VXLAN 网络标识符范围：

    ```bash
    [ml2_type_vxlan]
    # ...
    vni_ranges = 1:1000
    ```

  - 在该`[securitygroup]`部分中，启用 ipset 以提高安全组规则的效率：

    ```bash
    [securitygroup]
    # ...
    enable_ipset = true
    ```

    

配置Linux网桥代理

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

- 编辑`/etc/neutron/plugins/ml2/linuxbridge_agent.ini`文件并完成以下操作：

  - 在`[linux_bridge]`部分中，将提供商虚拟网络映射到提供商物理网络接口：

    ```bash
    [linux_bridge]
    physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
    ```

    替换`PROVIDER_INTERFACE_NAME`为底层提供者物理网络接口的名称。 有关详细信息，请参阅[主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在该`[vxlan]`部分中，启用 VXLAN 覆盖网络，配置处理覆盖网络的物理网络接口的 IP 地址，并启用第 2 层填充：

    ```bash
    [vxlan]
    enable_vxlan = true
    local_ip = OVERLAY_INTERFACE_IP_ADDRESS
    l2_population = true
    ```

    替换`OVERLAY_INTERFACE_IP_ADDRESS`为处理覆盖网络的底层物理网络接口的 IP 地址。示例架构使用管理接口将流量隧道传输到其他节点。因此，请替换`OVERLAY_INTERFACE_IP_ADDRESS`为控制器节点的管理 IP 地址。有关详细信息，请参阅 [主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在该`[securitygroup]`部分中，启用安全组并配置 Linux bridge iptables 防火墙驱动程序：

    ```bash
    [securitygroup]
    # ...
    enable_security_group = true
    firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    ```

  - `sysctl`通过验证以下所有值都设置为，确保您的 Linux 操作系统内核支持网桥过滤器`1`：

    ```bash
    net.bridge.bridge-nf-call-iptables
    net.bridge.bridge-nf-call-ip6tables
    ```

    要启用网桥支持，通常`br_netfilter`需要加载内核模块。查看您的操作系统文档以获取有关启用此模块的更多详细信息。





配置三层代理

第 3 层 (L3) 代理为自助虚拟网络提供路由和 NAT 服务。

- 编辑`/etc/neutron/l3_agent.ini`文件并完成以下操作：

  - 在`[DEFAULT]`部分中，配置 Linux 桥接接口驱动程序：

    ```bash
    [DEFAULT]
    # ...
    interface_driver = linuxbridge
    ```



配置DHCP代理

DHCP 代理为虚拟网络提供 DHCP 服务。

- 编辑`/etc/neutron/dhcp_agent.ini`文件并完成以下操作：

  - 在该`[DEFAULT]`部分中，配置 Linux 桥接接口驱动程序、Dnsmasq DHCP 驱动程序并启用隔离元数据，以便提供商网络上的实例可以通过网络访问元数据：

    ```bash
    [DEFAULT]
    # ...
    interface_driver = linuxbridge
    dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
    enable_isolated_metadata = true
    ```



返回*网络控制器节点配置*。



### 安装和配置计算节点

计算节点处理实例的连接和安全组。

安装组件

```bash
# apt install neutron-linuxbridge-agent

```

配置公共组件

Networking公共组件配置包括认证机制、消息队列和插件。

默认配置文件因发行版而异。您可能需要添加这些部分和选项，而不是修改现有部分和选项。`...`此外，配置片段中的省略号 ( ) 表示您应该保留的潜在默认配置选项。

- 编辑`/etc/neutron/neutron.conf`文件并完成以下操作：

  - 在该`[database]`部分中，注释掉任何`connection`选项，因为计算节点不直接访问数据库。

  - 在`[DEFAULT]`部分中，配置`RabbitMQ` 消息队列访问：

    ```bash
    [DEFAULT]
    # ...
    transport_url = rabbit://openstack:RABBIT_PASS@controller
    ```

    替换`RABBIT_PASS`为您为 RabbitMQ 中的帐户选择的密码`openstack` 。

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
    username = neutron
    password = NEUTRON_PASS
    ```

    替换为您 在身份服务中`NEUTRON_PASS`为用户选择的密码。`neutron`

    注释掉或删除该 `[keystone_authtoken]`部分中的任何其他选项。

- 在`[oslo_concurrency]`部分中，配置锁定路径：

  ```bash
  [oslo_concurrency]
  # ...
  lock_path = /var/lib/neutron/tmp
  ```



配置网络选项

选择您为控制器节点选择的相同网络选项以配置特定于它的服务。之后，返回此处并继续 [配置计算服务以使用网络服务](https://docs.openstack.org/neutron/yoga/install/compute-install-ubuntu.html#neutron-compute-compute-ubuntu)。

- [网络选项 1：供应商网络](https://docs.openstack.org/neutron/yoga/install/compute-install-option1-ubuntu.html)
- [网络选项 2：自助服务网络](https://docs.openstack.org/neutron/yoga/install/compute-install-option2-ubuntu.html)



配置计算服务以使用网络服务

- 编辑`/etc/nova/nova.conf`文件并完成以下操作：

  - 在`[neutron]`部分中，配置访问参数：

    ```bash
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

    替换为您 在身份服务中`NEUTRON_PASS`为用户选择的密码。`neutron`

    请参阅[计算服务配置指南](https://docs.openstack.org/nova/yoga/configuration/config.html#neutron) 以获取完整的选项集，包括在必要时覆盖服务目录端点 URL。



完成安装

1. 重新启动计算服务：

   ```bash
   # service nova-compute restart
   
   ```

2. 重启 Linux 网桥代理：

   ```bash
   # service neutron-linuxbridge-agent restart
   
   ```

   

#### 网络选项 1：供应商网络

*在计算*节点上配置网络组件。



配置 Linux 网桥代理

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

- 编辑`/etc/neutron/plugins/ml2/linuxbridge_agent.ini`文件并完成以下操作：

  - 在`[linux_bridge]`部分中，将提供商虚拟网络映射到提供商物理网络接口：

    ```bash
    [linux_bridge]
    physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
    ```

    替换`PROVIDER_INTERFACE_NAME`为底层提供者物理网络接口的名称。 有关详细信息，请参阅[主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在`[vxlan]`部分中，禁用 VXLAN 覆盖网络：

    ```bash
    [vxlan]
    enable_vxlan = false
    ```

  - 在该`[securitygroup]`部分中，启用安全组并配置 Linux bridge iptables 防火墙驱动程序：

    ```bash
    [securitygroup]
    # ...
    enable_security_group = true
    firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    ```

  - `sysctl`通过验证以下所有值都设置为，确保您的 Linux 操作系统内核支持网桥过滤器`1`：

    ```bash
    net.bridge.bridge-nf-call-iptables
    net.bridge.bridge-nf-call-ip6tables
    ```

    要启用网桥支持，通常`br_netfilter`需要加载内核模块。查看您的操作系统文档以获取有关启用此模块的更多详细信息。

    

返回网络计算节点配置



#### 网络选项 2：自助服务网络

*在计算*节点上配置网络组件。

配置Linux网桥代理

Linux 网桥代理为实例构建第 2 层（桥接和交换）虚拟网络基础设施并处理安全组。

- 编辑`/etc/neutron/plugins/ml2/linuxbridge_agent.ini`文件并完成以下操作：

  - 在`[linux_bridge]`部分中，将提供商虚拟网络映射到提供商物理网络接口：

    ```bash
    [linux_bridge]
    physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME
    ```

    替换`PROVIDER_INTERFACE_NAME`为底层提供者物理网络接口的名称。 有关详细信息，请参阅[主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在该`[vxlan]`部分中，启用 VXLAN 覆盖网络，配置处理覆盖网络的物理网络接口的 IP 地址，并启用第 2 层填充：

    ```bash
    [vxlan]
    enable_vxlan = true
    local_ip = OVERLAY_INTERFACE_IP_ADDRESS
    l2_population = true
    ```

    替换`OVERLAY_INTERFACE_IP_ADDRESS`为处理覆盖网络的底层物理网络接口的 IP 地址。示例架构使用管理接口将流量隧道传输到其他节点。因此，替换`OVERLAY_INTERFACE_IP_ADDRESS`为计算节点的管理IP地址。有关详细信息，请参阅 [主机网络。](https://docs.openstack.org/neutron/yoga/install/environment-networking-ubuntu.html)

  - 在该`[securitygroup]`部分中，启用安全组并配置 Linux bridge iptables 防火墙驱动程序：

    ```bash
    [securitygroup]
    # ...
    enable_security_group = true
    firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    ```

  - `sysctl`通过验证以下所有值都设置为，确保您的 Linux 操作系统内核支持网桥过滤器`1`：

    ```bash
    net.bridge.bridge-nf-call-iptables
    net.bridge.bridge-nf-call-ip6tables
    ```

    要启用网桥支持，通常`br_netfilter`需要加载内核模块。查看您的操作系统文档以获取有关启用此模块的更多详细信息。



返回网络计算节点配置。

### OVN 安装文档

https://docs.openstack.org/neutron/yoga/install/ovn/manual_install.html

https://docs.openstack.org/neutron/yoga/install/ovn/tripleo_install.html



### 验证操作

在控制器节点上执行这些命令。

1. 获取`admin`凭据以访问仅限管理员的 CLI 命令：

   ```bash
   $ . admin-openrc
   
   ```

2. 列出加载的扩展以验证进程是否成功启动 `neutron-server`：

   ```bash
   $ openstack extension list --network
   
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

   1. 实际输出可能与此示例略有不同。

您可以使用 [neutron-sanity-check 命令行客户端](https://docs.openstack.org/cli-reference/neutron-sanity-check.html)对您的网络进行进一步测试。

使用您选择部署的网络选项的验证部分。

#### 网络选项 1：供应商网络

- 列出代理以验证中子代理是否成功启动：

  ```bash
  $ openstack network agent list
  
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  | ID                                   | Agent Type         | Host       | Availability Zone | Alive | State | Binary                    |
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  | 0400c2f6-4d3b-44bc-89fa-99093432f3bf | Metadata agent     | controller | None              | True  | UP    | neutron-metadata-agent    |
  | 83cf853d-a2f2-450a-99d7-e9c6fc08f4c3 | DHCP agent         | controller | nova              | True  | UP    | neutron-dhcp-agent        |
  | ec302e51-6101-43cf-9f19-88a78613cbee | Linux bridge agent | compute    | None              | True  | UP    | neutron-linuxbridge-agent |
  | fcb9bc6e-22b1-43bc-9054-272dd517d025 | Linux bridge agent | controller | None              | True  | UP    | neutron-linuxbridge-agent |
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  ```

  输出应指示控制器节点上的三个代理和每个计算节点上的一个代理。

#### 网络选项 2：自助服务网络

- 列出代理以验证中子代理是否成功启动：

  ```bash
  $ openstack network agent list
  
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  | ID                                   | Agent Type         | Host       | Availability Zone | Alive | State | Binary                    |
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  | f49a4b81-afd6-4b3d-b923-66c8f0517099 | Metadata agent     | controller | None              | True  | UP    | neutron-metadata-agent    |
  | 27eee952-a748-467b-bf71-941e89846a92 | Linux bridge agent | controller | None              | True  | UP    | neutron-linuxbridge-agent |
  | 08905043-5010-4b87-bba5-aedb1956e27a | Linux bridge agent | compute1   | None              | True  | UP    | neutron-linuxbridge-agent |
  | 830344ff-dc36-4956-84f4-067af667a0dc | L3 agent           | controller | nova              | True  | UP    | neutron-l3-agent          |
  | dd3644c9-1a3a-435a-9282-eb306b4b0391 | DHCP agent         | controller | nova              | True  | UP    | neutron-dhcp-agent        |
  +--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
  ```

  输出应指示控制器节点上的四个代理和每个计算节点上的一个代理。



## Dashboard 安装教程

仪表板所需的唯一核心服务是身份服务。您可以将仪表板与其他服务结合使用，例如图像服务、计算和网络。您还可以在具有对象存储等独立服务的环境中使用仪表板。

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



安装和配置组件

默认配置文件因发行版而异。您可能需要添加这些部分和选项，而不是修改现有部分和选项。`...`此外，配置片段中的省略号 ( ) 表示您应该保留的潜在默认配置选项。

1. 安装软件包：

   ```bash
   # apt install openstack-dashboard
   
   ```

2. 编辑 `/etc/openstack-dashboard/local_settings.py` 文件并完成以下操作：

   - 配置仪表板以在 `controller`节点上使用 OpenStack 服务：

     ```bash
     OPENSTACK_HOST = "controller"
     
     ```

   - 在仪表板配置部分，允许您的主机访问仪表板：

     ```bash
     ALLOWED_HOSTS = ['one.example.com', 'two.example.com']
     
     ```

     - 不要编辑`ALLOWED_HOSTS`Ubuntu 配置部分下的参数。
     - `ALLOWED_HOSTS`也可以`['*']`接受所有主机。这可能对开发工作有用，但可能不安全，不应在生产中使用。 有关详细信息，请参阅 [Django 文档。](https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts)

   - 配置`memcached`会话存储服务：

     ```bash
     SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
     
     CACHES = {
         'default': {
              'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
              'LOCATION': 'controller:11211',
         }
     }
     ```

     注释掉任何其他会话存储配置。

   - 启用身份 API 版本 3：

     ```bash
     OPENSTACK_KEYSTONE_URL = "http://%s/identity/v3" % OPENSTACK_HOST
     
     ```

     如果你的 keystone 在 5000 端口运行，那么你也会在这里提到 keystone 端口，即 OPENSTACK_KEYSTONE_URL = “ http://%s:5000/identity/v3 ” % OPENSTACK_HOST

   - 启用对域的支持：

     ```bash
     OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
     
     ```

   - 配置 API 版本：

     ```bash
     OPENSTACK_API_VERSIONS = {
         "identity": 3,
         "image": 2,
         "volume": 3,
     }
     ```

   - 将`Default`您通过仪表板创建的用户配置为默认域：

     ```bash
     OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
     
     ```

   - 配置`user`为您通过仪表板创建的用户的默认角色：

     ```bash
     OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
     
     ```

   - 如果您选择网络选项 1，请禁用对第 3 层网络服务的支持：

     ```bash
     OPENSTACK_NEUTRON_NETWORK = {
         ...
         'enable_router': False,
         'enable_quotas': False,
         'enable_ipv6': False,
         'enable_distributed_router': False,
         'enable_ha_router': False,
         'enable_fip_topology_check': False,
     }
     ```

   - 或者，配置时区：

     ```bash
     TIME_ZONE = "TIME_ZONE"
     
     ```

     替换`TIME_ZONE`为适当的时区标识符。有关详细信息，请参阅[时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)。

3. `/etc/apache2/conf-available/openstack-dashboard.conf`如果不包括，请添加以下行 。

   ```bash
   WSGIApplicationGroup %{GLOBAL}
   
   ```

   

完成安装

- 重新加载 Web 服务器配置：

  ```bash
  # systemctl reload apache2.service
  
  ```

  

### 验证操作

验证仪表板的操作。

使用 Web 浏览器访问仪表板，网址为 `http://controller/horizon`。

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

## cinder 安装教程

### 安装指南

块存储服务（cinder）为来宾实例提供块存储设备。提供和使用存储的方法由块存储驱动程序确定，或者在多后端配置的情况下由驱动程序确定。有多种可用的驱动程序：NAS/SAN、NFS、iSCSI、Ceph 等。

Block Storage API 和调度程序服务通常在控制器节点上运行。根据使用的驱动程序，卷服务可以在控制器节点、计算节点或独立存储节点上运行。

有关详细信息，请参阅[配置参考](https://docs.openstack.org/cinder/yoga/configuration/block-storage/volume-drivers.html)。



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

   







