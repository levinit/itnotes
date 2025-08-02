# 实时查看工具

## htop

彩色、交互式界面，支持鼠标操作

## top

*按下 `1` 可展开所有核心的负载显示*

## mpstat（来自 sysstat）

展示每个核心的详细利用率，包括 user/system/idle 等状态

可用于脚本化采样分析：

```shell
mpstat -P ALL 1
```



# 记录与分析工具

## sar（来自 sysstat）

记录系统资源历史数据（包括 CPU），可分析高峰负载、空闲率变化

```bash
sar -u 1 5 # 每秒采样 5 次 CPU 使用情况
sar -q 1 5 # -q 查看运行队列和负载
sar -P ALL 1 3   # 每个逻辑核的 3 次采样 -P指定cpu，ALL代表全部cpu
sar -q -r -u -n DEV 1 5  # 同时监控CPU、负载、内存、网络
```



## pidstat

显示进程或线程级别的 CPU 使用率，可监控指定 PID 或全体进程

```bash
pidstat -u -p ALL 1
```



## dstat

支持实时显示每个核的 CPU 使用率，可以方便观察热点

```shell
dstat -c -C 0-79  #查看CPU 0-79
pidstat -w 1      #找出高上下文切换进程
```



## 原始数据分析

### /proc/stat
提供系统总的 CPU 时间片信息，可用脚本计算利用率：

```bash
cat /proc/stat
```



读取 `cpu` 行的内容，使用 user、system、idle 时间的变化计算出 CPU 利用率。

伪代码：

```python
def cpu_util(prev, curr):
    prev_idle = prev['idle'] + prev['iowait']
    curr_idle = curr['idle'] + curr['iowait']

    prev_total = sum(prev.values())
    curr_total = sum(curr.values())

    total_delta = curr_total - prev_total
    idle_delta = curr_idle - prev_idle

    usage = (1 - idle_delta / total_delta) * 100
    return usage
```



# 负载与利用率关系

在纯 CPU 密集型任务下，`load average ≈ CPU 总利用率 / 100`

可以使用`uptime`查看负载。



例如，在物理40 核心系统中：

- load = 40 → 约 4000% CPU 利用率（即全部物理核满载）
- load > 40 → 系统出现排队或任务抢核
- 利用率超过 4000%，表示多个任务抢一个物理核，性能下降明显



## 核心数的参考原则

- CPU 密集型任务通常需要独占一个物理核心
- 超线程带来的逻辑线程仅能带来有限性能提升（10~30%）
- HPC 调度器配置时，每个节点最多分配“物理核心数”个 CPU 密集型任务较为合理



## 选择指标的建议

- CPU 密集型任务：优先看 load average，近似反映资源耗尽
- IO 密集型或混合型任务：建议结合 CPU 利用率和 load 一起判断
- 多进程任务：配合 `pidstat` 查看资源分布情况
