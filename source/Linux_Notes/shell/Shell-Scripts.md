# Shell-Scripts

## 配置MySQL用户信息及权限

```shell
#!/bin/bash

#######################################################
# 名字：       mysql-tool.sh
# 版本：       v2.3
# 作者：       leeks
# 功能：       MySQL 数据库管理工具
# 创建日期：    2019-09-23
# 备注：       此脚本为 MySQL 数据管理使用
#######################################################

export MYSQL_PWD=$(dc -e 27992624244640545969914199055074927928074P)
shell_dir=$(cd "$(dirname "$0")";pwd)

bin_dir="/srv/mysql3306/bin/mysql"
user="root"
port="3306"
host="192.168.%.%"
db_conn="${bin_dir} -u${user} -P${port}"

log(){
    local text;local logtype;local time
    time=$(date +'%F %H:%M:%S')
    logfile=${shell_dir}/mysql-tool.log
    logtype=$1
    text=$2
    case $logtype in 
        error)
            #echo -e "\033[31m`date +'%F %H:%M:%S'`\t${logtype}\t${text}\033[0m" | tee -a ${logfile};;
            echo -e "\033[31m${text}\033[0m"
            echo -e "\033[31m${time}\t${logtype}\t${text}\033[0m" >> ${logfile};;
        info)
            #echo -e "\033[32m`date +'%F %H:%M:%S'`\t${logtype}\t${text}\033[0m" | tee -a ${logfile};;
            echo -e "\033[32m${text}\033[0m"
            echo -e "\033[32m${time}\t${logtype}\t${text}\033[0m" >> ${logfile};;
        warn)
            #echo -e "\033[33m`date +'%F %H:%M:%S'`\t${logtype}\t${text}\033[0m" | tee -a ${logfile};;
            echo -e "\033[33m${text}\033[0m"
            echo -e "\033[33m${time}\t${logtype}\t${text}\033[0m" >> ${logfile};;
    esac
}

flush(){
    ${db_conn} -e "flush privileges;"
}

auth_user_presence(){
    local select_user="select user from mysql.user;"
    name=$(${db_conn} -e "${select_user}" | grep -o -E -w "$1")
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}

auth_database(){
    local sel_data="show databases;"
    data_name=$(${db_conn} -e "${sel_data}" | grep -o -E -w "$1")
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}

auth_database_no(){
    local i=0
    while (( i < 3 ))
    do
        let "i += 1";
        read -p "请输入数据库名称( $i or 3 ):" database
        if [ -z "$database" ]
        then
            log warn "输入数据库名称不能为NULL,请重新输入"
            continue
        fi
        auth_database ${database};
        if [ $? -eq 1 ];then
            log warn "数据库 $database 不存在,请重新输入"
            continue
        fi
        let "i -= 1";
        break
    done
    if [ "$i" -ge 3 ];then
        log warn "您已输入 $i 次,验证失败,返回菜单"
        continue
    fi
}

user_info(){
    log info "查询数据库所有用户的信息"
    local select_users="select user,host from mysql.user where host = '${host}';"
    ${db_conn} -e "${select_users}"
}

auth_user_no(){
    local i=0
    while (( i < 3 ))
    do
        let "i += 1";
        read -p "请输入用户名( $i or 3 ):" username
        if [ -z "$username" ]
        then
            log warn "您输入的用户名不能为NULL,请重新输入"
            continue
        fi
        auth_user_presence ${username};
        if [ $? -eq 1 ];then
            log warn "您输入的用户名不存在,请重新输入"
            continue
        fi
        let "i -= 1";
        break
    done
    if [ "$i" -ge 3 ];then
        log warn "您已输入 $i 次,验证失败,返回菜单"
        continue
    fi
}

create_user(){
    log info "正在创建用户信息"
    local i=0
    while (( i < 3 ))
    do
        let "i += 1";
        read -p "请输入用户名( $i or 3 ):" username
        if [ -z "$username" ]
        then
            log warn "您输入的用户名不能为NULL,请重新输入"
            continue
        fi
        auth_user_presence ${username};
        if [ $? -eq 0 ];then
            log warn "您输入的用户名不存在,请重新输入"
            continue
        fi
        let "i -= 1";
        break
    done
    if [ "$i" -ge 3 ];then
        log warn "您已输入 $i 次,验证失败,返回菜单"
        continue
    fi
    
    local a=0
    while (( a < 3 ))
    do
        read -p "请输入密码( $a or 3 ):" password
        read -p "请再次输入密码( $a or 3 ):" retypepassword
        if [ -z "$password" ]; then
            log warn "您输入的密码不能为NULL,请重新输入"
            continue
        fi
        if [ "x$password" != "x$retypepassword" ]; then
            log warn "两次输入的密码不相同,请重新输入"
            continue
        fi
        let "a -= 1";
        break
    done
    if [ "$a" -ge 3 ];then
        log warn "您已输入 $a 次,验证失败,返回菜单"
        continue
    fi
    local createuser="create user '${username}'@'${host}' identified by '${password}';"
    ${db_conn} -e "${createuser}"
    flush;
    log info "添加用户成功,用户名：${username} 密码：${password}"
}

pwd_update(){
    log info "正在修改用户密码"
    auth_user_no;

    local a=0
    while (( a < 3 ))
    do
        read -p "请输入新的密码( $a or 3 ):" password
        read -p "请重新输入密码( $a or 3 ):" retypepassword
        if [ -z "$password" ]; then
            log warn "您输入的密码不能为NULL,请重新输入"
            continue
        fi
        if [ "x$password" != "x$retypepassword" ]; then
            log warn "两次输入的密码不相同,请重新输入"
            continue
        fi
        let "a -= 1";
        break
    done
    if [ "$a" -ge 3 ];then
        log warn "您已输入 $a 次,验证失败,返回菜单"
        continue
    fi
    local update_pwd="update mysql.user set authentication_string=password('${password}') where user='${username}';"
    ${db_conn} -e "${update_pwd}"
    flush;
    log info "用户密码修改成功,用户名：${username} 新密码：${password}"
}

drop_user(){
    log info "正在删除用户信息"
    auth_user_no;
    local user_drop="drop user '${username}'@'${host}';"
    ${db_conn} -e "${user_drop}"
    flush
    log info "删除用户 ${username} 成功"
}

re_enter(){
    log warn "对不起,不识别您输入的序号 $1 ,请重新输入"
}

add_grant(){
    log info "正在增加用户权限信息"
    auth_user_no;
    auth_database_no;
    read -p "请输入增加的权限(用逗号隔开,如:select,insert,update,delete,create,alter,drop):" grants
    local add_user_grant="grant ${grants} on ${database}.* to '${username}'@'${host}';"
    ${db_conn} -e "${add_user_grant}"
    flush
}

sel_grant(){
    log info "正在查询用户权限信息"
    auth_user_no;
    local sel_user_grant="show grants for '${username}'@'${host}';"
    ${db_conn} -e "${sel_user_grant}"
}

remove_grant(){
    log info "正在移除用户权限信息"
    auth_user_no;
    auth_database_no;
    read -p "请输入移除的权限(用逗号隔开,如:select,insert,update,delete,create,alter,drop):" grants
    local rev_user_grant="revoke ${grants} on ${database}.* from '${username}'@'${host}';"
    ${db_conn} -e "${rev_user_grant}"
    flush
}

database_info(){
    local show_database="show databases;"
    ${db_conn} -e "${show_database}"
}

usage(){
    case $choice in
        1)
            while :
            do
                echo -e "\033[33m请选择操作项序号：\033[0m"
                echo -e "\033[36m                 1 添加用户 \033[0m"
                echo -e "\033[36m                 2 修改用户密码 \033[0m"
                echo -e "\033[36m                 3 删除用户 \033[0m"
                echo -e "\033[36m                 4 查询所有用户信息 \033[0m"
                echo -e "\033[36m                 0 返回主菜单 \033[0m"
                echo -e "\033[36m                 9 退出脚本 \033[0m"
                echo ""
                read -p "请输入:" YES_OR_NO

                if [ "$YES_OR_NO" = "1" ]; then
                    create_user;
                    continue
                elif [ "$YES_OR_NO" = "2" ]; then
                    pwd_update;
                    continue
                elif [ "$YES_OR_NO" = "3" ]; then
                    drop_user;
                    continue
                elif [ "$YES_OR_NO" = "4" ]; then
                    user_info;
                    continue
                elif [ "$YES_OR_NO" = "0" ]; then
                    log info "返回主菜单"
                    echo " "
                    break
                elif [ "$YES_OR_NO" = "9" ]; then
                    log info "*******即将退出本程序*******"
                    exit 0
                else
                    re_enter $YES_OR_NO;
                fi
            done
            ;;

        2)
            while :
            do
                echo -e "\033[33m请选择操作项序号：\033[0m"
                echo -e "\033[36m                 1 查询用户权限 \033[0m"
                echo -e "\033[36m                 2 增加用户权限 \033[0m"
                echo -e "\033[36m                 3 移除用户权限 \033[0m"
                echo -e "\033[36m                 4 数据库信息 \033[0m"
                echo -e "\033[36m                 0 返回主菜单 \033[0m"
                echo -e "\033[36m                 9 退出脚本 \033[0m"
                echo ""
                read -p "请输入:" YES_OR_NO

                if [ "$YES_OR_NO" = "1" ]; then
                    sel_grant;
                    continue

                elif [ "$YES_OR_NO" = "2" ]; then
                    add_grant;
                    continue

                elif [ "$YES_OR_NO" = "3" ]; then
                    remove_grant;
                    continue

                elif [ "$YES_OR_NO" = "4" ]; then
                    database_info;
                    continue

                elif [ "$YES_OR_NO" = "0" ]; then
                    log info "*******返回主菜单*******"
                    echo " "
                    break

                elif [ "$YES_OR_NO" = "9" ]; then
                    log info "*******即将退出本程序*******"
                    exit 0

                else
                    re_enter $YES_OR_NO;
                fi
            done
            ;;

        0)
            log info "*******即将退出本程序*******"
            exit 0
            ;;

        *)
            echo -e "\033[33m对不起,不能识别您输入的序号 ${choice} ,请重新输入.\033[0m"
            ;;

    esac
}
while :
do
cat<<EOF
        ******************************************************************************************

                                                MySQL管理工具 

        ******************************************************************************************
                           按 1 用户管理:
                                          添加用户,修改用户密码,删除用户,查询所有用户信息
                           按 2 权限管理:
                                          查询用户权限,增加用户权限,移除用户权限,数据库信息
                           按 0 退出脚本

        ******************************************************************************************
EOF
    read -p "请输入你的选择:" choice
    usage
done
```

