[TOC]

# 归档和压缩格式建议

不少工具都支持多种归档/压缩格式，选择归档或压缩格式，可根据压缩率（或称为压缩比，越高则生成的压缩文件越小）和压缩/解压耗时考量，**一般来说，压缩率越高，压缩/解压耗时越长**。



- tar只是进行单纯的归档

  主要用于将多个文件打包成一个单独的文件，不会进行压缩，因此其打包/解包速度肯定比压缩文件的压缩/解压要快。

  对于不考虑文件归档后占用体积的情况可选择该方式，例如将包含众多文件的目录归档为一个文件便于传输。

  另外，zip设置压缩等级为0时也只是归档不压缩。

  

- 压缩格式的选择

  以下对常见的压缩格式进行对比，主要是7z，xz，rar，zstd，bzip2，gzip，zip。

  

  注意：压缩率、压缩耗时和解压耗时这些指标的排名可以因多种因素而有所不同，包括文件类型、文件大小、硬件配置等等，一些工具在压缩时也能指定压缩等级和使用的线程数量，这也影响最终压缩的文件大小和压缩/解压的速度，因此一下对比只能是一个通常情况的相对比较。

  

  - 相对较高的压缩率：xz>=7z>rar>zstd

    这些格式都支持设置压缩等级和使用多线程。

    xz/7z与其它格式相比**压缩率很高**，二者均采用lzma算法压缩率基本相当。压缩xz时如果只使用单线程（一般实现xz的工具默认使用单线程）则耗时很长。

    与其他格式对比，rar在压缩率和耗时上比较均衡，在windows上使用较为广泛。

     zstd兼得了**较高压缩率**（虽然比前面几者压缩率低）和**明显很低**的压缩/解压耗时（比前面几者耗时少很多，而且比低压缩率的gzip更快），尤其是解压时间耗时很短。

  

  - 相对较低的压缩率：bzip > gzip > zip

    低压缩率带来了耗时少的优势，适用于原始文件体积较小较小、难以再获得高压缩率的原始文件文件（如二进制文件），以及对压缩后的文件体积不敏感的情况。

    bzip2的压缩率明显高于gzip和zip；但bzip2与上文的高压缩率格式相比，其压缩率明显更低且压缩/解压耗时却处于劣势。如果使用支持多线程的pbzip2则压缩/解压耗时明显降低。

    gzip的通用性很好，其也有支持多线程的pigz也可以明显提升压缩/解压速度。

    zip被广泛采用，因此虽然压缩率低但通用性很好，不过注意6.0以前的版本的zip不支持大于4G的文件和存在编码问题。
    
    

# 常见打包和压缩格式

本文主要介绍相关工具在Linux/MacOS命令行下的使用。



## gzip(.gz)

一般使用`.gz`后缀。

