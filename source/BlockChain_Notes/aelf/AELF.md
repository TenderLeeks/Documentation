# AELF 公链节点管理

依赖环境安装

```shell
$ sudo apt-get update
$ sudo apt install -y git-all unzip make autoconf build-essential docker.io
```

## 部署SSDB服务

1. 下载和编译安装ssdb数据库

   ```shell
   $ wget --no-check-certificate https://github.com/ideawu/ssdb/archive/master.zip -P /tmp
   $ cd /tmp && unzip master.zip && cd ssdb-master
   $ make && sudo make install
   ```

2. 配置ssdb

   ```shell
   $ mkdir -p /opt/{ssdb8881/var,ssdb8882/var}
   
   $ cp -a /usr/local/ssdb/ssdb.conf /opt/ssdb8881/ssdb.conf \
   && sed -i "s#ip: 127.0.0.1#ip: 0.0.0.0#g" /opt/ssdb8881/ssdb.conf \
   && sed -i "s#port: 8888#port: 8881#g" /opt/ssdb8881/ssdb.conf \
   && sed -i "s#level: debug#level: error#g" /opt/ssdb8881/ssdb.conf
   
   $ cp -a /usr/local/ssdb/ssdb.conf /opt/ssdb8882/ssdb.conf \
   && sed -i "s#ip: 127.0.0.1#ip: 0.0.0.0#g" /opt/ssdb8882/ssdb.conf \
   && sed -i "s#port: 8888#port: 8882#g" /opt/ssdb8882/ssdb.conf \
   && sed -i "s#level: debug#level: error#g" /opt/ssdb8882/ssdb.conf
   ```

3. 创建服务启动脚本

   ```shell
   # ssdb8881
   $ tee /opt/ssdb8881/ssdb.sh <<-'EOF'
   #!/bin/bash
   
   ssdb_bin=/usr/local/ssdb/ssdb-server
   config=/opt/ssdb8881/ssdb.conf
   
   start() {
     $ssdb_bin ${config} -s restart -d
   }
   
   stop() {
     $ssdb_bin ${config} -s stop -d
   }
   
   case "$1" in
     start)
       start
       ;;
     stop)
       stop
       ;;
     restart)
       stop
       start
       ;;
     *)
       echo $"Usage: $0 {start|stop|restart}"
       ;;
   esac
   exit $RETVAL
   EOF
   
   # ssdb8882
   $ tee /opt/ssdb8882/ssdb.sh <<-'EOF'
   #!/bin/bash
   
   ssdb_bin=/usr/local/ssdb/ssdb-server
   config=/opt/ssdb8882/ssdb.conf
   
   start() {
     $ssdb_bin ${config} -s restart -d
   }
   
   stop() {
     $ssdb_bin ${config} -s stop -d
   }
   
   case "$1" in
     start)
       start
       ;;
     stop)
       stop
       ;;
     restart)
       stop
       start
       ;;
     *)
       echo $"Usage: $0 {start|stop|restart}"
       ;;
   esac
   exit $RETVAL
   EOF
   
   $ chmod +x /opt/ssdb8881/ssdb.sh /opt/ssdb8882/ssdb.sh
   ```

4. 管理服务

   ```shell
   # 启动服务
   $ /opt/ssdb8881/ssdb.sh start
   $ /opt/ssdb8882/ssdb.sh start
   
   # 重启服务
   $ /opt/ssdb8881/ssdb.sh restart
   $ /opt/ssdb8882/ssdb.sh restart
   
   # 停止服务
   $ /opt/ssdb8881/ssdb.sh stop
   $ /opt/ssdb8882/ssdb.sh stop
   ```
   
4. 服务自启动配置

   ```bash
   $ tee /etc/systemd/system/ssdb-8881.service <<EOF
   [Unit]
   Description=ssdb-server
   After=network.target
   
   [Service]
   Type=forking
   ExecStart=/opt/ssdb8881/ssdb-server /opt/ssdb8881/ssdb.conf -s restart -d
   PrivateTmp=true
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   $ tee /etc/systemd/system/ssdb-8882.service <<EOF
   [Unit]
   Description=ssdb-server
   After=network.target
   
   [Service]
   Type=forking
   ExecStart=/opt/ssdb8882/ssdb-server /opt/ssdb8882/ssdb.conf -s restart -d
   PrivateTmp=true
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   
   $ systemctl daemon-reload
   $ systemctl enable ssdb-8881.service
   $ systemctl enable ssdb-8882.service
   ```
   
   

