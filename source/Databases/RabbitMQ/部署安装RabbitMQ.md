# 简单部署RabbitMQ服务

```shell
# 1.安装erlang
# 由于rabbitMq需要erlang语言的支持，在安装rabbitMq之前需要安装erlang
$ sudo apt-get install erlang-nox

# 2.安装Rabbitmq
# 更新源
$ sudo apt-get update
# 安装
$ sudo apt-get install rabbitmq-server

# 启动
$ sudo rabbitmq-server start
# 停止
$ sudo rabbitmq-server stop
# 重启
$ sudo rabbitmq-server restart
# 查看状态
$ sudo rabbitmqctl status

# 3.添加admin，并赋予administrator权限
# 添加admin用户，密码设置为admin。
$ sudo rabbitmqctl add_user admin admin  
# 赋予权限
$ sudo rabbitmqctl set_user_tags admin administrator
# 赋予virtual host中所有资源的配置、写、读权限以便管理其中的资源
$ sudo rabbitmqctl set_permissions -p / admin '.*' '.*' '.*'

# 4.RabbitMQ GUID使用
# 官方提供的一个web管理工具（rabbitmq_management）http://www.rabbitmq.com/management.html
# 安装了Rabbitmq后，默认也安装了该管理工具，执行命令即可启动
$ sudo rabbitmq-plugins enable rabbitmq_management

# 浏览器访问 http://localhost:15672/
# 使用刚刚创建的admin就可以登录，密码也为admin

```