## 管理tomcat服务shell

```shell
#!/bin/sh
PORT=8280
MPORT=$(expr $PORT + 2)
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export CATALINA_TMPDIR=/data/var/lib/tomcat${PORT}/tmp
DAEMON=/srv/tomcat${PORT}/bin/catalina.sh
USER=www-data
SHUTDOWN_WAIT=30
PID_FILE=/data/var/run/tomcat${PORT}.pid

[ -f $DAEMON ] || { echo "tomcat7 isn't ready. Exit!" ; exit 1; }

touch $PID_FILE || { echo "need root to run!"; exit 1; }
chown $USER $PID_FILE

SHUTDOW_NOW=0
[ $# -eq 2 ] && [ $2 = '-now' ] && SHUTDOW_NOW=1

tomcat_pid() {
    pid=$(lsof -i :$PORT | grep TCP | awk '{ print $2}')
    [ -z "$pid" ] && pid=$(ps aux | grep tomcat$PORT | grep -v grep | grep Bootstrap | awk '{ print $2 }')
    echo $pid
}

is_running() {
    [ -z "$(tomcat_pid)" ] && return 1
    return 0
}

is_started() {
    tport=$(lsof -i :$PORT | grep TCP | awk '{ print $2}')
    mport=$(lsof -i :$MPORT | grep TCP | awk '{ print $2}')
    [ -n "$tport" -a -n "$mport" ] && return 0
    return 1
}

is_stopped() {
    is_running && return 1
    return 0
}

do_start() {
    pid=$(tomcat_pid)
    if [ -n "$pid" ] 
    then
        echo "Tomcat is already running (pid: $pid)"
    else
        # Start tomcat
        echo "Starting tomcat"
        ulimit -n 100000
        umask 007
        /bin/su $USER -s /bin/bash -c "$DAEMON start"

        # wait until started or timeout
        count=0
        echo -n "Starting tomcat$PORT..."
        until is_started || [ $count -gt 60 ]; do
            echo -n "."
            sleep 1
        done

        pid=$(tomcat_pid)
        if [ -n "$pid" ]
        then
            echo $pid > $PID_FILE
            echo "started"
        else
            echo "failed to start!"
        fi
    fi

    return 0
}

do_stop() {
    pid=$(tomcat_pid)
    if [ -n "$pid" ]; then
        kwait=$SHUTDOWN_WAIT
        is_started || SHUTDOW_NOW=1  # stop right now if no port

        if [ $SHUTDOW_NOW = "1" ]; then
            [ "x$pid" = "x" ] || kill -9 $pid > /dev/null 2>&1
            sleep 1
            echo "Stopped tomcat$PORT right now by kill"
        else
            echo "dump tomcat threads ... "
            kill -3 $pid && sleep 1
            /bin/su -l $USER -s /bin/bash -c "$DAEMON stop"

            count=0
            echo -n "Stopping tomcat$PORT..."
            until is_stopped || [ $count -gt $kwait ]; do
                echo -n "."
                sleep 1
                count=`expr $count + 1`
            done

            if is_running; then
                echo "timeout...killed"
                pid=$(tomcat_pid)
                [ "x$pid" = "x" ] || kill -9 $pid > /dev/null 2>&1
            else
                echo "tomcat stopped"
            fi
        fi
    else
        echo "Tomcat is not running"
    fi

    return 0
}


case "$1" in
        start)
                do_start
                ;;
        stop)
                do_stop
                ;;
        restart)
                is_running && do_stop
        do_start
                ;;
    status)
        pid=$(tomcat_pid)
        if [ -n "$pid" ]
        then
            echo "Tomcat is running with pid: $pid"
        else
            echo "Tomcat is not running"
        fi
        ;; 
    *)
                echo "Usage: $NAME {start|stop|restart}" >&2
                exit 3
                ;;
esac
```

