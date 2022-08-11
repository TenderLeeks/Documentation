# 处理json格式和转义UTC时间

```python
#!/usr/bin/env python
# -*- coding=utf-8
import os, re 
import json
import jsonpath
import datetime
import time

# 使UTC时间转换为本地时间
def utc2local(utc_st):
    now_stamp = time.time()
    local_time = datetime.datetime.fromtimestamp(now_stamp)
    utc_time = datetime.datetime.utcfromtimestamp(now_stamp)
    offset = local_time - utc_time
    local_st = utc_st + offset
    return local_st

# 处理json内容
def unicode_convert(input):
    if isinstance(input, dict):
        return {unicode_convert(key): unicode_convert(value) for key, value in input.iteritems()}
    elif isinstance(input, list):
        return [unicode_convert(element) for element in input]
    elif isinstance(input, unicode):
        return input.encode('utf-8')
    else:
        return input

if __name__ == '__main__':
    URL = "https://wallet.yottachain.net"
    INITIAL_VALUE = "0"
    bithumbyta15_full = 'cleos -u ' + URL + ' get actions bithumbyta15 ' + INITIAL_VALUE + ' 0 -j'
    #print bithumbyta15_full
    result = os.popen(bithumbyta15_full)
    res = result.read()
    json_loads = unicode_convert(json.loads(res))
    
    json_account_action_seq  = jsonpath.jsonpath(json_loads,"actions[0].account_action_seq")
    json_block_time = jsonpath.jsonpath(json_loads,"actions[0].block_time")
    json_receiver = jsonpath.jsonpath(json_loads,"actions.[]action_trace.receipt.receiver")
    json_account = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.account")
    json_name = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.name")
    json_from = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.from")
    json_to = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.to")
    json_quantity = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.quantity")
    json_memo = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.memo")
    
    UTC_FORMAT = "%Y-%m-%dT%H:%M:%S.%f"
    utc_time = datetime.datetime.strptime(json_block_time[0], UTC_FORMAT)
    local_time = utc2local(utc_time)
    
    print local_time.strftime("%Y-%m-%d,%H:%M:%S")
    
    print json_account_action_seq[0]
    print json_block_time[0]
    print json_receiver[0]
    print json_account[0]
    print json_name[0]
    print json_from[0]
    print json_to[0]
    print json_quantity[0]
    print json_memo[0]

```

# 使用 Flask 实现一个 api 接口

```python
import flask
import json
from flask import request

key = 'KdXptuiSpUptok7H'

# 创建一个服务，把当前这个python文件当做一个服务
server = flask.Flask(__name__)


@server.route('/jkfHk5', methods=['get', 'post'])
def info():
    token = request.values.get('token')
    if token == key:
        result = {"data": {}, "code": 200, "msg": "success"}
        return json.dumps(result, ensure_ascii=False)
    else:
        res = {"data": {}, 'code': 10001, 'message': 'invalid parameter'}
        return json.dumps(res, ensure_ascii=False)


if __name__ == '__main__':
    # 指定端口、host,0.0.0.0代表不管几个网卡，任何ip都可以访问
    # 在浏览器访问 http://127.0.0.1:56478/jkfHk5?token=KdXptuiSpUptok7H 进行测试
    server.run(debug=True, port=56478, host='127.0.0.1')

```

# python发邮件库 yagmail

**一般发邮件方法**

我以前在通过Python实现自动化邮件功能的时候是这样的：

```python
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

安装

```shell
$ pip install yagmail
```

简单例子

```python
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

给多个用户发送邮件

```shell
# 发送邮件
$ yag.send(['aa@126.com','bb@qq.com','cc@gmail.com'], 'subject', contents)
```

只需要将接收邮箱 变成一个list即可。

发送带附件的邮件

```shell
# 发送邮件
$ yag.send('aaaa@126.com', '发送附件', contents, ["d://log.txt","d://baidu_img.jpg"])
```

只需要添加要发送的附件列表即可。

```python
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



# 启用多线程监控账号地址转账动作

```python
import os
import threading
import json
import requests
import time
import hmac
import hashlib
import base64
import urllib
import datetime
from urllib import parse


class myThread(threading.Thread):
    """开启多线程工作模式"""
    def __init__(self, url, account, seq):
        threading.Thread.__init__(self)
        self.url = url
        self.account = account
        self.seq = seq

    def run(self):
        # print("开启线程： " + self.account)
        sort_data(self.url, self.account, self.seq)


