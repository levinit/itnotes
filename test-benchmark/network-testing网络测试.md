# 网络监控工具

- atop

- iftop

- nethogs

- nload

- [mtr](#mtr)

# 测试工具

## 网络可用性测试

主要用以监测和诊断网络是否连通，端口是否可达。

### ping回显测试

ping使用ICMP（因特网控制报文协议）测试目标地址是否可达

```shell
#ping [option] <addr>
ping 1.1.1.1
ping z.cn
ping -c 4 localhost  #-c count发送指定次数的数据包
```

注意：ping无响应，也可能是ICMP协议被防火墙过滤，应当采用其他方式测试佐证。



### curl、telnet检查端口

```shell
#curl addr:port
curl localhost:22

#telnet addr port 
telnet localhost 22
```



### nmap扫描主机信息

```shell
#nmap [option] addr
nmap localhost      #获取指定主机的基本信息，快速扫描并列出未关闭的端口
nmap -O 192.168.1.1 #同上，同时获取其mac并猜测其操作系统
```



## 路由追踪

### traceroute和tracepath

用于追踪并显示报文从数据源（source）主机到达目的（destination）主机所经过的路由信息，给出网络路径中每一跳（hop）的信息。

traceroute专门用户追踪路由，追踪速度更快；tracepath可以检测MTU值。

另windows下有tracert。

```shell
tracepath -n z.cn
traceroute z.cn
```



### mtr

mtr是My traceroute的缩写，是一个把ping和traceroute并入一个程序的网络诊断工具。

直接运行`mtr`会进入ncurses编写的实施监测界面。此外还有该工具的其他图形界面前端实现，如mtr-gtk。

```shell
mtr --report -c 10 -n z.cn  #检测z.cn的traceroute
```



## 网络性能测试

infiniband网卡在ib模式下（`ibstat`可看到Link layer为Infiniband）下的IPoIBTCP/UDP性能大打折扣，如欲获验证IB网卡的TCP/UDP性能，可将网卡模式调整为Ethernet再测试。参看[IB网卡调整为以太网模式](#IB网卡调整为以太网模式)



### qperf

qperf测试两个节点之间的带宽（bandwidth）和延迟（latency），除了测试 TCP/IP 协议的性能指标，还可以测试 RDMA 传输性能指标。

- 服务端

  ```shell
  qperf
  ```

- 客户端

  ```shell
  qperf <server> [option] <TESTS>  #<TESTS>为具体要测试的指标
  ```

  `OPTIONS` 常用选项：

  - `--time`或`-t`   测试持续的时间，默认为 2s

  - `--msg_size`或`-m`   设置报文的大小，默认测带宽是为 64KB，测延迟是为 1B

  - `--listen_port`或`-lp`   设置与服务端建立连接的端口号，默认为 19765

  - `--verbose`或`-v`    显示详细信息

  - `--use_bits_per_sec`或`-ub`  使用bit而非Bytes，如显示为Gb而不是GB

  - `--unify_units`或`-uu`    使用bytes为显示单位，例如显示为1024bytes而非1KB

    

  `TESTS`可为一个或多个测试指标，测试指标列表可使用`man qperf`详细了解，常用指标如：

  - socket Based
    - `tcp_bw`    TCP流带宽
    - `tcp_lat`    TCP流延迟
    - `udp_bw`    UDP流带宽
    - `udp_lat`    UDP流延迟
    
  - rdma Send/Receive
    
    IB的四种基本服务类型
    
    |                | 可靠reliable           | 不可靠unreliable         |
    | -------------- | ---------------------- | ------------------------ |
    | 连接connection | RC reliable connection | UC unreliable connection |
    | 数据报datagram | RD reliable datagram   | UD unreliable datagram   |
    
    每种类型均有bw（带宽）、lat（延迟）和bi_bw（双向带宽）等测试。
    
    - rc    reliable connected  以rc为例
      
      - `rc_bw`    RC() streaming one way bandwidth
      - `rc_lat`   RC one way latency
      - `rc_bi_bw`    RC streaming two way bandwidth
      - `rc_rdma_read_bw`
      - `rc_rdma_read_lat`
      - `rc_rdma_write_bw`
      - `rc_rdma_write_lat`
      
    - ud    unreliable datagram
    
    - uc    unreliable connection
    
      
    
  - `conf` —— 显示两端主机配置
  
  

### iperf

iperf

- 服务端：`iperf -s `
- 客户端：`iperf -c <server> `
  - `-t`  持续时间
  - `-i`  间隔时间
  - `-w`  TCP window 大小 ，如`256k`
  - `-u`  UDP测试
  - `-P`  多线程

```shell
iperf -s [-p port] [-i 2]  #p监听的端口 i报告刷新时间间隔
iperf -c <server> [-n filesize] [-p port] [-i 2] [-t 10]
```

### netperf

- 服务端：`netserver `
- 客户端：`netperf -H <server>`

``` shell
netserver [-p port] [-L localip]  #p端口 L本地ip
netperf -H <server> [-p port] [-m send_data_size] [-l total_time] #m发送数据大小  l测试总时间
```



### infiniband测试

确保一台服务器已经开启opensmd服务，所有服务器启用了openibd服务，使用`ibstat`查看ib卡是否已经就绪，节点互相可ping或ibping通信。可配置IPoIB以及其对应的主机名解析以方便使用。

- ibping 一般附带在Infiniband套件中，比通常的Ping功能更多。

  - 服务端 `ibping -S`
    获取服务端的`port_lid`

    ```shell
    ibv_devinfo
    #port_lid=$(ibv_devinfo|grep port_lid|grep -oE [0-9]+)
    ```
    
  - 客户端 `ibping -L <server port_lid>`


- 查看ib信息

  - `ibnodes`  同一网络中的节点信息
  - `ibstat`或`ibstatus`  基本信息和状态
  - `ibv_devices`  ib卡GUID信息

- 带宽和延迟测试

  ```shell
  #带宽
  ib_send_bw
  ib_write_bw
  ib_read_bw
  ib_atomic_bw
  #延迟
  ib_send_lat
  ib_write_lat
  ib_read_lat
  ib_atomic_lat
  ```

  以`ib_send_bw`为例：

  - 服务端：

    ```shell
    ib_send_bw
    #ib_send_bw -a -c UD -d mlx5_0 -i 2
    ```

    - `-c`  连接方式（可选） 
    - `-d` 指定设备(可选，多个ib卡时使用)
    - `-i` 端口（可选，多个端口连接且需要测试指定端口时使用）

  - 客户端：

    ```shell
    ib_send_bw <server>   #<server>为服务端地址
    ```



### IB网卡调整为以太网模式

获取mst device信息：

```shell
#如果mst status 提示module not loaded 先加载模块
modprobe mst_pci mst_pciconf
mst restart 
mst status
```

输出信息`MST devices`行下方有类似`/dev/mst/mt4119_pciconf0`信息，即为mst设备，

使用mlxconfig 修改模式：

```shell
#其中mt4119_pciconf0替换成mst status中看到的实际的device信息
echo y | mlxconfig -d /dev/mst/mt4119_pciconf0 set LINK_TYPE_P1=2  #1为ib模式
```

执行以下命令重启driver以生效：

```shell
echo y | mlxfwreset --device /dev/mst/mt4119_pciconf0 reset
```

查看link_layer：

```shell
ibstat
```

