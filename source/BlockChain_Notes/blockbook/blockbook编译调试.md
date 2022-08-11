[TOC]

## blockbook

### 服务器配置

1. Centos7.8

### 依赖

1. golang 1.4.2

   ```bash
   wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.tz && tar xf go1.14.2.linux-amd64.tar.gz
   sudo mv go /opt/go
   sudo ln -s /opt/go/bin/go /usr/bin/go
   # see `go help gopath` for details
   mkdir $HOME/go
   export GOPATH=$HOME/go
   export PATH=$PATH:$GOPATH/bin
   ```

2. RocksDB

   ```bash
   sudo apt-get install pkg-config cmake gcc g++ libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev 
   # 安装RocksDB
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb
   CFLAGS=-fPIC CXXFLAGS=-fPIC make release
   make install 
   
   # 设置golang代理
   export GOPROXY=https://goproxy.cn
   
   # 安装gorocksdb
   CGO_CFLAGS="-I/usr/local/include/rocksdb/include" \
   CGO_LDFLAGS="-L/usr/local/lib -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy -llz4 -lzstd" \
     go get github.com/tecbot/gorocksdb
     
   
   ```

   

3. ZeroMq

   ```bash
   echo 'deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/network:messaging:zeromq:release-stable.list
   sudo wget -nv https://download.opensuse.org/repositories/network:messaging:zeromq:release-stable/Debian_10/Release.key -O "/etc/apt/trusted.gpg.d/network:messaging:zeromq:release-stable.asc"
   sudo apt update
   sudo apt install libzmq3-dev
   ```

### 编译安装

1. 编译

   ```bash
   cd $GOPATH/src
   git clone https://github.com/trezor/blockbook.git
   cd blockbook
   # 编译对应的
   CGO_CFLAGS="-I/usr/local/include/rocksdb/include" \
   CGO_LDFLAGS="-L/usr/local/lib -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy -llz4 -lzstd -ldl" \
   go build
   ```

2. TODO：增加测试网、主网的BTC、ETH的启动脚本生成，注意ETH的测试网需要修改部分代码以及增加一个对应的测试网基础配置文件

### 运行问题记录
1.正常通过systemctl关闭blockbook服务后, 隔段时间后重新启动服务，rocksdb报错: blockbook.go:210] internalState: database is in inconsistent state and cannot be used
解决过程记录:
参考blockbook官方两个issue建议：
https://github.com/trezor/blockbook/issues/89
https://github.com/trezor/blockbook/issues/147
启用单线程工作模式, 否则需要每个blockbook服务实例占用30G内存的方式才能解决:
systemctl stop blockbook-bitcoin-testnet
rm -rf /opt/coins/data/bitcoin_testnet/blockbook/db
vim /lib/systemd/system/blockbook-bitcoin-testnet.service
在启动参数中增加`-workers=1`参数, 并启动blockbook服务
systemctl start blockbook-bitcoin-testnet

2.自测时不启用自签名证书，去掉启动参数中的`-certfile=/opt/coins/blockbook/ethereum/cert/blockbook`项，即可使用http访问restapi接口

