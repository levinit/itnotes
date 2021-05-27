# 安装配置

参看[官方文档](https://www.zabbix.com/documentation)。zabbix支持postgresql、mysql、sqlite3数据库，从源或者[官网](https://www.zabbix.com/download)下载。

## server和proxy端

- server

  汇总和输出所有被监控主机的信息，安装`zabbix-server`。

  某些发行版可能将postgresql和mysql版本分开打包，安装`zabbix-server-pgsql`或`zabbix-server-mysql`或`zabbix-server-sqlite3`（下同）。

- proxy（可选）

  分布式监控中，汇总一个区域内所有agent的信息转发给server，或在大量（通常指大于500台主机）监控主机的情况中分担server的采集压力，安装`zabbix-proxy`。

  

1. 配置存储数据库

   server和proxy上需要数据库，如果server和proxy在同一主机上，则需要创建不同数据库分别存储。以下以postgresql为例。

   1. 安装并配置数据库：

      ```shell
      #对于新安装postgresql，执行一下命令初始化：
      lang=en_US.UTF-8
      sudo chown postgres:postgres /var/lib/postgres -R
      sudo su - postgres -c "initdb --locale $lang  -D  '/var/lib/postgres/data'"
      sudo systemctl enable --now postgresql
      
      #创建数据库zabbix及数据库用户zabbix
      sudo -u postgres createuser zabbix
      #or
      #su - postgres -c "createuser zabbix"
      
      sudo -u postgres createdb -O zabbix -E unicode -T template0 zabbix
      #or
      # su - postgres -c "createdb -O zabbix -E unicode -T template0 zabbix"
      ```

   2. 导入初始数据

      初始数据存放在zabbix安装目录`/usr/share/doc/`（或在`/usr/share`）下，根据数据库(mysql或sqlite)及模块(server或proxy)情况进入相应目录中。

      ```shell
      #cd /usr/share/zabbix-server/postgresql
      #sudo psql -U zabbix -d zabbix < file.sql
      
      #如果存在多个sql文件，一般按一下顺序导入
      sudo psql -U zabbix -d zabbix -f schema.sql
      sudo psql -U zabbix -d zabbix -f images.sql
      sudo psql -U zabbix -d zabbix -f data.sql
      
      #如果是gz压缩包可以使用zcat解开后通过管道符传给pgsql导入：
      #zcat xx.gz | pgsql _U zabbix -d zabbix
      ```

   3. 配置数据库

      编辑`/etc/zabbix/zabbix_server.conf`，根据情况修改如下内容：

      ```shell
      #DBHost=localhost #默认值
      DBName=zabbix
      DBUser=zabbix
      DBPassword=<password>  #如果数据库在本机 设置了本地访问免密码则无需配置
      ```

   4. 启动`zabbix-server-pgsql`服务

      ```shell
      sudo systemctl enable --now zabbix-server-pgsql
      ```

   5. 用户密码（可选）

      可在安装的web管理平台中修改密码，或者修改zabbix数据库中users表中的用户密码。

      示例，将管理员`Admin`用户（id为1）密码重置为`zabbix`：

      ```sql
      --切换到zabbix数据库后 （postgresql: \c zabbbix  mysql: use zabbix;）
      update users set passwd='5fce1b3e34b520afeffb37ce08c7cd66' where userid='1';
      ```

2. 防火墙规则

   关闭，或放行端口如下

   - agent: 10050/tcp  （被动模式下才会监听该端口）
   - proxy/server: 10051/tcp

   ```shell
   #server or proxy
   firewall-cmd --zone=public --add-port=10051/tcp --permanent
   #agent
   firewall-cmd --zone=public --add-port=10050/tcp --permanent
   firewall-cmd--reload
   ```

## agent端

zabbix中agent即被监控的主机，数据发往proxy或server。

1. 安装`zabbix-agent`

2. 配置，编辑配置文件，一般是`/etc/zabbix/zabbix_agentd.conf`

   ```shell
   Server=server.example  #server或proxy的地址 被动模式时需要配置 纯主动模式可注释
   Hostnasme=client1      #本agent的名字，和hostname一致
   StartAgent=0           #0主动模式 1-100是被动模式
   ServerActive=server.example #主动模式时需配置 值为server或proxy的地址
   RefreshActiveChecks=120     #被控端到服务器获取监控项的周期，默认120s即可
   BufferSize=200              #被控端存储监控信息的空间大小
   Timeout=10                  #超时时间
   ```

   agent的主被动模式：

   - 主动模式

     agent定期主动向server或proxy发送数据，设置`StartAgent`值为0则开启，需要配置`ServerActive`。

   - 被动模式

     agent被动上传数据——server或proxy主动连接agent获取数据。

     注意被动模式下确保server或proxy能够连接的agent的端口（默认10050）。

3. 启动`zabbix-agent`服务

   ```shell
   sudo systemctl enable --now zabbix-agent
   ```

# 图形前端

## web

提供zabbix的web管理前端（一般安装在server上），安装`zabbix-web`（或`zabbix-frontend-php`），一般安装在诸如` /usr/share/webapps/zabbix `等位置。

web服务程序是用php编写，需要安装php、php-fpm、nginx/apache、php-pgsql（php-mysql）等，配置并启用服务。

配置web server。以nginx为例，配置一个`zabbix.conf`：

```nginx
server{
    listen 80; #web端口
    server_name zabbix.example.site; #域名
    root /usr/share/webapps/zabbix; #zabbix web应用位置
 
    #php页面解析相关
    location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;  #127.0.0.1:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

额外要启用和配置的php参数，编辑`etc/php/php.ini`：

```shell
extension=bcmath
extension=gd
extension=sockets
extension=pgsql   #posgresql启用
;extension=mysqli  #mysql启用
;extension=sqlite #sqlite启用
extension=gettext
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
date.timezone = "UTC"
```

重启nginx和php-fpm服务，访问zabbix的web页面，根据提示完成初始设置。

默认的用户名是`Admin`，密码是`zabbix`。

添加agent主机，在主机选择群组，主动式的agent主机，IP地址选择`0.0.0.0`，端口`1`，根据不同类型主机选择模板。

## grafana



# 其他

## api

## 

## 常用命令

- `zabbix_get`：一个命令行应用，它可以用于与 Zabbix agent 进行通信，并从 Zabbix agent 那里获取所需的信息，通常被用于 Zabbix agent 故障排错。

- `fping`：用于通过ICMP/ping发现新加入主机。

