> NFS 网络文件系统(Network File System) 是由Sun公司1984年发布的分布式文件系统协议。

# 安装

- windows

  - windows server 2012+：

    服务器管理器--添加角色和功能--服务器角色--文件和存储服务，勾选NFS相关选项。

  - windows 10+ Enterprise/Proffensional

    设置--应用--可选功能--添加可选功能，添加NFS功能项。

    或

    设置--应用--可选功能--更多windows功能，勾选添加NFS相关选项。
    
    

- Linux

  服务端和客户端均安装`nfs-utils`，服务端启动nfs服务。

  *不同发行版可能需要的包名不同，如debian安装`nfs-kernel-server`。*

  ```shell
  #nfsd, nfs-server，或nfsv4-server（用于NFS v4），不同发行版的systemd服务名可能不同
  systemctl enable --now nfsv4-server
  ```

  

- 按需对**防火墙配置**策略（或关闭防火墙）。

  - rpcbind：  111 /tcp/udp   （NFS v3）
  - nfsd：        2049/tcp  （NFS v3/v4）

  NFS v4以前的版本可能需要更多端口。

  

- NFS上文件的时间以NFS server的时间为基准，如果客户端和服务端有较大时间差距，NFS 可能产生非预期的延迟。

  为确保文件时间与系统时间尽量一致，应当使用NTP同步服务端和各个客户端的时间。
  
  

# 服务端配置

windows 端添加nfs服务器后，在要共享的目录上打开右键菜单的**属性**，找到NFS选项卡进行设置即可。

以下介绍为Linux端配置。

NFS共享的目录称为exported file system，可使用exportfs命令直接添加临时生效（重启服务后消失）的导出目录，持久化存储导出配置需要在`/etc/exports`或`/etc/exportfs.d/*.exports`文件中



## 导出文件系统exportfs

exportfs命令可管理当前NFS共享的文件系统。参数：

- `-a` 打开或取消配置文件中导出的所有共享目录
- `-r` 重新共享所有目录（配置文件中的）
- `-u` 取消导出的某个（需指定这个目录名字）或所有共享目录
- `-v` 输出详细信息
- `-f` 在“新”模式下，刷新内核共享表之外的任何东西。（任何活动的客户程序将在它们的下次请求中得到 mountd添加的新的共享条目。）
- `-s` 输出当前导出列表（信息来自`/etc/exports`）

```shell
#导出一个目录
exportfs  -o <option1,option2...> <allow-hosts>:<dir-

#添加一个共享目录（未写入配置，重启服务后会失效）
exportfs -o rw *:/tmp/a

exportfs #查看已经配置的共享目录
exportfs -v

exportfs -rsa #重新载入配置 修改配置文件后可使用改命令

exportfs -u #取消所有导出
exportfs -u *:/tmp/a  #取消/tmp/a的共享

exportfs -s
```



### exportfs配置文件

一般将导出配置写入/etc/exports以实现持久化，配置好该文件后，启动nfs服务或者执行`exportfs -a`会自动读取配置文件中的内容。



NFS v3配置：

```shell
#/path/to/dir  CIDR_or_IP_or_Hostname(options) [CIDR_or_IP_or_Hostname2(options) ...]
/data/home    192.168.0.0/24(rw,async,insecure,no_root_squash,subtree_check)
/share/public 192.168.1.1(ro,all_squash)
```



NFS v4配置：

需要配置fsid。 fsid=0或fsid=root表示NFS根目录，fsid=1表示导出的为tmpfs。



NFS v3仅支持导出整个目录，而对于NFS v4导出的根目录`/`是必须存在的，**其他导出的目录必须在它下面**。

NFS v4导出客户端挂载根目录的路径就是`/`，子目录就是`/<subdir>`，而v3的导出目录都是整个目录，客户端挂载使用的是服务端导出的完整路径。



