[TOC]

# 简介

## 概念

Shell 是一个用 C 语言编写的程序，Shell 既是一种命令语言，又是一种程序设计语言。

> Shell 是指一种应用程序，这个应用程序提供了一个界面，用户通过这个界面访问操作系统内核的服务。
>
> Ken Thompson 的 sh 是第一种 Unix Shell，Windows Explorer 是一个典型的图形界面 Shell。

## 常见shell实现

unix（及其衍生版）和linux的常见shell，粗略分为三类：Bourne Shell类，C shell类和其他（代表如fish)。

主要shell实现：

- Thompson shell：第一个Unix shell，肯·汤普逊（Kenneth Lane Thompson）1971年写作出第一版并加入UNIX之中，作为默认shell——`/bin/sh`。

- Bourne Shell，贝尔实验室史蒂芬·伯恩（stephen R. Bourne）1979编写加入到Unix 7取代Thompson shell为默认sh——`/bin/sh`。

- bash：Bourne Again Shell，1989发布，是Brian Fox为GNU项目编写用以取代Borne Shell的自由软件。
  
  许多Linux发行版、windows wsl以、solaris 11+、macos catalina之前的版本中的默认shell，这些系统上，sh往往实际指向bash。
  
  bash保持了对 sh shell 的兼容性，但有些行为并不一致；bash扩展了一些sh命令和参数。

- ash：Almquist shell，Kenneth Almquist  1980s 创建的Bourne Shell分支，1990s在BSD成为了默认shell
  
  - dash：1997年，Herbert Xu 从NetBSD 移植ash到Debian，更名为 dash (Debian Almquist Shell)，debian的默认shell，在debian上sh实际指向dash。

- csh：C shell，柏克莱大学的比尔·乔伊（Bill Joy，创建BSD，开发了 vi ，Sun 公司的创始人之一）编写 ，语法类C，故名。
  
  - tcsh：Tenex c shell，csh 的增强版，加入了命令补全功能，一些BSD发行版如FreeBSD的默认shell
    
    一些系统（如红帽和Macos）上，csh实际是指向tcsh的软链接。

- zsh：Z shell，Paul Falstad 1990编写，扩展自Bourne shell，加入大量改进，兼容bash、ksh、tcsh的大部分特性。
  
  Kali linux 2020.4+ 、macos catalina及以后版本的默认shell。

- ksh：KornShell， 贝尔实验室大卫·科恩（David Korn） 1980s早期编写的Unix shell，在 在1983年7月14日的USENIX年度技术会议上发布。基于Bourne shell，添加了一些csh的特性。

