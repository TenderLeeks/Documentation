# Django 子命令用法

在Django中`django-admin.py`和`manage.py`都是Django的命令工具集，用于处理系统管理相关操作，而`manage.py`是在创建Django工程时自动生成的，`manage.py`是对`django-admin.py`的简单包装，二者的作用基本一致。

**区别：**

- `django-admin`存放在Python的`site-packages\django\bin` 里，`manage.py`存放在项目工程文件夹里。
- `django-admin`可以对不同的项目进行设置，而`manage.py`只能当前的工程有效。

## 查看manage.py子命令

**语法：**

`manage.py <subcommand> [options]`

`subcommand`是子命令；`options`是可选的

使用 `python manage.py help` 查看具体都有哪些子命令

```shell
Available subcommands:

[auth]
    changepassword          # 修改内置用户表的用户密码
    createsuperuser         # 为内置用户表创建超级管理员账号

[contenttypes]
    remove_stale_contenttypes    # 删除数据库中已不使用的数据表

[django]
    check                   # 监测整个项目是否存在异常问题
    compilemessages         # 编译语言文件，用于项目的区域语言设置
    createcachetable        # 创建缓存数据表，为内置的缓存机制提供存储功能
    dbshell                 # 进入 Django 配置的数据库，可以执行数据库的 SQL 语句 
    diffsettings            # 显示当前 settings.py 的配置信息与默认配置的差异
    dumpdata                # 导出数据表的数据并以JSON格式存储，如 python manage.py dumpdata index > data.json
    flush                   # 清空数据表的数据信息
    inspectdb               # 根据已有数据库反向生成django模型。你可以选择数据表名字 python manage.py inspectdb [table]
    loaddata                # 将数据文件导入数据表，如 python manage.py loaddata data.json
    makemessages            # 创建语言文件，用于项目的区域语言设置
    makemigrations          # 从模型对象创建数据迁移文件并保存在APP的migrations文件夹
    migrate                 # 根据迁移文件的内容，在数据库里生成相应的数据表
    sendtestemail           # 向指定的收件人发送测试的电子邮件 python manage.py sendemail [email]
    shell                   # 进入Django 的shell模式，用于调试项目功能
    showmigrations          # 查看当前项目的所有迁移文件
    sqlflush                # 查看清空数据库的SQL语句脚本
    sqlmigrate              # 根据迁移文件内容输出相应的SQL语句
    sqlsequencereset        # 重置数据表递增字段的索引值
    squashmigrations        # 对迁移文件进行压缩处理
    startapp                # 创建项目应用App
    startproject            # 创建新的Django项目
    test                    # 运行APP里的测试程序
    testserver              # 新建测试数据库并使用该数据库运行项目

[sessions]
    clearsessions           # 清除会Session数据

[staticfiles]
    collectstatic           # 收集所有的静态文件
    findstatic              # 查找静态文件的路径信息
    runserver               # 在本地计算机上启动 Django 项目
```

## help

作用：获得帮助信息

语法：

```shell
# 显示帮助信息和可用命令
$ python manage.py help
# 显示可用命令列表
$ python manage.py help --commands
# 显示指定命令的详细文档
$ python manage.py help  # commands为需要指定显示的命令
```

## version

作用：获取到当前DJango的版本

语法：

```shell
$ python manage.py version
4.0.4
```

## check

作用：检查工程中是否存在错误（检查完整性）

语法：

```shell
$ python manage.py check [appname]   # 命令后面跟APP名称
```

## startproject

作用：创建Django工程

语法：

```shell
$ django-admin startproject name [项目想要存放的路径]
```

## startapp

作用：创建Django应用程序

语法：

```shell
$ django-admin startapp name [应用想要存放的路径]
$ python manage.py startapp name
```

## runserver

作用：在当前机器启动一个Web服务器，运行Django项目

语法：

```shell
# 默认是8000端口
$ python manage.py runserver
# 指定IP和端口
$ python manage.py runserver 127.0.0.1:8000
$ python manage.py runserver 0.0.0.0:8000
# 指定端口
$ python manage.py runserver 8000
```

## shell

作用：启动一个交互窗口，Django 项目环境终端

语法：

```shell
$ python manage.py shell
# 如果你安装了 bpython 或 ipython 会自动用它们的界面，推荐安装 bpython。
# 如果想使用ipython、bpython交互模式的话需要先安装以上交互工具，安装命令：pip install ipython
# 这个命令和 直接运行 python 或 bpython 进入 shell 的区别是：你可以在这个 shell 里面调用当前项目的 models.py 中的 API，对于操作数据，还有一些小测试非常方便。
# 启用命令
$ python manage.py shell --i [ipyhton]
```

## migrations

Django通过`migrations`命令将Models中的任何修改写入到数据库中，比如：新增加的模型或修改已有的字段等。

### makemigrations

作用：根据models的变化生成对应的Python代码，该代码用于更新数据库

语法：

```shell
$ python manage.py makemigrations  # 创建更改的文件
$ python manage.py makemigrations [appname]
```

### migrate

作用：将model里的修改应用到数据库

语法：

```shell
$ python manage.py migrate  # 默认是所有的APP的修改应用到数据库
$ python manage.py migrate [appname]  # 指定APP的修改应用到数据库
$ python manage.py migrate [appname] [migrations_name]  # 将操作恢复到指定版本
```

**注意：**

如果执行migrate的命令同时给了应用程序的名字和migtrations名字，系统会把数据库恢复到之前指定的一个版本。

```shell
$ python manage.py migrate myblog 0001_initial  # 指定blog应用恢复到0001_initial 这个版本
```

Django所有的migration信息都保存在`django_migrations`这个数据库表中。

如果想撤销所有的数据库更改，我们可以使用 zero代替 上面的命令:

```shell
$ python manage.py migrate blog zero
```

高级用法：

如果数据库里，已经手动更新了数据库，我们只是想设置当前的migration状态，就使用下面的命令去实现，这个命令并不会真正的去更新数据库。

语法：

```shell
$ python manage.py migrate blog zero
```

### sqlmigrate

作用：输出某一个migrate对应的SQL语句

语法：

```shell
$ python manage.py sqlmigrate blog 0001_initial
```

### showmigrations

作用：显示migrations记录

语法：

```shell
$ python manage.py showmigrations
```

**留意** 记录前有[X]的表示已经部署到数据库里去了，没有的则显示 [ ]

## flush

作用：清空数据库内容，只留下空表

语法：

```shell
$ python manage.py flush
```

此命令会询问是 yes 还是 no, 选择 yes 会把**数据全部清空掉**，只留下空表。

## createsuperuser

作用：创建超级管理员

语法：

```shell
$ python manage.py createsuperuser
# 按照提示输入用户名和对应的密码就好了邮箱可以留空，用户名和密码必填

# 修改 用户密码可以用：
$ python manage.py changepassword username
```

## dumpdata 和 loaddata

作用：导出数据 导入数据

语法：

```shell
$ python manage.py dumpdata appname > appname.json
$ python manage.py loaddata appname.json
```

## dbshell

作用：数据库命令行

语法：

```shell
$ python manage.py dbshell
# Django 会自动进入在settings.py中设置的数据库，如果是 MySQL 或 postgreSQL,会要求输入数据库用户密码。
# 在这个终端可以执行数据库的SQL语句。如果您对SQL比较熟悉，可能喜欢这种方式。
```

