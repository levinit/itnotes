







Tcl (Tool Command Language)

- 脚本语言
- 解释器tclsh

# 基本语法

- 后缀`.tcl`

- 可以在文件头部指定默认解释器，如`#!/usr/bin/tclsh`

- 代码行以`;`结尾，但不是必须的，但是如果要使用`#`内注释则需要`;`结尾

- 注释

  - 单行注释：`#`后面内容为注释

  - 多行注释或块注释：使用`if 0 {}`语句

  ```tcl
  #this is a comment line
  
  if 0 {
    all contents here is ignored.
    comments
  }
  puts "hello"; #inline comment
  ```



- 标识符

  *用于标识变量、函数或任何其他用户定义项的名称，区分大小写。*

  以字母 A 到 Z 或 a 到 z 或下划线 (_) 开头，后跟零个或多个字母、下划线、美元 ($) 和数字（0 到 9）。



- 空白字符

  Tcl 中用来描述空白、制表符、换行符和注释的术语。

   空格将语句的一部分与另一部分分隔开，并使解释器能够识别语句中的一个元素的结束位置和下一个元素的开始位置。

  如调用函数时，函数名和其参数直接需要空白。


# 变量

## 定义和引用

```tcl
# 定义变量 set 变量名 变量值
set a 1;

# 引用变量 变量名前加上$引用变量
puts $a;  #puts函数 打印（输出到标准输出）
```

## 内置特殊变量

在 Tcl 中，我们将一些变量归类为特殊变量，它们具有预定义的用法/功能。 下面列出了特殊变量的列表。

- 参数列表

  - `argc`  命令行参数
  - `argv`  令行参数的列表
  - `argv0`  当前执行的文件名

- 错误信息

  - `errCode`  最后一个 Tcl 错误的错误代码
  - `errInfo`  最后一个 Tcl 错误的堆栈跟踪

- 解释执行相关

  - `tcl_interactive`  交互模式（值为1）和非交互模式（值为0）之间切换
  - `tcl_rcFileName`  用户特定的启动文件
  - `tcl_traceCompile` 控制字节码编译的跟踪。 使用 0 表示无输出，1 表示摘要，2 表示详细。
  - `tcl_traceExec`  控制字节码执行的跟踪。 使用 0 表示无输出，1 表示摘要，2 表示详细。

- 环境和解释器版本

  - `env`  环境变量的元素数组

  - `tcl_library`  tcl标准库位置

  - `tcl_pkgPath`  通常安装软件包的目录列表

  - `tcl_platform`  程序执行的平台信息

  - `tcl_version` 解释器版本

  - `tcl_patchLevel`  解释器的当前补丁级别

    包含 byteOrder、machine、osVersion、platform 和 os 等对象的元素数组

  - `tcl_precision`  精度，即在将浮点数转换为字符串时要保留的位数。 默认值为 12。

- 提示内容

  - `tcl_prompt1`  主要提示
  - `tcl_prompt2`  无效命令的辅助提示



# 数据类型

## 字符串

可不用引号包裹，如果一个字符串有空格则需要使用双引号包裹。

```tcl
set str1 "hello world" #"hello world"是一个字符串
```

### 转义字符

这些特殊字符需要在前面添加转义符号`\`以表示其自身：`\  '  "  ?`，例如`\\`表示无特殊含义的`\`本身

这些添加了转义符号的组合有特殊的含义：

- `\a`  Alert or bell 响铃
- `\b`  Backspace 回退符
- `f`  Form feed 换页符
- `\n`  Newline新行符  和  `\r`  Carriage return 回车符
- `\t`  Horizontal tab 水平方向tab符 和 `\v`  Vertical tab 垂直方向tab符

### 常用字符串命令

```tcl
#按字典顺序比较 string1 和 string2
#如果相等返回 0，如果 string1 在 string2 之前则返回 -1，否则返回 1。
compare string1 string2;

first string1 string2; #返回 string1 在 string2 中第一次出现的索引。 如果没有找到则返回-1。

index string index; #返回索引处的字符。

last string1 string2; #返回 string1 在 string2 中最后一次出现的索引。 如果没有找到，则返回-1。

length string; #返回字符串的长度。

match pattern string; #如果字符串与模式匹配，则返回 1。

range string index1 index2; #返回字符串中从索引 1 到索引 2 的字符范围。

tolower string; #返回小写字符串。

toupper string; #返回大写字符串。

trim string ?trimcharacters?; #删除字符串两端的修剪字符。 默认的修剪字符是空格。

trimleft string ?trimcharacters?; #删除字符串左开头的修剪字符。 默认的修剪字符是空格。

trimright string ?trimcharacters?; #删除字符串左端的修剪字符。 默认的修剪字符是空格。

wordend findstring index; #返回包含索引处字符的单词之后的字符在 findstring 中的索引。

wordstart findstring index; #返回包含索引处字符的单词中第一个字符在 findstring 中的索引。
```



### 字符串格式化

`format 格式化字符串 参数值...`

格式化字符串中使用的占位符：

