# 只读站点 ReadOnlyAdmin

场景/解决问题

* 集成遗留的已有系统

* 已有系统的数据涉及到核心数据

* 为了确保数据安全，管理后台只提供数据的浏览功能

* 设置列表页 list_display 展示所有字段

`admin.py`中代码

```python
from django.contrib import admin
from .models import Country, Province, Area, City


# 新定义一个 ReadOnlyAdmin 类，需要继承 admin.ModelAdmin 类
class ReadOnlyAdmin(admin.ModelAdmin):
    readonly_fields = []

    # get_list_display 方法遍历 self.model._meta.concrete_fields 方法，把字段对应的名称显示出来
    def get_list_display(self, request):
        return [field.name for field in self.model._meta.concrete_fields]

    # 把 obj._meta 对应的字段全都取出来后追加到 readonly_fields 列表中
    def get_readonly_fields(self, request, obj=None):
        return list(self.readonly_fields) + \
               [field.name for field in obj._meta.fields] + \
               [field.name for field in obj._meta.many_to_many]

    # 禁止用户增加数据权限
    def has_add_permission(self, request):
        return False

    # 禁止用户删除数据权限
    def has_delete_permission(self, request, obj=None):
        return False

    # # 禁止用户修改数据权限
    def has_change_permission(self, request, obj=None):
        return False


# 定义 CountryAdmin，ProvinceAdmin 和 CityAdmin 类时继承 ReadOnlyAdmin 类
@admin.register(Country)
class CountryAdmin(ReadOnlyAdmin):
    search_fields = ('chn_name', 'eng_name',)

@admin.register(Province)
class ProvinceAdmin(ReadOnlyAdmin):
    search_fields = ('chn_name', 'eng_name',)
    
@admin.register(City)
class CityAdmin(ReadOnlyAdmin):
    autocomplete_fields = ['provinceid','countryid',]

    # list_display = ('cityid', 'countryid', 'areaid', 'provinceid', 'chn_name', 'eng_name')
```
