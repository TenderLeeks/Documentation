# 上传文件

## 上传到本地目录

1. 配置文件定义上传文件路径

   ```python
   MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
   ```

2. 文件上传对象的属性和方法

   <table border="1" cellpadding="10" cellspacing="10">
     <thead>
       <tr><th>名称</th><th>说明</th></tr>
     </thead>
       <tbody>
       <tr><td>file.name</td><td>获取上传的名称</td></tr>
       <tr><td>file.size</td><td>获取上传文件的大小（字节）</td></tr>
       <tr><td>file.read()</td><td>读取全部（适用于小文件）</td></tr>
       <tr><td>file.chunks()</td><td>按块来返回文件，通过for循环进行迭代，可以将大文件安装块来写入到服务器</td></tr>
       <tr><td>file.multiple_chunks()</td><td>判断文件是否大于2.5M 返回True或者False</td></tr>
     </tbody>
   </table>

3. `urls.py` 增加路由

   ```python
   urlpatterns = [
       path('upload/', views.handle_upload, name='upload'),
   ]
   ```

4. `views.py` 文件内容

   ```python
   from django.conf import settings
   from django.http import HttpResponse
   from django.shortcuts import render
   
   def handle_upload(request):
       if request.method == "POST":
           fobj = request.FILES.get('photo')
           # 使用自定义文件上传类
           path = settings.MDEIA_ROOT
           from upload.utils import FileUpload
           fp = FileUpload(fobj)
           if fp.upload(path):
               return HttpResponse("文件上传成功")
       return render(request, 'xxx.html')
   ```

5. 封装文件上传类

   可以自定义一个类实现文上传，文件上传类可以：

   - 检查文件类型
   - 检查文件大小
   - 是否生成随机文件名

6. `utils.py` 文件内容

   ```python
   import os
   from datetime import datetime
   from random import randint
   
   
   class FileUpload:
       def __init__(self, file, exts=('png', 'jpg', 'jpeg'), size=1024*1024, is_random_name=False):
           """
           :param file: 文件上传对象
           :param exts: 文件类型
           :param size: 文件大小，默认1M
           :param is_random_name: 是否是随机文件名，默认是否
           """
           self.file = file
           self.exts = exts
           self.size = size
           self.is_random_name = is_random_name
   
       # 文件上传
       def upload(self, dest):
           """
           :param dest: 文件上传的目标目录
           :return:
           """
           # 1 判断文件类型是否匹配
           if not self.check_type():
               return -1
           # 2 判断文件大小是否符合要求
           if not self.check_size():
               return -2
           # 3 如果是随机文件名，要生成随机文件名
           if self.is_random_name:
               file_name = self.random_name()
           else:
               file_name = self.file.name
           # 4 拼接目标文件路径
           path = os.path.join(dest, file_name)
           # 5 保存文件
           self.write_file(path)
           return 1
   
       def check_type(self):
           ext = os.path.splitext(self.file.name)  # 获取文件后缀
           if len(ext) > 1:
               ext = ext[1].lstrip('.')
               if ext in self.exts:
                   return True
           return False
   
       def check_size(self):
           if self.size < 0:
               return False
           # 如果文件大小小于给定的大小，返回True，否则返回False
           return self.file.size <= self.size
   
       def random_name(self):
           filename = datetime.now().strftime("%Y%m%d%H%M%S")+str(randint(1, 10000))
           ext = os.path.splitext(self.file.name)
           # 获取文件后缀
           ext = ext[1] if len(ext) > 1 else ''
           filename += ext
           return filename
   
       def write_file(self, path):
           with open(path, 'wb') as fp:
               if self.file.multiple_chunks():
                   for chunk in self.file.chunks():
                       fp.write(chunk)
               else:
                   fp.write(self.file.read())
   ```

   

## 上传到腾讯云COS

