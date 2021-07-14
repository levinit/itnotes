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

### 安装和启用服务

Redhat/CentOS

  ```shell
  yum install -y ypserv
  systemctl enable --now ypserv yppasswdd
  ```

  

  Debian/Ubuntu

  ```shell
  apt install -y nis          #随后会提示配置相关信息
  systemctl enable --now nis  #一般安装后即会自行enable改服务
  ```

  需要`/etc/defualt/nis`文件中将`NISSERVER`值设置为`true`。

  NIS 服务器同时也当成客户端，参看后文[客户端](#客户端)。

  

### nis网域设定

  临时设置domain：

  ```shell
  domainname -y <domain-name>  #ypdomainname 或 nisdomainname亦可
  ```

Debian/Ubuntu安装nis后会提示输入nisdomain。

  

持久化设置nisdomain：

可选，可以在配置好nis server后，再将nis server也配置为一个client，domainname自然会持久化存储到配置中。

  - debian系列，可以向`/etc/defaultdomain`文件中写入名称。

  - redhat系列，可使用authconfig-tui交互设置，或者使用authconfig （或authconfig-tui、authconfig-gtk等）命令：

    ```shell
    authconfig --nisdomain=hpc --update #nis ypserv没有启动时，该命令会卡住
    ```
    
    或者编辑`/etc/sysconfig/network`，添加网域名称和端口，示例：
    
    ```shell
    NETWORKING=yes
    HOSTNAME=master
    NISDOMAIN=cluster
    #YPSERV_ARGS="-p 1011" #可选 指定运行端口
    ```

  

### 修改配置文件（可选）

根据需要修改配置`/etc/ypserv.conf`，例如配置允许/禁止访问NIS服务器的网域以及它们可以获取的数据内容，默认是允许所有。（另`/var/yp/securenets`也可设置nis client白名单）

 限制指定主机的配置示例：

  ```shell
  #Host列为主机信息，可填写主机地址（主机名、IP），可以subnet/netmask写法指定网段
  #Domain域名，Map为nis的数据库名称
  #Security取值，port仅能使用<1024的端口，deny拒绝，none无限制
  # Host                : Domain : Map                  : Security 
  *			                : *      : shadow.byname        : port
  *			                : *      : passwd.adjunct.byname: port
  127.0.0.1/255.0.0.0   : *      : *                    : none
  10.0.0.1/255.255.255.0: *      : *                    : none
  *                     : *      : *                    : deny
  ```

  

### 建立帐号资料库

该操作会生成nis数据库文件于`/var/yp/`目录下与nisdomain同名的目录中。

照以下步骤操作：

1. 执行` /usr/lib64/yp/ypinit -m`（或`/usr/lib/yp/ypinit -m`）

   

2. 出现`next host to add:`其自动填入当前nis服务器主机名，如需添加其他nis服务器，添加其主机名到下一个`next host to add:`后即可。按下`ctrl`-`d`即可进入下一步配置。

   

3. `is this correct?`询问时，检查信息，如果无误，按下`y`生成用户信息资料库。

 

或者只有一个server是可以执行发送y给ypinit -m命令直接确认，跳过询问

```shell
echo y | /usr/lib64/yp/ypinit -m  #将master替换成实际的主机名
```



提示：**在新增/删除账户，或修改账户信息后，需要手动执行以下命令更新nis数据库：**

  ```shell
  make -C /var/yp
  ```

  其使用make读取`/var/yp/Makefile`生成nis数据库。

  如果使用ypch、yppasswdd更新用户shell和密码则无需手动make更新数据库。





## 从服务器配置

如果配置有从服务器，需要进行本小节设置。

从服务器保留主服务器映射的精确副本，并在主服务器忙于或不可用时代替主服务器应答客户端的查询。

主从服务器的资料自动同步有两种方式：通过 ypxfrd 方式，由 NIS slave 定时从NIS master更新；通过yppush方式，在NIS master更新资料时自动推送给NIS slave。



- 主服务器端

  - 启用 ypxfrd

    ```shell
    systemctl enable --now  ypxfrd
    ```
    
  - `/var/yp/Makefile`设置自动推送参数

    ```shell
    NOPUSH=false     #允许在make后自动推送到从服务器 （默认true）
    #YPPUSH_ARGS =   #被push的slave服务器的nis server监听端口，默认836
    ```

  - `/var/yp/ypservers`设置要推送的slave服务器列表

    ```shell
    slave
    ```

    如果有多个从服务器，每个从服务器单独列一行。

    

  此外如果主服务器要直接将某些特定数据库传给指定备用服务器，示例：

  ```shell
  yppush -h <slave>  netgroup   #例如更新了用户的组
  ```

  

- 从服务器端

  1. 将从服务器[配置为客户端](#客户端)

     对于主服务器来说，从服务器也是主服务器的一个客户端。

  2. 按照[主服务器配置](#主服务器配置)步骤执行，但是在[建立帐号资料库](#建立帐号资料库)一步时，将命令中的`-m`改为`-s master`，master为nis主服务器的地址：
  
     ```shell
     echo y | /usr/lib64/yp/ypinit -s master  #master改为实际的nis server
     ```
  
     该操作将自动从主服务器的`/var/yp/`下与 nis domain同名的目录复制到从服务器的`/var/yp`下。
  
  3. 可选，配置 ypxfrd定时任务
  
     在`/usr/lib64/yp/`（或`/usr/lib/yp/`）目录下有自带的`ypxfr_1perhour`等脚本，可在从节点设置定时任务调用这些脚本主动从主节点更新资料。
  
     例如添加cron任务，执行`crontab -e`添加：
  
     ```shell
     @hourly         ypxfr_1perhour
     @daily          ypxfr_1perday
     5 5 * *  1,3,5  ypxfr_2perday
     ```
  
     
  
  可执行以下命令手动从主服务器取得账户资料库：
  
  ```shell
  /usr/lib64/yp/ypxfr -h master passwd.byname  #master为服务器
  /usr/lib64/yp/ypxfr -h master passwd.byuid
  ```
  
  

## 网络安全配置

- 限制nis client

  `/var/yp/securenets`文件用以指定本nis (slave) server响应请求的nis客户端来源（客户端白名单），配置示例：

  ```shell
  #针对一个网段的主机 第一部分为掩码 第二部分为子网
  255.255.255.0 192.168.0.0
  #针对一个主机
  host 172.16.1.111
  host 127.0.0.1
  ```

  该文件不存在（安装后默认如此）或内容为空，表示无限制。

  注意，修改该文件后，必须重启ypserv服务以使其生效。

  

- 修改nis服务的默认监听端口
  - debian中在`/etc/defualt/nis`文件可配置nis服务相关端口。

  - rhel：

    - yppasswdd，`/etc/sysconfig/yppasswdd`文件：

      ```shell
      YPPASSWDD_ARGS="--port 1012"
      ```

    - ypserv，`/etc/sysconfig/network`文件：

      ```shell
      YPSERV_ARGS="-p 1011"
      ```

      

实际上可以查看相关服务的systemd unit文件，里面的`EnvironmentFile`指明了读取的配置文件路径。



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

## 安装和启用服务

Redhat安装`ypbind` `yp-tools`（可选），启用`ypbind`和`rpcbind`（一般将自行启用）服务并设置开机自启动。

Debian安装`nis`和`yp-tools`，启用`nis`。（debian将ypserv、yppasswdd、ypbind等均合并到nis服务）



## 配置客户端

使用工具配置：

- Redhat/centos上，使用authconfig命令配置：

  ```shell
  #多个server使用逗号分隔
  authconfig --enablenis --nisdomain=<domain-name> --nisserver=<server1,server2> --update
  #authconfig --enablenis --nisdomain=<domain name> --nisserver=server,slave --update
  ```

  或可使用`setup`或` authconfig-tui`（需要`python`）或` authconfig-gtk`（需要安装gtk相关的图形界面工具）完成下列各项的配置，如nis server不止一个，填写server时以逗号分隔多个server。

  

- debian系统可使用`dpkg-reconfigure nis`设置。

  debian的`/etc/defualt/nis`文件将其配置为client（默认）。

  ```shell
  sed -i -E -e "/NISSERVER=true/ s/true/false/" -e "/NISCLIENT=false/ s/false/true/" /etc/default/nis
  ```
  
  参看下文第2步修改`/etc/yp.conf`。
  
  重启nis服务。
  
  



小技巧：在一机多网的条件下（例如每个节点均有两个网络），可以将server节点不同网络的地址均添加为客户端的nis server，当一个网络故障时，另一个网络仍然可为客户端提供服务。



或者按照以下步骤进行以下配置：

1. nis网域设置

   参看[主服务器配置](#主服务器配置)中的设置方法。

2. 编辑`/etc/yp.conf`，添加类似：

   ```shell
   domain domain-name server master  #domainname换成实际的域名 master换成实际的地址
   #ypserver server2                 #其余备用sever写法
   ```
   
3. 编辑`/etc/nsswitch.conf `，在`passwd`、`shadow`和`group`最后添加`nis`（或`nisplus`），类似：

   一些发行版安装nis组件后已自动添加，无需设置。

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

## 在客户端上修改用户信息

client端的用户信息是由server端推送的，需要使用nis提供的工具修改才能通知nisserver更新数据库信息，以作用到所有client节点上：

- 修改密码 `yppasswd`   功能同`passwd`
- 修改shell  `ypchsh`  功能同`chsh`
- 修改finger  `ypchfn`  功能同`chfn`

