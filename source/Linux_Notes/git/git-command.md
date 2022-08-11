# Git 命令简单使用

## 常见的 Git 命令

```tex
开始一个工作区（参见：git help tutorial）
   clone             克隆仓库到一个新目录
   init              创建一个空的 Git 仓库或重新初始化一个已存在的仓库

在当前变更上工作（参见：git help everyday）
   add               添加文件内容至索引
   mv                移动或重命名一个文件、目录或符号链接
   restore           恢复工作区文件
   rm                从工作区和索引中删除文件
   sparse-checkout   初始化及修改稀疏检出

检查历史和状态（参见：git help revisions）
   bisect            通过二分查找定位引入 bug 的提交
   diff              显示提交之间、提交和工作区之间等的差异
   grep              输出和模式匹配的行
   log               显示提交日志
   show              显示各种类型的对象
   status            显示工作区状态

扩展、标记和调校您的历史记录
   branch            列出、创建或删除分支
   commit            记录变更到仓库
   merge             合并两个或更多开发历史
   rebase            在另一个分支上重新应用提交
   reset             重置当前 HEAD 到指定状态
   switch            切换分支
   tag               创建、列出、删除或校验一个 GPG 签名的标签对象

协同（参见：git help workflows）
   fetch             从另外一个仓库下载对象和引用
   pull              获取并整合另外的仓库或一个本地分支
   push              更新远程引用和相关的对象
```

## 版本回退

```shell
# 查看提交记录
$ git log --pretty=oneline
$ git log --graph --pretty=oneline --abbrev-commit

# 上一个版本是HEAD^，上上一个版本是HEAD^^，当然往上100个版本写100个^比较容易数不过来，所以写成HEAD~100
$ git reset --hard HEAD^

# 根据 commit id 到指定版本
$ git reset --hard e475afc93

# 查看历史命令
$ git reflog
```

## 修改文件

```shell
# 查看工作区和版本库里面最新版本的区别
$ git diff HEAD -- file-name

# 丢弃工作区的修改，就是让文件回到最近一次git commit或git add时的状态
$ git checkout -- file-name

# 把暂存区的修改撤销掉（unstage），重新放回工作区
$ git reset HEAD file-name

```

## 删除文件

```shell
$ git rm file-name

# 恢复误删除问题
$ git checkout -- file-name
```

## 关联远程库

```shell
# 关联远程 github 库
$ git remote add origin git@github.com/TenderLeeks/Documentation.git

# 把本地库内容推送到远程
$ git push -u origin master

# 查看远程库信息
$ git remote -v

# 删除远程库 origin：名称
$ git remote rm origin
```

第一次推送`master`分支时，加上了`-u`参数，Git不但会把本地的`master`分支内容推送的远程新的`master`分支，还会把本地的`master`分支和远程的`master`分支关联起来，在以后的推送或者拉取时就可以简化命令。

## 克隆远程库

```shell
$ git clone git@github.com/TenderLeeks/Documentation.git
```

## 分支管理

```shell
# 查看分支
$ git branch

# 创建分支
$ git branch <name>

# 切换分支
$ git checkout <name>
# 或者
$ git switch <name>

# 创建+切换分支
$ git checkout -b <name>
# 或者
$ git switch -c <name>

# 合并某分支到当前分支
$ git merge <name>

# 删除分支
$ git branch -d <name>

# 使用 --no-ff 参数合并分支，--no-ff 参数表示禁用Fast forward
$ git merge --no-ff -m "merge with no-ff" dev
# 本次合并要创建一个新的commit，所以加上-m参数，把commit描述写进去

# 查看分支历史
$ git log --graph --pretty=oneline --abbrev-commit

```

合并分支时，加上`--no-ff`参数就可以用普通模式合并，合并后的历史有分支，能看出来曾经做过合并，而`fast forward`合并就看不出来曾经做过合并。

