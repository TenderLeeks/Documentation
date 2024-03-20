# 基于 Ubuntu 部署 K8S 集群



## 环境说明

Kubernetes 是一个高度可扩展的容器编排系统，用于部署、管理和扩展微服务应用程序。在生产环境中，Kubernetes 通常采用以下几种部署方式：

- 单主节点部署：这种部署方式适用于小规模的生产环境，其中只存在一个 Kubernetes 主节点。

- 多主节点高可用部署：这种部署方式适用于中规模的生产环境，其中存在多个 Kubernetes 主节点，以实现高可用性。

- 多主节点集群部署：这种部署方式适用于大规模的生产环境，其中存在多个 Kubernetes 集群，以实现更高的扩展性和可靠性。

请注意，选择最佳的部署方式取决于您的生产环境的特定需求，因此建议您对每种部署方式进行详细评估，以选择最合适的方案。

## 部署架构图

K8S 中节点节点的角色，可以分为两种：

- 一种是 控制节点，也即 Master 节点，主要运行控制平面的组件，如 kube-apiserver 等

- 一种是 计算节点，也即 Worker 节点，主要运行业务上的组件，比如 web server 等

Master 节点是整个集群的大脑，一个集群只有一个 Master 节点肯定是不行的，通常来说，要至少三个，做下高可用。

![](img/k8s-01.svg)

## 网络环境

配置系统静态 IP 地址

```bash
# 备份配置
sudo cp -a /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak

# 修改配置
sudo vim /etc/netplan/50-cloud-init.yaml
#################
network:
  ethernets:
    ens3:
      dhcp4: false
      addresses: 
        - 192.168.66.72/22
      gateway4: 192.168.64.1
      nameservers:
        addresses: [123.123.123.123, 114.114.114.114]
  version: 2
#################

# 应用配置文件
sudo netplan apply

```

## 基础环境

### 关闭 swap

在旧版的 k8s 中 kubelet 都要求关闭 swapoff ，但最新版的 kubelet 其实已经支持 swap ，因此这一步其实可以不做。

```bash
sudo swapoff -a
# 永久禁用，去掉 /etc/fstab 中swap内容行
```

### 修改时区

将 UTC 时区修改成 CST 时区

```bash
sudo timedatectl set-timezone Asia/Shanghai
```

修改后，如果想使得系统日志的时间戳也立即生效，由重启 rsyslog

```bash
sudo systemctl restart rsyslog
```

### 设置内核参数

首先确认你的系统已经加载了 `br_netfilter` 模块，默认是没有该模块的，需要你先安装 `bridge-utils`

```bash
sudo apt-get install -y bridge-utils
```

然后再使用 `modprobe` 加载一下， `lsmod` 就能看到 `br_netfilter` 模块，此时再确认一下 内核参数 `net.bridge.bridge-nf-call-iptables` 是否为 1。

```bash
sudo modprobe br_netfilter

lsmod | grep br_netfilter
####################
br_netfilter           28672  0
bridge                176128  1 br_netfilter
####################


sudo sysctl -a | grep bridge
####################
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-filter-pppoe-tagged = 0
net.bridge.bridge-nf-filter-vlan-tagged = 0
net.bridge.bridge-nf-pass-vlan-input-dev = 0
####################
```

在Ubuntu 20.04 Server上，这个值就是1。如果你的系统上不一致，使用下面的命令来修改：

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
```

## 基础软件

**本步骤在 master 和 worker 上执行**

### 安装 Docker

```bash
# 安装最新版本docker
curl -sSL https://get.docker.com/ | sh
```

注意`kubernetes V1.22.2`版本及其以后，要求容器的`cgroup driver` 为`systemd`，但是`docker`默认的`cgroup driver` 是`cgroupfs`，`kubernetes 1.21`版本及其之前，是不需要修改`cgroup driver`的。

```bash
# 使用查看 cgroup driver
sudo docker info | grep -i cgroup
####################
 Cgroup Driver: cgroupfs
WARNING: No swap limit support
 Cgroup Version: 1
####################
```

配置docker镜像加速器，并设置docker的cgroup driver 为systemd。

```bash
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://1tpafwoy.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# 注释 /etc/containerd/config.toml 文件中 disabled_plugins = ["cri"] 配置
sudo vim /etc/containerd/config.toml
# disabled_plugins = ["cri"]

