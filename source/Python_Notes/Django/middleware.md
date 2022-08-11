# 中间件

默认中间件

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',  # 安全中间件
    'django.contrib.sessions.middleware.SessionMiddleware',  # session 中间件，处理用户登录信息
    'django.middleware.common.CommonMiddleware',  # 常用信息
    'django.middleware.csrf.CsrfViewMiddleware',  # 处理 CSRF 跨站攻击
    'django.contrib.auth.middleware.AuthenticationMiddleware',  # 处理用户认证登录
    'django.contrib.messages.middleware.MessageMiddleware',  # 处理消息
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

创建请求日志，性能日志记录中间件

* 定义实现中间件函数：`def performance_logger_middleware(get_response) `
* 记录请求URL，参数，响应时间
* 注册 middleware 到 settings 中
* 配置日志文件路径



```python
import time
import logging

logger = logging.getLogger(__name__)


def performance_logger_middleware(get_response):
    def middleware(request):
        start_time = time.time()
        response = get_response(request)
        duration = time.time() - start_time
        response["X-Page-Duration-ms"] = int(duration * 1000)
        logger.info("%s %s %s", duration, request.path, request.GET.dict())
        return response

    return middleware

```

把定义的中间件加到 `settings MIDDLEWARE` 配置中

```python
# 中间件的执行顺序是从上到下依次执行
MIDDLEWARE = [
    'commands.performance.performance_logger_middleware',  # 包名.文件名.函数名或类名
    'django.middleware.security.SecurityMiddleware',  # 安全中间件
    'django.contrib.sessions.middleware.SessionMiddleware',  # session 中间件，处理用户登录信息
    'django.middleware.common.CommonMiddleware',  # 常用信息
    'django.middleware.csrf.CsrfViewMiddleware',  # 处理 CSRF 跨站攻击
    'django.contrib.auth.middleware.AuthenticationMiddleware',  # 处理用户认证登录
    'django.contrib.messages.middleware.MessageMiddleware',  # 处理消息
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

在日志配置中加入

```python
        'performance': {  # 性能日志记录信息
            # 'level': 'INFO',
            'class': 'logging.FileHandler',
            'formatter': 'simple',
            'filename': os.path.join(LOG_DIR, 'logs/performance.log'),
        },
```
