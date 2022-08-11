# 生成环境部署

## 发布到生产环境的步骤

* 配置生产环境配置 (settings)：DEBUG & Secret 相关信息

* 选择Django App的托管环境 (IaaS/PaaS，比如 阿里云/AWS/Azure/GAE/Heroku 等等) 

* 部署前的安全检查

* 选择静态资源文件的托管环境（包括JS/CSS/图片/文件等） & 部署静态资源

* 部署 Django 应用容器 & Web服务器

## 让网站准备好发布

**必须调整的关键配置是：**

* DEBUG. 在生产环境中设置为 False（DEBUG = False）。避免在 web 页面上显示敏感的调试跟踪和变量信息

* SECRET_KEY. 这是用于CSRF保护的随机值

* ALLOWED_HOSTS, 生产环境必须设置 允许访问的域名

* 生成 SECRET KEY

  ```shell
  $ python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
  ```

## 密钥的存储和管理

* 从环境变量读取配置， 或从配置文件中读取

```python
import os

DEBUG = FALSE
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'xxxxzz')
ALLOWED_HOSTS = ["127.0.0.1", "域名", ]
```

* 从 KMS 系统中读取配置的密钥
  * 自己部署的 KMS 系统
  * 云服务的 KMS 服务： 阿里云/AWS 的 KMS 服务

## 部署前的安全检查

```shell
$ python manage.py check --deploy
```

**静态资源文件的托管环境**

* 静态内容 Web 服务器： Apache/Nginx

* CDN 服务器



**collectstatic 工具：用来收集静态资源文件, settings 中的相关设置：**

* STATIC_URL: 能够访问到静态文件的 URL 路径。

* STATIC_ROOT: collectstatic 工具用来保存收集到的项目引用到的任何静态文件的路径

* STATICFILES_DIRS: 这列出了 Django 的 collectstatic 工具应该搜索静态文件的其他目录。

```shell
$ python manage.py collectstatic --settings=settings.local
```

收集完成后，可以将这些静态文件，上传到托管文件的服务器/CDN。

## Django 应用容器

* 同步应用
  * uWSGI: C 实现的 Python Web 容器；Web 服务器 Apache/Nginx 与 django-uwsgi 进程通信来提供动态的内容; 
  * gunicorn：纯 Python 实现的高性能 Python 应用容器，无外部依赖，简单容易配置； 还没有遇到性能问题的时候，推荐使用 gunicorn. 

* 异步应用
  * Daphne: twisted 实现
  * Hypercorn: 基于 sans-io hyper, h11, h2, wsproto实现
  * Uvicorn: 基于 uvloop and httptools 实现

## 异步支持 Roadmap

* Django 的异步支持 Roadmap
  * Django 3.0 - ASGI Server
  * Django 3.1 - Async Views 
  * Django 3.2/4.0 - Async ORM



- 异步视图

  ```python
  async def view(request):
    await asyncio.sleep(0.5)
    return HttpRespomse("Hello, async world!")
  ```

  ## 启动服务器

* 同步应用服务器，以 gunicorn 为例

  ```shell
  $ python -m pip install gunicorn
  
  $ export DJANGO_SETTINGS_MODULE=settings.local
  
  $ gunicorn -w 3 -b 127.0.0.1:8000 recruitment.wsgi:application
  ```

  以上启动 3 个 worker进程, 绑定到 本机的8000端口

* 异步应用服务器，以uvcorn 为例

  ```shell
  $ python -m pip install uvicorn
  
  $ export DJANGO_SETTINGS_MODULE=settings.local
  
  $ uvicorn recruitment.asgi:application --workers 3
  ```

  