当只有一个导出目录时不指定fsid则默认值为0，但是如果存在多个导出目录，不指定fsid则客户端访问就会存在问题（多个目录被视为了同一个导出的文件系统）。



有时NFS根目录不一定都是其他要被导出的目录的父目录，这种情况需要将其他要被导出的目录bind到NFS根目录的子目录上。

```shell
#示例 NFS 根目录是 /srv/nfs，将其他位置要共享的目录bind到该根目录的子目录
mount --bind /mnt/music /srv/nfs/music
mount --bind /home /srv/nfs/home
```

如果要在`/etc/fstab`中配置自动bind，写法如下：

```shell
/mnt/music /srv/nfs/music  none   bind   0   0
/home      /srv/nfs/home   none   bind   0   0
```



导出NFS根及其子目录：

```shell
#/etc/exports 或 /etc/exports.d/*.exports
/srv/nfs        192.168.1.0/24(rw,sync,crossmnt,fsid=0)  #作为其他共享目录的root
/srv/nfs/music  192.168.1.0/24(rw,sync)
/srv/nfs/home   192.168.1.0/24(rw,sync,nohide,no_root_squash)
/srv/nfs/public 192.168.1.0/24(ro,all_squash,insecure) desktop(rw,sync,all_squash,anonuid=99,anongid=99) # map to user/group - in this case nobody
```

以上导出目录如果不使用NFS根目录的模式，则客户端挂载的每个导出目录的路径都是完整路径；而使用了fsid指定根目录后，导出的根目录`/srv/nfs`对于客户端来说就是`/`，挂载路径是`<nfs-server>:/`而非`<nfs-server>:/srv/nfs`，同理，导出的子目录`music`的挂载路径是`<nfs-server>:/music`。



其他常用选项

- 文件权限：

  - `ro`只读，`rw`可读写

  - `exec`（默认）或`noexec`  可以或不可执行二进制文件

  - 目录树权限检查：

    - `subtree_check`  NFS检查父目录的权限

    - `no_subtree_check`  不检查父目录权限（默认）
    
      

- 端口策略

  - `secure`  限制客户端只能使用小于1024的端口（默认）

  - `insecure`  允许客户端使用1024以上的端口

    

- 数据写入

  - 同步异步：`sync` （默认）和 `async` 

    注意，`asyn`异步存储突然中断（例如断电）的情况下可能数据丢失

  - 延迟归并写入

    - `wdelay`  一次操作将多个写入请求提交到磁盘（默认），即一个写入请求可能会等待其他写入请求一起写入磁盘。可减少写开销，但是如果NFS服务器接收到的主要是无关的小请求，这种行为实际上可能降低性能。
    - `no_wdelay`  任何写入请求都立即写入，**当使用async时，该设置无效**。 

    

- 用户映射

  - root用户的映射

    - `root_squash`   root用户映射成匿名用户nfsnobody（默认）

    - `no_root_squash`   不映射root为nfsnobody，即客户端root用户在共享目录仍具有root权限。

      安全建议：如果要启用该功能，配置中允许访问的客户端地址范围的主机应该是可控的，例如限制可访问的主机地址，掌握有可访问的主机的root权限，root权限不被不可信任的人获取。

  - 任何用户的映射

    - `no_all_squash`  不映射用户（默认）
    - `all_squash`  任何用户映射成匿名用户nfsnobody

  - uid和gid的映射

    `anonuid=`  或 `anongid=`   映射用户为指定的uid和gid，和`root_squash` 以及`all_squash`一同使用。

    

- 子目录是否隐藏：`no_hide`（默认）或`hide`

  NFS v4开始`hide`无效，子目录总是显示。




## 文件锁

如果遇到提示`lock: No locks available`之类的信息，服务端启动rpc-statd（也可能是rpc.statd）服务和rpc-lockd（也可能是rpc.lockd）服务。



## 其他相关命令

查看nfs状态（服务端）：`nfsstat`

