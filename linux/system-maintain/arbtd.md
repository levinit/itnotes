

`'abrt-cli status' timed out`，检查：

```shell
systemctl status abrtd

ls -l ~/.cache/abrt  #是否属于当前用户
chown -R $USER ~/.cache/abrt
```



关闭abrt服务：

```shell
systemctl disable --now abrtd abrt-oops
```



配置优化abrt日志空间占用：

```shell
#限制ABRT日志总空间占用，以MB为单位。超过限制则自动删除旧日志
MaxCrashReportsSize = 256
#是否记录非应用包中的执行指令的错误信息
ProcessUnpackaged = no
#是否在dump中包含完整的二进制镜像信息
SaveBinaryImage = no
```

