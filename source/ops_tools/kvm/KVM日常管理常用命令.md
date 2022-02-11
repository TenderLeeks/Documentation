# KVM日常管理常用命令

1. 查看、编辑及备份KVM 虚拟机配置文件 以及查看KVM 状态：

   - KVM 虚拟机默认的配置文件在 /etc/libvirt/qemu 目录下，默认是以虚拟机名称命名的.xml 文件，如下

     ```shell
     [root@localhost qemu]# ls /etc/libvirt/qemu/
     autostart ehs-jboss-01.xml ehs-jboss-02.xml ehs-mq-01.xml ehs-mq-02.xml ehs-oracle-01.xml ehs-oracle-02.xml networks
     ```

   - KVM 虚拟机配置文件的修改。可以使用vi 或 vim 命令进行编辑修改，但不建议。正确的做法为 virsh edit KVM-NAME：

     ```shell
     [root@localhost qemu]# virsh edit ehs-oracle-01
     ```

   - 备份KVM 虚拟机配置文件，先创建一个备份目录：

     ```shell
     [root@localhost qemu]# mkdir /data/kvmback
     [root@localhost qemu]# virsh dumpxml ehs-oracle-01 > /data/kvmback/ehs-oracle-01_back.xml
     ```

   - 正在运行的KVM 虚拟机的状态可以用virsh list 查看：

     ```shell
     [root@localhost qemu]# virsh list
      Id 名称 状态
     ----------------------------------------------------
      10 ehs-jboss-02 running
      12 ehs-oracle-02 running
      13 ehs-mq-01 running
      14 ehs-mq-02 running
      15 ehs-jboss-01 running
      16 ehs-oracle-01 running
     ```

   - 查看全部的虚拟机状态则在virsh list 后面加参数 --all 即可：

     ```shell
     [root@localhost qemu]# virsh list --all
      Id 名称 状态
     ----------------------------------------------------
      10 ehs-jboss-02 running
      12 ehs-oracle-02 running
      13 ehs-mq-01 running
      14 ehs-mq-02 running
      15 ehs-jboss-01 running
      16 ehs-oracle-01 running
     ```

