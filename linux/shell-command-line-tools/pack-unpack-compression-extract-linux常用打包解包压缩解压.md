[TOC]

# 归档压缩格式建议

- 跨平台注意文件使用UTF-8编码
- 对于源文件较小或不在意压缩率的情况，建议使用zip甚至tar（只归档）即可，跨平台适用性强。

- 压缩格式优先推荐使用7z，其次是xz，gz等（xz的压缩率更高）

以下示例命令中test指某个文件或者文件夹

# 常见打包和压缩格式

## tar

### tar打包解包

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

- -c或--create：建立新的备份文件；

- -v或--verbose：显示指令执行过程；

- -x或--extract或--get：从备份文件中还原文件；

- -f <归档文件>或--file=<归档文件>：指定归档文件（即要打包/压缩成的文件）；

- -r：添加文件到已经压缩的文件；

- -p或--same-permissions：用原来的文件权限还原文件；

- -A或--catenate：新增文件到以存在的备份文件；

- -u：添加发生变更的文件到已经存在的压缩文件；

- -k：保留原有文件不覆盖；

- -w：确认压缩文件的正确性；

- -C <目录>：这个选项用在解压缩时指定解压到特定目录；

### tar+xz或gz或bz2合用

tar添加以下参数，在打包tar后压缩成xz、bz2、gz等格式，或在解压缩xz、bz2、gz后再解tar包。

相比gz和bz，xz压缩率更高（耗时也更长），要进一步缩小体积，应当先tar归档，然后[使用xz压缩](#.xz)选用更高的压缩等级。

- `-J` ：支持xz
- `-j`：支持bz2
- `-z`：支持gz

```shell
tar xJvf test.tar.xz  #解压xz后解包tar
tar cJvf tets.tar.xz  #打包tar后压缩为xz格式
```

## .gz

参照上文，可配合tar使用。

```shell
#gzip或gnuzip
gzip test.gz  #解压
gzip -d test.gz  #解压
gzip test  #压缩
```

## .bz2

参照上文，可配合tar使用。

```shell
#使用bzip2或bunzip2
bzip2 -z test  #压缩
bzip2 -d test.bz2  #解压
```

## .xz

参照上文，可配合tar使用。

xz只能指定压缩一个或多个文件，不能直接压缩一个目录，因此对于目录可先tar归档，再使用xz压缩。

- `-k`或`--keep`  保存源文件（默认是压缩后删除原来的文件） 
- `-n`  压缩率n （取值0-9，默认6）
- `-T n`或`--threads=n`  最多使用的线程数量n（多线程需要xz版本5.2及以上  默认单线程），如果n的值为0则表示值为处理器的总线程数
- `-e`或`--extreme`  尝试通过使用更多的CPU时间来提高压缩比
- `-l`或`--list`  查看.xz文件中的信息
- `-z`或`--compress`  强制压缩
- `-d`或`--decompress`  强制解压
- `-t`或`--test`  压缩测试

为了更好的压缩率，可先tar归档，再使用xz压缩并选用`-n`参数指定更高的压缩率，为了提升压缩速度，最好使用`-T`使用多线程。

```shell
xz -zekv9 -T 12 test  #压缩  等级9 使用12线程
xz -d test.xz  #解压
```

## .zip

压缩工具：zip

- `-0`  只归档打包不压缩

- `-1`  快速压缩（低压缩率，压缩包大）

- `-9`  高效压缩（高压缩率，压缩包小）

  1-9是9个压缩等级

- `-r`  递归压缩

- `-e`  密码加密，交互式，会提示输入密码

- `-P`  指定压缩密码

- `-u`  追加文件压缩包

- `-s`  指定分卷切分大小

解压工具：unzip

- `-P`  指定解压密码
- `-d`  解压到指定目录
- `-l`  列出压缩包中文件（不解压）

unzip-iconv，为unzip增加了转码补丁，可在解压缩时使用`-O`参数可指定编码格式。

```shell
zip -r test.zip test/  #打包 -r递归
unzip test.zip  #解包
unzip test.zip -d /tmp   #解包到指定目录
#指定编码格式(如gbk)避免乱码 需要安装unzip-iconv
unzip -O gbk test.zip
zip -P 123 files.zip files
unzip -P 123 files.zip
zip -s 100m files.zip --out partzip #分卷 
cat partzip* > files.zip && unzip files.zip #合并分卷并解压
```

## .7z

工具p7zip

```shell
7za a  test.7z test  #压缩
7za x test.7z  #解压
```

## .rar

压缩工具：rar (非win平台，以及为了更好的跨平台，不建议压缩成rar)

解压工具：unrar

- `x`  使用完整路径
- `e`  不使用归档的完整路径（直接解压到当前目录）

```shell
rar a test.rar test  #压缩
unrar test.rar  [path-to-target]     #解压 (可指定解压目录)
echo password_str | unrar test.rar #使用密码解压
```

分卷解压，直接解压第一个分卷即可，其会自动合并解压所有分卷：

```shell
#例如某文件压缩为 file.part1.rar   fiel.part2.rar
unrar file.part1.rar
```



# 加密/解密

本章节描述使用gpg（gnupg）加密解密（归档/压缩）文件，当然[zip/unzip](#.zip)，[rar](#.rar)工具也带有加密解密功能，一般应当使用其加密功能加密，对于tar、7z、xz等不带有加密功能的，可再使用zip压缩并加密。

```shell
tar cJvf test.tar.xz test
#加密 -c使用对称加密  生成以.gpg结尾的文件 不能对目录加密
gpg -c test.tar.xz  #会提示输入密码
#解密 -o指定生成的解密文件，-d指定被解密的文件（该选项为默认选项可不写）。
gpg -o test.tar.xz -d test.tar.xz.gpg
```

# 分卷

一般不建议使用rar格式的分卷（尤其是非windows平台以及跨平台的需求下），理由同加密/解密章节所述。

zip分卷参考[zip章节](#.zip)

### 切分

这里介绍使用`split`切分归档/压缩文件：

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

### 合并

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

  RPM包括是使用cpio格式打包的，因此可以先转成cpio然后解压，如下所示：

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


