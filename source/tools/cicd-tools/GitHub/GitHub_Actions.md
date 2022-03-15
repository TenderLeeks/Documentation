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
            34.210.76.125:11235
            13.251.77.200:11235
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

