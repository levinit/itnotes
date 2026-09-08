#  Environment Modules System 环境模块系统

> 模块文件系统是用于动态管理用户环境变量的工具，允许用户在不同的环境之间切换，而无需手动修改环境变量。它通常用于高性能计算（HPC）集群和其他需要管理多个软件版本和依赖关系的场景。

常用对实现

- [environment modules](https://envmodules.github.io/modules/)（简称modules或em）是一个基于TCL的模块系统。

- [Lmod](https://lmod.readthedocs.io/)是一个基于Lua并兼容environment modules的TCL模块系统。


# 安装配置

参看各自的文档安装。

## 激活环境

无论是environment modules还是Lmod，在其安装目录下都有一个`init`目录，里面有不同shell的初始化脚本，确保shell总是加载某个初始化脚本。

以下`modules`泛指environment modules和Lmod。

例如：将init中的初始化脚本复制到`/etc/profile.d`目录下，又或者在`/etc/profile.d`目录下创建一个脚本文件载入要加载的初始化脚本。

```shell
inst_dir=/path/to/modules_install_dir
source $inst_dir/init/profile.sh  #modules
source $inst_dir/init/profile     #lmod

#加载profile或者profile.sh无需考虑当前shell类型，但是它们加载耗时更多，如果希望更快加载，可以直接加载当前shell的初始化脚本，如bash/zsh等
source $inst_dir/init/$shell      #可使用环境变量$shell来对应特定文件
```

注意：不使用`profile`或`profile.sh`，而是直接加载当前shell的初始化脚本时，modules安装目录内置的modulefiles目录不会被添加到`$MODULEPATH`（具体参看下面关于配置MODULEPATH的章节）中，因此需要手动添加。

```shell
export MODULEPATH=$MODULEPATH:$inst_dir/modulefiles       #对于environment modules
export MODULEPATH=$MODULEPATH:$inst_dir/modulefiles/Core  #对于Lmod
```

environment modules内置了`dot`、`null`、`module-info`、`module-git`等模块文件，例如`dot`模块文件可以用于加载当前目录下的modulefile。

Lmod的`Core`目录下有`lmod`等模块文件，例如`lmod`模块文件提供了`update_lmod_system_cache_files`命令用于更新Lmod的系统缓存文件。


## 配置MODULEPATH

`MODULEPATH`环境变量用于指定模块文件的搜索路径。

可直接设置`$MODULEPATH`环境变量，例如：

```shell
export MODULEPATH=$MODULEPATH:/share/config/modulefiles
```

也可以使用`module use`命令来添加目录到`MODULEPATH`中，`module unuse`命令可以从`MODULEPATH`中移除目录。

  ```shell
  # -a: append，添加到MODULEPATH末尾
  # -p: prepend，添加到MODULEPATH开头
  # module use [-a | -p] <dir-path1[, dir-paht2]> 

  module use -p /tmp/test1 /tmp/test2
  
  #从MODULEPATH环境变量移除某个module files 目录
  module unuse <dir-path1[, dir-paht2]>
  ```

注意：目录路径最后不要添加`/`

另外一些软件包如openmpi、gcc可能也自带modulefile，通过包管理器安装这些软件时，通常会自动将其modulefile目录添加到系统的`MODULEPATH`中（如`/usr/share/modulefiles`），如果要使用这些module，要确认系统的modulefiles目录是否在`MODULEPATH`中（如可能修改时将其删除了）。


## 用户私有modulefiles目录

在Environment Modules中，内置了一个`use.own`模块，用户可以使用它来管理自己的私有modulefiles目录（通常是`~/privatemodules`目录，具体可以使用`module show use.own`命令查看）。


```shell
module load use.own  #如果不存在~/privatemodules则自动创建

module load <user own module-name>  #加载在用户的module
```

加载`use.own`模块后，`~/privatemodules`加入到了`$MODULEPATH`和`$MODULEPATH_modshare`环境变量。


用户也可以手动创建自定义的modulefiles目录，只要将其添加到`MODULEPATH`中即可。


# 常用命令

**Lmod中提供了`module`命令对简写`ml`，下面的`module`命令在Lmod均可使用`ml`代替。**

```shell
#查看所有可用环境模块文件
module avail  #module av #ava #av ava均是简写
#ml av        #lmod

#已经加载的模块
module list   #module li #简写
#ml           #lmod的ml相当于执行module list

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


# 编写模块文件

Lmod读取模块文件时，会忽略文件名中的后缀如`.lua`或`.tcl`，如`module111.lua`或`module111.tcl`在使用该模块时，其模块名不包含后缀名，但是Environment Modules不会忽略后缀名。

Lmod兼容Environment Modules的TCL脚本，但它在执行时会将TCL脚本转换为Lua脚本，因此会耗时更多。


## tcl编写Environment Modules模块

Environment Modules的[modulefile](https://modules.readthedocs.io/en/stable/modulefile.html)使用tcl（Tool Command Language）编写，脚本第一行需要为`#%Module`才会被识别为module file。

示例：

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

# 与本模块冲突的模块
conflict another_module_flag

# 加载本模块需要的模块，如果没有加载需要的模块，则不能加载本模块
prereq module_flag

# 加载本模块需要给定的模块中的任意一个即可
prereq-any "module_flag1" "module_flag2"

# 加载本模块需要的模块，将自动加载
depends_on module_flag

# 也可以在当前模块中load其他模块，不过一般建议用depends_on
module load gcc
# 加载给定的模块列表中的一个
module load-any gcc/10 gcc/11

# 声明当前模块文件所属的“家族”，加载当前模块会卸载其他属于同一family的模块
family app1

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

## Lua编写Lmod模块

Lmod的[modulefile](https://lmod.readthedocs.io/en/latest/010_user.html)使用Lua编写。

参照上面对Environment Modules的TCL脚本，以Lua编写如下：

```lua
-- Lua使用--注释，模块文件顶部无需 #%Module 之类对标记

-- 显示消息，当模块加载时
if (mode() == "load") then
    io.stderr:write("hi!\n")
    io.stderr:write("ok echo $PATH\n")
end

-- 显示 module help 内容
help([[
This module sets up access to something
]])

-- 显示 module whatis 显示主要内容 可以多行
whatis("this is app1")
whatis("version： 1.0")

-- 声明当前模块文件所属的“家族”，加载当前模块会卸载其他属于同一family的模块
family("app1")

-- 于当前模块冲突的模块
conflict("another_module_flag")

-- 加载本模块需要的模块，如果没有加载需要的模块，则不能加载本模块
prereq("module_flag")

-- 加载本模块需要给定的模块中的任意一个即可
prereq_any("module_flag1", "module_flag2")

-- 加载本模块需要的模块，将自动加载
depends_on("module_flag")

-- 也可以在当前模块中load其他模块，不过一般建议用depends_on
load("gcc")
-- 加载给定的模块列表中的一个
load_any("gcc/10", "gcc/11")

-- 设置局部变量
local version = "1.1"
local appdir = "/path/to/dir"

-- 设置环境变量
setenv("ENV1", "env_value")

-- 添加环境变量 prepend_path（加在已有PATH前）或者append_path（加载已有PATH后）
prepend_path("PATH", "/path/to/bin")
append_path("MANPATH", pathJoin(appdir, "share/man"))
prepend_path("LD_LIBRARY_PATH", pathJoin(appdir, "lib"))

-- 在module file中载入shell script
source_sh("bash", "/path/to/shell-script-file.sh")
```

注意： Lmod中的`source_sh`载入shell脚本要求该脚本返回状态码必须是0才能成功载入，否则会报错并中止加载模块（Environment Modules不会中止加载模块）。


## 设置目录中默认的模块文件


如果一个目录中包含多个modulefile文件，并希望载入该目录时自动加载一个默认的modulefile文件的场景。


对于Lmod，将要设置为默认的modulefile文件在同级目录中创建一个名为`default`的软连接即可：
```shell
ln -s <modulefile> default
```

对于Environment Modules，创建一个`.version`的modulefile文件，其中有`set ModulesVersion xx`，其中`xx`对应默认modulefile文件中的`version`变量值。

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



## 转换shell为modulefile

environment modules 4.6版本新增的`sh-to-mod`模块，可以将shell转换为module file文件。

```shell
#module sh-to-mod <shell>  <shell script file> [args] > module-file
module sh-to-mod bash example/source-script-in-modulefile/foo-1.2/foo-setup.sh arg1 >modulefiles/foo/1.2
```

Lmod的`sh-to-mod`模块也可以使用。