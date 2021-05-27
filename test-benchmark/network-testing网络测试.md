# 网络监控工具

- atop

- iftop

- nethogs

- nload

- [mtr](#mtr)

# 测试工具

## 网络可用性测试

主要用以监测和诊断网络是否连通。

### ping

`ping <host>`

### curl

ping被禁止时可以用curl检查端口的可用性

`curl <host>:<port>`

### telnet

`telnet <host> <port>`

## 路由追踪

### traceroute和tracepath

用于追踪并显示报文从数据源（source）主机到达目的（destination）主机所经过的路由信息，给出网络路径中每一跳（hop）的信息。

traceroute专门用户追踪路由，追踪速度更快；tracepath可以检测MTU值。

另*windows下有tracert*。

```shell
tracepath [-n] z.cn
traceroute z.cn
```

### mtr

mtr是My traceroute的缩写，是一个把ping和traceroute并入一个程序的网络诊断工具。

直接运行`mtr`会进入ncurses编写的实施监测界面。此外还有该工具的其他图形界面前端实现，如mtr-gtk。

```shell
mtr --report -c 10 -n z.cn  #检测z.cn的traceroute
```



## 网络性能测试

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
    - `rc_bw`    RC streaming one way bandwidth
    - `rc_lat`   RC one way latency
    - `rc_bi_bw`    RC streaming two way bandwidth
    - `uc_bw`
    - `uc_lat`
    - `uc_bi_bw`
  - `conf` —— 显示两端主机配置

  



### iperf和netperf

二者均是客户端-服务端模式（C/S client-server），先在服务端开启监听服务，然后客户端向服务端发起连接。

简单示例（更多参数查看帮助）：

- iperf

  - 服务端：`iperf -s `
  - 客户端：`iperf -c <server> `
    - `-t`  持续时间
    - `-i`  间隔时间
    - `-w`  TCP window 大小
    - `-u`  UDP测试
    - `-P`  多线程

  ```shell
  iperf -s [-p port] [-i 2]  #p监听的端口 i报告刷新时间间隔
  iperf -c <server> [-n filesize] [-p port] [-i 2] [-t 10]
  ```

- netperf

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
