# 概述

lvm, logic volume manager

> LVM利用Linux内核的[device-mapper](http://sources.redhat.com/dm/)来实现存储系统的虚拟化（系统分区独立于底层硬件）。它在[硬盘](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F)的[硬盘分区](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F%E5%88%86%E5%89%B2)之上，又创建一个逻辑层，以方便系统管理硬盘分区系统。

通过lvm可以实现存储空间的抽象化，建立虚拟分区（Virtual Partitions），轻松实现对虚拟分区的扩大和缩小操作。

## 特性

> 比起正常的硬盘分区管理，LVM更富于弹性： 
>
> - 使用卷组(VG)，使众多硬盘空间看起来像一个大硬盘。
> - 使用逻辑卷（LV），可以创建跨越众多硬盘空间的分区。
> - 可以创建小的逻辑卷（LV），在空间不足时再动态调整它的大小。
> - 在调整逻辑卷（LV）大小时可以不用考虑逻辑卷在硬盘上的位置，不用担心没有可用的连续空间。
> - 可以在线（online）对逻辑卷（LV）和卷组（VG）进行创建、删除、调整大小等操作。LVM上的文件系统也需要重新调整大小，某些文件系统也支持这样的在线操作。
> - 无需重新启动服务，就可以将服务中用到的逻辑卷（LV）在线（online）/动态（live）迁移至别的硬盘上。
> - 允许创建快照，可以保存文件系统的备份，同时使服务的下线时间（downtime）降低到最小。

注意：当卷组中的一个硬盘损坏时，整个卷组都会受到影响，因此多硬盘组合使用时或可考虑使用raid等技术手段实现数据冗余存储。

## 组成

-  **物理卷Physical volume (PV)**：指硬盘分区，或硬盘本身，或者回环文件（loopback  file）。

   物理卷包括一个特殊的header，其余部分被切割为一块块物理区域（physical extents）。 

-  **卷组Volume group (VG)**：将一组物理卷收集为一个管理单元。

-  **逻辑卷Logical volume (LV)**：虚拟分区，由物理区域（physical extents）组成。

-  **物理区域Physical extent (PE)**：硬盘可供指派给逻辑卷的最小单位（通常为4MB）。



```shell
  lv1 |  lv2
-------------
     vg
-------------
 pv1  |  pv2
```



# 操作

## 创建流程

1. 创建物理卷pv：将块设备创建为lvm物理卷

2. 创建卷组vg：将一个或多个物理卷加入到卷组

3. 创建逻辑卷lv：在卷组中创建一个或多个逻辑卷

4. 使用逻辑卷

   像普通分区一样使用逻辑卷，只是逻辑卷挂载位置不同，可使用以下两种方式：

   - `/dev/mapper/卷组名-逻辑卷名`   如`/dev/mapper/cent-swap`
   - `/dev/卷组名/逻辑卷名`  如`/dev/cent/swap`

```shell
#1 在sda和sdb创建pv
pvcreate /dev/sda /dev/sdb

#2 创建名为linux的卷组 包含/dev/sda和/dev/sdb
vgcreate linux /dev/sda /dev/sdb

#3. 在卷组linux中创建三个逻辑卷 root  swap  home
lvcreate -n root -L 30G linux
lvcreate -n swap -L 8G linux
lvcreate -n home -l 100%FREE linux

#4. 使用逻辑卷 在逻辑卷建立文件系统
mkfs.ext4 /dev/linux/root
mkfs.ext4 /dev/linux/home
mkswap /dev/mapper/linux-swap
```

## 常用操作

以下为直接使用的lvm命令，也可以执行`lvm`命令进入lvm的交互式命令行，使用相关命令进行操作。



```shell
lvmdiskscan  #查看可以用作物理卷的设备
```



lvm中针对pv、vg和lv的操作命令类似，常用命令：

| 命令关键字 | pv命令    | vg命令    | lv命令    |
| :--------- | :-------- | :-------- | --------- |
| s          | pvs       | vgs       | lvs       |
| scan       | pvscan    | vgscan    | lvscan    |
| create     | pvcreate  | vgcreate  | lvcreate  |
| display    | pvdisplay | vgdisplay | lvdisplay |
| remove     | pvremove  | vgremove  | lvremove  |
| extend     |           | vgextend  | lvextend  |
| reduce     |           | vgreduce  | lvreduce  |
| rsize      | pvresize  |           | lvresize  |
| rename     |           | vgrename  | lvrename  |

`s`为列出相关信息，例如`pvs`命令用于列出pv的信息。

其余关键字即为单词的含义，如`scan`扫描，pvscan即为扫描系统中的所有pv。

另`vgexport`  注销vg信息，使vg不可使用；`vgimport`  激活已经注销的vg，使其可使用。



### 物理卷pv

```shell
pvremove /dev/sda  #删除物理卷/dev/sda
pvchange -x -u /dev/sda  #-x禁止分配PE -u生成uuid

#扩增物理卷（可在线）：分区扩大后需要对物理卷扩增才能使用新增空间
pvresize /dev/sda

#缩小物理卷（可在线）：缩小分区前需要先缩小物理卷
pvresize --setphysicalvolumesize 40G /dev/sda1
```

### 卷组vg

```shell
vgextend <vg-name> /dev/sdc #扩充卷组 新加一个sdc物理卷
vgrename <old-name> <new-name>  #卷组更名
vgremove <vg-name> #删除卷组
```

### 逻辑卷lv

- 创建

  常用参数：

  - `-n`或`--name`指定卷名
  - `-L`或`--size`指定大小
  - `-l`或`--extents`以百分比指定大小

  ```shell
  #在卷组中创建逻辑卷 可使用-n添加该逻辑卷名字（可选）
  lvcreate -L <size> <vg-name> [-n <lv-name>]
  
  #-l参数可使用 百分比加关键字 的方式分配空间
  #使用所有剩余空间（加号可省略）
  lvcreate -l +100%FREE <vg-name> [-n <lv-name>]
  #使用卷组50%的空间xxxxxxxxxx 
  lvcreate -l 50%VG <vg-name> [-n <lv-name>]
  ```

  lvm**快照**（snapshot）：创建快照即创建一个写时复制逻辑卷，在创建快照时使用`-s`或`--snapshot`参数。

  > LVM 快照处于底层块设备层，基于**数据块级别（block-level）的写时复制（Copy-On-Write, COW）**机制运作。创建快照时仅记录原始卷的块元数据；当源逻辑卷上的数据块被首次修改覆写前，LVM 会先将原始数据块复制保存到快照卷中。

  快照大小的设置主要根据快照存活期间源卷的数据变更量来估算：

  - 块的改变量
  - 数据写入频率

  一旦快照预留空间被写满（100% full），该快照将会失效（dropped）。因此快照通常用于一致性备份或短期维护。

  示例：

  ```shell
  # 为卷组 linux 中的 home 逻辑卷创建 5G 大小的快照卷 home_snap
  lvcreate -s -L 5G -n home_snap /dev/linux/home

  # 挂载只读快照进行数据备份
  mount -o ro /dev/linux/home_snap /mnt/snapshot

  # 恢复/合并快照（源卷需卸载，合并且自动删除快照）
  umount /mnt/snapshot /home
  lvconvert --merge /dev/linux/home_snap
  ```

- 修改

  警告: 并非所有文件系统都支持无损或/且在线（不卸载分区情况下）地调整大小。

  ```shell
  #容量变更
  #lvextend扩大逻辑卷容量 lvreduce缩小逻辑卷容量 用法均同下方lvresize
  
  #lvresize变更容量 -r(--resizefs）
  lvresize -r -L +2G <vg-name>/<lv-name> #增加2G
  lvresize -r -L -2G <vg-name>/<lv-name> #减少2G
  lvresize -r -L 10G <vg-name>/<lv-name> #新大小为10G
  lvresize -r -l +100%FREE <vg-name>/<lv-name>  #增加所有剩余空间 (+加号可省略）
  ```
  

注意：

> 如果在执行`lv{resize,extend,reduce}`时没有使用`-r, --resizefs`选项， 或文件系统不支持`fsadm(8)`（如[Btrfs](https://wiki.archlinux.org/index.php/Btrfs), [ZFS](https://wiki.archlinux.org/index.php/ZFS)等），则需要在缩小逻辑卷之前或扩增逻辑卷后手动调整文件系统大小。

```shell
  resize2fs <vg-name>/<lv-name>
```

警告：xfs分区不能缩小只能扩大，可以使用xfsdump备份数据，然后进行分区缩小操作，最后使用xfsrestore还原备份的数据。

- 物理区域pe

  在创建卷组 `vgcreate` 时可以使用 `-s`（或 `--physicalextentsize`）参数指定 PE 大小（默认为 4MB）。已创建的卷组也可使用 `vgchange -s` 修改。