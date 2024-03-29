# shell 介绍

## shell简介

`shell`是用户和Linux内核之间的一层代理，解释用户输入的命令，传递给内核。

shell是一种脚本语言（解释性语言）。

Shell既是一种命令语言，又是一种程序设计语言。作为命令语言，它交互式地解释和执行用户输入的命令；作为程序设计语言，它定义了各种变量和参数，并提供了许多在高级语言中才具有的控制结构，包括循环和分支。

**Shell有两种执行命令的方式：**

- 交互式（Interactive）：解释执行用户的命令，用户输入一条命令，Shell就解释执行一条。
- 批处理（Batch）：用户事先写一个Shell脚本(Script)，其中有很多条命令，让Shell一次把这些命令执行完，而不必一条一条地敲命令。

Shell脚本和编程语言很相似，也有变量和流程控制语句，但Shell脚本是解释执行的，不需要编译，Shell程序从脚本中一行一行读取并执行这些命令，相当于一个用户把脚本中的命令一行一行敲到Shell提示符下执行。

Unix/Linux上常见的Shell脚本解释器有bash、sh、csh、ksh等，习惯上把它们称作一种Shell。

程序设计语言可以分为两类：编译型语言和解释型语言。

### 编译型语言

很多传统的程序设计语言，例如Fortran、Ada、Pascal、C、C++和Java，都是编译型语言。这类语言需要预先将我们写好的源代码(source code)转换成目标代码(object code)，这个过程被称作“编译”。运行程序时，直接读取目标代码(object code)。由于编译后的目标代码(object code)非常接近计算机底层，因此执行效率很高，这是编译型语言的优点。

编译型语言多半运作于底层，所处理的是字节、整数、浮点数或是其他机器层级的对象，往往实现一个简单的功能需要大量复杂的代码。

### 解释型语言

有的语言（例如： Shell、JavaScript、Python、PHP等）需要一边执行一边翻译，不会产生任何可执行文件，用户需要拿到源码才能运行程序。程序运行后会即时翻译，翻译一部分执行一部分，并不用等所有代码翻译完。

这个过程叫`解释`，这类语言叫`解释型语言`或`脚本语言`，完成解释过程的软件叫`解释器`。



解释型语言也被称作“脚本语言”。因为每次执行程序都多了编译的过程，因此效率有所下降。

 使用脚本编程语言的好处是，它们多半运行在比编译型语言还高的层级，能够轻易处理文件与目录之类的对象；缺点是它们的效率通常不如编译型语言。

脚本编程语言的例子有awk、Perl、Python、Ruby与Shell。

## 常见的Shell类型

| shell类型 | 说明                                                         |
| --------- | ------------------------------------------------------------ |
| sh        | sh 是 UNIX 上的标准 shell，很多 UNIX 版本都配有 sh。         |
| bash      | bash shell 是 Linux 的默认 shell，bash 兼容 sh，但并不完全一致。 |
| csh       | 语法有点类似C语言。                                          |
| ...       |                                                              |

### 查看shell

```bash
$ cat /etc/shells
/bin/sh
/bin/bash
/sbin/nologin
/usr/bin/sh
/usr/bin/bash
/usr/sbin/nologin
/bin/tcsh
/bin/csh
```

查看默认shell

```bash
$ echo $SHELL
/bin/bash
```

sh 一般被 bash 代替，`/bin/sh`往往是指向`/bin/bash`的符号链接。

```bash
$ ls -l /bin/sh
lrwxrwxrwx. 1 root root 4 Mar  8  2018 /bin/sh -> bash
```

## 使用shell场景

之所以要使用Shell脚本是基于：

- 简单性：Shell是一个高级语言；通过它，你可以简洁地表达复杂的操作。
- 可移植性：使用POSIX所定义的功能，可以做到脚本无须修改就可在不同的系统上执行。
- 开发容易：可以在短时间内完成一个功能强大又妤用的脚本。



但是，考虑到Shell脚本的命令限制和效率问题，下列情况一般不使用Shell：

1. 资源密集型的任务，尤其在需要考虑效率时（比如，排序，hash等等）。
2. 需要处理大任务的数学操作，尤其是浮点运算，精确运算，或者复杂的算术运算（这种情况一般使用C++或FORTRAN 来处理）。
3. 有跨平台（操作系统）移植需求（一般使用C 或Java）。
4. 复杂的应用，在必须使用结构化编程的时候（需要变量的类型检查，函数原型，等等）。
5. 对于影响系统全局性的关键任务应用。
6. 对于安全有很高要求的任务，比如你需要一个健壮的系统来防止入侵、破解、恶意破坏等等。
7. 项目由连串的依赖的各个部分组成。
8. 需要大规模的文件操作。
9. 需要多维数组的支持。
10. 需要数据结构的支持，比如链表或数等数据结构。
11. 需要产生或操作图形化界面 GUI。
12. 需要直接操作系统硬件。
13. 需要 I/O 或socket 接口。
14. 需要使用库或者遗留下来的老代码的接口。
15. 私人的、闭源的应用（shell 脚本把代码就放在文本文件中，全世界都能看到）。

## shell脚本

打开文本编辑器，新建一个文件，扩展名为sh（sh代表shell），扩展名并不影响脚本执行，见名知意就好，如果你用php写shell 脚本，扩展名就用php好了。

输入一些代码：

```bash
#!/bin/bash
echo "Hello World !"
```

**“#!” 是一个约定的标记，它告诉系统这个脚本需要什么解释器来执行，即使用哪一种Shell**。echo命令用于向窗口输出文本。

## 运行shell

运行Shell脚本有两种方法。

### 作为可执行程序

将上面的代码保存为test.sh，并 cd 到相应目录：

```bash
chmod +x ./test.sh  #使脚本具有执行权限
./test.sh  #执行脚本
```

注意，一定要写成./test.sh，而不是test.sh。运行其它二进制的程序也一样，直接写test.sh，linux系统会去PATH里寻找有没有叫test.sh的，而只有/bin, /sbin, /usr/bin，/usr/sbin等在PATH里，你的当前目录通常不在PATH里，所以写成test.sh是会找不到命令的，要用./test.sh告诉系统说，就在当前目录找。

### 作为解释器参数

这种运行方式是，直接运行解释器

```bash
# 使用 sh 解释器
sh test.sh
# 使用 bash 解释器
bash test.sh
```

这种方式运行的脚本，不需要在第一行指定解释器信息，写了也没用。



参考：

-  http://c.biancheng.net/cpp/shell/