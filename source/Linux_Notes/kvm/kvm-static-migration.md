# kvm虚拟机静态迁移

静态迁移就是虚拟机在关机状态下，拷贝虚拟机虚拟磁盘文件与配置文件到目标虚拟主机中，实现的迁移。



1. 虚拟主机各自使用本地存储存放虚拟机磁盘文

   本文实现基于本地磁盘存储虚拟机磁盘文件的迁移方式

2. 虚拟主机之间使用共享存储存放虚拟机磁盘文件

   该方式只是在目标虚拟主机上重新定义虚拟机就可以了。



## 静态迁移过程如下

1. 确定虚拟机关闭状态

   ```shell
   [root@ehs-as-03 images]# virsh destroy ehs-tomcat-01
   域 ehs-tomcat-01 被删除
   [root@ehs-as-03 images]# virsh list --all            
    Id 名称 状态
   ----------------------------------------------------
    6 ehs-db-01 running
    - ehs-tomcat-01 关闭
   ```

2. 准备迁移 ehs-tomcat-01 虚拟机，查看该虚拟机配置的磁盘文件

   ```shell
   [root@ehs-as-03 images]# virsh domblklist ehs-tomcat-01 
   目标 源
   ------------------------------------------------
   vda /var/lib/libvirt/images/ehs-tomcat-01.qcow2
   hda -
   ```

3. 导入虚拟机配置文件

   ```shell
   [root@ehs-as-03 images]# virsh dumpxml ehs-tomcat-01 > /root/ehs-tomcat-01.xml
   [root@ehs-as-03 images]# ll /root/ehs-tomcat-01.xml
   -rw-r--r-- 1 root root 4394 10月 14 17:29 /root/ehs-tomcat-01.xml
   ```

4. 拷贝配置文件到目标虚拟主机上

   ```shell
   [root@ehs-as-03 images]# scp /root/ehs-tomcat-01.xml 10.0.7.100:/etc/libvirt/qemu/
   root@10.0.7.100's password: 
   ehs-tomcat-01.xml                                                                                             100%   4394  620.2KB/s   00:00
   ```

5. 查看虚拟机磁盘文件并拷贝到目标虚拟主机

   ```shell
   [root@ehs-as-03 images]# cd /var/lib/libvirt/images
   [root@ehs-as-03 images]# ll
   总用量 141579864
   drwx--x--x. 2 qemu qemu 56 10月 14 10:55 .
   drwxr-xr-x. 10 root root 117 9月 17 10:18 ..
   -rw------- 1 qemu qemu 107390828544 10月 14 17:32 ehs-db-01.qcow2
   -rw------- 1 root root 37586927616 10月 14 17:25 ehs-tomcat-01.qcow2
   ```

   拷贝虚拟磁盘文件

   ```shell
   [root@ehs-as-03 images]# scp ehs-tomcat-01.qcow2 10.0.7.100:/var/lib/libvirt/images
   root@10.0.7.100's password: 
   ehs-tomcat-01.qcow2                                                                                             100%   35GB  94.9MB/s   06:17
   ```

   

## 目标虚拟主机上

上面已经将虚拟机磁盘文件与配置文件都已经复制到目标虚拟主机上了。下面开始配置与启动。

