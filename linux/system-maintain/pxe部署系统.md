



# 简介

> 预启动执行环境（Preboot eXecution Environment，PXE，也被称为预执行环境)提供了一种使用网络接口（Network Interface）启动计算机的机制。这种机制让计算机的启动可以不依赖本地数据存储设备（如硬盘）或本地已安装的操作系统。

PXE 协议在启动过程分为 client 和 server 端，假设DHPC、TFTP和web镜像服务均由一台主机提供，称之为部服务器，其余要被部署系统的设备称为客户端。

> 客户端 PXE 网卡启动 --> 通过 Bootp 协议广播 dhcp 请求 --> DHCP 服务器 --> 获取 IP，TFTP 服务器地址 --> 从 TFTP 服务器下载boot/{vmlinuz,initrd.img}或者读取 NFS 文件共享服务器共享boot目录 --> 启动系统 --> 到制定 url 去下载kickstart文件 --> 根据kickstart文件去 NFS/HTTP/FTP服务器自动下载软件包安装系统

# 准备

相关准备工作。

- 一台Linux主机，作为PXE服务器，配置静态IP地址。

- 确保客户端（要安装操作系统的计算机）和PXE服务器的网络物理连接正确（网线直连/交换机）

- 客户端根据需求进行相关操作，一般有：

  - 搜集各个客户端的使用的网卡的MAC地址

    可选，因DHCP地址是随机分配的，在需要按设备摆放位置顺序进行IP分配的情况下很有必要，方便后续管理。

  - 具有RAID卡的设备如需使用RAID，需要配置好RAID。

  - 按需配置BIOS中其他选项。

  - hosts文件（可选）

- 操作系统镜像文件

# 约定说明和目录结构

为方便叙述，本文约定配置如下（以实际情况修改）：

- 客户端要安装的操作系统（非PXE服务器上的系统）为CentOS7，使用CentOS的iso文件，假设为`/srv/pxe/cent7.iso`。

- 相关文件均存放在`/srv/pxe/`。

  tftp服务根目录和web服务根目录均为`/srv/pxe`。

- PXE服务器网络配置：网口`eno1`，地址`192.168.0.251/24`。

- 客户端使用IP范围：`192.168.0.1-10`。

  dhcp服务自动在范围内向客户端分配IP，如果在dhcp服务配置中使用MAC地址绑定IP，DHCP服务器会根据客户端网卡MAC地址分配指定iP。

- hosts文件(可选)：`/srv/pxe/add_hosts`或`/etc/hosts`

  内容示例：

  > 192.168.0.1  c01
  >
  > 192.168.0.2 c02

- 关闭（或者配置相关策略）`selinux`和`firewalld`方便后续部署工作

  ```shell
  setenfore 0
  systemctl stop firewalld  #如果使用的iptables则关闭iptables
  ```

