ArchLinux aur打包简易指南

---

[TOC]

# PKGBUILD文件

> **PKGBUILD**是一个shell脚本，包含 [Arch Linux](https://wiki.archlinux.org/index.php/Arch_Linux) 在构建软件包时需要的信息。

可参考[archwiki-PKGBUILD](https://wiki.archlinux.org/index.php/PKGBUILD_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))，以及在[aur软件包](https://aur.archlinux.org/packages/)仓库中参照他人的PKGBUILD文件（在软件包详细资料的右侧有查看PKGBUILD的链接）。

`/usr/share/pacman/`亦有PKGBUILD模板，可选择一份，将其更名为PKGBUILD，根据情况编辑PKGBUILD内容。

示例：

```shell
# Maintainer: levinit
# Co-Maintainer: robertfoster

pkgname=edk2-avmf
pkgver=20200801
pkgrel=2
fedora_ver=34
pkgdesc="QEMU ARM/AARCH64 Virtual Machine Firmware (Tianocore UEFI firmware)."
arch=('any')  #x86_84
url="https://fedoraproject.org/wiki/Using_UEFI_with_QEMU"
license=('BSD') #GPL-3 | custom | Apache
#optional deps
optdepends=(
  "qemu: To make use of edk2 ovmf firmware"
  "qemu-arch-extra: QEMU for foreign architectures"
  "virt-manager: Desktop user interface for managing virtual machines"
)
#deps
#depends=()
#source contains files' urls
source=(
  "https://download-ib01.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/aarch64/os/Packages/e/edk2-aarch64-${pkgver}stable-${pkgrel}.fc${fedora_ver}.noarch.rpm"
  "https://download-ib01.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/aarch64/os/Packages/e/edk2-arm-${pkgver}stable-${pkgrel}.fc${fedora_ver}.noarch.rpm")
#files sha256sum
sha256sums=('0da4f919cdaede39119ff2ee98888d8e2d7723d18920250b5e3ecb7822913bb4'
            '2189bc4833fbb2f93e4e08c8602483d79f46f3bb08749e1a0610e4ed236ba5f9')
#postinstall script
install=${pkgname}.install
#how to install and hanle this pkg
package() {
  cd "${srcdir}"/usr/share/AAVMF
  ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
  cd "${srcdir}"
  cp -av usr "${pkgdir}"
}
```



# mkepkg配置文件（可选）

> `/etc/makepkg.conf` 是 makepkg 的主配置文件。
>
> 用户的自定义配置位于 `$XDG_CONFIG_HOME/pacman/makepkg.conf` 或 `~/.makepkg.conf`。

- 打包人信息

  找到`#PACKAGER="John Doe <john@doe.com>"`一行，去掉注释符号`#`（下同），修改`“John Doe <john@doe.com>”`为你的相关信息。

- 打包后的文件的输出位置

  `makepkg` 默认会在工作目录创建软件包，并把源代码下载到 `src/` 目录。

  可根据需要修改起默认位置，找到一下内容进行相关修改：

  - `#PKGDEST` 设置产生的包的路径
  - `#SRCDEST` 设置打包的源数据的路径
  - `SRCPKGDEST` 设置产生的源码包（可用`makdepkg -s`生成）的路径

- 打包临时目录

  找到`#BUILDDIR=/tmp/makepkg`去掉`#`，修改为目标目录。
  
  编译过程需要大量的读写操作，，将工作目录移动到 [tmpfs](https://wiki.archlinux.org/index.php/Tmpfs) 减少编译时间，例如`/tmp/makepkg`：
  
  `BUILDDIR=/tmp/makepkg makepkg`。

其余参考[archwiki-makepkg](https://wiki.archlinux.org/index.php/Makepkg_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E9.85.8D.E7.BD.AE)


# 构建和测试

在PKGBUILD文件目录下执行构建软件包的命令：

```bash
makepkg            #makepkg -f 可覆盖构建
pacman -U pkgname  #安装软件包
#makepkg -i        #相当于执行以上两步命令
```

如果因为依赖不满足而构建失败，可先检查其依赖情况：

```shell
namcap <pkgname>  #检测依赖情况 pkgname是软件包的名字
makepkg -s        #可自动安装依赖
#makepkg -S <lib-pkgname >  #手动安装依赖的软件包
```

*如有错误信息提示，根据提示修正PKGBUILD文件。*

# 提交到aur仓库

- 登记密钥

  [登录aur账号](https://aur.archlinux.org/),在账号设置里添加本机（用以打包aur的设备）的ssh公钥（如`~/.ssh/id_rsa.pub`），生成ssh密钥的方法：

  ```shell
  ssh-keygen
  ssh-keygen  -t  rsa   #或者-t指定加密类型如rsa、dsa
  ```

- 仓库连接

  进入到打包目录使用`git init`  初始化仓库。

  - 提交新的aur

    ```shell
    #在服务器上建立一个名为name.git的新仓库(name一般是软件包名)
    name=edk2-avmf
    git clone git+ssh://aur@aur.archlinux.org/$name.git
    #初始化仓库
    git init
    #连接远程仓库
    git remote add origin git+ssh://aur@aur.archlinux.org/$name.git
    ```

  - 连接已经存在的aur仓库

    克隆远程aur仓库到本地，然后手动合并：
    
    ```shell
    git clone <url>
    ```
    
    或者为当前git项目添加远程aur仓库：
    
    ```shell
    #连接仓库(name是该仓库名)
    git remote add origin git+ssh://aur@aur.archlinux.org/$name.git
    #从服务器同步内容
    git pull origin master
    ```
    
    注意：即使 AUR 中的软件包被删除，Git 仓库也不会删除（除非发起的删除申请被通过），所以你可能会发现 clone 一个 AUR 中还不存在的软件包时不会看到提示信息。

- 生成信息并上传

  注意：**原则上aur中只提供PKGBUILD文件和.SRCINFO文件，软件包相关资源应在PKGBUILD的source中提供URL，而不是上传到aur的git服务器。**

  ```shell
  updpkgsums     #生成校验码 如果不使用校验，跳过该步骤
  makepkg --printsrcinfo > .SRCINFO     #生成信息文件
  git add PKGBUILD .SRCINFO	# 提交变动到暂存区
  git commit -m 'some description'     #增加快照
  git push    #推送 
  ```

  注意：

  - 每次更新了软件包都需要重新生成校验码(sums)和信息文件（如果希望PKGBUILD文件的md5sum等加密方式的值为**SKIP**，则无需执行 ）。
  - aur的git服务器**不允许强制推送**，只能在最新快照上更新推送。
  - **每一次提交中都必须包含[.SRCINFO](https://wiki.archlinux.org/index.php/.SRCINFO)文件**，如果忘记在提交中包含`.SRCINFO`，即使稍后补上该文件，AUR也会拒绝接收推送请求，可以**增加一次新的commit**并推送到aur的git仓库来修正这个疏忽。 或者可以使用[git rebase](https://git-scm.com/docs/git-rebase) 中的 `--root` 选项或是 [git filter-branch](https://git-scm.com/docs/git-filter-branch) 中的 `--tree-filter` 选项。

