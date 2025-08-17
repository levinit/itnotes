# 基本权限管理

## 权限说明

- 查看**基本权限信息**，`ls -l /etc/hosts`示例，其列出信息如下：

  > -rw-r--r--. 1 root root 65 Mar 12 03:24 /etc/hosts

  提示：使用`stat -c %a <filename>`可以获取以数字表示的权限信息，例如`stat -c %a /etc/hosts `返回的信息是`644`。

  `-rw-r--r--.`即为权限信息，按顺序解释各个符号意义如下：

  - 第1位：文件类型

    linux文件类型，参看`/usr/include/linux/stat.h`或`/usr/include/x86_64-linux-gnu/bits/stat.h`

    | 标识 | 类型                            | 占用存储空间 | 备注                     |
    | ---- | ------------------------------- | ------------ | ------------------------ |
    | -    | 普通文件 regular files          | 是           |                          |
    | d    | 目录 directory files            | 是           |                          |
    | l    | 符号链接 link files             | 是           |                          |
    | s    | 套接字 socket files             | 否           | 进程间通信               |
    | b    | 块设备 block device files       | 否           | 如硬盘                   |
    | c    | 字符设备 character device files | 否           | 如键盘、鼠标             |
    | p    | 管道 Named pipe files           | 否           | 发送或接收其他进程的数据 |

    管道文件用以传递数据，遵循先进先出原则（FIFO，first in, fist out），在读取数据时，FIFO 管道中同时清除数据。

    

  - 第2-10位：不同用户对该文件的权限

    - 第2-4位：文件所属用户的权限

    - 第5-7位：文件所属用户组的权限

    - 第8-10位：其他用户的权限

    **权限所有者**，即哪些用户对文件具有权限：

    | 权限范围 | 符号表示 | 说明                  |
    | -------- | -------- | --------------------- |
    | user     | u        | 文件所属用户          |
    | group    | g        | 文件所属用户组        |
    | others   | o        | 所有其他用户          |
    | all      | a        | 所有用户（相当于ugo） |
  
    **权限类型**，即对文件所具有的基本权限：
  
    | 权限类型 | 字母表示 | 数字表示 | 说明                             |
    | :------- | -------- | -------- | -------------------------------- |
    | 读       | r        | 4        | 文件可读；目录下文件可列出       |
    | 写       | w        | 2        | 文件可写；目录下可创建和删除文件 |
    | 执行     | x        | 1        | 文件可执行；目录可进入           |
    | 无权限   | -        | 0        | 无权限                           |
  
    
  
  - 第11位：
  
    - 启用了selinux，该处以点号`.`字符表示
  
    - 设置了ACL后，该处以加号`+`表示
  
      可以用`getfacl`查看ACL信息，`ls -l`展示的权限信息可能是ACL MASK有效权限，参看下文[ACL权限管理](#ACL权限管理)中关于MASK有效权限的描述。



## 权限修改

`chown`修改文件的所属用户和用户组，`chgrp`修改文件所属用户组，`chmod`修改文件权限模式。

- 以上三个命令都能用到的常用参数：
  - `-c`或`--changes`  显示更改部分信息
  - `-R`或`--recursive`  作用于该目录下所有的文件和子目录
  - `-h`  修复符号链接
  - `--reference`  以指定的目录或文件的权限作为参照进行权限设置

- chmod

  [权限范围](#权限范围)：u g o a

  `+`表示增加权限，`-`表示去掉权限，`=`表示重设权限；也可直接使用数字模式设置权限。

  ```shell
  #chmod [参数] <权限范围>[+-=]<权限> <文件/目录>
  chmod -cR g+r /srv
  chmod -cR u+w,g+r /srv  #多条权限规则使用逗号分隔
  chmod g=rwx /srv
  chmod 775 /srv
  ```

- chown

  ```shell
  ##冒号:也可以使用点号. 组名可省略
  #chown [参数] <用户名>[:组名] <文件/目录>
  chown -R nginx.nginx /srv/
  ```

- chgrp修改所属组

  ```shell
  #chgrp [参数] <组名> <文件/目录>  #冒号:也可以使用点号.
  chgrp -cR nginx /srv/
  ```



## 权限掩码 umask

**umask命令**用来设置新建文件/目录的权限的掩码，一共4位（1特殊权限+3基本权限），使用数字表示时如只有3位则表示不设置特殊权限。

使用`777`减去umask的值，即得到新建文件/目录的默认权限，但是新建文件总是不会有执行权限的，无论umask设置为何值，这是由操作系统（所有的Unix和类Unix系统）内核层面机制决定的。

例如`umask`执行后得到`022`，则`777-022=755`，即`rxwr-xr-x`，为新建目录的权限，但是新建文件的权限为`664`，即`rw-rw-r--`。

```shell
umask #以数字形式当前的掩码 如022
umask -S #以符号方式输出掩码 如u=rwx,g=rx,o=rx 即是022

#设置掩码
umask u=,g=2,o=rwx  #umask 0750 即rwxr-x---
umask 022
```

# 特殊权限管理

| 权限类型 | 字母表示 | 数字表示 | 在ls -l中代替位置 |
| -------- | -------- | -------- | ----------------- |
| SUID     | s        | 4        | 所属用户的x位     |
| SGID     | s        | 2        | 所属用户组的x位   |
| SBIT     | t        | 1        | 其他用户的x位     |



使用chmod授权，示例：

```shell
chmod u+s /tmp/test.sh  #-rwxr-xr-- 变成 -rwsr--r--
chmod g+s /tmp/test.sh  #-rwxrwxr-- 变成 -rwxrwsr--
chmod +t /share        #-rwx------ 变成 -rwx-----t
```

以数字表示时，**在原来基本权限的3位数字前加上特殊权限的数字**，示例：

```shell
chmod 4755 /tmp/test.sh
#相当于 chmod 755 /tmp/test.sh && chmod u+s /tmp/test.sh
```



## SUID和SGID

- SUID

  `ls -l`的列出的权限信息中，原第4位为`x`的位置变为`s`。  

  文件所属用户（owner）对有可执行权限的文件赋予SUID权限后，其他用户执行该文件过程中，拥有与该文件所有者用户相同的权限。

  

  

- SGID

  `ls -l`的列出的权限信息中，原第7位为`x`的位置变为`s`。 

  文件所属用户组（group）对有可执行权限的文件/目录赋予SGID后，其他用户执行该文件或使用该目录的过程中，拥有与该文件/目录所有者用户相同的权限。

  - SGID作用于文件时，和SUID特性相似，只是执行用户获取的权限时文件所属用户组的权限。

  - SGID作用于目录时：
    - 其他用户可进入该目录（进入目录就相当于执行目录，SGID赋予其临时组权限）
    - 其他用户在该目录中创建的新文件/子目录，具有和该目录所属用户组相同的权限（当然能创建的前提是，目录所属用户组对该目录本来就具有w权限）

  

   

## SBIT（Sticky bit）粘滞位 

> the restricted deletion flag or sticky bit

`ls -l`的列出的权限信息中，原第10位为`x`的位置（本来是other的x位置）变为`t`。

SBIT 目前只对目录有效，当目录被设置了sbit后，对该目录具有写权限的用户可以向目录中写入内容，但只能删除自己的文件（root除外）。可用来阻止非文件的所有者删除/移动文件。

具有SBIT的目录中，即使一个文件权限是rwxrwxrwx，非文件的所有者（root除外）仍然不能删除该文件。





# 扩展属性 extended attr

Extended Attributes，以下简称EA，是区分于文件属性、文件的扩展出来的属性。

EA可以给文件、文件夹添加额外键值对，以键值对地形式将任意元数据与文件i节点关联起来。键和值都是字符串并且有一定长度地限制，是完全自定义的属性。

- 扩展属性模式：

  - a：只添加修改内容，不能删除。
  - b：不更新文件或目录的最后存取时间。
  - c：将文件或目录压缩后存放。
  - d：将文件或目录排除在倾倒操作之外。
  - i：不得任意更动文件或目录本身（不能被删除、改名、设定链接关系，不能写入或新增内容）。
  - s：保密性删除文件或目录。
  - S：即时更新文件或目录。
  - u：禁止删除。

  c，s，u不能在ext2，ext3，ext4文件系统

- 查看属性`lsattr <文件|目录>`

- 设置属性`chattr 选项 <文件|目录>`

  - `-R`：递归处理，将指令目录下的所有文件及子目录一并处理；
  - `+<属性>`：开启文件或目录的该项属性；
  - `-<属性>`：关闭文件或目录的该项属性；
  - `=<属性>`：指定文件或目录的该项属性。

  ```shell
  chattr +i /etc/hosts
  ```

  

# ACL权限管理

## ACL介绍

ACL（Access Control Lists，访问控制列表）为文件系统提供更为灵活的附加权限机制，弥补chmod/chown/chgrp的不足。

检查文件是否具有ACL：

```shell
#在输出中，模式字段右侧的加号 (+) 表示该文件具有 ACL
ls -l <filename>   #示例 drwxr-xr-x+

#查看acl权限使用getfacl：
getfacl <path>  #获取acl权限信息
```

*除非已添加了用于扩展 UNIX 文件权限的 ACL 项，否则会将文件视为具有“琐碎” ACL，并且不会显示加号 (`+`)。*



ACL 通过以下对象来控制权限：

- user  用户： 对应`ACL_USER_OBJ`和`ACL_USER`

- group  群组：  对应`ACL_GROUP_OBJ`和`ACL_GROUP`

- other  其他用户  对应ACL_OTHER

  > ACL_USER_OBJ：相当于Linux里file_owner的permission
  > ACL_USER：定义了额外的用户可以对此文件拥有的permission
  >
  > ACL_GROUP_OBJ：相当于Linux里group的permission
  > ACL_GROUP：定义了额外的组可以对此文件拥有的permission
  >
  > ACL_MASK：定义了ACL_USER, ACL_GROUP_OBJ和ACL_GROUP的最大权限
  >
  > ACL_OTHER：相当于Linux里other的permission
  
- mask  掩码：允许用户（所有者除外）和组使用的最大权限（Effective permission，或者说权限范围）   对应`ACL_MASK`。

  *和默认权限`umask`类似，是一个权限掩码，表示所能赋予的权限最大值。*

  设置了mask权限后，**使用者或群组所设置的权限必须要存在于 mask 的权限设置范围内才会生效**（未设置mask权限时不存在该种限制）。

  例如：使用chmod设置某文件mask为r，则无法设置该文件的user或group权限为rw或rwx。

  可使用setfacl设置大于mask范围的权限，设置后mask最大权限值被变更为新设置的权限值。



## 设置ACL setfacl

```shell
#setfacl 参数 规则 文件
setfacl [-bkndRLP] { -m|-M|-x|-X ... } <acl规则>
#设置文件权限示例： set -m <u|g|o|m]:[name]:[rwx-] <file>
```

*如无特别说明，文件（file）指各种类型的文件或目录。*

- 常用参数

  - 设置规则
    - `-m`或`--modify`  修改文件的acl
    - `-M`或`--modify-file`  从文件或标准输入读取acl用以修改文件的acl
    - `-R`或`--recursive`  为目录递归设置acl
    - `-d`或`--default`  设置默认acl

  - 删除规则

    - `-x`或`--remove`  删除后面的acl规则
    - `-X`或`--remove-file`  从文件或标准输入读取acl规则
    - `-b`或`--remove-all`  删除全部的acl规则
    - `-k`或`--remove-default`  删除默认的acl规则  （子文件将继承目录ACL权限规则）
    -  `--set`  从指定文件（可指定多个）中读取acl规则
      - `--set-file=file`  从文件中读取acl规则
      - `--mask`  重新计算有效权限
    - `-n`或`--no-mask`  不要重新计算有效权限
    
    注意：最基本的三个规则（ugo的基本权限）不能删除。
    
    

- 规则写法：`default:用户类型:名称:权限` （default也可简写为d）

  - default也可简写为d，设置默认权限，目录设置默认权限后，目录下新建的文件/子目录将**继承设置的权限**。

  - 用户类型即上文所述的u g o m （user/group/mask/others）；

  - 名称即user的用户名（或uid）或group的组名（或gid），**mask和others无对应名字，该项留空**；

  - 权限即`rwx-`中字母的组合。
  
  ```shell
  #示例
  setfacl -m u:http:r-- /srv/index.html
  setfacl -Rm d:u:admin:rwx /srv #srv下新建的文件均继承设置的u:admin:rwx
  setfacl -m m::r-x /home
  setfacl -bn /home
  ```



# NFS4 ACL权限管理

nfs4 acl不支持以用户名/组名设置chown/chgrp，只能使用原始的uid/gid设置，例如：

```shell
#以下命令提示Failed setxattr operation: Invalid argument
nfs4_setfacl -R -a A:dfg:admin:RWX /share

#使用gid设置权限，例如admin组gid为10001
nfs4_setfacl -R -a A:dfg:10001:RWX /share

nfs4_getfacl /share  #查看权限
```

目录使用nfs4_setfacl设置ACE规则后，基本权限管理的chown和chgrp会失效，即使删除增加的nfs4 acl规则，提示类似：

> ```shell
> [root@localhost share]# chown user1 file1
> chown changing ownership of 'file1': Invalid argument
> ```

原因是nfs4 acl xx

nfs客户端查看 systemctl status nfs-idmapd.service 可看到执行chown/chgrp的错误，类似：

> nss_getpwnam: name 'user1@9' does not map into domain 'localdomain'

使用nfs v3挂载一次再挂载nfs v4，或者重启，可能是module问题。。。待研究