# 修复glibc

手动编译升级glibc以替换原有glibc为默认版本，一定要慎重。如无绝对必要，不要升级替换。

> glibc是GNU发布的libc[库](http://baike.baidu.com/view/226876.htm)，即c运行库。glibc是linux系统中最底层的api，几乎其它任何运行库都会依赖于glibc。glibc除了封装linux操作系统所提供的系统服务外，它本身也提供了许多其它一些必要功能服务的实现。由于
> glibc 囊括了几乎所有的 UNIX 通行的标准，可以想见其内容包罗万象。

特别是 libc.so.6这个文件一旦误删除或变更，系统大部分命令都将失效。

*如果误操作的主机是远程主机，千万不要退出SSH，否则再也登录不上去，因此建议在进行此类重要软件包升级前，先以tmux和screen之类的工具开启一个后台窗口备用。*

执行以下命令立即修复为旧版本的glibc：

```shell
LD_PRELOAD=/lib64/libc-2.12.so
ln -sf /lib64/libc-2.12.so libc.so.6
unset LD_PRELOAD  #去掉LD_PRELOAD
```

这里的2.12应该以原来系统存在的glibc版本更改。



# 编译安装glibc

重要：

- glibc为系统极为底层的运行库，更新glibc可能影响到系统的正常运行，可以考虑选择其他方案解决的建议采用其他方案解决，例如：
  - 升级系统。
  - 使用虚拟机或者容器技术。
  - 在高版本的系统中使用静态编译，将所有依赖包一并打包放到低版本系统中使用。

- 如果误操作请不要退出终端，如果误操作的主机是远程主机，千万不要退出登录，否则可能再也登录不上去。 

  例如将新的glibc写入了ldconfig 中以默认启用代替原有glibc，但是操作有误，导致后续登录总是无法读取到正确的libc.so文件，无法再登录系统。

- 建议在进行此类重要软件包升级前，先以tmux和screen之类的工具开启一个后台窗口备用。

- 误操作或出现问题，保持终端开启，立即参照[修复glibc](#修复glibc)或其他资料修复。



查看当前glibc版本

```shell
strings /lib64/libc.so.6 | grep GLIBC
```



2. [下载glibc](https://ftp.gnu.org/gnu/libc/)

   2.16及以下版本还需要在该页面下载glibc-ports。

2. 编译安装

   最好要指定新glibc的安装位置，以免错误操作，导致原有glibc被覆盖。

   ```shell
   ver=2.18  #glibc版本
   dist=/usr/local/glibc-$ver  #glibc安装的路径
   
   tar -xJvf glibc-$ver.tar.xz 
   
   tar -xvf glibc-ports-$ver.tar.xz         #2.16及以下版本需要
   mv glibc-ports-$ver glibc-$ver/ports -f  #2.16及以下版本需要
   
   cd glibc-$ver
   mkdir build -p
   cd build
   ../configure --prefix=$dist
   make -j4 && make install
   
   #make localedata/install-locales   #2.16及以下版本需要执行避免locale问题
   #cp /etc/ld.so.conf $prefix/etc/  #2.16及以下版本需要执行
   
   make install
   ```

3. 配置

   1. 检查原先的libc版本

      ```shell
      ls -l  /lib64/libc.so.6
      oldlibc=$( ls -l  /lib64/libc.so.6|cut -d ">" -f 2)
      echo $oldlibc
      ```
      
   2. 启用新glibc的库并进行检查

      先以`export LD_LIBRARY_PATH`的方式临时加载新glibc环境变量：

      ```shell
      export PATH=$dist/bin:$PATH
      export LD_LIBRARY_PATH=$dist/lib:$LD_LIBRARY_PATH
      
      #检查当前libc路径
      ldconfig -p |grep libc.so
      strings $dist/lib/libc.so.6 | grep GLIBC
      ```

      尝试一些命令 如`cp`  `w` 等是否正常。

      如果需要将新glibc默认启用，尤其需要慎重检查后才能退出。

      建议在进行这类操作前确保已经开启其他已登入的备用连接方式（例如新开一个ssh会话）。

   

   # 问题

   - 执行date提示`Local time zone must be set--see zic `

     ```shell
     ln -sf /etc/localtime /usr/local/glibc-$ver/etc/localtime
     #echo "export LD_LIBRARY_PATH=$prefix/lib:\$LD_LIBRARY_PATH" > /etc/profile.d/glibc.sh
     ```

     

   