## ftp下载数据到本地

```shell
#!/bin/bash
# 0 9,12,15,17 * * * /bin/bash /opt/guaduan_ftp/guaduan_ftp.sh > /dev/null 2>&1

# echo $(date +'%Y-%m-%d %H:%M:%S')
monthold=$(date -d "1 month ago" +"%Y%m")
ivrdir="/opt/guaduan_ftp/ivr_data/data"
num=$(ls $ivrdir/*$monthold* | wc -l)

if [ $num -ne 4 ];then
/usr/bin/expect <<!
spawn /usr/bin/ftp xxx.xxx.xxx.xxx
expect {
  "root" {send "ivr\r";exp_continue}
  "Password" { send "ivr10116#\r"}
}
expect "*#"
send "cd /ftpdir/ivr/month\r"
send "pwd\r"
send "lcd /opt/guaduan_ftp/ivr_data/data\r"
send "prompt\r"
send "mget JF_*$monthold.AVL*\r"
set timeout 1800
send "exit\r"
#interact
expect eof
!

else
    echo "文件已存在"
fi;
```

## FTP用户初始化

1. 添加用户

   ```shell
   #!/bin/bash
   # adduser_ftp.sh
   USER="$1"
   MAIL="${2:-${USER}@yottachain.io}"
   PWD=$(mkpasswd -l 20 -s 0)
   IP="xxx.xxx.xxx.xxx"
   PORT="21"
   
   is_name=$(grep -w "${USER}" /etc/passwd | wc -l)
   
   if [ -z "${USER}" ];then
       echo "请输入用户名，sh adduser_ftp.sh user"
       exit 1
   fi
   
   adduser() {
       useradd -d /app/data/ftpuser/data/ -g ftpgroup -s /usr/sbin/nologin ${USER} >/dev/null 2>&1
       if [ $? -eq 0 ];then
          echo "user ${USER} is created successfully!!!"
       else
          echo "user ${USER} is created failly!!!"
          exit 1
       fi
   }
   
   password() {
       echo ${PWD} | passwd ${USER} --stdin  &>/dev/null
       if [ $? -eq 0 ];then
          echo "${USER}'s password is set successfully"
       else
          echo "${USER}'s password is set failly!!!"
       fi
   }
   
   mail() {
       python /app/data/ftpuser/mail.py ${USER} ${PWD} ${PORT} ${IP} ${MAIL}
   }
   
   if [ ${is_name} -eq 0 ];then
       adduser
       password
   else
       echo "用户名${USER}已存在."
       password
   fi
   
   mail
   
   echo "you are setting username : ${USER}"
   echo "you are setting password : ${PWD} for ${USER}"
   
   echo -e "mail : ${MAIL}\nusername : ${USER}\npassword : ${PWD}" > /app/data/ftpuser/user_info/${USER}
   ```

