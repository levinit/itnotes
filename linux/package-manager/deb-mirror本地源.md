将某个目录（已包含 Packages / Release 索引信息）作为 DEB 软件源，编写对应的 `.list` 或 `.sources` 文件，文件中的地址信息指向该软件源目录即可。

本地源的软件包一般来源：

- 发行版的系统 ISO 镜像文件
- 同步自公共镜像源（如中科大源、清华源）
- 自行编译或打包的私有 DEB 软件包

---

## 1. ISO 镜像创建本地源

挂载系统 ISO 镜像文件（例如 Ubuntu Server 或 Debian DVD ISO 包含大量核心软件包），假设镜像为 `~/ubuntu-22.04-live-server-amd64.iso`，挂载到 `/srv/repo/iso`：

```shell
mkdir -p /srv/repo/iso
mount -o loop ~/ubuntu-22.04-live-server-amd64.iso /srv/repo/iso
# 持久化挂载（编辑 /etc/fstab）：
#/srv/repo/ubuntu.iso  /srv/repo/iso   iso9660  loop,defaults  0  0
```

挂载完成后，在 `/etc/apt/sources.list.d/` 下创建源配置文件，如 `local-iso.list`：

```shell
# 针对标准 ISO（内含 dists/ 和 pool/ 结构）：
deb [trusted=yes] file:///srv/repo/iso/ jammy main restricted
```

*注：如果挂载的 ISO 结构较为特殊（只有单个 pool 目录或扁平 deb 目录），可参考下文扁平源配置。*

更新 APT 缓存：

```shell
apt-get update
```

---

## 2. 同步公共镜像源

当需要搭建供内网多台主机共享的局域网全量镜像站时，可从上游公共镜像站同步。

### 方式 A：使用 rsync 同步

