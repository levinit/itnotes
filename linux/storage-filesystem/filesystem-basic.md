# 文件类型

> linux为了实现一切皆文件的设计哲学，不仅将数据抽象成了文件，也将一切操作和资源抽象成了文件，比如说硬件设备，socket，磁盘，进程，线程等。

## 分区与文件系统

对分区进行格式化是为了在分区上建立文件系统。一个分区通常只能创建一个文件系统，磁盘阵列等技术可以在一个分区上创建多个文件系统。

## 组成

- inode：一个文件占用一个 inode，记录文件的属性，同时记录此文件的内容所在的 block 编号；

  inode 包含以下信息

  - 权限 (read/write/excute)；
  - 拥有者与群组 (owner/group)；
  - 容量；
  - 建立或状态改变的时间 (ctime)；
  - 最近一次的读取时间 (atime)；
  - 最近修改的时间 (mtime)；
  - 定义文件特性的旗标 (flag)，如 SetUID...；
  - 该文件真正内容的指向 (pointer)。

- block：记录文件的内容，文件太大时，会占用多个 block。

- superblock：记录文件系统的整体信息，包括 inode 和 block 的总量、使用量、剩余量，以及文件系统的格式与相关信息等；
- block bitmap：记录 block 是否被使用的位域。

## 目录

建立一个目录时，会分配一个 inode 与至少一个 block。block 记录的内容是目录下所有文件的 inode 编号以及文件名。

可以看出文件的 inode 本身不记录文件名，文件名记录在目录中，因此新增文件、删除文件、更改文件名这些操作与目录的 w 权限有关。



# ext4

 扩容：

```shell
e2fsck -f /dev/sdx

resize2fs /dev/sdx

#ext4根分区无损扩容（不可umount）

#modprobe，lsblk（个人决定这个可以没有）

resize2fs /dev/sdx

#reboot
```



