# Ubuntu 20.04 部署 OpenStack Yoga 版本

## Ubuntu 20.04 系统配置静态IP地址

```bash
# 备份配置
sudo cp -a /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak

# 修改配置
sudo vim /etc/netplan/00-installer-config.yaml
#################
network:
  ethernets:
    eno1:
      dhcp4: true
    eno2:
      dhcp4: true
    eno33:
      dhcp4: false
      addresses: 
        - 192.168.71.57/21
      gateway4: 192.168.64.1
      nameservers:
        addresses: [123.123.123.123, 114.114.114.114]
    eno34:
      dhcp4: true
  version: 2
#################

# eno1, eno2, eno33np0, eno34np1 为网络设备名称

# 应用配置文件
sudo netplan apply

```

## Ubuntu 20.04 系统配置 DNS

```bash
# 修改配置
sudo vim /etc/systemd/resolved.conf
################
[Resolve]
DNS=123.123.123.123 114.114.114.114
#FallbackDNS=
#Domains=
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#DNSOverTLS=no
#Cache=no-negative
#DNSStubListener=yes
#ReadEtcHosts=yes
################

# 重启服务
systemctl restart systemd-resolved
systemctl enable systemd-resolved

```

## 控制节点依赖服务部署

### 配置网络接口

官方链接：https://docs.openstack.org/install-guide/environment-networking-controller.html

```bash
# 编辑文件，替换 eno33 为实际网络接口名称
vim /etc/network/interfaces
################
auto eno33
iface eno33 inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
################

vim /etc/hosts
################
127.0.0.1 localhost
127.0.0.1 r7525-4

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

192.168.71.57  controller
################
```

### 网络时间协议(NTP)

官方链接：https://docs.openstack.org/install-guide/environment-ntp-controller.html

```bash
# 安装软件
apt install chrony

# 编辑配置，保持默认配置即可
vim /etc/chrony/chrony.conf

# 启动服务
service chrony restart
```

### 配置适用的软件包

```bash
# 适用于 Ubuntu 20.04 LTS 的 OpenStack Yoga：
add-apt-repository cloud-archive:yoga

# 安装示例
apt install nova-compute

# 客户端安装
apt install python3-openstackclient

```

### 配置 SQL 数据库

官方链接：https://docs.openstack.org/install-guide/environment-sql-database-ubuntu.html

```bash
# 安装软件包
apt install mariadb-server python3-pymysql

# 创建并编辑文件
vim /etc/mysql/mariadb.conf.d/99-openstack.cnf
#####################
[mysqld]
bind-address = 192.168.71.57

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
#####################

# 重启服务
service mysql restart

# 运行 mysql_secure_installation 命令确保数据库服务安全。特别是，为数据库root帐户选择合适的密码:
mysql_secure_installation

```

### 配置消息队列

官方链接：https://docs.openstack.org/install-guide/environment-messaging-ubuntu.html

```bash
# 安装软件包
apt install rabbitmq-server

# 添加用户 openstack
rabbitmqctl add_user openstack RABBIT_PASS

# 配置用户权限
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

```

### 配置内存缓存服务

官方链接：https://docs.openstack.org/install-guide/environment-memcached-ubuntu.html

```bash
# 安装
apt install memcached python3-memcache

# 修改/etc/memcache .conf文件，配置为使用控制节点的管理IP地址。这是为了允许其他节点通过管理网络访问:
vim /etc/memcached.conf
#####################
...
-l 192.168.71.57
...
#####################

# 重启服务
service memcached restart

```

### 配置 Etcd 服务

官方链接：https://docs.openstack.org/install-guide/environment-etcd-ubuntu.html

```bash
# 安装
apt install etcd

# 编辑/etc/default/etcd文件，将ETCD_INITIAL_CLUSTER、ETCD_INITIAL_ADVERTISE_PEER_URLS、ETCD_ADVERTISE_CLIENT_URLS、ETCD_LISTEN_CLIENT_URLS设置为控制节点的管理IP地址，使其他节点可以通过管理网络访问。
vim /etc/default/etcd
#####################
ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://192.168.71.57:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.71.57:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.71.57:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.71.57:2379"
#####################

# 启用和重启服务
systemctl enable etcd
systemctl restart etcd

```

