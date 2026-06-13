[TOC]

# 重要配置文件的备份

仅备份重要配置文件，用于重建系统并安装相应软件后轻松还原配置。

备份配置文件，可以从以下路径下筛选需要备份的配置：
**配置文件多以.conf或.ini或rc为文件名结尾**
- 多数配置在用户目录的.config/下

- 少数配置在家目录下  （如vim的配置文件~/.vimrc)

- 某些配置在/etc目录下（对改动过的文件才有备份意义，如nginx的配置文件，*一般*是/etc/nginx.conf和/etc/nginx/conf.d/，包管理器的设置和源，sudoers，enviroment……）

  其余位置**几乎**不需要备份配置。（当然根据具体情况而定，或许像grub主题文件/boot/grub/themes也有备份的需要）

备份文件时最保持原有的文件层级，方便还原。还原时复制相应的配置文件到相应的路径即可。

# 整个系统的备份和还原

整个系统的备份，用于迁移系统。

## dd

使用dd复制整个硬盘：｀dd if=/dev/sda of=/dev/sdb｀
if后面是要复制的位置，of后面是要写入的位置。dd命令使用无比小心确认写入位置，写入位置数据会被清空。

也可以加入sync参数来同步I/O，用bs参数指定block size（一个数据周期长度，理论上越大越快，但也有上限，设置了bs在进行还原时最好采用一致的值） `dd if=/dev/sda1 of=/dev/sdb bs=10M conv=noerror,sync`

使用dd复制分区并输出为镜像：`dd if＝/dev/sda/ of=/dev/sdb/backup.img`

dd还原系统时使用方法依然如上，if位置是备份所在位置，of位置是要写入的位置。

## tar

- 备份整个系统（这里使用bzip进行压缩，还可使用gzip，后缀.gz）：

  `tar dvpjf /path/backup.tar.bz2 /`

  不过一些目录没有备份的必要，如/tmp、/media等等，可使用--exclude参数排除目录：

  `tar dvpjf /path/backup.tar.bz2 --exclude=/tmp --exclude=/media /`

也可以建立一个排除文件，例如名为exclude，里面写入要排除的目录，一行一个，例如排除以下目录（后面均以该排除目录做説明）：

>  /proc/*
>  /dev/*
>  /sys/*
>  /run/*
>  /tmp/*
>  /mnt/*
>  /media/*
>  /var/*
>  /lost+found
>  /home/*
>  /boot/grub/grub.cfg
>  /etc/fstab
>  /root

建议排除用户家目录，家目录数据单独备份（到其他存储设备），因为家目录下可能排除目录太多比较麻烦，且家目录下存有**大量**用户数据（如音乐视频）的情况也不适合将其加进tar中，家目录中的配置文件（如.config）备份参考上文。当然家目录下的某些文件如firefox的插件文件等（在~/.mozilla）或许也有备份的必要。

root目录一般没有多大备份的必要，除非经常使用root用户操作，其目录下有不少重要的配置文件。



- tar利用排除文件进行备份示例：

  `tar cvpjf /path/backup.tar.bz2 --exclude-from=/path/exclude　/`

  excludefile即是是排除列表

  ​

- 还原示例：

  `tar xvpjf /path/backup.tar.bz2 /mnt/`

livecd中挂在根分区于/mnt；如果在系统中还原，则直接解压在/下。
boot挂载于根分区的/boot。

还原后注意事项：
- 更新fstab，执行`genfstab /etc/fstab`；

- 该备份使用了lvm，故而更改过/etc/mkinitcpio.conf，其中的HOOKS=这一行中添加了lvm2，如不使用lvm，删除了mkinitcpio.conf中HOOKS一行的lvm２，需要执行`mkinitcpio -p linux`；

- 更新grub(该文件已排除）`grub-config -o /boot/grub/grub.cfg`；

- 还原备份的家目录下的配置文件（如在tar备份时排除了家目录）……

  ​


