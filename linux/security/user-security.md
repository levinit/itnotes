# 账户删除、锁定和禁止登录

删除、锁定或禁止不必要登录的用户。

```shell
#删除用户
userdel -r <username>  #-r连带删除用户家目录

#禁止用户登录shell（例如运行nginx的用户nginx）
chsh <username> -s /sbin/nologin  #将其默认shell改为nologin
#chsh <username> -s /bin/bash

#锁定用户
passwd -l <username>
#解除锁定
passwd -u <username> 
```



# login.defs限制登陆

`/etc/login.defs`部分参数：

```shell
#登陆失败后 被允许再次可登陆的延迟时间（单位秒）
FAIL_DELAY      3

#密码有效时间
PASS_MAX_DAYS   99999
#密码更改允许的最小间隔天数 0随时可更改
PASS_MIN_DAYS   0
#密码警告天数 密码失效前N天向用户显示提示
PASS_WARN_AGE   7

#登陆尝试次数
LOGIN_RETRIES   5
```

在较新的发型版本中，login.defs中关于密码长度限制的功能已经移除，交由PAM管理。

```shell
#密码长度
#PASS_MIN_LEN  6
#PASS_MAX_LEN
```



# chage设置密码有效期

除了修改`/etc/login.defs`，也可以使用chage设置：

> ```shell
> # chage --help
> 用法：chage [选项] 登录
> 选项：
>  -d, --lastday 最近日期    将最近一次密码设置时间设为“最近日期”
>  -E, --expiredate 过期日期   将帐户过期时间设为“过期日期”
>  -h, --help          显示此帮助信息并推出
>  -I, --inactive INACITVE    过期 INACTIVE 天数后，设定密码为失效状态
>  -l, --list          显示帐户年龄信息
>  -m, --mindays 最小天数    将两次改变密码之间相距的最小天数设为“最小天数”
>  -M, --maxdays 最大天数    将两次改变密码之间相距的最大天数设为“最大天数”
>  -R, --root CHROOT_DIR     chroot 到的目录
>  -W, --warndays 警告天数    将过期警告天数设为“警告天数”
> ```



# 密码和登录控制

主要是修改PAM的密码策略。

## authconfig设置

在Redhat系列发行版中，使用`authconfig`也可以设置PAM，其配置文件为`/etc/security/pwquality.conf`。设置策略：

```shell
authconfig --update <密码策略配置参数>
```

参看`authconfig --help`：

>     --passminlen=<number>         密码最大长度 
>     --passminclass=<number>       密码中最多字符数
>     --passmaxrepeat=<number>      密码中同一字符最多连续使用次数
>     --passmaxclassrepeat=<number> 密码同一类别中最多连续使用同一字符次数
>     
>     --enablereqlower              密码中至少需要一个小写字符
>     --disablereqlower             密码中不需要小写字符
>     --enablerequpper              密码中至少需要一个大写字符
>     --disablerequpper             密码中不需要大写字符
>     --enablereqdigit              密码中至少需要一个数字
>     --disablereqdigit             密码中不需要数字
>     --enablereqother              密码中至少需要一个其他字符
>     --disablereqother             密码中不需要其他字符
>     
>     --enablefaillock        开启：多次登陆失败后锁定账户
>     --disablefaillock       关闭：多次登陆失败后锁定账户



## PAM用户认证配置

### PAM配置简介

> Linux PAM( Pluggable Authentication Modules ) 提供了一个框架，用于进行系统级的用户认证。

pam文件中的语法：

```shell
#module_interface  control_flag  module_name  module_arguments
auth               sufficient    pam_unix.so  nullok try_first_pass
```



- PAM模块接口（模块管理组）

  PAM为认证任务提供四种类型可用的模块接口，它们分别提供不同的认证服务：

  | 模块     | 说明                                                         |
  | -------- | ------------------------------------------------------------ |
  | auth     | 认证模块接口，如验证用户身份、检查密码是否可以通过，并设置用户凭据 |
  | account  | 账户模块接口，检查指定账户是否满足当前验证条件，如用户是否有权访问所请求的服务，检查账户是否到期 |
  | password | 密码模块接口，用于更改用户密码，以及强制使用强密码配置       |
  | session  | 会话模块接口，用于管理和配置用户会话。会话在用户成功认证之后启动生效 |

  单个PAM库模块可以提供给任何或所有模块接口使用。如pam_unix.so提供给四个模块接口使用。

  

- 模块控制标志

  每个PAM模块中由多个对应的控制标志决定结果是否通过或失败

  | 标志       | 说明                                                         |
  | ---------- | ------------------------------------------------------------ |
  | required   | 模块结果必须成功才能继续认证，如果在此处测试失败，则继续测试引用在该模块接口的下一个模块，直到所有引用结束才返回结果通知给用户。 |
  | requisite  | 模块结果必须成功才能继续认证，如果在此处测试失败，则会立即将失败结果通知给用户。 |
  | sufficient | 模块结果如果测试失败，将被忽略。如果sufficient模块测试成功，并且之前的required模块没有发生故障，PAM会向应用程序返回通过的结果，不会再调用堆栈中其他模块。 |
  | optional   | 该模块返回的通过/失败结果被忽略。当没有其他模块被引用时，标记为optional模块并且成功验证时该模块才是必须的。该模块被调用来执行一些操作，并不影响模块堆栈的结果。 |
  | include    | 与其他控制标志不同，include与模块结果的处理方式无关。该标志用于直接引用其他PAM模块的配置参数 |



