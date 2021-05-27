[toc]

# io监控工具

- atop

- iotop

- iostat

# 测试工具

## dd

```shell
if=/dev/zearo  #读取的文件
of=test_file     #写入到该文件
bs=4k                #block size  每个块文件的大小
count=64k      #块文件个数 64k=64000
time dd if=/dev/zero of=$of bs=$bs count=$count conv=fdatasync
```

if文件也可以是已经存在的一个文件。（创建一个测试用的大文件可以使用`fallocate -l <size> <filename>`。）

of文件位于要测试的硬盘的挂载目录中。

`/dev/zero`输入设备，不停输出0，可以忽略其读取速度，用以测试纯写入。

`/dev/null`空设备，抛弃任何输入的字符，可以忽略其写入速度，用以测试纯读取。

`/dev/urandom` 随机数生成设备，可用以测试随机读写。

conv和oflag/iflag参数的选择可按实际应用场景需要选择。

- `conv`

  - `fdatasync` physically write output file data before finishing 

    dd完成前将文件写入硬盘，读取所有数据到缓存后，最后将数据从缓存写入到硬盘 完全写到硬盘后返回完成，和平常使用场景类似。

  - `fsync`   likewise (fdatasync), but also write metadata 同上，只是还要写入元数据

  - `sync`  在每个块左侧用NUL填充空值，遇到错误即使不是所有数据本身都可以包含在映像中，也会保留原始 数据（单纯dd测试用不上）

- `iflag`/oflag

  - `dsync`   use synchronized I/O for data 同步IO写入数据 每次一个数据块完全输出到磁盘后才返回完成，继续写入下一个数据块。（每次读取bs大小的文件，再写入到硬盘中，直到读写完毕）

  - `sync`   likewise, but also for metadata 同上，只是还要写入元数据

  - `direct`  direct I/O for data 

    direct I/O 避免内核中整个缓存层并将I/O直接发送到磁盘.每个数据块完全完成后，再进行下一次IO，绕过缓存，用来测试硬盘的实际性能。

  - `nonblock`  非阻塞IO

    direct I/O和sync I/O：

    direct I/O从用户态直接跨过“**stdio缓冲区的高速缓存**”和“**内核缓冲区的高速缓存**”，直接写到存储上。
  
    sync I/O控制“**内核缓冲区的高速缓存**”直接写到存储上，即强制刷新内核缓冲区到输出文件的存储。
  
    IO流：用户数据 –> stdio缓冲区 –> 内核缓冲区高速缓存 –> 磁盘

## fio

随机I/O测试效果好。

```shell
fio --filename=/path/to/file --bs=4k --size=20G --numjobs=48 --runtime=600  --ioengine=libaio --iodepth=1 --direct=1 --rw=read --time_based --refill_buffers --norandommap --randrepeat=0 --group_reporting --name=fio-read
```

也可以创建参数文件，读取该文件即可，参数文件fio.conf示例：

```ini
[global]
ioengine=libaio
direct=1
thread=1
time_based
numjobs=1
group_reporting
iodepth=128
filename=/dev/vdb
runtime=300
size=50g
[4k-randwrite]
bs=4k
rw=randwrite
stonewall
[8k-randwrite]
bs=8k
rw=randwrite
stonewall
```

重要参数：

- bs  块文件大小
- bsrange  数据块的大小范围  例如`bsrange=512-2048`
- ioengine  测试I/O的方法，常用取值：
  - libaio - Linux 原生的异步 I/O（需要安装有libaio包）
  - sync -  同步read / write 操作
  - vsync - 使用 readv / writev，主要是会将相邻的 I/O 进行合并
  - psync - 对应的 pread / pwrite
  - pvsync / pvsync2 - 对应的 preadv / pwritev，以及 preadv2 / p writev2
- io-depth  请求的io队列深度（即线程数量，对应其他测试工具的threads）
- direct 取值1表示绕过buffer直接写入
- zero_buffers  初始化系统buffer
- rw或readdwrite  读写方式，取值：
  - read只读 write只写 rw读写
  - randread随机读 randwrite随机写 randrw随机读写
  - trim、randtrim、trimwrite  块设备（仅Linux）
- rwmixwrite  混合读写模式下写占的比例（百分比）
- size  测试文件大小
- numjobs  线程数量
- runtime  测试时间
- lockmem  测试使用的内存
- group_reporting  汇总报告结果
- nrfiles  每个进程生成的文件数量



设置 write_bw_log，write_bw_log 和 write_iops_log，然后使用 `fio_generate_plots` 来绘图，另外也可以用 `fio2gnuplot` 来绘制

