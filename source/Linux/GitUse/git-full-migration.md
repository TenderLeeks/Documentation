# git仓库完整迁移

1. 克隆git的版本库

   ```shell
   $ git clone --bare <源库>
   ```

2. 去目标仓库设置，将Protect保护去掉

   gitlab->group->newtest.com->点击设置->Protected branches

3. 以镜像推送的方式上传代码到gitlab服务器上

   ```shell
   $ git push --mirror <目标库>
   ```

4. 注意事项

   * git仓库迁移前，目标仓库需要先创建，且为空
   * 需要事先将仓库的protect权限去掉，否则在git push的时候会报错

