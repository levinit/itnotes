

# lspci 



# dmidecode

DMI（Desktop Management Interface）就是帮助收集电脑系统信息的管理系统，DMI信息的收集必须在严格遵照SMBIOS规范的前提下进行。 SMBIOS(System Management BIOS)是主板或系统制造者以标准格式显示产品管理信息所需遵循的统一规范。SMBIOS和DMI是由行业指导机构Desktop Management Task Force (DMTF)起草的开放性的技术标准，其中DMI设计适用于任何的平台和操作系统。



# lshw

```shell
lshw #查看所有硬件
lshw -short #-short 简略模式
lshw -class disk,storage -short  #-class 显示指定类型
lshw -class cpu -short  #查看CPU cpu或processor
```



# aid64