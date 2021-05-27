# 查看分区blocksize

```shell
stat  <分区挂载点> 
```

在输出信息中可以看到IO block大小。

# df卡住

```shell
mount |column -t
```

找出可能引起卡死的挂载一般是nfs等网络挂载点，`strace`追踪：

```shell
strace df
```

卸载之：

```shell
umount -fl /mountedPoint  #mountedPoint换成实际挂载点
```

# text file busy

卸载分区或删除文件时提示：

>text file busy

```shell
fuser /path/to/file   #换成实际的文件路径
```

然后kill掉该进程