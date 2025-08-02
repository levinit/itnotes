# glibc简介

> glibc是GNU发布的libc[库](http://baike.baidu.com/view/226876.htm)，即c运行库。glibc是linux系统中最底层的api，几乎其它任何运行库都会依赖于glibc。glibc除了封装linux操作系统所提供的系统服务外，它本身也提供了许多其它一些必要功能服务的实现。
>
> libc是linux下的ANSI C函数库，被glibc包含。
>
> libstdc++ 是gcc的标准c++库



查看当前系统的glibc版本信息：

```shell
ldd --version

#查看glic API版本
strings /lib64/libc.so.6 | grep GLIBC
strings /lib64/libc.so.6 | grep -E "^GLIBC_" |sort -u
```



# 编译安装glibc

glibc为系统极为底层的运行库，自行编译覆盖系统glibc会影响大多数系统基本程序的使用，尤其是其中关键的二进制文件如`/lib/ld-linux.so`和 `/lib/libc.so.6`（不同发行版路径可能有差异）。

因自行编译安装而覆盖系统glibc引起问题，可参看[修复glibc](#修复glibc)。



如一些程序的运行需更高版本的glibc，应考虑选择其他方案解决的建议采用其他方案解决，例如：

- 使用系统的包管理器升级系统（如果可以的话，glibc及相关程序会一并升级）

- 使用符合glibc版本要求的容器运行程序

- 使用chroot或fakechroot构建合适的系统环境运行程序

- 如果程序提供源码

  - 使用源码在当前glibc版本的环境中进行编译

  - 对程序进行静态编译

    libstdc++可以静态编译，但是libc不行，如果程序没有依赖了glibc，可以考虑直接静态编译libstdc++。

    查看程序是否依赖了glibc：

    ```shell
    nm <bin-file> | grep GLIBC_
    ```

    

  - 打包glibc的so发布

    gcc使用如下参数指定动态连接器和动态库的装载目录：

    ```shell
    gcc -Wl,-rpath=/path/to/glibc,-dynamic-linker=I/path/to/ld-linux-x86-64.so.2
    ```

    编译后的程序和glibc的文件一并打包使用。

    - rpath：run-time search path，指定了可执行文件执行时搜索so文件的第一优先位置，一般编译器默认将该字段设为空。

      elf文件中还有一个类似的字段runpath，其作用与rpath类似，但搜索优先级稍低。搜索优先级：

      > ```shell
      > rpath > LD_LIBRARY_PATH > runpath > ldconfig缓存 > 默认的/lib,/usr/lib等
      > ```

      如果需要使用相对路径指定lib文件夹，可以使用 `ORIGIN`变量，其代指可执行文件所在的路径，如：

      ```shell
      gcc -Wl,-rpath='$ORIGIN/../lib'
      ```

    - interpreter

      全名elf interpreter，用于加载elf文件。一般默认为`/lib64/ld-linux-x86-64.so.2`。

      一些程序将interpreter的绝对路径`/lib64/ld-linux-x86-64.so.2`写在elf文件中，因此无论怎么设置rpath、LD_LIBRARY_PATH等均无效（可使用`ldd 程序名字`检查）。

      

- 如果只有程序的可执行文件，可使用pathelf打补丁

  1. 安装patchelf

  2. 执行程序时使用patchelf指定`--set-interpreter`和`--set-rpath`，示例：

     ```shell
     patchelf --set-rpath /path/to/glibc/lib  \
     --set-interpreter /path/to/glibc/lib/ld-linux-x86-64.so.2 \
     <program>
     ```

     

编译glibc

1. [下载glibc](https://ftp.gnu.org/gnu/libc/)

   *2.16及以下版本还需要在该页面下载glibc-ports*

2. 编译安装

   注意：configure要指定`--prefix`位置，避免新glibc覆盖系统glibc，且注意存放目录不应该设置到会覆盖系统LD_LIBRARY_PATH环境变量的情况。

   ```shell
   ver=2.18  #glibc版本
   dist=/usr/local/glibc-$ver  #glibc安装的路径
   
   tar -xJvf glibc-$ver.tar.xz 
   
   #tar -xvf glibc-ports-$ver.tar.xz         #2.16及以下版本需要
   #mv glibc-ports-$ver glibc-$ver/ports -f  #2.16及以下版本需要
   
   cd glibc-$ver
   
   mkdir build -p && cd build  #直接在源码目录configure会报错
   ../configure --prefix=$dist  
   
   make -j4 && make install
   
   #make localedata/install-locales   #2.16及以下版本需要执行避免locale问题
   #cp /etc/ld.so.conf $prefix/etc/  #2.16及以下版本需要执行
   
   make install
   
   strings $dist/lib/libc.so.6 | grep GLIBC
   ```

   

3. 指定环境变量

   以`export LD_LIBRARY_PATH`的方式临时加载新glibc环境变量：

   ```shell
   export PATH=$dist/bin:$PATH
   export LD_LIBRARY_PATH=$dist/lib:$LD_LIBRARY_PATH
   ```

   注意：

   - 不应当将以上内容写入到shell登录后自动加载的配置文件中

     如使用bash，不应当写到`/etc/profile.d/`下的`*sh`文件中。

   

   # 修复glibc

   直接升级系统的glibc会造成系统大多数命令的失效，不应当直接编译安装来覆盖系统自带的glibc（覆盖lib中的 `libc.so.6`等文件），

   

   如果误操作的主机是远程主机，千万不要退出SSH，否则再也登录不上去，因此建议在进行此类重要软件包升级前，先以tmux和screen之类的工具开启一个后台窗口备用。

   

   执行以下命令立即修复为旧版本的glibc：

   ```shell
   LD_PRELOAD=/lib64/libc-2.12.so   #根据系统中实际的libc版本修改
   
   #创建链接库
   #使用ln命令
   ln -sf /lib64/libc-2.12.so libc.so.6
   
   #或者使用ldconfig命令
   ldconfig -lv $LD_PRELOAD
   
   unset LD_PRELOAD  #去掉LD_PRELOAD
   ```

   这里的2.12应该以原来系统存在的glibc版本更改。

   

   # 问题

   - 执行date提示`Local time zone must be set--see zic `

     ```shell
     ln -sf /etc/localtime /usr/local/glibc-$ver/etc/localtime
     #echo "export LD_LIBRARY_PATH=$prefix/lib:\$LD_LIBRARY_PATH" > /etc/profile.d/glibc.sh
     ```