[常见发行版不同包管理器常用命令对比](https://wiki.archlinux.org/index.php/Pacman_(简体中文)/Rosetta_(简体中文))

涉及到安装卸载锁定的操作一般需要root或sudo。

# 包管理器一览

| 包管理器命令 | 软件包类型(扩展名)       | 应用的系统                                                   |
| ------------ | ------------------------ | ------------------------------------------------------------ |
| yum/dnf      | .rpm                     | RHEL系，包括CentOS、Rocky、Fedora、Anolis （龙蜥）、openEuler（欧拉）等 |
| zypper       | .rpm                     | Slackware系，SLES系（包括OpenSUSE）                          |
| apt          | .deb                     | Debian系，包括Ubuntu、Deepin（深度）、Mint等                 |
| pacman       | .pkg.tar.xz/.pkg.tar.zst | Arch系，包括Manjaro等                                        |



# 软件源操作

## 安装/升级时指定源

- dnf/yum

  ```shell
  #启用某个源
  yum install --enablerepo=epel nginx
  
  #禁止从某个源中索引
  yum install --disablerepo=update python 
  ```




## 缓存管理

包管理器可以将软件源的信息缓存在本地，如果不指定更新缓存的相关选项，包管理器默认会



# 查询软件包依赖

## 依赖关系

查询某个软件包依赖于哪些软件包

- pacman

  ```shell
  pactree <pkg name> #pactree 来自于pacman-contrib包
  pacman -Qi <pkg name>
  ```

- yum/dnf（rpm）

  ```shell
  yum deplist <pkg name>
  ```

- apt（deb）

  ```shell
  apt depends <pkg name>
  dpkg -I <pkg name>
  
  #递归获取包依赖信息 需要安装apt-rdepends
  apt-rdepends <pkg name>
  ```



## 被依赖关系

查询某个软件包被哪些软件包依赖。

- yum/dnf

  ```shell
  dnf -q --whatrequires <pkg name>
  ```



# 查询包中所有文件的安装路径

- pacman

  ```shell
  pacman -Ql <pkg-name>
  ```

- apt

  ```shell
  dpkg -S <pkg-name>
  ```

- dnf

  ```shell
  dnf repoquery --list <pkg-name>
  ```



# 查询命令/文件所属的软件包

查看某个命令或文件等来自哪个软件包

- pacman

  ```shell
  pacman -S pacman-contrib
  pacman -Fyy
  pacman -F <command or file-name> #查找 例如pacman -F ss
  ```

  

- yum/dnf

  ```shell
  yum provides <command or file-name>
  yum provides vncserver  #查询vncserver来自哪个包
  ```

  dnf将yum命令替换即可（下同）

  

- apt：apt-file和apt-cache

  ```shell
  apt install -y apt-file
  apt-file update #更新数据库
  apt-file search <command or apt-file>
  
  apt-cache depends vim  #查看某个包所有依赖
  ```



# 仅下载不安装软件包

*下载的软件包可为其他设备提供离线安装。*

- yum/dnf

  ```shell
  yumdownloader <pkgs>
  yumdownloader --resolve <pkgs> <dir>
  dnf download <pkgs>
  ```

  两者均支持这些常用参数：

  - `--destdir=DESTDIR`  指定下载目录（默认当前目录）

  - `--urls`      仅列出下载地址
  - `--resolve`     同时下载依赖包
  - `--source`      下载源码
  - `--archlist=ARCHLIST`  指定要下载特定架构（一种或多种）的包

  

  另也可以使用yum install`--downloadonly`只下载不安装，`--downloaddir=<path>`下载到指定目录，**但是该方式会忽略下载已经安装在系统中的包** ，对于已经安装的包需要使用reinstall代替。

  ```shell
  yum install -y --downloadonly --downloaddir=<dir-path> <pkgs>
  ```

  

- apt

  ```shell
  apt download <pkgs>
  
  #获取依赖
  deps=$(apt-cache depends vim|grep Depends|awk -F ":" '{print $2}')
  #下载依赖
  apt download $deps
  
  #下载软件本身及所有依赖到当前目录
  #对于已经安装的包需要使用--reinstall否则被忽略
  #但是如果其依赖包已经被安装了仍然会被忽略
  apt --reinstall --download-only -o Dir::Cache="/tmp"     -o Dir::Cache::archives="./" install <pkgs>
  ```
  
  *可以编写程序获取依赖的依赖以下载齐全所有依赖。*
  



# 禁止自动更新

## 禁止packagekit更新

packagekit守护进程会检测更新。

禁止packagekit更新服务：

```shell
systemctl disable --now packagekit
systemctl mask packagekit  #注销unit
```

恢复packagekit更新服务：

```shell
systemctl unmask packagekit #恢复unit
systemctl enable --now packagekit
```



如果进行该操作后在 Debian类系统中执行`apt-get`产生类似错误：

> Error: GDBus.Error:org.freedesktop.systemd1.UnitMasked: Unit packagekit.service is masked.

这是由`/etc/apt/apt.conf.d/20packagekit`导致的。

因为在apt安装命令完成之后，会出触发特定的 PackageKit 钩子，由于禁用了服务而导致该错误，所以禁用该配置即可：

```shell
mv /etc/apt/apt.conf.d/20packagekit{,.disabled}

dpkg-divert --divert /etc/PackageKit/20packagekit.distrib --rename  /etc/apt/apt.conf.d/20packagekit
```



如果使用GNOME桌面，安装并启用了gnome-software（后端也是使用packagekit）自动更新，可使用以下方式之一禁用：

- 在该GUI应用的设置中关闭更行

- 更改`/etc/xdg/autostart/gnome-software-service.desktop`配置文件

  - 将该文件改名，后缀不为.desktop即可，也可以直接删除该文件。

  或者

  - 编辑`/etc/xdg/autostart/gnome-software-service.desktop`禁用更新，将文件中下面的行的true改成false：

    ```shell
    XGNOME-Autostart-enabled = false  #原来是true，改成false
    ```



## 更新时略过指定软件包

被版本锁定的软件包会被忽略，不再赘述。

- yum/dnf

  `-x`或`--exclude`

  ```shell
  yum update --exclude=kernel* --exclude=php*
  yum -x firefox update
  ```

  或者在`/etc/yum.conf`中添加`exclude`行，示例：

  ```ini
  #其余内容省略
  exclude=kernel* redhat-release* php* mysql* httpd* *.i686 
  ```



## 锁定指定软件包版本

锁定已经安装的软件包，避免重要软件包被意外升级，例如内核。



### yum/dnf

- yum-plugin-versionlock插件

  ```shell
  yum install -y yum-plugin-versionlock
  	
  #yum versionlock add pkg-name
  yum versionlock add kernel  #锁定当前版本内核
  yum versionlock list        #查看已经锁定软件包
  
  yum versionlock delete '0:kernel-3.10.0-957.5.1.el7.*'  #解锁示例
  yum versionlock delete vim*   #可使用通配符
  #yum versionlock clear       #解锁所有
  ```

  被锁定的包，将不会出现在yum search列表中，yum安装时也会被忽略而提示不存在。



### apt：apt-mark

```shell
#apt-mark hold <PACKAGE_NAME>  #锁定软件版本 可以指定多个
apt-mark hold linux-image-$(uname -r)  #锁定当前内核
apt-mark showhold             #显示锁定的软件包
apt-mark unhold PACKAGE_NAME  #解锁 可以一次指定多个包。
```

一些不遵守规则的图形包管理器，会忽略 apt-mark 锁定的软件，可以：

```shell
echo "PACKAGE hold" | dpkg --set-selections     #锁定
dpkg --get-selections | grep hold               #显示已锁定列表
echo "PACKAGE install" | dpkg --set-selections  #解锁
```


# 清理无用软件包

- yum

  ```shell
  #卸载指定源中的软件包
  yum repo-pkgs <repo-name> remove  #yum repolist查看源列表
  
  #package-cleanup 由yum-utils提供
  #清理孤儿包
  package-cleanup --orphans
  #清理旧内核
  package-cleanup --oldkernels --count=1
  
  yum clean all #清理下载的软件包数据缓存
  ```

- apt

  ```shell
  #卸载并清理
  apt purge <pkg-name>
  
  #清理孤儿包 需要安装deborphan
  #deborphan列出孤儿包 然后卸载之 可使用以下命令
  while true; do
    [[ -z $(deborphan) ]] && break
    apt purge $(deborphan)
  done
  ```

  

- pacman

  ```shell
  pacman -Rscn <pkg-name> #卸载软件包及其依赖
  
  #清理孤儿包
  pacman -Rscn $(pacman -Qtdq)
  
  #清理软件包缓存
  paccache -r  #-k 2 2
  ```
