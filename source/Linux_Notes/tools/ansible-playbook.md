# ansible-playbook 使用

## YAML语法

- YAML的语法和其他高阶语言类似并且可以简单表达清单、散列表、标量等数据结构。（列表用横杆表示，键值对用冒号分割，键值对里又可以嵌套另外的键值对）
- YAML文件扩展名通常为.yaml或者.yml。下面为示例
- 一定要对齐，只能使用空格

```yaml
name: tom
age: 21
gender: male
spourse:
    name: lily
    gender: female
children:
    - name: susan
      age: 2
      gender: feamle
    - name: sunny
      age: 10
      gender: male
```

## 核心组件

```
tasks：    任务
variables：变量
templates：模板
handlers： 处理器
roles：    角色
```

## playbook简单示例

### 第一个示例

```yaml
# first.yml
- hosts: all
  remote_user: root
  vars: httpd_port=80
 
  tasks:
  - name: install httpd
    yum: name=httpd state=present
  - name: install php
    yum: name=php state=present
  - name: start httpd
    service: name=httpd state=started enabled=true
```

 

```tex
hosts           定义单个主机或组
vars            定义变量
remote_user     定义执行命令的远程用户
tasks           定义执行哪些命令
handlers        定义调用哪些处理器
vars(变量)：
    变量命名： 字母数字下划线组成，只能以字母开头
    变量种类：
        1.facts（内置变量）
            由远程主机发回的主机属性信息，这些信息被保存在ansible变量当中
            例如：ansible 192.168.238.170 -m setup  来获取远程主机上的属性信息，这些属性信息保存在facts中
        2.通过命令行传递
            通过命令行传递：ansible-playbook test.yml --extra-vars “host=www user=tom“（如果剧本中已有此处定义的变量则会被覆盖）
        3.通过roles传递
        4.主机变量
            在/etc/ansible/hosts中定义
            [web1]
            192.168.1.1 name=haha
        5.组变量
            [group_name:vars]
            foo=bar
hosts :
/etc/abible/hosts   中指定的远程主机，并用指定的属性进行连接
    ansible_ssh_port 连接远程主机使用的端口
    ansible_ssh_user 连接远程主机使用的用户
    ansible_ssh_pass 连接远程主机使用的密码
    cat /etc/ansible/hosts
    [web1]
    web1.hostname ansible_ssh_port=22 ansible_ssh_user=root ansible_ssh_pass=123
    web2.hostname
```

### 第二个示例

```yaml
# /root/second.yml
- hosts: web1
  remote_user: root
  vars:
    username: bob
    password: 123
   
  tasks:
  - name: add user
    user: name={{ username }} state=present
    when: ansible_os_family == "Debian"
  - name: set password
    shell: echo {{ password }} |passwd --stdin {{ username }}
  - name: install httpd php
    yum: name={{ item }} state=present
    with_items:
      - httpd
      - php
  - name: add two users
    user: name={{ item }} state=present groups={{ item.groups }}
    with_items:
    - { name: 'user1', groups: 'group1'}
    - { name: 'user2', groups: 'group2'}
```

- 在 playbook 中调用变量的方式为 {{ variable }}
- when 语句用来条件测试
- ansible_os_family 是 facts 中内置的属性信息  ansible_os_family 的信息可以使用 ansible all -m setup | grep ansible_os_family 查看
- 在task中调用内置的item变量；在某task后面使用with_items语句来定义元素列表

### 第三个示例

```yaml
# /root/third.yml 

- hosts: web1
  remote_user: root
  vars:
    httpd_port=80
 
  tasks:
  - name: install httpd
    yum: name=httpd state=present
  - name: install php
    yum: name=php state=present
  - name: copy config file
    copy: src=/root/httpd.conf dest=/etc/httpd/conf/httpd.conf
    notify: restart httpd
  - name: start httpd
    service: name=httpd state=started enabled=true
   
  handlers:
  - name: restart httpd
    service: name=httpd state=restarted
```

- 上面的意思是 copy 中复制过去的文件跟远程主机上的文件不同，就通过 notify 调用 handlers，即重启 httpd 服务。
- handler 是重启服务是最通用的用法

### 第四个示例

```shell
$ cat /etc/ansible/hosts
[web1]
192.168.1.1 http_port=80

$ cat /root/httpd.conf
……
Listen {{ http_port }}
……
```



```yaml
# /root/fourth.yml
- hosts: web1
  remote_user: root
  vars:
    httpd_port=80
 
  tasks:
  - name: install httpd
    yum: name=httpd state=present
  - name: copy config file
    template: src=/root/httpd.conf dest=/etc/httpd/conf/httpd.conf
    notify: restart httpd
  - name: start httpd
    service: name=httpd state=started enabled=true
   
  handlers:
  - name: restart httpd
    service: name=httpd state=restarted
```

- templates：用于生成文本文件（配置文件）
- 模板文件中可使用jinja2表达式，表达式要定义在{{ }}，也可以简单地仅执行变量替换