### 部署身份服务 Keystone

官方链接：https://docs.openstack.org/keystone/yoga/install/index-ubuntu.html

#### 配置数据库

```bash
# 使用 root 用户登陆 MySQL
mysql

# 创建keystone数据库
MariaDB [(none)]> CREATE DATABASE keystone;

# 授予对keystone数据库的访问权限
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';

# 退出登录
MariaDB [(none)]> exit

```

#### 安装和配置组件

```bash
# 安装
apt install keystone

# 修改配置
vim /etc/keystone/keystone.conf
#####################
[DEFAULT]
log_dir = /var/log/keystone
[application_credential]
[assignment]
[auth]
[cache]
[catalog]
[cors]
[credential]
[database]
# 修改 connection
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[extra_headers]
Distribution = Ubuntu
[federation]
[fernet_receipts]
[fernet_tokens]
[healthcheck]
[identity]
[identity_mapping]
[jwt_tokens]
[ldap]
[memcache]
[oauth1]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[policy]
[profiler]
[receipt]
[resource]
[revoke]
[role]
[saml]
[security_compliance]
[shadow_users]
[token]
# 添加 provider
provider = fernet
[tokenless_auth]
[totp]
[trust]
[unified_limit]
[wsgi]
#####################

# 填充Identity服务数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 初始化Fernet密钥库
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# 引导Identity服务
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
```

#### 配置Apache HTTP服务器

```bash
# 编辑/etc/apache2/apache2.conf文件，配置ServerName选项以引用控制节点，如果不存在，则需要添加ServerName条目。
vim /etc/apache2/apache2.conf
#####################
...
ServerName controller
...
#####################

# 重启服务
service apache2 restart

# 通过设置适当的环境变量来配置管理帐户
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

```

#### 创建域、项目、用户和角色

```bash
# 虽然“默认”域已经在本指南的keystone-manage引导步骤中存在，但创建新域的正式方法是
openstack domain create --description "An Example Domain" example

# 本指南使用一个服务项目，该项目为您添加到环境中的每个服务都包含一个唯一的用户。
# 创建 service 项目
openstack project create --domain default \
  --description "Service Project" service

# 常规(非管理)任务应该使用非特权项目和用户。
# 作为一个例子，本指南创建了myproject项目和myuser用户。
# 为此项目创建其他用户时，请勿重复此步骤。

## 创建myproject项目
openstack project create --domain default \
  --description "Demo Project" myproject

## 创建myuser用户，密码设置为：myuser
openstack user create --domain default \
  --password-prompt myuser

## 创建myrole角色
openstack role create myrole

## 在myproject项目和myuser用户中添加myrole角色
openstack role add --project myproject --user myuser myrole

## 您可以重复此过程来创建其他项目和用户。

```

#### 验证

```bash
# 取消临时环境变量OS_AUTH_URL和OS_PASSWORD的设置
unset OS_AUTH_URL OS_PASSWORD

# 作为admin用户，请求一个身份验证令牌，使用admin用户的密码
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue

# 作为前面创建的myuser用户，请求一个身份验证令牌，使用myuser用户的密码
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name myproject --os-username myuser token issue

```

#### 创建客户端环境脚本

```bash
# 建议创建在 root 家目录
vim admin-openrc
#####################
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
#####################

vim demo-openrc
#####################
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=myuser
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
#####################

# 使用脚本
. admin-openrc

# 请求身份验证令牌
openstack token issue

```

### 部署图像服务 Glance

官方链接：https://docs.openstack.org/glance/yoga/install/install-ubuntu.html

#### 配置数据库

```bash
# 使用 root 登录
mysql

# 创建glance数据库
MariaDB [(none)]> CREATE DATABASE glance;

# 授予对glance数据库的访问权限
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';

# 退出
MariaDB [(none)]> exit
```

#### 创建服务凭证

