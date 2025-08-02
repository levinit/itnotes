# 简介

> IOZONE主要用来测试操作系统文件系统性能的测试工具。使用iozone可以在多线程、多cpu，并指定cpu cache空间大小以及同步或异步I/O读写模式的情况下进行测试文件操作性能。

iozone可测试项包括：Read, write, re-read,re-write, read backwards, read strided, fread, fwrite, random read, pread,mmap, aio_read, aio_write 。

iozone的测试以表格形式输出：顶部横行为每次读/写的块文件大小（单位Kbytes），左侧纵列为测试文件的大小（单位Kbytes），其余为对应的读写速度。

# 常用参数

- `-a`   全自动测试  测试记录块大小从4k到16M，测试文件从64k到512M

  `–a `在测试大文件（大于32MB）时将自动停止使用低于64K的块大小测试。

  自动测试的文件较小，被测主机的内存如果比自动测试中的文件大得多，测试往往受cache/buffer影响而结果严重失真，因此该参数不是很实用。

  - `-A`  全面测试 没有记录块的范围限制

    测试大文件（大于32MB）时依然会采取小记录块进行测试，测试全面但耗时更多。

    

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

  - 11=pwritev/Re-pwritev   

  - 12=preadv/Repreadv



- `-R`  产生Excel到标准输出 
- `-b`  指定输出文件的名字 和`-R`合用以输出xls文件



- `-s <file size>`  指定固定的测试文件大小
- `-r <block size>`  指定固定的测试的文件块大小
- `-n <min size> -g <max size>`  指定测试文件的大小范围
- `-y <min size> -q <max size>`  指定测试文件块的大小范围
- `-f <file name>`  测试文件的名字（该文件必须位于测试硬盘中)
- `-F <file1> [file2...fileN] `  测试多线程指定的文件名
- `-t <N>`  线程数量（配合`-F`或`-+m`使用）



- `-L`
  设置处理器交换信息的单位量为#（bytes）。可以加速测试。
- `-U mountpoint`
  在测试开始之前，iozone将unmount和remount挂载点，以保证测试中缓存不包含任何文件
- `-I`    使用DIRECT I/O。通知文件系统所有操作跳过缓存直接在磁盘上操作
- `-p`    清除缓存
- `-D`  对mmap文件使用msync异步写
- `-+r`  启用 O_RSYNC 和 O_SYNC进行测试。



- `-c`  测试包括文件的关闭时间

  测试网络文件系统例如NFS，可使用`-c`参数，这通知iozone在测试过程中执行close()函数，使用close()将减少NFS客户端缓存的影响。

  分布式文件系统测试需使用`-+m`选项测试，具体参看后文。

- `-C`  显示每个线程的吞吐量

- `-e`   测试包括flush (fsync,fflush) 的时间（把内存数据写入存储）

  

- `-w`  不要解锁测试时写入的临时文件（即不删除测试时写入的文件，可以方便后续测试使用）

- `-W`  在测试过程中，当读或写文件时锁住文件

- `-+k` 调用文件的总大小

- `-+n` 跳过重复读/写入  



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

  

- `-+t`  启动网络性能测试。需要 -+m

- `-+u`  输出CPU使用率信息

- `-O`  输出IOPS值 

# 测试示例

## 单节点

```shell
bs=1M
fs=20g
outpu_filename=iozone-$bs
test_dir=
test_file=ioztmp

iozone -i 0 -i 1 -r $bs -s $fs -p -I -O -+u -+n -w -f $test_file -Rb ~/$outpu_filename.xls | tee $outpu_filename.txt

#多线程测试
iozone -i 0 -i 1 -r $bs -s $fs -p -I -O -+u -+n -w -Rb ~/$outpu_filename.xls | tee $outpu_filename.txt
iozone -i 0 -i 1 -r $bs -s $fs -p -I -O -+u -+n -w -C -t 8 -F $test_dir/f{1,2,3,4,5,6,7,8}.ioz -Rb ~/$outpu_filename.xls | tee $outpu_filename.txt
```



## 跨节点

多节点同时测试文件系统的性能

```shell
nodes=(node{01..48}) #hosts

bs=1m           #block size
fs=64g          #test file size for every node

nodes_num=${#nodes[*]}
tread_every_node=2
treads=$(($nodes_num*$tread_every_node))

nodelist=~/nodelist             #hosts file
test_dir=/share/testdir         #public dir for every node
iozone_app_path=/share/iozone   #$(command -v iozone)

outpu_filename=iozone-bs_$bs-fs_$fs-nodes_$nodes_num-threads_every_node_$tread_every_node

echo -n '' >$nodelist

for node in ${nodes[*]}; do
  i=1
  while ((i <= $tread_every_node)); do
    echo "$node  $test_dir  $iozone_app_path" >>$nodelist
    i=$((i + 1))
  done
done

export RSH=ssh
export rsh=ssh

#test seq write and seq read
$iozone_app_path -i 0 -i 1 \
-r $bs -s $fs \
-t $treads -+m $nodelist \
-p -I \
-O -+u \
-+n -C -w \
-Rb ~/$outpu_filename.xls | tee $outpu_filename.txt
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