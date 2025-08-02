# 简介

**cgroups (Control Groups)** 是 Linux 内核提供的功能，用于限制、记录和隔离进程组的资源使用。

支持的资源包括：`cpu` ，`memory` ，`io` ，`pids`，`devices`，`hugetlb`，`cpuset`，`net_cls`，`rdma`等。



| 特性       | cgroups v1    | cgroups v2            |
| ---------- | ------------- | --------------------- |
| 层级结构   | 多独立层级    | 单一统一层级          |
| 控制器挂载 | 可单独挂载    | 必须统一挂载          |
| 内存控制   | memory 子系统 | memory 控制器直接集成 |

建议优先使用 cgroups v2



# 临时配置

直接操作 `/sys/fs/cgroup`， 下的控制文件即可，适合用于临时调试或自动化脚本。

```bash
# --- 创建一个新的群组
mkdir /sys/fs/cgroup/myapp

# --- 修改配置
# 设置 CPU 限制
# 格式: "配额(us) 周期(us)", 800000 表示允许 8 核
echo "800000 100000" > /sys/fs/cgroup/myapp/cpu.max

# 设置内存限制
echo 2G > /sys/fs/cgroup/myapp/memory.max

# --- 迁移进程到限制中
# 查看进程所属 cgroup
cat /proc/<PID>/cgroup

# 查看进程所属的slice cgroup （参看下文使用systemd slice配置cgroup的方法）
systemd-cgls | grep user-1000.slice -A 20

# 迁移当前进程到某个cgroup资源限制中
echo $$ > /sys/fs/cgroup/myapp/cgroup.procs

# 迁移进程到指定 slice 
echo <PID> | tee /sys/fs/cgroup/user.slice/user-1000.slice/cgroup.procs
# 如果使用slice cgroup，也可以使用（低版本systemd可能不支持）
systemd-run --slice=user-1000.slice --scope vncserver :3
```



# 使用 systemd slice持久化设置

systemd 作为环境中应用最普遍，推荐通过它管理 cgroup，方法是创建或配置 slice unit。

当用户通过真实登录行为（如 ssh、tty、login、gdm 等）登录系统时，systemd 会自动为该用户创建对应的 `user-<UID>.slice` 和 `session-<ID>.scope`，并在内存中（`/run/systemd/system/`）生成相应的 cgroup 层级结构。

> 使用 `su - <username>` 不会触发slice 创建



如果 `/etc/systemd/system/user-<UID>.slice.d/`（或支持模板的系统使用 `user-@.slice.d/`）中存在资源限制配置，则会一并应用到该用户的所有进程中。



查看slice应用情况：

```shell
# 所有用户的slice都是user.slice的下级
systemctl status user.slice

# 查看特定用户的slice cgroup
systemctl status user-$UID.slice
```



## user-@.slice模板

对于 systemd v240及以上版本，可以创建`/etc/systemd/system/user-@.slice.d`目录，然后在目录中创建slice配置文件`*.conf`，该配置将作为模板，应用于所有用户的 `user-<UID>.slice`。



*如果systemd版本低于v240，则不支持，用户登录只会应用已经存在的`/etc/systemd/system/user-<UID>.slice.d/*.conf`*



配置文件写法参看下文。


## 自定义slice配置

以 UID=1000 的用户为例

1. 创建配置文件

   ```shell
   mkdir -p /etc/systemd/system/user-1000.slice.d          #slice目录，1000替换为具体UID
   touch /etc/systemd/system/user-1000.slice.d/slice.conf  #配置文件
   ```

2. 配置文件内容

   ```ini
   [Slice]
   # 限制为最多使用 4 个 CPU（逻辑核心）
   CPUQuota=400%
   
   # 超过此值前不会被杀死，仅作软限制（警告或限制优先级）
   MemoryHigh=6G
   
   # 达到该值后将触发 OOM 杀死进程，强制硬限制
   MemoryMax=8G
   
   # systemd 旧版本（如 v219）只支持 MemoryLimit，等价于 MemoryMax
   MemoryLimit=12G
   ```

3. 校验配置文件（可选）

   ```shell
    systemd-analyze verify  user-1000.slice #注意是不带.d
   ```

4. 重新加载配置（不会终止进程）

   ```shell
   systemctl daemon-reload
   ```

   > 不要重启 user-1000.slice，否则会杀死其下面的所有子进程。



如果希望限制立即生效给已有进程，可以将其迁移进对应 slice（需要user的slice已经启动）



# 验证限制

## 查看限制信息

```shell
#进程树查看
systemd-cgls

#所有用户的slice都在其下
systemctl status user.slice 

#查看用户slice下的进程树
systemctl status user-<UID>.slice
systemctl cat user-<UID>.slice
#不过查看cgroup文件系统最为准确!

#查看指定进程是否在某个cgroup中
cat /proc/$pid/cgroup
```



## 压力测试检查

可使用stress等工具进行压力测试验证限制是否生效

```shell
#--- cpu
#--timeout是测试时间(单位:秒)
stress -c 8  --timeout 90               #8 线程cpu密集型任务
#可使用top htop 或ps -u <username> -o %cpu,cmd 等工具查看cpu占用率


#--- memory
#--vm指定进程数量  --vm-bytes指定总内存 给定一个超过设置限定对值
stress --vm 2 --vm-bytes 16G timeout 30 #16G内存占用的任务
#可使用top htop 或ps -u <username> -o RSS,cmd 等工具查看物理内存占用率
#可看到实际使用内存占用逐步攀升 到达限制时会触发OOM 使用dmesg可看到最进行类似的日志
#Memory cgroup out of memory: Kill process 36245 (stress)
```

