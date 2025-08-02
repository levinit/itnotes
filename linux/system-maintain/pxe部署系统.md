



# 简介

> 预启动执行环境（Preboot eXecution Environment，PXE，也被称为预执行环境)提供了一种使用网络接口（Network Interface）启动计算机的机制。这种机制让计算机的启动可以不依赖本地数据存储设备（如硬盘）或本地已安装的操作系统。

PXE 协议在启动过程分为 client 和 server 端，

server端主要提供：

- DHCP地址分配服务（abbr. Dynamic host configuration protocol）
- 引导（bootstrap）程序

pxe启动流程简介：

1. client端（BIOS里面的PXE固件）广播一个DHCPDISCOVER的包，询问所需的网络配置以及网络启动的参数。

2. server端（PXE enabled的DHCP服务器）返回包含PXE相关信息的DHCPOFFER包

   *没有配置PXE（非PXE enabled）的标准DHCP服务器只返回一个普通的DHCPOFFER包，包含网络信息（如IP地址），但并不提供PXE相关参数。*

3. client端收到DHCPOFFER包后将设置自己的IP地址，并将引导程序指向网络上的启动资源以启动引导

   启动资源是最小的操作系统，如WindowsPE，Linux的 kernel（一般名为vminuz）和initrd，client端将通过TFTP下载启动资源到内存中。

   如果是UEFI Secure Boot（而不是Legacy的BIOS）则还会检验一下这些启动资源。
   

# 准备

- PXE server端（本文使用linux系统）

  本文约定：

  - 系统为linux（示例使用rhel系列的linux）

  - 相关文件均存放在`/srv/pxe/`。

  - tftp服务根目录和web服务根目录均为`/srv/pxe`。

  - 关闭（或者配置相关策略）`selinux`和`firewalld`方便后续部署工作

    ```shell
    setenfore 0
    systemctl stop firewalld  #如果使用的iptables则关闭iptables
    ```

- 确保客户端和PXE server网络链路连通

- 客户端相关准备

  非必要，可选操作：

  - 搜集MAC地址

    DHCP地址是在设定的范围内随机分配的，预先搜集MAC地址，可以在DHCP中为指定的MAC配置固定的IP。

  - 编写hosts文件用于dnsmasq的add-hosts配置

  - 组建RAID卷（带有专用RAID控制器的设备）

  - 在BIOS/UEFI中允许通过pxe启动（一般都默认允许）

- 操作系统镜像文件

  网络启动仅需要系统引导相关文件，一些发行版有专门的netboot镜像。

- kickstart文件

  可选，使用kickstart自动安装，需要先写好kickstart文件（简称ks文件）。
  
  

# 配置pxe server

## DHC和TFTP--dnsmasq

dnsmasq包含dhcp、dns和tftp功能，无需单独安装配置这三种工具。

这里主要使用dhcp和tftp功能。

1. 安装dnsmasq

