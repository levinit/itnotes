[TOC]

# 简介

[docker doc](https://docs.docker.com/reference/)

# docker与容器技术

docker是一种Linux 容器（Linux Containers，缩写为 LXC）解决方案。

容器Contanier将运行环境打包，提供标准的接口，能够运行在众多操作系统上。

> **容器使软件具备了超强的可移植能力。**

容器由两部分组成：应用程序本身和依赖。

容器在宿主机操作系统的用户空间中运行，与操作系统的其他进程隔离。

> 传统虚拟机技术是虚拟出一套硬件后，在其上运行一个完整操作系统，在该系统上再运行所需应用进程；而容器内的应用进程直接运行于**宿主的内核** ，**容器内没有自己的内核，而且也没有进行硬件虚拟**。因此容器要比传统虚拟机更为轻便。

docker基础镜像（base images，如各个发行版的基础镜像）使用的是**宿主机的内核**。在对内核版本有要求（比如应用只能在某个 kernel 版本下运行）的情况下，虚拟机可能更合适。

## docker的架构

- 客户端Client：构建和运行容器。
- 镜像Image：容器的只读模板，通过镜像构建容器。镜像由多个层组成（参看dockerfile文档）
- 容器Container：镜像的运行实例。
- 服务daemon：创建、运行、监控容器，构建、存储镜像。
- 仓库Repository：存放镜像



# 安装配置

安装docker参看[docker docs : get started](https://docs.docker.com/get-docker/)

## 修改镜像源

Linux修改 `/etc/docker/daemon.json`，windows修改`%programdata%\docker\config\daemon.json`，示例：

```json
{
  "registry-mirrors": ["源地址"]
}
```

Mac在docker的preference中修改Docker Engine配置：

```json
{
  "experimental": false,
  "debug": true,
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```



## 非root用户使用docker

要将该用户添加到docker组中：

```shell
usermod -aG docker <username> #或 gpasswd -a <username> docker
#重新登入系统或使用以下命令使其立即生效：
newgrp docker
```

## 修改存放目录

默认情况下，Docker镜像和容器的默认存放位置为:`/var/lib/docker`，可使用`docker info | grep 'Root Dir'`命令查看。

假如要设定的存放路径为`/home/docker/` ，可使用以下方法：

- 使用软链接

  ```shell
  systemctl stop docker  #如果docker服务正在运行 先关闭之
  mv /var/lib/docker /home/docker  #移动docker存放文件
  ln -sf /home/docker /var/lib/docker  #将新位置软连接到原来的存放位置
  ```

- 修改全局配置文件

  各个操作系统中的存放位置不一致， Ubuntu 中的位置是：`/etc/default/docker`，在 CentOS 中的位置是：`/etc/sysconfig/docker`。在配置文件中添加：

  ```shell
  OPTIONS=--graph="/root/data/docker" -H fd://
  #如果系统有selinux并已经开启，可添加关闭selinux的参数
  OPTIONS=--graph="/root/data/docker" --selinux-enabled -H fd://
  ```

## docker信息

- 查看docker状态`docker info`
- 查看镜像、容器、数据卷所占用的空间`docker system df`

# 镜像操作

```shell
docker images  #列出本地镜像

#列出虚悬镜像
docker image ls -f dangling=true

#删除镜像
docker image rm <image>[:tag]  #或者docker image rm <镜像id>
docker rmi <image>[:tag]       #rmi简写形式
```



## 从仓库获取镜像

 这里演示从[DockerHub](https://hub.docker.com/explore/)仓库获取。

```shell
docker search <key words>  #搜索镜像

#拉取镜像
docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]
#示例
docker pull base/archlinux
docker pull centos
docker pull unbuntu:17.04
docker pull scratch  #scratch是一个空白镜像（没有内容）

#推送镜像到仓库
docker push [选项] 镜像名[:标签] 用户名/镜像名
```
镜像仓库参看https://docs.docker.com/docker-cloud/builds/push-images/



## 存储和载入镜像

[docker save](https://docs.docker.com/engine/reference/commandline/save/)

> Save one or more images to a tar archive (streamed to STDOUT by default

[docker load](https://docs.docker.com/engine/reference/commandline/load/)

> Load an image from a tar archive or STDIN

```shell
#docker save [OPTIONS] IMAGE [IMAGE...]
#导出目标可以使用 >  或 --output（或-o）两种方式指定
docker save busybox > busybox.tar
docker save --output busybox.tar busybox
#导出并使用gzip压缩
docker save myimage:latest | gzip > myimage_latest.tar.gz

#docker load [OPTIONS]
docker load < busybox.tar.gz
docker load --input busybox.tar.gz
```



## 构建镜像

镜像是一层一层的构建的（参看下面两种构建方法），可使用`docker history 镜像名`查看其构建历史。

### docker commit构建

1. 运行容器

2. 修改容器：进行各种操作（例如增删改文件/软件包）

3. 将容器保存为新的镜像

   ```shell
   docker commit [选项] 容器名 [仓库名：标签]
   ```

   每一次commit都会构建一层镜像。**如果没有标签名，则默认为lastest**。

### dockerfile构建

参看[dockerfile reference](https://docs.docker.com/engine/reference/builder/)

- 从已有dockerfile文件构建

   ```shell
   docker build -t 镜像名[:标签] 生成路径
   #docker build -t 'centos-with-nginx:v1' ./
   docker tag 源镜像[:标签] 新镜像名[:标签]  #修改标签
   ```

   在镜像名后面加上`:`，在`:`后面添加标签，**如果没有标签名，则默认为lastest**。

   - `-f`  指定读取的dockerfile，如不指定，默认读取当前目录下的**Dockerfile文件**。

   

- dockerfile文件

   > Dockerfile 是一个文本文件，其内包含了一条条的指令(Instruction)，每一条指令构建一层,因此每一条指令的内容,就是描述该层应当如何构建。

   示例：

   ```shell
   FROM archlinux  #指定基础镜像 scratch是空白镜像
   MAINTAINER yourname "xx@yy.com"  #维护者
   RUN buildDeps=pacman -Syu nginx  #RUN后面是要执行的命令
   RUN echo '<h1>Hello Docker!</h1>'  >  /usr/share/nginx/html/index.html
   CMD ["nginx", "-g", "daemon off;"]
   EXPOSE 80
   ```

   Dockerfile 中每一个指令都会建立一层，因此有必要尽可能减少命令条数，例如使用`&&`将几条`RUN`指令合成一条。

   - 常用指令：
     - `FROM 镜像名`  基于的镜像 

     - `MAINTAINER 作者` 镜像作者

     - `COPY 来源 目的`  复制

     - `ADD 来源 目地`  类似COPY，如果要复制的文件是归档文件（tar、zip、xz等），其会被自动解压

     - `ENV 环境变量`  设置环境变量供后面的指令使用

     - `EXPOSE 端口`  指定容器中的进程会监听某个端口

     - `VOLUME 路径 `  将文件或目录声明为 volume

     - `WORKIDR 路径`  为后面的RUN, CMD, ENTRYPOINT, ADD或COPY指令当前工作目录

     - `RUN 指令`  在构建时容指定的命令

     - `CMD 指令`  容器启动时运行指定的命令

     - `ENTRYPOINT 指令`  容器启动时运行的命令

       不同于CMD，ENTRYPOINT**一定会被执行**，即使运行 docker run 时指定了其他命令。

     - `USER 用户名`  指定后面指令的运行用户

     - `HEALTHCHECK [选项] CMD <命令>：设置检查容器健康状况的命令`

     - `ONBUILD`

   

   - 技巧

     - `RUN`、`CMD`和`ENTRYPOINT`均有三种命令运行方式，但只建议将命令以IFS分隔的各个部分在`[]`中以`,`分隔的方式编写。

     - 减小镜像体积

     - 压缩镜像层

       Dockerfile中的每条指令都会创建一个镜像层（最多127层），继而会增加整体镜像的尺寸，为了减小景象大小，应该将某些指令合并编写。例如：

       ```dockerfile
       RUN apt install -y vim
       RUN apt install mariadb
       RUN rm -rf /var/cache/apt/*
       ```

       可以合并为：

       ```dockerfile
       RUN apt install -y vim mariadb && rm -rf /var/cache/apt/*
       ```

     - [google distroless](https://github.com/GoogleContainerTools/distroless)提供了一些容器镜像，可根据需要选用。

       > “distroless”镜像只包含应用程序及其运行时依赖项，不包含程序包管理器、shell 以及在标准 Linux 发行版中可以找到的任何其他程序。

     - 选用较小体积的基础镜像

       例如，[alphine](https://hub.docker.com/_/alpine)，一个基于 musl libc 和 busybox 的面向安全的轻量级 Linux 发行版；使用[scratch](https://hub.docker.com/_/scratch)空白镜像基础上构建。

       

   

# 容器操作

以下示例代码中的`<container>`表示某个容器，可以使用容器的ID或容器的名字。

## 查看

```shell
#查看正在运行的容器
docker ps
docker container ls
#查看所有容器
docker ps -a
docker container ls -a
#容器详情
docker inspect <container>
#容器日志
docker logs -f <container> #-f持续输出
```



## 创建

```shell
#创建容器
docker create -t archlinux

#创建并运行
docker run -itd archlinux

#使用其他创建容器时的常用参数
docker run -it --rm --name 容器名 --hostname 主机名 -v 宿主机目录:容器目录:读写权限 -p 容器端口:宿主机器端口 --network 网络 archlinux 要执行的命令

# 以centos 镜像为基础创建一个名为webserver的容器
# 主机名webserver 以只读权限挂载宿主机的/home/data到容器的/srv/web 使用主机网络 创建成功后立即进入bash shell
docker run -itd --name webserver --hostname webserver -v /home/data:/srv/web:ro --network host --restart always centos
```



`docker create`或`docker run`：create是创建一个容器，run是创建一个容器（并启动）执行指定命令，二者大部分参数一致。



容器的生命周期是由其入口点（ENTRYPOINT）或命令（CMD）决定的。当入口点或命令执行结束（主线程结束）时容器后就会退出。

如果没有明显要执行的入口点命令，可使用`-itd` 选项组合使容器后台运行，运行一个交互式shell并保持 STDIN 打开，后续可登入容器的shell交互式环境。



常用参数：

- `-i` 或 `--interactive`：保持 STDIN 开放，通常用于交互式会话，例如 shell 提示符。
- `-t` 或 `--tty`：为容器分配一个伪终端，创建一个可以交互的环境。
- `-d` 或 `--detach`：在后台运行容器。


- `--name 容器名` 参数给容器命名

  

- `--ip 地址` 指定IP地址

- 端口映射


  - `-P 容器端口`                      随机将宿主机某个端口与容器端口映射

  - `-p 宿主机端口:容器端口`  指定宿主机端口和容器端口的映射

    不指定协议时，映射端口仅支持tcp，可使用以下方式指定其他协议，如：`-p 22:22/udp`


- `-h 主机名`或`--hostname 主机名 ` 设置主机名

- `--network 网络类型`  指定[网络](#网络)类型（默认值为`default`）


- `-w 工作目录`  工作目录


  - `--mount type=bind,source=宿主机目录,target=容器内目录`

- `-v 宿主机目录:容器目录`  挂载宿主机的卷到容器中（使用绝对路径）

  还可以在容器目录后加上`:`然后指定访问权限

  - `r`读
  - `w`写
  - `o`配合读写一起使用——如`ro`只读


- `--privileged` 赋予容器外部root权限（注意安全风险）
- `-u` 用户名或UID


- `--rm` 使用后删除容器



资源配置（默认对容器资源无限制）

- 内存

  - `-m 内存大小`（或`--memory`）内存限额

  - `--memory-swap=内存大小`  内存+交换分区限额

    提示：指定了 `-m` 而不指定 `--memory-swap`，那么 `--memory-swap` 默认为 `-m` 的两倍。

  - `--vm 线程数`  启用指定个数的内存工作线程

  - `--vm-bytes 给定内存大小`  每个线程分配的内存大小

- cpu

  默认对容器无限制。

  - `--cpus=<N cpus>`  指定可使用的cpu资源数量（可使用小数）

    例如设置1，表示容器最多达到100%的cpu负载。

  - `--cpuset-cpus=<cpus index>`  指定固定的cpu

    例如：`--cpuset-cpus="0,1"` 表示cpu0和cpu1

  - `-c 权重值`（或`--cpu-share`）容器使用cpu的权重值（有多个容器运行才有意义）

    默认值是1024，当有两个容器而只有一个cpu（或者指定到一个cpu上），各设置512表示各自权重50%

- IO

  默认情况下，所有容器能平等地读写硬盘

  - 设置权重：` --blkio-weight 权重值`  容器读写的权重值 默认500

  - 设置bps或iops

    bps： byte per second，每秒读写的数据量。
    iops ：io per second，每秒 IO 的次数。

    - `--device-read-bps`和`--device-write-bps`
    - `--device-read-iops`和`--device-write-iops`

    使用示例：

    ```shell
    docker run -it --device-write-bps /dev/sda:30MB centos  #限制sda写入速度30MB每秒
    ```

  

- 容器自启动机制(restart policy)

  在创建容器时通过`--restart`指定相应的值：

  - `no`  默认值，不自动重启容器。
  - `on-failure`  容器发生error而退出(容器退出状态不为0)重启容器。
    - `on-failure:3`  失败尝试3次
  - `unless-stopped`  容器已经stop或Docker stoped/restarted的时候才重启容器。
  - `always`  容器已经stop掉或Docker stoped/restarted的时候才重启容器，手动stop除外。

其他参数参见后文相关叙述。



## 修改和删除

```shell
#重命名容器
docker rename 原名 新名

#删除一个容器
docker rm 容器名或容器ID

#强制删除正在运行的容器 
docker rm -f 容器名或容器ID

#删除所有容器
docker rm `docker ps -a -q`

#删除所有处于退出状态的容器
docker container prune
```



## 启动、运行、重启和停止

对已经创建的容器执行启动、进入、重启和停止等操作

```shell
#docker [参数] 操作容器的命令  容器名或容器id
#启动一个容器
docker start <container>

#启动一个容器并直接进入
docker start -a <container> #-a或--attach

#进入已经运行的容器的默认shell
docker attach <container>

#执行容器中的命令
#-i交互式操作 -t启用tty  -w工作目录  -u用户
docker exec -it <container> bash   #进入容器的交互式bash
docker exec <container> <command>  #在容器中执行某条命令
docker run <container> <command>

#重启
docker restart <container>

#暂停pause和恢复unpause
docker pause <container>  

#停止
docker stop <container>
```



## 导入和导出容器

[docker import](https://docs.docker.com/engine/reference/commandline/import/)

> Import the contents from a tarball to create a filesystem image

[docker export](https://docs.docker.com/engine/reference/commandline/export/)

> Export a container’s filesystem as a tar archive

```shell
#docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
docker import http://example.com/exampleimage.tgz
cat exampleimage.tgz | docker import - exampleimagelocal:new
#从本地目录导入
sudo tar -c . | docker import - exampleimagedir
#导入时添加commit message
cat exampleimage.tgz | docker import --message "New image imported from tarball" - exampleimagelocal:new

#docker export [OPTIONS] CONTAINER
#导出目标可以使用 >  或 --output（或-o）两种方式指定
docker export red_panda > latest.tar      #以容器名字导出
docker export f299f451773a --output="latest.tar"   #以容器id导出
```



# 网络

[docker network](https://docs.docker.com/network/)

docker安装后默认创建有bridge、host和none网络。

可使用`docker network ls`查看存在的网络。建容器时可以使用`--network`参数指定网络类型。

用户也可以自定义创建bridge、macvlan或overlay驱动类型的网络。

```shell
#创建网络
docker network create --driver bridge br0 --subnet 172.16.0.0/16 --gateway 172.16.0.251
```

`-d`或`--driver`指定网络类型，`--subnet`指定子网，`gateway`指定网关。

- bridge

  桥接网络，**默认网络类型**，默认使用docker安装时创建的桥接网络（可使用可以创建查看其配置）。每次docker容器重启时，会按照顺序从网桥配置的子网段中获取IP地址（默认网桥的网段为`172.17.0.0/16`）。

- host  容器与宿主机共用一个网络环境，容器与外接网络直连。 这种情况下不需要使用ip参数，指定port映射等。

- overlay  将多个docker守护程序连接在一起，并使 swarm 服务能够相互通信。

- macvlan  允许您向容器分配MAC地址，使其在网络上显示物理设备。

- none  无网络



# 文件读写

## 宿主机和容器之间复制文件

```shell
docker cp <宿主机文件路径> <容器名>:<容器内目标路径>
docker cp <容器名>:<容器内目标路径> <宿主机路径>
```



# 相关资源

## 自动更新容器[Watchtower](https://containrrr.github.io/watchtower/)

```shell
# 自动更新
 docker run -d \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower \
    --cleanup --interval 3600000 #container1 container2
```

- --cleanup清理老旧镜像  （可选）
- --interval 每隔n秒检测一次  （可选）

- 在末尾可以加上容器名字以只检测指定的容器（一个或多个）