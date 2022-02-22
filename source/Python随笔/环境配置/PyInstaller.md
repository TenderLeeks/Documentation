# PyInstaller

## 简介

PyInstaller可以用来打包python应用程序，打包完的程序就可以在没有安装Python解释器的机器上运行了。PyInstaller支持Python 2.7和Python 3.3+。可以在Windows、Mac OS X和Linux上使用，但是并不是跨平台的，而是说你要是希望打包成.exe文件，需要在Windows系统上运行PyInstaller进行打包工作；打包成mac app，需要在Mac OS上使用。



## 安装更新

```shell
# 安装
$ pip install pyinstaller -i https://pypi.tuna.tsinghua.edu.cn/simple
...
Successfully installed altgraph-0.17.2 macholib-1.15.2 pyinstaller-4.9 pyinstaller-hooks-contrib-2022.2

# 更新
$ pip install --upgrade pyinstaller -i https://pypi.tuna.tsinghua.edu.cn/simple

# Windows上运行PyInstaller还需要PyWin32或者pypiwin32，其中pypiwin32在你安装PyInstaller的时候会自动安装。
```

## 使用

PyInstaller分析你的python程序，找到所有的依赖项。然后将依赖文件和python解释器放到一个文件夹下或者一个可执行文件中。

1. 打包成一个文件夹

   当使用PyInstaller打包的时候，默认生成一个文件夹，文件夹中包含所有依赖项，以及可执行文件。打包成文件夹的好处就是debug的时候可以清楚的看到依赖项有没有包含。另一个好处是更新的时候，只需要更新可执行文件就可以了。当然缺点也很明显，不方便，不易管理。

   ```shell
   $ pyinstaller script.py
   ```

   那么它是如何工作的呢？PyInstaller的引导程序是一个二进制可执行程序。当用户启动你的程序的时候，PyInstaller的引导程序开始运行，首先创建一个临时的Python环境，然后通过Python解释器导入程序的依赖，当然他们都在同一个文件夹下。

2. 打包成一个文件

   我们可以用 `--onefile` 或者 `-F` 参数将所有文件打包到一个可执行文件中。

   ```shell
   $ pyinstaller -F script.py
   ```

   打包成一个文件相对于文件夹更容易管理。坏处运行相对比较慢。这个文件中包含了压缩的依赖文件拷贝（.so文件）。

   当程序运行时，PyInstaller的引导程序会新建一个临时文件夹。然后解压程序的第三方依赖文件到临时文件夹中。这也是为什么一个可执行文件比文件夹中执行的时间要长的原因。剩下的就和上面的一样了。

3. spec 文件

   当你执行下面命令

   ```shell
   $ pyinstaller options..script.py
   ```

   PyInstaller首先建一个sepc(specification)文件：script.spec。这个文件的存放地址可以使用参数–specpath= 来定义，默认放在当前文件夹下。

   spec文件的作用是什么呢？它会告诉PyInstaller如何处理你的py文件，它会将你的py文件名字和输入的大部分参数进行编码。PyInstaller通过执行spec文件中的内容来生成app，有点像makefile。正常使用中我们是不需要管spec文件的，但是下面几种情况需要修改spec文件：

   - 需要打包资源文件
   - 需要include一些PyInstaller不知道的run-time库
   - 为可执行文件添加run-time 选项
   - 多程序打包

   可以通过下面命令生成spec文件

   ```shell
   $ pyi-makespec options script.py [other scripts ...]
   ```

   修改完spec文件，就可以通过下面命令来生成app文件了

   ```shell
   $ pyinstaller options script.spec
   ```

   当通过spec文件来生成app文件的时候只有下面几个参数是有用的：

   - `–upx-dir=`
   - `–distpath=`
   - `–noconfirm=`
   - `–ascii`

