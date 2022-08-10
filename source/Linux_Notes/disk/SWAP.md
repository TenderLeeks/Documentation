# Ubuntu 20.04 swap管理

## 创建 swap 交换空间

1. 创建swap交换文件

   ```shell
   $ sudo fallocate -l 8G /swapfile
   ```

   如果系统上没有`fallocate`命令，或者您收到一条错误消息，提示`fallocate failed: Operation not supported`操作不支持，请使用以下命令创建swap交换空间文件：

   ```shell
   $ sudo dd if=/dev/zero of=/swapfile bs=1024 count=8388608
   ```

   设置文件权限为`600`，以防止其它普通用户读写文件

   ```shell
   $ sudo chmod 600 /swapfile
   ```

2. 格式化 swap 交换空间文件

   ```shell
   $ sudo mkswap /swapfile  # 或使用 sudo mkswap -f swapfile 命令
   Setting up swapspace version 1, size = 8 GiB (8589930496 bytes)
   no label, UUID=423c626d-7703-45ca-8b31-6afaba8deddf
   ```

3. 启用 swap 交换空间文件

   ```shell
   $ sudo swapon /swapfile
   ```

4. 自动挂载 swap 交换空间文件到分区

   ```shell
   $ sudo cat /etc/fstab
   /swapfile swap swap defaults 0 0
   ```

5. 通过使用 `swapon` 或 `free` 命令验证 swap 交换空间是否处于活动状态

   ```shell
   $ sudo swapon --show
   NAME  TYPE SIZE USED PRIO
   /swap file   8G   0B   -2
   
   $ sudo free -h
                 total        used        free      shared  buff/cache   available
   Mem:           7688        4004         431           2        3251        3383
   Swap:          8191           0        8191
   ```

   

## 调整Swappiness值

Swappiness是Linux内核属性，它定义系统多久使用一次swap交换空间。 它的值可以在0到100之间。较低的值将使内核尽可能避免交换，而较高的值将使内核更积极地使用交换空间。

1. 查看系统 `swappiness` 值

   ```shell
   $ cat /proc/sys/vm/swappiness
   0
   ```

2. 临时修改系统 `swappiness` 值

   ```shell
   $ sudo sysctl vm.swappiness=40
   ```

3. 永久修改系统 `swappiness` 值

   ```shell
   $ echo vm.swappiness=40 | sudo tee -a /etc/sysctl.conf
   ```

   

最佳交换值取决于您的系统工作负载以及内存的使用方式。 您应该以较小的增量调整此参数以找到最佳值。

## 删除swap交换文件

要停用和删除交换文件，请按照以下步骤操作：首先，停用swap交换空间：

```shell
$ sudo swapoff -v /swapfile
```

接下来，从`/etc/fstab`文件删除自动挂载项，然后使用`rm`命令删除swap交换空间文件：

```shell
$ sudo rm /swapfile
```

