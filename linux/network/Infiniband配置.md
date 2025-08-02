# 简介

- 虚拟协议互联（VPI）技术允许Mellanox ConnectX网卡系列在两个端口上同时传输InfiniBand和以太网流量
- IPoIB（IP over IB），在infiniband网卡上使用IP协议。
- 可在所有可用的Mellanox InfiniBand和以太网设备及配置（例如MemFree、SDR/DDR/QDR/FDR/EDR/HDR、10 /25/40/50/100/200 GbE和PCI Express模式3.0和4.0上运行单个软件堆栈
- 支持HPC应用于科学研究、人工智能、石油和天然气勘探、汽车碰撞测试、标杆管理等（例如，Fluent、 LS-DYNA）
- 支持Oracle 11g/10g RAC、IBM DB2等数据中心应用，以及IBM WebSphere LLM、Red Hat MRG、NYSE Data Fabric等金融服务应用
- 支持利用RDMA优势的高性能块存储应用



# 驱动安装

使用开源的ofed或生产商提供的驱动。

```shell
 ./mlnxofedinstall   #mellnaox ib driver
```



安装驱动后启用openibd服务，检查网卡情况：

```shell
#查看当前驱动版本
ofed_info |head -n 1

systemctl enable --now openibd
ibstat
```



# 子网管理器

每个infiniband网口连入一个子网中，一个Infiniband子网中至少需要一个子网管理器subnet manager（SM）。

如果一个主机上使用多个网口，每个网口接入不同的子网，每个子网均需要启动一个opensm。

*可以在交换机中启动子网管理器或者在该子网的主机中启动子网管理器。*



## 交换机中启用子网管理器

登录带有管理功能的交换机交换机，执行`config`进入配置模式：

```shell
ib sm      #启动
show ib sm #查看
#ib sm routing-engines ftree  #设置路由算法
```



## 主机上启用启动子网管理器

启用opensmd：

```shell
#-B run opensmd in the background
opensm -B

#或者使用systemd管理
systemctl enable --now opensmd
```

一般建议在多个主机中启用opensm服务，多个oepnsm服务的主机中将至少一个生效，以保证整个子网ib网络的高可用。

可为不同的opensm服务主机使用`-p`参数设置不同的权重`PRIORITY`（取值0-15），权重大的主机总是优先作为SM：

``` 
opensm -B -p 15 [-g guid]
```



对于使用system/chkconfig启动opensm服务，可找到opensmd的服务管理文件，该文件中定义了opensm配置文件路径，在rhel中一般是`/etc/sysconfig/opensm`，示例：

```shell
#可以为不同主机的opensm设置不同的权重
PRIORITY=15

#sm使用多个port时，每个port之间使用空格分隔
GUIDS="0xb8599f030012a480 0xb8599f030012a364"  #ibstat -p
```

或者编辑`/etc/opensm/opensm.conf`，示例：

```shell
#sm使用多个port时，每个port之间使用空格分隔
guid 0xb8599f030012a480,guid 0xb8599f030012a481
```

如果没有这个文件，可以使用`opensm -c /etc/opensm/opensm.conf`生成。



### 多个子网

多个主机 之间使用多个独立的子网时，需要为不同的子网启动各自的opensm服务。

在一个子网中为保证高可用，一般会有多个启动opensm服务的主机，因此也可以在多个主机上为不同子网启动一个opensm。例如需要启动两个子网，可以在一些主机上为一个子网启动opensm，在另一些主机上为另一个字网启动opensm，启动opensm时需要指定guid。

或者在每个需要启动子网服务的主机上启动多个opensm。



注意：如果使用systemctl或chkconfig管理oepnsmd服务，默认的opensmd服务启用一个字网服务（具体可检查测试相关启动脚本）。

```shell
ibstat -p  #列出所有port的guid
ibstat -l  #列出所有IB设备
```

为每个guid启动一个oepnsm进程：