- `%s`	字符串表示
- `%d`	整数表示
- `%f`	浮点表示
- `%e`	尾数指数形式的浮点表示
- `%x`	十六进制表示

```tcl
puts [format "%f" 43.5] ;  #43.500000
```



### 日期时间格式化

```tcl
#获取当前日期时间 四位数年-月-日 时：分：秒 的形式
puts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
```

- 年份：`%y`两位数的年份，`%Y`两位数的年份。
- 月份：`%b`缩写为三个字母如Jun，`%B`完整月份入June，`%m`月份数字。
- 日期：`%d`日期数字
- 时：`%I`12小时制的时，`%H`24小时制的时。
- 分：`%M`
- 秒：`%S`
- 上午下午：`%p`显示为AM或PM。
- 星期：`%a`缩写为三个字母如Sun，`%A`完整形式如Sunday。
- 日期mm/dd/yy形式：`%D`
- 12 小时制时间：`%r`
- 24 小时制时间：`%T`含有秒数，`%R`不带秒。
- 时区：`%Z`时区名称如 GMT、IST、EST 等。



## 列表

项目的有序集合。

```tcl
set 列表名 { 项目1 项目2 ... 项目N }
set 列表名 [ 项目1 项目2 ... 项目N ]

#如果省略分割符号则使用空白符号
set 列表名 [split "items separated by a character" 分割符号];

set colors {red cyan};
#set colors "red cyan"
puts [lindex $colors 0];
```

常用列表命令：

```tcl
lindex $listName index; #索引指定位置的项目

#追加项目到列表
append $listName split_character value
lappend $listName valu

#在索引处插入项目
linsert $listName index value1 value2..valuen

llength $listName;  #列表长度

#替换索引处的项目
lset $listName index value
#替换索引范围内的多个项目
lreplace $listName firstindex lastindex value1 value2..valuen

#将列表转换为变量
lassign $listName variable1 variable2.. variablen

#列表排序
lsort $listName
```

## 关联数组

类似于键值对的字符串，索引（键）对应的值即是数组的元素。

Tcl 中所有数组本质上都是关联的。 数组的存储和检索没有任何特定的顺序， 关联数组的索引不一定是数字，并且可以稀疏填充。 

```tcl
set 数组名(索引) 值；

set price(apple) 10;
set price(pear) 15;

puts $price(pear); #通过索引获取指对应的值
```

- 数组元素个数 `array size 数组名`

## 字典

键值对映射集合

```tcl
dict set 字典名 键 值
# or 
set 字典名 [dict create 键1 值1 键2 值2 ... 键n 值n]
```

常用字典命令：

```tcl
dict get $dictname $keyname; #获取键对应的值
dict exists $dictname $key;  #字典中是否存在指定的键

dict keys $dictname;  #字典所有的键（组成的列表）
dict values $dictnam; #字典所有的值（组成的列表）

dict size $dictname; #字典大小（键值对数量）
```



# 数学计算

## expr数学表达式

参与计算的数字都是整数，则计算结果为整数；如果包含一个浮点数，则计算结果为浮点数。

```tcl
expr 3.0/7; #0.42857142857142855

set tcl_precision 5; #设置精度（默认12），参看内置特殊变量
expr 3/0.7; #4.2857

expr 4*(1+2); #同数学中小括号可提升计算优先级

expr 4<<2; #16
```

## 运算符

- 算数：加、减、乘、除、余数 ` +  -  *  /  %`
- 关系：（数值大小比较） `==  !=  >  <  >=  <=`
- 位运算：位与、位或、异或、二进制左移位、二进制右移位 `&  |  ^  <<  >>`
- 逻辑：与、或、非 `&&  || !`
- 三元：`?:` （语法格式：`如果条件为真 ? 则值 X ：否则值 Y`）

# 流程控制

## 条件

### if语句

`if...elseif...else`

```tcl
if {条件} {
	#body1
} elseif {条件} {
  #body2
#more elseif ...
}else{
  #body others
}
```



### switch语句

使用场景为分支条件为特定的值。

```tcl
switch 匹配项 {
   匹配字符串1 {
      #body1
   }
   匹配字符串2 {
      #body2
   }
#...
   default {
      #body for default
   }
}
```

`default` 块可选，只能出现在 `switch` 的末尾，当所有情况都不成立时，可以使用默认情况来执行任务。





# 循环

`break`语句立即终止整个循环语句

`continue`语句立即进入循环的下一次迭代



### for循环

在达到边界条件前循环执行，每次循环按照一定条件逐步迭代初始值，直到达到特定边界条件则停止。

```tcl
for {初始值} {终止循环的边界条件表达式} {变化控制语句} {
   #statement(s);
}
#例子
for { set a 10}  {$a < 20} {incr a} {
   puts "value of a: $a"
}
```

### while循环

给定条件为真时执行

```tcl
while {condition} {
   #statement(s)
}
```

### foreach

迭代列表

```tcl
foreach 迭代项变量 可迭代数据{
  #codes
}
```



# 命令

在 Tcl (Tool Command Language) 中，通常使用 "命令" 这个词来描述一种特殊的操作。

