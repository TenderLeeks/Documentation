# shell几种字符串加密解密的方法

## Python 与 Bash Shell 的结合

这个命令会让你输入一个字符串，然后会再输出一串加密了的数字。

1. 加密代码[照直输入]

   ```shell
   $ python -c 'print reduce(lambda a,b: a*256+ord(b), raw_input("string: "), 0)'
   ```

2. 解密代码[数字后+P]

   ```shell
   $ dc -e 输出的数字P
   ```

   

## 应该是纯 Bash Shell，含 VIM 的 xxd

用 RCOSR8toZ7nF9Gyc 作为明文

1. 加密代码

   ```shell
   $ echo "RCOSR8toZ7nF9Gyc" |xxd -ps -u
   52434F535238746F5A376E46394779630A
   
   $ echo "ibase=16;52434F535238746F5A376E46394779630A" |bc
   27992624244640545969914199055074927928074
   ```

   一步加密代码

   ```shell
   $ echo "ibase=16; $(echo "RCOSR8toZ7nF9Gyc" |xxd -ps -u)" |bc
   27992624244640545969914199055074927928074
   ```

2.  解密代码

   ```shell
   $ dc -e 27992624244640545969914199055074927928074P
   RCOSR8toZ7nF9Gyc
   ```

   

## Base64 编码，这个很好很强大，适合写加密脚本

同样用 RCOSR8toZ7nF9Gyc 作为明文，来看代码：

1. 加密代码

   ```shell
   $ echo "RCOSR8toZ7nF9Gyc" |base64 -i
   Z3RhbGtAZ21haWwuY29tCg==
   ```

2. 解密代码

   ```shell
   $ echo "Z3RhbGtAZ21haWwuY29tCg==" |base64 -d
   RCOSR8toZ7nF9Gyc
   ```

   