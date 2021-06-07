# 简介

fio可运行在多种系统之上，用以测试本地磁盘、网络存储等的性能。

fio功能强大，支持十几种IO引擎，支持多客户端并发测试（server、client模式），支持文件级、对象级存储测试，自带绘图工具（调用gnuplot绘图），可对测试需要的cpu、内存、进程/线程等进行灵活配置。



参看[fio doc](https://fio.readthedocs.io/en/latest/)



# 测试

fio中将测试行为成为job（作业）

## 常用选项

fio支持直接使用选项参数，也可以编写一个描述各个选项参数的作业文件进行测试。

### 通用选项

通用选项可用于作业文件中，也可以用于命令行中，在命令行中使用时需要在选项名字前加上`-`。

如`bs`，在作业文件中：

```ini
bs=4k
```

在命令行中：

```shell
fio -bs=4k
```



- I/O类型

  文件的输入输出模式。

  - 读写方式`rw`或`readdwrite`  读写方式，取值：
    - read顺序读    write顺序写    rw顺序读写
    - randread随机读    randwrite随机写    randrw随机读写
    - trim、randtrim、trimwrite  块设备（仅Linux）

  - `rwmixwrite`  值为数字，指混合读写模式下写占的比例（百分比）
  - `direct`    值为1时使用非缓冲（non-bufferd）I/O（通常是O_DIRECT），默认0
  - `bufferd`   值为1时使用缓冲（bufferd）I/O，默认为1。该选项值始终与`direct`的取值相反。

  

- 块大小 block size

  I/O分发的数据块大小，一个固定的值或取值区间，参数：

  - `bs`或`blocksize`    值为块文件大小  如`bs=4k`，`bs=4k,16k`
  - `bsrange`或`blocksize_range`   数据块的大小范围  如`bsrange=512-2048`

  

- I/O大小

  读写的数据量

  - `size`    此作业的每个线程的io操作数据量

    示例：`size=10G`  `size=20%`

    百分数表示读写大小为该分区容量的的百分比空间。

    测试的总io大小，除非受到其他选项的限制（如`runtime`的值），fio将指定大小的数据量全部读/写完成，才会停止测试。

  

- I/O引擎

  I/O操作模式，选项`ioengine`常用取值：

  - psync - 默认，对应的 pread / pwrite

  - libaio - Linux 原生的异步 I/O（需要安装有libaio包）

  - sync -  同步read / write 操作

  - vsync - 使用 readv / writev，主要是会将相邻的 I/O 进行合并

  - pvsync / pvsync2 - 对应的 preadv / pwritev，以及 preadv2 / p writev2

    

- I/O深度

  一次提交要提交的I/O请求数量，只对异步I/O引擎有意义。

  同步I/O总是会等待提交的I/O请求返回了再提交下一个I/O请求，iodepth总是1。

  - `iodepth`  个进程/线程可以同时下发的io作业数（io深度），默认为`1`

    随着iodepth的增大在一定范围内，带宽、io延时会增加，超过一定范围后带宽增加缓慢，延时继续会增加。

    

- 目标文件/设备

  - `directory`    测试生成文件存放目录

    可以通过用`:`字符分隔这些名称来指定多个目录，这些目录将平均分配给作业线程创建的文件。

  - `filename`   测试对象，一般是设备或者文件。
    如`/dev/sdb`，`/share/testf`

    如不指定，fio默认根据作业名、线程号和文件号组成文件名（请参见filename_format）（因此可以只指定`directory`值，不设置`filename`，测试文件生成在`directory`下）。

    

  - `nfiles`    用于此作业的文件数。默认1。

    每一个作业要产生多少个大小为filesize的文件。

    作业的每个线程将分别创建文件，除非由文件大小指定显式大小，每隔线程的filesize值将为size除以nfiles（$filesize=size/nfiles$）。

  - `openfiles`    同一时间可以打开的文件数量，默认与nfiles值相同。

  

- 线程/进程数量和作业异步

  - `thread`    无值。Fio默认使用fork创建作业，使用该选项后，将使用POSIX线程的函数pthread_create创建线程。

    使用 threads **在一定程度上可以节省系统开销**

  - `exec_prerun`   运行作业之前，通过过system执行指定的命令。

  - `exec_postrun`   运行作业之后，通过过system执行指定的命令

  - `cpus_allowed`    允许作业使用的cpu，用于cpu绑定。

    cpu从0开始索引。

    对于SSD测试，最好进行cpu绑定，因为若IOPS太大，fio线程运行在相对繁忙的cpu上，测试可能达不到最佳性能。

    此外还可以使用`taskset`绑定cpu，如`taskset -c 11 fio...`。

    

- 测试时间

  - `runtime`   测试作业运行的时间，到达该时间测试将终止，单位秒。 如`runtime=100`

  - `time_based`    以`runtime`的值为最终运行时间。无值。

    如果设置了该选项，当同时设置有size和runtime，如果读写已经达到size的大小，但未达到rumtime的限定时长，测试将继续直到达到runtime的限制。

  - `ramp_time`   测试的热身时间，热身时间不计入测试统计，单位秒

  - `startdelay`   延迟时间，单位秒。

    与ramp_time的区别：startdelay是job作业完全不运行空等待，ramp_time作业运行而此段时间内不会做记录。

    

- 作业描述

  - `description`    描述信息

  - `loops`   测试轮数，默认1

  - `numjobs`    测试的线程/进程数量，默认1

    如果指定了`thread`参数，则使用单进程多线程模式，否则使用多进程模式。

    由于每个线程单独报告，如果要汇总所有线程的数据报告，需将group_reporting与new_group结合使用。



- 报告相关

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

    

- 其他常用选项

  - `thinktime`   等待时间，在I/O完成后，停止指定的作业，然后发布下一个作业。

    

### 作业文件选项

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

  

### 命令行选项

只能用于命令行中，不可用于作业文件中。

- `--name`    作业的名字，即作业配置文件中`[]`包含的内容（golbal除外）
- `--output`   输出日志保存的文件的路径（默认只输出不保存到文件）

- `--output-format`    报告文件格式，取值：

  - `normal`  默认值，普通文本文件
  - `terse`    基于csv格式
  - `json`    
  - `json+`    

  可设置多种格式如`output-format=json,terse`。

  

## 作业文件中的变量

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



## 使用示例

### 作业文件

示例文件fio.ini

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

运行：

```shell
dir=. --output-format=terse fio fio.ini
```



### 命令行

```shell
fio -directory=. -bs=4k -size=2G -numjobs=1 -runtime=30  -ioengine=libaio -iodepth=96 -direct=1 -rw=randrw -rwmixwrite=50% -time_based -refill_buffers -norandommap -randrepeat=0 -group_reporting -name=fio-read --output-format=terse 
```



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



