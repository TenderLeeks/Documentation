本教程将帮助您在Ubuntu 20.04 LTS Linux系统上安装Gitlab。 您将使用本教程安装Gitlab社区版。

14.4.2

GitLab CE或Community Edition是一个开源应用程序，主要用于托管Git存储库，以及其他与开发相关的功能，如问题跟踪。它旨在使用您自己的基础架构进行托管，并为您的开发团队提供部署内部存储库的灵活性，与用户交互的公共方式，或者为贡献者提供托管自己项目的方法。

GitLab项目使用简单的安装机制在您自己的硬件上设置GitLab实例变得相对简单。在本指南中，我们将介绍如何在阿里云Ubuntu 20.04服务器上安装和配置GitLab。



### GitLab介绍

GitLab一个开源的git仓库管理平台，方便团队协作开发、管理。在GitLab上可以实现完整的CI（持续集成）、CD（持续发布）流程。而且还提供了免费使用的Plan，以及免费的可以独立部署的社区版本([https://gitlab.com/gitlab-org/gitlab-ce](https://link.segmentfault.com/?enc=NGl56MStoroVXltx4TPf3Q%3D%3D.apbOZ537R1FXt6B%2BiAOyXcCzU1ur%2BO510F0boU0FPbqZBNpW33PtPLd%2FYrFDErPZ) )。官网：[https://about.gitlab.com/](https://link.segmentfault.com/?enc=JcUKD7oNpvvmnXls81jTTA%3D%3D.JmW%2BLarhBBpLhKi4xt7%2FC443DkXnYGQDDaRJbQGa58o%3D)





```shell
# 安装依赖包
sudo apt update
sudo apt install ca-certificates curl openssh-server postfix
# 您可能已经安装了一些此软件。对于postfix的安装，请在出现提示时选择“ Internet站点”。在下一个屏幕上，输入服务器的域名以配置系统发送邮件的方式。
# 我选择了 No Con­fig­u­ra­tion（不配置）。如果屏幕选择项不在 ok 上，可以用 tab 键进行切换，然后回车进入下一屏幕选择。


#启动postfix并设置为开机启动
sudo systemctl enable postfix
sudo systemctl start postfix



# 安装GitLab
cd /tmp
curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
# 您可以随意检查下载的脚本，以确保您对所需的操作感到满意。您还可以在 https://packages.gitlab.com/gitlab/gitlab-ce/install 找到该脚本的托管版本：
less /tmp/script.deb.sh

sudo bash /tmp/script.deb.sh
# 该脚本将设置您的服务器以使用GitLab维护的存储库。这使您可以使用与其他系统软件包相同的软件包管理工具来管理GitLab。完成后，您可以使用以下apt命令安装实际的GitLab应用程序：
# 执行安装脚本后，gitlab 库地址会存放到 /etc/apt/sources.list.d/gitlab_gitlab-ce.list 中，之后就可以直接通过 apt-get 指令直接安装了。
sudo apt install gitlab-ce


下载gitlab-ce软件包
wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/focal/main/g/gitlab-ce/gitlab-ce_13.2.3-ce.0_amd64.deb

安装软件
dpkg -i gitlab-ce_13.2.3-ce.0_amd64.deb

sudo yum install gitlab-ce-x.x.x #安装指定版本



gitlab-ce 是社区版，免费的
gitlab-ee 是企业版，收费的

gitlab-ee:
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
gitlab-ce: 
curl -sS http://packages.gitlab.cc/install/gitlab-ce/script.deb.sh | sudo bash




配置镜像路径

由于国外的下载速度过慢，所以配置清华大学镜像的路径。
建议利用命令sudo -i进入root模式使用vim进行配置：
vim /etc/apt/sources.list.d/gitlab-ce.list
根据你的版本，选择对于的内容写入/etc/apt/sources.list.d/gitlab-ce.list，详见[Gitlab Community Edition 镜像使用帮助]
在这里插入图片描述
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu bionic main



官方下载地址太慢了，这里我们换源：

1、首先信任 GitLab 的 GPG 公钥:
curl https://packages.gitlab.com/gpg.key 2> /dev/null | sudo apt-key add - &>/dev/null
2、打开vi：
vi /etc/apt/sources.list.d/gitlab-ce.list
3、将下面的内容粘贴进去
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu xenial main  //粘贴至文本中，按Esc键，键入:，最后输入wq保存并退出。



```



#### 注意事项

在安装GitLab应用程序中如果报以下错误，我们可以配置国内加速镜像。



```shell
# 报错信息：
Reading package lists... Done
Building dependency tree
Reading state information... Done
E: Unable to locate package gitlab-ce

# 修改安装脚本
sudo vim /etc/apt/sources.list.d/gitlab_gitlab-ce.list

# OLD
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ focal main
deb-src https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ focal main
# NEW
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main
deb-src https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main

# 再次执行
sudo apt update
sudo apt install gitlab-ce

```





编辑GitLab配置文件

```shell
sudo vim /etc/gitlab/gitlab.rb

external_url 'https://example.com' // 此处修改为您的域名或ip地址

letsencrypt['contact_emails'] = ['sammy@example.com'] // 此处修改为您的邮箱地址


# 邮箱配置
#配置邮箱来源， 与展示的名称
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '您的qq邮箱地址'
gitlab_rails['gitlab_email_display_name'] = '您的邮箱显示名称'

#smtp配置
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "您的qq邮箱地址"
gitlab_rails['smtp_password'] = "您的授权码"
gitlab_rails['smtp_domain'] = "smtp.qq.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true


# 发送测试邮件
sudo gitlab-rails console

#进入控制台，然后发送邮件
Notify.test_email('测试邮箱地址', '邮件标题', '邮件正文').deliver_now


# GitLab修改端口
# GitLab默认端口是80，如果我们想更改成9091端口，则需要修改GitLab配置文件。

nginx['listen_port'] = 9091 // GitLab端口，默认80端口
unicorn['port'] = 9092 // 可不修改，默认监听8080端口



禁用创建组权限
GitLab默认所有的注册用户都可以创建组。但对于团队来说，通常只会给Leader相关权限。
虽然可以在用户管理界面取消权限，但毕竟不方便。我们可以通过配置GitLab默认禁用创建组权限。

#修改配置文件
sudo vi /etc/gitlab/gitlab.rb

#开启gitlab_rails['gitlab_default_can_create_group'] 选项，并将值设置为false
### GitLab user privileges
gitlab_rails['gitlab_default_can_create_group'] = false

#保存后，重新配置并启动GitLab
sudo gitlab-ctl reconfigure




##禁用捆绑的 Nginx
# 将
nginx['enable'] = true
# 修改为
nginx['enable'] = false
# 并去掉注释 (前边的#)
...
##设置 gitlab-workhorse 监听 TCP 端口
gitlab_workhorse['listen_network'] = "tcp"
gitlab_workhorse['listen_addr'] = "127.0.0.1:8021"  //这个端口号和之后设置的 Nginx 代理的端口号要一致
...



修改端口
由于GitLab默认在80端口，可能和本地服务冲突，可以选择其他端口号替代。
按照配置方式，搜索关键词nginx['listen_port']，修改端口为指定端口(我使用8099)。
nginx['listen_port'] = 8099
修改端口后为了保持统一，需要将访问链接修改成加上端口号的url。
external_url 'http://{你的IP}:{你的端口号}'


# GitLab Pages设置
gitlab_pages[‘enable’] = true; 开启 Pages 服务
pages_external_url ‘您的GitLab Pages域名地址'; 替换成你自己的域名
gitlab_pages[‘inplace_chroot’] = true; 以Docker container 方式运行的 Gitlab 必须开启此项
pages_nginx[‘enable’] = true; 开启 Pages 服务的 vhost，该项开启后将会在 /var/opt/gitlab/nginx/conf 目录下生成独立的名为 gitlab-pages.conf Nginx 配置文件。
gitlab_pages['access_control'] = true 开启 Pages 访问控制。



#设置备份文件的保存位置
gitlab_rails['backup_path'] = "/data/tools/gitlab/backup"

#设置备份文件的过期时间，单位为秒，默认7天
gitlab_rails['backup_keep_time'] = 604800


```





GitLab Runner配置



第1步 - 安装
参考官网安装流程：https://docs.gitlab.com/runner/install/linux-repository.html

第2步 - 注册
参考官网注册流程：https://docs.gitlab.com/runner/register/







# 取消用户注册页面和删除用户

## 取消用户注册页面

Admin Area—>Settings—>Sign-up enabled(取消前面的勾）—save





常用命令

```shell
sudo gitlab-ctl reconfigure	重新加载配置，每次修改/etc/gitlab/gitlab.rb文件之后执行
sudo gitlab-ctl status	查看 GitLab 状态
sudo gitlab-ctl start	启动 GitLab
sudo gitlab-ctl stop	停止 GitLab
sudo gitlab-ctl restart	重启 GitLab
sudo gitlab-ctl tail	查看所有日志
sudo gitlab-ctl tail nginx/gitlab_acces.log	查看 nginx 访问日志
sudo gitlab-ctl tail postgresql	查看 postgresql 日志

```





```shell
gitlab 备份
gitlab-rake gitlab:backup:create
或
sudo /usr/bin/gitlab-rake gitlab:backup:create
ps: 路径在/var/opt/gitlab/backups目录下

gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
执行后会生成一个[编码]_[年月日]_[版本号]_gitlab_backup.tar格式的备份文件,例如1551348332_2018_07_20_11.0.0_gitlab_backup.tar

修改备份路径, 进入/gitlab.rb来修改

通过/etc/gitlab/gitlab.rb配置文件来修改默认存放备份文件的目录

gitlab_rails['backup_path'] = "/xxxx/gitlab_backup"
修改后再重新配置gitlab应用程序

gitlab-ctl reconfigure




gitlab修改带nginx
关闭自带nginx,进入/etc/gitlab/gitlab.rb查找
nginx['enable'] = false
修改gitlab的nginx的配置文件

gitlab的nginx是默认80端口,可以进去/gitlab-http.conf配置文件修改端口号,然后再重启

// nginx配置文件,包含gitlab-http.conf文件
/var/opt/gitlab/nginx/conf/nginx.conf

// gitlab核心nginx配置文件
/var/opt/gitlab/nginx/conf/gitlab-http.conf
gitlab重启
gitlab-ctl restart



upstream gitlab {
    server unix:/var/opt/gitlab/gitlab-workhorse/socket;
}
server {
    listen *:80;
    server_name cwj.wechat-class.com;   # 请修改为你的域名
    server_tokens off;     # don't show the version number, a security best practice
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
        proxy_pass http://127.0.0.1:9500;

    }
    location ~ ^/(assets)/  {
        root /opt/gitlab/embedded/service/gitlab-rails/public;
        expires max;
        add_header Cache-Control public;
    }
    error_page 502 /502.html;
}



gitlab迁移
将原服务器上的备份文件发送至新服务器的相应目录下
scp

scp /var/opt/gitlab/backups/1551348332_2018_07_20_11.0.0_gitlab_backup.tar root@192.168.1.1:/var/opt/gitlab/backups/
gitlab恢复
将新服务器的gitlab服务停止
// 停止相关数据连接服务
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
修改文件权限为777,不然会提示权限不足
chmod 777 /var/opt/gitlab/backups/1551348332_2018_07_20_11.0.0_gitlab_backup.tar
使用gitlab-rake gitlab:backup:restore恢复,注意:_gitlab_backup.tar不用加,会默认加上.
gitlab-rake gitlab:backup:restore BACKUP=1551348332_2018_07_20_11.0.0
会提示yes/no,输入yes

重启gitlab
gitlab-ctl start
迁移成功
```



```shell
初始化
如果想访问配置链接登录，需要先对账号进行初始化。
进入GitLab控制台。
sudo gitlab-rails console
1
输入以下命令，修改root用户密码。
user = User.where(id:1).first
user.password = {新密码}
user.password_confirmation = {新密码}
user.save!
exit
使用更改后的root用户登录，同时设置偏好。




修改Gitlab的Root密码
进入 gitlab 生产控制台
sudo gitlab-rails console production
进入加载生产环境 (Rails 5.0.7.1)
irb(main):001:0> user = User.where(id: 1).first
=> #<User id:1 @root>
irb(main):005:0> user.password = 'aaaaaaaa111111111'
=> "aaaaaaaa111111111"
irb(main):006:0> user.password_confirmation = 'aaaaaaaa111111111'
=> "aaaaaaaa111111111"
irb(main):007:0> user.save!
Enqueued ActionMailer::DeliveryJob (Job ID: 18cbb4be-5215-43b2-9f3d-6b8e8ca5443a) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007f227ce31ef8 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
irb(main):008:0> quit



```





```shell
# 设置GitLab开机自启动命令为
sudo systemctl enable gitlab-runsvdir.service

# 禁止GitLab开机自启动命令为
sudo systemctl disable gitlab-runsvdir.service

```



```shell
完全卸载Gitlab
登录后复制
# 停止gitlab
sudo gitlab-ctl stop

# 查看进程
ps -e | grep gitlab

# 删除所有包含gitlab的文件及目录
sudo find / -name gitlab | xargs rm -rf

# 卸载
sudo apt-get remove gitlab-ce

# 检查还有没有卸载的gitlab相关软件
sudo dpkg --get-selections | grep gitlab
sudo gitlab-ce deinstall

# 再执行
sudo apt-get --purge remove gitlab-ce

```





```shell
Git解决中文乱码问题
git status 乱码

解决方法：
git config --global core.quotepath false

git commit 乱码

解决方法：
git config --global i18n.commitencoding utf-8

git status 乱码

解决方法：
git config --global i18n.logoutputencoding utf-8

注意：如果是Linux系统，需要设置环境变量 export LESSCHARSET=utf-8



查看 GitLab 版本号
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
```



```
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash 
上面的命令将在系统中创建apt配置文件（/etc/apt/sources.list.d/gitlab_gitlab-ce.list）。 接下来是使用apt命令在Ubuntu系统上安装Gitlab：
sudo apt install gitlab-ce 
此命令将需要一些时间才能在Ubuntu上完成Gitlab安装。 这将安装所有必需的服务，例如Nginx，PostgreSQL，Redis等。


Ubuntu 20.04的gitlab-ce软件包地址为https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/focal/main/g/gitlab-ce/,这里以13.2.3为例
wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/focal/main/g/gitlab-ce/gitlab-ce_13.2.3-ce.0_amd64.deb
安装软件
dpkg -i gitlab-ce_13.2.3-ce.0_amd64.deb

```



编辑Gitlab配置文件 `/etc/gitlab/gitlab.rb` 并将外部网址更新为用于访问Gitlab的有效域名或子域名。

```
sudo vim /etc/gitlab/gitlab.rb 
external_url "https://gitlab.tecadmin.net"
修改外部url
在gitlab配置文件/etc/gitlab/gitlab.rb中修改外部url，改为自己的ip地址或者域名

external_url 'http://172.16.129.170'  ## 本机的局域网ip地址为172.16.129.170


Gitlab还为配置让我们加密SSL证书提供了本机支持。 要启用加密SSL，请在配置文件中编辑以下值。
# Enable the Let's encrypt SSL
letsencrypt['enable'] = true

# This is optional to get SSL related alerts
letsencrypt['contact_emails'] = ['[email protected]']

# This example renews every 7th day at 12:30
letsencrypt['auto_renew_hour'] = "12"
letsencrypt['auto_renew_minute'] = "30"
letsencrypt['auto_renew_day_of_month'] = "*/7"

重新配置gitlab
gitlab-ctl reconfigure  ## 此过程可能需要较长时间


重启gitlab
gitlab-ctl restart
```

 访问测试
使用浏览器访问页面http://172.16.129.170，本机的局域网ip地址为172.16.129.170，推荐使用Chrome浏览器



## 配置备份

使用以下命令完整备份数据。 在/ var / opt / gitlab / backups目录下创建的默认备份，可以在/etc/gitlab/gitlab.rb文件中进行更改。

```
sudo gitlab-rake gitlab:backup:create 
```

您还可以添加相同的命令调度程序以每晚备份数据。 将以下作业添加到系统crontab中。

```
0   22  *  *  *   sudo gitlab-rake gitlab:backup:create
```



```shell
修改配置文件
# 打开gitlab配置文件
vim /etc/gitlab/gitlab.rb

#设置备份文件的保存位置
gitlab_rails['backup_path'] = "/data/tools/gitlab/backup"

#设置备份文件的过期时间，单位为秒，默认7天
gitlab_rails['backup_keep_time'] = 604800
执行wq保存后，刷新配置

gitlab-ctl reconfigure
2）执行备份命令验证
执行备份命令，去对应的文件路径查看是否已经创建了备份文件

gitlab-rake gitlab:backup:create


红色字体描述为 gitlab.rb 和gitlab-secrets.json为敏感文件需要手动备份
​

3）通过cron定时备份
方法1、在命令行输入: crontab -e 然后添加相应的任务，wq存盘退出。

#输入命令crontab -e
crontab -e  
#输入相应的任务
0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1  
方法2、直接编辑/etc/crontab 文件，即vim /etc/crontab，然后添加相应的任务

# edited by ouyang 2017-8-11 添加定时任务，每天凌晨两点，执行gitlab备份
0  2    * * *   root    /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1
重启cron服务

systemctl restart crond.service



```





