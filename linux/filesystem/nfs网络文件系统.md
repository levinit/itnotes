> NFS 网络文件系统(Network File System) 是由Sun公司1984年发布的分布式文件系统协议。



# 安装

- windows

  - windows server 12+：

    服务器管理器--添加角色和功能--服务器角色--文件和存储服务，勾选NFS相关选项。

  - windows 10+ Enterprise/Proffensional

    设置--应用--可选功能--添加可选功能，添加NFS功能项。

    或

    设置--应用--可选功能--更多windows功能，勾选添加NFS相关选项。

- Linux

  服务端和客户端均安装`nfs-utils`，如还需支持v4版以前的协议，还需要安装`rpcbind`。

  服务端启动`nfs`（或名`nfs-server`）服务，如还需支持v4版以前的协议，还需启用`rpcbind`服务。

  

- 按需对**防火墙配置**策略（或关闭防火墙）。

- **如果客户端和服务端有较大时间差距，NFS 可能产生非预期的延迟。**



# 服务端配置

windows 端添加nfs服务器后，在要共享的目录上打开右键菜单的**属性**，找到NFS选项卡进行设置即可。

以下介绍为linux端配置：

```shell
#导出一个目录
exportfs  -o <option1,option2...> <allow-hosts>:<dir-path>
#示例 将/tmp目录导出共享给任意主机
exportfs -o async *:/tmp
#查看共享的目录
exportfs
```

也可以将导出目录写到`/etc/exportfs`文件中。



## 配置文件

编辑`/etc/exports`，添加导出文件系统的相关配置：

```shell
#共享目录 允许访问的主机(配置选项)
/share 192.168.0.0/24(rw,async,insecure,no_root_squash)
/share 192.168.1.1(ro,async)
```

`/share`  为共享目录

`192.168.0.0/24`为可访问的网段（可以是域名，**支持通配符**）

括号中为各个选项，部分选项说明：

- 访问权限：

  - `ro`只读
  - `rw`可读写

- 安全策略

  - `insecure`  允许客户端使用1024以上的端口

  - `secure`  限制客户端只能使用小于1024的端口（默认）

  - `subtree_check`  NFS检查父目录的权限（默认） 

  - `no_subtree_check`  不检查父目录权限

    关闭subtree检查可以提高性能，但是安全性降低。

  - `exec`（默认）或`noexec`  可以或不可执行二进制文件

- 数据写入规则

  - `async`  异步写入
  - `sync`  同步写入（默认）
  - `wdelay`  如果多个用户要写入NFS共享目录，则归组写入（默认） 
  - `no_wdelay`  如果多个用户要写入NFS目录，则立即写入，**当使用async时，无需此设置**。 
  - `size`  缓冲区大小

- 用户映射

  NFS客户端操作挂载自服务端的共享目录时，客户端的用户压缩（映射）策略：

  - `root_squash`   root用户映射成匿名用户nfsnobody

  - `no_root_squash`   不映射root

    客户端root用户在共享目录仍具有root权限，该情况下存在安全隐患。

    *如果要启用该功能，配置中允许访问的地址范围的主机应该是可控的，例如限制可访问的主机地址，掌握有可访问的主机的root权限，root权限不被不可信任的人获取。*

  - `all_squash`  任何用户映射成匿名用户nfsnobody

  - `no_all_squash`  不映射用户

  - `anonuid=`  或 `anongid=`   映射用户为指定的uid和gid

    和`root_squash` 以及`all_squash`一同使用。

- `no_hide` 共享NFS目录的子目录（默认）

- `bg`/`fg` 以后台/前台形式执行挂载

- `fsid=<数字>`或`fsid=root`或`fsid=<uuid>`  导出的文件系统（即共享目录的文件系统）的识别号。

  通常fsid是文件系统的UUID（默认值）；不存储在该设备上的文件系统和没有UUID的文件系统需要显示地指定fsid（该值需唯一）。

  如果使用NFSv4，其能够指定所有导出的文件系统的root，通过`fsid=root`或`fsid=0`来标识。系统不能指定时须手动添加该配置项。

  注意：`fsid=0`选项的时候只能共享一个目录，这个目录将成为NFS服务器的根目录。



## 导出文件系统exportfs

管理当前NFS共享的文件系统。参数：

- `-a` 打开或取消配置文件中导出的所有共享目录
- `-r` 重新共享所有目录（配置文件中的）
- `-u` 取消导出的某个（需指定这个目录名字）或所有共享目录
- `-v` 输出详细信息
- `-f` 在“新”模式下，刷新内核共享表之外的任何东西。（任何活动的客户程序将在它们的下次请求中得到 mountd添加的新的共享条目。）
- `-s` 输出当前导出列表（信息来自`/etc/exportfs`）

```shell
#添加一个共享目录（未写入配置，重启服务后会失效）
exportfs -o rw *:/tmp/a

exportfs #查看已经配置的共享目录
exportfs -v

exportfs -rsa #重新载入配置 修改配置文件后可使用改命令

exportfs -u #取消所有导出
exportfs -u *:/tmp/a  #取消/tmp/a的共享
```



# 客户端挂载

## 获取挂载信息showmount

参数：

- `-a` 列出所有客户端挂载点信息

- `-e` 显示服务端导出目录

- `-d` 列出客户端挂载的目录

  ```shell
  #showmont [参数] [地址/主机名]
  showmount  #显示挂载当前主机的客户端信息
  showmount -a
  showmount -d 192.168.0.251
  showmount -e 192.168.0.251
  ```

  以上命令如指定“地址/主机名”，默认使用当前系统主机名。

  如果使用`showmount -e`检测服务端服务器情况出现`clnt_create: RPC: Program not registered`错误，表示rpc程序未注册成功，关闭`rpcbind`和`nfs`，再依次重启即可。

  ```shell
  systemctl stop rpcbind
  systemctl stop nfs
  
  systemctl start rpcbind
  systemctl start nfs
  ```

## 挂载

*示例挂载192.168.0.251的/share到客户端的/share。*

- 使用mount 挂载

  - linux

    手动挂载

    ```shell
    mount -t nfs 192.168.0.251:/share /share
    ```

    写入`/etc/fstab`自动挂载

    ```shell
    192.168.0.251:/share /share nfs defaults,_netdev	0 0
    ```

    autofs等工具挂载

  - windows

    ```powershell
    mount -o nolock \\192.168.0.251\share Z:
    ```

    `z:`是要挂载的位置
    
    可使用windows任务计划程序实现自动挂载。


## 其他相关命令

查看nfs状态（服务端）：`nfsstat`

查看rpc执行信息：`rpcinfo`