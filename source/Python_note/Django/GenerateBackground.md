# 为已有数据库生成管理后台

## 背景

在进行开发过程中，为了简化后台的开发过程或者更新后台框架为Django，我们需要使用Django对现有的数据库进行一个接管，以此来完成我们的开发过程。

## 方法

在 Django 中提供了一种数据转化的程序 inspectdb，我们可以通过这个 inspectdb 来将数据库内容转化成数据模型，这样就完成了数据库的结果，就可以对数据库进行后续开发和实现。

1. 创建Django项目

   ```shell
   $ django-admin startproject management
   ```

2. 编辑 `management/settings.py` 中的数据库配置

   ```python
   DATABASES = {
       # 'default': {
       #     'ENGINE': 'django.db.backends.sqlite3',
       #     'NAME': BASE_DIR / 'db.sqlite3',
       # }
       'default': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'chain_account_info',
           'USER': 'root',
           'PASSWORD': '6#R@a7e2mSALMUg3',
           'HOST': '127.0.0.1',
           'PORT': '3306',
       }
   }
   ```

   

## 生成数据模型

我们可以通过下面的指令将配置好的数据库信息直接生成模板。输出到 models.py 的文件中

```shell
$ python manage.py inspectdb > models.py
```

如果我们只是对某个数据表进行模板生成，可以使用下面的指令。结果将输出到models1.py的文件中。

```shell
$ python manage.py inspectdb --database default table_name > models1.py
# 例
$ python manage.py inspectdb --database hk_trade_robot nvex_balance bithumb_balance --settings=settings.local > models1.py
```

结果

```python
...
class AccountUsdyBalance(models.Model):
    account_name = models.CharField(primary_key=True, max_length=13)
    action_id = models.IntegerField(blank=True, null=True)
    balance = models.DecimalField(max_digits=19, decimal_places=4, blank=True, null=True)
    balance_update_flag = models.CharField(max_length=1)

    class Meta:
        managed = False
        db_table = 'account_usdy_balance'
...
```

默认情况下，inspectdb 创建非托管模型。 也就是说，在模型的 Meta 类中，`managed = False` 告诉 Django 不要管理每个表的创建，修改和删除。如果想让Django管理表的生命周期，你需要将上面的托管选项更改为 True，即将 `managed = False` 修改为 `managed = True`，或者删除他。

```python
...
class AccountUsdyBalance(models.Model):
    account_name = models.CharField(primary_key=True, max_length=13)
    action_id = models.IntegerField(blank=True, null=True)
    balance = models.DecimalField(max_digits=19, decimal_places=4, blank=True, null=True)
    balance_update_flag = models.CharField(max_length=1)

    class Meta:
        managed = True
        db_table = 'account_usdy_balance'
...
```

运行 migrate 命令以安装任何额外需要的数据库记录，如 session、auth 等。若对此类表格没有操作必要，可以不用执行下列代码，亦可进行数据库操作。

```shell
$ python manage.py makemigrations
$ python manage.py migrate
```

## 替换模板

将生成出来的结果，替换原代码，在进行admin的注册就可以了。