2. KVM 开关机，重启、强制断电、挂起、恢复、删除及随物理机启动而启动的设置：

   - KVM 虚拟机开启（启动）：

     ```shell
     [root@localhost qemu]# virsh start ehs-oracle-01
     域 ehs-oracle-01 已开始
     ```

   - 重启KVM 虚拟机。要想重启kvm 虚拟机，必须如2.3 ，先在kvm 虚拟机里面安装acpid 服务，并且启动设置为随机启动，否则使用virsh reboot 无效：

     ```shell
     [root@localhost qemu]# virsh reboot ehs-oracle-01
     域 ehs-oracle-01 正在被重新启动
     ```

   - KVM 虚拟机关机：

     ```shell
     [root@localhost qemu]# virsh shutdown ehs-mq-01
     域 ehs-mq-01 被关闭
     查看发现还是在运行
     [root@localhost qemu]# virsh list
      Id 名称 状态
     ----------------------------------------------------
      10 ehs-jboss-02 running
      12 ehs-oracle-02 running
      14 ehs-mq-02 running
      15 ehs-jboss-01 running
      16 ehs-oracle-01 running
     ```

     注：KVM 虚拟机默认是无法用virsh shutdown 进行关机的，如果要想使用该命令关机，则必须在kvm 虚拟机上安装acpid acpid-sysvinit 两个包，启动acpid 服务，并且加入随机启动，如下：

     ```shell
     [root@localhost qemu]# yum install -y acpid acpid-sysvinit
     [root@localhost qemu]# service acpid start
     启动 acpi 守护进程：[确定]
     [root@localhost qemu]# chkconfig --add acpid && chkconfig acpid on
     ```

     将虚拟机重启后，再使用virsh shutdown 即可关机：  

     ```shell
     [root@kvm ~ 13:45:11]#virsh shutdown snale2
     域 snale2 被关闭
     
     [root@kvm ~ 13:45:17]#virsh list --all
     Id 名称 状态
     ----------------------------------------------------
     4 snale running
     - snale2 关闭
     
     ```

   - 强制关机（强制断电）：

     ```shell
     [root@kvm ~ 13:48:07]#virsh list --all
      Id 名称 状态
     ----------------------------------------------------
      4 snale running
      - snale2 关闭
     
     [root@kvm ~ 13:48:16]#virsh destroy snale
     域 snale 被删除
     
     [root@kvm ~ 13:48:29]#virsh list --all
      Id 名称 状态
     ----------------------------------------------------
      - snale 关闭
      - snale2 关闭
     ```

   - 暂停（挂起）KVM 虚拟机：

     ```shell
     [root@kvm ~ 13:49:22]#virsh list
      Id 名称 状态
     ----------------------------------------------------
      6 snale running
     
     [root@kvm ~ 13:49:27]#virsh suspend snale
     域 snale 被挂起
     
     [root@kvm ~ 13:50:06]#virsh list
      Id 名称 状态
     ----------------------------------------------------
      6 snale 暂停
     ```

   - 恢复被挂起的 KVM 虚拟机：

     ```shell
     [root@kvm ~ 13:51:05]#virsh resume snale
     域 snale 被重新恢复
     
     [root@kvm ~ 13:51:20]#virsh list
      Id 名称 状态
     ----------------------------------------------------
      6 snale running
     ```

   - 删除KVM 虚拟机：

     ```shell
     [root@kvm ~] virsh undefine snale
     ```

     该方法只删除配置文件，磁盘文件未删除，相当于从虚拟机中移除。

   - KVM 设置为随物理机启动而启动（开机启动）：

     ```shell
     [root@kvm ~ 13:54:26]#virsh autostart snale
     域 snale标记为自动开始
     [root@kvm ~ 14:21:25]#virsh autostart --disable snale
     域 snale取消标记为自动开始
     ```

     

## KVM-Virsh指令详解

```shell
# 查看所有虚拟机状态
virsh list --all

# 启动 test 虚拟机
virsh start test

# 重启虚拟机
virsh reboot test

# 虚拟机处于paused暂停状态,一般情况下是被admin运行了virsh suspend才会处于这种状态,但是仍然消耗资源,只不过不被超级管理程序调度而已。
virsh suspend test

# 把虚拟机唤醒，使其恢复到running状态
virsh resume test

# 关闭指令，是虚拟机进入shutoff状态，系统提示虚拟机正在被关闭，却未必能成功
virsh shutdown test

# 强制关闭该虚拟机，但并非真的销毁该虚拟机，只是关闭而已。
virsh destroy test

# 将该虚拟机的运行状态存储到文件a中
virsh save test a

# 根据文件a恢复被存储状态的虚拟机的状态，即便虚拟机被删除也可以恢复（如果虚拟机已经被undefine移除，那么恢复的虚拟机也只是一个临时的状态，关闭后自动消失）
virsh restore a

# 移除虚拟机，虚拟机处于关闭状态后还可以启动，但是被该指令删除后不能启动。在虚拟机处于Running状态时，调用该指令，该指令暂时不生效，但是当虚拟机被关闭后，该指令生效移除该虚拟机，也可以在该指令生效之前调用define+TestKVM.xml取消该指令
virsh undefine test

# 根据文件定义虚拟机
virsh define file-name.xml 

# 修改TestKVM的配置文件，效果等于先dumpxml得到配置文件，然后vi xml，最后后define该xml文件(建议关机修改，修改完virsh define防止不生效)
virsh edit test

# 在-o后面为被克隆虚拟机名称，-n后克隆所得虚拟机名称，file为克隆所得虚拟机镜像存放地址。
# 克隆的好处在于，假如一个虚拟机上安装了操作系统和一些软件，那么从他克隆所得的虚拟机也有一样的系统和软件，大大节约了时间。
virt-clone -o test -n test01 –file   /data/test01.img  

# 创建快照
virsh snapshot-create-as test01 test02
```