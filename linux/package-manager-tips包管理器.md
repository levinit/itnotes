[常见发行版不同包管理器常用命令对比](https://wiki.archlinux.org/index.php/Pacman_(简体中文)/Rosetta_(简体中文))

涉及到安装卸载锁定的操作一般需要root或sudo

# 禁止自动更新

```shell
systemctl disable --now packagekit
systemctl mask packagekit  #注销unit
```

恢复

```shell
systemctl unmask packagekit #恢复unit
systemctl enable --now packagekit
```



如果进行该服务后在 Debian类系统中执行`apt-get`产生类似错误：

> Error: GDBus.Error:org.freedesktop.systemd1.UnitMasked: Unit packagekit.service is masked.

是由`/etc/apt/apt.conf.d/20packagekit`导致的。因为在安装命令完成之后，会出触发特定的 PackageKit 钩子，由于禁用了服务而导致该错误，所以禁用该配置即可：

```
mv /etc/apt/apt.conf.d/20packagekit{,.disabled}
```

# 命令或文件等软件包来源

查看某个命令或库文件等来自哪个软件包

- pacman

  ```shell
  pacman -S pacman-contrib
  pacman -Fyy
  pacman -F <command or file-name> #查找 例如pacman -F ss
  ```

  

- yum/dnf

  ```shell
  yum provides <command or file-name>
  ```

  dnf将yum命令替换即可（下同）

  

- apt：apt-file和apt-cache

  ```shell
  apt install -y apt-file
  apt-file update #更新数据库
  apt-file search <command or apt-file
  
  apt-cache depends vim  #查看某个包所有依赖
  ```



# 仅下载不安装

多用于为其他设备提供离线安装。

建议在各个发行版的最小环境中（如centos的minimal）使用仅下载方式获取软件包及其依赖，避免某些依赖已经安装而被忽略下载（debian系）。

- yum/dnf

  `--downloadonly` 

  ```shell
  yum install -y --downloadonly --downloaddir=<dir-path> <pkgs>
  #对于已经安装的包需要使用reinstall代替install 否则被略过
  yum reinstall -y --downloadonly --downloaddir=<dir-path> <pkgs>
  ```

  如不指定`--downloaddir`默认下载到当前目录

- apt

  ```shell
  apt download <pkgs>  #无需root 只会下载软件包本身不包含依赖
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

  

# 软件包版本锁定

锁定已经安装的软件包，避免重要软件包被升级，例如内核。

## yum/dnf：yum-plugin-versionlock插件

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



## apt：apt-mark

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



# 升级略过指定软件包

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



# 安装/升级时指定源

- dnf/yum

  ```shell
  yum install --enablerepo=epel nginx
  ```

  

# 卸载指定源的所有包

- yum

  ```shell
  yum repo-pkgs <repo-name> remove  #yum repolist查看源列表
  ```

  