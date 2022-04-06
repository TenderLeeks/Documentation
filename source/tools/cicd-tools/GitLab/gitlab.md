# GitLab 服务

## GitLab介绍

​		GitLab CE或Community Edition是一个开源应用程序，主要用于托管Git存储库，以及其他与开发相关的功能，如问题跟踪。它旨在使用您自己的基础架构进行托管，并为您的开发团队提供部署内部存储库的灵活性，与用户交互的公共方式，或者为贡献者提供托管自己项目的方法。

​		GitLab项目使用简单的安装机制在您自己的硬件上设置GitLab实例变得相对简单。在本指南中，我们将介绍如何在阿里云Ubuntu 20.04服务器上安装和配置GitLab。

​		GitLab一个开源的git仓库管理平台，方便团队协作开发、管理。在GitLab上可以实现完整的CI（持续集成）、CD（持续发布）流程。

[社区版本](https://gitlab.com/gitlab-org/gitlab-ce)

[GitLab 官网](https://about.gitlab.com/)



## 安装

以下内容仅供参考

```shell
# 安装依赖包
$ sudo apt update
$ sudo apt install ca-certificates curl openssh-server postfix

# 启动postfix并设置为开机启动
$ sudo systemctl enable postfix
$ sudo systemctl start postfix

# 安装GitLab
$ cd /tmp  && curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
# 可以在 https://packages.gitlab.com/gitlab/gitlab-ce/install 找到该脚本的托管版本：
$ less /tmp/script.deb.sh
$ sudo sh /tmp/script.deb.sh
# 该脚本将设置服务器以使用GitLab维护的存储库。可以使用与其他系统软件包相同的软件包管理工具来管理GitLab。完成后，可以使用以下apt命令安装实际的GitLab应用程序：
# 执行安装脚本后，gitlab 库地址会存放到 /etc/apt/sources.list.d/gitlab_gitlab-ce.list 中，之后就可以直接通过 apt-get 指令直接安装了。
$ sudo apt install gitlab-ce

# 如果官方地址下载太慢了或者失败，可以更换清华大学镜像源
# 信任 GitLab 的 GPG 公钥
$ curl https://packages.gitlab.com/gpg.key 2> /dev/null | sudo apt-key add - &>/dev/null

$ vim /etc/apt/sources.list.d/gitlab-ce.list
# 将下面的内容粘贴进去
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu bionic main

$ apt-get update

# 安装指定版本
$ VERSION="14.4.2"
# 老版本请在此链接查找 https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/bionic/main/g/gitlab-ce
$ cd /tmp && wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/focal/main/g/gitlab-ce/gitlab-ce_${VERSION}-ce.0_amd64.deb
# 安装软件
$ dpkg -i gitlab-ce_${VERSION}-ce.0_amd64.deb

# 或者使用以下命令安装指定版本
$ sudo yum install gitlab-ce-x.x.x
$ sudo apt install gitlab-ce-x.x.x

# 查看 GitLab 版本号
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION

# gitlab-ce 是社区版，免费的
$ curl -sS http://packages.gitlab.cc/install/gitlab-ce/script.deb.sh | sudo bash
# gitlab-ee 是企业版，收费的
$ curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
```

**注意：**

```shell
# 报错信息
Reading package lists... Done
Building dependency tree
Reading state information... Done
E: Unable to locate package gitlab-ce

# 修改安装脚本
$ sudo vim /etc/apt/sources.list.d/gitlab_gitlab-ce.list
# old
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ focal main
deb-src https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ focal main
# new
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main
deb-src https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main

# 再次执行
$ sudo apt update
$ sudo apt install gitlab-ce
```

## 配置

GitLab 配置文件：`/etc/gitlab/gitlab.rb`

```shell
$ sudo vim /etc/gitlab/gitlab.rb

# 此处修改为访问域名或ip地址
external_url 'https://example.com'

# 此处修改为接收消息的邮箱地址
letsencrypt['contact_emails'] = ['sammy@example.com']

# 设置备份文件的保存位置
gitlab_rails['backup_path'] = "/opt/backup/gitlab"

# 设置备份文件的过期时间，单位为秒，默认7天
gitlab_rails['backup_keep_time'] = 2592000

# 邮箱配置
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '邮箱地址'
gitlab_rails['gitlab_email_display_name'] = '邮箱显示名称'
# smtp配置
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp地址"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "邮箱地址"
gitlab_rails['smtp_password'] = "密码或授权码"
gitlab_rails['smtp_domain'] = "smtp地址"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true


# 发送测试邮件
$ sudo gitlab-rails console
# 进入控制台，然后发送邮件
Notify.test_email('接收测试消息的邮箱地址', '邮件标题', '邮件正文').deliver_now


########################
### 以下配置请酌情更改  ###
########################

# GitLab修改端口
# GitLab默认端口是80，如果我们想更改成其他端口，则需要修改GitLab配置文件。
nginx['listen_port'] = 18088  # GitLab端口，默认80端口
unicorn['port'] = 18089  # 可不修改，默认监听8080端口

# 禁用创建组权限，GitLab默认所有的注册用户都可以创建组
gitlab_rails['gitlab_default_can_create_group'] = false

### 设置https域名还需要添加证书
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate' = "/etc/gitlab/ssl/gitlab-ce.mshk.top.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab-ce.mshk.top.key"
# 证书名称需要更改为和域名相同的名称，证书需上传到目录 /etc/gitlab/ssl 中。

# 禁用内不 nginx 组件
nginx['enable'] = false
# 设置 gitlab-workhorse 监听 TCP 端口
gitlab_workhorse['listen_network'] = "tcp"
gitlab_workhorse['listen_addr'] = "127.0.0.1:28088"  # 这个端口号和之后设置的 Nginx 代理的端口号要一致


# 重新配置gitlab
$ gitlab-ctl reconfigure

# 启动 GitLab
$ sudo gitlab-ctl start

# 设置GitLab开机自启动命令为
$ sudo systemctl enable gitlab-runsvdir.service

# 禁止GitLab开机自启动命令为
$ sudo systemctl disable gitlab-runsvdir.service
```



## 初始化root密码

```shell
# 进入GitLab控制台。
$ sudo gitlab-rails console

# 输入以下命令，修改root用户密码。
irb(main):001:0> user = User.where(id:1).first
irb(main):002:0> user.password = "Gfanx#Root#2022"
irb(main):003:0> user.password_confirmation = "Gfanx#Root#2022"
irb(main):004:0> user.save!
irb(main):005:0> exit
```



## 取消用户注册

Admin Area --> Settings --> Sign-up restrictions --> Sign-up enabled(取消前面的勾） --> save

![](img/glqxzcgn.png)



## 外置nginx配置

```nginx
upstream gitlab {
    server 127.0.0.1:28088;
}

server {
    listen *:80;
    listen 443 ssl;
    server_name brqsd5j1d.xxxx.co,;

    ssl_certificate       /opt/nginx/conf/ssl-cert/brqsd5j1d.xxxx.com.crt;
    ssl_certificate_key   /opt/nginx/conf/ssl-cert/brqsd5j1d.xxxx.com.key;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_protocols SSLv3 SSLv2 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_prefer_server_ciphers on;

    if ($scheme = http) {
        return 301 https://$host$request_uri;
    }

    server_tokens off;
    root /opt/gitlab/embedded/service/gitlab-rails/public;
    client_max_body_size 250m;
    access_log  logs/gitlab.access.log;
    error_log   logs/gitlab.error.log;

    location / {
        try_files $uri $uri/index.html $uri.html @gitlab;
    }

    location @gitlab {
        proxy_read_timeout 300; # Some requests take more than 30 seconds.
        proxy_connect_timeout 300; # Some requests take more than 30 seconds.
        proxy_redirect     off;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_set_header   Host              $http_host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Frame-Options   SAMEORIGIN;
        proxy_pass http://127.0.0.1:28088;

    }
    location ~ ^/(assets)/  {
        root /opt/gitlab/embedded/service/gitlab-rails/public;
        expires max;
        add_header Cache-Control public;
    }
    error_page 502 /502.html;
}
```



## Gitlab 备份

```shell
# 执行后会生成一个[编码]_[年月日]_[版本号]_gitlab_backup.tar格式的备份文件,例如: 1642919929_2022_01_23_14.4.2_gitlab_backup.tar
$ gitlab-rake gitlab:backup:create
# 红色字体描述为 gitlab.rb 和gitlab-secrets.json为敏感文件需要手动备份

# 查看备份文件保存目录
$ cat /etc/gitlab/gitlab.rb | grep "backup_path" | egrep -v "^$|^#"
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"


# 可以添加备份命令crontab中。
0   22  *  *  *   sudo gitlab-rake gitlab:backup:create
0 2 * * * gitlab-rake gitlab:backup:create CRON=1  
0  2    * * *   root    /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1

```

## GitLab 恢复备份数据

```shell
# 将原服务器上的备份文件发送至新服务器的相应目录下
$ scp 1642919929_2022_01_23_14.4.2_gitlab_backup.tar 10.10.1.154:/var/opt/gitlab/backups

### 导入数据
# 将新服务器的gitlab相关数据连接服务停止
$ gitlab-ctl stop unicorn
$ gitlab-ctl stop sidekiq

# 修改文件权限为777,不然会提示权限不足
$ chmod 777 1642919929_2022_01_23_14.4.2_gitlab_backup.tar

# 使用 gitlab-rake gitlab:backup:restore 恢复,注意:_gitlab_backup.tar不用加,会默认加上.
$ gitlab-rake gitlab:backup:restore BACKUP=1642919929_2022_01_23_14.4.2
# 会提示yes/no,输入yes

# 重启gitlab
$ gitlab-ctl restart
```

## 更新版本

GitLab跨大版本升级

- gitlab的升级不能随意升级，需要根据官方文档的升级路线进行升级。

- 查看官方升级路线请点击[此处](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)

- 本次版本为`12.8.0`需要升级到`14.6.2`版本，升级路线如下：

  `12.8.0` -> `12.9.2` -> `12.10.14` -> `13.0.14` -> `13.1.11` -> `13.8.8` -> `13.12.15` -> `14.0.12` -> `14.6.2`

更新前准备

- 一定要备份当前正常运行的版本数据。
- 每次版本install完成后，一定要执行reconfigure和restart命令，等待页面能正常访问后再继续更新。
- 不需要停止整个gitlab服务，只需要停止几个通信的服务（不停止也可以，需要保证在更新期间无人使用）

更新步骤

```shell
# 备份数据
$ gitlab-rake gitlab:backup:create
$ cp -a /etc/gitlab/gitlab.rb /opt/backup/gitlab/gitlab.rb.12.8.0
$ cp -a /etc/gitlab/gitlab-secrets.json /opt/backup/gitlab/gitlab-secrets.json.12.8.0
$ cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
12.8.0
# 更新升级版本
$ dpkg -i gitlab-ce_12.9.2-ce.0_amd64.deb
$ dpkg -i gitlab-ce_12.10.14-ce.0_amd64.deb
$ dpkg -i gitlab-ce_13.0.14-ce.0_amd64.deb
$ dpkg -i gitlab-ce_13.1.11-ce.0_amd64.deb
$ dpkg -i gitlab-ce_13.8.8-ce.0_amd64.deb
$ dpkg -i gitlab-ce_13.12.15-ce.0_amd64.deb
$ dpkg -i gitlab-ce_14.0.12-ce.0_amd64.deb
$ dpkg -i gitlab-ce_14.6.2-ce.0_amd64.deb

```



## 卸载 GitLab

```shell
# 停止gitlab
$ sudo gitlab-ctl stop
# 查看进程
$ ps -e | grep gitlab
# 删除所有包含gitlab的文件及目录
$ sudo find / -name gitlab | xargs rm -rf
# 卸载
sudo apt-get remove gitlab-ce
# 检查还有没有卸载的gitlab相关软件
$ sudo dpkg --get-selections | grep gitlab
gitlab-ce      deinstall
# 再执行
$ sudo apt-get --purge remove gitlab-ce
```



## GitLab Pages设置

```shell
gitlab_pages[‘enable’] = true; 开启 Pages 服务
pages_external_url ‘您的GitLab Pages域名地址'; 替换成你自己的域名
gitlab_pages[‘inplace_chroot’] = true; 以Docker container 方式运行的 Gitlab 必须开启此项
pages_nginx[‘enable’] = true; 开启 Pages 服务的 vhost，该项开启后将会在 /var/opt/gitlab/nginx/conf 目录下生成独立的名为 gitlab-pages.conf Nginx 配置文件。
gitlab_pages['access_control'] = true 开启 Pages 访问控制。
```

## GitLab Runner配置

[安装](https://docs.gitlab.com/runner/install/linux-repository.html)

[注册](https://docs.gitlab.com/runner/register/)



## 常用命令

```shell
sudo gitlab-ctl reconfigure                  # 重新加载配置
sudo gitlab-ctl status                       # 查看 GitLab 状态
sudo gitlab-ctl start                        # 启动 GitLab
sudo gitlab-ctl stop                         # 停止 GitLab
sudo gitlab-ctl restart                      # 重启 GitLab
sudo gitlab-ctl tail                         # 查看所有日志
sudo gitlab-ctl tail nginx/gitlab_acces.log  # 查看 nginx 访问日志
sudo gitlab-ctl tail postgresql              # 查看 postgresql 日志
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION    # 查看版本
```

