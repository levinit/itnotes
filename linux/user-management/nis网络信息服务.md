[TOC]

# 简介

NIS（ NetworkInformation Service）提供了一个网络黄页（Yellow Pages）的功能。服务端将用户信息加入到资料库中；客户端上用户登录系统时，系统会到NIS服务器上去寻找用户使用的帐号密码信息加以比对，以提供用户登录检验。

NIS通过RPC（Remote Procedure Call，远程过程调用）协议通讯。

在 NIS 环境中， 有三种类型的主机： 主服务器， 从服务器， 以及客户机。



nis系列工具主要包括：

- ypserv   ：NIS Server 端工具
- ypbind   ：NIS Client 端工具
- yp-tools ：提供 NIS 相关的工具



配置nis前一遍应当做好主机名解析（使用DNS server或hosts文件）。



# 服务端

## 主服务器配置

### 安装和启动服务

```shell
#rhel系
yum install -y ypserv
systemctl enable --now ypserv yppasswdd

#debian系
apt install -y nis          #随后会提示配置相关信息
systemctl start ypserv yppasswdd

systemctl enable --now nis  #一般安装后即会自行enable改服务
```

NIS 服务器同时也可以作为客户端，参看后文[客户端](#客户端)。

Debian中需要在`/etc/defaults/nis`文件中设置`NISSERVER=master`。

Debian中nis这个启动单元包含多个子单元，启动nis单元时会同时拉起客户端的ypbind服务。由于server尚未配置，造成ypbind卡住而影响ypserv启动，因此首次启动最好不启动nis单元，只启动ypserv和yppasswdd（可选）。

当然也可以在`/etc/defaults/nis`文件中设置`NISCLIENT=false`，该主机将不会作为客户端，这样首次启动nis单元就不会卡住。配置：

```shell
sed -i -E -e "/NISSERVER=/ s/false/master/" -e "/NISCLIENT=/ s/true/false/" /etc/default/nis
```



### 配置nisdomain

nis网域设定，临时设置domain：

```shell
domainname [-y] <domain-name>  #ypdomainname 或 nisdomainname亦可
```

Debian/Ubuntu安装nis后会提示输入nisdomain，或者使用`dpkg-reconfigure  nis`设置。



持久化设置nisdomain：

- debian系列，可以向`/etc/defaultdomain`文件中写入名称

- redhat系列，编辑`/etc/sysconfig/network`，添加网域名称和端口，示例：

  ```shell
  NETWORKING=yes
  HOSTNAME=master
  NISDOMAIN=cluster
  #YPSERV_ARGS="-p 1011" #可选 指定运行端口
  ```



也可以在配置好nis server后，可再将nis server也配置为一个client，domainname、nis sever等配置信息会持久化存储到配置中。

redhat系列，可使用authconfig-tui交互设置，或者使用authconfig （或authconfig-tui、authconfig-gtk等）命令：

```shell
authconfig --nisdomain=hpc --update #nis ypserv没有启动时，该命令会卡住
```



### 建立NIS映射文件

NIS信息映射（map）文件，一般默认默认保存在`/var/yp/`下与nisdomain同名的目录中。



``/var/yp/``目录中存在一个`Makefile`文件，该文件定义了生成各种map文件的逻辑代码，执行`make -C /var/yp`会使用这个Makefile文件生成map文件，初始化NIS服务的操作最后也是调用了`make -C /var/yp`命令生产map文件。



> 默认的Makefile文件中`MERGE_PASSWD`值可能为`true`，这会将密码散列值合并到passwd map，任意普通用户都能通过`ypcat passwd`或者`getent passwd`查看到用户密码的hash值（`getent shadow`需要root权限）。
>
> 在生成映射文件前，可按如下内容配置，避免将密码散列值合并到passwd map，而是将真正的密码散列值存储在shadow map中（就像`/etc/passwd`和`/etc/shadow`的行为一样）：
>
> ```shell
> MERGE_PASSWD=false
> 
> #... 这一行中如果没有shadow，添加上shadow
> all: shadow passwd group hosts services
> ```



照以下步骤操初始化NIS服务数据文件：

1. 执行` /usr/lib64/yp/ypinit -m`（或`/usr/lib/yp/ypinit -m`）

2. 出现`next host to add:`其自动填入当前nis服务器主机名，如需添加其他nis服务器，添加其主机名到下一个`next host to add:`后即可。按下`ctrl`-`d`即可进入下一步配置。

3. `is this correct?`询问时，检查信息，如果无误，按下`y`将生成用户信息资料库。



**在新增/删除账户，或修改账户信息后，需要手动执行以下命令更新nis数据库：**

```shell
make -C /var/yp
```

**如果使用ypch、yppasswdd更新用户shell和密码则无需手动make更新数据库。**



## 从服务器配置

如果配置有从服务器，需要进行本小节设置。

安装住服务器的方法进行安装，建议同时将从服务器可以配置为住服务器的client。

从服务器保留主服务器映射的精确副本，并在主服务器忙于或不可用时代替主服务器应答客户端的查询。



配置从服务器：

1. 将从服务器[配置为客户端](#客户端)

   从服务器也是主服务器的一个客户端。

2. 按照[主服务器配置](#主服务器配置)步骤执行

   Debian/ubuntu系，需要编辑`/etc/defaults/nis`文件，将`NISSERVER=false`（默认值）改为`NISSERVER=slave`。

   ```shell
   sed -i -E -e "/NISSERVER=true/ s/true/false/" /etc/default/nis
   ```

   在[建立帐号资料库](#建立帐号资料库)一步时，将命令中的`-m`改为`-s <master-host>`，master-host为nis主服务器的地址：

   ```shell
   /usr/lib64/yp/ypinit -s mgt01  #mgt01改为实际的nis server
   ```

   该操作将从主服务器获取资料库数据。

  

主服务器NIS数据如果发生变更，需要推送数据给从服务器，使用yppush，示例：

  ```shell
#或push指定资料到指定slave主机 （任意位置执行均可）
yppush -v -h <slave-host> passwd.byuid
  ```

从服务器可执行以下命令获取主服务器的NIS资料库：

```shell
/usr/lib64/yp/ypxfr -h master passwd.byname  #master为服务器
```



### 主从服务器自动同步

为了减少繁琐的推送操作，可在主从服务器数据自动同步，可以考虑在主/从服务器配置周期任务（如crontab或system timer）实现。

 1. 主服务器主动推送：

    周期任务，执行`make -C /var/yp`或`yppush` 向 NIS slave 推送更新信息。

    使用make方式推送，需要确认：

    - 在`/var/yp/Makefile`设置自动推送参数

      ```shell
      NOPUSH=false     #允许在make后自动推送到从服务器 
      #YPPUSH_ARGS =   #被push的slave服务器的nis server监听端口，默认836
      ```

    - 在`/var/yp/ypservers`设置要推送的slave服务器地址列表

      ```shell
      slave_host1
      slave_host1.10g
      slave_host2
      ```

    

 2. 从服务器主动获取：

    **需要NIS master 开启 ypxfrd 服务，以允许 NIS slave 自动从 NIS master 获取更新。**

    ```shell
    systemctl enable --now  ypxfrd
    ```

    周期任务，使用`/usr/lib64/yp/ypxfr`或`/usr/lib64/yp/`下的脚本主动从 NIS master 获取更新，例如crontab内容：

    ```shell
    #/usr/lib64/yp/有数个以ypxfr_开始的脚本可以直接使用
    @hourly         /usr/lib64/yp/ypxfr_1perhour > /tmp/ypxfr_1h.log
    @daily          /usr/lib64/yp/ypxfr_1perday  > /tmp/ypxfr_1d.log
    ```

    或执行`/usr/lib64/yp/ypinit -s master`重新拉取数据亦可。




## 网络和安全限制

### 客户端可访问的资料库

`/etc/ypserv.conf`中可配置允许/禁止访问NIS服务器的网域以及它们可以获取的数据内容。

另`/var/yp/securenets`也可设置nis client白名单）。

 限制指定主机的配置示例：

  ```shell
#Host列为主机信息，可填写主机地址（主机名、IP），可以subnet/netmask写法指定网段
#Domain域名，Map为nis的数据库名称
#Security取值，port仅能使用<1024的端口，deny拒绝，none无限制
# Host           : Domain : Map                  : Security 
#*			         : *      : shadow.byname        : port
#*               : *      : passwd.adjunct.byname: port
127.0.0.1/8      : *      : *                    : none
10.0.0.1/24      : *      : *                    : none
192.168.0.24     : *      : *                    : deny
  ```

  

### 客户端白名单

`/var/yp/securenets`文件用以指定本nis (slave) server响应请求的nis客户端来源（客户端白名单），配置示例：

```shell
#针对一个网段的主机 第一部分为掩码 第二部分为子网（注意！！！）
255.0.0.0   	127.0.0.0
255.255.255.0 192.168.0.0
#针对一个主机
host 172.16.1.111
host 127.0.0.1
```

该文件不存在（安装后默认如此）或内容为空，表示无限制。

注意：

- 默认配置文件一般是允许所有主机访问，如有需要，应当修改规则
- 修改该文件后，必须重启ypserv服务以使其生效。



### 固定端口

NIS服务器是基于RPC服务工作，使用 TCP/UDP 的111端口号和其它的一些动态高位端口。

可为nis各个服务设置固定端口：

- debian中在`/etc/defualt/nis`文件可配置nis服务相关端口。

- rhel：

  - yppasswdd，`/etc/sysconfig/yppasswdd`文件：

    ```shell
    YPPASSWDD_ARGS="--port 1012"
    ```

  - ypserv，`/etc/sysconfig/network`文件：

    ```shell
    YPSERV_ARGS="-p 834"   #ypserv
    YPXFRD_ARGS="-p 835"   #ypxfrd
    ```
  
  - yppush，`/var/yp/Makefile`
  
    ```shell
    YPPUSH_ARGS = "--port 836"
    ```
  
    

也可以查看相关服务的systemd unit文件，里面的`EnvironmentFile`指明了读取的配置文件路径。



## 测试服务端

主服务器上查看ypserv情况

```shell
rpcinfo -p localhost | grep -E '(portmapper|ypserv|fypxfrd)'
rpcinfo -u localhost ypserv  #2
```

如果安装配置无误，第1条查询命令会看到postmapper、 ypserv（该示例中为1011端口）、yppasswdd（该示例中为1012端口）等服务的端口信息。第2条查询命令会看到类似以下信息：

> program 100004 version 1 ready and waiting
> program 100004 version 2 ready and waiting



从服务器可以执行以下命令检查从主服务器同步的账户信息情况。

```shell
rpcinfo -p localhost | grep -E '(portmapper|ypserv|fypxfrd)'
ypcat -h master passwd.byname
```



# 客户端

## 安装和配置

rhel系安装`ypbind` `yp-tools`（可选），启用`ypbind`和`rpcbind`（一般将自行启用）服务并设置开机自启动。

deb系安装`nis`和`yp-tools`（可选），启用`nis`。（debian将ypserv、yppasswdd、ypbind等均合并到nis服务）



- Redhat/centos上，可使用authconfig命令配置：

  ```shell
  #多个server使用逗号分隔
  authconfig --enablenis --nisdomain=<domain-name> --nisserver=<server1,server2> --update
  #authconfig --enablenis --nisdomain=<domain name> --nisserver=server,slave --update
  ```

  或可使用`setup`或` authconfig-tui`（需要`python`）或` authconfig-gtk`（需要安装gtk相关的图形界面工具）完成下列各项的配置，如nis server不止一个，填写server时以逗号分隔多个server。

  

- debian系统

  1. 参看前文服务端中设置nisdomain的方法设置domain。

  2. 确保nis配置`/etc/defualt/nis`中将本主机设置为nis client（默认即是）：
  
     ```shell
     #sed -i -E -e "/NISSERVER=true/ s/true/false/" -e "/NISCLIENT=false/ s/false/true/" /etc/default/nis
     ```
  
     配置文件中`NISCLIENT=true`（默认即是true），如果不作为服务端`NISSERVER=false`（默认即是false）。
  
  参看下文第2步修改`/etc/yp.conf`。
  
  重启nis服务。
  
  



小技巧：在一机多网的条件下（例如每个节点均有两个网络），可以将server节点不同网络的地址均添加为客户端的nis server，当一个网络故障时，另一个网络仍然可为客户端提供服务。



也可以按照以下步骤配置：

1. nis网域设置

   参看[主服务器配置](#主服务器配置)中的设置方法。

2. 编辑`/etc/yp.conf`，添加类似：

   ```shell
   domain domain-name server master  #domainname换成实际的域名 master换成实际的地址
   ypserver server2                  #备用sever写法
   ```

   如果使用了hostname配置server，主机检查nis server的主机名对应地址是否正确，可使用ping测试。

   

3. 编辑`/etc/nsswitch.conf `，在`passwd`、`shadow`和`group`最后添加`nis`（或`nisplus`），类似：

   *一些发行版安装nis组件后已自动添加，无需设置。*

   ```shell
   passwd:  files nis
   shadow:  files nis
   group:  files nis
   ```

   `/etc/nsswitch.conf`用于管理系统中多个配置文件查找的顺序。

4. 系统认证

   - Redhat/CentOS

     编辑` /etc/sysconfig/authconfig`， 修改`USENIS`的值为`yes` 。

   - Debian/Ubuntu

     编辑`/etc/pam.d/common-session `，添加一行：

     ```shell
     session optional        pam_mkhomedir.so skel=/etc/skel umask=077
     ```

5. 可能需要启动或重启nis客户端服务

   ```shell
   systemctl restart ypbind
   ```




## 测试客户端

重启`rpcbind`和`ypbind`服务并设置开机自启动。

- 使用检测工具

  - `yptest`  测试 server 端和 client 端能否正常通讯
  - `ypwhich`   查看资料库映射数据
  - `ypcat`  读取数据库内容 

  测试示例：

  ```shell
  yptest              #显示各项服务启用状况及同步自服务端的用户信息
  ypwhich             #显示服务器主机名
  ypwhich -x          #显示所有服务端与客户端连线共用的资料库
  ypcat -k passwd     #显示所有所有同步的用户密码信息
  ypcat hosts.byname  #查看服务端与客户端共用的hosts资料库内容
  ```

- 如果连接成功，即可在客户端登录在服务端建立的账号。

  ```shell
  su - nis1  #切换到服务端建立的nis1账户
  # 登录成功
  whoami  #检查以下当前用户
  ```

- 检查客户端是否已经同步用户信息

  ```shell
  id <username>
  getent passwd <username>
  ```

  如果用户出现在`getent passwd`中而使用`id`命令提示无用户，则检查`/etc/nsswitch`中是否配置了nis。

  



## 用户管理

root用户添加（useradd）、删除（userdel）、变更用户信息（如修改密码passwd），参照Linux用户管理方式，在NIS管理节点操作即可，对用户信息进行变更后，需要执行`make -C /var/yp`更新数据信息。



也可以使用以下命令更新用户信息，而无需make更新数据（需要开启yppasswdd服务）：

- 修改密码 `yppasswd [用户名]`
- 修改shell  `ypchsh [用户名]`
- 修改finger  `ypchfn [用户名]`

