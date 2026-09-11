如果忘记了root密码，也没有任何可用的具有sudo权限的用户，可使用以下方法重置密码。

# LiveCD

1. 启动LiveCD

2. mount系统根分区，例如：

   ```shell
   mount /dev/sda2 /mnt
   ```

3. 重置密码，可选择以下方法

   - passwd指定分区挂载点

     ```shell
     #passwd --root <根分区挂载点> 用户名
     passwd --root /mnt root
     ```

   - chroot到根分区挂载点后直接修改

     ```shell
     chroot /mnt
     passwd
     ```

   - 修改根分区挂载目录中的etc/passwd和etc/shadow文件

     以root用户为例

     - 将passwd文件中root行第1个和第2个`:`间内容改成`x`
     - 将shadow文件中root行第1个和第2个`:`间内容删除

4. 卸载并正常重启



# 单用户模式 / 救援模式

### 方法一：RHEL/CentOS 系推荐（rd.break 方式）

1. 在 GRUB 引导界面，按下 <kbd>e</kbd> 编辑启动项。
2. 找到以 `linux` 或 `linux16`（包含 `vmlinuz`）开头的行末尾，添加空格和 `rd.break`。
3. 按下 <kbd>Ctrl</kbd>+<kbd>x</kbd> 开始引导，进入 switch_root 前的 initramfs 紧急 shell。
4. 重新挂载 `/sysroot` 为可读写：
   ```shell
   mount -o remount,rw /sysroot
   chroot /sysroot
   ```
5. 修改密码并触发 SELinux 重新打标：
   ```shell
   passwd root
   touch /.autorelabel
   exit
   exit
   ```

### 方法二：通用 Linux 方式（init=/bin/sh 方式）

1. 在 GRUB 引导行末尾追加 `init=/bin/sh`（切勿写成 `/sysroot/bin/sh`，否则切换真实根文件系统后内核会报 panic 崩溃）。
2. 按下 <kbd>Ctrl</kbd>+<kbd>x</kbd> 启动，直接进入根目录的只读 sh 环境。
3. 重新挂载根目录为可写并修改密码：
   ```shell
   mount -o remount,rw /
   passwd root
   touch /.autorelabel  # 如果开启了 SELinux
   exec /sbin/init      # 或重启机器
   ```