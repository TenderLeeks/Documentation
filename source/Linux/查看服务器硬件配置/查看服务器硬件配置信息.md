# 查看服务器硬件配置信息

1. 查看物理CPU的个数

   ```shell
   $ grep -c "physical id" /proc/cpuinfo |sort |uniq
   ```

2. 查看逻辑CPU的个数

   ```shell
   $ grep -c "processor"  /proc/cpuinfo
   ```

3. 查看CPU是几核

   ```shell
   $ grep "cores" /proc/cpuinfo | uniq
   ```

4. 查看CPU的主频

   ```shell
   $ grep MHz /proc/cpuinfo |uniq
   ```

5. 查看cpu型号

   ```shell
   $ grep name  /proc/cpuinfo | cut -f2 -d: | uniq -c
   ```

6. 查看操作系统内核信息

   ```shell
   $ uname -a
   ```

7. 查看当前操作系统发行版信息

   ```shell
   $ grep Linux /etc/issue
   ```

8. 查看cpu几颗几核

   ```shell
   $ grep physical /proc/cpuinfo | uniq -c
   ```

9. cpu运行模式

   ```shell
   $ getconf LONG_BIT
   # 输出 64 或 32
   # 64 说明当前CPU运行在64bit模式下
   # 32 说明当前CPU运行在32bit模式下, 但不代表CPU不支持64bit
   
   $ grep "flags" /proc/cpuinfo| grep -c 'lm'
   4
   # 结果大于0, 说明支持64bit计算. lm指long mode, 支持lm则是64bit
   ```

10. 每个物理CPU中Core的个数

    ```shell
    $ grep -c "cpu cores" /proc/cpuinfo
    ```

11. 查看CPU信息命令

    ```shell
    $ cat /proc/cpuinfo
    ```

12. 查看内存信息命令

    ```shell
    $ cat /proc/meminfo
    ```

13. 查看硬盘信息命令

    ```shell
    $ fdisk -l
    ```

14. 查看内存

    ```shell
    free -m
    ```

    



