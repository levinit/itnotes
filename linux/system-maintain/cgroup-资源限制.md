# 简介

**cgroups (Control Groups)**: Linux内核功能，用于限制、记录和隔离进程组的资源使用。

cgroup可以对不同资源控制器进行限制，如cpu, memory, blkio, devices 等。

版本：

- v1: 传统版本，子系统可独立挂载
- v2: 统一层级，更严格的组织结构

|    特性    |  cgroups v1  |       cgroups v2       |
| :--------: | :----------: | :--------------------: |
|  层级结构  |  多独立层级  |      单一统一层级      |
| 控制器挂载 |  可单独挂载  |      必须统一挂载      |
|  内存控制  | memory子系统 |  memory控制器直接集成  |
|  默认启用  | 旧版系统默认 | 新版系统(如RHEL9+)默认 |

使用建议：

- **新项目优先使用v2**

- **关键服务设置MemoryHigh而非MemoryMax** (允许临时超限)

- **容器环境**通常已自动配置cgroups

- **生产环境**修改前充分测试

> 注意：所有/sys/fs/cgroup下的修改重启后失效，需通过配置文件或systemd持久化



# 临时修改

直接操作 `/sys/fs/cgroup/`下的文件即可。示例：

一些系统默认配置了一些cgroup控制器（如果cpu，memory）可直接修改，参照下面的例子将其中的myapp_v1替换为实际的目录名字（如cpu）即可。

```shell
# 查看已经挂载的cgroup
mount |grep cgroup

#--- cgroups v1 设置命令

# 创建v1控制组
mkdir -p /sys/fs/cgroup/{cpu,memory}/myapp_v1

# CPU限制/修改（如果已经存在某个控制器，例如
echo 100000 > /sys/fs/cgroup/cpu/myapp_v1/cpu.cfs_period_us  # 100ms周期
echo 50000 > /sys/fs/cgroup/cpu/myapp_v1/cpu.cfs_quota_us   # 50ms配额=50%CPU
echo 512 > /sys/fs/cgroup/cpu/myapp_v1/cpu.shares           # CPU权重(默认1024)

# 内存限制设置/修改
echo "500M" > /sys/fs/cgroup/memory/myapp_v1/memory.limit_in_bytes      # 物理内存
echo "1G" > /sys/fs/cgroup/memory/myapp_v1/memory.memsw.limit_in_bytes  # 内存+Swap

# 添加进程到v1组
echo $$ > /sys/fs/cgroup/cpu/myapp_v1/tasks
echo $$ > /sys/fs/cgroup/memory/myapp_v1/tasks

#--- cgroups v2 设置命令

# 创建v2控制组
mkdir /sys/fs/cgroup/myapp_v2

# CPU限制设置/修改 （一般已经存在
echo "50% 100000" > /sys/fs/cgroup/myapp_v2/cpu.max  # 50%CPU(百分比格式)
echo 500 > /sys/fs/cgroup/myapp_v2/cpu.weight        # CPU权重(1-10000)

# 内存限制设置/修改
echo "500M" > /sys/fs/cgroup/myapp_v2/memory.max        # 物理内存
echo "1G" > /sys/fs/cgroup/myapp_v2/memory.swap.max     # Swap内存

# 添加进程到v2组
echo $$ > /sys/fs/cgroup/myapp_v2/cgroup.procs
```



# 持久化配置

## cgroups v1 配置

### 配置文件

```shell
# /etc/cgconfig.d/*.conf 示例
group all_limits {
    cpu {
        cpu.shares = 1024;          # CPU 相对权重（默认值）
        cpu.cfs_quota_us = 400000;  # 限制 4 核（400000us/100000us）
    }
    memory {
        memory.limit_in_bytes = 8G;         # 限制 8GB 内存
        memory.memsw.limit_in_bytes = 10G;  # 限制 8GB RAM + 2GB Swap
    }
}
```



立即加载启用：

```shell
cgconfigparser -l /etc/cgconfig.d/
```



手动挂载：

```shell
mount -t cgroup -o cpu,cpuacct cpu /sys/fs/cgroup/cpu
```



重启服务：

```shell
systemctl restart cgconfig
```

对于RHEL，需要安装有libcgroup-tools



### 用户级限制

配置`/etc/cgrules.conf`，添加类似内容：

```shell
#排除限制的用户或用户组
root:*     *    /
user1:*    *    /
@group1:*  *    /

#其余用户受到前面配置的cgconfig.d/*.conf限制
*:*     cpu,memeory  /all_limits
```

重启服务生效：

```shell
systemctl restart cgred
```



## cgroups v2 配置

### 启用v2

```shell
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
reboot
```



### 使用systemd 集成

```shell
# 服务限制
systemctl set-property httpd.service CPUQuota=50%

# 用户限制
systemctl set-property user-1000.slice MemoryHigh=1.5G
```
