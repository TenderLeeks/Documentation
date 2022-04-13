# 图形验证码

## 安装django-simple-captcha库

在网站开发的登录页面中，经常会需要使用到图形验证码来验证，在Django中，django-simple-captcha库包提供了图形验证码的使用。

```shell
$ pip install django-simple-captcha

# 如果安装有依赖库问题，清执行下面的安装
$ apt-get -y install libz-dev libjpeg-dev libfreetype6-dev python-dev
```

## 修改配置

```python
INSTALLED_APPS = [
    'captcha',
]

# CAPTCHA验证码设置
CAPTCHA_IMAGE_SIZE = (80, 45)  # 设置 captcha 图片大小
CAPTCHA_LENGTH = 4  # 字符个数
CAPTCHE_RIMEOUT = 1 # 超时(minutes)

# 输出格式：输入框 验证码图片 隐藏域
CAPTCHA_OUTPUT_FORMAT = '%(text_field)s %(image)s %(hidden_field)s'
CAPTCHA_NOISE_FUNCTIONS = ('captcha.helpers.noise_null',
                           'captcha.helpers.noise_arcs',  # 线
                           'captcha.helpers.noise_dots',  # 点
                          )
# 随机字符验证码
CAPTCHA_CHALLENGE_FUNCT = 'captcha.helpers.random_char_challenge'
# CAPTCHA_CHALLENGE_FUNCT = 'captcha.helpers.math_challenge'
```

`urls.py` 添加

```python
urlpatterns = [
    path('captcha/', include('captcha.urls')),  # 图片验证码路由
]
```

迁移数据库

```shell
$ python manage.py migrate
```

## 建立表单

```python
# forms.py

from django import forms
from captcha.fields import CaptchaField

class LoginForm(forms.form):
    username = forms.CharField(max_length=20,min_length=3)
    password = forms.CharField(max_length=128,widget=forms.PasswordInput())
    captcha = CaptchaField()  # 验证码字段
```

## 实现

`urls.py`

```python
urlpatterns = [
    ......
    path('yzm/', views.user_login, name='yzm'),
]
```

`login.html`

```html
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<div> {{ msg }} </div>
<form action="{% url 'app03:yzm' %}" method="post">
    {% csrf_token %}
    用户：{{ form.username }} <span> {{ form.username.errors.0 }}</span> <br>
    密码：{{ form.password }} <span> {{ form.password.errors.0 }}</span> <br>
    验证码：{{ form.captcha }} <span> {{ form.captcha.errors.0 }}</span> <br>
    <input type="submit">
</form>
</body>
</html>

<script src="https://cdn.bootcss.com/jquery/1.12.3/juqery.min.js"></script>
<script>
    // 点击刷新验证码
    $(function () {
        $('.captcha').css({
            'cursor': 'pointer'
        });
        // ajax刷新
        $('.captcha').click(function () {
            console.log('click');
            $.get("/app/refresh/",
                function (result) {
                    $('.captcha').attr('str', result['image_url']);
                    $('#id_captcha_0').val(result['key'])
                });
        });
    })
</script>
```

`views.py`

```python
import json
from captcha.helpers import captcha_image_url
from captcha.models import CaptchaStore
from django.contrib.auth import authenticate
import django.contrib.auth as auth
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, redirect

def user_login(request):
    if request.method == "POST":
        form = LoginForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(request, username=username, password=password)
            if user:
                auth.login(request, user)
                return redirect(reverse("app03:home"))
            else:
                form = LoginForm()
            # 跳转登录页面
            return render(request, 'app03/login.html', context={'form':form})
```


