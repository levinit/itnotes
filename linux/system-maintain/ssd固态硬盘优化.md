固态硬盘优化技巧

[TOC]

# 禁用文件系统日志

一般**不建议**。**明显缺点是非正常卸载分区（即断电后，内核锁定等）会造成数据丢失。**

# 分区对齐

如今各大发行版几乎在分区的时候都用了4k对齐。对齐检查：

```shell
parted /dev/sda
align-check optimal 1 
```
使用图形界面的`gaparted`可以调整对齐。

# TRIM

TRIM支持的文件系统：Ext4、Btrfs、JFS、VFAT，XFS。*VFAT 只有挂载参数为'discard'(而不是fstrim)时才支持 TRIM 。*

TRIM需`utils-linux`包。

可用以下方法检查是否支持trim：

- `lsblk --discard`

  DISC-GRAN (discard granularity) 和 DISC-MAX (discard max bytes) 列非 0 表示该 SSD 支持 TRIM 功能。

- `cat /sys/block/sda/queue/discard_granularity`

  值非0表示支持TRIM。

- `hdparm -I /dev/sda | grep TRIM` （需要安装有hdparm包）

  得到类似信息  *    Data Set Management TRIM supported (limit 1 block)。有几种TRIM支持的规格，因此，输出内容取决于驱动器支持什么。



手动trim，示例：

```shell
fstrim -v /home   #对home分区执行trim
fstrim -v /
```

通过挂载参数`discard`自动trim，示例：

```shell
/dev/sda1  /       ext4   defaults,noatime,discard   0  1
/dev/sda2  /home   ext4   defaults,noatime,discard   0  2
```

使用systemd的系统启用`fstrimer.timer`即可开启每周一次的自动trim任务：

```shell
systemctl enable fstrim.timer
```

# swapiness

将swapiness的值改低（如1到10）会减少内存的交换，从而提升一些系统上的响应度。

```shell
cat /proc/sys/vm/swappiness    #检查swappiness值
sysctl vm.swappiness=5    #临时设置为5
```
为了长久保存设置可新建一个`/etc/sysctl.d/99-sysctl.conf`文件，修改swappiness为5:

```shell
vm.swappiness=5
vm.vfs_cache_pressure=50
```
# 设置频繁读取的分区

## 频繁读取的分区放置于HDD

如单独设置`/var`分区，挂载于HDD上而不是SSD上。

## tmpfs--挂载到内存

使用tmpfs将频繁读取的文件置于内存。

- 内存剩余比例没有少于swappiness规定的百分比时，linux不会去用交换区。
- `df -h`可查看使用tmpfs的情况。

### 修改tpmfs分配大小

如今许多发行版默认对一些文件夹（如`/tmp`、`/dev/shm` ）使用tmpfs，默认tmpffs**大小为物理内存的一半**。

如果遇到默认分配的tmpfs空间不够大，可以可在`/etc/fstab`中指定size。

例如，内存为8g的设备，`/tmp`会分配4g，修改为6g大小，编辑`/etc/fstab`添加（或修改）如下：

```shell
# /tmp tmpfs .default size is half of physical memory size
tmpfs /tmp      tmpfs nodev,nosuid,size=6G          0 0
```

重启后生效。

### 浏览器使用tmpfs存放cache

- firefox

  1. 在地址栏中输入 about:config 进入高级设置页

  2. 新建一个 String 

     name 为 

     > browser.cache.disk.parent_directory

     value为 

     > /dev/shm/firefox

- Chromium（或Chrome）

  找到Chromium程序图标所在位置（一般在`/usr/share/applications/chromium.desktop` ），编辑文件中`Exec`行添加`--disk-cache-dir="/dev/shm/chromium/"`：

  ```shell
  Exec=/usr/bin/chromium --disk-cache-dir="/dev/shm/chromium/"
  ```

  建议复制`/usr/share/applications/chromium.desktop`到当前用户家目录的`~/.local/share/applications/chromium.desktop`，再对其修改：
  
  ```shell
  sudo cp /usr/share/applications/chromium.desktop ~/.local/share/applications/chromium.desktop
  sudo chown $(whoami) ~/.local/share/applications/chromium.desktop
  sed -i '/Exec/c Exec=/usr/bin/chromium --disk-cache-dir="/dev/shm/chromium/"'  ~/.local/share/applications/chromium.desktop
  ```
  
  



另：有 [anything-sync-daemon](https://aur.archlinux.org/packages/anything-sync-daemon/)允许用户将**任意** 目录使用相同的基本逻辑和安全防护措施同步入内存。