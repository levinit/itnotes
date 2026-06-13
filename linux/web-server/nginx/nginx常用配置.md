# 导入配置片段

可以拆分conf文件内容为多个文件，在一个其他文件使用`include <file-path>`导入该片段。例如[目录浏览](#目录浏览)相关配置行在多个server配置中均有相同内容的行，可以抽离这些行到一个文件中。

注意：`include`引入文件时如果使用相对路径，则相对路径根目录为nginx配置文件目录。例如抽离的片段文件为`/etc/nginx/conf.d/indexview`：

```nginx
autoindex on;
autoindex_exact_size off;
autoindex_localtime on;
```

引用片段文件indexview的配置文件`/etc/nginx/conf.d/download.conf`：

```nginx
server {
  server_name dl.xx.yy;
  root /srv/dl;
  location / {
    include conf.d/indexview;
  }
}
```

# SSL和HTTP2/HTTP3(QUIC)

使用ssl和http2，需在listen后的端口号后面加上ssl/http2；ssl需要填写证书路径和私钥路径。

http3(quic)需要nginx支持。

```nginx
server{
  listen 443 ssl http2;        # TCP listener for HTTP/2
  
  #=http3 config start=以下行为http3配置 需要安装支持quic的nginx
  #--http3不支持时将启用http2 
  #listen 443 http3 reuseport;  # UDP listener for QUIC+HTTP/3
  #add_header Alt-Svc 'quic=":443"; h3-27=":443";h3-25=":443"; h3-T050=":443"; h3-Q050=":443";h3-Q049=":443";h3-Q048=":443"; h3-Q046=":443"; h3-Q043=":443"'; # Advertise that QUIC is available
  #ssl_protocols       TLSv1.3; # QUIC requires TLS 1.3
  #=http3 config end=
  
  ssl_certificate /etc/letsencrypt/live/xx.xxx/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/xx.xx/privkey.pem;
  ssl_session_cache shared:SSL:1m;
  ssl_session_timeout 10m;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
}
```

http地址跳转到https地址可以新建一个server，示例：

```nginx
server{
  listen 80;
  server_name _;
  return 301 https://$server_name$request_uri;
  #或rewrite ^(.*) https://$host$1 permanent;
}
```

## certbot 使用letsencryt

安装certbot-nginx。

确保nginx已经关闭，执行：

```shell
certbot --nginx -d abc.def -d www.abc.def #abc.def为示例域名
```

如果提示：

> Could not find a usable 'nginx' binary

将nginx所在目录加入到PATH后再执行。



非80/443端口申请证书，需要先执行以下命令获取DNS TXT 记录信息，将获取的信息填到DNS

```shell
certbot -d example.com --manual --preferred-challenges dns certonly 
```

其输出类似内容：

> Please deploy a DNS TXT record under the name:
>
> _acme-challenge.example.com.
>
> with the following value:
>
> uEWcWEXY1bnCxw0aBr0X9iRpccpZWR7Xtoq3Pu6E8vg

根据输出内容在DNS解析中添加一条TXT记录。

等待几分钟，使用`dig _acme-challenge.example.com txt`进行检查。

# 页面密码验证

可以用htpasswd（apache的工具）来生成密码，使用以下命令生成一个密码文件：

```shell
#username是要添加的用以在加密页面登录的用户 password是对应的密码
htpasswd -c -b /etc/nginx/conf.d/lock username password
#可以重复添加用户 参照上一条命令
#删除用户
htpasswd -D /etc/nginx/conf.d/lock username
#修改密码参照添加用户的方法 使用一个新密码即可
```

- -b 在命令行中一并输入用户名和密码而不是根据提示输入密码
- -c 创建passwdfile，如果passwdfile 已经存在，那么它会重新写入并删去原有内容.
- -n 不更新passwordfile，直接显示密码
- -m 使用MD5加密（默认）
- -d 使用CRYPT加密（默认）
- -p 使用普通文本格式的密码（不建议，可能出现验证失败的情况）
- -s 使用SHA加密
- -D 删除指定的用户

然后在要加密的目录的location中单独[配置](nginx/conf.d/passlock)：

```nginx
auth_basic "tips";  #tips是要提示给用户的信息
auth_basic_user_file /etc/nginx/conf.d/lock;  #密码文件路径
```



# 端口转发

```nginx
server{
  listen 5030;
  server_name xx.yy;

  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://localhost:5678;
  }
}
```



# 禁止使用ip访问网站

[禁止使用ip访问](nginx/conf.d/donotvisitbyip.conf)以防止恶意解析，添加一个新的server：

```nginx
server{
  listen 80 default_server;
  listen 443 ssl default_server;
  server_name _;    #ip处写上ip地址
  
  #添加ssl信息：为了防止其他使用443端口的服务出现协议错误。可以复用已存在网站的ssl证书
  ssl_certificate /www/server/panel/ssl/certificate.pem;
  ssl_certificate_key /www/server/panel/ssl/privateKey.pem;
  
  return 444;
  
  #或者将ip访问跳转到指定域名（需要去掉上面return行)
  #rewrite ^(.*) http://www.xxx.yyy;
}
```

`server_name _;`：解析到一个无效的域名。

或者在监听域名的server配置中判断访问域名是否为指定域名：

```nginx
server {
    server_name xxx.yyy;
  
  	#其他内容略...

    if ($host != '$server_name') {
        return 444;
    }
}
```

也可以在通过防火墙过滤流量禁止域名访问。



# 配置websocket

WebSocket协议的握手兼容于HTTP的，使用HTTP的`Upgrade`设置可以将连接从HTTP升级到WebSocket。

配置示例（server内其他内容略）：

```nginx
location /wsapp/ {
  proxy_pass https://wsapp.xx.xxx;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
}
```

# 子域名访问对应的子目录

*如abc.xx.com访问xx.com/abc*

1. 确保在域名解析服务商设置了泛解析：使用A记录，主机记录填写`*`

2. 配置一个server，示例：

   ```nginx
   server{
     listen 80;
     server_name ~^(?<subdomain>.+).xx.com$;
     root   /srv/web/$subdomain;
     index index.html;
   }
   ```



# 目录浏览

在server（或者指定的location中）添加（示例[autoindex](nginx/conf.d/indexview/autoindex) ）：

```nginx
server{
  server_name dl.xx.yy;
  root /srv/download;
  
  location / {
  autoindex on;
  autoindex_exact_size off;
  autoindex_localtime on;
  }
}
```

- [fancy插件](https://github.com/aperezdc/ngx-fancyindex) ：如果要修改目录浏览页面的样式需要使用

  1. 在server中添加[fancy配置](nginx/conf.d/indexview/fancy)（使用fancy配置就不要再添加autoindex相关配置了）：

  ```nginx
  server{
    server_name dl.xx.yy;
    root /srv/download;
    
    location / {
      fancyindex on;
  		fancyindex_exact_size off;
  		fancyindex_localtime on;
  		fancyindex_name_length 255;
  
  		fancyindex_header "/fancyindex/header.html";
		fancyindex_footer "/fancyindex/footer.html";
  		fancyindex_ignore "/fancyindex";
    }
  }
  ```
  
  2. 添加相应位置的header.html和footer.html页面（可以是空白页面）
  
     在header.html和footer.html进行目录浏览页面相关配置。
     
  3. 配置fancy后提示unknown directive "fancyindex" 
  
     在nginx.conf文件中加载fancy模块（例如该模块位于/usr/lib/nginx/modules下）：
  
     ```shell
     load_module "/usr/lib/nginx/modules/ngx_http_fancyindex_module.so";
     ```
  

# webdav

安装有webdav扩展。如果编译安装nginx，configure时启用`--with-http_dav_module`。

