[TOC]

# jobs任务管理

使用`jobs`命令可以查看当前终端的任务列表，常用选项：

> ```shell
> -l：在正常信息基础上列出进程号
> -n：仅列出自上次调用以来状态发生变化的进程
> -p：仅显示进程号
> -r：仅显示当前正在运行的进程
> -s：仅显示当前处于停止状态的进程
> ```



## 暂停

<kbd>Ctrl</kbd>+<kbd>Z</kbd> 暂停当前前台进程，并将其移至后台（状态为 Stopped）。

其会向前台进程发送 `SIGTSTP` 信号，等同于执行：

```shell
kill -SIGTSTP <PID>
```

类似的有`SIGSTOP`信号，它们区别是：

* `SIGTSTP` 是可被进程捕获和忽略的暂停信号；
* `SIGSTOP` 也能暂停进程，但不能被捕获或忽略，通常用于强制挂起。



## 恢复

### `fg`：恢复为前台任务

将后台任务带回前台运行：

```shell
fg        # 将最近的后台任务调回前台

#如果后台中有多个命令，可以用%n调用指定编号的任务
fg %2     # 将编号为 2 的任务调回前台
```



### `bg`：恢复为后台运行

将暂停的后台任务继续在后台运行：

```shell
bg %1  #用法同fg
```

其会向进程发送`SIGCONT`信号，等同于执行：

```shell
kill -SIGCONT <PID>
```



## 终止

<kbd>Ctrl</kbd>+<kbd>C</kbd> 终止当前的前台进程

其会向进程发送 `SIGINT` 信号，等同与执行：

```shell
kill -SIGINT <PID>
```

其他信号：

* `SIGTERM`：默认由 `kill` 发送，温和终止，进程可捕获；
* `SIGKILL`：强制终止（`kill -9`），不可捕获、不可忽略；
* `SIGHUP`：挂起信号，常在终端关闭或会话退出时发送。



# 保持后台运行

将命令放入后台：

```shell
ping -c 99 z.cn &             # 后台运行
ping -c 99 z.cn > ping.log &  # 输出重定向
```

循环命令放入后台：

```shell
#将整个for循环/while循环放入后台 在done后面添加&
for i in {1..10}
do
  sleep 1
  echo $i
done &
```



以上仅使用`&`将任务放入后台，是当前 shell 的子进程，shell 退出时将收到 `SIGHUP`，导致任务终止！

可使用以下方法在推出当前shell后保持继续运行。



## nohup

`nohup`英文全称 no hang up（不挂起），父进程退出时，这个子进程将忽略`SIGHUP`信号，该进程将托管给1号进程成为1号进程子进程。

```shell
nohup long_task.sh > out.log 2>&1 &
```



## `setsid`

`setsid`创建一个新的会话运行程序，将进程作为1号进程的子进程。

```shell
setsid ping -c 10 z.cn > ping.log &
```



## 子 shell + 后台

将一个或多个命名包含在`()`中就能让这些命令在**子 shell 中运行**，将命令连同`&`也放入`()`内之后，该进程就**不再是当前终端进程的子进程**，而是1号进程的子进程。

```shell
(sleep 233) &
```



## disown

`disown`为shell内置命令

选项：

```shell
-a	如果不提供 JOBSPEC 参数，则删除所有任务。
-h  标识每个 JOBSPEC 任务，从而当 shell 接收到 SIGHUP信号时不发送 SIGHUP 给指定任务。
-r  仅删除运行中的任务。
```



- 如果提交命令时已经用`&`将命令放入后台运行，直接使用`disown`即可。

  1. `jobs`   命令查看该后台任务的作业号(jobID)
  2. `disown -h %<jobID>`

  

- 如果提交命令时未经用`&`将命令放入后台运行，可以：

  1. <kbd>Ctrl</kbd> <kbd>z</kbd>挂起任务
  2. `jobs`命令查看挂起的作业号(jobID)
  3. `bg`放入后台执行
  4. `disown -h %<jobID>`
  
  ```shell
  ➜  ~ sleep 999
  ^Z
  [1]  + 118959 suspended  sleep 999
  ➜  ~ jobs
  [1]  + suspended  sleep 999
  ➜  ~ bg %1
  [1]    118959 continued  sleep 999
  ➜  ~ disown %1
  ➜  ~ pstree -p $$
  zsh(118784)─┬─pstree(119126)
              └─sleep(118959)
  ```
  
  disown后其仍为当前shell子进程，但是shell退出时其不会被中止，而将成为1号进程子进程。
  
  ```shell
  ➜  ~ ps -ef|grep sleep
  root      118959       1  0 21:04 ?        00:00:00 sleep 999
  ```
  
  

## at 、cron、systemd unit等

* `at`：可指定时间运行一次性任务，使用`at now`可创建at任务后立即执行。

  ```shell
  echo "ping -c 10 z.cn" | at now
  echo "pkill gdm" | at 23:59 today
  ```

  

* `cron`：周期性任务；

* `batch`：负载低时运行任务。



## `tmux`、`screen`

用于大量运行后台任务的场景，功能强大。



# 多后台任务控制

模拟多线程，Shell中没有真正意义的多线程，可启动多个后端进程，最大程度利用cpu性能。

## wait 进程阻塞

需要等待后台任务完成后再执行后续任务的场景。

`wait`等待作业号或者进程号制定的进程退出，返回最后一个作业或进程的退出状态状态。

如果没有指定参数，则等待所有子进程的退出，其退出状态为0。

shell中等待使用wait，不会等待**调用函数中的子任务**；在函数中使用wait，则只等待函数中启动的后台子任务。（类似其他编程语言的多线程编程）

示例：

