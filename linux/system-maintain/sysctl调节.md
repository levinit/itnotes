sysctl用于调节运行时的内核参数。

> configure kernel parameters at runtime

# systctl使用

参看其帮助文件。

```shell
sysctl [options] [variable[=value] ...]
```

常用：

- `-a`  查看所有参数
- `p <file>`  从文件中读取参数值（并设置）
- `-w`  设置参数的值
- `-n`  仅查看参数的值
- `-N`  仅查看参数名
- `-e`  忽略未知参数错误
- `参数名=值`  设置参数的值

```shell
#查看所有参数
sysctl -a
#查看指定参数
sysctl net.ipv4.ip_forward  #net.ipv4.ip_forward = 0
sysctl net.ipv4.ip_forward -n #只输出参数值 不输出参数名

#临时设置参数值 仅在本次系统运行中生效
sysctl -w net.ipv4.ip_forward=1
echo 1 > /proc/sys/net/ipv4/ip_forward

#读取配置文件中设置的值并应用
sysctl -p <path/to/xxx.conf> #如不指定文件则读取/etc/sysctl.conf
sysctl -p  /etc/sysctl.d/*.conf
sysctl --system   #读取所有配置文件
```

将配置内容写到`/etc/sysctl.d/`目录下的`.conf`文件中，配置内容将在下次启动后生效。

警告：`.conf`文件中的错误的配置可能造成系统无法启动。修改文件后，可使用`sysctl -p`读取该文件，测试设置是否正常。

# 常用调节参数

参数值如果是0或1，则1表示启用，0表示关闭。

## 内核kernel

### 调度策略

- `kernel.sched_migration_cost_ns`  值为时间，单位纳秒

  调度器针对桌面环境优化，桌面环境下，快速响应比整体效率重要，不注重桌面（甚至不使用桌面）响应速度的服务器，可增加任务切换的响应间隔时间以提升效率。

  在一些web服务器和数据库服务器上，可调高该值，例如500000。

- `kernel.sched_autogroup_enabled`  值为0或1

  有些服务器（尤其是postgres），该参数值设置为0可提高性能。

## 网络net

- `net.ipv4.ip_forward`  值为0或1 设置为1开启网络转发（如配置NAT服务器）。

- 网络缓存

  - `net.core.rmem_max`
  - `net.core.wmem_max`
  - `net.ipv4.tcp_wmem`
  - `net.ipv4.tcp_rmem`
  - `net.ipv4.tcp_max_syn_backlog`


## 虚拟内存vm

- `vm.swappiness`  值为0-100，表示当内存剩余百分之多少时开始使用swap。