2. 修改用户密码

   ```shell
   #!/bin/bash
   # up_pwd.sh
   fun_check_stat_file(){
       CHECK_STAT_FILE="$1";
       CHECK_INTERVAL="${2:-30}";
   
       if [ ! -f ${CHECK_STAT_FILE} ] ;then
           echo -1;
           return;
       fi;
   
       #FILE_MODIFY_TIME=$(stat ${CHECK_STAT_FILE} |egrep '最近更改|Modify'|awk -F'[： ]' '{print $2}')
       FILE_MODIFY_TIME=$(stat ${CHECK_STAT_FILE} |egrep '最近更改|Modify'|awk -F'[：. ]' '{print $2, $3}')
       #OLG_TIME=$(date -d "${CHECK_INTERVAL} days ago"  "+%Y-%m-%d")
       OLG_TIME=$(date -d "${CHECK_INTERVAL} days ago"  "+%Y-%m-%d %H:%M:%S")
   
       FILE_MODIFY_TIME_S=$(date -d "${FILE_MODIFY_TIME}" +%s)
       OLG_TIME_S=$(date -d "${OLG_TIME}" +%s)
       
       if [ "${FILE_MODIFY_TIME_S}" -le "${OLG_TIME_S}" ];then
           echo 0
       else
           echo 1
       fi;
   
   }
   
   filelist=$(ls /app/data/ftpuser/user_info)
   #filelist="yushuai"
   
   for line in ${filelist}
   do
       scriptpath=`cd $(dirname $0) && pwd`;
       file=${scriptpath}/user_info/${line}
       MAIL=$(cat ${file}|grep "mail"|awk '{print $3}')
       CHECK_STAT_FILE_FLAG=$(fun_check_stat_file ${file} 30)
       if [ ${CHECK_STAT_FILE_FLAG} -eq 0 ]; then
           sh /app/data/ftpuser/adduser_ftp.sh ${line} ${MAIL}
       fi;
   done
   ```