```bash
. admin-openrc

# 创建glance用户，设置密码为：GLANCE_PASS
openstack user create --domain default --password-prompt glance

# 在glance用户和业务群组中添加admin角色
openstack role add --project service --user glance admin

# 创建glance服务实体
openstack service create --name glance \
  --description "OpenStack Image" image

# 创建图像服务API端点
openstack endpoint create --region RegionOne \
  image public http://controller:9292

openstack endpoint create --region RegionOne \
  image internal http://controller:9292

openstack endpoint create --region RegionOne \
  image admin http://controller:9292


# 注册配额限制（可选）可以不进行配置，部署完成后在 web 页面也可以修改限额配置
# 一定要在glance-api.conf文件中设置 use_keystone_quota =True

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 1000 --region RegionOne image_size_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 1000 --region RegionOne image_stage_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 100 --region RegionOne image_count_total

openstack --os-cloud devstack-system-admin registered limit create \
  --service glance --default-limit 100 --region RegionOne image_count_uploading

```

#### 安装和配置组件

```bash
# 安装
apt install glance

# 修改配置
vim /etc/glance/glance-api.conf
#####################
[DEFAULT]
# use_keystone_quotas = True
[barbican]
[barbican_service_user]
[cinder]
[cors]
[database]
# 修改 connection
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
[file]
[glance.store.http.store]
[glance.store.rbd.store]
[glance.store.s3.store]
[glance.store.swift.store]
[glance.store.vmware_datastore.store]
[glance_store]
# 添加配置
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
[healthcheck]
[image_format]
disk_formats = ami,ari,aki,vhd,vhdx,vmdk,raw,qcow2,vdi,iso,ploop.root-tar
[key_manager]
[keystone_authtoken]
# 添加配置
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[paste_deploy]
# 添加配置
flavor = keystone
[profiler]
[store_type_location_strategy]
[task]
[taskflow_executor]
[vault]
[wsgi]
#####################


# 填充Image服务数据库
su -s /bin/sh -c "glance-manage db_sync" glance

# 重启服务
service glance-api restart

```

#### 验证

```bash
. admin-openrc

# 下载cirros源镜像
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

# 下载 Ubuntu 20.04 镜像
wget https://cloud-images.ubuntu.com/focal/20231124/focal-server-cloudimg-amd64-disk-kvm.img

# 使用QCOW2磁盘格式、裸容器格式和公共可见性将映像上传到image服务
glance image-create --name "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --visibility=public

# 上传 Ubuntu 镜像
glance image-create --name "Ubuntu 20.04" \
  --file focal-server-cloudimg-amd64-disk-kvm.img \
  --disk-format qcow2 --container-format bare \
  --visibility=public

# 确认图像的上传并验证属性
glance image-list

```

### 部署服务 Placement

官方链接：https://docs.openstack.org/placement/yoga/install/install-ubuntu.html

#### 配置数据库

```bash
# 使用 root 登录
mysql

# 创建placement数据库
MariaDB [(none)]> CREATE DATABASE placement;

# 授予对glance数据库的访问权限
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';

# 退出
MariaDB [(none)]> exit
```

#### 配置用户和端点

```bash
. admin-openrc

# 使用您选择的 PLACEMENT_PASS 创建一个放置服务用户
openstack user create --domain default --password-prompt placement

# 将Placement用户添加到具有admin角色的服务项目
openstack role add --project service --user placement admin

# 在服务目录中创建Placement API条目
openstack service create --name placement \
  --description "Placement API" placement

# 创建Placement API服务端点
openstack endpoint create --region RegionOne \
  placement public http://controller:8778

openstack endpoint create --region RegionOne \
  placement internal http://controller:8778

openstack endpoint create --region RegionOne \
  placement admin http://controller:8778

```

#### 安装和配置组件

```bash
# 安装软件包
apt install placement-api

# 修改配置
vim /etc/placement/placement.conf
#####################
[DEFAULT]
[api]
# 添加配置
auth_strategy = keystone
[cors]
[keystone_authtoken]
# 添加配置
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_PASS

[oslo_middleware]
[oslo_policy]
[placement]
[placement_database]
# 修改 connection
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
[profiler]
#####################

# 填充placement数据库
su -s /bin/sh -c "placement-manage db sync" placement

# 重新加载 Web 服务器进行调整以获得新的放置配置设置。
service apache2 restart

```