```shell
# 把当前工作现场“储藏”起来，等以后恢复现场后继续工作
$ git stash

# 查看储存的stash
$ git stash list

# 恢复stash
$ git stash apply

# 删除stash
$ git stash drop

# 恢复并删除
$ git stash pop

# 恢复指定的stash
$ git stash apply stash@{0}

```



```shell
# 从本地推送分支，如果推送失败，先用git pull抓取远程的新提交
$ git push origin branch-name

# 在本地创建和远程分支对应的分，本地和远程分支的名称最好一致
$ git checkout -b branch-name origin/branch-name

# 建立本地分支和远程分支的关联
$ git branch --set-upstream branch-name origin/branch-name
```



```shell
$ git rebase
# rebase 操作可以把本地未push的分叉提交历史整理成直线
# rebase 的目的是使得我们在查看历史提交的变化时更容易，因为分叉的提交需要三方对比
```

## 标签管理

```shell
# 查看标签
$ git tag

# 历史提交的 commit id 创建标签
$ git tag v0.9 f52c633

# 注意，标签不是按时间顺序列出，而是按字母排序的。

# 查看标签信息
$ git show v0.9

# 创建带有说明的标签，用-a指定标签名，-m指定说明文字
$ git tag -a v0.1 -m "version 0.1 released" 1094adb

# 删除标签
$ git tag -d v0.1
# 推送标签到远程
$ git push origin v1.0

# 一次性推送全部尚未推送到远程的本地标签
$ git push origin --tags

# 删除远程标签
$ git tag -d v0.9
$ git push origin :refs/tags/v0.9

```

## 使用GitHub参与开源项目开发

首先需要在开源的仓库中`Fork` 到自己账号下，修改完后，使用`pull request`提交修改到开源仓库；

## 自定义Git

```shell
# Git显示颜色
$ git config --global color.ui true

```

### 忽略特殊文件

在Git工作区的根目录下创建一个特殊的`.gitignore`文件，然后把要忽略的文件名填进去，Git就会自动忽略这些文件。

忽略文件的原则是：

- 忽略操作系统自动生成的文件，比如缩略图等；

- 忽略编译生成的中间文件、可执行文件等，也就是如果一个文件是通过另一个文件自动生成的，那自动生成的文件就没必要放进版本库，比如Java编译产生的`.class`文件；

- 忽略你自己的带有敏感信息的配置文件，比如存放口令的配置文件。

发现`.gitignore`写得有问题，需要找出来到底哪个规则写错了，可以用`git check-ignore`命令检查：

```shell
$ git check-ignore -v file-name
```

编写规则：

```shell
# 排除所有.开头的隐藏文件:
.*
# 排除所有.class文件:
*.class

# 不排除.gitignore和App.class:
!.gitignore
!App.class
```

### 配置别名

```shell
# 以 git st 表示 git status
$ git config --global alias.st status

# 用 co 表示 checkout，ci 表示 commit，br 表示 branch
$ git config --global alias.co checkout
$ git config --global alias.ci commit
$ git config --global alias.br branch

# 配置一个git last，让其显示最后一次提交信息
$ git config --global alias.last 'log -1'

git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

```

- `--global`参数是全局参数，也就是这些命令在这台电脑的所有Git仓库下都有用。
- 配置Git的时候，加上`--global`是针对当前用户起作用的，如果不加，那只针对当前的仓库起作用。
- 每个仓库的Git配置文件都放在`.git/config`文件中。
- 当前用户的Git配置文件放在用户主目录下的一个隐藏文件`.gitconfig`中。

## 命令扩展

