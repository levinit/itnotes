# ps

ps是查看进程(process)信息的命令。

该命令选项极多，这里仅介绍常用的UNIX风格短选项，另有BSD风格的选项，以及长选项。

- 常用短选项
  - -e或-A  所有进程*（最常使用的选项，与其他选项配合）*
  - -f  或 -F  完整格式的输出
  - -l  详细进程信息（显示长列表）
  - -L  显示线程信息，列名为LWP(light weight process (thread) ID ,即tid或spid) 和 NLWP(number of LWP )
  - -U  属于指定用户的进程
  - -G  属于指定用户组的进程
  - -p  指定进程编号的进程
  - -d  除控制进程外的进程
  - -a  除控制进程和无终端进程外的进程
  - -u  指定用户
  - -o 指定特别的选项

不带任何参数时使用该命令仅显示当前控制台下属于当前用户的进程信息，显示的各列信息：

- PID  进程的编号
- TTY  启动进程的终端（?表示没有使用终端，即无终端进程）
- TIME  运行进程耗费的CPU时间
- CMD  启动该进程的程序名称(command)

`-f`选项额外显示的各列信息：

- UID 启动进程的用户
- PPID  父进程的编号(parent PID)
- C  进程生命周期中的CPU利用率
- STIME  进程启动时的系统时间(star time)

`-l`选项额外显示的各列信息：

- F  内核分配给进程的系统标记(flag)

- S  进程的状态(status)

  各种状态：

  - D  不可中断的睡眠(Uninterruptable sleep)  *一般是处于IO状态*
  - R  正在运行
  - S  中断睡眠(interruptable sleep)  *进程等待某个资源处*
  - T  停止(terminated)
  - X  终止的进程
  - Z  “僵尸”(zombie)  
  - N  低优先级
  - L  锁定
  - s  包含子进程
  - `+`  位于后台进程组
  
- PRI  进程的优先级(priority)

- NI  谦让度(nice) 该值用来参与决定优先级

- ADDR  内存地址

- SZ  假如有进程被换出，表示所需交换空间大小(size)

- WCHAN  进程休眠的内核函数的地址

常用示例：

```shell
ps -efL
ps -up pid1，pid2  #查看指定pid
ps -eo command,user,pid,ppid,comm root

#指定参数查看
ps -eo user,euser,ruser,pid,ppid,comm,command,vsz,rsz
ps -o user=userForLongName -e -o pid,ppid,cmd
```

`-o`参数：

- 用户相关

  - user和euser 相同意义，代表（改运行文件的）有效权限用户 
  - euid=uid，egid=gid
  - ruser代表真正执行用户。
  - ruid和rgid

  userForLongName 显示长用户名，避免用户名过长显示不全时省略部分显示为+

- 命令相关

  - cmd作用等同于command和args，代表执行的完整命令，包括选项参数。
  - comm是command name，只显示命令不显示其选项参数。

- 进程

  - pid即process id
  - ppid即parent pid

- cpu相关

  - %cpu=c， processor utilization.
  - etime，elapsed time since the process was started,in the form [[DD-]hh:]mm:ss.
  - etimes，elapsed time since the process was started, in seconds.

- 内存空间相关

  - %mem=pmem，ratio of the process's resident set size（percentage）
  - sz， size in physical pages of the core image of the process
  - rss=rssize=rsz，resident set size, the non-swapped physical memory that a task has

   used (in kiloBytes）





# pgrep



# kill killall pkill







# lsof



# fuser





# top

另有htop，界面直观，操作方便。

top是实时监控进程信息的命令。

s – 改变画面更新频率
l – 关闭或开启第一部分第一行 top 信息的表示
t – 关闭或开启第一部分第二行 Tasks 和第三行 Cpus 信息的表示
m – 关闭或开启第一部分第四行 Mem 和 第五行 Swap 信息的表示
N – 以 PID 的大小的顺序排列表示进程列表
P – 以 CPU 占用率大小的顺序排列进程列表
M – 以内存占用率大小的顺序排列进程列表
h – 显示帮助
n – 设置在进程列表所显示进程的数量
q – 退出 top
s – 改变画面更新周期