#### 验证

```bash
. admin-openrc

# 执行状态检查以确保一切正常
placement-status upgrade check

```

### 部署计算服务 Nova （控制节点和计算节点）

#### 配置数据库

```bash
# 使用 root 登录
mysql

# 创建nova_api、nova和nova_cell0数据库
MariaDB [(none)]> CREATE DATABASE nova_api;
MariaDB [(none)]> CREATE DATABASE nova;
MariaDB [(none)]> CREATE DATABASE nova_cell0;

# 授予对数据库的适当访问权限
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

# 退出
MariaDB [(none)]> exit
```

#### 创建计算服务凭证

```bash
. admin-openrc

# 创建nova用户，密码：NOVA_PASS
openstack user create --domain default --password-prompt nova

# 为nova用户添加admin角色
openstack role add --project service --user nova admin

# 创建nova服务实体
openstack service create --name nova \
  --description "OpenStack Compute" compute


# 创建计算 API 服务端点
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1

```

#### 安装和配置组件

```bash
# 安装软件包
apt install nova-api nova-conductor nova-novncproxy nova-scheduler nova-compute

# 修改配置
vim /etc/nova/nova.conf
#####################
[DEFAULT]
lock_path = /var/lock/nova
state_path = /opt/nova

transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/
my_ip = 192.168.71.57

allow_resize_to_same_host = true
scheduler_default_filters=RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter

[api]
# 添加配置
auth_strategy = keystone

[api_database]
# 修改 connection 配置
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
# 修改 connection 配置
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova

[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
# 添加配置
api_servers = http://controller:9292

[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
# 添加配置
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[libvirt]
[metrics]
[mks]
[neutron]
# 添加配置
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

[notifications]
[oslo_concurrency]
# 添加配置
lock_path = /var/lib/nova/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
# 添加配置
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS

[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
# 添加配置
send_service_user_token = true
auth_url = http://controller:5000/identity
auth_strategy = keystone
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = NOVA_PASS

[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
# 添加配置
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[workarounds]
[wsgi]
[zvm]
[cells]
enable = False
[os_region_name]
openstack = 
#####################

# 填充nova-api数据库
su -s /bin/sh -c "nova-manage api_db sync" nova

# 注册cell0数据库
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

# 创建cell1单元格
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

# 填充 nova 数据库
su -s /bin/sh -c "nova-manage db sync" nova

# 验证 nova cell0 和 cell1 是否已正确注册
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

# 重新启动计算服务
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart

```

#### 将计算节点添加到单元格数据库中

```bash
. admin-openrc

# 获取admin凭据以启用admin-only CLI命令，然后确认数据库中存在计算主机
openstack compute service list --service nova-compute

# 发现计算主机
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

# 添加新计算节点时，必须在控制节点上执行nova-manage cell_v2 discover_hosts命令注册新计算节点。您也可以在/etc/nova/nova.conf中设置一个合适的时间间隔。
[scheduler]
discover_hosts_in_cells_interval = 300

```

#### 验证

```bash
. admin-openrc

# 列出服务组件以验证每个进程的成功启动和注册
openstack compute service list

# 列出身份服务中的 API 端点以验证与身份服务的连接
openstack catalog list

# 列出图像服务中的图像以验证与图像服务的连接
openstack image list

# 检查单元和放置API是否工作成功，以及其他必要的先决条件是否到位
nova-status upgrade check

```

### 部署网络服务 Neutron（控制节点）

#### 配置数据库

```bash
# 使用 root 登录
mysql

# 创建neutron数据库
MariaDB [(none)] CREATE DATABASE neutron;

# 授予对neutron数据库的适当访问权限，用合适的密码替换NEUTRON_DBPASS
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';

# 退出
MariaDB [(none)]> exit
```

#### 创建服务凭证

```bash
. admin-openrc

# 创建neutron用户，密码：NEUTRON_PASS
openstack user create --domain default --password-prompt neutron

# 为neutron用户添加admin角色
openstack role add --project service --user neutron admin

# 创建neutron服务实体
openstack service create --name neutron \
  --description "OpenStack Networking" network

# 创建网络服务 API 端点
openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696

```

