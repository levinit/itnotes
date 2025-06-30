# 简介

 用户在系统中的用户名是唯一的，用户具有这些属性：

- uid  用户的id，唯一

  为一个数字，一般1000及以上的为普通用户（可设置），1000以下为系统用户，0为root用户

- groups 用户组

  一个用户可以属于多个用户组，每个7用户组都有一个唯一的gid（一个数字）。

  - primary group  主要组，是当前生效的某一个用户组

  - supplementary groups  补充组，包含用户所属的所有组

    

# 查看用户信息

- `id <username>`  打印指定用户的信息

  > ```shell
  > # id user1
  > uid=1050(user1) gid=10000(group1) groups=1000(group1),1001(group2),1002(group3)
  > ```

  

- 记录本系统用户信息的文件

  - `/etc/passwd`
  - `/etc/shadow`
  - `/etc/group`
  - `/etc/gshadow`

- 查看NSS（Name Service Switch）中的用户信息——使用`getent`(get entries)

  *会包含获取自用户信息管理工具如NIS、LDAP等的条目信息。*

  使用`getent --help`查看支持的数据库类型。

  ```shell
  getent <db> #可查看用户相关的数据库：passwd shadow group gshadow
  ```

  





# 用户管理

## 添加用户

```shell
useradd <username>

useradd -m -d /path/to/userhome/ -s /bin/bash -g <gid> -u <uid> -G <group1,group2> <username>

useradd -r <username>  #创建一个系统用户
```

常用选项：

- `-m`  创建家目录
- `-d`  用户家目录路径
- `-u`  用户uid，不指定时由系统自动分配
- `-s`  shell
- `-g`  用户主组(primary group)，默认与用户名相同
- `-G`  用户补充组（supplementary group）
- `-r`  创建系统用户
- `-k`  指定一个目录代替默认的`/etc/login.defs`目录作为



### 新用户的默认配置文件

- `/etc/login.defs`

  定义了创建新用户的一些参数，如

  - `UID_MIN`/`UID_MAX`和`GID_MIN`/`GID_MAX`的值，在这个MIN-MAX区间（包含MIN和MAX自身）的id为普通可登录用户的uid和gid。

  - `SYS_UID_MIN`/`SYS_UID_MAX`和`SYS_GID_MIN`/`SYS_GID_MAX`，含义同上，用户系统用户。
  - `PASS_`开头的配置行可定义密码复杂度要求和过期时间等

`/etc/skel`目录为新建用户家目录的模板目录，使用`useradd`创建用户家目录时，会自动复制该目录的内容到用户家目录中。



## 更改密码

- 交互式

  ```shell
  #更改指定用户密码，如不指定username则默认用当前用户自身
  passwd <username>  #更改其他用户密码需要root权限
  ```

  

```shell


#batch模式修改密码
echo <password> | passwd --stdin <username>  #部分linux版本中的passwd支持--stdin选项

echo <username>:<password> | chage
```





## 删除用户

需要退出被删除的用户的所有进程。

```shell
userdel <username>
userdel -r <username>  #-r同时删除用户家目录
```



## 管理用户组

- gpasswd
- groupmems



## 变更用户组



