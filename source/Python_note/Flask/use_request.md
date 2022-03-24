# Flask request 用法

对于 Web 应用，与客户端发送给服务器的数据交互至关重要。在 Flask 中由全局的 request 对象来提供这些信息，比如说GET在url后面追加参数、POST在body中带参数、又或者是POST的表单提交方式，这时候就需要从`request`里提取出参数。

## 常用属性和方法

<table  border="1" cellpadding="10" cellspacing="10">
  <thead>
    <tr>
      <th>属性</th>
      <th>用途</th>
      <th>类型</th>
    </tr>
  </thead>
    <tbody>
    <tr><td>data</td><td>记录请求的数据，并转化成字符串</td><td>*</td></tr>
    <tr><td>form</td><td>记录请求中的表单数据</td><td>MultiDict</td></tr>
    <tr><td>args</td><td>记录url中的查询参数</td><td>MultiDict</td></tr>
    <tr><td>cookies</td><td>记录请求中的cookies信息</td><td>Dict</td></tr>
    <tr><td>headers</td><td>记录请求中的报文头</td><td>EnvironHeaders</td></tr>
    <tr><td>method</td><td>记录请求使用的HTTP方法</td><td>GET/POST/…</td></tr>
    <tr><td>files</td><td>记录请求上传的文件</td><td>*</td></tr>
    <tr><td>url</td><td>记录请求的URL地址</td><td>string</td></tr>
  </tbody>
</table>

## 请求对象

request请求对象封装了从客户端发来的请求报文信息，我们能从request对象上获取请求报文中的所有数据。 其大部分功能是由依赖包Werkzeug完成的，Flask 做了一些特定功能的封装，形成了request请求对象。

```python
from flask import request

@app.route('/user', methods=['GET', 'POST'])
def user():
  if request.method == 'POST':
      user_name = request.form['user_name']
      return 'user :{} add success!'.format(user_name)
  else:
      user_id = request.args.get('user_id', 0)
      return 'Hello user:{}!'.format(user_id)
```

request对象中的method变量可以获取当前请求的方法，即GET、POST、PUT、DELETE等；form变量获取POST请求form-data表单中的数据，本质是一个字典，如果提交的表单中没有user_name，则会返回 400 Bad Request 的错误，当然也可以使用异常捕获机制处理。request.args.get()方法获取的是GET请求的url中的参数（问号?之后的部分），第一个参数指定获取的 url 参数的 key，第二个参数指定默认值，当 key 不存在时，则返回默认值。

- `url`：请求的 url
- `args`：获得url中携带的params(参数)，与传输方式（GET or POST）无关。有时候POST请求也会将参数加入到url中，这种情况下也可以得到args属性。使用args解析后也是ImmutableMultiDict(一键多值字典)类型。
- `blueprint`：当前蓝本的名称
- `cookies`：返回请求的cookies，类型为dict。
- `data`：包含请求的数据，并转化成字符串，除非是Flask无法处理的mimetype。
- `endpoint`：于当前请求相匹配的端点值
- `files`：获取上传的文件流，可以获得一个文件对象，并保存本地。
- `form`：从POST或者PUT请求中解析表单数据。如果GET请求将表单数据编码到url里面，而不是放在表单中传输过来的信息，则不能使用form捕捉。使用form解析后是ImmutableMultiDict(一键多值字典)类型。
- `values`：类型为CombinedMultiDict，结合了 args 和 form 属性的值，可以通过values代替form和args。
- `get_data(cache=True,as_text=False,parse_from_data=False)`：获取请求中的数据，默认读取为字节字符串（bytestring），as_text为True则返回解码后的unicode字符串
- `get_json(self,force=False,silent=False,cache=True)`：作为 json 解析并返回数据，如果 MIME 类型不是 json，返回 None（除非 force 设为 True）；解析出错则抛出Werkzeug提供的 BadRequest 异常（如果未开启调试模式，则返回400错误响应），如果 silent 设为 True 则返回 None；cache 设置是否缓存解析后的 json 数据
- `headers`：返回请求头，为字典类型。
- `json`：如果请求的mimetype是application/json，那么这个参数将会解析json数据，如果不是将会返回None，可以代替上面的get_json()方法。
- `method`：获取请求方法，GET或者POST或者其他。
- `referrer`：请求发起的源 url，即 referer
- `scheme`：请求的URL模式（http 或 https）
- `user_agent`：用户代理（User Agent），包含了用户的客户端类型，操作系统类型等信息

`request.args` 与 `request.form` 的区别:

- `request.args` 是获取url中的参数

- `request.form` 是获取form表单中的参数

请求url为：`http://www.baidu.com/leeks/index.html?id=1` 参数内容如下：

<table  border="1" cellpadding="10" cellspacing="10">
  <thead>
    <tr>
      <th>名称</th>
      <th>显示内容</th>
    </tr>
  </thead>
    <tbody>
    <tr><td>path</td><td>./index.html</td></tr>
    <tr><td>script_root</td><td>/leeks</td></tr>
    <tr><td>base_url</td><td>http://www.baidu.com/leeks/index.html</td></tr>
    <tr><td>url</td><td>http://www.baidu.com/leeks/index.html?id=1</td></tr>
    <tr><td>url_root</td><td>http://www.baidu.com/leeks/</td></tr>
  </tbody>
</table>

## 示例

```python
from flask import Flask, request
 
app = Flask(__name__)
 
# http://127.0.0.1:8000/index?name=leeks&id=1
@app.run("/index", methods=["GET","POST"])
def index():
    # request中包含了前端发来的所有请求数据
    # request.form可以直接提取请求体中的表达格式的数据，是一个类字典的对象
    # request.form["name"] # 通常不是有这种方式提取参数，因为如果前端没有传这参数程序就会报错,为了程序健壮性通常使用get方式获取
    # 通过get方法只能拿到多个重名参数的第一个
    name = request.form.get("name")
    id = request.form.age("id")
    # 获取同名参数,将名为name的参数全部提取到一个列表中
    name_list = request.form.getlist("name")
    # 提出url中的参数（查询字符串）
    name = request.args.get("name")
    # 如果前端传数据全部是表单数据，那么data里面不会有内容
    # 如果发来的是json格式数据那么就会在data请求体中出现，在form中就不会有数据
    print(request.data)
    return "hello name=%s, id=%s" % (name, id)
 

@app.route("/post", methods=["GET","POST"])
def post():
    name = request.args.get("name")
    print(request.data)
    return "hello name=%s" % (name)


@app.route("/upload", methods=["GET","POST"])
def upload():
    f = request.files.get("pic")
    if f is None:
        # 没有发送文件
        return "未上传文件"
    # 直接使用上传的文件对象保存
    f.save("./ex.jpg")
    return "上传成功"


if __name__ == '__main__':
    app.run(host = '0.0.0.0', port = 8000, debug = True)
```

