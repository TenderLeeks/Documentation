# 注册登录

## 集成 registration

* 允许注册：安装 `registration`

  ```shell
  $ pip install django-registration-redux
  ```

* 添加到 apps 中

* 同步数据库

* 添加登录，退出链接到页面中

注册 URL 到 `urls.py` 文件中

```python
urlpatterns = [
    ...
    path('accounts/', include('registration.backends.simple.urls')),
    ...
]
```

同步数据

```shell
$ python3.8 manage.py makemigrations --settings=settings.local
$ python3.8 manage.py migrate --database default --settings=settings.local
```

测试

访问地址：http://127.0.0.1:8000/accounts/register/
