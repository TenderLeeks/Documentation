# Polygon Testnet

## 先决条件

- 两台机器：一台本地机器，你将在其中运行 Ansible playbook；一台远程机器用于全节点。
- 在本地机器上，安装了 Ansible、Python 3.x、确保没有安装 Go。
- 在远程机器上，你本地机器的 SSH 公钥在远程机器上，让 Ansible 连接到它们。
- Ansible 应该安装在带有 Python3.x 的本地机器上。如果您有 Python2.x，则设置将不起作用。
  - 要使用 Python 3.x 安装 ansible，您可以使用此命令`pip3 install ansible`。这将安装 Python 3 依赖项以及 ansible。
- 检查https://github.com/maticnetwork/node-ansible#requirements以了解要求。
- 你还需要确保你的虚拟机/机器上没有安装 Go。如果你已经安装了 Go，那么通过 ansible 设置你的完整节点会遇到问题，因为 ansible 需要安装特定的 Go 包。
- 您还需要确保您的虚拟机/机器之前没有对 Polygon Validator、Heimdall 或 Bor 进行任何设置。您将需要删除它们，因为您的设置会遇到问题。
- 最低系统要求
  - 16 - 32 GiB 内存，4 - 8 核 CPU (t3 xLarge)，最低 650GB SSD（确保它是可扩展的）



## 环境配置

1. ansible主机配置

   ```shell
   $ apt install -y python3-pip
   $ pip3 install ansible
   $ ansible --version
   ```

2. 数据节点主机配置

   ```shell
   # 修改主机名
   $ sudo hostnamectl set-hostname aws-tokyo-testnet-polygon-01a
   # 创建普通用户
   $ sudo groupadd deploy; sudo useradd deploy -m -s /bin/bash -d /data/deploy -g deploy
   # 修改用户sudo权限
   $ visudo
   # 在 visudo 文件中加入以下内容
   deploy    ALL=(ALL:ALL) NOPASSWD: ALL
   ```

   

## 测试网设置完整节点

### **以下步骤请在ansible 主机上配置**

1. 确保您有权访问正在设置完整节点的远程计算机或 VM。

   有关更多详细信息，请参阅https://github.com/maticnetwork/node-ansible#setup。

   ```shell
   # 在 ansible 主机配置
   $ cd /tmp
   $ git clone https://github.com/maticnetwork/node-ansible.git
   $ cd node-ansible
   # 修改 group_vars/all 文件中用户信息
   $ vim group_vars/all 
   ---
   ansible_user: deploy
   ```

2. 编辑`inventory.yml`文件并在该`sentry->hosts`部分插入您的 IP 。

   有关更多详细信息，请参阅https://github.com/maticnetwork/node-ansible#inventory。

   ```shell
   $ vim inventory.yml
   all:
   
     hosts:
     children:
       sentry:
         hosts:
           172.31.30.104
       validator:
         hosts: 
   ```

3. 通过运行检查远程机器是否可访问

   ```shell
   $ ansible sentry -m ping
   ```

4. 要进行测试运行以确认是否配置了正确的远程机器/VM，请运行以下命令：

   ```shell
   $ ansible-playbook -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.9 heimdall_branch=v0.2.3 network_version=testnet-v4 node_type=sentry/sentry heimdall_network=mumbai" --list-hosts
   
   # 输出内容
   playbook: playbooks/network.yml
   
     play #1 (all): Network node management        TAGS: []
       pattern: ['all']
       hosts (1):
         172.31.30.104
   ```

5. 使用以下命令设置完整节点：

   ```shell
   $ ansible-playbook -l sentry playbooks/network.yml --extra-var="bor_branch=v0.2.9 heimdall_branch=v0.2.3 network_version=testnet-v4 node_type=sentry/sentry heimdall_network=mumbai"
   ```

6. 如果您遇到任何问题，请使用以下命令删除并清理整个设置

   ```shell
   # 安装步骤请不要运行此命令
   $ ansible-playbook -l sentry playbooks/clean.yml
   ```



### **以下步骤请在节点主机上配置**

1. 切换用户

   ```shell
   $ sudo su deploy
   ```

2. 在 `~/.heimdalld/config/config.toml` 中配置以下内容

   ```shell
   $ vim ~/.heimdalld/config/config.toml
   
   # moniker = <输入唯一标识符>
   moniker = "aws-tokyo-testnet-polygon-01a"
   seeds = "4cd60c1d76e44b05f7dfd8bab3f447b119e87042@54.147.31.250:26656"
   ```

   如果您的 Heimdall 已停止同步，您可以向`config.toml`文件中添加其他种子：

   ```shell
   seeds="4cd60c1d76e44b05f7dfd8bab3f447b119e87042@54.147.31.250:26656,b18bbe1f3d8576f4b73d9b18976e71c65e839149@34.226.134.117:26656"
   ```

   

