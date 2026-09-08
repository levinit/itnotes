# 简介

GlusterFS 是一个高扩展性、高可用性、高性能、可横向扩展的分布式网络文件系统。

- **无集中式元数据服务**
- 全局统一命名空间
- 采用哈希算法定位文件
- 弹性卷管理

适用于大文件存储场景，对海量小文件存储和访问效率不佳。多用于云存储、虚拟化存储、HPC领域。



## 基本概念

- cluster集群

  相互连接的一组服务器，他们协同工作共同完成某一个功能，对外界来说就像一台主机。

- Server / Node / Peer  节点

  单台服务器，在glusterfs中单个节点被称为peer，是运行gluster和分享“卷”的服务器。

- Trusted Storage Pool  可信的存储池

  peer节点的集合，是存储服务器所组成的可信网络。

- Brick “砖块” 即存储块

  可信主机池中由主机提供的用于物理存储的专用分区。

- Volume 卷（逻辑卷）

  Brick组成的逻辑集合，是存储数据的逻辑设备。

  - SubVolume 分卷

    由多个Brick逻辑构成的卷，是其它卷的子卷，特定[卷类型](卷类型)中存在。

    *比如在`分布复制卷`中每一组复制的Brick就构成了一个复制的分卷(subvolume)，而这些分卷又组成了逻辑卷(volume)。*

- Client 客户端

  挂载glusterfs共享的Volume（卷）的主机。
  
  

## 卷类型

