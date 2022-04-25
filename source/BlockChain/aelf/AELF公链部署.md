# AELF 公链

## AELF 主网主链

### 区块链数据

1. 从头开始同步

   使用docker启动方式不需要执行此步骤，使用二进制或者编译方式运行，需要替换以下文件。

   ```shell
   $ wget https://github.com/AElfProject/AElf/releases/download/v1.1.0/genesis-contract-dlls.zip
   $ unzip genesis-contract-dlls.zip
   ```

2. 导入数据快照方式

   ```shell
   $ mkdir snapshot && cd snapshot
   # 获取快照下载脚本
   $ curl -O -s https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/download-mainchain-db.sh
   # 执行脚本时，您可以通过附加“yyyymmdd”作为参数来指定日期
   $ sh download-mainchain-db.sh
   # 链数据库:解压并加载链数据库快照
   $ tar -zxf aelf-mainnet-mainchain-chaindb-*.tar.gz
   ### 需要先停止ssdb链数据库服务
   $ /opt/ssdb-chain/ssdb-server -d /opt/ssdb-chain/ssdb.conf -s stop
   $ cp -r aelf-mainnet-mainchain-chaindb-*/* /path/to/install/chaindb/ssdb/var/
   ### 启动链数据库实例
   $ /opt/ssdb-chain/ssdb-server -d /opt/ssdb-chain/ssdb.conf -s start
   >> enter ssdb console (ssdb-cli) use the "info" command to confirm that the data has been imported)
   
   # 状态数据库:解压并加载状态数据库
   $ tar -zxf aelf-mainnet-mainchain-statedb-*.tar.gz
   ### 停止ssdb状态数据库服务
   $ /opt/ssdb-state/ssdb-server -d /opt/ssdb-state/ssdb.conf -s stop
   $ cp -r aelf-mainnet-mainchain-statedb-*/* /path/to/install/statedb/ssdb/var/
   ### 启动ssdb状态数据库服务
   $ /opt/ssdb-state/ssdb-server -d /opt/ssdb-state/ssdb.conf -s start
   >> enter ssdb console (ssdb-cli) use the "info" command to confirm that the data has been imported)
   ```

   

### 节点配置

1. 生成节点账户

   需要安装 aelf-command npm 包

   ```shell
   $ npm i -g aelf-command
   ```

2. 创建账户信息

   ```shell
   $ aelf-command create
   ```

   命令提示输入密码，输入密码，不要忘记。命令的输出应如下所示：

   ```tex
   AElf [Info]: Your wallet info is : 
   AElf [Info]: Mnemonic            : village green school sort day agent sound hobby prize velvet eyebrow quality 
   AElf [Info]: Private Key         : 41a7f83f352217b35368f79593614e294e0a909b8a2f5001be442e80663ba3f2 
   AElf [Info]: Public Key          : 04f25002f99da4bfc074f28be66702cdccfd40d53c132b3a0b3b70acc49bc7717a3dc783b080c52b6130746008e286a8da03d6d7c125dd1981b852a90dc41384b4 
   AElf [Info]: Address             : 2GXoWWs6a8REyPACkHLSRMTGXvzbdLLB3poKMGUnZUEGmU5tgF 
   ? Save account info into a file? Yes
   ? Enter a password: **********
   ? Confirm password: **********
   ✔ Account info has been saved to "/root/.local/share/aelf/keys/2GXoWWs6a8REyPACkHLSRMTGXvzbdLLB3poKMGUnZUEGmU5tgF.json"
   ```

3. 下载节点配置

   ```shell
   $ cd /tmp/ && wget https://github.com/AElfProject/AElf/releases/download/v1.0.0/aelf-mainnet-mainchain.zip
   $ unzip aelf-mainnet-mainchain.zip
   $ mv aelf-mainnet-mainchain /opt/aelf-node
   ```

4. 拷贝账户文件

   ```shell
   $ cp -a /root/.local/share/aelf/keys/2GXoWWs6a8REyPACkHLSRMTGXvzbdLLB3poKMGUnZUEGmU5tgF.json /opt/aelf-node/keys
   ```

5. 修改 `appsetting.json` 配置文件

   ```json
   // 关联的帐户/密钥对
   {
     "Account": {
       "NodeAccount": "2GXoWWs6a8REyPACkHLSRMTGXvzbdLLB3poKMGUnZUEGmU5tgF",
       "NodeAccountPassword": "Aelf123456"
     },
   }
   
   // 配置数据库连接字符串（端口/数据库号）
   {
     "ConnectionStrings": {
       "BlockchainDb": "redis://192.168.66.65:8888",
       "StateDb": "redis://192.168.66.65:9999"
     },
   }
   
   // 将主网主链节点添加为对等节点（引导节点对等节点）
   {
     "Network": {
       "EnablePeerDiscovery": false,
       "BootNodes": [
         "18.185.93.36:6801"
       ],
       "ListeningPort": 6801
     },
   }
   ```

