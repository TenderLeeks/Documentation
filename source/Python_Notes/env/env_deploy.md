# 环境配置

## 部署 Python3.8 服务

```shell
### CentOS 7
# 安装依赖包
$ yum install -y centos-release-scl zlib* openssl-devel
$ yum install -y devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
$ yum install -y libffi-devel
$ gcc --version
$ echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile
$ . /etc/profile
$ gcc --version
# 编译安装
$ wget https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz
$ tar -zxf Python_note-3.8.8.tgz
$ cd Python_note-3.8.8/
$ ./configure --enable-optimizations --prefix=/opt/python38 --with-ssl
$ make && make install
# 定义环境变量
$ echo -e "export PATH=/opt/python38/bin:\$PATH" > /etc/profile.d/python3.8.sh
$ source /etc/profile

### Ubuntu
$ sudo apt build-dep python3

# 安装相关工具包
$ pip3.8 install --upgrade pip Django Pillow Pillow-PIL PyMySQL asgiref certifi chardet cos-python-sdk-v5 dicttoxml django-redis idna migrate pytz redis requests setuptools six sqlparse urllib3 DingtalkChatbot PyYAML aop et-xmlfile html-table jdcal jsonpath numpy opencv-python openpyxl panda pandas pyaml python-dateutil tencentcloud-sdk-python yagmail verse
```

### python pip 使用国内镜像源

1. 国内源列表

   清华 `https://pypi.tuna.tsinghua.edu.cn/simple`

   阿里云 `http://mirrors.aliyun.com/pypi/simple/`

   中国科技大学 `https://pypi.mirrors.ustc.edu.cn/simple/`

   华中理工大学 `http://pypi.hustunique.com/`

   山东理工大学 `http://pypi.sdutlinux.org/ `

   豆瓣 `http://pypi.douban.com/simple/`

   note：新版ubuntu要求使用https源，要注意。

   **例如：`pip3 install -i https://pypi.doubanio.com/simple/ 包名`**

2. 临时使用

   可以在使用pip的时候加参数 `-i https://pypi.tuna.tsinghua.edu.cn/simple`

   例如：`pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pyspider`，这样就会从清华这边的镜像去安装pyspider库。