参看[Setting up GlusterFS Volumes](https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Volumes/#creating-distributed-replicated-volumes)

- 基本卷类型
  - 分布式 Distributed

    文件分布到brick server上，无冗余，可看作文件级RAID0，如果有一个存储块所在硬盘损坏，**对应的数据也丢失**。

    文件通过DHT（Distributed Hash Table，分布式哈希表算法），对文件名进行hash计算，以确定文件存放的位置，因此分布式卷又称为哈希卷。其有以下特点：

    - hash计算时不包含文件名对后缀

      例如`1.txt`和`1`等同

    - 不包含文件所在的目录的路径

      例如`a/b/1.txt`、`a/1.txt`与`1.txt`也是等同的
  
    - 根据以上两条原则，一旦确定某个名字的文件存放在哪个节点的brick上，以后创建的任何路径的同名文件总是存放在相同的节点的brick上
  
      例如`1.txt`hash后被存放在`io01`的brick上，其后创建的任何同名（`1`）文件均存放到`io01`的brick上。
  
    
  
  - 复制 Replicated
  
    为了[处理脑裂（split brain）问题](https://docs.gluster.org/en/latest/Administrator-Guide/Split-brain-and-ways-to-deal-with-it/#split-brain)，复制卷副本数量应该为单数（例如使用3副本），或者使用仲裁卷(arbiter volume)。
  
    
  
  - 分散 Dispersed
  
    
  
- 复合卷类型

  glusterfs的复合卷是分布式卷，复合卷由子卷组成，子卷是基本卷，子卷由brick组成。

  - 分布式复制 Distributed Replicated

    多个复制卷组成的分布式卷，分布式卷的每个子卷为复制卷。

  - 分布式分散 Distributed Dispersed

    多个分散卷组成的分布式卷，分布式卷的每个子卷为分散卷。

# 服务端创建卷

server节点的准备：

- root用户ssh密钥认证
- 配置好/etc/hosts的主机名映射（组建存储时使用IP不利用后期迁移等工作）

- selinux和firewalld关闭或为glusterfs配置好策略

  glusterfs端口24007

- 准备好存放glusterfs brick的目录



1. 组建存储池（glusterfs trusted storage pool）

   在其中一个glusterfs节点上添加其他glusterfs节点以组建存储池

2. 创建卷



server节点创建卷示例：

```shell
#--创建pool
for node in io{01..03}
do
  ssh $node "yum install -y glusterfs-server"
  systemctl -H $node enable --now glusterd  #启动glusterd
  gluster peer probe $node #加入pool
  ssh $node "mkdir -p /storage/brick1"  #创建brick目录
done
gluster pool list

#--创建卷
#gluster volume create <vol name> [transport tcp,rdma] io{01..02}:/storage/brick1
#分布式
gluster v create <volname> io{01..02}:/storage/brick1

#3副本
gluster v create <volname> replica 3 io{01..3}:/storage/brick1
#2副本1仲裁
gluster v create <volname> replica 3 arbiter 1 io{01..3}:/storage/brick1

#分散卷（EC纠删码）2+1 ，3分散 1冗余
gluster v create <volname> disperse 3 redundancy 1 io1.ib:/storage/brick1 io2.ib:/storage/brick1 io3.ib:/storage/brick1

#启用卷
gluster v start <volname>
```

组建复合卷时，主要要按照正确的子卷顺序添加brick。

例如分布式复制卷3x3（3个3副本复制卷组建一个分布式卷），要按照每个复制子卷逐一添加：

```shell
gluster v create rep-vol replica 3 \
io1:/storage/brick1 io2:/storage/brick1 io3:/storage/brick1 \ #子卷1
io1:/storage/brick2 io2:/storage/brick2 io3:/storage/brick2 \ #子卷2
io1:/storage/brick3 io2:/storage/brick3 io3:/storage/brick3  #子卷3
```

复合卷的子卷中的各个brick应当分布在不同server节点，如果一个子卷的2个（或更多）brick分布在同一server上，当这个server掉线时，整个子卷不可用，造成复合卷（复合卷时一个分布式卷）数据不完整 。



# 客户端挂载卷

## navtive client

在linux上使用glusterfs-fuse。

client节点挂载示例：

```shell
yum install -y glusterfs glusterfs-fuse
mkdir /share
mount -t -o reader-thread-count=8,acl glusterfs io01:/share /share
```

挂载参数

- `backupvolfile-server`  指定一个备用挂载的server

- `backup-volfile-servers`   指定备用挂载节点（server节点）列表（多个volfile）

  使用`:`分隔多个，如`io01:io02`

- `log-level`  指定日志级别

  取值：TRACE, DEBUG, WARNING,ERROR, CRITICAL INFO, NONE

- `log-file`  指定一个日志文件

  如不指定，日志一般位于`/var/log/glusterfs`下，以卷的名字为前缀的文件。

- `transport-type`  通信传输模式

  取值：`tcp`、`rdma`或者两者皆有`tcp,rdma`，默认`tcp`。

- `dump-fuse`  指定一个转储文件

  glusterfs client和linux kernel之间的流量信息。

- `ro`   启用只读模式

- `acl`  启用acl

- `background-qlen`   指定fuse请求处理之前最大的请求队列

  默认64

- `reader-thread-count`   指定fuse的读线程数

  默认1，增大这个线程可以获取比较好的读性能

- `lru-limit`  指定采用lru方式限制客户端缓存的最大inodes数量

  默认是131072
  
- `enable-ino32`  允许文件系统呈现32位内码而不是64位内码

  

在`/etc/fstab`中添加挂载示例：

```shell
#<file system>	<dir>  <type>	<options>	 <dump> 	<pass>
io01:/share  /share  glusterfs  _netdev,defaults,acl,backup-volfile-servers=io02:io03,log-level=WARNING,reader-thread-count=8   0 0
```

`_netdev`参数将当成网络设备挂载，只有网络就绪后才执行。



## nfs挂载

在任意glusterfs server节点为glusterfs卷开启nfs：

```shell
vol=share
gluster v set $vol nfs.disable off
```



## samba挂载

方法1：参考[Gluster-from-Windows](https://docs.gluster.org/en/latest/Administrator-Guide/Accessing-Gluster-from-Windows/)配置samab+ctdb

方法2：在挂载glusterfs卷的客户端上配置挂载点目录的samab共享

方法3：samba配合`samba-vfs-glusterfs`，方法如下

在所有glusterfs server节点执行：

```shell
yum install samba-vfs-glusterfs samba
systemctl enable --now samba
```

配置samba文件`/etc/samba/smb.conf`，示例：

```ini
[global]
workgroup = WORKGROUP
security = user

passdb backend = tdbsam

printing = cups
printcap name = cups
load printers = yes
cups options = raw
kernel share modes = no
kernel oplocks = no
map archive = no
map hidden = no
map read only = no
map system = no
store dos attributes = yes

;配置glusterfs共享目录
;普通samba模式，将glusterfs卷挂载到某个目录（例如/statics），配置该目录的共享
[static]
comment = For testing a Gluster volume exported through CIFS
path = /statics
browseable = yes
write list = root
read only = no

;gluster-static模式，可用glusterfs特定参数指定要共享的卷
[gluster-static]
comment = For samba share of volume static
vfs objects = glusterfs
;glusterfs卷名
glusterfs:volume = static
;该glusterfs卷的log日志路径
glusterfs:logfile = /var/log/samba/glusterfs-static.%M.log
glusterfs:loglevel = 7
path = /
read only = no
guest ok = yes
```

使用samba客户端挂载即可。

如果使用glusterfs-static模式，挂载的路径是`samaba主机地址/path/to/glusterfs-vol`。例如`glusterfs:volume=share`，`path=/`，主机地址为io01，则挂载地址为`io01:/share`。



# 配额quota

按目录或卷设置磁盘空间使用限制，配额有两个级别：

- 目录级别
- 卷级别

在glusterfs server端操作：

```shell
#开启配额
gluster v quota <volname> enable  #disable关闭
 
#配额
gluster v quota <volname> limit-usage <dir-parth> <size>

#移除配额
gluster volume quota <volname> remove <dir-path>

#查看配额信息
gluster v quota <volname> list            #某个卷的所有配额目录信息
gluster v quota <volname> list <dir-path> #指定目录的配额信息

#开启df显示配额（卷配额情况下才有用）
gluster v set <volname> quota-deem-statfs on

#配额警告时间，是达到软限制后警告频率， time默认1w（一周），可以设置诸如1d
gluster volume quota <volname> alert-time <time>
```

- 配额目录路径的是该卷中目录的路径，卷的根目录是`/`，对`/`设置配额即对该卷进行配额。

  例如：一个卷`vol1`挂载到客户端的`/share`，要对`/share/test`配额，配额命令中的路径是`/test`，与客户端挂载点的路径无关。

- 可以在空目录上设置配额限制，当文件添加到目录时，配额限制将自动执行。



# 调优tune

## 系统参数调整

参考：

- [glusterfs doc - linux tuning](https://docs.gluster.org/en/latest/Administrator-Guide/Linux-Kernel-Tuning/)

- [redhat glusterfs storage doc - virtual memory params](https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3/html/administration_guide/sect-memory)

vm参数：

| 参数                      | 默认值 | 调整值 | 说明                                                         |
| ------------------------- | ------ | ------ | ------------------------------------------------------------ |
| vm.swappiness             | 10     | 0      | 触发使用交换分区的剩余内存百分比。                           |
| vm.dirty_ratio            | 20     | 5      | 脏数据占可用内存的百分比达到该值触发同步写。                 |
| vm.dirty_background_ratio | 10     | 3      | 脏数据占可用内存的百分比达到该值触发触发数据回刷（异步写入磁盘）。 |

vm.swappiness值为0表示完全不使用交换分区，当内存耗尽时会触发OOM killer终止内存占用最大的进程。

*swappiness值可以设置为0，但稳妥起见该值不宜为0，避免glusterd某些场景下被终止的可能，具体值根据实际内存配置情况设置。glusterfs某些版本有偶发内存泄漏问题导致glusterd内存占用飙升。*

对于大文件顺序IO场景使用较大的dirty值，对于小文件和随机IO场景使用较小的值：

> The appropriate values of these parameters vary with the type of workload:
>
> - Large-file sequential I/O workloads benefit from higher values for these parameters.
> - For small-file and random I/O workloads it is recommended to keep these parameter values low.

```shell
#/etc/sysctl.d/vm.conf  |  sysctl -f
vm.swappiness=0
vm.vfs_cache_pressure=150
vm.dirty_ratio=5
vm.dirty_background_ratio=3
```



centos/rhel  tuned

```shell
tuned-adm profile network-latency
```



## glusterfs参数调整

glusterfs调优相关命令：

```shell
#查看全局参数
gluster v get all all

#查看某个卷的参数
gluster v get <vol-name> all   #所有参数
gluster v get <vol-name> <parama-key>  #指定参数

#设置全局参数
gluster v set all <param-key> <param-val>
#设置卷参数
gluster v set <vol-name> <param-key> <param-val>

#重置全局参数
gluster v reset all
#重置指定卷参数
gluster v reset <vol-name>
```



全局调整参数

| 参数                      | 默认值  | 设置值  | 说明             |
| ------------------------- | ------- | ------- | ---------------- |
| cluster.daemon-log-level  | INFO    | WARNING | 守护进程日志级别 |
| cluster.localtime-logging | disable | enable  | 日志使用本地时间 |



卷参数

以下重要优化参数在较新glusterfs中已经默认启用：

| 参数                          | 默认值 | 说明                                                         |
| ----------------------------- | ------ | ------------------------------------------------------------ |
| performance.quick-read        | on     | 快速读功能提升小文件读性能                                   |
| performance.io-cache          | on     | 缓存已经被读过的数据                                         |
| performance.readdir-ahead     | on     | 为目录提供预先读取支持，以提高顺序目录读取操作性能。         |
| performance.read-ahead        | on     | 文件预读 请求不连续时无效                                    |
| performance.write-behind      | on     | 延后写（数据写入内部队列并积累到一定aggregate-size才处理）   |
| performance.flush-behind      | on     | 数据写入到内部队列后直接返回操作结果（需要write-behind)      |
| performance.flush-behind      | on     | write-behind延时写在后台执行刷新 提前返回写入完成信号        |
| performance.force-readdirp    | true   | 将所有readdir请求转换为readdirplus，以收集每个条目的统计信息。 |
| performance.client-io-threads | on     | 多线程IO并发处理，仅用于EC分散卷                             |
| cluster.lookup-optimize       | on     |                                                              |

- `cluster.lookup-optimize`  在处理查找卷中不存在的条目时会有性能损失。因为DHT会试图 在所有子卷中查找文件，所以这种查找代价很高，并且通常会减慢文件的创建速度。 这尤其会影响小文件的性能，其中大量文件被快速连续地添加/创建。 查找卷中不存在的条目的查找扇出行为可以通过在一个均衡 过的卷中不进行相同的执行进行优化



调整的卷参数：

这些值一般应当根据情况进行调整：

| 参数                                 | 默认值   | 可取值     | 说明                      |
| ------------------------------------ | -------- | ---------- | ------------------------- |
| cluster.min-free-disk                | 10%      | 0%-100%    | 最小剩余空间百分比        |
| network.ping-timeout                 | 42       | 30-300     | server超时等待时间(se c)  |
| server.tcp-user-timeout              | 42       | 30-300     | tcp连接下用户超时时间     |
| storage.linux-aio                    | off      | on/off     | 使用linux aio 异步IO模式  |
| performance.parallel-readdir         | off      | on/off     | 并行readdir功能           |
| performance.cache-size               | 32MB     | 4MB-♾️      | 读缓存大小                |
| client.event-threads                 | 2        | 1-32       | 客户端线程数量            |
| server.event-threads                 | 2        | 1-32       | 服务端线程数量            |
| performance.io-thread-count          | 16       | 1-64       | IO线程数量                |
| group metadata-cache                 | (未启用) |            | 启用元数据缓存 无取值     |
| network.inode-lru-limit              | 200000   | 0-1048576  | 元数据缓存文件数量        |
| cache-samba-metadata                 | false    | true/false |                           |
| performance.write-behind-window-size | 1M       | 512KB-1GB  | 单个文件写缓冲区大小      |
| aggregate-size                       | 128K     | 0-♾️        | write-behindn内部队列大小 |
| server.outstanding-rpc-limit         | 64       | 0-65535    | 客户端rpc请求数           |
| performance.read-ahead-page-count    | 4        | 1-16       | 预读取页数                |
| lookup-unhashed                      | on       | on/off     |                           |
| features.cache-invalidation          | off      | true/false |                           |
| performance.cache-invalidation       | off      | true/false |                           |
| cache-invalidation-timeout           | 1        | 1-♾️        |                           |
| performance.qr-cache-timeout         | 1        | 1-♾️        |                           |

- `performance.cache-size`：该值如果大于某个客户端的内存，则该客户端不能挂载此卷。
- `group metadata-cache`：设置后即启用，无取值。

具体值根据实际情况修改。

这些值一般较少调整，可根据具体情况酌情调整：

| 参数                            | 默认值 | 可取值 | 说明                              |
| ------------------------------- | ------ | :----- | --------------------------------- |
| performance.cache-max-file-size | 0      | 0-♾️    | 缓存文件的最大尺寸（无限制）      |
| performance.cache-max-file-size | 0      | 0-♾️    | 缓存文件的最小尺寸（无限制）      |
| performance.rda-cache-limit     | 10MB   | 1B-♾️   | 预读取目录数据缓存大小            |
| cluster.read-hash-mode          | 1      | 1-4    | 读取数据选择子卷(subvolume)的策略 |



```shell
vol=share      #vol name
server_cpus=32
client_cpus=32
read_cache_size=16GB

#日志记录级别 由默认的INFO调整为WARINING，仅记录警告级别以上的日志
gluster v set all cluster.daemon-log-level WARNING
#日志中的时间以系统本地时间记录（默认使用UTC +0)
gluster v set all cluster.localtime-logging enable

#节点检测超时时间
gluster v set $vol network.ping-timeout 3
gluster v set $vol server.tcp-user-timeout 3

#读缓存
gluster v set $vol performance.cache-size $read_cache_size

#延迟写
gluster v set $vol performance.write-behind-window-size 1GB
gluster v set $vol aggregate-size 8MB

#线程数量
gluster v set $vol server.event-threads $server_cpus
gluster v set $vol client.event-threads $client_cpus
gluster v set $vol performance.io-thread-count $client_cpus

#元数据缓存
gluster v set $vol group metadata-cache
gluster v set $vol network.inode-lru-limit 1000000
gluster v set $vol cache-samba-metadata on
gluster v set $vol xattr-cache-list "comma separated xattr list"

#aio异步
gluster v set $vol storage.linux-aio on

#目录缓存
#list dir
gluster v set $vol performance.parallel-readdir on
#create/deletes dir/file
gluster v set $vol group nl-cache 
gluster v set $vol nl-cache-positive-entry on
#gluster v set $vol performance.nl-cache-limit 10M #default 10M

gluster v set $vol performance.cache-invalidation on
gluster v set $vol features.cache-invalidation on
gluster v set $vol performance.qr-cache-timeout 600 #default 1
gluster v set $vol cache-invalidation-timeout 600   #default 1
```

lookup-unhashed  lookup-optimize cluster-optim



调优参数详细说明：

- 超时等待

  - `network.ping-timeout` 
  - ` server.tcp-user-timeout`

  当检测到有server节点掉线，客户端挂载的卷将挂起无法操作（表现为和改挂载卷的相关操作卡顿），直到满足一下两个条件之一：

  - 检测到掉线的server节点重新上线
  - 达到超时的时间（秒）（`network.ping-timeout`）

  

- IO缓存

  - `performance.io-cache` 

    - `performance.cache-size`

      缓存将消耗内存空间，应当根据实际内存配置、系统可用内存等信息预估。

    - `performance.cache-max-file-size` 和`performance.cache-min-file-size`

      默认是0，没有限制。

    

- 目录读取优化

  - `performance.readdir-ahead`   目录预缓存
    - `performance.rda-cache-limit`   目录预缓存限制（默认10MB一般足够）
    - `performance.force-readdirp`  将所有readdir请求转换为readdirplus，以收集每个条目的统计信息 （默认开）
    - `performance.parallel-readdir`  并行读

  

- 延迟写

  - `performance.write-behind`

    当执行IO操作时候会在客户端把IO加入一个内部队列，当内部队列积累的数量（达到一定aggregate-size）后统一进行通过网络发到后端存储或者经过下一个xlator的处理，这个是异步处理。

    - `aggregate-size`   累计的队列大小

    - `performance.flush-behindon`    数据写入到内部队列后直接返回操作结果

    - `performance.write-behind-window-size`

      单个文件写缓冲区大小 



- 多线程处理

  - `performance.client-io-threads`

    多线程并行读取EC卷数据（EC数据进行了分片，多线程处理可以提高读取数据效率）

  - `server.event-threads`和`client.event-threads`  服务端和客户端上处理glusterfs连接事件的线程数量
    该值适当增加提升整体IO性能，但该值不要超过server/client节点的可用cpu数量（使用`lscpu`查看`On-line CPU(s) list`行的值）。

    可根据服务端进程（glusterfsd）或客户端进程（glusterfs或gfapi）上的连接计数设置较为合适的值，配置高于可用处理单元的事件线程值可能会再次导致这些线程的上下文切换。

  - `performance.io-thread-count`  实际IO操作线程的数量

    参考`event-threads`，它比`event-threads`更底层。

  

- `group meta-cache`  启用元数据缓存，可以提高操作文件/目录元数据的新建、删除、列出、改名操作的性能

  该参数启用后将同时启用这些关联参数：

  >network.inode-lru-limit: 200000           #缓存inode数量（其采用LRU最近最少使用淘汰算法）
  >
  >performance.md-cache-timeout: 600  #缓存超时时间
  >
  >performance.cache-invalidation: on  
  >
  >performance.stat-prefetch: on
  >
  >features.cache-invalidation-timeout: 600
  >
  >features.cache-invalidation: on

  可适当调整`network.inode-lru-limit` 和`performance.md-cache-timeout`。



- `cluster.read-hash-mode`  读取数据时子卷选择策略

  不同取值代表的策略为：

  - `1`  根据文件的gfid选择子卷
  - `2`  根据客户端 mount的pid和gfid选择子卷
  - `3`  根据最少请求读取子卷
  - `4`  选择网络延迟最小的子卷



## 监控

```shell
#开启
gluster volume profile <volname> start  #stop 停止

#查看
gluster volume profile <volname> info

#查看每个brick的读/写取性能  bs单位为Byte
gluster volume top read-perf [bs] [brick ] [list-cnt] #write 写
```

开启了profile的卷的info信息中包含以下内容：

> ```shell
> diagnostics.count-fop-hits: on
> diagnostics.latency-measurement: on
> ```



# 扩容、收缩和迁移

扩容：

1. 添加新的节点（新节点完成了各种[准备](#准备)操作）

2. 添加新的存储块

   ```shell
   gluster volume add-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 # 合并卷
   ```

收缩：危险操作，有数据丢失风险，收缩卷前先移动数据到其他位置以确保数据安全。

```shell
gluster volume remove-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 start 

#可查看完成状态
gluster volume remove-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 status 
```

迁移：迁移一个brick上的数据到另一个brick

```shell
gluster volume replace-brick GPUFS node5:/mnt/md0 node6:/mnt/md0 start 

# 查看迁移状态 
gluster volume replace-brick GPUFS node5:/mnt/md0 node6:/mnt/md0 status

gluster volume heal  <volume-name>  full # 同步整个卷
```