2. 配置dnsmasq（[dnmasq文档](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)）

   配置文件默认为`/etc/dnsmasq.conf`，也可以使用`-C`命令指定配置文件位置。

   这里单独编写配置文件`/srv/pxe/dnsmasq-pxe.conf`，其中`#`行表示注释，参考内容如下：

   精简版：
   
   ```shell
   port=0  #关闭dns
   dhcp-range=10.211.55.50,10.211.55.55,12h  #dhcp分配范围及地址有效时间
   
   #efi启动引导
   dhcp-boot=EFI/BOOT/grubx64.efi
   
   #tftp
   enable-tftp        #启用tftp
   tftp-root=/srv/pxe #tfp根目录
   ```
   
   更多详细配置：
   
   ```shell
   ###---基本配置
   #监听地址
   #listen-address=::1,127.0.0.1,192.168.0.251
   #绑定端口
   bind-interfaces
   #在docker容器中，user需配置为root
   #user=root
   
   ###---DNS
   #dns端口　0表示不使用dns功能（一般dns使用53端口）
   port=0
   domain=cluster
   #use a custom hosts file
   #no-resolv
   #no-hosts  #去掉该行注释将不启用本地解析文件(/etc/hosts)
   addn-hosts=/srv/pxe/addn-hosts #自定义hostname解析文件
   
   ###---DHCP
   #dnsmasq服务监听的网口，不配置表示不特别指定
   interface=eno1
   #dhcp分配地址段、租期(示例：12h 1w 1d infinite)
   dhcp-range=192.168.0.１,192.168.0.10,36h
   
   #权威服务器，在多dhcp环境中可能需要
   #dhcp-authoritative
   
   #根据指定文件分配hostname
   #dhcp-host=judge # 通过/etc/hosts
   
   #MAC绑定IP
   #dhcp-host=00:0C:29:F6:07:CA,192.168.0.1,hostname1,infinite
   #忽略这个mac地址的dhcp请求
   #dhcp-host=00:0C:29:5E:F2:3F,ignore
   
   ###---其他信息
   #dhcp-option=42,172.16.1.199  #ntp server
   #dhcp-option=3,172.16.1.199   #gateway
   #dhcp-option=6,172.16.1.199   #dns server
   #dhcp-option=v28,$broadcast   #broadcast addr
   
   ###---TFTP
   enable-tftp
   tftp-root=/srv/pxe/  #tftp根目录
   
   ###---pxe boot
   pxe-prompt=pxe-server... #pxe的提示信息
   pxe-service=X86PC,"Install OS from $server",pxelinux
   
   ##legacy BIOS
   #dhcp-boot=pxelinux.cfg/pxelinux.0
   #dhcp-boot=pxelinux.cfg/pxelinux.0,pxeserver,192.168.0.251
   
   ##UEFI
   dhcp-boot=EFI/BOOT/grubx64.efi
   
   ##同时配置legacy和uefi，根据客户端响应提供不同的启动文件
   #dhcp-boot中的tag与dhcp-match中set的值相同，根据match中set的关键字决定提供的引导文件
   #某些设备的tag可能不同，需要修改match值
   #legacy
   #dhcp-match=set:bios,option:client-arch,0
   #dhcp-boot=tag:!uefi,pxelinux.0  
   #dhcp-match=set:x86-legacy,option:client-arch,0
   #dhcp-boot=tag:x86-legacy,pxelinux.0
   
   #uefi
   #dhcp-match=set:EFI_BC,option:client-arch,7
   #dhcp-boot=tag:EFI_BC,EFI/BOOT/grubx64.efi
   #dhcp-match=set:EFI_x86_64,option:client-arch,7
   #dhcp-boot=tag:EFI_x86_64,EFI/BOOT/grubx64.efi
   #dhcp-match=set:efi-x86_64,option:client-arch,7
   #dhcp-boot=tag:efi-x86_64,EFI/BOOT/grubx64.efi
   
   
   ###---log文件
   log-queries
   #log-dhcp
   log-async=20
   cache-size=1024
   log-facility=/srv/pxe/dnsmasq.log  #log文件保存位置
   ```
   
   DHCP option 值 （RFC4578）
   
   - 9 EFI x86-64
   
3. 启动dnsmasq

   - 使用默认配置`/etc/dnsmasq.conf`：`systemctl start dnsmasq`或`dnsmasq`
   - 指定配置文件`dnsmasq -C /srv/dnsmasq-pxe.conf`



## web镜像源

使用已有的web服务器为客户端提供操作系统网络安装源。（也可以使用nfs提供网络镜像源）

示例，创建一个web镜像源：

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

> - tftp根目录
>   - pxelinux.0
>   - pxelinux.cfg
>     - default
>     - initrd.img
>     - vmlinuz

1. 在tftp根目录下创建pxelinux.cfg

1. 从系统镜像文件中，将系统内核镜像`initrd.img`和文件系统镜像`vmlinuz`放置到tftp根目录下的pxelinux.cfg中

