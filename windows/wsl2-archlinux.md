以下内容中windows命令在powershell或windows terminal（建议，其默认使用powershell）中执行。

# 启用wsl2

在 系统设置--应用和功能--程序和功能--打开或关闭**Windows** 功能，勾选启用：

- 启用于linux的子系统

- 启用hyperv

命令行启用hyper

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
```

家庭版启用hyperv，可创建一个bat文件如hyperv.bat，内容如下：

```bat
pushd "%~dp0"

dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum >hyper-v.txt

for /f %%i in ('findstr /i . hyper-v.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"

del hyper-v.txt

Dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL

Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
```

管理员用户执行上面的bat文件。

可能要重启系统。



# 安装wsl2 archlinux

1. 将wsl作为默认wsl版本：

   ```shell
   wsl --set-default-version 2
   ```

   使用`wsl -l -v`查看当前wsl 版本及linux列表。

   可能提示需要更新其内核组件，根据提示的网址下载内核安装。

2. 下载[ArchWSL2](https://github.com/yuk7/ArchWSL2/releases)，解压目录，这里假设将加压的目录ArchWSL2放到`C:\`目录下，点击目录内的`Arch2.exe`安装。

3. 将`C:\ArchWSL2`加入环境变量方便使用

   搜索path，在 系统属性--环境变量 中编辑 `Path` 行，添加该环境变量。




# arch 基本配置

以下内容在wsl archlinux的shell中执行，根据需要进行一些基本配置：

```shell
#密钥初始化
pacman-key --init
pacman-key --populate archlinux

#修改源，使用China源
curl 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4'|sed  "s/^#//" >/etc/pacman.d/mirrorlist

#更新系统
pacman -Syyu --noconfirm

#root密码
passwd root

#添加archlinuxcn源（可选）
echo '[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch' >> /etc/pacman.conf
pacman -Syy
pacman -S archlinuxcn-keyring --noconfirm

#安装一些软件（可选）
pacman -S --noconfirm vim htop git sudo

#添加一个普通用户（可选）
useradd -m -g wheel user1


#将windows的一些目录与linux共用(可选)
#ln -sf /mnt/c/path/to/Documents ~/
```

## 设置wsl默认登录用户

archlinux的wsl默认使用root用户登录。在wsl装创建了普通用户后，在windows terminal中配置wsl默认登录用户：

```powershell
 Arch config --default-user user1
```



# wsl2硬件资源分配

在用户目录`C:\Users\<username>`下创建`.wslconfig`文件：

```ini
[wsl2]
#kernel=C:\\temp\\myCustomKernel
memory=4GB # 将WSL 2中的VM内存限制为4 GB
processors=2 #使WSL 2 VM使用两个虚拟处理器
```

# wsl2可访问宿主机网络

windows中允许WSL中对网卡`vEthernet (WSL)`（WSL网卡的默认名字）

管理员执行powershell命令

```powershell
#Requires -RunAsAdministrator
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound  -InterfaceAlias "vEthernet (WSL)"  -Action Allo\
```

可编写以下cmd脚本，实现从右键菜单的管理员运行，编写文件wsl-to-host-net.cmd文件，内容为：

```cmd
PowerShell -Command "New-NetFirewallRule -DisplayName 'WSL' -Direction Inbound  -InterfaceAlias 'vEthernet (WSL)'  -Action Allow " > wsl-net-log
```

可使用task scheduler（任务计划程序），创建一个任务，选择最高权限运行（用户需要有管理员权限），实现在登录时触发执行该脚本的操作，实现自动化。
