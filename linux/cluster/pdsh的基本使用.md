# 安装

- 从源安装（以yum安装为例）

  ```shell
  #yum安装确保已经安装epel源，pdhs位于该源中
  yum install epel-release
  yum install pdsh
  #不同发行版打包不同，rhel/centos中pdsh的相关mod单独打包
  #pdsh-mod-dshgroup.x86_64 : Provides dsh-style group file support for pdsh
  #pdsh-mod-genders.x86_64 : Provides libgenders support for pdsh
  #pdsh-mod-netgroup.x86_64 : Provides netgroup support for pdsh
  #pdsh-mod-nodeupdown.x86_64 : Provides libnodeupdown support for pdsh
  #pdsh-mod-torque.x86_64 : Provides support for running pdsh under Torque jobid
  #pdsh-rcmd-rsh.x86_64 : Provides bsd rcmd capability to pdsh
  #pdsh-rcmd-ssh.x86_64 : Provides ssh rcmd capability to pdsh
  ```

- 编译安装

  下载[pdsh编译](https://github.com/chaos/pdsh/releases)。常用的几个编译选项：

  ```shell
  bash bootstrap
  ./configure --prefix=/usr/local/pdsh --with-ssh --with-exec  machines=/path/to/machines --with-dshgroups --with-timeout=15 --with-readline
  ```
  
  - `--with-ssh`  ssh模块（支持ssh）
  
  - `--with-dshgroups`  支持dsh风格的主机分组
  
  - `--with-machines=</path/to/file>`  主机列表文件路径
  
    在该文件中写入主机地址（或主机名——需要在hosts中写好主机解析），每行一个。
  
    存在machines文件，使用`pdsh`执行时若不指定主机，则默认对machines文件中所有主机执行该命令。
  
  - `--with-exec`  exec模块
  
  - `--with-timeout`  超时，默认10s
    
  - `--with-nodeupdown`  节点宕机功能
    
  - `--with-readline`	支持交互式输入模式 双击tab自动补全
  
  
  具体可参看[文档](https://github.com/chaos/pdsh)。

# 使用

## 命令介绍

一条pdsh命令分为三部分：`pdsh` + `参数` + `并行执行的命令`。

参数部分不一定是必须的，该部分中一般会指定要执行的命令的主机信息。

如果只输入前面两部分，回车后可进入pdsh交互式命令行（若是编译安装需要启用`--with-readline`），再输入并行执行的命令部分，如：

```shell
pdsh -w 192.168.0.[1-9]  #回车后进入交行命令行
```



常用参数：

- `-w`  指定主机 `-x`  排除指定的主机

  目标主机可以使用Ip地址或主机名（确保该主机名已经在`/etc/hosts`中存在解析）

  多个主机之间可以使用逗号分隔，可重复使用该参数指定多个主机；可以使用简单的正则（参看下面的示例）。

- `-g`  指定主机组 `-X`  排除指定主机组

- `-l <username` 目标主机的用户名

  如果不指定用户名，默认以当前用户名作为在目标主机上执行命令的用户名。

  *例如：当前执行pdsh的用户为root，则以root用户在目标主机上执行命令*。

- `-t <seconds>`  超时时间（单位：秒）

- `-N` 用来关闭目标主机所返回值前的主机名显示。

- `-b`  禁止<kbd>Ctrl</kbd><kbd>c</kbd>特性，使用该选项和，按下<kbd>Ctrl</kbd><kbd>c</kbd>将kill所有并行的任务。



## 环境变量

重要环境变量（参看`man pdsh`）

- `DSHGROUP_PATH`  分组主机列表文件存放目录

- `WCOLL`  默认主机列表文件路径

- `PDSH_RCMD_TYPE`  同`-R`选项，设置rcmd模块，默认为rsh，可以设置为ssh

  ```shell
  export PDSH_RCMD_TYPE=ssh
  ```

- `PDSH_SSH_ARGS`  设置ssh参数

- `PDSH_SSH_ARGS_APPEND`  设置追加的ssh参数（如ssh的`-q`参数）

- `DPATH`  设置远程主机的`PATH`变量

  


## 主机列表文件

主机列表文件包含一个或多个主机信息，当存在该文件时，直接使用`pdsh`命令而不指定主机列表，将默认指定主机列表中的主机执行后续命令。

注意：如果是编译安装，需要`--with-machines`启用该功能并指定主机列表文件路径。

`WCOLL`环境变量也设置主机列表文件路径：

```shell
[ -r ~/pdsh/nodes ] && export WCOLL=~/pdsh/nodes
```


主机列表文件示例：

```shell
c[01-11]
c11
```



使用示例：


```shell
pdsh hostname　                   #主机列表文件对应的文件中的所有主机执行hostname命令
pdsh -w c[01-10] -w 10.0.0.1 date #对c01--c10主机和10.0.0.1执行date命令
pdsh -w c[01-10] -x c2 poweroff   #对c01--c10但排除c02 执行关机命令
pdsh -w c01,c10,master reboot     #对c1,c10,master执行重启命令
pdsh -w c[01-10] -l test id       #使用test用户在c01--c10执行id命令
```



## 主机分组

如果安装有dshgroup模块（编译安装需要启用`--with-dshgroups`，rpm包需要安装pdsh-mod-dshgroup），可使用主机分组功能。

默认的主机组定义文件存放目录是`/etc/dsh/group/`或`~/.dsh/group/`，该目录中可包含一个或多个主机列表文件，其环境变量为`DSHGROUP_PATH`，可以定义主机列表的存放目录，如：

```shell
[ -d ~/pdsh/group ]  && export DSHGROUP_PATH=~/pdsh/group
```

例如在主机组目录中添加了`group1`和`group2`两个主机列表文件：

```shell
pdsh -g group1 hostname  #在group1组的主机上执行hostname命令
pdsh -g group2 uname -r  #在group2组的主机上执行uname -r命令
```



## pdcp

pdsh提供的多主机并行复制工具，该功能需要每个主机都装有pdsh。

用法类似cp。

