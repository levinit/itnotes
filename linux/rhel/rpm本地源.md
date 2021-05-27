将某个目录（已经包含repodata信息）作为软件源，编写对应的repo文件，文件中的地址信息指向该软件源目录即可。

# 软件包来源

本地源的软件包一般来源：

- 发行版的系统镜像文件
- 同步自公共源
- 自行添加的软件包

## 系统镜像文件

挂载iso系统镜像文件（例如centos的everything镜像文件含有大量软件包），假如iso为`~/centos.iso`，挂载到`/srv/repo/iso`：

```shell
mkdir -p /srv/repo/iso
mount -o loop ~/centos.iso /srv/repo/iso
```

## 同步公共镜像源

1. 安装rsync

2. 同步源软件源

   这里以[中国科技大学开源软件镜像](https://mirrors.ustc.edu.cn/)站——https://mirrors.ustc.edu.cn/为例（参看中科大源[同步方法与注意事项](https://mirrors.ustc.edu.cn/help/rsync-guide.html)），将公共镜像源同步到`/srv/repo`下：

   ```shell
   rsync -avz rsync://rsync.mirrors.ustc.edu.cn/repo/centos/7.5.1804/ /srv/repo/
   ```

   如果不想同步所有的文件夹，可以使用排除参数：

   ```shell
   rsync -avz --exclude 'isos' rsync://rsync.mirrors.ustc.edu.cn/repo/centos/7.5.1804/ /srv/repo/
   ```

   如果要排除多个目录，可以指定一个排除文件

   ```shell
   rsync -avz --exclude-from=./exclude.list 'isos' rsync://rsync.mirrors.ustc.edu.cn/repo/centos/7.5.1804/ /srv/repo/
   ```

   排除文件`exclude.list`示例：

   ```shell
   EFI
   LiveOS
   images
   isolinux
   CentOS_BuildTag
   EULA
   GPL
   ```
   
   如果只想同步某些目录，使用包含参数`—include`和`--include-from`，使用类似上面所述排除方法。
   
   

## 包含rpm包的目录

将软件包放到指定目录，将该目录设置为软件源，下称该目录我软件源目录。

建立一个文件夹如`/srv/repo/rpms`，将软件包放到该目录下。

使用`createrepo`工具生成rpm包信息，存放到软件源根目录下的repodata子目录中信息：

```shell
#createrepo <目录名>
createrepo -v --basedir /srv/repo/rpms -d  /srv/repo/rpms
#或cd到rpms执行createrepo . 亦可
```

*createrepo会递归读取软件源目录的所有层级子目录的rpm信息，因此不必将所有rpm均放到软件源根目录下，可 创建子目录存放方便管理。*

当添加新的rpm包时，可使用`--update`参数更新信息文件：

```shell
createrepo -v --update /srv/repo/rpms
```



该软件源如果要通过网络协议让其他主机使用，可以搭建网络服务器（如http服务器、nfs服务器），确保该软件源目录可被其他主机以相关网络协议访问。

例如搭建web服务器，使用http协议为其他主机提供自建的软件源服务，其监听9999端口，`/srv`为web服务的根目录，那么`/srv/repo/rpms`的地址即是：`http://192.168.0.1:9999/repo/rpms`。

# repo文件

软件源信息的文件位于`/etc/yum.repos.d`下，扩展名为`.repo`，文件内容示例：

```shell
[local-repo]  #软件源名称 在该系统中 此名应该唯一
name=$releasever local repo #软件仓库的名称
baseurl=file:///srv/repo  #软件源地址
enabled=1  #是否启用  启用1  不启用0
gpgcheck=0  #gpg校验  校验1  不校验0
```

- baseurl支持4重格式：
  - 本地路径  `file:///路径`

    同时使用多个路径以空格隔开，例如在`mnt`下有`dvd1`和`dvd1`两个目录作为软件源：

    ```shell
    baseurl=file:///mnt/dvd1  file:///mnt/dvd2
    ```

  - http(s)协议地址  `https://地址`

  - ftp协议地址  `ftp://地址`

  - rsync协议  `rsync://地址`


- path代表baseurl值下面的子路径

  如果baseurl已经描述完整了路径，也可以省略path值。

# 使用源

将编写的repo文件放置到`/etc/yum.repos.d`下。

如果使用本地源而不连接外网，（CentOS）系统自带的repo无法使用，应当将这些repo文件移除（或修改扩展名，只有`.repo`结尾的文件才被使用）。

```shell
yum clean all  #清除原有repo缓存
yum makecache   #更新repo缓存
```

