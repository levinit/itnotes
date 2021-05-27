# kernel panic

- 较新的cpu

  尝试使用较新版本内核（甚至不稳定版）



# kernel crash

- kdump启动失败报错No memory reserved for crash kernel

  ```shell
  systemctl status kdump
  ```

  > Starting Crash recovery kernel arming...
  > kdumpctl[913]: No memory reserved for crash kernel

  提示没[为崩溃内核保留内存](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/kernel_administration_guide/kernel_crash_dump_guide)，默认情况下crashkernel保留内存值为auto，也可将其修改为一个确切的值（如128M）。

  *值为auto时根据实际物理内存情况保留一些内存给kernelcrash用，在x86_64系统中内存大于等于2GB时会保留内存。最小保留内存计算方法：160 MB + 2 bits for every 4 KB of RAM。*

  1. 修改`/etc/default/grub`的`GRUB_CMDLINE_LINUX`行中的`crashkernel`的值：

     ```shell
     GRUB_CMDLINE_LINUX="crashkernel=128M console=ttyS0 console=tty0 panic=5 net.ifnames=0 biosdevname=0"
     ```

     某些系统需要设置一定的保留内存偏移量，写法如下：

     ```shell
     crashkernel=128M@16M
     ```

  2. 重新生成grub

     ```shell
     grub-mkconfig -o /boot/grub/grub.cfg 
     #某些发行版如centos中命令可能为grub2-mkconfig
     #grub2-mkconfig -o /boot/grub/grub.cfg 
     ```

# lockup

- cpu soft lockup

  ```shell
  echo 30 > /proc/sys/kernel/watchdog_thresh
  sudo sysctl -a|grep watchdog
  sysctl -w kernel.watchdog_thresh=30
  ```



# coredump