3. pxe启动文件pxelinux.0放到tftp根目录下

   具体位置应当根据`dnsmasq.conf`中，legacy模式的`dhcp-boot`中设置的路径来确定，dnsmasq.conf中的路径是相对于`tftp-root`的相对路径。

   ​	例如`dhcp-boot`中的路径为`pxelinux.0`，则说明`pxelinux.0`应当直接放到`tftp-root`目录中。

   ​	例如`dhcp-boot`中的路径为`boot/pxelinux.0`，则说明`pxelinux.0`应当直接放到`tftp-root`目录下的`boot中。

   

   可从syslinux.org网站下载pexlinux，或者安装`syslinux`包，然后将pxelinux.0复制到tftp根目录。

   可使用包管理器查找pxelinux.0位置，例如：

   - rpm：`rpm -ql syslinux|grep -E "/pxelinux.0"`
   - pacman：`pacman -Ql syslinux|grep -E "/pxelinux.0"`

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
     append ks=http://192.168.0.199:9999/ks/leagcy-ks.cfg ip=dhcp
     ##append其他选项：text使用字符界面安装
     ##vnc相关选项启动vnc服务，使用客户端ip进行访问，这里的密码是pwd@vnc
     ##vnc_options=inst.vnc vncpassword=pwd@vnc
   ```

### UEFI

> - tftp根目录
>   - EFI
>     - BOOT
>       - grubx64.efi
>       - grub.cfg
>   - images/
>     - pxeboot
>       - vmlinuz
>       - initrd.img

1. 从镜像文件中复制EFI到tftp根目录

   主要是需要`grubx64.efi`和`grub.cfg`

   *若开启了安全启动（UEFI SecureBoot），需要使用shim.efi嵌套调用grub.efi来引导。

   

2. 从镜像文件中复制（或软链接）images到tftp根目录下

   主要是需要其中的vmlinuz和initrd.img，也可以只复制该2个文件。

   

3. 引导文件

   - ~~对于`BOOTX64.EFI`，在tftp根目录下创建`efidefault`，文件内容示例：~~

     ```shell
     default=0
     splashimage=(nd)/splash.xpm.gz
     #prompt 1
     #timeout 10
     #hiddenmenu
     title PXE_Installation
         root (nd)
         kernel /images/pxeboot/vmlinuz ks=uefi-ks.cfg
         #ks也可以使用http传输
         #kernel /images/pxeboot/vmlinuz ks=http://192.168.0.199/uefi-ks.cfg
         initrd /images/pxeboot/initrd.img
     title rescue
         root (nd)
         kernel pxelinux.cfg/6/x86_64/vmlinuz rescue askmethod
         initrd pxelinux.cfg/6/x86_64/initrd.img
     ```

     

   - 对于`grubx64.efi`，编辑EFI/BOOT/grub.cfg文件，内容示例：

     主要内容是修改 kernel和initrd的配置行。参考[redhat文档-引导选项](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options)

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
     
     menuentry 'Install Red Hat Enterprise Linux 7.9' --class fedora --class gnu-linux --class gnu --class os {        
             #路径以tftp的web根目录为/
             linuxefi /images/pxeboot/vmlinuz inst.repo=http://10.211.55.19:9999/os/ inst.ks=http://10.211.55.19:9999/ks/uefi-ks.cfg
             initrdefi /images/pxeboot/initrd.img
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

# Run the Setup Agent on first boot
firstboot --disable

# System language
lang en_US.UTF-8
#lang en_US --addsupport=zh_CN #additional lang

# Keyboard layouts
keyboard --vckeymap=cn --xlayouts='us'

# System timezone
timezone Asia/Shanghai --isUtc #--nontp

# OS Source
#--- Use network installation
url --server=10.211.55.19:9999/os/
#nfs --server=172.168.0.251 --dir=/srv/repo/os

# Network information
network  --bootproto=dhcp --hostname=localhost.localdomain
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
#------CentOS minimal installation---only below packages
@core
@^minimal
kexec-tools
#CentOS minimal installation---only above packages

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

