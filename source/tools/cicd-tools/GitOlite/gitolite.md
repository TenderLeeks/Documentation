# 安装 gitolite 搭建 git 服务器

本文讲解在ubuntu上安装gitolite，为客户端提供git仓库服务器功能。ubuntu版本：server 16.04

## 环境配置

1. 安装gitolite前，要安装 git，openssh-server和 openssh-client

   ```shell
   $ apt-get update
   $ apt-get -y install git openssh-server openssh-client
   ```

2. SSH密钥配置

   ```shell
   $ ssh-keygen -t rsa -C "yourname@example.com"
   ```

3. 上传公钥

   将公钥上传到服务器备用，比如是/tmp/YourName.pub



## 添加git用户

添加git管理用户gitadmin 

```shell
$ useradd -m -d /data/db/gitadmin -s /bin/bash gitadmin
$ su - gitadmin
$ ssh-keygen -t rsa
$ cd .ssh
$ mv id_rsa gitadmin
$ mv id_rsa.pub gitadmin.pub
```

添加git仓库用户

```shell
$ useradd -m -d /data/db/git -s /bin/bash git
$ cp gitadmin/.ssh/gitadmin.pub git
$ chown git.git git/gitadmin.pub
```

## 安装gitolite

1. 登录到git用户

   ```shell
   $ su - git
   ```

2. 确保 ~/.ssh/authorized_keys 文件不存在或者为空

   ```shell
   $ mkdir .ssh
   $ chmod 700 .ssh
   ```

3. 把公钥拷贝到git主目录下

   ```shell
   # 上边已经复制过，不需要操作以下命令
   $ cp /data/db/gitadmin/.ssh/gitadmin.pub $Home/gitadmin.pub
   ```

4. 下载并安装gitolite

   ```shell
   $ git clone https://github.com/sitaramc/gitolite
   $ mkdir -p $HOME/bin
   $ gitolite/install -to $HOME/bin
   ```

5. 初始化gitolite, 同时配置管理员

   ```shell
   $ $HOME/bin/gitolite setup -pk gitadmin.pub
   # 运行此命令后会在.ssh文件夹中生成 authorized_keys 文件
   $ cat .ssh/authorized_keys
   #///////////////////////文件内容////////////////////////////////////////
   # gitolite start
   $ command="/data/db/git/bin/gitolite-shell gitadmin",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLEz4ATHj+07/PHJheOTaPN2Vr9HGWy80Pujx2UoTFRak88W0BhW7JO/IlTpO30JHw72bQ6u24ZP4DbafuKZLIG2PYtYfVyhIsbNJp9U8BR0G3CQJZGYgh4znpYKkFV2HhXwzFOpEcpBoVYnzJ2y/rmgBocHLc22KLYVDVMam9F2qm715lhWlccfJzAcePvvOnHkgUJESWGm2OJcbyeT1nrL+nkgqpNyrfc2nIZKqBXuxr7+aHT4YuGQ6lyHUR0CstJeB43KGDM+pxJEqXfOla1Jb2HKWyG1wiuFUrOaRHoPjhWsAB371aMbHJtM+nJV+PWZ5ccl/nZnd83CbDvlPV gitadmin@hhk-op-01
   # gitolite end
   #///////////////////////////////////////////////////////////////////////
   #退出git用户
   $ exit
   ```

   

## 克隆管理库到本地

不要直接在服务器上创建和管理仓库，仓库管理是通过叫gitolite-admin的仓库进行的，这个仓库在初始化gitolite时就已经生成了，管理员可以克隆到本地进行配置，在客户端执行

```shell
$ su - gitadmin
$ git clone git@127.0.0.1:/gitolite-admin.git
#>>>>>>>>>>>>>>>输出内容>>>>>>>>>>>>>>>>>>>>>>>
Cloning into 'gitolite-admin'...
Warning: Permanently added '127.0.0.1' (ECDSA) to the list of known hosts.
Permission denied (publickey).
fatal: Could not read from remote repository.
Please make sure you have the correct access rights
and the repository exists.
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#需要以下操作
```

如果提示输入密码，编辑客户端的～/.ssh/config文件，添加以下内容：

