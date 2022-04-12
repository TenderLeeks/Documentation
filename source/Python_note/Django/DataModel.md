# 数据模型 Model

从模型的定义过程分析归纳得知，模型定义可以分为三部分，每个部分的功能说明如下：

1. 定义模型字段，每个模型字段对应数据表的某个表字段，字段以 `aa=models.bb(cc)` 格式表示，比如 `id = models.AutoField(primary_key=True)`，其中id为模型字段名称，它与数据表的表字段相互对应；`models.AutoField` 是设置字段的数据类型，常用类型有整型、字符型或浮点型等；`primary_key=True`是设置字段属性，例如字段是否为表主键、限制内容长度、设置默认值等。

   在源码目录 `django/db/models/fields的__init__.py` 和 `files.py` 文件里找到各种模型字段，说明如下：

   - `AutoField`: 自增长类型，数据表的字段类型为整数，长度为11位。
   - `BigAutoField`: 自增长类型，数据表的字段类型为bigint，长度为20位。
   - `CharField`: 字符类型。
   - `BooleanField`: 布尔类型。
   - `CommaSeparatedIntegerField`: 用逗号分隔的整数类型。
   - `DateField`: 日期（Date）类型。
   - `DateTimeField`: 日期时间（Datetime）类型。
   - `Decimal`: 十进制小数类型。
   - `EmailField`: 字符类型，存储邮箱格式的字符串。
   - `FloatField`: 浮点数类型，数据表的字段类型变成Double类型。
   - `IntegerField`: 整数类型，数据表的字段类型为11位的整数。
   - `BigIntegerField`: 长整数类型。
   - `IPAddressField`: 字符类型，存储Ipv4地址的字符串。
   - `GenericIPAddressField`: 字符类型，存储Ipv4和Ipv6地址的字符串。
   - `NullBooleanField`: 允许为空的布尔类型。
   - `PositiveIntegerField`: 正整数的整数类型。
   - `PositiveSmallIntegerField`: 小正整数类型，取值范围为0~32767。
   - `SlugField`: 字符类型，包含字母、数字、下划线和连字符的字符串。
   - `SmallIntegerField`: 小整数类型，取值范围为-32768~+32767。
   - `TextField`: 长文本类型。
   - `TimeField`: 时间类型，显示时分秒 HH:MM[:ss[.uuuuuu]]。
   - `URLField`: 字符类型，存储路由格式的字符串。
   - `BinaryField`: 二进制数据类型。
   - `FileField`: 字符类型，存储文件路径的字符串。
   - `ImagerField`: 字符类型，存储图片路径的字符串。
   - `FilePathField`: 字符类型，从特定的文件目录选择某个文件。

   在不同的字段类型中，还可以设置字段的基本属性，比如 primary_key=True 是将字段设置为主键，没个字段都具有共同的基本属性，如下所示：

   - `verbose_name`: 默认为None，在Admin站点管理设置字段的线上名称。
   - `primary_key`: 默认为False，若为True，则将字段设置成主键。
   - `max_length`: 默认为None，设置字段的最大长度。
   - `unique`: 默认为False，若为True，这设置字段的唯一属性。
   - `blank`: 默认为False，若为True，则字段允许为空值，数据库将存储空字符串。
   - `null`: 默认为False，若为True，则字段允许为空值，数据库表现为NULL。
   - `db_index`: 默认为False，若为True，则以此字段来创建数据库索引。
   - `default`: 默认为NOT_PROVIDED对象，设置字段的默认值。
   - `editable`: 默认为True，允许字段可编辑，用于设置Admin的新增数据的字段。
   - `serialize`: 默认为True，允许字段序列化，可将数据转化为JSON格式。
   - `unique_for_date`: 默认为None，设置日期字段的唯一性。
   - `unique_for_month`: 认为None，设置日期字段月份的唯一性。
   - `unique_for_year`: 认为None，设置日期字段年份的唯一性。
   - `choices`: 默认为空列表，设置字段的可选性。
   - `help_text`: 默认为空字符串，用于设置表单的提示信息。
   - `db_column`: 默认为None，设置数据表的列名称，若不设置，则将字段名作为数据表的列名。
   - `db_tablespace`: 默认为None，如果字段已创建索引，那么数据库的表空间名称将作为该字段的索引名。注意: 部分数据库不支持表空间。
   - `auto_created`: 默认为False，若为True，则自动创建字段，用于一对一的关系模型。
   - `validators`: 默认为空列表，设置字段内容的验证函数。
   - `error_messages`: 默认为None，设置错误提示。

