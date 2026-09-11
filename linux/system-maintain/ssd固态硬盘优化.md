# 现代 Linux 固态硬盘（SSD / NVMe）调优与健康监控

随着闪存控制器性能、磨损均衡算法（Wear Leveling）以及 NVMe 协议的发展，现代 SSD 具有极高的写入寿命（TBW）与低延迟并发能力。早期 Linux 社区流行的部分优化手段（如关闭日志、将缓存强行塞入内存等）在现代硬件下不仅毫无必要，反而会带来数据丢失风险与内存浪费。

本文基于现代 Linux 内核（blk-mq 多队列架构）与 NVMe/SATA 硬件规范，总结兼顾性能、稳定性与寿命的调优实践。

---

## 1. 优化理念：摒弃过时反模式

| 早期优化做法 | 现代评估与危害 | 现代推荐实践 |
| :--- | :--- | :--- |
| **禁用文件系统日志** | **极度危险**。SSD 写入寿命已远超日均写入量，关闭日志会导致异常断电时文件系统元数据损坏崩溃。 | 保持 Ext4/XFS 默认日志开启，确保 ACID 事务完整性。 |
| **将浏览器/系统缓存移至 `/dev/shm`** | 白白占用宝贵的物理内存；且关机或断电时缓存全失，导致下次启动重复网络下载。 | 交由现代 Linux 页缓存（Page Cache）机制自动管理，无需人工干预。 |
| **将频繁写入目录（如 `/var`）迁移至 HDD** | 机械盘寻道极慢，将 `/var` 移至 HDD 会严重拖慢系统启动、包管理和日常日志写入响应。 | 统一放置于高速 SSD，按需通过 `journald.conf` 限制日志最大保留容量。 |

---

## 2. 分区与 4K 对齐检查

固态硬盘的物理擦除块通常为 4KB 的整数倍（如 4KB、8KB 或 16KB）。若分区起始物理扇区未对齐，一次 4KB 的读写操作将跨越两个物理块，导致性能折半并加倍闪存磨损。

现代 Linux 分区工具（`fdisk`、`parted`、`gdisk`）默认均以 1MiB（2048 扇区）为起始边界，已天然实现 4K 对齐。

### 检查对齐状态

使用 `parted` 工具验证对齐：

```shell
# parted <设备名> align-check optimal <分区编号>
sudo parted /dev/nvme0n1 align-check optimal 1
# 输出：1 aligned 即表示完美对齐
```

或者查看扇区起始号：

```shell
sudo fdisk -l /dev/nvme0n1
# 检查 Start 扇区是否能被 8 整除（512 字节扇区场景下 8*512=4096B）
```

---

## 3. TRIM 空间回收机制

TRIM 命令通知固态硬盘主控哪些逻辑块（LBA）已被文件系统释放，主控可在后台垃圾回收（GC）时擦除空闲物理块，避免写入时二次擦除带来的“写入放大”与性能劣化。

### 最佳实践：定期 TRIM（推荐）

使用 systemd 提供的 `fstrim.timer` 每周自动执行一次全盘整理：

```shell
# 查看定时任务状态
systemctl status fstrim.timer

# 启用并立即激活每周 TRIM
sudo systemctl enable --now fstrim.timer

# 如需手动立即触发 TRIM
sudo fstrim -av
```

### 为什么不推荐挂载参数 `discard`（连续 TRIM）？

在 `/etc/fstab` 挂载选项中加上 `discard` 会在**每次删除文件时同步触发 TRIM 请求**。在多并发删除、大规模日志轮转或小文件清理时，同步 TRIM 会阻塞主控 I/O 队列，造成严重的写入延迟抖动（Latency Spike）。因此主流发行版一致推荐使用周期性的 `fstrim.timer`。

---

## 4. I/O 调度器（I/O Schedulers）选型

现代 Linux 内核全面采用 `blk-mq`（多队列块层架构），不同介质应匹配不同调度器以最大化发挥硬件吞吐：

| 介质类型 | 推荐调度器 | 原因说明 |
| :--- | :--- | :--- |
| **NVMe 固态硬盘** | **`none`** | NVMe 原生支持 64K 个硬件队列和命令并发，无需内核软件层做合并重排，`none` 直接直通主控，CPU 开销最低。 |
| **SATA / eMMC SSD** | **`mq-deadline`** | 具备基本的合并与防饥饿保证，兼顾顺序写入吞吐与随机响应。 |
| **机械硬盘 (HDD)** | **`bfq`** | 针对寻道延时优化，提供桌面交互与各进程公平调度。 |

### 检查与临时切换

```shell
# 查看当前调度器（中括号内为正在使用的调度器）
cat /sys/block/nvme0n1/queue/scheduler
# 典型输出：[none] mq-deadline kyber bfq

# 临时切换调度器
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler
```

### 持久化配置：编写 udev 规则

在 `/etc/udev/rules.d/60-ioschedulers.rules` 中添加针对设备类型的自动匹配：

```udev
# 针对 NVMe 固态硬盘使用 none
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"

# 针对 SATA 固态硬盘（非旋转介质 rot==0）使用 mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

# 针对机械硬盘（旋转介质 rot==1）使用 bfq
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
```

---

## 5. 内核内存与脏页回写优化

针对搭载高速 SSD / NVMe 的服务器或高性能主机，合理调节内存换出与回写参数可减少无谓的 I/O 停顿。

编辑 `/etc/sysctl.d/99-ssd-tuning.conf`：

```ini
# 控制内存交换倾向（默认 60）
# 对于配备充足物理内存的 SSD 主机，适度降低此值，优先回收页缓存，减少频繁换出匿名内存
vm.swappiness = 10

# 目录项与 Inode 缓存回收倾向（默认 100）
# 设置为 50 让内核更倾向于保留 VFS 目录缓存，加快高频文件查找速度
vm.vfs_cache_pressure = 50

# 脏页后台异步回写阈值（默认约 10% 内存）
# 高速 NVMe 写入速度极快，适度调低让脏页及早平滑刷盘，避免积攒过多引发瞬间冲刷停顿
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
```

加载配置生效：

```shell
sudo sysctl --system
```

---

## 6. 健康监控与寿命评估

### 针对 NVMe 固态：使用 `nvme-cli`

```shell
sudo apt install -y nvme-cli   # Debian/Ubuntu
sudo dnf install -y nvme-cli   # RHEL/CentOS

# 读取指定 NVMe 控制器的 SMART 健康日志
sudo nvme smart-log /dev/nvme0
```

核心关注字段：
- **`percentage_used`**：已消耗寿命百分比（`0%` 表示新盘，达 `100%` 说明已达到官方质保写入寿命，但仍可工作）；
- **`critical_warning`**：严重警告标记（`0x0` 表示无故障）；
- **`temperature`**：当前工作温度（通常应保持在 70°C 以下）；
- **`data_units_written`**：总写入扇区数（换算 TBW：数值 $\times 512 \times 1000 / 10^{12}$ TB）。

### 针对通用 SATA / NVMe：使用 `smartctl`

```shell
sudo apt install -y smartmontools

# 查看整体健康评定
sudo smartctl -H /dev/nvme0n1
sudo smartctl -H /dev/sda

# 查看详细 SMART 属性
sudo smartctl -A /dev/sda
```
SATA 盘重点观察 `Reallocated_Sector_Ct`（重分配扇区数）与 `Media_Wearout_Indicator`（磨损指示器）。