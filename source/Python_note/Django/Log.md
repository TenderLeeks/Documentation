# 日志记录

四个组件：

* `Loggers`：日志记录的处理类/对象，一个 Logger 可以有多个 Handlers
* `Handlers`：对于每一条日志消息如何处理，记录到文件，控制台，还是网络
* `Fiters`：定义过滤器，用于 Logger/Handler 之上
* `Formmaters`：定义日志文本记录的格式

四个日志级别：

* `DEBUG`：调试
* `INFO`：常用的系统消息
* `WARNING`：小的告警，不影响主要功能
* `ERROR`：系统出现不可忽视的错误
* `CEITICAL`：非常严重的错误



配置文件设置：

```python
import platform
from pathlib import Path

LOG_DIR = "/Users/ken/PycharmProjects/management/"
if platform.system() == "Linux" or platform.system() == "Windows":
    # linux or windows
    Path(LOG_DIR).mkdir(parents=True, exist_ok=True)
elif platform.system() == "Darwin" or platform.system() == "Mac":
    # OS X,
    # you could not create a folder at /data/logs dure to OS default policy
    LOG_DIR = BASE_DIR
    
LOGGING = {
    'version': 1,  # 日志版本是1，Python中一个统一的用法
    'disable_existing_loggers': False,  # 是否禁用已有的其他log
    'formatters': {
        'simple': {  # 确切的格式并不重要，这是最基本的信息
            'format': '%(asctime)s %(name)-12s %(lineno)d %(levelname)-8s %(message)s',  # 时间，类名，行数，级别，信息
        },
    },
    'handlers': {
        'console': {  # console 表示控制台，往控制台输出日志
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },

        'mail_admins': {  # 为 mail_admins 添加处理程序用于 'warning' 或更高级别
            'level': 'ERROR',
            'class': 'django.utils.log.AdminEmailHandler',  # AdminEmailHandler 邮件处理器，把错误的日志发送到邮件
        },
        'file': {  # file: 记录到文件
            # 'level': 'INFO',
            'class': 'logging.FileHandler',
            'formatter': 'simple',
            'filename': os.path.join(LOG_DIR, 'logs/admin.log'),
        },

        'performance': {
            # 'level': 'INFO',
            'class': 'logging.FileHandler',
            'formatter': 'simple',
            'filename': os.path.join(LOG_DIR, 'logs/performance.log'),
        },
    },

    'root': {  # root 是系统全局级别的日志记录器
        'handlers': ['console', 'file'],  # 定义往控制台和文件中同时输出日志
        'level': 'INFO',
    },

    'loggers': {
        "django_python3_ldap": {  # loggers 中 key 是日志定义的名称，对应 INSTALLED_APPS 中字段，如：django_python3_ldap
            "handlers": ["console", "file"],
            "level": "DEBUG",
        },

        "commands.performance": {  # 包名.文件名
            "handlers": ["console", "performance"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

```

在代码中应用：

```python
import logging

logger.info("%s ... %s ..." (xxx, xxx))
```


