# 单次任务at

## at服务和配置

使用at执行任务前，确保atd.service已经启动。

```shell
systemctl start atd  #立即启动atd
systemctl enable atd  #开机atd自启动
```

`/etc/at.deny`和`/etc/at.allow`（该文件默认不存在需自行创建）用以指定可使用at的用户黑名单和白名单。

用户的at任务列表存储在`/var/spool/atd`下，文件与用户名一致。

默认情况，普通用户是不能直接用编辑器添加或编辑该文件的（当然root用户可以编辑，或者对该文件进行权限重设，但不建议）。



## at使用

at相关命令：

- `at`    在指定实现执行任务

  常用选项：

  - `-f`：指定包含具体指令的任务文件
  - `-q`：指定新任务的队列名称
  - `-l`：`atq`的别名
  - `-r`：`atrm`的别名
  - `-d`：`atrm`的别名
  - `-b`：`batch`的别名
  - `-m`：任务执行完成后向用户发送E-mail
  - `-c` ：查看指定的任务内容

  

- `atq`   列出用户待执行的任务

- `atrm`  删除指定任务

- `batch`  在系统负载水平允许的情况下执行命令，默认负载值0.8（查看`man batch`获知），可指定一个负载值。创建任务方式参看“创建at任务”。



### at任务创建

- 使用脚本`at <时间点> -f <脚本名>`

- 使用交互式命令行

  1. 输入`at [选项 参数] 时间点，然后回车

  2. 输入要执行的命令

     注意：命令可能需要使用绝对路径

  3. 按下<kbd>Ctrl</kbd> <kbd>d</kbd>退出at交互式命令行



### at时间点表述方式

at的时间表述方式多样，扩展自POSIX.2的标准。



- 时间：某时某分

  未指定日期，则表示今天的某时某分，但如果设置任务时该时间点已经时过去，则在次日的该时间点执行。

  - 时分：`HH:MM`，只可精确到某小时的某分钟

    **表示00-09分时不可省却前面的0，分钟不可省略**（除非配合am/pm，见下文）

    ```shell
    at 12:00
    at 3:01
    ```

    

  - 上午（00:00-11:59）下午（12:00-23:59）：`AM`  `PM`  大小写均可，必须配合时分使用

    ```shell
    at 7pm
    at 7 pm
    at 7:00pm
    at 7:00 pm
    ```

    表示上午/下午几点可以不指定分钟。

  

  - 午夜`midnight`，等同`00:00`
  - 正午`noon`，等同`12:00`
  - 茶歇时间`teatime`，等同`4pm`

  

  - 现在`now`

    添加任务后立即创建子进程在后台执行。

    

- 日期：某年某月某日

  未指定准确的时分时则使用创建任务时的时间。

  - 年月日

    - `MMDD[CC]YY`
    - `MM/DD/[CC]YY`
    - `DD.MM.[CC]YY`
    - `[CC]YY-MM-DD`

    ```shell
    at 2046-11-30   #在2046年11月30日的此时（创建at任务的时分）
    ```

  

  - 几月，月份可使用全写或三字母简写，首字母可大小，**必须指定该月的几日**

    ```shell
    at 3pm Jul 31  #7月31日下午3点
    at midnight july 31  #在7月31日午夜
    ```

    

  - 星期几，可使用全写或三个字母的缩写形式，首字母可大小

    ```shell
    at monday
    at mon    #同monday
    at 11pm Tue
    ```

    

  - 今天`today`，明天`tomorrow`，**必须配合时间描述**

    ```shell
    at noon today
    at 7pm today
    ```

    

- `+`  配合日期和时间描述，表示指定时间点后的某时间点

  `+`还可使用时间单位值： minutes(min),  hours,  days, weeks

  ```shell
  at now + 30 miniutes
  at 10am+3days
  at 12pm July 31 + 3days
  ```



# 周期任务cron

## cron服务和配置

cron有多个软件实现，如cronie、fcron、dcron等等。

确保实现cron的服务已经作为守护进程运行（如ronie或crond）。

`/etc/cron.deny`和`/etc/cron.allow`（该文件默认不存在需自行创建）用以指定可使用cron的用户黑名单和白名单。

`/etc/crontab`是系统的crontab文件，通常只被 root 用户或守护进程用于配置系统级别的任务。用户的crontab列表存储在`/var/spool/cron`或`/var/spool/cron/crontabs`下，文件与用户名一致。



crontab基本命令：

```shell
crontab -l   #查看当前用户cron任务列表文件
crontab -e   #编辑当前用户cron任务列表文件
crontab -r   #移除用户的cron任务
crontab -u <username> -e  #编辑指定用户的cron （root和具有sudo权限的用户）
```

可以直接编辑用户的cron文件，但是一般推荐使用`crontab -e`编辑cron文件，这样在保存时，cron会自动进行语法校验。



提示：默认的cron文件编辑器一般是vi，可使用以下命令修改：

```shell
export EDITOR="/usr/bin/vim"  #修改默认编辑器为vim
```



读取指定文件（按照[cron文件语法](#cron文件语法)编写）并将其内容添加到当前用户cron文件中：

```shell
cronlist=$(mktemp)
echo "1 * * * * whoami" >> $cronlist
crontab $cronlist
```



## cron任务语法

cron文件中**每一行一个任务**，

单个任务的书写格式：

> `时间 命令`

注意命令运行的环境变量及路径（最好使用绝对路径）

可使用`#`注释行。



