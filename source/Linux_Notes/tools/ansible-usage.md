# ansible 使用

## Ansible 特点

- 部署简单，只需在主控端部署 Ansible 环境，被控端无需做任何操作。
- 默认使用 SSH（Secure Shell）协议对设备进行管理。
- 主从集中化管理。
- 配置简单、功能强大、扩展性强。
- 支持 API 及自定义模块，可通过 Python 轻松扩展。
- 通过 Playbooks 来定制强大的配置、状态管理。
- 对云计算平台、大数据都有很好的支持。
- 提供一个功能强大、操作性强的 Web 管理界面和 REST API 接口 ---- AWX 平台。

## 配置 ansible

```shell
$ yum -y install ansible
$ ls /etc/ansible/
ansible.cfg hosts roles
#ansible.cfg       是 Ansible 工具的配置文件。
#hosts             用来配置被管理的机器。
#roles             是一个目录，playbook 将使用它
```

### SSH秘钥认证

```shell
$ ssh-keygen -t rsa -C "Leeks"
$ ssh-copy-id root@10.0.7.164
$ ssh-copy-id root@10.0.7.166
```

### 添加被管理主机 

```shell
$ cat /etc/hosts
10.0.7.164 centos-01
10.0.7.166 centos-03
$ vim /etc/ansible/hosts
[Client]
centos-01
centos-03
```

### 测试ansible

操作 Client 组 ( all 为操作 hosts 文件中所有主机 )，-m 指定执行 ping 模块，下面是返回结果

```shell
$ ansible Client -m ping
centos-03 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
centos-01 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
# -i       指定 hosts 文件位置
# -u       username 指定 SSH 连接的用户名
# -k       指定远程用户密码
# -f       指定并发数
# -s       如需要 root 权限执行时使用 ( 连接用户不是 root 时 )
# -K       -s 时，-K 输入 root 密码
```

## hosts主机文件

```shell
$ cat /etc/ansible/hosts
www.abc.com              # 定义域名
192.168.1.100            # 定义 IP
192.168.1.150:37268      # 指定端口号
[WebServer]              # 定义分组
10.0.7.160
10.0.7.161
10.0.7.162
[DBServer]               # 定义多个分组
10.0.7.163
10.0.7.164
Monitor ansible_ssh_port=12378 ansible_ssh_host=192.168.1.200          # 定义别名
# ansible_ssh_host                    连接目标主机的地址
# ansible_ssh_port                    连接目标主机的端口，默认 22 时无需指定
# ansible_ssh_user                    连接目标主机默认用户
# ansible_ssh_pass                    连接目标主机默认用户密码
# ansible_ssh_connection              目标主机连接类型，可以是 local 、ssh 或 paramiko
# ansible_ssh_private_key_file        连接目标主机的ssh私钥
# ansible_*_interpreter               指定采用非Python的其他脚本语言，如 Ruby 、Perl 或其他类似 ansible_python_interpreter 解释器
[webservers]              # 主机名支持正则描述
www[01:50].example.com
[dbservers]
db-[a:f].example.com
```

## ansible常用模块

```shell
# 列出 Ansible 支持的模块
$ ansible-doc -l

# 查看该模块帮助信息
$ ansible-doc ping
```

### 远程命令模块（command / script / shell）

1. command

   command 作为 Ansible 的默认模块，可以运行远程权限范围所有的 shell 命令，不支持管道符。

   **查看 Client 分组主机内存使用情况**

   ```shell
   $ ansible Client -m command -a "free -m"
   centos-03 | SUCCESS | rc=0 >>
                 total        used        free      shared  buff/cache   available
   Mem:           7982         151        7729           8         100        7642
   Swap:          3071           0        3071
   centos-01 | SUCCESS | rc=0 >>
                 total        used        free      shared  buff/cache   available
   Mem:           7982        4442         357         101        3181        3138
   Swap:          3071           1        3070
   ```

