# 基本安装和配置

## 安装和初始化

1. 安装postgresql

2. 初始化数据库

   ```shell
   postgresql-setup initdb
   ```

   如果没有上面的命令，可以执行`initdb -D <postgres数据库存放位置>`进行初始化，示例：

   ```shell
   lang=en_US.UTF-8
   db_path=/var/lib/postgres
   [ -d /var/lib/pgsql ] && db_path=/var/lib/pgsql
   
   sudo chown postgres:postgres $db_path -R
   #    su - postgres -c "initdb --locale $lang  -D  '/var/lib/postgres/data'"
   sudo su - postgres -c "initdb --locale $lang  -D  '/var/lib/postgres/data'"
   ```

   初始化命令用法参看`initdb --help`。

   

3. 启动`postgresql`服务

   如果是linux中使用systemd（或其他类似服务）管理postgres守护进程服务，则不建议使用`pg_ctl -D`命令启动服务。systemd启用postgresql自启动：

   ```shell
   sudo systemctl enable --now postgresql
   ```

   

   使用pg_ctl启动：

   ```shell
   pg_ctl -D <path-to-db>
   ```

   如果使用`pg_ctl `启动报错，根据`/var/lib/postgres/logfile`信息解决。如果提示类似

   > could not create lock file/run/postgresql/...

   创建该目录，授权给postgres用户，再重新启动即可：

   ```shell
   mkdir -p /run/postgresql/
   chown postgres:postgres /run/postgresql
   ```

   

## 更改默认数据库目录   

Linix中安装postgres后，其数据存储的目录一般是`/var/lib/pgsql/data`（或`/var/lib/postgres/data`），可根据需求修改位置。

   **不要使用软链接将新数据目录链接到默认的位置，其不会正常工作。**

   示例迁移默认的`/var/lib/postgres/data`到`/home/pg/data`：

   1. 创建目标目录

      ```shell
      mkdir -p /home/pg/data
      chown -R postgres:postgres /home/pg
      ```
2. 停止postgresql服务

   ```shell
      systemctl stop postgresql
   ```

   3. 移动数据

      ```shell
      mv /var/lib/postgres/data   /home/pg/
      ```
   
      如果原来的`/var/lib/postgres/data/`并没有重要数据，只是新建一个位置存放数据，可以不移动内容，直接初始化新的数据目录即可：

      ```shell
      lang=en_US.UTF-8
      sudo su - postgres -c "initdb --locale $lang  -D  '/home/pg/data'"
      ```
   
4. 编辑postgresql的systemd units 文件（一般位于`/usr/lib/systemd/system`）
   
   修改`Environment`和`PIDFile`
   
      ```shell
   [Service]
   Environment=PGROOT=/home/postgres
   PIDFile=/home/postgres/data/postmaster.pid
   #如果要将/home 目录用作默认目录或表空间，需要添加：
   ProtectHome=false
      ```

## 配置文件

配置文件位于初始化时指定的目录下的data文件夹中，常用的配置文件为：

- `postgresql.conf`  主配置文件

  - 更改服务监听地址

    安装完成后，postgres服务默认只允许本地访问。

    示例，监听所有地址，修改：

    ```shell
    listen_addresses = '*'
    ```

- `pg_hba.conf`  数据库访问配置文件

  修改客户端登录验证，postgreSQL默认只允许本机连接，认证方式为ident，修改：

  ```shell
  #TYPE  DATABASE        USER            ADDRESS                 METHOD
  host           all                      all              127.0.0.1/24              trust
  host           all                      all              192.168.1.0/24          md5
  ```
  *提示：initdb方式初始化时若使用`-A`参数，则会自动为本地连接启动 "trust" 认证。*
  
  注意：**pg_hba.conf 文件的更改对当前连接不影响，仅影响更改配置之后的新的连接。**
  
  修改后可使用`pg_ctl reload -D /var/lib/pgsql/` 重载数据库。
  
  `DATABASE`/`USER`值为`all`时表示所有数据库/用户。
  
  METHOD取值：
  
  - `reject`  拒绝
  
  - `trust`  信任
  
  - `md5`  双重MD5加密口令
    
  - `ident`  服务器鉴别认证
    
    通过联系客户端的 ident 服务器获取客户端的操作系统名，并且检查它是否匹配被请求的数据库用户名，只能在 TCIP/IP 连接上使用。
    
    **当为本地连接指定该认证方式时，将用 `peer` 认证来替代。**
    
  - `peer`  对等认证
    
    从操作系统获得客户端的操作系统用户，并且检查它是否匹配被请求的数据库用户名，只对本地连接可	用。
    
  - `password`  未加密的口令
    
    口令是以明文形式在网络上发送的  

## 创建数据库用户和数据库实例

为避免将<u>数据库用户</u>和<u>操作系统用户</u>混淆，以下“用户”如无特指，均指的数据库中的用户。

> PostgreSQL使用**角色**的概念**管理数据库访问权限**。 根据角色自身的设置不同，一个角色可以看做是一个数据库用户，**或者一组**数据库用户。

user具有login权限可以登录数据库，role不带有login属性。

postgresql安装后创建的默认用户postgres，其角色为“超级管理员”。

