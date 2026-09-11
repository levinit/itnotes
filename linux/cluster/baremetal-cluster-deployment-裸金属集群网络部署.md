# 裸金属集群网络部署

在高性能计算 (HPC) 集群中，通常需要对成百上千台物理节点进行网络引导与环境部署。本文记录基于 **UEFI HTTP Boot / iPXE** 的网络部署架构，包含**无状态 (Stateless / 内存运行)** 与**有状态 (Stateful / 本地磁盘安装)** 两种模式。

[TOC]

---

## 1. 架构与启动流程

通过网卡 UEFI 固件与 HTTP 协议完成大文件传输，避免 TFTP 协议在并发传输时的丢包与速度瓶颈。

```
                ┌────────────────────────────────────────────────────────┐
                │                  管理节点 (Management)                 │
                │   DHCP/DNS (Dnsmasq) + HTTP Server (Nginx) + Warewulf   │
                └───────────┬────────────────────────────────┬───────────┘
                            │                                │
                 DHCP Offer │ (Option 67: ipxe.efi)           │ HTTP GET kernel + rootfs
                            ▼                                ▼
                ┌────────────────────────────────────────────────────────┐
                │                  物理计算节点 (Client)                 │
                │                                                        │
                │  1. UEFI 网卡发起 DHCP 请求                             │
                │  2. 加载 iPXE 引导程序 (支持 TCP/HTTP 协议栈)           │
                │  3. iPXE 通过 HTTP 线速拉取内核与系统镜像至内存/磁盘   │
                │  4. 启动系统，挂载共享存储，加入集群调度网络           │
                └────────────────────────────────────────────────────────┘
```

### 两种部署模式选择

* **无状态模式 (Stateless / 内存运行)**：
  * 系统镜像（VNFS）在开机时通过网络直接载入物理机内存（tmpfs），节点无需格式化本地磁盘。
  * **特点**：节点每次重启自动还原至干净基线，杜绝长期运行导致的配置漂移和软件污染；但会占用数 GB 物理内存，且**节点启动阶段高度依赖管理节点及网络在线**。
  * **适用场景**：集群计算节点（Compute Worker Nodes）。
* **有状态模式 (Stateful / 本地磁盘安装)**：
  * 通过网络引导加载安装程序，由 Kickstart 自动化分区并将系统完整写入本地 SSD/RAID。
  * **特点**：系统独立固化在本地磁盘，系统安装完成后即使管理节点网络中断，计算节点依然可以独立正常运行；但节点多时存在本地磁盘维护与各节点系统环境长期一致性问题。
  * **适用场景**：管理节点、登录节点、存储节点（Lustre MDS/OSS、NFS Server）。

---

## 2. 基础引导服务配置 (DHCP + iPXE + HTTP)

以 Rocky Linux / RHEL 为例，使用 `dnsmasq` 提供轻量 DHCP 与初始引导，大文件由 Nginx 提供 HTTP 服务。

### 2.1 基础服务安装与目录规划

```bash
dnf install -y dnsmasq nginx
systemctl enable --now nginx

# 创建部署资源目录
mkdir -p /var/www/html/ipxe/{kernels,images,kickstart}
mkdir -p /var/lib/tftpboot
```

### 2.2 获取 iPXE 引导文件

```bash
# 获取支持 UEFI x86_64 的 iPXE 固件
wget http://boot.ipxe.org/ipxe.efi -O /var/lib/tftpboot/ipxe.efi
```

### 2.3 配置 dnsmasq 识别 UEFI 客户端并链式加载

编辑 `/etc/dnsmasq.d/pxe.conf`：

```ini
interface=eth0
bind-interfaces

# DHCP 分配范围与掩码
dhcp-range=192.168.1.100,192.168.1.200,255.255.255.0,12h

# 网关与 DNS
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1

# 启用 TFTP (仅用于首次传递几十 KB 的 ipxe.efi)
enable-tftp
tftp-root=/var/lib/tftpboot

# 匹配客户端架构 (Option 93)
dhcp-match=set:bios,option:client-arch,0
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-match=set:efi-x86_64,option:client-arch,9
dhcp-match=set:ipxe,175

# 链式引导：未加载 iPXE 时分发 ipxe.efi；加载 iPXE 后分发 HTTP 脚本
dhcp-boot=tag:!ipxe,tag:efi-x86_64,ipxe.efi
dhcp-boot=tag:ipxe,http://192.168.1.1/ipxe/boot.ipxe
```

重启服务：
```bash
systemctl restart dnsmasq
```

---