2. script

   script 的功能是在远程主机执行主控端存储的 shell 脚本文件，相当于 scp + shell 组合。

   **远程执行本地脚本**

   ```shell
   $ ansible Client -m script -a "/root/test.sh aa bb"    
   centos-03 | SUCCESS => {
       "changed": true, 
       "rc": 0, 
       "stderr": "Shared connection to centos-03 closed.\r\n", 
       "stdout": "", 
       "stdout_lines": []
   }
   centos-01 | SUCCESS => {
       "changed": true, 
       "rc": 0, 
       "stderr": "Shared connection to centos-01 closed.\r\n", 
       "stdout": "", 
       "stdout_lines": []
   }
   ```

3. shell

   shell模块基本和 command 相同，但是 shell 支持管道符

   **执行远程脚本**

   ```shell
   $ ansible Client -m shell -a "ps -ef|grep nginx"  
   centos-01 | SUCCESS | rc=0 >>
   root     10453 10452  0 05:26 pts/0    00:00:00 /bin/sh -c ps -ef|grep nginx
   root     10455 10453  0 05:26 pts/0    00:00:00 grep nginx
   centos-03 | SUCCESS | rc=0 >>
   root     10453 10452  0 05:26 pts/0    00:00:00 /bin/sh -c ps -ef|grep nginx
   root     10455 10453  0 05:26 pts/0    00:00:00 grep nginx
   ```

   

### copy模块

实现主控端向目标主机拷贝文件，类似于 scp 功能

**向 Client 组中主机拷贝 test.sh 到 /tmp 下，属主、组为 root ，权限为 0755**

```shell
$ ansible Client -m copy -a "src=/root/test.sh dest=/tmp/ owner=root group=root mode=0755" 
centos-03 | SUCCESS => {
    "changed": true, 
    "checksum": "6a6a052e339186d5057c8eb184d694c2384b16eb", 
    "dest": "/tmp/test.sh", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "48cc15d62eb9843112afae4911f50323", 
    "mode": "0755", 
    "owner": "root", 
    "size": 21, 
    "src": "/root/.ansible/tmp/ansible-tmp-1571909317.6-280606834236702/source", 
    "state": "file", 
    "uid": 0
}
centos-01 | SUCCESS => {
    "changed": true, 
    "checksum": "6a6a052e339186d5057c8eb184d694c2384b16eb", 
    "dest": "/tmp/test.sh", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "48cc15d62eb9843112afae4911f50323", 
    "mode": "0755", 
    "owner": "root", 
    "secontext": "unconfined_u:object_r:admin_home_t:s0", 
    "size": 21, 
    "src": "/root/.ansible/tmp/ansible-tmp-1571909317.59-110536292508777/source", 
    "state": "file", 
    "uid": 0
}
```

### stat模块

**获取远程文件状态信息，atime/ctime/mtime/md5/uid/gid 等信息**

```shell
$ ansible Client -m stat -a "path=/etc/syctl.conf"
centos-03 | SUCCESS => {
    "changed": false, 
    "stat": {
        "exists": false
    }
}
centos-01 | SUCCESS => {
    "changed": false, 
    "stat": {
        "exists": false
    }
}
```

### get_url

**实现在远程主机下载指定 URL 到本地，支持 sha256sum 文件校验**