4. spec 文件解析

   ```python
   # -*- mode: python ; coding: utf-8 -*-
   
   block_cipher = None
   a = Analysis(['script.py'],
                pathex=[],
                binaries=[],
                datas=[],
                hiddenimports=[],
                hookspath=[],
                hooksconfig={},
                runtime_hooks=[],
                excludes=[],
                win_no_prefer_redirects=False,
                win_private_assemblies=False,
                cipher=block_cipher,
                noarchive=False)
   pyz = PYZ(a.pure, a.zipped_data,
                cipher=block_cipher)
   exe = EXE(pyz,
             a.scripts,
             a.binaries,
             a.zipfiles,
             a.datas,  
             [],
             name='script',
             debug=False,
             bootloader_ignore_signals=False,
             strip=False,
             upx=True,
             upx_exclude=[],
             runtime_tmpdir=None,
             console=True,
             disable_windowed_traceback=False,
             target_arch=None,
             codesign_identity=None,
             entitlements_file=None )
   coll = COLLECT(...)
   ```

   spec文件中主要包含4个class: `Analysis`, `PYZ`, `EXE`和`COLLECT`。

   - `Analysis` 以py文件为输入，它会分析py文件的依赖模块，并生成相应的信息
   - `PYZ` 是一个.pyz的压缩包，包含程序运行需要的所有依赖
   - `EXE` 根据上面两项生成
   - `COLLECT` 生成其他部分的输出文件夹，COLLECT也可以没有

5. 修改spec文件

   我们上面说过有时候PyInstaller自动生成的spec文件并不能满足我们的需求，最常见的情况就是我们的程序依赖我们本地的一些数据文件，这个时候就需要我们自己去编辑spec文件来添加数据文件了。
   上面的spec文件解析中Analysis中的datas就是要添加到项目中的数据文件，我们可以编辑datas.

   ```python
   a = Analysis(
       ...
       datas = [('you/source/file/path','file_name_in_project'),
       ('source/file2', 'file_name2')]
       ...
       )
   ```

   可以认为datas是一个List,每个元素是一个二元组。元组的第一个元素是你本地文件索引，第二个元素是拷贝到项目中之后的文件名字。除了上面那种写法，也可以将其提出来。

   ```python
   added_files = [...]
   
   a = Analysis(
       ...
       datas = added_files,
       ...
       )
   ```

   其他的二进制文件添加方法类似。

6. 总结

   最后简单来说，我们要通过PyInstaller生成可执行的文件主要下面两步。

   ```shell
   $ pyinstaller [option] mypython.py
   ```

   option为空生成文件夹，选择onefile，生成一个文件。
   如果项目有一些依赖的数据文件，上面生成的二进制文件是无法运行的，这个时候可以通过修改spec文件，让后再用pyinstaller运行spec文件。

   ```shell
   $ pyinstaller [option] mypython.spec
   ```

   当然也按上文那样先生成spec文件。

## Pyinstaller解释

