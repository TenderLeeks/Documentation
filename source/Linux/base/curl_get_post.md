# curl 命令模拟POST/GET请求

1. 发送GET请求

   请求格式：`curl http://ip:port/url?args=xxx&args1=xxxx`

2. 发送POST请求

   请求格式：`curl -H 请求头 -d 请求体 -X POST http://ip:port/url`

   参数说明：

   - -H (或者 --header)：请求头，格式：`“Content-Type: application/json”`
   - -d：POST内容，格式：{"name":"abc","passwd":"aaa123"}或者"name=abc&passwd=aaa123"
   - -X：请求协议，格式：POST、GET、DELETE、PUSH、PUT、OPTIONS、HEAD

   示例：

   - **application/x-www-form-urlencoded**

     最常见的一种 POST 请求，用 curl 发起这种请求也很简单

     ```shell
     $ curl -X POST -d "user=admin&passwd=abcd" http://127.0.0.1:8000/login
     ```

   - **application/json**

     跟发起 `application/x-www-form-urlencoded` 类型的 POST 请求类似，-d 参数值是 `JSON 字符串`，并且多了一个 `Content-Type: application/json` 指定发送内容的格式。

     ```shell
     $ curl -H "Content-Type: application/json" -X POST -d '{"name": "admin", "passwd":"abcd"}' http://127.0.0.1:8000/login
     ```

   - **multipart/form-data**

     这种请求一般涉及到文件上传。后端对这种类型请求的处理也复杂一些。

     ```shell
     $ curl -F raw=@raw.data -F name=admin http://127.0.0.1:8000/login
     ```

   - **把文件内容作为要提交的数据**

     如果要提交的数据不像前面例子中只有一个 `name: admin` 键值对，数据比较多，都写在命令行里很不方便，也容易出错，那么可以把数据内容先写到文件里，通过 `-d @filename` 的方式来提交数据。这是 `-d` 参数的一种使用方式，所以前面用到 `-d` 参数的地方都可以这样用。
     实际上就是把 `-d` 参数值写在命令行里，变成了写在文件里。跟 `multipart/form-data` 中上传文件的 `POST` 方式不是一回事。`@` 符号表明后面跟的是文件名，要读取这个文件的内容作为 `-d` 的参数。
     `data.json` 文件内容：

     ```json
     {
       "name":"admin",
       "passwd":"abcd"
     }
     ```

     请求方式：

     ```shell
     $ curl -H "Content-Type: application/json" -X POST -d @data.json http://127.0.0.1:8000/login
     ```

     