压缩目录可配合[tar](#tar)使用。

```shell
#gzip或gnuzip
gzip test.gz     #解压
gzip -d test.gz  #解压 -d选项
gzip test  #压缩
```

pigz可以多线程并行压缩gzip



## bzip2(.bz2)

bzip也常使用更简略的`.bz2`为文件后缀。

压缩目录可配合[tar](#tar)使用。

```shell
#使用bzip2或bunzip2
bzip2 -z test      #压缩 -z选项
bzip2 -d test.bz2  #解压 -d选项
```



## xz

xz只能指定压缩一个或多个文件，不能直接压缩一个目录，因此对于目录可先tar归档，再使用xz压缩，或使用[tar](#tar)命令指定使用xz压缩。

```shell
xz -zkev9T 12 test  #压缩  等级9 使用12线程
xz -d test.xz  #解压
```

xz命令的常用选项：

- `-k`或`--keep`  保存源文件（**默认在压缩后删除原来的文件**） 

- `-n`  压缩率n （取值0-9，默认6）

- `-T n`或`--threads=n`  最多使用的线程数量n（多线程需要xz版本5.2及以上  默认单线程）

  如果n的值为0则表示值为处理器的核心数

  xz默认单线程，因此压缩速度很慢，条件允许的情况下尽量使用多线程。

- `-e`或`--extreme`  尝试通过使用更多的CPU时间来提高压缩比

- `-l`或`--list`  查看.xz文件中的信息

- `-z`或`--compress`  强制压缩

- `-d`或`--decompress`  强制解压

- `-t`或`--test`  压缩测试



## zstd(.zst)

一般使用`.zst`后缀。

一般zstd程序安装后除了`zstd`命令，还提供以下别名命令：

- `zstdmt` 等同于`zstd -T0`

- `unzstd` 等同于 `zstd -d`
- `zstdcat`  等同于 `zstd -dcf`

zstd只能指定压缩一个或多个文件，不能直接压缩一个目录，因此对于目录可先tar归档，再使用zst压缩，或使用[tar](#tar)命令指定使用zstd压缩。

```shell
#压缩 zstd [OPTIONS...] [INPUT... | -] [-o OUTPUT]
zstd -frv -T0 test -o test.zst  #zstdmt -frv test -o test.zst
#解压
zstd -d dir1.zst

#训练字典
zstd --train trainingDir/* -o dict1
```



常用选项：

- 压缩或解压模式

  没有指定压缩或解压的选项时，默认行为就是对指定的文件进行压缩（即进行压缩时可不指定该选项）

  - `-z`或`--compress` 压缩

    可以在要压缩的文件后使用`-o`选项指定输出的压缩文件的名字，如不指定，则输出的压缩文件名为原文件名加上`.zst`后缀。

    如果指定了文件进行压缩，则`-o`无效，将为每个文件进行单独压缩。

  - `-d`或`--decompress`或`--uncompress`  解压

    **zst压缩包也可以使用[tar](#tar)命令以解开tar包的方式解压。**
    
    

- 压缩级别

  - `-<#>`  压缩级别，这里的`#`为1至19（包含1和19）的任意一个整数，默认值为3

    不过，如果配合`--ultra`选项使用，则可使用更高的20至22等级。

  - `--fast[=#]` 切换到超快压缩水平

    如果`=#`不存在，则默认为1。值越高，压缩速度越快，以某种压缩比为代价。

  压缩水平和压缩级别的选项互相覆盖（后指定的选项覆盖先指定的选项。

  

- `-T#`或`--threads=#`  使用的线程数量

  如不指定，则使用默认值1（即等同于`-T1`，如果`#`为0（即`-T0`）则尝试检测和使用**物理CPU内核的数量**

  

-  `-D <DICT_file>`   使用字典进行压缩/解压

  小数据量压缩场景使用字典效果更好，字典可以自行训练。

  

- `-f`或`--force`  强制覆盖已经存在的文件（例如压缩时不再提示确认是否覆盖已经存在的文件）



- `-l`或者`--list`  显示与zstd压缩文件相关的信息

  信息内容包含大小、比率和校验和。其中一些字段可能不可用。此命令的输出可以使用`-v`修饰符进行增强。



## tar

### tar归档打包和解包

```shell
#仅查看内容
tar -tf file.tar[.xz/gz.bz]
#打包
tar -cvf test.tar test
#解包
tar -xvf test.tar test
#仅解包 部分内容 ｜可先查看内容确定相对路径 如data/abc
tar -xvf test.tar data/abc #仅解开data/abc目录
```

常用参数：

- `-c`或`--create`：建立新的备份文件
- `-v`或`--verbose`：显示指令执行过程
- `-f <tar_file>`或`--file=<tar_file>`：指定归档文件（即要打包/压缩成的文件）
- `-x`或`--extract`或`--get`：从备份文件中还原文件
- `-r`：添加文件到已经压缩的文件
- `-p`或`--same-permissions`：用原来的文件权限还原文件
- `-A`或`--catenate`：新增文件到以存在的备份文件
- `-u`：添加发生变更的文件到已经存在的压缩文件
- `-k`：保留原有文件不覆盖
- `-w`：确认压缩文件的正确性
- `-C <dir>`：这个选项用在解压缩时指定解压到特定目录



### tar打包并压缩和解压

tar添加以下参数指定压缩算法一次性实现归档tar包+压缩/解压的组合操作，可用方法：

- `-a`参数+特定后缀自动选择压缩/解压程序

  如果`.xz`选择xz，示例：

  ```shell
  tar -acvf test.tar.gz  test/  #tar检测到.gz后缀，使用gzip压缩
  tar -acvf test.tar.zst test/  #tar检测到.zst后缀，使用zstd压缩
  tar -acvf test.tar.xz  test/  #tar检测到.xz后缀，使用xz压缩
  
  tar -xvf  tets.tar.xz. #tar自动检测压缩算法并解压
  ```

  

- 指定压缩/解压程序的选项

  > ```shell
  > -j, --bzip2
  >       Filter the archive through bzip2(1).
  > 
  > -J, --xz
  >       Filter the archive through xz(1).
  > 
  > --lzip Filter the archive through lzip(1).
  > 
  > --lzma Filter the archive through lzma(1).
  > 
  > --lzop Filter the archive through lzop(1).
  > 
  > --no-auto-compress
  >       Do not use archive suffix to determine the compression program.
  > 
  > -z, --gzip, --gunzip, --ungzip
  >       Filter the archive through gzip(1).
  > 
  > -Z, --compress, --uncompress
  >       Filter the archive through compress(1).
  > 
  > --zstd Filter the archive through zstd(1).
  > ```

  示例：
  
  ```shell
  tar -xJvf test.tar.xz test        #解压xz后解包tar
  tar -cJvf tets.tar.xz test        #打包tar后压缩为xz格式
  tar -cvf --zstd test.tar.zst test #使用zstd
  ```
  
  

- `--use-compress-program=`调用指定程序命令对压缩包压缩

  ```shell
  tar cvf test.tar.xz --use-compress-program='xz -1T0' test
  ```

  

## zip

压缩工具：zip

- `-#`  压缩等级

  *程序里面描述为压缩速度，压缩速度越快压缩率越低。*`#`为0-9的整数，默认值为6

  - `-0`  只归档打包不压缩


  - `-1`  快速压缩（低压缩率，压缩包大）


  - `-9`  高效压缩（高压缩率，压缩包小）


- `-r`  递归（即包含各级子目录下的文件）

- `-e`  密码加密，交互式，会提示输入密码

- `-P`  指定压缩密码

- `-u`  追加文件压缩包

- `-s`  指定分卷切分大小

解压工具：unzip

- `-P`  指定解压密码
- `-d`  解压到指定目录
- `-l`  列出压缩包中文件（不解压）
- `-O`  指定编码格式 （6.0+版本支持，或者打补丁实现支持）



```shell
zip -r test.zip test/  #打包 -r递归
unzip test.zip  #解包
unzip test.zip -d /tmp   #解包到指定目录

#指定密码以解压加密文件（如不指定密码，则需要在提示输入密码后输入密码）
zip -P 123 files.zip files
unzip -P 123 files.zip

#指定编码格式(如gbk)避免乱码
unzip -O gbk test.zip

#分卷
zip -s 100m files.zip --out part.zip #按大小分割，输出文件带数字编号的后缀
cat part.zip* > all.zip && unzip all.zip #合并分卷并解压
```



## 7-zip(.7z)

7-zip（或7zip）压缩包使用`.7z`后缀，其在POSIX上常用的实现程序为p7zip。

p7zip安装后提了`7z`、`7za`和`7zr`：`7z`程序可以处理除了7z格式外的其他格式，而`7za`程序处理的格式比`7z`少，`7zr`程序则只能处理7z格式文件且不能处理加密的7z文件。

注意：不要将 7z 格式用于备份目的，因为它不会保存文件的所有者/组信息。

`7z`常用命令和选项：

- `a`  归档压缩
- `x`  解压缩

```shell
#压缩 a命令 7z a xx.7z file1 [file2...]
7z a  test.7z f1 f2

#解压 x命令保留目录结构，e命令不保留目录结构
7z x test.7z
#解压到指定目录 -o选项指定输出路径，注意-o和路径之间没有空白字符
7z x test.7z -o/path/to/target

#加密 -p选项指定密码，注意-p和密码之间没有空白字符
7z x -p123pass test.7z
```



## rar

- 压缩工具：rar

- 解压工具：unrar

  常用命令

  - `x`  解压并使用完整路径

  - `e`  解压并不使用归档的完整路径（直接解压到当前目录）

    


```shell
rar a test.rar test  #压缩
unrar test.rar  [path-to-target]     #解压 (可指定解压目录)

echo password_str | unrar test.rar #使用密码解压
```



分卷解压，直接解压第一个分卷即可，其会自动合并解压所有分卷：

```shell
#例如某文件压缩为 file.part1.rar   fiel.part2.rar
unrar x file.part1.rar
```



# 加密/解密

zip，rar，7z等带有加密实现的参看相应的章节。

对于tar、xz等不带有加密功能的，可再使用zip加密，或者使用gpg（gnupg）加密解密（归档/压缩）文件，

```shell
tar cJvf test.tar.xz test
#加密 -c使用对称加密  生成以.gpg结尾的文件 不能对目录加密
gpg -c test.tar.xz  #会提示输入密码
#解密 -o指定生成的解密文件，-d指定被解密的文件（该选项为默认选项可不写）。
gpg -o test.tar.xz -d test.tar.xz.gpg
```



# 分卷

## 切分

zip分卷可使用zip工具自带参数实现，参考zip章节。

rar对分卷压缩的实现比较好。



本章节只介绍使用`split`切分归档/压缩文件：

```shell
split -b <平均大小> <被切割文件> [切割后生成文件的前缀]
```

切割后生成文件即分卷文件，如果不指定切割后生成文件前缀，默认以`x`为前缀，而后以`aa`开始按顺序编号，例如切割成了3个文件，名字就分别为`xaa`、`xab`和`xac`。

```shell
#假如file.tar.xz大小1200m 按500m一份切分
#生成文件前缀使用file.tar.xz-part
#三个文件分别为500m 500m 200m
split -b 500m file.tar.xz file.tar.xz-part
#tar czvf - filedir | split -b 100m
```



## 合并

rar无需合并解压，参看[rar](#.rar)章节。



使用cat合并文件，然后再解包/解压缩：

```shell
#接以上面split的例子
#将各个文件合并 合并后的文件名为file.tar.xz
cat file.tar.xz-part* > file.tar.xz && tar xJvf file.tar.xz
```



# 特殊文件打包/解包和压缩/解压

## archlinux系安装包

- 解包/解压缩：tar.xz格式，参看上文[tar](#tar)。
- 打包工具：makepkg

## redhat系安装包rpm

- 解包/解压缩：

  ```shell
  tar -xf <rpm file>
  ```

  如果不能解压，使用rpm2cpio工具（RPM使用cpio格式打包，因此可以先转成cpio然后解压），如下所示：

  ```shell
  rpm2cpio <file.rpm> | cpio -div
  ```

- 打包rpm工具：rpmbuild

## debian系安装包deb

- 解包工具：ar

  ```shell
  ar -x <file.deb>
  tar -zxvf data.tar.gz  #解开应用文件夹
  ```

- 打包deb工具：dpkg-deb

## exe

- 解压缩：p7zip

  ```shell
  7z -x <file.exe>
  ```

