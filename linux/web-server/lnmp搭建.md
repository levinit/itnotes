 部署lnmp环境

[TOC]

LNMP（linux,nginx,mariadb,php）部署，以下默认在root权限下操作，以centos７为例。

# 安装

- 安装nmp(nginx-mariadb-php)

`yum install nginx mariadb-server php php-fpm`

- 设置开机启动并立即启动服务：

`systemctl enable nginx mariadb php-fpm && systemctl start nginx mariadb php-fpm`

- 可安装phpmyadmin方便管理mariadb数据库：

`yum install phpMyAdmin`

# 配置

## mariadb配置

`mysql_secure_installation`

回车>根据提示输入Y>输入2次密码(不建议无密码)>回车>根据提示一路输入Y>最后出现：Thanks for using MariaDB!

## php配置

- 修改php-fpm的执行用户为nginx组的nginx（默认为apache组的apache）

  编辑/**etc/php-fpm.d/www.conf**，修改用户名和组：

  ```shell
  user = nginx #修改用户为nginx
  group = nginx #修改组为nginx

  #...
  #取消以下行的注释以启用 php-fpm 的系统环境变量
  env[HOSTNAME] = $HOSTNAME
  env[PATH] = /usr/local/bin:/usr/bin:/bin
  env[TMP] = /tmp
  env[TMPDIR] = /tmp
  env[TEMP] = /tmp
  ```

- 将储存php会话(session)记录文件夹权限赋给nginx组的nginx：

  ```shell
  mkdir -p /var/lib/php/session
  chown nginx:nginx /var/lib/php/session -R
  ```

  提示：自定义session路径，可在`/etc/php.ini`中找到`session.save_path`行，去掉其注释，指定自定义路径值

## nginx配置

在[/etc/nginx/nginx.conf](nginx/nginx.conf)使用`include conf.d/*.conf;` ，而从`/tec/nginx/conf.d`中引入各个配置文件。

在`/etc/nginx/conf.d/`中新建一个.conf文件，如website.conf，内容如下(据情况修改)：
```nginx
server{
    listen 80;
    server_name localhost;
    root /srv;
    index index.html index.php;
    charset utf-8,gbk;
    
    #为一个单页应用配置解析的示例
    location single_page_app {
        try_files $uri $uri/ /index.html;
    }
}
```

- listen 监听端口
- server_name 服务主机名
- root 根目录
- index 默认主页
- charset 编码格式（默认为utf8，中文gbk会乱码）

### php解析

在server中添加[php解析](nginx/conf.d/backend-parse/php)：

```nginx
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
    #fastcgi_pass 127.0.0.1:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

`fastcgi_pass` 根据php-fpm的配置文件中`listen`的值设置。

## phpmyadmin配置

将phpMyAdmin复制`/usr/share/phpMyAdmin`到web根目录`/srv/web`下，或者创建一个软链接：location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;  #127.0.0.1:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}

```shell
ln -s /usr/share/phpMyAdmin /usr/share/nginx/html
```

提示：有的发行版中，通过包管理安装的phpmyadmin位于`/usr/share/webapps`目录下。

### 权限问题

如果出现“403forbiden”，可能是该目录下没有index规定的默认主页文件（如index.html）或者nginx的执行用户不具有读取该目录的权限。可以用以下方法解决：

- 确保正确的读取权限

  文件644（rw-r--r--），文件夹755（rwx-r-xr-x）。假如nginx的执行用户是nginx组的nginx，web主目录是/srv/http，可使用以下命令修改所有权限：

  ```shell
  chown -R nginx.nginx /srv/http/
  find /srv/web/ -type f -exec chmod 644 {} \;
  find /srv/web/ -type d -exec chmod 755 {} \;
  ```


- 给予该用户相应权限，如将执行用户（假如执行用户名为nginx）加入具有读取该目录的用户组（假如该用户组是users）中`useradd -aG users nginx` 。
- 换用具有权限的用户执行，如换用root用户，在`/etc/nginx/nginx.conf`中将user改为root。

## 测试

配置完后，测试前重启所有服务：

`systemctl restart nginx mariadb php-fpm`

- 测试nginx：

`nginx -t`  

注意：该命令默认使用nginx的运行用户监测。

成功则返回如下内容：
>nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
>nginx: configuration file /etc/nginx/nginx.conf test is successful

- 登录网站测试，在浏览器打开域名或IP。

- 测试php解析：
  添加phpinfo.php测试文件到根目录，其内容为：

```php
<?php
phpinfo();
?>
```
保存后，打开网站，例如网址是xxx.com，浏览xxx.com/info.php，就可以看到php详情页面。

- mariadb测试，以主目录下phpMyAdmin名字未更改为例，例如网址是xxx.com，浏览xxx.com/phpMyAdmin进入到mariadb的登录页面，用户名root，密码是mariadb配置时输入的密码。
