# 缓存

Django 缓存的存储方式：

- Memcached 缓存
- Redis 缓存 （需要安装 django-redis 包）
- 数据库缓存
- 文件系统缓存
- 本地内存缓存
- 伪缓存( Dummy Cache， 用于开发、测试) 
- 自定义缓存

缓存的策略：

- 整站缓存
- 视图缓存
- 模板片段缓存



[django-redis 中文文档](https://django-redis-chs.readthedocs.io/zh_CN/latest/)



配置文件：

```python
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379/1",
        "TIMEOUT": 300,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "PASSWORD": "123456",
            "SOCKET_CONNECT_TIMEOUT": 5,  # in seconds
            "SOCKET_TIMEOUT": 5,  # r/w timeout in seconds
        }
    }
}

MIDDLEWARE = [
    ...
    'django.middleware.cache.UpdateCacheMiddleware',  # 整站缓存
    'django.middleware.common.CommonMiddleware',
    'django.middleware.cache.FetchFromCacheMiddleware',  # 整站缓存
    ...
]
```