```shell
#!/bin/bash
log_level=ERROR #INFO | DEBUG | ERROR and so on
log_dir=/var/log
log_limit=10 #log size ,unit is MB

#=======
devices=$(ibstat -l) #all IB devices  --list_of_cas

echo "$devices" | while read device; do
    guids=$(echo $(ibstat $device | grep "Port GUID" | awk '{print $NF}') | sed -E "s/\s/,/g")

    [[ -z "$guids" ]] && continue

    priority=$((RANDOM % 15)) #0-15

    if [[ -z $(ps -eo cmd | grep opensm | grep $guids | grep -v grep) ]]; then
        pid_file=/var/run/$device.pid
        log_file=$log_dir/opensm-$device.log
        opensm -B -g $guids -p $priority -f $log_file -D $log_level --log_prefix $device -L $log_limit -e --pid_file $pid_file &>>/tmp/start_opensm.log
    fi
done

# ib_guids=$(ibstat -p)
#--deamon or -B
# --guid or -g                     #specify device via guid
# --priority or -p                 #0-15
# --log_limit or -L
# --erase_log_file or -e
# --log_file or -f
# --config or -F                    #specify config file
# --create-config, -c <file-name>  #generate config file
```



# IPoIB配置

infiniband提供了IPoIB（Internet Protocol over InfiniBand）功能，利用物理IB网络通过IP协议进行数据传输。IPoIB提供了基于RDMA之上的IP网络模拟层，允许应用无修改的运行在InfiniBand网络上。

注意在为ib网卡配置ip地址时，网络类型选择Infiniband。

但是，IPoIB没有充分利用HCA的功能，网络流量通过正常的IP堆栈，这意味着每条消息都需要系统调用，主机CPU必须处理将数据分解为数据包等，普通IP套接字的应用程序将在IB链路的全速上工作（尽管CPU可能无法以足够快的速度运行IP堆栈，无法使用高带宽的IB链路）。

另：IB一般也支持切换link layer为Ethernet（需要修改配置），当作纯粹的以太网卡使用。



# 检查测试

## 状态消息查看

- ibstat            ib状态信息

  ```shell
  ibstat -l        #list all devices
  ibstat <device>  #display info of specified device
  ibstat -p        #list all guids
  ```

- ibping

  在一个节点启动服务端

  ```shell
  #先查看处于active状态的ib卡的Base lid值 ,例如值为16
  ibstat
  #启动ibping server
  ibing -s
  ```

  在另一个节点测试ping

  ```shell
  #ibping [-c N] -L <lid>
  ibping -c 100 -L 16  #例如server的lid时16, ibping 100次
  ```

  

- ibnodes        当前子网中的节点信息

- ibv_devices  设备基本信息

- ibv_devinfo  设备的详细信息

- iblinkinfo      网络拓扑信息

- ofed_info      查看驱动版本 

- ibdiagnet      网络诊断（日志默认保存在/var/tmp/ibdiagnet2/）

  ```shell
  ibdiagnet -ls FDR10 -lw 4x -r
  ```

  - --ls <2.5|5|10|14|25|FDR10|EDR20>: Specifies the expected link speed.

  - --lw <1x|4x|8x|12x> : Specifies the expected link width.

  - -r|--routing : Provides a report of the fabric qualities.

- mst               mellanox software tools

  - mst status -v

- mlnx_tune  调优工具

  ```text
  mlnx_tune -r 
  ```




## 性能测试

IB网卡的TCP性能的测试结果（尤其是带宽）和网卡的标称性能差距很大，是因为IPoIB并不能充分发挥出IB的能力，IB产品宣称的性能是针对RDMA协议而言的。如果要测出接近IB产品宣称的性能指标，应当使用以下工具测试：

- qperf

  测试RC、UC、RD、UD不同传输模式的性能。

- 使用ib驱动组件中带有的工具测试

  示例：

  1. 在一台主机host1上启动程序

     ```shell
     ib_send_bw  #示例测试bw
     ```

  2. 在另一台主机host2上发起数据传输进行测试

     ```shell
     ib_send_bw host1  #可使用主机名或LID
     ```

  - 带宽bw测试工具
    - ib_send_bw
    - ib_write_bw
    - ib_read_bw
    - ib_atomic_bw
  - 延迟lat测试工具
    - ib_send_lat
    - ib_write_lat
    - ib_read_lat
    - ib_atomic_lat





# IB设备管理

使用mst（Mellanox Software Tools）工具可以管理本机IB设备和子网内可发现的其他IB设备。

## 设备查看

```shell
mst start

#默认只发现本机的ib设备，设备以/dev/mst/xxx形式
mst status

#发现并加入子网种其他可见的ib设备
mst ib add
mst status  #加入后就能发现本网络中其他ib设备

#查看某个IB设备详细信息
mst <device> query
```



## 升级固件

flint工具可以升级本机IB设备的固件和子网内可发现的其他IB设备的固件。

提示：

- mellanox的设备固件以MT开头，可从mellanox官网下载，mellanox设备的其他OEM厂商固件需要向厂商索取，不同厂商有固定的PSID编号，OEM的设备无法使用mellanox的固件。