#### 配置网络选项 1：提供商网络

```bash
# 安装组件
apt install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-dhcp-agent \
  neutron-metadata-agent

# 配置服务器组件
vim /etc/neutron/neutron.conf
#########################
[DEFAULT]
# 修改配置
core_plugin = ml2
service_plugins =
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[agent]
root_helper = "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"
[cache]
[cors]
[database]
# 修改配置
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron

[healthcheck]
[ironic]
[keystone_authtoken]
# 修改配置
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
# 修改配置
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS

[oslo_concurrency]
# 修改配置
lock_path = /var/lib/neutron/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[placement]
[privsep]
[profiler]
[quotas]
[ssl]
#########################
```

配置模块化第 2 层 (ML2) 插件

```bash
vim /etc/neutron/plugins/ml2/ml2_conf.ini
#########################
DEFAULT]
[ml2]
# 修改配置
type_drivers = flat,vlan
tenant_network_types =
mechanism_drivers = linuxbridge
extension_drivers = port_security

[ml2_type_flat]
# 修改配置
flat_networks = provider

[ml2_type_geneve]
[ml2_type_gre]
[ml2_type_vlan]
[ml2_type_vxlan]
[ovs_driver]
[securitygroup]
enable_ipset = true
[sriov_driver]
#########################
```

配置 Linux 桥接代理

```bash
vim /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#########################
[DEFAULT]
[agent]
[linux_bridge]
# 修改 eno33 网络接口名称
physical_interface_mappings = provider:eno33

[network_log]
[securitygroup]
# 修改配置
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

[vxlan]
# 修改配置
enable_vxlan = false
#########################

# 通过验证以下所有sysctl值都设置为1，确保Linux操作系统内核支持网桥过滤器
sysctl -a | grep net.bridge.bridge-nf-call-iptables
sysctl -a | grep net.bridge.bridge-nf-call-ip6tables

```

配置 DHCP 代理

```bash
vim /etc/neutron/dhcp_agent.ini
#########################
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
[agent]
[ovs]
#########################

```

#### 创建提供商网络

```bash
. admin-openrc

# 创建网络
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider

# --share: 选项允许所有项目使用虚拟网络。
# --external: 选项将虚拟网络定义为外部网络。如果您希望创建一个内部网络，您可以使用 --internal 代替。默认值是internal。
# --provider-physical-network provider 和 --provider-network-type flat 选项使用以下文件中的信息将平面虚拟网络连接到主机eth1接口上的平面(本机/无标签)物理网络。


vim /etc/neutron/plugins/ml2/ml2_conf.ini
#########################
[DEFAULT]
[ml2]
type_drivers = flat,vlan
tenant_network_types =
mechanism_drivers = linuxbridge
extension_drivers = port_security
[ml2_type_flat]
# 修改配置
flat_networks = provider

[ml2_type_geneve]
[ml2_type_gre]
[ml2_type_vlan]
[ml2_type_vxlan]
[ovs_driver]
[securitygroup]
enable_ipset = true
[sriov_driver]
#########################


vim /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#########################
[DEFAULT]
[agent]
[linux_bridge]
# 修改 eno33 网络接口名称
physical_interface_mappings = provider:eno33

[network_log]
[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
[vxlan]
enable_vxlan = false
#########################

# 在网络中创建子网，请参考下面例子
openstack subnet create --network provider \
  --allocation-pool start=START_IP_ADDRESS,end=END_IP_ADDRESS \
  --dns-nameserver DNS_RESOLVER --gateway PROVIDER_NETWORK_GATEWAY \
  --subnet-range PROVIDER_NETWORK_CIDR provider
# 将 PROVIDER_NETWORK_CIDR 替换为提供商物理网络中的子网(CIDR表示法)。
# 将START_IP_ADDRESS和END_IP_ADDRESS替换为要为实例分配的子网范围内的第一个和最后一个IP地址。此范围不能包括任何现有的活动IP地址。
# 将DNS_RESOLVER替换为DNS解析器的IP地址。在大多数情况下，您可以使用主机上的/etc/resolv.conf文件中的一个。
# 将PROVIDER_NETWORK_GATEWAY替换为提供程序网络上的网关IP地址，通常是“。1”IP地址。

# 例子：
openstack subnet create --network provider \
  --allocation-pool start=192.168.65.5,end=192.168.70.250 \
  --dns-nameserver 114.114.114.114 --gateway 192.168.64.1 \
  --subnet-range 192.168.64.1/21 provider

```