以[中国科技大学开源软件镜像站](https://mirrors.ustc.edu.cn/)为例，同步指定发行版目录到本地 `/srv/mirror/ubuntu/`：

```shell
# 安装 rsync
apt-get install -y rsync

# 同步指定发行版仓库（排除源码包和调试符号以节省空间）
rsync -avz --progress --delete \
  --exclude "source/" \
  --exclude "*.tar.gz" \
  --exclude "*.dsc" \
  --exclude "debug/" \
  rsync://rsync.mirrors.ustc.edu.cn/repo/ubuntu/ /srv/mirror/ubuntu/
```

可配合编写 `exclude.list` 过滤不需要的架构（如 `*arm64*`、`*s390x*`、`*ppc64el*` 等）：

```shell
rsync -avz --progress --delete --exclude-from=/path/to/exclude.list \
  rsync://rsync.mirrors.ustc.edu.cn/repo/ubuntu/ /srv/mirror/ubuntu/
```

### 方式 B：使用 debmirror 专用工具

`debmirror` 是 Debian/Ubuntu 官方推荐的镜像同步工具，支持按架构、发行版代号与分段精准同步：

```shell
apt-get install -y debmirror

debmirror /srv/mirror/ubuntu \
  --arch=amd64 \
  --dist=jammy,jammy-updates,jammy-security \
  --section=main,restricted,universe,multiverse \
  --host=mirrors.ustc.edu.cn \
  --method=http \
  --root=ubuntu \
  --progress \
  --no-source \
  --nocleanup
```

---

## 3. 自建 DEB 软件源

下载或内部打包的 DEB 文件存放到指定目录，将该目录制作成可供 APT 索引的软件源。

### 简易扁平源（适用于少量包快速分发）

1. 创建存放目录并将 deb 包放入其中：

   ```shell
   mkdir -p /srv/debs
   cp *.deb /srv/debs/
   ```

2. 安装 `dpkg-dev` 工具：

   ```shell
   apt-get install -y dpkg-dev
   ```

3. 扫描目录并生成 `Packages.gz` 索引文件：

   ```shell
   cd /srv
   # dpkg-scanpackages <deb所在相对目录> /dev/null | gzip -9c > <deb所在目录>/Packages.gz
   dpkg-scanpackages debs /dev/null | gzip -9c > debs/Packages.gz
   ```

4. 客户端配置：

   在 `/etc/apt/sources.list.d/local-debs.list` 添加（扁平源末尾直接跟目录相对路径）：

   ```shell
   deb [trusted=yes] file:///srv/ debs/
   ```

   执行 `apt-get update` 即可安装。

---

### 标准结构软件源（推荐，支持 Release 索引与多架构）

标准 DEB 源具有规范的组件与 Release 签名体系。

1. 建立符合 Debian 规范的目录层级：

   ```shell
   mkdir -p /srv/repo/debian/dists/stable/main/binary-amd64
   mkdir -p /srv/repo/debian/pool/main
   
   # 将 deb 包放入 pool/main 目录
   cp *.deb /srv/repo/debian/pool/main/
   ```

2. 生成 `Packages` 与 `Release` 索引：

   ```shell
   cd /srv/repo/debian
   
   # 生成 Packages 和 Packages.gz
   apt-ftparchive packages pool/main > dists/stable/main/binary-amd64/Packages
   gzip -k -f dists/stable/main/binary-amd64/Packages
   
   # 生成 Release 文件
   apt-ftparchive release dists/stable > dists/stable/Release
   ```

3. （可选）为仓库执行 GPG 签名：

   如需正式分发避免客户端配置 `trusted=yes`，可使用 GPG 私钥签名：

   ```shell
   # 生成 InRelease（内联签名）与 Release.gpg（分离签名）
   gpg --clearsign -o dists/stable/InRelease dists/stable/Release
   gpg -abs -o dists/stable/Release.gpg dists/stable/Release
   
   # 导出公钥给客户端导入
   gpg --armor --export <YOUR_KEY_ID> > /srv/repo/debian/repo.gpg.key
   ```

---

## 4. 网络共享与分发

将本地构建的源目录通过 Web 服务向局域网其他节点分发。

例如使用轻量 Web 服务（如 Nginx、Caddy 或 Python）：

```shell
# 测试分发：使用 Python 快速启动 HTTP 服务
cd /srv/repo/debian
python3 -m http.server 8080
```

生产环境中推荐使用 Nginx 托管 `/srv/repo/` 目录。其他客户端配置示例：

- **免密模式**（局域网内部开发测试）：

  ```shell
  echo "deb [trusted=yes] http://192.168.1.100:8080/ stable main" > /etc/apt/sources.list.d/myrepo.list
  ```

- **GPG 安全认证模式**（推荐）：

  ```shell
  # 客户端导入服务端公钥
  curl -fsSL http://192.168.1.100:8080/repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/myrepo.gpg
  
  # 配置 signed-by 签名来源
  echo "deb [signed-by=/etc/apt/keyrings/myrepo.gpg] http://192.168.1.100:8080/ stable main" > /etc/apt/sources.list.d/myrepo.list
  ```

---

## 5. APT 软件源配置语法详解

### 传统单行格式（One-line-style，`.list` 文件）

文件位于 `/etc/apt/sources.list` 或 `/etc/apt/sources.list.d/*.list`，单行格式规范：

```text
deb [选项1=值1 选项2=值2] URI 发行版代号 组件1 组件2 ...
```

- **类型**：`deb`（二进制二进制包仓库）或 `deb-src`（源码仓库）。
- **常用选项 `[...]`**：
  - `trusted=yes`：跳过 GPG 签名校验（内网简易源常用）。
  - `arch=amd64,arm64`：限制仅拉取指定 CPU 架构的索引与包。
  - `signed-by=/path/to/key.gpg`：指定校验该源 Release 签名的专用公钥文件（现代推荐标准）。
- **URI**：支持 `file:///`（本地）、`http://`、`https://`、`ftp://`。
- **发行版代号（Suite / Codename）**：如 `jammy`、`bookworm`、`stable`。在扁平源中也可以使用相对目录并以 `/` 结尾。
- **组件（Component）**：如 `main`（自由软件）、`restricted`、`universe`、`multiverse`。

### 现代 DEB822 格式（`.sources` 文件）

Ubuntu 24.04+ 及现代 Debian 默认采用更易读的 RFC822 字段格式（`/etc/apt/sources.list.d/*.sources`）：

```text
Types: deb
URIs: http://192.168.1.100:8080/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/myrepo.gpg
Architectures: amd64
```