- fish：friendly interactive shell，强调良好交互性
  
  > fish的语法类似于其他兼容[POSIX](https://zh.wikipedia.org/wiki/可移植操作系统接口)的shell，但由于其开发者认为POSIX shell设计得有问题，fish的语法又与POSIX shell有相当的不同。

本文以bash为基础，部分与sh差异将特别说明（标明为bash的特性除外）。查看当前shell

```shell
echo $SHELL        #查看当前使用的shell
echo $shell        #某些shell中可能使用小写的环境变量
cat /etc/shells    #查看当前系统支持的shell
```



## bash shell脚本文件

- 扩展名`.sh`：脚本文件**可以不使用扩展名** （但是使用扩展名sh，shell可以为代码提供颜色高亮）。

- 解释器：在脚本文件开始时使用shebang指定解释器，例如`#!/bin/bash`指定sh作为解释器。
  
  shebang，即sharp `#`和ban  `!`的联合缩写。

- 执行脚本：
  
  - 脚本有可执行权限：`./file.sh`
    
    为脚本添加执行权限：`chmod +x file.sh`
  
  - 脚本无可执行权限：`bash file.sh`

- 命令别名alias和type
  
  - alias 为某个命令设置别名
  - type 查看某个别名命令（如果它被alias定义过）对应的内容
  - `unalias -a`  可删除所有别名
  
  示例：
  
  ```shell
  alias ll=`ls -al --color=auto`  #执行ll就等于执行ls -al --color=auto
  type ll  #查看ll对应的命令内容 ls -al --color=auto
  ```

- 命令优先级顺序：绝对/相对路径执行命令 > 别名 > bash内部命令 > $PATH环境变量定义的目录查找顺序的第一个命令 。



## bash 启动环境

### 登录与非登录式shell

用户每次使用Bash Shell都会开启一个与 Shell 的 Session（会话）。

- 登录式shell会话
  
  开启一个新的会话进程，初始化所有环境变量。通常需要用户名密码验证。例如：ssh远程登录，VNC远程登录，本地tty登录和本地桌面环境登录。

- 非登录式shell会话（无需登录）
  
  用户进入登录式shell会话后新建的子shell会话，例如：在登录的桌面中打开一个terminal，在登录的bash shel中执行bash命令开启新的bash子进程。

根据shell会话是否可交互可分为：

- 交互式shell：终端交互模式，用户输入命令回车执行。
- 非交互式shell：shell脚本运行，shell 不会和用户交互，读取并执行脚本文件直到读取到文件 EOF 时结束

判断shell是否为登录式shell：

```shell
echo $-    
```

bash中以上命令输出的可能是`himBH`：

> - `h`: 以*Hash*方式缓存环境变量`$PATH`中的可执行文件，用来加速命令执行。
> - `i`: 表示*Interactive*，当前shell是可交互的。
> - `m`: 启用*Job control*，Bash的工作控制功能。
> - `B`: 启用*Brace expansion*，使得shell可以展开`*`，`?`这些形式的命令。
> - `H`: 启用*History substitution*，Bash的历史机制啦，`history`，`!`这些。

登录式shell和非登录式shell主要区别在读取环境变量文件的差异。参看下文。



### shell PS1提示符

交互式shell下的行首提示性字符内容，形如：

>[user1@host1 ~]$ 

由`PS1`[环境变量](#环境变量)的值确定，例如默认的多为：

```shell
PS1='[\u@\h \W]\$ '
```

其中的特殊字符含义：

- `\u`当前用户名
- `\h`当前主机名
- `\W`当前目录名（basename of `$PWD`） `\w`当前路径

可使用`man bash`然后搜索`PROMPTING`章节了解更多的特殊字符的含义。

注意：

- 输出特殊字符本身需要使用`\`转义符号，如输出普通的`$`符号需要使用`\$`

- PS1中的**非打印字符**都必须用`\[\]`，否则计算提示符长度时也会将其计算在内，输入过长命令导致第一次折行不正常，光标回到行首进行覆盖，第二次出现折行则正常。

  如颜色转移序列符

  ```shell
  #PS1='[\e[1m\u\e[0m@\e[37m\h\e[0m \W]\$ '  #此处PS1的颜色转义符没有使用\[ \]包裹
  PS1='[\[\e[1m\]\u\[\e[0m\]@\[\e[37m\]\h\[\e[0m\] \W]\$ '
  ```



### 配置文件载入顺序

一般如果没有对系统文件进行修改，多数发行版会按以下顺序读取配置文件：

- 登录式shell流程

  如执行`bash -l`、`su -l <user>`、ssh登录等。
  
  1. `/etc/environment`
  
     仅设置环境变量（不会执行 shell 命令）

  2. `/etc/profile`

     系统范围的初始化脚本，会加载 `/etc/profile.d/*.sh`
  
  3. `/etc/profile.d/*.sh`
  
     按文件名顺序执行
  
  4. `~/.bash_profile`
  
     用户登录脚本，若存在通常会 source ~/.bashrc
  
  5. `~/.bashrc `
  
     用户 shell 初始化设置
  
  *登录式 shell 不会自动加载 /etc/bashrc（或 /etc/bash.bashrc），但可能通过 ~/.bashrc 间接加载。*
  
  

- 非登录shell读取

  1. `~/.bashrc`

     用户 shell 初始化设置，通常在其中包含一行 `source /etc/bashrc` 或 `source /etc/bash.bashrc`



另外，对于`/etc/bashrc`或者`/etc/bash.bashrc`，不同发行版可能有不同处理方式，例如：

- RHEL系：默认的`~/.bashrc`的文件中会读取`/etc/bashrc`
- SUSE系：倾向于在登录（在`/etc/proifle`中）和非登录环境（在默认的`~/.bashrc`中）都读取`/etc/bashrc`
- Debian系：在`/etc/profile`中读取`/etc/bash.bashrc`



另：如果存在`~/.bash_logout`，会在退出shell时会读取该文件。



- 使用`--login`或`-l`选项可以开启一个登录式shell
  
  ```shell
  bash -l  #没有-l或--login则开启新的非登陆式shell
  ```

- `--noprofile`  忽略读取以上任何文件。
  
  > Do not read either the system-wide startup file /etc/profile or  any  of the personal initialization files ~/.bash_profile,  ~/.bash_login, or ~/.profile
  
  示例，登陆ssh时使用该参数：
  
  ```shell
  ssh <server> -t "bash --noprofile"
  ```

- `--norc`   忽略禁非登录shell的交互模式中读取`~/bashrc`配置文件
  
  > Do not read and execute the personal initialization file ~/.bashrc if the shell is interactive.

- `--rcfile`   指定另一个文件替代`~/.bashrc`

```shell
bash --norc
ssh user@server -t "/bin/bash --noprofile --norc" #用户跳过shell初始化
```

# 变量

## 变量分类

标准的UNIX 变量分为两类：环境变量和shell变量

> Standard UNIX variables are split into two categories, environment variables and shell variables.

--by [UNIX Tutorial Eight](http://www.ee.surrey.ac.uk/Teaching/Unix/unix8.html)

- shell变量（局部变量）：在脚本或命令中定义，仅在shell当前实例（当前运行的shell进程，下简称当前shell）中存在的变量。这些变量不为子进程所继承。一般习惯小写。

  - 函数内局部变量，在函数内使用`local`定义

  可使用`set`（bash shell内建命令）查看当前shell变量，但是输出中也包含了环境变量。

  此外，set主要用于改变当前shell的默认行为，一般写在shell脚本的头部

  常用选项和参数：

- `-u`  或 `-o nounset`   遇到未定义或未赋值的变量时退出shell

- `-e`  遇到错误（返回值不为0）时退出shell

- `-o pipefail`    遇到管道命令错误时退出shell，可以和`-e`（不能判断管道符后面命令的错误）何用

- `-C`  禁止写入已有文件

- `-x`  或 `-o xtrace`     调试模式（相当于执行bash的`-x`参数 ）

  ```shell
  #!/bin/bash
  set -euo pipefail
  ```

- [环境变量](#环境变量)：用以存储有关shell会话和工作环境的信息。可用于shell的任何子进程。一般惯全大写。

- [shell内部变量](#shell内部变量)：由 shell 设置的特殊变量。实际其中一些变量是环境变量，而另一些变量则是局部变量。         

  

## 定义和使用

基本定义方式：直接使用`=`对变量赋值即可；`readonly`可定义只读变量——常量

- 如果变量的值的内容中含有空白字符或换行符时，务必要使用双引号`""`包含变量，否则换行将被去掉

- 默认情况下，shell均以字符串存储，需要根据上下文来确定类型进行操作



引用变量：`$变量名`或`${变量名}`，无大括号是简写方法，需要**使用`{}`的情况**：

- 如果变量后面跟一个**非小写字符串、数字或下划线**   `${var}_1`

- [位置参数变量](#位置参数变量)中**第10个及以后的参数的写法**

- 增加可读性或避免混淆  例如`${var}test`和`$vartest`

- 间接引用变量`${!varName}`，其将指定的变量对应的值作为变量名，然后引用这个值对应的变量名

  ```shell
  var1="hello"
  hello="11111"
  
  #将var1变量对应的值——hello作为变量名，相当于执行echo $hello
  echo ${!var1}  #11111
  ```

  

定义和调用变量示例：

```shell
var1=123     #变量名=变量值
readonly var2=3  #定义后就不能修改var2的值
echo $var1
```

特殊的声明方式：

- declare声明变量类型
  
  选项：
  
  - 变量类型属性：`+`和`-` 给变量设定/取消类型属性
  
  - 定义数组
    
    - `-a`  将变量声明为**数组**
    
    - `-A`  将变量声明为**关联数组**
      
      关联数组中可以使用字符串作为索引（类似其他变成语言的对象/字典等）
  
  - `-i`    将变量声明为**整数**
  
  - `-x`    将变量声明为**环境变量**
  
  - `-r`    将变量声明为**只读**
  
  - `-p`    **显示**指定变量的被声明的**类型**
  
  - `-f`     仅显示函数

- `local`定义函数内部变量：在变量声明前加上`local`，仅作用于函数内部
  
  ```shell
  function abc(){
    local x=123
    echo $x
  }
  abc      #123
  echo $x  #空
  ```

- 取消设置或删除变量：`unset 变量名 `

## 环境变量

`printenv`或`env`命令查看环境变量，二者(均不是bash shell内建命令）的输出内容只有一行不同：

> < _=/usr/bin/env
>
> \---
>
> \> _=/usr/bin/printenv

`env`除了打印环境变量外，主要用于**临时为某个程序（子进程）设置环境变量**并运行的场景，man手册写到：

> run a program in a modified environment

```shell
#env [OPTION]... [-] [NAME=VALUE]... [COMMAND [ARG]...]
env VAR1=123 myprogram  #myprograms中可读取VAR1这个环境变量
```

env设置的临时环境变量需要被其后的程序接收的，单独一行使用env设置环境变量，只会输出环境变量，其后的子进程中是无法读取env设置的值，示例：

```shell
env x=1       #如不调用一个程序读取设置的值，改行只会输出一堆环境变量
bash /tmp/x   #/tmp/x中内容为echo $x 但是读取不到x这个变量
echo $x       #一样读取不到$x
```

用户可以使用export（bash shell内建命令）将某个变量导出为当前shell进程的环境变量，从而**被其所有子进程自动继承**。export导出变量为环境变量示例：

```shell
arch=$(uname -m)
export arch   #export变量时，不能使用$

export app_ver=1.0

export PATH=~/bin:$PATH
```

export的变量无法改变父进程的环境变量（子shell中修改继承的环境变量不会影响父shell中对应变量的值）。



## shell内部变量

bash内置的变量。

### 预定义变量

通常用于保存程序运行状态

| 预定义变量 | 说明                                                         |
| ---------- | ------------------------------------------------------------ |
| $?         | 返回最后一次执行的命令返回的状态码（0执行正确，1执行错误）参看[exit退出状态码](#exit退出状态码) |
| $$         | 脚本运行的当前进程号（PID）                                  |
| $!         | 后台运行的最后一个进程的进程号（PID）                        |
| $-         | 当前shell的参数                                              |

### 位置参数变量

| 位置参数变量 | 说明                                                      |
| :----------- | :-------------------------------------------------------- |
| `${n}`或`$n` | 第n个参数，**$0代表该shell脚本（在脚本中时）或shell本身** |
| `$*`         | **所有参数的集合**                                        |
| `$@`         | **所有参数的集合**                                        |
| `$#`         | 所有参数的个数                                            |

获取特定参数：

- `${@:m:n}`  第m到第n个参数，如`${@:1:3}`  `${@:$#}`  获取最后一个参数
- `${@:$#}`    获取最后一个参数，
- `${@:$#-1}`   获取最后2个参数(依次类推)

`$*`和`$@`对比：

- 无双引号`""`包裹
  
  `$@`和`$*`：二者均表示所有的参数集合。
  
  **无论传入的参数有没有引号，将以IFS（默认为空格）来分割分字符串**。（例如原本传入一个参数"a b"，会被处理为a和b两个参数。
  
  *IFS, Internal Field Separator内部字段分隔符。*

- 使用双引号`""`包裹
  
  - `"$*"`将所有内容当成一个字符串处理。
    
    例如无论传入`a b c`、`'a b c'`还是`"a b" c`，`"$*"`都视作一个字符串`a b c`。
  
  - `"$@"`将参数当作一个参数数组
    
    其将以IFS（默认为空格）分割分字符串，但如果分隔符（默认为空格）在引号`""`里面则忽略而不进行拆分。**大多数情况下使用`"$@"`更符合使用预期。**
    
    
    
    例如传入`"a b" c`，`"$@"`将其视作传入了两个参数，分别为`"a b"`和`c`。
    
    文件test.sh
    
    ```shell
    echo ====='$@'=====
    for k in $@;do echo $k;done
    echo ====='$*'=====
    for l in $*;do echo $l;done
    echo ====='"$*"'=====
    for i in "$*";do echo $i;done
    echo ====='"$@"'=====
    for j in "$@";do echo $j;done
    ```
    
    测试：
    
    ```shell
    ./test.sh a b c
    ./test.sh 'a b' c
    ```
    
    传入参数`a b c`：`$*`、`$@`和`$@`输出a b c三行 ，  `"$*"`将传入内容当作整体输出`a b c`一行。
    
    传入参数`'a b' c`：`$*`、`$@`依然输出a b c三行，`"$@"`输出`a b`和`c`两行，  `"$*"`将传入内容当作整体输出`a b c`一行。



## 变量测试（变量置换）

| 变量置换方式    | 变量y没有设置        | 变量y为空值时        | 变量y值不为空   |
| --------------- | -------------------- | -------------------- | --------------- |
| `x=${y-新值} `  | x=新值               | x为空                | `x=$y`          |
| `x=${y:-新值}`  | x=新值               | x=新值               | `x=$y`          |
| `x=${y+新值}`   | x为空                | x=新值               | x=新值          |
| `x=${y:+新值}`  | x为空                | x为空                | x=新值          |
| `x=${y=新值}`   | x=新值 y=新值        | x为空 y值不变        | `x=$y`  y值不变 |
| `x=${y:=新值}`  | x=新值 y=新值        | x=新值 y=新值        | `x=$y`  y值不变 |
| `x=${y?新值}`   | 新值（标准错误）输出 | x值为空              | `x=$y`          |
| `x=${y:?新值} ` | 新值（标准错误）输出 | 新值（标准错误）输出 | `x=$y`          |

例子：

```shell
test=''
val=world
echo "${test:-hello} -- $test"  #hello --
echo "${test:-$val} -- $test"  #world --

echo "${test:+hello} -- $test"  #hello --  hello

#此时test已经被上条命令赋值为hello
echo "${test:?bye} -- $test"  #hello -- hello  #test不为空仍用原值
test=''　#置空test
echo "${test:?hello} -- $test"  #错误　输出提示 bash: test: hi

#test仍为空
echo "${test:+bye} -- $test"  # --   原值为空使用原空值
test=hello
echo "${test:+bye} -- $test"  #bye -- hello  原值不为空　使用新值
```



# 数组

使用索引将数据集合保存为独立条目。

bash支持普通数组和关联数组（bash 4.0+）：普通数组使用整数作为索引，关联数组使用字符串作为索引。

Bash目前只支持一维数组。

- 定义数组
  
  - 普通数组，可直接对某个元素赋值（数组不存在时将自动创建）
    
    ```shell
    arr[0]=0  #直接赋值即可创建数组
    arr[1]=1
    ```
  
  - declare定义数组并赋值
    
    `-a`定义普通数组（对于普通数组 declare不声明可直接赋值）
    
    `-A`定义关联数组 （需要声明）
    
    ```shell
      declare -a arr1
      arr[0]=zero
      arr[1]=one
    
      #定义关联数组
      declare -A arr2
      arr2[indexA]=aaa
    ```
  
  - 直接定义并对各个索引赋值
    
    - 普通数组：`数组名=(元素1 元素2 元素n)`， 使用空格隔开各个元素。
    
            注意，csh，zsh中数组下标从1开始。
    
    - 关联数组：**需要先用declare声明**  `数组名=([索引]=值 [索引]=值)`
    
    ```shell
    arr1=(1 2 test)  #1 2 test
    arr2=(test{1..3} what how)  #test1 test2 test3 what how
    
    #关联数组
    declare -A fruite_prices
    fruite_prices[apple]=10
    fruite_prices=([orange]=7 [banana]=5)
    
    #有分隔符的字符串转数组
    x="1 2"  #默认分隔符IFS为空白字符
    y=(${x}) #y为(1 2)
    
    m="3,4"
    IFS=,
    n=(${m}) #m为(3 4)
    ```
  
  - 追加元素`+=`
    
    ```shell
    arr=(1 2)
    arr+=(3)  #arr=(1 2 3)
    ```

- 读取数组
  
  - 某个数组元素：`${数组名[索引]}`
  - 数组所有元素：`${数组名[*]}`或`${数组名[@]}`
  - **关联数组的索引列表**：`${!数组名[*]}`或`${!数组名[@]}`

- 数组长度：`${#数组名[*]}`或`${#数组名[@]}`  （比读取数组所有元素多一个`#` ）

- 判断字符串是否为数组的元素
  
  ```shell
  array=(111 222)
  var=11
  echo "${array[*]}" |grep -wq $var
  echo $?  #如果存在退出码为0
  ```
  
  提示，以下方法均存在问题：
  
  ```shell
  #  #将输出yes，而array中只有111没有11
  [[ ${array[@]} =~ $var ]]  && echo yes || echo no
  [[ ${array[@]/${var}/} != ${array[@]} ]] && echo "Yes" || echo "No"
  ```

数组示例：

```shell
arr1=(1 2 )
echo ${arr1[0]}  #1  第0个元素
echo ${arr1[@]}  #1 2  所有数组元素
echo ${!arr1[*]}  #0 1  数组索引值
echo ${#arr1[@]}  #2 个数组元素

#关联数组
declare -A arr2
arr2=([one]=1 [tow]=2)
echo ${arr2[one]}  #1  第one个元素
echo ${arr2[@]}  #2 1  所有数组元素 倒序排列
echo ${!arr2[*]}  #one two  数组索引值
```



# 字符串处理

字符串以引号包含，如果一个字符串内部没有空格（所有字符连在一起），也可以不使用引号。

单双引号区别参看前文[特殊符号](#基本特殊符号)中关于引号的描述。

- 字符串拼接、字符串和变量拼接：连接在一起即可。
  
  ```shell
  echo "abc"def'ghi'  #abcdefghi
  a=111;echo ${a}222  #111222  #shell默认以字符串存储变量值
  ```

- 长度获取`${#var}`
  
  需要将字符串赋值给变量
  
  ```shell
  str=abcd
  echo ${#str}  #3
  
  #使用expr length <string>
  expr length "string1"    #7  字符串长度
  ```

- 子字符位置查询`expr index $var char`
  
  char是一个或多个字符，该命令将从字符串中查找char中第一个字符首次出现的位置（index）。
  
  注意：字符串中第一个字符的位置序号是1而不是0。
  
  需要将字符串赋值给变量
  
  ```shell
  str=abc
  echo $(expr index $str b)  #2
  
  #查找a或b第一次出现的位置
  #前面的找到后立即就返回位置
  echo $(expr index $str ab)  #1
  
  #expr index <string> <sub-string>
  expr index "string" st   #1  s第一次出现的位置
  ```

## 字符串截取

操作变量截取

| 格式                       | 说明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| ${string: start :length}   | 从 string 字符串的左边第 start 个字符开始，向右截取 length 个字符。 |
| ${string: start}           | 从 string 字符串的左边第 start 个字符开始截取，直到最后。    |
| ${string: 0-start :length} | 从 string 字符串的右边第 start 个字符开始，向右截取 length 个字符。 |
| ${string: 0-start}         | 从 string 字符串的右边第 start 个字符开始截取，直到最后。    |
| ${string#*chars}           | 从 string 字符串第一次出现 chars 的位置开始，截取 chars 右边的所有字符。 |
| ${string##*chars}          | 从 string 字符串最后一次出现 chars 的位置开始，截取 chars 右边的所有字符。 |
| ${string%chars*}           | 从 string 字符串第一次出现 chars 的位置开始，截取 chars 左边的所有字符。 |
| ${string%%chars*}          | 从 string 字符串最后一次出现 chars 的位置开始，截取 chars 左边的所有字符。 |

### 从指定位置开始截取

从指定位置开始，**向字符串尾部截取指定长度**的内容。

从左边开始计数时，起始数字是 0；从右边开始计数时，起始数字是 1（以0-N表示）。

- 以左边开始计数的指定位置
  
  ```shell
  #${变量名:起始位置:长度}   #从字符串起始位置0开始
  #${string:start:length}
  str=hello
  echo ${str:2:3}  #llo 截取第2个字符后面的3个字符
  ```

`start`为起始字符序号，`length`为自`start`开始所截取的长度。如果**有冒号`:`但省略冒号后面的数字**，则`start`或`length`则默认取值为0。

- 以右侧指定位置开始，向尾部截取指定长度内容
  
  语法同上，只是起始位置以`0-N`表示，截取方向仍然是向字符串尾部。
  
  ```shell
  #${变量名:0-起始位置:长度}   #右侧起始位置为1
  #${string:start:length}
  str=hello
  echo ${str:0-3:3}  #llo 从倒数第2个字符开始向前面截取3个
  ```

### 从指定字符（子字符串）开始截取

- 使用`#`截取右侧的内容
  
  ```shell
  #${变量名#*子字符串}   #*在这里作为通配符
  #${string#*chars}    #*在这里作为通配符
  str=hello
  echo ${str#*e}  #llo 截取e字符右侧字符 *表示e的左侧省略，截取右侧
  ```
  
  注意，如果子字符串出现过多次，那么遇到第一个匹配的子字符串就会结束，将返回该匹配子字符串后面的内容（即使后面的内容中也包含这个子字符串），使用`##`表示匹配最后一个指定子字符串后面的内容，示例：
  
  ```shell
  str=/a/b/c
  echo ${str#*/} #a/b/c
  echo ${str##*/} #c
  ```

- 使用`%`截取左侧的内容
  
  用法类似`#`，只是`*`放置位置与其相反，位于子字符串的右侧，表示右侧省略，截取左侧：
  
  ```shell
  str=hello
  echo ${str%ll*} #he  hello的ll左侧为he
  ```



## 正则表达式

这里不详述正则表达式相关内容，具体参看正则表达式和相关工具文档。

**正则表达式与[通配符](#通配符)**：

正则表达式是**包含匹配**，用于**文件内容**匹配；通配符是**完全匹配**，多用于**文件名**匹配。

shell需调用外部命令使用正则表达式处理字符串

- 支持正则：grep 、cut、sort、awk、sed、uniq
- 只支持通配符不支持正则：find、cp、ls、rm

应注意以下特殊字符的使用区别：

- `$`  shell中用作变量引用的时置于变量名前的标志符号；正则中表示字符串末尾。
- `*`  通配符中可单独使用，代表任意个数字符；**正则中不能单独使用**，表示重复前面的内容任意次。
- `?`  通配符中可单独使用，代表1字符；**正则中不能单独使用**，表示重复前面的内容0次或1次。

## 输出输入命令

较为常用。

### echo输出

echo不是bash内建命令。

选项：

- `-e`   启用[控制符](#控制符)转换
- `-E`  关闭[控制符](#控制符)转换
- `-n`  不在末尾输出空行（同[控制符](#控制符)中`\c` ）

输出的内容最好加上引号，否则在某些情况下会出问题（如使用空格、控制符号等的时候）。

```shell
echo a  #输出test
echo a\nb    #输出anb
echo -e 'a\nb'    #输出a (换行) b
```

### printf输出

printf不是bash内建命令。

printf 命令模仿 C 程序库（library）里的 printf() 程序，使用printf的脚本比使用echo移植性好。

**默认printf不会像 echo 在输出内容尾部自动添加换行符**，需要手动添加 `\n`。

```shell
$ printf "Hello, Shell\n"
Hello, Shell
```

printf可是使用格式化字符串：`printf format-string [arguments...]`

参数：

- format-string： 为格式控制字符串(占位符)
  
  - `%s`  `%c`   `%d`   `%f`：格式替代符（s-string，c-char，d-decimal，f-float）
    
    `f`前可以指定保留的小数位数，例如`.2f`表示保留两位小数。
  
  - `[-][n]`
    
    - `-`表示左对齐，没有该符号则表示右对齐。
    - `n`是一个数字，表示占用多少个字符的宽度（不足则以空格填充）。
  
  - 特殊符号（如`\t`，`\n`等参看前文）。

- arguments：为参数列表。

例如脚本内容：

```shell
#!/bin/shprintf "%-10s %-8s %-4s\n" 姓名 性别 身高printf "%-10s %-8s %-4.2f\n" 人甲 男 177.7111printf "%-10s %-8s %-4.2f\n" 人乙 女 168.8222
```

%-10s 指一个宽度为10个字符，字符左对齐。%-4.2f 指格式化为小数，其中.2指保留2位小数。

将输出：

```shell
姓名     性别   身高人甲     男      177.7人乙     女      168.8
```



### read输入

read是bash内建命令。

选项：

- `-p`   提示信息
- `-e`   启用编辑功能，使用readline程序获取内容，支持tab补全文件路径（使用readline的补全）、方向键等
- `-E`   同`-e`，但是补全使用的是bash的补全，包含可编程的补全。
- `-i <text>`    提供默认值，需要和`-e`或`-E`配合，程序会直接读取给定对默认值作为输入内容展示
- `-t <N>`   等待时间（单位：秒）
- `-d <char>`   自定义分隔符（delimiter），持续读取直到读入分隔符为止，可以是空白字符
- `-r`   不允许反斜杠转义任何字符
- `-n <N>`   指定接收输入的字符数（超出的字符被忽略）
- `-s`   静默模式，不显示输入的数据，用于机密信息的输入（如密码）
- `-a <array_name>`  以分隔符（默认为任意长度空白字符串）将字符串读取为数组 



```shell
read -p "please input username:"    name
read -s -p "please input password:" password

#将用户的输入内容赋值给name变量#使用-d -r
read -d -r '' msg << TIPYou should reboot system after installation.\nGood Luck!\nTIPecho $msg

#-e/-E和-i
read -E -i "/usr/local" -p "input installation path: " path
#以上命令执行后会展示如下，且能输入时用tab补全，使用方向键移动
#input installation path: /usr/local
```



read 读取字符串内容，以指定字符为分隔符，将字符串读取为数组：

```shell
#/为分隔符，得到数组build_info=(linux amd64)
IFS='/' read -r -a build_info <<<"linux/amd64"
```

另外，内建命令readarray（或mapfile）可从标准输入或选项“-u”指定的文件描述符fd中读取文本为数组。

```shell
#list1为各行内容组成的数组，-t删除了每行的换行符
readarrary -t list1 < file1

echo 1,2,3 | readarray -d , -t nums  #nums为(1 2 3)
readarray -d , -t nums <<< 1,2,3  #同上
```

默认以换行符为分隔符，每个元素字符串末尾保留分隔符，`-t` 可去掉每个元素的末尾的分隔符。`-d`可指定分隔符。



# 特殊符号

## 基本特殊符号

- `#`：注释本行

- `\`：反斜杠，转义符，将其后的一个特殊字符转为普通字符。

- 命令替换：在命令行中使用命令的输出来替换特定的命令。

  - `$()`：括号内部的内容是系统命令，会最先执行。（建议）
  - ``：反引号，其内部的反斜杠无转义功能。（不建议，属于早期非POSIX兼容sh语法的遗留产物）

- `()`：子命令组，**另开一个子shell**执行，子shell中的变量不能够被外面部分使用。

- 路径

  - `/` ：斜杠，路径分隔符。
  - 路径简写
    - `~`：当前用户的家目录（一般等同于`$HOME`）
    - `-`：当前用户的上次工作目录
    - `..`：上一级目录
    - `.`：当前目录

- 引号

  - 单引号`' '`

    **成对的单引号中不能出现一个单独的单引号**（即`'''`），即使转义也不行，必须成对出现。表示单引号，可在双引号中使用。

    单引号内特殊字符**均无**特殊意义，但是一对单引号内部的单引号内部可使用`$`引用变量

    ```shell
    echo "'"    #'
    a=1
    echo '$a'   #$a
    echo ''$a'' #1
    ```

  - 双引号`" "`： 引号中除了` $ \ ""  （**反引号、美元符号、反斜杠和双引号**）外的特殊字符无特殊意义。    

    - 成对单引号位于双引号内，这对单引号内的特殊字符仍有其特殊意义（即该对单引号不能消除字符的特殊意义）。

      如`a=1; echo "'$a'"`输出内容为`'1'`而不是`$a`。

    - 双引号中可以出现任意个数单引号

      如`echo "aaa'bbbb"`输出`aaa'bbbb`

    - 如果要在双引号中表示双引号，必须对其中的双引号转义

      如`echo "aaa\"bbb"`输出`aaa"bbb`

- `&`：将命令放入后台执行。

- `:` 空命令

  - 在while中使用，可以认为`:`与shell的内建命令true相同，它的返回值是0
    `while :`等效于`while true`
  - 在其他地方可作为一行的占位符，例如if/then和function中没有执行的内容时可使用`:`占位（否则报错）

- 大括号`{}`展开：

  - 搭配`..`连续展开：`{1..10}`展开1到10
  - 搭配`,`分别展开：`{1,a,d}`分别展开为1、a和d

  技巧：使用变量保存展开式

  ```shell
  v1=$(echo {1..3})
  v2=$(echo {1..3} {10,20} 33)
  for i in $v1;do echo $i ;done #打印1 2 3
  for j in $v2;do echo $j ;done #打印1 2 3 10 20 33
  ```

  遍历展开式时，里面的不能使用变量，例如`a=5;for i in {1..$a};do echo $i; done`是不能正常遍历1到5的。

  技巧：cp、mv等命令操作长路径时进行简写

  ```shell
  mv /tmp/a-long-path-example/aaaa /tmp/a-long-path-example/aaaa.bak
  #简写：
  mv /tmp/a-long-path-example/{aaaa,aaaa.bak}
  ```

上述特殊字符与其他字符组合成的特殊意义（如`\`加上一些字符成为特殊意义的[控制符](#控制符) ），以及其余特殊符号如`[]`（测试表达式使用），归入后文各相关章节叙述。

## 通配符

- `?`    匹配1个字符

- `*`    匹配任意个数字符

  特别的：

  ```shell
  x=*
  echo $x  #打印出当前目录下所有文件（夹）名 ，与echo *输出一致
  ```

- `[]`    匹配括号内任意一个字符如`[ab]`匹配a或b或c）

  注意：条件判断中使用的`[]`见后文[测试表达式](#测试表达式)

  - `[-]`   匹配在编码顺序内的所有字符

    如`[a-z]`匹配a到z之中的任意字母，`[0-9]`匹配0到9之中的任意数字。

- `[^]`   匹配内容取反（如`[^abc]`匹配除了abc之外的字符）

- 专用字符集合

  小写字母：`[[:lower:]]`  大写字母：`[[:upper:]]`  数字：`[[:digit:]]`

  字母：`[[:alpha:]]`   数字：`[[:alnum:]]`

  空格：`[[:space:]]`   标点：`[[:punct:]]`

通配符与正则表达式差异见后文[正则表达式](#正则表达式) 。

## 控制符

[echo输出](#echo输出)命令中使用`-e`启用控制符

|    控制符    | 意义                                    |
| :----------: | :-------------------------------------- |
|  \a 或 \007  | 警告声/响铃（alert bell）               |
|  \b 或 \010  | 退格（backspace）                       |
|  \E 或 \033  | 退出/取消（escpae）                     |
|  \f 或 \014  | 换页符（formfeed）                      |
|  \n 或 \012  | 换行符（new line）                      |
|  \r 或 \012  | 回车（return）                          |
|  \t 或 \011  | 表格跳位/制表符（tab）                  |
|      \v      | 垂直表格跳位/垂直制表符（vertical tab） |
|      \c      | 取消行末换行符 （cancel）               |
|     \0nn     | 八进制数(nn表示八进制数)                |
|     \xhh     | 十六进制数(hh表示十六进制数)            |
| \e[ 或 \033[ | 字符转义为ANSI escape code              |

注意：退格键`\b`并不会在内容中删除`\b`前面一个字符，它**只是让光标**向前**移动**一格而已，回车键`\r`同理。

### ANSI escape code

`\e[`或`\033`是CSI，全称为“控制序列引导器”（Control Sequence Introducer/Initiator），能将字符转义成[ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code)

#### 显示样式和颜色

写法：在样式或颜色之后要使用m，如`1m`，如果使用颜色和样式，二者以`;`分隔，只在第二个数字后写上m即可，例如：`echo -e '\e[1;35m文字文字\e[0m'` 。

这些样式和颜色值是ANSI escape code中的[SGR](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes) ，某些SGR码支持并不广泛，以下列出常见SGR code。



- 样式：

  | 样式 | 加粗 | 弱化 | 斜体 | 下划线 | 闪烁 | 反色 | 隐藏 | 删除线 |
  | :--: | :--: | :--: | :--: | :----: | :--: | :--: | :--: | :----: |
  | 开启 |  1   |  2   |  3   |   4    |  5   |  7   |  8   |   9    |
  | 关闭 |  21  |  22  |  23  |   24   |  25  |  27  |  28  |   29   |

  **0恢复默认**样式。

  2弱化是指显示的颜色和粗细强度等减弱，22关闭弱化即使用普通效果（normal）。

  21具有关闭粗体或者设置双下划线的效果，不过几乎不被支持。		

  6/26（快速闪烁，每分钟闪烁150+次）较少被支持。

  10用于设置首选字体，11-19设置其他代替字体，20设置哥特体。

  

- 颜色

  |  颜色  |  黑  |  红  |  绿  |  黄  |  蓝  | 洋红 |  青  |  白  |
  | :----: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
  | 前景色 |  30  |  31  |  32  |  33  |  34  |  35  |  36  |  37  |
  | 背景色 |  40  |  41  |  42  |  43  |  44  |  45  |  46  |  47  |

  此外：38默认的前景颜色上设置下划线    39默认的前景颜色上关闭下划线    49默认背景色

  

#### 光标位置和键盘控制

参看ANSI escape code中中[CSI code](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes)

- 光标位置

  | 字符内容  | 光标位置说明               |
  | :-------- | :------------------------- |
  | \033[nA   | 上移n行                    |
  | \033[nB   | 下移n行                    |
  | \033[nC   | 右移n行                    |
  | \033[nD   | 左移n行                    |
  | \033[y;xH | 设置光标位置（第y行第x列） |
  | \033[K    | 清除从光标到行尾的内容     |
  | \033[s    | 保存光标位置               |
  | \033[u    | 恢复光标位置               |
  | \033[?25l | 隐藏光标                   |
  | \033[?25h | 显示光标                   |
  | \033[2J   | 清除屏幕                   |

- 键盘控制

  - \033[0q         　关闭所有的键盘指示灯 
  - \033[1q         　设置“滚动锁定”指示灯 (Scroll Lock) 
  - \033[2q         　设置“数值锁定”指示灯 (Num Lock) 
  - \033[3q         　设置“大写锁定”指示灯 (Caps Lock) 

  另参看stty和tput控制

  

## 逻辑符

- `; `  分号-- `a;b`   各命令间没有逻辑关系影响
- `&& `   逻辑与--`a&&b`    前面的命令正确执行，才能执行后面的命令
- `||`    逻辑或--`a||b`    前面的命令不能正确执行，就执行后面的命令



## 管道符

管道符pipeline  `|`

- 管道命令只处理前一个命令正确输出，不处理错误输出。（参看[标准输出重定向](#重定向)）

- 管道命令右边命令，必须能够接收标准输入流命令。 

  `a|b`    管道符前面命令a的**正确输出**，作为管道符后面命令b的操作对象。
  
- 管道中的每个部分都被创建为一个新的子进程

  每个子进程都会有自己的环境副本，包括变量。如果你在管道的一部分中修改了一个变量，这个修改只会影响到当前子进程的环境，而不会影响到其他子进程或父进程中的同名变量。



## 运算符

shell运算符包括：算数运算符、关系运算符、布尔运算符、字符串运算符和文件测试运算符。

### 算术运算符

同多数是编程语言一致，不再列出。**shell变量默认类型为字符串**，可使用以下方法进行数值运算（主要是整数运算）。

#### 整数运算

- `(())`表达式
  
  ```shell
  a=1
  b=2
  c=$(($a+$b))  #c为3
  ((b+=2))  #b为4
  ```

- `$[]`表达式
  
  ```shell
  var=1
  var=$[$var+1]
  echo $var
  ```

- `declare`命令
  
  ```shell
  a=1
  declare -i c = $a + 1  #声明为整数
  echo c    #c为2
  ```

- `expr`命令（非bash shell内建命令）
  
  expr命令后把的算式中，**操作符和操作数之间必须有空格**
  
  ```shell
  expr 17 \* 6    #102  整数运算  #要使用\对*进行转
  expr $var1 + $var2  #注意加号两侧空格
  ```

    此外`expr`还能操作字符串，参看[字符串处理](#字符串处理)

- `let`命令（bash shell内建命令）
  
  - 只能进行整数运算
  - 操作符和操作数之间**不能有空格**
  
  ```shell
  let a=1+1    #a为2
  let a++       #a为3
  let a-=2    #a为1
  echo $a   # 1
  ```

#### 浮点数运算

- bc命令（非bash shell内建命令）
  
  直接执行bc可以进入bc的交互命令行，直接使用即可，下不赘述bc的交互式命令行计算方法。
  
  ```shell
  #普通四则运算
  echo "1+1-1*1/1"|bc  #1
  #幂运算
  echo "2^10"|bc #1024
  #开方运算
  echo "sqrt(100)"|bc  #10
  ```
  
  - 浮点数精度
    
    ```shell
    echo "0.1+0.9"|bc  #1.0
    #scale设置小数精度
    echo "scale=2;1/3"|bc  #.33
    ```
  
  - 进制转换
    
    ```shell
    echo "obase=2;3"|bc  #十进制3转为二进制 结果为11
    echo "obase=10;ibase=2;11"|bc  #2进制11转为十进制 结果为3
    ```
    
    - ibase指明原数的进制（i, input默认十进制，十进制时可省略）
    - obase指明要目标进制（o, output）

#### 数字大小关系运算符

**关系运算符只支持整数**（全是数字组成的字符串）。另参看[字符串运算符](#字符串运算符)

`数字1 选项 数字2`根据各选项，将第一个数和第二个数对比，判断对比情况，返回true/false。

| 选项 | 说明                                  |
| :--: | :------------------------------------ |
| -eq  | 是否相等（equal）                     |
| -ne  | 是否不等（not equal）                 |
| -gt  | 是否更大（greater than）              |
| -lt  | 是否更小（less than）                 |
| -ge  | 是否大于等于（greater than or equal） |
| -le  | 是否小于等于（less than or equal）    |

示例：

```shell
test 2 -gt 3 && echo "front is big"
[[ $? -eq 0 ]] && echo "app is running"
```



### 字符串运算符

空和非空：`选项 字符串（或变量）` ；等和不等：`字符串1 选项 字符串2` ，根据各选项判断字符串情况，返回true或false。

| 选项  | 说明                                               |
| :---: | -------------------------------------------------- |
|  -z   | 字符串长度是否为0                                  |
|  -n   | 字符串长度是否不为0                                |
| ==或= | 是否相等                                           |
|  !=   | 是否不相等                                         |
|  =~   | 前一个字符串是否包含后一个字符串 仅支持[[ ]]中使用 |

注意：

- 建议使用`[[ ]]`而不是`[]`，如果使用`[]`必须要用`" "`把变量引起来。
  
  判断字符串是否为空的可靠的方法：`"x${value}" == "x"`

- 判断是否相等时，在`=` 、`==`或`!=`的**两侧一定要有空格**（`=`两侧不加空格是赋值）。

- 最好不要使用`=`或`!=`对数值进行判断（会被当作字符串进行对比）。

- `=~`后面的字符最好使用引号引起来，特殊字符（如通配符`*`）必须使用引号包裹，例如：

  ```shell
  str=haha*
  [[  $str =~ '*' ]] && echo find it  #打印find it
  [[  $str =~ * ]]   && echo find it  #不打印内容
  ```

  

### 布尔运算符

非运算：`! 表达式`；与/或运算：`表达式1 选项 表达式2` ，根据各表达式情况判断，返回true或false。

- !    非运算
- -o    或运算
- -a    与运算

### 逻辑运算符

`表达式1 选项 表达式2`

- &&    逻辑与
- ||    逻辑或

## 文件测试运算符

### 文件类型

` 选项 文件名`根据各选项，判断文件的某种情况，返回true或false。

| 选项 | 说明                                         |
| :--: | -------------------------------------------- |
|  -e  | 判断文件是否存在                             |
|  -f  | 判断文件是否存在，且是否为**普通**文件       |
|  -b  | 判断文件是否存在，且是否为**块设备**文件     |
|  -c  | 判断文件是否存在，且是否为**字符设备**文件   |
|  -d  | 判断文件是否存在，且是否为**目录**文件       |
|  -L  | 判断文件是否存在，且是否为块**符号链接**文件 |
|  -p  | 判断文件是否存在，且是否为**管道**文件       |
|  -s  | 判断文件是否存在，且是否为非空               |
|  -S  | 判断文件是否存在，且是否为**套接字**文件     |

### 文件权限

`选项 文件名`根据各选项，判断某项权限的情况，返回true或false。

| 选项 | 说明                               |
| :--: | ---------------------------------- |
|  -r  | 判断文件是否存在，且是否有读权限   |
|  -w  | 判断文件是否存在，且是否有写权限   |
|  -x  | 判断文件是否存在，且是否有执行权限 |
|  -u  | 判断文件是否存在，且是否有SUID权限 |
|  -g  | 判断文件是否存在，且是否有SGID权限 |
|  -k  | 判断文件是否存在，且是否有SBit权限 |

### 文件对比

`文件名1 选项 文件名2`根据各选项，将第一个文件和第二个文件对比，判断对比情况，返回true/false。

| 选项 | 说明                                        |
| :--: | ------------------------------------------- |
| -nt  | 判断文件修改时间是否更新                    |
| -ot  | 判断文件修改时间是否更晚                    |
| -ef  | 判断文件的Inode是否一致（一致则为同一文件） |

## 重定向符

> （数据流是）以规定顺序被读取一次的数据序列。

重定向是指将数据流重新定向到指定的位置。



### 标准输入/输出和标准错误输出

重定向指使用文件代替标准输入、标准输出和标准错误输出。

| 数据流类型            | 设备文件    | 文件描述符 | 重定向符号    |
| --------------------- | ----------- | ---------- | ------------- |
| 标准输入 (stdin)      | /dev/stdin  | 0          | `<`           |
| 标准输出 (stdout)     | /dev/stdout | 1          | `>` 或 `>>`   |
| 标准错误输出 (stderr) | /dev/stderr | 2          | `2>` 或 `2>>` |

- `>`表示覆盖方式重定向，`>>`表示追加方式重定向

  `>`相当于`1>`，标准输出重定向；`2>` 标准错误输出重定向。`>>`、`1>>`和`2>>`同理。

  ```shell
  command >log 2>err #等同于 command 1>log 2>err
  command >> log
  ```

- `&`（and）和`>`结合可以合并不同类型的数据流重定向

  - `>&2`或`1>&2`   把标准输出重定向到标准错误

    ```shell
    command > log >&2  #>&2要放到后面
    ```

  - `2>&1`   把标准错误输出重定向到标准输出

    ```shell
    command > log 2>&1  #2>&1要放到后面
    ```

  - `&>`   准输出和标准错误输出都重定向到指定位置

    ```shell
    command &>log
    ```

  执行`set -C`，可以在当前shell中禁止重定向覆盖已有文件；`set +C`允许覆盖已有文件。

  ```shell
  touch a
  set -C
  echo "" > a  #提示 无法覆盖已存在的文件
  #使用|可以强制重定向覆盖已有文件
   echo "sdfds" >| a
  ```

  如果希望执行某个命令，但又不希望输出结果，重定向到特殊位置：

  - `command > /dev/null`   - `/dev/null`是一个空文件

  - `command > /dev/zero`   - `/dev/zero`是一个无显示的无限输入文件

- `<` 表示从标准输入读取文件

  ```shell
  wc -l /etc/environment  #输出：9 /etc/environment
  #从标准输入读取内容再交由wc处理
  wc -l < /etc/environment  #类似cat /etc/environment | wc -l  输出：9
  ```

- 循环的重定向参看[循环](#循环)

### Here Document和Here String输入重定向

- Here Document：使用`<<`符号将多行输入（两个同名标记之间的内容）传递给命令的标准输入（stdin）

  - 标记可以是任意名字，`EOF` 是一个常被使用的标志名。

  - 开始标记后面可使用输出重定向符合、管道符号。

  - 结束标记必须单独一行顶格写，且后面不能有内容（注释或空格等也不行）

  - `<<`后面添加`-`，即`<<-`，将会忽略分隔符中内容行的制表符（Tab）。

  ```shell
  cat << EOF
      Hello  #如果空白是Tab，将被忽略（输出内容忽略Tab）
    she    l  l   #如果空白是空格，空格仍然有效
  EOF
  
  mysql << EOF ｜ tee db-list.txt  #将输出内容写入db-list.txt
  show databases;  #本行sql语句将交由mysql程序执行
  EOF
  ```
  
  

- Here String：使用`<<<`符号将单行字符串直接传递给命令的标准输入（stdin）

  - 字符串如果有空白分隔符（IFS，如空格），要使用引号包裹字符串
  - Here String 会自动在字符串末尾添加换行符，若需去除，可用 `printf`，如`<<$(printf %s 'aaa')`
  - Here String 后面的内容如果以引号包裹，引号内部也能使用换行符，但是输入的内容在语法上是单一行，换行符是字符串的一部分，而非 Shell 的语法换行。
  
  ```shell
  tr a-z A-Z <<< 'hello shell' #输出 HELLO SHELL
  
  mysql -uroot <<< 'show databases;
  select user from mysql.user;
  '
  ```
  



### tee重定向

命令tee可以将数据重定向到给定文件和屏幕上。

常用参数：

- `-a`：向文件中重定向时使用追加模式
- `-i`：忽略中断（interrupt）信号

```shell
who | tee users.txt
echo "alias rm='mv'" | tee -a .bashrc
```

## 测试表达式

各类参见运算符号（除算术运算）中各个运算符使用说明：[数值关系判断](#关系运算符)、[字符串运算符](#字符串判断)、[布尔运算符](#布尔值判断)、[逻辑运算符](#逻辑判断)和[文件测试运算符](#文件判断)。

测试表达式会返回状态码（参看[预定义变量](#预定义变量)中的`$?`），0表示执行正确（true），1执行错误（false）。

- `test`关键字：`test 表达式`

- 单中括号`[ ]`和双中括号`[[ ]]`：`[ 表达式 ]` 和`[[ 表达式 ]]`

  - sh不支持`[[ ]]`
  - **`[ ]`在参数只是一个变量时，会把变量当字符串** 。（类似单双引号）
  - `[[ ]]`内部支持`&&`  `||`  `<`  `>` 操作符，`[ ]`只能在外部使用逻辑操作符`&&`  `||` 
  - 这两个命令作用同`test`（相当于是`test`的别名）。
  - 表达式与括号`[]`或`[[ ]]`之间**必须有空格** ，因为`[`和`[[`是linux内部命令（不过，算数运算中的`$[]`不需要有空格）。

注意：如果设置了`set -e`，测试表达式的结果非0会立即退出当前shell，如果不希望这种行为，应当使用if表达式，例子

```shell
set -e
[[ -d /tmp/1 ]] && echo yes         #如果/tmp/1不存在，返回1，执行完[[ -d /tmp/1 ]]立刻退出
if [[ -d /tmp/1 ]];then echo yes;fi ##如果/tmp/1不存在，返回0，会继续执行
echo end
```

# 流程控制

- 如果两条命令写在一行，每条命令后面需要添加`;`进行间隔。

## 分支

### 单分支

```shell
if [ expression ]
then
    #some codes
fi
#或者这样写
if [ expression ]; then
    #some codes
fi
```

利用[测试表达式](#测试表达式)和[逻辑符](#逻辑符)简写if语句：

- if判断为真的语句简写：`[[ 判断语句 ]] && 要执行的代码`
- if判断为假的语句简写：`[[ 判断语句 ]] || 要执行的代码`

```shell
if [[ -f /etc/profile ]];then echo 'found it';fi
#改写
[[ -f /etc/profile ]] && echo 'found it'

if [[ ! -f /sfdsfa/sdfdsf ]];then echo 'nof found';fi
#改写
 [[ -f /sfdsfa/sdfdsf ]] || echo 'nof found'
```

### 双分支

```shell
if [ expression ]
then
    #some codes
else
    #some codes
fi
```

### 多分支

#### 多分支if

```shell
if [ expression ]
then
    #some codes
elif [ expression ]
then
    #some codes
else
    #some codes
fi
```

#### 多分支case

```shell
case $var in
  pattern1)
  #some codes
  ;;  ##;;跳出（相当于break）
  pattern2 | pattern3) 
    #some codes
  ;;
  [a-z])
    #some codes
  ;;
*)    #最后一个默认分支的值使用*
    #some codes
;;
esac
```

case 语句中每个分支中匹配的是一种模式，模式可使用通配符。

匹配模式中可是使用方括号表示一个连续的范围，如`[0-9]`

使用竖杠符号`|`分隔两个模式表示逻辑或。

`*）`表示默认模式。

## 循环

- 跳出循环：`break`
- 结束当前迭代，进入下一次迭代：`contiune`
- 循环的输入输出重定向：在`done`后面添加重定向，例如`done > output.txt` 、`done | wc -l`、`done < file1`等。
- 后台执行重定向：在`done`命令后面添加`&`
- `getops`根据用户指定的每个选项执行所需要的操作，没有找到要求的参数，它会将问号保存到变量中并向标准错误中输出错误信息。

### for循环

```shell
for var in value1 value2 value3 #遍历值列表
for var in ${arr[*]}            #遍历数组
#for var in $(cat testfile)     #从文件中获取要遍历的值列表

for ((i=1;i<=10;i=i+1)) #注意：shell中不能写i+=1
do
  echo $i
done
```

使用展开符号简写循环语句：

```shell
for i in {1..10}  #相当于for ((i=1;i<=10;i=i+1)) 
do
  echo $i
done
```

此外还有`{a..z}` 、`{A..Z}`

### while循环和util循环

- while循环：expression中条件为真时进行循环：
  
  ```shell
  while [ expression]
  do
      #some codes
  done
  ```
  
  **无限循环`while true`可以简写为`while :`，或者用for语句简写为`for (( ; ; ))`。**
  
  while循环按行读取和处理文件：
  
  ```shell
  while read line
  do
    #处理每行
    echo $line #line就是每行的内容
  done < filename
  
  #也可使用
  cat filename | while read line
  do
      echo $line
  done
  ```
  
  遍历目录：
  
  ```shell
  #对于有空格的情况，这种方法便利可以
  ls -1 | while read line:
  do
    echo "do sth for $line"  #带上引号，避免某些操作因为文件名有空格出现错误而中断
  done
  ```

- until循环：**与while相反**，expression中条件为**假**时进行循环：
  
  ```shell
  util [ expression ]
  do
      #some codes
  done
  ```

# 函数

## 声明和调用

```shell
#声明
function fn () {
    # action
    echo $1 $2
    return <int>;
}
#调用
fn [参数] [参数] [...]
```

- `function`关键字和函数名后面的小括号可以省略。
- 函数名中的小括号中不能写参数，使用参数参看下面的[函数参数](#函数参数)。
- 函数调用的参数写在函数名后即可（空格隔开）。
- 可使用readonly定义只读函数；可使用`export`输出函数为环境变量。
- 函数中在变量前适用`local`可使得该变量仅作用于函数内部。



## 返回值

- echo输出返回值，从标准输出中获取返回的值。
  
  ```shell
  function getVal(){
      echo 'hello shell'
  }
  str=$(getVal)  #hello shell
  ```

- ruturn返回状态码
  
  返回的状态码只能是0 ~ 255，上一条命令的状态码为`$?`。
  
  如果没有使用return语句返回状态码，则返回最后一条命令执行结果的状态码。
  
  *如果只有true和false状态，一般约定以0表示true，1表示flase。*
  
  ```shell
  function getVal(){
      return 255
  }
  getVal
  echo $?   #255
  ```

- 赋值给全局变量：将要返回的内容写到一个全局变量中。
  
  ```shell
  function getVal(){
      str="a global var"
  }
  getVal
  echo $str   #a global var
  ```



# shell程序参数处理

在shell脚本中处理调用时传递的选项参数。

## 使用预定义变量和位置参数变量处理

大多数简单的命令使用[多分支](#多分支)和[预定义变量](#预定义变量)及[位置参数变量](#位置参数变量)判断处理传入的参数。

脚本示例para.sh

```shell
case "$1" in
    -h|--help)
        echo "help docs"
    ;;
    -v|--version)
        echo "ver 1.0"
    ;;
    *)
        echo "content: $1"
    ;;
esac
```

使用示例：

```shell
./para.sh -v  #ver 1.0
./para.sh haha  #content: haha
```



## getopts处理单字符短选项

`getopts`是shell内置方法，仅支持单字符的短选项（例如`-a`形式），选项和参数之间用空格隔开。

```shell
getopts OPTSTRING VARNAME [ARGS...]  #ARGS默认是 $@，即传入 Shell 脚本的全部参数
getopts ':a:bc:' opt
```

上面例子 `':a:bc:'`中：第一个`:`表示如果输入错误则忽略错误，`a`或`c`后面各自有一个`:`，表示该选项需要接受一值，而`b`后面没有冒号表示这个参数不需要传值。

注意：**不能使用冒号 `:` 和问号 `?` 来作为选项。**



`getopts`的相关内置变量：

- `OPTIND`：option index，逐个递增，初始值为1。

  getopts 在解析传入 Shell 脚本的参数时（也就是 $@），不会更改位置参数的设置，如要将位置参数移位，必须仍使用 shift 命令来处理位置参数（具体参看下文的例子），当没有内容可以解析时，getopts 会设置一个退出状态 FALSE。

  OPTIND保留最后一次调用getopts的选项的索引值，shell不会重置OPTIND的值，通常的做法是在处理循环结束时调用shift命令，从`$@`中删除已处理的选项。

  ```shell
  shift $((OPTIND -1))  #每次循环处理选项后将OPTIND值减去1
  ```
  例如`test.sh abc -s yes`，处理完所有选项后，使用`$@`就能取到`abc`这个参数。

- `OPTARG` ：option argument，选项对应的值。

  getopts 在解析到选项的参数时，就会将参数保存在 OPTARG 变量当中；如果 getopts 遇到不合法的选项，择把选项本身保存在 OPTARG 当中。

- `OPTSTRING`： 记录合法的选项列表（以及参数情况)

- `VARNAME`：传入一个 Shell 变量的名字，用于保存 getopts 解析到的选项的名字（而不是参数值，参数值保存在 OPTARG 里）



脚本示例test.sh：

```shell
while getopts ':a:bc:' opt
do
  case $opt in
    a)
      a=$OPTARG ;;
    b)
      echo "val is not necessary for option b" ;;
    c)
      c=$
      ;;
  esac
  shift $((OPTIND -1))  #删除已处理的选项内容
done
echo $@  #去除掉解析完成的选项及其值后的剩余参数
echo $1  #除掉解析完成的选项及其值后的剩余内容的第1个参数
echo $#  #去除掉解析完成的选项及其值后的剩余的参数
```

使用示例：

```shell
bash test.sh -a 111 -b -c 222
```



在function中使用getopts，调用时需要传入所有位置参数变量`"$@"`，否则函数内的getopts获取不到任何选项参数，示例：

```shell
function get_args(){
  while while getopts ':a:bc:' opt; do 
      #...
  done
}
get_args "$@"    #传入
```



## getopt处理长/短选项参数

getopt 不是bash的内置命令，它支持单横线的短选项和单/双横线的多个字符的长选项（例如`-arg`或`--arg`）。

```shell
getopt [options] -o|--options optstring [options] [--] parameters
getopt -o ab:c:: --long along,blong:,clong:: -n "$0" -- "$@"
```

上面例子中：

- `-o`或`--options` 选项后面是可接受的短选项

  - 如果选项后面没有冒号表示该选项不接收参数

  - 如果选项后面有一个`:`表示必须接收一个参数，如`b:`
  - 如果选项后面有两个冒号，表示选项参数为可选，如`c::`，但是使用时参数必须紧跟在选项名后面不能有空格等空白字符，例如`./test.sh -cName`中`Name`时`-c`对应的参数

- `-l`或`--long`  选项后面是可接受的长选项，用逗号分开，冒号的意义同短选项。

  使用时，长选项可用`=`来连接参数，例如`--file=/path/to/file`

- `-n`  选项后接选项解析错误时提示的脚本名字

- `--`后面接收不需要指定对应选项的参数

getopt其他常用的选项

- `-a`或`--alternative`   允许在长选项前面只使用单个`-`



脚本示例test.sh：

```shell
#!/bin/bash
echo original parameters=[$@]

ARGS=`getopt -o hf:o:: --long help,file:,optional:: -n "$0" -- "$@"`
if [ $? != 0 ]; then
    echo "parse parameters failed"
    exit 1
fi

eval set -- "${ARGS}"

while true
do
    case "$1" in
        -h|--help) 
            echo "help"
            shift
            ;;
        -f|--file)
            echo "file: $2"
            shift 2
            ;;
        -o|--optional)
            case "$2" in
                "")
                    echo "Option o / optional, no argument"
                    shift 2  
                    ;;
                *)
                    echo "Option o / optional, argument '$2'"
                    shift 2;
                    ;;
            esac
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "fatal error, usage: $0 [-h] [-f file] [-o [optional]]"
            exit 1
            ;;
    esac
done

#处理剩余的参数
echo remaining parameters=[$@]
#do something
```



## shift向左移动位置参数

shift命令位置参数向左移动，也就是将第一个参数给去掉。

示例脚本`run`：

```shell
#!/bin/bash
while [ $# != 0 ]
do
echo "prama is $1,prama size is $#"
shift
done
```

运行`run a b c`，返回内容为：

> prama is a,prama size is 3
> prama is b,prama size is 2
> prama is c,prama size is 1



# 调用外部脚本

- fork，即直接执行外部脚本
  
  fork是linux的系统调用，其将为当前shell创建一个子进程以执行外部脚本，子进程从父进程那里获得一定的资源分配以及继承父进程的环境。
  
  fork的子进程集成父进程的变量，子进程中定义的变量在父进程中无效。
  
  - 如果脚本有执行权限：`path/to/file.sh`
  - 如果没有执行权限：`sh path/to/file.sh`

source和exec是shell内建命令。

- `.`或`source`  将外部脚本放在**当前shell环境中**执行
  
  相当于将外部脚本内容插入到source位置（“合并成一个脚本执行”）。
  
  注：被引用的文件可以没有可执行权限；在`()`中source外部脚本，外部脚本中的变量不会影响当前shell。
  
  - `. path/to/file.sh`
  - `source path/to/file.sh`

- **exec**： `exec path/to/file.sh`
  
  exec与source区别在于**exec所在行后面的命令将不再执行**。
  
  ```shell
  echo 'touch bye' > test.sh
  exec sh test.sh  #执行test.sh 创建了一个名为bye的文件
  echo 'hello' > bye  #这条命令不会被执行
  ```

# exit退出状态码

`exit n` n为返回的状态码，如果不指定，则根据情况返回0或1。可使用`$?`获取状态码。

```shell
whoami
[[ $? -eq 0 ]] && echo "ok"
```

附常用状态码：

- 0         命令成功结束
- 1         通用未知错误
- 2         误用shell内建命令
- 126     命令不可执行
- 127     没找到命令
- 128     无效退出参数（例如exit 2.1，因为exit不接受整数0-255之外的任何值）
- 128+n 信号"n"的致命错误
- 130     通过Ctrl + C 终止
- 255     超出范围的退出状态（exit只能够接受范围是0 - 255的整数作为参数）



# trap 捕捉退出信号

内建命令trap可以捕捉当前shell的退出信号，以实现在退出时执行特定指令。

```shell
#trap 捕捉到信号之后，可以有3种反应方式：  

#1. 捕捉到信号时执行特定指令
trap <do_something> <signal_1> [signal_2, ...]

#2. 捕捉到信号时什么也不做，需要使用空字符串占位
trap '' KILL

#3. 捕捉到信号时接受信号的默认操作
trap <signal_1> [signal_2, ...]
```

`trap -l`可以查看所有信号，信号名以SIG（signal缩写）开头，并有一个对应的数值代号。

trap命令中捕捉到信号可使用代号或名字，但是使用信号名字时无需前面的SIG字符。

常用的信号如：

| 代号 | 名称    | 说 明                                                        |
| ---- | ------- | ------------------------------------------------------------ |
| 1    | SIGHUP  | 该信号让进程立即关闭.然后重新读取配置文件之后重启            |
| 2    | SIGINT  | 程序中止信号，用于中止前台进程。相当于输出 Ctrl+C 快捷键     |
| 3    | SIGQUIT | 和SIGINT类似，但由QUIT字符(通常是Ctrl+\)来控制。进程在因收到SIGQUIT退出时会产生core文件，在这个意义上类似于一个程序错误信号。 |
| 8    | SIGFPE  | 在发生致命的算术运算错误时发出。不仅包括浮点运算错误，还包括溢出及除数为 0 等其他所有的算术运算错误 |
| 9    | SIGKILL | 用来立即结束程序的运行。本信号不能被阻塞、处理和忽略。般用于强制中止进程 |
| 14   | SIGALRM | 时钟定时信号，计算的是实际的时间或时钟时间。alarm 函数使用该信号 |
| 15   | SIGTERM | 正常结束进程的信号，kill 命令的默认信号。如果进程已经发生了问题，那么这 个信号是无法正常中止进程的，这时我们才会尝试 SIGKILL 信号，也就是信号 9 |
| 18   | SIGCONT | 该信号可以让暂停的进程恢复执行。本信号不能被阻断             |
| 19   | SIGSTOP | 该信号可以暂停前台进程，相当于输入 Ctrl+Z 快捷键。本信号不能被阻断 |

处理以上Linux的标准信号外，Bash程序还有一个特别的信号`EXIT`，当退出当前shell时总是产生。

注意trap行应当放在要捕捉相关信号可能会出现的位置之前。

示例：

```shell
#在sleep期间中断执行（如按下Ctrl+C）会打印Exit now!
trap "echo exit now!" INT QUIT KILL TERM
sleep 233
```

在shell脚本中使用trap捕捉退出信号，可以让程序更健壮，示例：

```shell
#!/bin/bash
unalias -a
set -euo pipefail

trap finished EXIT  #退出时调用finished函数

function finished(){
    echo "exited"
    #some codes
}

adfa  #命令不存在报错退出
```





# 调试

- 执行脚本时使用`-x`参数：`bash -x test.sh`

- 在脚本中`set -x`和`set +x`进行部分调试（二者分别是调试开始和调试结束的标志）
  
  ```shell
  for i in {1..10}
  do
    set -x
    echo $i
    set +x
  done
  echo "script execited"
  ```
  
  `set -v`和`set +v`  分别是命令执行时打印输入和和停止打印输入的标志。

- `set -e`   执行到指令传回值不等于0时立即退出

- `set -u`   如果引用了未定义变量时立即退出

- `set -n`  只读取指令，而不实际执行

- 在shebang后添加`xv`参数
  
  ```shell
  #!/bin/bash -xv
  ```