1. `upload.py` 文件内容

   ```python
   from qcloud_cos import CosConfig, CosServiceError
   from qcloud_cos import CosS3Client
   from django.conf import settings
   from django.http import HttpResponse
   from django.shortcuts import render
   
   import os
   import sys
   import logging
   
   logging.basicConfig(level=logging.INFO, stream=sys.stdout)
   config = CosConfig(Region=settings.COS_REGION, SecretId=settings.COS_SECRET_ID, SecretKey=settings.COS_SECRET_KEY,
                      Token=None)
   client = CosS3Client(config)
   logger = logging.getLogger(__name__)
   
   
   def index_app(request):
       return render(request, 'myadmin/upload/upload.html')
   
   
   def upload_app(request):
       cos_name = request.POST['cos_name']
       app_env = request.POST['app_env']
   
       if cos_name == '0':
           logger.warning("没有选择存储桶类型")
           return HttpResponse("没有选择存储桶类型")
       elif app_env == '0':
           logger.warning("没有选择APP版本包类型")
           return HttpResponse("没有选择APP版本包类型")
       else:
           cos_bucket_name = None
           cos_url = None
           cos_path = None
           for i in settings.COS_BUCKET_NAME:
               if int(cos_name) == i[0]:
                   cos_bucket_name = i[1]
                   cos_url = i[2]
           for j in settings.COS_PATH:
               if int(app_env) == j[0]:
                   cos_path = j[1]
   
       app_name = request.FILES.get("upload", None)  # 根据表单name获取文件信息
       if not app_name:
           logger.warning("没有选择APP版本包信息")
           return HttpResponse("没有选择APP版本包信息")
   
       filename = request.FILES["upload"].name  # 获取文件名
       root_path = os.path.join(settings.MEDIA_ROOT, 'upload_app')  # 生成文件上传目录
       if not os.path.exists(root_path):  # 判断文件上传目录是否存在
           os.makedirs(root_path)  # 不存在，则创建
   
       file_path = os.path.join(root_path, filename)
       destination = open(os.path.join(root_path, filename), 'wb+')
       for chunk in app_name.chunks():  # 分块写入文件
           destination.write(chunk)
       destination.close()
       try:
           response = client.upload_file(
               Bucket=cos_bucket_name,
               LocalFilePath=file_path,  # 本地图片路径
               Key=cos_path + filename,  # 上传路径
               ACL='public-read',
               PartSize=10,
               MAXThread=10,
               EnableMD5=False
           )
           context = {}
           if response['ETag'] != "":
               os.remove(file_path)  # 上传成功，删除本地图片
               logger.info(f"upload path: {cos_bucket_name}/{cos_path}, URL: {cos_url}, APP name: {filename}, 上传成功")
               context = {'info': f'上传成功！URL: {cos_url}{cos_path}{filename}'}
       except CosServiceError as e:
           logger.error(f"{e.get_digest_msg()}, 上传失败")
           context = {'info': f'上传失败！error: {e.get_digest_msg()}'}
   
       return render(request, "myadmin/info.html", context)
   ```

2. `urls.py` 文件内容

   ```python
   from django.conf.urls import url
   from django.urls import path
   from dev_ystar_app import upload
   
   urlpatterns = [
       path('upload/', upload.index_app, name='upload'),  # 上传图片至腾讯云COS
       path('upload/app/', upload.upload_app, name="upload_app"),
   ]
   ```

3. `upload.html` 模板内容

   ```html
   <h3>
       上传 APP
   </h3>
   <form id="edit-profile" action="{% url 'upload_app' %}" class="form-horizontal" method="post"
         enctype="multipart/form-data">
       {% csrf_token %}
   
       <fieldset>
           <legend>上传 APP</legend>
   
           <div class="control-group">
               <div class="controls">
                   <label class="control-label" for="cos_name">* 存储桶类型：</label>
                   <select name="cos_name" id="cos_name" onChange="change()">
                       <option value="0">--请选择--</option>
                       <option value="1">Ystar</option>
                       <option value="2">Bingoo</option>
                   </select>
               </div>
           </div>
   
           <div class="control-group">
               <div class="controls">
                   <label class="control-label" for="app_env">* APP类型：</label>
                   <select name="app_env" id="app_env">
                       <option value="0">--请选择--</option>
                   </select>
               </div>
           </div>
   
           <div class="control-group">
               <div class="controls">
                   <label class="control-label" for="upload">* APP版本包：</label>
                   <input type="file" name="upload" class="input-xlarge" id="upload"/>
               </div>
           </div>
           <div class="form-actions">
               <button type="submit" class="btn btn-primary">上传</button>
               <button type="reset" class="btn">重置</button>
           </div>
       </fieldset>
   </form>
   
   
   <script>
   function change()
   {
      var x = document.getElementById("cos_name");
      var y = document.getElementById("app_env");
      y.options.length = 0; // 清除second下拉框的所有内容
         if(x.selectedIndex == 0)
      {
      		y.options.add(new Option("--请选择--", "0", false, true));  // 默认选中
      }
   
      if(x.selectedIndex == 1)
      {
      		y.options.add(new Option("Ystar Android Dev", "1", false, true));  // 默认选中
   		y.options.add(new Option("Ystar Android Prod", "2"));
      }
   
      if(x.selectedIndex == 2)
      {
      		y.options.add(new Option("Bingoo Android Dev", "3", false, true));  // 默认选中
   		y.options.add(new Option("Bingoo IOS Dev", "4"));
   		y.options.add(new Option("Bingoo Android Prod", "5"));
   		y.options.add(new Option("Bingoo IOS Prod", "6"));
      }
   }
   </script>
   
   
   ```

   