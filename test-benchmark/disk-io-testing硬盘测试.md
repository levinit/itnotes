# 磁盘性能核心指标（IOPS 与吞吐量）

- **IOPS (Input/Output Operations Per Second)**：每秒处理的 I/O 次数。
  - **核心场景**：衡量**随机小文件读写**（如 OLTP 数据库、高并发 Web 请求、虚拟化/容器混合负载）的关键指标。
- **数据吞吐量 (Throughput / Bandwidth)**：单位时间内传输的数据流量（通常以 MB/s 或 GB/s 计）。
  - **核心场景**：衡量**顺序大文件读写**（如视频流、离线备份、大日志回放、大数据批处理）的关键指标。
- **核心换算关系**：
  $$
  \text{吞吐量 (MB/s)} = \frac{\text{IOPS} \times \text{块大小 (KB)}}{1024}
  $$
  - *示例*：4KB 随机写达到 10,000 IOPS 时，吞吐量约为 $10000 \times 4 / 1024 \approx 39\text{ MB/s}$；而在 1MB 顺序读写时，仅需 500 IOPS 即可占满 500 MB/s 带宽。
- **介质特性差异**：
  - **机械硬盘 (HDD)**：受限于机械臂寻道时间（Seek Time 约 3~15ms）与盘片旋转延时（7200 RPM 延时约 4.16ms），单盘随机 IOPS 物理极限通常仅在 75 ~ 200 之间。
  - **固态硬盘 (SSD / NVMe)**：基于电子闪存与多通道并发控制器，消除寻道开销，随机 IOPS 可达数万至数百万级；测试重点由单纯 IOPS 转向**高队列深度（Queue Depth）下的并发性能**与**长尾延迟（P99/P999 Latency）**。

# io监控工具

- atop
- iotop
- iostat

# 测试工具

## dd

dd只能进行简单的单线程串行读写操作测试。

```shell
if=/dev/zero   #读取的文件
of=test_file   #写入到该文件
bs=4k          #block size 每个块文件的大小
count=64k      #块文件个数 64k=65536 (4k*64k = 256MB)
time dd if=$if of=$of bs=$bs count=$count conv=fdatasync
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

    direct I/O 避免内核中整个缓存层并将I/O直接发送到磁盘。每个数据块完全完成后，再进行下一次IO，绕过缓存，用来测试硬盘的实际性能。

  - `nonblock`  非阻塞IO

    direct I/O和sync I/O：

    direct I/O从用户态直接跨过“**stdio缓冲区的高速缓存**”和“**内核缓冲区的高速缓存**”，直接写到存储上。
  
    sync I/O控制“**内核缓冲区的高速缓存**”直接写到存储上，即强制刷新内核缓冲区到输出文件的存储。
  
    IO流：用户数据 –> stdio缓冲区 –> 内核缓冲区高速缓存 –> 磁盘

## fio

参看[fio](fio.md)



## smallfile

[Smallfile](https://github.com/distributed-system-analysis/smallfile)用于分布式文件系统的小文件IO测试



## ior

测试元数据性能。



## iozone

参看[iozone](iozone.md)

# 其他测试工具

- hdparm
- gnome-disks的测试工具