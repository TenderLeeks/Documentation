> 此笔记部分内容为网上资料整理，方便自己查询使用。

# EFK日志分析系统

[官方网站](https://www.elastic.co/cn/what-is/elk-stack)

[官方文档](https://www.elastic.co/guide/en/elastic-stack/current/index.html)

## 环境说明

| 名称             | 版本    | 主机名          | 主机IP         |
| ---------------- | ------- | --------------- | -------------- |
| filebeat/fluentd | 7.16.2/ | filebeat-kibana | 192.168.66.239 |
| kibana           | 7.16.2  | filebeat-kibana | 192.168.66.239 |
| elasticsearch-1  | 7.16.2  | elasticsearch-1 | 192.168.66.43  |
| elasticsearch-2  | 7.16.2  | elasticsearch-2 | 192.168.67.44  |
| elasticsearch-3  | 7.16.2  | elasticsearch-3 | 192.168.66.40  |

**注意：三个组件（elasticsearch，filebeat，kibana）版本必须一致，elasticsearch必须3台以上且总数量为单数。**

## 安装顺序

按以下顺序安装您要使用的 Elastic Stack 产品：

1. Elasticsearch（[安装说明](https://www.elastic.co/guide/en/elasticsearch/reference/8.3/install-elasticsearch.html)）
2. Kibana（[安装](https://www.elastic.co/guide/en/kibana/8.3/install.html)）
3. Logstash（[安装](https://www.elastic.co/guide/en/logstash/8.3/installing-logstash.html)）
4. Beats（[安装说明](https://www.elastic.co/guide/en/beats/libbeat/8.3/getting-started.html)）
5. APM（[安装说明](https://www.elastic.co/guide/en/apm/guide/8.3/apm-quick-start.html)）
6. Elasticsearch Hadoop（[安装说明](https://www.elastic.co/guide/en/elasticsearch/hadoop/8.3/install.html)）

按此顺序安装可确保每个产品所依赖的组件都到位。

## elasticsearch + filebeta + kibana 日志采集

### elasticsearch 安装

1. 下载安装

   ```shell
   $ E_VERSION="7.16.2"
   $ E_HOME="/opt/elasticsearch"
   $ cd /tmp
   $ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${E_VERSION}-linux-x86_64.tar.gz
   $ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${E_VERSION}-linux-x86_64.tar.gz.sha512
   $ shasum -a 512 -c elasticsearch-${E_VERSION}-linux-x86_64.tar.gz.sha512 
   # 比较下载的 .tar.gz 存档的 SHA 和发布的校验和，应该输出 elasticsearch-7.16.2-linux-x86_64.tar.gz: OK
   
   $ tar -zxf elasticsearch-${E_VERSION}-linux-x86_64.tar.gz
   $ mv elasticsearch-${E_VERSION}-linux-x86_64 ${E_HOME}
   $ sudo mkdir -p ${E_HOME}/logs
   $ sudo useradd elasticsearch -d ${E_HOME} -s /sbin/nologin
   $ sudo chown elasticsearch.elasticsearch ${E_HOME} -R
   
   # 限制一个进程可以拥有的VMA(虚拟内存区域)的数量要超过262144，不然elasticsearch会报max virtual memory areas vm.max_map_count [65535] is too low, increase to at least [262144]
   $ echo "vm.max_map_count = 655350" >> /etc/sysctl.conf
   $ sysctl -p
   ```

2. elasticsearch-1 配置

   elasticsearch 详细配置请点击[此处](https://www.elastic.co/guide/en/elasticsearch/reference/index.html)

   ```shell
   $ cat ${E_HOME}/config/elasticsearch.yml
   
   cluster.name: my-application
   node.name: 192.168.66.43
   path.logs: /opt/elasticsearch/logs
   network.host: 192.168.66.43
   http.port: 9200
   transport.port: 9300
   discovery.seed_hosts: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   cluster.initial_master_nodes: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   http.cors.enabled: true
   http.cors.allow-origin: "*"
   gateway.recover_after_nodes: 2
   ```

3. elasticsearch-2 配置

   ```shell
   $ cat ${E_HOME}/config/elasticsearch.yml
   
   cluster.name: my-application
   node.name: 192.168.67.44
   path.logs: /opt/elasticsearch/logs
   network.host: 192.168.67.44
   http.port: 9200
   transport.port: 9300
   discovery.seed_hosts: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   cluster.initial_master_nodes: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   http.cors.enabled: true
   http.cors.allow-origin: "*"
   gateway.recover_after_nodes: 2
   ```

4. elasticsearch-3 配置

   ```shell
   $ cat ${E_HOME}/config/elasticsearch.yml
   
   cluster.name: my-application
   node.name: 192.168.66.40
   path.logs: /opt/elasticsearch/logs
   network.host: 192.168.66.40
   http.port: 9200
   transport.port: 9300
   discovery.seed_hosts: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   cluster.initial_master_nodes: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]
   http.cors.enabled: true
   http.cors.allow-origin: "*"
   gateway.recover_after_nodes: 2
   ```

5. 验证是否成功

   ```shell
   $ curl 192.168.66.43:9200
   {
     "name" : "192.168.66.43",
     "cluster_name" : "my-application",
     "cluster_uuid" : "YiLx8zVmSKOfvE8-OeoI1w",
     "version" : {
       "number" : "7.16.2",
       "build_flavor" : "default",
       "build_type" : "tar",
       "build_hash" : "2b937c44140b6559905130a8650c64dbd0879cfb",
       "build_date" : "2021-12-18T19:42:46.604893745Z",
       "build_snapshot" : false,
       "lucene_version" : "8.10.1",
       "minimum_wire_compatibility_version" : "6.8.0",
       "minimum_index_compatibility_version" : "6.0.0-beta1"
     },
     "tagline" : "You Know, for Search"
   }
   
   $ curl 192.168.67.44:9200
   {
     "name" : "192.168.67.44",
     "cluster_name" : "my-application",
     "cluster_uuid" : "YiLx8zVmSKOfvE8-OeoI1w",
     "version" : {
       "number" : "7.16.2",
       "build_flavor" : "default",
       "build_type" : "tar",
       "build_hash" : "2b937c44140b6559905130a8650c64dbd0879cfb",
       "build_date" : "2021-12-18T19:42:46.604893745Z",
       "build_snapshot" : false,
       "lucene_version" : "8.10.1",
       "minimum_wire_compatibility_version" : "6.8.0",
       "minimum_index_compatibility_version" : "6.0.0-beta1"
     },
     "tagline" : "You Know, for Search"
   }
   
   $ curl 192.168.66.40:9200
   {
     "name" : "192.168.66.40",
     "cluster_name" : "my-application",
     "cluster_uuid" : "YiLx8zVmSKOfvE8-OeoI1w",
     "version" : {
       "number" : "7.16.2",
       "build_flavor" : "default",
       "build_type" : "tar",
       "build_hash" : "2b937c44140b6559905130a8650c64dbd0879cfb",
       "build_date" : "2021-12-18T19:42:46.604893745Z",
       "build_snapshot" : false,
       "lucene_version" : "8.10.1",
       "minimum_wire_compatibility_version" : "6.8.0",
       "minimum_index_compatibility_version" : "6.0.0-beta1"
     },
     "tagline" : "You Know, for Search"
   }
   ```

6. 管理服务

   ```shell
   # 启动服务
   $ sudo -u elasticsearch /opt/elasticsearch/bin/elasticsearch -d
   ```

7. 检查集群是否部署成功

   ```shell
   $ http://192.168.67.44:9200/_cluster/state?pretty
   ```

   

### filebeat 安装

1. 下载安装

   ```shell
   $ F_VERSION="7.16.2"
   $ F_HOME="/opt/filebeat"
   $ cd /tmp
   $ wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${F_VERSION}-linux-x86_64.tar.gz
   $ tar -zxf filebeat-${F_VERSION}-linux-x86_64.tar.gz
   $ mv filebeat-${F_VERSION}-linux-x86_64 ${F_HOME}
   $ mkdir -p ${F_HOME}/logs/
   
   ```

2. 配置

   filebeat详细配置请点击[此处](https://www.elastic.co/guide/en/beats/filebeat/index.html)

   ```shell
   $ cat ${F_HOME}/filebeat.yml
   ```

   ```yaml
   filebeat.inputs:
   - type: log  
     enabled: true
     paths:
       - /opt/aelf-node/Logs/*.log
     scan_frequency: 10s
     fields:
       type: aelf_node
   filebeat.config.modules:
     path: ${path.config}/modules.d/*.yml
     reload.enabled: false
   setup.template.enabled: false
   setup.template.settings:
     index.number_of_shards: 1
   setup.kibana:
   output.elasticsearch:
     hosts: ["http://192.168.66.43:9200", "http://192.168.67.44:9200", "http://192.168.66.40:9200"]
     indices:
       - index: "aelf_node_%{+yyyy.MM.dd}"
         when.equals:
           fields.type: "aelf_node"
   processors:
     - add_host_metadata:
         when.not.contains.tags: forwarded
     - add_cloud_metadata: ~
     - add_docker_metadata: ~
     - add_kubernetes_metadata: ~
   logging.to_files: true
   logging.level: info
   
   logging.files:
     path: /opt/logs/filebeat/
     name: filebeat
     keepfiles: 7
     permissions: 0600
   ```

3. 管理服务

   ```shell
   # 启动服务(前台运行)
   $ /opt/filebeat/filebeat -e -c /opt/filebeat/filebeat.yml -d "publish"
   ```

   

### kibana 安装

1. 下载

   ```shell
   $ K_VERSION="7.16.2"
   $ K_HOME="/opt/kibana"
   $ cd /tmp
   $ wget https://artifacts.elastic.co/downloads/kibana/kibana-${K_VERSION}-linux-x86_64.tar.gz
   $ tar -zxf kibana-${K_VERSION}-linux-x86_64.tar.gz
   $ mv kibana-${K_VERSION}-linux-x86_64 ${K_HOME}
   $ useradd kibana -d ${K_HOME} -s /sbin/nologin
   $ chown kibana.kibana ${K_HOME} -R
   ```

2. 配置

   ```shell
   $ cat ${K_HOME}/config/kibana.yml
   ```

   ```yaml
   server.port: 5601
   server.host: "192.168.66.239"
   server.name: "192.168.66.239"
   elasticsearch.hosts: ["http://192.168.66.43:9200", "http://192.168.67.44:9200", "http://192.168.66.40:9200"]
   i18n.locale: "zh-CN"
   ```

3. 管理服务

   ```shell
   # 启动服务(前台运行)
   $ sudo -u kibana /opt/kibana/bin/kibana -c /opt/kibana/config/kibana.yml
   ```

   

## kibana 界面配置







## filebeat 配置说明

```yaml
# 文件输入
filebeat.inputs:
- type: log  # 文件输入类型
  enabled: true  # 开启加载
  paths:
    - /opt/aelf-node/Logs/*.log  # 文件位置
  scan_frequency: 10s  # 扫描频率
  fields:   # 自定义参数
    type: aelf_node  # 类型是 aelf_node,和上面fields.type是一致的

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.enabled: false  # 关闭自带模板
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:

# 输出至elasticsearch
output.elasticsearch:
  # elasticsearch集群
  hosts: ["http://192.168.66.43:9200", "http://192.168.67.44:9200", "http://192.168.66.40:9200"]
  indices:  # 索引配置
    - index: "aelf_node_%{+yyyy.MM.dd}"  # 索引名
      when.equals:  # 当类型是 aelf_node 时使用此索引
        fields.type: "aelf_node"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~

logging.to_files: true  # 开启日志记录
logging.level: info  # 日志等级

logging.files:  # 日志文件
  path: /opt/filebeat/logs/  # 日志位置
  name: filebeat  # 日志名字
  keepfiles: 7  # 日志轮转期限，必须要2~1024
  permissions: 0600  # 日志轮转权限
```

## kibana 配置说明

```yaml
server.port: 5601  # 本节点访问端口
server.host: "192.168.66.65"  # 本节点IP
server.name: "192.168.66.65"  # 本节点名字
# elasticsearch集群IP
elasticsearch.hosts: ["http://192.168.66.43:9200", "http://192.168.67.44:9200", "http://192.168.66.40:9200"]
i18n.locale: "zh-CN"
```

## elasticsearch 配置说明

```yaml
cluster.name: my-application  # 集群名字
node.name: ${HOSTNAME}  # 节点名字
path.logs: /opt/elasticsearch/logs  # 日志位置
network.host: 192.168.66.43  # 本节点访问IP
http.port: 9200  # 本节点访问
transport.port: 9300  # 节点运输端口
discovery.seed_hosts: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]  # 集群中其他主机的列表
# 首次启动全新的Elasticsearch集群时，在第一次选举中便对其票数进行计数的master节点的集合
cluster.initial_master_nodes: ["192.168.66.43", "192.168.67.44", "192.168.66.40"]

# 启用跨域资源共享
http.cors.enabled: true
http.cors.allow-origin: "*"

gateway.recover_after_nodes: 2  # 只要有2台数据或主节点已加入集群，就可以恢复
```



参考：

https://blog.51cto.com/cyent/2445813