

# update-alternatives

## 简介

创建、删除、维护和显示关于包含替代系统的符号链接的信息。

用于管理：

- 一个软件的多个版本的默认版本

  例如：系统中安装了gcc-7，gcc-9，`$PATH`中默认的`gcc`，如`/usr/bin/gcc`只可能为其中的一个gcc版本。

- 一个功能的多个实现的默认实现

  例如：系统中安装了多个编辑器，vim、nano、vi，而一些软件在编辑文件时会调用`$EDITOR`变量指向的某个编辑器如`vi`。

  

update-alternatives以权重来确定默认值，数值最大的为默认值，

update-alternatives本质上是通过建立两重软链接的方式工作的，其在shell命令与真正的执行程序间加入匹配层。例如一个系统中的editor可能是这样链接的：

> ```shell
> $ ls -l /usr/bin/editor
> lrwxrwxrwx 1 root root 24 Jan 10  2020 /usr/bin/editor -> /etc/alternatives/editor
> 
> $ ls -l /etc/alternatives/editor
> lrwxrwxrwx 1 root root 17 Jun 25 20:21 /etc/alternatives/editor -> /usr/bin/vim.tiny
> ```

在shell中键入`editor`会先找到`/etc/alternatives/editor`，然后找到`/usr/bin/vim.tiny`。



## 使用

设置默认链接：

```shell
#update-alternatives --install <link> <name> <path> <priority>

update-alternatives --install /usr/bin/gcc gcc gcc-7 50
```

- `<link>`    要创建的软连接的位置

- `<name>`    同一软件的不同版本或同一功能的不同实现公用的名字，例如gcc-7，gcc-9，一般将公用名字设置为gcc

- `<path>`    被软链接的文件的路径

- `<priority>`    优先级（权重）

  当前`<nam>`中权重值最高的才会成为默认的链接最终指向的源文件，相同则后install的覆盖为最新默认值。

  例如为每个`gcc-*`设置不同的权重，权重高的将成为默认的`gcc`。



设置指定项的各个版本的优先级：

```shell
# update-alternatives  --config <name>
update-alternatives  --config editor   #设置editor的优先级
```

移除指定项的相关链接：

```shell
#update-alternatives --remove <name> <path>
#update-alternatives --remove-all <name>     #移除所有

update-alternatives --remove gcc /usr/bin/gcc-7
```

查看指定项的各个版本的路径：

```shell
update-alternatives --diplay <name>
```