### 第五个示例

roles：roles用于实现“代码复用”，roles以特定的层次型格式组织起来的playbook元素（variables, tasks, templates,handlers）；可被playbook以role的名字直接进行调用

roles的文件结构:

```tex
files/：     此角色中用到的所有文件均放置于此目录中
templates/： Jinja2模板文件存放位置
tasks/：     任务列表文件；可以有多个，但至少有一个叫做main.yml的文件
handlers/：  处理器列表文件；可以有多个，但至少有一个叫做main.yml的文件
vars/：      变量字典文件；可以有多个，但至少有一个叫做main.yml的文件
meta/：      此角色的特殊设定及依赖关系
```

```shell
$ mkdir /root/roles
$ cd /root/roles
$ mkdir -p web1/{files,templates,tasks,handlers,vars,meta}
$ cat web1/vars/main.yml
user: tom
group: tom
http_port: 8080
```

 

```yaml
# web1/tasks/main.yml
- name: install httpd
  yum: name=httpd state=present
- name: copy config file
  template: src=httpd.conf dest=/etc/httpd/conf/httpd.conf
  notify: restart httpd
  tags: conf
- name: start httpd
  service: name=httpd state=started enabled=true
###### 这里的template指的是相对路径-->web1/templates
###### tags可以在运行时指定标签任务
[root@centos-02 roles]# cat web1/handlers/main.yml
handlers:
- name: restart httpd
  service: name=httpd state=restarted
```

```shell
$ cat web1/templates/httpd.conf
……
Listen {{ http_port }}
……
```



定义一个调用roles文件

```yaml
# /root/web1.yml
- hosts: web1
  remote_user: root
  roles:
    - web1
    - { role:web2, http_port:8080 }
```

- hosts：web1    指在 /etc/ansible/hosts 中定义的组，上面有定义

- roles: web1     指的是当前目录下的web1目录，也可通过role传递变量， 也可调用多个role

- 这样只需更改hosts的主机就可以实现不同主机的代码重用了

 

```shell
# 运行
$ ansible-playbook web1.yml
# 指定运行任务
$ ansible-playbook -t conf web1.yml
```

## 使用 ansible-playbook 安装 zabbix

### 定义hosts 

```shell
$ cat /etc/ansible/hosts
[mini]
centos-01:22
centos-03:22
```

### 定义入口文件 install_zabbix_agent.yml

```yaml
# /etc/ansible/install_zabbix_agent.yml
- hosts: mini
  roles:
  - install_zabbix_agent
  
# 可以看到将要安装的主机组为 mini 组，角色为 install_zabbix_agent
```

### 定义角色 install_zabbix_agent 

```shell
# 建立 files     目录，存放编译安装过的 zabbix_agent 目录的压缩文件，用于拷贝到远程主机
# 建立 tasks     目录，用于编写将要执行的任务
# 建立 templates 目录，用于存放可变的模板文件
# 建立 vars      目录，用于存放变量信息
$ mkdir -p /etc/ansible/roles/install_zabbix_agent/{files,tasks,templates,vars}
$ tree /etc/ansible/roles/install_zabbix_agent/
/etc/ansible/roles/install_zabbix_agent/
├── files
│   └── zabbix-2.4.5.tar.gz
├── tasks
│   └── main.yml
├── templates
│   ├── zabbix_agentd
│   └── zabbix_agentd.conf
└── vars
    └── main.yml
```

### 建立tasks主文件

```yaml
# /etc/ansible/roles/install_zabbix_agent/tasks/main.yml
  - name: Install Software
    yum: name={{ item }} state=latest
    with_items:
      - libcurl-devel
  - name: Create Zabbix User
    user: name={{ zabbix_user }} state=present createhome=no shell=/sbin/nologin
  - name: Copy Zabbix.tar.gz
    copy: src=zabbix-{{ zabbix_version }}.tar.gz dest={{ zabbix_dir }}/src/zabbix-{{ zabbix_version }}.tar.gz owner=root group=root
  - name: Uncompression Zabbix.tar.gz
    shell: tar zxf {{ zabbix_dir }}/src/zabbix-{{ zabbix_version }}.tar.gz -C {{ zabbix_dir }}/
  - name: Copy Zabbix Start Script
    template: src=zabbix_agentd dest=/etc/init.d/zabbix_agentd owner=root group=root mode=0755
  - name: Copy Zabbix Config File
    template: src=zabbix_agentd.conf dest={{ zabbix_dir }}/zabbix/etc/zabbix_agentd.conf owner={{ zabbix_user }} group={{ zabbix_user }} mode=0644
  - name: Modify Zabbix Dir Permisson
    file: path={{ zabbix_dir }}/zabbix owner={{ zabbix_user }} group={{ zabbix_user }} mode=0755 recurse=yes
  - name: Start Zabbix Service
    shell: /etc/init.d/zabbix_agentd start
  - name: Add Boot Start Zabbix Service
    shell: chkconfig --level 35 zabbix_agentd on
```

### 建立主变量文件

