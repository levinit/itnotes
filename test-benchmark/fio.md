# 简介

fio可运行在多种系统之上，用以测试本地磁盘、网络存储等的性能。

fio功能强大，支持十几种IO引擎，支持多客户端并发测试（server、client模式），支持文件级、对象级存储测试，自带绘图工具（调用gnuplot绘图），可对测试需要的cpu、内存、进程/线程等进行灵活配置。



参看[fio doc](https://fio.readthedocs.io/en/latest/)

# 作业参数

fio中将测试行为成为job（作业）

fio支持直接使用选项参数，如：

```shell
fio --name=seqWrite --ioengine=libaio --rw=write --bs=4k --direct=0 --size=10G --numjobs=1 --iodepth=48 --runtime=60 --time_based --group_reporting --directory=tmp  # --filename=fio-w-1t-48iodepth
```

也可以编写一个描述各个选项参数的作业文件进行测试，常用参数如下：



## 通用参数

通用参数可用于作业文件中，也可以用于命令行中，在命令行中使用时需要在选项名字前加上`-`。

如`bs`，在作业文件中：

```ini
bs=4k
```

在命令行中：

```shell
fio -bs=4k
```



### I/O类型

文件的输入输出模式。

- 读写方式`rw`或`readdwrite`  读写方式，取值：
  - read顺序读    write顺序写    rw顺序读写
  - randread随机读    randwrite随机写    randrw随机读写
  - trim、randtrim、trimwrite  块设备（仅Linux）

- `rwmixwrite`  值为数字，指混合读写模式下写占的比例（百分比）
- `direct`    值为1时使用非缓冲（non-bufferd）I/O（通常是O_DIRECT），默认0
- `bufferd`   值为1时使用缓冲（bufferd）I/O，默认为1。该选项值始终与`direct`的取值相反。



### I/O大小

读写的数据量

- `size`    此作业每个线程的io操作总数据量

  示例：`size=10G`  `size=20%`

  百分数表示读写大小为该分区容量的的百分比空间。

  测试的总io大小，除非受到其他选项的限制（如`runtime`的值），fio将指定大小的数据量全部读/写完成，才会停止测试。
  
  fio将此大小划分为由`nrfiles`（默认1）`numjobs`、`name`（即作业名字）、`filename`等选项确定的可用文件的名称和大小。
  
  在`filename`未设置情况下，生成名称由name、numjobs序号和nrfiles的序号组成的文件，每个文件大小为$$size/nrfiles$$。例如`-nrfiles=4 -numjobs=2 -size=1G -name=test`，`filename`未设置，则fio将生成类似test.0.0、test.1.0（test为作业名，1表示numjob的第二个job，0表示nrfiles的第1个file）等文件，每个文件256M（1G/4）。
  
  
  
- `filesize`    单个文件的大小范围，fio将在给定范围内随机选择文件的大小，此选项将覆盖`size`值

  如`-size=1G -nrfiles=2 filesize=10M-1G`，则fio读写生成的每个文件大小在10M到1G之间的随机大小，忽视`size`（没有指定filesize情况下，每个文件大小应当是1G/2=500M）

  

### I/O引擎

I/O操作模式，选项`ioengine`常用取值：

- psync - 默认，对应的 pread / pwrite

- libaio - Linux 原生的异步 I/O（需要安装有libaio包）

- sync -  同步read / write 操作

- vsync - 使用 readv / writev，主要是会将相邻的 I/O 进行合并

- pvsync / pvsync2 - 对应的 preadv / pwritev，以及 preadv2 / p writev2

  

### I/O深度

一次提交给系统的I/O请求数量，只对异步I/O引擎有意义。同步I/O总是会等待提交的I/O请求完成后，再提交下一个I/O请求，iodepth总是1。

- `iodepth`  个进程/线程可以同时下发的io作业数（io深度），默认为`1`

  随着iodepth的增大在一定范围内，带宽、io延时会增加，超过一定范围后带宽增加缓慢，延时继续会增加。




### 块大小

I/O分发的数据块大小，一个固定的值或取值区间，参数：

- `bs`或`blocksize`    值为块文件大小  如`bs=4k`，`bs=4k,16k`
- `bsrange`或`blocksize_range`   数据块的大小范围  如`bsrange=512-2048`



### 延迟限制

- `max_latency`   最大延迟，当延迟超过该值，fio会自动退出，整数，单位微秒
- `latency_target`    目标延迟，最大可接受的延迟，整数，单位微秒
- `latency_window`    延迟窗口，工作在不同队列深度下测试性能的窗口，整数，单位微妙
- `latency_percentile`     延迟时间百分比，浮点数，默认为100.0，意味着所有IO延迟必须等于或低于目标设置的值。
- `minimum`



### 测试目标

测试目标可以是文件、块设备、镜像

- `directory`    测试生成文件存放目录

  可以通过用`:`字符分隔这些名称来指定多个目录，这些目录将平均分配给作业线程创建的文件。

- `filename`   测试对象，一般是设备或者文件。
  如`/dev/sdb`，`/share/testf`

  如不指定，fio默认根据作业名、线程号和文件号组成文件名（请参见filename_format）（因此可以只指定`directory`值，不设置`filename`，测试文件生成在`directory`下）。

  

- `nfiles`    用于此作业的文件数。默认1。

  每一个作业要产生多少个大小为filesize的文件。

  作业的每个线程将分别创建文件，除非由文件大小指定显式大小，每隔线程的filesize值将为size除以nfiles（$filesize=size/nfiles$）。

- `openfiles`    同一时间可以打开的文件数量，默认与nfiles值相同。



### buffer和memory

- `lockmem`   无取值 锁定每个作业的可用内存上限，模拟较小内存的场景。
- `zero_buffers`    无取值 初始化具有所有零的缓冲区。默认使用用随机数据填充缓冲区。



### 线程/进程数量和作业异步

- `thread`    无值。Fio默认使用fork创建作业，使用该选项后，将使用POSIX线程的函数pthread_create创建线程。

  使用 thread **在一定程度上可以节省系统开销**

- `exec_prerun`   运行作业之前，通过过system执行指定的命令。

- `exec_postrun`   运行作业之后，通过过system执行指定的命令

- `cpus_allowed`    允许作业使用的cpu，用于cpu绑定。

  cpu从0开始索引。

  对于SSD测试，最好进行cpu绑定，因为若IOPS太大，fio线程运行在相对繁忙的cpu上，测试可能达不到最佳性能。

  此外还可以使用`taskset`绑定cpu，如`taskset -c 11 fio...`。

  

### 测试时间

- `runtime`   测试作业运行的时间，到达该时间测试将终止，单位秒。 如`runtime=100`

- `time_based`    以`runtime`的值为最终运行时间。无值。

  如果设置了该选项，当同时设置有size和runtime，如果读写已经达到size的大小，但未达到rumtime的限定时长，测试将继续直到达到runtime的限制。

- `ramp_time`   测试的热身时间，热身时间不计入测试统计，单位秒

- `startdelay`   延迟时间，单位秒。

  与ramp_time的区别：startdelay是job作业完全不运行空等待，ramp_time作业运行而此段时间内不会做记录。

  

### 作业描述

- `description`    描述信息

- `loops`   测试轮数，默认1

- `numjobs`    测试的线程/进程数量，默认1

  如果指定了`thread`参数，则使用单进程多线程模式，否则使用多进程模式。

  由于每个线程单独报告，如果要汇总所有线程的数据报告，需将group_reporting与new_group结合使用。



### 报告相关

- `group_reporting`  汇总报告结果，无值。

  如不使用该参数，当`numjobs`大于1时将为每个线程生成报告。

- `output`   报告输出文件的路径。

  如不指定，则报告只打印而不输出到文件中。

- 输出文件相关

  - `log_avg_msec`    日志记录均值间隔时间，单位毫秒，仅记录一段时间内的所有io测试值的平均数

    默认每次I/O的iops、bw和lat值都将被记录，会造成最终记录日志文件过大，对每n秒种所有I/O的记录值取平均值以减少文件大小。

    如`log_avg_msec=2000`，每2000毫秒内的记录值平均，仅记录该平均值到日志中。

  - `write_bw_log`、`write_lat_log`、`write_iops_log`   指定记录指定测试指标的日志文件：bw为bandwidth，lat为latency，iops为io per second。

    该值为存储指定指标的日志文件的前缀，如`write_bw_log=test-1m`，则生成为日志文件为`test-1m_bw.x.log` ，其中x为作业的编号，如不想有作业编号.x部分，添加`per_job_logs=0`参数即可。

    如果指定了选项但未赋值，如指定选项`write_bw_log`，则生成`jobname_bw.x.log`。

  

### 其他常用

- `thinktime`   等待时间，在I/O完成后，停止指定的作业，然后发布下一个作业。

  

## 仅用于作业文件中的参数

仅能用于作业文件中

- `[global]`   全局配置，适用于所有作业

- `stonewall`或`wait_for_previous`    仅在fio配置文件中的作业部分使用，表示在启动这个作业之前，等待作业文件中的前面的作业退出。可用于在作业文件中插入序列化点，也意味着创建一个新的报告小组，参见小组报告。

- `include`   引入其他作业文件中的内容

  ```ini
  [global]
  include global.ini
  
  [test1]
  rw=read
  ```

  被引入的文件global.ini

  ```shell
  direct=1
  size=1g
  runtime=10
  time_based
  ```



## 仅用于作业文件中的变量

fio支持在作业文件中使用shell中的环境变量。

fio还有一组保留关键字，内部将用适当的值替换。这些关键词包括：

- `$pagesize`    当前系统的页文件大小
- `$mb_memory`    当前系统内存大小（单位mb）
- `ncpus`    当前系统可用cpu数量



示例：

```shell
bs=4k dir=/share/testdir fio test.conf
```

test.conf中可引用变量如下

```ini
[global]
bs=${bs}
directory=${dir}
numjobs=${ncpus}
```



## 仅用于命令行的选项

只能用于命令行中，不可用于作业文件中，这些选项都以`--`开头。

- `--name`    作业的名字，即作业配置文件中`[]`包含的内容（golbal除外）

- `--output`   输出日志保存的文件的路径（默认只输出不保存到文件）

- `--output-format`    报告文件格式，取值：

  - `normal`  默认值，普通文本文件
  - `terse`    基于csv格式
  - `json`    
  - `json+`    

  可设置多种格式如`output-format=json,terse`。

- `--server`和`--client`    参看[client/server章节](#client/server模式)

  

# 作业文件示例

示例作业文件fio.ini

```ini
[global]
ioengine=libaio  #psync | sync
direct=1
zero_buffers
thread=1
numjobs=1
directory=${dir}
runtime=30
size=1g
latency_target=5000
latency_window=50000000
latency_percentile=95
time_based
group_reporting
per_job_logs=0

[4k-randwrite]
name=4k-randwrite-iops
iodepth=128
bs=4k
rw=randwrite
write_iops_log
stonewall

[4k-randread]
name=4k-randread-iops
iodepth=128
bs=4k
rw=randread
write_iops_log
stonewall

[1m-write]
name=1m-write-bw
bs=1M
rw=write
numjobs=$ncpus
write_bw_log
stonewall

[1m-read]
name=1m-read-bw
bs=1M
rw=read
numjobs=$ncpus
write_bw_log
stonewall
```

示例使用fio.ini运行测试：

```shell
dir=. --output-format=terse fio fio.ini
```



示例使用命令行测试：

```shell
fio -directory=. -bs=4k -size=2G -numjobs=1 -runtime=30  -ioengine=libaio -iodepth=96 -direct=1 -rw=randrw -rwmixwrite=50% -time_based -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-read --output-format=terse 
```

多CPU可以绑定在最近的NUMA node的所有core上测试（尤其是本机SSD），示例：

> ```shell
> [root@master ~]#  readlink -f /sys/block/sda/sda2  #查询ssd设备的pci
> /sys/devices/pci0000:5d/0000:5d:00.0/0000:5e:00.0/host0/target0:2:0/0:2:0:0/block/sda/sda2
> [root@master ~]# lspci -s 0000:5d:00.0 -v|grep -i node  #查询ssd对应的numa节点
> 	Flags: bus master, fast devsel, latency 0, IRQ 32, NUMA node 0
> [root@master ~]# lscpu|grep NUMA
> NUMA node(s):          2
> NUMA node0 CPU(s):     0-15,32-47
> NUMA node1 CPU(s):     16-31,48-63
> [root@master ~]# numactl -H 
> available: 2 nodes (0-1)
> node 0 cpus: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
> node 0 size: 31670 MB
> node 0 free: 5226 MB
> node 1 cpus: 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63
> node 1 size: 32231 MB
> node 1 free: 8446 MB
> node distances:
> node   0   1 
>   0:  10  21 
>   1:  21  10 
> #[root@master ~]# taskset -c 0-47 fio xxx
> ```

# 输出信息含义

示例：

> ```shell
> $ fio -iodepth=1 -runtim=10 -size=1G -filename=aaa -rw=write -bs=1M -name="test"
> test: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=psync, iodepth=1
> fio-3.25
> Starting 1 process
> test: Laying out IO file (1 file / 1024MiB)
> Jobs: 1 (f=1): [W(1)][100.0%][w=109MiB/s][w=109 IOPS][eta 00m:00s]
> test: (groupid=0, jobs=1): err= 0: pid=1679412: Sun Jun 20 18:19:52 2021
>   write: IOPS=122, BW=122MiB/s (128MB/s)(1024MiB/8375msec); 0 zone resets
>     clat (usec): min=473, max=196047, avg=8144.76, stdev=12719.92
>      lat (usec): min=504, max=196089, avg=8173.88, stdev=12719.50
>     clat percentiles (usec):
>      |  1.00th=[   494],  5.00th=[   515], 10.00th=[   529], 20.00th=[   553],
>      | 30.00th=[   594], 40.00th=[   676], 50.00th=[  3589], 60.00th=[ 11338],
>      | 70.00th=[ 11600], 80.00th=[ 14484], 90.00th=[ 15926], 95.00th=[ 19792],
>      | 99.00th=[ 47973], 99.50th=[ 70779], 99.90th=[170918], 99.95th=[196084],
>      | 99.99th=[196084]
>    bw (  KiB/s): min=86016, max=380928, per=99.98%, avg=125184.00, stdev=69811.97, samples=16
>    iops        : min=   84, max=  372, avg=122.25, stdev=68.18, samples=16
>   lat (usec)   : 500=2.05%, 750=41.31%, 1000=3.71%
>   lat (msec)   : 2=1.95%, 4=2.05%, 10=2.54%, 20=41.41%, 50=4.10%
>   lat (msec)   : 100=0.49%, 250=0.39%
>   cpu          : usr=1.15%, sys=6.93%, ctx=1763, majf=0, minf=13
>   IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
>      submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
>      complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
>      issued rwts: total=0,1024,0,0 short=0,0,0,0 dropped=0,0,0,0
>      latency   : target=0, window=0, percentile=100.00%, depth=1
> 
> Run status group 0 (all jobs):
>   WRITE: bw=122MiB/s (128MB/s), 122MiB/s-122MiB/s (128MB/s-128MB/s), io=1024MiB (1074MB), run=8375-8375msec
> 
> Disk stats (read/write):
>   vda: ios=645/2327, merge=0/75, ticks=2208/443400, in_queue=402444, util=88.38%
> ```

重要指标：

- IOPS：io per second 每秒IO操作次数

- BW：bandwidth 带宽，单位时间内从一端到另一端的数据量

- lantency：延迟

  延迟的单位，nsec即纳秒，usec即微妙（μsec），msec即毫秒

  - lat=slat+clat

  - slat ：slat为submission latency，IO提交延时，从io提交到kernel需要的时间

  - clat ：clat为completion latency，IO完成延时，从kernel到io完成需要的时间

    - clat percentiles 下面的内容为本次测试IO延时的比重

      例如：`30.00th=[ 10]`，表示10msec以下延时的IO操作占所有IO操作的30%。

- Run status行：汇总了测试的主要数据

- Disk stats行：仅linux下测试本地文件磁盘时有该行输出；如果测试的是挂载的网络文件系统（如挂载的NFS的目录），没有该行输出。

  - ios：总的 I/O 操作次数
  - merge  被 I/O 调度合并的次数
  - ticks  让磁盘保持忙碌的次数
  - in_queue  总的在磁盘队列里面的耗时
  - util 磁盘的利用率。

  

# client/server模式

通常fio仅在I/O工作负载的计算机上的进行独立测试，但fio的后端和前端可以单独运行。

例如，fio server的I/O负载测试工作可以由另一台机器上的client控制

在分布式文件系统测试中，可以在所有文件系统客户端节点上启动fio server，然后在其他节点（也可以是启动fio server的节点）上启动fio client向各个节点发起测试任务。

- `--server`  当前主机作为fio server端

  默认监听所有网卡的8765端口，可指定网卡地址和端口，二者用逗号分隔；也可使用UNIX socket文件。

  ```shell
  #要测试的节点
  fio --server
  
  #指定网卡地址和端口
  #fio --server=<addr1>:<addr2>,<port>
  #仅指定某个网卡地址  使用默认端口
  #fio --server=<addr1>   
  #仅指定端口  使用所有网卡地址
  #fio --server=,<port>
  #使用socket文件
  #fio --server=/shardir/server1.sock
  ```

- `--client`   当前主机作为fio client端

  ```shell
  fio --client=<server1> <job file(s)> --client=<server2> <job file(s)>
  ```

  如果作业文件位于fio server上，则也可以使用`--remote-config`告诉server加载本地（fio server上的）文件：
  
  ```shell
  fio --client=<server1> --remote-config=~/job1.ini
  ```
  
  
  
  server较多使用命令行过于冗长，也可以使用指定一个fio server列表文件，例如该文件为fio-servers，在文件中添加server列表，每行一个，如：
  
  ```shell
  192.168.1.1
  node1
  node2
  ```
  
  然后指定上面的列表文件进行测试：
  
  ```shell
  fio --client=fio-servers  <job file(s)>  #fio-servers中所有server将接收相同的作业任务
  ```
  
  提示：如果jobfile文件中使用`include`读取其他文件，可能无法成功，提示bad option，则



# 绘图

fio安装后提供有`fio_generate_plots`（shell脚本）和`fio2gnuplot`（python脚本）用以绘图。

目前（2021）看绘图质量一般。

需要安装gnuplot，绘图脚本调用gnuplot，读取绘图日志文件生成图片。

fio的输出日志主要包含三种：bw，lat和iops，使用三种的参数如下：

```
write_bw_log=rw
write_lat_log=rw
write_iops_log=rw
```

参看前文选项中关于日志记录相关选项说明。



fio2gnuplot可以匹配包含指定字符的文件名并调用gnuplot生成文件

```shell
fio2gnuplot -b -g
fio2gunplot -i -g
fio2gnuplot -p "*bw*" -g
```

- `-b`   匹配`*_bw.log`文件
- `-i`    匹配`*_iops.log`文件
- `-g`   使用gnuplot生成图片
- `-p`   自定义匹配（如`fio2gnuplot -p '*bw*' -g`，



使用fio_generate_plots需要存在bw、lat和iops日志，该脚本接收三个变量，分别是：

- 图片名字
- 图片宽
- 图片高

```shell
fio_generate_plots <title> <width> <height>
```



