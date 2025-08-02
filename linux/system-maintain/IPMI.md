IPMI是智能型平台管理接口（Intelligent Platform Management Interface）是管理基于 Intel结构的企业系统中所使用的外围设备采用的一种工业标准。

> IPMI 信息通过基板管理控制器 (BMC)（位于 IPMI 规格的硬件组件上）进行交流。使用低级硬件智能管理而不使用操作系统进行管理。



安装`ipmitool`工具，重启后会自动加载ipmi相关模块，或者手动加载相关模块：

```shell
modprobe ipmi_watchdog
modprobe ipmi_poweroff
modprobe ipmi_devintf
modprobe ipmi_msghandler
modprobe ipmi_si   
```

加载后即可使用ipmitool命令，例如获取硬件信息

```shell
ipmitool sdr
```

# IMPI远程管理配置

1. 确在BIOS中已经启用IPMI over LAN功能。

2. 设置impi网络参数

3. 假如该设备目前IP为192.168.1.10，网关为192.168.1.1，则为其配置一个该网段中未被分配使用的IP，示例：

   ```shell
    ipmitool lan print  #查看配置信息
    ipmitool lan print [数字]  #从0开始一个一个试 找到该设备上默认的ipmi的channel值
    ipmitool lan set 1 ipaddr 192.168.0.100  #IP  #这里假设channel时1 下同
    ipmitool lan set 1 netmask 255.255.255.0  #子网掩码
    ipmitool lan set 1 defgw ipaddr 192.168.0.1  #网关
    ipmitool lan set 1 access on  #启用 （off为关闭）
   ```

   更多`ipmi`命令可在输入`ipmitool`回车后查看，在`ipmitool lan`回车后可查看配置LAN控制相关命令。

- 设置管配置理用户

  ```shell
  ipmitool user list 1  #查看当前用户列表
  ipmitool user set name <user id> <username>   #修改用户名
  ipmitool user set password <user id>  #设置admin密码 执行后输入两次新密码
  ```
  **注意**：密码可能有位数要求(一般最少8位），密码过短会返回错误信息。

  更多命令帮助，在`ipmitool user`回车后可查看。

  常见服务器厂商IPMI（带外管理）默认管理员用户信息（以/分隔用户名密码）：

  - DELL戴尔  iDRAC
    - root/calvin
  - Inspur浪潮
    - root /superuser
  - H3C新华三  HDM
    - admin/Password@_
  - Huawei华为
    - root/Huawei12#$
  - HPE慧与（惠普） iLO
    - Administrator/密码在服务器的信息卡片或标签上
  - Sungon曙光
    - admin/admin
  - Lenovo联想
    - lenovo/len0VO

  

  ## ipmitool常用操作

  ```shell
  #查看本机
  ipmitool sdr   #查看传感器信息Sensor Data Repository
  
  #远程控制
  #power status
  ipmitool -H 192.168.0.100 -U admin -P <password> power status  #会返回power is on
  
  #power on/off
  ipmitool -H <addr> -U <user> -P <password> power on #off
  
  #boot via PXE
  ipmitool -H <addr> -U <user> -I lanplus -P <password> chassis bootdev pxe
  ```

​		远程控制使用`-H`制定地址，`-U`指定用户，`-P`指定用户密码。



# WEB管理界面

浏览器开启https://你IPMI的IP地址（例如本文中为https://192.168.1.100），输入用户名和密码，即可登录web管理界面。

在web管理界面可以对设备进行电源管理、镜像挂载、固件升级、网络配置、设备实时画面查看等等操作，就如同身处该设备旁边一般。
