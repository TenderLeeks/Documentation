[TOC]

## blockbook

### 服务器配置

1. Debain10.4

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

2. 安装

   ```bash
   sudo chown -R jason.jason /opt/
   mkdir -p /opt/chain/blockbook/bin
   cp -r ./blockbook /opt/chain/blockbook/bin
   sudo ln -sf /opt/chain/blockbook/bin/blockbook /usr/local/bin/blockbook 
   ```

### BTC测试节点搭建

1. 生成测试配置文件

   ```bash
   mkdir -p /opt/chain/blockbook/config
   contrib/scripts/build-blockchaincfg.sh bitcoin_testnet
   cp build/blockchaincfg.json /opt/chain/blockbook/config/bitcoin_testnet.json
   ```

   

2. 修改测试文件

   ````bash
   vim /opt/chain/blockbook/config/bitcoin_testnet.json
   ````

   

3. 

1. TODO：增加测试网、主网的BTC、ETH的启动脚本生成，注意ETH的测试网需要修改部分代码以及增加一个对应的测试网基础配置文件
2. 




