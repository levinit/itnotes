# 查看挂载设备信息

## mtab已挂载设备列表

`/etc/mtab`记录了当前系统已挂载的分区（**m**ounted file systems **tab**le），每次挂载/卸载分区时会更新/etc/mtab文件。

```shell
cat /etc/mtab | column -t  #用column -t表格化处理更容易阅读
```

解决系统挂载问题时可以参看该文件，获取挂载信息。



## 获取分区信息lsblk和挂载信息df

```shell
lsblk                     #将输出NAME  FSTYPE  LABEL  UUID  MOUNTPOINT 信息
lsblk -o name,uuid,label  #指定输出NAME UUID LABEL

df -h
```

>```shell
>$ lsblk -f
>NAME   FSTYPE LABEL UUID                                 MOUNTPOINT
>sda                                                      
>├─sda1 vfat         D409-0125                            /boot/efi
>├─sda2 ext4         2bd78210-021f-4133-9d91-3837018010f6 /boot
>├─sda3 swap         d362fe17-006b-41ac-8c18-0632ab99c281 [SWAP]
>└─sda4 ext4         bcbaa227-e973-4dcb-8c2f-2cdad1f264e3 /
>sdb    ext4   DATA  01b08ad6-5f6e-4eb8-af37-690e30680a10 /storage
>
>$ df -h 
>Filesystem      Size  Used Avail Use% Mounted on
>udev            414M     0  414M   0% /dev
>tmpfs            86M  656K   86M   1% /run
>/dev/vda1        50G   17G   31G  36% /
>```

- NAME：内核中为文件系统的命名，实际存放在`/dev`下，如`/dev/sdb`
- FSTYPE：文件系统类型
- LABEL：卷标名
- UUID：该文件系统唯一的ID值
- MOUNTPOINT：文件系统挂载点



# mount挂载和umount卸载

具体使用参看相关文档。

mount示例：

```shell
#mount <fs-source>  <dir>
mount /dev/sdc /mnt    #不指定文件类型直接挂载（系统可识别时会自动处理）

#mount -t <fs-type> <fs-source> <dir>
mount -t nfs ioserver:/share /share  #使用-t指定类型

#挂载回环文件（如.img镜像文件，iso镜像文件，光盘驱动器）
mount -o loop /dev/sr0 /mnt    #一般不指定参数直接挂载，系统也能智能识别

#使用uuid挂载|可使用lsblk -o name,uuid 查看每个文件系统的uuid值
mount UUID=<UUID> <dir>
mount -U <UUID> <dir>

#使用label挂载
mount -L <label> <dir>
mount LABEL=<label> <dir>
```

