# lxc容器无法联网

archlinux特权容器开启嵌套才可以联网，或者使用无特权容器。



# 挂载宿主机目录到lxc容器

注意：挂载的目录只能读。

然后按以下方法之一映射pve的目录到容器中：



命令行设置：

```shell
pct set <lxc-id> -mp<N> </path/in/pve>,mp=</path/in/container>
```



或者



编辑lxc配置文件：

`/etc/pve/lxc/<lxc-id>.conf`，加上：

```shell
lxc.mount.entry: /pve_mount_point  lxc_mount_point none rw,bind 0 0
```



如果需要用户映射：

获取lxc中用户的uid、gid（一般为1000，1000），获取PVE与LXC中uid、gid映射起始值
> cat /var/lib/lxc/your_lxc_id/config | grep idmap                                                                                   > 17:41.49 Wed Jan 26 2022 >>> 
> lxc.idmap = u 0 100000 65536
> lxc.idmap = g 0 100000 65536

mount命令中的uid、gid 等于 lxc 容器中uid、gid （即1000，1000）加上 pve与lxc映射值（即100000，100000）等于 101000，101000