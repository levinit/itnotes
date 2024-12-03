禁止windows挂载某个硬盘。

例如Linux+Windows双系统时，禁止Windows挂载文件系统为ext4的外置硬盘，避免因windows无法识别ext4而提示格式化硬盘，用户因此不慎格式化该硬盘。

1. 以管理员身份运行diskpar工具

2. 禁止自动挂

   ```shell
   automount disable
   #恢复 automount enable
   automount scrub  #删除此前连接的磁盘的驱动器号
   ```
