# 自动注册所有Model到管理后台

场景/解决问题

* 实际的业务场景中， 往往Model 多大几十个

* 一个个写Admin， 再Register， 效率低

期望：能够自动注册 Model 到管理后台

* 注册所有 App 的所有 Model

* 直接注册所有 model 的问题

* settings 里面可能已经注册了 App

* 重复注册时会出现异常，需要处理重复注册的逻辑

* 避免重复注册



在主应用目录下 创建 `apps.py` 文件

```python
from django.contrib import admin
from django.apps import apps, AppConfig


class ListAdminMixin(object):
    def __init__(self, model, admin_site):
        # 列表页自动显示所有的字段：
        self.list_display = [field.name for field in model._meta.fields]
        super(ListAdminMixin, self).__init__(model, admin_site)


# 自动注册所有 models
class UniversalManagerApp(AppConfig):
    """
    应用配置在 所有应用的 Admin 都加载完之后执行
    """
    # AppConfig的名称必须与当前应用程序相同
    name = 'management'

    # ready 方法，是在某一个应用加载完成之后会调用 ready 方法
    def ready(self):
        # 遍历 trade_robot 应用下所有 model，也可以设置成遍历所有应用的model。
        models = apps.get_app_config('trade_robot').get_models()
        # models = apps.get_models()
        for model in models:
            admin_class = type('AdminClass', (ListAdminMixin, admin.ModelAdmin), {})
            try:
                admin.site.register(model, admin_class)
            except admin.sites.AlreadyRegistered:
                pass

```

Setting 配置文件中 INSTALLED_APPS 中注册

```python
INSTALLED_APPS = [
		...
    'management.apps.UniversalManagerApp',
]
```



Python 的动态 model

* Python中类也是对象

* 使用 Python 的动态特性

* 使用 type()函数来动态定义一个类

  `model = type(name, (models.Model,), attrs)`

  普通的类定义：

  ```python
  class Person(models.Model)
      first_name = models.CharField(max_length=255)
      last_name = models.CharField(max_length=255)
  ```

  等同于如下的动态类定义：

  ```python
  Person = type('Person', (models.Model,), {  # 类名，继承哪些类，参数
      'first_name': models.CharField(max_length=255),
      'last_name': models.CharField(max_length=255),
  })
  ```


* 对已有数据库提供增、删、改、查功能 和 Rest API

* 安装 sandman2

  `pip install sandman2`

* 以 SQLite 数据库为例子， 启动 sandman2

  `sandman2ctl sqlite+pysqlite:///db.sqlite3`

  访问 restapi 和 管理后台：

  http://127.0.0.1:5000/

  http://127.0.0.1:5000/admin/

