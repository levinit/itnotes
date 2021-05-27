

重要提示：如果是通过ssh连接远程主机并升级其openssh，请预先开启其他连接方式，以免因升级时ssh连接中断而无法连接到该主机。

# 依赖

具体版本参看站点上的readme。

- openssl-devel  openssl  (如果从包管理器中安装的版本不符合要求，需要下载源码编译安装)
- pam-devel
- gcc
- gcc-c++
- zlib-devel zlib zlib-static

# 编译

## openssl

**不要卸载原openssl，也不要将新编译的openssl的bin目录加入到`$PATH`**，只需要将新编译的openssl的lib加入到ld环境变量即可。

如果需要编译openssl，从https://www.openssl.org/下载源码。

```shell
openssl_install_dir=/opt/openssl
./config --prefix=$openssl_install_dir --shared  #如果不填加shared 在编译openssh中如果指定--with-ssl-dir会报错
make -j 4
make install  #将安装到/usr/local/bin

#需要将其写ld环境变量 以供后面编译openssh使用
echo "$openssl_install_dir/lib" > /etc/ld.so.conf.d/openssl.conf
ldconfig
```

## openssh

**不建议卸载原openssh。**

从https://www.openssh.com/站点下载ssh源码包。

```shell
#对于自行编译openssl，可能需要指定openssl相关参数
openssh_install_dir=/opt/openssh
prefix="--prefix=$openssh_install_dir"
./configure $prefix --sysconfdir=/etc/ssh   --with-ssl-dir=$openssl_install_dir --with-md5-passwords --with-pam
chmod 600 /etc/ssh/ssh_host*  #确保文件权限正确以保证后续make install
make -j 4
make install   #将安装到/usr/local/bin
ssh -V  #查看版本。
```

如果不指定prefix，其将安装到`/usr/local`下的目录中，无需再写入环境变量即可使用openssh相关命令。如果要移除编译的openssh，需要到`/usr/local/bin`删除相关文件（如ssh、scp、sftp等），到`/usr/local/sbin`删除`sshd`文件。

指定prefix为`/usr`，其将覆盖安装在原openssh所有文件（但不会覆盖`/etc/ssh`下已有配置文件）。可以通过包管理重新安装openssh快速还原成原来的openssh版本。

# sshd服务的启动

编译安装完毕后，使用systemctl无法启动sshd服务（`/var/lib/systemd/system/sshd.service`)，可使用以下方法解决：

- 更改`sshd.service`的type为forking（原为`notify`），修改部分如下：

  ```shell
  Type=forking
  PIDFile=/var/run/sshd.pid
  ExecStart=/usr/sbin/sshd $SSHD_OPTS
  ```

- 不使用该sshd.service启动sshd服务，用其他方法保证其自启动，例如：

  - 在`/etc/rc.local`中添加`/usr/sbin/sshd`（注意需要赋予`/etc/rc.d/rc.local`可执行权限，`/etc/rc.local`是其软连接）

  - crontab添加任务

    ```shell
    @reboot  /usr/sbin/sshd
    ```

- 为openssh打补丁，参看 [patch](https://salsa.debian.org/ssh-team/openssh/commit/fe97848e044743f0bac019a491ddf0138f84e14a)。

  重新编译安装

  

  如果prefix非`/usr`，安装完毕后，需要更新` /usr/lib/systemd/system/`下sshd相关文件中`sshd`的路径，例如默认编译安装位置为`/usr/local/sbin/sshd`（使用`which sshd`查看sshd的路径）。

