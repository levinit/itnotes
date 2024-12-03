问题：windows挂载网络存储并映射到某个盘符，虽然在资源管理器里面能够看到并打开这个盘符，但是某些软件可能找不到这个盘符号。

​	例如在windows中挂载了smaba服务器的share文件夹到s盘，在某软件中想使用s盘中的文件，但是却找不到s盘。

解决方法：

- 关闭UAC
  1. 打开注册表（regedit），定位到`HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System`。
  1. 找到`EnableLUA` ，将`Value data`的值改成`0`。
  1. （如果还不能找到，再）重启系统。