## 部署主网主链服务

### 修改节点配置

1. 安装命令`aelf-command`

   安装node环境请参照[文档](https://www.leeks.info/zh_CN/latest/Linux_Notes/env/linux-env.html#node)

   ```shell
   $ npm i -g aelf-command
   ```

2. 创建主网账户地址

   ```shell
   $ aelf-command create
   # 命令提示输入密码，输入密码，不要忘记。命令的输出应如下所示：
   AElf [Info]: Your wallet info is : 
   AElf [Info]: Mnemonic            : joy flee ignore purpose easily among zebra rain unlock dragon smoke pride 
   AElf [Info]: Private Key         : 876c3fbf2df702095deae7eefbaf94bba7258db2d468f335c9698e2ea4e501f6 
   AElf [Info]: Public Key          : 04807bd8dcb69179376c1a025c4359eb118215e4d66dd3f5d8255941c166c35d8d9817cbee1c5d7ef1b6cee5309f2f625261d77bd89060efc5b23766de2820f56a 
   AElf [Info]: Address             : N9PeS5pCJDwncm4AmZgrd3LY1GB9gCKRLPLp6LSb11eyvaT6y 
   ? Save account info into a file? Yes
   ? Enter a password: ********
   ? Confirm password: ********
   ✔ Account info has been saved to "/root/.local/share/aelf/keys/N9PeS5pCJDwncm4AmZgrd3LY1GB9gCKRLPLp6LSb11eyvaT6y.json"
   ```

3. 下载主网节点配置文件

   ```shell
   $ AELF_VERSION="v1.2.0"
   $ wget https://github.com/AElfProject/AElf/releases/download/${AELF_VERSION}/aelf-mainnet-mainchain.zip -P /tmp
   
   $ cd /tmp && unzip aelf-mainnet-mainchain.zip -d /opt
   $ mv /opt/aelf-mainnet-mainchain /opt/aelf-node
   ```

4. 拷贝账户文件

   ```shell
   $ mkdir -p /opt/aelf-node/keys
   $ cp -a /root/.local/share/aelf/keys/*.json /opt/aelf-node/keys
   ```

5. 修改`appsetting.json` 配置文件

   ```shell
   # 配置文件优先级 
   # 此处填写的账号密码为上面创建主网账号时填写的信息
   $ sed -i 's#"NodeAccount": ""#"NodeAccount": "w38rsUfGxf4e8qvqYjZPFLSfsTYLXfx3k8qzY27QBMLAydffG"#g' /opt/aelf-node/appsettings.json
   $ sed -i 's#"NodeAccountPassword": ""#"NodeAccountPassword": "12345678"#g' /opt/aelf-node/appsettings.json
   
   $ sed -i 's#"BlockchainDb": ""#"BlockchainDb": "redis://192.168.67.158:8881"#g' /opt/aelf-node/appsettings.json
   $ sed -i 's#"StateDb": ""#"StateDb": "redis://192.168.67.158:8882"#g' /opt/aelf-node/appsettings.json
   ```

   注意：如果您的基础设施在防火墙后面，您需要打开节点的 P2P 侦听端口`6801`

   **注意：配置文件优先级 `appsettings.Development.json > appsettings.Production.json > appsettings.json`，如果目录中存在 `appsettings.Production.json`和`appsettings.Production.json`文件，此时会覆盖`appsettings.json`配置文件内容。**

6. `appsettings.MainChain.MainNet.json` 配置文件

   `CrossChain.Grpc.ListeningPort: 50001` 此端口为侧链连接的端口

   ```json
   {
     "Economic": {
           "Symbol": "ELF",
           "TokenName": "Native Token",
           "TotalSupply": 100000000000000000,
           "Decimals": 8,
           "IsBurnable": true,
           "DividendPoolRatio": 0.12,
           "MinimumLockTime": 7776000,
           "MaximumLockTime": 93312000,
           "SymbolListToPayTxFee": "WRITE,READ,STORAGE,TRAFFIC",
           "SymbolListToPayRental": "CPU,RAM,DISK,NET"
       },
       "CrossChain": {
           "Grpc": {
               "ListeningPort": 5001
           }
       }
   }
   ```

### 启动主网主链服务

使用docker运行完整节点

```shell
$ docker pull aelf/node:mainnet-${AELF_VERSION}
$ cd /opt/aelf-node
# 启动服务
$ sh aelf-node.sh start aelf/node:mainnet-${AELF_VERSION}

# 停止服务
$ sh aelf-node.sh stop
```

查看节点数据状态

```shell
$ curl http://127.0.0.1:8000/api/blockchain/chainStatus
{"ChainId":"AELF","Branches":{"73b6d1064013c0b34e6b4783d04a7c550863c95bd78e9b372fe8372577e290e8":1},"NotLinkedBlocks":{},"LongestChainHeight":1,"LongestChainHash":"73b6d1064013c0b34e6b4783d04a7c550863c95bd78e9b372fe8372577e290e8","GenesisBlockHash":"73b6d1064013c0b34e6b4783d04a7c550863c95bd78e9b372fe8372577e290e8","GenesisContractAddress":"pykr77ft9UUKJZLVq15wCH8PinBSjVRQ12sD1Ayq92mKFsJ1i","LastIrreversibleBlockHash":"73b6d1064013c0b34e6b4783d04a7c550863c95bd78e9b372fe8372577e290e8","LastIrreversibleBlockHeight":1,"BestChainHash":"73b6d1064013c0b34e6b4783d04a7c550863c95bd78e9b372fe8372577e290e8","BestChainHeight":1}
```

`LastIrreversibleBlockHeight` 为节点数据块高度，如果发现高度不增长，请停止节点服务，然后删除ssdb中数据后重启ssdb和节点服务。或者查看本机系统6801端口是否打开防火墙对外开放。

检查节点高度命令

```shell
$ aelf-command get-blk-height -e http://127.0.0.1:8000

$ curl http://127.0.0.1:8000/api/blockChain/blockHeight
```

### 使用快照数据启动

停止节点服务和ssdb服务

```shell
$ docker stop aelf-node
$ /opt/ssdb8881/ssdb.sh stop
$ /opt/ssdb8882/ssdb.sh stop
```

删除ssdb数据文件

```shell
$ rm -rf /opt/ssdb8881/var/*
$ rm -rf /opt/ssdb8882/var/*
```

下载快照数据文件

```shell
# 快照压缩包大小约为200G，解压后文件大小约为350G
$ cd /tmp
# 可以通过附加 yyyymmdd 作为参数来下载指定日期的快照文件
$ bash <(curl -s "https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/download-mainchain-db.sh")

$ tar -zxf aelf-mainnet-mainchain-chaindb-20220424.tar.gz  # 链数据文件
$ tar -zxf aelf-mainnet-mainchain-statedb-20220424.tar.gz  # 状态数据文件

# 下载并解压
$ wget https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/aelf-mainnet-mainchain-chaindb-20220424.tar.gz -O - | tar -zxf - &
$ wget https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/aelf-mainnet-mainchain-statedb-20220424.tar.gz -O - | tar -zxf - &

$ mv aelf-mainnet-mainchain-chaindb-20220424/* /opt/ssdb8881/var/
$ mv aelf-mainnet-mainchain-statedb-20220424/* /opt/ssdb8882/var/

# 启动ssdb服务
$ /opt/ssdb8881/ssdb.sh start
$ /opt/ssdb8882/ssdb.sh start

# 启动节点服务
$ docker start aelf-node
```



## 部署主网侧链服务

安装SSDB服务请参照[此链接]()部署

### 下载数据快照文件

```shell
$ bash <(curl -s "https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/download-sidechain-db.sh")

$ tar -zxf aelf-mainnet-sidechain-chaindb-20220424.tar.gz  # 链数据文件
$ tar -zxf aelf-mainnet-sidechain-statedb-20220424.tar.gz  # 状态数据文件

# 下载并解压
$ wget https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/aelf-mainnet-sidechain-chaindb-20220424.tar.gz -O - | tar -zxf - &
$ wget https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/aelf-mainnet-sidechain-statedb-20220424.tar.gz -O - | tar -zxf - &

$ mv aelf-mainnet-sidechain-chaindb-20220424/* /opt/ssdb8881/var/
$ mv aelf-mainnet-sidechain-statedb-20220424/* /opt/ssdb8882/var/

# 启动ssdb服务
$ /opt/ssdb8881/ssdb.sh start
$ /opt/ssdb8882/ssdb.sh start
```

### 修改节点配置

```shell
$ AELF_VERSION="v1.2.0"

$ wget https://github.com/AElfProject/AElf/releases/download/${AELF_VERSION}/aelf-mainnet-sidechain1.zip -P /tmp
$ cd /tmp && unzip aelf-mainnet-sidechain1.zip -d /opt
$ mv /opt/aelf-mainnet-sidechain1 /opt/aelf-node
```

为了让侧链连接到主链节点，您需要`appsettings.SideChain.MainNet.json`使用您的节点信息修改。

```shell
# "ParentChainServerIp": "" 需要填写主链服务IP地址
$ sed -i 's#"ParentChainServerIp": ""#"ParentChainServerIp": "192.168.67.158"#g' /opt/aelf-node/appsettings.SideChain.MainNet.json
```

修改后的文件内容如下：

```json
{
  "CrossChain": {
    "Grpc": {
      "ParentChainServerPort": 5001,
      "ListeningPort": 5011,
      "ParentChainServerIp": "192.168.67.38"
    },
    "ParentChainId": "AELF",
    "Economic": {
      "SymbolListToPayTxFee": "WRITE,READ,STORAGE,TRAFFIC",
      "SymbolListToPayRental": "CPU,RAM,DISK,NET"
    }
  }
}
```

配置文件`appsettings.json`修改信息，需要注意的是此节点的6801端口也需要对`18.134.154.80`IP开发。

```shell
$ sed -i 's#"NodeAccount": ""#"NodeAccount": "gUwmgYse4EHfAXxh78HrTaXzUXXNng5bP3E5Qn4z2t3gRkCxf"#g' /opt/aelf-node/appsettings.json

$ sed -i 's#"NodeAccountPassword": ""#"NodeAccountPassword": "12345678"#g' /opt/aelf-node/appsettings.json

$ sed -i 's#"BlockchainDb": ""#"BlockchainDb": "redis://192.168.67.21:8881"#g' /opt/aelf-node/appsettings.json

$ sed -i 's#"StateDb": ""#"StateDb": "redis://192.168.67.21:8882"#g' /opt/aelf-node/appsettings.json

$ sed -i 's#"BootNodes": \[\]#"BootNodes": \["18.134.154.80:6801"\]#g' /opt/aelf-node/appsettings.json

# 此处账号密码配置需要自定义即可
$ sed -i 's#"UserName" : ""#"UserName" : "aelf2022"#g' /opt/aelf-node/appsettings.json
$ sed -i 's#"Password": ""#"Password": "66666666"#g' /opt/aelf-node/appsettings.json
```

修改后的文件内容如下：

```json
{
  "ChainId": "tDVV",
  "ChainType": "SideChain",
  "NetType": "MainNet",
  "CorsOrigins": "*",
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "BlockchainDb": "redis://192.168.67.39:8881",
    "StateDb": "redis://192.168.67.39:8882"
  },
  "Account": {
    "NodeAccount": "gUwmgYse4EHfAXxh78HrTaXzUXXNng5bP3E5Qn4z2t3gRkCxf",
    "NodeAccountPassword": "aelf2022"
  },
  "Network": {
    "EnablePeerDiscovery": false,
    "BootNodes": ["18.134.154.80:6801"],
    "ListeningPort": 6801
  },
  "Kestrel": {
    "EndPoints": {
      "Http": {
        "Url": "http://0.0.0.0:8000"
      }
    }
  },
  "Consensus": {
    "InitialMinerList": [],
    "MiningInterval": 4000,
    "PeriodSeconds": 604800
  },
  "DeployServiceUrl": "",
  "BasicAuth": {
    "UserName" : "aelf2022",
    "Password": "66666666"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Trace"
    }
  }
}
```

### 启动主网侧链服务

```shell
$ mkdir -p /opt/aelf-node/keys
# 把主链配置账号的json文件复制到keys中
$ cp -a /root/.local/share/aelf/keys/gUwmgYse4EHfAXxh78HrTaXzUXXNng5bP3E5Qn4z2t3gRkCxf.json /opt/aelf-node/keys

# 拉取主网侧链镜像
$ docker pull aelf/node:mainnet-${AELF_VERSION}

# 启动节点服务
$ sh aelf-node.sh start aelf/node:mainnet-${AELF_VERSION}
```

