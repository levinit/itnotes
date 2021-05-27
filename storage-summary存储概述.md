# 接口协议

## P(ATA)/IDE

IDE即电子集成驱动器（Integrated Device Electronics）。

IDE接口也称为ATA（Advanced Technology Attachment高级技术附加装置）接口，俗称“并口”（并行接口）。

> ATA是一个[控制器](https://zh.wikipedia.org/wiki/%E6%8E%A7%E5%88%B6%E5%99%A8)技术，而IDE是一个匹配它的磁盘驱动器技术，但是两个术语经常可以互用。

> 2003年推出SATA（Serial ATA）后，原有的ATA改名为PATA（并行高技术配置，Parallel ATA）。

停产，基本不再使用。

## SATA

串行ATA（Serial ATA），俗称“串口”（串行接口）。

> 串行ATA总线使用嵌入式时钟信号，具备了更强的纠错能力，结构简单，支持热拔插。

不同版本的SATA宽带速度

> 为了防止数据在高速传输中出错而加入校验码，比如PCI-E 2.0、USB 3.0和SATA 3.0中采用的是[8/10编码](https://zh.wikipedia.org/wiki/8b/10b)，每10位编码中只有8位是真实数据，这时单位换算就不再是1:8而是1:10。

| SATA版本     | 带宽    | 理论速度 |
| ------------ | ------- | -------- |
| SATA Express | 16Gb/s  | 1600MB/s |
| SATA 3.0     | 6Gb/s   | 600MB/s  |
| SATA 2.0     | 3Gb/s   | 300MB/s  |
| SATA 1.0     | 1.5Gb/s | 150MB/s  |

## SCSI

小型计算机系统接口（SCSI，**S**mall **C**omputer **S**ystem **I**nterface）。

> 一种用于计算机和智能设备之间（硬盘、软驱、光驱、打印机、扫描仪等）系统级接口的独立处理器标准。
>
> SCSI并不是专门为硬盘设计的接口，是一种广泛应用于小型机上的高速数据传输技术。SCSI接口具有应用范围广、多任务、带宽大、CPU占用率低，以及热插拔等优点。

## SAS

SAS(Serial Attached SCSI)，串行连接SCSI，速度较传统SCSI接口显著提上。

> SAS是并行SCSI接口之后开发出的全新接口

SAS可以兼容SATA，但是SATA系统并不兼容SAS。

## FC

光纤通道（FC，Fiber Channel），又名网状通道，是一种高速网络互联技术。

> **网状通道协议**（**Fibre Channel Protocol**，**FCP**）是一种类似于[TCP](https://zh.wikipedia.org/wiki/TCP)的传输协议，大多用于在光纤通道上传输[SCSI](https://zh.wikipedia.org/wiki/SCSI)命令。

# 存储分类

- **封闭系统的存储**（主要指大型机 略）

- **开放系统的存储**（基于包括Windows、UNIX、Linux等操作系统的服务器）

  - **内置存储**

  - **外挂存储**(*根据连接方式分类*)

    - **DAS** - **直连式存储**（或称为直接连接存储Direct Attached Storage） 

      - SCSI（*SCSI*，Small Computer System Interface）小型计算机系统接口
      - FC（Fibre Channel） 光纤通道

    - **FAS** - **网络化存储**（Fabric-Attached Storage）（*根据传输协议分类*）

      - **NAS** - 网络接入存储（Network Attached Storage）

        - NFS
        - SAMBA

      - **SAN** - 存储区域网络（Storage Area Network）

        - IP-SAN/**ISCSI**

          ISCSI即互联网小型计算机接口（Internet Small Computer System Interface）

        - FC-SAN

          光纤连接

## DAS 

- 数据传输

  **存储设备**<--->**客户端FS**<--->**客户端应用程序**

- 输出：块级
- 主要特点
  - 优点
    - 成本低；
    - 易实施和维护；
    - 存储资源专有——每个应用服务器都要有独立的存储设备
  - 缺点
    - 无法与其他服务器共享数据其扩展差，同时存储依赖服务器主机操作系统进行数据的读写和维护管理，将占用服务器一部分资源，一般只适合小规模服务器群。

*FS指文件系统，下同*。

## NAS

- 数据传输

  **存储设备**<--->**存储服务器FS**<--->**以太网络** <--->**客户端应用程序**

- 输出：文件级

- 主要特点：

  - 成本低；扩展灵活；适合高并发随机小块IO或者共享访问文件的环境

## SAN

- 数据传输

  **存储设备**<--->**FC/ISCSI**<--->**客户端FS**<--->**客户端应用程序**

- 输出：块级

成本高；存储与应用服务器分离 ；扩展好；性能好——适合大块连续IO密集型环境。

----

NAS和SAN最本质的区别——文件系统FS在不同的“位置”：

SAN结构中，文件管理系统（FS）分别在每一个应用服务器上面；NAS结构中，每个应用服务器通过网络共享协议，使用同一个文件管理系统。

SAN与NAS的整合可增加存储的适用性。

# 硬盘分类

- HDD
  - IDE
  - STAT
  - SCSI
  - SAS
- SSD
  - 按接口形态分：
    - SATA类：SATA、mSATA、SATA Express
    - M.2类：Bkey和Mkey
    - PCIE
    - U.2
  - 按传输协议分：
    - SATA
    - NVMe
  - 按传输通道分：
    - PCIe
      - AHCI
      - NVMe
    - SATA