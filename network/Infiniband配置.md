

- 虚拟协议互联（VPI）技术允许Mellanox ConnectX网卡系列在两个端口上同时传输InfiniBand和以太网流量
- 可在所有可用的Mellanox InfiniBand和以太网设备及配置（例如MemFree、SDR/DDR/QDR/FDR/EDR/HDR、10 /25/40/50/100/200 GbE和PCI Express模式3.0和4.0上运行单个软件堆栈
- 支持HPC应用于科学研究、人工智能、石油和天然气勘探、汽车碰撞测试、标杆管理等（例如，Fluent、 LS-DYNA）
- 支持Oracle 11g/10g RAC、IBM DB2等数据中心应用，以及IBM WebSphere LLM、Red Hat MRG、NYSE Data Fabric等金融服务应用
- 支持利用RDMA优势的高性能块存储应用



# 安装

卸载 ofed_uninstall 



# 获取信息

- ibv_devinfo 详细信息
- ivv_device  卡列表  

查看驱动版本 ofed_info 



# 测试

1. 类似地，运行 **ibv_rc_pingpong** 命令。
2. 类似地，运行 **ib_read_bw** 和 **ib_write_bw** 命令。



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