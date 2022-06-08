# LVM + XFS 格式分区系统

## CentOS 7 系统创建分区

本次操作以此片vdb为例

```shell
$ yum update -y
# 创建PV，将新添加的磁盘创建为物理卷
$ pvcreate /dev/vdb
# 创建VG，在新创建的物理卷上创建名称为data的卷组，‘data’可以跟随需求自定义名称
$ vgcreate data /dev/vdb
# 创建LV，在data的卷组上创建名称为mydata的逻辑卷，并使用卷组的所有空间，
# ‘mydata’可以跟随需求自定义名称
$ lvcreate -l 100%VG -n mydata data
# 格式化逻辑卷，将名称为mydata的逻辑卷格式化为xfs格式
$ mkfs.xfs /dev/data/mydata
# 挂载逻辑卷，查询新分区的 uuid
$ blkid /dev/data/mydata
# 将新创建的文件系统以noatime及nodiratime的模式进行挂载，
# 并写入/etc/fstab文件中，以便开机实现自动挂载
# 需替换下面命令中UUID内容
$ echo "UUID=ea4b86d4-f2b9-4906-b00d-9fe66551f8cc /opt xfs noatime,nodiratime,inode64 0 0" >> /etc/fstab
$ mount -a
```

## CentOS 7 系统分区扩容

```shell
# 增加一块新磁盘vdc，查看新增磁盘信息
$ fdisk -l
$ lsblk
$ pvcreate /dev/vdc  # 增加PV
$ vgextend data /dev/vdc  # 扩展VG
$ lvextend -l +100%FREE /dev/data/mydata  # 扩展LV
$ xfs_growfs /dev/data/mydata  # 扩展XFS
$ xfs_info /dev/data/mydata  # 查看扩展后的信息
$ df -h  # 查看操作系统空间情况

# brtfs文件系统扩容空间(无需操作，扩展)
# 直接使用brtfs命令即可。vdd为新增磁盘，opt为挂载目录
$ btrfs device add /dev/vdc /opt
$ df -h
```

## Debian 9  系统创建分区

```shell
$ apt-get update -y
$ apt-get install lvm2
$ pvcreate /dev/vdb
$ vgcreate data /dev/vdb
$ lvcreate -l 100%VG -n mydata data
$ mkfs.ext4 /dev/data/mydata
$ echo "/dev/data/mydata     /opt                 ext4       defaults,auto    0 0" >> /etc/fstab
$ mount -a
$ df -h
```

## 删除 LVM

1. 查看卷组VG相关信息

   ```shell
   $ df -h
   Filesystem                  Size  Used Avail Use% Mounted on
   ...
   /dev/vda1                    50G   14G   34G  28% /
   /dev/mapper/omni-data       1.6T  886G  715G  56% /opt/chain/omni
   /dev/mapper/btc-data       1000G  394G  607G  40% /opt/chain/bitcoin
   /dev/mapper/hecochain-data  300G  225G   76G  75% /opt/chain/hecochain
   
   $ lsblk
   NAME             MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
   sr0               11:0    1 16.4M  0 rom
   vdc              253:32   0 1000G  0 disk
   └─btc-data       252:3    0 1000G  0 lvm  /opt/chain/bitcoin
   vdd              253:48   0  800G  0 disk
   └─omni-data      252:0    0  1.6T  0 lvm  /opt/chain/omni
   vdf              253:80   0  800G  0 disk
   └─omni-data      252:0    0  1.6T  0 lvm  /opt/chain/omni
   vdg              253:96   0  300G  0 disk
   └─hecochain-data 252:5    0  300G  0 lvm  /opt/chain/hecochain
   
   $ vgscan
     Reading volume groups from cache.
     Found volume group "btc" using metadata type lvm2
     Found volume group "omni" using metadata type lvm2
     Found volume group "hecochain" using metadata type lvm2
       
   $ pvscan
     PV /dev/vdc   VG btc             lvm2 [<1000.00 GiB / 0    free]
     PV /dev/vdd   VG omni            lvm2 [<800.00 GiB / 0    free]
     PV /dev/vdf   VG omni            lvm2 [<800.00 GiB / 0    free]
     PV /dev/vdg   VG hecochain       lvm2 [<300.00 GiB / 0    free]
     ...
     Total: 10 [<8.40 TiB] / in use: 10 [<8.40 TiB] / in no VG: 0 [0
   ```

2. 查看卷组 omni 包含的PV、LV信息

   ```shell
   $ vgdisplay -v omni
     --- Volume group ---
     VG Name               omni
     System ID
     Format                lvm2
     Metadata Areas        2
     Metadata Sequence No  4
     VG Access             read/write
     VG Status             resizable
     MAX LV                0
     Cur LV                1
     Open LV               1
     Max PV                0
     Cur PV                2
     Act PV                2
     VG Size               1.56 TiB
     PE Size               4.00 MiB
     Total PE              409598
     Alloc PE / Size       409598 / 1.56 TiB
     Free  PE / Size       0 / 0
     VG UUID               G98fNR-32ze-VDL1-zAd3-aah2-e4Hk-m52q0a
   
     --- Logical volume ---
     LV Path                /dev/omni/data
     LV Name                data
     VG Name                omni
     LV UUID                YiyowX-IU2G-Q9CI-2mze-qmko-t2kV-aRyDZv
     LV Write Access        read/write
     LV Creation host, time bj-prod-chain-eth-btc-01b, 2021-01-05 17:14:58 +0800
     LV Status              available
     # open                 1
     LV Size                1.56 TiB
     Current LE             409598
     Segments               2
     Allocation             inherit
     Read ahead sectors     auto
     - currently set to     8192
     Block device           252:0
   
     --- Physical volumes ---
     PV Name               /dev/vdd
     PV UUID               9bjDlb-Ealf-YteL-QR3e-1bDQ-WKPI-9X0Vkm
     PV Status             allocatable
     Total PE / Free PE    204799 / 0
   
     PV Name               /dev/vdf
     PV UUID               BQ7E5S-1wNG-C0ek-PEhm-2Glw-1eid-HcjYfH
     PV Status             allocatable
     Total PE / Free PE    204799 / 0
   ```

