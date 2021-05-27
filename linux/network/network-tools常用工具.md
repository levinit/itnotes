# NetworkManager

桌面中可使用GUI前端，终端中可使用nmtui。

## nmcli

```shell
nmcli con show --active
nmcli con mod <con-name> ipv.method manual ipv4.address <ip-addr> ipv4.getway <gateway-addr> ipv4.dns <dns-addr>

nmcli con add type ethernet con-name <name> ifname <interface-name>

#bridge
nmcli con add type bridge con-name TowerBridge ifname TowerBridge
nmcli con add type ethernet con-name br-slave-1 ifname ens3 master TowerBridge
nmcli con modify TowerBridge bridge.stp no

#wifi
nmcli device wifi connect "$SSID" password "$PASSWORD"
nmcli --ask device wifi connect "$SSID"

```





nethogs: 按进程查看流量占用iptraf: 按连接/端口查看流量ifstat: 按设备查看流量ethtool: 诊断工具tcpdump: 抓包工具ss: 连接查看工具其他: dstat, slurm, nload, bmon

atop

iftop

iotop

# ping

常用参数：

- `-i`  指定发包间隔时间
- `-c`  指定发包次数

```shell
ping -c 4 -i 1 z.cn
```

# ip-router

iproute（或iproute2）的相关命令替代net-tools的`ifconfig`、`arp`和`route`等命令。

用法`ip [选项] 对象 {其他命令}`

- 常用选项
  - `-4`或`-6`  网络协议层IPv6或IPv4
  - `-r`  显示主机时，不使用IP地址，而使用主机的域名

- 常用对象（*括号内容前面命令作用一致*）
  - `ip a`（`ip address`的）
  - `ip l`（`ip link`）
  - `ip m`  （`ip maddress`）
  - `ip n`（`ip neigh`，neigh即neighbor，作用同`arp`命令）
  - `ip r`（`ip route`）

```shell
ip a help  #ip a 的帮助
ip -4 -r a
ip neigh  #“邻居”表
```

## ip地址

```shell

```

## 路由

```shell
ip route

```

# ss

替代net-tools的`netstat`

常用选项

- `-n`  不解析服务名称，以数字方式显示；
- `-a`  显示所有的套接字；
- `-l`  显示处于监听状态的套接字；
- `-o`  显示计时器信息；
- `-m`  显示套接字的内存使用情况；
- `-p`  显示使用套接字的进程信息；
- `-i`  显示内部的TCP信息；
- `-4`或`-6` 只显示ipv4或ipv6的套接字；
- `-t`  只显示tcp套接字；
- `-u`  只显示udp套接字；
- `-s`  显示所有socket使用的摘要信息；

```shell
ss -l |grep http  #监听中的http服务
ss -s #Sockets 摘要
ss -tulp4 #ipv4地址中处于监听状态的tcp和udp连接
```

## telnet

telnet使用明文传输，因此使用telnet登陆不安全。

```shell
#测试主机端口是否开启
telnet <地址> <端口>
```