3. 发送邮件脚本

   ```python
   #!/usr/bin/python
   # -*- coding: UTF-8 -*-
   
   import yagmail
   import sys
   
   from_user='xxx@yottachain.io'
   from_pwd='xxxx'
   from_host='smtp.exmail.qq.com'
   from_portt='465'
   
   #接收人列表
   USER = sys.argv[1]
   #to_user = USER + '@yottachain.io'
   to_user = sys.argv[5]
   
   #邮件标题
   m_title = 'FTP服务器用户"' + USER + '"信息初始化详细'
   #title = m_title
   title = u'FTP服务器用户信息初始化详细'
   #邮件正文（接收参数1）
   #contents = sys.argv[2]
   PWD = sys.argv[2]
   PORT = sys.argv[3]
   IP = sys.argv[4]
   contents = ['hello :', 'FTP服务器登录权限已为您开通，账号详细信息如下：',
               '用户名：' + USER , '密码：' + PWD, '端口：' + PORT, 'IP地址：' + IP , '\n',
               '*注：用户名"' + USER + '"权限有效期为30天，超过有效期会更新用户密码；', '\n',
               '请登录' + to_user + '邮箱查收信息！！！',
               'FTP客户端下载地址：http://90xxy.com/FlashFXPv54.03970.zip',
               'FTP客户端下载地址(多平台)：https://www.filezilla.cn/download/client/']
   
   #附件（接收参数2）
   #DATE = sys.argv[2]
   #抄送人列表
   #c_user = 'linyingying@yottachain.io'
   #链接邮箱服务器
   yag = yagmail.SMTP(user=from_user, password=from_pwd, host=from_host, port=from_portt)
   # 发送邮件
   yag.send(to_user, title, contents)
   ```

