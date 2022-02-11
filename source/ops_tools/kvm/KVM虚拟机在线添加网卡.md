# KVM虚拟机在线添加网卡

1. 查看原有网卡信息

   ```shell
   [root@localhost qemu]# virsh domiflist ehs-rac-01
   接口 类型 源 型号 MAC
   -------------------------------------------------------
   vnet5 bridge br0 virtio 52:54:00:fa:ea:70
   ```

2. 临时添加新网卡

   ```shell
   [root@localhost qemu]# virsh attach-interface ehs-rac-01 --type bridge --source br0
   成功附加接口
   [root@localhost qemu]# virsh attach-interface ehs-rac-01 --type bridge --source br0 --config
   成功附加接口
   ```

3. 查看

   ```shell
   [root@localhost qemu]# virsh domiflist ehs-rac-01
   接口 类型 源 型号 MAC
   -------------------------------------------------------
   vnet5 bridge br0 virtio 52:54:00:fa:ea:70
   vnet6 bridge br0 rtl8139 52:54:00:d0:a5:35
   [root@localhost qemu]# ip a
   1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
       link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
       inet 127.0.0.1/8 scope host lo
          valid_lft forever preferred_lft forever
       inet6 ::1/128 scope host 
          valid_lft forever preferred_lft forever
   2: em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master br0 state UP group default qlen 1000
       link/ether 44:a8:42:2b:fa:d4 brd ff:ff:ff:ff:ff:ff
   3: em2: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
       link/ether 44:a8:42:2b:fa:d5 brd ff:ff:ff:ff:ff:ff
   10: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
       link/ether 44:a8:42:2b:fa:d4 brd ff:ff:ff:ff:ff:ff
       inet 10.0.7.100/24 brd 10.0.7.255 scope global noprefixroute br0
          valid_lft forever preferred_lft forever
       inet6 fe80::46a8:42ff:fe2b:fad4/64 scope link 
          valid_lft forever preferred_lft forever
   21: vnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:fd:d3:f8 brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fefd:d3f8/64 scope link 
          valid_lft forever preferred_lft forever
   23: vnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:0e:e7:6c brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fe0e:e76c/64 scope link 
          valid_lft forever preferred_lft forever
   24: vnet3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:64:2f:2c brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fe64:2f2c/64 scope link 
          valid_lft forever preferred_lft forever
   25: vnet4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:ee:d7:4f brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:feee:d74f/64 scope link 
          valid_lft forever preferred_lft forever
   26: vnet1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:93:99:c8 brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fe93:99c8/64 scope link 
          valid_lft forever preferred_lft forever
   27: vnet5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:fa:ea:70 brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fefa:ea70/64 scope link 
          valid_lft forever preferred_lft forever
   28: vnet6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN group default qlen 1000
       link/ether fe:54:00:d0:a5:35 brd ff:ff:ff:ff:ff:ff
       inet6 fe80::fc54:ff:fed0:a535/64 scope link 
          valid_lft forever preferred_lft forever
   ```

4. 命令行增加的网卡只保存在内存中，重启就失效，所以需要保存到配置文件中

   ```shell
   [root@localhost qemu]# virsh dumpxml ehs-rac-01 > /etc/libvirt/qemu/ehs-rac-01.xml
   [root@localhost qemu]# virsh define /etc/libvirt/qemu/ehs-rac-01.xml 
   定义域 ehs-oracle-01（从 /etc/libvirt/qemu/ehs-oracle-01.xml）
   ```

   删除网卡命令

   ```shell
   [root@localhost qemu]# virsh detach-interface ehs-rac-01 --type bridge --mac fe:54:00:d0:a5:35
   成功分离接口  
   ```

   再重新保存配置