2. 重写函数 __str__()，这是设置模型的返回值，默认情况下，返回值为模型名+主键。

   - 函数 __str__ 可用于外键查询，比如模型A设有外键字段F，外键字段F关联模型B，当查询模型A时，外键字段F会将模型B的函数__str__返回值作为字段内容。
   - 注意: 函数__str__只允许返回字符类型的字段，如果字段的整型或者日期类型的，就必须使用Python的str()函数将其转化成字符类型。

3. 重写Meta选项，这是设置模型的常用属性，一共设有19个属性，每个属性的说明如下:

   - `abstract`: 若设为True，则该模型为抽象模型，不会在数据库里创建数据表。
   - `app_label`: 属性值为字符串，将模型设置为指定的项目应用，比如将index的models.py定义的模型A指定到其他的App里。
   - `db_table`: 属性值为字符串，设置模型所对应的数据表名称。
   - `db_tablespace`: 属性值为字符串，设置模型所使用数据库的表空间。
   - `get_latest_by`: 属性值为字符串或列表，设置模型数据的排序方式。
   - `managed`: 默认值为True，支持Django命令执行数据迁移；若为False，则不支持数据迁移功能。
   - `order_with_respect_to`: 属性值为字符串，用于多对多的模型关系，指向某个关联模型的名称，并且模型名称必须为英文小写。
   - `ordering`: 属性值为列表，将模型数据以某个字段进行排序。
   - `permissions`: 属性值为元组，设置模型的访问权限，默认设置添加、删除和修改的权限。
   - `proxy`: 若为True，则为模型创建代理模型，即克隆一个与模型A相同的模型B。
   - `required_db_features`: 属性值为列表，声明模型依赖的数据库功能。
   - `required_db_vendor`: 属性值为列表，声明模型支持的数据库，默认支持SQLite、PostgreSQL、MySQL和Oracle。
   - `select_on_save`: 数据新增修改算法，通常无需设置此属性，默认值为False。
   - `indexes`: 属性值为元组，多个字段的联合唯一，等于数据库的联合约束。
   - `verbose_name`: 属性值为字符串，设置模型直观可读的名称并以复数形象表示。
   - `verbose_name_plural`: 与 verbose_name 相同，以单数形式表示。
   - `label`: 只读属性。
   - `label_lower`: 与label相同。

## 数据迁移创建数据表

```shell
$ python manage.py makemigrations
$ python manage.py migrate
# 单独执行一个应用
$ python manage.py migrate commodity 0001_initial
# 生成 sql 语句
$ python manage.py sqlmigrate commodity 0001_initial
```

## 使用 QuerySet 操作数据

Django 对数据库的数据进行增、删、改操作是借助内置ORM框架所提供的API方法实现的

### 新增数据

```shell
$ python manage.py shell
# 在Shell模式下，对数据表commodity_types新增数据
>>> from commodity.models import Types
>>> t = Types()
>>> t.firsts = '童装1'
>>> t.seconds = '女装1'
>>> t.save()
>>> t.id
```

除了上述方法外，数据新增还有以下3种常见方法，如下：

```shell
# 方法一
# 使用create方法实现数据新增
>>> t = Types.objects.create(firsts='儿童用品1', seconds='婴儿床')

# 方法二
# 同样使用create方法，但数据以字典格式表示
>>> d = dict(firsts='奶粉辅食1', seconds='磨牙饼干1')
>>> t = Types.objects.create(**d)

# 方法三
# 在实例化时直接设置属性值
>>> t = Types(firsts='儿童早教1', seconds='通话故事1')
>>> t.save
```

#### get_or_create 方法

数据去重判断，数据表中有数据则不操作，没有数据则新增数据。

```shell
>>> d = dict(firsts='奶粉辅食1', seconds='营养品1')
>>> t = Types.objects.get_or_create(**d)
# 数据新增后，获取新增数据的主键id
>>> t[0].id
```

#### update_or_create 方法

判断当前数据在数据表里是否存在，若存在，则进行更新操作，否则在数据表里新增数据。

```shell
# 第一次是新增数据
>>> d = dict(firsts='儿童早教1', seconds='儿童玩具1')
>>> t = Types.objects.update_or_create(**d)
# 第二次是修改数据
>>> t = Types.objects.update_or_create(**d, defaults={'firsts': '教育资料'})
>>> t[0].title
```

#### bulk_create 方法

批量新增数据

```shell
>>> t1 = Types(firsts='儿童用品', seconds='湿纸巾')
>>> t2 = Types(firsts='儿童用品', seconds='纸尿裤')
>>> ojb_list = [t1, t2]
>>> Types.objects.bulk_create(ojb_list)
```

### 更新数据

