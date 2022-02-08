# 搭建Django开发环境

## 创建一个简单的Django项目

```shell
$ pip install Django

# 创建项目 django_test
$ django-admin startproject django_test

# 启动项目
$ python manage.py runserver 0.0.0.0:8080

# 测试访问：http://127.0.0.1:8080

$ python manage.py makemigrations
No changes detected

# 初始化数据库相关表
$ python manage.py migrate

# 测试访问：http://127.0.0.1:8080/admin

# 创建管理员账号
$ python manage.py createsuperuser

# 中文显示需要修改配置文件settings.py
LANGUAGE_CODE = 'zh-hans'

```

## 创建应用

```shell
# 创建名称为jobs的应用
$ python manage.py startapp jobs

# 应用添加到settings.py配置中
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'jobs',
]
```

