# if语句

if 语句通过关系运算符判断表达式的真假来决定执行哪个分支。Shell 有三种 if ... else 语句：

- if ... fi 语句；
- if ... else ... fi 语句；
- if ... elif ... else ... fi 语句。

## if ... else 

if ... else 语句的语法：

```bash
if [ expression ]
then
   Statement(s) to be executed if expression is true
fi
```

如果 expression 返回 true，then 后边的语句将会被执行；如果返回 false，不会执行任何语句。
**最后必须以 fi 来结尾闭合 if**，fi 就是 if 倒过来拼写。
注意：**expression 和方括号([ ])之间必须有空格**，否则会有语法错误。

## if ... else ... fi 

if ... else ... fi 语句的语法：

```bash
if [ expression ]
then
   Statement(s) to be executed if expression is true
else
   Statement(s) to be executed if expression is not true
fi
```

如果 expression 返回 true，那么 then 后边的语句将会被执行；否则，执行 else 后边的语句。

## if ... elif ... fi 多分枝选择

if ... elif ... fi 语句可以对多个条件进行判断，语法为：

```bash
if [ expression 1 ]
then
   Statement(s) to be executed if expression 1 is true
elif [ expression 2 ]
then
   Statement(s) to be executed if expression 2 is true
elif [ expression 3 ]
then
   Statement(s) to be executed if expression 3 is true
else
   Statement(s) to be executed if no expression is true
fi
```

哪一个 expression 的值为 true，就执行哪个 expression 后面的语句；如果都为 false，那么不执行任何语句。

if ... else 语句也可以写成一行，用分号隔开，以命令的方式来运行

if ... else 语句也经常与 test 命令结合使用，test 命令用于检查某个条件是否成立，与方括号([ ])类似。  

```bash
 if test $[num1] -eq $[num2]
```

## 运算符

### 文件比较运算符

| 运算符                  | 描述                                   | 示例                                            |
| ----------------------- | -------------------------------------- | ----------------------------------------------- |
| -e filename             | 如果 filename 存在，则为真             | [ -e /var/log/syslog ]                          |
| -d filename             | 如果 filename 为目录，则为真           | [ -d /tmp/mydir ]                               |
| -f filename             | 如果 filename 为常规文件，则为真       | [ -f /usr/bin/grep ]                            |
| -L filename             | 如果 filename 为符号链接，则为真       | [ -L /usr/bin/grep ]                            |
| -r filename             | 如果 filename 可读，则为真             | [ -r /var/log/syslog ]                          |
| -w filename             | 如果 filename 可写，则为真             | [ -w /var/mytmp.txt ]                           |
| -x filename             | 如果 filename 可执行，则为真           | [ -L /usr/bin/grep ]                            |
| filename1 -nt filename2 | 如果 filename1 比 filename2 新，则为真 | [ /tmp/install/etc/services -nt /etc/services ] |
| filename1 -ot filename2 | 如果 filename1 比 filename2 旧，则为真 | [ /boot/bzImage -ot arch/i386/boot/bzImage ]    |

### 字符串比较运算符

请注意引号的使用，这是防止空格扰乱代码的好方法

| 运算符             | 描述                                 | 示例                            |
| ------------------ | ------------------------------------ | ------------------------------- |
| -z string          | 如果 string 长度为零，则为真         | [ -z "$myvar" ]                 |
| -n string          | 如果 string 长度非零，则为真         | [ -n "$myvar" ]                 |
| string1 = string2  | 如果 string1 与 string2 相同，则为真 | [ "$myvar" = "one two three" ]  |
| string1 != string2 | 如果 string1 与 string2 不同，则为真 | [ "$myvar" != "one two three" ] |

### 算术比较运算符

