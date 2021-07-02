[TOC]

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
rsync -avz --delete a/ b/
```



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



# 随机数

`RANDOM`变量会生成0--32767的整数。

生成一定范围内的整数

```shell
echo $(($RANDOM%99))    #生成0-99的数
echo $(($RANDOM%82+6))  #生成6-87（81+6)的数
```

从shell数组中随机选择一个元素

```shell
arr=(1 3 5 7 9)
rand_index=$(($RANDOM % ${#a[*]})) #随机获取一个下标值
echo ${arr[$rand_index]}
```

注意：csh、zsh，数组元素下标从1开始



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

# 遍历名字有空格的目录/文件

某目录的子目录/文件有空格，直接遍历`ls`的返回值会发生错误而中断，可以使用以下方法：

```shell
#-1是数字1不是字母l
ls -1 | while read line
do
  echo "$line"
  #cp "$line" /tmp/xxx
done
```

`ls -1`按行列出子目录/文件的名字，使用管道符将列出的内容传递给`while read line`按行读取，循环中使用双引号`""`包裹变量，避免因为有空格而导致某些操作出错。

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
   seq -s "=" $(({COLUMNS}+1))|sed -E "s/[0-9]//g"
  ```

  seq以`=`为分隔符生成与终端宽度字符数量相等的数字（形如`1=2=3=4`）

  sed正则匹配所有数字并替换为空字符串。（`=`总比数字少1个，因此要行数基础上+1，这样再将数字去掉后`=`数量才和一行字符数量一致）

# shell脚本相关

- `sh`中没有`source`

- shell文件格式化工具`shfmt`

- 在脚本最前面使用`unalias -a`取消所有alias避免alias而可能造成的问题。

- `$BASHPID`  当前bash的pid（非bash终端变量名不同）

- 更加安全的执行脚本`set -eu`

  - 避免引用未定义变量造成的问题，在脚本最上方添加：`set -u`

    例如`rm -rf $xx/`，而`$xx`未定义，结果成了执行`rm -rf /`。

  - 遇到错误行自行退出，在脚本最上方添加一行：`set -e`

    某行执行后返回值不为0自行退出，避免继续执行其后的代码，例如某行执行的命令书写错误而执行失败。



# seq序列化输出

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
  readlink -f `dirname $0`     #当前脚本文件的绝对路径
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