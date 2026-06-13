[toc]

# 简介

AWK是一种处理文本文件的语言，也是一个强大的文本分析工具。

> AWK取自三位创始人 Alfred Aho，Peter Weinberger, 和 Brian Kernighan 的Family Name的首字符。

awk处理的数据可以来自标准输入(stdin)、一个或多个文件，或其它命令的输出。



# awk命令用法

```shell
awk [options] 'script' var=value file(s)
awk [options] -f scriptfile var=value file(s)
```

- options：awk的选项

  常用选项：

  - `-F <fs>`   fs指定输入分隔符

    fs可以是字符串或正则表达式。默认为空白分隔符（一个或多个tab、空格等组成的空白区域）。

    分隔符将一行文本内容分成若干字段，字段的编号从1开始，使用对应的变量为`$1`，最后一个字段内容可使用变量`$NF`表示。

    例如一个文件test1内容如下：

    ```
    1  aaa 11a  aa11
    2  bbb 22b  bb22
    ```

    使用awk处理：

    以空格为分隔符（可省略）

    打印（awk命令print）第一个字段和最后一个字段内容，打印的两个字段之间有一个`:`

    > ```shell
    > $ awk -F " " '{print $1":"$NF}' test1
    > 1:aa11
    > 2:bb22
    > ```

  - `-v <var=value>`   赋值一个用户定义变量，将外部变量传递给awk

  - `-f <scripfile>`  从脚本文件中读取awk命令

    

- script：awk的语句 ；scriptfile：使用awk语言编写的脚本文件

  其内容即awk语言编写的语句。

  

- file：要处理的文件

  也可以处理标准输入的内容。

  示例，通过管道符传递数据给awk处理：

  ```shell
  head -n 10 testfile | awk -F ":"  '{print $1" : "$NF}'
  ```



# awk语言语法

## 语句组成

awk语句由*pattern*和*action*组成：

```shell
awk '{pattern + action}' {filenames}
```



- pattern——AWK在查找（或者说匹配到）的数据

  pattern可以没有，也可以是以下几种内容：

  - /正则表达式/：使用通配符的扩展集

  - 关系表达式：使用运算符进行操作，可以是字符串或数字的比较测试。

  - 模式匹配表达式：使用运算符`~`（匹配）和`~!`（不匹配）

  - BEGIN语句块、pattern语句块、END语句块

  

- action——对找到匹配内容时所执行的一系列命

  由**大括号包裹**的一个或多个命令、函数、表达式组成，如果由**多个**组成，则每个**之间**由换行符或**分号（建议使用）隔开**。

  一般建议使用单引号`''`将大括号包裹起来。

  action可以没有，也可以是以下几种内容：

  - 变量或数组赋值
- 输出命令
  - 内置函数
- 控制流语句



## 执行流程

一个awk命令结构示例，实际每个awk语句不一定包括该示例的所有部分：

```shell
awk 'BEGIN{ commands } pattern{ commands } END{ commands }'
```

执行顺序：

1. 执行 `BEGIN {commands}` 内的语句块

   该语句块只会执行一次，在通过stdin读入数据前就被执行，常用于变量初始化，打印表头信息等。

2. 按行处理数据，每读取一行就使用 **`pattern{commands}`** 处理

3. 执行 `END{ commands }` 

   该语句块之后执行一次，在所有行处理完后执行，例如打印一些统计结果。



## 内置变量

awk常用内置变量

| 变量        | 说明                                       |
| :---------- | :----------------------------------------- |
| ARGC        | 命令行参数的数目                           |
| ARGIND      | 命令行中当前文件的位置（从0开始算）        |
| ARGV        | 包含命令行参数的数组                       |
| CONVFMT     | 数字转换格式（默认值为%.6g）               |
| ENVIRON     | 环境变量关联数组                           |
| ERRNO       | 最后一个系统错误的描述                     |
| FIELDWIDTHS | 字段宽度列表（用空格键分隔）               |
| FILENAME    | 当前输入文件的名                           |
| FNR         | 同NR，但相对于当前文件                     |
| FS          | 字段分隔符（默认是任何空格）               |
| IGNORECASE  | 如果为真，则进行忽略大小写的匹配           |
| NF          | 表示字段数，在执行过程中对应于当前的字段数 |
| NR          | 表示记录数，在执行过程中对应于当前的行号   |
| OFMT        | 数字的输出格式（默认值是%.6g）             |
| OFS         | 输出字段分隔符（默认值是一个空格）         |
| ORS         | 输出记录分隔符（默认值是一个换行符）       |
| RS          | 记录分隔符（默认是一个换行符）             |
| RSTART      | 由match函数所匹配的字符串的第一个位置      |
| RLENGTH     | 由match函数所匹配的字符串的长度            |
| SUBSEP      | 数组下标分隔符（默认值是34）               |