更多`-o`的参数可参看后文[fstab](#/etc/fstab)

umount示例：

```shell
#mount <mounted-point>
umount /mnt
#-fl组合使用卸载 强制卸载并使用懒卸载模式（分离文件系统但等到该文件系统不再繁忙时清理各种对其的引用)
umount  -fl /mnt  #-f或--force  -l或--lazy 懒卸载模式
```



# /etc/fstab

`/etc/fstab`多用于启动时自动挂载，但随着systemd的发展，现在一些linux发行版有逐渐使用systemd接管部分fstab挂载的文件系统的趋势，最多见的是不少发行版的tmpfs不再存在于`/etc/fstab`中。

```shell
#要挂载的分区或存储设备    挂载点     文件系统类型     选项        是否备份   是否检查
# <file system>        <dir>      <type>       <options>    <dump>    <pass>
```

- `<file systems> `  ：要挂载的分区或存储设备

  可以使用以下方式表示：

  - 内核名称
  - UUID
  - label

  在BIOS 中改变了存储设备顺序，或是重新拔插了存储设备，可能会随机地改变存储设备的顺序，那么用 UUID 或是 label 来表示将更有效。

  

- `<dir>` ：挂载位置

  

- `<type>`：要挂载设备或是分区的文件系统类型

  设置成`auto`类型，mount 命令会猜测使用的文件系统类型（对 CDROM 和 DVD 等移动设备是非常有用）

  `cat /proc/filesystems`可查看支持的文件系统

  

- `<options>`： 挂载时使用的参数

  例如（注意：**有些参数是特定文件系统才有效的**）：

  - `defaults`： 使用文件系统的默认挂载参数，`rw suid dev exec auto nouser async`

    注意：所有默认挂载选项的实际集合取决于内核和文件系统类型

    其中`auto`表示系统启动后自动挂载。

  - `noexec`：禁止在此文件系统执行二进制文件

  - `noatime`： 不更新文件系统上 inode 访问记录，可以提升性能（但是失去了时间信息）

  - `ro`、`rw`：只读和读写

  - `size`：指定大小

    对于tmpfs比较有用，例如默认的tmpfs较小，一些软件编译时需要的tmpfs空间不够，可以指定更大的size：

    ```shell
    tmpfs /tmp      tmpfs nodev,nosuid,size=6G          0 0
    ```

  - `nofail`：设备不存在时忽略报错（部分文件系统有效）

  - `_netdev`：声明该文件系统是一个网络设备，只有网络就绪后才挂载

    **对于挂载网络文件系统比较有用**（避免网络尚未就绪时挂载而引起挂载失败）

  - `noauto`：只能显式挂载，即`mount -a`不会自动挂载

    一般和`x-systemd.automount`合用，使得文件系统不开机自动挂载，但在需要使用时自动挂载。

  - `x-systemd.automount`：只在需要访问时才会挂载

    注意：该参数会使得文件系统类型被识别为 `autofs`，造成 [mlocate](https://wiki.archlinux.org/title/Mlocate) 查询时忽略该目录。

  - `x-systemd.device-timeout=<seconds>`：挂载超时时间（超时将放弃挂载）

    **对于挂载网络文件系统比较有用**（避免不能访问时挂载操作一直挂起）

  - `x-systemd.requires-mounts-for=<mount-point>`：该文件系统的挂载依赖于其他挂载点（其他挂载点必须先于它挂载）

  - `x-systemd.idle-timeout=<seconds>`：automount 最大闲置时长

  

- `<dump>`：dump 读取改值来确定是否作备份

  允许的值：

  - 0  忽略
  - 1  备份

  大部分的用户是没有安装 dump 的 ，应设为 0。

  

- `<pass>`：fsck 读取该值来确定需要检查的文件系统的检查顺序

  允许的值：

  - 0  忽略
  - 1  根目录应当获得最高的优先权
  - 2  其它所有需要被检查的设备



# autofs

> autofs 是一个可根据需要自动装入指定目录的程序。它基于一个内核模块运行以实现高效率，并且可以同时管理本地目录和网络共享。这些自动安装点仅会在被访问时装入，一定时间内不活动后即会被卸载。

autofs是按需挂载，即该文件系统需要读写时才挂载。可使用`df -h`发现其并未挂载。

使用前确保已经安装并启用autofs服务。



## 主映射配置文件

autofs的配置文件`/etc/autofs.conf`中可设置主映射文件，一般是`/etc/autofs/auto.master`或`/etc/autofs.master`（不同发行版位置可能有差异）。



在主映射文件中加载特定的子映射配置文件，示例：

```shell
#加载子映射配置文件
#<mount point>    <map name>        <options>
#/misc            /etc/auto.misc

#将读取/etc/auto.master.d/ 目录中的.autofs映射文件
+dir:/etc/auto.master.d/

#可确保使用 NIS的用户仍可找到其 master 映射
+auto.master
```



如果配置了`+dir:/etc/auto.master.d/`行，则autofs会读取`/etc/auto.master.d/`中文件名后缀为`.autofs`的文件。因此也可以将子映射配置信息写到``etc/auto.master.d/`中的文件名后缀为`.autofs`文件中。



加载子映射配置文件示例：

```shell
#<mount point>    <map name>        <options>
/-               /etc/auto.vol     
/srv/mirror      /etc/auto.mirror   --timeout=90
#用于nis
/share/home      yp:auto_home       --timeout=60
```

- `<mount point>`：文件系统挂载点的父目录

  子映射配置文件中的文件系统均将挂载到该目录的子目录中，例如欲将`/dev/sdb`挂载到`/mnt/db`，则这里的`<mount point>`为`/mnt`。

  

  *因为一个`<map name>`映射文件中可定义多个文件系统的挂载信息，这些文件系统均挂载到`<mount point>`下到子目录中。*

  

  `/-`表示不指定（需在对应的`<map name>`映射文件中以绝对路径指定挂载点）

  **注意：如果要挂载文件系统到`/`下的子目录，不可以指定`<mount point>`为`/`，应该设置为`/-`，然后在对应的`<map name>`文件中设置key为绝对路径。**（参看下文配置自动挂载的映射文件）

  如欲挂载到`/data`，这里的值设置为`/-`，对应的映射文件中的key填写`/data`。

  

- `<map name>`：映射配置文件的路径

- `<options>`：可选，这些选项将作为默认值应用于给定映射中的所有项



## 子映射配置文件

配置自动挂载的

映射文件的写法：

```shell
#key [ -mount-options-separated-by-comma ] location
```



- 主映射配置文件中的挂载目录为`/-`

  以第1步中`/etc/auto.master.d/example.autofs`为例：

  其第一条为`/-  /etc/auto.vol`，使用了`/-`未指定挂载位置，因此映射文件`/etc/auto.vol`中的key为具体的挂载（绝对）路径：

  ```shell
  #挂载  /dev/vdb 到 /data  (自动猜测类型)
  /data  -fstype=auto  :/dev/sdb
  ```

  文件系统位置部分包含`:`，对于本机的文件系统，`:`前为空白内容。

- 主映射配置文件中的挂载目录为指定的目录

  其第二条为`/srv/mirror   /etc/auto.mirro  --timeout=90`，映射文件`/etc/auto.mirror`中的key为一个目录的相对路径：

  ```shell
  os     -fstype=iso9660       :/dev/sr0
  rpms   -fstype=nfs,_netdev   sever1:/rpms
  ```



## 检查和使用

查看已配置的自动挂载映射项：

```shell
 automount -m
```

autofs挂载的文件系统的挂载点自动生成，未被自动挂载前，该目录不存在，`df`中也看不到挂载信息。

对文件系统挂载目录进行操作，会发现目录出现了，df中也能看到挂载信息。