```shell
usage: pyinstaller [-h] [-v] [-D] [-F] [--specpath DIR] [-n NAME] [--add-data <SRC;DEST or SRC:DEST>] [--add-binary <SRC;DEST or SRC:DEST>] [-p DIR] [--hidden-import MODULENAME] [--collect-submodules MODULENAME] [--collect-data MODULENAME] [--collect-binaries MODULENAME] [--collect-all MODULENAME] [--copy-metadata PACKAGENAME] [--recursive-copy-metadata PACKAGENAME] [--additional-hooks-dir HOOKSPATH] [--runtime-hook RUNTIME_HOOKS] [--exclude-module EXCLUDES] [--key KEY] [--splash IMAGE_FILE] [-d {all,imports,bootloader,noarchive}] [--python-option PYTHON_OPTION] [-s] [--noupx] [--upx-exclude FILE] [-c] [-w] [-i <FILE.ico or FILE.exe,ID or FILE.icns or "NONE">] [--disable-windowed-traceback] [--version-file FILE] [-m <FILE or XML>] [--no-embed-manifest] [-r RESOURCE] [--uac-admin] [--uac-uiaccess] [--win-private-assemblies] [--win-no-prefer-redirects] [--osx-bundle-identifier BUNDLE_IDENTIFIER] [--target-architecture ARCH] [--codesign-identity IDENTITY] [--osx-entitlements-file FILENAME] [--runtime-tmpdir PATH] [--bootloader-ignore-signals] [--distpath DIR] [--workpath WORKPATH] [-y] [--upx-dir UPX_DIR] [-a] [--clean] [--log-level LEVEL] scriptname [scriptname ...]


位置参数：
  scriptname            # 要处理的脚本文件的名称或恰好是一个 .spec 文件。 如果指定了 .spec 文件，则大多数选项都是不必要的并被忽略。

可选参数：
  -h, --help            # 显示此帮助信息并退出
  -v, --version         # 显示程序版本信息并退出。
  --distpath DIR        # 捆绑应用程序的放置位置（默认：./dist）
  --workpath WORKPATH   # 将所有临时工作文件、.log、.pyz 等放在哪里（默认：./build）
  -y, --noconfirm       # 替换输出目录（默认：SPECPATH/dist/SPECNAME）而不要求确认
  --upx-dir UPX_DIR     # UPX 实用程序的路径（默认：搜索执行路径）
  -a, --ascii           # 不包括 unicode 编码支持（默认：如果可用，包括在内）
  --clean               # 在构建之前清理 PyInstaller 缓存并删除临时文件。
  --log-level LEVEL     # 构建时控制台消息中的详细信息量。 LEVEL 可以是 TRACE、DEBUG、INFO、WARN、ERROR、CRITICAL 之一（默认值：INFO）。

生成什么：
  -D, --onedir          # 创建一个包含可执行文件的单文件夹包（默认）
  -F, --onefile         # 创建一个单一文件捆绑的可执行文件。
  --specpath DIR        # 存放生成的spec文件的文件夹（默认：当前目录）
  -n NAME, --name NAME  # 分配给捆绑的应用程序和规范文件的名称（默认值：第一个脚本的基本名称）

What to bundle, where to search:
  --add-data <SRC;DEST or SRC:DEST>
                        # 要添加到可执行文件的其他非二进制文件或文件夹。 路径分隔符是特定于平台的，使用 ``os.pathsep``（在 Windows 上是 ``;`` 而在大多数 unix 系统上是 ``:``）。 此选项可以多次使用。
  --add-binary <SRC;DEST or SRC:DEST>
                        # 要添加到可执行文件的附加二进制文件。 有关更多详细信息，请参见 --add-data 选项。 此选项可以多次使用。
  -p DIR, --paths DIR   # 搜索导入的路径（例如使用 PYTHONPATH）。 允许多个路径，由 ``':'`` 分隔，或多次使用此选项。 等效于在规范文件中提供 ``pathex`` 参数。
  --hidden-import MODULENAME, --hiddenimport MODULENAME
                        # 命名在脚本代码中不可见的导入。 此选项可以多次使用。
  --collect-submodules MODULENAME
                        # 从指定的包或模块中收集所有子模块。 此选项可以多次使用。
  --collect-data MODULENAME, --collect-datas MODULENAME
                        # 从指定的包或模块中收集所有数据。 此选项可以多次使用。
  --collect-binaries MODULENAME
                        # 从指定的包或模块中收集所有二进制文件。 此选项可以多次使用。
  --collect-all MODULENAME
                        # 从指定的包或模块中收集所有子模块、数据文件和二进制文件。 此选项可以多次使用。
  --copy-metadata PACKAGENAME
                        # 复制指定包的元数据。 此选项可以多次使用。
  --recursive-copy-metadata PACKAGENAME
                        # 复制指定包及其所有依赖项的元数据。 此选项可以多次使用。
  --additional-hooks-dir HOOKSPATH
                        # 搜索钩子的附加路径。 此选项可以多次使用。
  --runtime-hook RUNTIME_HOOKS
                        # 自定义运行时挂钩文件的路径。 运行时挂钩是与可执行文件捆绑在一起的代码，在任何其他代码或模块之前执行以设置运行时环境的特殊功能。 此选项可以多次使用。
  --exclude-module EXCLUDES
                        # 将被忽略的可选模块或包（Python 名称，而不是路径名称）（就好像它没有找到一样）。 此选项可以多次使用。
  --key KEY             # 用于加密 Python 字节码的密钥。
  --splash IMAGE_FILE   # (EXPERIMENTAL) 将带有图像 IMAGE_FILE 的启动画面添加到应用程序。 启动画面可以在解包时显示进度更新。
```



[参考文档](http://legendtkl.com/2015/11/06/pyinstaller/)