查看rpc执行信息：`rpcinfo`

# 客户端挂载

*示例挂载192.168.0.251的/share到客户端的/share。*

## linux

手动挂载

对于NFSv3，使用以下命令显示服务器分享的文件系统： 

```shell
showmount -e server
mount -t nfs -o vers=3 192.168.0.251:/share /share
```

showmount常用选项：

- `-a` 列出所有客户端挂载点信息

- `-e` 显示服务端导出目录

- `-d` 列出客户端挂载的目录

如果使用`showmount -e 或者mount时出现`clnt_create: RPC: Program not registered`错误，表示rpc程序未注册成功，这是因为客户端使用了nfs v4之前的协议，这需要服务端启用rpcbind。



对于NFSv4，可以挂载NFS根目录以查看可挂载的子目录，当然也可以直接挂载子目录：

```shell
#mount server:/ /mountpoint/on/client
mount 192.168.0.251:/ /mnt          #挂载nfs根目录
mount 192.168.0.251:/music /music   #挂载子目录
```

*因为对于v4，如果启用了rpcbind，showmount可用，但是showmount并不会展示服务端的`/`目录为`server:/`样式，不能确定列出的目录中哪一个是`/`。*



写入`/etc/fstab`自动挂载

```shell
192.168.0.251:/share /share nfs defaults,_netdev,timeo=10,retrans=3	0 0
```

也可使用autofs等工具挂载。



常用选项：

- `timeo=<num>`   超时时间（单位秒），默认值根据具体客户端情况而定

- `retrans=<num>`   重试次数

- `vers=<ver-num>`  NFS协议版本，如`4.2`，每个客户端系统的默认值根据具体情况而定。

- `noacl`  关闭acl支持

- `sec=`  一个或多个以冒号分隔的值，可以是：

  - `sec=sys` 使用本地 UNIX UID 和 GID（默认）；
  - `sec=krb5` 使用 Kerberos V5；
  - `sec=krb5i` 使用 Kerberos V5 进行用户身份验证，并使用安全校验和执行 NFS 操作的完整性检查；
  - `sec=krb5p` 使用 Kerberos V5 进行用户身份验证、完整性检查，并加密 NFS 流量以防止流量嗅探。这是最安全的设置，但它也会涉及最大的性能开销。 							

- `noexec`  禁止客户端执行二进制文件

- `port`  指定NFS服务器的端口号（默认为2049）

- proc  指定通信协议为还是tcp

- `rsize=<num>` 和 `wsize=<num>`  单一NFS 读写操作传输的最大字节数。

  没有固定的默认值。默认情况下，NFS 使用服务器和客户端都支持的最大的可能值



## windows

```powershell
mount -o nolock \\192.168.0.251\share Z:
```

`z:`是要挂载的位置

可使用windows任务计划程序实现自动挂载。选项参照linux，但不一定都支持。



# 其他相关配置

## NFS v4+的ACL

v4+版本开始，不可再使用系统的ACL，而需要使用NFS内置的nfs4acl。



## NFSoRDMA

mellanox驱动安装时添加` --with-nfsrdma`参数：

```shell
./mlnxofedinstall  --with-nfsrdma
```

可查看mellanox驱动对应版本的release Notes文件中General Support部分对NFS over RDMA (NFSoRDMA) Supported Operating Systems的描述。



服务端：

```shell
#以下信息不会持久化存储，应当采用其他方式令其启动后执行
modprobe svcrdma
echo rdma 20049 > /proc/fs/nfsd/portlist
cat /proc/fs/nfsd/portlist #rdma 20049  udp 2049  tcp 2049
```



客户端：

```shell
modprobe xprtrdma

mount -o proto=rdma,port=20049 <server IPoIB>:<dir> <mountpoint>

#fstab
#192.168.0.251:/share /share nfs proto=rdma,port=20049,defaults,_netdev	0 0
```



