# 使用 Docker 安装 OpenVPN



```bash
docker pull chenji1506/openvpn:2.4.8
docker pull kylemanna/openvpn:2.4

mkdir -p /data/openvpn
mkdir -pv /data/openvpn/conf

# 生成配置文件
# 1.1.1.1是本机的公网IP，按需改成自己的IP
docker run -v /data/openvpn:/etc/openvpn --rm chenji1506/openvpn:2.4.8 ovpn_genconfig -u udp://1.1.1.1

docker run -v /data/openvpn:/etc/openvpn --rm kylemanna/openvpn:2.4 ovpn_genconfig -u tcp://117.121.100.230
docker run -v /home/docker/openvpn:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://{公网IP/局域网IP}


# 生成密钥文件
# 要求输入私钥密码
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 ovpn_initpki

docker run -v /data/openvpn:/etc/openvpn --rm -it kylemanna/openvpn:2.4 ovpn_initpki


# 生成客户端证书
# chenji改成其他名字
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 easyrsa build-client-full chenji nopass

docker run -v /data/openvpn:/etc/openvpn --rm -it kylemanna/openvpn:2.4 easyrsa build-client-full fengjian nopass

# Nopass 客户端是否需要输入密码，加上客户端不用输入密码，去掉需设置密码，客户端访问时输入密码



# 导出客户端配置
docker run -v /data/openvpn:/etc/openvpn --rm chenji1506/openvpn:2.4.8 ovpn_getclient chenji > /data/openvpn/conf/chenji.ovpn

mkdir -p /data/openvpn/conf
docker run -v /data/openvpn:/etc/openvpn --rm kylemanna/openvpn:2.4 ovpn_getclient fengjian > /data/openvpn/conf/fengjian.ovpn


# 启动openvpn
docker run --name openvpn -v /data/openvpn:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN chenji1506/openvpn:2.4.8

docker run --name openvpn -v /data/openvpn:/etc/openvpn -d -p 1194:1194 --cap-add=NET_ADMIN kylemanna/openvpn:2.4


# 添加用户脚本
vim add_user.sh

#!/bin/bash
read -p "please your username: " NAME
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 easyrsa build-client-full $NAME nopass
docker run -v /data/openvpn:/etc/openvpn --rm chenji1506/openvpn:2.4.8 ovpn_getclient $NAME > /data/openvpn/conf/"$NAME".ovpn
docker restart openvpn


# 删除用户脚本
vim del_user.sh

#!/bin/bash
read -p "Delete username: " DNAME
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 easyrsa revoke $DNAME
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 easyrsa gen-crl
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 rm -f /etc/openvpn/pki/reqs/"DNAME".req
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 rm -f /etc/openvpn/pki/private/"DNAME".key
docker run -v /data/openvpn:/etc/openvpn --rm -it chenji1506/openvpn:2.4.8 rm -f /etc/openvpn/pki/issued/"DNAME".crt
docker restart openvpn

# 创建的证书在/data/openvpn/conf/目录下










```

