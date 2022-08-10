# Ubuntu部署NFS服务

## 服务端

1. 安装NFS服务

   ```shell
   # 执行以下命令安装NFS服务器，
   # apt会自动安装 nfs-common、rpcbind 等13个软件包
   $ sudo apt install nfs-kernel-server
   ```

2. 配置文件

   ```shell
   $ cat /etc/exports
   /data/use *(rw,sync,no_subtree_check,no_root_squash)
   ```

   `/data/use` NFS服务器端的目录，用于与nfs客户端共享

   `*`  允许所有的网段访问，也可以使用具体的IP

   `rw`  挂接此目录的客户端对该共享目录具有读写权限

   `sync`  资料同步写入内存和硬盘

   `no_root_squash`  root用户具有对根目录的完全管理访问权限

   `no_subtree_check`  不检查父目录的权限

3. 创建共享目录

   ```shell
   $ sudo mkdir -p /data/use
   ```

4. 重启nfs服务

   ```shell
   $ sudo service nfs-kernel-server restart
   ```

5. 常用命令工具

   ```shell
   # 在安装NFS服务器时，已包含常用的命令行工具，无需额外安装。
   # 显示已经mount到本机nfs目录的客户端机器。
   $ sudo showmount -e localhost
   # 将配置文件中的目录全部重新export一次！无需重启服务。
   $ sudo exportfs -rv
   # 查看NFS的运行状态
   $ sudo nfsstat
   # 查看rpc执行信息，可以用于检测rpc运行情况
   $ sudo rpcinfo
   # 查看网络端口，NFS默认是使用111端口。
   $ sudo netstat -tu -4
   ```

   

## 客户端

1. 安装客户端工具

   ```shell
   # 在需要连接到NFS服务器的客户端机器上，
   # 需要执行以下命令，安装nfs-common软件包。
   # apt会自动安装 nfs-common、rpcbind 等12个软件包
   4 sudo apt install nfs-common
   ```

2. 查看NFS服务器上的共享目录

   ```shell
   # 显示指定的（hcg-bg-as-01）NFS服务器上export出来的目录
   # hcg-bg-as-01为服务端主机名或IP地址
   $ sudo showmount -e hcg-bg-as-01
   ```

3. 创建本地挂载目录

   ```shell
   $ sudo mkdir -p /data/use
   ```

4. 挂载共享目录

   ```shell
   # 将NFS服务器192.168.3.167上的目录，挂载到本地的/data/use/目录下
   $ mount -t nfs hcg-bg-as-01:/data/use /data/use
   $ mount -t nfs -o sync,noac hcg-nfs-01:/data/freeswitch /data/freeswitch
   ```

5. 自动挂载

   ```shell
   $ cat /etc/fstab
   hcg-nfs-01:/data/freeswitch /data/freeswitch nfs defaults 0 0
   hcg-nfs-01:/data/freeswitch /data/freeswitch nfs sync,noac 0 0
   ```

   

## 附录

- 注：在没有安装`nfs-common`或者`nfs-kernel-server`软件包的机器上，直接执行`showmount`、`exportfs`、`nfsstat`、`rpcinfo`等命令时，系统会给出友好的提示，比如直接`showmount`会提示需要执行`sudo apt install nfs-common`命令，比如直接`rpcinfo`会提示需要执行`sudo apt install rpcbind`命令。

- NFS常用参数

  `ro` ：只读访问
  `rw` ：读写访问
  `sync`：所有数据在请求时写入共享
  `async`：nfs在写入数据前可以响应请求
  `secure`：nfs通过1024以下的安全TCP/IP端口发送
  `insecure`：nfs通过1024以上的端口发送
  `wdelay`：如果多个用户要写入nfs目录，则归组写入（默认）
  `no_wdelay`：如果多个用户要写入nfs目录，则立即写入，当使用async时，无需此设置
  `hide`：在nfs共享目录中不共享其子目录
  `no_hide`：共享nfs目录的子目录
  `subtree_check`：如果共享/usr/bin之类的子目录时，强制nfs检查父目录的权限（默认）
  `no_subtree_check`：和上面相对，不检查父目录权限
  `all_squash：`文件的UID和GID映射匿名用户anonymous，适合公用目录。
  `no_all_squash`：保留共享文件的UID和GID（默认）
  `root_squash`：root用户的所有请求映射成如anonymous用户一样的权限（默认）
  `no_root_squash`：root用户具有根目录的完全管理访问权限
  `anonuid=xxx`：指定nfs服务器/etc/passwd文件中匿名用户的UID
  `anongid=xxx`：指定nfs服务器/etc/passwd文件中匿名用户的GID