6. 配置文件 `appsettings.MainChain.MainNet.json`

   设置为侧链连接配置监听 ip 和端口

   ```json
   {
       "CrossChain": {
           "Grpc": {
               "ListeningPort": 5001
           }
       }
   }
   ```

7. 注意：如果您的基础设施在防火墙后面，您需要打开节点的 P2P 侦听端口（6801）。

### 运行节点

1. 使用 Docker 运行完整节点，

   ```shell
   $ docker pull aelf/node:mainnet-v1.1.0
   $ cd /opt/aelf-node
   # 启动服务
   $ sh aelf-node.sh start aelf/node:mainnet-v1.0.0
   
   # 停止服务
   $ sh aelf-node.sh stop
   ```

2. 使用二进制版本运行完整节点

   大多数 AElf 是使用 dotnet core 开发的，因此要运行二进制文件，您需要在开始之前下载并安装 .NET Core SDK： [下载 .NET Core 3.1](https://dotnet.microsoft.com/download/dotnet-core/3.1)。目前 AElf 依赖于 SDK 的 3.1 版，在提供的链接上找到适用于您平台的下载并安装它。

   使用以下命令获取最新版本：

   ```shell
   $ cd /tmp/ && wget https://github.com/AElfProject/AElf/releases/download/v1.0.0/aelf.zip
   $ unzip aelf.zip
   $ mv aelf /opt/aelf-node/
   ```

   进入配置文件夹并运行节点：

   ```shell
   $ cd /opt/aelf-node
   $ dotnet aelf/AElf.Launcher.dll
   ```

3. 使用源运行完整节点

   最方便的方法是直接使用 docker 或二进制包，但如果您愿意，也可以从源代码编译。首先确保代码版本一致（当前版本为 AELF v1.0.0），其次确保在 Ubuntu Linux 机器上编译（我们推荐 Ubuntu 18.04.2 LTS）并安装 dotnet core SDK 3.1 版。这是因为不同的平台或编译器会导致 dll 哈希与当前链不一致。

### 检查节点

您现在应该有一个正在运行的节点，要检查该节点，请运行以下命令，该命令将查询该节点的当前块高度：

```shell
$ aelf-command get-blk-height -e http://your node ip address:port
```



## AELF 主网侧链

### 运行侧链

运行侧链与运行主链节点非常相似，只是配置会发生变化。在这里您可以找到 sidechain1 的说明：

```shell
$ cd /tmp/ && wget https://github.com/AElfProject/AElf/releases/download/v1.0.0/aelf-mainnet-sidechain1.zip
$ unzip aelf-mainnet-sidechain1.zip
$ mv aelf-mainnet-sidechain1 /opt/aelf-node
```

为了让侧链连接到主链节点，您需要`appsettings.SideChain.MainNet.json`使用您的节点信息修改。

```json
{
  "CrossChain": {
    "Grpc": {
      "ParentChainServerPort": 5001,
      "ListeningPort": 5011,
      "ParentChainServerIp": "192.168.66.65"
    },
    "ParentChainId": "AELF",
    "Economic": {
      "SymbolListToPayTxFee": "WRITE,READ,STORAGE,TRAFFIC",
      "SymbolListToPayRental": "CPU,RAM,DISK,NET"
    }
  }
}
```

在这里您可以找到当前唯一运行的侧链的快照数据，您可以选择指定日期，但我们建议您获取最新的：

```shell
$ curl -O -s https://aelf-backup.s3.ap-northeast-2.amazonaws.com/snapshot/mainnet/download-sidechain-db.sh 
```

在这里您可以找到侧链的模板文件夹列表（appsettings 和 docker run 脚本）：

```shell
$ wget https://github.com/AElfProject/AElf/releases/download/v1.0.0/aelf-mainnet-sidechain1.zip
```

在**appsettings.json 中**更改以下配置部分：

每个侧链都有自己的P2P网络，添加主网侧链节点作为peer：

```json
{
  "ConnectionStrings": {
    "BlockchainDb": "redis://192.168.66.65:8888",
    "StateDb": "redis://192.168.66.65:9999"
  },
  "Account": {
    "NodeAccount": "2GXoWWs6a8REyPACkHLSRMTGXvzbdLLB3poKMGUnZUEGmU5tgF",
    "NodeAccountPassword": "Aelf123456"
  },
  "Network": {
    "EnablePeerDiscovery": false,
    "BootNodes": [
      "3.126.255.181:6801"
    ],
    "ListeningPort": 6801
  },
}
```