- 后文配置完成后`/srv/pxe`目录结构示例，其中带`/`表示其为一个目录。

  > - pxelinux.cfg/  (legacy BIOS启动相关文件，可从镜像文件中的isolinux复制)
  >   - default  (可参看isolinux下isolinux.cfg)
  >   - pxelinux.0
  >   - vmlinuz  (可复制自isolinux)
  >   - initrd.img  (可复制自isolinux)
  >   - 其余省略...
  > - efidefault  (uefi安装配置文件)
  > - EFI  （UEFI启动文件，可从镜像文件中的EFI目录复制）
  >   - images/  (可复制自镜像文件中的images) 
  >     - vmlinuz
  >     - initrd.img
  >     - 其余省略...
  >   - BOOT  (复制自EFI/BOOT)
  >     - BOOTX64.EFI
  >     - grub.cfg
  >     - 其余省略...
  > - os  (系统ISO镜像文件挂载或解压目录）
  > - ks  (kickstart 文件)
  >   - legacy-ks.cfg
  >   - uefi-ks.cfg
  > - dnsmasq-pxe.conf  (dnsmasq配置文件)
  > - dnsmasq.log  (dnsmasq-pxe.conf指定的log日志路径，运行dnsmasq后生成)
  > - addn-hosts  (自定义hosts文件)

# 安装配置相关工具

## DHC和TFTP--dnsmasq

dnsmasq包含dhcp、dns和tftp功能，无需单独安装配置这三种工具。

这里主要使用dhcp和tftp功能。

1. 安装dnsmasq。

2. 配置dnsmasq。

   [dnmasq文档](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)

   配置文件默认为`/etc/dnsmasq.conf`，也可以使用`-C`命令指定配置文件位置。

   这里单独编写配置文件`/srv/pxe/dnsmasq-pxe.conf`，其中`#`行表示注释，参考内容如下：

   ```shell
   ###DNSMASQ基本配置
   #dnsmasq服务监听的网口，不配置表示不特别指定
   interface=eno1
   #监听地址
   #listen-address=::1,127.0.0.1,192.168.0.251
   #绑定端口
   bind-interfaces
   #在docker容器中，user需配置为root
   #user=root
   #权威服务器，在多dhcp环境中可能需要
   #dhcp-authoritative
   
   ###DHCP
   #dhcp分配地址段、租期(示例：12h 1w 1d infinite)
   dhcp-range=192.168.0.１,192.168.0.10,36h
   #MAC绑定IP
   #dhcp-host=00:0C:29:F6:07:CA,192.168.0.1,hostname1,infinite
   #忽略这个mac地址的dhcp请求
   #dhcp-host=00:0C:29:5E:F2:3F,ignore
   
   #dns端口　0表示不使用dns功能（一般dns使用53端口）
   port=0
   
   #dhcp-option=42,172.16.1.199  #ntp server
   #dhcp-option=3,172.16.1.199  #gateway
   #dhcp-option=6,172.16.1.199  #dns server
   
   ##host
   #根据指定文件分配hostname
   #dhcp-host=judge # 通过/etc/hosts
   #no-hosts  #去掉该行注释将不启用本地解析文件(/etc/hosts)
   #addn-hosts=/srv/pxe/addn-hosts #自定义hostname解析文件
   #no-resolv
   
   ###TFTP
   enable-tftp
   tftp-root=/srv/pxe/  #tftp根目录
   
   ###启动文件
   pxe-prompt=pxe-server... #pxe的提示信息
   pxe-service=X86-64,"Install OS from $server", EFI/BOOT/grubx64.ef,pxelinux
   
   ##legacy或uefi配置
   #legacy BIOS
   #dhcp-boot=pxelinux.cfg/pxelinux.0
   #dhcp-boot=pxelinux.cfg/pxelinux.0,pxeserver,192.168.0.251
   #UEFI
   #dhcp-boot=EFI/BOOT/BOOTX64.EFI
   
   ##同时配置legacy和uefi，根据客户端响应提供不同的启动文件
   #dhcp-boot中的tag与dhcp-match中set的值相同
   #根据match中set的关键字决定提供的引导文件
   #某些设备的tag可能不同，需要修改match值
   #legacy
   dhcp-match=set:bios,option:client-arch,0
   dhcp-match=set:x86-legacy,option:client-arch,0
   #dhcp-boot=tag:!uefi,pxelinux.0  
   dhcp-boot=tag:x86-legacy,pxelinux.cfg/pxelinux.0
   
   #uefi
   dhcp-match=set:uefi,option:client-arch,7
   #dhcp-match=set:efi-x86_64,option:client-arch,7
   #dhcp-match=set:x86_64-uefi,option:client-arch,7
   #dhcp-match=set:x86_64-uefi,option:client-arch,9
   dhcp-boot=tag:uefi-x86_64,EFI/BOOT/BOOTX64.EFI
   
   ###log文件
   log-queries
   #log-dhcp
   log-async=20
   cache-size=1024
   log-facility=/srv/pxe/dnsmasq.log  #log文件保存位置
   ```

3. 启动dnsmasq

   - 使用默认配置`/etc/dnsmasq.conf`：`systemctl start dnsmasq`或`dnsmasq`
   - 指定配置文件`dnsmasq -C /srv/dnsmasq-pxe.conf`

## web镜像源--darkhttpd

web服务器为客户端提供操作系统网络安装源。（也可以使用nfs提供网络镜像源）

1. 挂载系统镜像文件

   ```shell
   mkdir -p /srv/pxe/os
   mount -o loop /srv/pxe/cent7.iso /srv/pxe/os
   ```

2. 提供web服务

   安装`darkhttpd`（或者其他web服务工具如nginx、apache代替），执行`darkhttpd <系统文件根目录路径>`即可，默认监听8080端口。

   ```shell
   sudo darkhttp /srv/pxe --port 80
   ```

## 引导文件和配置

### Legacy BIOS

> - pxelinux.cfg
>   - default
>   - initrd.img
>   - vmlinuz
>   - pxelinux.0

1. 从系统镜像文件中，将系统内核镜像`initrd.img`和文件系统镜像`vmlinuz`放置到tftp根目录下的pxelinux.cfg。

2. pxe启动文件pxelinux.0放到tftp根目录下的pxelinux.cfg下。

   从syslinux.org网站下载pexlinux，或者安装`syslinux`包，然后将pxelinux.0复制到tftp根目录。

   可使用包管理器查找pxelinux.0位置，例如：

   - rpm：`rpm -ql syslinux|grep pxelinux`
   - pacman：`pacman -Ql syslinux|grep pxelinux`

3. 引导文件pxelinux.cfg

   从镜像中复制isolinux目录到tftp根目录改为pxelinux.cfg，修改其下的isolinux.cfg文件名问为default，或者在tftp根目录下新建pxelinux.cfg目录，在其中新建一个pxelinux.cfg：

   ```shell
   #默认选中的选项(label) linux是label的名字
   #用数字时则是按顺序排列 0表示选中第一个
   #或default=0，  可使用=赋值，下同
   default 0  
   #prompt 1  #0表示不询问(默认) 1表示询问（多label可选时需要）
   #timeout 60  #菜单选择时间 和prompt 1配合
   label 0
     kernel pxelinux.cfg/vmlinuz
     initrd pxelinux.cfg/initrd.img
   #ks指定kickstart文件uri（或inst.ks表示仅用于安装的kickstart文件）
   #ip=dhcp表示随机分配ip
     append ks=http://192.168.0.199/ks/leagcy-ks.cfg ip=dhcp
     ##append其他选项：text使用字符界面安装
     ##vnc相关选项启动vnc服务，使用客户端ip进行访问，这里的密码是pwd@vnc
     ##vnc_options=inst.vnc vncpassword=pwd@vnc
   ```

### UEFI

> - efidefault
> - EFI
>   - images/
>     - pxeboot
>       - vmlinuz
>       - initrd.img
>   - BOOT
>     - BOOTX64.EFI
>     - grub.cfg

1. 从镜像文件中复制EFI到tftp根目录

   主要是使用其中的BOOTX64.EFI。

   *若开启了安全启动（UEFI SecureBoot），需要使用shim.efi嵌套调用grub.efi来引导。

2. 从镜像文件中复制images到tftp根目录下

   主要是需要其中的vmlinuz和initrd.img，也可以只复制该2个文件。

3. 在tftp根目录下创建efidefault（BOOTX64.EFI默认使用该配置）文件内容如下：

   #todo待测试 或不需要

   ```shell
   default=0
   splashimage=(nd)/splash.xpm.gz
   #prompt 1
   #timeout 10
   #hiddenmenu
   title PXE_Installation
       root (nd)
       kernel /images/pxeboot/vmlinuz ks=http://192.168.0.199/uefi-ks.cfg
       initrd /images/pxeboot/initrd.img
   title rescue
       root (nd)
       kernel pxelinux.cfg/6/x86_64/vmlinuz rescue askmethod
       initrd pxelinux.cfg/6/x86_64/initrd.img
   ```

4. 编辑EFI/BOOT/grub.cfg文件（主要是修改vmlinuz和initrd.img位置），或删除该文件并重新创建，内容如下：

   ```shell
   set default="0"  #默认选中的grub项目
   
   function load_video {
     insmod efi_gop
     insmod efi_uga
     insmod video_bochs
     insmod video_cirrus
     insmod all_video
   }
   
   load_video
   set gfxpayload=keep
   insmod gzio
   insmod part_gpt
   insmod ext2
   
   #label选择等待时间 原grub等待时间可能较长
   set timeout=5
   
   #禁止掉过时的软盘驱动检测(未来的5.x内核已经抛弃了floppy，那时侯就可以不用管这个啦)
   search --no-floppy --set=root -l 'CentOS 7 x86_64'
   
   menuentry 'Install Linux' --class fedora --class gnu-linux --class gnu --class os {
     #inst.stage2要修改为web源的uri
     linuxefi /images/pxeboot/vmlinuz inst.stage2=http://192.168.0.199/os ip=dhcp inst.ks=http://192.168.0.199/ks/uefi-ks.cfg
     ##inst.cmdline inst.sshd vnc_options=inst.vnc vncpassword=pwd@vnc
     initrdefi /images/pxeboot/initrd.img #quiet
     #inuxefi /BOOT/images/pxeboot/vmlinuz inst.repo=http://192.168.0.199/os inst.ks=http://192.168.0.199/ks/uefi-ks.cfg
   }
   ```

   


## 自动化安装系统--kickstart（可选）

红帽公司开发的kickstart工具，以自动化安装方式代替传统交互式安装方式。

kickstart的配置文件（以下称为`ks.cfg`）中含有系统安装时各种配置参数，可参照[创建 Kickstart 文件](#https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/6/html/installation_guide/s1-kickstart2-file)手册编写配置文件，此外还可按以下方式取得配置文件kc.cfg：

- 手动安装的rhel/centos系统的/root家目有`anaconda-ks.cfg`文件可供参考。

  注意：kickstart文件中含有root管理员及其他用户（如果安装时创建过这些用户）密码（安装时设置的密码），因此在安装完成后务必修改用户密码或保存好`/root`目录下的kickstart文件。

- 使用图形界面工具`system-config-kickstart`生成。

可安装` pykickstart`用以验证ks文件的正确性。

```shell
ksvalidator ks.cfg  #如果没任何输出则表示没有问题
ksverdiff -f RHEL6 -to RHEL7  #在CentOS 7系统查看CentOS 6与7的ks版本区别
```

注意：配置文件中，disk相关项特别重要，尤其是涉及可能需要保存的数据，使用务必检查clearpart、ignoredisk相关项。`%packages`部分的包名应根据实际情况填写。

ks.cfg示例

```shell
#version=DEVEL
# Install OS instead of upgrade
#upgrade
install

# Reboot after installation
reboot
#poweroff

# Installation
graphical
#text

# System language
lang en_US.UTF-8
#lang en_US --addsupport=zh_CN #additional lang

# System timezone
timezone Asia/Shanghai --isUtc #--nontp

# Keyboard layouts
keyboard --vckeymap=cn --xlayouts='us'

# OS Source
#--- Use network installation
url --server=192.168.0.251/os
#nfs --server=172.168.0.251 --dir=/srv/repo/os

# Network information
network  --bootproto=dhcp -activate --hostname=localhost.localdomain
#network  --bootproto=static --device=em1 --ip=192.168.10.251 --netmask=255.255.255.0 --ipv6=auto --activate --hostname=master


#=======only for mbr=======start
# Clear the Master Boot Record
#zerombr

# System bootloader configuration
#bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
#=======only for mbr=======end

#=======clear and specify disk=======start
#clear at first
clearpart --all --initlabel
#clearpart --drives=sda --all

#specify the disk
#ignoredisk --only-use=sda
#=======clear and specify disk=======end


#=======partition=======start
#autopart
#autopart --type=lvm  #type value: plain | thin | btrfs

#~~~(if selected autopart ,should disabled all about part size plan below )

#===specify part size---standard mode
#boot
part /boot --fstype="ext4" --ondisk=sda --size=256

#EFI(not necessary for Legacy BIOS boot)
part /boot/efi --fstype="efi" --ondisk=sda --size=256 --fsoptions="umask=0077,shortname=winnt"

#swap (Swap file is a good alternative to swap partition)
#/
#part / --fstype="ext4" --ondisk=sda --size=1

#===specify part size---LVM mode
#---PV---physical volume(size 1 means "all space")
part pv.01 --fstype="lvmpv" --ondisk=sda --size=1 --grow

#---VG---lvm group
volgroup linux --pesize=4096 pv.01  #linux is the lvm group name

#---LV---logical volumes
#swap
logvol swap --fstype="swap" --size=8192 --name=swap --vgname=linux
#root
logvol / --fstype="ext4" --grow --size=1 --name=root --vgname=linux
#=======partition=======end

# System authorization information
auth --enableshadow --passalgo=sha512

# Root password
#this crypted password is "root"
#rootpw --iscrypted $1$NUnfNNYO$Tz./plpwPFs2Blb2VuSnQ/
rootpw --plaintext root

# System services
services --enabled="chronyd" --disabled="postfix"

# SELINUX configuration
selinux --disabled #default is enable (Enforcing)

# Firewall configuration
firewall --disabled


# Run the Setup Agent on first boot
firstboot --disable

# X Window System configuration information
#xconfig  --startxonboot
skipx

# License agreement
eula --agreed

#save screenshots   #/root/anaconda-screenshots
#autostep --autoscreenshot #May cause errors 


%packages
#@gnome-desktop
#@^gnome-desktop-environment
#@desktop-debugging
#@dial-up
#@directory-client
#@fonts
#@base
#@guest-agents
#@guest-desktop-agents
#@input-methods
#@internet-browser
#@java-platform
#@multimedia
#@network-file-system-client
#@networkmanager-submodules
#@print-client
#@x11

#CentOS minimal installation---only below
@core
@^minimal
kexec-tools
#CentOS minimal installation---only above

chrony
pciutils
psmisc
vim
nfs-utils
tmux
tcl-devel
tk-devel
lsof
gcc
gcc-c++
make
chrony
ypbind
yp-tools

%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end

#user password configurations
%anaconda
pwpolicy root --minlen=4 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
```

