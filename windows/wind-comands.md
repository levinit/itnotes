以`$`开头的字段表示其为一个自定的内容，例如`$username`表示要实际操作的用户名字，例如`Administrator`。

以`[]`包含表示其为一个可选内容，例如`net user test test /add [/domain]`的`[\domain]`表示新建用户要加入的域（如果不些表示加入本地域）。

# powershell
powershell不能执行脚本。使用管理员打开powershell执行：
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


# 系统

```powershell
shutdow -s -t 0 #立即关机 shutdown
shutdown -r -t 0 #立即重启 reboot
logoff #登出（注销）
sconfig #进入配置界面（命令行）
```



# 防火墙

Firewall.cpl

```powershell
#查看防火墙状态
netsh advfirewall show allprofiles
#关闭防火墙
netsh advfirewall set allprofiles state off #开启使用on
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
