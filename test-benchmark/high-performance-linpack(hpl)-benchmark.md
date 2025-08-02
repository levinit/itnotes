[TOC]

HPC LINPACK benchmark

# 介绍

LINPACK （Linear system package）即线性系统软件包，该工具

> 通过在高性能计算机上用**高斯消元法**求解 N 元一次稠密线性代数方程组的测试，评价高性能计算机的**浮点**性能。

HPL（High Performance Linpack）是针对现代**并行计算集群**的测试工具。

>  用户不修改测试程序,通过调节问题规模大小 N（矩阵大小）、进程数等测试参数,使用各种优化方法来执行该测试程序,以获取最佳的性能。

参看：

- [Intel® Distribution for LINPACK* Benchmark](https://software.intel.com/en-us/mkl-linux-developer-guide-intel-distribution-for-linpack-benchmark)

## 浮点计算能力

浮点计算峰值衡量计算机性能的一个重要指标，它是指计算机每秒钟能完成的浮点计算操作数。

理论浮点峰值（Rpeak）：理论上能达到的每秒钟能完成的最大浮点计算次数。
$$
理论浮点峰值=单处理器核心主频*处理器核心数量*每时钟周期执行浮点运算的次数
$$


*如2颗10核心主频2Ghz的CPU，时钟周期为16，理论值为：`2*10*2*16=640` Gflops。*



每时钟周期执行浮点运算的次数(float operations per CPU cycle , fpc)与cpu指令集、单/双精度计算有关。
$$
CPU单周期双精度浮点计算能力=FMA数量*2(同时加法和乘法)*512/64
$$


CPU的FMA Units值N表示单个CPU周期可以同时执行N条512bit加法和2条512bit乘法。

单精度指32bit的指令长度的运算，双精度指64bit指令长度的运算。



例如，某CPU支持AVX-512指令集，FMA Units为2，CPU单周期双精度（64bit）浮点计算能力为：

> 2 x 2 x 512 / 64 =32



时钟周期参看[wikipedia-FLOPS#FLOPS per cycle per core for various processors](https://en.wikipedia.org/wiki/FLOPS#FLOPS_per_cycle_per_core_for_various_processors)

附处理器信息查询：

- [intel processor](https://ark.intel.com/content/www/us/en/ark.html#@Processors)
- [amd processor](https://www.amd.com/en/products/specifications/processors)



# 准备

## 硬件条件

非必须，但为了获取更好的测试效果应当重视这些内容：

-  集群中所有节点的 CPU、内存容量、频率必须一致（最好）。
-  内存配置要合理，尽量插满所有内存通道，cpu可以发挥更好的性能。比如8通道CPU应当配置 8 根内存或者 16 根内存，容量应当至少128GB+。
- 集群整体测试场景中，尽量采用更好的网络，例如Infiniband或Omni-Path等高速网络。



## BIOS 配置

通常情况测试设备在通常情况下的性能，根据具体情况变通，主要调整cpu频率及功耗相关的项目，如：

- 电源策略（Power Policy）或CPU frequency：普通模式（非省电模式等）

  另，可在操作系统中查看和临时设置性能模式以用于测试：

  ```shell
  cpupower frequency-info
  cpupower frequency-set -g performance
  ```

- 空闲低功耗模式（CPU C-State）：关闭

- EIST（Enhanced Intel SpeedStep Technology）：启用

- 睿频（Intel Turbo Boost或AMD Turbo Core）：启用

- 超线程（Hyper-Threading）：关闭

## 集群配置

如果在集群中测试，需要：

- 各个节点网络互通
- 各个节点ssh密钥认证
- 集群共享目录（用以安装hpl，或者在所有节点上安装到相同路径亦可）



# HPL安装

## 依赖环境

[HPL软件包](https://www.netlib.org/benchmark/hpl/)需要在配备了MPI环境选的系统中才能运行，还需要底层有线性代数子程序包BLAS的支持（或者有另一种向量信号图像处理库VSIPL）。

编译HPL需要一些常见的基础的工具支持，如gcc、gcc-c++、gcc-gfortran、线性代数子程序包BLAS（参看后文中关于blas和blas各种实现的介绍）或者向量信号图像处理库VSIPL。



常用的可选用的编译工具和运行库环境组合：

- intel工具集[Intel® oneAPI Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/commercial-base-hpc.html)（Intel® oneAPI Base & HPC Toolkit）

  包含了数学库(mkl)、各种编译器(如icc、gcc)和intel mpi，用于Intel的cpu。

  提示：安装完intel工具库后，需要激活环境变量，全部激活可以：

  ```shell
  #假如安装目录在/opt/intel
  source /opt/intel/setvars.sh
  ```
  
  
  
  此外，安装Intel工具集后，在其安装目录下的`mkl/benchmarks`下有编译好的`linpack`及`mplinpack`测试工具，可直接使用；或者下载[intel mkl bechmarks suit](https://software.intel.com/en-us/articles/intel-mkl-benchmarks-suite)。



- GCC/Clang + blas或lapack等数学库 + 开源mpi

  - GCC（GNU Compiler Collection）：包含c、c++、fortran等编译器

  - 数学库：openblas、ScaLapack等（开源实现中，openblas效率更好，集群环境等多节点测试可选择使用ScaLapack）

  - mpi：mpich或openmpi等

    提示：rhel/centos中包管理器安装mpich/openmpi后，其目录在可能在`/usr/lib64`下，且可能需要用户自行添加`PATH`和`LD_LIBRARAY_PATH`。

    

- ACML + GCC/Clang + 开源mpi

  ACML由AMD推出，用于AMD的cpu。



以上也可以混合实现，如使用openmpi+[mkl](https://software.intel.com/en-us/mkl/choose-download)+gcc等开源编译器。



## 编译

如果使用 [intel mkl bechmarks suit](https://software.intel.com/en-us/articles/intel-mkl-benchmarks-suite) ，解压即可，略过安装步骤。



下载[hpl](http://www.netlib.org/benchmark/hpl/)，解压后进入hpl目录。

如果使用intel工具链（intel oneapi），确保已经激活环境变量（mpi、mkl等）

如果安装有gcc、mpich、blas等开源库，且在环境变量中已经生效，一般可直接按照普通的编译三步骤编译即可：

```shell
./configure
make
```

可根据具体情况编辑Makefile后编译：

1. 修改`Make.<arch>`文件

   可在`setup`目录下选择合适的模板文件，可执行`sh ./config.guess`获取当前系统架构信息。

   

   执行`setup`目录的`make_generic`脚本将以`setup/Make.UNKOWN.in`文件为模板，根据当前系统环境变量情况生成一份`Make.UNKOWN`文件：

   ```shell
   bash setup/make_generic
   #复制生成的setup/Make.UNKNOWN到hpl源码根目录下并根据需要改名为Make.<arch>，<arch>部分以架构命名，如Make.aarch64
   cp setup/Make.UNKOWN ./Make.aarch64
   ```

   提示：`Make.UNKOWN`修改后的`<arch>`名字其实也是随意的，只是方便区分而已。

   

   `Make.<arch>`文件中重要配置行的说明：

   - `ARCH`： 必须与文件名 `Make.<arch>`中的`<arch>`一致

   - `TOPdir`：指明 hpl 程序所在的目录

   - `MPdir`：MPI 所在的目录

   - `MPlib`：MPI 库文件

   - `LAdir`:  BLAS 库或 VSIPL 库所在的目录

   - `LAinc`、`LAlib`：BLAS 库或 VSIPL 库头文件、库文件

   - `HPL_OPTS`：包含采用什么库、是否打印详细的时间、L广播参数等，若

     - 采用 FLBAS 库则置为空
     - 采用 CBLAS 库为`-DHPL_CALL_CBLAS`
     - 采用 VSIPL  为`-DHPL_CALL_VSIPL`
     
   - `-DHPL_DETAILED_TIMING`为打印每一步所需的时间，默认不打印

   - `-DHPL_COPY_L`为在  L 广播之前拷贝 L，默认不拷贝

   - `CC`： C 语言编译器

   - `CCFLAGS`：C 编译选项

   - `LINKER`：Fortran 77 编译器

   - `LINKFLAGS`：Fortran 77 编译选项(Fortran 77 语言只有在采用 Fortran 库时才需要)

     

2. 编译安装

   ```shell
   #示例：文件名为Make.Linux_Intel64 文件中arch为Linux_Intel64
   #cp setup/Make.Linux_Intel64 ./  #修改内容
   make arch=Linux_Intel64
   ```

   编译生成的文件在hpl源码中的bin下以arch值为名的目录下（如Linux_Intel64编译生成在目录`bin/Linux_Intel64/`下），目录中包含xhpl可执行文件及HPL.dat。

   提示：如果之前使用其他`Make.<arch>`文件编译过，make之前应当执行`make clean`。



示例1：使用intel工具集编译

复制`setup/Make.Linux_Intel64`到hpl源码根目录下，编辑源码根目录下的`Make.Linux_Intel64`：

```shell
##名字和文件名中的Make.后面的字符要保持一致
ARCH    = Linux_Intel64
#TOPdir修改为当前目录（pwd，当前所在的hpl源码目录）
TOPdir  = /root/hpl-2.3

#该文件作者已经配置好，只要intel套件的各个环境变量无误，该文件后续基本无需修改即可通过编译
```

保存后执行：

```shell
make arch=Linux_Intel64 #make
```

提示：清除编译生成的文件`make clean arch=Linux_Intel64`



示例2：使用GNU编译器+openblas+mpich编译

1. 安装编译器、mpi、blas等

   ```shell
   #blas、mpi和编译器等 rhel/centos需要epel源安装openblas
   dnf install -y openblas-devel mpich-devel gcc gcc-c++
   
   #或者将mpich变量写入.bashrc或/etc/profile.d/下面的.sh文件中
   export PATH=/usr/lib64/mpich/bin:$PATH
   export LD_LIBRARY_PATH=/usr/lib64/mpich/lib:$LD_LIBRARY_PATH
   ```

2. 生成`Make.UNKOWN`

   源码setup目录中的模板可能满足不了编译需要或者需要改动参数过多，不如根据当前系统安装的编译器和依赖库等重新生成一份`Make.UNKOWN`文件，以满足用户自行修改编译的需要：

   ```shell
   bash setup/make_generic
   #复制生成的setup/Make.UNKNOWN到hpl源码根目录下并根据需要改名为Make.<arch>，<arch>部分以架构命名，如Make.aarch64
   cp setup/Make.UNKOWN ./Make.aarch64
   ```

   提示：`Make.UNKOWN`修改后的`<arch名>`字其实也是随意的，只是方便区分而已。

3. 编辑`Make.aarch64`文件：

   ```shell
   ARCH         = aarch64  
   TOPdir       = $(HOME)/hpl-2.3
   #以centos为例，yum或dnf安装mpich后，其位于/usr/lib64/mpich
   #如果自行编译，则需要根据具体情况修改
   MPdir        = /usr/lib64/mpich
   #如果非包管理安装mpich，该include目录应该位于mpich的安装目录下
   MPinc        = -I /usr/include
   MPlib        = $(MPdir)/lib/libmpich.a
   #如果非包管理安装blas/lapack或其他数学库，则需要自行指定
   LAdir        = /usr/lib64
   LAinc        = /usr/include
   LAlib        =  $(LAdir)  #同上
   ```

4. 编译

   保存后执行`make arch=Linux_Intel64`即可。
   









# HPL NVIDIA GPU 版

除了前文所述要求的mpi、数学库等工具外，还需要安装配置好以下工具：

- NVIDIA driver

  run文件版本nvidia驱动的安装

  ```shell
  #备份原启动时的初始化系统文件镜像
  cp /boot/initramfs-$(uname -r).img boot/initramfs-$(uname -r).img.bak
  #dracut -v /boot/initramfs-$(uname -r).img $(uname -r)
  #移除nouveau驱动模块
  rmod nouveau
  #如果当前已经开启图形界面，需要切换至文本界面
  systemctl isolate multi-user.target
      
  chmod +x NVIDIA*.run
  kernelVer=`uname -r` #内核版本
  #使用参数--no-opengl-files以禁止安装驱动自带的opengl 避免与已安装的opengl冲突
  #未安装kernel-devel需要指定--kernel-source-path
  #--ui=none --no-questions --accept-license自动接受协议
  ./NVIDIA*.run --kernel-source-path=/usr/src/kernels/$kernelVer -k $kernelVer --no-opengl-files --ui=none --no-questions --accept-license
  
  #卸载nvidia驱动 nvidia-uninstall
  ```

- CUDA（含有gpu driver）

  run文件版本cuda安装

  ```shell
  chmod +x ./cuda*.run
  #安装时--slient静默安装
  #但是该模式下默认应用所有选项 指定--toolkit后将值安装cuda不会安装其附带的驱动
  ./cuda*.run --silent --toolkit --verbose #--verbose将打印所有日志信息
  
  #环境变量
  echo '
  export PATH=/usr/local/cuda/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
  ' > /etc/profile.d/cuda.sh
  source /etc/profile.d/cuda.sh
  ```

- [cuda-accelerated-linpack](https://developer.nvidia.com/rdp/assets/cuda-accelerated-linpack-linux64)  nvidia 显卡性能测试专用hpl版本（代替上文所述的hpl）

  解压后进入目录，编辑Make.CUDA文件，修改相关参数（参看上文）。

  以使用intel编译工具为例，需要修改以下几行：

  ```shell
  #TOPdir修改为当前目录（pwd）
  TOPdir       = /root/hpl-2.0_FERMI_v15
  #MPI
  MPdir        = $(I_MPI_ROOT)
  MPinc        = -I$(MPdir)/intel64/include
  MPlib        = $(MPdir)/intel64/lib/release/libmpi.so
  #MKL
  LAdir        = $(MKLROOT)
  LAinc        = -I$(LAdir)/include
  #C compiler
  CC      = icc
  ```

  编译完成后在bin/CUDA目录下，根据具体情况修改其中的run_linpack脚本，使用该脚本进行测试，注意：

  - 如果要移走该目另下的文件到其他目录使用，需要连带复制hpl文件夹下的src目录，run_linpack脚本执行时会用到其中的库文件。
  - 测试GPU时，根据情况为每个GPU分配一定数量的CPU，修改run_linpack中的CPU_CORES_PER_GPU的值，不一定要将所有cpu都分给GPU，CPU数量过多可能反而拖累GPU测试的峰值。
  - 进行GPU测试，HPL.dat装的P和Q的值应当以GPU数量为标准。



# HPL测试

测试前将cpu模式临时调整为performance用于测试：

```shell
#redhat 可调整为hpc-compute模式
tuned-adm active   #查看当前模式
tuned-adm profile hpc-compute   #设置为hpc-compute模式

#cpupower工具设置cpu频率模式
cpupower frequency-set -g performance
cpupower frequency-info
```



##  自行编译的hpl

可参看源码目录中的`TUNNING`文件以及`testing`目录中的内容。

在集群测试中，一般将将测试程序xhpl及HPL.dat等文件放置到集群共享目录中。

在hpl源码目录中的testing目录的子目录中有HPL.dat样本，参看[HPL.dat配置](HPL.dat配置)修改，在HPL.dat文件所在目录下执行xhpl程序即可。

```shell
./xhpl
#mpirun -N ./xhpl  #N为进程数(N>=PxQ)

export I_MPI_PIN_DOMAIN=numa   #使用intel mpi 可使用

mpirun ./xhpl      #同上，程序会自动识别cpu数量
mpirun -f <nodes_file> ./xhpl  #多节点并行
```

nodes_file文件中每行为一个节点的地址（IP或hostname），如：

```shell
192.168.1.1
192.168.1.2
```

初始的HPL.dat文件无法满足需求，需要对其进行修改，参看hpl data文件相关说明修改。



## intel-mkl-benchmark工具

intel安装目录下的`mkl/benchmarks`的`linpack`及`mplinpack`测试工具，或者单独的[intel mkl bechmarks suit](https://software.intel.com/en-us/articles/intel-mkl-benchmarks-suite)解压后找到mkl/benchmarks目录中的linpack和mp_linpack：

- LINPACK  主要用于基础简单的测试，可自定义的参数较少，主要用作单颗CPU的计算机测试

- MP LINPACK  分布式内存版本，用于多颗CPU计算机（SMP machine）以及多节点集群测试，需要使用HPL.dat文件。

  > **对称多处理**（英语：Symmetric multiprocessing，缩写为 SMP），也译为**均衡多处理**、**对称性多重处理**、**对称多处理机**[[1\]](https://zh.wikipedia.org/wiki/对称多处理#cite_note-1)，是一种[多处理器](https://zh.wikipedia.org/wiki/多處理器)的电脑硬件架构，在对称多处理架构下，每个处理器的地位都是平等的，对资源的使用权限相同。

### linpack

linpack目录的文件

- help.lpk        输入参数相关的帮助文件

- xhelp.lpk      程序使用帮助文件

- runme_xeon64   测试双精度64bit浮点运算的脚本

  需要根据具体情况修改该脚本内容，该脚本调用xlinpack_xeon64。

- lininput_xeon64

  输入文件，`./runme_xeon64`将读取该文件，应需要可对其参数进行修改，示例：

  ```shell
  64                     # number of tests 测试方程组数量
  35000 40000 45000      # problem sizes 问题规模 （可多个规模）
  30000 35000 40000 45000 # leading dimensions 矩阵维度
  1 2 3 1 # times to run a test 每个问题规模下的运行次数
  1 1 4 4 # alignment values (in KByte) 内存地址对齐值
  ```

- lin_xeon64.txt

  `./runme_xeon64`运行完成后生成的结果文件。

- xlinpack_xeon64  测试64位双精度浮点运算的可执行二进制文件
  runme_xeon64脚本中调用了该程序，可参考runme_xeon64脚本了解使用方法。

  直接使用该程序，需指定输入文件，或执行后进入交互命令行，根据提示输入相关参数：

  1. `Input data or print help ? Type [data]/help` 

     回车继续或输入help查看帮助。

  2. `Number of equations to solve (problem size)` 问题规模（方程数量）

     一个数值，如50000，具体参看[HPL.dat配置](#HPL.dat配置)中关于 Ns 取值的计算方法。

  3. `Leading dimension of array` 矩阵主维度

     一个不小于问题规模的值（如果不输入或输入值小于问题规模之，将被设置为和问题规模一样大的值），如不了解输入值同问题规模即可。

  4. `Number of trials to run`  运行次数

     即在该问题规模下运行多少次

  5. `Data alignment value (in KByte)`  数据对齐值

     内存对齐的方式，对齐值允许数列与指定的值对齐。当数列与页面大小边界对齐时，可能会获得最佳性能。

     双精度计算输入8（双精度64bit=8Byte），单精度计算输入4。

     零表示不执行特定的对齐——数组在分配时使用。
  
     
  
  

测试示例：

```shell
./runme_xeon64    #脚本默认读取lininput_xeon64的参数进行测试
./xlinpack_xeon64 lin.input  #使用指定的lin.input为输入文件
```



### mp_linpack

目录内各个文件说明可查看其中的readme文件内容。

其中dynamic结尾的文件和static结尾的文件仅表示使用MPI动态链接或静态链接。



以使用runme_intel64_dynamic脚本为例，根据具体情况修改内容：

```shell
# Set total number of MPI processes for the HPL (should be equal to PxQ).
export MPI_PROC_NUM=20   #cpu物理核心数量

# Set the MPI per node to each node.
# MPI_PER_NODE should be equal to 1 or number of sockets in the system. Otherwise,
# the HPL performance will be low. 
# MPI_PER_NODE is same as -perhost or -ppn paramaters in mpirun/mpiexec
export MPI_PER_NODE=2    # NUMA sockets数量，一般等于cpu颗数

# You can find description of all Intel(R) MPI parameters in the
# Intel(R) MPI Reference Manual.
export I_MPI_DAPL_DIRECT_COPY_THRESHOLD=655360

#...some lines

#单节点测试无需修改，多节点测试参考下方“多节点测试”修改
mpirun -perhost ${MPI_PER_NODE} -np ${MPI_PROC_NUM} ./runme_intel64_prv "$@" | tee -a $OUT
```



提示，获取cpu信息：

```shell
LANG=C
#lscpu |grep Socket  #cpu颗数
lscpu |grep NUMA
lscpu |grep 'Thread'  #每个cpu core的线程（查看是否开启超线程）
lscpu |grep 'On-line CPU'  #cpu数量  如果开启超线程，需要除以2
```



runme_intel64_dynamic将调用runme_intel64_prv脚本，runme_intel64_prv脚本调用xhpl_intel64_dynamic程序读取HPL.dat输入文件进行测试。

参看后文[HPL.dat](#HPL.dat配置)的说明，根据情况修改HPL.dat文件。

runme_intel64_dynamic生成的结果文件为xhpl_intel64_dynamic_outputs.txt。



单节点测试按上述设置后直接运行`runme_intel64_dynamic`即可

多节点测试，在执行脚本前确保一下配置已经完成：

- 设置并挂载集群共享目录，mp_linpack存放在公项目录

- 所有节点网络互通，配置好主机名映射

- 当前用户ssh密钥互信（免密码登录）

- 所有节点上均配置好intel mpi环境

- 编写主机列表文件，假如文件名为nodes_file，内容为：

  ```shell
  c01
  c02
  ```

- 修改runme_intel64_dynamic中mpirun行

  ```shell
  #mpirun -perhost ${MPI_PER_NODE} -np ${MPI_PROC_NUM} ./runme_intel64_prv "$@" | tee -a $OUT
  mpirun -perhost ${MPI_PER_NODE} -f node_files ./runme_intel64_prv "$@" | tee -a $OUT
  ```



## HPL.dat配置

HPL.dat配置生成工具：

- [HPL-dat生成工具](http://www.advancedclustering.com/act-kb/tune-hpl-dat-file/)

- [UL HPC - hpl params](https://ulhpc-tutorials.readthedocs.io/en/latest/parallel/mpi/HPL/#hpl-main-parameters)

HPL.dat文件中最重要的几个参数（一般只修改这几个）：

- problem sizes (matrix dimension N) 

  - of problems(N) 行

  - Ns 行

    of problems设置要测试的问题规模N的组数（也就是测试几次N） ，该行值设置为多少，则Ns行就需要填写相应多个数量的数值。例如of problems行填写2，则Ns行需要有2个以空白字符分隔的数值：

    > 2                             \# of problems sizes (N)
  >
    > 165696 182208      Ns
  
    
  
    HPL对双精度(D P)元素的NxN数组执行计算，并且每个双精度元素需要8字节（memory alignment in double，8Byte=64bit）大小（另：单精度为32bit需要4字节），由于系统本身也会消耗一些内存，运行hpl消耗的内存以不超过可用内存为限度，因此一般可先预估hpl消耗的内存一般控制在实际内存的80%-90%，例如取物理内存（单位KB）的85%：
  $$
    N*N*8≤RAM*0.85
  $$
    另外，**比较理想的问题规模值N应该是NB值的整数倍数**，得出初始N后，用其整除NB值得到商，再以该商乘以NB的积即是合适的N值。
  
    
  
    例如内存256G，NB为192，`(256*1024^3)*0.85>=N*N*8`  ，得出N为165794，165794/192取整为863，863*192得出N最大合适整数值为165696。
  
    提示：*实际操作中监测内存占用量，可以适当调整规模值。*
  
    在集群测试中，占用内存指的是hpl在所有参与测试节点使用的内存。
  
    

- block size NB

  - of NBs 行
  - NBs 行

  of NBS设置测试的NB的组数（也就是测试几次NB） ，该行值设置为多少，则NBs行就需要填写相应多个数量的数值。例如of NBs 行填写2，则NBs行需要有2个以空白字符分隔的数值：

  > 2                \# of NBs
  >
  > 128 192    NBS

  为提高整体性能，HPL采用分块矩阵的算法，of NBs行表示要设置几组分块矩阵，`NBs`根据`of NBs`规定设置相应数量的值，NBs取值和软硬件许多因素密切相关，根据具体测试不断调节。

  `NB×8`一定是CPU L2 Cache line(单位kb）的倍数，例如L2 Cache为1024k，则`NB=1024/8=192`。

  一般通过单节点或单CPU测试得到较好的NB值，选择3个左右较好的NBs值，再扩大规模验证这些选择。

  

- PMAP process mapping

  对于集群测试：按行Row排列（值为0）节点数量少于单节点理器核心数量，按列Column（值为1）节点数量多于每节点处理器核心数量。

  当然，单节点使用值0即可。

  

- process grid (P x Q) 

  - of process grids (P x Q) 行
  - P 行
  - Q 行

  

  这三行和CPU核心数量及运行hpl的线程有关。

  process grids 设置测试的网格组数（也就是测试几次PxQ） ，该行值设置为多少，则P行和Q行就需要填写相应多个数量的数值。例如of  process grids行填写2，则P行和Q行需要有2个以空白字符分隔的数值：

  > 2        #of process grids
  >
  > 2  4   #Ps
  >
  > 8  4   #Ns

  

  P和Q的取值应该尽量满足：

  - `P*Q=系统CPU Process数`

    cpu物理核心数，集群测试中`P*Q`为集群总的核心数。
  
  - `P<=Q`，即P 的值尽量比Q取小一点结果更好。
  
  - `P=2^n`，即P取值为2的幂结果更好。
  
    HPL中L分解 的列向通信采用二元交换法( Binary Exchange)，当列向处理器个数P为2 的幂时，性能最优。
  
  例如2CPU×8cores=16cores(每个core 1 thread）的情况下，如果of process grids行为2，即测试2组网格，则 P行和Q行各写2个数字，每两个上下对应的数字的值的乘积为16，例如
  
  
  
- memory alignment in double

  内存对其，双精度浮点数使用64位存储，这里的值的单位为Byte，填写8即可（8Byte=64bit）。

  

HPL.dat文件说明：

```shell
# 以下两行 该文件的注释说明
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee

# 以下两行 输出文件
HPL.out      output file name (if any) 
6            device out (6=stdout,7=stderr,file)  #6标准输出 7标准错误输出 其他值表示输出到指定文件（这里的文件名为out）

# 以下两行 求解矩阵规模的大小
6            # of problems sizes (N)   计算的组数
19200 38400 76800 153600 192000 230400     Ns  #  每组规模
 
# 以下两行 求解矩阵分块的大小
4 	           # of NBs 矩阵分块大小，分块矩阵的数量
1 2 3 4        NBs  #每种分块的具体值 参数为块大小，是将问题规模划分为块的基本单元

# 以下一行 阵列处理方式 （按列的排列方式还是按行的排列方式）
0            PMAP process mapping (0=Row-,1=Column-major)

#以下三行 二维处理器网格 PxQ=系统CPU process数  其中 P<=Q  且P=2^n较优
3            # of process grids (P x Q)  使用几组网格
1  2  4       Ps   #P<=Q P*Q<=总process数量
16 8  4       Qs  #

# 以下一行 余数的阈值（用以检测求解结果）
16.0         threshold

# 以下八行 L分解的方式
1            # of panel fact  使用几种分解方法
2            PFACTs (0=left, 1=Crout, 2=Right)  #使用的分解方法
1            # of recursive stopping criterium  使用几种停止递归的判断标准
4            NBMINs (>= 1)  #具体的标准数值（须不小于1）
1            # of panels in recursion  #递归中用几种分割法
2            NDIVs  #即每次递归分成几块
1            # of recursive panel fact.  用几种递归分解方法
1            RFACTs (0=left, 1=Crout, 2=Right) #选择的矩阵作消元

# 以下两行 L的广播方式  HPL中提供了6种广播方式
1            # of broadcast  #用几种向前看的步数
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM) #一般小规模系统选0或1 大规模 系统选3

# 以下两行 广播波通信深度
1            # of lookahead depth
1            DEPTHs (>=0)  #小规模集群取值1或2 大规模集群取值2到5

# 以下两行 U的广播算法
2            SWAP (0=bin-exch,1=long,2=mix)  #binary exchange  或 long 或 二者混合
64           swapping threshold  #采用混合的交换算法时使用的阈值

# 以下两行 L和U的数据存放格式（数据在内存的存放方式——行存放和列存放）
0            L1 in (0=transposed,1=no-transposed) form  #L1是否用转置形式
0            U  in (0=transposed,1=no-transposed) form  #U是否用转置形式表示

# 以下一行 平衡策略
1            Equilibration (0=no,1=yes)

#以下一行   指定HPL分配的内存空间的内存对齐
8            memory alignment in double (> 0) #双精度为8Byte

##### This line (no. 32) is ignored (it serves as a separator). ######
0                               Number of additional problem sizes for PTRANS
1200 10000 30000                values of N
0                               number of additional blocking sizes for PTRANS
40 9 8 13 13 20 16 32 64        values of NB
```



# 常见各种数学库

blas、lapack、atlas、openblas、mkl和cuBLAS

- BLAS（Basic Linear Algebra Subprograms，基本线性代数子程序）

  用以规范发布基础线性代数操作的数值库（如矢量或矩阵乘法）的API标准。它定义了一组应用程序接口（API）标准，是一系列初级操作的规范，如向量之间的乘法、矩阵之间的乘法等，是一组向量和矩阵运行的接口（API）规范。

  Netlib用Fortran实现了BLAS的API接口库名字也叫[BLAS](http://www.netlib.org/blas/)，Netlib并没有对运算做过多的优化。

  BLAS在高性能计算领域被广泛使用，各个软硬件厂商针对其产品对BLAS接口实现进行了优化，开源社区也有atlas和openblas等著名BLAS实现项目。

  

- [LAPACK](http://www.netlib.org/lapack/) （linear algebra package，线性代数包）

  Netlib用fortran语言编写的一组科学计算（矩阵运算）的接口规范，其底层是BLAS，在此基础上定义了很多矩阵和向量高级运算的函数，如矩阵分解、求逆和求奇异值等，运行效率比BLAS库高。

  

- [atlas](http://math-atlas.sourceforge.net)（Automatically Tuned Linear Algebra Software）和[openblas](http://www.openblas.net)

  atlas和openblas均为著名开源社区项目，它们都实现了BLAS的全部功能，以及LAPACK的部分功能，并且都对计算过程进行了优化。

  - Atlas （Automatically Tuned Linear Algebra Software）能根据硬件，在运行时，自动调整运行参数。Openblas在编译时根据目标硬件进行优化，生成运行效率很高的程序或者库。

  - Openblas的优化是在编译时进行的，所以其运行效率一般比atlas要高，但这也决定了openblas对硬件依赖性高，更换硬件后可能需要重新编译。

  

- [ScaLAPACK](http://www.netlib.org/scalapack/)（Scalable LAPACK）

  netlib编写的并行的LAPACK计算软件包，适用于分布式存储的 MIMD （multiple instruction, multiple data），采用消息传递机制实现处理器/进程间通信，使用和编写与传统的 MPI 程序比较类似。ScaLAPACK 主要针对密集和带状线性代数系统，提供若干线性代数求解功能，如各种矩阵运算，矩阵分解，线性方程组求解，最小二乘问题，本征值问题，奇异值问题等，具有高效、可移植、可伸缩、高可靠性等优点，利用它的求解库可以开发出基于线性代数运算的并行应用程序。

  

- [Eigen](https://eigen.tuxfamily.org/index.php?title=Main_Page)

  线性代数、矩阵、向量操作等运算的C++库，包含了众多算法，支持多平台。

  Eigen采用源码的方式提供给用户使用，在使用时只需要包含Eigen的头文件即可进行使用。Eigen采用模板方式实现，由于模板函数不支持分离编译，所以只能提供源码而不是动态库的方式供用户使用。其底层基于BLAS、LAPACK、MKL、CUDA、OpenMP等。

  

- [MKL](https://www.intel.com/content/www/us/en/develop/documentation/get-started-with-mkl-for-dpcpp/top.html)（Math Kernal Library，数学内核库）

  英特尔MKL基于英特尔® C++和Fortran编译器构建而成，并使用OpenMP*实现了线程化，现作为 [Intel® oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html)产品的模块。

  包含了优化过的BLAS、LAPACK、FFTW、ScaLAPACK、DFTs等等。

  

- [AOCL](https://developer.amd.com/amd-aocl/)（AMD Optimizing CPU Libraries）

  AMD推出的主要针对AMD的CPU架构进行了相关计算过程进行优化的数学库，包含了优化过的BLIS、LAPACK、FFTW、ScaLAPACK等等。

  

- [cuBLAS](https://docs.nvidia.com/cuda/cublas/index.html)（cuda BLAS）

  cuBLAS库是BLAS（基本线性代数子程序）在NVIDIA®CUDATM运行时之上的实现，它允许用户访问NVIDIA图形处理单元（GPU）的计算资源。