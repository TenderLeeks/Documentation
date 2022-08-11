# Rest API 使用

[官网网站地址](https://www.django-rest-framework.org)

```shell
$ pip install djangorestframework
$ pip install markdown       # Markdown support for the browsable API.
$ pip install django-filter  # Filtering support
```

或从 github 克隆项目

```shell
$ git clone https://github.com/encode/django-rest-framework
```

添加`rest_framework`到您的`INSTALLED_APPS`设置中。

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
]
```

如果您打算使用可浏览 API，您可能还想添加 REST 框架的登录和注销视图。将以下内容添加到您的根`urls.py`文件中。

```python
urlpatterns = [
    ...
    path('api-auth/', include('rest_framework.urls'))
]
```

请注意，URL 路径可以是您想要的任何内容。

例子：

让我们看一下使用 REST 框架构建简单的模型支持 API 的快速示例。

我们将创建一个读写 API 来访问有关我们项目用户的信息。

REST 框架 API 的任何全局设置都保存在一个名为`REST_FRAMEWORK`. 首先将以下内容添加到您的`settings.py`模块中：

```python
REST_FRAMEWORK = {
    # Use Django's standard `django.contrib.auth` permissions,
    # or allow read-only access for unauthenticated users.
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.DjangoModelPermissionsOrAnonReadOnly'
    ]
}
```

不要忘记确保您还添加`rest_framework`到您的`INSTALLED_APPS`.

我们现在准备好创建我们的 API。这是我们项目的根`urls.py`模块：

```python
from django.urls import path, include
from django.contrib.auth.models import User
from rest_framework import routers, serializers, viewsets

# 序列化器定义API表示
class UserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'username', 'email', 'is_staff']

# 视图集定义了视图行为
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
class JobSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Job
        fields = '__all__'
        
class JobViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Job.objects.all()
    serializer_class = JobSerializer
    

# 路由器提供了一种自动确定URL配置文件的简单方法
router = routers.DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'jobs', JobViewSet)

# 使用自动URL路由连接我们的API
# 此外，我们还包含了可浏览API的登录url
urlpatterns = [
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
]
```

您现在可以在浏览器中打开该 API，访问地址为 `http://127.0.0.1:8000/`，并查看您的新“用户”API。如果您使用右上角的登录控件，您还可以在系统中添加、创建和删除用户。
