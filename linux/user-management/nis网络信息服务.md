[TOC]

# 简介

NIS（ NetworkInformation Service）提供了一个网络黄页（Yellow Pages）的功能。服务端将用户信息加入到资料库中；客户端上用户登录系统时，系统会到NIS服务器上去寻找用户使用的帐号密码信息加以比对，以提供用户登录检验。

在 NIS 环境中， 有三种类型的主机： 主服务器， 从服务器， 以及客户机。nis系列工具主要包括：

- ypserv   ：NIS Server 端工具
- rpcbind  ： 远程过程调用(Remote Procedure Call)协议支持
- ypbind   ：NIS Client 端工具
- yp-tools ：提供 NIS 相关的工具

# 服务端

主要*以centos为例*。

## 安装和启用服务

Redhat/CentOS安装 `ypserv` `rpcbind` ，启用`ypserv` `yppasswdd`并设置自启动。

Debian/Ubuntu安装`nis`。

NIS 服务器同时也当成客户端，参看后文[客户端](#客户端)。

## 配置服务端

- nis网域设定/etc/sysconfig/network（CentOS）

  临时设置nisdomain：

  ```shell
  nisdomainname -y <domain-name>  #ypdomainname
  ```

  Debian/Ubuntu安装nis后会提示输入nisdomain。

  设置永久nisdomain：

  对于debian系列，可以向`/etc/defaultdomain`文件中写入名称。

  对于redhat系列，可使用authconfig-tui交互设置，或者使用authconfig 命令；或者编辑`/etc/sysconfig/network`，添加网域名称和端口，示例：

  ```shell
  NETWORKING=yes
  HOSTNAME=master
  NISDOMAIN=cluster
  #YPSERV_ARGS="-p 1011" #可选 指定运行端口
  ```

- 主配置文件/etc/ypserv.conf

  **可选**。如需配置允许/禁止访问NIS服务器的网域，编辑`etc/ypserv.conf`，添加类似：

  ```shell
  127.0.0.0/255.255.255.0     : * : * : none
  192.168.100.0/255.255.255.0 : * : * : none
  #* : * : * : deny
  ```

- 主机名解析/etc/hosts

  **可选**，配置服务器ip对应的域名解析，添加类似：

  ```shell
  192.168.100.101  master
  192.168.100.102 client1
  ```

- nis客户端密码修改功能

  **可选**，该配置启用可启用NIS 用户端的密码修改功能。

  centos的配置在`/etc/sysconfig/yppasswdd `，编辑该文件，修改配置，添加yppasswd的启用端口：

  ```shell
  YPPASSWDD_ARGS="--port 1012"
  ```

## 建立帐号资料库

- nis主服务器（master）上执行` /usr/lib64/yp/ypinit -m`；如果有nis后备服务器（slave服务器），则其执行`/usr/lib64/yp/ypinit -s`。

  对于Debian/ubuntu，ypinit的位置可能是`/usr/lib/yp/ypinit`

  1. 出现`next host to add:`其自动填入当前nis服务器主机名，如需添加其他nis服务器，添加其主机名到下一个`next host to add:`后即可。按下`ctrl`-`d`即可进入下一步配置。
  2. `is this correct?`询问时，检查信息，如果无误，按下`y`生成用户信息资料库。

  账号相关档案会被转成数据库档案存放到`/var/yp/`目录下与nisdomain同名的目录中。

- 更新用户资料库信息

  ```shell
  make -C /var/yp
  ```

  **在新增账户后，需要执行以上命令更新信息。**

重启`ypserv`服务



## 网络安全配置

nis的默认安全配置文件是`/var/yp/securenets`（主服务器和后备服务器均需要配置该文件），用以指定可接入的nis客户端，如无该文件则任何网络可达的主机都可以成为该nis服务器的nis客户端。

配置示例：

```shell
#针对一个网段的主机
#第一部分为掩码 第二部分为子网
255.255.255.0 192.168.0.0
#针对一个主机
host 172.16.1.111
```



## 后备服务器(slave)配置

slave服务器作为主nis服务器(master)的后备，在主服务器无法提供服务时代替其工作。

- 主服务器端

  - 配置`/var/yp/Makefile`：

    ```shell
    NOPUSH=false
    ```

  - 配置`/var/yp/ypservers`：

    ```shell
    master-node  #主服务器的主机名或地址
    slave-node     #备用服务器的主机名或地址
    ```

  - 启动`ypxfrd`服务并设为自启动

    *备用服务器主动链接上主服务器的`ypxfrd`来更新帐号资料库。*

    

  此外如果主服务器要直接将某些特定数据库传给指定备用服务器：

  ```shell
  yppush -h <slave-node>  passwd.*
  ```

- 备用服务器端

  按照前面所述步骤配置，在[建立帐号资料库](#建立帐号资料库)一步时，执行`/usr/lib64/yp/ypinit -s master-node`（master-node为主服务器主机名或地址。

  可执行以下命令手动从主服务器取得账户资料库：

  ```shell
  /usr/lib64/yp/ypxfr -h master-node passwd.byname  #master-node为服务器
  /usr/lib64/yp/ypxfr -h master-node passwd.byuid
  ```

## 测试服务器

查看启用情况：

```shell
rpcinfo -p localhost | grep -E '(portmapper|yp)' #1
rpcinfo -u localhost ypserv  #2
```

如果安装配置无误，第1条查询命令会看到postmapper、 ypserv（该示例中为1011端口）、yppasswdd（该示例中为1012端口）等服务的端口信息。第2条查询命令会看到类似以下信息：

> program 100004 version 1 ready and waiting
> program 100004 version 2 ready and waiting

备用服务器（slave）可以执行以下命令检查从主服务器（master）同步的账户信息情况。

```shell
 ypcat -h localhost passwd.byname
```

# 客户端

## 安装和启用服务

CentOS安装`ypbind` `yp-tools`，启用`rpcbind`和`ypbind`服务并设置开机自启动。

Debian安装`nis`和`yp-tools`，启用`nis`和`ypbind`。

## 配置客户端

redhat/centos上，可使用`setup`或` authconfig-tui`（需要`python`）或` authconfig-gtk`（需要安装gtk相关的图形界面工具）完成下列各项的配置，或者使用authconfig命令配置：

```shell
authconfig --enablenis --nisdomain=<domain name> --nisserver=<nis server> --update
```

debian系统可使用`dpkgreconfig nis`设置。

或者按照以下步骤进行以下配置：

1. nis网域设置

   redhat系列：

   使用`nisdomainname <domain name>`命令配置，或者编辑`/etc/sysconfig/network`（CentOS），添加：

   ```shell
   NISDOMAIN=cluster  #cluster换成具体的域名
   ```

   或执行：

   ```shell
   sed -i "/NISDOMAIN/c NISDOMAIN=cluster" /etc/sysconfig/network
   ```

   

   debian系列：

   ```shell
   echo cluster > /etc/defaultdomain
   ```

   

2. 主配置文件`/etc/yp.conf`

   编辑`/etc/yp.conf`，添加类似：

   ```shell
   domain domain-name server 192.168.10.1  #domainname换成实际的域名
   ```

3. 服务搜索顺序文件`/etc/nsswitch.conf `

   `/etc/nsswitch.conf`用于管理系统中多个配置文件查找的顺序。

   编辑该文件，在`passwd`、`shadow`和`group`添加`nis`（或`nisplus`），类似：

   ```shell
   passwd:  files nis
   shadow:  files nis
   group:  files nis
   ```

4. 系统认证

   - Redhat/CentOS

     编辑` /etc/sysconfig/authconfig`， 修改`USENIS`的值为`yes` 。

   - Debian/Ubuntu

     编辑`/etc/pam.d/common-session `，添加一行：

     ```shell
     session optional        pam_mkhomedir.so skel=/etc/skel umask=077
     ```

5. 在hosts中添加相关解析（可选）

6. 可能需要启动或重启nis客户端服务



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

- 在nis服务器上修改用户相关参数

  - 修改密码 `yppasswd`   功能同`passwd`
  - 修改shell  `ypchsh`  功能同`chsh`
  - 修改finger  `ypchfn`  功能同`chfn`