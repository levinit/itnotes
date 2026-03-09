# 存储类型

## 集中式存储

传统存储的集中式存放数据到中心设备中。

传统磁盘存储：

- **封闭系统的存储**（主要指大型机 略）

- **开放系统的存储**

  - **内置存储**

  - **外挂存储**(*根据连接方式分类*)

    - **DAS** - **直连式存储**（或称为直接连接存储Direct Attached Storage） 

      ​	**存储设备**<--->**客户端FS**<--->**客户端应用程序**

      将外部存储设备使用SCSI/FC等方式直接连接到计算机上使用。

    - **FAS** - **网络化存储**（Fabric-Attached Storage）（*根据传输协议分类*）

      - **NAS** - 网络接入存储（Network Attached Storage） 

        通过TCP、UDP等网络协议将目录共享给客户端。输出的是文件级别。

        典型应用：NFS、SAMBA

      - **SAN** - 存储区域网络（Storage Area Network）

        **存储设备**<--->**FC/ISCSI**<--->**客户端FS**<--->**客户端应用程序**

        将传输网络模拟成SCSI总线来使用，通过网络将存储设备（一般是磁盘阵列）以块文件方式映射到计算机上。

        - IP-SAN/ISCSI-SAN   基于以太网

          **iSCSI**（Internet Small Computer System Interface，发音为/ˈаɪskʌzi/），Internet小型计算机系统接口，又称为IP-SAN，基于因特网和SCSI-3协议下的存储技术。
        
        - FC-SAN                     基于光纤通道
        

## 分布式存储

Distributed data store，DDS

数据分散在多个存储节点上，各个节点通过网络相连，对这些节点的资源进行统一的管理。

- 块存储
- 对象存储系统
- 文件存储系统



# 硬盘分类

按照存储介质分类：

- HDD  Hard Disk Drive  硬盘（为了与固态硬盘相区分称“机械硬盘”或“传统硬盘”）

  按照接口协议分类参看后问硬盘接口协议，按照常规尺寸分类主要是2.5寸和3.5寸。

  例如：1TB 10000转 SAS 3.5寸硬盘，包含了容量、转速、数据接口协议类型以及尺寸。

- SSD   Solid State Drive  固态硬盘

  固态硬盘一般首先按照外观结构接口分类，再按照支持的逻辑设备接口（驱动程序）与总线协议分类。

  例如：512G M.2接口 Nvme协议 PCIex4总线

- HHD  Hybrid drive或Solid state hybrid drive  混合固态硬盘



## 接口类型

物理设备接口的外观形态

- IDE     Integrated Drive Electronics，电子集成驱动器

- SATA

  AHCI协议，SATA总线

- SATAe    AHCI协议，SATA总线，两个SATA接口和一个辅助接口组合而成（提升速度），目前多被M.2接口取代

- SCSI

- SAS

  AHCI协议，SATA总线

- mSATA  (mini-SATA)

    AHCI协议，SATA总线

- M.2（前身NGFF，标准名称为PCI Express M.2 Specification）  

  用于固态硬盘，尺寸小，替代mSATA

  按照接口处的缺口形态区分：

  - Bkey（socket 2）

    1个 缺口在左侧，缺口左方6引脚（金手指）

    SATA总线或PCIex2总线

  - Mkey（socket 3）

    1个缺口在右侧，缺口右方5引脚

    使用NVMe协议，PCIex4总线

  - B&M key

    两个缺口（为B和M的缺口位置）

    PCIex2总线

- U.2

  NVMe协议口，PCIe总线，外观上和SAS接口一致

- PCIe    PCI Express（也简称PCI-E）  直连 CPU，速度快

  可有 PCIe 2.0x2、PCIe 2.0x4、PCIe 2.0x8、PCIe 3.0x4等等

  有兼容SATA、不带NVMe、带NVMe等类型



## 传输协议

- ACHI
- iSCSI
- NVMe



## 传输总线

计算机多个电子元器（如CPU，内存，硬盘等）之间**传输数据的公用通道**。

- PCIe
- SATA
- ATA
- SCSI
- SAS