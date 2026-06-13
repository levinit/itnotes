# 简介

> [Podman](http://podman.io/) is a daemonless, open source, Linux native tool designed to make it easy to find, run, build, share and deploy applications using Open Containers Initiative ([OCI](https://www.opencontainers.org/)) [Containers](https://developers.redhat.com/blog/2018/02/22/container-terminology-practical-introduction/#h.j2uq93kgxe0e) and [Container Images](https://developers.redhat.com/blog/2018/02/22/container-terminology-practical-introduction/#h.dqlu6589ootw). 

参看RedHat文档[构建、运行和管理容器](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/assembly_starting-with-containers_building-running-and-managing-containers)



*pod的含义为豆荚，类似docker集装箱，是一个很形象的名字。*

> Podman使用libpod库管理整个容器生态系统，包括豆荚（pod）、容器、容器图像和容器卷。

[podman](https://docs.podman.io)兼容docker的大部分命令，将命令中的docker替换成podman即可。

podman计成 rootless ，它可以在没有 root 权限的情况下运行。

# 基本设置

一般的，在linux上安装podman后，全局配置文件目录为`/etc/containers`，仅作用于用户的配置文件目录为`~/.config/containers`。

## 镜像源

配置文件为`registries.conf`（TOML格式），示例：

```shell
#unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io"]
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry]]
prefix = "quay.io"
location = "quay.io"

[[registry]]
prefix = "ghcr.io"
location = "ghcr.io"
```



## 存储位置

配置文件为storage.conf可定义存储位置。默认情况：

- 对于root用户，镜像和容器等存储在`/var/lib/containers`

- 对于普通用户，镜像和容器等存储在`~/.local/share/containers`

  



## 用户id映射

如果以普通用户运行容器，且在容器中运行了需要使用主机的用户或组身份验证的应用程序，那么容器中必须存在与主机上相同UID和GID的用户或组。

`useradd` 命令会在 `/etc/subuid` 和 `/etc/subgid` 文件中自动设置可访问用户和组 ID 的范围。

如果当前发行版的`useradd`不能实现自动设置，可使用以下方法为已有用户设置subuid和subid：

- `usermod`

  ```shell
  usermod --add-subuids <start>-<end> --add-subgids <start>-<end> <user>
  
  #例子：
  usermod --add-subuids 100000-165535 --add-subgids 100000-165535 user1
  ```

  *使用 65536 UID 和 GID 来最大限度地与现有容器镜像兼容，但这个数字可以设置得更小。*

  

- 编辑``/etc/subuid`和`/etc/subgid`，添加相同的行，示例：

  ```shell
  user1:10000000:65535  #表示从1000000开始后面的65535个数字
  ```
  修改了以上文件必须执行迁移操作：

  ```shell
  podman system migrate
  ```

  

在运行容器的命令中使用`--users=keep-id`可以保持容器中UID/GID与外部的一致性，也可以使用`--uidmap`和`--gidmap`选项手动映射容器中的用户或组到主机上的用户或组。



# 容器创建

参考docker的build。

注意：Podman 默认使用 `crun` 作为其 OCI 运行时，Docker file中如果使用`RUN`指令则需要 `runc`。可以通过编辑 `/etc/containers/containers.conf` 文件来更改运行时。



通过dockerfile或者podman的文件（yaml格式）创建：

```shell
podman build -t <名字> -f <文件路径>
```



# 容器编排

- `podman generate`从容器生成编排文件

  - spec 生成json格式，符合 [Open Container Initiative (OCI) runtime specification](https://github.com/opencontainers/runtime-spec) ）

    `podman generate spec <container> > container.json`

  - kube 生成yaml格式，兼容kubernets

    `podman generate kube <container> > mycontainer.yaml`

- `podman play`使用编排文件运行容器

  ```shell
  podman play kube <compose-file>  #可以是yaml或json的编排文件
  ```

  注意：`podman play kube` 命令主要是用于处理 Kubernetes 兼容的 YAML 文件的，对于 OCI 兼容的 JSON 文件，可能需要一些额外的处理。

  
