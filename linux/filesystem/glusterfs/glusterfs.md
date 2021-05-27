注解：本文中

- 以centos7.x 为例
- master为集群主节点，io组为存储节点（这里示例有三个io），cn组为计算节点。
- 各节点使用使用Ifniband进行数据传输，其中各io节点在`/etc/hosts`中添加的IPoIB解析名分别为`ibio1`、`ibio2`和`ibio3`。

[TOC]

# 服务端

## 安装

- 官网[gluster.org](https://download.gluster.org/pub/gluster/)下载安装包安装

- 使用在线源

  ```shell
  yum install epel-release
  yum search gluster release  #从结果列表中选择一个gluster版本例如312
  yum install centos-release-gluster312.noarch
  ```

- 搭建本地源

  1. 从centos各个公共镜像网站的storage仓库（如[centos.org的storage仓库](http://mirror.centos.org/centos/7/storage/x86_64/)）中找到需要的gluster版本并下载其中的软件包。

     一些镜像站可使用rsync下载，例如[ustc](https://mirrors.ustc.edu.cn/centos/7/storage/x86_64)：

     ```shell
     distro=7.7.1908  # 8 | 7.7.1908
     ver=6  #luminous | jewel
   rsync  -avz rsync://rsync.mirrors.ustc.edu.cn/centos/$distro/storage/x86_64/gluster-$ver/ .
     ```

     参看[ustc rsync注意事项](https://mirrors.ustc.edu.cn/help/rsync-guide.html)

  2. 创建repo文件gluster.repo，将其分发到要安装glusterfs节点的`/etc/yum.repos.d`目录下：

     ```shell
     [gluster]
     name=gluster
     baseurl=http://172.16.1.251/repo/gluster
     enabled=1
  gpgcheck=0
     ```

  3. 搭建并开启web服务器，配置好默认的根目录为`/srv/repo`。

  4. 安装

     ```shell
     yum install glusterfs-server -y
     yum install glusterfs-rdma  -y #如果要使用rdma
     systemctl enable --now glusterd  #启用服务
     #如果要使用rdma需要安装rdma并启动rdma服务（mellanox驱动无需单独安装rdma）
     ```

## 配置

glusterfs基本概念

- Brick

  **文件系统挂载点** GLusterFS存储结构单元

- Translator

  按层级提供功能

- Volume

  由brick通过translator组合而成

- Node/Peer

  运行gluster进程的服务器

### 存储池

组合各个存储节点为一个存储池，只需要在其中一个存储节点执行：

```shell
gluster peer probe ib.io2  #ib.io2是该节点的IPoIB对应的用户名
gluster peer probe ib.io3

gluster peer status  #查看添加的各个节点的状态信息
```

**不需要将执行以上命令的节点自身添加仅存储池，因为该节点会自动将自身加入。**

### 卷

```shell
#创建卷
gluster volume create <vol-name> [type N] [replica N] [transport tcp,rdma] [other-options] <servers>:<bricks>
```

- vol-name ： 卷名

- type N ：type是卷类型，N为加入的brick数量

  如果不写type 及N值，则默认为distribute，数量为后面添加的brick数量。type类型：

  - distribute  分布式
  - diperse  散列式

- replica N：副本数量

- transport：通信方式，默认tcp，可使用tcp、rdma或tcp,rdma。

- 其他参数：参看文档。其中如果type为diperse，可以添加redundancy N，即冗余数量。如果没有该参数，则程序会建议一个冗余值，并提示用户是否使用该值。

-  servers:bricks ：按照`主机名:卷路径`的方式一一添加brick，每个brick之间使用空格分隔。

```shell

#分布式卷 bricks=每节点brick * 节点数量
gluster volume create <volume-name> [type count]  <server>:<brick>  <server>:<brick>

#分布式复制卷 server节点是副本(replica)的倍数(>=2倍)
#bricks=每个节点的brick数量 * 副本数量 ？
gluster volume create <vol-name> replica <N>  <server>:<brick>  <server>:<brick>

#散列卷 bricks=每个节点的brick数量 * (可用于存储的brick数量+冗余brick数量)
gluster volume create hdd_data disperse 3 redundancy 1
io{1..3}.10g:/storage/hdd/gv1


#删除卷
gluster volume delete <volume-name>

#将新加入存储池的brick加入卷
gluster volume add-brick <volume-name> <brick>

#查看卷信息
gluster volume info <volume-name>
```

参数设置

```shell
#设置选项
gluster volume get <vol-name> all  #获取所有选项
gluster volume get <vol-name> <option> #获取指定选项
gluster volume set <vol-name> <option> <val> #设置指定选项
gluster volume reset <vol-name> <option> #重置指定选项 all
```



复制卷和条带卷才需要设置count值

卷类型（type）：

- 基本卷

  - 分布式卷 distributed

    又称哈席卷，在创卷时不指定卷类型将默认使用分布式卷。

    近似RAID0，**文件**根据hash算法写入各个节点的硬盘上。优点是容量大，缺点是没冗余，另外由于文件没有分片，类似本地文件系统，因此读写性能没有提升。

  - 条带卷 striped

    相当于RAID0，**文件分片**存储在各个节点的硬盘上的，优点是分布式读写，性能整体较好。缺点是没冗余，分片随机读写可能会导致硬盘IOPS饱和。

  - 复制卷 replicated

    相当于RAID1，文件复制到多个brick上。优点是有冗余，缺点是磁盘利用率低。通常与分布式卷或者条带卷组合使用较好。

  - 分散卷 dispersed

    分散卷基于纠错码，它基于条带编码，添加冗余冗余编码，并分布到多个brick上存储。 分散卷以最小的磁盘空间消耗实现冗余，并且冗余级别可以配置。应用场景：对冗余和磁盘空间都敏感的场景。
    优点：在冗余和磁盘空间上取的平衡。
    缺点：需要消耗额外的资源去做验证，对性能也有一点影响。

- 复合卷

  - 分布条带卷 distributed stripe

    Brick server 数量必须是条带数的倍数，兼具 distribute 和 stripe 卷的特点。至少需要4台服务器。

  - 分布复制卷 distributed replica

    Brick server 数量是镜像数的倍数，兼具 distribute 和 replica 卷的特点,可以在 2 个或多个节点之间复制数据。

  - 条带复制卷 stripe replica

    类似RAID10，同时具有条带卷和复制卷的特点。

  - 分布条带复制卷 distributed stripe replica

    三种基本卷的复合，通常用于类 Map Reduce 应用。

  - 分布分散卷

- 传输模式
  transport 传输类型默认为`tcp` ，还可以取值`rdma` 或 `tcp,rdma`

  更改传输模式：

  ```shell
   gluster volume set <卷名> config.transport tcp,rdma  #改为使用tcp和rdma两种模式
  ```

# 客户端

要挂载gluster文件系统的节点都称为客户端，作为gluster服务器的io节点也可以同时成为客户端。

```shell
yum install -y glusterfs glusterfs-fuse
#如果要使用rdma需要安装glusterfs-rdma和rdma并启动rdma服务
yum install glusterfs-rdma rdma
systemctl enable rdma && systemctl start rdma
```

挂载卷：

```shell
mkdir /share    #示例挂载点为/share
#手动挂载
mount -t glusterfs -o transport=rdma io1.ib:/share /share  #trnaport指定挂载方式（如rdma或tcp）
#写入fstab以自动挂载
echo 'io1.ib:/share.rdma  /share  glusterfs defaults 0 0 >> /etc/fstab
#如果开机自动挂载失败可能时网络尚未就绪时就执行了自动挂载，可设置延迟挂载
echo 'sleep 180 && mount -a' >> /etc/profile
```

如果要挂载的卷配置了多种传输方式（transport目前支持同时配置rdma和tcp传输方式），挂载时如不指定传输方式，则默认使用tcp传输方式。



----

```shell
gluster vol get <vol-name> all #所有参数
```

- `network.ping-timeout`  客户端等待检查服务器是否响应的持续时间（0-42 单位秒）

  某些节点掉线后，glusterfs会不断尝试和该节点通信，此时文件系统会一直等待该节点返回信息（具体表现如访问文件系统卡住，例如对挂载目录执行`ls`或`df`卡住），直到等待到`network.ping-timeout`设置的秒数后，若该节点仍无反馈则停止等待。

- `diagnostics.brick-log-level`  日志级别 默认INFO (取值` 	DEBUG/WARNING/ERROR/CRITICAL/NONE/TRACE`)
- `cluster.min-free-disk`  磁盘剩余空间报警值 默认`10%`
- `auth.allow`或`auth.reject`  允许或禁止的客户端IP
- `performance.cache-size`  	读取缓存的大小默认 默认32 MB
- `performance.write-behind-window-size`  能提高写性能单个文件后写缓冲区的大小默认
  	`1MB`
- `performance.io-thread-count`  IO操作的最大线程


### 复本卷及分布式复本卷



对于分布式副本卷，每个副本是一个分布式子卷，为了保证可用性，子卷的各个组成块（brick）不应该来有两个块来自于同一个节点。
例如3节点，每节点2 brick，组建双副本（当然，为了预防脑裂，不应该使用双副本，此处为了更简单的举例），应该是这样：

todo 表格
副本1  副本2
1a     1b
2a     2b
3a     3b

1a表示节点1的第个brick

不应该出现任意两个来自同一节点的brick在同一个副本中,例如：
副本1  副本2
1a     2b
1b     3a
2a     3b



以双副本+1仲裁  可以理解为三副本，但是第三个副本的每个brick都是仲裁brick

以4节点，每个节点3brick为例：
- 每个节点有两个brick大小相等，每个brick将各从属一个副本，各个节点共组件两副本
这些brick上存储完整的文件（这里不考虑官方已经启用的条带卷，仅考虑只存储原文件的复制卷或分布式复制卷）
- 每个节点有一个较小的brick用作仲裁（arbiter brick），该brick可用空间较小
 该brick只存储元数据信息用以校验，一般考虑要大于存储文件的brick的文件系统所需要的indoes空间，因为具体应用中无法预估实际要使用的inodes数量，可以以存储文件的brick当前分配的indoes值做参考，可使用`df -i`查看。
 以xfs文件系统为例，如果在mkfs.xfs创建文件系统时没有指定inodes的数量，则一般默认预留5%空间给inodes使用。
使用mkfs创建文件系统时可以指定inode的数量或百分比，具体查看相关的help了解。

```shell
# 4*(2+1)  distribute replica  1 arbiter
#sdd for every nodes is a smaller brick
#all sdd brick as a arbiter
#

gluster vol create vol1 replica 2 arbiter 1 \
io04:/storage/sdb/brick1 io02:/storage/sdc/brick1 io01:/storage/sdd/brick1 \
io03:/storage/sdb/brick1 io04:/storage/sdc/brick1 io02:/storage/sdd/brick1 \
io02:/storage/sdb/brick1 io01:/storage/sdc/brick1 io03:/storage/sdd/brick1 \
io01:/storage/sdb/brick1 io03:/storage/sdc/brick1 io04:/storage/sdd/brick1
#   replica 1               #replica 2            #replica 3 (arbiter vol)
```





挂载出现

# :glusterfs_graph_init] 0-share-quick-read: initializing translator failed 

检查客户端节点的内存大小和io server上卷设置的performance.cache-size大小，

如果performance.cache-size大小比客户端节点的内存大小还大，可能出现改问题。