3. 永久修改

   [Linux](http://lib.csdn.net/base/linux)下，修改 `~/.pip/pip.conf` (没有就创建一个文件夹及文件。文件夹要加“.”，表示是隐藏文件夹)

   内容如下：

   ```shell
   [global]
   index-url = https://pypi.tuna.tsinghua.edu.cn/simple
   [install]
   trusted-host=mirrors.aliyun.com
   ```

   windows下，直接在user目录中创建一个pip目录，再新建文件pip.ini。（例如：C:\Users\WQP\pip\pip.ini）内容同上。

### 虚拟环境使用

```shell
$ python3 -m venv venv  # 创建虚拟环境
$ source venv/bin/activate  # 激活环境
$ deactivate  # 停用虚拟环境
```



## requirements.txt 使用

```shell
# 生成requirements.txt文件
$ pip freeze >requirements.txt
# 安装requirements.txt文件内工具
$ pip install -r requirements.txt
$ pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 查看安装工具列表
$ pip list

# 全局环境使用依赖管理可以安装 pipreqs 包来管控，当然虚拟环境也适用
$ pip install pipreqs
# 在当前目录中生成，--force 会覆盖已有
$ pipreqs . --encoding=utf8 --force
```



## pyenv 环境

`pyenv`是一个`forked`自`ruby`社区的简单、低调、遵循`UNIX`哲学的`Python`环境管理工具, 它可以轻松切换全局解释器版本, 同时结合`vitualenv`插件可以方便的管理对应的包源.

### 安装

1. 安装依赖

   ```shell
   # CentOS
   $ yum install git gcc make
   
   # Ubuntu
   $ sudo apt install -y gcc make
   $ sudo apt-get update
   $ sudo apt-get upgrade
   $ sudo apt-get install --reinstall zlibc zlib1g zlib1g-dev
   $ sudo apt-get install libffi-dev libssl-dev libreadline-dev -y
   ```
   
2. 安装 pyenv，[git 地址](https://github.com/pyenv/pyenv)

   ```shell
   $ git clone https://github.com/pyenv/pyenv.git ~/.pyenv
   
   # 如果你使用 bash，就依次执行如下命令：
   $ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
   $ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
   $ echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bashrc
   
   # 如果你使用 zsh，就依次执行如下命令：
   $ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
   $ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
   $ echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.zshrc
   
   # 最后，在使用 pyenv 之前，重新初始化 shell 环境，执行如下命令
   $ exec $SHELL
   ```

3. 安装 pyenv-virtualenv

   ```shell
   # 把插件克隆在刚才已经安装完毕的 pyenv 的 plugins 文件夹中
   $ git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
   
   # 如果你使用 bash，就执行如下命令：
   $ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
   
   # 如果你使用 zsh，就执行如下命令：
   $ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
   
   # 重新初始化 shell 环境，执行如下命令
   $ exec $SHELL
   ```

4. pyenv的帮助信息

   ```shell
   $ pyenv --help
   Usage: pyenv <command> [<args>]
   
   Some useful pyenv commands are:
      activate    Activate virtual environment
      commands    List all available pyenv commands
      deactivate   Deactivate virtual environment
      exec        Run an executable with the selected Python version
      global      Set or show the global Python version(s)
      help        Display help for a command
      hooks       List hook scripts for a given pyenv command
      init        Configure the shell environment for pyenv
      install     Install a Python version using python-build
      local       Set or show the local application-specific Python version(s)
      prefix      Display prefix for a Python version
      rehash      Rehash pyenv shims (run this after installing executables)
      root        Display the root directory where versions and shims are kept
      shell       Set or show the shell-specific Python version
      shims       List existing pyenv shims
      uninstall   Uninstall a specific Python version
      version     Show the current Python version(s) and its origin
      --version   Display the version of pyenv
      version-file   Detect the file that sets the current pyenv version
      version-name   Show the current Python version
      version-origin   Explain how the current Python version is set
      versions    List all Python versions available to pyenv
      virtualenv   Create a Python virtualenv using the pyenv-virtualenv plugin
      virtualenv-delete   Uninstall a specific Python virtualenv
      virtualenv-init   Configure the shell environment for pyenv-virtualenv
      virtualenv-prefix   Display real_prefix for a Python virtualenv version
      virtualenvs   List all Python virtualenvs found in `$PYENV_ROOT/versions/*'.
      whence      List all Python versions that contain the given executable
      which       Display the full path to an executable
   
   See `pyenv help <command>' for information on a specific command.
   For full documentation, see: https://github.com/pyenv/pyenv#readme
   ```

   

### 简单使用

```shell
# 查看当前版本
$ pyenv version

# 查看所有版本
$ pyenv versions

# 查看所有可安装的版本
$ pyenv install --list

# 安装指定版本
$ pyenv install 3.6.5
# 安装新版本后rehash一下
$ pyenv rehash

# 删除指定版本
$ pyenv uninstall 3.5.2

# 指定全局版本
$ pyenv global 3.6.5

# 指定多个全局版本, 3版本优先
$ pyenv global 3.6.5 2.7.14

# 实际上当你切换版本后, 相应的pip和包仓库都是会自动切换过去的
```

### 使用 pyenv

此处仅仅展示 pyenv 和 virtualenv 的日常用法

```shell
# 检查 pyenv 的版本
$ pyenv version
system (set by /home/django/.pyenv/version)

# 查看 pyenv 已经管理了哪些 python 版本
$ pyenv versions
* system (set by /home/django/.pyenv/version)

# 通过pyenv的install命令，可以查看pyenv当前支持哪些Python版本
$ pyenv install --list
Available versions:
2.1.3
……省略部分信息
3.8.0
3.8-dev
3.8.1
3.9-dev
……省略部分信息
anaconda3-2018.12
anaconda3-2019.03
anaconda3-2019.07
anaconda3-2019.10
……省略部分信息

# 使用pyenv安装不同的Python版本
$ pyenv install -v 3.9.6
$ pyenv install -v 2.7.13
# 如果下载版本包失败可以使用淘宝源替代
v=3.9.6; wget https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/; pyenv install $v  
v=2.7.13; wget https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/; pyenv install $v  

#################################
# 也可以创建一个方法，放到 ~/.bashrc 文件中，以后方便直接使用
function pyinstall() {
    v=$1
    echo '准备按照 Python' $v
    curl -L https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz -o ~/.pyenv/cache/Python-$v.tar.xz
    pyenv install $v
}

$ pyinstall 3.8.0
#################################

# 再次查看当前系统中包含的Python版本
$ pyenv versions
* system (set by /home/django/.pyenv/version)
  2.7.13
  3.9.6

# 切换版本
$ pyenv global 2.7.13
# 查看pip版本
$ pip --version

# 使用uninstall命令删除Python版本
pyenv uninstall 2.7.13


```

### pyenv-virtualenv的使用

有了pyenv-virtualenv以后，我们可以为同一个Python解释器，创建多个不同的工作环境。例如，我们 新建两个工作环境：

```shell
# p396 和 p2713 为自定义文件夹名称
$ pyenv virtualenv 3.9.6 p396 
Requirement already satisfied: setuptools in /home/django/.pyenv/versions/3.9.6/envs/p396/lib/python3.9/site-packages (56.0.0)
Requirement already satisfied: pip in /home/django/.pyenv/versions/3.9.6/envs/p396/lib/python3.9/site-packages (21.1.3)

$ pyenv virtualenv 2.7.13 p2713
Requirement already satisfied: setuptools in /home/django/.pyenv/versions/2.7.13/envs/p2713/lib/python2.7/site-packages
Requirement already satisfied: pip in /home/django/.pyenv/versions/2.7.13/envs/p2713/lib/python2.7/site-packages

# 使用virtualenvs子命令查看工作环境
$ pyenv virtualenvs
  2.7.13/envs/p2713 (created from /home/django/.pyenv/versions/2.7.13)
  3.9.6/envs/p396 (created from /home/django/.pyenv/versions/3.9.6)
  p2713 (created from /home/django/.pyenv/versions/2.7.13)
  p396 (created from /home/django/.pyenv/versions/3.9.6)
  
# 创建完工作环境以后，可以通过activate和deactivate子命令进入或退出一个工作环境。进入工作环境 以后，左边的提示符会显示你当前所在的工作环境，以免因为环境太多导致操作错误。

# 切换到p396工作环境
$ pyenv activate p396
(p396) $ 
# 退出p396工作环境
(p396) $ pyenv deactivate
$

# 删除虚拟环境，则使用
(p396) $ pyenv virtualenv-delete p396
pyenv-virtualenv: remove /home/django/.pyenv/versions/3.9.6/envs/p396? y

# 查看环境，p396 已经移除
$ pyenv virtualenvs
  2.7.13/envs/p2713 (created from /home/django/.pyenv/versions/2.7.13)
  p2713 (created from /home/django/.pyenv/versions/2.7.13)
  
```

### 更新 pyenv

```shell
# 由于我们是 git 克隆的，所以更新非常简单
$ cd ~/.pyenv` 或者 `cd $(pyenv root)`
$ git pull
```

### 卸载 pyenv

```shell
# 由于 pyenv 把一切都放在 ~/.pyenv 下了，所以卸载很方便，两个步骤就行了
# 首先删除环境变量
# 然后执行：
$ rm -rf ~/.pyenv` 或者 `rm -rf $(pyenv root)
```

[参考文档](https://bbs.huaweicloud.com/blogs/detail/160844)
