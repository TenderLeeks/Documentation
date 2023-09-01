# Elasticsearch 8.6 中文文档

## 安装

### Linux系统安装Elasticsearch

```bash
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.6.0-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.6.0-linux-x86_64.tar.gz.sha512
shasum -a 512 -c elasticsearch-8.6.0-linux-x86_64.tar.gz.sha512 
tar -xzf elasticsearch-8.6.0-linux-x86_64.tar.gz
cd elasticsearch-8.6.0/ 
```

### 启用自动创建系统标记编辑


一些商业功能会自动在Elasticsearch中创建索引。默认情况下，Elasticsearch配置为允许自动创建索引，不需要额外的步骤。但是，如果您禁用了Elasticsearch中的自动索引创建，则必须在Elasticsearch.yml中配置action.auto_create_index，以允许商业功能创建以下索引：

```yaml
action.auto_create_index: .monitoring*,.watches,.triggered_watches,.watcher-history*,.ml*

```

⚠️警告：如果您使用的是Logstash或Beats，那么您很可能需要在action.auto_create_index设置中使用其他索引名称，具体值将取决于您的本地配置。如果您不确定环境的正确值，可以考虑将该值设置为*，这将允许自动创建所有索引。

### 从命令行启动Elasticsearch

```bash
./bin/elasticsearch

```

首次启动Elasticsearch时，默认情况下会启用和配置安全功能。以下安全配置将自动发生：

- 启用身份验证和授权，并为弹性内置超级用户生成密码。

- TLS的证书和密钥是为传输层和HTTP层生成的，TLS是用这些密钥和证书启用和配置的。

- 为Kibana生成注册令牌，有效期为30分钟。

弹性用户的密码和Kibana的注册令牌将输出到您的终端。例如：

```bash
# 为弹性内置超级用户生成的密码为：
The generated password for the elastic built-in superuser is:
<password>
# Kibana实例的注册令牌，在接下来的30分钟内有效：
The enrollment token for Kibana instances, valid for the next 30 minutes:
<enrollment-token>
# 生成的HTTPS CA DER编码证书的十六进制编码SHA-256指纹：
The hex-encoded SHA-256 fingerprint of the generated HTTPS CA DER-encoded certificate:
<fingerprint>

# 您可以随时完成以下操作：
# 使用重置弹性内置超级用户的密码
You can complete the following actions at any time:
Reset the password of the elastic built-in superuser with
'bin/elasticsearch-reset-password -u elastic'.

# 使用生成Kibana实例的注册令牌
Generate an enrollment token for Kibana instances with
'bin/elasticsearch-create-enrollment-token -s kibana'.

# 为Elasticsearch节点生成注册令牌
Generate an enrollment token for Elasticsearch nodes with
'bin/elasticsearch-create-enrollment-token -s node'.
```

如果您对Elasticsearch密钥库进行了密码保护，系统将提示您输入密钥库的密码。有关详细信息，请参阅[安全设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/secure-settings.html)。

默认情况下，Elasticsearch将其日志打印到控制台（stdout）和日志目录中的<cluster-name>.log文件。Elasticsearch在启动时会记录一些信息，但在完成初始化后，它将继续在前台运行，在发生值得记录的事情之前不会再记录任何信息。当Elasticsearch运行时，您可以通过其HTTP接口与它进行交互，默认情况下，该接口位于9200端口。

要停止Elasticsearch，请按Ctrl-C。

### 在现有群集中注册节点

当Elasticsearch第一次启动时，安全自动配置过程将HTTP层绑定到0.0.0.0，但仅将传输层绑定到localhost。这种预期行为确保您可以启动默认启用安全性的单节点群集，而无需任何额外配置。

在注册新节点之前，在生产集群中通常需要执行其他操作，例如绑定到本地主机以外的地址或满足引导检查。在此期间，自动生成的注册令牌可能会过期，这就是为什么不会自动生成注册令牌的原因。

