

# 硬盘offline



# 扇区故障bad sector

查看分区blocksize

```shell
stat  <分区挂载点> 
```

在输出信息中可以看到IO block大小。

# df或ls卡住

df卡住一般是网络文件系统挂载问题，查找原因：

```shell
mount |column -t
cat /etc/mtab
strace df
fuser <挂载点>
```

ls卡住多在出问题的挂载目录中出现，尝试：

```shell
strace ls -l
unalias -a && ls -1 
```



解决：

- 检查网络文件系统服务端情况

- 卸载挂载点

  ```shell
  umount -fl /mountedPoint  #mountedPoint换成实际挂载点
  ```

  



# device / target is busy

卸载分区或目录时提示：

> umount: /mountedPoint: target is busy. (In some cases useful info about processes that use the device is found by lsof(8) or fuser(1))

排查占用挂载点的进程：

```shell
fuser -vm /mountedPoint   # 查看占用该挂载点的进程和 PID
# 或者
lsof +D /mountedPoint
```

然后确认并终止占用进程，或必要时执行 lazy 卸载：

```shell
umount -l /mountedPoint
```

# Text file busy

修改、覆写正在运行的可执行程序文件，或执行正在被写入的文件时提示：

> bash: ./app: Text file busy

排查占用该程序的进程：

```shell
fuser -v /path/to/file   # 换成实际的文件路径
```

然后停止该进程，或先删除/移动原可执行文件（unlink），再放入新编译的二进制文件（因为正在运行的 inode 仍被进程持有，新文件会分配新 inode）。