# kvm快照备份恢复



查看磁盘格式：

```shell
[root@ehs-as-04 ehs-rac-01]# cd /var/lib/libvirt/images/
[root@ehs-as-04 images]# qemu-img info ehs-rac-01.qcow2
image: ehs-rac-01.qcow2
file format: qcow2
virtual size: 30G (32212254720 bytes)
disk size: 34G
cluster_size: 65536
Snapshot list:
ID TAG VM SIZE DATE VM CLOCK
1 ehs-rac-01-bak 1.6G 2019-09-09 16:00:13 00:16:16.672
2 ehs-rac-01-bak02 1.9G 2019-09-09 16:04:40 00:20:27.294
Format specific information:
    compat: 1.1
    lazy refcounts: true
```

因为kvm虚拟机默认使用raw格式的镜像格式，性能最好，速度最快，它的缺点就是不支持一些新的功能，如支持镜像,zlib磁盘压缩,AES加密等。要使用镜像功能，磁盘格式必须为qcow2。如果格式为raw，那么需要来转换。可以看到我们的镜像格是qcow2，故无需改变镜像格式。

转换磁盘格式

```shell
[root@ehs-as-04 images]# qemu-img convert -f raw -O qcow2 ehs-rac-01.img ehs-rac-01.qcow2
-f 源镜像的格式   
-O 目标镜像的格式
```

对虚拟机进行快照管理

创建快照

```shell
[root@ehs-as-04 images]# virsh snapshot-create ehs-rac-01
##也可以给快照起个别名
[root@ehs-as-04 images]# virsh snapshot-create-as ehs-rac-01 ehs-rac-01-bak
```

查看快照版本

```shell
[root@ehs-as-04 images]# virsh snapshot-list ehs-rac-01
 名称 生成时间 状态
------------------------------------------------------------
 ehs-rac-01-bak 2019-09-09 16:00:13 +0800 running
 ehs-rac-01-bak02 2019-09-09 16:04:39 +0800 running
```

查看当前虚拟机的快照版本 

```shell
[root@ehs-as-04 images]# virsh snapshot-current ehs-rac-01
<domainsnapshot>
  <name>ehs-rac-01-bak02</name>
  <state>running</state>
  <parent>
    <name>ehs-rac-01-bak</name>
  </parent>
  <creationTime>1568016279</creationTime>
  <memory snapshot='internal'/>
  <disks>
    <disk name='hda' snapshot='internal'/>
    <disk name='hdb' snapshot='no'/>
  </disks>
  ...
```

查看当前的镜像文件：

```shell
[root@ehs-as-04 images]# qemu-img info ehs-rac-01.qcow2
image: ehs-rac-01.qcow2
file format: qcow2
virtual size: 30G (32212254720 bytes)
disk size: 34G
cluster_size: 65536
Snapshot list:
ID TAG VM SIZE DATE VM CLOCK
1 ehs-rac-01-bak 1.6G 2019-09-09 16:00:13 00:16:16.672
2 ehs-rac-01-bak02 1.9G 2019-09-09 16:04:40 00:20:27.294
Format specific information:
    compat: 1.1
    lazy refcounts: true
```

快照配置文件在/var/lib/libvirt/qemu/snapshot/虚拟机名称下

```shell
[root@ehs-as-04 images]# ll /var/lib/libvirt/qemu/snapshot/ehs-rac-01/
总用量 16
-rw------- 1 root root 5250 9月 9 16:04 ehs-rac-01-bak02.xml
-rw------- 1 root root 5193 9月 9 16:04 ehs-rac-01-bak.xml
```

恢复虚拟机快照

注：恢复快照，必须关机，确认虚拟机处于关机状态。

```shell
[root@ehs-as-04 images]# virsh destroy ehs-rac-01
域 ehs-rac-01 被删除
[root@ehs-as-04 images]# virsh list --all
 Id 名称 状态
----------------------------------------------------
 10 ehs-jboss-02 running
 14 ehs-mq-02 running
 15 ehs-jboss-01 running
 17 ehs-mq-01 running
 23 ehs-rac-02 running
 - ehs-oracle-01 关闭
 - ehs-oracle-02 关闭
 - ehs-rac-01 关闭
```

确认需要恢复的快照版本或时间，这里恢复到 ehs-rac-01-bak02

```shell
[root@ehs-as-04 images]# virsh snapshot-list ehs-rac-01
 名称 生成时间 状态
------------------------------------------------------------
 ehs-rac-01-bak 2019-09-09 16:00:13 +0800 running
 ehs-rac-01-bak02 2019-09-09 16:04:39 +0800 running
```

执行恢复操作

```shell
[root@ehs-as-04 images]# virsh snapshot-revert ehs-rac-01 ehs-rac-01-bak02
```

如果按时间恢复需要把 ehs-rac-01-bak02 修改为时间戳

```shell
[root@ehs-as-04 images]# virsh snapshot-revert ehs-rac-01 1500373324
```

删除虚拟机快照

先ehs-rac-01镜像对应有哪些快照 

```shell
[root@ehs-as-04 images]# qemu-img info ehs-rac-01.qcow2 
image: ehs-rac-01.qcow2
file format: qcow2
virtual size: 30G (32212254720 bytes)
disk size: 34G
cluster_size: 65536
Snapshot list:
ID TAG VM SIZE DATE VM CLOCK
1 ehs-rac-01-bak 1.6G 2019-09-09 16:00:13 00:16:16.672
2 ehs-rac-01-bak02 1.9G 2019-09-09 16:04:40 00:20:27.294
Format specific information:
    compat: 1.1
    lazy refcounts: true
```

删除第一个快照

```shell
[root@ehs-as-04 images]# virsh snapshot-delete ehs-rac-01 ehs-rac-01-bak
已删除域快照 ehs-rac-01-bak
```

查看确认

```shell
[root@ehs-as-04 images]# virsh snapshot-list ehs-rac-01
 名称 生成时间 状态
------------------------------------------------------------
 ehs-rac-01-bak02 2019-09-09 16:04:39 +0800 running
```

已经被删除。