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

启用`smb`（或名`smbd`，用于文件和打印共享）和`nmb`服务（或名`nmbd`，用于网络发现，可以不开启）

其他配置：

- selinux：关闭


- firewall

  客户端主要使用smb的445 TCP进行文件共享，如果需samba服务被自动网络发现，还需要开启nmb相关端口。
  
  - smb   AD和SMB / CIFS文件服务器
    - TCP 139：文件和打印共享，用于早期版本的SMB协议通信
    - TCP 445 ：文件和打印共享，还用于windows的Microsoft-DS Active Directory服务、文件共享和群组策略管理等
  - nmb   NetBIOS名称服务器
    - UDP 137： NetBIOS 名称服务
    - UDP 138 ：NetBIOS 数据报服务
  - winbind   加AD域后提供名称解析服务(用于从NT服务器解析名称)
    - TCP 389：LDAP目录服务
  - swat 网页管理Samb
    - TCP 901



### 配置文件

主配置文件`/etc/samba/smb.conf`，示例：

```ini
;===globale config===
[global]
; multi config(smb.conf.host1 smb.conf.host2)
;config file = /etc/samba/smb.conf.%m

;---server config
netbios name = SAMBA-SERVER
server string = Samba Server %v
workgroup = MYGROUP
;wins server = 192.168.1.251
;smb ports = 4455  ;default is 445

;---compatible with macos
fruit:nfs_aces = no
fruit:zero_file_id = yes
fruit:metadata = stream
fruit:encoding = native
vfs objects = catia fruit streams_xattr

;---security config
;security = user ;default is user, domain,server,share,user
;passdb backend = tdbsam ;or ldapsam
idmap config * : backend = tdb
map to guest = bad user
server min protocol = SMB3_11
ntlm auth = No
lanman auth = no
restrict anonymous = 2
;guest account = nobody  ; default guest name is "nobody"
;guest account = guest

;---log file
;log file = /var/log/samba/log.%m
max log size = 50
;loglevel = 0 ;0 means close

;---listen specified interfaces
;bind interfaces only = yes
;interfaces = eth0 eth1
;interfaces = 192.168.12.2/24 192.168.13.2/24 

;---allow / deny clients
;hosts allow = 192.168.1. 127. 172.17.2.EXCEPT172.17.2.50 192.168.10.*
;hosts deny = c01,c02 @students 192.168.1.10 172.17.2.0/16

;max connections = 0 ;default is 0 (no limited)

;---upper and lower case
case sensitive = yes
;preserve case = yes        ;default is yes
;short preserve case = yes  ;default is yes
;default case = lower       ;default is lower

;---link file support in *nix （！注意允许软链接可能有逃逸风险！）
allow insecure wide links = no
wide links = no
;follow symlinks = yes  ;default is yes

;---file permission
inherit acls = Yes 
inherit owner = Yes
inherit permissions = Yes

;idmap
;idmap backend = ldap:ldap://ldap-server.quenya.org:636

;---tunning
use sendfile = yes
max xmit = 65535
aio read size = 16384
aio write size = 16384
create mask = 0664
max open files = 102400 ;default 65535
;dead time = 30  ;default 15 mins
;enable core files = no
;map archive = no

;===printers===
[printers]
comment = All Printers
;printing = cups   ;default is cups
printcap name = cups
load printers = no
cups options = raw
path = /var/tmp/samba/printer
;browseable = no
guest ok = yes  ;default is no, whether to allow anonymous access
;public = yes    ;default is no, same as guest ok
create mask = 0600
printable = yes

;===system user home dir===
[homes]
comment = %U Home in %L
valid users = %S ;or likes this: path = /home/%S
browseable = No  ;default is yes, whether to be discovered
readonly = no    ;default is yes
;writable = yes   ;opposite of readonly

;common share dir
[public]
comment = Public for everyone
path = /home/public
read only = yes ;default is no
guest ok = yes  ;default is no, whether to allow anonymous access

[project]
path = /share/proj
create mask = 0664
directory mask = 2755
force create mode = 0644
force directory mode = 2755
;admin users = @wheel
;valid users =
;invalid users =
write list = @wheel @admin
;create mask = 0664
;directory mask = 0775
;files and directories that are neither visible nor accessible.
;veto files = /*.exe/*.com/*.dll/*.bat/*.vbs/*.tmp/*.mp3/*.avi/*.mp4/*.wmv/*.wma/
```
*配置项中，布尔值可以使用true/yes 和 false/no，任意字母大小写均可。*

使用`testparm`命令检测配置文件语法是否正确，如果正确，该命令会dump出所有生效的行，其中配置的值和默认值一致的行会被消除，一些配置行还会被优化，例如：

- `writeable = yes`行会被替换为等效的 `read only = no` （默认不可写）
- `public = yes` 会被替换为 `guest ok = yes`

注意：配置文件中，可使用`#`、`!`或`;`**注释整行**，除中括号`[]`配置行所在行外，不可在该行配置内容后使用`#`、`!`或`;`加注释内容，否则启动服务会报错。

*linux共享给windows时，windows上用户可能没有读写权限（用户映射问题），可以将目录的权限设置为777，新建文件和目录的权限设置为0777，但是该权限过于宽泛，可以考虑在共享目录上层再加一层目录，上层目录只有所有者用户可以访问。*



samba配置中各项名字意义较为明了，也可参看[配置文件](https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD)。

配置中常用变量：

- `%S`：当前服务名（取代目前的设定项目值，即`[ ]`中的内容）
- `%P`：当前服务的根目录
- `%m`：客户机的 NetBIOS 主机名
- `%M`：客户机的 Internet  主机名（hostname）
- `%L`：服务器 NetBIOS 主机名
- `%N`：NIS服务器名
- `%p`：NIS服务的Home目录
- `%I`：客户机的 IP
- `%H`：当前服务的用户的家目录
- `%u`： 当前服务的用户名
- `%U`：当前会话（登入的使用者）的用户名
- `%g`：当用户的主工作组
- `%G`：当前会话（登入的使用者）的主工作组
- `%h`：当前服务器的主机名
- `%T`：当前的日期与时间
- `%v`：samba版本号



### 用户管理

samba中使用的账户必须是linux系统中已经存在的账户，但是仍需单独将该系统账户添加到samba数据库中，可设置独立的密码。

查看samba用户数据库中的用户：

```shell
pdbedit -L
```



samba用户管理主要使用`smbpasswd`或`pdbedit`命令。

```shell
#-a添加一个samab用户
smbpasswd -a <user>  #添加samba用户并设置密码 交互式

#修改用户密码 可使用-s从stdin读取内容设置密码
smbpasswd <user>  #交互式

#非交互式
user=abc
new_pwd=123456
echo -e "$new_pwd\n$new_pwd" | smbpasswd -a $user  #添加用户并读取标准输入内容作为密码

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



# 客户端

## Linux

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

## Windows

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
  

如果服务端没有使用默认的445端口，windows客户端可以使用端口转发，将445端口转发到指定smb服务地址的端口：

```powershell
sc config LanmanServer start= disabled
net stop LanmanServer
sc config iphlpsvc start= auto
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=445 connectaddress=<smb server addr> connectport=<smb server port>

netsh interface portproxy show all

#删除
#netsh interface portproxy delete v4tov4 listenaddress=<listen addr> listenport=<listen port>
```

然后连接时将smb服务器地址改成监听的listenaddress（不指定时就是127.0.0.1）即可访问。