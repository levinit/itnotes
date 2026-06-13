提示：

- 要重装的设备需要能连接到互联网，如果其不能连接到互联网，可在其所处的局域网中搭建私有源，同时搭建web服务器如apache/nginx，挂载（mount）DVD镜像到web根目录下。
- 内存过小可能无法成功（centos实测1G内存失败）


1. ssh登录到该设备

2. 下载引导文件

3. 下载`vmlinuz`和`initrd.img`放置于`/boot`目录下

   - 不同的发行版，这两个文件可能略有出入（例如可能是`vmlinz-linux`和`initramfs-linux.img`）。
   - 这两个文件可以从镜像源网站中直接获取，或者从下载的系统镜像文件中提取。
   - 给予`initrd.img`600权限，`vmlinuz`755权限。

4. 修改grub启动项

   1. 制作grub启动项

      查看`grub.cfg`文件（可能是`/etc/grub.cfg`、`/etc/grub2/grub.cfg`、`/boot/grub/grub.cfg`等）。

      找到`### BEGIN /etc/grub.d/10_linux ###`行下的`menuentry `项，复制该部分，在`/etc/grub.d/40_custom`文件中添加上文复制的内容，作出部分修改（大部分内容可省略，注意下面注释的部分是重要部分），示例：

      ```shell
      #预留足够长的时间保证有时间连上去进行操作
      set timeout=60
      menuentry "remote reinstall" {
              set root=(hd0,msdos1)  #与第1步中查看到内容要一致
              # 设置repo地址 vncpassword ip gateway nameserver
              linux /vmlinuz repo=http://mirrors.aliyun.com/centos/7/os/x86_64/ vnc vncpassword=password ip=192.168.100.3 netmask=255.255.255.0 gateway=192.168.100.1 nameserver=192.168.100.1 noselinux headless xfs panic=60
              initrd /initrd.img
      }
      ```

      提示：

      - 获取ip  `ip addr`
      - 获取gateway  `arp -a`或`ip route`
      - 获取nameserver `cat /etc/resolv.conf`

   2. 修改grub默认启动项

      在`/etc/default/grub`修改或添加`GRUB_DEFAULT="remote reinstall"`，然后重新生成grub.cfg：

      ```shell
      grub2-mkconfig -o /boot/grub2/grub.cfg  #注意grub.cfg路径正确
      ```
      提示：不同的发行版，该命令和grub文件路径或有不同，例如命令可能为`grub-mkconfig`， 路径可能为`/boot/grub/grub.cfg`。

   3. 重启系统`reboot`，系统会自动从上面配置的`remote install`项目启动。

      估计安装程序已经启动完毕，尝试使用vnc连接（上文设置的vnc地址：`172.18.229.218:5901`，密码`password`），进行系统安装操作即可。

----

使用iso文件 以archlinux为例

下载镜像到根目录下命名为arch.iso

在grub.cfg中添加启动项

```shell
#timeout设为60,是为了VNC连接时有足够时间选择启动项，若为第一启动项，可不设置
set timeout=60
menuentry 'ArchISO' --class iso {
  #isofile是系统镜像iso文件的绝对路径
  set isofile=/arch.iso
  loopback loop0 $isofile
  #archisolabel设置archiso文件驻留的文件系统标签。
  #img_dev指明archiso文件驻留的设备
  #img_loop是archiso文件在img_dev里的绝对位置
  linux (loop0)/arch/boot/x86_64/vmlinuz archisolabel=ARCH20181201 img_dev=/dev/vda1 img_loop=$isofile
  initrd (loop0)/arch/boot/x86_64/archiso.img
}
```