此外，只有同一主机上的节点才能加入集群，而无需额外配置。如果您希望其他主机的节点加入群集，则需要将`transport.host`设置为受[支持的值](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-network.html#network-interface-values)（例如取消注释建议值0.0.0.0），或绑定到其他主机可以访问的接口的IP地址。有关详细信息，请参阅[传输设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-network.html#transport-settings)。

要在群集中注册新节点，请在群集中的任何现有节点上使用`elasticsearch-create-enrollment-token`工具创建注册令牌。然后可以使用`--enrollment-token`参数启动一个新节点，使其加入现有集群。

1. 在运行Elasticsearch的独立终端中，导航到安装Elasticearch的目录，并运行[elasticsearch-create-enrollment-token](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/create-enrollment-token.html)工具为新节点生成注册令牌。

   ```bash
   bin/elasticsearch-create-enrollment-token -s node
   
   ```

   复制注册令牌，用于在Elasticsearch集群中注册新节点。

2. 从新节点的安装目录中，启动Elasticsearch并传递带有`--enrollment-token`参数的注册令牌。

   ```bash
   bin/elasticsearch --enrollment-token <enrollment-token>
   
   ```

   Elasticsearch自动在以下`config/certs`目录中生成证书和密钥

3. 对要注册的任何新节点重复上一步骤。

### 检查Elasticsearch是否正在运行

您可以通过向localhost上的9200端口发送HTTPS请求来测试Elasticsearch节点是否正在运行：

```bash
curl --cacert $ES_HOME/config/certs/http_ca.crt -u elastic https://localhost:9200

# 请确保在呼叫中使用https，否则请求将失败。
# --cacert：为http层生成的http_c.crt证书的路径。
```

输入安装期间生成的弹性用户的密码，其应返回如下响应：

```json
{
  "name" : "Cp8oag6",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "AT69_T_DTp-1qgIJlatQqA",
  "version" : {
    "number" : "8.6.0",
    "build_type" : "tar",
    "build_hash" : "f27399d",
    "build_flavor" : "default",
    "build_date" : "2016-03-30T09:51:41.449Z",
    "build_snapshot" : false,
    "lucene_version" : "9.4.2",
    "minimum_wire_compatibility_version" : "1.2.3",
    "minimum_index_compatibility_version" : "1.2.3"
  },
  "tagline" : "You Know, for Search"
}
```

可以使用命令行上的`-q`或`--quiet`选项禁用打印到stdout的日志。

### 作为守护程序运行

要将Elasticsearch作为守护程序运行，请在命令行中指定`-d`，并使用`-p`选项将进程ID记录在文件中：

```bash
./bin/elasticsearch -d -p pid

```

如果您对Elasticsearch密钥库进行了密码保护，系统将提示您输入密钥库的密码。

日志消息可以在`$ES_HOME/logs/`目录中找到。

要关闭Elasticsearch，请关闭pid文件中记录的进程ID：

```bash
pkill -F pid
```

### 在命令行上配置Elasticsearch

默认情况下，Elasticsearch从`$ES_HOME/config/lasticsearch.yml`文件加载其配置。[配置Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html)中解释了此配置文件的格式。

可以在配置文件中指定的任何设置也可以在命令行上指定，使用-E语法如下：

```bash
./bin/elasticsearch -d -Ecluster.name=my_cluster -Enode.name=node_1

```

### 将客户端连接到Elasticsearch

当您第一次启动Elasticsearch时，TLS会自动为HTTP层配置。CA证书生成并存储在磁盘上：

```bash
$ES_HOME/config/certs/http_ca.crt

```

 该证书的十六进制编码的SHA-256指纹也被输出到终端。任何连接到Elasticsearch的客户端，如[Elasticearch客户端](https://www.elastic.co/guide/en/elasticsearch/client/index.html)、Beats、独立ElasticAgent和Logstash，都必须验证它们是否信任Elasticsearch用于HTTPS的证书。舰队服务器和舰队管理的弹性代理自动配置为信任CA证书。其他客户端可以通过使用CA证书的指纹或CA证书本身来建立信任。

如果自动配置过程已经完成，您仍然可以获得安全证书的指纹。您还可以将CA证书复制到计算机上，并配置客户端使用它。

#### 使用CA指纹

复制Elasticsearch启动时输出到终端的指纹值，并将客户端配置为在连接到Elasticsearch时使用此指纹建立信任。

如果自动配置过程已经完成，您仍然可以通过运行以下命令获取安全证书的指纹。该路径指向自动生成的HTTP层CA证书。

```bash
openssl x509 -fingerprint -sha256 -in config/certs/http_ca.crt

```

该命令返回安全证书，包括指纹。

发行人应为`Elasticsearch security auto-configuration HTTP CA`。

```bash
issuer= /CN=Elasticsearch security auto-configuration HTTP CA
SHA256 Fingerprint=<fingerprint>
```

#### 使用CA证书

如果您的库不支持验证指纹的方法，则会在每个Elasticsearch节点的以下目录中创建自动生成的CA证书：

```bash
$ES_HOME/config/certs/http_ca.crt

```

将`http_ca.crt`文件复制到您的计算机，并配置您的客户端，使其在连接到Elasticsearch时使用此证书建立信任。

### 档案目录布局

存档发行版完全独立。默认情况下，所有文件和目录都包含在`$ES_HOME`中 — 解压缩存档文件时创建的目录。

这非常方便，因为您不必创建任何目录即可开始使用Elasticsearch，卸载Elasticearch就像删除`$ES_HOME`目录一样简单。但是，建议更改配置目录、数据目录和日志目录的默认位置，以便以后不会删除重要数据。

| 类型        | 描述                                                         | 默认位置                | 环境                                                         |
| ----------- | ------------------------------------------------------------ | ----------------------- | ------------------------------------------------------------ |
| **home**    | Elasticsearch 主目录或 `$ES_HOME`                            | 通过解压存档创建的目录  |                                                              |
| **bin**     | 二进制脚本，包括用于启动节点的 elasticsearch 和用于安装插件的 elasticsearch-plugin | `$ES_HOME/bin`          |                                                              |
| **conf**    | 配置文件包括`elasticsearch.yml`                              | `$ES_HOME/config`       | [ES_PATH_CONF](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#config-files-location) |
| **conf**    | 为传输层和 HTTP 层生成的 TLS 密钥和证书。                    | `$ES_HOME/config/certs` |                                                              |
| **data**    | 节点上分配的每个索引/分片的数据文件的位置。                  | `$ES_HOME/data`         | `path.data`                                                  |
| **logs**    | 日志文件位置。                                               | `$ES_HOME/logs`         | `path.logs`                                                  |
| **plugins** | 插件文件位置。每个插件都将包含在一个子目录中。               | `$ES_HOME/plugins`      |                                                              |
| **repo**    | 共享文件系统存储库位置。可以容纳多个位置。文件系统存储库可以放在此处指定的任何目录的任何子目录中。 | 未配置                  | `path.repo`                                                  |

#### 安全证书和密钥

当您安装Elasticsearch时，Elasticearch配置目录中会生成以下证书和密钥，这些证书和密钥用于将Kibana实例连接到安全的Elasticsearch集群并加密节点间通信。此处列出的文件仅供参考。

- `http_ca.crt`

  用于签署此Elasticsearch集群的HTTP层证书的CA证书。

- `http.p12`

  包含此节点的HTTP层密钥和证书的密钥库。

- `transport.p12`

  包含群集中所有节点的传输层密钥和证书的密钥库。

http.p12和transport.p12是受密码保护的PKCS#12密钥库。Elasticsearch将这些密钥库的密码存储为安全设置。要检索密码以便您可以检查或更改密钥库内容，请使用bin/selasticsearch密钥库工具。

使用以下命令检索http.p12的密码：

```bash
bin/elasticsearch-keystore show xpack.security.http.ssl.keystore.secure_password

```

使用以下命令检索 transport.p12 的密码：

```bash
bin/elasticsearch-keystore show xpack.security.transport.ssl.keystore.secure_password

```



## 配置

配置文件应该包含特定于节点的设置（例如`node.name`和路径），或者节点为了能够加入集群而需要的设置，例如`cluster.name`和`network.host`。

### 配置文件位置

Elasticsearch 有三个配置文件：

- `elasticsearch.yml`用于配置 Elasticsearch
- `jvm.options`用于配置 Elasticsearch JVM 设置
- `log4j2.properties`用于配置 Elasticsearch 日志记录

这些文件位于 config 目录中，其默认位置取决于安装是来自存档分发（`tar.gz`或 `zip`）还是包分发（Debian 或 RPM 包）。

### 重要的 Elasticsearch 配置

#### 路径设置

Elasticsearch将您索引的数据写入索引，并将数据流写入数据目录。Elasticsearch将自己的应用程序日志写入日志目录，其中包含有关集群运行状况和操作的信息。

默认情况下，数据和日志是`$ES_HOME`的子目录。但是，在升级过程中，`$ES_HOME`中的文件可能会被删除。

在生产中，我们强烈建议您将`elasticsearch.yml`中的`path.data`和`path.logs`设置为`$ES_HOME`之外的位置。默认情况下，Docker、Debian和RPM安装会将数据和日志写入$ES_HOME之外的位置。

```yaml
path:
  data: /var/data/elasticsearch
  logs: /var/log/elasticsearch
```

⚠️警告：不要修改数据目录中的任何内容或运行可能干扰其内容的进程。如果Elasticsearch以外的其他东西修改了数据目录的内容，那么Elasticsearch可能会失败，报告损坏或其他数据不一致，或者可能在默默丢失了一些数据后看起来工作正常。不要尝试对数据目录进行文件系统备份；没有支持的方法来恢复这样的备份。相反，请使用快照和恢复来安全地进行备份。不要在数据目录上运行病毒扫描程序。病毒扫描程序可以阻止Elasticsearch正常工作，并可能修改数据目录的内容。数据目录不包含可执行文件，因此病毒扫描只能发现误报。

#### 群集名称设置

只有当节点与集群中的所有其他节点共享其cluster.name时，节点才能加入集群。默认名称是elasticsearch，但您应该将其更改为描述集群用途的适当名称。

```yaml
cluster.name: logging-prod

```

⚠️警告：不要在不同的环境中重复使用相同的群集名称。否则，节点可能会加入错误的集群。

#### 节点名称设置

Elasticsearch使用node.name作为Elasticsearch特定实例的可读标识符。该名称包含在许多API的响应中。当Elasticsearch启动时，节点名默认为机器的主机名，但可以在`elasticsearch.yml`中显式配置：

```yaml
node.name: prod-data-2

```

#### 网络主机设置

默认情况下，Elasticsearch仅绑定到127.0.0.1和[ : : 1]等环回地址。这足以在单个服务器上运行一个或多个节点的集群进行开发和测试，但[弹性生产集群](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/high-availability-cluster-design.html)必须包含其他服务器上的节点。有许多[网络设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-network.html)，但通常只需配置`network.host`：

```yaml
network.host: 192.168.1.10

```

⚠️警告：当您为XXXX提供值时，Elasticsearch假设您正在从开发模式转到生产模式，并将大量系统启动检查从警告升级为异常。查看[开发模式和生产模式](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/system-config.html#dev-vs-prod)之间的差异。

#### 发现和群集形成设置

在投入生产之前，配置两个重要的发现和集群形成设置，以便集群中的节点可以相互发现并选择主节点。

**`discovery.seed_hosts`**

在没有任何网络配置的情况下，Elasticsearch将立即绑定到可用的环回地址，并扫描本地端口9300到9305，以与同一服务器上运行的其他节点连接。这种行为提供了自动集群体验，而无需进行任何配置。

如果要与其他主机上的节点组成群集，请使用[静态](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#static-cluster-setting)`discovery.seed_hosts`。此设置提供了群集中其他节点的列表，这些节点符合主节点资格，并且可能处于活动状态并可联系，以便为[发现过程](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-discovery-hosts-providers.html)提供种子。此设置接受集群中所有主合格节点的地址的YAML序列或数组。每个地址可以是IP地址，也可以是通过DNS解析为一个或多个IP地址的主机名。

```yaml
discovery.seed_hosts:
   - 192.168.1.10:9300
   - 192.168.1.11  # 该端口是可选的，默认为 9300，但可以被覆盖。
   - seeds.mydomain.com  # 如果一个主机名解析为多个 IP 地址，该节点将尝试发现所有已解析地址的其他节点。
   - [0:0:0:0:0:ffff:c0a8:10c]:9301  # IPv6 地址必须括在方括号中。
```

如果符合主机条件的节点没有固定的名称或地址，请使用[备用主机](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/discovery-hosts-providers.html#built-in-hosts-providers)提供程序动态查找其地址。

**`cluster.initial_master_nodes`**

当您第一次启动Elasticsearch集群时，[集群引导](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-discovery-bootstrap-cluster.html)步骤将确定在第一次选举中投票的主合格节点集。在[开发模式](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/bootstrap-checks.html#dev-vs-prod-mode)下，在未配置发现设置的情况下，此步骤由节点自己自动执行。

因为自动引导[本身就不安全](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-discovery-quorums.html)，所以在生产模式下启动新集群时，必须明确列出在第一次选举中应计算其投票的主节点。您使用`cluster.initial_master_nodes`设置设置此列表。

⚠️警告：首次成功形成群集后，从每个节点的配置中删除`cluster.initial_master_nodes`设置。在重新启动群集或向现有群集添加新节点时，请勿使用此设置。

```yaml
cluster.initial_master_nodes: 
   - master-node-a
   - master-node-b
   - master-node-c
```

请参阅[引导集群](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-discovery-bootstrap-cluster.html)以及[发现和集群形成设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-discovery-settings.html)。

#### 堆大小设置

默认情况下，Elasticsearch根据节点的[角色](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-node.html#node-roles)和总内存自动设置JVM堆大小。我们建议大多数生产环境使用默认大小。

如果需要，可以通过[手动设置JVM堆大小](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/advanced-configuration.html#set-jvm-heap-size)来覆盖默认大小。

#### JVM堆转储路径设置

默认情况下，Elasticsearch将JVM配置为将内存不足异常的堆转储到默认数据目录。在RPM和Debian软件包中，数据目录是/var/lib/selasticsearch。在Linux、MacOS和Windows发行版上，数据目录位于Elasticsearch安装的根目录下。

如果此路径不适合接收堆转储，请修改[`jvm.options`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/advanced-configuration.html#set-jvm-options)中的`-XX:HeapDumpPath=...`条目：

- 如果指定目录，JVM将根据运行实例的PID为堆转储生成文件名。
- 如果指定固定的文件名而不是目录，则当JVM需要对内存不足异常执行堆转储时，该文件必须不存在。否则，堆转储将失败。

#### GC日志记录设置

默认情况下，Elasticsearch启用垃圾收集（GC）日志。这些在[`jvm.options`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/advanced-configuration.html#set-jvm-options)中配置，并输出到与Elasticsearch日志相同的默认位置。默认配置每64 MB循环一次日志，最多可消耗2 GB的磁盘空间。

#### 示例

通过使用一些示例选项创建`$ES_HOME/config/jvm.options.d/gc.options`，将默认GC日志输出位置更改为`/opt/my-app/gc.log`：

```bash
# 关闭所有以前的日志记录配置
-Xlog:disable

# JEP 158的默认设置，但使用"utctime"而不是"uptime"来匹配下一行
-Xlog:all=warning:stderr:utctime,level,tags

# 使用多种选项启用到自定义位置的GC日志记录
-Xlog:gc*,gc+age=trace,safepoint:file=/opt/my-app/gc.log:utctime,pid,tags:filecount=32,filesize=64m
```

配置Elasticsearch Docker容器以将GC调试日志发送到标准错误（stderr）。这让容器编排器处理输出。如果使用ES_JAVA_OPTS环境变量，请指定：

```bash
MY_OPTS="-Xlog:disable -Xlog:all=warning:stderr:utctime,level,tags -Xlog:gc=debug:stderr:utctime"
docker run -e ES_JAVA_OPTS="$MY_OPTS" # etc
```

#### 群集备份

在灾难中，[快照](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/snapshot-restore.html)可以防止永久数据丢失。[快照生命周期管理](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/snapshots-take-snapshot.html#automate-snapshots-slm)是对群集进行定期备份的最简单方法。有关详细信息，请参见[创建快照](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/snapshots-take-snapshot.html)。

⚠️警告：**拍摄快照是备份群集的唯一可靠且受支持的方法。**您不能通过复制Elasticsearch集群节点的数据目录来备份该集群。不支持从文件系统级备份恢复任何数据的方法。如果您尝试从这样的备份还原群集，则可能会失败，并报告损坏或丢失文件或其他数据不一致，或者可能已成功地默默丢失了部分数据。



### 安全设置

有些设置是敏感的，依靠文件系统权限来保护其值是不够的。对于这个用例，Elasticsearch提供了一个密钥库和 [`elasticsearch-keystore`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/elasticsearch-keystore.html)工具来管理密钥库中的设置。

⚠️警告：只有一些设置被设计为从密钥库中读取。但是，密钥库没有验证来阻止不受支持的设置。向密钥库添加不受支持的设置会导致Elasticsearch无法启动。要查看密钥库中是否支持设置，请在设置引用中查找"安全"限定符。

只有在重新启动Elasticsearch后，对密钥库的所有修改才会生效。

这些设置，就像`elasticsearch.yml`配置文件中的常规设置一样，需要在集群中的每个节点上指定。目前，所有安全设置都是node-specific设置，每个节点上必须具有相同的值。

#### 可重新加载的安全设置

与elasticsearch.yml中的设置值一样，对密钥库内容的更改不会自动应用于正在运行的elasticsearch节点。重新读取设置需要重新启动节点。但是，某些安全设置被标记为可**重新加载**。这些设置[可以重新读取并应用于正在运行的节点](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-nodes-reload-secure-settings.html)。

所有安全设置的值（无论是否可重新加载）在所有群集节点上必须相同。使用`bin/elasticsearch-keystore add`命令更改所需的安全设置后，调用：

```bash
POST _nodes/reload_secure_settings
{
  "secure_settings_password": "keystore-password"  # 用于加密 Elasticsearch 密钥库的密码。
}
```

该API解密并重新读取每个集群节点上的整个密钥库，但只应用可重新加载的安全设置。对其他设置的更改在下次重新启动之前不会生效。调用返回后，重新加载已完成，这意味着依赖于这些设置的所有内部数据结构都已更改。所有设置从一开始就应该看起来具有新值。

当更改多个可重新加载的安全设置时，请在每个群集节点上修改所有设置，然后发出[`reload_secure_settings`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-nodes-reload-secure-settings.html)调用，而不是在每次修改后重新加载。

有可重新加载的安全设置：

- [The Azure repository plugin](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/repository-azure.html)
- [The EC2 discovery plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/8.6/discovery-ec2-usage.html#_configuring_ec2_discovery)
- [The GCS repository plugin](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/repository-gcs.html)
- [The S3 repository plugin](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/repository-s3.html)
- [Monitoring settings](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/monitoring-settings.html)
- [Watcher settings](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/notification-settings.html)



### 审核安全设置

您可以使用审核日志记录来记录与安全相关的事件，例如身份验证失败、拒绝连接和数据访问事件。此外，还记录了通过API对安全配置的更改，例如创建、更新和删除本地和内置用户、角色、角色映射和API密钥。

如果已配置，则必须在群集中的每个节点上设置审核设置。静态设置（如`xpack.security.audit.enabled`）必须在每个节点上的`elasticsearch.yml`中配置。对于动态审核设置，请[使用群集更新设置API](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-update-settings.html)确保所有节点上的设置相同。

#### 常规审核设置

**`xpack.security.audit.enabled`**

（[静态](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#static-cluster-setting)）设置为`true`以启用节点上的审核。默认值为`false`。这会将审核事件放入每个节点上名为`<clustername>_audit.json`的专用文件中。

如果启用，则必须在集群中的所有节点上的`elasticsearch.yml`中配置此设置。

#### 已审核事件设置

可以使用以下设置控制事件和其他有关记录内容的信息：

**`xpack.security.audit.logfile.events.include`**

（[动态](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)）指定要在审核输出中打印的[事件类型](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/audit-event-types.html)。此外，`_all`可以用于彻底审计所有事件，但这通常是不鼓励的，因为它会变得非常冗长。默认列表值包含：`access_denied, access_granted, anonymous_access_denied, authentication_failed, connection_denied, tampered_request, run_as_denied, run_as_granted, security_config_change`.

**`xpack.security.audit.logfile.events.exclude`**

（动态）从包含列表中排除指定类型的事件。这在`events.include`设置包含特殊值`_all`的情况下非常有用。默认为空列表。

**`xpack.security.audit.logfile.events.emit_request_body`**

（Dynamic）指定是否将REST请求的完整请求体作为某些类型审核事件的属性。此设置可用于[审核搜索查询](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/auditing-search-queries.html)。

默认值为false，因此不打印请求主体。

**重要的**：请注意，在审核事件中包含请求主体时，可能会以明文形式审核敏感数据，即使所有安全API（如更改用户密码的API）在审核时都会过滤掉凭据。

#### 本地节点信息设置

**`xpack.security.audit.logfile.emit_node_name`**

（动态）指定是否将节点名称作为字段包含在每个审核事件中。默认值为false。

**`xpack.security.audit.logfile.emit_node_host_address`**

（动态）指定是否将节点的IP地址作为字段包含在每个审核事件中。默认值为false。

**`xpack.security.audit.logfile.emit_node_host_name`**

（动态）指定是否将节点的主机名作为字段包含在每个审核事件中。默认值为false。

**`xpack.security.audit.logfile.emit_node_id`**

（Dynamic）指定是否将节点id作为字段包含在每个审核事件中。与节点名（如果管理员更改配置文件中的设置，其值可能会更改）不同，节点id将在集群重新启动时保持不变，管理员无法更改它。默认值为true。

#### 审核日志文件事件忽略策略

以下设置影响忽略策略，这些策略允许对哪些审核事件打印到日志文件进行细粒度控制。具有相同策略名称的所有设置组合成一个策略。如果事件符合任何策略的所有条件，则将忽略该事件，并且不打印该事件。大多数审核事件都受忽略策略的约束。唯一的例外是`security_config_change`类型的事件，除非完全排除，否则无法过滤掉这些事件。

**`xpack.security.audit.logfile.events.ignore_filters.<policy_name>.users`**

（动态）用户名或通配符列表。指定的策略不会为匹配这些值的用户打印审核事件。

**`xpack.security.audit.logfile.events.ignore_filters.<policy_name>.realms`**

（动态）身份验证领域名称或通配符的列表。指定的策略不会为这些领域中的用户打印审核事件。

**`xpack.security.audit.logfile.events.ignore_filters.<policy_name>.actions`**

（动态）动作名称或通配符列表。可以在审核事件的操作字段中找到操作名称。指定的策略不会为与这些值匹配的操作打印审核事件。

**`xpack.security.audit.logfile.events.ignore_filters.<policy_name>.roles`**

（动态）角色名或通配符列表。指定的策略不会为具有这些角色的用户打印审核事件。如果用户具有多个角色，其中一些角色未包含在策略中，则策略将不包含此事件。

**`xpack.security.audit.logfile.events.ignore_filters.<policy_name>.indices`**

（动态）索引名或通配符列表。当事件中的所有索引都与这些值匹配时，指定的策略将不会打印审核事件。如果事件涉及多个指数，其中一些指数不在政策范围内，则政策将不涵盖此事件。



### 断路器设置

Elasticsearch包含多个断路器，用于防止操作导致OutOfMemoryError。每个断路器都指定了它可以使用的内存的限制。此外，还有一个父级断路器，用于指定可在所有断路器中使用的内存总量。

除非另有说明，否则可以使用[cluster-update-settings](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-update-settings.html) API在实时集群上动态更新这些设置。

有关断路器错误的信息，请参见[断路器错误](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/circuit-breaker-errors.html)。

#### 父断路器

可以使用以下设置配置上级断路器：

**`indices.breaker.total.use_real_memory`**

（静态）确定父断路器应考虑实际内存使用情况(true)还是仅考虑子断路器保留的数量(false)。默认为true。

**`indices.breaker.total.limit`**

（动态）总父断路器的启动限制。如果`indices.breaker.total.use_real_memory`为false，则默认为JVM堆的70%。如果`indices.breaker.total.use_real_memory`为true，则默认为JVM堆的95%。

####  现场数据断路器

字段数据断路器估计将字段加载到[字段数据缓存](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-fielddata.html)所需的堆内存。如果加载字段会导致缓存超过预定义的内存限制，断路器将停止操作并返回错误。

**`indices.breaker.fielddata.limit`**

（动态）现场数据断路器限值。默认值为JVM堆的40%。

**`indices.breaker.fielddata.overhead`**

（动态）一个常数，所有现场数据估计值都乘以该常数以确定最终估计值。默认值为`1.03`。

#### 请求断路器

请求断路器允许Elasticsearch防止每个请求的数据结构（例如，用于在请求期间计算聚合的内存）超过一定的内存量。

**`indices.breaker.request.limit`**

（动态）请求中断器的限制，默认为JVM堆的60%。

**`indices.breaker.request.overhead`**

（动态）一个常数，所有请求估计值都乘以该常数以确定最终估计值。默认值为1。

#### 飞行中请求断路器

飞行中请求断路器允许Elasticsearch限制传输或HTTP级别上所有当前活动传入请求的内存使用，使其不超过节点上的特定内存量。内存使用量基于请求本身的内容长度。该断路器还认为，内存不仅是表示原始请求所需的，而且是由默认开销反映的结构化对象。

**`network.breaker.inflight_requests.limit`**

（动态）飞行中请求中断器的限制，默认为JVM堆的100%。这意味着它受到为主断路器配置的限制的约束。

**`network.breaker.inflight_requests.overhead`**

（动态）一个常数，所有飞行中的请求估计值乘以该常数以确定最终估计值。默认值为2。

#### 记帐请求断路器

计费断路器允许Elasticsearch限制请求完成时未释放的内存中的内容的内存使用。这包括Lucene段内存。

**`indices.breaker.accounting.limit`**

（动态）记帐中断器的限制，默认为JVM堆的100%。这意味着它受到为主断路器配置的限制的约束。

**`indices.breaker.accounting.overhead`**

（【动态】）常数：所有会计估计乘以确定最终估计的常数。默认值为1

#### 脚本编译断路器

与之前的`memory-based`断路器略有不同，脚本编译断路器限制了一段时间内内联脚本编译的数量。

有关详细信息，请参阅[脚本](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-scripting-using.html)文档的"prefer-parameters"部分。

**`script.max_compilations_rate`**

（动态）限制某个时间间隔内允许编译的唯一动态脚本的数量。默认值为150/5m，即每5分钟150次。

如果集群定期命中给定的`max_compilation_rate`，则脚本缓存可能大小不足，请使用[Nodes Stats](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-nodes-stats.html)检查最近的缓存逐出次数`script.cache_evictions_history`和编译`script.compilations_history`。如果最近有大量缓存逐出或编译，脚本缓存可能会过小，请考虑通过设置`script.cache.max_size`将脚本缓存的大小加倍。

#### Regex断路器

写得不好的正则表达式会降低集群的稳定性和性能。正则表达式断路器限制了在Painless脚本中正则表达式的使用和复杂性。

**`script.painless.regex.enabled`**

（静态）在Painless脚本中启用正则表达式。接受：

- **`limited` (Default)**

  启用正则表达式，但使用 [`script.painless.regex.limit-factor`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/circuit-breaker.html#script-painless-regex-limit-factor)群集设置限制复杂性。

- **true**

  启用无复杂性限制的正则表达式。禁用正则表达式断路器。

- **false**

  禁用正则表达式。任何包含正则表达式的Painless脚本都会返回错误。

**`script.painless.regex.limit-factor`**

（静态）限制Painless脚本中正则表达式可以考虑的字符数。Elasticsearch通过将设置值乘以脚本输入的字符长度来计算此限制。

例如，输入foobarbaz的字符长度为9。如果`script.painless.regex.limit-factor`是6，foobarbaz上的正则表达式最多可以考虑54（9*6）个字符。如果表达式超过此限制，它将触发正则表达式断路器并返回错误。

Elasticsearch仅在[`script.painless.regex.enabled`](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/circuit-breaker.html#script-painless-regex-enabled)受到限制时适用此限制。

#### EQL断路器

当执行序列查询时，处理查询的节点需要在内存中保留一些结构，这些结构是实现序列匹配的算法所需要的。当需要处理大量数据，和/或用户请求大量匹配的序列（通过设置大小查询参数）时，这些结构占用的内存可能会超过JVM的可用内存。这将导致`OutOfMemory`异常，从而导致节点停机。

为了防止这种情况发生，使用了一个特殊的断路器，它限制了序列查询执行期间的内存分配。当断路器被触发时，将抛出`org.elasticsearch.common.breaker.CircuitBreakingException`，并向用户返回一条描述性错误消息。

该断路器可以使用以下设置进行配置：

**`breaker.eql_sequence.limit`**

（动态）在执行EQL序列查询期间，用于限制内存使用的断路器限制。该值定义为JVM堆的百分比。默认为50%。如果主断路器设置为小于50%的值，则此设置将使用该值作为默认值。

**breaker.eql_sequence.overhead**

（动态）常数：序列查询内存估计值乘以确定最终估计值的常数。默认值为1。

**breaker.eql_sequence.type**

（静态）断路器类型。有效值为：

- **`memory` (Default)**

  断路器限制EQL序列查询的内存使用。

- **noop**

  禁用断路器。

#### 机器学习断路器

**`breaker.model_inference.limit`**

（动态）经过训练的模型断路器的极限。该值定义为JVM堆的百分比。默认为50%。如果主断路器设置为小于50%的值，则此设置将使用该值作为默认值。

**`breaker.model_inference.overhead`**

（动态）常数：所有经过训练的模型估计值乘以确定最终估计值的常数。请参见[断路器设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/circuit-breaker.html)。默认值为1。

**`breaker.model_inference.type`**

（静态）断路器的基本类型。有两个有效的选项：`noop`和`memory`。`noop`意味着断路器不采取任何措施来防止过多的内存使用。`memory`表示断路器跟踪训练模型使用的内存，可能会中断并防止`OutOfMemory`错误。默认值为`memory`。



### 集群级碎片分配和路由设置

碎片分配是将碎片分配给节点的过程。这可能发生在初始恢复、副本分配、重新平衡期间，或者添加或删除节点时。

主机的主要角色之一是决定将哪些碎片分配给哪些节点，以及何时在节点之间移动碎片，以便重新平衡集群。

有许多设置可用于控制碎片分配过程：

- 集群级碎片分配设置控制分配和重新平衡操作。
- 基于磁盘的碎片分配设置解释了Elasticsearch如何考虑可用磁盘空间以及相关设置。
- 碎片分配感知和强制感知控制碎片如何分布在不同的机架或可用性区域。
- 集群级碎片分配过滤允许从分配中排除某些节点或节点组，以便它们可以停用。

除此之外，还有一些其他[杂项的集群级别设置](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/misc-cluster-settings.html)。

#### 群集级碎片分配设置

您可以使用以下设置来控制碎片分配和恢复：

**`cluster.routing.allocation.enable`**

（动态）启用或禁用特定类型碎片的分配：

- `all` - (default)允许为所有类型的碎片分配碎片。
- `primaries` - 仅允许为主碎片分配碎片。
- `new_primaries` - 仅允许为新索引的主碎片分配碎片。
- `none` - 任何索引都不允许任何类型的碎片分配。

此设置不会影响重新启动节点时本地主碎片的恢复。具有未分配主碎片副本的重新启动节点将立即恢复该主碎片，假设其分配id与集群状态中的一个活动分配id匹配。

**`cluster.routing.allocation.node_concurrent_incoming_recoveries`**

（动态）一个节点上允许发生多少并发传入碎片恢复。传入恢复是指在节点上分配目标碎片（很可能是副本，除非碎片正在重新定位）的恢复。默认值为2。

**`cluster.routing.allocation.node_concurrent_outgoing_recoveries`**

（动态）一个节点上允许发生多少并发传出碎片恢复。传出恢复是指在节点上分配源碎片（很可能是主碎片，除非碎片正在重新定位）的恢复。默认值为2。

**`cluster.routing.allocation.node_concurrent_recoveries`**

（动态）设置`cluster.routing.allocation.node_concurrent_incoming_recoveries`和`cluster.routing.allocation.node_concurrent_outgoing_recoveries`的快捷方式。默认值为2。

**`cluster.routing.allocation.node_initial_primaries_recoveries`**

（动态）虽然副本的恢复是通过网络进行的，但在节点重新启动后恢复未分配的主副本时，会使用本地磁盘中的数据。这些恢复应该很快，以便在同一节点上并行进行更多的初始主恢复。默认值为4。

**`cluster.routing.allocation.same_shard.host`**

（动态）如果为`true`，则禁止将碎片的多个副本分配给同一主机上的不同节点，即具有相同网络地址的节点。默认值为`false`，这意味着碎片的副本有时会分配给同一主机上的节点。只有在每个主机上运行多个节点时，此设置才相关。



#### 分片重新平衡配置

当集群在每个节点上具有相同数量的碎片，所有节点都需要相同的资源，而没有来自任何节点上任何索引的碎片集中时，集群是“平衡的”。Elasticsearch运行一个名为“重新平衡”的自动过程，该过程在集群中的节点之间移动碎片，以改善其平衡。重新平衡遵守所有其他碎片分配规则，如[分配过滤](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#cluster-shard-allocation-filtering)和[强制感知](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#forced-awareness)，这可能会阻止它完全平衡集群。在这种情况下，再平衡努力在您配置的规则内实现尽可能平衡的集群。如果您使用的是[数据层](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/data-tiers.html)，则Elasticsearch会自动应用分配过滤规则，将每个碎片放置在适当的层中。这些规则意味着平衡器在每个层中独立工作。

您可以使用以下设置来控制集群中碎片的重新平衡：

**`cluster.routing.rebalance.enable`**

（动态）启用或禁用特定类型碎片的重新平衡：

- `all` - (默认) 允许对所有类型的碎片进行碎片平衡。
- `primaries` - 仅允许对主碎片进行碎片平衡。
- `replicas` - 仅允许对副本碎片进行碎片平衡。
- `none` - 任何索引都不允许任何类型的碎片平衡。

**`cluster.routing.allocation.allow_rebalance`**

（动态） 指定何时允许碎片重新平衡：

- `always` - 始终允许再平衡。
- `indices_primaries_active` - 仅当分配了群集中的所有主节点时。
- `indices_all_active` - (default) 仅当分配了集群中的所有碎片（主碎片和副本）时。

**`cluster.routing.allocation.cluster_concurrent_rebalance`**

（动态）定义整个集群中允许的并发碎片重新平衡的数量。

默认为`2`。请注意，由于集群中的不平衡，此设置仅控制并发碎片重定位的数量。由于[分配过滤](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#cluster-shard-allocation-filtering)或[强制感知](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#forced-awareness)，此设置不限制碎片重定位。

**`cluster.routing.allocation.type`**

Selects the algorithm used for computing the cluster balance. Defaults to `desired_balance` which selects the *desired balance allocator*. This allocator runs a background task which computes the desired balance of shards in the cluster. Once this background task completes, Elasticsearch moves shards to their desired locations.

May also be set to `balanced` to select the legacy *balanced allocator*. This allocator was the default allocator in versions of Elasticsearch before 8.6.0. It runs in the foreground, preventing the master from doing other work in parallel. It works by selecting a small number of shard movements which immediately improve the balance of the cluster, and when those shard movements complete it runs again and selects another few shards to move. Since this allocator makes its decisions based only on the current state of the cluster, it will sometimes move a shard several times while balancing the cluster.

#### 碎片平衡启发式设置

Rebalancing works by computing a *weight* for each node based on its allocation of shards, and then moving shards between nodes to reduce the weight of the heavier nodes and increase the weight of the lighter ones. The cluster is balanced when there is no possible shard movement that can bring the weight of any node closer to the weight of any other node by more than a configurable threshold.

The weight of a node depends on the number of shards it holds and on the total estimated resource usage of those shards expressed in terms of the size of the shard on disk and the number of threads needed to support write traffic to the shard. Elasticsearch estimates the resource usage of shards belonging to data streams when they are created by a rollover. The estimated disk size of the new shard is the mean size of the other shards in the data stream. The estimated write load of the new shard is a weighted average of the actual write loads of recent shards in the data stream. Shards that do not belong to the write index of a data stream have an estimated write load of zero.

The following settings control how Elasticsearch combines these values into an overall measure of each node’s weight.

**`cluster.routing.allocation.balance.shard`**

(float, [Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Defines the weight factor for the total number of shards allocated to each node. Defaults to `0.45f`. Raising this value increases the tendency of Elasticsearch to equalize the total number of shards across nodes ahead of the other balancing variables.

**`cluster.routing.allocation.balance.index`**

(float, [Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Defines the weight factor for the number of shards per index allocated to each node. Defaults to `0.55f`. Raising this value increases the tendency of Elasticsearch to equalize the number of shards of each index across nodes ahead of the other balancing variables.

**`cluster.routing.allocation.balance.disk_usage`**

(float, [Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Defines the weight factor for balancing shards according to their predicted disk size in bytes. Defaults to `2e-11f`. Raising this value increases the tendency of Elasticsearch to equalize the total disk usage across nodes ahead of the other balancing variables.

**`cluster.routing.allocation.balance.write_load`**

(float, [Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Defines the weight factor for the write load of each shard, in terms of the estimated number of indexing threads needed by the shard. Defaults to `10.0f`. Raising this value increases the tendency of Elasticsearch to equalize the total write load across nodes ahead of the other balancing variables.

**`cluster.routing.allocation.balance.threshold`**

(float, [Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) The minimum improvement in weight which triggers a rebalancing shard movement. Defaults to `1.0f`. Raising this value will cause Elasticsearch to stop rebalancing shards sooner, leaving the cluster in a more unbalanced state.

#### Disk-based 碎片分配设置

The disk-based shard allocator ensures that all nodes have enough disk space without performing more shard movements than necessary. It allocates shards based on a pair of thresholds known as the *low watermark* and the *high watermark*. Its primary goal is to ensure that no node exceeds the high watermark, or at least that any such overage is only temporary. If a node exceeds the high watermark then Elasticsearch will solve this by moving some of its shards onto other nodes in the cluster.

The allocator also tries to keep nodes clear of the high watermark by forbidding the allocation of more shards to a node that exceeds the low watermark. Importantly, if all of your nodes have exceeded the low watermark then no new shards can be allocated and Elasticsearch will not be able to move any shards between nodes in order to keep the disk usage below the high watermark. You must ensure that your cluster has enough disk space in total and that there are always some nodes below the low watermark.

Shard movements triggered by the disk-based shard allocator must also satisfy all other shard allocation rules such as [allocation filtering](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#cluster-shard-allocation-filtering) and [forced awareness](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#forced-awareness). If these rules are too strict then they can also prevent the shard movements needed to keep the nodes' disk usage under control. If you are using [data tiers](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/data-tiers.html) then Elasticsearch automatically configures allocation filtering rules to place shards within the appropriate tier, which means that the disk-based shard allocator works independently within each tier.

If a node is filling up its disk faster than Elasticsearch can move shards elsewhere then there is a risk that the disk will completely fill up. To prevent this, as a last resort, once the disk usage reaches the *flood-stage* watermark Elasticsearch will block writes to indices with a shard on the affected node. It will also continue to move shards onto the other nodes in the cluster. When disk usage on the affected node drops below the high watermark, Elasticsearch automatically removes the write block.




It is normal for the nodes in your cluster to be using very different amounts of disk space. The [balance](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#shards-rebalancing-settings) of the cluster depends only on the number of shards on each node and the indices to which those shards belong. It considers neither the sizes of these shards nor the available disk space on each node, for the following reasons:

- Disk usage changes over time. Balancing the disk usage of individual nodes would require a lot more shard movements, perhaps even wastefully undoing earlier movements. Moving a shard consumes resources such as I/O and network bandwidth and may evict data from the filesystem cache. These resources are better spent handling your searches and indexing where possible.
- A cluster with equal disk usage on every node typically performs no better than one that has unequal disk usage, as long as no disk is too full.

You can use the following settings to control disk-based allocation:



**`cluster.routing.allocation.disk.threshold_enabled`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Defaults to `true`. Set to `false` to disable the disk allocation decider. Upon disabling, it will also remove any existing `index.blocks.read_only_allow_delete` index blocks.



**`cluster.routing.allocation.disk.watermark.low`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the low watermark for disk usage. It defaults to `85%`, meaning that Elasticsearch will not allocate shards to nodes that have more than 85% disk used. It can alternatively be set to a ratio value, e.g., `0.85`. It can also be set to an absolute byte value (like `500mb`) to prevent Elasticsearch from allocating shards if less than the specified amount of space is available. This setting has no effect on the primary shards of newly-created indices but will prevent their replicas from being allocated.

**`cluster.routing.allocation.disk.watermark.low.max_headroom`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the max headroom for the low watermark (in case of a percentage/ratio value). Defaults to 200GB when `cluster.routing.allocation.disk.watermark.low` is not explicitly set. This caps the amount of free space required.



**`cluster.routing.allocation.disk.watermark.high` **

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the high watermark. It defaults to `90%`, meaning that Elasticsearch will attempt to relocate shards away from a node whose disk usage is above 90%. It can alternatively be set to a ratio value, e.g., `0.9`. It can also be set to an absolute byte value (similarly to the low watermark) to relocate shards away from a node if it has less than the specified amount of free space. This setting affects the allocation of all shards, whether previously allocated or not.

**`cluster.routing.allocation.disk.watermark.high.max_headroom`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the max headroom for the high watermark (in case of a percentage/ratio value). Defaults to 150GB when `cluster.routing.allocation.disk.watermark.high` is not explicitly set. This caps the amount of free space required.

**`cluster.routing.allocation.disk.watermark.enable_for_single_data_node`**

([Static](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#static-cluster-setting)) In earlier releases, the default behaviour was to disregard disk watermarks for a single data node cluster when making an allocation decision. This is deprecated behavior since 7.14 and has been removed in 8.0. The only valid value for this setting is now `true`. The setting will be removed in a future release.



**`cluster.routing.allocation.disk.watermark.flood_stage` **

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the flood stage watermark, which defaults to 95%. Elasticsearch enforces a read-only index block (`index.blocks.read_only_allow_delete`) on every index that has one or more shards allocated on the node, and that has at least one disk exceeding the flood stage. This setting is a last resort to prevent nodes from running out of disk space. The index block is automatically released when the disk utilization falls below the high watermark. Similarly to the low and high watermark values, it can alternatively be set to a ratio value, e.g., `0.95`, or an absolute byte value.An example of resetting the read-only index block on the `my-index-000001` index:

```bash
PUT /my-index-000001/_settings
{
  "index.blocks.read_only_allow_delete": null
}
```

**`cluster.routing.allocation.disk.watermark.flood_stage.max_headroom`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the max headroom for the flood stage watermark (in case of a percentage/ratio value). Defaults to 100GB when `cluster.routing.allocation.disk.watermark.flood_stage` is not explicitly set. This caps the amount of free space required.

**`cluster.routing.allocation.disk.watermark.flood_stage.frozen` **

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the flood stage watermark for dedicated frozen nodes, which defaults to 95%.



**`cluster.routing.allocation.disk.watermark.flood_stage.frozen.max_headroom` **

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Controls the max headroom for the flood stage watermark (in case of a percentage/ratio value) for dedicated frozen nodes. Defaults to 20GB when `cluster.routing.allocation.disk.watermark.flood_stage.frozen` is not explicitly set. This caps the amount of free space required on dedicated frozen nodes.

**`cluster.info.update.interval`**

([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) How often Elasticsearch should check on disk usage for each node in the cluster. Defaults to `30s`.



An example of updating the low watermark to at least 100 gigabytes free, a high watermark of at least 50 gigabytes free, and a flood stage watermark of 10 gigabytes free, and updating the information about the cluster every minute:

```bash
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.disk.watermark.low": "100gb",
    "cluster.routing.allocation.disk.watermark.high": "50gb",
    "cluster.routing.allocation.disk.watermark.flood_stage": "10gb",
    "cluster.info.update.interval": "1m"
  }
}
```



Concerning the max headroom settings for the watermarks, please note that these apply only in the case that the watermark settings are percentages/ratios. The aim of a max headroom value is to cap the required free disk space before hitting the respective watermark. This is especially useful for servers with larger disks, where a percentage/ratio watermark could translate to a big free disk space requirement, and the max headroom can be used to cap the required free disk space amount. As an example, let us take the default settings for the flood watermark. It has a 95% default value, and the flood max headroom setting has a default value of 100GB. This means that:

- For a smaller disk, e.g., of 100GB, the flood watermark will hit at 95%, meaning at 5GB of free space, since 5GB is smaller than the 100GB max headroom value.
- For a larger disk, e.g., of 100TB, the flood watermark will hit at 100GB of free space. That is because the 95% flood watermark alone would require 5TB of free disk space, but that is capped by the max headroom setting to 100GB.

Finally, the max headroom settings have their default values only if their respective watermark settings are not explicitly set (thus, they have their default percentage values). If watermarks are explicitly set, then the max headroom settings do not have their default values, and would need to be explicitly set if they are desired.

#### 碎片分配意识

You can use custom node attributes as *awareness attributes* to enable Elasticsearch to take your physical hardware configuration into account when allocating shards. If Elasticsearch knows which nodes are on the same physical server, in the same rack, or in the same zone, it can distribute the primary shard and its replica shards to minimise the risk of losing all shard copies in the event of a failure.

When shard allocation awareness is enabled with the [dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting) `cluster.routing.allocation.awareness.attributes` setting, shards are only allocated to nodes that have values set for the specified awareness attributes. If you use multiple awareness attributes, Elasticsearch considers each attribute separately when allocating shards.



#### 启用碎片分配意识

To enable shard allocation awareness:

1. Specify the location of each node with a custom node attribute. For example, if you want Elasticsearch to distribute shards across different racks, you might set an awareness attribute called `rack_id` in each node’s `elasticsearch.yml` config file.

   ```yaml
   node.attr.rack_id: rack_one
   
   ```

   You can also set custom attributes when you start a node:

   ```bash
   ./bin/elasticsearch -Enode.attr.rack_id=rack_one
   
   ```

2. Tell Elasticsearch to take one or more awareness attributes into account when allocating shards by setting `cluster.routing.allocation.awareness.attributes` in **every** master-eligible node’s `elasticsearch.yml` config file.

   ```yaml
   cluster.routing.allocation.awareness.attributes: rack_id  # Specify multiple attributes as a comma-separated list.
   ```

   You can also use the [cluster-update-settings](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/cluster-update-settings.html) API to set or update a cluster’s awareness attributes.

With this example configuration, if you start two nodes with `node.attr.rack_id` set to `rack_one` and create an index with 5 primary shards and 1 replica of each primary, all primaries and replicas are allocated across the two nodes.

If you add two nodes with `node.attr.rack_id` set to `rack_two`, Elasticsearch moves shards to the new nodes, ensuring (if possible) that no two copies of the same shard are in the same rack.

If `rack_two` fails and takes down both its nodes, by default Elasticsearch allocates the lost shard copies to nodes in `rack_one`. To prevent multiple copies of a particular shard from being allocated in the same location, you can enable forced awareness.

#### 强制意识

By default, if one location fails, Elasticsearch assigns all of the missing replica shards to the remaining locations. While you might have sufficient resources across all locations to host your primary and replica shards, a single location might be unable to host **ALL** of the shards.

To prevent a single location from being overloaded in the event of a failure, you can set `cluster.routing.allocation.awareness.force` so no replicas are allocated until nodes are available in another location.

For example, if you have an awareness attribute called `zone` and configure nodes in `zone1` and `zone2`, you can use forced awareness to prevent Elasticsearch from allocating replicas if only one zone is available:

```yaml
cluster.routing.allocation.awareness.attributes: zone
cluster.routing.allocation.awareness.force.zone.values: zone1,zone2  # Specify all possible values for the awareness attribute.
```

With this example configuration, if you start two nodes with `node.attr.zone` set to `zone1` and create an index with 5 shards and 1 replica, Elasticsearch creates the index and allocates the 5 primary shards but no replicas. Replicas are only allocated once nodes with `node.attr.zone` set to `zone2` are available.

#### Cluster-level 碎片分配过滤

You can use cluster-level shard allocation filters to control where Elasticsearch allocates shards from any index. These cluster wide filters are applied in conjunction with [per-index allocation filtering](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/shard-allocation-filtering.html) and [allocation awareness](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/modules-cluster.html#shard-allocation-awareness).

Shard allocation filters can be based on custom node attributes or the built-in `_name`, `_host_ip`, `_publish_ip`, `_ip`, `_host`, `_id` and `_tier` attributes.

The `cluster.routing.allocation` settings are [dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting), enabling live indices to be moved from one set of nodes to another. Shards are only relocated if it is possible to do so without breaking another routing constraint, such as never allocating a primary and replica shard on the same node.

The most common use case for cluster-level shard allocation filtering is when you want to decommission a node. To move shards off of a node prior to shutting it down, you could create a filter that excludes the node by its IP address:

```bash
PUT _cluster/settings
{
  "persistent" : {
    "cluster.routing.allocation.exclude._ip" : "10.0.0.1"
  }
}
```



#### 群集路由设置

- **`cluster.routing.allocation.include.{attribute}`**

  ([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Allocate shards to a node whose `{attribute}` has at least one of the comma-separated values.

- **`cluster.routing.allocation.require.{attribute}`**

  ([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Only allocate shards to a node whose `{attribute}` has *all* of the comma-separated values.

- **`cluster.routing.allocation.exclude.{attribute}`**

  ([Dynamic](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/settings.html#dynamic-cluster-setting)) Do not allocate shards to a node whose `{attribute}` has *any* of the comma-separated values.

The cluster allocation settings support the following built-in attributes:

| `_name`       | Match nodes by node name                                     |
| ------------- | ------------------------------------------------------------ |
| `_host_ip`    | Match nodes by host IP address (IP associated with hostname) |
| `_publish_ip` | Match nodes by publish IP address                            |
| `_ip`         | Match either `_host_ip` or `_publish_ip`                     |
| `_host`       | Match nodes by hostname                                      |
| `_id`         | Match nodes by node id                                       |
| `_tier`       | Match nodes by the node’s [data tier](https://www.elastic.co/guide/en/elasticsearch/reference/8.6/data-tiers.html) role |

You can use wildcards when specifying attribute values, for example:

```bash
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.exclude._ip": "192.168.2.*"
  }
}

```



















