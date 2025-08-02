

以操作系统为centos 7.x的3个节点组建ceph为例，分别为：

- node1

  作为管理节点ceph-admin 。

- node2

- node3

如无特别说明，则该操作均适用于三个节点。

基本要求

> 5GB 系统磁盘、swap = 512MiB，及主目录 = 3GiB 
>
> 2GiB 内存及每台系统一个虚拟处理器 
>
> 每台系统一个固定的 IP 
>
> 所有系统必须能用*简称*（hostname -s）互相 ping

---

# 准备

- 关闭防火墙和selinux

  ```shell
  systemctl disable --now firewalld
  sed -i '/SELINUX=/c SELINUX=disabled' /etc/selinux/config
  setenforce 0
  ```

- 配置主机名和hosts解析

  > 192.168.78.101 node1
  > 192.168.78.102 node2
  > 192.168.78.103 node3

- 帐户和认证

  配置管理账户ssh密钥认证，各个创建ceph账户并配置密钥认证（可以使用nis等工具管理账户）

  ```shell
  useradd -d /home/ceph -m ceph
  echo "ceph" | passwd ceph --stdin
  #ssh-key
  ssh-keygen  -b 4096 -f ~/.ssh/id_rsa -N ""
  #ssh-copy-id 略
  ```

- 时间同步服务

- 准备ceph源

  ```shell
  echo '
  [ceph]
  name=ceph nautilus
  baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/x86_64/
  gpgcheck=0
  enabled=1
  '> /etc/yum.repos.d/ceph.repo
  yum makecache
  ```

- 安装epel源

  ```shell
  yum install -y epel-release
  ```

  

# 部署

- 在所有节点 安装ceph包

  ```shell
  yum install -y ceph
  ```

  也可以使用ceph-deploy为其他节点安装ceph

  ```shell
  ceph-deploy install node1 node2 node3
  ```

- 在node1 安装ceph-deploy

  ```shell
  yum install -y ceph-deploy
  ```

- 在node1执行 创建monitor

  ```shell
  mkdir ceph && cd ceph
  ceph-deploy new node1 node2 node3
  ```

  正确执行后会生成三个文件：`ceph.conf`  `ceph.log`  `ceph.mon.keyring`

- 在node1执行 配置ceph.conf

  ```shell
  cat << EOF >> ceph.conf
  osd_journal_size = 10000
  osd_pool_default_size = 2
  osd_pool_default_min_size = 2
  osd_crush_chooseleaf_type = 1
  osd_crush_update_on_start = true
  max_open_files = 131072
  osd pool default pg num = 128
  osd pool default pgp num = 128
  mon_pg_warn_max_per_osd = 0
  EOF
  ```

  

- node1安装ceph-deploy安装 = Minimal，及一个可用的时间长注程序（即是可靠的 NTP 来源） 

  5GB 系统磁盘、swap = 512MiB，及主目录 = 3GiB 

  2GiB 内存及每台系统一个虚拟处理器 

  每台系统一个固定的 IP 

  所有系统必须能用*简称*（hostname -s）互相 ping。要是没有 DNS 服务，可采用一致的 /etc/hosts 档，内有所有简称（而不是群集的 FQDN）。 

- ```shell
yum install -y epel-release
  yum install -y ceph-deploy
  ```
  
- 部署ceph到各个io节点

  ```shell
  mkdir deploy-ceph && cd deploy-ceph
  ceph-deploy new m1
  ```

  

---

手动安装

```shell
yum install -y ceph-common
```

装载rbd模块

```shell
modprobe rbd       #装载rb生成d模块
lsmod | grep rbd   #查看模块是否已经装载
```

## 部署monitor



监控密钥monitor-keyring

```shell
ceph-authtool --create-keyring ./ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```



```shell
cp ./ceph.mon.keyring ./cluster.bootstrap.keyring
ceph-authtool ./cluster.bootstrap.keyring --import-keyring  /etc/ceph/ceph.client.admin.keyring
```