| 运算符        | 描述       | 示例             |
| ------------- | ---------- | ---------------- |
| num1 -eq num2 | 等于       | [ 3 -eq $mynum ] |
| num1 -ne num2 | 不等于     | [ 3 -ne $mynum ] |
| num1 -lt num2 | 小于       | [ 3 -lt $mynum ] |
| num1 -le num2 | 小于或等于 | [ 3 -le $mynum ] |
| num1 -gt num2 | 大于       | [ 3 -gt $mynum ] |
| num1 -ge num2 | 大于或等于 | [ 3 -ge $mynum ] |

### 结论

shell字符串比较、判断是否为数字

二元比较操作符,比较变量或者比较数字.注意数字与字符串的区别.

整数比较

```bash
-eq       等于,如:if [ "$a" -eq "$b" ]
-ne       不等于,如:if [ "$a" -ne "$b" ]
-gt       大于,如:if [ "$a" -gt "$b" ]
-ge       大于等于,如:if [ "$a" -ge "$b" ]
-lt       小于,如:if [ "$a" -lt "$b" ]
-le       小于等于,如:if [ "$a" -le "$b" ]
<       小于(需要双括号),如:(("$a" < "$b"))
<=       小于等于(需要双括号),如:(("$a" <= "$b"))
>       大于(需要双括号),如:(("$a" > "$b"))
>=       大于等于(需要双括号),如:(("$a" >= "$b"))
```

字符串比较

```bash
=       等于,如:if [ "$a" = "$b" ]

==       等于,如:if [ "$a" == "$b" ],与=等价
       注意:==的功能在[[]]和[]中的行为是不同的,如下:
       1 [[ $a == z* ]]    # 如果$a以"z"开头(模式匹配)那么将为true
       2 [[ $a == "z*" ]] # 如果$a等于z*(字符匹配),那么结果为true
       3
       4 [ $a == z* ]      # File globbing 和word splitting将会发生
       5 [ "$a" == "z*" ] # 如果$a等于z*(字符匹配),那么结果为true
       一点解释,关于File globbing是一种关于文件的速记法,比如"*.c"就是,再如~也是.
       但是file globbing并不是严格的正则表达式,虽然绝大多数情况下结构比较像.
       
!=       不等于,如:if [ "$a" != "$b" ]
       这个操作符将在[[]]结构中使用模式匹配.
       
<      小于,在ASCII字母顺序下.如:
       if [[ "$a" < "$b" ]]
       if [ "$a" \< "$b" ]
       注意:在[]结构中"<"需要被转义.
       
>       大于,在ASCII字母顺序下.如:
       if [[ "$a" > "$b" ]]
       if [ "$a" \> "$b" ]
       注意:在[]结构中">"需要被转义.
       具体参考Example 26-11来查看这个操作符应用的例子.
       
-z       字符串为"null".就是长度为0.

-n       字符串不为"null"
```

注意:

使用-n在[]结构中测试必须要用""把变量引起来.使用一个未被""的字符串来使用! -z或者就是未用""引用的字符串本身,放到[]结构中。虽然一般情况下可以工作,但这是不安全的.习惯于使用""来测试字符串是一种好习惯。



# case语句

case ... esac 与其他语言中的 switch ... case 语句类似，是一种多分枝选择结构。

```bash
case 值 in模式1)  #------->匹配值
    command1
    command2
    command3
    ;;  #------>break
模式2）
    command1
    command2
    command3
    ;;
*) # ------->相当于default
    command1
    command2
    command3
    ;;
esac  #----->结束标志
```

case工作方式如上所示。

- 取值后面必须为关键字 in，
- 每一模式必须以右括号结束
- 取值可以为变量或常数。
- 匹配发现取值符合某一模式后，其间所有命令开始执行直至 ;;。
- ;; 与其他语言中的 break 类似，意思是跳到整个 case 语句的最后。
- 取值将检测匹配的每一个模式。一旦模式匹配，则执行完匹配模式相应命令后不再继续其他模式。
- 如果无一匹配模式，使用星号 * 捕获该值，再执行后面的命令。



参考：

- http://c.biancheng.net/cpp/shell/