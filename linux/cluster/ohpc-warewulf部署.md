本文是[ohpc install guide centos7 warewulf slurm](https://github.com/openhpc/ohpc/releases)的简要整理，具体参看官方手册。​

以CentOS7.x为例。

[TOC]

本文中，管理节点ip192.168.1.251，主机名sms，以太网口为eth0，子网掩码为255.255.255.0，网关为192.168.1.1，定义这些变量方便后面使用：

```shell
sms_ip=192.168.1.251
sms_name=master
sms_eth_internal=eth0
internal_netmask=255.255.255.0
```

# 管理节点系统配置

1. 添加本机hosts信息

   ```shell
   echo '${sms_name} ${sms_name}' >> /etc/hosts
   ```

2. 关闭selinux和防火墙

   ```shell
   systemctl disable firewalld  && systemctl stop firewalld
   setenforce 0
   sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux
   ```

3. 配置ntp

   ```shell
   yum install ntp -y
   echo 'server ${sms_ip}' >> /etc/ntp.conf
   systemctl start ntpd && systemctl enable ntpd
   ```

# openHPC安装配置

在管理节点安装openHPC

## 安装openHPC

在http://build.openhpc.community/OpenHPC:/下找到repo软件添加到系统中，或安装其中提供的rpm包添加软件源，例如：

```shell
#例如1.3的ohpc-release
yum install http://build.openhpc.community/OpenHPC:/1.3/CentOS_7/x86_64/ohpc-release-1.3-1.el7.x86_64.rpm
```
---

也可以手动下载

- 在http://build.openhpc.community/dist/中下载openHPC工具集压缩包。
- 在http://build.openhpc.community/OpenHPC:/下载到各单独的软件包。

### ohpc组件

- ohpc-base
- ohpc-warewulf
- docs-ohpc
- ohpc-slurm-server

```shell
# install ohpc components
yum -y install ohpc-base ohpc-warewulf ohpc-slurm-server docs-ohpc
# identify resource manager hostname on master host
perl -pi -e "s/ControlMachine=\S+/ControlMachine=${sms_name}/" /etc/slurm/slurm.conf
```

- 可选 IB([InfiniBand](https://zh.wikipedia.org/zh-hans/InfiniBand))或 [omni-path](https://en.wikipedia.org/wiki/Omni-Path)


## 配置warewulf

```shell
perl -pi -e "s/device = eth1/device = ${sms_eth_internal}/" /etc/warewulf/provision.conf
# Enable tftp service for compute node image distribution
perl -pi -e "s/^\s+disable\s+= yes/ disable = no/" /etc/xinetd.d/tftp
# Enable internal interface for provisioning
ifconfig ${sms_eth_internal} ${sms_ip} netmask ${internal_netmask} up

# Restart/enable services to support provisioning
systemctl restart xinetd mariadb httpd
systemctl enable mariadb httpd dhcpd
```

## 配置计算节点镜像

为各个计算节点创建镜像。

### 创建基础系统

Warewulf在wwmkchroot进程期间的默认配置为访问外部储存库。

这里使用CentOS，按照如下配置，就会自动从镜像源中下载CentOS基础系统文件到指定目录：

```shell
# Define chroot location
export CHROOT=/opt/ohpc/admin/images/centos
# Build initial chroot image
wwmkchroot centos-7 $CHROOT
```
---

如果需要使用本地镜像源，将相关文件（系统镜像，ohpc工具等等）放到ttpd服务目录下，然后设置`$YUM MIRROR envir`即可：

```shell
export YUM_MIRROR=${BOS_MIRROR}
```

---

### 添加OpenHPC组件和其他软件包

安装基础系统之外可能会用到的ohpc组件和其他软件包。

使用`yum -y --installroot=$CHROOT install 包名`的形式，将该软件包添加到计算节点的镜像中。

```shell
# Install compute node base meta-package
yum -y --installroot=$CHROOT install ohpc-base-compute

# Copy DNS configuration
cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

# Add Slurm client, ntp, kernel drivers, and  include modules user environment 
yum -y --installroot=$CHROOT install ohpc-slurm-client ntp kernel lmod-ohpc
```
### 自定义系统配置

为各个计算节点进行系统配置。

```shell
# Initialize warewulf database and ssh_keys
wwinit database ssh_keys

## Add NFS client mounts of /home and /opt/ohpc/pub to base image
echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid,noatime 0 0" >> $CHROOT/etc/fstab
echo "${sms_ip}:/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev,noatime 0 0" >> $CHROOT/etc/fstab

# Export /home and OpenHPC public packages from master server
echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports
echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports
exportfs -a
systemctl restart nfs-server  && systemctl enable nfs-server

# Enable NTP time service on computes and identify master host as local NTP server
chroot $CHROOT systemctl enable ntpd
echo "server ${sms_ip}" >> $CHROOT/etc/ntp.conf
```
### 其他可选配置

- IfiniBand / Omni-Path

- ssh访问控制

  使用PAM认证模块，来限制计算节点上的SSH访问

  ```shell
  echo "account required   pam_slurm.so" >> $CHROOT/etc/pam.d/sshd
  ```

- [BeeGFS](https://en.wikipedia.org/wiki/BeeGFS)

- lustre client

- 转发系统日志forwarding of system logs

- 监控monitoring

  - nagios
  - ganglie

- ClusterShell 在集群节点上并行执行命令

  ```shell
  compute_prefix=cn  #计算节点名的前缀
  num_computes="${num_computes:-12}"  #12是该组计算节点的总数

  yum -y install clustershell-ohpc

  cd /etc/clustershell/groups.d
  mv local.cfg local.cfg.orig
  echo "adm: ${sms_name}" > local.cfg
  echo "compute: ${compute_prefix}[1-${num_computes}]" >> local.cfg
  echo "all: @adm,@compute" >> local.cfg
  ```

- mrsh--a secure remote shell

- genders--a static cluster configuration database

- ConMan--a serial console management program

- 引入文件

  将管理节点的重要文件（如密码/分组等）分发到各个计算节点上。示例：

  ```shell
  wwsh file import /etc/passwd
  wwsh file import /etc/group
  wwsh file import /etc/shadow

  wwsh file import /etc/slurm/slurm.conf
  wwsh file import /etc/munge/munge.key
  ```

### 确认配置

1. 引导镜像 bootstrap image

   ```shell
   # (Optional) Include drivers from kernel updates; needed if enabling additional kernel modules on computes
   export WW_CONF=/etc/warewulf/bootstrap.conf
   echo "drivers += updates/kernel/" >> $WW_CONF
   # (Optional) Include overlayfs drivers; needed by Singularity
   echo "drivers += overlay" >> $WW_CONF
   # Build bootstrap image
   wwbootstrap `uname -r`
   ```


2. 虚拟节点文件系统（VNFS）镜像

   在chroot环境中定义计算节点实例：

   ```shell
   wwvnfs --chroot $CHROOT
   ```

3. 登记节点

   ```shell
   eth_provision="${eth_provision:-eth0}"  #计算节点网卡的名字
   compute_regex="${compute_regex:-cn1*}"  #计算节点的命名规则（正则）
   c_name[1]='01'  #一个节点的名字
   c_name[2]='02'
   #……其他节点name参照上面写法
   c_ip[1]='192.168.1.11'  #一个节点的ip
   #……其他节点ip参照上面写法
   c_mac[1]='fc:15:b4:14:54:e8'
   #……其他节点mac参照上面写法

   # Set provisioning interface as the default networking device
   echo "GATEWAYDEV=${eth_provision}" > /tmp/network.$$
   wwsh -y file import /tmp/network.$$ --name network
   wwsh -y file set network --path /etc/sysconfig/network --mode=0644 --uid=0

   # Add nodes to Warewulf data store
   for ((i=0; i<$num_computes; i++)) ; do
       wwsh -y node new ${c_name[i]} --ipaddr=${c_ip[i]} --hwaddr=${c_mac[i]} -D ${eth_provision}
   done

   # Additional step required if desiring to use predictable network interface
   # naming schemes (e.g. en4s0f0). Skip if using eth# style names. 更换
   wwsh provision set "${compute_regex}" --kargs "net.ifnames=1,biosdevname=1"
   wwsh provision set --postnetdown=1 "${compute_regex}"

   # Define provisioning image for hosts
   wwsh -y provision set "${compute_regex}" --vnfs=centos --bootstrap=`uname -r` \
   --files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network

   # Restart dhcp / update PXE
   systemctl restart dhcpd
   wwsh pxe update
   ```

4. 可选 内核参数

5. 可选 状态配置

   ```shell
   # Add GRUB2 bootloader and re-assemble VNFS image
   yum -y --installroot=$CHROOT install grub2
   wwvnfs --chroot $CHROOT

   # Select (and customize) appropriate parted layout example
   cp /etc/warewulf/filesystem/examples/gpt_example.cmds /etc/warewulf/filesystem/gpt.cmds
   wwsh provision set --filesystem=gpt "${compute_regex}"
   wwsh provision set --bootloader=sda "${compute_regex}"
   ```

   如果使用uefi

   ```shell
   # Add GRUB2 bootloader and re-assemble VNFS image
   yum -y --installroot=$CHROOT install grub2-efi grub2-efi-modules
   cp /etc/warewulf/filesystem/examples/efi_example.cmds /etc/warewulf/filesystem/efi.cmds
   wwsh provision set --filesystem=efi "${compute_regex}"
   wwsh provision set --bootloader=sda "${compute_regex}"
   ```

6. 引导计算节点

   计算节点使用pxe启动，管理节点为各个计算节点进行引导：

   ```shell
   for ((i=0; i<${num_computes}; i++)) ; do
       ipmitool -E -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} chassis power reset
   done
   ```

   监测各个节点情况：

   ```shell
   pdsh -w c[1-4] uptime
   ```

   ​