## 3. 无状态计算节点部署 (基于 Warewulf v4)

Warewulf v4 基于 Go 重构，采用容器镜像（OCI 镜像）作为物理节点的 VNFS 运行环境。

### 3.1 安装与启动

```bash
dnf install -y warewulf
systemctl enable --now warewulfd
```

### 3.2 导入容器镜像构建节点系统

```bash
# 导入系统基础镜像
wwctl container import docker://rockylinux:9 rocky-9-compute

# 进入镜像环境配置 HPC 基础依赖与驱动
wwctl container exec rocky-9-compute /bin/bash
```

在容器环境中安装必要组件：
```bash
dnf groupinstall -y "Development Tools"
dnf install -y kernel-core kernel-modules     infiniband-diags libibverbs librdmacm rdma-core     nfs-utils sssd autofs tcsh ksh
exit
```

构建打包节点镜像：
```bash
wwctl container build rocky-9-compute
```

### 3.3 节点与网络配置

```bash
# 设置默认 Profile
wwctl profile set default     --container rocky-9-compute     --netmask 255.255.255.0     --gateway 192.168.1.1

# 批量添加计算节点
wwctl node add node[001-064]     --profile default     --ipaddr 192.168.1.[101-164]     --netname default

# 绑定具体节点 MAC 地址 (以 node001 为例)
wwctl node set node001 --hwaddr 00:11:22:33:44:55

# 渲染并更新引导覆盖层
wwctl overlay build
```

节点开机通过 UEFI 获取 IP 并通过 HTTP 从管理节点拉取 rootfs 解压至内存运行。

---

## 4. 有状态节点自动化安装 (iPXE + Kickstart)

针对管理机、存储机等需要将系统固化在本地磁盘的机器，采用 iPXE 配合 Kickstart 脚本进行无人值守安装。

### 4.1 iPXE 引导菜单 (`/var/www/html/ipxe/boot.ipxe`)

```ini
#!ipxe

set server_ip 192.168.1.1
set base_url http://${server_ip}/ipxe

menu OS Provisioning Menu
item rocky9_node   Install Rocky Linux 9 (Local Disk)
item local_boot    Boot from Local Storage
choose target && goto ${target}

:rocky9_node
echo Booting Rocky Linux 9 installer via HTTP...
kernel ${base_url}/kernels/rocky9/vmlinuz inst.repo=${base_url}/images/rocky9 inst.ks=${base_url}/kickstart/node.ks quiet
initrd ${base_url}/kernels/rocky9/initramfs.img
boot

:local_boot
exit
```

### 4.2 Kickstart 自动化安装文件样例 (`node.ks`)

```ini
url --url="http://192.168.1.1/ipxe/images/rocky9"
text
reboot

lang en_US.UTF-8
keyboard us
timezone Asia/Shanghai --utc

# 磁盘清理与 UEFI 自动分区
zerombr
clearpart --all --initlabel
part /boot/efi --fstype="efi" --size=1024 --fsoptions="umask=0077,shortname=winnt"
part /boot --fstype="xfs" --size=2048
part pv.01 --size=1 --grow
volgroup vg_system pv.01
logvol / --vgname=vg_system --size=102400 --name=lv_root --fstype=xfs
logvol /tmp --vgname=vg_system --size=51200 --name=lv_tmp --fstype=xfs
logvol swap --vgname=vg_system --size=32768 --name=lv_swap

firewall --disabled
selinux --disabled
services --enabled="sshd,chronyd,autofs"

%packages
@^minimal-environment
@development
chrony
nfs-utils
tcsh
ksh
%end

%post
# 内核参数调优
cat <<EOF >> /etc/sysctl.d/99-hpc.conf
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
vm.max_map_count = 262144
EOF
sysctl -p /etc/sysctl.d/99-hpc.conf
%end
```

---

## 5. 常见配置与问题排查

1. **UEFI 与 Secure Boot**：
   * 服务器 BIOS 需关闭 CSM，确保纯 UEFI 模式。
   * 若启用了 Secure Boot，引导链需要通过官方签名的 `shimx64.efi` 链式加载，或在 BIOS 中临时关闭 Secure Boot。
2. **串口控制台输出 (IPMI SOL)**：
   * 批量装机时，在内核参数中加入 `console=tty0 console=ttyS0,115200n8`，方便通过带外管理网络（IPMI）远程监控节点安装进度。
3. **网络巨型帧 (MTU 9000)**：
   * 集群管理网交换机如果支持并开启了 MTU 9000，大镜像拉取与系统解压速度会有明显提升。
