[TOC]

参看 [arch Linux 安装指导](https://wiki.archlinux.org/title/Installation_guide_(简体中文)#安装前的准备)

# 准备工作

- 划分磁盘空间用于linux安装（推荐至少30G）

- **确定系统引导方式**以确认[启动盘制作](#启动盘制作)方法（[UEFI](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface_%28%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%29)还是Legacy BIOS，可在设备的BIOS中查看和设置。）

- **在bios设置中关闭启设置中的安全启动**

  *如有没有该设置则略过，对Arch Linux使用安全启动可参考[archwiki-Secure Boot](https://wiki.archlinux.org/index.php/Secure_Boot_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))。*

- **互联网**（安装需要联网）

- U盘（本文讲述使用U盘作为启动介质安装操作系统）

- [Arch Linux 系统镜像](https://www.archlinux.org/download/)

- nano或vi/vim基本操作技能

  *编辑配置文件时需要用到的最基本的编辑操作。*

## U盘启动盘制作

根据情况选择：

- 如果设备支持[UEFI](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))启动，**可以**直接将下载的系统镜像文件解压或挂载，复制其中的内容到U盘根目录即可。

- 使用工具制作启动盘

  - [balenaEther](https://www.balena.io/etcher/) 和 [poweriso](http://www.poweriso.com)   用于windows、macos和linux

  - windows： [rufus](https://rufus.ie/zh/)

  - dd 用于linux、macos
  
    ```shell
    #/path/arch.iso是下载的Arch Linux镜像文件路径  /dev/sdx U盘的设备编号（根据情况修改如sdb sdc）
    dd if=/path/arch.iso of=/dev/sdx bs=1024
    ```
  
  - linux： gnome-disks、KDE Partition Manager等写入系统镜像文件
  
  - macos：磁盘工具diskutil写入系统镜像文件
  
  - [ventory](https://www.ventoy.net/cn/index.html) 用于windows和linux。参看[ventory说明](https://www.ventoy.net/cn/doc_start.html)
  
    [ventory livecd](https://www.ventoy.net/cn/doc_livecd.html)，任何系统均可。
  
    - 如果要安装系统的计算机支持UEFI，可以之间将iso内容提取到U盘（fat 32格式的分区）中。
    - 也可以将livecd使用使用dd或其他工具如 [rufus](https://rufus.ie/zh/) 将iso写入到U盘（fat 32格式的分区）中。
  
    


## 启动引导

1. 在计算机上插入U盘，然后开启（重启）计算机。

2. 适时选择启动方式——使用USB启动（不同设备方法设置不同）。

3. 载入U盘上的系统 > 回车选择**第一项**（默认）> 等待一切载入完毕……

   

# 基础安装

**可使用[archinstall](https://wiki.archlinuxcn.org/wiki/Archinstall)辅助安装工具**完成本章节的安装工作，安装完成后**连续按两次`ctrl`+`d` ，输入`reboot`重启并拔出u盘**

---

以下安装过程中遇到需要选择（y/n）的地方，如不清楚如何选择，可直接回车或按下<kbd>y</kbd>即可。

## 系统分区

### 规划

在进行分区操作前或许要了解以下信息以进行预规划，然后根据情况选择UEFI模式或legacy模式分区。

- 了解硬盘情况

  如果对设备硬盘分区情况不了解，可使用如下命令查看：

  ```shell
  lsblk  #列出所有可用块设备的信息
  fdisk -l  #查看硬盘信息
  fdisk -l |grep gpt  #查看硬盘是否使用GPT
  parted -l   #查看硬盘信息
  ```

- 分区工具使用

  例如parted、fdisk、cfdisk。

  这里简要介绍cfdisk工具：

  - 查看整个磁盘的情况 `cfdisk /dev/sda` （第二块硬盘则是`cfdisk /dev/sdb` ）

    如果硬盘没有创建分区，以上命令会提示选择分区表类型，建议选择GPT。

    cfdisk的顶部label会显示分区表类型。

    如果已经是mbr分区表，而希望采用gpt分区表，可退出cfdisk，使用parted重建（该操作会**清除分区上原有数据**）：cfd

    ```shell
    parted /dev/sda mklabel gpt #在/dev/sda创建gpt
    ```

  - 利用箭头进行上下左右移动，选中项会高亮显示，回车键确定操作。

  - `New`用于新建分区，输入新建分区的大小并回车，建立了一个分区。

  - `Delete`删除当前选中的分区。

  - `Type`选择分区类型。

  - `Write`用于保存操作。

  - `quit`退出（直接输入`q`亦可）。



以下是不同模式的分区方案，根据个人情况选择，一般建议使用GPT分区+UEFI引导，分区方案建议使用LVM或Btrfs。

使用[swap文件](https://wiki.archlinux.org/index.php/Swap_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E4%BA%A4%E6%8D%A2%E6%96%87%E4%BB%B6)比使用swap分区更为灵活，易于调整，二者没有性能差别，一般建议使用swap文件，但是使用btrfs分区，因其本身原因，则建议使用单独的swap分区。

物理内存很大也可以不划分swap，**需要进行大量使用内存的操作而可能造成内存耗尽建议划分，某些软件可能会要求有swap空间，另要使用休眠功能必须划分。**(*休眠所需swap大小和休眠前系统开启的程序占用的内存大小有关，根据情况酌情调整。*)



不清楚自己需要划分多大的分区，尤其是根分区`/`和swap分区（还是推荐使用swap文件），建议使用LVM或btrfs。

EFI分区（ESP，即[EFI system partition](https://wiki.archlinux.org/index.php/EFI_system_partition_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))））始终是单独建立的分区。



检查当前是否使用UEFI启动：

```shell
ls /sys/firmware/efi/  #如果该文件存在则表示使用UEFI启动
```



以下是不同的分区规划方案的常规建议：

*建议使用swapfile，此处不划分swap分区*

- MBR

  - **/**  系统根分区 （可以只有该分区）
  - /boot  可选 启动分区  200M+
  - home  可选  **但建议单独划分**
- UEFI+LVM

  - ESP
  - 其他使用LVM
- UEFI+标准分区

  - **ESP**  256M-512M （足以存放多个系统引导文件）
  - **/  系统根分区**     一般桌面用户建议至少25G+。
  - /boot  可选   如果要单独创建该分区，容量建议200M+。
  - /home  用户目录 可选 **但建议单独划分**
- UEFI+btrfs

  - ESP
  - 其余使用btrfs



以下命令中为的设备名字如`nvme0n1p1`为示例名字，也可能硬盘设备名字类似`/dev/sda1`，具体根据`lsblk`实际情况确定。选择一种分区模式进行操作。



### ESP+LVM分区管理

- ESP(EFI系统分区)

  - 已经存在ESP

    支持UEFI的设备上，先前已经存在一个操作系统（例如windows10）且**打算保留原操作系统，不要对EFI系统分区进行任何操作。**

    ```shell
    fdisk -l | grep -i efi  #查看是否存在efi
    ```

    如果不保留原来的EFI系统分区中的引导文件，直接对其格式化即可：

    ```shell
    mkfs.vfat /dev/nvme0n1p1  #这里假设EFI系统分区位于/dev/nvme0n1p1（下同）
    ```

  - 新建ESP

    使用cfdisk或其他工具创建一个100M（可以稍微大一些），Type选择类型为`EFI system`即可。

    *这里假设EFI系统分区位于/dev/sda1*，下同。

    

- 使用[LVM](https://wiki.archlinux.org/index.php/LVM_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))创建其他分区

  如果使用lvm-raid，参看[arch-wiki:lvm#RAID](https://wiki.archlinux.org/index.php/LVM_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E4%B8%BARAID%E9%85%8D%E7%BD%AEmkinitcpio)

  使用cfdisk或其他磁盘工具将剩余空间创建一个分区。*假设其为/dev/nvme0n1p2。*

  ```shell
  #1.建立物理卷：在 /dev/nvme0n1p2建立物理卷
  pvcreate /dev/nvme0n1p2
  
  #2.建立卷组：新建名为linux的卷组 并 将nvme0n1p2加入到卷组中
  vgcreate linux /dev/nvme0n1p2
  
  #3.建立逻辑卷：在linux卷组中建立root和home逻辑卷
  #lvcreate -L 200M linux -n boot   #如果要创建boot分区
  lvcreate -L 30G linux -n root  #3.2.1  用linux卷组中30G空间建立适用于根分区的逻辑卷
  lvcreate -l +100%FREE linux -n home   #3.2.2  用linux卷组中所有剩余空间建立home逻辑卷
  #lvcreate -L 100G linux -n home  #创建home逻辑卷并指定100GB空间
  lvdisplay
  
  #4.各个逻辑卷创建文件系统
  mkfs.ext4 /dev/mapper/linux-root    #根分区
  mkfs.ext4 /dev/mapper/linux-home   #home分区
  #mkfs.ext4 /dev/mapper/linux-boot   #如果创建有boot分区
  
  #5.挂载
  #根分区
  mount /dev/mapper/linux-root /mnt
  
  #home分区
  mkdir /mnt/home    #建立home挂载点
  mount /dev/mapper/linux-home /mnt/home
  
  #boot分区 （如果有单独的boot分区）
  #mdkir /mnt/boot
  #mount /dev/mapper/linux-boot /mnt/boot
  
  #EFI分区
  mkdir /mnt/boot/efi -p
  mount /dev/nvme0n1p1 /mnt/boot/efi
  ```

  

### ESP+标准分区

- 参照ESP+LVM分区管理处理ESP

- 使用标准方式创建其他分区

  使用cfdisk或其他工具创建`/`根分区（*假设为/dev/nvme0n1p2*）和home（*假设为/dev/nvme0n1p2*）用户家目录分区，创建文件系统：

  ```shell
  #1. 挂载根分区
  mkfs.ext4 /dev/nvme0n1p2
  mount /dev/nvme0n1p2 /mnt    #挂载根分区
  
  #2. 挂载home分区
  mkfs.ext4 /dev/nvme0n1p2
  mkdir /mnt/home    #建立home挂载点
  mount /dev/nvme0n1p2 /mnt/home    #挂载home逻辑卷到/home
  
  #3.挂载esp
  mkdir -p /mnt/boot/efi  #建立efi系统分区的挂载点
  mount /dev/nvme0n1p1 /mnt/boot/efi    #挂载esp到/boot/efi
  ```



### ESP+btrfs

- 参照ESP+LVM分区管理处理ESP

- 创建btrfs文件系统

  ```shell
  #mkfs.btrfs [-m <meta-data-profile>] [-L <lable-name>] /dev/nvme0n1p2
  mkfs.btrfs /dev/nvme0n1p2
  ```

  根据需要创建btrfs子卷，子卷规划示例：

  | subvolume | 在系统的挂载点 | 附注           |
  | --------- | -------------- | -------------- |
  | @         | /              | 根分区，必须   |
  | @home     | /home          | 家目录，可选   |
  | @log      | /var/log       | 日志目录，可选 |
  | @cache    | /var/cache     | 缓存目录，可选 |
  | @lib      | /var/lib       | 程序运行数据   |
  
  1. 将btrfs分区挂载到/mnt
  
     ```shell
     mount /dev/nvme0n1p2 /mnt
     ```
  
  2. 使用`btrfs subvolume create /mnt/<name>`创建子卷
  
     一般name以`@` 开头，也可使用单个`@`字符作为卷名
  
     ```shell
     btrfs subvolume create /mnt/@
     btrfs subvolume create /mnt/@home
     btrfs subvolume create /mnt/@log
     btrfs subvolume create /mnt/@cache
     
     #使用 chattr 忽略无需写时复制的子卷
     chattr +C /mnt/@log
     chattr +C /mnt/@cache
     
     btrfs subvol list /mnt  #subvol简写等同于subvolume
     #删除示例
     #btrfs subvolume delete /mnt/@xxx
     
     umount -fl /mnt  #创建完毕后卸载/mnt以进行后续操作
     ```
  
  
    3. 挂载分区
  
       ```shell
       #1. 根分区 @root子卷
       mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt
       
       #2. EFI
       mkdir -p /mnt/boot/efi  #EFI分区挂载点
       mount /dev/nvme0n1p1 /mnt/boot/efi
       
       #3. swap （如有）
       swapon /dev/nvme0n1p2
       
       #4.1 创建subvolume的挂载点
       mkdir /mnt/home
       mkdir -p /mnt/var/{log,cache}
       
       #4.2 挂载subvolume
       mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home
       
       mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@log /dev/nvme0n1p2 /mnt/var/log
       
       mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@cache /dev/nvme0n1p2 /mnt/var/cache
       
       #...依次挂载完毕
       
       lsblk #查看
       ```
       
       
  

### Legacy（MBR）模式分区

无ESP相关部分，其余参看其他分区模式

```shell
#创建文件系统
#挂载根分区到/mnt
#挂载其他分区
mkdir /mnt/boot分区
mkfs.vfat /dev/sda1
mount /dev/sda1 /boot
```



## 连接网络

有线网络：

```shell
dhcpcd    #连接到有线网络
```

WIFI：

iwctl 或 iw命令：

```shell
ip a #查看无限网卡名字 一般可能是wlan0
iw dev wlan0 scan #wlan0网卡扫描wifi接入点
iw dev wlan0 connect wifi接入点名字 wifi密码
```

检查：

```shell
ip a     #查看连接状态
ping -c 5 z.cn  #测试连接情况
ip a  #查看分配的ip
```

## 配置镜像源

可选。

在安装前最好选择较快的镜像，以加快下载速度。
编辑` /etc/pacman.d/mirrorlist`，添加或选择首选源（按所处国家地区关键字索搜选择，如搜索china），将其复制（或粘贴）到文件顶部，保存并退出。一些中国地区镜像源如：

```shell
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.163.com/archlinux/$repo/os/$arch
```

## 安装基础包

```shell
##base-devel 包可选
pacstrap -K /mnt base linux-lts linux-firmware
```

## swapfile

可选。

swapfile也可以安装完毕后再配置，创建完毕后在`/etc/fstab`中添加类似`/swap none swap defaults,nofail 0 0 `即可。

```shell
fallocate -l 4G /mnt/swap
mkswap /mnt/swap
chmod 600 /mnt/swap
swapon /mnt/swap

swapon --show
```

如果要在btrfs上使用swapfile：

```shell
btrfs subvolume create /mnt/swap
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile
swapon /swap/swapfile
```

## 建立fstab文件

```shell
genfstab -U /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab    # 查看生成的 /mnt/etc/fstab
```

## 进入系统

```shell
arch-chroot /mnt
```

## 激活lvm2钩子

**使用了lvm分区方式，需要执行该步骤**，否则跳过。

```shell
pacman -S lvm2
```

基本系统不带有编辑器，安装一个编辑器如vim或nano：

```shell
pacman -S neovim #or vim
#or
pacman -S nano
```

nvim（或vim）编辑/etc/mkinitcpio.conf文件，找到类似字样：

>HOOKS="base udev autodetect modconf block  filesystems keyboard fsck"

在block 和 filesystems之间添加`lvm2`（注意lvm2和block及filesystems之间有一个空格），类似：

> HOOKS="base udev autodetect modconf block lvm2 filesystems keyboard fsck"

再执行：

```shell
mkinitcpio -P
```



## 添加btrfs module

**如果使用btrfs分区，需要执行该步骤**，否则跳过。

```shell
pacman -S btrfs-progs
```

编辑/etc/mkinitcpio.conf文件，在`MODULES=`行后面的括号中添加`btrfs`：

> MODULES=(btrfs)

再执行：

```shell
mkinitcpio -P
```



## 网络配置

linux自带的`linux-frimware`已经支持大多数驱动，如果某些设置不能使用，参看[archwiki:网络驱动](https://wiki.archlinux.org/index.php/Wireless_network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E5.AE.89.E8.A3.85_driver.2Ffirmware)。

如果要安装Gnome、KDE等桌面环境，可以略过该步骤，桌面环境将集成图形界面网络管理工具，如NetworkManger管理网络。

参看archlinux-wiki的[网络配置](https://wiki.archlinux.org/index.php/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))了解更多。



- [NetworkManager](https://wiki.archlinuxcn.org/wiki/NetworkManager)

  ```shell
  pacman -S networkmanager
  systemctl enable --now NetworkManager
  ```

- [dhcpcd](https://wiki.archlinuxcn.org/wiki/Dhcpcd)

  ```shell
  pacman -S dhcpcd wpa_supplicant #wpa_supplicant无线支持可选
  systemctl enable dhcpcd  #开机自启动有线网络 当然也可以手动执行 dhcpcd 连接
  ```

- [systemd-network](https://wiki.archlinux.org/title/systemd-networkd)

  1. 创建或编辑`/etc/systemd/network`下的文件配置，例如为eno1网口配置dhcp，内容示例：

     ```shell
     [Match]
     Name=eno1
     
     [Network]
     DHCP=yes
     IPv6AcceptRA=true
     ```
     
     启动服务：
     
     ```shell
     systemctl enable --now systemd-networkd
     ```
  
- [netctl](https://wiki.archlinuxcn.org/wiki/Netctl)

  ```shell
  pacman -S netctl iw wpa_supplicant dialog  #iw wpa_supplicant无线支持可选
  ip a      #查看到当前连接无线的网卡名字
  wifi-menu #连接无线网络
  systemctl enable netctl-auto@网卡名字  #开机自动使用该网卡连接曾经接入的无线网络
  ```

## 系统引导

- 安装[微码](https://wiki.archlinux.org/index.php/Microcode_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))（建议安装）

  ```shell
  pacman -S intel-ucode   #仅intel CPU安装
  pacman -S amd-ucode  #仅amd CPU安装
  ```

- 如过要引导多系统安装（可选）

  ```shell
  pacman -S os-prober
  ```

### grub引导

  ```shell
  pacman -S grub
  ```
  如果安装了os-prober检测其他引导，需要编辑/etc/default/grub并添加该行（或取消该行注释）：

  ```shell
  GRUB_DISABLE_OS_PROBER=false
  ```

  - 使用UEFI引导，执行：

    ```shell
    pacman -S efibootmgr  #使用esp还需安装
    ##如果单独划分了esp，将其挂载到/boot，则--efi-directory=/boot
    grub-install --efi-directory=/boot/efi --bootloader-id=grub
    ```

  - 使用Legacy模式，则执行：

     ```sehll
     grub-install  /dev/sda
     ```

### systemd引导

```shell
bootctl install
```


- 生成引导

  ```shell
  grub-mkconfig -o /boot/grub/grub.cfg
  ```

  如果在生成引导命令执行后卡住，很久不能成功，参看下方[生成grub配置时挂起](#生成grub配置时挂起)解决。

  **注意**：如果多系统使用grub配合os-prober管理，但在启动的grub菜单中找不到其他系统的引导条目，可在**进入系统**再次执行该命令重新检测生成。
  
  

至此**基础系统**安装完成，**基础系统仅有字符界面**，可继续进行下面的[常用配置](#常用配置)安装流程，或者结束基础安装重启系统：**连续按两次`ctrl`+`d` ，输入`reboot`重启并拔出u盘**。

如果windows+archlinux双系统用户在重启后直接进入了Windows系统，可参看[选择grub为第一启动项](#选择grub为第一启动项) 解决。



## 用户管理

- 设置root密码和建立普通用户
## Locale设置

参看[Locale](https://wiki.archlinux.org/index.php/Locale_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)) 设置

编辑`/etc/locale.gen`，根据本地化需求移除对应行前面的注释符号。

以中文用户常用locale为例，去掉这些行之前前面#号：

```shell
en_US.UTF-8 UTF-8
zh_CN.GBK
zh_CN.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
```

保存退出后执行：

```shell
locale-gen
```
## 用户和密码

```shell
passwd     #设置或更改root用户密码  接着输入两次密码（密码不会显示出来）
#添加普通用户 （可选）
useradd -m user1
#如果要添加为管理用户，可直接在创建是加入wheel组（用作sudoers的组）
useradd -m -g wheel user1
passwd user1    #设置或更改user1用户密码 接着输入两次密码
```


- 给予普通用户sudo权限

  ```shell
  pacman -S sudo vim
  #使用nvim的可以暂时
  #alias vim=nvim
  
  export EDITOR=vim  #或者nano
  ```
  
  执行visudo，该命令会打开一个文件，在该文件中找到`%wheel`行，去掉前面的`#`
  
  > %wheel ALL=(ALL) ALL'
  
  或去掉wheel行前面的注释（如果在创建用户时将用户加入了wheel组）。
  
  参看[arch-wiki:sudo](https://wiki.archlinux.org/index.php/Sudo_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))



## 时钟

保留windows的用户可能还需要**参考后文[windows和linux统一使用UTC](#windows和linux统一使用UTC)** 。

linux时钟分为系统时钟（system clock）和硬件时钟（Real Time Clock, RTC——即实时时钟，电脑主板记录的时钟）。

设置时区，将系统时间和硬件时间统一：

```shell
date #查看当前系统时间
#设置时区 示例为中国东八区标准时间--Asia/Shanghai
#也可使用tzselect命令按提示选择时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#将当前硬件时间写入到系统时钟  并使用utc时间
hwclock -s -u  #或hwclock --systohc --utc
```



# 常用配置

## sshd

```shell
pacman -S openssh
systemctl --now enable sshd #安装时--now无效无法立即启动sshd systemd service
```



## swappiness

[swappiness](https://wiki.archlinux.org/index.php/Swap_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#Swappiness)值代表了内核对于交换空间的喜好(或厌恶)程度。

Swappiness值在0-200之间，设置这个参数为较低的值会减少内存的交换，从而提升一些系统上的响应度。默认值过大，除非设备内存很小且很大概率经常使用超出物理内存的情况，否则调低该值很有必要。

```shell
echo 'vm.swappiness=1
vm.vfs_cache_pressure=50'> /etc/sysctl.d/vm.conf
```

**从kernel 3.5rc2开始swappiness=0表示禁止swap*仅在物理内存严重不足（内存即将耗尽）时才使用swap** （待验证）

对于使用且大内存较大，可以设置为0。如果完全不 想使用swap，可以不swapon任何分区或swap文件。



## 主机名

```shell
echo MyPC > /etc/hostname  #MyPC是要设置的主机名
```

**注意:** 在 Arch Linux chroot 安装环境中，*hostnamectl*不起作用，因此不能使用`hostnamectl set-hostname 主机名`设置主机名。

### 字体

参看[archwiki:fonts](https://wiki.archlinux.org/index.php/Fonts_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))根据需要安装字体，一般建议至少安装以下三类字体。

- 等宽字体，如`otf-fira-code`和`ttf-dejavu`。
- 数学和特殊符号字体，如`noto-fonts-emoji`（emoji表情)和`ttf-symbola`（需要aur）。
- 中文字体，如`wqy-microhei`（文泉驿微米黑），可参看下文[中文显示](#中文显示)。

```shell
pacman -S wqy-microhei otf-fira-code noto-fonts-emoji
```


## 图形界面

### 显卡驱动

首先需要了解设备的显卡信息，也可是使用`lspci | grep VGA`查看。根据显卡情况安装驱动：

```shell
pacman -S nvidia             #nvidia显卡驱动（包含vulkan）

pacman -S mesa               #amd显卡使用开源mesa驱动即可(一般已经在基础系统中集成，安装图形环境时都会自动安装，无需独立安装）

#vulkan 支持
pacman -S vulkan-intel       #intel显卡
pacman -S vulkan-radeon      #amd/ati显卡

#opencl支持
pacman -S opencl-mesa        #mesa(amd)
pacman -S opencl-nvidia      #nvidia
```
注意：

带有独立显卡的设备不安装显卡驱动可能造成进入图形界面出错卡死，请务必先安装显卡驱动！

双显卡设备，可参看后文[双显卡管理](#双显卡管理)。

### 桌面环境/窗口管理器

安装一个[桌面环境](https://wiki.archlinux.org/index.php/Desktop_environment_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))或者[窗口管理器](https://wiki.archlinux.org/index.php/Window_manager_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))。

- 桌面环境，如[Plasma](https://wiki.archlinux.org/index.php/KDE_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))或者[Gnome](https://wiki.archlinux.org/index.php/GNOME_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))：

  ```shell
  pacman -S plasma sddm  && systemctl enable sddm  #plasma(kde)
  pacman -S gnome gdm  && systemctl enable gdm  #gnome
  ```


- 窗口管理器，如[i3wm](https://wiki.archlinux.org/index.php/I3_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))或[openbox](https://wiki.archlinux.org/index.php/Openbox_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))

  ```shell
  pacman -S xorg-server xorg-xinit      #务必安装
  pacman -S i3  #i3wm
  pacman -S awesome  #awesome
  pacman -S openbox  #openbox
  ```

  窗口管理还需要自行配置[显示管理器](https://wiki.archlinux.org/index.php/Display_manager_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))或[xinitrc](https://wiki.archlinux.org/index.php/Xinitrc_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))，用以启动窗口管理器 。


### 中文显示和输入

中文字体选择一款（或多款）安装，如：

```shell
pacman -S wqy-microhei                     #文泉驿微米黑
pacman -S adobe-source-han-sans-cn-fonts   #思源黑体简体中文包
pacman -S ttf-arphic-uming                 #文鼎明体
pacman -S ttf-sarasa-gothic                #更纱黑体
```

更多字体参看[中日韩越CJKV字体](https://wiki.archlinux.org/index.php/Fonts_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E4.B8.AD.E6.97.A5.E9.9F.A9.E8.B6.8A.E6.96.87.E5.AD.97) 。安装思源黑体全集（或noto fonts cjk）而出现的中文显示异体字形的问题，参看该文的[修正简体中文显示为异体（日文）字形](https://wiki.archlinux.org/index.php/Arch_Linux_Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E4.B8.AD.E6.96.87.E5.AD.97.E4.BD.93) 。



输入法可选择[fcitx](https://wiki.archlinux.org/index.php/Fcitx_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))或[ibus](https://wiki.archlinux.org/index.php/IBus_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))。

- fcitx本体带有：拼音（主流双拼支持）、二笔、五笔（支持五笔拼音混输）等：

  ```shell
  pacman -S fcitx-im fcitx-configtool     #安装fcitx本体及配置工具
  #按需选择下面的输入法支持或功能插件
  pacman -S fcitx-cloudpinyin        #云拼音插件（推荐拼音用户安装）
  pacman -S fctix-rime                    #rime中州韵（即小狼毫/鼠须管）引擎 任选
  pacman -S fcitx-libpinyin           #智能拼音（支持搜狗词库）任选
  pacman -S fcitx-sogoupinyin    #可使用搜狗拼音（自带云拼音）任选
  ```

  提示：云拼音插件不支持RIME和搜狗，且其默认使用谷歌云拼音，可在fcitx设置中选用百度。

  环境变量设置——在`~/.pam_environment`或`/etc/environment`添加：

  ```shell
  export GTK_IM_MODULE=fcitx
  export QT_IM_MODULE=fcitx
  export XMODIFIERS="@im=fcitx"
  ```

  安装完毕后需要在配置工具(fictx-configtool)中添加相应的输入法才能使用。

- ibus

  ```shell
  pacman -S ibus  ibus-qt        #ibus本体 ibus-qt保证在qt环境中使用正常
  pacman -S ibus-pinyin         #拼音
  pacman -S ibus-libpinyin    #智能拼音（支持导入搜狗词库）
  pacman -S ibus-rim               #rime
  ```

  环境变量设置：在`/etc/environment`添加：

  ```shell
  export GTK_IM_MODULE=ibus
  export XMODIFIERS=@im=ibus
  export QT_IM_MODULE=ibus
  ```

  安装完毕后需要在gnome配置(gnome-control-center)的地区和语言中添加输入源，然后在ibus设置中添加输入法才能使用。

## 声音

**桌面环境用户可略过**。

安装[pipewire](https://wiki.archlinux.org/title/PipeWire)，图形界面控制可以安装：

- **Helvum** — GTK-based patchbay for PipeWire, inspired by the JACK tool *catia*. Does not save wire sets.

- **qpwgraph** — Qt-based Graph/Patchbay for PipeWire, inspired by the JACK tool QjackCtl. Saves wire sets.



## 软件包管理器

### pacman

更多信息查看[archwiki:pacman]((https://wiki.archlinux.org/index.php/Pacman_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))。

- 常用命令

  ```shell
  pacman -Syu   #升级整个系统
  pacman -S <package-name>   #安装软件 ,package-name>即软件名
  pacman -Sw <package-name>   #只下载不安装（安装包存放在/var/cache/pacman/pkg/
  pacman -R <package-name>   #移除某软件但不移除其依赖
  pacmna -Rcn   <package-name>   #移除某软件及相关依赖
  pacman -Qi name  #查看已经安装的某软件的信息
  pacman -Ss <word>  #从软件源查询有某关键字的软件 <word>即是要查询的关键字
  pacman -Qs word  #在已安装软件中根据关键字搜寻
  pacman -Qdt  #查看和卸载不被依赖的包
  pacman -Fs <command>  #查看某个命令属于哪个软件包
  ```

- pacman 设置（可选）
  配置文件在`/etc/pacman.conf`，编辑该文件：

  - 彩色输出：取消`#Color`中的#号。

  - 升级前对比版本：取消`#VerbosePkgLists`中的#号。

  - 社区镜像源：在末尾添加相应的源，[中国地区社区源archlinuxcn](https://github.com/archlinuxcn/mirrorlist-repo)

    例如添加archlinuxcn.org的源：

    ```shell
    [archlinuxcn]
    SigLevel = Optional TrustedOnly
    Server = http://repo.archlinuxcn.org/$arch
    ```

    添加完后执行：

    ```shell
    pacman -Syu archlinuxcn-keyring
    ```

此外可使用 [pacman图形化的前端工具](https://wiki.archlinux.org/index.php/Graphical_pacman_frontends_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))。

### AUR

AUR(Arch User Repository）是为用户而建、由用户主导的Arch软件仓库。

aur软件可以通过[aur助手工具](https://wiki.archlinux.org/index.php/AUR_helpers)器搜索、下载和安装，或者从[aur.archlinux.org](https：//aur.archlinux.org)中搜索下载，用户自己通过makepkg生成包，再由pacman安装。

*可从archlinuxcn源中安装aur助手（例如paru、yay）。*

## 设备连接

### 触摸板

**多数桌面环境已经集成**。

```shell
pacman -S xf86-input-synaptics
```
### 蓝牙

**多数桌面环境已经集成**。

```shell
pacman -S bluez
systemctl enable bluetooth
usermod -aG lp user1    #user1是当前用户名
```
蓝牙控制：命令行控制安装`bluez-utils`，使用参考[通过命令行工具配置蓝牙](https://wiki.archlinux.org/index.php/Bluetooth_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E9.80.9A.E8.BF.87.E5.91.BD.E4.BB.A4.E8.A1.8C.E5.B7.A5.E5.85.B7.E9.85.8D.E7.BD.AE.E8.93.9D.E7.89.99)；[蓝牙图形界面工具]((https://wiki.archlinux.org/index.php/Bluetooth_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E5.9B.BE.E5.BD.A2.E5.8C.96.E5.89.8D.E7.AB.AF))如blueman或blueberry。

### NTFS分区

桌面环境的文件管理器一般都能读取NTFS分区的内容，但不一定能能够写入。可使用`ntfs-3g`挂载：

```shell
pacman -S ntfs-3g       #安装
mkdir /mnt/ntfs          #在/mnt下创建一个名为ntfs挂载点
lsblk                                 #查看要挂载的ntfs分区 假如此ntfs分区为/dev/sda5
ntfs-3g /dev/sda5 /mnt/ntfs       #挂载分区到/mnt/ntfs目录
```
### U盘和MTP设备

**桌面环境一般能自动挂载**。

- 使用[udisk](https://wiki.archlinux.org/index.php/Udisks_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))和libmtp

  ```shell
  pacman -S udiskie udevil
  systemctl enable devmon@username.service    #username是用户名
  pacman -S libmtp
  ```

  在/media目录下即可看到挂载的移动设备。

- 使用gvfs gvfs-mtp（thunar pcmafm等文件管理器如果不能挂载mtp，也可安装`gvfs-mtp` ）

  ```shell
  pacman -S gvfs    #可自动挂载u盘
  pacman -S gvfs-mtp    #可自动挂载mtp设备
  ```



## btrfs 快照

管理工具

- btrfs-assistant
- timeshift
- snapper

# 其他配置/常见问题

## 参考资料

- [获取和安装Arch](#https://wiki.archlinux.org/index.php/Category:Getting_and_installing_Arch_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- [Arch相关](#https://wiki.archlinux.org/index.php/Category:About_Arch_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- [系统维护](https://wiki.archlinux.org/index.php/System_maintenance_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- [pacman提示和技巧](#https://wiki.archlinux.org/index.php/System_maintenance_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))

## 生成grub配置时挂起

archroot中执行`grub-mkconfig`命令挂起，系统无任何反馈信息。参看[Arch GRUB asking for /run/lvm/lvmetad.socket on a non lvm disk](https://unix.stackexchange.com/questions/105389/arch-grub-asking-for-run-lvm-lvmetad-socket-on-a-non-lvm-disk)。

1. 终止`grub-mkconfig`命令，执行`exit`退出archroot；

2. 假设前面archroot的为`/mnt`，执行：

   ```shell
   mkdir /mnt/hostrun
   mount --bind /run /mnt/hostrun
   ```

3. `archroot /mnt`进入/mnt，再执行：

   ```shell
   arch-chroot /mnt /bin/bash
   mkdir /run/lvm
   mount --bind /hostrun/lvm /run/lvm
   ```

4. 重新执行`grub-mkconfig`生成grub配置。

   退出archroot前先`umount /run/lvm`。

## 笔记本电源管理

参看wiki[Laptop](#https://wiki.archlinux.org/index.php/Laptop_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))和本人笔记[laptop笔记本相关](../laptop笔记本相关.md)

## 开机后直接进入windows系统

安装系统后重启，**直接进入了windows** 。

原因：windows的引导程序bootloader并不会将linux启动项加入到启动选择中，且windows的引导程序处于硬盘启动的默认项。（**在windows上进行重大更新后也可能出现该情况**）

解决：进入BIOS，找到启动设置，**将硬盘启动的默认启动项改为grub**，保存后重启。

## 无法启动图形界面

参看前文[图形界面](#图形界面) 。原因可能是：

- 没有安装显卡驱动（双显卡用户需安装两个驱动）
- 没有正确安装图形界面
- 没有自启动图形管理器或xinintrc书写错误

## 非root用户（普通用户）无法启动startx

重装一次`xorg-server`

## 无法挂载硬盘（不能进入Linux）

原因：**windows开启了快速启动可能导致linux下无法挂载**，提示如：

>The disk contains an unclean file system (0, 0).
>Metadata kept in Windows cache, refused to mount.

等内容。

解决：在windows里面的 电源选项管理 > 系统设置 > 当电源键按下时做什么， 去掉勾选启用快速启动。或者直接在cmd中运行：`powercfg /h off`。

## 高分辨率（HIDPI）屏幕字体过小

桌面环境设置中可调整。参考[archwiki-hidpi](https://wiki.archlinux.org/index.php/HiDPI)

## 蜂鸣声（beep/错误提示音）
去除按键错误时、按下tab扩展时、锁屏/注销等出现的“哔～”警告声。参考[archwiki-speaker](https://wiki.archlinux.org/index.php/PC_speaker)
```shell
rmmod pcspkr    #暂时关闭
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf   #直接屏蔽
```
## 没有声音

一般出现在轻量桌面(如xfce)或窗口管理器上，因为archlinux安装后默认处于静音状态。

安装`alsa-utils`，然后执行`alsamixer`进入 其ncurses 界面：

使用<kbd>←</kbd>和<kbd>→</kbd>方向键移动，选中 **Master** 和 **PCM** 声道，按下<kbd>m</kbd> 键解除静音（静音状态下其显示有`mm`字样）使用<kbd>↑</kbd>方向键增加音量。

或者直接使用以下命令解除静音：

```shell
amixer sset Master unmute
```

## 双显卡管理

更多内容可参看[双显卡管理](../laptop笔记本相关.md#显卡管理)

- 显卡切换

  在Linux中可使用以下方法来切换显卡。参看相关资料：

  - [prime](https://wiki.archlinux.org/index.php/PRIME_%28%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%29)（NVIDIA和ATI均支持）
  - [NVIDIA optimus](https://wiki.archlinux.org/index.php/NVIDIA_Optimus_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))如：
    - [bumblebee](https://wiki.archlinux.org/index.php/Bumblebee_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
    - [nvidia-xrun](https://github.com/Witko/nvidia-xrun)（该方案支持Vulkan接口）


- 关闭独显

  如果不需要运行大量耗费GPU资源的程序，可以禁用独立显卡，只使用核心显卡，一些禁用方法如：

  - 在BIOS中关闭独立显卡（不是所有设备都具有该功能）

  - 执行`echo OFF > /sys/kernel/debug/vgaswitcheroo/switch`临时关闭独立显卡（注意，如果使用了bbswtich那么应该是没有这个文件的！）。

  - 使用bbswitch

    ```shell
    #设置bbswitch模块参数
    echo 'bbswitch load_state=0 unload_state=1' > /etc/modprobe.d/bbswitch.conf
    #开机自动加载bbswitch模块
    echo 'bbswitch ' > /etc/modules-load.d/bbswitch.conf

    modprobe -r nvidia nvidia_modeset nouveau #卸载相关模块
    sudo mkinitcpio -p linux  #重新生成initramfs--系统引导时的初始文件系统
    ```

    可使用以下命令控制bbswitch进行开关显卡：

    ```shell
    sudo tee /proc/acpi/bbswitch <<<OFF  #关闭独立显卡
    sudo tee /proc/acpi/bbswitch <<<ON  #开启独立显卡
    ```

  - 屏蔽相关模块

    将独立显卡相关模块进行屏蔽，示例屏蔽NVIDIA相关模块。

    ```shell
    echo nouveau > /tmp/nvidia    #开源的nouveau
    lsmod | grep nvidia | grep -E '^nvidia'|cut -d ' ' -f 1 >> /tmp/nvidia    #闭源的nvidia
    sed -i 's/^\w*$/blacklist &/g' /tmp/nvidia  #添加为blacklist
    sudo cp /tmp/nvidia /etc/modprobe.d/nvidia-blacklist.conf  #自动加载
    
    modprobe -r nvidia nvidia_modeset nouveau #卸载相关模块
    sudo mkinitcpio -p linux  #重新生成initramfs--系统引导时的初始文件系统
    ```

    重启后检查NVIDIA开启情况：`lspci |grep NVIDIA`，如果输出内容后面的括号中出现了` (rev ff)` 字样则表示该显卡已关闭。

    注意：如果载入了其他依赖nvidia的模块，nvidia模块也会随之载入。



## SSD固态硬盘相关

参看：[Solid State Drives](https://wiki.archlinux.org/index.php/Solid_State_Drives_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))和[ssd固态硬盘优化](../ssd固态硬盘优化.md)



## windows和linux统一使用UTC

Windows使用本地时间（Localtime），而Linux则使用UTC（Coordinated Universal Time ，世界协调时）。以使用中国东八区UTC+8为例，windows会将本地东八区时间写入到硬件时钟，linux启动后认为硬件时钟的时间为UTC+0（实际是当前UTC+8的时间），于是在硬件时钟时间的基础上增加了8个小时作为本地时间。

建议更改windows注册表使windows也使用utc时间。

1. 设置windows使用utc时间为基准，而非本地时钟为基准。

   在windwos新建文件`utc.reg`，写入：

   ```shell
   Windows Registry Editor Version 5.00
   [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation]
   "RealTimeIsUniversal"=dword:00000001
   ```

   保存后，双击该文件运行，以写入注册表。

   设置系统时间为本地时间。

   

2. 设置硬件时钟为UTC。

   以北京时间为例，即设置硬件时钟为北京时间减去8小时。

   可以选择以下方法：

   - 在BIOS中根据当地所用的标准时间来设置正确的UTC时间。（例如在中国使用的北京时间是东八区时间，根据当前北京时间，将BIOS时间前调8小时）。

   - 在linux中设置正确的硬件时钟时间和时区。

     ```shell
     timedatectl set-timezone Asia/Shanghai  #确保当前设置的时区正确
     date  #查看当前本地时间 是否是当前时区时间（北京时间UTC+8）
     #hwclock -w -u
     hwclock --systohc --utc  #将当前时间写入硬件时钟且硬件时钟保持为UTC时间
     ```

     

     

   

## wayland

wayland不会读取.xprofile和xinitrc等xorg的环境变量配置文件，故而不要将某些软件的相关设置写入到上诉文件中，可写入/etc/profile、 /etc/bash.bashrc 和/etc/environment。参考[archwiki-wayland](https://wiki.archlinux.org/index.php/Wayland)、[archwiki-环境变量](https://wiki.archlinux.org/index.php/Environment_variables_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E5.AE.9A.E4.B9.89.E5.8F.98.E9.87.8F)和[wayland主页](https://wayland.freedesktop.org/)。

# 常用软件

参考看：[archwiki:软件列表](https://wiki.archlinux.org/index.php/List_of_applications_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))、[awesome linux softwares](https://github.com/LewisVo/Awesome-Linux-Software)、[我的软件列表](../我的软件列表.md)、[gnome配置](../gnome配置.md)……
