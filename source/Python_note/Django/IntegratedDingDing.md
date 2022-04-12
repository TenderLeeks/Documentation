# 集成钉钉

1. 安装钉钉插件

   ```shell
   $ pip install DingtalkChatbot
   ```

2. 添加 `dingtalk.py` 脚本

   ```python
   from dingtalkchatbot.chatbot import DingtalkChatbot
   from django.conf import settings
   
   def send(message, at_mobiles=[]):
       # 引用 settings里面配置的钉钉群消息通知的WebHook地址:
       webhook = settings.DINGTALK_WEB_HOOK
   
       # 初始化机器人, # 方式一：通常初始化方式
       # ding = DingtalkChatbot(webhook)
   
       # 方式二：勾选“加签”选项时使用（v1.5以上新功能）
       ding = DingtalkChatbot(webhook, secret=settings.DINGTALK_AUTH)
   
       # Text消息@所有人
       ding.send_text(msg=('消息通知: %s' % message), at_mobiles=at_mobiles)
   ```

3. 配置文件设置

   ```python
   # 钉钉配置
   DINGTALK_WEB_HOOK = 'https://oapi.dingtalk.com/robot/send?access_token=xxxx'
   DINGTALK_AUTH = 'xxxxx'  # 加签使用
   ```

4. 测试

   ```shell
   python3.8 manage.py shell --settings=settings.local
   >>> from tools import dingtalk
   >>> dingtalk.send("消息通知")
   ```

   在钉钉群中查看是否收到消息。