例如`puts`命令用于将数据输出到标准输出。



格式：

```tcl
命令名 参数1 参数2 ... 参加n
```



命令替换：用于复杂的命令嵌套，将被嵌套的命令放在`[ ]`中

```tcl
puts [ expr 1 + 2 ]
```



## 自定义命令

`proc` 是 Tcl 中定义新命令的方式，可视作其他编程语言的函数概念。

# 

```tcl
proc 名字 {参数1 参数2 ... 参数n} {
   #body
}

proc myfirstproc {args} {
  puts "args: \"$args\"" ;
  puts [info level 0] ;
}
myfirstproc a b c d;
```

如果要为参数设置默认值，以`{参数名 默认参数值}`形式置于参数列表的`{}`中：

```tcl
proc add {a {b 100} } {
   return [expr $a+$b]
}
add 10; #110
```

# 命名空间

命名空间是一组标识符的容器，用于对变量和过程进行分组。

```tcl
#创建命名空间
namespace eval 命名空间名称 {
	variable 变量名
}

#在命名空间中创建procedure
proc 命名空间名称::函数名 {}{
  #codes
}

#调用命名空间中的procedure
命名空间名称::函数名 参数

#导入一个命名空间中的所有方法
namespace import 命名空间名字::*
#导入后即可直接调用该命名空间中的函数

#删除命名空间
namespace forget 命名空间::*
#不能再直接使用这个命名空间中的函数了

#例子
namespace eval MyMath {
  variable myResult
}

proc MyMath::Add {a b } {  
  set ::MyMath::myResult [expr $a + $b]
}
MyMath::Add 10 23

puts $::MyMath::myResult

namespace import MyMath::*
puts [Add 10 30]

namespace forget MyMath::*
```



# 包

包（package）由提供特定功能的文件集合组成， 该文件集合由包名称标识，并且可以具有相同文件的多个版本，用于创建可重用的代码单元。

包使用[命名空间](#命名空间)的概念来避免变量名和过程名的冲突

一个包含有两种文件：

- 代码文件
- 包索引文件（在包目录中使用 `pkg_mkIndex` 命令创建）

例子：包目录为`~/hello`

文件1 代码文件`~/hello/test1.tcl`

```tcl
namespace eval ::HelloWorld {
 
  # Export MyProcedure
  namespace export MyProcedure
 
  # My Variables
   set version 1.0
   set MyDescription "HelloWorld"
 
  # Variable for the path of the script
   variable home [file join [pwd] [file dirname [info script]]]
 
}
 
# Definition of the procedure MyProcedure
proc ::HelloWorld::MyProcedure {} {
   puts $HelloWorld::MyDescription
}

package provide HelloWorld $HelloWorld::version
package require Tcl 8.0
```



文件2 索引文件，切换到`tclsh`，进入包目录`~/hello`后使用以下命令完成：

```tcl
pkg_mkIndex . *.tcl
lappend auto_path "~/hello"； #也可使用[pwd]或$::env(PWD)获取当前目录
package require HelloWorld 1.0
puts [HelloWorld::MyProcedure]
```



# I/O

读取和写入操作都需要先打开文件，操作完毕后应该关闭文件。

- 打开文件 `open 文件路径 读写模式`，其返回文件句柄（handle）

  - 读写模式

    - 读`r`  未指定读写模式时的默认模式，文件必须存在.

    - 写`w`  如果文件不存在将创建，如果文件存在将覆盖已有内容.

    - 追加 `a`  文件必须存在

    - `r+`  打开一个文本文件以进行读写, 文件必须已经存在。

    - `w+`  打开一个文本文件以进行读写，如果文件存在，它首先将其截断为零长度，否则创建文件（如果不存在）。

    - `a+`  打开一个文本文件以进行读写。 如果文件不存在，它将创建该文件。 阅读会从头开始，但写作只能追加。

- 关闭文件  `close 文件句柄`
- 读取文件  `read 文件句柄`
- 写入文件  `puts 文件句柄 内容`



读写示例： 

```tcl
#写入内容 test
set fp [open "input.txt" w+]
puts $fp "test"
close $fp

#读取写入的内容
set fp [open "input.txt" r]
set file_data [read $fp]
puts $file_data
close $fp
```



# 错误处理

- error命令抛出错误

  ```tcl
  error message ?info? ?code?
  
  error "Error generated by error" "Info String for error" 401
  ```

  - `message` 描述错误的字符串，这将成为生成的错误的 `-errorinfo` 选项的值。
  - `info` 可选参数，如果提供，它将成为生成的错误的 `-errorinfo`选项的值。这通常是一个调用堆栈跟踪。
  - `code` 可选参数，如果提供，它将成为生成的错误的 `-errorcode` 选项的值。这通常是一个列表，描述了错误的具体类型。

  

- catch命令

  ```tcl
  catch 语句 返回的信息
  
  if {[catch {puts "Result = [expr 10/0]"} errmsg]} {
     puts "ErrorMsg: $errmsg"
     puts "ErrorCode: $errorCode"
     puts "ErrorInfo:\n$errorInfo\n"
  }
  ```
