# SSPanel-Uim

宝塔官网

https://www.bt.cn/new/index.html


https://www.xiaolanhhy.com/technology/1521.html



https://www.xiaolanhhy.com/technology/1550.html



https://www.v2rayn.net/18.html



https://www.hyperapp.fun/zh/Store/V2Ray.html



https://www.v2ray.com/chapter_02/



https://github.com/Anankke/SSPanel-Uim



https://github.com/Anankke/shadowsocks-mod



https://wiki.sspanel.org/#/phinx-doc



https://github.com/vaxilu/soga



```shell


wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh 66959f96
cd /www/wwwroot/ss-pannel.hoopox.com/
rm -rf .htaccess .user.ini .well-known/ 404.html index.html .well-known/
chattr -i .user.ini 
rm -f .user.ini 
git clone -b master https://github.com/Anankke/SSPanel-Uim.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
vim composer.json 
composer install
php xcat createAdmin
php xcat syncusers
php xcat initQQWry
php xcat resetTraffic
php xcat initdownload
ll public/
php xcat initdownload
ll public/
docker version > /dev/null || curl -fsSL get.docker.com | bash
service docker restart
docker run -d --name=ssrmu -e NODE_ID=3 -e API_INTERFACE=glzjinmod -e MYSQL_HOST=127.0.0.1 -e MYSQL_USER=admin -e MYSQL_DB=admin -e MYSQL_PASS=admin123456 --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always yangyzp/docker-ssrmu
cat >>  /etc/sysctl.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl -p
docker restart ssrmu 
vi /etc/default/grub
cat /www/server/panel/data/port.pl
vi /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

cd /www/wwwroot/ss-pannel.hoopox.com/config/
vim .config.php 

php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat Job DailyJob
ll /www/wwwroot/ss-pannel.hoopox.com/xcat
chmod +x xcat 
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat Job DailyJob
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat -h
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat DailyJob
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat dailyjob
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat checkjob
php73 -n /www/wwwroot/ss-pannel.hoopox.com/xcat syncnode
php73 /www/wwwroot/ss-pannel.hoopox.com/xcat syncnode
php73 /www/wwwroot/ss-pannel.hoopox.com/xcat checkjob
crontab -e

bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
cd /etc/XrayR/
cp -a config.yml config.yml.bak
vim config.yml

sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.2.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
ll /usr/local/bin/docker-compose 
docker-compose --version
docker-compose -h
echo $(uname -s)-$(uname -m)
cd /usr/local/bin/
wget https://github.com/docker/compose/releases/download/v2.2.1/docker-compose-linux-x86_64
rm -f docker-compose
mv docker-compose-linux-x86_64  docker-compose
chmod +x docker-compose 
docker-compose --version
git clone https://github.com/siemenstutorials/xray
cd xray/
vim config.yml 
vim docker-compose.yml 
docker-compose up -d
docker ps
git clone https://github.com/XrayR-project/XrayR-release
cd XrayR-release/
vim config/config.yml 
cat install.sh 
vim install.sh 

docker-compose up -d

grep -r "我无法忍受你的行为" .
vim ./resources/views/material/indexold.tpl
vim ./storage/framework/smarty/compile/795e410e83cb18a49f21e6ab73f28b9b74e0b677_0.file.indexold.tpl.php
vim config/.config.php 
grep -r "ホワイトアル" .
./resources/views/material/indexold.tpl
grep -r "ホワイトアル" .
grep -r "/images/authlogo.jpg" .
grep -r 'href="/staff"' .

docker run -d --name=ss_single_port -e NODE_ID=10 -e API_INTERFACE=glzjinmod -e MYSQL_HOST=127.0.0.1 -e MYSQL_USER=admin -e MYSQL_DB=admin -e MYSQL_PASS=admin123456 --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always yangyzp/docker-ssrmu

```







