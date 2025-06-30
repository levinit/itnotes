[TOC]

# unalias和`\command`

在一些使用场景中，将所有命令别名清除，可以防止别名覆盖同名命令的意外的干扰：

```shell
unalias -a
```

或者在要执行的命令前使用`\`表示不使用该命令的别名：

```shell
\ls -1   #即使存在一个别名ls，\ls也会忽略之，只会从PATH中找到第一个ls去执行
```



# install和cp

一些程序安装脚本以及Makefile里会用到install进行文件复制，它与cp主要区别：

- 如果目标文件存在，cp会先清空文件后往里写入新文件，而install则会先删除掉原先的文件然后写入新文件

  这是因为往正在使用的文件中写入内容可能会导致一些问题，比如写入正在执行的文件可能会失败，已经在持续写入的文件句柄中写入新文件会产生错误的文件。使用  install先删除后写入（会生成新的文件句柄）的方式去安装就能避免这些问题

- install命令会恰当地处理文件权限的问题。

  - `install -c a /path/to/b`  把目标文件b的权限设置为`-rwxr-xr-x`
  - `install -m 0644  a /path/to/b`  把目标文件b的权限设置为`-rw-r--r--`

- install命令可以打印出更多更合适的debug信息，还会自动处理SElinux上下文的问题。



# rsync

rsync 镜像同步目录，最好在目录最后加上`/`：

```shell
#同步a b 目录
#将删除b目录中存在但a目录不存在的文件，即保证a b完全一致
rsync -avzPu --delete a/ b/
```

- `-e <program>` 或 `--rsh=<program>`  指定远程shell程序（默认是ssh）
  - `-e "ssh -p 22"`  指定ssh端口为22（默认端口）
  - `-e "ssh -i ~/.ssh/id_rsa"`  指定ssh密钥文件
- `--dry-run` 只显示将要执行的操作，而不实际执行
- `-i` 或 `--itemize-changes`  显示每个文件的变化信息
- `-a` 或 `--archive` 归档模式，等同于`-rltpgoD`，即递归处理目录，保留符号链接、权限、时间戳、组、所有者和设备信息
- `-r` 或 `--recursive` 递归处理目录
- `-l` 或 `--links` 复制符号链接（默认行为）
- `-p` 或 `--perms` 复制文件权限（默认行为）
- `-t` 或 `--times` 复制文件的时间戳（默认行为）
- `-g` 或 `--group` 复制文件的组信息
- `-o` 或 `--owner` 复制文件的所有者信息
- `-D` 复制设备文件和特殊文件（等同于`--devices --specials`）
  - `--devices` 复制设备文件
  - `--specials` 复制特殊文件（如管道和套接字
- `-L` 或 `--copy-links`  复制符号链接指向的文件，而不是链接本身

> 默认情况下，rsync 会通过 文件大小 和 修改时间（mtime） 来判断文件是否需要同步，跨平台同步时不一定可靠。

- `--size-only`  只根据文件大小来决定是否更新文件
- `-c` 或 `--checksum`  使用校验和来决定是否更新文件
- `-u`  或 `--update`    如果目标文件已经存在且更新则跳过（即目标文件比源文件新时不更新，依赖时间戳）
  - `--inplace`   直接在目标文件上更新，而不是创建一个临时文件
  - `--append`    追加数据到较短的文件
  - `--append-verify`   类似于 --append，但会对文件中的旧数据进行校验和
- `--ignore-existing`  忽略目标目录中已经存在的文件（可适用于初始化备份）
- `--delete`   从目标目录中删除无关的文件（目标目录中存在的文件在源目录不存在）
- `--exclude=<pattern>`  排除文件名与该模式匹配的文件

- `--partial`  保留部分传输的文件（如果传输中断，下一次传输将从中断处继续）
- `--partial-dir=<dir>`  指定部分传输文件的目录(默认是`.part`目录)
- `-P` 或 `--progress`  显示进度
- `-h` 或 `--human-readable`  显示数字转为可读性更强的形式（转换文件大小单位 如1005.2k显示为1M）
- `-W` 或 `--whole-file` 跳过增量传输算法，直接传输整个文件，在带宽较高时适用
- `-z` 或 `--compress`  压缩传输数据
  - `--compress-level=NUM`    显式设置压缩级别

- `-v`  显示详情



# find

查找文件

```shell
find  <path>   -option   [   -print ]   [ -exec   -ok   command ]   {} \;
```

- 常用选项option：

  - 文件名

    `-name name`：文件名称符合 name 的文件，可使用通配符

    `-iname name` : iname 会忽略大小写

    

  - 文件大小

    `-size n[cwbkMG]`： 文件大小为n，单位为中括号中任意一个字母，

    其中，单位b 代表 512 bytes的区块（默认单位），c 表示bytes，w表示2字节词

    

  - 文件时间信息

    - `-amin n` ： 在过去 n 分钟内被读取过

    - `anewer file` ：比文件 file 更晚被读取过的文件

    - `atime n` ：在过去 n 天内被读取过的文件

    - `cmin n` ：在过去 n 分钟内被修改过

    - `cnewer file`：比文件 file 更新的文件

    - `ctime n`：在过去 n 天内创建的文件

    - `mtime n`：在过去 n 天内修改过的文件

    

  - 文件类型

    `-type <type_name>`    类型有

    - d：目录
    - c：字型装置文件
    - b：区块装置文件
    - p：具名贮列
    - f：一般文件
    - l：符号连结
    - s：socket

    


- `-print`： find命令将匹配的文件输出到标准输出。

  

- `-exec`  后面可接上对查找到的文件要执行的命令（command）

  `{}` 表示匹配到的一个文件。

  最后的`  \;`部分为固定搭配，注意`\`之前要有空格。

  ```shell
  find . -name "*.py" -exec chmod +x {} \;
  ```

  

- `-ok`  与`-exec`作用和用法相同，但是会在执行后面的的命令前询问用户





# 自动打开gui终端并执行命令

例如想打开一个gnome-terminal终端，打开终端后直接进入python交换环境：

```shell
gnome-terminal -- python
```



# 系统环境

- 获取当前发行版信息

  ```shell
  echo $(. /etc/os-release;echo $NAME)
  ```

- `EDITOR`  默认编辑器（某些软件会调用例如git commit或crontab -e时）

  ```shell
  export EDITOR=vim
  ```

- 获知当前系统架构

  ```shell
  echo $MACHTYPE
  uname -m
  ```

- 获知当前shell

  ```shell
  echo $SHELL
  echo $0
  ```

- 搜索某个命令的手册描述（数据来自mandb） `apropos <command>`

- 一般能用以下方式获取某个命令相关信息：

  ```shell
  info <command> 
  man <command>
  <command> --help
  <command> -h
  <command> help
  ```

  二者有交集。info 工具可显示比man更完整的GNU工具信息。man没有内建与外部命令的区分。



# 进程管理

杀死一个进程以及其所有后代进程

```shell
pid=1234  #1234是进程号
[[ $pid ]] && kill -9 $(pstree $pid -p|grep -oE "\([0-9]+\)"|grep -oE "[0-9]+")
```



# 判断命令是否可用

判断某个命令是否可用，即判断是该命令在$PATH中。

以检查命令ssh是否可用为例，以下方法均可在ssh存在的情下返回一些内容，code为0，不存时返回值为空 ，code为1：

- `command -v ssh` 
- `which ssh 2>/dev/null`
- `type 2>/dev/null`
- `hash ssh 2>/dev/null`

# 字符串处理

## 合并连续的空白行为一个空白行

```shell
sed -e '/^$/{N;/\n$/D};' <file>
```

## 去掉字符串前后的空格

```shell
eval echo "xxx xx"
eval echo $(echo 'ab c')
```

## 重复输出一个字符

- 使用printf

  ```shell
  #打印30个*
  s=$(printf "%-30s" "*")
  echo -e "${s// /*}"
  
  #根据当前终端宽度（列数）打印一整行=
  
  #使用sed
  printf "%-${COLUMNS}s" "="|sed "s/ /=/g"
  
  #使用echo
  s=$(printf "%${COLUMNS}s" "=")
  echo -e "${s// /=}"
  ```

- 使用seq

  根据当前终端宽度（列数）打印一整行`=`：

  ```shell
   seq -s "=" $((COLUMNS + 1))|sed -E "s/[0-9]//g"
  ```

  seq以`=`为分隔符生成与终端宽度字符数量相等的数字（形如`1=2=3=4`）

  sed正则匹配所有数字并替换为空字符串。（`=`总比数字少1个，因此要行数基础上+1，这样再将数字去掉后`=`数量才和一行字符数量一致）



## expr字符串截取

使用expr截取指定区间（前开后闭区间）的字符串：

```shell
#expr substr <string> <start-index> <end-index>
expr substr "this-string" 3 5    #is  在[3,5)区间查找字符串
```

## seq序列化输出

seq命令产生从某个数到另外一个数之间的所有整数。

```shell
seq [选项]... 尾数
seq [选项]... 首数 尾数
seq [选项]... 首数 增量 尾数
```

如果不指定首数，则首数默认为1；如果不指定增量，则增量默认为1。

常用选项

- `-f`, `--format=格式`        使用printf 样式的浮点格式
- `-s`, `--separator=字符串`   使用指定字符串分隔数字（默认使用：`\n`）
- `-w`, `--equal-width`        在数字添加0补充位数 使得宽度相同



seq输出的数字每个占用一行，因为默认的分隔符是换行符，可指定分隔符：

```shell
seq -s " " 3 #一个空格分隔 输出一行 1 2 3
seq -s "" 3  #无分隔符 输出一行123
```

提示：使用`{m..n}`展开也能输出数字m到n的所有整数，所有数字只占用一行，两个数字间使用空格分隔；可使用`seq m n|xargs`将输出数字合并为一行，两个数字间使用空格分隔。

```shell
seq -w 99 101  #倒序生成数字
```



## 将文本按分隔符读取为数组

readarray（或mapfile）命令用于从标准输入或选项“-u”指定的文件描述符fd中读取内容，然后赋值给索引（下标）数组array，如果不指定数组array，则使用默认的数组名MAPFILE。

```shell
#list1为各行内容组成的数组，-t删除了每行的换行符
readarrary -t list1 < file1