```shell
$ ansible Client -m get_url -a "url=http://www.baidu.com dest=/tmp/index.html mode=0440 force=yes"
centos-03 | SUCCESS => {
    "changed": true, 
    "checksum_dest": null, 
    "checksum_src": "c0eaf9fbbde1b7eb8566b0daa4d7a9f0c7de6172", 
    "dest": "/tmp/index.html", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "c4bcd35f0a2cbbe34f80fc6a1f1f2f10", 
    "mode": "0440", 
    "msg": "OK (unknown bytes)", 
    "owner": "root", 
    "size": 156058, 
    "src": "/tmp/tmp3PULcQ", 
    "state": "file", 
    "status_code": 200, 
    "uid": 0, 
    "url": "http://www.baidu.com"
}
centos-01 | SUCCESS => {
    "changed": true, 
    "checksum_dest": null, 
    "checksum_src": "5f72f185e45406201fc2af14ca28c0c35fead887", 
    "dest": "/tmp/index.html", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "49d11681e549810d052edb6797ece805", 
    "mode": "0440", 
    "msg": "OK (unknown bytes)", 
    "owner": "root", 
    "secontext": "unconfined_u:object_r:user_tmp_t:s0", 
    "size": 156082, 
    "src": "/tmp/tmp2ceW5B", 
    "state": "file", 
    "status_code": 200, 
    "uid": 0, 
    "url": "http://www.baidu.com"
}
```

### yum

**软件包管理**

```shell
$ ansible Client -m yum -a "name=curl state=latest"
centos-01 | SUCCESS => {
    "changed": false, 
    "msg": "", 
    "rc": 0, 
    "results": [
        "All packages providing curl are up to date", 
        ""
    ]
}
centos-03 | SUCCESS => {
    "changed": false, 
    "msg": "", 
    "rc": 0, 
    "results": [
        "All packages providing curl are up to date", 
        ""
    ]
}
```

### corn

**远程主机 crontab 配置** 

```shell
$ ansible Client -m cron -a "name='check dirs' hour='5,2' job='ls -alh > /dev/null'"
centos-03 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "check dirs"
    ]
}
centos-01 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "check dirs"
    ]
}
```

**效果**

```shell
$ crontab -l
#Ansible: check dirs
* 5,2 * * * ls -alh > /dev/null
```

### mount

**远程主机分区挂载**

```shell
$ ansible Client -m mount -a "name=/mnt/data src=/dev/sd0 fstype=ext4 opts=ro state=present"
centos-03 | SUCCESS => {
    "changed": true, 
    "dump": "0", 
    "fstab": "/etc/fstab", 
    "fstype": "ext4", 
    "name": "/mnt/data", 
    "opts": "ro", 
    "passno": "0", 
    "src": "/dev/sd0"
}
centos-01 | SUCCESS => {
    "changed": true, 
    "dump": "0", 
    "fstab": "/etc/fstab", 
    "fstype": "ext4", 
    "name": "/mnt/data", 
    "opts": "ro", 
    "passno": "0", 
    "src": "/dev/sd0"
}
```

### service

**远程主机系统服务管理**

```shell
$ ansible Client -m service -a "name=nginx state=stoped"
$ ansible Client -m service -a "name=nginx state=restarted"
$ ansible Client -m service -a "name=nginx state=reloaded"
```

### user

**远程主机用户管理**

```shell
$ ansible Client -m user -a "name=wang comment='user wang'"
centos-03 | SUCCESS => {
    "changed": true, 
    "comment": "user wang", 
    "createhome": true, 
    "group": 1000, 
    "home": "/home/wang", 
    "name": "wang", 
    "shell": "/bin/bash", 
    "state": "present", 
    "system": false, 
    "uid": 1000
}
centos-01 | SUCCESS => {
    "changed": true, 
    "comment": "user wang", 
    "createhome": true, 
    "group": 1003, 
    "home": "/home/wang", 
    "name": "wang", 
    "shell": "/bin/bash", 
    "state": "present", 
    "system": false, 
    "uid": 1003
}
```

**添加删除用户**

```shell
$ ansible Client -m user -a "name=wang state=absent remove=yes"
centos-03 | SUCCESS => {
    "changed": true, 
    "force": false, 
    "name": "wang", 
    "remove": true, 
    "state": "absent"
}
centos-01 | SUCCESS => {
    "changed": true, 
    "force": false, 
    "name": "wang", 
    "remove": true, 
    "state": "absent"
}
```