## smallfile

[Smallfile](https://github.com/distributed-system-analysis/smallfile)用于分布式文件系统的小文件IO测试

## iozone

> IOZONE主要用来测试操作系统文件系统性能的测试工具。使用iozone可以在多线程、多cpu，并指定cpu cache空间大小以及同步或异步I/O读写模式的情况下进行测试文件操作性能。

iozone可测试项包括：Read, write, re-read,re-write, read backwards, read strided, fread, fwrite, random read, pread,mmap, aio_read, aio_write 。

通常情况下，**测试的文件大小要求至少是系统cache/buffer的两倍以上，测试的结果才是真是可信的**，否则结果失真严重。 

对于NFS等网络文件系统测试，最好启用`-c`参数，另外glusterfs等分布式文件系统测试需使用`-+m`选项测试，具体参看后文。

iozone的测试以表格形式输出：顶部横行为每次读/写的块文件大小（单位Kbytes），左侧纵列为测试文件的大小（单位Kbytes），其余为对应的读写速度。



pacman -Ql iozone 画图。。。



常用参数

- `-a`   全自动测试  测试记录块大小从4k到16M，测试文件从64k到512M
  
  `–a `在测试大文件（大于32MB）时将自动停止使用低于64K的块大小测试。
  
  自动测试的文件较小，被测主机的内存如果比自动测试中的文件大得多，测试往往受cache/buffer影响而结果严重失真。

   在进行测试前可清理系统缓存`echo 1 >/proc/sys/vm/drop_caches`。
  
  - `-A`  全面测试 没有记录块的范围限制
  
    测试大文件（大于32MB）时依然会采取小记录块进行测试，测试全面但耗时更多。

    
  
- `-R`  产生Excel到标准输出 

- `-b`  指定输出文件的名字 和`-R`合用以输出xls文件



- `-s <file size>`  指定固定的测试文件大小
- `-r <block size>`  指定固定的测试的文件块大小
- `-n <min size> -g <max size>`  指定测试文件的大小范围
- `-y <min size> -q <max size>`  指定测试文件块的大小范围
- `-f <file name>`  测试文件的名字（改文件必须位于测试硬盘中)
- `-F <file1> [file2...fileN] `  测试多线程指定的文件名
- `-t <N>`  线程数量（配合`-F`或`-+m`使用）



- `-L`
  设置处理器交换信息的单位量为#（bytes）。可以加速测试。
- `-U mountpoint`
  在测试开始之前，iozone将unmount和remount挂载点，以保证测试中缓存不包含任何文件
- `-I`
  对所有文件操作使用DIRECT I/O。通知文件系统所有操作跳过缓存直接在磁盘上操作



- `-c`  测试包括文件的关闭时间

  测试网络文件系统例如NFS，可使用`-c`参数，这通知iozone在测试过程中执行close()函数，使用close()将减少NFS客户端缓存的影响。

  **如果测试文件比内存大，就没有必要使用参数-c**。

- `-e`   测试包括flush (fsync,fflush) 的时间（把内存数据写入存储）

  

- `-w`  不要解锁测试时写入的临时文件（即不删除测试时写入的文件，可以方便后续测试使用）
  
- `-W`  在测试过程中，当读或写文件时锁住文件

- `-+k` 调用文件的总大小

- `-+n` 跳过重复读/写入  

- `-C`  显示每个线程的吞吐量



- `-D`  对mmap文件使用msync异步写

- `-+r`
  启用 O_RSYNC 和 O_SYNC进行测试。

- `-+m <cluster_file>`  集群文件测试

  分布式测试使用`-+m`选项来代替`-F`选项，配合`-t`使用，该参数指定一个包含各个被测主机相关信息的文件，该文件中每行指定一个主机，包括：

  > 节点hostname或ip  文件系统挂载点  iozone路径

  示例：

  > node1  /share  /usr/bin/iozone
  >
  > node1  /share  /usr/bin/iozone
  >
  > node2   /share  /usr/bin/iozone

  注意：

  - 该测试会使用rsh通信可设置`export RSH=ssh;export rsh=ssh`或安装rsh。

  - `-t`值一般和节点数量相同即可，`-t`值可随之增加，但是行数最好不要超过该节点CPU的threads数量。

    //?如果要测试多线程性能，每个节点应该多生成几行测试信息

- `-+t`
  启动网络性能测试。需要 -+m

- `-+u`
  启用CPU使用率模式（输出CPU使用率信息）。

