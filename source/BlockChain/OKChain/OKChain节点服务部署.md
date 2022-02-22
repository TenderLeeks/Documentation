>  edit by jason

[TOC]

### 常用参考资料

测试网：

- 水龙头：https://www.okex.com/drawdex
- 浏览器：https://www.oklink.com/okexchain-test/

主网：

- 浏览器：

开发者文档中心：https://okexchain-docs.readthedocs.io/en/latest/developers/quick-start.html



https://github.com/okex/testnets



你这个域名解析到的端口不对，应该解析到start命令指定的 --rest.laddr 参数上面，默认是26659端口



###编译节点/下载节点程序

````shell
# 创建目录并设置权限
mkdir -p /opt/chain/eos/okchain
cd /opt/chain/eos/okchain
mkdir bin testnet mainnet nohup_logs src

# 配置golang代理
go version
# go version go1.14.4 linux/amd64
echo $GOPATH
# /opt/go
export GOPROXY=https://goproxy.cn

# 下载代码并编译可执行程序
cd /opt/chain/eos/okchain/src/
git clone -b v0.17.0 https://github.com/okex/okexchain
export GO111MODULE=on
cd okexchain
#mainnet 编译安装
make install
#testnet 编译安装
make GenesisHeight=1121818 install

#软连接可执行程序
cp /opt/go/bin/{okexchaincli,okexchaind} /opt/chain/eos/okchain/bin

ln -s /opt/chain/eos/okchain/bin/okexchaincli /usr/bin/okexchaincli
ln -s /opt/chain/eos/okchain/bin/okexchaind /usr/bin/okexchaincli

# 查看版本
okexchaind version
cd /opt/chain/eos/okchain/testnet

# 下载最新的testnet数据快照
wget -c https://ok-public-hk.oss-cn-hongkong.aliyuncs.com/cdn/okexchain/snapshot/okexchain-v0.16.8-testnet-20210305-height_1121961.tar.gz
tar -zxvf okexchain-v0.16.8-testnet-20210305-height_1121961.tar.gz

# 配置文件生成, `okexNodeBingoo`为节点别称，只允许ASCII码
okexchaind init okexNodeBingoo --chain-id okexchain-65 --home /opt/chain/eos/okchain/testnet


export OKEXCHAIN_SEEDS="b7c6bdfe0c3a6c1c68d6d6849f1b60f566e189dd@3.13.150.20:36656,d7eec05e6449945c8e0fd080d58977d671eae588@35.176.111.229:36656,223b5b41d1dba9057401def49b456630e1ab2599@18.162.106.25:36656"

okexchaind start --chain-id okexchain-65 --home /opt/chain/eos/okchain/testnet --p2p.seeds $OKEXCHAIN_SEEDS

nohup okexchaind start --chain-id okexchain-65 --home /opt/chain/eos/okchain/testnet --p2p.seeds $OKEXCHAIN_SEEDS >> /opt/chain/eos/okchain/nohup_logs/okchain.log &



#删除默认创世文件，下载版本对应的创世文件
rm -f /opt/chain/eos/okchain/testnet/config/genesis.json
wget https://raw.githubusercontent.com/okex/testnets/master/v0.16.6/genesis.json -P /opt/chain/eos/okchain/testnet/config/

#替换种子节点
sed -i "s/seeds = \"\"/seeds = "\"b7c6bdfe0c3a6c1c68d6d6849f1b60f566e189dd@3.13.150.20:36656,d7eec05e6449945c8e0fd080d58977d671eae588@35.176.111.229:36656,223b5b41d1dba9057401def49b456630e1ab2599@18.162.106.25:36656\""/g" /opt/chain/eos/okchain/testnet/config/config.toml

chown -R deploy.deploy /opt/chain/eos/okchain

# 切换系统用户
su deploy
cd /opt/chain/eos/okchain
````

### 命令方式维护节点

```bash
# 命令方案启动测试网
okexchaind start --chain-id okexchain-65 --home /opt/chain/eos/okchain/testnet

nohup okexchaind start --chain-id okexchain-65 --home /opt/chain/eos/okchain/testnet >> /opt/chain/eos/okchain/nohup_logs/okchain.log &

# 命令方式启动主网

# 查看链的状态
okexchaincli status

```

### 常见问题解决