def action_info(url, account, seq):
    """账号动作信息"""
    cmd = "cleos -u %s get actions %s %s 0 -j" % (url, account, seq)
    run_cmd = os.popen(cmd)
    read_cmd = run_cmd.read()
    info_dict = json.loads(read_cmd)
    data_list = info_dict['actions']

    res_list = []
    if data_list:
        for line in data_list:
            act_name = line['action_trace']['act']['name']  # 等于yrctransfer或者transfer为转账操作
            receipt_receiver = line['action_trace']['receipt']['receiver']  # 等于account

            if receipt_receiver == account and (act_name == "yrctransfer" or act_name == "transfer"):
                account_action_seq = line['account_action_seq']  # 交易序号
                block_time = line['block_time']  # 交易时间
                local_time = utc2local(block_time, "%Y-%m-%dT%H:%M:%S.%f")
                from_account = line['action_trace']['act']['data']['from']  # 转出账号
                to_account = line['action_trace']['act']['data']['to']  # 转入账号
                quantity = line['action_trace']['act']['data']['quantity']  # 转出数量
                memo = line['action_trace']['act']['data']['memo']  # 备注信息

                res_list = [account_action_seq, local_time, from_account, to_account, quantity, memo]
    else:
        time.sleep(60)

    return res_list


def last_seq(url, account):
    """获取账号地址最后的信息"""
    cmd = "cleos -u %s get actions %s -1 -1 -j" % (url, account)
    run_cmd = os.popen(cmd)
    read_cmd = run_cmd.read()
    info_dict = json.loads(read_cmd)
    data_list = info_dict['actions']

    seq = None
    if data_list:
        for line in data_list:
            seq = line['account_action_seq']  # 交易序号

    return seq


def sort_data(url, account, seq):
    """使用无限循环实时检查账号动作"""
    while True:
        lastSeq = last_seq(url, account)
        if lastSeq is None:
            continue
        if seq <= lastSeq:
            data_list = action_info(url, account, seq)
            if data_list:
                print(data_list)
                dingding(data_list)
                phone_sms_alert(account, data_list)
        else:
            continue
        seq += 1


def send_msg(url, data):
    headers = {'Content-Type': 'application/json;charset=utf-8'}
    r = requests.post(url, data=json.dumps(data), headers=headers)
    return r.text


def utc2local(utc_st, utc_format):
    """UTC时间转换成本地时间，格式化时间 utc2local(line, "%Y-%m-%dT%H:%M:%S.%f")"""
    utc_times = datetime.datetime.strptime(utc_st, utc_format)
    now_stamp = time.time()
    local_time = datetime.datetime.fromtimestamp(now_stamp)
    utc_time = datetime.datetime.utcfromtimestamp(now_stamp)
    offset = local_time - utc_time
    local_st = utc_times + offset
    local_block_time = local_st.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    return local_block_time


def auth(secret):
    timestamp = round(time.time() * 1000)
    secret = secret  # 秘钥
    secret_enc = bytes(secret.encode('utf-8'))
    string_to_sign = '{}\n{}'.format(timestamp, secret)  # 把 timestamp+"\n"+密钥 当做签名字符串 string_to_sign
    string_to_sign_enc = bytes(string_to_sign.encode('utf-8'))
    hmac_code = hmac.new(secret_enc, string_to_sign_enc,
                         digestmod=hashlib.sha256).digest()  # 使用HmacSHA256算法计算签名，得到 hmac_code
    hmac_code_base64 = base64.b64encode(hmac_code)  # 将hmac_code进行Base64 encode
    sign = urllib.parse.quote(hmac_code_base64)  # 进行urlEncode，得到最终的签名sign
    auth_list = [timestamp, sign]
    return auth_list


def dingding(data_list):
    """集成钉钉消息通知"""
    dd_url = "https://oapi.dingtalk.com/robot/send"
    dd_auth = "********"
    dd_access_token = "*********"

    content = "时间:%s\n转出账号:%s\n转入账号:%s\n数量:%s\nmemo:%s" % (
        data_list[1], data_list[2], data_list[3], data_list[4], data_list[5])

    data = {
        "msgtype": "text",
        "text": {
            "content": content
        },
        "at": {
            "atMobiles": [
                "186********"
            ],
            "isAtAll": "true"
        }
    }

    auth_list = auth(dd_auth)
    url = "%s?access_token=%s&timestamp=%s&sign=%s" % (dd_url, dd_access_token, str(auth_list[0]), auth_list[1])
    print(send_msg(url, data))