- `-i <N>`  选择测试项N，N的取值及其意义：

  - 0 write/rewrite

  - 1 read/re-read

  - 2 random-read/write

  - 3 Read-backwards

  - 4 Re-write-record

  - 5 stride-read

  - 6 fwrite/re-fwrite

  - 7 fread/Re-fread

  - 8 random mix

  - 9 pwrite/Re-pwrite

  - 10=pread/Re-pread

  - 11=pwritev/Re-pwritev   12=preadv/Re-

     

测试示例：

```shell
iozone -i 0 -i 1 -f /nfs/testfile -r 4k -s 1g -Rb ~/nfs_vol_test.xls

#一个对于glusterfs的多线程测试
iozone -w -c -e -i 0 -+n -C -r 64k -s 1g -t 8 -F /mnt/glusterfs/f{1,2,3,4,5,6,7,8}.ioz

#集群多节点测试
nodes=(node{14..18} login{12..28}) #hosts
nodelist=~/nodelist                #hosts file
mountpoint=/chome
bs=1m
fs=1g
nodes_num=${#nodes[*]}
tread_every_node=2
treads=$(($nodes_num*$tread_every_node))
echo -n '' >$nodelist

for node in ${nodes[*]}; do
  echo $node
  i=1
  while ((i <= $tread_every_node)); do
    echo "$node $mountpoint  /root/iozone" >>$nodelist
    i=$((i + 1))
  done
done

export RSH=ssh
export rsh=ssh
/root/iozone -i 0 -i 1 -r $bs -s $fs -t $treads -+m $nodelist -C -w -Rb ~/iozone-bs_$bs-fs_$fs-nodes_$nodes_num-threads_every_node_$tread_every_node.xls | tee iozone-bs_$bs-fs_$fs-nodes_$nodes-threads_$threads.log
```



---

各种测试的含义

- Write: 测试向一个新文件写入的性能。

  当一个新文件被写入时，除了需要存储文件本身的数据内容，还需要定位数据存储在存储介质的具体位置的额外信息——即“元数据”，包括目录信息，所分配的空间和其他与该文件有关但又并非该文件所含数据的其他数据。

- Re-write: 测试向一个已存在的文件写入的性能。

  当一个已存在的文件被写入时，因为元数据已经存在，Re-write的性能通常比Write的性能高。

- Read: 测试读一个已存在的文件的性能。

- Re-Read: 测试读一个最近读过的文件的性能。

  因为操作系统通常会缓存最近读过的文件数据，Re-Read性能会高一些。

- Random Read: 测试读一个文件中的随机偏移量的性能。

  影响因素：操作系统缓存的大小，磁盘数量，寻道延迟等。

- Random Write: 测试写一个文件中的随机偏移量的性能。

  影响因素：操作系统缓存的大小，磁盘数量，寻道延迟等。

- Random Mix: 测试读写一个文件中的随机偏移量的性能。

  影响因素：操作系统缓存的大小，磁盘数量，寻道延迟等。

  该测试只有在吞吐量测试模式下才能进行。每个线程/进程运行读或写测试。这种分布式读/写测试是基于round robin 模式的，最好使用多于一个线程/进程执行此测试。

- Backwards Read: 测试使用倒序读一个文件的性能。

  极少应用程序会使用倒序读文件的方式。

- Record Rewrite: 测试写与覆盖写一个文件中的特定块的性能。

  如果某个特定块足够小（比CPU数据缓存小），测出来的性能将会非常高。

- Strided Read: 测试跳跃读一个文件的性能。

  一一定间隔来读取文件，例如：在0偏移量处读4Kbytes，然后间隔200Kbytes,读4Kbytes，再间隔200Kbytes，如此反复。文件中使用了数据结构并且访问这个数据结构的特定区域的应用程序常常这样做。

- Fwrite: 测试调用库函数fwrite()来写文件的性能。

  一个执行缓存与阻塞写操作的库例程，缓存在用户空间之内。如果一个应用程序想要写很小的传输块，fwrite()函数中的缓存与阻塞I/O功能能通过减少实际操作系统调用并在操作系统调用时增加传输块的大小来增强应用程序的性能。

- Fread:测试调用库函数fread()来读文件的性能。

  一个执行缓存与阻塞读操作的库例程，缓存在用户空间之内。如果一个应用程序想要读很小的传输块，fwrite()函数中的缓存与阻塞I/O功能能通过减少实际操作系统调用并在操作系统调用时增加传输块的大小来增强应用程序的性能。

- Freread: 与上面的fread 类似，除了在这个测试中被读文件是最近才刚被读过。这将导致更高的性能，因为操作系统缓存了文件数据。

# 其他测试工具

- hparm
- gnome-disks的测试工具