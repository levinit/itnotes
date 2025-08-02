# 分区准备

- /dev/nvme0n1p1  EFI 分区      512M

  ```shell
  mkfs.fat32 /dev/nvme0n1p1  #！如果要保留已有系统的efi，不要格式化
  ```

- /dev/nvme0n1p2   swap分区   可选，大小例如8G

  ```shell
  mkswap dev/nvme0n1p2
  ```

  

- /dev/nvme0n1p13  btrfs分区    系统和数据

  ```shell
  mkfs.btrfs [-m <meta-data-profile>] [-L <lable-name>] /dev/nvme0n1p3
  
  mkfs.btrfs /dev/nvme0n1p3
  ```



# 创建btrfs子卷

1. 将btrfs分区挂载到/mnt

   ```shell
   mount -o compress=zstd /dev/nvme0n1p3 /mnt
   ```

2. 使用`btrfs subvolume create /mnt/<name>`创建子卷

   一般name以`@` 开头，也可使用单个`@`字符作为卷名

   ```shell
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   btrfs subvolume create /mnt/@log
   btrfs subvolume create /mnt/@cache
   
   #使用 chattr 忽略无需写时复制的子卷
   chattr +C /mnt/@log
   chattr +C /mnt/@cache
   chattr +C /mnt/@tmp
   chattr +C /mnt/@dev
   
   btrfs subvol list /mnt  #subvol简写等同于subvolume
   #删除示例
   #btrfs subvolume delete /mnt/@xxx
   
   umount -fl /mnt  #创建完毕后卸载/mnt以进行后续操作
   ```
   
   子卷规划：
   
   | subvolume | 在系统的挂载点 | 附注                             |
   | --------- | -------------- | -------------------------------- |
   | @         | /              | 根分区                           |
   | @home     | /home          |                                  |
   | @log      | /var/log       | 日志                             |
   | @cache    | /var/cache     | 缓存目录，包缓存默认也在该目录下 |
   
   # 挂载分区
   
   ```shell
   
   #1. 根分区 @root子卷
   mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@ /dev/nvme0n1p3 /mnt
   
   #2. EFI
   mkdir -p /mnt/boot/efi  #EFI分区挂载点
   mount /dev/nvme0n1p1 /mnt/boot/efi
   
   #3. swap （如有）
   swapon /dev/nvme0n1p2
   
   #4.1 创建subvolume的挂载点
   mkdir /mnt/home
   mkdir -p /mnt/var/log
   mkdir -p /mnt/var/cache
   
   #4.2 挂载subvolume
   mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@home /dev/nvme0n1p3 /mnt/home
   
   mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@logs /dev/nvme0n1p3 /mnt/var/log
   
   mount -o noatime,nodiratime,ssd,compress=zstd,subvol=@cache /dev/nvme0n1p3 /mnt/var/cache
   
   #...依次挂载完毕
   
   lsblk #查看
   ```
   
   
   
   # 辅助工具
   
   - snapper
   - 