```shell
flint -d <device> -i <firmware file> burn #烧录新的固件，根据提示确认输入y
```



# 网卡模式

可以将IB网卡切换为ethernet当作纯以太网卡使用。

查看当前模式：

```shell
ibv_devinfo | grep transport
```

link_layer行显示当前模式，`Infiniband`或`Ethernet`

`mst status`获取mst device信息：

```shell
#如果mst status 提示module not loaded 先加载模块
modprobe mst_pci mst_pciconf
mst restart 
mst status
```

输出示例：

> MST devices:
>
> \------------
>
> /dev/mst/mt4119_pciconf0     - PCI configuration cycles access.
>
> ​                  domain​bus:dev.fn=0000:18:00.0 addr.reg=88 data.reg=92 cr_bar.gw_offset=-1
>
> ​                  Chip revision is: 00

使用mlxconfig 修改模式：

```shell
#其中mt4119_pciconf0替换成mst status中看到的实际的device信息
mlxconfig -d /dev/mst/mt4119_pciconf0 set LINK_TYPE_P1=2
```

`LINK_TYPE_P1=1`为infiniband

为使配置生效，需要重启系统或者执行以下命令重启driver：

```shell
mlxfwreset --device /dev/mst/mt4119_pciconf0 reset
```



# infiniband虚拟化

参考文档 https://community.mellanox.com/s/article/howto-configure-sr-iov-for-connect-ib-connectx-4-with-kvm--infiniband-x

```shell
#!/bin/bash
#1----for oepnsm server
if [[ $(systemctl is-enabled opensmd) == 'enabled' ]]; then
    echo "virt_enabled 2" >/etc/opensm/opensm.conf
    systemctl restart opensmd
fi

#2----for openibd nodes
#enable sr-iov and vmx virtual in BIOS(UEFI setup)
#add  intel_iommu=on iommu=pt  to /etc/default/grub CMDLINE,
#redhat uefi mode:
#grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg #centos is centos/grub.cfg
#redhat bios (some distro uefi mode):
#grub2-mkconfig -o /boot/grub2/grub.cfg
vf_nums=1 #how many virtual ib devices will be created

echo Follow >/sys/class/infiniband/mlx5_0/device/sriov/0/policy

cat /sys/class/infiniband/mlx5_0/device/sriov/0/policy

i=0
while [ $i -lt $vf_nums ]; do
    #virtal ib device defautl GUID is 00:00:00:00:00:00:00:00
    #eg. hostname is c10 , host_num is c10
    port_id=11:11:11:11:11:11:$(echo $HOSTNAME | grep -oE [0-9]+):${i}0
    node_id=11:11:11:11:11:11:$(echo $HOSTNAME | grep -oE [0-9]+):${i}1

    echo $port_id >/sys/class/infiniband/mlx5_0/device/sriov/$i/port
    echo $node_id >/sys/class/infiniband/mlx5_0/device/sriov/$i/node

    #find the id :ls /sys/bus/pci/drivers/mlx5_core/
    pci_id=$(lspci | grep -i mellanox | grep -v 00.0 | sed -n "$((i + 1))p" | cut -d " " -f 1)
    echo ===device $((i + 1)) PCI: $pci_id===
    echo 0000:$pci_id >/sys/bus/pci/drivers/mlx5_core/unbind
    echo 0000:$pci_id >/sys/bus/pci/drivers/mlx5_core/bind

    echo "port_id:"
    cat /sys/class/infiniband/mlx5_0/device/sriov/$i/port
    echo "node_id:"
    cat /sys/class/infiniband/mlx5_0/device/sriov/$i/node

    let i+=1
done
```

opensm服务运行节点需要在/etc/opensm/opensm.conf文件中添加`virt_enabled 2`



1. 宿主机上配置IB虚拟化

   1. 在BIOS（或者UEFI setup）中已经启用了SR-IOV和vmx功能
   2. 在grub启动参数中添加`intel_iommu=on iommu=pt`参数，重新生成grub.cfg
      1. add  intel_iommu=on iommu=pt  to /etc/default/grub CMDLINE
      2. generate grub.cfg
         - redhat uefi mode
           grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg  #centos is centos/grub.cfg
         - redhat bios (some distro uefi mode):
           grub2-mkconfig -o /boot/grub2/grub.cfg
   3. 安装Infiniband的驱动

   