```shell
$ git help -a
执行　'git help <command>' 来查看特定子命令

主要的上层命令
   add                  添加文件内容至索引
   am                   应用邮箱格式的系列补丁
   archive              基于一个指定的树创建文件存档
   bisect               通过二分查找定位引入 bug 的提交
   branch               列出、创建或删除分支
   bundle               通过归档移动对象和引用
   checkout             切换分支或恢复工作区文件
   cherry-pick          应用一些现存提交引入的修改
   citool               git-commit 的图形替代界面
   clean                从工作区中删除未跟踪文件
   clone                克隆仓库到一个新目录
   commit               记录变更到仓库
   describe             基于一个现存的引用为一个对象起一个可读的名称
   diff                 显示提交之间、提交和工作区之间等的差异
   fetch                从另外一个仓库下载对象和引用
   format-patch         准备电子邮件提交的补丁
   gc                   清除不必要的文件和优化本地仓库
   gitk                 Git 仓库浏览器
   grep                 输出和模式匹配的行
   gui                  一个便携的 Git 图形客户端
   init                 创建一个空的 Git 仓库或重新初始化一个已存在的仓库
   log                  显示提交日志
   maintenance          运行任务以优化仓库数据
   merge                合并两个或更多开发历史
   mv                   移动或重命名一个文件、目录或符号链接
   notes                添加或检查对象注释
   pull                 获取并整合另外的仓库或一个本地分支
   push                 更新远程引用和相关的对象
   range-diff           比较两个提交范围（如一个分支的两个版本）
   rebase               在另一个分支上重新应用提交
   reset                重置当前 HEAD 到指定状态
   restore              恢复工作区文件
   revert               回退一些现存提交
   rm                   从工作区和索引中删除文件
   shortlog             'git log' 输出摘要
   show                 显示各种类型的对象
   sparse-checkout      初始化及修改稀疏检出
   stash                贮藏脏工作区中的修改
   status               显示工作区状态
   submodule            初始化、更新或检查子模组
   switch               切换分支
   tag                  创建、列出、删除或校验一个 GPG 签名的标签对象
   worktree             管理多个工作区

辅助命令/操作者
   config               获取和设置仓库或者全局选项
   fast-export          Git 数据导出器
   fast-import          Git 快速数据导入器后端
   filter-branch        重写分支
   mergetool            运行合并冲突解决工具以解决合并冲突
   pack-refs            打包头和标签以实现高效的仓库访问
   prune                删除对象库中所有不可达对象
   reflog               管理 reflog 信息
   remote               管理已跟踪仓库
   repack               打包仓库中未打包对象
   replace              创建、列出、删除对象替换引用

辅助命令/询问者
   annotate             使用提交信息注释文件行
   blame                显示文件每一行最后修改的版本和修改者
   bugreport            收集信息以供用户提交错误报告
   count-objects        计算未打包对象的数量和磁盘空间占用
   difftool             使用常见的差异工具显示更改
   fsck                 验证仓库中对象的连通性和有效性
   gitweb               Git web 界面（Git 仓库的 web 前端）
   help                 显示 Git 的帮助信息
   instaweb             在 gitweb 中即时浏览您的工作仓库
   merge-tree           显示三路合并而不动索引
   rerere               重用冲突合并的解决方案记录
   show-branch          显示分支和提交
   verify-commit        检查 GPG 提交签名
   verify-tag           检查标签的 GPG 签名
   whatchanged          显示每一个提交引入的差异日志

与其它系统交互
   archimport           将一个 GNU Arch 仓库导入到 Git
   cvsexportcommit      将一个提交导出到 CVS 检出中
   cvsimport            从另外一个人们爱恨的配置管理系统中拯救你的数据
   cvsserver            Git 的一个 CVS 服务模拟器
   imap-send            从标准输入将一组补丁发送到IMAP文件夹
   p4                   导入和提交到 Perforce 仓库中
   quiltimport          将一个 quilt 补丁集应用到当前分支。
   request-pull         生成待定更改的摘要
   send-email           通过电子邮件发送一组补丁
   svn                  Subersion 仓库和 Git 之间的双向操作

低级命令/操作者
   apply                应用一个补丁到文件和/或索引区
   checkout-index       从索引拷贝文件到工作区
   commit-graph         写入和校验 Git 提交图文件
   commit-tree          创建一个新的提交对象
   hash-object          从一个文件计算对象 ID，并可以创建 blob 数据对象
   index-pack           从一个现存的包存档文件创建包索引
   merge-file           运行一个三路文件合并
   merge-index          对于需要合并的文件执行合并
   mktag                创建一个标签对象
   mktree               基于 ls-tree 的格式化文本创建一个树对象
   multi-pack-index     写入和校验多包索引
   pack-objects         创建对象的存档包
   prune-packed         删除已经在包文件中的多余对象
   read-tree            将树信息读取到索引
   symbolic-ref         读取、修改和删除符号引用
   unpack-objects       从打包文件中解压缩对象
   update-index         将工作区的文件内容注册到索引
   update-ref           安全地更新存储于引用中的对象名称
   write-tree           从当前索引创建一个树对象

低级命令/询问者
   cat-file             提供仓库对象的内容、类型或大小
   cherry               查找尚未应用到上游的提交
   diff-files           比较工作区和索引区中的文件
   diff-index           将一个树和工作区或索引做比较
   diff-tree            比较两个树对象的文件内容和模式
   for-each-ref         对每一个引用输出信息 
   get-tar-commit-id    从 git-archive 创建的归档文件中提取提交 ID
   ls-files             显示索引和工作区中文件的信息
   ls-remote            显示一个远程仓库的引用
   ls-tree              显示一个树对象的内容
   merge-base           为了合并查找尽可能好的公共祖先提交
   name-rev             查找给定版本的符号名称
   pack-redundant       查找冗余的包文件
   rev-list             按时间顺序列出提交对象
   rev-parse            选出并处理参数
   show-index           显示打包归档索引
   show-ref             显示本地仓库中的引用
   unpack-file          用 blob 数据对象的内容创建一个临时文件
   var                  显示一个Git逻辑变量
   verify-pack          校验打包的Git存仓文件

低级命令/同步仓库
   daemon               一个非常简单的 Git 仓库服务器
   fetch-pack           从另一个仓库获取缺失的对象
   http-backend         Git HTTP 协议的服务端实现
   send-pack            使用 Git 协议推送对象到另一个仓库
   update-server-info   更新辅助信息文件以帮助哑协议服务

低级命令/内部助手
   check-attr           显示 gitattributes 信息
   check-ignore         调试 gitignore / exclude 文件
   check-mailmap        显示联系人的规范名称和电子邮件
   check-ref-format     确保引用名称格式正确
   column               以列的方式显示数据
   credential           检索和存储用户密码
   credential-cache     在内存中临时存储密码的助手
   credential-store     在磁盘存储密码的助手
   fmt-merge-msg        生成一个合并提交信息
   interpret-trailers   添加或解析提交说明中的结构化信息
   mailinfo             从单个电子邮件中提取补丁和作者身份
   mailsplit            简单的 UNIX mbox 邮箱切分程序
   merge-one-file       与 git-merge-index 一起使用的标准向导程序
   patch-id             计算一个补丁的唯一 ID
   sh-i18n              为 shell 脚本准备的 Git 国际化设置代码
   sh-setup             常用的 Git shell 脚本设置代码
   stripspace           删除不必要的空白字符

外部命令
   cz

$ git help -g

Git 概念向导有：
   attributes          定义路径的属性
   cli                 Git 命令行界面和约定
   core-tutorial       面向开发人员的 Git 核心教程
   credentials         为 Git 提供用户名和口令
   cvs-migration       适合 CVS 用户的 Git 帮助
   diffcore            调整差异输出
   everyday            每一天 Git 的一组有用的最小命令集合
   faq                 关于使用 Git 的常见问题
   glossary            Git 词汇表
   hooks               Git 使用的钩子
   ignore              忽略指定的未跟踪文件
   modules             定义子模组属性
   namespaces          Git 名字空间
   remote-helpers      与远程仓库交互的助手程序
   repository-layout   Git 仓库布局
   revisions           指定 Git 的版本和版本范围
   submodules          将一个仓库安装到另外一个仓库中
   tutorial            一个 Git 教程
   tutorial-2          一个 Git 教程：第二部分
   workflows           Git 推荐的工作流概览
```

参考[文档](https://www.liaoxuefeng.com/wiki/896043488029600)