def phone_sms_alert(account, data_list):
    """增加电话,短信告警方式"""
    url = "http://api.aiops.com/alert/api/event"
    body = '''{"app": "******-6b73-411c-a709-******",
         "eventId": "888888",
         "eventType": "trigger",
         "alarmName": "账号地址%s发生动作信息",
         "priority": 3,
         "alarmContent": {"发生时间":"%s","转出账号":"%s","转入账号":"%s","数量":"%s","memo":"%s"},
         }''' % (account, data_list[1], data_list[2], data_list[3], data_list[4], data_list[5])

    headers = {'Content-Type': "application/json"}
    response = requests.post(url, data=body.encode(), headers=headers)
    print(response.text)


def main():
    """main"""
    account_info_list = [['ssssssyyyyyy', 406], ['1.bg', 15]]
    url = 'https://history.xxxx.com'  # eos 类型链查询历史的地址

    for account_list in account_info_list:
        account = account_list[0]
        seq = account_list[1]
        thread = myThread(url, account, seq)  # 创建新线程
        thread.start()  # 开启新线程


if __name__ == '__main__':
    main()

```

# 两数运算

```python
from decimal import Decimal, getcontext

# 两数和
def num_sum(num_list):
    getcontext().prec = 4  # 设置精度,用于浮点数计算
    sum = 0
    for num in num_list:
        sum = Decimal(str(sum)) + Decimal(str(num))
    return sum

# 两数差
def num_difference(num1, num2):
    # getcontext().prec = 4  # 设置精度,用于浮点数计算
    sum_result = Decimal(str(num1)) - Decimal(str(num2))
    return sum_result

# 两数商
def num_quotient(num1, num2):
    getcontext().prec = 4  # 设置精度,用于浮点数计算
    quotient_result = Decimal(str(num1)) / Decimal(str(num2))
    return quotient_result

# 两数乘积
def num_product(num1, num2):
    # getcontext().prec = 4  # 设置精度,用于浮点数计算
    # product_result = Decimal(str(num1)) * Decimal(str(num2))
    product_result = num1 * num2
    return product_result

# 百分率
def num_rate(num1, num2):
    getcontext().prec = 4  # 设置精度,用于浮点数计算
    quotient_result = Decimal(str(num1)) / Decimal(str(num2)) * Decimal('100')
    res = f'{quotient_result}%'
    return res
```

# 日期

```python
import datetime

# 根据间隔获取历史日期
def interval_date(interval):
    today = datetime.date.today()
    one_day = datetime.timedelta(days=1)
    interval_day = today - one_day * interval
    return interval_day

# 计算两个日期相差的天数
def difference_days(day1, day2):
    date1 = datetime.datetime.strptime(day1[0:10], "%Y-%m-%d")
    date2 = datetime.datetime.strptime(day2[0:10], "%Y-%m-%d")
    num = (date1 - date2).days
    return num

# 获取current_date日期后days天日期
def rear_date(current_date, days):
    one_day = datetime.timedelta(days=1)
    interval_day = current_date + one_day * days
    return interval_day

# 获取current_date日期前days天日期
def before_date(current_date, days):
    one_day = datetime.timedelta(days=1)
    interval_day = current_date - one_day * days
    return interval_day
```

# xlsx表格操作

```python
import openpyxl
import os

# 添加新的sheet页和列名称
def add_column(path, sheet_name, column_name):
    if not os.path.exists(path):
        write_excel_xlsx(path, sheet_name, column_name)
    else:
        workbook = openpyxl.load_workbook(path)
        if sheet_name not in workbook.sheetnames:
            workbook.create_sheet(sheet_name)
            sheet = workbook[sheet_name]
            rows = 0
            for i in range(1, len(column_name) + 1):
                for j in range(1, len(column_name[i - 1]) + 1):
                    sheet.cell(rows + i, j).value = column_name[i - 1][j - 1]
            workbook.save(path)