- 创建新用户

  ```shell
  createuser dbuser -P userpwd  #创建一个名为dbuser的用户 密码userpwd
  #交互式创建
  #createuser --interactive
  ```

  （创建角色需要psql命令行中使用CREATE ROLE命令）

  删除用户使用`dropuser`

  常用参数：

  - `-s`或`--superuser`  用户角色为超级用户

  - `--interactive`  交互式创建

  - `-d`或`--createdb`  是否允许该用户创建新的数据库

  - `-U`  指定连接数据库的用户(使用哪一个用户在数据库中创建新用户)

    不指定时将尝试以当前shell用户为数据库用户名进行连接。
    
  - `-P`或`--pwprompt`　给新角色指定口令

  

- 创建数据库createdb

  如果不带任何参数，将创建于用户同名数据库。
  
  ```shell
  #以postgres身份创建一个名为dbname的数据库实例，并将其归属于dbuser
  createdb -U postgres -O dbuser dbname
  ```
  
  删除数据库使用`dropdb`
  
  参数说明：
  
    - `-E`或`--encoding`  数据库编码
    - `-O`或`--ownwer`  数据库的所有者

当然也可以在psql中使用SQL语句创建用户和数据库。



## 修改数据库存放目录

*nix中安装postgres后，其默认目录一般是`/var/lib/pgsql/data`（或`/var/lib/postgres/data`）。

迁移数据库存放位置：

```shell
mkdir -p /home/db/pg/data
chown -R postgres:postgres /home/db/pg
initdb -D /home/db/pg/data
```



如果使用sytemd管理postgres守护进程，修改postgres的systemd units文件中`Environment`和`PIDFile`，一般位于`/usr/lib/systemd/system`下，或名`postgresql.service`：

```shell
[Service]
Environment=PGROOT=/home/postgres
PIDFile=/home/postgres/data/postmaster.pid
#如果要将/home 目录用作默认目录或表空间，需要添加：
ProtectHome=false
```



# 常用命令

操作postgresSQL的命令分为三类：

- SQL命令

- postgreSQL程序相关命令

- psql命令

  postgreSQL程序带有的一个命令，为postgreSQL的前端程序（类似mysql/mariadb的mysql命令），进入pgsql交互式命令行后可执行SQL命令。

  

## postgreSQL程序相关命令

### 程序控制

- [psql](#psql命令)

  基于终端的postgreSQL的前端程序，参看psql使用。

- pg_ctl  启动、停止和重启pg服务

- pg_controldata 显示PostgreSQL服务的内部控制信息

### 用户管理

- createuser
- dropuser

### 数据库管理

- 创建、删除数据库

  - initdb        创建一个新的 PostgreSQL数据库集群
  - createdb  创建一个数据库实例
  - dropdb

- 备份、恢复数据库

  - pg_dump  pg_dumpall
  - pg_restore

- 清理和分析数据库

  - vacuumdb

    它是客户端程序psql环境下SQL语句VACUUM的shell脚本封装，二者功能完全相同。



## psql命令

psql是postgreSQL的数据库管理命令。

直接执行`psql`该命令将进入psql的交互式命令行，或使用`-c`参数直接执行命令：

```shell
psql -c "\l"
psql -c "alter user postgres with password 'pwd123';"  #修改postgres角色密码为pwd123
```

psql命令常用参数：

- `-h host`  指定连接的Postgres数据库IP地址（如不指定则为localhost）
- `-U username`  指定连接数据库的用户名（如不指定则为当前shell用户名）
- `-d database`  指定连接的数据库名（如不指定则为当前shell用户名）
- `-p port`  指定数据库连接的服务端口（如不指定则为5432）
- `-w`  不提示用户输入密码
- `-W`  验证数据库用户密码
- `-l`  列出Postgres可用的数据库信息



psql交互式命令后中常用命令：

- 基本操作

  - psql命令帮助：`\?`

    `\? <commadn>`  查看某个psql命令的帮助

  - SQL命令帮助：`\h`或`\help`

  - 退出：`\q` （或<kbd>Ctrl</kbd> <kbd>d</kbd>）

- 数据库操作

  - 列出所有数据库：`\l`或`psql -l`
  - 切换数据库：`\c <dbname>`

- 表单操作

  - 查看表结构：`\d <table-name>`
  - 查看所有表信息：`\dt`

- 用户操作

  - 列出所有角色：`\du`

  - 列出用户映射：`\deu`

  - 创建角色：`\c`

  - 修改角色密码`\password`

    `\password username`  修改指定角色的密码
    
    

### 连接数据库

postgre服务默认监听于5432端口。

```shell
psql -h 127.0.0.1 -p 5432 -U dbuser -d dbname  #登录连接到指定数据库
psql -h localhost -U dbuser  #登录到某个用户 端口默认时可省略
#或
psql postgres://username:password@host:port/dbname
```

自动连接方式：

- 先导出密码变量`PGPASSWORD`，再登录时可自行认证，但不安全，一般不建议。

  ```shell
  export PGPASSWORD=123456  #假如用户dbuser的密码是123456
  psql -U dbuser -d dbname -h 127.0.0.1
  ```

- 客户端的`.pgpass`文件中提供密码

  1. 创建一个`.pgpass`文件，其中包含数据库连接的各项信息

     ```shell
     echo "127.0.0.1:5432:dbname:dbuser:123456" > ~/.pgpass
     chmod 600 ~/.pgpass
     ```

  2. 直接连接目标数据库将读取`.pgpass`文件自动认证

     ```shell
     psql -h 127.0.0.1 -U dbuser -d dbname
     ```
