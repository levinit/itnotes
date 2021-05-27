[TOC]

> **桥接器**（英语：network bridge），又称**网桥，**将[网络](https://zh.wikipedia.org/wiki/%E7%BD%91%E7%BB%9C)的多个[网段](https://zh.wikipedia.org/wiki/%E7%BD%91%E6%AE%B5)在[数据链路层](https://zh.wikipedia.org/wiki/%E6%95%B0%E6%8D%AE%E9%93%BE%E8%B7%AF%E5%B1%82)（[OSI模型](https://zh.wikipedia.org/wiki/OSI%E6%A8%A1%E5%9E%8B)第2层）连接起来（即桥接）。



*示例中，网桥名为`br0` ，有线网卡设备名为`eth0` ，无线网卡设备名为`wlo1`（网卡设备名可使用`ip addr`命令查看）。*

# brctl

需要安装`bridge-utils` 。

- 创建流程：

  1. 创建网桥
  2. 添加一个设备到网桥
  3. 启动网桥
  4. 分配ip地址

  ```shell
  bridge=br0
  interface=eno1
  addr=192.168.10.100/24
  #1. create bridge
  brctl addbr $bridge
  #2. add interface to bridge
  brctl addif $bridge $interface
  #3. start bridge
  ip link set up dev $bridge
  #assign address
  ip addr add dev $bridge $addr
  ```

- 其他常用命令

  bridge-utils的命令格式是`brctl [commonds]` ，更多命令查看`brctl --help` 。

  - 显示当前已存在的网桥`brctl show`

  - 删除网桥`delbr`

    ```shell
    ip link set dev br0 down  #删除网桥前先关闭启动的网桥
    brctl delbr br0  #删除名为br0的网桥
    ```

# ip命令

需要安装`iproute2`。

- 创建网桥

  1. 创建一个网桥并启用
  2. 添加一个设备到网桥
  3. 分配ip地址

  ```shell
  bridge=br0
  interface=eno1
  addr=10.10.10.251/24
  
  #1 create a bridge and start it
  sudo ip link add name $bridge type bridge
  sudo ip link set up dev $bridge
  
  #2 add interface device to bridge
  sudo ip link set dev $interface promisc on
  sudo ip link set dev $interface up
  sudo ip link set dev $interface master $bridge
  
  #3 assign address
  sudo ip addr add dev $bridge $addr
  ip a
  ```

- 显示当前已存在的网桥 `bridge link show`  （ bridge 工具包含在iproute2中）

- 删除网桥

  1. 关闭网口混杂模式
  2. 恢复创建了网桥的网口设置
  3. 删除网桥

  ```shell
  #!/bin/sh
  bridge=br0
  interface=eno1
  addr=10.10.10.251/24
  
  sudo ip link set $interface promisc off
  sudo ip link set $interface down
  sudo ip link set dev $interface nomaster
  sudo ip link delete $bridge type bridge
  ```

注意：创建的网桥在重启系统后就不存在了，可以但创建网桥的命令写成脚本放到/etc/profile.d下令其在系统启动后自动创建。