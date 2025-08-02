# 查看挂载信息

## `/etc/mtab`：已挂载设备列表

`/etc/mtab` 记录了当前系统已挂载的文件系统（**m**ounted file systems **tab**le），每次挂载/卸载时系统会自动更新。

```shell
cat /etc/mtab | column -t  # 用 column -t 格式化输出
```



## `lsblk`：查看块设备与挂载点

```shell
lsblk                         # 输出设备名称、挂载点等基本信息
lsblk -f                      # 包含文件系统类型、UUID 等
lsblk -o name,uuid,label      # 自定义输出字段
```

输出示例：
>```shell
>$ lsblk -f
>NAME   FSTYPE LABEL UUID                                 MOUNTPOINT
>sda                                                      
>├─sda1 vfat         D409-0125                            /boot/efi
>├─sda2 ext4         2bd78210-021f-4133-9d91-3837018010f6 /boot
>├─sda3 swap         d362fe17-006b-41ac-8c18-0632ab99c281 [SWAP]
>└─sda4 ext4         bcbaa227-e973-4dcb-8c2f-2cdad1f264e3 /
>sdb    ext4   DATA  01b08ad6-5f6e-4eb8-af37-690e30680a10 /storage
>```

- NAME：内核中为文件系统的命名，实际存放在`/dev`下，如`/dev/sdb`

- FSTYPE：文件系统类型

- LABEL：卷标名

- UUID：该文件系统唯一的ID值

  ```shell
  #blkid获取uuid
  blkid /dev/sda1  #获取/dev/sda1的uuid
  ```

- MOUNTPOINT：文件系统挂载点



##  `df`：查看磁盘使用与挂载情况

```shell
df -h  #-h 以人类易读模式输出容量单位
#其他常用选项
# -x <fs_type>  排除某个文件系统，如-x tmpfs
# -l  只输出本地文件系统，如排除挂载的网络文件系统
# -i, --inodes  输出Indoe使用情况
```

输出示例：

> ```shell
> Filesystem      Size  Used Avail Use% Mounted on
> udev            414M     0  414M   0% /dev
> tmpfs            86M  656K   86M   1% /run
> /dev/vda1        50G   17G   31G  36% /
> ```



##  `mountpoint`：判断路径是否为挂载点

mountpoint属于 `util-linux` 包（在大多数 Linux 发行版中默认安装）

```shell
mountpoint </path/to/check>     # 输出该路径是否为挂载点
mountpoint -q </path/to/check>  #-q静默输出
echo $?
```

可根据其执行后的退出码（执行后使用`$?`）判断一个路径是否为挂载点（已经挂载）

```shell
if mountpoint -q </path/to/check>;then
	#....
fi
```



##  `findmnt`：挂载信息查看工具

```shell
findmnt                   # 树状显示当前所有挂载信息
findmnt /mnt              # 查询特定路径的挂载信息
findmnt -t nfs            # 按类型过滤挂载信息
```



# mount挂载和umount卸载

具体使用参看相关文档。

直接执行`mount`命令也会输出挂载信息，不过不一定总是准确。

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



# fstab

`/etc/fstab`多用于启动时自动挂载，但随着systemd的发展，现在一些linux发行版有逐渐使用systemd接管部分fstab挂载的文件系统的趋势，最多见的是不少发行版的tmpfs不再存在于`/etc/fstab`中。

```shell
#要挂载的分区或存储设备    挂载点     文件系统类型     选项        是否备份   是否检查
# <file system>        <mount point>      <type>       <options>    <dump>    <pass>
```

- `<file systems> `  ：要挂载的分区或存储设备

  可以使用以下方式表示：

  - 内核名称
  - UUID
  - label

  在BIOS 中改变了存储设备顺序，或是重新拔插了存储设备，可能会随机地改变存储设备的顺序，那么用 UUID 或是 label 来表示将更有效。

- `<mount point>` ：挂载位置



- `<type>`：要挂载设备或是分区的文件系统类型

  设置成`auto`类型，mount 命令会猜测使用的文件系统类型（对 CDROM 和 DVD 等移动设备是非常有用）

  `cat /proc/filesystems`可查看支持的文件系统

  

- `<options>`： 挂载时使用的参数

  常用参数（注意：**有些参数是特定文件系统才有效的**）：

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



# autofs按序挂载（自动挂载服务）

Autofs 是一种支持**访问时自动挂载，空闲时自动卸载**的机制，适合网络共享或大容量设备管理。

使用前确保已经安装并启用autofs服务。



## 主配置文件 `/etc/auto.master`