1. starting ABCI with Tendermint                module=main 
   error during handshake: error on replay: validator set is nil in genesis and still empty after InitChain

   ```bash
   #该问题是由于本地区块存在脏数据与创世文件不一致导致,需使用如下命令进行清理
   okexchaind unsafe-reset-all --home /opt/chain/okchain/testnet
   ```

   

1. MAC替换seed是串报错`sed: 1: "/opt/chain/okchain/test ...": command c expects \ followed by text`

   ```bash
   #该问题是由于终端中默认的是BSD的sed，需要下载GNU的sed替换
   brew install gnu-sed 
   alias sed=gsed
   ```

   

### 脚本方式维护节点

1. 创建脚本

   ```bash
   # 脚本方式启动以及维护
   cd /opt/chain/okchain
   touch init.sh
   chmod +x init.sh
   ```

2. 使用附录的管理脚本

3. 使用如下命令进行日常维护

   ```bash
   ## 脚本方式维护测试网
   ./init.sh testnet start
   ./init.sh testnet stop
   ./init.sh testnet restart
   ./init.sh testnet status
   ## 脚本方式维护主网
   ./init.sh mainnet start
   ./init.sh mainnet stop
   ./init.sh mainnet restart
   ./init.sh mainnet status
   ./init.sh start
   ./init.sh stop
   ./init.sh restart
   ./init.sh status
   ```

### 常用命令

```bash

```





### 附录1：管理脚本

