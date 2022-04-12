# Celery 简介

什么是任务队列

* 任务队列一般用于线程或计算机之间分配工作的一种机制。

* 任务队列的输入是一个称为任务的工作单元，有专门的职程（Worker）进行不断的监视任务队列，进行执行新的任务工作。

* Celery 通过消息机制进行通信，通常使用中间人（Broker）作为客户端和职程（Worker）调节。启动一个任务，客户端向消息队列发送一条消息，然后中间人（Broker）将消息传递给一个职程（Worker），最后由职程（Worker）进行执行中间人（Broker）分配的任务。

* Celery 可以有多个职程（Worker）和中间人（Broker），用来提高Celery的高可用性以及横向扩展能力。

* Celery 是用 Python 编写的，但协议可以用任何语言实现。除了 Python 语言实现之外，还有Node.js的[node-celery](https://github.com/mher/node-celery)和php的[celery-php](https://github.com/gjedeer/celery-php)。

* 可以通过暴露 HTTP 的方式进行，任务交互以及其它语言的集成开发。

架构图

![](img/584bbf78e1783.png)



Celery 使用场景

* 大量需要使用异步任务的场景
  - 发送电子邮件，发送 IM 消息通知
  - 爬取网页， 数据分析
  - 图像、视频处理
  - 生成报告，深度学习

## 安装插件

```shell
$ pip install Celery
$ pip install django-celery-results  # django-celery-results 库基于 Django ORM 实现了结果存储后端
$ pip install celery-with-redis
# pip install -U "celery[redis,auth,msgpack]"
```



## 修改配置文件

```python
INSTALLED_APPS = [
    ...
    'celery',
    'django_celery_results',
    'django_celery_beat',  # 定时任务配置
]

# URL 的格式为：redis://:password@hostname:port/db_number
CELERY_BROKER_URL = 'redis://:YstarRedis@49.233.26.246:6379/14'  # 任务队列存储
CELERY_RESULT_BACKEND = 'redis://:YstarRedis@49.233.26.246:6379/13'  # 后端数据存储数据库配置
# CELERY_RESULT_BACKEND = 'django-db'  # 默认数据库
CELERY_ACCEPT_CONTENT = ['application/json']
CELERY_RESULT_SERIALIZER = 'json'  # 结果序列化为 json
CELERY_TASK_SERIALIZER = 'json'  # 任务序列化和反序列化使用 json 
CELERY_TIMEZONE = 'Asia/Shanghai'
CELERYD_MAX_TASKS_PER_CHILD = 10  # 每个 worker 最多执行10个任务就会被销毁，可防止内存泄漏
CELERY_TASK_RESULT_EXPIRES = 60 * 60 * 24  # 后端存储任务超过一天，则自动清理数据，单位为秒
CELERYD_LOG_FILE = os.path.join(BASE_DIR, "logs", "celery_work.log")
CELERYBEAT_LOG_FILE = os.path.join(BASE_DIR, "logs", "celery_beat.log")
```



## 数据库迁移

```shell
$ python3.8 manage.py migrate
```



在项目的主应用目录下创建 `celery.py` 文件

```python
from __future__ import absolute_import, unicode_literals
from celery import Celery
import os

# 定义配置文件
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings.base')

# 实例化 celery 对象
# 第一个参数是主应用名
app = Celery('management')

# 设置时区
app.conf.timezone = "Asia/Shanghai"

# 读取配置文件中以 CELERY_ 开头的配置项
app.config_from_object('django.conf:settings', namespace='CELERY')

# 自动发现任务
# 自动从加载的各个 APP 的下面取寻找 tasks.py 的脚步，然后把 tasks.py 脚本里的所有任务都加载到系统里面，然后让系统去运行任务
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
```



在项目的主应用目录 `__init__.py` 文件增加以下内容

```python
from __future__ import absolute_import, unicode_literals

# This will make sure the app is always imported when
# Django starts so that shared_task will use this app.
from .celery import app as celery_app  # 重命名

# __all__ = ('celery_app',)
```



在其他的应用下创建 `tasks.py` 文件来定义任务

```python
from celery.signals import task_success
from celery import shared_task


# 使用 shared_task 装饰器修饰的就属于一个任务，没有添加 shared_task 装饰器的就不算任务
@shared_task
def hello_world(n):
    for i in range(n):
        print("Hello World!")

```

生成数据库表

```shell
$ python manage.py migrate django_celery_results
```



在 `views.py` 视图函数中调用，调用方法：`任务函数名.delay(参数, , ,)`

```python
from tasks import hello_world

def exec_tasks(request):
    hello_world.delay(4)  # 把任务添加到任务队列
    return HttpResponse("celery")
```



启动 celery worker 服务

```shell
# -A 和 --app 等同，celery --app tasks worker --loglevel=INFO
$ DJANGO_SETTINGS_MODULE=settings.local celery -A 主应用名 worker --loglevel=INFO
```

添加 `urls.py` 路由进行测试

```python
urlpatterns = [
    path('task/', views.exec_tasks, name='task'),
]
```



获取异步任务执行结果

异步任务执行完毕后，会自动触发信号：

* before_task_publish：发布任务之前

* after_task_publish：发布任务之后
* task_prerun：运行之前
* task_postrun：运行之后
* task_success：执行成功之后
* task_failure：执行失败之后
* task_revoked：撤销任务



`tasks.py`

```python
from celery.signals import task_success
from celery import shared_task

@shared_task
def sum_even(n):
    result = 0
    for i in range(0, n+1, 2):
        result += i
    return result

# 获取异步任务的结果
@task_success.connect(sender=sum_even)
def complete(sender=None, result=None, **kwargs):
    print(result)
```



## 安装 flower

Flower: 一个实时的 Celery 任务监控系统，实时 Celery 网络监视器，Flower 是一个基于 Web 的实时监控和 Celery 管理工具。

```shell
# 使用 pip 安装 Flower
$ pip install flower 
```

运行 flower 命令将启动您可以访问的网络服务器：

```shell
$ DJANGO_SETTINGS_MODULE=settings.local celery -A proj flower  # proj 为项目名
# 默认端口是 http://localhost:5555，但您可以使用 --port 参数更改它
$ DJANGO_SETTINGS_MODULE=settings.local celery -A proj flower --port=5555
```

Broker URL 也可以通过 `--broker` 参数传递 

```shell
$ DJANGO_SETTINGS_MODULE=settings.local celery flower --broker=amqp://guest:guest@localhost:5672//  # mq 方式
# or
$ DJANGO_SETTINGS_MODULE=settings.local celery -A tasks --broker=redis://guest:guest:YstarRedis@localhost:6379/14 flower --port=5555  # redis 方式
```

然后，您可以在您的网络浏览器中访问 flower

```shell
$ open http://localhost:5555
```



**定时任务**

- 任务心跳管理进程 – Beat
- 任务调度器
  - PersistentScheduler （默认）
  - DatabaseScheduler
- 任务存储
  - File Configuration
  - Database
- 安装 beat：`pip install django-celery-beat`
- 数据库变更
- 使用 DatabaseScheduler 启动 beat 或者在 配置中设置 beat_scheduler
- 管理定时任务的方法
  - 在 Admin 后台添加管理定时任务
  - 系统启动时自动注册定时任务
  - 直接设置应用的 beat_schedule
  - 运行时添加定时任务



安装 django-celery-beat 插件

```shell
$ pip install django-celery-beat
```

配置中注册应用

```python
INSTALLED_APPS = [
    ...
    'django_celery_beat',
]
```

数据库迁移

```shell
$ python3.8 manage.py migrate
```

启动 beta 进程

```shell
$ DJANGO_SETTINGS_MODULE=settings.local celery --app management beat --scheduler django_celery_beat.schedulers:DatabaseScheduler
```



访问后台，可以在站点内看到新增的 PERIODIC TASKS 的栏目

在 PERIODIC TASKS 栏目下 intervals 是用来管理运行的周期，比如每隔10秒运行一个任务，crontabs 是用 crontab 格式来配置定时任务，和 Linux crontab 中格式相同，Periodic tasks 具体的有哪些个任务。



在系统启动的时候添加定时任务

在 项目名/主应用目录/celery.py 文件中添加

```python
from celery.schedules import crontab

# 在系统配置完成之后再去执行下面的方法
@app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    # Calls test('hello') every 10 seconds.
    sender.add_periodic_task(10.0, test.s('hello'), name='hello every 10')

    # Calls test('world') every 30 seconds
    sender.add_periodic_task(30.0, test.s('world'), expires=10)

    # Executes every Monday morning at 7:30 a.m.
    sender.add_periodic_task(
        crontab(hour=7, minute=30, day_of_week=1),
        test.s('Happy Mondays!'),
    )


@app.task
def test(arg):
    print(arg)
```

还有一种方法是在代码中直接配置哪些定时任务的运行

在 management/management/celery.py 文件中添加

```python
# 注意下面引用的 tasks.add 的方法，必须显示 import 才能正确注册
from management.tasks.tasks import add

# 直接配置 app.conf.beat_schedule 属性，下面是加了一个任务，每隔十秒钟执行一次，调用的任务是 management.tasks.add
app.conf.beat_schedule = {
    'add-every-10-seconds': {
        'task': 'management.tasks.add',
        'schedule': 10.0,
        'args': (16, 4, )
    },
}

```

动态的添加定时任务

```python
import json
from django_celery_beat.models import PeriodicTask, IntervalSchedule

# 先创建定时策略
schedule, created = IntervalSchedule.objects.get_or_created(every=10, period=IntervalSchedule.SECONDS, )
# every=10 是周期，每隔十秒执行任务

# 在创建任务
task = PeriodicTask.objects.create(interval=schedule, name='say welcome', task='management.celery.test',
                                   args=json.dumps(['welcome']), )
# name 定时任务名称
# task 是调用的方法
# args 是参数，传json格式的文本
```



长时间运行 Celery 有可能发生内存泄漏，可以像下面这样设置

```python
# 每个 worker 最多执行1000个任务就会被销毁，可防止内存泄漏
CELERYD_MAX_TASKS_PER_CHILD = 1000
```



其他配置说明

```python
# 后端存储任务超过一天，则自动清理数据，单位为秒
CELERY_TASK_RESULT_EXPIRES = 60 * 60 * 24
```

## 其他

在项目的跟目录下创建 delery 文件夹，然后在文件夹下创建 tasks.py 文件

```python
from celery import Celery

# 第一个参数 是当前脚本的名称，第二个参数 是 broker 服务地址
# backend 存储，指把每一个异步任务的结果存储在 backend 中
# broker 存储任务的系统，代理
app = Celery('tasks', backend='redis://:YstarRedis@127.0.0.1:6379/13',
             broker='redis://:YstarRedis@127.0.0.1:6379/14')


@app.task
def add(x, y):
    return x + y
```

运行任务

在 celery 文件夹内添加 run_task.py 脚本

```python
from tasks import add

result = add.delay(4, 4)
print('Is task ready: %s' % result.ready())  # ready 表示任务是否执行完成，执行完成后打印结果

run_result = result.get(timeout=1)
print('task result: %s' % run_result)

```

运行脚本结果

```shell
$ python3.8 run_task.py 
Is task ready: False  # False 表示任务还没有运行完
task result: 8
```



**参考文档**

https://docs.celeryproject.org/en/stable/userguide/monitoring.html

https://docs.celeryproject.org/en/stable/django/first-steps-with-django.html

[Celery 中文手册](https://www.celerycn.io/fu-lu/django)



## Celery 架构

• 3行代码定义一个异步任务 tasks.py

```python
from celery import Celery

# 第一个参数 是当前脚本的名称，第二个参数 是 broker 服务地址
# backend 存储，指把每一个异步任务的结果存储在 backend 中
# broker 存储任务的系统，代理
app = Celery('tasks', backend='redis://:YstarRedis@49.233.26.246:6379/13',
             broker='redis://:YstarRedis@49.233.26.246:6379/14')


@app.task
def add(x, y):
    return x + y

```

 调用异步任务 & 获取执行结果 run_task.py

```python
from tasks import add

result = add.delay(5, 5)
print('Is task ready: %s' % result.ready())  # ready 表示任务是否执行完成，执行完成后打印结果

run_result = result.get(timeout=1)
print('task result: %s' % run_result)

```



Celery 中的核心概念

• Task: 一个需要执行的任务，任务通常异步执行

• Period Task: 需要定时执行的任务，定时一定间隔执行，也可以使用 crontab 表达式设定执

行周期和时间点

• Message Broker: 消息代理，临时存储，传输任务到工作节点的消息队列。可以用 Redis, 

RabbitMQ, Amazon SQS 作为消息代理。消息代理可以有多个，以保障系统的高可用。

• Worker：工作节点，执行任务的进程，worker可以有多个，保障系统的高可用和扩展性。

![](img/image-20210803134921175.png)



Celery 中另外两个

需要用的概念

•Result Store: 结果存储

•Scheduler/Beat： 调度器进程, Beat是定时任务调度器

![](img/image-20210803134947318.png)

Celery 的跨平台 - 不同语言的客户端/服务器端实现

![](img/image-20210803135030556.png)

Celery 的高可用架构

![](img/image-20210803135047834.png)

