# Amazon CloudWatch Logs 收集 EC2 日志

1. 说明

   - [官方文档](https://docs.amazonaws.cn/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
   - 可以使用 Amazon CloudWatch Logs 监控、存储和访问来自 Amazon Elastic Compute Cloud (Amazon EC2) 实例、Amazon CloudTrail、Route 53 和其他来源的日志文件。
   - CloudWatch Logs 能够将所有系统、应用程序和Amazon服务中的日志集中在一个高度可扩展的单个服务中。可以轻松地查看日志、在日志中搜索特定错误代码或模式、根据特定字段筛选日志，或者安全地将这些日志归档以供将来分析。
   - CloudWatch Logs 能够将所有日志（无论其来源如何）视为按时间排序的单一且一致的事件流，可以查询它们并根据其他维度对其进行排序、按特定字段对它们进行分组、使用强大的查询语言创建自定义计算，并在控制面板中可视化日志数据。

2. 安装 Agent

   [参考文档](https://docs.amazonaws.cn/AmazonCloudWatch/latest/monitoring/download-cloudwatch-agent-commandline.html)

   ```shell
   $ wget https://s3.cn-north-1.amazonaws.com.cn/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -P /tmp
   $ dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
   # 安装成功后会生成 /opt/aws 文件夹
   $ ls /opt/aws/
   amazon-cloudwatch-agent
   
   $ /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
   {
     "status": "stopped",
     "starttime": "",
     "configstatus": "not configured",
     "cwoc_status": "stopped",
     "cwoc_starttime": "",
     "cwoc_configstatus": "not configured",
     "version": "1.247354.0b251981"
   }
   ```

3. 配置 Agent

   [日志配置参考文档](https://docs.amazonaws.cn/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html#CloudWatch-Agent-Configuration-File-Logssection)

   ```shell
   $ tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
   {
         "agent": {
           "metrics_collection_interval": 10,
           "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
         },
         "logs": {
           "logs_collected": {
             "files": {
               "collect_list": [
                 {
                   "file_path": "/opt/api-wallet-server/Logs/logs.txt",
                   "log_group_name": "{local_hostname}",
                   "log_stream_name": "wallet-app-scan-mainchain",
                   "retention_in_days": 30,
                   "timezone": "UTC"
                 }
               ]
             }
           },
           "log_stream_name": "my_log_stream_name",
           "force_flush_interval" : 15
         }
   }
   EOF
   
   $ cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
   ```

4. EC2 配置 IAM 权限

   [参考文档](https://docs.amazonaws.cn/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-commandline-fleet.html#install-CloudWatch-Agent-iam_permissions-first)

5. 启动 Agent

   [参考文档](https://docs.amazonaws.cn/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance-fleet.html#start-CloudWatch-Agent-EC2-fleet)

   ```shell
   $ /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
   
   $ /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
   {
     "status": "running",
     "starttime": "2022-07-28T06:25:23+00:00",
     "configstatus": "configured",
     "cwoc_status": "stopped",
     "cwoc_starttime": "",
     "cwoc_configstatus": "not configured",
     "version": "1.247354.0b251981"
   }
   
   $ tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
   ```

   

