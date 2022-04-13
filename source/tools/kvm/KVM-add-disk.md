# KVM虚拟机添加磁盘



未添加硬盘之前,到虚拟机中查看 fdisk -l ,确定只有一块vda

```shell
[root@ehs-oracle-01 rules.d]# fdisk -l
磁盘 /dev/vda：53.7 GB, 53687091200 字节，104857600 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x000b337a
   设备 Boot Start End Blocks Id System
/dev/vda1 * 2048 2099199 1048576 83 Linux
/dev/vda2 2099200 104857599 51379200 8e Linux LVM
磁盘 /dev/mapper/rhel-root：47.2 GB, 47240445952 字节，92266496 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/mapper/rhel-swap：5368 MB, 5368709120 字节，10485760 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
[root@ehs-oracle-01 rules.d]# 
```

在宿主机上进行操作

```shell
[root@localhost images]# cd /var/lib/libvirt/images
```

创建新的虚拟磁盘：

```shell
[root@ehs-as-04 images]# qemu-img create -f qcow2 -o size=4G /var/lib/libvirt/images/ehs-rac-01-b.qcow2
Formatting '/var/lib/libvirt/images/ehs-rac-01-b.qcow2', fmt=qcow2 size=4294967296 encryption=off cluster_size=65536 lazy_refcounts=off 
[root@ehs-as-04 images]# qemu-img create -f qcow2 -o size=4G /var/lib/libvirt/images/ehs-rac-01-c.qcow2
Formatting '/var/lib/libvirt/images/ehs-rac-01-c.qcow2', fmt=qcow2 size=4294967296 encryption=off cluster_size=65536 lazy_refcounts=off 
[root@ehs-as-04 images]# qemu-img create -f qcow2 -o size=4G /var/lib/libvirt/images/ehs-rac-01-d.qcow2
Formatting '/var/lib/libvirt/images/ehs-rac-01-d.qcow2', fmt=qcow2 size=4294967296 encryption=off cluster_size=65536 lazy_refcounts=off 
[root@ehs-as-04 images]# qemu-img create -f qcow2 -o size=40G /var/lib/libvirt/images/ehs-rac-01-e.qcow2
Formatting '/var/lib/libvirt/images/ehs-rac-01-e.qcow2', fmt=qcow2 size=21474836480 encryption=off cluster_size=65536 lazy_refcounts=off 
[root@ehs-as-04 images]# qemu-img create -f qcow2 -o size=20G /var/lib/libvirt/images/ehs-rac-01-f.qcow2
Formatting '/var/lib/libvirt/images/ehs-rac-01-f.qcow2', fmt=qcow2 size=21474836480 encryption=off cluster_size=65536 lazy_refcounts=off 
[root@ehs-as-04 images]# ll
总用量 127525264
-rw------- 1 qemu qemu 21478375424 9月   9 17:47 ehs-jboss-01.qcow2
-rw------- 1 qemu qemu  4642897920 9月   9 17:47 ehs-jboss-02.qcow2
-rw------- 1 qemu qemu  3873898496 9月   9 17:46 ehs-mq-01.qcow2
-rw------- 1 qemu qemu  3718119424 9月   9 17:43 ehs-mq-02.qcow2
-rw-r--r-- 1 root root      197120 9月   6 16:20 ehs-oracle-01-a.img
-rw-r--r-- 1 root root      197120 9月   6 16:21 ehs-oracle-01-b.img
-rw-r--r-- 1 root root      197120 9月   6 16:21 ehs-oracle-01-c.img
-rw-r--r-- 1 root root      197120 9月   6 16:21 ehs-oracle-01-d.img
-rw-r--r-- 1 root root      197120 9月   6 16:21 ehs-oracle-01-e.img
-rw------- 1 root root 53695545344 9月   9 15:42 ehs-oracle-01.qcow2
-rw------- 1 root root  3783524352 9月   9 15:42 ehs-oracle-02.qcow2
-rw-r--r-- 1 root root      197120 9月   9 17:46 ehs-rac-01-b.qcow2
-rw-r--r-- 1 root root      197120 9月   9 17:46 ehs-rac-01-c.qcow2
-rw-r--r-- 1 root root      197120 9月   9 17:46 ehs-rac-01-d.qcow2
-rw-r--r-- 1 root root      197120 9月   9 17:46 ehs-rac-01-e.qcow2
-rw-r--r-- 1 root root      197120 9月   9 17:46 ehs-rac-01-f.qcow2
-rw------- 1 qemu qemu 36369137664 9月   9 17:42 ehs-rac-01.qcow2
-rw------- 1 qemu qemu  4957863936 9月   9 17:47 ehs-rac-02.qcow2
```

