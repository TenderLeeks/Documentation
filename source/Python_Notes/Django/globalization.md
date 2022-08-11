# 国际化支持

步骤：

* 代码中使用 `gettext`，`gettext_lazy` 获取多语言资源对应的文本内容
* 生成多语言资源文件
* 翻译多语言内容
* 生成二进制多语言资源文件



需要使用多语言的字符前加下划线来引用，例如：`_('创建时间'))`

```python
from django.utils.translation import gettext_lazy as _

class Version(models.Model):
    # Translators: Dev Ystar Version
    created_at = models.DateTimeField(blank=True, null=True, verbose_name=_('创建时间'))
    updated_at = models.DateTimeField(blank=True, null=True, verbose_name=_('修改时间'))
    deleted_at = models.DateTimeField(blank=True, null=True, verbose_name=_('删除时间'))
    version = models.CharField(max_length=8, blank=True, null=True, verbose_name=_('版本号'))
    update_model = models.IntegerField(blank=True, null=True, choices=UpdateModel, verbose_name=_('更新模式'))
    platform = models.IntegerField(blank=True, null=True, choices=PlatformSystem, verbose_name=_('平台系统'))
    publish_time = models.DateTimeField(blank=True, null=True, verbose_name=_('发布时间'))
    update_content = models.TextField(max_length=1024, blank=True, null=True, default=DefaultContent,
                                      verbose_name=_('更新文案'))

    def __str__(self):
        return "123"

    class Meta:
        managed = False
        db_table = 'version'
        app_label = "dev_ystar_app"
        verbose_name = _('DEV版本信息')
        verbose_name_plural = _('DEV版本列表')
```

模板中使用多语言：

```html
{% load i18n %}

<h3 > {% translate "某某科技管理平台" %} </h3>

{% if user.is_authenticated %}
<p>{% blocktranslate with user_name=user.username %} 终于等到你 {{ user_name }}, 期待加入我们，用技术去探索一个新世界 {% endblocktranslate %}</p>
{% else %}
<br>{% translate "欢迎你，期待加入我们，登陆后可以提交简历." %}<br>
{% endif %}

```

`{% load i18n %}`：在模板中使用多语言需要导入 `i18n`， 然后使用 `translate` 这个指令来获取某一个 `key` 对应的多语言。

`blocktranslate`：声明变量



在工程目录下创建 `locale` 文件夹，`locale` 文件是存放多语言文件的地方

```shell
$ mkdir locale
```

生成多语言文件

```shell
$ django-admin makemessages -l zh_HANS -l en
```

命令运行完后会在 `locale` 目录下生成 `zh_HANS` 和 `en` 两个文件。

翻译对应的 `django.po` 文件内容，然后执行以下命令把多语言文件初始化为二进制格式 `django.mo` 文件。

```shell
$ django-admin compilemessages
```

在项目 urls.py 文件中加入 URL 映射

```python
urlpatterns = [
    path("", include("dev_ystar_app.urls")),
    path("", include("prod_ystar_app.urls")),
    path('admin/', admin.site.urls),
    # 多语言映射
    path("i18n/", include('django.conf.urls.i18n')),
]
```

在 `settings` 配置文件中加入多语言支持

```python
from django.utils.translation import gettext_lazy as _

# 在 SessionMiddleware 和 CommonMiddleware 中间加入多语言中间件 LocaleMiddleware
MIDDLEWARE = [
    ...
    'django.contrib.sessions.middleware.SessionMiddleware',  # session 中间件，处理用户登录信息
    'django.middleware.locale.LocaleMiddleware',  # 多语言中间件
    'django.middleware.common.CommonMiddleware',  # 常用信息
    ...
]


# 选择语言的种类
LANGUAGES = [
    ('zh-hans', _('Chinese')),
    ('en', _('English')),
]

# 中文
LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = 'Asia/Shanghai'
USE_I18N = True
USE_L10N = True
USE_TZ = True

# 多语言资源文件的路径配置
LOCALE_PATHS = (
    os.path.join(BASE_DIR, 'locale'),
)

```

在首页中添加按钮选择语言

```html
<div style="flex: 1; align-content:right;">
<form action="{% url 'set_language' %}" method="post" style="margin-block-end: 0em;">{% csrf_token %}
    <input name="next" type="hidden" value="{{ redirect_to }}">
    <select name="language">
        {% get_current_language as LANGUAGE_CODE %}
        {% get_available_languages as LANGUAGES %}
        {% get_language_info_list for LANGUAGES as languages %}
        {% for language in languages %}
            <option value="{{ language.code }}"{% if language.code == LANGUAGE_CODE %} selected{% endif %}>
                {{ language.name_local }} ({{ language.code }})
            </option>
        {% endfor %}
    </select>
        {% translate "language" %} {{ LANGUAGE_CODE}}
	<input type="submit" value={% translate "Switch" %} style="font-size:12;height:20px">
</form>
</div>
```

`redirect_to`：选择语言成功之后登陆的页面，默认是首页

`{% get_current_language as LANGUAGE_CODE %}`：获取当前的语言

`{% get_available_languages as LANGUAGES %}`：获取所有可用的语言

`{% get_language_info_list for LANGUAGES as languages %}`：遍历所有可用的语言

