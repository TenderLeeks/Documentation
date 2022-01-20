# 环境配置

```shell
# 自定义环境变量
$ echo -e "export OKEX_HOME=/data/okexchain" > /etc/profile.d/okexchain.sh
$ source /etc/profile

$ mkdir -p ${OKEX_HOME}/{bin,log,src}

# 设置golang代理
# export GOPROXY=https://goproxy.cn

$ sudo apt-get update
$ gcc --version
$ g++ --version
# 将您的 gcc 升级到至少 4.8 版本以获得 C++11 支持。
$ sudo apt-get install -y libgflags-dev
$ sudo apt-get install -y libsnappy-dev
$ sudo apt-get install -y zlib1g-dev
$ sudo apt-get install -y libbz2-dev
$ sudo apt-get install -y liblz4-dev
$ sudo apt-get install -y libzstd-dev
```



# Testnet 编译安装

两种方式
**注：测试网不支持创世块文件方式启动，仅支持 [快照链接](https://forum.okt.club/d/154) 启动**

1. 使用exchaind+快照启动

   ```shell
   # latest_version可以通过链接 https://github.com/okex/exchain/releases/latest 查看
   # git clone -b latest_version https://github.com/okex/exchain.git
   
   $ cd ${OKEX_HOME}/src
   $ git clone -b v0.19.13.2 https://github.com/okex/exchain.git
   $ cd exchain
   $ make rocksdb
   # 编译支持 rocksdb 的 exchaind
   $ make testnet WITH_ROCKSDB=true
   
   # 初始化交换链节点配置
   $ ${OKEX_HOME}/bin/exchaind init okexNodeHoopox --chain-id exchain-65 --home ${OKEX_HOME}
   
   # 下载快照
   $ rm -rf ${OKEX_HOME}/data
   $ cd ${OKEX_HOME}
   # 选择最近日期的快照下载
   # wget https://ok-public-hk.oss-cn-hongkong.aliyuncs.com/cdn/okexchain/snapshot/okexchain-$version-$date-$height_xxx.tar.gz
   # tar -zxvf okexchain-$version-$date-$height_xxx.tar.gz
   
   # start exchaind
   $ export EXCHAIN_SEEDS="b7c6bdfe0c3a6c1c68d6d6849f1b60f566e189dd@3.13.150.20:36656,d7eec05e6449945c8e0fd080d58977d671eae588@35.176.111.229:36656,223b5b41d1dba9057401def49b456630e1ab2599@18.162.106.25:36656"
   
   $ exchaind start --chain-id exchain-65 --db_backend rocksdb --mempool.sort_tx_by_gp --home ${OKEX_HOME} --p2p.seeds $EXCHAIN_SEEDS
   
   # 后台启动
   $ nohup ${OKEX_HOME}/bin/exchaind start --chain-id exchain-65 --db_backend rocksdb --mempool.sort_tx_by_gp --pruning nothing --home ${OKEX_HOME} --p2p.seeds $EXCHAIN_SEEDS >> ${OKEX_HOME}/log/okexchain.log &
   
   ```

2. 使用docker+快照启动

   ```shell
   $ exchaind init okexNodeHoopox --chain-id exchain-65 --home ${OKEX_HOME}
   
   $ rm -rf ${OKEX_HOME}/data
   $ cd ${OKEX_HOME}
   # $ wget https://ok-public-hk.oss-cn-hongkong.aliyuncs.com/cdn/okexchain/snapshot/okexchain-$version-$date-$height_xxx.tar.gz
   # $ tar -zxvf okexchain-$version-$date-$height_xxx.tar.gz
   
   $ docker pull okexchain/fullnode-testnet:latest
   
   $ docker run -d --name exchain-testnet-fullnode -v ${OKEX_HOME}/data:/root/.exchaind/data/ -p 8545:8545 -p 26656:26656 okexchain/fullnode-testnet:latest
   ```

   

# Mainnet 编译安装

1. 使用快照启动

   [快照链接](https://forum.okt.club/d/154)

   ```shell
   # latest_version可以通过链接 https://github.com/okex/exchain/releases/latest 查看
   # git clone -b latest_version https://github.com/okex/exchain.git
   $ cd ${OKEX_HOME}/src
   $ git clone -b v0.19.13.2 https://github.com/okex/exchain.git
   $ cd exchain
   $ make rocksdb
   $ make mainnet WITH_ROCKSDB=true
   
   $ ${OKEX_HOME}/bin/exchaind init okexNodeHoopox --chain-id exchain-66 --home ${OKEX_HOME}
   
   # 注意：检查genesis.json文件的shasum值
   $ sha256sum ${OKEX_HOME}/config/genesis.json
   # 输出信息 >> 0958b6c9f5f125d1d6b8f56e042fa8a71b1880310227b8b2f27ba93ff7cd673b  /opt/chain/okexchain/config/genesis.json
   
   $ rm -rf ${OKEX_HOME}/data
   $ cd ${OKEX_HOME}
   # $ wget https://ok-public-hk.oss-cn-hongkong.aliyuncs.com/cdn/okexchain/snapshot/okexchain-$version-$date-$height_xxx.tar.gz
   # $ tar -zxvf okexchain-$version-$date-$height_xxx.tar.gz
   
   $ export EXCHAIN_SEEDS="e926c8154a2af4390de02303f0977802f15eafe2@3.16.103.80:26656,7fa5b1d1f1e48659fa750b6aec702418a0e75f13@175.41.191.69:26656,c8f32b793871b56a11d94336d9ce6472f893524b@35.74.8.189:26656"
   
   $ nohup ${OKEX_HOME}/bin/exchaind start --chain-id exchain-66 --db_backend rocksdb --mempool.sort_tx_by_gp --home ${OKEX_HOME} --p2p.seeds $EXCHAIN_SEEDS >> ${OKEX_HOME}/log/okexchain.log &
   
   ```

2. 使用创世文件

   ```shell
   # 1. build exchain
   $ git clone -b latest_version https://github.com/okex/exchain.git 
   # latest_version可以通过链接 https://github.com/okex/exchain/releases/latest 查看
   $ cd exchain
   $ make mainnet   # 务必使用
   
   # 2. Initialize exchain node configurations
   $ export EXCHAIND_PATH=~/.exchaind (或者其他目录)
   $ exchaind init your_custom_moniker --chain-id exchain-66 --home ${EXCHAIND_PATH}
   
   # 3. download genesis.json
   $ wget https://raw.githubusercontent.com/okex/mainnet/main/genesis.json -O ${EXCHAIND_PATH}/config/genesis.json
   
   # 4. start exchaind
   $ export EXCHAIN_SEEDS="e926c8154a2af4390de02303f0977802f15eafe2@3.16.103.80:26656,7fa5b1d1f1e48659fa750b6aec702418a0e75f13@175.41.191.69:26656,c8f32b793871b56a11d94336d9ce6472f893524b@35.74.8.189:26656"
   
   $ exchaind start --chain-id exchain-66 --mempool.sort_tx_by_gp --home ${EXCHAIND_PATH} --p2p.seeds $EXCHAIN_SEEDS
   ```



# 查看链的状态
```shell
$ ${OKEX_HOME}/bin/exchaincli status
```



# 查看主网区块哈希值

```tex
需要把 height 值替换成对应的区块数
https://exchaintmrpc.okex.org/block?height=2439212
```



# 注意

1. 默认端口：解析到start命令指定的 --rest.laddr 参数上面，默认是26659端口。

2. 如果你使用s3快照启动，务必在启动参数中加上`pruning=nothing`，因为pruning的默认值是default，会裁剪数据。

3. 注意：自 [v0.19.12.2](https://github.com/okex/exchain/releases/tag/v0.19.12.2) 版本起，OEC使用的leveldb被改为性能更好的rocksdb。

4. **你可能会出现遇到`panic: couldn't create db: Error initializing DB: Corruption: Unsupported compression method or corrupted compressed block contents: Snappy`这样的错误，此时需要安装`Snappy`并重新编译rocksdb，具体可以参考[这里](https://github.com/facebook/rocksdb/blob/main/INSTALL.md#supported-platforms)**

5. **如果你使用s3快照启动，务必在启动参数中加上`pruning=nothing`，因为pruning的默认值是default，会裁剪数据。**

6. 设置参数`--p2p.persistent_peers`加速区块同步效率

   ```shell
   1. --p2p.persistent_peers bbd4aa19249ad42de4fe2ca99209894412fd4707@3.135.138.205:26656,add30aff52c2e43f071c7c2a8be797bef0ed8261@18.135.79.233:26656,e5c4c525df58bb072f2aacebea1cd92d36e83fd3@18.162.117.130:26656,7ce43d169e955309e1cca22468ee3ed9e6fd6f45@8.166.245.222:26656,f7c67632e51fde3c30bc8e41852c1e81aa1d9c2a@18.167.7.207:26656,833777703584393d763b60169e5ca204da91dd83@18.166.194.215:26656,54c195e08ff53e9fd31973dd73d530dcd1506807@52.78.236.126:26656,0eb87d4eb92f8f04d9c2d444dd403671a634af56@13.125.38.24:26656,01b21d39f250a3a5411113aae4a7032eaf9b344e@3.64.37.17:26656,69ea6fb105a3f85d3dd44267d28fae4f0dedf5ab@18.192.220.49:26656,b2a2f799a726b74f83f73b62e1bfef017575b21a@54.151.166.67:26656,3449bb4d2180dfaa9ddb13776177b0e67f95ebb4@54.255.93.228:26656,da32322e27dc9ef5002fed0416f05326fd27723f@54.151.129.9:26656,c88044fb164896bd9ed29bbee7c290c6ac362133@3.112.119.135:26656,39700092b3c7893fdd8ab3af9d66f18113ca47cd@54.150.183.225:26656,9e2aa6bd61c40f08782f7c2ff47d9ea197994b74@54.249.109.150:26656,44cd4db42723a65d61e8803498703b9e4b353036@44.233.186.156:26656,8c7affcb25e8e059f992d4c6494586587782d809@52.40.214.137:26656
   ```

7. 在启动rpc节点时建议带上一些性能优化的参数，可以避免节点同步区块慢等问题。

   具体参数如下：

   ```shell
   # 以二进制形式启动的节点，在exchaind start命令中增加以下参数
   --max-open=10000 
   --close-mutex=1
   --fast-query=1 
   --enable-bloom-filter=1 
   --mempool.size=10000 
   --mempool.recheck=0 
   --mempool.force_recheck_gap=2000 
   --iavl-cache-size=1000000
   
   # 以docker方式启动的节点，在docker run命令中增加以下参数
   --env OKEXCHAIN_MAX_OPEN=10000
   --env OKEXCHAIN_CLOSE_MUTEX=1
   --env OKEXCHAIN_FAST_QUERY=1
   --env OKEXCHAIN_ENABLE_BLOOM_FILTER=1
   --env OKEXCHAIN_MEMPOOL_SIZE=10000
   --env OKEXCHAIN_MEMPOOL_RECHECK=0
   --env OKEXCHAIN_MEMPOOL_FORCE_RECHECK_GAP=2000
   --env OKEXCHAIN_IAVL_CACHE_SIZE=1000000
   ```

   **性能参数含义解释**

   ```shell
   --max-open=10000 最大连接数，默认值1000，增加该值可以提供rpc服务能够接收的连接数。
   --close-mutex=1 abci query中的锁开关，默认值为关闭，打开后可以提升查询性能
   --fast-query=1 快速查询模式开关，默认值为关闭，打开后查询数据会额外记录到watch.db，提升查询性能
   --enable-bloom-filter=1 bloom filter开关，默认值为关闭，打开可以提升eth_getLogs查询性能_
   --mempool.size=10000 设置mempool大小，默认值2000，增加该值可以提高mempool中存储
   tx数量。
   --mempool.recheck=0 设置mempool recheck开关，默认值为打开，关闭可以减少recheck消耗的性能
   --mempool.force_recheck_gap=2000 设置mempool强制进行recheck的区块间隔数，默认值200，增大该值可以减少recheck次数，提升性能，但是设置过大可能会导致mempool中积压过多无效的交易。
   --iavl-cache-size=1000000 设置iavl树缓存大小，默认值1000000，增加该值可以减少磁盘读取，提升执行速度，但是会占用更多内存，可根据机器实际内存占用情况调整。
   --log_level *:debug  打印debug日志
   ```

7. 如果调用节点的JSON RPC 接口，需要在配置文件中添加如下配置

   ```shell
   # 配置文件添加
   [rest]
   laddr = "tcp://0.0.0.0:8545"
   
   # 或启动命令添加参数
   --rest.laddr tcp://0.0.0.0:8545
   ```
   
   

# 管理服务脚本

## Testnet

```shell
#!/bin/bash

#########################################################
# Function :OEC TestNet 节点服务管理
# Platform :All Linux Based Platform
# Version  :1.0
# Date     :2021-11-22
# Author   :shuai.yu
# Contact  :ken.yu@aelf.io
# Company  :HooPox
#########################################################

export OEC_HOME="/data/okexchain"

export EXCHAIN_SEEDS="b7c6bdfe0c3a6c1c68d6d6849f1b60f566e189dd@3.13.150.20:36656,d7eec05e6449945c8e0fd080d58977d671eae588@35.176.111.229:36656,223b5b41d1dba9057401def49b456630e1ab2599@18.162.106.25:36656"

SERVER_NAME="exchaind"

LOG_FILR="${OEC_HOME}/log/okexchain.log"
LOG_SHELL="${OEC_HOME}/log/init_shell.log"

PID=`ps -ef|grep "${SERVER_NAME}"|egrep -v "grep|sudo"|awk '{print $2}'`

is_running() {
    [ `ps -ef|grep "${SERVER_NAME}"|egrep -v "grep|sudo"|wc -l` -gt 0 ] || return 1
    return 0
}


is_root() {
    [ "`whoami`" = 'root' ] && return 0
    return 1
}


is_deploy() {
    [ "`whoami`" = 'deploy' ] && return 0
    return 1
}


wait_pid_exit() {
    count=0
    MAX_WAIT=30
    until ! `is_running` || [ ${count} -gt ${MAX_WAIT} ]
    do
        echo -n "."
        sleep 1
        count=`expr ${count} + 1`
        kill -15 ${PID}
    done

    if [ ${count} -gt ${MAX_WAIT} ]; then
        echo "killing it forcely after ${MAX_WAIT} second waiting."
        exit 0
        #kill -9 ${PID}  2>/dev/null
    fi;
}

start() {
    cd ${OEC_HOME}
    is_root && chown -R deploy.deploy ${OEC_HOME}
    is_root && nohup sudo -u deploy ${OEC_HOME}/bin/exchaind start --chain-id exchain-65 --db_backend rocksdb --mempool.sort_tx_by_gp --pruning nothing --home ${OEC_HOME} --p2p.seeds ${EXCHAIN_SEEDS} >> ${LOG_FILR} 2>&1 &
    
    is_deploy && chown -R deploy.deploy ${OEC_HOME}
    is_deploy && nohup ${OEC_HOME}/bin/exchaind start --chain-id exchain-65 --db_backend rocksdb --mempool.sort_tx_by_gp --pruning nothing --home ${OEC_HOME} --p2p.seeds ${EXCHAIN_SEEDS} >> ${LOG_FILR} 2>&1 &
}



stop() {
    kill -15 ${PID}
    wait_pid_exit
}


view_log() {
    tail -f ${LOG_FILR}
}



main(){
case "$1" in
    start)
        is_running && { printf "${SERVER_NAME} is already running. \n"; exit 0; }
        start
        printf "${SERVER_NAME} started \n"
        ;;
    stop)
        is_running || { printf "${SERVER_NAME} isn't running. \n"; exit 0; }
        stop
        printf "${SERVER_NAME} stop \n"
        ;;
    status)
        if is_running; then
            printf "${SERVER_NAME} is runing (${PID}) \n"
        else
            printf "${SERVER_NAME} isn't running \n"
        fi
        ;;
    restart)
        is_running && stop
        sleep 1
        start
        sleep 1
        if is_running; then
            printf "${SERVER_NAME} restarted \n"
        else
            printf "${SERVER_NAME} failed to restart \n"
        fi
        ;;
    log)
        view_log
        ;;
    *)
        printf "Usage: $0 {start|stop|status|restart|log} \n"
        exit 2
esac
}

#main "$@" | tee -a ${LOG_SHELL}
main "$@"
```

## Mainnet

```shell
#!/bin/bash

#########################################################
# Function :OEC MainNet 节点服务管理
# Platform :All Linux Based Platform
# Version  :1.0
# Date     :2021-11-22
# Author   :shuai.yu
# Contact  :ken.yu@aelf.io
# Company  :HooPox
#########################################################

export OEC_HOME="/data/okexchain"

export EXCHAIN_SEEDS="e926c8154a2af4390de02303f0977802f15eafe2@3.16.103.80:26656,7fa5b1d1f1e48659fa750b6aec702418a0e75f13@175.41.191.69:26656,c8f32b793871b56a11d94336d9ce6472f893524b@35.74.8.189:26656"

SERVER_NAME="exchaind"

LOG_FILR="${OEC_HOME}/log/okexchain.log"

PID=`ps -ef|grep "${SERVER_NAME}"|egrep -v "grep|sudo"|awk '{print $2}'`

is_running() {
    [ `ps -ef|grep "${SERVER_NAME}"|egrep -v "grep|sudo"|wc -l` -gt 0 ] || return 1
    return 0
}


is_root() {
    [ "`whoami`" = 'root' ] && return 0
    return 1
}


is_deploy() {
    [ "`whoami`" = 'deploy' ] && return 0
    return 1
}


wait_pid_exit() {
    count=0
    MAX_WAIT=30
    until ! `is_running` || [ ${count} -gt ${MAX_WAIT} ]
    do
        echo -n "."
        sleep 1
        count=`expr ${count} + 1`
        kill -15 ${PID}
    done

    if [ ${count} -gt ${MAX_WAIT} ]; then
        echo "killing it forcely after ${MAX_WAIT} second waiting."
        exit 0
        #kill -9 ${PID}  2>/dev/null
    fi;
}

start() {
    cd ${OEC_HOME}
    is_root && chown -R deploy.deploy ${OEC_HOME}
    is_root && nohup sudo -u deploy ${OEC_HOME}/bin/exchaind start --chain-id exchain-66 --db_backend rocksdb --mempool.sort_tx_by_gp --home ${OEC_HOME} --p2p.seeds ${EXCHAIN_SEEDS} >> ${LOG_FILR} 2>&1 &
    
    is_deploy && chown -R deploy.deploy ${OEC_HOME}
    is_deploy && nohup ${OEC_HOME}/bin/exchaind start --chain-id exchain-66 --db_backend rocksdb --mempool.sort_tx_by_gp --home ${OEC_HOME} --p2p.seeds ${EXCHAIN_SEEDS} >> ${LOG_FILR} 2>&1 &
}


stop() {
    kill -15 ${PID}
    wait_pid_exit
}


view_log() {
    tail -f ${LOG_FILR}
}


main(){
case "$1" in
    start)
        is_running && { printf "${SERVER_NAME} is already running. \n"; exit 0; }
        start
        printf "${SERVER_NAME} started \n"
        ;;
    stop)
        is_running || { printf "${SERVER_NAME} isn't running. \n"; exit 0; }
        stop
        printf "${SERVER_NAME} stop \n"
        ;;
    status)
        if is_running; then
            printf "${SERVER_NAME} is runing (${PID}) \n"
        else
            printf "${SERVER_NAME} isn't running \n"
        fi
        ;;
    restart)
        is_running && stop
        sleep 1
        start
        sleep 1
        if is_running; then
            printf "${SERVER_NAME} restarted \n"
        else
            printf "${SERVER_NAME} failed to restart \n"
        fi
        ;;
    log)
        view_log
        ;;
    *)
        printf "Usage: $0 {start|stop|status|restart|log} \n"
        exit 2
esac
}

main "$@"

```



# 附录

[Main浏览器](https://www.oklink.com/okexchain)

[TestNet浏览器](https://www.oklink.com/okexchain-test)

[TestNet水龙头](https://www.okex.com/drawdex)

[开发者文档中心](https://okexchain-docs.readthedocs.io/en/latest/developers/quick-start.html)

[开发文档](https://forum.okt.club/)

[资料文档](https://oec-docs.readthedocs.io/en/latest/)

~~[TestNet官方部署方案](https://github.com/okex/testnets)~~

~~[Main部署参考文档](https://forum.okt.club/d/70-exchainv0181)~~

[手动裁剪节点数据](https://forum.okt.club/d/196)

[主网和测试网最新快照](https://forum.okt.club/d/154)

[运行支持rocksdb的oec节点](https://forum.okt.club/d/242-rocksdboec)

[节点运行过程中报open too many files错误](https://forum.okt.club/d/38-open-too-many-files)

[修复状态数据方法说明](https://forum.okt.club/d/218)

[RPC 手册](https://okexchain-docs.readthedocs.io/en/latest/developers/basics/json_rpc.html)

```
curl -X POST --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' -H "Content-Type: application/json" http://127.0.0.1:26657
```
