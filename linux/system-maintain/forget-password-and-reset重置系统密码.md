如果忘记了root密码，也没有任何可用的具有sudo权限的用户，可使用以下方法重置密码。

# LiveCD

1. 启动LiveCD

2. mount系统根分区，例如：

   ```shell
   mount -o /dev/sda2 /mnt
   ```

3. 重置密码，可选择以下方法

   - passwd指定分区挂载点

     ```shell
     #passwd --root <根分区挂载点> 用户名
     passwd --root /mnt root
     ```

   - chroot到根分区挂载点后直接修改

     ```shell
     chroot /mnt
     passwd
     ```

   - 修改根分区挂载目录中的etc/passwd和etc/shadow文件

     以root用户为例

     - 将passwd文件中root行第1个和第2个`:`间内容改成`x`
     - 将shadow文件中root行第1个和第2个`:`间内容删除

4. 卸载并正常重启



# 单用户模式

1. 在grub引导界面，按下`e`修改选项（进入nano编辑器）。

2. 移动光标到包含`vmlinuz`的最后，添加空格，再添加`rd.break`

   或者添加`init=/sysroot/bin/sh`

3. <kbd>ctrl</kbd> <kbd>x</kbd>完成修改，开始系统引导。

4. 进入系统后执行`mount -o remount,rw /sysroot` 重新挂载`/sysroot`以使其可写。

5. `chroot /sysroot` 更改根目录；

1. 修改密码
   1. `passwd root`或者其他修改命令修改密码；

      或清空`/etc/shadow`文件中root用户第二字段——第一个冒号和第二个冒号之间的内容。

   2. `touch /.autorelabel`  开启了SELinux的情况下必须执行该步骤；

   3. `exit`或<kbd>ctrl</kbd> <kbd>d</kbd>退出`chroot`；

   4. `exit`或<kbd>ctrl</kbd> <kbd>d</kbd>或`reboot`重启系统。