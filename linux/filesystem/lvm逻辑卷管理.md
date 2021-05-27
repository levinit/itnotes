# 概述

lvm, logic volume manager

> LVM利用Linux内核的[device-mapper](http://sources.redhat.com/dm/)来实现存储系统的虚拟化（系统分区独立于底层硬件）。它在[硬盘](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F)的[硬盘分区](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F%E5%88%86%E5%89%B2)之上，又创建一个逻辑层，以方便系统管理硬盘分区系统。

通过lvm可以实现存储空间的抽象化，建立虚拟分区（Virtual Partitions），轻松实现对虚拟分区的扩大和缩小操作。

特点：

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

## lvm组成

-  **物理卷Physical volume (PV)**：指硬盘分区，或硬盘本身，或者回环文件（loopback  file）。物理卷包括一个特殊的header，其余部分被切割为一块块物理区域（physical extents）。 
-  **卷组Volume group (VG)**：将一组物理卷收集为一个管理单元。
-  **逻辑卷Logical volume (LV)**：虚拟分区，由物理区域（physical extents）组成。
-  **物理区域Physical extent (PE)**：硬盘可供指派给逻辑卷的最小单位（通常为4MB）。

# lvm操作

## 分区流程

1. 创建物理卷pv
2. 创建卷组vg：卷组含有一个和多个物理卷
3. 创建逻辑卷lv：在卷组中创建逻辑卷
4. 使用逻辑卷：像普通分区一样使用逻辑卷，只是逻辑卷挂载位置不同，可使用以下两种方式：
   - `/dev/mapper/卷组名-逻辑卷名`   如`/dev/mapper/cent-swap`
   - `/dev/卷组名/逻辑卷名`  如`/dev/cent/swap`

```shell
#1 在sda和sdb创建pv
pvcreate /dev/sda /dev/sdb
#2 创建名为linux的卷组
vgcreate linux /dev/sda /dev/sdb
#3. 创建三个逻辑卷 root  swap  home
lvcreate -n root -L 30G linux
lvcreate -n swap -L 8G linux
lvcreate -n home -l 100%FREE linux
#4. 使用逻辑卷 在逻辑卷建立文件系统
mkfs.ext4 /dev/linux/root /dev/linux/home
mkswap /dev/mapper/linux-swap
```

## 常用命令

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

部分常用命令示例：

- 物理卷pv

  ```shell
  pvremove /dev/sda  #删除物理卷/dev/sda
  pvchange -x -u /dev/sda  #-x禁止分配PE -u生成uuid
  
  #扩增物理卷（可在线）：分区扩大后需要对物理卷扩增才能使用新增空间
  pvresize /dev/sda
  
  #缩小物理卷（可在线）：缩小分区前需要先缩小物理卷
  pvresize --setphysicalvolumesize 40G /dev/sda1
  ```

- 卷组vg

  ```shell
  vgextend <vg-name> /dev/sdc #扩充卷组 新加一个sdc物理卷
  vgrename <old-name> <new-name>  #卷组更名
  vgremove <vg-name> #删除卷组
  ```

- 逻辑卷lv
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

    lvm**快照**（snapshot）：创建快照即创建一个逻辑卷，在创建快照时使用`-s`或`--snapshot`参数即可。lvm快照

    > 使用了写入时复制(copy-on-write) 策略相比传统的备份更有效率。初始的快照只有关联到实际数据的inode的实体链接(hark-link)而已。只要实际的数据没有改变，快照就只会包含指向数据的inode的指针，而非数据本身。

    快照大小的设置主要根据日常和使用情况估量：

    - 块的改变量
    - 数据更新频率

    一旦快照可用空间使用完毕，该快照将被立刻被释放。因此在使用快照维护时，要保证在快照的一次生命周期里完成。

    示例：

    ```shell
    #创建带有5g快照空间的卷
    lvcreate -s 5G +100%FREE -n home linux
    #####恢复快照
    dd i=/dev/linux/home of=/path/to/
    ```

  - 修改

    警告: 并非所有文件系统都支持无损或/且在线（不卸载分区情况下）地调整大小。

    ```shell
    #容量变更
    #lvextend扩大逻辑卷容量 用法同下方lvresize
    #lvreduce缩小逻辑卷容量 用法同下方lvresize
    
    #lvresize变更容量 -r(--resizefs）
    lvresize -r -L +2G <vg-name>/<lv-name> #增加2G
    lvresize -r -L -2G <vg-name>/<lv-name> #减少2G
    lvresize -r -L 10G <vg-naem>/<lv-name> #新大小为10G
    lvresize -r -l +100%FREE <vg-naem>/<lv-name>  #增加所有剩余空间 (+加号可省略）
    ```

    注意：

    > 如果在执行`lv{resize,extend,reduce}`时没有使用`-r, --resizefs`选项， 或文件系统不支持`fsadm(8)`（如[Btrfs](https://wiki.archlinux.org/index.php/Btrfs), [ZFS](https://wiki.archlinux.org/index.php/ZFS)等），则需要在缩小逻辑卷之前或扩增逻辑卷后手动调整文件系统大小。

    ```shell
    resize2fs <vg-naem>/<lv-name>
    ```

    警告：xfs分区不能缩小只能扩大，可以使用xfsdump备份数据，然后进行分区缩小操作，最后使用xfsrestore还原备份的数据。

- 物理区域pe

  在使用`pvcreate`和`vgcreate`时使用`-s`参数指定pe大小。