### 密码复杂度

redhat系列中，配置文件为：`/etd/pam.d/system-auth-ac`。

debian系列中，配置文件为：`/etc/pam.d/common-password`。其他相关配置文件：`/etc/pam.d/common-account`、`/etc/pam.d/common-auth`、`/etc/pam.d/common-session`。

如果缺少相关模块，安装：

```shell
apt install -y libpam_cracklib libpam-pwquality  #可能默认未安装
```



- pam_cracklib  适用于passwd接口

  ```shell
  password requisite pam_cracklib.so try_first_pass retry=5 type= difok=3 minlen=8 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1
  ```

  参数说明：

  > ```shell
  > retry=5      #最大尝试次数为5
  > minlen=8     #最小密码长度8
  > 
  > difok=3      #新旧密码相同字符数不少于3个
  > minclass=2   #密码必须包含至少2种不同的字符类型
  > #以下是密码的字符类型
  > lcredit=-1   #密码至少包含1个小写字母
  > ucredit=-1   #密码至少包含1个大写字母
  > dcredit=-1   #密码至少包含1个数字
  > ocredit=-1   #密码至少包含1个特殊字符
  > 
  > reject_username    #新密码中不能包含与用户名称相同的字段
  > maxrepeat=N        #拒绝包含超过N个连续字符的密码，默认值为0表示此检查已禁用
  > maxsequence=N      #拒绝包含大于N的单调字符序列（如1234）的密码
  > maxclassrepeat=N   #拒绝包含相同类别的N个以上连续字符的密码。默认值为0表示此检查已禁用。
  > use_authtok        #强制使用先前的密码，不提示用户输入新密码(不允许用户修改密码)
  > ```



- pam_unix （适用于account，auth， password和session模块接口）

  ```shell
  password  sufficient  pam_unix.so sha512 shadow nis nullok try_first_pass use_authtok
  ```

  参数说明：

  ```shell
  remember=N     #记录用户N个历史密码，新密码不能和这些密码相同
  sha512    #当用户下一次更改密码时，使用SHA256算法进行加密
  md5       #当用户更改密码时，使用MD5算法对其进行加密
  try_first_pass  #在提示用户输入密码之前，模块首先尝试先前的密码，以测试是否满足该模块的需求。
  use_first_pass  #该模块强制使用先前的密码(不允许用户修改密码)，如果密码为空或者密码不对，用户将被拒绝访问
  shadow        #用户保护密码
  nullok        #默认不允许空密码访问服务
  use_authtok   #强制使用先前的密码，不提示用户输入新密码(不允许用户修改密码)
  ```

  

### 限制用户使用su(sudo)

编辑`/etc/pam.d/su`，取消此行注释，将只允许wheel组的用户使用su切换到root。

```shell
auth required pam_wheel.so use_uid
```

`sudo`和`su -l`（`su -`）配置类似，只是第一步分别修改的是`/etc/pam.d/sudo`和`/etc/pam.d/su-l`。



### 登陆失败后锁定账户

pam_tally2模块

redhat系列中，在`/etc/pam.d/password-auth-ac`或`/etc/pam.d/sshd`文件添加。

debian系列中，在`/etc/pam.d/common-auth`文件添加。

```shell
auth  required  pam_tally2.so deny=3 unlock_time=600 onerr=succeed file=/var/log/tallylog
```

参数说明：

> ```shell
> #全局选项
> onerr=[succeed|fail]
> file=/path/to/log   #失败登录日志文件，默认为/var/log/tallylog
> audit               #如果登录的用户没有找到，则将用户名信息记录到系统日志中
> silent              #不打印相关的信息
> no_log_info         #不通过syslog记录日志信息
> 
> #AUTH选项
> deny=n              #失败登录次数超过n次后拒绝访问
> lock_time=n         #失败登录后锁定的时间（秒数）
> unlock_time=n       #超出失败登录次数限制后，解锁的时间
> no_lock_time        #不在日志文件/var/log/faillog 中记录.fail_locktime字段
> magic_root          #root用户(uid=0)调用该模块时，计数器不会递增
> even_deny_root      #root用户失败登录次数超过deny=n次后拒绝访问
> root_unlock_time=n  #与even_deny_root相对应的选项，如果配置该选项，则root用户在登录失败次数超出限制后被锁定指定时间
> ```

root用户为被pam_tally2锁定的用户解锁：

```shell
pam_tally2 -u <username>  #查看用户登录失败记录
pam_tally2 -u <username> -r --reset  #解锁用户
```