```shell
for f in $(ls -a)
do
{
  chmod 755 $f
  cp $f /tmp/ -av
}& #将放入后台 相当有新开一个线程
done
wait  #等待以上所有任务（放入后台的任务）执行完毕后才会执行下面的命令
echo "done at $(date)" >> /tmp/copy.log
```



## 并发任务数量控制

为了避免后台任务过多（操作系统压力过大）而需要控制后台任务数量的场景。



### 使用 `xargs`

```shell
seq 1 10 | xargs -n 1 -P 3 -I {} sh -c "echo task {}; sleep 1"

thread_num=5
all_num=100

seq 1 ${all_num} | xargs -n 1 -I {} -P ${thread_num} sh -c "echo dosomething;sleep 1;echo -----"

wait
echo -e "end"
```

选项：

- `-P <N>`  指定运行后面命令的进程数量（默认为1），0时表示尽可能地大；

- `-n 1`   指定每次使用的传入参数（管道符传来的参数）的数量，默认是所有参数。

  控制并发任务数量的场景下应该将其设置为1。

  ```shell
  echo {1..3}|xargs #打印1 2 3到一行 一次使用了所有传入参数
  echo {1..3}|xargs -n 1 #打印3行，分别是1,2,3，一次使用1个参数
  ```

- `-I {}`  指定将xargs会将传入参数赋予某个名称，一般约定习惯命名为`{}`，其他命令可直接使用`{}`（可任意起名）

  ```shell
  echo {1..3}|xargs -n 1 -I {} echo "get arg {}"
  ```

  

### FIFO 管道控制

```shell
fifofile="/tmp/$$.fifo"  #$$为当前shell的pid
mkfifo $fifofile
exec {fdnum}<>$fifofile #让系统分配一个fd索引值
#exec 6<>$fifofile  #也可以为fifofile的文件手动指定一个描述符6
thread_num=5

for ((i=0;i<${thread_num};i++));do  #为进程创建相应的占位
    echo  #为进程创建相应的占位
done >&$fdnum  #将占位信息写入管道$fdnum

for j in {1..50}
do
#每次执行read -u$fdnum命令，将从FD6中减去一个换行符号\n，然后向下执行
#当$fdnum中没有回车符，就停止，从而实现线程数量控制
read -u$fdnum
{
  sleep 1  #换成要执行的代码，这里模拟假设普通顺序执行时 每一条代码执行要花费1s
  echo "$j...pid is $$"
  echo >&$fdnum  #当任务执行完后，会释放管道占位，所以补充一个占位
}& #将进程放入后台
done

wait
echo "done at $(date)" >> /tmp/copy.log
# exec $fdnum>&-  #关闭标识符
```

有名管道和无名管道：

- 无名管道`|`：`ps aux | grep ping`

- 有名管道：`mkfifo /tmp/fd1`  由`mkfifo`创建（fifo first input first output），如果管道内容为空，则阻塞。示例：

  1. 打开一个终端，输入执行：

     ```shell
     mkfifo /tmp/fd1; cat /tmp/fd1; echo "oooh, done!"
     ```

     将发现echo 内容没有输出，当前shell处于阻塞状态，因为没向/tmp/fd1写入过内容

  2. 新开一个终端，输入执行：

     ```shell
     echo "unlock" >> /tmp/fd1 #随便输入什么内容都行
     ```

     发现前一个终端阻塞解除，执行了后面echo的内容。

文件描述符(file descriptor)：

> linux为了实现一切皆文件的设计哲学，不仅将数据抽象成了文件，也将一切操作和资源抽象成了文件，比如说硬件设备，socket，磁盘，进程，线程等。

内核（kernel）利用文件描述符（file descriptor）来访问文件，每打开或创建一个文件，内核就会向进程返回一个`fd`，`fd`是一个非负的整数。

习惯上，

- 标准输入（standard input）的文件描述符是 0
- 标准输出（standard output）是 1
- 标准错误（standard error）是 2

3以后对应打开的文件，使用`ulimit -n`可查看一个进程可打开的文件描述符数量。



## 任务管理进阶

### shell job control 开关

* 开启：`set -m`
* 关闭：`set +m`

可用于控制是否允许 job 控制（某些脚本场景中关闭更稳定）。



# 附

## 进程、线程、服务、任务概念

| 类型            | 描述                                              |
| --------------- | ------------------------------------------------- |
| 进程（Process） | 独立运行的程序实例，拥有独立内存空间              |
| 线程（Thread）  | 进程中的执行单元，共享内存空间                    |
| 服务（Service） | 在后台长期运行的进程，通常无终端                  |
| 任务（Task）    | 泛指一个操作或动作，可能由一个或多个进程/线程组成 |



## 进程类型

* 交互进程：由 shell 启动；
* 批处理进程：脱离终端运行；
* 守护进程：后台常驻进程（如 `sshd`、`cron`）。



## 进程组与会话

### 进程组（process group）

一组相关联的进程（通常父子），由进程组 ID（PGID）标识，常用于信号广播控制。

```shell
ps -o pid,ppid,pgid,sid,comm
```

### 会话（session）

多个进程组的集合，标识一个用户会话：

* 一个终端登录即为一个 session；
* `setsid` 可启动新 session。



## 文件描述符（FD）

| 标准流   | FD 值 | 说明     |
| -------- | ----- | -------- |
| 标准输入 | 0     | `stdin`  |
| 标准输出 | 1     | `stdout` |
| 标准错误 | 2     | `stderr` |

重定向示例：

```shell
command > out.log 2>&1     # 输出和错误都重定向
command < in.txt           # 从文件读取输入
```

查看最大打开文件数：

```shell
ulimit -n
```

