# 简介

TCSH兼容CSH，csh实际很少使用，**许多发行版的csh只是tcsh的软链接**，本文所述不区分二者，但实际以tcsh为准。

除了部分语法和特性不同于bash，其余可参考bash。本文记录与bash明显不同的部分。



# tcsh设置

## 配置文件读取顺序

一般如果没有对系统文件进行修改，多数发行版会按以下顺序读取配置文件：

- 登录shell
  1. `/etc/csh.cshrc`
  2. `/etc/csh.login`
  3. `/etc/profile.d/*.csh`  (按文件名顺序读取)  和 `/etc/profile.d/csh.local`（如果存在）
  4. `~/.tcshrc`  或 `~/.cshrc`   （如果`~/.tcshrc`存在则忽略`~/.cshrc` ）
  5. `~/.login`

- 非登录shell
  1. `/etc/csh.cshrc`
  2. `~/.tcshrc`  或 `~/.cshrc`   （如果`~/.tcshrc`存在则忽略`~/.cshrc` ）

不同发行版可能略有出入。

另：如果存在`~/.logout`，会在退出shell时会读取该文件。



## 常用开关变量

用于设置csh的一些特性，触发指定的动作：

- nobeep
- autocorrect
- dunique
- filec
- histlit
- ignoreeof
- listjobs
- listlinks
- loginsh
- noclobber

- noglob
- nonomatch
- notify
- pushdtohome
- pushdsilent
- rmstar
- verbose
- visiblebell



```shell
if ($?prompt) then            # only for prompt mode
    set autolist              # autocomplete while press TAB
    set complete = enhance    # ignore case，- equals _ ,and treat . - _ as seperators
                              # igncase: only for ingore case
    set autoexpand            # history as a reference for autocompletion
    set correct = cmd         #auto correct command when corrected command is unique
    # set correct = all       #correct all
endif
```

# 变量

## 字符串变量

定义变量不同于bash：

- 定义变量需要使用set  （bash中set用于设置bash shell的特性开关）
- 定义环境变量使用setenv
- 等号两边可以有空格
- 同一行定义多个变量需要使用`;`分隔

```shell
set var1       #set 定义变量
set var1=123   #定义变量并赋值

setenv var2='hello'  #setenv定义环境变量
```

打印所有环境变量使用`env`或`printenv`，`printenv HOME`等于`echo $HOME`等于`env HOME`。

环境变量使用setenv设置，但是不能使用`=`连接：

```shell
setenv ENV1 abcdef
setenv PATH "/path/1:$PATH"
```



不同于bash的内置变量：

- `$%x` 变量x的值的长度  （bash使用`${#x}`
- `$?x`  判断变量x是否已经定义，是返回1，否返回0。引用未定义会直接抛出错误，bash则返回空值。

*csh中一些默认的系统环境变量不区分大小写，例如`$HOME`、`$USER`。*



## 数字变量及计算

使用`@`命令代替set命令来声明数字变量，进行算术、关系和位操作。

数字和字符串变量是两个不同的对象，需要用不同的方法管理，不能把set用于数值变量的设置@命令由关键词，变量名，赋值运算符和表达式构成。如:

```shell
@ x=1
@ y=2 * ($x + 1)
echo $y  #4
```

或者使用expr计算：

```shell
set i=1
set i=`expr $i + 1` #注意+两边空格，i需要set重新赋值
```





# 数组

```shell
set arr=( a b c )
echo $arr[1]     #获取第一个索引值
echo ${arr[1]}   #也可以同bash的用法一样使用${}
```

**数组元素的索引编号从1开始**（bash从0开始）。





# 流程控制

## goto

跳转到指定label

```shell
#如果在周1到周5，直接goto到最后输出echo内容
#如果在周0或周6，额外多输出一行echo
if ( 0 < `date +%w` < 6 ) then
  goto do_some_thing
endif

  echo  "今天周`date +%w`, 双休日"

do_some_thing:
  echo "加油打工人"
```



## 条件分支

### if语句

与bash中使用`[]`或`[[]]`不同，csh使用`()`包含判定表达式，且无需在`()`和内部内容直接间隔空白字符。

- 一行

  ```shell
  #一行 if (...) ...
  #if ( expression ) some_codes
  set x=1
  if ( x == 1  ) echo yes
  ```

- 多行

  注意：then必须和if在一行
  
  ```shell
  #多行 if (...) then (...) endif
  #if ( expression ) then
  #  some_codes
  #else if (expression) thne
  #  some_codes
  #else
  #   some_codes
  #endif
  
  set x=0
  if ( $x > 0 ) then
    echo positive number
  else if ( $x < 0 ) then
    echo negative number
  else
    echo 0 
  endif
  ```



## switch语句

```shell
#switch ( test-string )
#  case pattern:  #pattern 
#    some_codes
#  breaksw
#  case pattern:
#    some_codes
#  breaksw
#  default:   #默认分支
#    some_codes
#endsw

if ($#argv != 1) then
    echo usage: $0 y or $0 n
    exit 1
endif 

switch ( $argv[1] )
 case [hH]:
   echo "usage: $0 y or $0 n"
 breaksw
 case [yY]:
   echo "it will run app"
 breaksw
  case [nN]:
   echo "it will stop app"
 breaksw
 default:
   echo "use $0 h to get usage"
endsw
```

参看bash的case匹配用法，不过**csh不能使用`|`符**，可使用的有`[]`，`?`，`*`。



## 循环

可在循环中使用break中断循环，或使用continue直接进入下一次循环，用法与bash及许多编程语言一致。

### foreach循环

等同于bash中的for...in循环。

```shell
#foreach loop-index (arg-list)
#  some_codes
#end
foreach i (`seq 1 3`)  # foreach i (1 2 3)
  echo $i
end
```



### while 循环

```shell
#while (expression)
#  some_codes
#end
set x=1
while ( $x <= 3 )
  echo $x
  @ x++
end
```


# 重定向

csh不能使用`&>`、`2>`，可使用`>&`。

csh不能为标准输出和标准错误输出分别重定向，变通方法是在子shell中执行命令并重定向标准输出，父shell仅能接收到来自子shell的标准错误输出：

```shell
(cat x > outlog ) >& errlog
```



# alias

查看alias对应的实际指令不能使用type：

```shell
alias  #show all alias
alias <command>  #show alias info for specified command
```

设置和取消alias：
```shell
alias <aliasName> <command...>

#remove all alias
unalias *
```

csh没有函数，只能使用alias实现

```shell
alias fn1 'echo hello'
fn1
```


# 参数使用

当tcsh脚本被执行时，命令行中的单词被分析并放入argv数组中。

- 位置参数：

  - 与bash一致的用法： `$1-9`  

    还支持`$0` 和 `$*`，用法同bash

  或

  - tcsh中特有的用法：`$argv[1-N]`

- 参数个数

  - 与bash一致的用法：`$#`

  或

  - tcsh中特有的用法： `$#argv`

- （向左）移动参数

  - 与bash一致的用法：`shift`
  - tcsh中特有的用法：`shift argv`



# 内建命令

bash和tcsh的部分内建命令对比

| 用途              | bash                                               | csh           |
| ----------------- | -------------------------------------------------- | ------------- |
| 用户shell限制情况 | ulimit                                             | limit         |
| 别名查看          | `type <cmd>` 或`alias <cmd>` 或 `command -v <cmd>` | `alias <cmd>` |
|                   |                                                    |               |
