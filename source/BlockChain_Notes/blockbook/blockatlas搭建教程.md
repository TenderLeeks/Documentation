[TOC]

## blockbook

### 服务器配置

1. Centos7.8

### 依赖

#### docker(可选)

1. 卸载旧版本的docker

   ```bash
   sudo yum remove docker \
                     docker-client \
                     docker-client-latest \
                     docker-common \
                     docker-latest \
                     docker-latest-logrotate \
                     docker-logrotate \
                     docker-engine
   ```

2. 安装`yum-utils`软件包（提供`yum-config-manager` 实用程序）并设置**稳定的**存储库。

   ```bash
   sudo yum install -y yum-utils
   sudo yum-config-manager \
       --add-repo \
       https://download.docker.com/linux/centos/docker-ce.repo
   ```

3. 安装*最新版本*的Docker Engine和容器，或者转到下一步安装特定版本：

   ```bash
   sudo yum install docker-ce docker-ce-cli containerd.io
   ```

   

4. 添加`docker`用户组,将登入用户添加到docker用户组中

   ```bash
   sudo groupadd docker
   sudo gpasswd -a $USER docker
   # 更新用户组
   newgrp docker
   # 测试docker命令是否正常运行
   docker ps
   ```

5. 启动Docker。

   ```bash
   sudo systemctl start docker
   ```

6. 通过运行`hello-world` 映像来验证是否正确安装了Docker Engine 。

   ```bash
   docker run hello-world
   ```

#### golang

1. 安装golang环境

   ```bash
   wget https://golang.org/dl/go1.14.2.linux-amd64.tar.gz && tar xf go1.14.2.lin	ux-amd64.tar.gz
   
   sudo mv go /opt/go
   sudo ln -s /opt/go/bin/go /usr/bin/go
   # see `go help gopath` for details
   mkdir $HOME/go
   export GOPATH=$HOME/go
   export PATH=$PATH:$GOPATH/bin
   ```

   

2. RocksDB

   ```bash
   # Upgrade your gcc to version at least 4.8 to get C++11 support: 
       sudo yum install gcc-c++ 
       sudo yum install git
       
   # Install gflags:
       git clone https://github.com/gflags/gflags.git
       cd gflags
       git checkout v2.0
       ./configure && make && sudo make install
       export CPATH=$CPATH:/usr/local/include
       export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib
       
       
   # Install snappy:
       sudo yum install snappy snappy-devel
   # Install zlib:
       sudo yum install zlib zlib-devel
   # Install bzip2:
       sudo yum install bzip2 bzip2-devel
   # Install lz4:
       sudo yum install lz4-devel
   # Install libzstd:
       sudo yum install libzstd-devel
   # Install ASAN (optional for debugging):
       sudo yum install libasan
   # Install zstandard:
      wget https://github.com/facebook/zstd/archive/v1.1.3.tar.gz
      mv v1.1.3.tar.gz zstd-1.1.3.tar.gz
      tar zxvf zstd-1.1.3.tar.gz
      cd zstd-1.1.3
      make && sudo make install 
   # Install RocksDB
      cd ~
      git clone https://github.com/facebook/rocksdb.git
      cd rocksdb
      CFLAGS=-fPIC CXXFLAGS=-fPIC make release
      sudo make install
      
   # gorocksdb的设置变量：https : //github.com/tecbot/gorocksdb
      export CGO_CFLAGS="-I/usr/local/include/rocksdb/include" \
      export CGO_LDFLAGS="-L/usr/local/lib -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy -llz4 -lzstd"
     go get github.com/tecbot/gorocksdb
   ```
# 设置golang代理
export GOPROXY=https://goproxy.cn
3. ZeroMQ

   ```bash
   cd /etc/yum.repos.d/
   sudo wget https://download.opensuse.org/repositories/network:messaging:zeromq:release-stable/CentOS_7/network:messaging:zeromq:release-stable.repo
   sudo yum install epel-release # 安装企业版源
   sudo yum install zeromq-devel
   ```

### 编译

1. 下载源码并执行编译

   ```bash
   mkdir $GOPATH/src
   cd $GOPATH/src
   git clone https://github.com/trezor/blockbook
   cd blockbook
   git checkout v0.3.4
   
   CGO_CFLAGS="-I/usr/local/include/rocksdb/include" \
   CGO_LDFLAGS="-L/usr/local/lib -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy -llz4 -lzstd -ldl" 
   go build
   ```

   

2. 安装

   ```bash
   sudo chown -R jason.jason /opt/
   mkdir -p /opt/blockbook/bin
   cp -r ./blockbook /opt/blockbook/bin
   cp -r static /opt/blockbook/ethereum/
   sudo ln -sf /opt/blockbook/bin/blockbook /usr/local/bin/blockbook 
   ```

### ETH节点搭建

1. 生成配置文件

   ```bash
   mkdir -p /opt/blockbook/config
   # 生成配置文件
   contrib/scripts/build-blockchaincfg.sh ethereum
   
   cp build/blockchaincfg.json /opt/blockbook/config/ethereum.json
   ```

   

2. 修改测试文件

   ````bash
   vim /opt/blockbook/config/ethereum.json
   # 修改rpc节点地址
   ````

3. 启动

   ```bash
   #-public 前台页面路径 [address]:port[/path] 
   #-datadir 数据存储路径

   /opt/blockbook/ethereum/bin/blockbook -sync -blockchaincfg=/opt/blockbook/ethereum/config/ethereum.json -datadir=/opt/blockbook/ethereum/data/ -debug=true -internal=:9036 -public=:9136 -logtostderr
   # 非debug调试模式
   blockbook -sync -blockchaincfg=/opt/blockbook/config/ethereum.json -datadir=/opt/blockbook/data/ -debug=true -internal=:9036 -public=:9136/opt/blockbook -logtostderr 
   ```
#Ethereum
blockbook -sync -blockchaincfg=/opt/blockbook/ethereum/config/ethereum.json -datadir=/opt/blockbook/ethereum/data/ -debug=true -internal=:9036 -public=:9136/opt/blockbook/ethereum -logtostderr




#Bitcoin

cd /opt/go/src/blockbook

blockbook -sync -blockchaincfg=/opt/blockbook/bitcoin/config/bitcoin.json -datadir=/opt/blockbook/bitcoin/data/ -workers=1 -debug=true -internal=:9030 -public=:9130 -logtostderr 


./blockbook -sync -blockchaincfg=build/blockchaincfg.json -internal=:9030 -public=:9130 -certfile=server/testcert -logtostderr




## 附录1：RocksDB管理

## 附录2：BlockBook端口

| coin     | blockbook internal port | blockbook public port | backend rpc port | backend service ports (zmq) |
| -------- | ----------------------- | --------------------- | ---------------- | --------------------------- |
| Bitcoin  | 9030                    | 9130                  | 8030             | 38330                       |
| Ethereum | 9036                    | 9136                  | 8036             | 38336 p2p, 8136 http        |

