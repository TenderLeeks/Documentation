# KVM 虚拟机系统配置文件



## 虚拟机配置文件

每个KVM虚拟主机都有自己的配置文件，都是以虚拟主机名命名；KVM虚拟机的配置文件在/etc/libvirt/qemu/下，以xml文件形式存在；

```shell
[root@localhost ~]# cd /etc/libvirt/qemu/
```

显示虚拟主机列表

```shell
[root@localhost qemu]# virsh list --all
 Id 名称 状态
----------------------------------------------------
 3 ehs-vm-01 running
 4 ehs-oracle-01 running
```

查看KVM虚拟机配置文件信息

```shell
[root@localhost qemu]# ls
ehs-oracle-01.xml ehs-vm-01.xml networks
```

查看 ehs-vm-01 信息

```shell
[root@localhost qemu]# virsh dominfo ehs-vm-01 
Id: 3
名称： ehs-vm-01
UUID: b2a48a5b-999b-494e-93d0-b2deddd1013c
OS 类型： hvm
状态： running
CPU： 2
CPU 时间： 157.9s
最大内存： 4194304 KiB
使用的内存： 4194304 KiB
持久： 是
自动启动： 禁用
管理的保存： 否
安全性模式： none
安全性 DOI： 0
```

设置 ehs-vm-01  开机自启

```shell
[root@localhost qemu]# virsh autostart ehs-vm-01 
域 ehs-vm-01标记为自动开始
```

autostart 为开机自启目录

```shell
[root@localhost qemu]# ls
autostart ehs-oracle-01.xml ehs-vm-01.xml networks
```

编辑虚拟机centos7.0配置文件，调用vi

```shell
[root@localhost qemu]# virsh edit ehs-vm-01
```

设置virsh edit 高亮显示

```shell
[root@localhost qemu]# export EDITOR=vim
```

备份centos7.0虚拟主机配置文件 

```shell
[root@localhost qemu]# virsh dumpxml ehs-vm-01 > ehs-vm-01.bak
```

## 虚拟机网络配置文件

```shell
[root@localhost qemu]# cd /etc/libvirt/qemu/networks
```

查看网络信息

```shell
[root@localhost networks]# virsh net-list --all
 名称 状态 自动开始 持久
----------------------------------------------------------
 default 不活跃 否 是
```

相关list列表

```shell
[root@localhost networks]# virsh --help |grep list
    domblklist                     列出所有域块
    domiflist                      列出所有域虚拟接口
    list                           列出域
    iface-list                     物理主机接口列表
    nwfilter-list                  列出网络过滤器
    nwfilter-binding-list          list network filter bindings
    net-list                       列出网络
    nodedev-list                   这台主机中中的枚举设备
    secret-list                    列出 secret
    snapshot-list                  为域列出快照
    pool-list                      列出池
    vol-list                       列出卷
```

编辑网络文件 

```shell
[root@localhost networks]# virsh net-edit default
<network>
  <name>default</name>
  <uuid>d0efc2ef-1ed1-4b82-9fd8-0043a0accd05</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:e0:25:f5'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

## 虚拟机存储配置文件

```shell
[root@localhost networks]# cd /etc/libvirt/storage/
[root@localhost storage]# ll
总用量 8
drwxr-xr-x. 2 root root 40 9月 4 10:44 autostart
-rw-------. 1 root root 538 9月 4 10:40 default.xml
-rw-------. 1 root root 515 9月 4 10:44 iso.xml
```

显示存储列表

```shell
[root@localhost storage]# virsh pool-list --all
 名称               状态     自动开始
-------------------------------------------
 default              活动     是       
 iso                  活动     是       
```

编辑存储配置文件

```shell
[root@localhost storage]# virsh pool-edit default
```

## 镜像文件[磁盘文件]

```shell
[root@localhost storage]# cd /var/lib/libvirt/images/
[root@localhost images]# ll
总用量 83899404
-rw------- 1 qemu qemu 53695545344 9月   4 17:28 ehs-oracle-01.qcow2
-rw------- 1 qemu qemu 32217432064 9月   4 17:27 ehs-vm-01.qcow2
```