时间有两类表示法

- `分 时 日 月 周`字段

  - 确定的数值
    - 分 值从 0 到 59
    - 时 值从 0 到 23
    - 日 值从 1 到 31
    - 月 值从 1 到 12
    - 周 值从 0 到 7    （其中0和7均代表周日）

  - 特殊符号
    - `*`  任意值

    - `-`  连接符用在两个值之间表示一个时间段

      如在“时”这个字段使用`1-3`表示1点、2点、3点

    - `,`  分隔符用在两个（多个）值之间表示两个（多个）时间点

      如在“日”这个字段使用`1,2`表示1号和2号

    - `/`  分隔符用在两个值之间表示间隔频率

      如在“分”这个字段使用`*/5`表示每5分钟

- 是以`@`开头的特殊字符串

  - `@reboot`  每次启动时
  - `@yearly` 或 `@annually`  每年，等同于 `0 0 1 1 *`
  - `@monthly`  每月，等同于 `0 0 1 * *`
  - `@weekly`  每周，等同于`0 0 * * 0`
  - `@daily` 或 `@midnight`  每天，等同于`0 0 * * *`
  - `@hourly`  每小时，等同于`0 * * * *`

示例：

```shell
* * * * * /usr/ls  #每分钟执行一次ls
0 0 1 * * /usr/bin/reboot  #每月1日0时0分重启系统

#每周三周六1点到3点和11点到13点每5分钟执行一次/home/test/update.sh
*0,*5 1-3,11-13 * * 3,6 /home/test/update.sh

#每次启动后执行
@reboot  /usr/bin/echo $(/usr/bin/date) > /tmp/newboot
```



## cron中的环境变量

注意：cron执行中不会读取用户环境变量，cron的默认环境变量只有`/bin`没有`/sbin`。

**如果执行的任务环境变量有问题**，可以在要执行的任务中设置正确的环境变量，例如：

```shell
#cron list
@reboot PATH=/sbin:/bin && lsmod |grep nvidia
```

如果任务中执行的额外的程序，可在那个程序中配置好环境变量。



也可以在cron文件中添加环境变量，作用于所有cron任务，使用`crontab -e`打开文件，添加环境变量例如：

```shell
SHELL=/bin/bash
PATH=/usr/sbin/apps/bin:$PATH
MAILTO=      #send mail to someone
HOME=/root  

#task list below...
```

