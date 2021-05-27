[TOC]

# 简介

## 概念

Shell 是一个用 C 语言编写的程序，Shell 既是一种命令语言，又是一种程序设计语言。

> Shell 是指一种应用程序，这个应用程序提供了一个界面，用户通过这个界面访问操作系统内核的服务。
>
> Ken Thompson 的 sh 是第一种 Unix Shell，Windows Explorer 是一个典型的图形界面 Shell。

## shell分类

- Bourne：常见的是sh(Bourne Shell)和bash(Bourne Again Shell)，还有fish、zsh等等
- C：cshell、tcsh（BSD的Unix)

本文以bash为基础。查看当前shell

```shell
echo $SHELL    #查看当前使用的shell
cat /etc/shells    #查看当前系统支持的shell
```

## bash shell脚本文件

- 扩展名sh：脚本文件**可以不使用扩展名** （但是使用扩展名sh，shell可以为代码提供颜色高亮）。

- 解释器：在脚本文件开始时使用shebang指定解释器，例如`#!/bin/sh`指定sh作为解释器。

  shebang，即sharp--`#`和ban--`!`的联合缩写。

- 为脚本添加执行权限：`chmod +x file.sh`。

- 执行脚本：

  - 脚本有可执行权限：`./file.sh`
  - 脚本无可执行权限：`bash file.sh`

- 命令别名alias和type

  - alias 为某个命令设置别名
  - type 查看某个别名命令（如果它被alias定义过）对应的内容

  示例：

  ```shell
  alias ll=`ls -al --color=auto`  #执行ll就等于执行ls -al --color=auto
  type ll  #查看ll对应的命令内容 ls -al --color=auto
  ```

- 命令优先级顺序：绝对/相对路径执行命令 > 别名 > bash内部命令 > $PATH环境变量定义的目录查找顺序的第一个命令 。

- bash相关配置文件的执行顺型，**一般是**（注意：以下某些文件可能缺失）：

   1. `/etc/profile/`
   2. `/etc/profile.d/`下面的文件（具体要看`/etc/profile`中的相关代码）
   3. `$HOME/.bash_profile`
   4. `$HOME/.bash_login`
   5. `$HOME/.profile`
   6. `$HOME/.bashrc`

## bash shell运行模式

- 登录
- 交互（普通的输入模式）
- 非交互（如直接运行某个脚本）

```shell
echo $-	
```

可能输出的是`himBH`：

> - `h`: 以*Hash*方式缓存环境变量`$PATH`中的可执行文件，用来加速命令执行。
> - `i`: 表示*Interactive*，当前shell是可交互的。
> - `m`: 启用*Job control*，Bash的工作控制功能。
> - `B`: 启用*Brace expansion*，使得shell可以展开`*`，`?`这些形式的命令。
> - `H`: 启用*History substitution*，Bash的历史机制啦，`history`，`!`这些。



## bash 配置文件

