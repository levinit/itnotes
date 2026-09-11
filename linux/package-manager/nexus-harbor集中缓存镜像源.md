# Nexus 与 Harbor 集中缓存镜像源

在内网或受限网络环境中，为避免全量同步公共源带来的大量冷门包冗余，可采用集中式代理缓存（Proxy Cache）的方式搭建中间镜像站：客户端请求时才按需抓取并永久保存在内网。

本文记录基于 **Nexus**（针对 YUM、APT、PyPI 等常规包）与 **Harbor**（针对 Docker / OCI 容器镜像）搭建集中代理缓存镜像源的配置方法，并包含大规模并发拉取时的 Dragonfly P2P 传输加速方案。

[TOC]

---

## 1. 架构拓扑

```
        外网官方源 (Internet)
  (Rocky YUM / Ubuntu APT / PyPI / DockerHub)
                     │
                     │ (DMZ 受控单向出口 / 代理网关)
                     ▼
    ┌────────────────────────────────────────────────────────┐
    │                  隔离内网基础服务区                    │
    │                                                        │
    │  ┌───────────────────────┐   ┌──────────────────────┐  │
    │  │     Nexus OSS 统一     │   │      Harbor 镜像     │  │
    │  │    制品库 (按需代理)   │   │     仓库 (安全审计)  │  │
    │  │  (YUM / APT / PyPI)   │   │        (OCI)         │  │
    │  └───────────┬───────────┘   └──────────┬───────────┘  │
    └──────────────┼──────────────────────────┼──────────────┘
                   │                          │
                   └────────────┬─────────────┘
                                │ P2P 块级分发
                                ▼
    ┌────────────────────────────────────────────────────────┐
    │               Dragonfly P2P 分发集群                   │
    └───────────────────────────┬────────────────────────────┘
                                │ 节点间对等互传
                                ▼
    ┌────────────────────────────────────────────────────────┐
    │                 计算节点与工作站集群                   │
    │                                                        │
    │  ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐ │
    │  │ Compute Node 01 │ │ Compute Node 02 │ │ ... Node N│ │
    │  │  (dfdaemon 代理) │ │  (dfdaemon 代理) │ │           │ │
    │  └─────────────────┘ └─────────────────┘ └───────────┘ │
    └────────────────────────────────────────────────────────┘
```

* **按需拉取缓存 (Pull-Through Cache)**：客户端请求某个软件包时，代理服务穿透网关下载并持久化在内网，后续请求直接命中内网缓存。
* **P2P 并发加速**：节点拉取大体积镜像或文件时，数据块在局域网内节点间并行互传，降低中央服务器网卡带宽压力。

---

## 2. 统一包代理配置 (Sonatype Nexus OSS)

Nexus OSS 用于集中代理与缓存操作系统仓库 (YUM/APT) 与编程语言仓库 (PyPI/NPM/Go)。

### 2.1 部署配置 (Docker Compose)

```yaml
version: '3.8'
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: always
    ports:
      - "8081:8081"
    volumes:
      - /data/nexus-data:/nexus-data
    environment:
      - INSTALL4J_ADD_VM_OPTIONS=-Xms4g -Xmx4g -XX:MaxDirectMemorySize=2g
```

### 2.2 仓库类型与规划
针对每种包格式，通常在 Nexus 中规划三类仓库：
1. **Proxy（代理仓库）**：配置外网源地址。首次拉取时下载并本地缓存，未拉取的包不占用磁盘。
2. **Hosted（宿主仓库）**：存放内部编译的私有 RPM/DEB 包、专用工具及内部脚本库。
3. **Group（组合仓库）**：将 Proxy 与 Hosted 聚合为一个单一访问入口，提供给客户端使用。

### 2.3 客户端使用配置

#### YUM / DNF 客户端配置 (`/etc/yum.repos.d/internal.repo`)
```ini
[nexus-baseos]
name=Rocky Linux $releasever - BaseOS (Nexus Proxy)
baseurl=http://192.168.1.10:8081/repository/yum-rocky-baseos/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
```

#### Python pip 客户端配置 (`/etc/pip.conf`)
```ini
[global]
index-url = http://192.168.1.10:8081/repository/pypi-group/simple
trusted-host = 192.168.1.10
```

---

## 3. 私有容器镜像中心配置 (Harbor)

Harbor 用于管理集群中的 Docker / OCI 镜像及 Apptainer/Singularity 基础镜像。

### 3.1 核心功能与配置
* **代理缓存项目 (Proxy Cache Project)**：
  * 在 Harbor 中新建项目并开启 `Proxy Cache`，关联上游公网 Registry。
  * 客户端直接通过 `192.168.1.10/proxy-hub/library/rockylinux:9` 拉取，Harbor 自动拉取并固化到内网。
* **漏洞扫描集成 (Trivy)**：
  * 开启 Trivy 自动扫描，配置安全策略，阻断包含高危漏洞的镜像在生产集群中被拉取运行。
* **离线环境复制 (Replication)**：
  * 处于物理完全隔离的网络时，可在过渡环境通过离线 tar 包导入镜像，再通过 Harbor 的 Replication 策略批量同步至各个机房子节点。

---

## 4. 大规模并发 P2P 加速 (Dragonfly)

当数百台计算节点在同一时间初始化或拉取数十 GB 镜像时，中央镜像源单机网卡容易被打满排队。

### 4.1 工作机制
* **分块与调度**：文件或镜像层按块（如 4MB）切分，调度中心（Scheduler）记录各节点持有的数据块。
* **对等互传**：节点在下载的同时向同机架或同子网的相邻节点上传已有数据块，90% 以上的流量直接在节点间完成。

### 4.2 客户端接入 (`dfdaemon`)

在各计算节点启动轻量客户端 `dfdaemon`，并将容器运行时的镜像镜像加速地址（Registry Mirror）指向本地代理端口：

```json
{
  "registry-mirrors": ["http://127.0.0.1:65001"]
}
```

客户端拉取镜像的请求自动重定向至 Dragonfly P2P 网络，大幅缩短集群大规模初始化耗时。

---

## 5. 轻量化替代方案与维护

1. **小型纯 Debian/Ubuntu 集群的轻量缓存方案**：
   * 若集群以 Debian/Ubuntu 为主且规模较小，可使用轻量级工具 **`apt-cacher-ng`**。
   * 客户端只需在 `/etc/apt/apt.conf.d/01proxy` 中指定：
     ```ini
     Acquire::http::Proxy "http://192.168.1.10:3142";
     ```
     即可实现自动代理与缓存，无需单独维护 Java 运行环境。
2. **清理与存储策略**：
   * 在 Nexus 与 Harbor 中配置清理规则（Retention / Cleanup Rules），定期清理长周期未被访问的临时构建包与快照镜像，避免磁盘被历史包占满。