echo 1,2,3 | readarray -d , -t nums  #nums为(1 2 3)
readarray -d , -t nums <<< 1,2,3  #同上
```

readarrary 参数：

- `-d delim`：delim是自定义的分隔符，默认为行分隔符。
- `-t`：删除每个数组元素（字符串）结尾的分隔符。
- `-n count`：复制最多count行，如果count为0，则复制所有的行。 
- `-O origin`：从下标位置origin开始对数组赋值，默认为0。 
- `-s count`：忽略开始读取的count行。 
- `-u fd`：从文件描述符fd中读取文本行。 
- `-C callback`：每当读取选项“-c”指定的quantum行时（默认为5000行），就执行一次回调callback。



IFS和read分割字符串为数组

```shell
IFS='/' read -r -a build_info <<<"linux/amd64"  #得到数组build_info=(linux amd64)
```



## readarrary 将文本读取为数组

```shell
readarrary 
```

# 用户相关

- `$USER`或`whoami`  当前用户名

- `id $USER`  用户的uid和gid信息

- `getent`  从管理数据库取得条目（参看`getent --help`）

  ```shell
  getent passwd <username>
  ```

- 用户家目录 

  - `$HOME` 变量获取当前用户家目录

  - 获取任意用户家目录

    ```shell
    username=root  #当前用户whomai 或者 $USER
    grep ^$username: /etc/passwd |cut -d ":" -f 6
    getent passwd | grep ^$username: |cut -d ":" -f 6
    ```

    

- 修改密码（非交互式）

  - passwd的`--stdin`参数（某些发行版的passwd可能不支持）

    ```shell
    echo "new_pwd" | passwd --stdin [username]
    ```

  - chpasswd 读取文件或标准输入

    创建一个含有用户名和密码的文件，每行一个用户信息，使用`:`分隔用户名和密码，形如`username:password`，例如该文件为`/tmp/pwds`，内容为：

    > root:123456
    > user1:123456
    
    使用chpasswd读取该文件：

    ```shell
    chpasswd < /tmp/pwds
    ```
    
    从标准输入读取：
    
    ```shell
    chpasswd <<EOF
    user1:pwd1
    EOF
    ```

# 文件处理

## ls文件列表

###  `-f`不排序文件列表

默认情况下，`ls`获取到文件列表后会对文件进行排序好再输出。

一个应用场景是统计目录下的文件数量——`ls -l | wc -l`，如果一个目录下文件数量规模巨大，则排序耗时就会很长，使用`-f`则可以很快统计出文件数量：

```shell
ls -fl | wc -l
```



###  `-AFQlh`更清晰地区分文件

在需要区分目录下的文件类型等相关信息时，这些选项很有帮助。

- `-A`  不展示`.`和`..`

- `-F`  在文件名后面添加一个区分文件类型的标记字符

  文件名后面的字符和其含义为：

  - `/`    目录
  - `*`    可执行文件
  - `@`    符号链接
  - `|`    管道（FIFO）
  - `=`    套接字

  另有：`--file-type`选型，作用与`-F`的唯一区别是不为文件标记`*`；`-p`只为目录添加`/`

- `Q`  为文件名两侧添加`""`双引号

##  临时文件mktemp

由系统随机起名，一般回存放于`/tmp`下。

```shell
testfile=$(mktemp)
echo "test test" > $testfile
cat $testfile  #test test
```



## 更新时间戳touch

```shell
touch <file> #如果file不存在将创建file
touch -c <file> #或--no-create 　不建立任何文档
```

如果文件不存在则创建；如果已经存在将更新该文件/目录的时间戳，包括：

- atime：最后访问时间，文件被读取或执行时更新。
- mtime：最后内容修改时间，文件内容修改（并保存）后更新。
- ctime：最后状态改动时间，文件属性修改后更新（如所属者、权限）。

可使用相关参数修改某一个时间戳。

提示`stat <file>`可查看某个文件的时间戳信，`stat`和`ls`命令不会更新文件的atime。



## 删除文件后未释放空间

重启。
或者：

```shell
lsof |grep deleted
```

kill掉相关进程

确保删除文件能立即释放空间可使用：

```shell
echo > /path/to/file  #换成实际的文件路径
```



## 创建一个大文件

例如大小1g，路径`$HOME/file`

- fallocate

  ```shell
  fallocate -l 1g file
  sync
  ```

- truncate

  ```shell
  truncate -s 1g file
  sync
  ```

- dd

  ```shell
  dd if=/dev/zero of=$HOME/file bs=1 count=0 seek=1G
  sync
  ```

  务必小心of的值不要写错，避免抹掉重要文件。



## 文件信息获取

- 获取文件的绝对路径/软链接的原始文件的路径

  ```shell
  readlink -f link-file-name   #软链接的原始文件的绝对路径
  readlink -f $0     #当前脚本文件的绝对路径
  ```

  注意，如果source的脚本中，使用以上方式通过$0获取当前执行脚本的绝对路径会提示：

  >  invalid option -- 'b’

  因为在source时，脚本中的$0的返回值为`-bash`而不是脚本的名字，可以使用`${BASH_SOURCE[0]}`获取被source的文件都绝对路径：

  ```shell
  readlink -f "${BASH_SOURCE[0]}"
  ```

- 当前执行文件所在的目录

  ```shell
  dirname $(readlink -f "$0")
  ```

- 文件绝对路径

  ```shell
  realpath xxx  #xxx为当前目录下某文件的名字
  ```

- 从路径字符串中截取文件或文件夹的名字

  例如要获取`/home/test1/testfile`字符串中获取到`testfile`字符串

  ```shell
  basename `/home/test1/testfile`
  basename `$0`  #获取当前脚本的文件名
  ```

- 文件大小

  ```shell
  stat --format=%s <filename>  #单位为byte 或-c
  ls -lh <filename>
  ```


## 替换和删除文件内容

### 将换行转换为实际的`\n`字符

示例，欲将文件file

>line1
>
>line2

变成

>line1\nline2

在文本中的换行符号表现为换行，示例将file文件的换行符号变成实际的`\n`字符（无特殊意义），所有行文本归为一行：

- sed模式空间处理

  ```shell
  #tag只是一个自定义的标记名
  sed ":tag;N;s/\n/\\\n/;b tag" file
  ```

- 利用echo输出自动去掉换行符

  echo不使用-e时将忽略`\n`换行

  ```shell
  #$表示最后一行   $ !表示除了最后一行的行
  #行末替换成\n字符 （注意转义），再echo输出
  echo $(sed  "$ !  s/$/\\\n/" file) > file
  ```

### 删除空白行

或者说替换空白行内容为空字符。

- tr   只打印到标准输出（可重定向保存）

  ```shell
  cat file | tr -s '\n'
  ```

- sed  使用-i参数可以直接编辑并存储

  ```shell
  sed "/^$/d" file
  sed -i "/^$/d" file
  ```

- awk  只打印到标准输出 （可重定向保存）

  ```shell
  awk '{if($0!="") print}' file
  awk '{if(length!=0) print $0}' file
  ```

- grep  只打印到标准输出 （可重定向保存）

  ```shell
  grep -v "^$" file
  ```




# 终端控制

获取当前终端端宽（列数）高（行数）

- 全局变量`COLUMNS`和`LINES`
- `tput cols`和`tput lines`
- `stty size`  (输出两个数字，以空格分开，前面为行数--高，后面为列数-宽）
- `stty ek` 重置终端按键映射



# 未归类

- 不小心卸载了所有分区，无法reboot

  ```shell
  reboot -f
  ```
  
- 消息提示

  ```shell
  notify-send "xxx"
  ```
  桌面环境中将弹出提示消息。

  

- 打开默认应用 `xdg-open <file or url>`

  ```shell
  xdg-open http://localhost #使用默认浏览器访问http://localhost
  xdg-open testfile  #使用默认编辑器打开testfile文件
  ```

- 参数以`-`开头，额外使用`--`选项

  ```
  ls -- -test.txt
  cat -- -test.txt
  grep -- -abc test.txt
  ```

- gzexe给脚本加密（普通文件亦可）

  ```shell
  gzexe a.sh
  ```

   例如给a.sh加密，该命令执行完成后将有两份文件，`a.sh`和`a.sh~`，带`~`的是原来的文件，不带`~`的是加密过的文件。