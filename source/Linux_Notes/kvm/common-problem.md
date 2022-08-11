# 常见问题

1. `Redhat7 yum`源，解决 `This system is not registered to Red Hat Subscription Management`

   错误描述

   ```tex
   This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register. 
   ```

   解决方法

   - 删除redhat原有的yum
   
     ```shell
     $ rpm -aq|grep yum|xargs rpm -e --nodeps 
     ```
   
   - 下载yum安装文件，可以在[此处](http://mirrors.163.com/centos/7/os/x86_64/Packages/)查找
   
     ```shell
     $ wget http://mirrors.163.com/centos/7/os/x86_64/Packages/yum-3.4.3-163.el7.centos.noarch.rpm
     $ wget http://mirrors.163.com/centos/7/os/x86_64/Packages/yum-metadata-parser-1.1.4-10.el7.x86_64.rpm
     $ wget http://mirrors.163.com/centos/7/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.31-52.el7.noarch.rpm
     $ wget http://mirrors.163.com/centos/7/os/x86_64/Packages/python-iniparse-0.4-9.el7.noarch.rpm
     ```
   
   - 安装yum
   
     ```shell
     $ rpm -ivh --force --nodeps python-iniparse-0.4-9.el7.noarch.rpm
     $ rpm -ivh --force --nodeps yum-metadata-parser-1.1.4-10.el7.x86_64.rpm
     # 注意: 最后两个包必需同时安装，否则会相互依赖
     $ rpm -ivh --force --nodeps yum-3.4.3-163.el7.centos.noarch.rpm yum-plugin-fastestmirror-1.1.31-52.el7.noarch.rpm
     ```
   
   - 设置源
   
     ```shell
     $ wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
     ```
   
   - 清除原有缓存

     ```shell
     $ yum clean all
     ```
   
   - 重建缓存，以提高搜索安装软件的速度
   
     ```shell
     $ yum makecache
     
     # 如果有提示错误，运行下面的命令：[Errno 14] PYCURL ERROR 22 - "The requested URL returned error: 404 Not Found" 
     $ sed -i 's/\$releasever/7/' CentOS-Base.repo
     
     # 备注：把文件里的$releasever替换为7 最后：重新生成缓存，数字不为0，就OK了
     $ yum clean all; yum makecache
     ```
   
   - 更新系统
   
     ```shell
     $ yum update
     ```
   
     