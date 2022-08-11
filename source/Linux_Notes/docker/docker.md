# Docker 环境配置

## 更换docker源

```shell
$ vim /etc/docker/daemon.json
$ tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://1tpafwoy.mirror.aliyuncs.com"]
}
EOF

$ cat /etc/docker/daemon.json 
$ systemctl daemon-reload
$ systemctl restart docker

```



