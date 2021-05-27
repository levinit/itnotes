1. 进入救援模式
   1. 在grub引导界面，按下`e`修改选项。

   2. 移动光标到启动项目一行（该行内容以类似`linux 16`开始）的最后，添加空格，再添加`rd.break`。

      或者添加`init=/sysroot/bin/sh`

   3. <kbd>ctrl</kbd> <kbd>x</kbd>完成修改，开始系统引导。

   4. `mount -o remount,rw /sysroot` 重新挂载`/sysroot`以使其可写。

   5. `chroot /sysroot` 更改根目录；

2. 修改密码
   1. `passwd root`或者其他修改命令修改密码；

      或清空`/etc/shadow`文件中root用户第二字段——第一个冒号和第二个冒号之间的内容。

   2. `touch /.autorelabel`  开启了SELinux的情况下必须执行该步骤；

   3. `exit`或<kbd>ctrl</kbd> <kbd>d</kbd>退出`chroot`；

   4. `exit`或<kbd>ctrl</kbd> <kbd>d</kbd>或`reboot`重启系统。