# Windows 实用技巧与故障排查指南

本文档收录现代 Windows 10/11 环境下高频实用的系统管理、网络共享、磁盘控制与排错实践。

---

## 1. 软件或管理员程序无法识别网络映射驱动器（Samba/NFS）

### 故障现象
在 Windows 资源管理器中已成功映射网络驱动器（如 `Z:` 盘），普通操作可正常读写；但在以“管理员身份运行”的开发工具、IDE、备份程序或部分第三方软件中，打开文件对话框却找不到该驱动器盘符。

### 原理剖析
Windows 在启用 UAC（用户账户控制）时，用户登录后系统会为当前会话生成**两个独立的访问令牌**：
- **标准受限令牌（Filtered Token）**：资源管理器及常规程序运行于该上下文；
- **提升管理员令牌（Elevated Token）**：右键“以管理员身份运行”的程序运行于该上下文。

默认情况下，网络驱动器映射只注册在标准令牌中，提升令牌无法直接看到。

### 官方标准解决方案（无害共享连接）

通过注册表启用“关联连接（Linked Connections）”，使系统在标准令牌与提升令牌之间自动同步网络映射。

1. 打开管理员 PowerShell 或命令提示符，执行以下命令写入注册表：

   ```powershell
   reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections /t REG_DWORD /d 1 /f
   ```

2. 重启电脑生效。

> [!CAUTION]
> **切勿使用暴力关闭 UAC（`EnableLUA=0`）的过时偏方！**
> 在 Windows 10/11 中直接关闭 `EnableLUA` 会破坏安全沙箱，导致 Windows Terminal、微软应用商店、系统设置组件及大部分 UWP 应用瞬间闪退，并引发系统异常。

---

## 2. 磁盘管理：禁止自动挂载外置磁盘（防误格式化）

在 Linux + Windows 双系统或多系统共用外置存储场景下，Windows 插入包含 Ext4/Btrfs/XFS 格式的磁盘时会由于无法识别而频繁弹出“需要将其格式化后才能使用”的危险提示，极易诱导误操作。

可通过 `diskpart` 禁用全局自动挂载并清理缓存盘符：

1. 以管理员身份运行 `diskpart`：

   ```shell
   diskpart
   ```

2. 执行控制指令：

   ```text
   # 禁用后续接入新磁盘时的自动分配盘符
   automount disable

   # 清理此前已记录但未挂载驱动器的旧盘符缓存
   automount scrub

   # 退出 diskpart
   exit
   ```

*(如后续需要恢复 Windows 自动分配盘符行为，执行 `automount enable` 即可)*

---

## 3. 桌面与文件资源管理器异常排查

### 增删文件后桌面图标不自动刷新
在桌面新建、重命名或删除文件后，界面未立即更新，需手动按 <kbd>F5</kbd> 才能刷新。

- **快速恢复（重启 Explorer 进程）**：

  在 PowerShell 中快速重启资源管理器进程：
  ```powershell
  Stop-Process -Name explorer -Force
  ```

- **注册表修复 UpdateMode**：

  检查注册表项 `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Update`：
  ```powershell
  reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Update" /v UpdateMode /t REG_DWORD /d 0 /f
  ```
  *(值为 `0` 表示自动刷新，`1` 表示手动)*

---

## 4. 现代 Windows 运维高频排错

### A. 系统文件与镜像完整性修复（SFC + DISM）
遇到系统异常崩溃、右键菜单报错或系统更新损坏时，使用官方组合拳进行联机校验与替换：

```powershell
# 1. 联网比对 Windows Update 官方干净组件存储，修复损坏镜像
DISM /Online /Cleanup-Image /RestoreHealth

# 2. 扫描并自动修复当前受保护的系统文件
sfc /scannow
```

### B. 网络栈重置与 DNS 缓存排障
遇到网络连通异常、代理软件残留导致浏览器断网或域名解析死锁时：

```powershell
# 清除本地 DNS 解析缓存
ipconfig /flushdns

# 重置 Winsock 目录协议栈与 TCP/IP 栈
netsh winsock reset
netsh int ip reset

# 释放并重新获取 DHCP 地址
ipconfig /release
ipconfig /renew
```
*(执行完毕后建议重启计算机)*

### C. 端口占用定位与强制终止
查看某个本地端口（如 `8080`）被哪个进程占用并终止：

```powershell
# 1. 查找监听端口对应的进程 PID
netstat -ano | findstr :8080

# 2. 根据查到的 PID 定位程序名称
Get-Process -Id <PID>

# 3. 强制终止该进程
Stop-Process -Id <PID> -Force
```

### D. 开发与编译性能优化（Defender 白名单）
Windows Defender 实时防护会在每次编译器生成临时目标文件（`.o`、`.obj`、`.tmp`）时触发杀毒扫描，严重拖慢 Go / C++ / Rust / 前端构建速度。

针对受信任的代码仓库或编译目录添加排除项：

```powershell
# 以管理员权限执行，为指定工作目录排除实时扫描
Add-MpPreference -ExclusionPath "D:\workspace"
Add-MpPreference -ExclusionPath "C:\Users\<username>\go"

# 查看当前已排除路径
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
```