def write_excel_xlsx(path, sheet_name, value):
    index = len(value)
    workbook = openpyxl.Workbook()
    sheet = workbook.active
    # sheet = workbook[sheet_name]
    sheet.title = sheet_name
    for i in range(0, index):
        for j in range(0, len(value[i])):
            sheet.cell(row=i + 1, column=j + 1, value=str(value[i][j]))
    workbook.save(path)

# 读取最后一行的内容
def read_excel_xlsx(path, sheet_name):
    workbook = openpyxl.load_workbook(path)
    sheet = workbook[sheet_name]
    rows = sheet.max_row  # 获得行数
    return sheet.cell(row=rows, column=1).value

# 追加数据
def append_excel_xlsx(path, sheet_name, value):
    workbook = openpyxl.load_workbook(path)
    # last_content = str(read_excel_xlsx(path, sheet_name)).split()[0]
    # if last_content != str(value[0][0]):
    sheet = workbook[sheet_name]
    rows = sheet.max_row  # 获得行数
    for i in range(1, len(value) + 1):  # 注意行业列下标是从1开始的
        for j in range(1, len(value[i - 1]) + 1):
            sheet.cell(rows + i, j).value = value[i - 1][j - 1]
    workbook.save(path)


if __name__ == '__main__':
    book_name_xlsx = 'xlsx格式测试工作簿.xlsx'
    sheet_name_xlsx = 'xlsx格式测试表'
    column_name = [["姓名", "性别", "年龄", "城市", "职业"]]
    value3 = [["1112", "女", "66", "石家庄", "运维工程师"],
              ["2223", "男", "55", "南京", "饭店老板"],
              ["3334", "女", "27", "苏州", "保安"], ]
    add_column(book_name_xlsx, sheet_name_xlsx, column_name)
    append_excel_xlsx(book_name_xlsx, sheet_name_xlsx, value3)
```

# 检查GitHub代码库版本更新

```yaml
dingding:
  url: "https://oapi.dingtalk.com/robot/send"
  access_token: "*********"
  auth: "*********"
  headers:
    Content-Type: 'application/json;charset=utf-8'
chain:
  BinanceSmartChain:
    tags_url: 'https://api.github.com/repos/binance-chain/bsc/tags'
    id: 83
    local_url:
      bj-prod-chain-eth-btc-01b: 'http://***.***.***.***:8645'
      bj-prod-chain-01a: 'http://***.***.***.***:8645'
    header:
      User-Agent: 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'
    headers:
      Content-Type: 'application/json;charset=utf-8'

  Ethereum:
    tags_url: 'https://api.github.com/repos/ethereum/go-ethereum/tags'
    id: 67
    local_url:
      bj-prod-chain-eth-btc-01b: 'http://***.***.***.***:6666'
      bj-prod-chain-01a: 'http://***.***.***.***:6666'
    header:
      User-Agent: 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'
    headers:
      Content-Type: 'application/json;charset=utf-8'

  HuobiECOChain:
    tags_url: 'https://api.github.com/repos/HuobiGroup/huobi-eco-chain/tags'
    id: 83
    local_url:
      bj-prod-chain-eth-btc-01b: 'http://***.***.***.***:8545'
      bj-prod-chain-01a: 'http://***.***.***.***:8545'
    header:
      User-Agent: 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'
    headers:
      Content-Type: 'application/json;charset=utf-8'
```

```python
"""
检查节点版本是否有更新
"""

import requests
import json
import yaml
import os
import hmac
import time
import urllib
import base64
import hashlib

def load_config():
    path = os.path.dirname(os.path.abspath(__file__))
    yaml_file = os.path.join(path, "CheckGitHubVersion.yaml")
    file = open(yaml_file, 'r', encoding='utf-8')
    data = yaml.load(file.read(), Loader=yaml.Loader)
    file.close()
    return data

def init_service_port_conf():
    config = load_config()
    return config

def auth():
    timestamp = round(time.time() * 1000)
    secret_enc = bytes(ding_conf['auth'].encode('utf-8'))
    string_to_sign = '{}\n{}'.format(timestamp, ding_conf['auth'])  # 把 timestamp+"\n"+密钥 当做签名字符串 string_to_sign
    string_to_sign_enc = bytes(string_to_sign.encode('utf-8'))
    hmac_code = hmac.new(secret_enc, string_to_sign_enc,
                         digestmod=hashlib.sha256).digest()  # 使用HmacSHA256算法计算签名，得到 hmac_code
    hmac_code_base64 = base64.b64encode(hmac_code)  # 将hmac_code进行Base64 encode
    sign = urllib.parse.quote(hmac_code_base64)  # 进行urlEncode，得到最终的签名sign
    auth_list = [timestamp, sign]
    return auth_list

