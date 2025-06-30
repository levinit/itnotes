# 系统

```powershell
shutdow -s -t 0 #立即关机 shutdown
shutdown -r -t 0 #立即重启 reboot
logoff #登出（注销）
sconfig #进入配置界面（命令行）
```



# 环境变量

```powershell
#===CMD
set  var1=value1 #当前shell中有效
setx var2=value2 #写入当前用户的环境变量

#===powershell
ls env:        #查看所有环境变量
$env:username  #输出username的环境变量的值
$env:TMP       #输出TMP变量的值

#当前用户的环境变量
[environment]::GetEnvironmentvariable("Path", "User")
#系统变量
[environment]::GetEnvironmentvariable("Path", "Machine")

#---操作环境变量，在当前shell有效
$env:var3="value3"  #设置环境变量var3值为value3
del env:$var3       #删除环境变量var3
$env:Path="C:\apps;$Path"  #追加变量Path的值

#---操作环境变量，存储到系统中
# 用户变量
# 设置变量
[environment]::SetEnvironmentvariable("变量名", "变量值", "User")
# 追加变量值 依然使用;分隔
[environment]::SetEnvironmentvariable("PATH", "$([environment]::GetEnvironmentvariable("Path", "User"));%GOPATH%\bin", "User")

# 系统变量
[environment]::SetEnvironmentvariable("变量名", "变量值", "Machine")
```



# powershell脚本执行策略

使用管理员打开powershell执行：

```powershell
Set-ExecutionPolicy RemoteSigned
```

module管理：

```shell
# 安装
Install-Module -Name xxx
# 查询已安装
Get-InstalledModule
# 移除
Uninstall-Module -Name xxx
# 搜寻
Find-Module -Name xxx
```



# 文件管理

## 链接

- cmd

  ```cmd
  mklink <option> <link> <src>
  ```

  option：

  - `/D` 创建目录符号链接（默认创建文件符号链接）
  - `/H` 创建硬链接
  - `/J`  创建目录联接

- powershell

  ```powershell
  New-Item -Path <link> -ItemType SymbolicLink -Value <src>
  ```

  

# 查询命令的路径

例如查询reg命令的路径：

- cmd

  ```cmd
  where reg
  ```

  

- powershell

  ```powershell
  Get-Command reg
  ```

  

# 防火墙

```powershell
#查看防火墙状态
netsh advfirewall show allprofiles
#关闭防火墙
netsh advfirewall set allprofiles state off #开启使用on
```



# 端口转发

```powershell
#转发
sc config LanmanServer start= disabled
net stop LanmanServer
sc config iphlpsvc start= auto

#listenaddress不指定则默认127.0.0.1
netsh interface portproxy add v4tov4 listenaddress=<addr> listenport=<port> connectaddress=<smb server addr> connectport=<smb server port>

#查看所有
netsh interface portproxy show all

#删除
netsh interface portproxy delete v4tov4 listenaddress=<listen addr> listenport=<listen port>
```



# 进程管理

- powershell

  ```powershell
  get-process
  get-process explorer.exe  #查询explorer.exe进程
  
  #Get-WmiObject可以获得更详细的信息
  #搜索名字为explorer.exe进程信息
  Get-WmiObject win32_process -Filter "name = 'explorer.exe'"
  
  #搜索名字为explorer.exe进程信息（需要名字准确），并过滤出Name,Handle,CommandLine属性
  Get-WmiObject -Class Win32_process -Filter "name = 'explorer.exe'" | Select-Object -Property Name,Path,ProcessId,CommandLine
  
  #搜索名字包含'%explorer%' 的进程信息，并过滤出Name,Handle,CommandLine属性
  Get-WmiObject -Class Win32_process -Filter "name like '%explorer%'" | Select-Object -Property Name,Path,ProcessId,CommandLine
  ```

  Get-WmiObject查找进程的输出示例：

  > ```powershell
  > Get-WmiObject -Class Win32_process -Filter "name = 'explorer.exe'" | Select-Object -Property Name,Path,ProcessId,CommandLine
  > 
  > Name         Path                    ProcessId CommandLine
  > ----         ----                    --------- -----------
  > explorer.exe C:\Windows\Explorer.EXE      5796 C:\Windows\Explorer.EXE
  > ```



- cmd

  ```cmd
  tasklist
  
  #wmic（win11中将被弃用）
  wmic process
  wmic process | find /i "explorer.exe"  #从进程中查找explorer.exe
  wmic process where "name like '%explorer%'" get processid,commandline
  ```



## 启动和停止

```powershell
#启动进程
start-process explorer.exe
#停止进程
Stop-Process <pid>
Stop-Process -Name "explorer"
Get-Process -Name "explorer" | Stop-Process
```



# 账户管理

- `netplwiz`  用户账户管理程序
- `lusrmgr.msc`  本地用户和组管理程序



## 用户管理

```powershell
#账户策略
#密码长度最小值 0
net accounts /minpwlen:0

#密码最短使用时间 0（默认0 表示可以立即修改密码）
net accounts /minpwage:0

#密码最长使用时间 （unlimited表示密码永不过期）
net accounts /maxpwage:unlimited

#列出用户信息
net user  #所有用户
net user /domain  #当前域的用户
net user $username  #具体某个用户

#用户管理  domain不写时表示管理本地域中的这个用户
#添加用户
net user $username $password /add [/domain]
#不能直接修改用户名（可以在组策略gpedit.msc中修改）
#修改用户密码
net user $username $new_pwd /active
#删除用户
net user $username /del  #delete

#当然 以下的操作可以合并到用户创建的命令中
#禁用和启用账户
net user $username active:yes  #进行则是no
#指定用户家目录
net user $username /homedir:$homeDir
#修改用户的组
net localgroup "power users" $netbios\$username /add
```



