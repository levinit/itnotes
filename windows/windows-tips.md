

# 启用gpedit

```cmd
@echo off

pushd "%~dp0"

dir /b C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt

dir /b C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt

for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"C:\Windows\servicing\Packages\%%i"

pause
```



# 禁止windows挂载某个硬盘

例如Linux+Windows双系统时，禁止Windows挂载文件系统为ext4的外置硬盘，避免因windows无法识别ext4而提示格式化硬盘，用户因此不慎格式化该硬盘。

1. 以管理员身份运行diskpar工具

2. 禁止自动挂

   ```shell
   automount disable
   #恢复 automount enable
   automount scrub  #删除此前连接的磁盘的驱动器号
   ```



# 问题

## 桌面增删文件后不自动刷新

桌面增删文件后不自动刷新，例如在桌面删除某个文件到回收站或者从回收站恢复文件，但在桌面上文件图标无变化）。

解决方法：修改注册表

1. 击“开始→运行”，在对话框中输入“regedit”启动注册表编辑器，展开`HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Update`

2. 在右面找到`UpdateMode`的`DWORD`值，用鼠标双击`UpdateMode`在出现的窗口中将其值修改为`0`。（值`0`为自动刷新，`1`为手动刷新）

   如果没有`UpdateMode`，则自行在`Control`下新建一个`updateMode`，添加`DWORD32`，值为`0`。



## 某些软件无法发现挂载的网络存储

windows挂载网络存储并映射到某个盘符，虽然在资源管理器里面能够看到并打开这个盘符，但是某些软件可能找不到这个盘符号。

​	例如在windows中挂载了smaba服务器的share文件夹到s盘，在某软件中想使用s盘中的文件，但是却找不到s盘。

解决方法：

- 关闭UAC
  1. 打开注册表（regedit），定位到`HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System`。
  1. 找到`EnableLUA` ，将`Value data`的值改成`0`。
  1. （如果还不能找到，再）重启系统。