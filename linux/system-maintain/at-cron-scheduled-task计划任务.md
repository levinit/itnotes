# 单次任务at

## at服务和配置

使用at执行任务前，确保atd.service已经启动。

```shell
systemctl start atd  #立即启动atd
systemctl enable atd  #开机atd自启动
```

`/etc/at.deny`和`/etc/at.allow`（该文件默认不存在需自行创建）用以指定可使用at的用户黑名单和白名单。

用户的at任务列表存储在`/var/spool/atd`下，文件与用户名一致。默认情况，普通用户是不能直接用编辑器添加或编辑该文件的（当然root用户可以编辑，或者对该文件进行权限重设，但不建议）。



## at使用语法

- 语法：`at 选项 参数 时间语句` 

  - 选项：

    - `-f`：指定包含具体指令的任务文件

    - `-q`：指定新任务的队列名称

    - `-l`：显示待执行任务的列表

      `at -l`是`atq`的别名，查看系统中其他尚未执行的命令，将显示任务列表，每一个任务有一个数字编号。

    - `-d`：删除指定的待执行任务

      `at -d`是`atrm`的别名，`atrm 任务编号`  删除某条未执行的任务。

    - `-m`：任务执行完成后向用户发送E-mail

    - `-c` ：查看指定的任务内容

      `at -c 数字`  显示某条未执行的任务内容

  - 时间语句示例：

    ```shell
    at 12:22
    at 17:00 tomorrow
    at now+30 miniutes
    at 10am+3 days
    ```

- 创建at任务

  - 使用脚本`at <时间语句> -f <脚本名>`

  - 使用交互式命令行

    1. 输入`at [选项 参数] 时间语句`，然后回车

    2. 输入要执行的命令

       注意：命令可能需要使用绝对路径

    3. 按下<kbd>Ctrl</kbd> <kbd>d</kbd>退出at交互式命令行

提示：用户的at任务列表文件位于`/var/spool/at/`目录下，文件名与用户名相同，因此也可以直接编辑该目录下相应的文件管理用户的at任务列表。

# 周期任务cron

## cron服务和配置

cron有多个软件实现，如cronie、fcron、dcron等等。确保实现cron的服务已经作为守护进程运行（如ronie或crond）。

`/etc/crontab`是系统的crontab文件，通常只被 root 用户或守护进程用于配置系统级别的任务。



用户的crontab列表存储在`/var/spool/cron`下，文件与用户名一致。默认情况，普通用户是不能直接用编辑器添加或编辑该文件的（当然root用户可以编辑，或者对该文件进行权限重设，但不建议）。



`/etc/cron.deny`和`/etc/cron.allow`（该文件默认不存在需自行创建）用以指定可使用cron的用户黑名单和白名单。



## cron使用语法

用户应使用`crontab -e`编辑周期任务列表，cron列表**每一行一个任务**。root用户和具有sudo权限的用户可以使用`crontab -u username -e`编辑其他用的任务列表 （username是其用户名）。

提示：默认的cron文件编辑器一般是vi，可使用以下命令修改：

```shell
export EDITOR="/usr/bin/vim" `  临时修改默认编辑器为vim
```



如果需要使用命令直接添加任务而不是使用`crontab -e`进行编辑添加，可以在一个文件中先写好任务列表，再使用crontab读取该文件一添加到用户任务列表中：

```shell
  cronlist=$(mktemp)
  echo "1 * * * * whoami" >> $cronlist
  crontab $cronlist
```



单个任务的书写格式：

> `时间 命令`

注意命令运行的环境变量及路径（最好使用绝对路径）

时间有两种表示法

- `分 时 日 月 周`

  - 分 值从 0 到 59
  - 时 值从 0 到 23
  - 日 值从 1 到 31
  - 月 值从 1 到 12
  - 周 值从 0 到 7    其中0和7均代表周日

  该表示法中每个时间还可以使用以下特殊符号

  - `*`  任意值
  - `-`  连接符用在两个值之间表示一个时间段
  - `,`  分隔符用在两个（多个）值之间表示两个（多个）时间点
  - `/`  分隔符用在两个值之间表示间隔频率

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
@reboot  /usr/bin/echo $(/usr/bin/date) > /tmp/newboot
```

crontab其他参数或命令：

- -l  查看任务列表
- -r  移除任务列表
- -u  指定用户