## 模拟cpu占用100%

```shell
#! /bin/sh 
# filename killcpu.sh
if [ $# -ne 1 ] ; then
  echo "USAGE: $0 <CPUs>|stop"
  exit 1;
fi

stop()
{
while read LINE
  do
    kill -9 $LINE
    echo "kill $LINE sucessfull"
  done < pid.txt
cat /dev/null > pid.txt
}

start()
{
  echo "u want to cpus is: "$1
  for i in `seq $1`
do
  echo -ne " 
i=0; 
while true
do
i=i+1; 
done" | /bin/sh &
  pid_array[$i]=$! ;
done

for i in "${pid_array[@]}"; do
  echo 'pid is: ' $i ';';
  echo $i >> pid.txt
done
}

case $1 in
  stop)
    stop
  ;;
  *)
  start $1
;;
esac
```

运行方式：

```shell
# 启动
$ ./killcpu.sh 1
# 停止
$ killcpu.sh stop
```

## 备份 MySQL 数据库

```shell
#!/bin/bash

DATE=$(date +%Y%m%d)
DAYS=7
BAK_DIR="/opt/backup/mysql"
SHELL_LOGS="/opt/backup/logs/mysql/backup_mysql_${DATE}.log"
PASSWD='1q2w3e4r!@#'

shell_log(){
  LOG_INFO=$1
  echo "$(date +%Y-%m-%d_%H:%M:%S) ${LOG_INFO}" >> ${SHELL_LOGS}
}


mysql_backup(){

  shell_log "cd ${BAK_DIR}"
  cd ${BAK_DIR}
  
  ls -l ${BAK_DIR} >> ${SHELL_LOGS}
  
  shell_log "删除 ${DAYS} 天之前的压缩备份文件"
  find ${BAK_DIR} -type f -name "*.tar.gz" -mtime +${DAYS} >> ${SHELL_LOGS}
  find ${BAK_DIR} -type f -name "*.tar.gz" -mtime +${DAYS} -exec rm -f {} \;
  
  
  shell_log "开始备份 mysql mh_1 数据库"
  mysqldump -uroot -p${PASSWD} --single-transaction --routines mh_1 > "${BAK_DIR}/mh_1_${DATE}.sql"
  shell_log "压缩 mh_1_${DATE}.sql 文件"
  tar -zcvf mh_1_${DATE}.tar.gz mh_1_${DATE}.sql >> ${SHELL_LOGS}
  shell_log "删除 mh_1_${DATE}.sql 文件"
  rm -f mh_1_${DATE}.sql
  shell_log "备份 mysql mh_1 数据库完成"
  sleep 1


  shell_log "开始备份 mysql mh_2 数据库"
  mysqldump -uroot -p${PASSWD} --single-transaction --routines mh_2 > "${BAK_DIR}/mh_2_${DATE}.sql"
  shell_log "压缩 mh_2_${DATE}.sql 文件"
  tar -zcvf mh_2_${DATE}.tar.gz mh_2_${DATE}.sql >> ${SHELL_LOGS}
  shell_log "删除 mh_2_${DATE}.sql 文件"
  rm -f mh_2_${DATE}.sql
  shell_log "备份 mysql mh_2 数据库完成"
  sleep 1


  shell_log "开始备份 mysql mh_3 数据库"
  mysqldump -uroot -p${PASSWD} --single-transaction --routines mh_3 > "${BAK_DIR}/mh_3_${DATE}.sql"
  shell_log "压缩 mh_3_${DATE}.sql 文件"
  tar -zcvf mh_3_${DATE}.tar.gz mh_3_${DATE}.sql >> ${SHELL_LOGS}
  shell_log "删除 mh_3_${DATE}.sql 文件"
  rm -f mh_3_${DATE}.sql
  shell_log "备份 mysql mh_3 数据库完成"
  sleep 1


  shell_log "开始备份 mysql plus 数据库"
  mysqldump -uroot -p${PASSWD} --single-transaction --routines plus > "${BAK_DIR}/plus_${DATE}.sql"
  shell_log "压缩 plus_${DATE}.sql 文件"
  tar -zcvf plus_${DATE}.tar.gz plus_${DATE}.sql >> ${SHELL_LOGS}
  shell_log "删除 plus_${DATE}.sql 文件"
  rm -f plus_${DATE}.sql
  shell_log "备份 mysql plus 数据库完成"
  sleep 1


  shell_log "开始备份 mysql sszg_0 数据库"
  mysqldump -uroot -p${PASSWD} --single-transaction --routines sszg_0 > "${BAK_DIR}/sszg_0_${DATE}.sql"
  shell_log "压缩 sszg_0_${DATE}.sql 文件"
  tar -zcvf sszg_0_${DATE}.tar.gz sszg_0_${DATE}.sql >> ${SHELL_LOGS}
  shell_log "删除 sszg_0_${DATE}.sql 文件"
  rm -f sszg_0_${DATE}.sql
  shell_log "备份 mysql sszg_0 数据库完成"
  sleep 1


  shell_log "完成"

}

mysql_backup
```

