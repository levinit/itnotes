Samba一种支持[SMB/CIFS](https://zh.wikipedia.org/wiki/%E4%BC%BA%E6%9C%8D%E5%99%A8%E8%A8%8A%E6%81%AF%E5%8D%80%E5%A1%8A)（Server Message Block/Common Internet File System）协议的文件共享工具。

# 服务端

## Windows

### 共享目录

在文件夹的属性中开启共享即可，需要开启windows等共享功能。

或使用命令行共享文件夹：

```powershell
#添加共享   可设置注释
net share <share_name>=<dir-path> /GRANT:用户名,FULL
net share <share_name>=<dir-path> /remark:"share comment."

net share <share_name> /del  #删除共享
net share  #查看已经共享列表
```



### 用户管理

windows系统用户即是samba用户。

在系统设置中管理用户即可。或使用命令行管理：

```powershell
net user 用户名 密码 /add  #添加用户
net localgroup administrators 用户名 /add #加入用户组示例

net user 用户名 /del      #删除用户

net user 用户名 密码 /active  #更新密码
```

## Linux

### 应用安装

安装`samba`，不同发行版可能包名不同，有的发行版将winbind模块拆分单独打包。

启用`smb`和`nmb`服务（或名`smbd`或`nmbd`）。

其他配置：

- selinux: off


- firewall: samba使用445 TCP/UDP端口：

  - nmb   NetBIOS名称服务器
    - TCP 445 ：Microsoft-DS Active Directory、Windows 共享资源（TCP）
    - UDP 445 ：Microsoft-DS SMB 文件共享（UDP）
  - smb   AD和SMB / CIFS文件服务器
    - UDP 137： NetBIOS 命名服务（WINS）
    - UDP 138 ：NetBIOS 数据包
  - winbind   加AD域后提供名称解析服务(用于从NT服务器解析名称)

### 共享目录

主配置文件`/etc/samba/smb.conf`，示例：

```shell
#===globale config===
[global]
   # multi config(smb.conf.host1 smb.conf.host2)
   ;config file = /etc/samba/smb.conf.%m
   
   #windows workgroup or domain
   workgroup = MYGROUP
   netbios name = SAMBA-SERVER @ %h
   server string = Samba Server %v
   ;wins server = 192.168.1.251
   # default is 445
   ;smb ports = 4455
   
   # default guest name is "nobody"
   ;guest account = guest
   # log file
   ;log file = /usr/local/samba/var/log.%m
   # log file maxium size
   max log size = 50

   # for multiple interfaces(user name or addr)
   ;interfaces = eth0
   ;interfaces = 192.168.12.2/24 192.168.13.2/24 

	# allow / deny clients
   ;hosts allow = 192.168.1. 127. 172.17.2.EXCEPT172.17.2.50 192.168.10.*
   ;hosts deny = c01,c02 @students 192.168.1.10 172.17.2.0/16

	# max connections, default is 0 (no limited)
   ;max connections = 0
	
	  printing = cups
    printcap name = cups
    load printers = no
    cups options = raw
    
    ;tunning
    use sendfile = yes
    write raw = yes
    read raw = yes
    max xmit = 65535
    aio read size = 16384
    aio write size = 16384
    enable core files = no

    max open files = 65535
    dead time = 15
    getwd cache = yes

    ;default case = lower
    preserve case = no
    short prserve case = no

#===printers===
[printers]
   comment = All Printers
   path = /var/tmp/samba/printer
   browseable = no
   public = yes
   writable = no
   create mask = 0600
   printable = yes

#===system user home dir===
[homes]
   comment = User Home
   browseable = no
   writable = yes
   inherit acls = yes

#common share dir
[public]
   comment = Public for everyone
   path = /home/public
   public = yes
   writable = no
   printable = no
   ;admin users = @wheel,levin
   ;valid users =
   ;invalid users =
   ;write list = @wheel,levin
   ;create mask = 0664
   ;directory mask = 0775
```
注意：配置文件中，可使用`#`、`!`或`;`**注释整行**，除中括号`[]`配置行所在行外，不可在该行配置内容后使用`#`、`!`或`;`加注释内容，否则启动服务会报错。

samba配置中各项名字意义较为明了，也可参看[配置文件](https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD)。

使用`testparam`命令检测配置文件语法是否正确。

配置中常用变量：

- %S：取代目前的设定项目值（即`[ ]`中的内容）
- %m：客户机的 NetBIOS 主机名
- %M：客户机的 Internet  主机名（hostname）
- %L：服务器 NetBIOS 主机名
- %H：用户的家目录
- %U：目前登入的使用者的名称
- %g：目前登入的使用者的组名
- %h：目前服务器的hostname
- %I：客户机的 IP
- %T：目前的日期与时间
- %v：samba版本号

### 用户管理

samba中使用的账户必须是linux系统中已经存在的账户，但是仍需单独将该系统账户添加到samba数据库中，可设置独立的密码。

samba用户管理主要使用`smbpasswd`命令。

```shell
#-a添加一个samab用户
smbpasswd -a <user>  #添加samba用户并设置密码 交互式
echo -e "<user>\n<passwd>" | smbpasswd -a <user>  #添加用户并读取标准输入内容作为密码

#修改用户密码 可使用-s从stdin读取内容设置密码
smbpasswd <user>  #交互式

#删除samba用户
smbpasswd -x <user>

#启用和禁用用户分别使用-d 和 -e
smbpasswd -d <user>
smbpasswd -e <user>
```

提示，为了安全可以将，可将仅用于挂载samba共享目录的用户禁用shell登录：

```shell
usermod -s /sbin/nologin
```



查看samba用户数据库中的用户：

```shell
pdbedit -L
```



# 客户端

## linux

安装`cifs-utils`和`samba-client`（或名`smbclient` ）

- 挂载

  - 可在支持samba的文件管理器中访问：`smb://samba服务器地址`，访问某个具体共享目录则是`smb://samba服务器地址/目录`。

    注意：如果访问用户家目录，地址后的目录名直接写用户家目录名即可，无需写出全部路径。

  - 命令手动挂载

    ```shell
    mount -t cifs -o username=<user>,password=<password> //<SERVER/sharedir> <mountpoint>
    ```

    其他可用选项（均以逗号`,`分隔）：

    - `uid=<user>`
    - `gid=<group>`
    - `workgroup=<workgroup>`
    - `ip=<serverip>`
    - `iocharset=<utf8>`

    提示：如果挂载提示`write-protected, mounting read-only`，需要安装`cifs-utils`；如果服务端为windows，类似`C$`这类以`$`结尾的共享名在linux客户端上挂载会出错。

  - 自动挂载（在`/etc/fstab`添加）示例：

    ```shell
    //smb-server/share /share cifs username=testuser,password=testpwd 0 0
    ```

- smbclient命令

  ```shell
  #显示可用共享
  smbclient -L <host>
  #显示某个用户的可用共享
  smbclient -L <host> -U <user>
  ```

- smbtree命令：显示共享目录树（不建议再有大量计算机的网络上使用此功能）

  ```shell
  smbtree -b -N
  ```

  - -b (--broadcast) 使用广播模式
  - -N (-no-pass) 不询问密码

## windows

可使用任务计划程序实现自动挂载

- 通过资源管理器管理

  通过`\\samba服务器地址\路径`连接

- 命令行

  示例挂载主机host的share到Z盘
  
  ```shell
  net use Z: \\host\share
  ```
  
  卸载
  
  ```powershell
  net share ShareFiel /del
  ```
  
  