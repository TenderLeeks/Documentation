# 配置建议要求

## 全节点

- VPS 运行最新版本的 Mac OS X 或 Linux。
- **重要**1T GB 可用磁盘空间、固态硬盘 (SSD)、gp3、3k IOPS、125MB/S 吞吐量、读取延迟 <1 毫秒。（如果从快照/快速同步开始，它将需要 NVMe SSD）
- 8 核 CPU 和 32 GB 内存 (RAM)。
- 建议AWS上c5.4xlarge实例类型，谷歌云上c2-standard-8。
- 上传/下载速度为每秒 5 兆字节的宽带互联网连接

## 验证器

- VPS 运行最新版本的 Mac OS X 或 Linux。
- **重要**2T GB 可用磁盘空间、固态硬盘 (SSD)、gp3、8k IOPS、250MB/S 吞吐量、读取延迟 <1ms
- 12 核 CPU 和 48 GB 内存 (RAM)
- 建议在 AWS 上使用 m5zn.3xlarge 实例类型，或在 Google 云上使用 c2-standard-8。
- 上传/下载速度为每秒 10 兆字节的宽带互联网连接

# 使用快照同步

## 链数据快照

请下载链数据[快照](https://docs.binance.org/smart-chain/developer/snapshot)并解压到您的主文件夹以加快速度

```shell
# 下载前请替换最近的快照下载URL
$ nohup wget -q -O - "https://tf-dex-prod-public-snapshot-site1.s3.amazonaws.com/geth-20211116.tar.gz?AWSAccessKeyId=AKIAYINE6SBQPUZDDRRO&Signature=x2s7VqyfTjCkGXXn2%2BBQFg3NGyw%3D&Expires=1639717271" | tar -zxvf - &

$ mkdir node
$ mv ./server/data-seed/geth ./node/
```

## 下载二进制文件

从[发布页面](https://github.com/binance-chain/bsc/releases/latest)下载预构建二进制文件

```shell
$ version='v1.1.5'
$ wget  https://github.com/binance-chain/bsc/releases/download/${version}/geth_linux
$ chmod +x geth_linux
$ mv geth_linux /usr/bin/geth
```

## 下载配置文件

下载`genesis.json`和`config.toml`通过

```shell
$ wget https://github.com/binance-chain/bsc/releases/download/${version}/mainnet.zip
$ unzip mainnet.zip
```

## 修改主网配置文件

```toml
HTTPHost: HTTP-RPC服务连接白名单，此参数的值默认为 "localhost"，仅允许本地可访问，可设置为："0.0.0.0"

HTTPVirtualHosts：HTTP-RPC服务监听接口,此参数的值默认为 ["localhost"],可设置为：HTTPVirtualHosts = ["*"]
```

## 启动全节点

```shell
nohup geth --config ./config.toml --datadir ./node --cache 8000 --rpc.allow-unprotected-txs --txlookuplimit 0 --diffsync &
```

参数说明

> --config：指定BSC节点配置文件
>
> --datadir：指定BSC节点数据库和密钥存储库的数据目录(默认:"/root/.ethereum")
>
> --cache value  分配给内部缓存的兆字节内存(默认= 4096主网全节点，128轻模式)(默认:1024)
>
> --maxpeers value   网络对等体的最大数量(如果设置为0则禁用网络)(默认值:50)
>
> --maxpendpeers value   挂起的连接尝试的最大数量(设置为0时使用默认值)(默认值:0)
>
> --diffsync   启用差异同步，请注意，启用差异同步将提高同步速度，但将降低安全性到轻客户端级别
>
> --snapshot    启用快照-数据库模式(默认= enable)
>
> --rpc.allow-unprotected-txs  允许通过RPC提交不受保护的(非EIP155签名的)事务
>
> --syncmode value  区块链同步模式("fast"， "full"， "snap"或"light")(默认:fast)
>
> --txlookuplimit value  最近维护事务索引的块数(默认=大约一年，0 =整个链)(默认:2350000)



日志说明

```shell
# 预置BSC主网节点各种配置
t=2021-11-17T11:12:12+0000 lvl=warn msg="Sanitizing cache to Go's GC limits" provided=18000 updated=10439
# 初始化链配置
t=2021-11-17T11:12:25+0000 lvl=info msg="Initialised chain configuration"    config="{ChainID: 56 Homestead: 0 DAO: <nil> DAOSupport: false EIP150: 0 EIP155: 0 EIP158: 0 Byzantium: 0 Constantinople: 0 Petersburg: 0 Istanbul: 0, Muir Glacier: 0, Ramanujan: 0, Niels: 0, MirrorSync: 5184000, Bruno: 13082000, Berlin: <nil>, YOLO v3: <nil>, Engine: parlia}"
# 加载最新的header文件
t=2021-11-17T11:12:26+0000 lvl=info msg="Loaded most recent local header"    number=12,616,931 hash=0xd92dba8702a2e0c7cfb865356e209c2ff29013b287a2077404878dce2dd6c889 td=25,098,626 age=3d20h1m
# 加载最新的完整的区块
t=2021-11-17T11:12:26+0000 lvl=info msg="Loaded most recent local full block" number=12,616,931 hash=0xd92dba8702a2e0c7cfb865356e209c2ff29013b287a2077404878dce2dd6c889 td=25,098,626 age=3d20h1m
# 加载最新的fast区块
t=2021-11-17T11:12:26+0000 lvl=info msg="Loaded most recent local fast block" number=12,616,931 hash=0xd92dba8702a2e0c7cfb865356e209c2ff29013b287a2077404878dce2dd6c889 td=25,098,626 age=3d20h1m
# 同步模式由快速同步切换为全同步
t=2021-11-17T11:12:26+0000 lvl=warn msg="Switch sync mode from fast sync to full sync"
# 启动p2p网络
t=2021-11-17T11:12:26+0000 lvl=info msg="Started P2P networking"              self=enode://6a9a48a03027a26a155a1ccfe68197a1f79027af54a1bd586f9003ada102e85f088aaa82c90d5473991dad65f3d6272020e6621fade53757af106c15ed7a8a8a@127.0.0.1:30311
# 区块同步开始
t=2021-11-17T11:12:36+0000 lvl=info msg="Block synchronisation started"
# 同步到新的链数据
t=2021-11-17T11:12:36+0000 lvl=info msg="Imported new chain segment"
```

## 查询是否同步完成

```shell
# 查看当前最新区块
$ curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://127.0.0.1:8545

{"jsonrpc":"2.0","id":1,"result":"0x8f8e68"}

# 查看当前同步状态
$ curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://127.0.0.1:8545

{"jsonrpc":"2.0","id":1,"result":false}
# 注：结果为false为同步完成

$ curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://127.0.0.1:8545

```



# 常用命令

```shell
# 查看区块同步情况
eth.syncing
# 列出所有账号
eth.accounts
# 在同步的过程中我们通过 eth.blockNumber 去查看当前区块号的话会显示为0
eth.blockNumber
# 节点连了多少个其它节点进行数据同步。如果返回结果为0，就要自查一下了
net.peerCount
# 查看同行
admin.peers
# 查看第一个账号余额
eth.getBalance(eth.accounts[0])
# 新建一个密码123456的账号
personal.newAccount('123456')
# 币值转换为big ether
web3.toWei(0.0001, "ether")
# big ether转换为ether
web3.fromWei(100000000000000, "ether")
# 查看当前网络信息
admin.nodeInfo
# 查看网络是否监听
net.listening
# 开始挖矿
miner.start()
# 停止挖矿
miner.stop()
# 获取用户金额
eth.getBalance(my)
# 添加同行
admin.addPeer( "enode://9e779099395c022e4a4f14305f3b513c09c8a933f058dd50cf93ad4418dc62d990ce54e07267b8a5a87ee3da5c8b4ec760998ef869abd276487066f0da0f4dba@43.129.250.112:30311" )
admin.addPeer( "enode://0daef7aa168454c9404f7d4f819f340ebc28d1593a7f29953c93968f87ca35d8e88d5cf37258fe9326f95e63b959eb8f8c62ac1020b7fca1f2a37eec483c41e1@49.233.60.245:30311" )
```



# 附录

[官网](https://www.binance.org)

[MainNet区块链浏览器](https://www.bscscan.com)

[论坛](https://community.binance.org)

[GitHub Issues 区块同步越来越慢 #4465](https://github.com/filecoin-project/lotus/issues/4465)

[运行 BSC 全节点的一些技巧 #502](https://github.com/binance-chain/bsc/issues/502)

[BSC 同步问题 #338](https://github.com/binance-chain/bsc/issues/338)

[二进制启动BSC主网快照数据](https://segmentfault.com/a/1190000040425692)

[官方参考文档](https://docs.binance.org/smart-chain/developer/fullnode.html)

https://github.com/binance-chain/bsc/issues/338#issuecomment-971501973

[生成状态快照 #555](https://github.com/binance-chain/bsc/issues/555)

