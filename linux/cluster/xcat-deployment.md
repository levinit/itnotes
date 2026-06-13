[TOC]

[xcat中文文档](https://www.ibm.com/developerworks/cn/aix/library/1009_qixl_xcataix/)

[xcat英文文档](http://xcat-docs.readthedocs.io/en/stable/index.html)

[下载xcat](https://github.com/xcat2/xcat-core/releases)

IBM Extreme Cloud Administration Toolkit，即xCAT，是一个集群管理工具。

> xCAT 可以自动发现硬件，开机之后，可以由 xCAT 从裸机自动引导安装，当然，也可以提前导入 client node 信息。

# xcat基本概念

## xCAT Objects

xCAT对象是可xCAT被管理的单位。

xCAT有多种类型的对象，常用几种：

- node 节点——集群中物理服务器/虚拟服务器/硬件控制服务处理器

  xCAT集群节点主要有：管理节点(Management Node) 、服务节点(Service Node)和计算节点(Compute Node)。一般中小型集群可省掉服务节点。

  node的相关信息存放在数据库的表中（参看下文[xCAT Database](#xCAT Database)），node的主要attributes（以下均称为属性）:

  - os  操作系统 取值如：AIX、centos7.4、fedora25

  - arch  架构 取值：c, ppc64, x86, ia64

  - groups

  - mac

  - mgt  硬件设备上的部署方式 取值如：hmc, ivm,kvm, esx, rhevm.

  - ip

  - netboot  启动方式 取值如：pxe, xnba

    ……

- group 群组——多个node对象的集合

- osimage 系统镜像——用以部署的操作系统

  osimage的主要属性有：

  - imagetype  操作系统类型（如AIX、Linux）

  - osarch

  - osvers

  - pkgdir

  - pkglist

    ……

## xCAT Database

xCAT数据库（默认使用SQLite）用以存储所有xCAT对象的数据信息。

xCAT使用数十种**tables**（表）来存储不同的数据。常用tables（以下均称为”表“）：

- site  集群的全局设置信息
- policy table  控制策略配置信息（不同用户的控制权限）
- passwd  用户密码信息


- networks 集群的[network](#xCAT Network)信息
- noderes  节点资源列表信息

## Gobal Configuration

全局配置文件，存储在[xCAT Database](#xCAT Database)的site表中。site主要属性：

- Database
  - excludenodes  排除节点
  - nodestatus  节点状态
- DHCP
  - dhcpinterfaces  DHCP接口（网卡）
  - dhcplease  DHCP租约时间
  - managedaddressmode  地址管理模式 一般取值为dhcp或static（静态/固定）
- DNS
  - domain  （集群）域名
  - forwarders  集群的DNS服务器（的IP）
  - master   集群的管理节点（的IP）
  - nameservers  DNS服务器列表
  - dnsinterfaces  DNS服务器的网络接口
- Install/Deployment 
  - installdir  节点上部署安装包的目录
  - runbootscripts  启动时执行的脚本
  - precreatemypostscripts
  - xcatdebugmode
- Remoteshell
  - sshbetweennodes  一组节点的ssh密码信息
- Services
  - consoleondemand
  - timezone
  - tftpdir
  - tftpflags
- Virtualization
  - persistkvmguests
- xCAT Daemon
  - xcatdport

## xCAT Network

通过网络管理/发现集群中的硬件设备。xCAT有不同的network分管不同的任务：

- Management  简称MN（management network），安装/管理操作系统。该网络常用依赖服务有：
  - DNS
  - HTTP
  - DHCP
  - TFTP
  - NFS
  - NTP
- Service  管理外部节点
- Application  计算节点上的应用程序使用
- Site (Public)  访问管理节点，有时用于计算节点向站点提供服务。

# xcat部署

在管理节点上安装xCAT。

## 准备工作

- 关闭selinux（或者自行进行相应配置）

  1. 编辑`/etc/selinux/config`，设置`SELINUX=disabled` 。（需要重启后生效）
  2. `setenfore 0`本次临时关闭。

- 关闭iptables/firewalld。（或者自行配置相关规则）

- 设置静态IP（根据具体情况设置）。

  本文中设置管理节点的IP为**192.168.1.251** 。

- 启用ntp服务`ntpd`。（如未安装需先安装）

- 设置主机名和DNS

  本文中，域（domain）为cluster，设置管理节点的主机名为**master.cluster** ，集群的节点名均为xx.xcat的形式：

  ```shell
  hostname master.cluster
  echo -e "search cluster\nnameserver 192.168.1.251" >> /etc/resolv.conf
  ```


## 安装xcat

[xcat官网](https://xcat.org)下载安装包安装。

这里推荐使用[go-xcat](https://raw.githubusercontent.com/xcat2/xcat-core/master/xCAT-server/share/xcat/tools/go-xcat)轻松安装：

```shell
wget https://raw.githubusercontent.com/xcat2/xcat-core/master/xCAT-server/share/xcat/tools/go-xcat -O - >/tmp/go-xcat
chmod +x /tmp/go-xcat
/tmp/go-xcat install            # installs the latest stable version of xCAT
source /etc/profile.d/xcat.sh  #加载xcat的环境变量
lsxcatd -a  #xCAT版本
```
- 如果**执行该命令后**安装很慢，可以终止安装，使用`yum install xCAT`进行安装，因为执行过`go-xcat install`后，xCAT源会被自动添加。
- 如果安装仍然很慢，也可以[下载](http://xcat.org/download.html)xcat-core和xcat-dep包，解压后执行其中的`./mklocalrepo.sh`，就能使用包管理器安装了（如`yum install xCAT`）。

## 基本配置

xcat将各种配置信息存储到各个表(table)中。相关命令参看[xcat常用命令](#xcat常用命令)

### site表

site table的attritbutes参看上文[Gobal Configuration](#Gobal Configuration)。

使用` lsdef -t site -l`或`tabdump stie` 检查site表的各项配置信息是否正确。在默认配置下，一般主要添加或修改项为：

- forwarders  DNS的ip
- master  管理节点的ip
- nameservers  管理节点的ip
- domain   集群的域名
- ntpservers  管理节点的ip

可使用`tabedit`、`chtab`或`chdef`等命令修改。`chdef`修改示例：

```shell
chdef -t site domain="cluster" forwarders="192.168.1.1" master="192.168.1.251" nameservers="192.168.1.251" ntpservers="192.168.1.251"
```

检查nameserver，查看` /etc/resolv.conf `中的nameserver是否与上面的配置一致。

- 多网口设备要指定dhcp要使用的网口（或者指定dhcp使用网口的顺序）

  ```shell
  chdef -t site dhcpinterfaces=eth0  #指定网卡
  chdef -t site dhcpinterfaces=eth0,eth1  #多个网卡使用逗号分隔，dhcp将按顺序使用
  ```

  提示：也可在系统配置中设置dhcp的网卡（例如centos中，该文件为`/etc/sysconfig/dhcpd` ）

### networks表

xCAT默认会对每个网卡创建一个network object。

使用`lsdef -t network -l`或`tabdump networks`查看各项参数是否与上文site表中的配置，在默认配置下，一般主要添加或修改项为：

- netname
- net
- mask
- gateway
- dhcpserver
- tftpserver
- nameservers
- ntpservers

如不一致需对其进行修改，配置示例：

```shell
chtab netname=192_168_1_0-255_255_255_0 \
        networks.net=192.168.1.0 \
        networks.mask=255.255.255.0 \
        networks.gateway=192.168.1.1 \
        networks.dhcpserver=192.168.1.251 \
        networks.tftpserver=192.168.1.251 \
        networks.nameservers=192.168.1.251 \
        networks.ntpservers=192.168.1.251
```

然后

增加一个ip为管理节点ip的ntp服务器：

```shell
echo "server 192.168.1.251 \nfudge 192.168.1.251 stratum 10" >> /etc/ntp.conf
systemctl restart ntpd && systemctl enable ntpd
```

设置管理节点默认的域名，编辑`/etc/sysconfig/network`，示例：

```shell
NETWORKING=yes
HOSTNAME=master
DOMAINNAME=cluster
```

添加集群中节点的DNS解析到`/etc/hosts中`，或者添加到[节点](#节点)的hosts表中，示例：

```shell
192.168.1.251  master master.cluster
192.168.1.11  node1 node1.cluster
```

---

如果要自行添加一个networks，可使用类似命令：

```shell
mkdef -t network -o net1 net=192.168.100.0 mask=255.255.0.0 gateway=192.168.100.1
```

### passwd表

- 设置系统用户root的密码

  ```shell
  # 将用户root的密码设置为root
  chtab key=system passwd.username=root passwd.password=root
  #可使用openssl加密用户的密码
  chtab key=system passwd.username=root passwd.password=`openssl passwd -1 root`
  ```

- 添加一个用户并设置密码（可选）

  ```shell
  useradd xcauser1
  passwd xcatuser1 # set the password
  chtab key=xcat passwd.username=xcatuser1 passwd.password=<xcatws_password>
  ```

### 节点

节点（node）时要被发现/管理的设备。可根据不同作用将各个节点划分到不同的群组（group）中。

节点的数据表——节点信息存放在nodelist、nodetype、noderes、mac、hosts等表中。

分别编辑各个表进行增改节点信息比较繁琐，建议使用以下方式进行操作。

- 添加节点`nodeadd 节点名 <其他配置属性>`

  ```shell
  nodeadd io3 \
      groups=io,all \
      mac.interface=eth0 \
      mac.mac=a0:d3:c1:f2:e7:a8 \
      hosts.ip=192.168.1.203 \
      noderes.netboot=pxe \
      noderes.xcatmaster=192.168.1.251 \
      noderes.installnic=eth0 \
      noderes.primarynic=eth0 \
      noderes.nfsserver=192.168.1.251 \
      nodetype.os=centos7.4 \
      nodetype.arch=x86_64 \
      nodetype.nodetype=osi
  ```

  提示：如果某个group不存在，添加节点时会自动创建groups属性中对应的组。根据实际需要，这些属性并非都需要配置。

- 删除节点：`noderm 节点名`

- 添加节点到某个组中

  ```shell
  #将指定节点添加到某个组中
  chdef -t node -p -o cn1,cn2,cn3 groups=compute
  ```

### 群组

`makdef -t group -o 群组名 <其他配置属性>`

```shell
#创建一个静态群组compute 直接指定成员节点 多个节点使用逗号分隔
mkdef -t group -o compute members="io"
#创建一个动态群组compute
mkdef -t group -o compute -d -w os=~centos[0-9]+ -w arch=x86_64
```

静态群组不指定members会提示`Warning: Cannot determine a member list for group xxx`

动态群组是指用perl的操作`==`, `!=`, `=~` and `!~`等设置属性值，参看[perl文档](http://www.perl.com/doc/manual/html/pod/perlre.html) 。

群组信息存放在**nodegroup 表**中，也可以通过编辑该表添加群组。

## kickstart

修改`/opt/xcat/share/xcat/install/`目录下相关系统的tmpl文件实现定制安装，该类tmpl文件为kickstart文件。

参看[kickstart](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/6/html/installation_guide/s1-kickstart2-file)相关文档。

推荐使用`system-config-kickstart`图形工具创建该配置文件。

## 系统镜像

### 创建系统镜像文件

假如系统镜像存在当前操作目录下，其文件名为`centos.iso` ，创建操作系统安装文件

```shell
copycds -n centos -a  x86_64 ./centos.iso
lsdef -t osimge  #检查镜像情况
```

系统文件信息存放在osdistro、osdistroupdate和osimage表中（还有特定系统镜像信息的table，如linuximage——Linux系统，winimage——windows系统）

### 为节点配置安装镜像

```shell
makehosts
makedns -n
makedhcp -n
```

> 因为 makedns 命令要求管理节点必须是domain的一部分，所以如果没有需要手动添加。

```shell
echo '192.168.1.251 master master.xcat' >> /etc/hosts
makehosts
```
分发

```shell
# 为cn1节点安装osimage中的centos-x86_64-install-compute
nodeset cn1 osimage=centos-x86_64-install-compute
```

# 其他

## web UI

 .安装`xCAT-UI-deps`，浏览器访问//todo

## 常见问题

- 内存过小(小于等于1G)，会报ks.cfg找不到的错误

## 卸载xcat

参看[Remove xCAT](http://xcat-docs.readthedocs.io/en/stable/guides/install-guides/maintenance/uninstall_xcat.html?highlight=remove#remove-xcat)

```shell
makedhcp -d -a
nodeset all offline
makehosts -d all  #移除hosts  可选
makedns -n
service xcatd stop
rpm -qa |grep -i xcat
rm -rf /root/.xcat
rm -rf /etc/xcat
#其他可选删除项
#/install
#/tftpboot
#/etc/yum.repos.d/xCAT-*
#/etc/sysconfig/xcat
#/etc/apache2/conf.d/xCAT-*
#/etc/logrotate.d/xCAT-*
#/etc/rsyslogd.d/xCAT-*
#/var/log/xcat
#/opt/xcat/
#/mnt/xcat
```
## xcat常用命令

- 查看table信息：`tabdump 表名`，例如`tabdump site`
- 编辑table内容：
  - `tabedit 表名`命令，将开启文本编辑器以编辑某个表的信息，例如`tabedit site`编辑site表。
  - 类似`chtab key=master site.value=192.168.1.251`的命令更改表中的属性值。
  - 类似`chdef -t site domain="xcatdomain"`的命令更改表中的属性值。
- 创建对象：类似`mkdef -t network -o net1 net=192.168.186.0   mask=255.255.255.0 gateway=192.168.100.1`
- 查看对象信息：` lsdef -t 对象名 -l`，例如`lsdef -t network -l` `lsdef -t osimage -l`

## 