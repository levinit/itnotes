# 简介

> [Podman](http://podman.io/) is a daemonless, open source, Linux native tool designed to make it easy to find, run, build, share and deploy applications using Open Containers Initiative ([OCI](https://www.opencontainers.org/)) [Containers](https://developers.redhat.com/blog/2018/02/22/container-terminology-practical-introduction/#h.j2uq93kgxe0e) and [Container Images](https://developers.redhat.com/blog/2018/02/22/container-terminology-practical-introduction/#h.dqlu6589ootw). 



[podman](https://docs.podman.io)兼容docker的大部分命令，将命令中的docker替换成podman即可。

podman无daemon守护进程。

*pod的含义为豆荚，类似docker集装箱，是一个很形象的名字。*

> Podman使用libpod库管理整个容器生态系统，包括豆荚（pod）、容器、容器图像和容器卷。



# 基本设置

一般的，在linux上安装podman后，全局配置文件目录为`/etc/containers`，仅作用于用户的配置文件目录为`~/.config/containers`。

## 换源

配置文件为registries.conf，示例：

```shell
#unqualified-search-registries = ["docker.io","quay.io" "registry.redhat.io", "registry.access.redhat.com"]

unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "hub-mirror.c.163.com"

[[registry.mirror]]
location = "mirror.baidubce.com"

[[registry.mirror]]
location = "dockerproxy.com"

[[registry.mirror]]
location = "ghcr.io"
```



## 镜像存储位置

配置文件为storage.conf可定义存储位置，默认在/var/lib/containers。

root用户拉取的镜像可以别其他用户直接使用，普通用户拉取的镜像默认存放在自己的家目录下的`.local/share/containers`，仅能自己使用。



## 用户id映射

如果以普通用户运行容器，且在容器中运行了需要使用主机的用户或组身份验证的应用程序，那么容器中必须存在与主机上相同UID和GID的用户或组。

在运行容器的命令中使用`--users=keep-id`可以保持容器中UID/GID与外部的一致性，也可以使用`--uidmap`和`--gidmap`选项手动映射容器中的用户或组到主机上的用户或组

```shell
usermod --add-subuids <start>-<end> --add-subgids <start>-<end> <user>

#示例
usermod --add-subuids 10000000-10065535 --add-subgids 10000000-10065535 user1

#修改了ud映射后需要执行迁移
podman system migrate
```

上面的示例为user1用户添加了uid和gid的映射，在`/etc/subuid`和`/etc/subgid`中增加了一行：

```shell
user1:10000000:65535  #表示从1000000开始后面的65535个数字
```

