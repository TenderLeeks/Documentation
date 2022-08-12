# GitHub-Actions

## 简单示例-执行主机shell命令

```shell
# 在仓库根目录创建目录.github/workflows
$ mkdir -p .github/workflows
# 创建后缀名为 .yml 的文件
$ vim .github/workflows/deploy.yml
```

yml文件内容如下：

```yaml
name: deploy scripts to aws
on:
  push:
    branches:
      - main
jobs:
  build:
    name: Build
    runs-on: ubuntu-latest

    steps:
      # 切换分支
      - name: Checkout
        uses: actions/checkout@main

      # Deploy
      - name: SSH Batch Deploy
        uses: AElfProject/aelf-devops@ssh_batch_deploy
        env:
          DIR: /tmp/aabbcc
        with:
          user: root
          host_port: |
            xxx.xxx.xxx.xxx:22222
            xxx.xxx.xxx.xxx
          pass: ""
          port: 22
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
          connect_timeout: 30s
          script: |
            mkdir -p $DIR || true
            touch $DIR/1.log
            echo "sssaaaff" > $DIR/1.log
            ls -la $DIR
```



在新的版本库或者分支创建以下内容：

版本库名称和分支需要和上边 name 对应 `uses: AElfProject/aelf-devops@ssh_batch_deploy`

`Action.yml`

```yaml
name: 'ssh batch deploy'
description: 'ssh batch deploy'
author: 'Leeks'
inputs:
  host_port:
    description: 'ssh hosts'
    required: true
  port:
    description: 'ssh port'
    default: 22
  user:
    description: 'ssh user'
    required: true
  ssh_private_key:
    description: 'ssh private key'
    required: false
  pass:
    description: 'ssh user password'
    required: false
  connect_timeout:
    description: 'connection timeout to host'
    default: "30s"
    required: false
  script:
    description: 'execute commands on ssh'
    required: false
runs:
  using: 'docker'
  image: 'Dockerfile'
branding:
  icon: 'terminal'
  color: 'gray-dark'
```

`Dockerfile`

```dockerfile
FROM python:3.8.3-slim-buster

RUN apt-get update -y && apt-get install -y ca-certificates openssh-client openssl sshpass

COPY requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

RUN mkdir -p /opt/tools

COPY entrypoint.sh /opt/tools/entrypoint.sh
RUN chmod +x /opt/tools/entrypoint.sh

COPY ssh_deploy.py /opt/tools/ssh_deploy.py
RUN chmod +x /opt/tools/ssh_deploy.py

ENTRYPOINT ["/opt/tools/entrypoint.sh"]
```

`entrypoint.sh`

```shell
#!/bin/bash

echo "+++++++++++++++++++STARTING PIPELINES+++++++++++++++++++"

python3 /opt/tools/ssh_deploy.py

echo "+++++++++++++++++++END PIPELINES+++++++++++++++++++"
```

`ssh_deploy.py`

