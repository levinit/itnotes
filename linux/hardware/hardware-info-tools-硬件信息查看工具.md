

# Linux

## lspci 

查看pci设备

```shell
lspci
```



## dmidecode

DMI（Desktop Management Interface）就是帮助收集电脑系统信息的管理系统，DMI信息的收集必须在严格遵照SMBIOS规范的前提下进行。 SMBIOS(System Management BIOS)是主板或系统制造者以标准格式显示产品管理信息所需遵循的统一规范。SMBIOS和DMI是由行业指导机构Desktop Management Task Force (DMTF)起草的开放性的技术标准，其中DMI设计适用于任何的平台和操作系统。
```shell
dmidecode

#dmidecode -t <类型>
dmidecode -t   #查看所有可选择类型

dmidecode -t system  #SMBIOS data获取系统信息（如制造商，型号）

#内存
dmidecode -t memory

#内存条数量
dmidecode -t memory|grep -i Size|grep -vi No|wc -l

#总物理内存大小
dmidecode -t memory|grep -i Size|grep -vi No| awk '{sum += $2};END{print sum}'
```



## lshw

可以查看详细的硬件信息

```shell
lshw #查看所有硬件
lshw -short #-short 简略模式
lshw -c disk,storage -short  #-c 或 -class 显示指定类型
lshw -class cpu -short  #查看CPU cpu或processor
```



## hwloc、hwloc-ls 、lstopo-no-graphics 和 hwloc-gui

hwloc，haredware location list topology，General information about hwloc ("hardware locality")，输出硬件信息：

```shell
hwloc-info
```

hwloc-ls和lstopo-no-graphics是一样的，Show the topology of the system，用于显示硬件拓扑结构。

```shell
hwloc-ls
hwloc-ls --only pci   #只显示pci设备
hwloc-ls --only NUMANode
hwloc-ls --no-io      #不显示io设备
```

hwloc-gui是General information about hwloc ("hardware locality")，可输出硬件信息的结构图：

```shell
lstopo --of png > hardward-topology.png
```





# Windows

## aid64