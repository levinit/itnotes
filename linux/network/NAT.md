# 简介

> **网络地址转换**（Network Address Translation，缩写为NAT），也叫做**网络掩蔽**或者**IP掩蔽**（IP masquerading），是一种在IP数据包通过[路由器](https://zh.wikipedia.org/wiki/%E8%B7%AF%E7%94%B1%E5%99%A8)或[防火墙](https://zh.wikipedia.org/wiki/%E9%98%B2%E7%81%AB%E5%A2%99)时重写来源IP地址或目的[IP地址](https://zh.wikipedia.org/wiki/IP%E5%9C%B0%E5%9D%80)的技术。

NAT实现了内部网络中的主机访问外部资源，以及外部网络中主机访问内部网络主机；通过NAT可以隐藏内部私有网络主机，提高内网网络主机的安全性。 

> NAT广泛用于在有多台主机但只通过一个公有IP地址访问因特网的**私有网络**中。因为IPV4地址数量的不足，NAT作为解决[IPv4地址短缺](https://zh.wikipedia.org/wiki/IPv4%E4%BD%8D%E5%9D%80%E6%9E%AF%E7%AB%AD)以避免保留IP地址困难的方案而流行起来。

附：IPv4的3组私有IP地址

- A  10.0.0.0~10.255.255.255.255
- B  172.16.0.0.0~172.31.255.255
- C  192.168.0.0~192.168.255.255

## NAT转换类型

- 静态转换

  私有IP地址转换为固定的共有IP地址——一对一固定映射。

- 动态转换

  私有IP地址转换为随机的公有IP地址——一对一动态映射到可用地址池中的一个。

- 端口转换（PNAT，端口多路复用）

  修改数据包的源端口并进行**端口转换**，私有网络中多台主机**共用一个公有IP地址**——多对一。

# 配置

```bash
外部网络===========[网口1]--NAT服务器--[网口2]----内部网络----内部网络主机
```

NAT服务器负责将内部网络的流量（来自网口2）转换到外部网络（网口1）。

# NAT服务器配置

下文所述为使用端口多路复用方式配置内部网络主机访问外部网络资源的示例。

## IP转发

```shell
#查看开启状态 1为开启 0为关闭
sudo sysctl -n net.ipv4.ip_forward
#或sysctl net.ipv4.ip_forward
#或 cat /proc/sys/net/ipv4/ip_forward

#临时开启（暂时开启，重启后失效）
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

#永久生效（配置须在重启后才被启用）
echo "
net.ipv4.ip_forward=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
" > /sysctl.d/ip_forward.conf
#使用该命令可以立即读取上面增加的配置文件 使配置生效
sysctl --system
```

## 端口转发

可使用firewalld或iptables进行转发

### firewall

- 外部网口：eno1 地址192.168.1.1/24
- 内部网口：eno2 地址172.16.1.1/24

```shell
#1修改接口区域
#这里为了示例中区分方便使用 external和internal区域分别表示访问外网的连接和访问内网的连接，具体区域名以实际情况为准

#1.1 将外部网络网口eno1（网口1）的网络区域设置为external
firewall-cmd --permanent --zone=external --change-interface=eno1

#1.2 将内部网络网口eno2（网口2）的网络区域设置为internal
firewall-cmd --permanent --zone=internal --change-interface=eno2

#2. 为外部网口eno１（网口１）设置地址伪装开启NAT转发
firewall-cmd --permanent  --zone=external --add-masquerade
#关闭NAT时需要去掉masquerade
#firewall-cmd --remove-masquerade

#开放DNS使用的53端口，否则可能导致内网服务器虽然设置正确的DNS，但是依然无法进行域名解析。
# firewall-cmd --zone=public --add-port=53/tcp --permanent


#3. NAT规则（可选）　将来自内网172.16.1.0/24子网的数据转发到外部网口eno1上
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eno1 -j MASQUERADE -s 172.16.1.0/24

#3. 重载配置
firewall-cmd --reload
```

相关命令

```shell
#查看网口的网络区域
firewall-cmd --get-zone-of-interface=eno1
firewall-cmd --get-zone-of-interface=eno2

firewall-cmd --query-masquerade

# 查看所有外部网络区域配置
firewall-cmd --zone=external --list-all

# 只允许特定端口转发
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080
```

### iptables

- 外部网口：eno1 地址192.168.1.1/24
- 内部网口：eno2 地址172.16.1.1/24

```shell
#1. 添加SNAT规则  示例
# 172.16.1.0/24为内网网卡eno2的子网　192.168.1.1为外网网卡eno1的IP
iptables -A POSTROUTING -t nat -o eno2 -j MASQUERADE
#或使用SNAT
#iptables -t nat -A POSTROUTING -s 172.16.1.0/24 -o eno2 -j SNAT --to-source 192.168.1.1

#改变TCP MSS以适应PMTU(Path MTU)
#iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
#或设置固定tcp mss
#通常以太网的mtu为1500，tcp的mss就是1460（1500-20（IP头）-20（tcp头）
# iptables -A FORWARD -p tcp --syn -s 172.6.1.0/24 -j TCPMSS --set-mss 1460

#2. 保存设置的规则
service iptables save            
service iptables restart
```

# NAT客户端配置

修改内部网络中主机的网络连接参数：

- GATEWAY：为NAT服务器的内部网络网口（网口2，eno2）的IP地址
- DNS：同NAT服务器