|          文件           |                             描述                             | 登录 shell(见下) | 交互 shell非登录 |
| :---------------------: | :----------------------------------------------------------: | :--------------: | :--------------: |
|     `/etc/profile`      | [加载](https://wiki.archlinux.org/index.php/Help:Reading_(简体中文)#Source)全部储存在 `/etc/profile.d/*.sh` 和 `/etc/bash.bashrc` 中的配置。 |        是        |        否        |
|    `~/.bash_profile`    | 针对每个用户，紧接 `/etc/profile` 执行。如果这个文件不存在，会顺序检查 `~/.bash_login` 和 `~/.profile` 文件。框架文件 `/etc/skel/.bash_profile` 同时会引用 `~/.bashrc`。 |        是        |        否        |
|    `~/.bash_logout`     |              针对每个用户，退出登录 shell 后。               |        是        |        否        |
| `/etc/bash.bash_logout` | 取决于 `-DSYS_BASH_LOGOUT="/etc/bash.bash_logout"` 编译标记。退出登录 shell 后。 |        是        |        否        |
|   `/etc/bash.bashrc`    | 取决于编译标志 `-DSYS_BASHRC="/etc/bash.bashrc"`。加载 `/usr/share/bash-completion/bash_completion`配置。 |        否        |        是        |
|       `~/.bashrc`       |         针对每个用户，在 `/etc/bash.bashrc` 后加载。         |                  |                  |

- 如果以 `--login` 调用，登录 shell 可能不是交互式的。
- `--noproflie`忽略任何配置文件，`--norc`忽略交互模式中用户个人的`.bashrc`配置文件。

# 基础

## 基本特殊符号

- `#`：注释符号。

- `\`：反斜杠，转义符，将后一个特殊字符转为普通字符。

- 命令替换：在命令行中使用命令的输出来替换特定的命令。

  - `$()`：括号内部的内容是系统命令，会最先执行。（建议）
  - ``：反引号，其内部的反斜杠无转义功能。（不建议，属于早期非POSIX兼容sh语法的遗留产物）

- `()`：子命令组，**另开一个子shell**顺序执行，其中的变量不能够被外面部分使用。

- 路径

  - `/` ：斜杠，路径分隔符。
  - 路径简写
    - `~`：当前用户的家目录
    - `-`：当前用户的上次工作目录
    - `..`：上一级目录
    - `.`：当前目录

- 引号

  - 单引号`' '`：引号内特殊字符**均无**特殊意义。

    **单引号中不能出现一个单独的单引号**，即使转义也不行，必须成对出现。

  - 双引号`" "`： 引号中除了` $ \ ""  （**反引号、美元符号、反斜杠和双引号**）外的特殊字符无特殊意义。​	

    - 成对单引号位于双引号内，若该对单引号中有特殊字符，该对单引号不能消除特殊字符的意义。

      如：`a=1; echo "'$a'"`输出内容为`'1'`而不是`$a`。
    
    - 双引号中可以出现任意个数单引号   `"aaa'bbbb"`
    
    - 双引号中的双引号必须转义  `"aaa\"bbb"`

- `&`：将命令放入后台执行。

- `:`：空命令。

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

上述特殊字符与其他字符组合成的特殊意义（如`\`加上一些字符成为特殊意义的[控制符](#控制符) ），以及其余特殊符号如`[]`（测试表达式使用），归入后文各相关章节叙述。

## 多命令执行符号

### 逻辑符

- `; `  分号-- `a;b`   各命令间没有逻辑关系影响
- `&& `   逻辑与--`a&&b`    前面的命令正确执行，才能执行后面的命令
- `||`    逻辑或--`a||b`    前面的命令不能正确执行，就执行后面的命令

### 管道符

管道符pipeline  `|`

- 管道命令只处理前一个命令正确输出，不处理错误输出。（参看[标准输出重定向](#重定向)）

- 管道命令右边命令，必须能够接收标准输入流命令。 

 `a|b`    管道符前面命令a的**正确输出**，作为管道符后面命令b的操作对象。

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

注意：退格键\b并不会在内容中删除\b前面一个字符，它**只是让光标**向前**移动**一格而已，回车键\r同理。

|   控制符   | 意义                                    |
| :--------: | :-------------------------------------- |
| \a 或 \007 | 警告声/响铃（alert bell）               |
|  \b或\010  | 退格（backspace）                       |
|  \E或\033  | 退出/取消（escpae）                     |
|  \f或\014  | 换页符（formfeed）                      |
|  \n或\012  | 换行符（new line）                      |
|  \r或\012  | 回车（return）                          |
|  \t或\011  | 表格跳位/制表符（tab）                  |
|     \v     | 垂直表格跳位/垂直制表符（vertical tab） |
|     \c     | 取消行末换行符 （cancel）               |
|   \0nnn    | 八进制数(nnn表示八进制数)               |
|    \xhh    | 十六进制数(hh表示十六进制数)            |
| \e[或\033[ | 字符转义为ANSI escape code              |

### ANSI escape code

`\e[`或`\033`是CSI，全称为“控制序列引导器”（Control Sequence Introducer/Initiator），能将字符转义成[ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code)

#### 显示样式和颜色

写法：在样式或颜色之后要使用m，如`1m`，如果使用颜色和样式，二者以`;`分隔，只在第二个数字后写上m即可，例如：`echo -e '\e[1;35m文字文字\e[0m'` 。

这些样式和颜色值是ANSI escape code中的[SGR](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes) ，某些SGR码支持并不广泛，以下列出常见SGR code。

- 样式：
|  样式  |  加粗  |  弱化  |  斜体  | 下划线  |  闪烁  |  反色  |  隐藏  | 删除线  |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
|  开启  |  1   |  2   |  3   |  4   |  5   |  7   |  8   |  9   |
|  关闭  |  21  |  22  |  23  |  24  |  25  |  27  |  28  |  29  |
**0恢复默认**样式。2弱化是指显示的颜色和粗细强度等减弱，22关闭弱化即使用普通效果（normal）。21具有关闭粗体或者设置双下划线的效果，不过几乎不被支持。

此外：6/26（快速闪烁，每分钟闪烁150+次）较少被支持；10用于设置首选字体，11-19设置其他代替字体，20设置哥特体。

- 颜色
|  颜色  |  黑   |  红   |  绿   |  黄   |  蓝   |  洋红  |  青   |  白   |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| 前景色  |  30  |  31  |  32  |  33  |  34  |  35  |  36  |  37  |
| 背景色  |  40  |  41  |  42  |  43  |  44  |  45  |  46  |  47  |

此外：38默认的前景颜色上设置下划线    39默认的前景颜色上关闭下划线    49默认背景色

#### 光标位置和键盘控制

参看ANSI escape code中中[CSI code](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes)

- 光标位置

| 字符内容      | 光标位置说明         |
| :-------- | :------------- |
| \033[nA   | 上移n行           |
| \033[nB   | 下移n行           |
| \033[nC   | 右移n行           |
| \033[nD   | 左移n行           |
| \033[y;xH | 设置光标位置（第y行第x列） |
| \033[K    | 清除从光标到行尾的内容    |
| \033[s    | 保存光标位置         |
| \033[u    | 恢复光标位置         |
| \033[?25l | 隐藏光标           |
| \033[?25h | 显示光标           |
| \033[2J   | 清除屏幕           |

- 键盘控制
  - \033[0q         　关闭所有的键盘指示灯 
  - \033[1q         　设置“滚动锁定”指示灯 (Scroll Lock) 
  - \033[2q         　设置“数值锁定”指示灯 (Num Lock) 
  - \033[3q         　设置“大写锁定”指示灯 (Caps Lock) 

## 重定向

> （数据流是）以规定顺序被读取一次的数据序列。

重定向是指将数据流重新定向到指定的位置。

### 标准输入/输出和错误输出重定向

重定向指使用文件代替标准输入、标准输出和标准错误输出。

| 数据流类型            | 设备文件    | 文件描述符 | 重定向符号    |
| --------------------- | ----------- | ---------- | ------------- |
| 标准输入 (stdin)      | /dev/stdin  | 0          | `<`           |
| 标准输出 (stdout)     | /dev/stdout | 1          | `>` 或 `>>`   |
| 标准错误输出 (stderr) | /dev/stderr | 2          | `2>` 或 `2>>` |

- `>`表示覆盖方式重定向，`>>`表示追加方式重定向

  `>`其实相当于`1>`，只会将标准输出重定向。

  ```shell
  command >log 2>err #等同于 command 1>log 2>err
  command >> log
  ```

- `&`（and）可以合并不同类型的数据流重定向
  
  - `>&2`或`1>&2`   把标准输出重定向到标准错误
  
    ```shell
    command > log >&2  #>&2要放到后面
    ```
  
  - `2>&1`   把标准错误输出重定向到标准输出
  
    ```shell
    command > log 2>&1  #2>&1要放到后面
    ```
  
  - `&>` 	准输出和标准错误输出都重定向到指定位置
  
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
  
  如果希望执行某个命令，但又不希望输出结果:
  - `command > /dev/null`   - `/dev/null`是一个空文件
  - `command > /dev/zero`   - `/dev/zero`是一个无显示的无限输入文件
  
- `<` 表示从标准输入读取文件

  ```shell
  wc -l /etc/environment  #输出：9 /etc/environment
  #从标准输入读取内容再交由wc处理
  wc -l < /etc/environment  #类似cat /etc/environment | wc -l  输出：9
  ```

- 循环的重定向参看[循环](#循环)

### Here Document和Here Strings重定向

- Here Document：`<<`用来将输入重定向到一个交互式 Shell 脚本或程序，两个标志（可以是任意名字，`EOF` 是一个常被使用的标志名）之间的内容作为输入内容交由`<<`前面的命令处理。

  `<<`后面添加`-`，即`<<-`会忽略行首的制表符。

  ```shell
  wc -l << EOF
      Hello
      shell
  EOF
  2          # 输出结果为 2 行
  ```

- Here Strings：`<<<`后面的字符串作为标准输入交由前面的命令处理。

  ```shell
  tr a-z A-Z <<< 'hello shell'
  HELLO SHELL
  ```

### tee重定向

tee可以将数据重定向到给定文件和屏幕上。

常用参数：

- `-a`：向文件中重定向时使用追加模式
- `-i`：忽略中断（interrupt）信号

```shell
who | tee users.txt
echo "alias rm='mv'" | tee -a .bashrc
```

## 输出输入命令

### echo输出

选项：

-  `-e`   启用[控制符](#控制符)转换
-  `-E`  关闭[控制符](#控制符)转换
-  `-n`  不在末尾输出空行（同[控制符](#控制符)中`\c` ）

输出的内容最好加上引号，否则在某些情况下会出问题（如使用空格、控制符号等的时候）。
```shell
echo a  #输出test
echo a\nb    #输出anb
echo -e 'a\nb'    #输出a (换行) b
```

### printf输出

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
#!/bin/sh
printf "%-10s %-8s %-4s\n" 姓名 性别 身高
printf "%-10s %-8s %-4.2f\n" 人甲 男 177.7111
printf "%-10s %-8s %-4.2f\n" 人乙 女 168.8222
```

%-10s 指一个宽度为10个字符，字符左对齐。%-4.2f 指格式化为小数，其中.2指保留2位小数。

将输出：

```shell
姓名     性别   身高
人甲     男      177.7
人乙     女      168.8
```

### read输入

选项：

- -p   提示信息
- -t    等待时间（单位：秒）
- -d   持续读取直到读入定界符（delimiter）为止
- -r    不允许反斜杠转义任何字符
- -n   指定接收输入的字符数
- -s    不显示输入的数据，用于机密信息的输入（如密码）

```shell
read -p "please input username:"
read -s -p "please input password:"
read -p "请输入名字：" name  #将用户的输入内容赋值给name变量
#使用-d -r 将多行内容存到一个变量中
read -d -r '' msg << TIP
You should reboot system after installation.\n
Good Luck!\n
TIP
echo $msg    #将会输出那两行提示内容 TIP是界定符 两个TIP间的内容被存到msg变量中
```

# 变量

## 定义和使用

直接赋值即可：`变量名=值`，如`var1=123`

这样定义的变量被称为用户变量，**仅在当前shell及其子shell中生效**。

默认情况下，shell均以字符串存储，需要根据上下文来确定类型进行操作。

- declare声明变量类型。

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

- 定义只读变量（和函数）：`readonly 变量名`

- 删除变量：`unset 变量名 `

- 调用变量：`$变量名`或`${变量名}`，如 `$var1`或者`${var1}` 

  无大括号是简写方法，需要**使用`{}`的情况**：

  - 如果变量后面跟一个**非小写字符串、数字或下划线**   `${var}_1`

  - [位置参数变量](#位置参数变量)中**第10个及以后的参数的写法**

  - 增加可读性或避免混淆  例如`${var}test`和`$vartest`

  - 如果变量的值的内容中含有换行符时，务必要使用双引号`""`包含变量，否则换行将被去掉。

    ```shell
    test="line1
    line2"
    echo "$test"  #两行内容，line1和line2
    echo $test   #仅一行内容，line1和line2在一行
    ```

## 变量分类

- 局部变量(Local Variables），存在于当前 shell实例中的变量，仅作用于当前shell进程。

  - 函数内局部变量——只作用于函数内部的变量

    在函数内部定义的变量，可在函数外部读取。可在[函数](#函数)中可使用`local`关键字定义。

- 环境变量，可用于当前shell 的任何子进程。

  可以使用export导出变量为当前shell进程的环境变量。

- shell变量，由 shell 设置的特殊变量，其中一些变量是环境变量, 而另一些变量则是局部变量。                                                                                                                                                  

  

  set、env和export

  - set

    shell内建命令

    > 设定或取消设定 shell 选项和位置参数的值。
    > 改变 shell 选项和位置参数的值，或者显示 shell 变量的名称和值。

    set设置的变量只在当前shell的进程内有效，不会被子进程继承和传递。

    另可参看set常用参数。

  - export

    shell内建命令

    > 为 shell 变量设定导出属性。

    export可将一个shell本地变量提升为当前shell进程的环境变量，从而被子进程自动继承，但是export的变量无法改变父进程的环境变量（子shell中修改继承的环境变量不会影响父shell中对应变量的值）。

  - env

    非shell内建，为外部命令。

    > run a program in a modified environment

    定义一个环境变量提供给后续程序使用。

    ```shell
    env CMD_DIR="test/path/"  test_command
    ```

### 用户自定义变量                                                                                                                                                                                                                                                                                                                                                           

即用户自己定义的变量，使用`export`可以导出为环境变量，在当前shell及子shell有效。

### 环境变量

查看环境变量`printenv`

主要的几个环境变量配置文件：

- /etc/profie
- /etc/profile.d/*
- ~/.bash_profile
- ~/.bashrc
- /etc/bashrc、

定义环境变量：

```shell
setenv a=2
b=2;export b
```

配置文件修改后立即生效，使用source，示例:

```shell
source ~/.bashrc
#或者
. ~/.bashrc
```

### 内部变量

bash内置的变量。

#### 预定义变量

通常用于保存程序运行状态

| 预定义变量 | 说明                                                       |
| ---------- | ---------------------------------------------------------- |
| $?         | 返回最后一次执行的命令返回的状态码（0执行正确，1执行错误） |
| $$         | 脚本运行的当前进程号（PID）                                |
| $!         | 后台运行的最后一个进程的进程号（PID）                      |
| $-         | 当前shell的参数                                            |

附常用状态码：
- 0 	命令成功结束
- 1 	通用未知错误
- 2 	误用shell命令
- 126 	命令不可执行
- 127 	没找到命令
- 128 	无效退出参数
- 130 	通过Ctrl + C 终止

#### 位置参数变量

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
  
    其将以IFS（默认为空格）分割分字符串，但如果分隔符（默认为空格）在引号`""`里面则忽略而不进行拆分。
  
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

# 字符串

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
  ```

## 字符串截取

需要将字符串赋值给变量，操作变量完成。

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

  用法类似`#`，只是`*`放置位置与其想法，位于子字符串的右侧，表示右侧省略，截取左侧：

  ```shell
  str=hello
  echo ${str%ll*} #he  hello的ll左侧为he
  ```
  


# 数组

使用索引将数据集合保存为独立条目。

bash支持普通数组和关联数组（bash 4.0+）：普通数组使用整数作为索引，关联数组使用字符串作为索引。

Bash只支持一维数组。

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
      declar -a arr1
      arr[0]=zero
      arr[1]=one
      
      #定义关联数组
      declar -A arr2
      arr2[indexA]=aaa
    ```

  - 直接定义并对各个索引的值

    - 普通数组：`数组名=(元素1 元素2 元素n)`， 使用空格隔开各个元素。

    ​		注意，csh，zsh中数组下标从1开始。

    - 关联数组：**需要先用declare声明**  `数组名=([索引]=值 [索引]=值)`
    
    ```shell
    arr1=(1 2 test)  #1 2 test
    arr2=(test{1..3} what how)  #test1 test2 test3 what how
    
    #关联数组
    declare -A fruite_prices
    fruite_prices[apple]=10
  fruite_prices=([orange]=7 [banana]=5)
    ```
  
- 读取数组

  - 某个数组元素：`${数组名[索引]}`
  - 数组所有元素：`${数组名[*]}`或`${数组名[@]}`
  - **关联数组的索引列表**：`${!数组名[*]}`或`${!数组名[@]}`

- 数组长度：`${#数组名[*]}`或`${#数组名[@]}`  （比读取数组所有元素多一个`#` ）

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



# 运算符

shell运算符包括：算数运算符、关系运算符、布尔运算符、字符串运算符和文件测试运算符。

## 算术运算符

同多数是编程语言一致，不再列出。**shell变量默认类型为字符串**，可使用以下方法进行数值运算（主要是整数运算）。

### 整数运算

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


- `expr`命令

  - 只能进行整数运算
  - expr命令后把的算式中，**操作符和操作数之间必须有空格**

  ```shell
  expr 17 \* 6    #102  整数运算  #要使用\对*进行转
  expr $var1 + $var2  #注意加号两侧空格
  ```


  此外`expr`还能操作字符串：

  ```shell
  expr length "string"    #6  字符串长度
  expr substr "this-string" 3 5    #is  在[3,5)区间查找字符串
  expr index "string" s   #1  s第一次出现的位置
  ```

- `let`命令

  - 只能进行整数运算
  - 操作符和操作数之间**不能有空格**

  ```shell
  let a=1+1    #a为2
  let a++	   #a为3
  let a-=2    #a为1
  echo $a   # 1
  ```

### 浮点数运算

- bc命令

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

## (数字大小）关系运算符

**关系运算符只支持数字**，不支持字符串，除非字符串的值是数字。(字符串参看[字符串运算符](#字符串运算符))

`数字1 选项 数字2`根据各选项，将第一个数和第二个数对比，判断对比情况，返回true/false。

|  选项  | 说明                            |
| :--: | :---------------------------- |
| -eq  | 是否相等（equal）                   |
| -ne  | 是否不等（not equal）               |
| -gt  | 是否更大（greater than）            |
| -lt  | 是否更小（less than）               |
| -ge  | 是否大于等于（greater than or equal） |
| -le  | 是否小于等于（less than or equal）    |

## 字符串运算符

空和非空：`选项 字符串（或变量）` ；等和不等：`字符串1 选项 字符串2` ，根据各选项判断字符串情况，返回true或false。

|  选项  | 说明         |
| :--: | ---------- |
|  -z  | 字符串长度是否为0  |
|  -n  | 字符串长度是否不为0 |
| ==或= | 是否相等       |
|  !=  | 是否不相等      |

注意：

- 建议使用`[[ ]]`而不是`[]`，如果使用`[]`必须要用`" "`把变量引起来。

  判断字符串是否为空的可靠的方法：`"x${value}" == "x"`

- 判断是否相等时，在`=` 、`==`或`!=`的**两侧一定要有空格**（`=`两侧不加空格是赋值）。

- 最好不要使用`=`或`!=`对数值进行判断（会被当作字符串进行对比）。

## 布尔运算符

非运算：`! 表达式`；与/或运算：`表达式1 选项 表达式2` ，根据各表达式情况判断，返回true或false。

- !    非运算
- -o    或运算
- -a    与运算

## 逻辑运算符

`表达式1 选项 表达式2`

- &&    逻辑与
- ||    逻辑或

## 文件测试运算符

### 文件类型

` 选项 文件名`根据各选项，判断文件的某种情况，返回true或false。

| 选项 | 说明                                   |
| :--: | --------------------------------------|
|  -e  | 判断文件是否存在                         |
|  -f  | 判断文件是否存在，且是否为**普通**文件      |
|  -b  | 判断文件是否存在，且是否为**块设备**文件    |
|  -c  | 判断文件是否存在，且是否为**字符设备**文件   |
|  -d  | 判断文件是否存在，且是否为**目录**文件      |
|  -L  | 判断文件是否存在，且是否为块**符号链接**文件 |
|  -p  | 判断文件是否存在，且是否为**管道**文件      |
|  -s  | 判断文件是否存在，且是否为非空             |
|  -S  | 判断文件是否存在，且是否为**套接字**文件    |

### 文件权限

`选项 文件名`根据各选项，判断某项权限的情况，返回true或false。

|  选项  | 说明                  |
| :--: | ------------------- |
|  -r  | 判断文件是否存在，且是否有读权限    |
|  -w  | 判断文件是否存在，且是否有写权限    |
|  -x  | 判断文件是否存在，且是否有执行权限  |
|  -u  | 判断文件是否存在，且是否有SUID权限 |
|  -g  | 判断文件是否存在，且是否有SGID权限 |
|  -k  | 判断文件是否存在，且是否有SBit权限 |

###　文件对比

`文件名1 选项 文件名2`根据各选项，将第一个文件和第二个文件对比，判断对比情况，返回true/false。

|  选项  | 说明                       |
| :--: | ------------------------ |
| -nt  | 判断文件修改时间是否更新             |
| -ot  | 判断文件修改时间是否更晚             |
| -ef  | 判断文件的Inode是否一致（一致则为同一文件） |

# 正则表达式

这里不详述正则表达式相关内容，具体参看正则表达式和相关工具文档。

**正则表达式与[通配符](#通配符)**：

正则表达式是**包含匹配**，用于**文件内容**匹配；通配符是**完全匹配**，多用于**文件名**匹配。

- 支持正则：grep 、cut、sort、awk、sed、uniq
- 只支持通配符不支持正则：find、cp、ls、rm

应注意以下特殊字符的使用区别：

- `$`  shell中用作变量引用的时置于变量名前的标志符号；正则中表示字符串末尾。
- `*`  通配符中可单独使用，代表任意个数字符；**正则中不能单独使用**，表示重复前面的内容任意次。
- `?`  通配符中可单独使用，代表1字符；**正则中不能单独使用**，表示重复前面的内容0次或1次。

# 测试表达式

各类参见运算符号（除算术运算）中各个运算符使用说明：[数值关系判断](#关系运算符)、[字符串运算符](#字符串判断)、[布尔运算符](#布尔值判断)、[逻辑运算符](#逻辑判断)和[文件测试运算符](#文件判断)。

测试表达式会返回状态码（参看[预定义变量](#预定义变量)中的`$?`），0表示执行正确（true），1执行错误（false）。

- `test`关键字：`test 表达式`
- 单中括号`[ ]`和双中括号`[[ ]]`：`[ 表达式 ]` 和`[[ 表达式 ]]`
  - **`[ ]`在参数只是一个变量时，会把变量当字符串** 。（类似单双引号）
  - 更建议使用`[[ ]]`，相比单层中括号，它的内部支持`&&`  `||`  `<`  `>` 操作符。
  - 这两个命令作用同`test`（相当于是`test`的别名）。
  - 表达式与括号`[]`或`[[ ]]`之间**必须有空格** ，因为`[`和`[[`是linux内部命令（不过，算数运算中的`$[]`不需要有空格）。


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
*)	#最后一个默认分支的值使用*
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
for var in value1 value2 value3
#for var in ${arr[*]}  #数组
#for var in $(cat testfile)  #从文件中获取变量列表

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

## 参数

### 参数传入处理

### 使用预定义变量和位置参数变量处理

大多数简单的命令使用[多分支](#多分支)和[预定义变量](#预定义变量)及[位置参数变量](#位置参数变量)判断处理传入的参数。

示例脚本para.sh

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

```shell
./para.sh -v  #ver 1.0
./para.sh haha  #content: haha
```

### getopts处理单字符短选项

```shell
getopts OPTSTRING VARNAME [ARGS...]  #ARGS默认是 $@，即传入 Shell 脚本的全部参数
```

`getopts`是shell内置方法，仅支持单字符参数（例如`-a`形式），通常情况下，在处理命令行选项和参数时需要多次调用 getopts。getopts 本身不会更改位置参数的设置，如要将位置参数移位，必须仍使用 shift 命令来处理位置参数。因为当没有内容可以解析时，getopts 会设置一个退出状态 FALSE。

`getopts`的相关内置变量：

- **OPTIND**: getopts 在解析传入 Shell 脚本的参数时（也就是 $@），并不会执行 shift 操作，而是通过变量 OPTIND 来记住接下来要解析的参数的位置。
- **OPTARG**: getopts 在解析到选项的参数时，就会将参数保存在 OPTARG 变量当中；如果 getopts 遇到不合法的选项，择把选项本身保存在 OPTARG 当中。
- **OPTSTRING** 记录合法的选项列表（以及参数情况)
- **VARNAME** 则传入一个 Shell 变量的名字，用于保存 getopts 解析到的选项的名字（而不是参数值，参数值保存在 OPTARG 里）

实例，test.sh：

```shell
while getopts ':a:bc:' opt
do
	case $opt in
	a) a=$OPTARG ;;
	b) echo "val is not necessary for option b" ;;
	c) c=$ ;;
	esac
done
echo $a $c
```

其中option的`':a:bc:'`表示获取参数`a`、`b`和`c`，参数后面带有一个`:`表示该参数可以接受一个值，而第一个`:`表示如果输入错误则忽略错误。以上实例表示参数`a`和`c`接受传入值，而`b`则不需要。

运行并传入参数：

```shell
bash test.sh -a 111 -b -c 222
```

### getopt处理多字符长选项

支持双横线的多个字符的参数（例如`--arg`）。



#### shift向左移动位置参数

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

### 参数替换

以下写法中，`param`为参数名，`val`为新的值（`val`也可以引用一个变量）。

| 语法            | 关键符号 | 参数值不为空 | 参数值为空                      |
| :-------------- | :------: | :----------- | ------------------------------- |
| `${param:-val}` |   `-`    | 使用原值     | 使用新值                        |
| `$param:=val}`  |   `=`    | 使用原值     | 为参数对应变量赋予新值 使用新值 |
| `${param:?val}` |   `?`    | 使用原值     | 发返回错误　打印错误信息        |
| `${param:+val}` |   `+`    | 使用新值     | 使用原值——空值                  |

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

  

