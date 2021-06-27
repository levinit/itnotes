

# update-alternatives

## 简介

创建、删除、维护和显示关于包含替代系统的符号链接的信息。

用于管理：

- 一个软件的多个版本的默认版本

  例如：系统中安装了gcc-7，gcc-9，`$PATH`中默认的`gcc`，如`/usr/bin/gcc`只可能为其中的一个gcc版本。

- 一个功能的多个实现的默认实现

  例如：系统中安装了多个编辑器，vim、nano、vi，而一些软件在编辑文件时会调用`$EDITOR`变量指向的某个编辑器如`vi`。

  

update-alternatives以权重来确定默认值，数值最大的为默认值，

update-alternatives本质上是通过建立两重软链接的方式工作的，其在shell命令与真正的执行程序间加入匹配层。例如一个系统中的editor可能是这样链接的：

> ```shell
> $ ls -l /usr/bin/editor
> lrwxrwxrwx 1 root root 24 Jan 10  2020 /usr/bin/editor -> /etc/alternatives/editor
> 
> $ ls -l /etc/alternatives/editor
> lrwxrwxrwx 1 root root 17 Jun 25 20:21 /etc/alternatives/editor -> /usr/bin/vim.tiny
> ```

在shell中键入``editor`会先找到`/etc/alternatives/editor`，然后找到`/usr/bin/vim.tiny`。

## 使用

设置默认链接：

```shell
#update-alternatives --install <link> <name> <path> <priority>

update-alternatives --install /usr/bin/gcc gcc gcc-7 50
```

- `<link>`    要创建的软连接的位置

- `<name>`    同一软件的不同版本或同一功能的不同实现公用的名字，例如gcc-7，gcc-9，一般将公用名字设置为gcc

- `<path>`    被软链接的文件的路径

- `<priority>`    优先级（权重）

  当前`<nam>`中权重值最高的才会成为默认的链接最终指向的源文件，相同则后install的覆盖为最新默认值。

  例如为每个`gcc-*`设置不同的权重，权重高的将成为默认的`gcc`。



设置指定项的各个版本的优先级：

```shell
# update-alternatives  --config <name>
update-alternatives  --config editor   #设置editor的优先级
```

移除指定项的相关链接：

```shell
#update-alternatives --remove <name> <path>
#update-alternatives --remove-all <name>     #移除所有

update-alternatives --remove gcc /usr/bin/gcc-7
```

查看指定项的各个版本的路径：

```shell
update-alternatives --diplay <name>
```



# environment Modules

environment module（以下简称modules或em），环境模块包是一个简化shell初始化的工具，允许用户在使用模块文件的会话期间轻松地修改他们的环境。 

每个模块文件都包含为应用程序配置 shell 所需的信息。模块文件可以由系统上的许多用户共享，并且用户可以拥有自己的集合来补充或替换共享模块文件。

modules可用于配置特定的使用环境，根据需要切换，可起到隔离环境，规避各种版本的冲突等。

例如安装了不同版本的编译或使用环境，每个版本可能存在不同的依赖，借助modules可轻松管理不同的环境，避免处理复杂的依赖关系以及繁琐的环境切换操作。



参看[modules-doc](https://modules.readthedocs.io/en/stable/INSTALL.html)通过包管理器或源码编译等方式安装。

## 使用

确保已经激活modules环境，在environment modules安装目录下找到init，根据不同的shell，source不同的脚本。

例如moudles安装在`/usr/share/modules`，装使用bash，则：

```shell
source /usr/share/modules/init/bash
```



### 常用命令

```shell
#查看所有可用环境模块文件
module avail  #module av #简写

#已经加载的模块
module list   #module li #简写

#加载模块
module load <module-nam>

#卸载模块
module unload <module-name>

#查看模块的描述信息
module whatis <module-name>
```

更多命令参看其帮助信息。



### 用户私有module

全局环境模块文件存放在安装目录下的modulefiles目录中，文件名字和`module list`中列出的一致。

用户自己的模块存放在`~/privatemodules`中，需要先加载`user.own`模块，然后即可加载用户私有module：

```shell
module load use.own  #如果不存在~/privatemodules则自动创建

module load <user own module-name>
```

加载`use.own`模块后，`~/privatemodules`加入到了`$MODULEPATH`和`$MODULEPATH_modshare`环境变量。

如果不想将模块文件存放到`~/privatemodules`，用户可以添加或修改`$MODULEPATH`值，加入其他自定的目录。



模块文件可以存放在模块目录下的子目录中，加载时需要写出相对路径。例如`~/privatemodules/mpi/mpi-4.0`，加载`module load mpi/mpi-4.0`。



## 编写module脚本

[module file](https://modules.readthedocs.io/en/stable/modulefile.html)使用tcl（Tool Command Language）编写，

module脚本文件示例：

```shell
#%Module -*- tcl -*-
## This is a module to access something

# 显示 module help 主要内容
proc ModulesHelp { } {
        puts stderr "This module sets up access to something" 
}

# 显示 module whatis 显示主要内容
module-whatis "sets up access to something"
# module 加载前需要模块类
prereq module_flag
# module 加载冲突模块类
conflict another_module_flag

# 加载其他模块
module load gcc
# 设置环境变量
setenv       SOMEVERION       0.95
# 添加环境变量
append-path  PATH             /home/[user]/[somedir]/bin
append-path  MANPATH          /home/[user]/[somedir]/man
append-path  LD_LIBRARY_PATH  /home/[user]/[somedir]/lib
```

