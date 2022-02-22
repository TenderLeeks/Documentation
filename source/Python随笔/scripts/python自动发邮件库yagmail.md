# python自动发邮件库yagmail



**一般发邮件方法**

我以前在通过Python实现自动化邮件功能的时候是这样的：

 

```
import smtplib
from email.mime.text import MIMEText
from email.header import Header
# 发送邮箱服务器
smtpserver = 'smtp.sina.com'
# 发送邮箱用户/密码
user = 'username@sina.com'
password = '123456'
# 发送邮箱
sender = 'username@sina.com'
# 接收邮箱
receiver = 'receive@126.com'
# 发送邮件主题
subject = 'Python email test'
# 编写HTML类型的邮件正文
msg = MIMEText('<html><h1>你好！</h1></html>','html','utf-8')
msg['Subject'] = Header(subject, 'utf-8')
# 连接发送邮件
smtp = smtplib.SMTP()
smtp.connect(smtpserver)
smtp.login(user, password)
smtp.sendmail(sender, receiver, msg.as_string())
smtp.quit()
```

其实，这段代码也并不复杂，只要你理解使用过邮箱发送邮件，那么以下问题是你必须要考虑的：

​    你登录的邮箱帐号/密码

​    对方的邮箱帐号

​    邮件内容（标题，正文，附件）

​    邮箱服务器（SMTP.xxx.com/pop3.xxx.com）

## yagmail 实现发邮件

yagmail 可以更简单的来实现自动发邮件功能。

github项目地址: https://github.com/kootenpv/yagmail

### 安装

 

```
pip install yagmail
```

### 简单例子

 

```
import yagmail
#链接邮箱服务器
#yag = yagmail.SMTP( user="user@126.com", password="1234", host='smtp.126.com')
yag=yagmail.SMTP(user='xxx.xxxx@csdn.com',password='11111',host='smtp.exmail.qq.com',port=465)
# '''
# 第一个参数 发件人邮箱地址
# 第二个参数 密码
# 第三个参数 发送邮箱的服务器
# 第四个参数 发送邮箱的端口
# '''
# 邮件正文
contents = ['This is the body, and here is just text http://somedomain/image.png',
            'You can find an audio file attached.', '/local/path/song.mp3']
title=''#标题
#title=u'邮件标题'
yag.send('xxxx.xxx@csdn.com',title,content,'附件目录',['抄送人1','抄送人2'])
# '''
# 第一个参数 收件人邮箱地址 如果收件人多 可以采用列表
# 第二个参数 标题
# 第三个参数 正文
# 第四个参数 发送的附件 如果附件多 可以采用列表
# 第五个参数 抄送人 如果抄送人多 可以采用列表
# '''
# 发送邮件
yag.send('taaa@126.com', 'subject', contents)
```

**注：**

  邮件发送成功时标题会出现乱码，yagmail支持uncode编码

  将标题更正为 title=u''，这样就解决乱码的问题了

### 给多个用户发送邮件

 

```
# 发送邮件
yag.send(['aa@126.com','bb@qq.com','cc@gmail.com'], 'subject', contents)
```

只需要将接收邮箱 变成一个list即可。

### 发送带附件的邮件

 

```
# 发送邮件
yag.send('aaaa@126.com', '发送附件', contents, ["d://log.txt","d://baidu_img.jpg"])
```

只需要添加要发送的附件列表即可。

 

```
#!/usr/bin/python
# -*- coding: UTF-8 -*-
import yagmail
import sys
from_user='xxxxxx@co-gro.com'
from_pwd='Q1w2e3'
from_host='smtp.exmail.qq.com'
from_portt='465'
#接收人列表
to_user = 'aaaa@co-gro.com'
#邮件标题
title = u'MySQL慢查询统计信息'
#邮件正文（接收参数1）
contents = sys.argv[1]
#附件（接收参数2）
DATE = sys.argv[2]
sql_select = '/root/mysql_slowLog_file/select/sql_select_' + DATE + '.txt'
report_name = '/root/mysql_slowLog_file/html/mysql_slow_' + DATE + '.html'
file = [sql_select, report_name]
#抄送人列表
c_user = 'bbbbb@co-gro.com'
#链接邮箱服务器
yag = yagmail.SMTP(user=from_user, password=from_pwd, host=from_host, port=from_portt)
# 发送邮件
yag.send(to_user, title, contents, file, c_user)
```