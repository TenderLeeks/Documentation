# Django 介绍

Django官方[文档](https://docs.djangoproject.com/zh-hans)

# Django 安全性

Django 的安全：如何防止 XSS 跨站脚本攻击

恶意攻击者将代码通过网站注入到其他用户浏览器中的攻击方式。

- 攻击者会把恶意 JavaScript 代码作为普通数据放入到网站数据库中；
- 其他用户在获取和展示数据的过程中，运行JavaScript 代码；
- JavaScript 代码执行恶意代码（调用恶意请求，发送数据到攻击者等等）。



Django 的安全：CSRF 跨站请求伪造和 SQL 注入攻击

* CSRF（Cross-site request forgery，简称：CSRF 或 XSRF）
* 恶意攻击者在用户不知情的情况下，使用用户的身份来操作
* **黑客的准备步骤**
  - 黑客创建一个 请求网站 A 类的 URL 的 Web 页面，放在恶意网站 B 中 ，这个文件包含了一个创建用户的表单。这个表单加载完毕就会立即进行提交。
  - 黑客把这个恶意 Web 页面的 URL 发送至超级管理员，诱导超级管理员打开这个 Web 页面。



SQL 注入攻击

* SQL 注入漏洞: 攻击者直接对网站数据库执行任意 SQL语句，在无需用户权限的情况下即可实现对数据的访问、修改甚至是删除

* Django 的 ORM 系统自动规避了 SQL 注入攻击

* 原始 SQL 语句，切记避免拼接字符串，这是错误的调用方式：

  ```python
  query = 'select * from employee where name = %s' % name
  Person.objects.raw(query)
  ```

* 正确的调用方式， 使用参数绑定：

  ```python
  name_map = {'first': 'first_name', 'last': 'last_name', 'bd': 'birth_date', 'pk': 'id'}
  >>> Person.objects.raw('select * from ecployee', translations=name_map)
  ```

  