```shell
>>> t = Types.objects.get(id=1)
>>> t.firsts = '儿童用品'
>>> t.save
```

#### update 方法

```shell
# 批量更新一条或多条数据，查询方法使用filter
# filter 以列表格式返回，查询结果可能是一条或多条数据
>>> Types.objects.filter(id=1).update(seconds='男装')
# 更新数据以字典格式表示
>>> d = dict(seconds='童鞋')
>>> Types.objects.filter(id=1).update(**d)
# 不使用查询方法，默认对全表的数据进行更相信
>>> Types.objects.update(firsts='母婴用品')
# 使用内置 F 方法实现数据的自增和自减
# F 方法还可以在 annotate 或 filter 方法里使用
>>> from django.db.models import F
>>> t = Types.objects.filter(id=1)
# 将 id 字段原有的数据自增加10，自增或自减的字段必须为数字类型
>>> t.update(id=F('id')+10)
```

#### bulk_update

数据批量更新

```shell
# 新增两个数据
>>> t1 = Types.objects.create(firsts='奶粉辅食', seconds='纸尿片')
>>> t2 = Types.objects.create(firsts='儿童用品', seconds='进口奶粉')
# 修改字段 firsts 和 seconds 的数据
>>> t1.firsts = '儿童用品'
>>> t2.seconds = '婴儿车'
# 批量修改字段 firsts 和 seconds 的数据
>>> Types.objects.bulk_update([t1, t2],fields=['firsts','seconds'])
```

### 删除数据

删除数据有3种方式：删除数据表的全部数据、删除一行数据和删除多行数据。

```shell
# 删除数据表中的全部数据
>>> Types.objects.all().delete()
# 删除一条id为1的数据
>>> Types.objects.get(id=1).delete()
# 删除多条数据
>>> Types.objects.filter(firsts='儿童用品').delete()
```

### 查询单表数据

```shell
>>> from index.models import *
# 全表查询
# SQL：select * from index_vocation，数据以列表返回
>>> v = Vocation.objects.all()
# 查询第一条数据，序列从0开始
>>> v[0].job

# 查询前3条数据
# SQL：select * from index_vocation limit 3
# SQL 语句的limit方法，在Django中使用列表截取即可
>>> v = Vocation.objects.all()[:3]

# 查询某个字段
# SQL：select job from index_vocation
# values 方法，数据以列表返回，列表元素以字典表示
>>> v = Vocation.objects.values('job')
>>> v[1]['job']

# values_list 方法，数据以列表返回，列表元素以元组表示
>>> v = Vocation.objects.values_list('job')[:3]

# 使用 get 方法查询数据
# SQL：select * from index)_vocation where id=2
>>> v = Vocation.objects.get(id=2)
>>> v.job

# 使用 filter 方法查询数据，注意区分get和filter的差异
>>> v = Vocation.objects.filter(id=2)
>>> v[0].job

# SQL 的and查询主要在filter里面添加多个查询条件
>>> v = Vocation.objects.filter(job='网站设计', id=3)
# filter 的查询条件可设为字典格式
>>> d = dict(job='网站设计', id=3)
>>> v = Vocation.objects.filter(**d)

# SQL 的or查询，需要引入Q，编写格式：Q(field=value)|Q(ffield=value)
# 多个Q之间使用"|"隔开即可
# SQL：select * from index_vocation where job='网站设计' or id=9
>>> from django.db.models import Q
>>> v = Vocation.objects.filter(Q(job='网站设计')|Q(id=9))

# SQL 的不等于查询，在Q查询前面使用"~"即可
# SQL语句：select * from index_vocation where not (job='网站设计')
>>> v = Vocation.objects.filter(~Q(job='网站设计'))
# 还可以使用exclude实现不等于查询
>>> v = Vocation.objects.exclude(job='网站设计')

# 使用count方法统计查询数据的数据量
>>> v = Vocation.objects.filter(job='网站设计').count()

# 去重查询，distinct 方法无须设置参数，去重方式根据values设置的字段执行
# SQL：select distinct job from index_vocation wherer job = '网站设计'
>>> v = Vocation.objects.values('job').filter(job='网站设计').distinct()

# 根据字段id降序排列，降序只要在order_by里面的字段前面加"-"即可
>>> v = Vocation.objects.order_by('-id')

# 聚合查询，实现对数据值的求和、求平均值等，由annotate和aggregate方法实现
# annotate 类似于SQL里面的GROUP BY方法
# 如果不设置values，默认对主键进行GROUP BY分组
# SQL：select job,sum(id) as 'id__sum' from index_vocation group by job
>>> from django.db.models import Sum, Count
>>> v = Vocation.objects.values('job').annotate(Sum('id'))
>>> print(v.query)

# aggregate是计算某个字段的值并只返回计算结果
# SQL：select count(id) as 'id_count' from index_vocation
>>> from django.db.models import Count
>>> v = Vocation.objects.aggregate(id_count=Count('id'))

# union、intersection和difference语法
# 每次查询结果的字段必须相同
# 第一次查询结果v1
>>> v1 = Vocation.objects.filter(payment__=9000)
# 第二次查询结果v2
>>> v2 = Vocation.objects.filter(payment__gt=5000)

# 使用SQL的UNION来组合两个或多个查询结果的并集
# 获取两次查询结果的并集
>>> v1.intersection(v2)
# 使用SQL的except来获取两个或多个查询结果的差
# 以v2为目标数据，去除v1和v2的共同数据
>>> v2.difference(v1)
```