#### 配置元数据代理

```bash
vim /etc/neutron/metadata_agent.ini
#########################
[DEFAULT]
# 修改配置，替换METADATA_SECRET为元数据代理的合适密钥。
nova_metadata_host = controller
metadata_proxy_shared_secret = METADATA_SECRET

[agent]
[cache]
#########################
```

#### 配置计算服务以使用网络服务

必须安装 Nova 计算服务才能完成此步骤。

```bash
vim /etc/nova/nova.conf
#########################
...
[neutron]
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
#########################
```

#### 完成安装

```bash
# 填充数据库
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# 重启计算API服务
service nova-api restart

# 重新启动网络服务
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

```

#### 验证

```bash
. admin-openrc

# 列出加载的扩展以验证进程是否成功启动 neutron-server
openstack extension list --network

# 列出代理以验证中子代理是否成功启动
openstack network agent list
```

### 部署仪表盘服务 Horizon

#### 安装和配置组件

```bash
# 安装软件包
apt install openstack-dashboard

# 修改配置
vim /etc/openstack-dashboard/local_settings.py
#########################
...
# 配置memcached会话存储服务
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
# 修改配置
OPENSTACK_HOST = "controller"

# 启用身份 API 版本 3
# 如果你的keystone运行在5000端口，那么你也会在这里提到keystone端口，即:
# OPENSTACK_KEYSTONE_URL = “http://%s:5000/identity/v3” % OPENSTACK_HOST
OPENSTACK_KEYSTONE_URL = "http://%s:5000/identity/v3" % OPENSTACK_HOST

# 启用对域的支持
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

# 配置API版本
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}

# 将Default配置为通过仪表板创建的用户的默认域
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"

# 将user配置为通过仪表板创建的用户的默认角色
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

# 如果选择了网络选项1，请禁用对三层网络服务的支持
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': False,
    'enable_quotas': False,
    'enable_ipv6': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_fip_topology_check': False,
}

# 配置时区
TIME_ZONE = "UTC"

DEFAULT_THEME = 'ubuntu'
WEBROOT='/horizon/'

# 允许您的主机访问仪表板
ALLOWED_HOSTS = '*'

COMPRESS_OFFLINE = True
#########################

# 在/etc/apache2/conf-available/openstack-dashboard.conf中添加以下行
vim /etc/apache2/conf-available/openstack-dashboard.conf
#########################
...
WSGIApplicationGroup %{GLOBAL}
#########################


# 重新加载web服务器配置
systemctl reload apache2.service
```

#### 验证

使用web浏览器访问仪表板 http://controller/horizon

使用admin或demo用户和默认域凭据进行身份验证。





## 计算节点服务部署和配置

### 依赖服务配置

- 网络配置参照控制节点网络接口配置。

- 网络时间协议参照控制节点配置即可。

- 配置适用的软件包参照控制节点配置即可。

### 部署和配置计算节点

