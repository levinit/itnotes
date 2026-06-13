## memtester内存正确性验证工具

> Utility to test for faulty memory subsystem.

下载[memtester](https://github.com/jnavila/memtester)使用make编译即可。

测试方法：

```shell
#memtester  [-p physaddrbase] <memory> [runs]
memtester 100G 1  #申请100G内存，测试1次
```

- `-p`  指定申请内存的开始地址
- `<memory>`  指定要申请的内存大小
- `<runs>`  指定要重复测试的次数（如不指定则为无限次，需要自行终止）

测试结果中正常的项会输出OK，输出示例（部分内容）：

>  Stuck Address    : ok 
>  Random Value     : ok
>  Compare XOR     : ok
>  Compare SUB     : ok
>  Compare MUL     : ok
>  Compare DIV     : ok
>  Compare OR      : ok
>  Compare AND     : ok
>  Sequential Increment: ok
>  Solid Bits      : ok
>  Block Sequential   : ok
>  Checkerboard     : ok
>  Bit Spread      : ok
>  Bit Flip       : ok
>  Walking Ones     : ok
>  Walking Zeroes    : ok
>  8-bit Writes     : ok
>  16-bit Writes    : ok  

如不需要测试某些项，可以通过修改memtester.c文件中`struct test tests[]`结构体内容，注释掉无需测试的项后重现make编译，例如：



## stream内存带宽测试工具

[Stream](https://github.com/jeffhammond/STREAM)用于测量持续内存带宽， 具有良好的空间局部性，是对TLB友好，Cache友好的一款测试程序，其分为Copy、Scale、Add和Triad四个更基本的测试功能。

获取[stream.c](https://www.cs.virginia.edu/stream/FTP/Code/stream.c)源码，编译后使用：

```shell
#wget https://www.cs.virginia.edu/stream/FTP/Code/stream.c
#gcc -O stream.c -o stream   #一般编译 单线程，使用源码默认的STREAM_ARRAY_SIZE值

#--自定义参数编译
#这里lscpu获取的值单位是k，如果不是k，根据具体情况进行换算
L3_cache=$(lscpu|grep 'L3 cache'|awk '{print $NF}'|grep -oE '[0-9]+')  #N kbytes
cpu_sockets=$(lscpu|grep 'Socket(s)'|awk '{print $NF}')
multiple=8   #一般为cpu3级缓存的4倍即可
STREAM_ARRAY_SIZE=$(($L3_cache*1024*$multiple*$cpu_sockets/8))
NTIMES=16
mcmodel_param=''
#STREAM_ARRAY_SIZE大于2gb时
[ $STREAM_ARRAY_SIZE -le $((1024*1024*1024*2)) ] && $mcmodel_param='-mcmodel=medium'
gcc -O3 -fopenmp -DSTREAM_ARRAY_SIZE=$STREAM_ARRAY_SIZE -DNTIMES=$NTIMES $mcmodel_param stream.c -o stream

#运行stream测试
#./stream  #简单测试

#先指定运行线程和系统线程数一致（linux中nproc可以得到这个数值）
export OMP_NUM_THREADS=$(nproc)
./stream
```

编译参数：

- -O3

  指定最高编译优化级别为3（一般不指定时为O0）

  

- -fopenmp：多线程支持，fopenmp为gcc使用

  icc为-openmp，pgcc为-mp，Open64的opencc为-openmp

  多处理器环境最好启用以获得到内存带宽实际最大值。

  开启后，运行stream时如不指定线程数量，则程序默认运行线程为CPU线程数。

  

- -DSTREAM_ARRAY_SIZE=20000000

  指定测试数组a[]、b[]、c[]的大小（Array size），该值对测试结果影响较大。必须设置测试数组大小远大于CPU 最高级缓存（一般为L3 Cache）的大小，否则测试时会因为CPU缓存的作用而获得更高的虚假值，其并内存吞吐性能的值。

  （根据stream.c源码）一般建议是STREAM_ARRAY_SIZE必须至少是系统中最高级别缓存的4倍（可以更高，可调高倍数后再次测试），且测试数组类型为双精度浮点，单个数组的占用内存为STREAM_ARRAY_SIZE*8字节，因此STREAM_ARRAY_SIZE推荐计算公式：
  $$
  SIZE=CPU最高级别缓存(KB)*1024*4*CPU颗数/8
  $$
  *注意：根据实际的cpu缓存值的单位进行换算得到以Byte为单位的值。*

  

- -DNTIMES=10：执行的次数（默认10）

  stream的输出结果是所有次测试结果中最优的一次

  

- stream.c：待编译的源码文件



- stream：输出的可执行文件名

其他可用参数

- -mtune=native -march=native：针对CPU指令的优化，此处由于编译机即运行机器。故采用native的优化方法。更多编译器对CPU的[优化参考](http://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/i386-and-x86_002d64-Options.html)
- -mcmodel=medium ；当STREAM_ARRAY_SIZE过大（一般<=2GB时）需要设置此参数
- -DOFFSET=4096 ；数组的偏移，一般可以不定义
- -DSTREAM_TYPE=double ：默认值为double即双精度测试，一般无需更改，单精度改为float

