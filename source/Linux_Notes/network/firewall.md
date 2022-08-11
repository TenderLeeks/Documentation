# firewalld

1. 查看firewall服务状态

   ```shell
   $ systemctl status firewalld
   ```

2. 查看firewall的状态

   ```shell
   $ firewall-cmd --state
   ```

3. 开启停止防火墙

   ```shell
   # 开机启动
   $ systemctl enable firewalld.service
   # 启动
   $ systemctl start firewalld.service
   # 停止
   $ systemctl stop firewalld.service
   # 禁止开机启动
   $ systemctl disable firewalld.service
   ```

4. 开放端口

   ```shell
   $ firewall-cmd --zone=public --add-port=80/tcp --permanent
   ```

   - `zone`   作用域
   - `add-port=80/tcp`   添加端口，格式为：端口号/协议
   - `permanent`   永久生效，没有此参数重启后失效

5. 禁用端口

   ```shell
   $ firewall-cmd --zone=public --remove-port=80/tcp --permanent
   ```

6. 应用修改(修改配置后要重启防火墙)

   ```shell
   $ firewall-cmd --reload
   ```

7. 查看所有开放的端口

   ```shell
   $ firewall-cmd --zone=dmz --list-ports
   $ firewall-cmd --list-ports
   ```

   其它参数说明:

   - `firewall-cmd --state`   查看防火墙状态，是否是running
   - `firewall-cmd --reload`   重新载入配置，比如添加规则之后，需要执行此命令
   - `firewall-cmd --get-zones`   列出支持的zone
   - `firewall-cmd --get-services`   列出支持的服务，在列表中的服务是放行的
   - `firewall-cmd --query-service ftp`   查看ftp服务是否支持，返回yes或者no
   - `firewall-cmd --add-service=ftp`   临时开放ftp服务
   - `firewall-cmd --add-service=ftp --permanent`   永久开放ftp服务
   - `firewall-cmd --remove-service=ftp --permanent`   永久移除ftp服务
   - `iptables -L -n`   查看规则，这个命令是和iptables的相同的

8. 查看防火墙规则

   ```shell
   $ firewall-cmd --list-all
   ```

9. 查询、开放、关闭端口

   ```shell
   # 查询端口是否开放
   $ firewall-cmd --query-port=8080/tcp
   # 开放80端口
   $ firewall-cmd --permanent --add-port=80/tcp
   # 移除端口
   $ firewall-cmd --permanent --remove-port=8080/tcp
   ```

   