想使用大于、小于、不等于或模糊查询的匹配方法，则可在查询条件filter和get里使用匹配符实现。

<table border="1" cellpadding="10" cellspacing="10">
  <thead>
    <tr><th>匹配符</th><th>使用</th><th>说明</th></tr>
  </thead>
    <tbody>
    <tr><td>__exact</td><td>filter(job__exact='开发')</td><td>精确等于，如SQL的like'开发'</td></tr>
    <tr><td>__iexact</td><td>filter(job__iexact='开发')</td><td>精确等于并忽略大小写</td></tr>
    <tr><td>__contains</td><td>filter(job__contains='开发')</td><td>模糊匹配，如SQL的like'%开发%'</td></tr>
    <tr><td>__icontains</td><td>filter(job__icontains='开发')</td><td>模糊匹配，忽略大小写</td></tr>
    <tr><td>__gt</td><td>filter(id__gt=5)</td><td>大于</td></tr>
    <tr><td>__gte</td><td>filter(id__gte=5)</td><td>大于等于</td></tr>
    <tr><td>__lt</td><td>filter(id__lt=5)</td><td>小于</td></tr>
    <tr><td>__lte</td><td>filter(id__lte=5)</td><td>小于等于</td></tr>
    <tr><td>__in</td><td>filter(id__in=[1,2,3])</td><td>判断是否在列表内</td></tr>
    <tr><td>__startswith</td><td>filter(job__startswith='开发')</td><td>以.....开头</td></tr>
    <tr><td>__istartswith</td><td>filter(job__istartswith='开发')</td><td>以......开头并忽略大小写</td></tr>
    <tr><td>__endswith</td><td>filter(job__endswith='开发')</td><td>以......结尾</td></tr>
    <tr><td>__iendswith</td><td>filter(job__iendswith='开发')</td><td>以......结尾并忽略大小写</td></tr>
    <tr><td>__range</td><td>filter(job__range='开发')</td><td>在......范围内</td></tr>
    <tr><td>__year</td><td>filter(date__year=2021)</td><td>日期字段的年份</td></tr>
    <tr><td>__month</td><td>filter(date__month=12)</td><td>日期字段的月份</td></tr>
    <tr><td>__day</td><td>filter(date__day=30)</td><td>日期字段的天数</td></tr>
    <tr><td>__isnull</td><td>filter(date__isnull=True/False)</td><td>判断是否为空</td></tr>
  </tbody>
</table>




#### 查询条件 get 和 filter 的差异

* `查询条件 get`：查询字段必须是主键或者唯一约束的字段，并且查询的数据必须存在，如果在查询的字段有重复值或者查询的数据不存在，程序就会抛出异常信息。
* `查询条件 filter`：查询字段没有限制，只有该字段是数据表的某一字段即可。查询结果一列表形式返回，如果查询结果为空（查询的数据在数据表中找不到），就返回空列表。

### 查询多表数据

```shell
# 正向查询
# 查询模型Vocation某行数据对象v
>>> v = Vocation.objects.filter(id=1).first()
# v.name代表外键name
# 通过外键name去查询模型PersonInfo所对应的数据
>>> v.name.hireDate

# 反向查询
# 查询模型PersonInfo某行数据对象p
>>> p = PersonInfo.objects.filter(id=2).first()
# 方法一
# vocation_set的返回值为queryset对象，即查询结果
# vocation_set的vocation为模型Vocation的名称小写
# 模型Vocation的外键字段name不能设置参数related_name
# 若设置参数related_name，则无法使用vocation_set
>>> v = p.vocation_set.first()
>>> v.job
# 方法二
# 由模型Vocation的外键字段name的参数related_name实现
# 外键字段name必须设置参数related_name才有效，否则无法查询
# 将外键字段name的参数related_name设为ps
>>> v = p.ps.first()
>>> v.job
```