autofs的主配置文件用于指定[映射文件](#映射文件)的位置和配置信息。

该文件路径一般是`/etc/autofs/auto.master`或`/etc/auto.master`（不同发行版位置可能有差异，可在`/etc/autofs.conf`文件自定义）。

注意：**主配置文件修改后需要重启autofs服务。**

示例：

```shell
#配置映射文件的语法
#<mount point>  [map-type[,format]:]map [options]

#内置的配置文件
/misc          /etc/auto.misc
/net	         -hosts

#加载子配置文件目录
#+dir:</path/to/sub-configs/dir/>
+dir:/etc/auto.master.d/

#可确保使用 NIS的用户仍可找到其 master 映射
+auto.master
```

可以在该文件中加载其他目录中的配置文件，而不是直接在主配置文件中添加映射文件信息，以实现配置文件拆分。

如上文中的`+dir:/etc/auto.master.d/`行，则autofs会读取`/etc/auto.master.d/`中文件名后缀为`.autofs`的文件，然后在这些`.autofs`文件中配置具体的映射信息：

示例`/etc/auto.master.d/example.autofs`：

```shell
#<mount point>  [map-type[,format]:]map   [options]
/-               /etc/auto.vol     
/srv/repo        /etc/auto.repo           --timeout=90
/share/home      yp:auto_home             --timeout=60
```

各列字段说明：

- `<mount point>`：挂载点（目录）

  如果使用`/-`，表示此处不指定挂载路径，具体的挂载路径在映射文件中指定。

  如果指定了挂载点目录的路径（绝对路径），则映射件中的文件系统均将挂载到该目录的子目录中，例如欲将`/dev/sdb`挂载到`/data/db`，则这里的`<mount point>`为`/data`。

  

  注意：autofs挂载后，此处`<mount point>`目录中，只有对应映射文件中的子目录可以访问，原有的文件不可访问。例如`/data`中有`db`子目录和其他一些文件，在autofs配置文件中配置为挂载点，如果对应映射文件中配置挂载某文件系统到子目录`db`，则autofs生效后，`/data`目录只能访问到`/data/db`目录。该场景下应当使用`/-`模式。

  

- `[map-type[,format]:]map`：映射文件配置

  

- `[options]`：可选，选项

  此处可用的选项是使用`mount`命令挂载对应的文件系统可用的那些选项。

  注意：此处的选项将作为默认值应用于给定映射文件中的所有项。



## 映射文件

即具体挂载某个文件系统到指定挂载点的配置文件。

示例：

```shell
#<mount point>  [ -mount-options ]     <location>
/data                                  :/dev/sdb
os              -fstype=iso9660,ro     :/dev/sr0
rpms            -fstype=auto           sever1:/rpms
smb1            -fstype=cifs           ://server1/smb1
```

各列字段说明：

- `<mount point> `  挂载点

  - 如果是相对路径，则挂载到上文的配置文件中`<mount point>`列所指定的子目录。

    例如配置文件`/etc/autofs.master.d/repo.autofs`内容为：

    ```shell
    /srv/repo  /etc/auto.repo
    ```

    映射文件`/etc/auto.repo`内容为：

    ```shell
    os    :/dev/sr0
    ```

    则表示`/dev/srv0`设备挂载到`/srv/rep/os`

    

  - 如果配置文件中`<mount point>`列使用了`/-`，则此处必须使用绝对路径。

    例如配置文件`/etc/autofs.master.d/share.autofs`内容为：

    ```shell
    /-  /etc/share.repo
    ```

    映射文件`/etc/share.repo`内容为：

    ```shell
    /share -fstype=nfs nfs_server1:/share
    ```

    则表示将`nfs_server1:/share`挂载到`/share`。

  

- `[ -mount-options ] `   指定相关项的安装点逗号分隔列表，可选

  此处可用的选项是使用`mount`命令挂载当前文件系统可用的那些选项。

  常用选项：

  - `--fstype=<type>`  指定挂载的文件系统类型

    可使用`--fstype=auto`让其自动尝试挂载，一般都能实现常见的文件系统识别。

    注意：虽然不指定该选项，autofs也会自动猜测文件系统，不过也有可能出现失败的情况，如`iso9660`的ISO文件。

  - `--timeout=<N>`  挂载超时的时间（一个数字），单位为秒

  

- `<location>`    指定要挂载的文件系统的来源

  语法为`[host]:<path>`，对于本机的文件系统，`:`前的主机信息留空。



## 动态挂载网络路径/net配置

内置的`/net` 可以根据需要自动装入本地网络上的所有 NFS 共享，可以在映射文件中使用通配符实现灵活挂载

确保在`auto.master` 文件中有没有注释的该行内容：

```shell
/net      -hosts
```



在映射文件中使用通配符自动装入子目录，可以使用星号`*`取代安装点，使用符号`&`取代要装入的目录。

```shell
*      server1:/home/&
```



## 使用与调试

```shell
automount -m           #查看已配置的自动挂载映射项
sudo automount -f -v   #前台测试，输出详细信息
```

autofs挂载的文件系统的挂载点自动生成，未被自动挂载前，该目录不存在，`df`中也看不到挂载信息。

对文件系统挂载目录进行操作，会发现目录出现了，df中也能看到挂载信息。