## 监听服务

```shell
#!/bin/bash

function check_server () {
  server_name=$1
  server_dir=$2
  server_user=$3
  num=$(pgrep -c "${server_name}")
  if [ "${num}" == 0 ]; then
    time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${time} server ${server_name} down." >> "/opt/scripts/check-server.log"
    sudo -u "${server_user}" "${server_dir}"/init.sh restart
  fi
}

check_server "mwd-api" "/opt/app/mwd-api" "guest"
check_server "market-api" "/opt/app/market-api" "guest"
check_server "gfanx-gateway" "/opt/app/gfanx-gateway" "deploy"
check_server "gfanx-cron" "/opt/app/gfanx-cron" "deploy"
```

## 日志模块编写

```shell
#!/bin/bash

function log() {
  [ -d "${backupDir}/logs" ] || mkdir -p ${backupDir}/logs

  if [[ $# -eq 1 ]];then
    msg=$1
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[32m[INFO]\033[0m ${msg}" >> ${backupDir}/logs/shell.log
  elif [[ $# -eq 2 ]];then
    param=$1
    msg=$2
    if [[ ${param} = "-w" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[34m[WARNING]\033[0m ${msg}" >> ${backupDir}/logs/shell.log
    elif [[ ${param} = "-e" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[31m[ERROR]\033[0m ${msg}" >> ${backupDir}/logs/shell.log
      exit 1
    elif [[ ${param} = "-d" ]];then
      echo "$(date +"%Y-%m-%d %H:%M:%S") [DEBUG] ${msg}" >> ${backupDir}/logs/shell.log
      if [[ ${DEBUG_FLAG} = 1 ]];then
        set -x
      fi
    fi
  fi
}

function main() {
   DEBUG_FLAG=0
   log "this is INFO"
   log -w "this is WARNING"
   log -d "this is DEBUG"
   log -e "this is ERROR"
}

main
```

