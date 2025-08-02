参看https://wiki.archlinux.org/title/Archiso



1. 安装archiso包

2. 复制模板配置

   `/usr/share/archiso/configs`下有两个模板目录：

   - baseline  最小archlinux livecd iso配置
   - releng  每月构建的archlinux livecd iso配置

   ```shell
   cp -r /usr/share/archiso/configs/baseline/ archlive
   ```

   

3. 各种自定义操作

   例如：

   - 修改root密码

     ```shell
     #例如设置root密码为root
     echo "root:$(echo root |openssl passwd -6 -stdin):14871::::::" > archlive/airootfs/etc/shadow
     ```

4. 构建archiso

   ```shell
   mkarchiso -v archlive #-o ./archlinux-2024.12.12-x86_64.iso
   ```

   如不指定`-o`，将默认生成iso到out目录中。



---

tips:

- archlinux live iso会默认启动sshd
- 如果在本地网络中安装archlinux，可使用`ssh root@archiso.local`访问

