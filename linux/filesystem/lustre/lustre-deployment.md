# 安装准备

安装方式：

- 安装已编译的lutre二进制包，需要下载适合当前系统内核版本的安装包
- 从源码编译安装





# 安装

xx x



刚安装后，如果需要手动加载模块：

```shell
modprobe -v zfs
modprobe -v lustre
modprobe -v lnet
lsmod | grep {zfs,lustre,lnet}
```



# 组建lustre集群

- mgt
- mdt
- ost