def send_msg(url, message):
    r = requests.post(url, data=json.dumps(message), headers=ding_conf['headers'])
    return r.text

def msg(hostname, node_name, _latest, _local):
    t = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
    content = f'警告时间: {t}\n主机信息:{hostname}\n节点名称: {node_name}\nGitHub最新版本: {_latest}\n本地节点版本: {_local}'
    data_info = {
        "msgtype": "text",
        "text": {
            "content": content
        },
        "at": {
            "atMobiles": [],
            "isAtAll": "False"
        }
    }
    auth_list = auth()
    url = f"{ding_conf['url']}?access_token={ding_conf['access_token']}&timestamp={str(auth_list[0])}&sign={str(auth_list[1])}"
    send_msg(url, data_info)

def latest_version(config_info):
    all_info = requests.get(config_info['tags_url']).json()
    return all_info[0]['name']

def local_version(config_info, url):
    params = {"jsonrpc": 2.0, "method": "web3_clientVersion", "params": [], "id": config_info['id']}
    data_str = requests.post(url, data=json.dumps(params), headers=config_info['headers']).text
    data_dict = json.loads(data_str)
    result = data_dict['result']
    version = result.split('/')[1].split('-')[0]
    return version


if __name__ == '__main__':
    conf = init_service_port_conf()
    ding_conf = conf['dingding']
    for k, v in conf['chain'].items():
        latest = latest_version(v)
        for local_name, local_url in v['local_url'].items():
            local = local_version(v, local_url)
            if latest != local:
                msg(local_name, k, latest, local)
```

# 监控区块链账号余额信息

```python
"""
    监控heco地址余额信息
"""

import hashlib
import base64
import hmac
import requests
import json
import time

fs_conf = {
    "url": "https://open.feishu.cn/open-apis/bot/v2/hook/72be0a78-******-456e-b994-******",
    "secret": "******",
    "headers": {'Content-Type': 'application/json;charset=utf-8'}
}

heco_chain_conf = {
    "testnet_heco": {
        "url": "https://http-testnet.hecochain.com",
        "account": "******",
        "warn": [1, 2],
        "severe": [0.5, 1],
        "disaster": [0, 0.5]
    },
    "mainnet_heco": {
        "url": "https://http-mainnet.hecochain.com",
        "account": "******",
        "warn": [5, 10],
        "severe": [1, 5],
        "disaster": [0, 1]
    }
}


def gen_sign(timestamp):
    # 拼接timestamp和secret
    string_to_sign = f'{timestamp}\n{fs_conf["secret"]}'
    hmac_code = hmac.new(string_to_sign.encode("utf-8"), digestmod=hashlib.sha256).digest()
    # 对结果进行base64处理
    sign = base64.b64encode(hmac_code).decode('utf-8')
    return sign


def msg(timestamp, sign, warn_type, chain_type, warn_level, warn_info, other_info):
    t = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
    content = f'警告时间: {t}\n警告类型: {warn_type}\n公链类型: {chain_type}\n警告级别: ' \
              f'{warn_level}\n警告信息: {warn_info}\n其他信息: {other_info}'

    message_content = {
        "timestamp": timestamp,
        "sign": sign,
        "msg_type": "text",
        "content": {
            "text": content
        }
    }
    response = requests.request("POST", fs_conf["url"], headers=fs_conf["headers"], data=json.dumps(message_content))
    return response.text