3. 卸载卷组的逻辑卷LV

   要卸载对应卷组VG的所有逻辑卷LV。从上面的信息可以看出对应的卷组 omni 只有 /dev/omni/data 这个逻辑卷LV

   ```shell
   # 如果还用进程在使用对应逻辑卷的文件，就必须强制卸载挂接点。
   $ umount /dev/omni/data
   ```

4. 删除逻辑卷LV

   ```shell
   $ lvremove /dev/omni/data
   Do you really want to remove active logical volume omni/data? [y/n]: y
     Logical volume "data" successfully removed
   ```

   验证LV是否删除

   ```shell
   $ lvdisplay | grep "/dev/omni/data"
   ```

5. 删除卷组VG

   采用安全的方式删除卷组VG，则必须使用 vgchange -a n omni 关闭了omni，然后才可以删除它。

   ```shell
   $ vgchange -a n omni
     0 logical volume(s) in volume group "omni" now active
   $ vgremove omni
     Volume group "omni" successfully removed
   ```

   验证卷组VG是否删除

   ```shell
   $ vgscan
     Reading volume groups from cache.
     Found volume group "btc" using metadata type lvm2
     Found volume group "hecochain" using metadata type lvm2
     Found volume group "eth" using metadata type lvm2
     Found volume group "blockbook" using metadata type lvm2
     Found volume group "bsc" using metadata type lvm2
   ```

6. 删除物理卷PV

   ```shell
   $ pvremove /dev/vdd /dev/vdf
     Labels on physical volume "/dev/vdd" successfully wiped.
     Labels on physical volume "/dev/vdf" successfully wiped.
   $ pvscan
     PV /dev/vdc   VG btc             lvm2 [<1000.00 GiB / 0    free]
     PV /dev/vdg   VG hecochain       lvm2 [<300.00 GiB / 0    free]
     PV /dev/vdb   VG eth             lvm2 [<2.15 TiB / 0    free]
     PV /dev/vde   VG blockbook       lvm2 [<1000.00 GiB / 0    free]
     PV /dev/vdh   VG bsc             lvm2 [<500.00 GiB / 0    free]
     PV /dev/vdi   VG bsc             lvm2 [<500.00 GiB / 0    free]
     PV /dev/vdj   VG bsc             lvm2 [<500.00 GiB / 0    free]
     PV /dev/vdk   VG bsc             lvm2 [<1000.00 GiB / 0    free]
     Total: 8 [<6.84 TiB] / in use: 8 [<6.84 TiB] / in no VG: 0 [0   ]
   ```

7. 编辑/etc/fstab，删除对应挂载信息

   ```shell
   $ vim /etc/fstab
   ```

8. 腾讯云卸载磁盘

   ```shell
   # 查看当前系统内的磁盘，这里对应控制台的磁盘id和系统内部标识
   $ ll /dev/disk/by-id/ | egrep "vdf|vdg"
   ...
   lrwxrwxrwx 1 root root  9 Jun 11 12:49 virtio-disk-58gkencf -> ../../vdf
   lrwxrwxrwx 1 root root  9 Apr 14 17:06 virtio-disk-k5cy90yp -> ../../vdg
   ```


## 增加 LVM 容量

```shell
# 将新硬盘分区并转成pv
$ vgextend data /dev/vdc
$ lvextend -l +100%FREE /dev/data/mydata
# 或使用
$ lvresize -L +7G /dev/data/mydata
# 感觉对lv容量操作使用lvresize较好
$ resize2fs -f /dev/data/mydata
```

## LVM 扩展命令

```shell
$ lvreduce  # 减少lv的容量
$ vgreduce  # 从vg中抽出pv
$ pvmove  # 将组中的指定pv上的数据移走，一般是pv出错替换硬盘时使用
```

## 移除LVM中的硬盘

**请不要轻易缩容和移除硬盘**，移除硬盘请参考[此处](http://mnstory.net/2017/10/20/lvm-reduce/)文档

```shell
$ pvmove /dev/sdd  # 将当前pv的的数据移动到卷组中的其他pv中
$ vgreduce vg0 /dev/sdd  # 将硬盘/dev/sdd从卷组vg0中移除
$ pvremove /dev/sdd  # 将sdd硬盘从pv中移除
```

## 使用iostat命令查看磁盘读写情况

```shell
$ iostat 1 5
$ iostat -d /dev/vde 1 5
```