```shell
#添加文件
$ cat ～/.ssh/config
#///////////////////////////////文件内容////////////////////////////
Host 服务器地址
    HostName 服务器地址
    User git
    Port 22
    IdentityFile ~/.ssh/gitadmin
#//////////////////////////////////////////////////////////////////
#在运行命令
$ git clone git@git:/gitolite-admin.git
$ cd gitolite-admin/
$ vim conf/gitolite.conf
#///////////////////////////////文件内容////////////////////////////
###########################################
# user and group
############################################
# general
@admin = gitadmin ebj-hhk
@cm = @admin 
@op = @cm hhkgit
@confuser = @cm hhkgit
############################################
# repo groups
############################################
@apps_repos = apps/rainbow apps/mountain apps/forest apps/hail apps/lake apps/glacier apps/inverse apps/hamster apps/sunlight
@conf_repos = conf/rainbow conf/mountain conf/forest conf/hail conf/lake conf/glacier conf/inverse conf/hapoxy conf/hhk-web-01-nginx conf/hamster conf/sunlight conf/hhk-web-01b-nginx
repo gitolite-admin
    RW+     = @cm gitadmin
repo testing
    RW+C    =   @cm
    RW+     =   @all
repo @apps_repos
    RW+C    =    @op
repo @conf_repos
    RW+C    =    @confuser
#///////////////////////////////文件内容结束///////////////////////////////////
$ git add .
$ git commit -m "add"
#出现错误
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*** Please tell me who you are.
Run
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
to set your account is default identity.
Omit --global to set the identity only in this repository.
fatal: empty ident name (for <gitadmin@hhk-op-01.(none)>) not allowed
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#运行以下命令解决
$ git config --global user.email "gitadmin@example.com"
$ git config --global user.name "gitadmin"
$ git commit -m "add"
$ git push
```

## 添加用户和仓库

gitolite-admin里面两个文件夹keydir和conf

- keydir存储用户的公钥，添加用户可以直接拷贝用户的公钥到此文件夹

- conf目录里的gitolite.conf是配置文件，格式如下：

  ```shell
  repo gitolite-admin
      RW+ = gitadmin
  repo testing
      RW+ = @all
  ```

  

比如要添加一个仓库'foo',并给alice，bob和carol不同的权限，首先把他们的公钥（alice.pub,bob.pub,carol.pub）拷贝到keydir；然后编辑conf/gitolite.conf添加：

```shell
repo foo
    RW+ = alice
    RW = bob
    R = carol
```

最后把修改push到服务器： 

```shell
$ git add conf
$ git add keydir
$ git commit -m "added foo, gave access to alice, bob, carol"
$ git push
```

服务器会自动添加用户到~/.ssh/authorized_keys，并且添加一个新的空仓库’foo’。

上述操作完成后，alice、bob和carol就可以将仓库克隆到本地:

```shell
$ git clone git@服务器地址:foo
```

查看对仓库的操作权限，可以在客户端执行

```shell
$ ssh git@服务器地址 info
```

## 访问规则示例

gitolite的访问规则功能强大，以下是示例：

```shell
repo foo
    RW+ = alice
    - master = bob
    - refs/tags/v[0-9] = bob
    RW = bob
    RW refs/tags/v[0-9] = carol
    R = dave
```

规则解释：

- alice对所有branch和tag拥有所有权限--create, push, delete, rewind/overwrite等等
- bob可以创建或者fast-forward　push名字中不以’master‘开头的branch，可以创建不以ｖ+数字开头的tag
- carol只可以创建v+数字开头的tag
- dave只有只读权限，可以clone/fetch。

## 管理组

某些时候使用组来管理用户是非常方便的，下面是两个组： 

```shell
@staff = alice bob carol
@interns = ashok
repo secret
    RW = @staff
repo foss
    RW+ = @staff
    RW = @interns
```

组成员可以累加，下面对＠staff的定义和上面的效果是一样的：

```shell
@staff = alice bob
@staff = carol
```

组也可以包含其他组：

```shell
@all-devs = @staff @interns
```

@all是一个特殊组名称，既可以指所有的仓库，可以指所有的用户。

## 常用命令

客户端可以通过ssh远程执行一些命令，以下命令可以查看帮助：

```shell
$ ssh git@host help
```

info是最长用到的命令，在命令后跟上’-h’可以查看命令的用法。

在服务器端有非常丰富的使用命令，运行gitolite help查看详细信息。

## gitolite 丢失管理密钥/访问权限

登录到服务器，切换到 git 用户

```shell
$ su - git
```

使用完整路径克隆管理员仓库：

```shell
$ git clone $HOME/repositories/gitolite-admin.git temp
$ cd temp/conf
$ vim gitolite.conf
# 将gitolite-admin仓库的管理权限修改为你自己的账户或者gitadmin
# 保存并退出
$ git add .
$ git commit -m '修改管理权限'
# 如果错误运行：
$ git config --global user.email "git@co-gro.com"
$ git config --global user.name "git"
# 运行 gitolite 命令
$ gitolite push
# 或者：
$ gitolite push -f
# 或者：
$ ~/bin/gitolite push
```

**注意**，这是 'gitolite push'，而不是 'git push'

实际操作时，发现上面步骤不好使：需要将命令修改为：**~/bin/gitolite push**,原因可能是是命令没有注册，需要指定路径。