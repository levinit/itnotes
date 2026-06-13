

# 零散

- `sh`中没有`source`

- shell文件格式化工具`shfmt`

- `$BASHPID`  当前bash的pid（非bash终端变量名不同），相当于`$$`



# 随机数

`RANDOM`变量会生成0--32767的整数。

生成一定范围内的整数

```shell
echo $(($RANDOM%99))    #生成0-99的数
echo $(($RANDOM%82+6))  #生成6-87（81+6)的数
```

从shell数组中随机选择一个元素

```shell
arr=(1 3 5 7 9)
rand_index=$(($RANDOM % ${#a[*]})) #随机获取一个下标值
echo ${arr[$rand_index]}
```

注意：csh、zsh，数组元素下标从1开始



# 加密shell文件

## gzexe

gzexe只能简单压缩，解密很简单。

加密

```shell
gzexe test.sh  #原文件变成了test.sh~
```

解密

cat加密后内容可以看到有一行叫skip=44（或其他数字），它告诉我们从第44行起才是原来压缩之前文件的内容。

```shell
tail -n +44 test.sh > test1.gz
gunzip test1.gz   #得到test1.sh 内容和源文件一样
```



## shc

改写为c语言然后编译成二进制文件。

```shell
orig_name=test.sh

shc -r -f $orig_name
rm -f $orig_name $orig_name.x.c  #删除含有源码的文件
mv $orign_name.x $orig_name
```

以原文件名为test.sh为例，加密后，原文件还在，共有3个相关文件：

- test.sh  原文件
- test.sh.x  可执行的二进制文件
- test.sh.x.c  test.sh.x的源码文件（c语言）

注意，shc加密的脚本文件里面要声明shengbang，如：

```shell
#!/bin/bash
```

不能使用`#!/bin/env bash`方式。