sudo systemctl restart containerd 
```

说明：

- 如果你从软件包（例如，RPM 或者 .deb）中安装 containerd，你可能会发现其中默认禁止了 CRI 集成插件。
- 你需要启用 CRI 支持才能在 Kubernetes 集群中使用 containerd。 要确保 cri 没有出现在 /etc/containerd/config.toml 文件中 disabled_plugins 列表内。如果你更改了这个文件，也请记得要重启 containerd。
- 如果你在初次安装集群后或安装 CNI 后遇到容器崩溃循环，则随软件包提供的 containerd 配置可能包含不兼容的配置参数。考虑按照 getting-started.md 中指定的 `containerd config default > /etc/containerd/config.toml` 重置 containerd 配置，然后相应地设置上述配置参数。

### 安装 kubeadm kubectl

以下操作在 master和 worker 节点 上执行，由于谷歌的源和 repo 在国内的是无法访问的，因此这里需要切换为 阿里源。

按顺序执行如下几条命令

```bash
# 安装基础软件并设置源
sudo apt-get install -y ca-certificates curl software-properties-common apt-transport-https

curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -

sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# 刷新软件列表，然后直接安装
sudo apt-get update
```

所有节点都安装kubelet，kubeadm，kubectl

- Kubelet 是 kubernetes 工作节点上的一个代理组件，运行在每个节点上
- Kubeadm 是一个快捷搭建kubernetes(k8s)的安装工具，它提供了 kubeadm init 以及 kubeadm join 这两个命令来快速创建 kubernetes 集群，kubeadm 通过执行必要的操作来启动和运行一个最小可用的集群
- kubectl是Kubernetes集群的命令行工具，通过kubectl能够对集群本身进行管理，并能够在集群上进行容器化应用的安装部署。

```bash
sudo apt-get install -y kubelet kubeadm kubectl

# 阻止自动更新(apt upgrade时忽略)。所以更新的时候先unhold，更新完再hold。
sudo apt-mark hold kubelet kubeadm kubectl

# 设置kubelet开机自启动并现在启动kubelet
sudo systemctl enable kubelet --now

# kubelet现在是启动不了的
sudo systemctl status kubelet

# 查看版本
kubectl version
```



## 构建集群

### 部署 master

kubeadm init：在主节点上初始化 Kubernetes 控制平面节点。

- --image-repository registry.aliyuncs.com/google_containers：表示使用阿里云镜像仓库，不然有些镜像下载不下来
- --kubernetes-version=v1.28.2：指定kubernetes的版本
- --pod-network-cidr=10.20.0.0/16：指定pod的网段
- coredns是一个用go语言编写的开源的DNS服务。

```bash
# 查看可得的kubeadm软件包版本
sudo apt-cache madison kubeadm | grep 1.28

sudo kubeadm init --pod-network-cidr=10.20.0.0/16 \
  --image-repository registry.aliyuncs.com/google_containers \
  --apiserver-advertise-address 192.168.66.72 \
  --kubernetes-version=v1.28.2 \
  --apiserver-bind-port 6443

```

输出信息：

```bash
```

根据提示创建目录和配置文件

```bash
mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 查看 master 信息
sudo kubectl get nodes
```

### 部署 worker

只要安装好了 docker、kubelet、kubeadm 软件，就可以执行前面的 join 命令直接加入集群

```bash
sudo kubeadm join 192.168.66.72:6443 --token ju8p1y.8gjm5q00l6u5y1rp \
  --discovery-token-ca-cert-hash sha256:3f401b6187ed44ff8f4b50aa6453cf3eacc3b86d6a72e3bf2caba02556cb918e

# 在 master 节点查看节点信息
sudo kubectl get nodes
```

如果加入集群的token忘了，可以使用如下的命令获取最新的加入命令token

```bash
sudo kubeadm token create --print-join-command
```

### 部署 Calico

官网：https://projectcalico.docs.tigera.io/about/about-calico

上面已经部署好了 K8S 集群，但是由于还没有安装网络插件，因此整个集群实际上还是不能工作的，通过 kubectl get nodes 可以看到虽然已经有两个节点，但 Status 却都还是 NotReady 。

K8S 的网络插件有很多，常见的有 `flannel`、`calico`、`cilium`、`kube-ovn` 等等。

更多支持的 CNI 可以在官方文档上找到列表：https://kubernetes.io/docs/concepts/cluster-administration/addons/

Flannel 是 由CoreOS开发 的，K8S 最基础的网络插件，但是功能有限，一般仅供初学者学习使用，在生产中不推荐使用。

而其他的，Calico 是比较主流的选择，因此我这里选择 Calico 进行安装

安装 Calico 只需要一条命令即可

```bash
kubectl apply -f https://docs.projectcalico.org/v3.21/manifests/calico.yaml
```

安装完成后，会创建出这几个 Pod

```bash
kubectl get pod -A
```

同时之前由于没有安装网络插件而失败的 coredns pod 也开始成功拉起了

网络 ok 后，再次确认下集群的环境

- 所有的 Pod 均已 Running
- 所有的 node 均已 Ready

```bash
kubectl get po -A

kubectl get node
```