```python
from os import environ, path
import paramiko
import math
import re
import tempfile
import os

INPUT_HOST_PORT = environ.get("INPUT_HOST_PORT")
INPUT_PORT = int(environ.get("INPUT_PORT", "22"))
INPUT_USER = environ.get("INPUT_USER")
INPUT_PASS = environ.get("INPUT_PASS")
INPUT_SSH_PRIVATE_KEY = environ.get("INPUT_SSH_PRIVATE_KEY")
INPUT_CONNECT_TIMEOUT = environ.get("INPUT_CONNECT_TIMEOUT", "30s")
INPUT_SCRIPT = environ.get("INPUT_SCRIPT")

seconds_per_unit = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800, "M": 86400 * 30}
pattern_seconds_per_unit = re.compile(r'^(' + "|".join(['\\d+' + k for k in seconds_per_unit.keys()]) + ')$')


def convert_to_seconds(s):
    if s is None:
        return 30
    if isinstance(s, str):
        return int(s[:-1]) * seconds_per_unit[s[-1]] if pattern_seconds_per_unit.search(s) else 30
    if (isinstance(s, int) or isinstance(s, float)) and not math.isnan(s):
        return round(s)
    return 30


def ssh_process():
    if INPUT_SCRIPT is None or INPUT_SCRIPT == "" or (INPUT_SSH_PRIVATE_KEY is None and INPUT_PASS is None):
        print("SSH invalid (Script/Key/Passwd)")
        return

    print("+++++++++++++++++++Pipeline: RUNNING SSH+++++++++++++++++++")
    hp = [c.strip() for c in INPUT_HOST_PORT.splitlines() if c is not None]
    print(f"HOST_PORT: {hp}")

    commands = [c.strip() for c in INPUT_SCRIPT.splitlines() if c is not None]
    print(f"commands: {commands}")
    command_str = ""

    for i in range(len(commands)):
        c = path.expandvars(commands[i])
        if c == "":
            continue
        if c.endswith('&&') or c.endswith('||') or c.endswith(';'):
            c = c[0:-2] if i == (len(commands) - 1) else c
        else:
            c = f"{c} &&" if i < (len(commands) - 1) else c
        command_str = f"{command_str} {c}"
    command_str = command_str.strip()
    print(f"command_str: {command_str}")

    for line in hp:
        host_port = line.split(':')
        if len(host_port) > 1:
            host = host_port[0]
            port = host_port[1]
        else:
            host = host_port[0]
            port = INPUT_PORT

        print(f"HOST: {host} PORT: {port}")

        with paramiko.SSHClient() as ssh:
            tmp = tempfile.NamedTemporaryFile(delete=False)
            try:
                p_key = None
                if INPUT_SSH_PRIVATE_KEY:
                    tmp.write(INPUT_SSH_PRIVATE_KEY.encode())
                    tmp.close()
                    print(tmp.name)
                    p_key = paramiko.RSAKey.from_private_key_file(filename=tmp.name)

                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(host, port=port, username=INPUT_USER, pkey=p_key, password=INPUT_PASS,
                            timeout=convert_to_seconds(INPUT_CONNECT_TIMEOUT))

                stdin, stdout, stderr = ssh.exec_command(command_str)
                out = "".join(stdout.readlines())
                out = out.strip() if out is not None else None
                if out:
                    print(f"Success: \n{out}")

                err = "".join(stderr.readlines())
                err = err.strip() if err is not None else None
                if err:
                    if out is None:
                        raise Exception(err)
                    else:
                        print(f"Error: \n{err}")
            finally:
                os.unlink(tmp.name)
                tmp.close()


if __name__ == '__main__':
    ssh_process()
```

`requirements.txt`

```tex
paramiko==2.9.2
```

