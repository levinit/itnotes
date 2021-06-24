

- 虚拟协议互联（VPI）技术允许Mellanox ConnectX网卡系列在两个端口上同时传输InfiniBand和以太网流量
- 可在所有可用的Mellanox InfiniBand和以太网设备及配置（例如MemFree、SDR/DDR/QDR/FDR/EDR/HDR、10 /25/40/50/100/200 GbE和PCI Express模式3.0和4.0上运行单个软件堆栈
- 支持HPC应用于科学研究、人工智能、石油和天然气勘探、汽车碰撞测试、标杆管理等（例如，Fluent、 LS-DYNA）
- 支持Oracle 11g/10g RAC、IBM DB2等数据中心应用，以及IBM WebSphere LLM、Red Hat MRG、NYSE Data Fabric等金融服务应用
- 支持利用RDMA优势的高性能块存储应用



# 安装配置

## 驱动安装

使用开源的ofed或生产商提供的驱动。

安装驱动后启用openibd服务，检查网卡情况：

```shell
systemctl enable --now openibd
ibstat
```



## 子网管理器

一个Infiniband网络中要有至少一个子网管理器subnet manager（sm）。可以在交换机中启动子网管理器或者在该子网的主机中启动子网管理器

### 交换机中启用子网管理器

登录带有管理功能的交换机交换机，执行`config`进入配置模式：

```shell
ib sm      #启动
show ib sm #查看
#ib sm routing-engines ftree  #设置路由算法
```

### 该网络中的主机上启用启动子网管理器

可以在该子网的一个或多个主机中启用：

```shel
systemctl enable --now opensmd
```

多个sm可以保证整个子网ib网络的高可用。可以为每个开启opensmd的主机设置不同的优先级。

opensm的`-p`参数可以指定优先级，优先级为一个0-15的数字，数字越大优先级越高；对于多个port的情况，可以使用`-g`指定GUID。参看`man opensm`。

对于使用自启动服务（如systemd）启动opensmd，找到opensmd的服务管理文件，其执行的是一个shell脚本，脚本中有读取的opensm配置文件行，确定该opensm配置文件的路径，即可新建或编辑该opensm配置文件，在文件中使用`PRIORITY`定义优先级，如：

```shell
PRIORITY=15
```



## IPoIB配置

infiniband提供了IPoIB（Internet Protocol over InfiniBand）功能，利用物理IB网络通过IP协议进行数据传输。IPoIB提供了基于RDMA之上的IP网络模拟层，允许应用无修改的运行在InfiniBand网络上。

注意在为ib网卡配置ip地址时，网络类型选择Infiniband。

但是，IPoIB没有充分利用HCA的功能，网络流量通过正常的IP堆栈，这意味着每条消息都需要系统调用，主机CPU必须处理将数据分解为数据包等，普通IP套接字的应用程序将在IB链路的全速上工作（尽管CPU可能无法以足够快的速度运行IP堆栈，无法使用高带宽的IB链路）。

另：IB一般也支持切换link layer为Ethernet（需要修改配置），当作纯粹的以太网卡使用。



## 检查验证

- ibstat            ib状态信息

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

- mlnx_tune  调优工具

  ```text
  mlnx_tune -r 
  ```

  



## 切换网卡模式 infiniband/ethernet

查看当前模式：

```shell
ibstat  #或ibv_devinfo
```

link_layer行显示当前模式，`Infiniband`或`Ethernet`（Ehternet模式下网卡将作为太网卡使用，放弃infiband的优势）。

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