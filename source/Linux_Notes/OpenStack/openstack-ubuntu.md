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







## placement 安装教程









## nova 安装教程









## neutron 安装教程





## Dashboard 安装教程





## cinder 安装教程