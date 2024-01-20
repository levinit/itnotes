#  Environment Modules

environment module（以下简称modules或em），环境模块包是一个简化shell初始化的工具，允许用户在使用模块文件的会话期间轻松地修改他们的环境。 

每个模块文件都包含为应用程序配置 shell 所需的信息。模块文件可以由系统上的许多用户共享，并且用户可以拥有自己的集合来补充或替换共享模块文件。

modules可用于配置特定的使用环境，根据需要切换，可起到隔离环境，规避各种版本的冲突等。

*例如安装了不同版本的编译或使用环境，每个版本可能存在不同的依赖，借助modules可轻松管理不同的环境，避免处理复杂的依赖关系以及繁琐的环境切换操作。*



参看[modules-doc](https://modules.readthedocs.io/en/stable/INSTALL.html)通过包管理器或源码编译等方式安装。



## module使用

### 激活环境

确保已经激活modules环境，在environment modules安装目录下找到init，根据不同的shell，source不同的脚本，位于安装目录中下子目录`init`中的shell文件即可载入module，例如使用bash，可以：

```shell
source /usr/share/Modules/init/profile.sh #或.bash 或.csh 等等
```

*编译时也可以使用`--modulefilesdir`（默认在`PREFIX/modulefiles`）指定默认的modulefiles目录*。



### 常用命令

```shell
#查看所有可用环境模块文件
module avail  #module av #ava #av ava均是简写

#已经加载的模块
module list   #module li #简写

#加载模块 load 或 add
module load <module-name>
#对于不在module avi列表的模块，可指定其路径即可
module load </path/to/module-file>

#刷新已经载入的module中的所有非持久组件
module refresh
#刷新所有已经载入模块（会先unload然后load）
module reload

#卸载模块 unload 或 remove
module unload <module-name>
#对于不在module avi列表的模块，指定其路径即可

#切换到同一目录下的其他modulefile
#例如在gcc目录有11和10两个module，从当前的10切换到11
module switch gcc/11

#清空所有已经加载的module （清空module list）
module purge

#查看模块的描述信息
module whatis <module-name>
#对于不在module avi列表的模块，指定其路径即可
```



### 添加modulefiles目录

modules自带的模块文件在`/usr/share/Modules/modulefiles`（不同发行版可能略有差异）；而一些软件安装后会可能自动添加modules模块文件到`/etc/modulefiles`，这些一般无需自行编写模块，例如openmpi，使用`module avi`可看到新增了模块。

> ```shell
> $ module ava
> ---------------- /usr/share/Modules/modulefiles -----------------
> dot     module-git module-info modules   null    use.own
> ----------------- /etc/modulefiles ------------------------------
> mpi/openmpi3-x86_64
> ```



如果想自行增加其他目录到`module avail`列表中，可以：

- 添加该目录到`$MODULEPATH` 中，例如：

  ```shell
  export MODULEPATH=$MODULEPATH:/share/config/modules
  ```

- 使用module use添加modulefiles目录：

  ```shell
  #Prepend  one  or  more  directories  to  the   MODULEPATH environment  variable.
  #The -a flag will append the directory to MODULEPATH.
  #The -p flag will prepend the directory to MODULEPATH.
  module use [-a | -p] <dir-path1[, dir-paht2]>
  module use -p /tmp/test1 /tmp/test2
  
  #从MODULEPATH环境变量移除某个module files 目录
  module unuse <dir-path1[, dir-paht2]>
  ```
  
  注意：目录路径最后不要添加`/`



### 用户私有modulefiles目录

除了使用上面的`module use`或设置`$MODULEPATH`环境变量实现增加modulefiles目录，用户还使用自带的`use.own`模块。

`use.own`模块的目录一般在`~/privatemodules`中，加载`user.own`模块，然后即可加载用户私有module：

```shell
module load use.own  #如果不存在~/privatemodules则自动创建

module load <user own module-name>  #加载在用户的module
```

加载`use.own`模块后，`~/privatemodules`加入到了`$MODULEPATH`和`$MODULEPATH_modshare`环境变量。



*如果不想将模块文件存放到`~/privatemodules`，用户可以修改`/usr/share/Modules/modulefiles/use.own`文件中的`ownmoddir`行中的变量。*



## 编写module脚本

[module file](https://modules.readthedocs.io/en/stable/modulefile.html)使用tcl（Tool Command Language）编写，脚本第一行需要为`#%Module`才会被识别为module file。

module脚本文件module1示例：

```shell
#%Module ----本行必须包含#%Module字样
## This is a module to access something

# show messages while module load 
if [ module-info mode load ] {
    puts stderr "hi! "
    puts stderr "ok echo \$PATH"
}

# 显示 module help 内容
proc ModulesHelp { } {
        puts stderr "This module sets up access to something" 
}

# 显示 module whatis 显示主要内容
module-whatis "sets up access to something"

# module 冲突模块类
conflict another_module_flag

# module 加载前需要模块类
prereq module_flag
# 加载本模块时，附加加载的其他模块
module load gcc

# 设置局部变量
set version 1.1
set appdir /path/to/dir

# 设置环境变量
setenv        ENV1            env_value       

# 添加环境变量 append-path（加载已有PATH后）或者prepend-path（加在已有PATH前）
prepend-path  PATH             /path/to/bin
append-path   MANPATH          $appdir/share/man
prepend-path  LD_LIBRARY_PATH  $appdir/lib

#在module file中载入shell script（需要module 4.6+）
source-sh bash /path/to/shell-script-file.sh
```



## 设置目录中默认的module file

如果希望载入包含多个modulefile文件的目录中的默认文件，可在该目录的每个modulefile中添加一个version变量并赋予不同的值，例如：`set version v1.1`，然后在该目录中创建一个`.version`的modulefile文件，文件中以`set ModulesVersion xx`的值`xx`对应默认modulefile文件中的`version`变量值。

最常用的场景是当存在多个版本的情况是，无需指定具体的module，载入默认的软件版本的modulefile。



例子：

当前在gcc目录下有两个modulefile文件，gcc11和gcc10：

> ```shell
> [root@localhost ~]# ls -1 gcc
> 10
> 11
> [root@localhost ~]# module ava
> ------- /share/config/modulefiles ------
> gcc/10 gcc/11
> ```

在modulefile文件中添加一个名为version的本地变量，在11文件添加`set version 11`，在10文件添加`set version 10`，在gcc目录中创建一个`.version`文件，内容为：

```tcl
#%Module
#ModulesVersion的值为希望默认载入的modulefile中version变量的值
set ModulesVersion 11
```

配置完毕后，使用者只需要执行`module load gcc`即等于`module load gcc/11`。



## sh-to-mod转换shell为module file

module 4.6版本新增的sh-to-mod模块，可以将shell转换为module file文件。

```shell
#module sh-to-mod <shell>  <shell script file> [args] > module-file
module sh-to-mod bash example/source-script-in-modulefile/foo-1.2/foo-setup.sh arg1 >modulefiles/foo/1.2
```



## 在module file中载入shell script

module 4.6版本新增source-sh功能可以在module文件中载入shell文件：

```tcl
#%Module

source-sh bash /path/to/shell-script-file.sh
```