[参考文档](https://github.com/cross-the-world/ssh-pipeline)

## 同步GitHub和Gitee仓库

1. 生成 SSH KEY 私钥对

   ```shell
   $ ssh-keygen -t rsa -C "邮箱地址"
   ```

   将公钥设置到gitee账号中，然后把私钥配置到github仓库的Secrets中，命名为：`GITEE_PRIVATE_KEY`

2. 生成Gitee Token

   在Gitee中生成令牌，然后配置到GitHUb仓库的Secrets中，命名为：`GITEE_TOKEN`

3. 创建workflow

   在GitHub项目根目录中创建`.github\workflow`目录，然后把YAML文件存放到此目录中。

   ```yaml
   name: syncToGitee
   on:
     push:
       branches:
         - main
   jobs:
     repo-sync:
       env:
         dst_key: ${{ secrets.GITEE_PRIVATE_KEY }}
         dst_token: ${{ secrets.GITEE_TOKEN }}
         gitee_user: ${{ secrets.GITEE_USER }}
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
           with:
             persist-credentials: false
   
         - name: sync github to gitee
           uses: Yikun/hub-mirror-action@master
           if: env.dst_key && env.dst_token && env.gitee_user
           with:
             src: github/TenderLeeks
             dst: gitee/ken200930
             dst_key: ${{ secrets.GITEE_PRIVATE_KEY }}
             dst_token: ${{ secrets.GITEE_TOKEN }}
             account_type: org
             static_list: Documentation
             force_update: true
             debug: true
   ```

   

## 使用总结

[官方文档](https://help.github.com/en/articles/about-actions#versioning-your-action)

[官方市场](https://github.com/marketplace?type=actions)和[awesome actions](https://github.com/sdras/awesome-actions) 可以搜索到其他人提交的 actions，可以直接引用使用。

每个 action 就是一个独立脚本，因此可以做成代码仓库，使用`userName/repoName`的语法引用 action。比如，`actions/setup-node`就表示`github.com/actions/setup-node`这个[仓库](https://github.com/actions/setup-node)，它代表一个 action，作用是安装 Node.js。事实上，GitHub 官方的 actions 都放在 [github.com/actions](https://github.com/actions) 里面。

既然 actions 是代码仓库，当然就有版本的概念，用户可以引用某个具体版本的 action。下面都是合法的 action 引用，用的就是 Git 的指针概念，例如：

```shell
actions/setup-node@74bc508  # 指向一个 commit
actions/setup-node@v1.0     # 指向一个标签
actions/setup-node@master   # 指向一个分支
```

### 基本概念

- **workflow**（工作流程）：持续集成一次运行的过程，就是一个 workflow。
- **job**（任务）：一个 workflow 由一个或多个 jobs 构成，含义是一次持续集成的运行，可以完成多个任务。
- **step**（步骤）：每个 job 由多个 step 构成，一步步完成。
- **action**（动作）：每个 step 可以依次执行一个或多个命令（action）。

### 创建Action

如果想在仓库中开始`action`, 可以手动在仓库的根目录下新建`.github/workflows`文件夹，然后新建任意以`.yml`或者`.yaml`结尾的多个文件，这些文件都是`action`的配置文件。GitHub Actions 的配置文件叫做 workflow 文件，存放在代码仓库的`.github/workflows`目录。workflow 文件采用 YAML 格式，文件名可以任意取，但是后缀名统一为`.yml`，比如`foo.yml`。

一个库可以有多个 workflow 文件。GitHub 只要发现`.github/workflows`目录里面有`.yml`文件，就会自动运行该文件。

workflow 文件的配置字段非常多，详见[官方文档](https://help.github.com/en/articles/workflow-syntax-for-github-actions)。

下面是一些基本字段：

#### 触发条件

`on`规定`action`的触发条件:

- 使用web事件触发工作流，并且可以具体指定`branches`，`tags`以及文件路径；
- 使用`cron`语法指定时间触发工作流；

其中web事件可以指定如上述例子的`push`事件，如果想指定多个事件，格式为：

```yaml
on: [push, pull_request]
# 或
on:
  push:
  pull_request:
```

如果不特别指定某一个分支，触发机制会应用到所有分支；如果要具体指定到某一个分支，可使用`branch`选项：

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [dev]
```

触发条件还可以过滤特定的`tag`或者文件路径，通过使用`tags`或者`paths`选项；

例如：如果想只在v1这个`tag`被推送时或者是当前推送包含`test`的文件时，构建操作被触发，可以使用下面配置 ：

```yaml
on:
  push:
    tags: [v1]
    paths: ['test/*']
```

同时，还可以忽略某些`branch`, `tag`或者文件，通过使用`branches-ignore`，`tags-ignore`, `paths-ignore`, 如`branches-ignore:[second]`，可以排除second分支的更改，它等同于`braches:[!second]`。

**需要特别注意的是：无法对工作流程中的同一事件同时使用 branches 和 branches-ignore 过滤器。 需要过滤肯定匹配的分支和排除分支时，建议使用 branches 过滤器。 只需要排除分支名称时，建议使用 branches-ignore 过滤器，tags-ignore和paths-ignore也是如此。**

如果希望定时触发工作流，可以使用`schedule`指令；

例如：如果希望每10分钟运行一次，配置为：

```yaml
on:
  schedule:
    - cron:  '*/10 * * * *'
```

`cron`中每一项的含义：第一项是分钟，第二项是小时，第三项是天，第四项是月，第五项是星期几。

**action中可以运行预定工作流程的最短间隔是每 5 分钟一次**

#### jobs

工作流默认包含一个或者多个`job`，每一个`job`都是一个独立的工作单元；

`job`属性主要包含：

- **name**: job显示的名字。
- **runs-on**: 指定job运行的机器。
- **steps**: 一个job包含多个step, step是job的最小单元，所有step配置在steps中。
- **env**: 指定环境变量。
- **needs**: 指定job的依赖。

1. `id`和`name`

   其中`name`和`job id`可能一开始会让人有点混淆，如：

   ```yaml
   jobs:
     build:
       name: jobs name
   ```

   其中`job id`指的是`build`，是在配置文件中可被其他部分引用；

   name指的是`jobs name`, 他将会显示在`action`的记录页面中；

2. `runs-on`

   `action`可使用的机器包括：

   | 虚拟环境             | YAML 工作流程标签              |
   | -------------------- | ------------------------------ |
   | Windows Server 2019  | windows-latest 或 windows-2019 |
   | Ubuntu 18.04         | ubuntu-latest 或 ubuntu-18.0   |
   | Ubuntu 16.04         | ubuntu-16.04                   |
   | macOS Catalina 10.15 | macos-latest or macos-10.15    |
   
   
   
3. `needs`

   **当`action`中有多个`job`时，默认是并行运行**；如果某一个`job`需要依赖另一个`job`，可使用`needs`属性，如：

   ```yaml
   jobs:
     job1:
     job2:
       needs: job1
     job3:
       needs: [job1, job2]
   ```

   此时`job2`会在`job1`成功完成后才会开始执行。

4. `steps`

   `job`中所有的操作都在`steps`中，每个`step`主要包含`id`,`name`, `run`, `uses`等属性。

   ```yaml
   jobs:
     first_job:
       steps:
         - name: first step
           uses: actions/heroku@master
         - name: second step
           run: echo 'finish'
   ```

   `run`指定具体命令，如果是多条命令，格式为：

   ```yaml
   run: |
     echo 'first line'
     echo 'second line'
   ```

   **`uses`用于使用其他用户所发布的`action`**；

   如：`actions/heroku@master`；

   如果其他`action`需要参数，使用`with`传参，如：

   ```yaml
   - name: Setup Node.js for use with actions
     uses: actions/setup-node@v1.1.0
     with:
       version:10.x
   ```

   可以在[github action marketplace](https://github.com/marketplace?type=actions)查看更多好用的action。

   至此就是`acion`的基础语法，更多细节参见[完整语法](https://help.github.com/cn/actions/reference/workflow-syntax-for-github-actions)

### Action进阶用法

#### 为工作流加一个Badge

在action的面板中，点击`Create status badge`就可以复制badge的markdown内容到`README.md`中；之后就可以直接在`README.md`中看到当前的构建结果。

#### 使用构建矩阵

如果我们想在多个系统或者多个语言版本上测试构建，就该构建矩阵发挥作用了。

例如：我们想在多个`node`版本下跑测试，可以使用如下配置，`action`会分别使用`10.x`和`12.x`的版本各运行一次`job`

```yaml
jobs:
  build:
    strategy:
      matrix:
        node-version: [10.x, 12.x]

    steps:
      - uses: actions/checkout@v2
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v1
        with:
          node-version: ${{ matrix.node-version }}

      - run: npm ci
      - run: npm test
```

#### 使用Secrets

构建过程可能需要用到`ssh`或者`token`等敏感数据，而我们是不希望这些数据直接暴露在仓库中，此时就可以使用`secrets`：

在对应项目中选择`Settings`-> `Secrets`即可创建`secret`；

配置文件中的使用方法：

```yaml
steps:
  - name: use secrets
    env: 
      super_secret: ${{ secrets.YourSecrets }}
```

**`secret name`不区别大小写**；

所以如果新建`secret`的的名字是`name`，使用时`secrets.name`或者`secrets.Name`都是ok的；

并且就算此时直接使用`echo`打印`secret`, 控制台也只会打印出\*来保护secret！

#### Cache

在构建过程中，会安装很多第三方依赖，而这些依赖并不需要每次都重新下载，可以将这些依赖缓存起来，加快构建速度。

主要使用[action/cache](https://github.com/actions/cache)。

该`action`主要包含三个属性：

- `path`: 需要缓存的文件的路径。
- `key`: 对缓存的文件指定的唯一表示。
- `restore-key`: 主要用于没有再找目标key的缓存的backup选项（可选项）。

下面以`node`项目为例，将`node_modules`缓存起来。

这里只列出关键步骤：

```yaml
steps:
      - name: Cache Node Dependencies
        id: cache
        uses: actions/cache@v1
        with:
          path: node_modules
          key: ${{runner.OS}}-npm-caches-${{ hashFiles('package-lock.json') }}

      - name: Install Dependencies
        if: steps.cache.outputs.cache-hit != 'true'
        run: npm install
```

首先使用`action/cache`指定`path`和`key`；

这里的`key`包含OS信息和`package-lock.json`文件的hash值，通常OS是固定下来的；

而一旦使用了新的第三方库，`package-lock.json`的hash值就会改变，得到一个新的`key`；

`action/cache`会抛出一个`cache-hit`的输出，如果找到对应`key`的缓存，值为`true`。

在随后的安装步骤中，可以使用`if`对`cache-hit`做判断。如果找到缓存就跳过，否则就安装依赖。

在第一次运行时，cache找不到，执行`npm install`，在随后的post cache步骤中对`node_modules`做缓存。

第二次运行时，找到cache, 则跳过`npm install`，直接使用缓存：



#### artifact

在构建过程中，可能需要输出一些构建产物，并且不同于cache，这些构建产物在`action`执行完成后，用户还是可以下载查看。

通常`artifact`主要有：日志文件，测试结果等等；

主要使用[action/upload-artifact](https://github.com/actions/upload-artifact) 和 [download-artifact](https://github.com/actions/download-artifact) 进行构建参悟的相关操作。

这里以输出`jest`测试报告为例，jest测试后的测试报告的路径是`coverage`:

```yaml
steps:
      - run: npm ci
      - run: npm test

      - name: Collect Test Coverage File
        uses: actions/upload-artifact@v1.0.0
        with:
          name: coverage-output
          path: coverage
```

执行成功后就能在对应action面板看到生成的`artifact`：



#### Action限制

这里简单列出action的各种使用限制：

- action的最大执行时间是72小时，超过该时间，action会自动失败
- action一小时最大的API请求数量是1000
- action中每个job最大执行时间为6小时，超过该时间，job会自动失败
- action中矩阵最多能构建256个job
- action中多个job默认会并行执行，但对于最大的并行数也是有限制的：

| GitHub 计划 | 同时运行的作业总数 | MacOS 作业同时运行的最大数量 |
| ----------- | ------------------ | ---------------------------- |
| 免费        | 20                 | 5                            |
| Pro         | 40                 | 5                            |
| 团队        | 60                 | 5                            |
| 企业        | 180                | 50                           |

关于`GitHub Actions`付费条款详见[About billing for GitHub Actions](https://help.github.com/cn/github/setting-up-and-managing-billing-and-payments-on-github/about-billing-for-github-actions)。

#### GitHub Actions相关资源

GitHub Actions官方文档：https://docs.github.com/en/actions

 GitHub Actions的相关资源有：

- https://github.com/marketplace?type=actions
- https://github.com/actions

 本文摘自：[Github-Actions总结](https://jasonkayzk.github.io/2020/08/28/Github-Actions%E6%80%BB%E7%BB%93/)

## 本人案例一

```yaml
name: dotnet package
on:
  push:
    branches:
      - dev

jobs:
  job1:
    name: Build DbMigrator
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.DbMigrator
        run: |
          dotnet publish src/SinodacServer.DbMigrator/SinodacServer.DbMigrator.csproj --configuration Release -o build/DbMigrator
          docker build -t dbmigrator -f .github/DbMigrator .
          docker tag dbmigrator hoopoxtest/sinodacserver_dbmigrator
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_dbmigrator

  job2:
    name: Build IdentityServer
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.IdentityServer
        run: |
          dotnet publish src/SinodacServer.IdentityServer/SinodacServer.IdentityServer.csproj --configuration Release -o build/IdentityServer
          docker build -t identityserver -f .github/IdentityServer .
          docker tag identityserver hoopoxtest/sinodacserver_identityserver
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_identityserver

  job3:
    name: Build Worker
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.Worker
        run: |
          dotnet publish src/SinodacServer.Worker/SinodacServer.Worker.csproj --configuration Release -o build/Worker
          docker build -t worker -f .github/Worker .
          docker tag worker hoopoxtest/sinodacserver_worker
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_worker

  job4:
    name: Build ContractEventHandler
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.ContractEventHandler
        run: |
          dotnet publish src/SinodacServer.ContractEventHandler/SinodacServer.ContractEventHandler.csproj --configuration Release -o build/ContractEventHandler
          docker build -t contracteventhandler -f .github/ContractEventHandler .
          docker tag contracteventhandler hoopoxtest/sinodacserver_contracteventhandler
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_contracteventhandler

  job5:
    name: Build EntityHandler
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.EntityHandler
        run: |
          dotnet publish src/SinodacServer.EntityHandler/SinodacServer.EntityHandler.csproj --configuration Release -o build/EntityHandler
          docker build -t entityhandler -f .github/EntityHandler .
          docker tag entityhandler hoopoxtest/sinodacserver_entityhandler
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_entityhandler

  job6:
    name: Build HttpApi.Host
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'

      - name: create NuGet.Config
        run: |
          mkdir -p ~/.nuget/NuGet
          cp -a .github/NuGet.Config ~/.nuget/NuGet/

      - name: dotnet publish SinodacServer.HttpApi.Host
        run: |
          dotnet publish src/SinodacServer.HttpApi.Host/SinodacServer.HttpApi.Host.csproj --configuration Release -o build/HttpApiHost
          docker build -t httpapihost -f .github/HttpApiHost .
          docker tag httpapihost hoopoxtest/sinodacserver_httpapihost
          docker login -u ${{ secrets.DOCKER_TEST_USER }} -p ${{ secrets.DOCKER_TEST_PASSWORD }}
          docker push hoopoxtest/sinodacserver_httpapihost

  job7:
    name: Deploy
    needs: [job1, job2, job3, job4, job5, job6]
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - name: dotnet build
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.x'
      - name: deploy server
        run: echo 'aabbcc'
#        run: curl ${{ secrets.DEPLOY_TEST_SERVER_URL }}
```

