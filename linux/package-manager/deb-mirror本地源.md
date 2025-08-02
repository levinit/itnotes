1. 将deb包存放到指定目录中，例如`/srv/debs`

2. 在deb包存放目录中生成Packages文件（该文件包含软件包信息，如包名，md5等）

3. 在`/etc/apt/source.list.d/`下添一个后缀为`.list`文件，指定本地镜像源等位置，格式：

   ```shell
   #deb   [trusted=yes]  deb包存放目录的父目录的uri deb目录/
   deb [trusted=yes] file:///srv debs/
   #deb [trusted=yes] http:/// debs/   #此debs目录存放在web根目录下
   ```

   `[trusted=yes]`信任该源，否则还需要生成gpg密钥。

   deb包存放目录的父目录的uri可以是本地路径（以`file://`开始）或其他网络协议的路径（例如`http://127.0.0.1:8000`)
   
   

---

```shell
mirror_dir=/srv/mirror/ubuntu2004/

apt-get install dpkg-dev

cd $mirror_dir
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release
#gpg gen-key
#gpg --clearsign -o InRelease Release
#gpg --armor --detach-sign -o Release.gpg Release # 生成 Release.gpg
#gpg --clearsign -o InRelease Release # 生成 InRelease
chown -R _apt $mirror_dir

echo "deb [trusted=yes] file://$mirror_dir /" > /etc/apt/source.list.d/debs.list
apt-get update
```

