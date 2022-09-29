# Docker 环境配置

## 安装Docker

```shell
# 卸载老版本docker服务
$ sudo apt-get remove docker docker-engine docker.io -y

# 安装最新版本docker
# curl -sSL https://get.docker.com/ | sh 
$ curl -fsSL get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh

```

## 安装docker-compose

```shell
# 下载最新版的 docker-compose 文件
$ sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

# 若是github访问太慢，可以用daocloud下载
$ sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

# 添加可执行权限
$ sudo chmod +x /usr/local/bin/docker-compose

# 查看安装版本
$ docker-compose --version
```



## 更换docker源

```shell
$ vim /etc/docker/daemon.json
$ tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://1tpafwoy.mirror.aliyuncs.com"]
}
EOF

$ systemctl daemon-reload
$ systemctl restart docker
```



## 迁移 /var/lib/docker 目录

在使用docker时，往往会出现磁盘空间不足，导致该问题的通常原因是因为docker中部署的系统输出了大量的日志内容。

针对/var/lib/docker/overlay2空间占用很大网上提供了很多解决方案，其中有些误导的说法需要去迁移路径等操作。其实磁盘空间的占用和overlay没关系（它的usage和真实的disk usage相同），它只是一个docker的虚拟文件系统，真实的文件系统是前者/dev/vda1,可以看到路径所指为根目录，所以你要去找是哪里出现了垃圾。

```shell
# 命令查看磁盘使用情况。
$ du -sh /var/lib/docker

# 查看Docker的磁盘使用情况
$ docker system df

# 清理磁盘，删除关闭的容器、无用的数据卷和网络，以及dangling镜像(即无tag的镜像)。
$ docker system prune

# 清理得更加彻底，可以将没有容器使用Docker镜像都删掉。
# 注意，这两个命令会把你暂时关闭的容器，以及暂时没有用到的Docker镜像都删掉，使用之前一定要想清楚。
$ docker system prune -a

# 列出所有虚悬（dangling）镜像，也就是 TAG 为 <none> 的
$ docker images -f dangling=true
```

1. 查看docker默认目录的方法

   ```shell
   # docker默认目录为/var/lib/docker，可以通过下面的方法查看
   $ docker info |grep "Docker Root Dir"
    Docker Root Dir: /var/lib/docker
   ```

2. 停止docker服务并移动原有docker文件到新目录

   ```shell
   $ systemctl stop docker.socket
   $ systemctl stop docker.service
   $ mkdir -p /opt/docker/lib/
   $ cp -a /var/lib/docker /opt/docker/lib/
   ```

3. 修改文件 `/etc/docker/daemon.json` 配置

   ```shell
   $ tee /etc/docker/daemon.json <<-'EOF'
   {
     "data-root": "/opt/docker/lib/docker",
     "storage-driver": "overlay2",
     "log-level": "INFO",
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "5"
     }
   }
   EOF
   
   $ systemctl daemon-reload
   $ systemctl restart docker.service
   ```

   `data-root`：docker数据目录

   `storage-driver`：docker存储的类型

   `log-level`：docker日志记录级别

   `log-opts`：dockr驱动程序选项



 