2. 在开启opensmd服务的节点的配置文件中开启虚拟化

   MLNX OFED 4.x 的配置文件是`/etc/opensm/opensm.conf`

   UFM 5.x 和 6.x 的配置文件是`/opt/ufm/files/conf/opensm/opensm.conf`

   > virt_enabled 2

   virt_enabled取值：

   - 0: Ignore Virtualizations - No virtualization support
   - 1: Disable Virtualization - Disable virtualization on all Virtualization supporting ports
   - 2: Enable Virtualization - Enable (virtualization on all Virtualization supporting ports)

   编辑保存后重启opensmd服务

   

3. 在宿主机开启固件上的SR-IOV

   启动服务

   ```shell
   mst start
   ```

   > \# mst start
   >
   > Starting MST (Mellanox Software Tools) driver set
   >
   > Loading MST PCI module - Success
   >
   > Loading MST PCI configuration module - Success
   >
   > Create devices

   确认IB设备信息

   ```shell
   mst status
   ```

   > \# mst status
   >
   > MST modules:
   >
   > \------------
   >
   > MST PCI module loaded
   >
   > MST PCI configuration module loaded
   >
   >  
   >
   > MST devices:
   >
   > （略）

   检查IB状态

   ```shell
   mlxconfig -d /dev/mst/mt4113_pciconf0 q  #从mst status中获取ib卡信息替换这里的mt4113
   ```

   > \# mlxconfig -d /dev/mst/mt4113_pciconf0 q
   >
   >  
   >
   > Device #1:
   >
   > \----------
   >
   >  
   >
   > Device type: ConnectIB 
   >
   > PCI device: /dev/mst/mt4113_pciconf0
   >
   >  
   >
   > Configurations: Current
   >
   > SRIOV_EN 0 
   >
   > NUM_OF_VFS 0 
   >
   > INT_LOG_MAX_PAYLOAD_SIZE 0

   开启SR-IOV，设置以下值：

   - SRIOV_EN=1
   - NUM_OF_VFS=4   #表示虚拟出4个IB设备

   ```shell
   mlxconfig -d /dev/mst/mt4113_pciconf0 set SRIOV_EN=1 NUM_OF_VFS=4 FPP_EN=1
   ```

   重启固件服务（或者重启系统）

   ```shell
   mlxfwreset --device /dev/mst/mt4113_pciconf0 reset
   ```

   

   

4. 在宿主机上将虚拟出来的IB设备以直通方式到加入到虚拟机中

   virt-manager图形前端中可以方便地选择虚拟出来的PCI设备添加到虚拟机中。

   

5. 在虚拟机中安装Infiniband驱动

   

6. 宿主机开机自动配置虚拟IB卡信息

   *虚拟IB卡在宿主机重启后，部分配置信息会丢失。*

   在宿主机系统引导完成后执行以下内容，在宿主机启动后根据主机编号为虚拟的ib卡配置地址等信息，以确保IB虚拟化正常，且虚拟机在IB虚拟化完成后才启动，避免虚拟机启动后没有可用的IB。

   ```shell
   #!/bin/bash
   
   log=/tmp/ib-sriov-kvm.log
   ib_type=mlx5
   ib_device=${ib_type}_0
   ib_core=${ib_type}_core
   
   echo "===$(date)===" > $log
   
   #主机编号 eg. c09 --> 09
   host_num=$(cat /etc/hostname | /usr/bin/grep -oE "[0-9]+") #eg. 09
   
   node_addr=11:11:11:11:11:11:${host_num}:00
   
   port_addr=11:11:11:11:11:11:${host_num}:01
   
   #虚拟出1个ib卡
   echo 1 > /sys/class/infiniband/$ib_device/device/${ib_type}_num_vfs
   echo Follow > /sys/class/infiniband/$ib_device/device/sriov/0/policy
   #为虚拟ib卡设置地址
   echo $node_addr > /sys/class/infiniband/$ib_device/device/sriov/0/node
   echo $port_addr > /sys/class/infiniband/$ib_device/device/sriov/0/port
   echo 0000:af:00.1 > /sys/bus/pci/drivers/$ib_core/unbind
   echo 0000:af:00.1 > /sys/bus/pci/drivers/$ib_core/bind
   
   sleep 10
   #启动虚拟机
   vm=vm${host_num}
   echo "start $vm ..." &>> $log
   virsh start $vm &>> $log
   ```

   可以用crontab的`@reboot`任务或`/etc/rc.local`或stemd unit方式实现自启动。

   如果要自启动虚拟机系统，确保虚拟机在以上命令执行后再启动。