1. 查看目标虚拟主机环境

   ```shell
   [root@ehs-as-04 qemu]# virsh list --all
    Id    名称                         状态
   ----------------------------------------------------
    51    ehs-mq-01                      running
    54    ehs-mq-02                      running
    56    ehs-mq-03                      running
    65    ehs-jboss-01                   running
    66    ehs-jboss-02                   running
    70    test                           running
   [root@ehs-as-04 qemu]# ll /etc/libvirt/qemu
   总用量 56
   drwxr-xr-x  2 root root    6 9月   4 18:19 autostart
   -rw-------  1 root root 4619 9月  27 10:15 ehs-jboss-01.xml
   -rw-------  1 root root 4619 9月  27 10:20 ehs-jboss-02.xml
   -rw-------  1 root root 4610 9月   5 14:58 ehs-mq-01.xml
   -rw-------  1 root root 4674 9月  12 19:47 ehs-mq-02.xml
   -rw-------  1 root root 4674 9月  12 19:45 ehs-mq-03.xml
   -rw-r--r--  1 root root 4394 10月 14 17:31 ehs-tomcat-01.xml
   drwx------. 3 root root   65 9月   5 14:50 networks
   -rw-------  1 root root 5229 10月 10 14:24 test.xml
   ```

   查看虚拟机磁盘文件，目录结构与源虚拟主机一致。

   ```shell
   [root@ehs-as-04 qemu]# cd /var/lib/libvirt/images/
   [root@ehs-as-04 images]# ll
   总用量 155312804
   -rw------- 1 qemu qemu 38973931520 10月 14 17:43 ehs-jboss-01.qcow2
   -rw------- 1 qemu qemu 14153416704 10月 14 17:44 ehs-jboss-02.qcow2
   -rw------- 1 qemu qemu 10469834752 10月 14 17:44 ehs-mq-01.qcow2
   -rw------- 1 qemu qemu  7567572992 10月 14 17:43 ehs-mq-02.qcow2
   -rw------- 1 qemu qemu 28703981568 10月 14 17:43 ehs-mq-03.qcow2
   -rw------- 1 root root 37586927616 10月 14 17:40 ehs-tomcat-01.qcow2
   -rw-r--r-- 1 qemu qemu   439353344 10月 14 17:43 test-01.qcow2
   -rw-r--r-- 1 qemu qemu   133365760 10月 14 17:44 test-02.qcow2
   -rw------- 1 qemu qemu 19602276352 10月 14 17:43 test.qcow2
   ```

2. 定义注册虚拟主机

   ```shell
   [root@ehs-as-04 images]# virsh define /etc/libvirt/qemu/ehs-tomcat-01.xml 
   定义域 ehs-tomcat-01（从 /etc/libvirt/qemu/ehs-tomcat-01.xml）
   [root@ehs-as-04 images]# virsh list --all
    Id    名称                         状态
   ----------------------------------------------------
    51    ehs-mq-01                      running
    54    ehs-mq-02                      running
    56    ehs-mq-03                      running
    65    ehs-jboss-01                   running
    66    ehs-jboss-02                   running
    70    test                           running
    -     ehs-tomcat-01                  关闭
   ```

3. 启动虚拟主机

   ```shell
   [root@ehs-as-04 images]# virsh start ehs-tomcat-01 
   错误：开始域 ehs-tomcat-01 失败
   错误：the CPU is incompatible with host CPU: 主机 CPU 不提供所需功能: fma, movbe, fsgsbase, bmi1, avx2, smep, bmi2, erms, invpcid
   ```

   **错误：**CPU与主机不兼容

   解决：这是配置文件中CPU类型设置不对，改一下就行了

   查看其他虚拟机 cpu 配置类型

   ```shell
   [root@ehs-as-04 qemu]# more ehs-mq-01.xml
   ……
     <cpu mode='custom' match='exact' check='partial'>
       <model fallback='allow'>SandyBridge-IBRS</model>
     </cpu>
   ……
   [root@ehs-as-04 qemu]# more ehs-tomcat-01.xml
   ……
     <cpu mode='custom' match='exact' check='partial'>
       <model fallback='allow'>Haswell-noTSX-IBRS</model>
     </cpu>
   ……
   ```

   需要把 Haswell-noTSX-IBRS 改成 SandyBridge-IBRS

   ```shell
   [root@ehs-as-04 qemu]# virsh edit ehs-tomcat-01
   编辑了域 ehs-tomcat-01 XML 配置。
   [root@ehs-as-04 qemu]# virsh dumpxml ehs-tomcat-01
   ……
     <cpu mode='custom' match='exact' check='partial'>
       <model fallback='allow'>SandyBridge-IBRS</model>
     </cpu>
   ……
   ```

   启动虚拟机

   ```shell
   [root@ehs-as-04 qemu]# virsh start ehs-tomcat-01 
   域 ehs-tomcat-01 已开始
   ```

   进入虚拟机系统

   ```shell
   [root@ehs-as-04 ~]# virsh console ehs-tomcat-01
   ```

   至此虚拟机静态迁移完成。

