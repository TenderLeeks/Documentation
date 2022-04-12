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



# Django配置文件

## 中间件 MIDDLEWARE

- `SecurityMiddleware`: 内置的安全机制，保护用户与网站的通信安全。
- `SessionMiddleware`: 会话 Session 功能。
- `LocaleMiddleware`: 国际化和本地化的功能。
- `CommonMiddleware`: 处理请求信息，规范化请求内容。
- `CsrfViewMiddleware`: 开启 CSRF 防护功能。
- `AuthenticationMiddleware`: 开启内置的用户认证系统。
- `MessageMiddleware`: 开启内置的信息提示功能。
- `XFrameOptionsMiddleware`: 防止恶意程序单劫持。

## 配置数据库 DATABASES

Django 提供了4种数据库引擎:

* `'django.db.backends.postgresql'`
* `'django.db.backends.mysql'`
* `'django.db.backends.sqlite3'`
* `'django.db.backends.oracle'`

使用 MySQL 数据

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'babys',
        'USER': 'root',
        'PASSWORD': '123456',
        'HOST': '127.0.0.1',
        'PORT': '3306',
    }
}
```

`Django` 可以使用 `mysqlclient` 和 `pymysql` 模块实现 `MySQL` 连接。
安装指令分别是 `pip install mysqlclient` 和 `pip install pymysql`。
使用模块 `mysqlclient` 无需修改其他配置，但是使用模块 `pymysql` 时，需要在项目同名的文件夹 `__init__.py` 中设置数据库连接模块。

```python
import pymysql
pymysql.install_as_MySQLdb()
```

## 配置静态资源

静态资源的配置分别由配置属性 STATIC_URL、STATICFILES_DIRS 和 STATIC_ROOT 完成，默认情况下，Django 只配置了配置属性 STATIC_URL。

## 配置媒体资源

媒体资源只有配置属性 MEDIA_URL 和 MEDIA_ROOT。



# 多数据库路由设置

在django项目中, 一个工程中存在多个APP应用很常见. 有时候希望不同的APP连接不同的数据库，这个时候需要建立多个数据库连接。

1. **修改项目的 settings 配置**

   在 `settings.py` 中配置需要连接的多个数据库连接串

   ```python
   DATABASES = {
       # 'default': {
       #     'ENGINE': 'django.db.backends.sqlite3',
       #     'NAME': BASE_DIR / 'db.sqlite3',
       # }
       'default': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'databases_name1',
           'USER': 'user1',
           'PASSWORD': '123456',
           'HOST': '127.0.0.1',
           'PORT': '3306',
       },
       'databases01': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'databases_name2',
           'USER': 'user2',
           'PASSWORD': '123456',
           'HOST': '127.0.0.1',
           'PORT': '3306',
       }
   }
   ```

2. **设置数据库的路由规则方法**

   - 在 `settings.py` 中配置 `DATABASE_ROUTERS`

     ```python
     DATABASE_ROUTERS = ['settings.router.DatabaseRouter']
     ```

   - `settings`: 创建 settings 包。

   - `router`: 定义路由规则`router.py` 文件名称, 这个文件名可以自己定义。

   - `DatabaseRouter`: 路由规则的类名称，这个类是在`router.py` 文件中定义。

3. **设置APP对应的数据库路由表**

   每个APP要连接哪个数据库，需要在做匹配设置，在 `settings.py` 文件中做如下配置：

   ```python
   DATABASE_APPS_MAPPING = {
       'app_name01': 'databases01',
   }
   ```

   为了使django自己的表也创建到你自己定义的数据库中，你可以指定 : admin, auth, contenttypes, sessions 到设定的数据库中，如果不指定则会自动创建到默认（default）的数据库中

4. **创建数据库路由规则**

   创建 `settings/router.py` 文件

   ```python
   from django.conf import settings
   
   DATABASE_MAPPING = settings.DATABASE_APPS_MAPPING
   
   
   # settings/router.py
   # 数据库路由器到多个数据库的应用程序标签
   class DatabaseRouter(object):
       """
       用于控制不同数据库模型上所有数据库操作的路由器。
       如果应用程序没有在 settings.DATABASE_APPS_MAPPING 中设置，路由器将回退到“默认”数据库。
   
       Settings example:
       DATABASE_APPS_MAPPING = {'app1': 'db1', 'app2': 'db2'}
       """
   
       def db_for_read(self, model, **hints):
           """"将所有读操作指向特定的数据库"""
           if model._meta.app_label in DATABASE_MAPPING:
               return DATABASE_MAPPING[model._meta.app_label]
           return 'default'
   
       def db_for_write(self, model, **hints):
           """将所有写操作指向特定的数据库"""
           if model._meta.app_label in DATABASE_MAPPING:
               return DATABASE_MAPPING[model._meta.app_label]
           return 'default'
   
       def allow_relation(self, obj1, obj2, **hints):
           """允许使用相同数据库的应用程序之间存在任何关系"""
           db_obj1 = DATABASE_MAPPING.get(obj1._meta.app_label)
           db_obj2 = DATABASE_MAPPING.get(obj2._meta.app_label)
           if db_obj1 and db_obj2:
               if db_obj1 == db_obj2:
                   return True
               else:
                   return False
           return None
   
       def allow_syncdb(self, db, model):
           """确保应用程序只出现在相关的数据库中"""
           if db in DATABASE_MAPPING.values():
               return DATABASE_MAPPING.get(model._meta.app_label) == db
           elif model._meta.app_label in DATABASE_MAPPING:
               return False
           return None
   
       def allow_migrate(self, db, app_label, model=None, **hints):
           """确保auth应用只出现在'auth_db'数据库中"""
           if db in DATABASE_MAPPING.values():
               return DATABASE_MAPPING.get(app_label) == db
           elif app_label in DATABASE_MAPPING:  # 遗留数据库中的表不允许迁移
               return False
           return None
   ```

5. **Models创建样例**

   如果是已经存在数据的库，指定数据库表生成model（inspectdb）

   ```python
   python3.8 manage.py inspectdb --database=databases01 version version_channel > models.py
   ```

   在各自的 APP 中创建数据表的models时，必须要指定表的 `app_label` 名字，如果不指定则会创建到 `default` 中配置的数据库名下，如下：

   ```python
   class Version(models.Model):
       created_at = models.DateTimeField(blank=True, null=True, verbose_name='创建时间')
       updated_at = models.DateTimeField(blank=True, null=True, verbose_name='修改时间')
       deleted_at = models.DateTimeField(blank=True, null=True, verbose_name='删除时间')
       version = models.CharField(max_length=8, blank=True, null=True, verbose_name='版本号')
       update_model = models.IntegerField(blank=True, null=True, verbose_name='更新模式')
       platform = models.IntegerField(blank=True, null=True, verbose_name='平台')
       publish_time = models.DateTimeField(blank=True, null=True, verbose_name='发布时间')
       update_content = models.CharField(max_length=1024, blank=True, null=True, verbose_name='更新文案')
   
       class Meta:
           managed = True
           db_table = 'version'
           app_label = "app_name01"
   ```

6. **注册到admin中（admin.py）**

   ```python
   from django.contrib import admin
   from app_name01.models import Version, VersionChannel
   
   admin.site.register(Version)
   admin.site.register(VersionChannel)
   ```




# 配置分离

1. 在项目根目录下创建名为 `settings` 的`Python`包，然后把项目中原配置文件 `settings.py` 移动到 `settings`目录中，并重命名为 `base.py` 。

2. 修改项目管理文件 `manage.py` 中配置项。

   ```python
   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'management.settings')
   # 修改如下
   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings.base')
   ```

3. 文件 `base.py` 中放入一些基础的配置。

4. 在创建 `local.py` 本地配置文件，把一些敏感的配置写的 `local.py` 配置文件中，然后在 `.gitignore` 文件中加入此文件，这样在上传代码后不会把 `local.py` 文件上传到版本库中。

5. 在创建生产环境配置文件 `production.py` 文件，此配置文件问生产环境配置，项目上线后修改此配置文件配置。

6. 启动本地环境命令：

   ```shell
   $ python manage.py runserver 0.0.0.0:8000 --settings=settings.local
   ```

   