```yaml
# /etc/ansible/roles/install_zabbix_agent/vars/main.yml
zabbix_dir: /usr/local
zabbix_version: 2.4.5
zabbix_user: zabbix
zabbix_port: 10050
zabbix_server_ip: 10.0.7.165
```

### 建立模板文件

```shell
$ cat /etc/ansible/roles/install_zabbix_agent/templates/zabbix_agentd
#!/bin/bash
. /etc/init.d/functions
### 变量
### 编辑它们以匹配您的系统设置
        # Zabbix-Directory
        BASEDIR={{ zabbix_dir }}/zabbix
        # Binary File
        BINARY_NAME=zabbix_agentd
        # Full Binary File Call
        FULLPATH=$BASEDIR/sbin/$BINARY_NAME
        # PID file
        PIDFILE=/tmp/$BINARY_NAME.pid
        # Establish args
        ERROR=0
        STOPPING=0
# 无需编辑以下内容
# 应用程序检查状态
if [ -f $PIDFILE  ] && [ -s $PIDFILE ]
        then
        PID=`cat $PIDFILE`
        if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null && [ $BINARY_NAME == `ps -e | grep $PID | awk '{print $4}'` ]
        then
                STATUS="$BINARY_NAME (pid `pidof $APP`) running.."
                RUNNING=1
        else
                rm -f $PIDFILE
                STATUS="$BINARY_NAME (pid file existed ($PID) and now removed) not running.."
                RUNNING=0
        fi
else
        if [ `ps -e | grep $BINARY_NAME | head -1 | awk '{ print $1 }'` ]
                then
                STATUS="$BINARY_NAME (pid `pidof $APP`, but no pid file) running.."
        else
                STATUS="$BINARY_NAME (no pid file) not running"
        fi
        RUNNING=0
fi
# functions
start() {
        if [ $RUNNING -eq 1 ]
                then
                echo "$0 $ARG: $BINARY_NAME (pid $PID) already running"
        else
                action $"Starting $BINARY_NAME: " $FULLPATH
                touch /var/lock/subsys/$BINARY_NAME
        fi
}
stop() {
        echo -n $"Shutting down $BINARY_NAME: "
        killproc $BINARY_NAME
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$BINARY_NAME
        RUNNING=0
}
# logic
case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        status)
                status $BINARY_NAME
                ;;
        restart)
                stop
                sleep 10
                start
                ;;
        help|*)
                echo $"Usage: $0 {start|stop|status|restart|help}"
                cat <<EOF
                        start           - start $BINARY_NAME
                        stop            - stop $BINARY_NAME
                        status          - show current status of $BINARY_NAME
                        restart         - restart $BINARY_NAME if running by sending a SIGHUP or start if not running
                        help            - this screen
EOF
        exit 1
        ;;
esac
exit 0
```

 

```shell
$ cat /etc/ansible/roles/install_zabbix_agent/templates/zabbix_agentd.conf
LogFile=/tmp/zabbix_agentd.log
Server={{ zabbix_server_ip }}
ListenPort={{ zabbix_port }}
Hostname={{ ansible_all_ipv4_addresses[1] }}
Timeout=20
UnsafeUserParameters=1
```

### 安装

```shell
$ ansible-playbook /etc/ansible/install_zabbix_agent.yml
PLAY [mini] *******************************************************************
GATHERING FACTS ***************************************************************
ok: [129.139.153.78]
ok: [155.139.190.94]
TASK: [install_zabbix_agent | Install Software] *******************************
changed: [155.139.190.94] => (item=libcurl-devel)
changed: [129.139.153.78] => (item=libcurl-devel)
TASK: [install_zabbix_agent | Create Zabbix User] *****************************
changed: [129.139.153.78]
changed: [155.139.190.94]
TASK: [install_zabbix_agent | Copy Zabbix.tar.gz] *****************************
changed: [129.139.153.78]
changed: [155.139.190.94]
TASK: [install_zabbix_agent | Uncompression Zabbix.tar.gz] ********************
changed: [129.139.153.78]
changed: [155.139.190.94]
TASK: [install_zabbix_agent | Copy Zabbix Start Script] ***********************
changed: [155.139.190.94]
changed: [129.139.153.78]
TASK: [install_zabbix_agent | Copy Zabbix Config File] ************************
changed: [129.139.153.78]
changed: [155.139.190.94]
TASK: [install_zabbix_agent | Modify Zabbix Dir Permisson] ********************
changed: [155.139.190.94]
changed: [129.139.153.78]
TASK: [install_zabbix_agent | Start Zabbix Service] ***************************
changed: [129.139.153.78]
changed: [155.139.190.94]
TASK: [install_zabbix_agent | Add Boot Start Zabbix Service] ******************
changed: [129.139.153.78]
changed: [155.139.190.94]
PLAY RECAP ********************************************************************
155.139.190.94               : ok=10   changed=9    unreachable=0    failed=0
129.139.153.78               : ok=10   changed=9    unreachable=0    failed=0
```