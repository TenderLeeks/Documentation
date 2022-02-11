# KVM虚拟化之虚拟机内存、CPU调整

## 调小虚拟机内存

**注意：**调小虚拟机内存可以动态实现，不用关机

1. 查看当前内存大小

   ```shell
   [root@ehs-as-04 ~]# virsh dominfo ehs-jboss-01 | grep memory
   [root@ehs-as-04 ~]# virsh dominfo ehs-jboss-01
   Id: 15
   名称： ehs-jboss-01
   UUID: 6c407a2d-e355-4dee-bf00-d13f2cba0c1f
   OS 类型： hvm
   状态： running
   CPU： 2
   CPU 时间： 123263.9s
   最大内存： 4194304 KiB
   使用的内存： 4194304 KiB
   持久： 是
   自动启动： 禁用
   管理的保存： 否
   安全性模式： none
   安全性 DOI： 0
   ```

2. 设置虚拟机内存大小为512MB

   ```shell
   [root@kvm01 ~]# virsh setmem ehs-jboss-01 524288
   ```

3. 再次查看当前内存大小

   ```shell
   [root@kvm01 ~]# virsh dominfo ehs-jboss-01 | grep memory
   Max memory: 786432 KiB
   Used memory: 524288 KiB
   ```

   

## 增大虚拟机内存、增加虚拟机 CPU 个数

**注意：**增大虚拟机内存、增加虚拟机 CPU 个数需要首先关机虚拟机

1. 关闭虚拟机

   ```shell
   virsh shutdown ehs-jboss-01
   ```

2. 编辑虚拟机配置文件

   修改内存 memory 和 currentMemory 参数来调整内存大小；

   修改 CPU vcpu 参数来调整 CPU 个数(核数)；

   ```shell
   [root@ehs-as-04 ~]# virsh edit ehs-jboss-01
   ......
     <name>ehs-jboss-01</name>
     <uuid>6c407a2d-e355-4dee-bf00-d13f2cba0c1f</uuid>
     <memory unit='KiB'>8388608</memory>
     <currentMemory unit='KiB'>8388608</currentMemory>
     <vcpu placement='static'>2</vcpu>
     <os>
   ......
   ```

3. 从配置文件启动虚拟机

   ```shell
   [root@ehs-as-04 ~]# virsh create /etc/libvirt/qemu/ehs-jboss-01.xml 
   域 ehs-jboss-01a 被创建（从 /etc/libvirt/qemu/ehs-jboss-01.xml）
   ```

4. 查看当前内存大小

   ```shell
   [root@ehs-as-04 ~]# virsh dominfo ehs-jboss-01
   Id:             65
   名称：       ehs-jboss-01
   UUID:           6c407a2d-e355-4dee-bf00-d13f2cba0c1f
   OS 类型：    hvm
   状态：       running
   CPU：          2
   CPU 时间：   32.8s
   最大内存： 8388608 KiB
   使用的内存： 8388608 KiB
   持久：       是
   自动启动： 禁用
   管理的保存： 否
   安全性模式： none
   安全性 DOI： 0
   ```

5. 设置虚拟机内存大小为8G

   ```shell
   [root@kvm01 ~]# virsh setmem ehs-jboss-01 8388608
   ```

6. 验证

   查看当前内存大小

   ```shell
   [root@kvm01 ~]# virsh dominfo ehs-jboss-01 | grep memory
   Max memory: 1048432 KiB
   Used memory: 1048432 KiB
   ```

   查看当前CPU个数

   ```shell
   [root@kvm01 ~]# virsh dominfo ehs-jboss-01 | grep CPU
   CPU(s): 2
   CPU time: 15.0s
   ```

   