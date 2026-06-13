# Linux文件类型

在`ls -l`中第1位字符表示文件类型，各种类型如下： 

- `-`  普通文件(common file)
  -  文本文件（如/etc/hosts）
  -  二进制文件（如/usr/bin/ls）
  -  数据格式文件（如/var/logwtmp）
- `d`  目录(directory)文件
- `l`  符号链接(link)
- 设备与装置
  - `b`  块（block）设备（如/dev/sda）
  - `c`  字符（character）设备 （如鼠标键盘等串行端口设备）
- s  套接字(sockets)文件（数据接口文件）
- `p`  管道(pipe)文件（ FIFO——first-in-first-out，解决多个程序同时存取一个文件所造成的错误问题）



file命令可以查看更为详细的文件类型信息

```shell
file ~/.bashrc  #文件类型信息
file -i ~/.bashrc  #mime类型和编码格式
file --mime-type ~/.bashrc  #mime类型
file --mime-encoding ~/.bashrc  #mime编码格式
```



stat 查看文件各项信息

```shell
stat ~/.bashrc
stat  --format %s .bashrc  #获取文件大小（单位bytes)
stat .bashrc --format %u:%g   #文件所属用户名(%u)及用户组(%g)的id
stat .bashrc --format %U:%G  #文件所属用户名及用户组的名字
```