添加虚拟磁盘到指定的虚拟机：

```shell
[root@ehs-as-04 images]# virsh attach-disk --domain ehs-rac-01 --source /var/lib/libvirt/images/ehs-rac-01-b.qcow2 --target sdb --targetbus virtio --driver qemu --subdriver qcow2 --sourcetype file --cache none --persistent
成功附加磁盘
[root@ehs-as-04 images]# virsh attach-disk --domain ehs-rac-01 --source /var/lib/libvirt/images/ehs-rac-01-c.qcow2 --target sdc --targetbus virtio --driver qemu --subdriver qcow2 --sourcetype file --cache none --persistent
成功附加磁盘
[root@ehs-as-04 images]# virsh attach-disk --domain ehs-rac-01 --source /var/lib/libvirt/images/ehs-rac-01-d.qcow2 --target sdd --targetbus virtio --driver qemu --subdriver qcow2 --sourcetype file --cache none --persistent
成功附加磁盘
[root@ehs-as-04 images]# virsh attach-disk --domain ehs-rac-01 --source /var/lib/libvirt/images/ehs-rac-01-e.qcow2 --target sde --targetbus virtio --driver qemu --subdriver qcow2 --sourcetype file --cache none --persistent
成功附加磁盘
[root@ehs-as-04 images]# virsh attach-disk --domain ehs-rac-01 --source /var/lib/libvirt/images/ehs-rac-01-f.qcow2 --target sdf --targetbus virtio --driver qemu --subdriver qcow2 --sourcetype file --cache none --persistent
成功附加磁盘
```

**注意**：这里的 --source 后面必须跟绝对路径；

参数说明：

--persistent：会让此操作同时对运行的虚拟机以及虚拟机的xml文件都会生效；

--target：设定在虚拟机中此设备的设备文件名称，最好在添加硬盘之前到虚拟机中先查看确认一下磁盘设备名称；然后此处设置名称顺延，比如我的虚拟机中原来只有一块盘，其设备文件名为vda，所以我这里设定为vdb。

--targetbus：用来设定客户机磁盘的总线类型；

--driver：根据模拟器而定，如果模拟器是qemu则此处的值只能是qemu；

--subdriver：磁盘源的类型；

--sourcetype：磁盘源的大类，这里用的是file，也可以使用block；

查看虚拟机的配置信息：

```shell
[root@localhost images]# virsh dumpxml ehs-rac-01
 ...
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01.qcow2'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-a.img'/>
      <backingStore/>
      <target dev='vdb' bus='virtio'/>
      <alias name='virtio-disk1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0b' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-b.img'/>
      <backingStore/>
      <target dev='vdc' bus='virtio'/>
      <alias name='virtio-disk2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0c' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-c.img'/>
      <backingStore/>
      <target dev='vdd' bus='virtio'/>
      <alias name='virtio-disk3'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0d' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-d.img'/>
      <backingStore/>
      <target dev='vde' bus='virtio'/>
      <alias name='virtio-disk4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0e' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-e.img'/>
      <backingStore/>
      <target dev='vdf' bus='virtio'/>
      <alias name='virtio-disk5'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0f' function='0x0'/>
    </disk>
 ...
```

编辑虚拟机配置文件：

```shell
[root@localhost images]# virsh edit ehs-rac-01
 ...
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-a.img'/>
      <target dev='vdb' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0b' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-b.img'/>
      <target dev='vdc' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0c' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-c.img'/>
      <target dev='vdd' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0d' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-d.img'/>
      <target dev='vde' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0e' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/var/lib/libvirt/images/ehs-oracle-01-e.img'/>
      <target dev='vdf' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x0f' function='0x0'/>
    </disk>
 ...
```

添加磁盘之后，到虚拟机中查看：

```shell
[root@ehs-oracle-01 rules.d]# fdisk -l
磁盘 /dev/vda：53.7 GB, 53687091200 字节，104857600 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x000b337a
   设备 Boot Start End Blocks Id System
/dev/vda1 * 2048 2099199 1048576 83 Linux
/dev/vda2 2099200 104857599 51379200 8e Linux LVM
磁盘 /dev/mapper/rhel-root：47.2 GB, 47240445952 字节，92266496 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/mapper/rhel-swap：5368 MB, 5368709120 字节，10485760 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/vdb：4294 MB, 4294967296 字节，8388608 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/vdc：4294 MB, 4294967296 字节，8388608 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/vdd：4294 MB, 4294967296 字节，8388608 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/vde：21.5 GB, 21474836480 字节，41943040 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘 /dev/vdf：21.5 GB, 21474836480 字节，41943040 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
```

然后对磁盘进行分区格式化挂载，使用就行了；