```bash
#!/bin/bash

DAEMON="/opt/chain/tron"
TESTNET_ENV="-c /opt/chain/tron/conf/test_net_config.conf -d /opt/chain/tron/data/testnet/"
MAINNET_ENV="-c /opt/chain/tron/conf/main_net_config.conf -d /opt/chain/tron/data/mainnet/"
NAME="/opt/chain/tron/jar/FullNode.jar"
ENV=""
LOG_PERFIX=""
CMD=""
NETWORK=""
DEPLOY_USER="deploy"
PID=""

is_running() {
	[ $(ps -ef | grep "${NAME} ${ENV}" | egrep -v "grep|sudo" | wc -l) -gt 0 ] || return 1
	return 0
}

usage() {
  echo "Usage: $0 {mainnet|testnet} {start|stop|status|restart|flush}"
}

is_root() {
	[ "$(whoami)" = 'root' ] && return 0
	return 1
}

is_deploy() {
	[ "$(whoami)" = ${DEPLOY_USER} ] && return 0
	return 1
}
is_deploy_exist() {
  if id -u ${DEPLOY_USER}>/dev/null 2>&1; then
    return 1
  else
    return 0
  fi
}

is_demon_permission_ready() {
  owner=$(ls -l ${DAEMON}|sed -n '2p' |awk -F " " '{print $3}')
  if [ "${owner}"x = "${DEPLOY_USER}"x ]; then
    echo "Demon path ${DAEMON} is permission ready"
    return 1
  else
    return 0
  fi
}

change_demon_permission() {
  if is_root; then
	  chown -R ${DEPLOY_USER}.${DEPLOY_USER} ${DAEMON}
  else
	  sudo chown -R ${DEPLOY_USER}.${DEPLOY_USER} ${DAEMON}
  fi
}

# 等待进程结束
wait_pid_exit() {
	count=0
	MAX_WAIT=300
	until ! $(is_running) || [ $count -gt $MAX_WAIT ]; do
		echo -n "."
		sleep 1
		count=$(expr $count + 1)
	done

	if [ $count -gt $MAX_WAIT ]; then
		echo "process it not response after $MAX_WAIT second waiting."
	fi
}

# 等待进程结束，如300s无响应则直接杀掉进程
wait_pid_with_kill() {
	count=0
	MAX_WAIT=300
	until ! $(is_running) || [ $count -gt $MAX_WAIT ]; do
		echo -n "."
		sleep 1
		count=$(expr $count + 1)
	done

	if [ $count -gt $MAX_WAIT ]; then
		echo "killing it forcely after $MAX_WAIT second waiting."
		if is_deploy; then
		  kill -9 ${PID} 2>/dev/null
		else
      sudo -u ${DEPLOY_USER}  kill -15 ${PID}
    fi
    sleep 1
	fi
}

start() {
	cd $DAEMON
	# 由于tron无指定log选项，所以需要切换到对应的data目录下进行启动，这样log文件会输出到data文件夹下
	cd "${DAEMON}/data/${NETWORK}"
	if is_deploy; then
		nohup java -jar ${NAME} ${ENV} >>$DAEMON/nohup_logs/${LOG_PERFIX}.out 2>&1 &
		cd -
	else
		nohup sudo -u ${DEPLOY_USER} java -jar ${NAME} ${ENV} >>$DAEMON/nohup_logs/${LOG_PERFIX}.out 2>&1 &
		cd -
	fi
}

flush() {
	cd ${DAEMON}/nohup_logs
	cat ${LOG_PERFIX}.out >>${LOG_PERFIX}.$(date -d "yesterday" +"%Y-%m-%d").out
	echo "" >nohup.out
	if is_root; then
		chown -R ${DEPLOY_USER}.${DEPLOY_USER} ${LOG_PERFIX}.$(date -d "yesterday" +"%Y-%m-%d").out
	else
		sudo chown -R ${DEPLOY_USER}.${DEPLOY_USER} ${LOG_PERFIX}.$(date -d "yesterday" +"%Y-%m-%d").out
	fi
	#    find . -type f -mtime +7 -delete
	#    find . -type d -mtime +7 -delete
}

stop() {
  if is_deploy; then
	  kill -15 ${PID}
  else
     sudo -u ${DEPLOY_USER}  kill -15 ${PID}
  fi
	wait_pid_exit
}

# Main Start ....
# 解析参数
# 判断是否是多参数，如果不输入网络参数则直接默认mainnet
cmd1=( "mainnet" "testnet" )
cmd2=( "start" "stop" "status" "restart" "flush" )

if [ $# -eq 1 ]; then
  if [[ "${cmd2[*]}" =~ "${1}" ]]; then
     CMD=$1
     NETWORK="mainnet"
     ENV=${MAINNET_ENV}
     LOG_PERFIX="nohup_mainnet"
  else
     echo "Invalid commond: $1, arg num is $#"
     usage
     exit 2
  fi
elif [ $# -ge 2 ]; then
  if [[ "${cmd1[*]}" =~ "$1" ]]; then
    if [[ "${cmd2[*]}" =~ "$2" ]]; then
      case "$1" in
        mainnet)
          ENV=${MAINNET_ENV}
          LOG_PERFIX="nohup_mainnet"
          ;;
        testnet)
          ENV=${TESTNET_ENV}
          LOG_PERFIX="nohup_testnet"
        ;;
      esac
     NETWORK=$1
     CMD=$2
    else
      echo "Invalid commond: $1 $2 ,arg num is $#"
      usage
      exit 2
    fi
  else
    echo "Invalid commond: $1 $2 ,arg num is $#"
    usage
    exit 2
  fi
else
   echo "Invalid commond: $1 $2 ,arg num is $#"
  usage
  exit 2
fi
echo "The administrative command network is ${NETWORK}, and the run command is ${CMD}"

is_deploy_exist && {
  echo "the Deploy User :${DEPLOY_USER} is not exist"
  exit 2
}

if [ ! -d ${DAEMON} ]; then
  mkdir -p ${DAEMON}
  echo "Create demon path: ${DAEMON} successed"
fi
echo "The demon path is ${DAEMON}"

# 判断demo路径所属账户是否预备好
is_demon_permission_ready && {
  change_demon_permission
  echo "Change demon path ${DAEMON} permission ok "
}

PID=$(ps -ef | grep "${NAME} ${ENV}" | egrep -v "grep|sudo" | awk '{print $2}')
case ${CMD} in
start)
	is_running && {
		echo "$NAME is already running."
		exit 0
	}
	start
	echo "Demon $NAME started"
	;;
stop)
	is_running || {
		echo "Demon $NAME isn't running."
		exit 0
	}
	stop
	echo "Demon $NAME stop"
	;;
status)
	if is_running; then
		echo "Demon $NAME is runing ($PID)"
	else
		echo "Demon $NAME isn't running"
	fi
	;;
restart)
	is_running && stop
	sleep 1
	start
	sleep 1
	if is_running; then
		echo "Demon ${NAME} restarted"
	else
		echo "Demon ${NAME} failed to restart"
	fi
	;;
flush)
	flush
	;;
*)
	usage
	exit 2
	;;
esac
```

### 附录2：测试网配置文件