## 用户组管理

```shell
#组信息
net localgroup Administrators #查看 Administrators 用户组信息

#组管理类似用户管理
net localgroup $newGroupName /add

#添加用户到组 从组中删除用户
net localgroup Administrators $username /add # 添加到Administrators组
net localgroup Administrators $username /delete # 从 Administrators 用户组删除
```



# 主机信息

```shell
# 修改主机名
Rename-Computer $newHostname

#系统信息
systeminfo
```



# 服务管理

```powershell
#查看启动的服务
net start

#启用/停用服务
net start $serviceName
net stop $serviceName

#停止系统更新服务
net stop 'Windows Update'
```



# 网络共享

```powershell
#查看开启的共享服务
net view  #本地
net view $remoteHost  #远程

#查看远程主机时间
net time \\$remoteHost

#windows中浏览共享的路径写法：   \\主机名或ip\路径
#查看本机的共享
net share
net share $shareName  #某个共享的具体信息

#添加/删本机共享
net share $shareName=$path #添加 shareName是共享展示的名字 path是共享的路径
net share $shareName /del  #删除

#映射远程主机存储到本地
net use h: \\ip\c$  #登陆后映射对方C：到本地为H:
net use h: /del  #删除映射对方到本地的为H:的映射
net use h: \\ip\share  #登陆后映射对方share目录 到本地为S:

net use \\ip\ipc$ /del  #删除IPC链接
```



# 注册表

## reg命令

> ```powershell
> REG Operation [Parameter List]
> 
>   Operation  [ QUERY   | ADD    | DELETE  | COPY    |
>                SAVE    | LOAD   | UNLOAD  | RESTORE |
>                COMPARE | EXPORT | IMPORT  | FLAGS ]
> 
> 返回代码: (除了 REG COMPARE)
> 
>   0 - 成功
>   1 - 失败
> 
> 要得到有关某个操作的帮助，请键入:
>   REG Operation /?
> ```



示例，添加一个自定义的test:// url协议，打开test://开头的的链接会自动调用某个程序

```powershell
APPPATH=/path/to/your/exe_file
reg add HKCU\SOFTWARE\Classes\dc /d "URL:test1" /f
reg add HKCU\SOFTWARE\Classes\dc /v "URL Protocol" /f
reg add HKCU\SOFTWARE\Classes\dc\shell /f
reg add HKCU\SOFTWARE\Classes\dc\shell\open /f
reg add HKCU\SOFTWARE\Classes\dc\shell\open\command /d "$APPPATH -url %1" /f
```



## powershell操作注册表项

```powershell
$APPPATH=/path/to/your/exe_file

# Define the protocol
$Protocol = "test"
# Define the command to be executed when the protocol is clicked
$Command = '"$APPPATH" "-url" "%1"'
# Create the registry key for the protocol
New-Item -Path "HKCU:\Software\Classes" -Name $Protocol -ItemType Directory

# Set the default value of the key to "URL:dc"
Set-ItemProperty -Path "HKCU:\Software\Classes\$Protocol" -Name "(Default)" -Value "URL:dc"

# Create the "URL Protocol" value
New-ItemProperty -Path "HKCU:\Software\Classes\$Protocol" -Name "URL Protocol" -Value "" -PropertyType String

# Create the "shell" key
New-Item -Path "HKCU:\Software\Classes\$Protocol" -Name "shell" -ItemType Directory
New-Item -Path "HKCU:\Software\Classes\$Protocol\shell" -Name "open" -ItemType Directory
New-ItemProperty -Path "HKCU:\Software\Classes\$Protocol\shell\open" -Name "command" -Value $Command -PropertyType String
```



# CA证书安装

```powershell
#使用Import-Certificate
Import-Certificate -FilePath .\ca.crt -CertStoreLocation "Cert:\CurrentUser\Root"

#使用certutils工具
certutil.exe -user -addstore "Root" .\ca.crt

# Refresh the certificate store
#Update-StoreCertificate -UseWinRM
```



# 常用系统服务

- MSConfig------系统配置实用程序
- regedit------注册表编辑器
- notepad------打开记事本
- calc------计算器
- mstsc------远程桌面连接
- services.msc------系统服务
- gpedit.msc------组策略
- explorer------资源管理器
- chkdsk.exe------Chkdsk磁盘检查
- dcomcnfg------系统组件服务
- devmgmt.msc------设备管理器
- cleanmgr------垃圾整理
- compmgmt.msc------计算机管理
- secpol.msc------本地安全策略
- netstat -an------(TC)命令检查接口
- taskmgr------任务管理器
- mmc------控制台
- lusrmgr.msc------本机用户和组
- dvdplay------DVD播放器
- diskmgmt.msc------磁盘管理实用程序
- dxdiag------检查DirectX信息
- perfmon.msc------计算机性能检测程序
- winver------检测Windows版本
- write------写字板
- wiaacmgr------扫描仪和照相机向导
- mspaint------画图板
- magnify------放大镜实用程序
- utilman------辅助工具管理器
- osk------屏幕键盘
- odbcad32------ODBC数据源管理器
- Sndvol------音量控制程序
- sfc.exe------系统文件检查器
- sfc /scannow------Windows文件保护
- eventvwr------事件查看器