```bash
# 安装软件包
apt install nova-compute

# 修改配置
vim /etc/nova/nova.conf
#####################
[DEFAULT]
# 修改配置
lock_path = /var/lock/nova
state_path = /opt/nova
transport_url = rabbit://openstack:RABBIT_PASS@controller
my_ip = 192.168.71.54

allow_resize_to_same_host = true
scheduler_default_filters=RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter

[api]
# 修改配置
auth_strategy = keystone

[api_database]
connection = sqlite:////var/lib/nova/nova_api.sqlite
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
connection = sqlite:////var/lib/nova/nova.sqlite
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
# 修改配置
api_servers = http://controller:9292

[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
# 修改配置
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[libvirt]
[metrics]
[mks]
[neutron]
# 修改配置
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS

[notifications]
[oslo_concurrency]
# 修改配置
lock_path = /var/lib/nova/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
# 修改配置
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS

[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
# 修改配置
send_service_user_token = true
auth_url = http://controller:5000/identity
auth_strategy = keystone
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = NOVA_PASS

[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
# 修改配置
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[workarounds]
[wsgi]
[zvm]
[cells]
enable = False
[os_region_name]
openstack = 
#####################

# 确定您的计算节点是否支持虚拟机硬件加速
# 如果此命令返回的值为1或更大，则表示计算节点支持硬件加速，这通常不需要额外的配置。
# 如果此命令返回值为0，则表示计算节点不支持硬件加速，必须将libvirt配置为使用QEMU而不是KVM。
egrep -c '(vmx|svm)' /proc/cpuinfo

# 编辑/etc/nova/nova-computer.conf文件中的[libvirt]部分
[libvirt]
# ...
virt_type = qemu


# 重新启动计算服务
service nova-compute restart

```

### 将计算节点添加到单元格数据库中

此步骤需要在控制节点中执行，请参考控制节点方法配置

### 部署网络服务 Neutron（计算节点）

#### 安装和配置

```bash
# 安装组件
apt install neutron-linuxbridge-agent

# 配置公共组件
vim /etc/neutron/neutron.conf
#####################
[DEFAULT]
# 修改配置
core_plugin = ml2
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone

[agent]
root_helper = "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"
[cache]
[cors]
[database]
# 在[database]部分中，注释掉所有connection选项，因为计算节点不直接访问数据库。
[healthcheck]
[ironic]
[keystone_authtoken]
# 修改配置
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
[oslo_concurrency]
# 修改配置
lock_path = /var/lib/neutron/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[placement]
[privsep]
[profiler]
[quotas]
[ssl]
#####################

```

#### 配置网络选项 1：提供商网络

配置 Linux 桥接代理

```bash
vim /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#####################
[DEFAULT]
[agent]
[linux_bridge]
# 修改 eno33np0 网络接口名称
physical_interface_mappings = provider:eno33np0

[network_log]
[securitygroup]
# 修改配置
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

[vxlan]
# 修改配置
enable_vxlan = false
#####################

# 通过验证以下所有sysctl值都设置为1，确保Linux操作系统内核支持网桥过滤器
sysctl -a | grep net.bridge.bridge-nf-call-iptables
sysctl -a | grep net.bridge.bridge-nf-call-ip6tables

```

#### 配置计算服务以使用网络服务

```bash
vim /etc/nova/nova.conf
#####################
...
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
#####################
```

#### 完成安装

```bash
# 重新启动计算服务
service nova-compute restart

# 重新启动 Linux 桥接代理
service neutron-linuxbridge-agent restart

```

## OpenStack在线调整虚拟机的大小报错

openstack的虚拟机在线调整大小的原理：
其实就相当于做了一个云主机在不同宿主机(计算节点)之间的迁移，所以前提是至少需要有两个计算节点。
如果是单机部署的openstack（即控制节点和计算节点都在一台机器上），有且只有一个计算节点，那么是无法完成在线调整虚拟机大小的。

同时要注意的是：
要在相关迁移云主机间进行无密码访问，由于OpenStack是由Nova组件来管理云主机，所以需要对Nova用户进行无密码访问。

```bash
# 修改控制节点和节点节点的nova.conf文件，添加下面两行内容：
[defaults]
allow_resize_to_same_host=True
scheduler_default_filters=RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter

# 控制节点上重启nova相关服务
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart

# 计算节点上重启nova服务
service nova-compute restart

# 将nova账号的shell类型改为/bin/bash，即可以使用nova账号登陆
cat /etc/passwd|grep nova
#####################
nova:x:64060:64060::/var/lib/nova:/bin/bash
#####################

su - nova

ssh-keygen -t rsa

vim .ssh/authorized_keys

chmod 600 .ssh/authorized_keys

visudo
#####################
nova ALL=(ALL) NOPASSWD: ALL
#####################

# 使用 ssh 命令相互验证
ssh ip
```

