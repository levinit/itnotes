> AWK是一种处理文本文件的语言，是一个强大的文本分析工具。
>
> 之所以叫AWK是因为其取了三位创始人 Alfred Aho，Peter Weinberger, 和 Brian Kernighan 的Family Name的首字符。



基本语法：

```shell
awk [选项参数] 'script' var=value file(s)
#或
awk [选项参数] -f scriptfile var=value file(s)
```

option：awk的选项；script：awk的语句；file：要处理的文件。



常用选项：

-  **-F <fs>**   fs指定输入分隔符，fs可以是字符串或正则表达式，如-F:
-  **-v <var=value>**   赋值一个用户定义变量，将外部变量传递给awk
-  **-f <scripfile>**  从脚本文件中读取awk命令
-  **-m[fr] <val>**   对val值设置内在限制，-mf选项限制分配给val的最大块数目；-mr选项限制记录的最大数目。这两个功能是Bell实验室版awk的扩展功能，在标准awk中不适用。

```shell
#$NF获取最后一列 以下命令获取当前已经连接到网络的网卡名字
ip a|grep -E "inet\s+" |grep -v 127.0.0.1|awk '{print $NF}'
```

