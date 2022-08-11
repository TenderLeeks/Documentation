# Archery SQL 审核查询平台

详细信息请查看[官方文档](https://archerydms.com/)

## 修改配置文件

在 [Releases](https://github.com/hhyo/Archery/releases)查看版本并下载，本次安装以版本`v1.8.5`为参考。

```shell
$ wget https://github.com/hhyo/Archery/archive/refs/tags/v1.8.5.tar.gz -P /tmp
$ tar -zxf /tmp/v1.8.5.tar.gz -C /opt
$ cd /opt/Archery-1.8.5/src/docker-compose/
```

删除`docker-compose.yml`中`MySQL`和`Redis`配置，使用自建的数据库服务。

```shell
# 删除配置archery中entrypoint配置项
$ cat docker-compose.yml
version: '3'

services:
  goinception:
    image: hanchuanchuan/goinception
    container_name: goinception
    restart: always
    ports:
      - "4000:4000"
    volumes:
      - "./inception/config.toml:/etc/config.toml"

  archery:
    image: hhyo/archery:v1.8.5
    container_name: archery
    restart: always
    ports:
      - "9123:9123"
    volumes:
      - "./archery/settings.py:/opt/archery/archery/settings.py"
      - "./archery/soar.yaml:/etc/soar.yaml"
      - "./archery/docs.md:/opt/archery/docs/docs.md"
      - "./archery/downloads:/opt/archery/downloads"
      - "./archery/sql/migrations:/opt/archery/sql/migrations"
      - "./archery/logs:/opt/archery/logs"
      - "./archery/keys:/opt/archery/keys"
    environment:
      NGINX_PORT: 9123
```

修改`inception/config.toml `数据库连接信息

```shell
backup_host = "192.168.67.250"
backup_port = 3306
backup_user = "root"
backup_password = "123456"
```

修改`archery/settings.py`配置信息，请参考此[文档](https://archerydms.com/installation/manual/#_5)修改内容。

```python
# 修改 SECRET_KEY 信息
# 修改 MySQL 配置
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'archery',
        'USER': 'root',
        'PASSWORD': '123456',
        'HOST': '192.168.67.250',
        'PORT': '3306',
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
            'charset': 'utf8mb4'
        },
        'TEST': {
            'NAME': 'test_archery',
            'CHARSET': 'utf8mb4',
        },
    }
}

# 修改缓存配置
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://192.168.67.250:6379/0",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "PASSWORD": "123456"
        }
    },
    "dingding": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://192.168.67.250:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "PASSWORD": "123456"
        }
    }
}
```

## 启动服务

```shell
$ docker-compose -f docker-compose.yml up -d

# 表结构初始化
$ docker exec -ti archery /bin/bash
$ cd /opt/archery
$ source /opt/venv4archery/bin/activate
$ python3 manage.py makemigrations sql
$ python3 manage.py migrate

# 数据初始化
$ python3 manage.py dbshell<sql/fixtures/auth_group.sql
$ python3 manage.py dbshell<src/init_sql/mysql_slow_query_review.sql

# 创建管理用户
$ python3 manage.py createsuperuser
$ exit
# 重启
$ docker restart archery

# 日志查看和问题排查
$ docker logs archery -f --tail=50
```

## 修改系统配置项

请参照[文档](https://archerydms.com/configuration/)修改系统配置

