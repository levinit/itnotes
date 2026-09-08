

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

  



# text file busy

卸载分区或删除文件时提示：

>text file busy

```shell
fuser /path/to/file   #换成实际的文件路径
```

然后kill掉该进程