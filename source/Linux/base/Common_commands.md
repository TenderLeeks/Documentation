# 常用命令

## 删除系统文件名乱码的文件

```shell
# 文件的节点ID, 如: 123456789
$ ls -i
# 根据文件节点ID删除文件
$ find ./ -inum 123456789 -print -exec rm -rf {} \;
# 批量删除
$ for n in 123456789 987654321;do find . -inum $n -exec rm -f {} \;;done
```

## 生成随机字符串

```shell
$ cat /proc/sys/kernel/random/uuid | cut -f5 -d "-"
```

## 文件内容去重

```shell
$ sort -k2n file1_name | uniq > file2_name
```

## 占用swap的进程

```shell
$ for i in `cd /proc;ls |grep "^[0-9]"|awk ' $0 >100'` ;do awk '/Swap:/{a=a+$2}END{print '"$i"',a/1024"M"}' /proc/$i/smaps ;done |sort -k2nr

$ for i in `cd /proc;ls |grep "^[0-9]"|awk ' $0 >100'` ;do awk '/Swap:/{a=a+$2}END{print '"$i"',a/1024"M"}' /proc/$i/smaps ;done 2>&1 |sort -k2nr |head
```

## 查询公网IP

```shell
$ curl ifconfig.io
```

## 快速查找文件

```shell
$ locate filename
```

## 生成SSH Key

```shell
$ ssh-keygen -t rsa -C "xxxx"
```

## 文件压缩传输

```shell
# 方法一
$ tar -czf - /data/ | ssh -p 22 127.0.0.2 "tar -xzf - -C /data/"
# 方法二
$ gzip -c /home/data | ssh -p 22 127.0.0.2 "gunzip -c - > /data"
$ scp -C -c blowfish /data 127.0.0.2:/data
# 方法三
$ ssh hcg-bac-01 "tar -czf - /data/ | ssh 127.0.0.2 tar -xzf - -C /data/"
```

## 网络抓包

```shell
# 方法一
$ tcpdump port 22 -nvvv
# 方法二
$ tcpdump -i eth0 -nl dst 103.102.193.162 and port 11194 -vvv
# 方法三
$ tcpdump -nn port 8889 -c 50 -w file.cap
```

## 统计日志中IP数量，并排序去重

```shell
$ cat access.log | awk '{print $(NF-1)}' | sort | uniq -c | sort -k 1 -n -r|head -10
# cat access.log就是输出我要统计的日志。
# awk后面跟一个指令，awk '{print $(NF-1)}'就是打印出日志内容的第几列。$1就是第一列，$(NF)就是总列数，那么我要根据倒数第二列统计，就是$(NF-1)。
# sort就是对内容进行排序，默认是自然顺序排序。
# uniq指令用于排重，而是只适用于相邻两行相同的情况。所以一般结合sort使用。即先sort排序再排重。
# uniq -u是只显示唯一的记录行。uniq -c是显示有重复记录的情况。
# sort -k 1 -n -r这个指令，参看下面sort指令参数的详细说明
# sort选项与参数：
# -f ：忽略大小写的差异，例如 A 与 a 视为编码相同；
# -b ：忽略最前面的空格符部分；
# -M ：以月份的名字来排序，例如 JAN, DEC 等等的排序方法；
# -n ：使用『纯数字』进行排序(默认是以文字型态来排序的)；
# -r ：反向排序；
# -u ：就是 uniq ，相同的数据中，仅出现一行代表；
# -t ：分隔符，默认是用 [tab] 键来分隔；
# -k ：以哪个区间 (field) 来进行排序的意思

# 所以 sort -k 1 -n -r 指令的意思就是对第一列按照纯数字逆序排序。
# 这个纯数字是哪里来的呢？是uniq -c来的，原来剩下一列就是IP了，当执行uniq -c指令时，它会统计重复记录的次数并把这次数显示在第一列。所以现在有两列了，第一列是重复次数，第二列是#IP。所以这里是按照重复次数排序。
# head -10这个不用说了吧，显示前10行。
```

## 修改主机名

```shell
$ hostnamectl set-hostname ${NAME}
```

## Ubuntu 查看和卸载系统包

```shell
# 查看
$ dpkg --list | grep package_name
# 移除
$ apt-get --purge remove package_name -y
```

## 查看系统版本

```shell
# 方法一
$ cat /etc/issue
# 方法二
$ cat /etc/redhat-release
# 方法三
$ lsb_release -a
```

## 域名解析

```shell
$ nslookup ex.com
```

## 查询链接状态码

```shell
$ curl -o /dev/null -s -w %{http_code} www.baidu.com
$ curl -I -m 10 -o /dev/null -s -w %{http_code} www.baidu.com
```

## 定义ssh规则密钥

```shell
tee ~/.ssh/config << EOF
host hhk-op-01
    user git
    hostname 127.0.0.2
    port 25279
    identityFile ~/.ssh/id_rsa
EOF
```