3. 在 `~/.heimdalld/config/heimdall-config.toml` 中配置以下内容

   ```shell
   $ vim ~/.heimdalld/config/heimdall-config.toml
   
   # eth_rpc_url =<insert Infura or any full node RPC URL to Goerli>
   eth_rpc_url = "http://172.31.19.101:8545"
   ```

4. 将以下标志添加`~/node/bor/start.sh`到`bor`开始参数中

   ```shell
   $ vim ~/node/bor/start.sh
   
   --bootnodes "enode://320553cda00dfc003f499a3ce9598029f364fbb3ed1222fdc20a94d97dcc4d8ba0cd0bfa996579dcc6d17a534741fb0a5da303a90579431259150de66b597251@54.147.31.250:30303"
   ```

   如果您的 Bor 节点停止同步，您可以向`start.sh`文件中添加额外的引导节点：

   ```shell
   --bootnodes enode://320553cda00dfc003f499a3ce9598029f364fbb3ed1222fdc20a94d97dcc4d8ba0cd0bfa996579dcc6d17a534741fb0a5da303a90579431259150de66b597251@54.147.31.250:30303,enode://f0f48a8781629f95ff02606081e6e43e4aebd503f3d07fc931fad7dd5ca1ba52bd849a6f6c3be0e375cf13c9ae04d859c4a9ae3546dc8ed4f10aa5dbb47d4998@34.226.134.117:30303
   ```

   

5. 如果您想`trace`为 Bor 启用，要为 Bor 打开跟踪，请将以下标志添加到 中的`bor`开始参数`~/node/bor/start.sh`

   ```shell
   --gcmode 'archive'
   ```

## Heimdall 和 Bor 的快照说明

在设置新的 Sentry、Validator 或 Full Node 服务器时，建议您使用快照以加快同步速度，而无需通过网络进行同步。使用快照可为 Heimdall 和 Bor 节省数天时间。

最新快照请参考 https://snapshots.matic.today

使用快照

**Heimdall**

首先，您需要根据节点设置指南使用先决条件设置节点。在启动 Heimdall 同步服务之前，请按照以下步骤使用快照：

将快照下载到您的 VM。要将 Snapshot Tar 文件下载到您的 VM，您可以运行以下命令

```shell
$ wget -c https://matic-blockchain-snapshots.s3-accelerate.amazonaws.com/matic-mumbai/heimdall-snapshot-2021-11-08.tar.gz
```

这将下载 Heimdall 的快照。

现在，要解压 Heimdall Data 目录中的 Tar 文件，请运行以下命令。在您的节点上启动 Heimdall 服务之前，您需要确保您正在运行此命令。如果您的 Heimdall 服务已启动，请停止并运行以下命令。解压完成后，您可以再次启动 Heimdall 服务。

```shell
$ tar -xzvf heimdall-snapshot-2021-11-08.tar.gz -C ~/.heimdalld/data/
```

请注意，如果您的 Heimdall 数据目录不同，请正确提及该目录名称。此命令完成后，您可以删除 tar 文件以回收空间。

**Bor**

首先，您需要根据节点设置指南使用先决条件设置节点。在启动 Bor 同步服务之前，请按照以下步骤使用快照：

将快照下载到您的 VM。要将 Snapshot Tar 文件下载到您的 VM，您可以运行以下命令

```shell
$ wget -c https://matic-blockchain-snapshots.s3-accelerate.amazonaws.com/matic-mumbai/bor-fullnode-node-snapshot-2021-11-03.tar.gz
```

现在，要解压 Bor Data 目录中的 Tar 文件，请运行以下命令。在您的节点上启动 Bor 服务之前，您需要确保您正在运行此命令。如果您的 Bor 服务已启动，请停止并运行以下命令。解包完成后，您可以再次启动 Bor 服务。

```shell
$ tar -zxvf bor-fullnode-node-snapshot-2021-11-03.tar.gz -C ~/.bor/data/bor/chaindata/
```

请注意，如果您的 bor 数据目录不同，请正确提及该目录名称。此命令完成后，您可以删除 tar 文件以回收空间。

## 启动节点和服务

1. 使用以下命令运行完整节点

   ```shell
   # 启动 Heimdall
   $ sudo service heimdalld start
   # 要启动 Heimdall Rest Server，您可以运行以下命令：
   $ sudo service heimdalld-rest-server start
   # 同步 Heimdall 后，运行
   $ sudo service bor start
   ```

2. 检查日志

   ```shell
   # 检查 Heimdall 日志
   $ journalctl -u heimdalld.service -f
   # 检查 Heimdall Rest Server 日志
   $ journalctl -u heimdalld-rest-server.service -f
   # 检查 Bor 日志
   $ journalctl -u bor.service -f
   ```

3. 检查 Heimdall 是否同步

   在远程机器/VM 上，运行 `curl localhost:26657/status`
   在输出中，`catching_up`值应该是`false`

4. 端口/防火墙配置

   在节点防火墙上向 (0.0.0.0/0) 开放端口 22、26656 和 30303。所有其他端口都应该关闭。