def heco_balance_info(timestamp, sign):
    for key, value in heco_chain_conf.items():
        try:
            params = {"jsonrpc": 2.0, "method": "eth_getBalance", "params": [value["account"], "latest"], "id": 1}
            data_str = requests.post(value['url'], data=json.dumps(params), headers=fs_conf["headers"]).text
            result = json.loads(data_str)['result']
            balance_base16 = result[2:]  # 十六进制
            balance_base10 = int(balance_base16, 16)  # 转换为十进制
            balance = round(balance_base10 / 1000000000000000000, 4)  # 1 HT = 1000000000000000000

            warn_type = f'{value["account"]} 账号余额信息'
            chain_type = key

            if value["warn"][0] <= balance < value["warn"][1]:

                warn_level = "警告"
                warn_info = f'账号余额: {balance} 已不足 {value["warn"][1]}'
                other_info = f'阈值范围: [{value["warn"][0]}, {value["warn"][1]}]'
                msg(timestamp, sign, warn_type, chain_type, warn_level, warn_info, other_info)
            elif value["severe"][0] <= balance < value["severe"][1]:
                warn_level = "严重"
                warn_info = f'账号余额: {balance} 已不足 {value["severe"][1]}'
                other_info = f'阈值范围: [{value["severe"][0]}, {value["severe"][1]}]'
                msg(timestamp, sign, warn_type, chain_type, warn_level, warn_info, other_info)
            elif value["disaster"][0] <= balance < value["disaster"][1]:
                warn_level = "灾难"
                warn_info = f'账号余额: {balance} 已不足 {value["disaster"][1]}'
                other_info = f'阈值范围: [{value["disaster"][0]}, {value["disaster"][1]}]'
                msg(timestamp, sign, warn_type, chain_type, warn_level, warn_info, other_info)
            else:
                pass
        except Exception as e:
            print(e)
            continue


def main():
    timestamp = str(round(time.time()))
    sign = gen_sign(timestamp)
    heco_balance_info(timestamp, sign)


if __name__ == '__main__':
    main()
```

# 监控错误日志

```python
import subprocess
import os
import hashlib
import base64
import hmac
import requests
import json
import time
import datetime

fs_conf = {
    "url": "https://open.feishu.cn/open-apis/bot/v2/hook/b33b73c7-******-48ac-a805-******",
    "secret": "******",
    "headers": {'Content-Type': 'application/json;charset=utf-8'}
}


def gen_sign(timestamp):
    # 拼接timestamp和secret
    string_to_sign = f'{timestamp}\n{fs_conf["secret"]}'
    hmac_code = hmac.new(string_to_sign.encode("utf-8"), digestmod=hashlib.sha256).digest()
    # 对结果进行base64处理
    sign = base64.b64encode(hmac_code).decode('utf-8')
    return sign


def msg(timestamp, sign, error_log, front_log, later_log):
    content = f'错误日志内容: \n{error_log}\n\n前10行内容:\n{front_log}\n后10行内容: \n{later_log}'

    message_content = {
        "timestamp": timestamp,
        "sign": sign,
        "msg_type": "text",
        "content": {
            "text": content
        }
    }
    response = requests.request("POST", fs_conf["url"], headers=fs_conf["headers"], data=json.dumps(message_content))
    return response.text


def error_log_info(timestamp, sign):
    error_log_file = '/opt/app/gfanx-cron/log/error.log'
    nohup_log_file = '/opt/app/gfanx-cron/nohup_logs/nohup.out'

    error_log_time = (datetime.datetime.now() - datetime.timedelta(minutes=1)).strftime("%Y-%m-%d %H:%M")
    error_log = subprocess.Popen(f'grep "{error_log_time}" {error_log_file}', shell=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, encoding="utf-8")

    output, error = error_log.communicate()

    if len(output.split(os.linesep)) > 1:
        for line in output.split(os.linesep):
            try:
                line_list = line.split(' ')

                nohup_log_front = subprocess.Popen(
                    f'tail -n 10000 {nohup_log_file} | grep -B 10 "{line_list[0]} {line_list[1]} \[{line_list[2].strip("[]")}\] \[{line_list[3].strip("[]")}\]"',
                    shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")

                nohup_log_later = subprocess.Popen(
                    f'tail -n 10000 {nohup_log_file} | grep -A 10 "{line_list[0]} {line_list[1]} \[{line_list[2].strip("[]")}\] \[{line_list[3].strip("[]")}\]"',
                    shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")

                msg(timestamp, sign, line, nohup_log_front.communicate()[0], nohup_log_later.communicate()[0])

            except Exception:
                pass


def main():
    timestamp = str(round(time.time()))
    sign = gen_sign(timestamp)
    error_log_info(timestamp, sign)


if __name__ == '__main__':
    main()
```

