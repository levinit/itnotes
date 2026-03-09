Cobbler是一个快速网络安装系统的服务。[官方网站](https://cobbler.github.io/) [github仓库](https://github.com/cobbler/cobbler) 

本文基于centos 7.x。

cobbler运行流程：

1. PXE客户端向服务端的DHCP服务发送分配IP地址的请求
2. DHCP服务端接收请求，给客户端分配IP地址
3. 客户端从服务端下载引导文件，执行引导程序

[TOC]

批量部署需要的条件

- 客户机支持PXE

  PXE，Preboot eXecution Environment，预执行环境。使用网络接口（Network Interface）启动计算机的机制。客户机以PXE启动，通过网络从远端服务器下载系统镜像，然后启动操作系统。

- 服务器端和客户端建立网络通信(DHCP)

  在服务器上运行DHCP server，为DHCP 客户机（使用PXE启动的客户机）动态分配IP地址。

- 服务器端要有可供客户机开机引导的引导文件

- 服务器端的可引导文件还必须能传递到客户机（TFTP）

  服务器上的TFTP目录下存放相关文件（操作系统文件、配置文件等），使用PXE启动的客户机通过服务器的TFTP服务下载需要的文件。

- 客户机包括安装定制的软件或服务（KICKSTART文件）

  KickStart的工作原理：将典型的安装过程中所需人工干预填写的各种参数写入到ks.cfg的文件；在安装过程中（不只局限于生成KickStart安装文件的机器），当出现要求填写参数的情况时，安装程序会首先去查找ks.cfg文件的参数，依照设置的参数进行自动操作。

---

# 准备工作

- 安装epel源（如过未安装）

  ```shell
  yum install -y epel-release
  yum makecache
  ```

- 关闭selinux和防火墙

  ```shell
  systemctl stop firewalld  #暂时关闭防火墙
  setenforce 0  #暂时关闭selinux
  ```

  完全关闭selinux需要编辑`/etc/sysconfig/selinux`，将其中的`SELINUX=enforcing`修改为`SELINUX=disabled`。

## 需要的工具及对应的服务

安装需要的工具，启动相应的服务（使用`systemd` ）：

| 包名                      | 服务名      | 说明                   |
| ----------------------- | -------- | -------------------- |
| cobbler                 | cobblerd | cobbler程序包           |
| pykickstart             |          | kickstart文件管理        |
| rsync                   | rsyncd   | 同步工具                 |
| tftp                    | tftpd    | 小型文件传输服务             |
| dhcp                    | dhcpd    | 动态主机配置服务（可选）         |
| bind                    | named    | DNS服务（可选）            |
| dnsmasq                 | dnsmasq  | 管理DHCP和DNS（可选）       |
| httpd                   | httpd    | apache web服务（可选）     |
| cobbler-web             |          | cobbler的web服务包（可选）   |
| fence-agents            |          | 电源管理工具 （可选）          |
| system-config-kickstart |          | 生成kickstart文件的工具（可选） |

附注：

- [cobbler-web](#cobbler-web)需要httpd
- system-config-kickstart是图形界面工具
- 名词：
  - tftp, Trivial File Transfer Protocol  简单文件传输协议
  - dhcp, Dynamic Host Configuration Protocol  动态主机配置协议
  - bind, Berkeley Internet Name Daemon 伯克利互联网名称服务

# 配置流程

相关提示

- 修改配置后务必重启相关服务并将更改同步到文件系统：

  ```shell
  systemctl restart xx xx  #重启各项服务
  cobbler sync  #同步更改
  ```

- 可以执行[cobbler check进行配置检查](#配置检查)。

- 以下配置中，假设cobbler服务器的ip为**192.168.100.1**。获取服务器ip可在服务器运行：

  ```shell
  ip addr | grep inet
  ip addr | grep -o -P '1[^2][0-9?](\.[0-9]{1,3}){3}(?=\/)'
  ```

## cobbler

### 配置cobbler管理的服务

cobbler的运行依赖于dhcpd、tftpd、dns及rsyncd服务，cobbler可自行管理这些服务中的部分甚至是全部，本文配置场景均使用cobbler管理这些服务。

这些服务的提供者有：

- dhcpd：dhcpd(ISC) 或 dnsmasq
- dns：bind 或 dnsmasq
- tftpd：tftp-server 或 cobbler 的内部 tftp（默认启用）
- rsyncd：rsync  （默认启用）

提示：如果使用既有的DHCP服务，则略过dhcp相关配置。

需要编辑`/etc/cobbler/settings`，启用需要cobbler管理的服务，以下是该文件中常用服务的配置示例：

```shell
#0表示禁用 1表示启用
manage_dhcp: 1  #DHCP服务
manage_dns: 0  #DNS服务
manage_tftpd: 1  #tftp服务
manage_rsync: 1  #rsync
restart_dhcp: 1  #自动重启dhcp（当配置发生更改时）
restart_dns: 0  #自动重启dns（当配置发生更改时）
pxe_just_once: 1  #仅安装一次（可选）
allow_dynamic_settings: 1  #动态更新（可选）

next_server: 192.168.0.9  #服务器的 IP 地址 DHCP需要
server: 192.168.0.9  #cobbler服务需要
# kickstart安装的系统的初始root密码（以下加密字符串解密后是root）
default_password_crypted: "$1$3jlvufj0$KJ.Ed2rDy8ijM7sQ35OaM/"
```

使用以下方法生成root密码的加密字符串：

```shell
openssl passwd -1  #注意这是1不是l 执行命令后会提示输入两次密码
#或 使用-salt参数进行“加盐”将salt word替换成一个自定义字符串
openssl passwd -1 -salt 'salt-word' <yourpassword>
```

提示：

- 使用`openssl --help`可以查看更多的加密方式，`-1`使用的是MD5。 


- 可以使用类似这样的命令对setting文件进行配置：

  ```shell
  cobbler setting edit --name=pxe_just_once --value=1
  ```

- 可执行以下命令查询cobbler管理的服务的基本配置：

  ```shell
  cobbler setting report | grep -E '^(manage_|server|next_server)'
  ```

### DHCP和DNS

提示：

- *nix DHCP server 对 IP 的分配是从高到低的，Windows则相反。
- 多个DHCP服务器在同一物理网段中时，客户端计算机分配到的网络参数信息来自于最先响应的那个服务器，因此在已经正常运作的网络中运行新的DHCP服务器，可能会使得该网段原有设备连接到新部署的DHCP服务器上。为避免这种干扰，需要选择合适的地址池（ip段，即配置中的range项），或可关闭地址池。

#### ISC DHCP server管理的DHCP

如果使用dnsmasq，直接参阅下文[dnsmasq管理DHCP和DNS](#dnsmasq管理DHCP和DNS)。

编辑`/etc/cobbler/dhcp.template`（部分配置内容示例，主要配置subnet部分）：

```shell
subnet 192.168.100.0 netmask 255.255.255.0 {  #网段 这里分配到192.168.100.x
     option routers             192.168.0.9;   #网关就是上文settings中的server ip
     option domain-name-servers 192.168.0.9;  #dns服务器地址  同上
     option subnet-mask         255.255.255.0;  #子网掩码
     #dhcp服务器IP地址租用的范围  可注释该行关闭地址池
     range dynamic-bootp        192.168.100.1 192.168.100.10;
    #中间部分内容略
}
#dhcp分组
group {
host name1 {  #name是主机名 注意 该网络中主机名不可重复 否则会报错
    hardware ethernet A4:DC:BE:F2:06:31;  #MAC地址
    fixed-address 192.168.30.50;  #分配的静态IP
        }
 #host name2
 #......
    ｝
```

#### bind管理DNS服务

编辑`/etc/cobbler/named.template`，监听端口和地址以及DNS转发等参数：

```shell
options {
          listen-on port 53 { 127.0.0.1; };  #127.0.0,1只允许本地网络访问
		 #中间略
          allow-query     { localhost; };
          recursion yes;
          ##DNS转发到上游DNS服务器添加下面这行(这里使用了Google DNS)
          # forwarders { 8.8.8.8; 8.8.4.4; };
};
```

#### dnsmasq管理DHCP和DNS

如果使用ISC管理dhcp、bind管理dns，可直接参考上文[ISC DHCP server管理的DHCP](#ISC DHCP server管理的DHCP) 和[bind管理DNS服务](#bind管理DNS服务)。

需要安装`dnsmasq`包。

- 编辑`/etc/cobbler/modules.conf`，修改相关服务管理工具为dnsmasq：

  ```shell
  [dns]
  module = manage_dnsmasq
  [dhcp]
  module = manage_dnsmasq
  ```

- 编辑` /etc/cobbler/dnsmasq.template` 上的`dnsmasq` 模板来修改网络配置相关信息：

  ```shell
  read-ethers
  addn-hosts = /var/lib/cobbler/cobbler_hosts

  dhcp-range=192.168.100.1,192.168.100.10,255.255.255.0  #分配的IP段 可不写掩码
  dhcp-option=66,$next_server
  dhcp-lease-max=1000
  dhcp-authoritative
  dhcp-boot=pxelinux.0
  dhcp-boot=net:normalarch,pxelinux.0
  dhcp-boot=net:ia64,$elilo
  #dhcp-ignore=tag:!known  #忽略未注册的客户端从服务器引导
  #dhcp-host=11:22:33:44:55:66,ignore  #忽略该MAC的主机
  tftp
  $insert_cobbler_system_definitions
  ```


### tftp

编辑`/etc/xinetd.d/tftp`，将其中的`disable`项的值改为`no`即可：

```shell
service tftp {
	disable           = no    #默认yes 更改为no
    socket_type = dgram
    protocol         = udp
    wait                 = yes
    user                 = root
    server             = /usr/sbin/in.tftpd
    server_args  = -B 1380 -v -s /var/lib/tftpboot
    per_source   = 11
    cps                   = 100 2
    flags                = IPv4
}
```
### cobbler引导文件

执行`cobbler get-loaders`进行下载。


## 配置检查

运行`cobbler check`检查存在的问题，该命令会列出一份需要解决的问题清单。

常见问题的解决（注意，部分列出的问题需要在解决后**重启`cobblerd`服务并执行`cobbler sync`**才能从问题清单中移除）：

- > The 'server' field in /etc/cobbler/settings must be set to something...

  修改[cobbler配置](#cobbler)文件`/etc/cobbler/settings` 文件中`server:` 的IP地址。

- > For PXE to be functional, the 'next_server' field in /etc/cobbler/settings must be set...

  修改[cobbler配置](#cobbler)文件`/etc/cobbler/settings` 文件中`next_server:` 的IP地址。

- > SELinux is enabled...

  [关闭selinux](#关闭selinux和防火墙)。

- > change 'disable' to 'no' in /etc/xinetd.d/tftp...

  [启用tftp](#tftp)： 编辑`/etc/xinetd.d/tftp`，将其中的`disable`项的值改为no即可。

- > some network boot-loaders are missing from /var/lib/cobbler/loaders...run 'cobbler get-loaders' to download them

  提示要求使用cobbler get-loaders从网上下载[引导文件](#cobbler引导文件) 。

- > debmirror package is not installed, it will be required to manage debian deployments and repositories

  提示deb的包没有被安装，如果**不打算部署debian系统可以忽略**，否则安装`debmirror`这个包。

- > comment out 'dists' on /etc/debmirror.conf for proper debian support
  > comment out 'arches' on /etc/debmirror.conf for proper debian support

  需要安装debian系统，并安装了`debmirror`可能会出现此类提示，修改`/etc/debmirror`文件，按照提示去掉相应行的注释。

- > The default password ... try:default_password_crypted "openssl passwd -1 -salt 'random-phrase-here' 'your-password-here'"...

  参看[配置cobbler管理的服务](#配置cobbler管理的服务)中设置密码的方法。

- > fencing tools were not found, and are required to use the (optional) power management features...

  可选安装包`fence-agents`（或者`fence-agents-all` ），用于电源管理模块，可选。

## 导入系统镜像

cobbler组件概念：

- distro  发行版即即“操作系统”，导入iso时，会自动生成一个distro；
- profile  部署时的配置文件（本文中指的[kickstart](#kickstart)文件)，即“操作系统” + “具体的系统安装参数”；
- system  具体的实例。

---

1. 准备系统镜像（这里是`/root`目录下名为CentOS-7-x86_64-Minimal-1708.iso的镜像 ）

2. 要挂在镜像的目录 （这里使用`/mnt/iso`这个目录）

3. 使用`cobbler import`命令导入

4. 为了在客户机部使用PXE署系统时，让默认启动项就是本次要部署的profile，**建议将该profile对应到default上**（可选）

   ```shell
   mkdir /mnt/iso
   mount -o loop /root/CentOS-7-x86_64-Minimal-1708.iso /mnt/iso  #挂载镜像
   cobbler import --arch=x86_64 --path=/mnt/iso --name=centos7.4  #导入
   #上面的命令将生成  名为centos7.4-x86_64的profile  名为centos7.4-x86_64的distro
   cobbler system add --name=default --profile=centos7.4-x86_64
   ```

   提示：默认情况下，客户机PXE启动后第一项是local（即硬盘启动，为默认启动项），后面项才是添加的profile，且该界面**需要手动选择启动项**，**超时（默认200s）后会自动选择从local启动**。可以按照上方第4步的方法将第一启动项设为要安装的profile，或者编辑`/var/lib/tftpboot/pxelinux.cfg/default`，设置`ONTIMEOUT`为要部署的profile：

   ```shell
   DEFAULT menu
   PROMPT 0
   MENU TITLE Cobbler | http://cobbler.github.io/  #标题名
   TIMEOUT 5  #将默认超时改短 默认是200(单位秒)
   TOTALTIMEOUT 60
   ONTIMEOUT centos7.4-x86_64  #将超时启动项改成了下面的第二个LABEL 默认是local

   LABEL local  #启动项1 硬盘启动
           MENU LABEL (local)
           MENU DEFAULT
           LOCALBOOT -1

   LABEL centos7.4-x86_64  #启动项2 这是本次要部署的目标
   # 部分内容略
   MENU end
   ```

bobbler import` 部分参数：

- `--arch=`操作系统架构：`x86_64` `i686`
- `--path=`镜像文件路径
- `--name=`系统名（可自定义）
- `--os-version=`系统版本号



distro和profile常用命令：

```shell
cobbler distro list  #查看distro 列表
cobbler profile list  #查看profile 列表
cobbler distro report --name=centos7.4-x86_64  #查看某个导入镜像的详细信息

cobbler distro remove --name=centos7.4-x86_64  #删除名为centos7.4-x86_64的distro
cobbler profile remove --name=centos7  #删除名为centos7的profile
```

## kickstart

### 指定kickstart配置文件

编写好ks文件（后缀名`.cfg` ）后，将其复制到 `/var/lib/cobbler/kickstarts`，并将其指定为某个镜像文件对应的ks配置文件（假如该ks文件为`/root/ks.cfg` ）：

```shell
cobbler profile add --name=centos7 --distro=centos7.4-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos7.kc.cfg
cobbler sync  #务必进行一次同步
```

提示：运行`cobbler distro list`和`cobbler profile list`获取准确的name和distro值。

推荐使用图形界面的kickstart工具system-config-kickstart。

### kickstart文件示例

参看[redhat-kickstart文件](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/6/html/installation_guide/s1-kickstart2-file)

```shell
#version=DEVEL

# Use text/graphical mode install
text
#graphical

# Installation method
url --url= https://192.168.100.1/cobbler/ks_mirror/centos7.4/
#nfs --server=192.168.100.1  --dir=/srv/nfs/centos7.4
#cdrom
#harddrive

# Install OS instead of upgrade
install
#upgrade

# Action after installation
reboot
#poweroff
#halt

# Partition clearing information
clearpart --all --initlabel
#clearpart --none --initlabel
#clearpart  --drives=sda  --all

# Clear the Master Boot Record
zerombr

# Disk Partitioning information
autopart
#autopart --type=lvm
# part /boot --fstype="vfat" --size=200
# part pv.008 --size=61440
# volgroup vg0 --pesize=8192 pv.008
# logvol / --fstype=ext4 --name=root --vgname=vg0 --size=20480
# logvol swap --name=swap --vgname=vg0 --size=2048
# logvol /usr --fstype=ext4 --name=usr --vgname=vg0 --size=10240
# logvol /var --fstype=ext4 --name=var --vgname=vg0 --size=20480

# System bootloader configuration
bootloader --append=" crashkernel=auto rhgb quiet" --location=mbr --boot-drive=sda,hda,vda

# Run the Setup Agent on first boot
firstboot --disable
#firstboot --enable
#ignoredisk --only-use=vda

# Keyboard layouts
keyboard us
#keyboard --vckeymap=cn --xlayouts='cn'

# System language
lang en_US.UTF-8
#lang en_US
#lang zh_CN.UTF-8

# System timezone
timezone Asia/Shanghai --isUtc

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
network  --hostname=manager
#network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.100.2 --netmask=255.255.255.0 --gateway=192.168.100.1 --nameserver=192.168.100.1

# Root password
rootpw --iscrypted $default_password_crypted

# System authorization information
auth --enableshadow --passalgo=sha512

# Firewall
firewall --disabled
#firewall --service=ssh
#firewall --port=22:tcp
#firewall --port=2049:udp
#firewall  --port=22:tcp,25:tcp,80:tcp   --trust eth1

# SELinux configuration
selinux --disabled
#selinux --permisive
# selinux --enforcing

# System services
services --enabled="chronyd"
services  --disabled  cups,kdump,acpid,portreserve

# additional repostories get added here
$yum_repo_stanza

# Packages what will be installed
%packages

# Packages group
@^minimal
@core
@base
#@base-x
 
epel-release
#firefox

# chrony: NTP client
chrony 

# kexec-tool: Load another kernel from the currently executing Linux kernel
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

#%pre

#%end

%post
# create user
#useradd admin
#passwd -d admin

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
```



---

# cobbler-web

使用web界面管理cobbler。

提示：web界面访问需要使用**https**，地址是`https://服务器ip/cobbler_web`。

## 用户认证

cobbler有三种能认证用户登录cobbler_web的方式：默认、LDAP和PAM。

提示：

- 默认用户名：cobbler  默认密码 ：cobbler
- 启用了LDAP/PAM后，默认方式下使用`htdigest`添加的用户无法再登入。


- 默认方式

  确保`/etc/cobbler/modules.conf`中`[authentication]`和`[authentication]`项如下（默认即如此）：

  ```shell
  [authentication] 
  module = authn_configfile 
  [authorization] 
  module = authz_allowall  
  ```

  添加一个名为`admin`的用户：

  ```shell
  htdigest /etc/cobbler/users.digest "Cobbler" admin  #执行该命令后会出现如下设置密码提示
  #Changing password for user admin in realm Cobbler
  #New password: 
  #Re-type new password:
  ```

  提示：修改一个用户密码的命令同添加用户的命令。

- pam或ldap方式

  编辑`/etc/cobbler/modules.conf`，修改`[authentication]`和`[authentication]`项如下：

  ```shell
  [authentication]
  module = authn_pam  #pam方式
  #module = authn_ldap  #ldap方式使用该行
   
  [authorization]
  module = authz_ownership  #pam方式
  #module = authz_ldap  #ldap方式使用该行
  ```

  添加一个用户到`/etc/cobbler/users.conf` 的`[admins]`组，假如要添加的用户名是`admin`：

  ```shell
  [admins]
  cobbler = ""
  admin = ""    #新添加的用户
  ```

# 客户机相关

- 客户机使用pxe引导启动。
- 客户机内存分配过小（小于等于1G）可能无法安装，出现“can not write body...”的错误。
- 重装系统可以使用工具koan。