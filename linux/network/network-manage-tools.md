# 网络配置管理

## iproute2

### 基本用法

iproute（或iproute2）的相关命令替代net-tools的`ifconfig`、`arp`和`route`等命令。

用法`ip [选项] 对象 {其他命令}` （对象如`link`、`address`等）

- 常用选项

  - `-4`或`-6`  网络协议层IPv6或IPv4
  - `-r`  显示主机时，不使用IP地址，而使用主机的域名
  - `--brief`或`-br`  显示简略信息（必须放在操作的对象之前）
  - `--detail`或`-d` 显示详细信息
  - `--json`或`-j`  以JSON格式输出

- 对象例如：

  - address
  - link
  - maddress
  - neighbor
  - route

  更多对象查看`man ip`

  只要位置正确，这些对象均可以简写，例如`link`写作`l`、`li`均能识别，示例：

  ```shell
  ip a                 #a同address  查看网卡信息，-br简略显示
  ip r                 #同ip route
  ip l s up dev lo   #ip link set up dev lo
  ```



### 链接管理 ip link

网卡链路层的查看和管理，例如启动网卡，关闭网卡。

- 查看

  ```shell
  ip -br l    #查看
  ip link show dev lo  #查看lo网卡链接状态
  ```

  

- 启用、禁用、删除

  ```shell
  #up启用  down禁用
  #ip link set dev ${interface name} up
  #ip link set dev ${interface name} down
  ip link set dev eth0 down
  ip link set dev eth0 up
  
  #删除
  #ip link delete dev ${interface name}
  ```



- 修改信息

  ```shell
  #为网卡添加描述信息
  #ip link set dev ${interface name} alias "${description}"
  
  #网卡重命名
  #ip link set dev ${interface name} alias "${description}"
  
  #修改MAC地址
  ip link set dev ${interface name} address ${address}
  
  #修改MTU
  #ip link set dev ${interface name} mtu ${MTU value}
  ip link set dev tun0 mtu 1480
  ```



此外link还可以管理网桥、bond、VLAN等，具体查看相关文档。



### 地址管理 ip address

网卡信息，主要是地址的查看和管理。

- 查看

  ```shell
  ip -br a      #简略显示所有网卡消息
  ip a show up  #ip a s up  #查看正在运行的网卡的信息
  ip a s eth0   #ip a show eth0
  
  #显示静态地址的网卡信息
  ip address show [dev ${interface}] permanent
  
  #显示动态地址（DHCP）的网卡信息
  ip address show [dev ${interface}] dynamic
  ```

  

- 向网卡添加地址

  ```shell
  #ip address add ${address}/${mask} dev ${interface name}
  ip a add 192.0.2.10/27 dev eth0
  ip a add 2001:db8:1::/48 dev tun10
  
  #添加地址并给网卡增加一个说明
  #ip address add ${address}/${mask} dev ${interface name} label ${interface name}:${description} 
  ip a add 192.0.2.1/24 dev eth0 label eth0:WANaddress
  ```

  如果有多个地址，默认第一个为主地址，

  可使用`sysctl`修改`net.ipv4.conf.default.promote_secondaries`值更改设置（默认值1）。

  

- 从网卡删除地址

  ```shell
  #ip address delete ${address}/${prefix} dev ${interface name}
  
  ip address delete 192.0.2.1/24 dev eth0
  ip address delete 2001:db8::1/64 dev tun1
  
  # Remove all addresses from an interface
  #use ip -4 a flush or ip -6 a flush , only remove ipv4 or ipv6
  ip address flush dev ${interface name}
  ip address flush dev eth1
  ```



### 路由管理 ip route

- 查看

  ```shell
  ip r                   #所有路由信息
  ip route show cached   #路由缓存信息
  
  #查看某个地址的路由
  #ip route show to match ${address}/${mask}
  ip route show to root 10.1.1.4/24
  
  #查看某个子网路由
  #ip route show to exact ${address}/${mask}
  ip route show to exact 10.1.1.0/24
  
  #仅查看内核实际使用的路由
  #ip route get ${address}/${mask}
  ip route get 192.168.0.0/24  #mask不是必须的
  ```

- 管理路由

  ```shell
  #---添加
  #通过网卡添加路由
  #ip route add ${address}/${mask} dev ${interface name}
  ip route add 192.0.2.0/25 dev ens0
  
  #通过网关添加路由  dev关键字变成via
  #ip route add ${address}/${mask} via ${next hop}
  ip route add 10.1.1.111/24 via 10.1.1.1
  ip route add 2001:db8:1::/48 via 2001:db8:1::1
  
  #添加默认路由  在add后面使用 default 关键字即可
  #ip route add default via ${address}/${mask}
  #ip route add default dev ${interface name}
  
  #添加黑洞路由
  #ip route add blackhole ${address}/${mask}
  µip route add blackhole 192.0.2.1/32.
  
  #---修改 与添加路由方法类似，只是使用change/replace替换add
  ip route change 192.168.2.0/24 via 10.0.0.1
  ip route replace 192.0.2.1/27 dev tun0
  
  #---删除
  #ip route delete ${route specifier}
  ip route delete 10.0.1.0/25 via 10.0.0.1
  ip route delete default dev ppp0
  ```

  

## NetworkManager

管理NetworkManager的方式：

- 桌面中可使用GUI前端
- 终端中可使用TUI的nmtui
- `nmcli con edit`可使用交换式编辑

### nmcli

nmcli中许多关键字也能简写（类似iproute2），可使用tab补全。

```shell
nmcli general status  #总体状态 nmcli g s
nmcli device status   #设备状态 nmcli d s

#链接信息
nmcli con                #所有链接 nmcli connection show
nmcli con show --active  #活动的链接 nmcli c s -a

#启动和断开链接
#nmcli dev disconnect iface <interface name>
nmcli dev disconnect iface ens3

#编辑链接
nmcli con edit     #可以启动交互式编辑

#添加链接
nmcli connection add type ethernet  #nmcli c a type ethernet
nmcli con add type ethernet con-name <name> ifname <interface-name>

#修改链接（如果不存在将创建）
nmcli con mod <con-name> ipv.method manual ipv4.address <ip-addr> ipv4.getway <gateway-addr> ipv4.dns <dns-addr>

#wifi连接
SSID=xxx
PASSWD=yyy
nmcli device wifi connect "$SSID" password "$PASSWD"
nmcli --ask device wifi connect "$SSID"
```



# sockets管理

## ss

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
