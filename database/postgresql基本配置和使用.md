# 安装和基本配置

## 安装和初始化

1. 安装postgresql

2. 初始化数据库

   ```shell
   postgresql-setup initdb
   ```

   如果没有上面的命令，可使用安装目录的bin下的`init`或`pg_ctl init`工具：

   ```shell
   lang=en_US.UTF-8
   db_path=/var/lib/postgres #一些发行版目录位于 /var/lib/pgsql
   
   sudo chown -R postgres:postgres $db_path
   
   sudo su - postgres -c "pg_ctl initdb -D $db_path"
    
   #或者
   #    su - postgres -c "initdb --locale $lang  -D  '/var/lib/postgres/data'"
   sudo su - postgres -c "initdb --locale $lang  -D  '/var/lib/postgres/data'"
   ```

   初始化命令用法参看`initdb --help`。

   

3. 启动`postgresql`服务

   postgres安装目录下有pg_ctl工具用于初始化、启动和停止postgresql服务：

   ```shell
   #pg_ctl [-D DATADIR] [-l FILENAME] [-W] [-t SECS] [-s]
   pg_ctl start -D </path/to/pg/data>
   ```

   

   如果linux中使用systemd管理postgres守护进程服务，systemd启用postgresql自启动：

   ```shell
   sudo systemctl enable --now postgresql
   ```

   如果使用systemd但修改了默认的数据库文件存放位置，可以将新位置软连接到默认位置，或者修改postgresql.service文件中的数据库位置。

   

   使用pg_ctl启动：

   ```shell
   db_path=/xxx/yyy
   log_file=/zzz.log   #可选
   su postgres -c "/usr/bin/pg_ctl -D $db_path -l $log_file start"
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

   3. 移动数据目录或初始化一个数据库目录

      ```shell
      mv /var/lib/postgres/data   /home/pg/
      ```

      如果需要新建一个位置作为数据库目录，使用以下命令初始化新的数据目录即可：

      ```shell
      lang=en_US.UTF-8
      sudo su - postgres -c "initdb --locale $lang  -D  '/path/pg/data'"
      chown postgres:postgres /path/pg/data
      ```

   4. 修改postgesql启动命令，使用`PGDATA`环境变量定义数据库目录的路径

      ```shell
      export PGDATA=/path/to/data
      pg_ctl start
      ```

      如果使用systemd启动postgresql，可能需要编辑postgresql的systemd unit 文件，该文件中一般定义了`PGDATA`路径。

      可使用 `systemctl staus postgresql`查看具体systemd unit文件路径。
      
      ```shell
      [Service]
      Environment=PGDATA=/path/pg/data/   #修改路径
      ```
      
      

## 配置文件

配置文件位于初始化时指定的目录下的data文件夹中，常用的配置文件目录为`/var/lib/postgres/data/`，以下为该目录中的配置文件。

### `postgresql.conf`  主配置文件

- 更改服务监听地址

  安装完成后，postgres服务默认只允许本地访问。

  示例，监听所有地址，修改：

  ```shell
  listen_addresses = '*' #多个地址使用,分隔如 localhost,10.1.1.1
  ```
  
  

### `pg_hba.conf`  数据库访问配置文件

修改客户端登录验证，避免认证权限过于宽泛。

*提示：initdb方式初始化时若使用`-A`参数，则会自动为本地连接启动 "trust" 认证。*

```shell
#TYPE  DATABASE       USER    ADDRESS       METHOD
# "local" is for Unix domain socket connections only
local     all          all                    ident
# IPv4 local connections:
host      all          all     127.0.0.1/32   password
host      all          all     10.1.1.0/24    scram-sha-256
# IPv6 local connections:
host      all          all     ::1/128        ident

#---Allow replication connections from localhost
local   replication    all                     ident
host    replication    all      127.0.0.1/32   ident
host    replication    all      ::1/128        ident
```
具体配置可参看配置文件中的示例说明。

注意：**pg_hba.conf 文件的更改对当前连接不影响，仅影响更改配置之后的新的连接**，因此修改后需要重载（或重启）数据库。*可使用`pg_ctl reload -D /var/lib/pgsql/` 重载数据库，或者`DATABASE`/`USER`值为`all`时表示所有数据库/用户。*

- TYPE值：
  - `local`
  - `host`、`hostssl`或`hostnossl`
  - `hostgssenc`或`hostnogssenc`



- ADDRESS值：

  - 留空表示本地网络

  - IP地址、主机名或CIDR（127.0.0.1/32）

  - `samehost`或者`samenet`：允许当面服务器直连的任何同一子网内的主机连接



- TYPE值：

  - `local`  使用unix-domain socket

  - `host` 使用TCP/IP




- METHOD值：

  部份常用取值

  - `reject`  拒绝任何连接


  - 以操作系统用户名为数据库用户名

    - `trust`  信任，以当前**操作系统用户名**作为数据库用户名访问数据库，无需密码

    - `ident`  服务器鉴别认证

      通过联系客户端的 ident 服务器获取客户端的**操作系统用户名**，并且检查它是否匹配被请求的数据库用户名，只能在 TCIP/IP 连接上使用。

      **如果在本地连接指定该认证方式，其将用 `peer` 认证来替代。**

    - `peer`  对等认证

      从操作系统获得客户端的**操作系统用户名**，并且检查它是否匹配被请求的数据库用户名，只对本地连接可用。


  - 数据库用户名+密码

    - `password`  未加密的口令

      密码是以明文形式在网络上发送的，应当只在在信任的网络中可以使用。

    - `md5` 或`scram-sha-256`  加密传输的的密码
    
    


- DATABASE值：
  - 某个数据库名字或者`all`（所有）
  - `sameuser`或`samerole`
  - `replication`
  - 正则表达式



# 数据库基本操作

## 创建数据库用户

为避免将<u>数据库用户</u>和<u>操作系统用户</u>混淆，以下“用户”如无特指，均指的数据库中的用户。

PostgreSQL 通过角色的概念来控制数据库的访问权限。 

角色是一个用于授权和权限管理的抽象概念，可以用来表示一个用户、用户组或其他实体。

用户是一个具体的实体，可以登录到 PostgreSQL 数据库并执行操作。用户可以是一个普通用户，也可以是一个超级用户（即具有所有权限的用户）。

PostgreSQL 从 **8.1 版本开始统一了用户（user）和角色（role）的概念**，是否是“用户”，取决于角色是否有 **LOGIN 权限**。

每个用户都必须关联到一个角色，这个角色决定了用户的权限和访问级别。如果没有指定一个角色，那么 PostgreSQL 将为该用户创建一个默认角色。



postgresql安装后创建的默认用户`postgres`，其角色为“超级管理员”。

这里介绍使用postgresql提供的命令管理用户，也可以在psql中使用SQL语句管理用户。

- 创建新用户

  ```shell
  createuser <dbuser> -P  #创建一个名为dbuser的用户createuser --interactive
  ```

  （创建角色需要psql命令行中使用CREATE ROLE命令）

  常用参数：

  - `-s`或`--superuser`  用户角色为超级用户

  - `--interactive`  交互式创建

  - `-d`或`--createdb`  是否允许该用户创建新的数据库

  - `-U`  指定连接数据库的用户（使用哪一个用户在数据库中创建新用户）

    不指定时将尝试以当前shell用户为数据库用户名进行连接。

  - `-P`或`--pwprompt`　给新角色指定口令

  

- 删除用户使用`dropuser` 参数参考创建用户

  

## 创建数据库实例

- 创建数据库createdb

  如果不带任何参数，将创建于用户同名数据库。

  ```shell
  #以postgres身份创建一个名为dbname的数据库实例，并将其归属于dbuser
  createdb -O dbuser dbname
  ```

  删除数据库使用`dropdb`

  参数说明：

  - `-U`  指定连接到postgres数据库执行创建操作命令的用户
  
    - `-E`或`--encoding`  数据库编码
    - `-O`或`--ownwer`  数据库的所有者

当然也可以在psql中使用SQL语句管理数据库。



## 连接数据库

postgre服务默认监听于5432端口。

```shell
#登录连接到指定数据库 -W 将提示输入密码
psql -h 127.0.0.1 -p 5432 -U dbuser -d dbname -W
psql -h localhost -U dbuser  #登录到某个用户 端口默认时可省略
#或
psql postgres://username:password@host:port/dbname
```

参看[psql命令](#psql命令)

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



# postgresql常用操作

操作postgresSQL的命令分为三类：

- postgreSQL程序相关命令

- psql中执行的命令

  - psql命令行的命令

    postgreSQL程序带有的一个命令，为postgreSQL的前端程序（类似mysql/mariadb的mysql命令），进入pgsql交互式命令行后可执行SQL命令。

  - SQL命令

    常规的sql命令（postgresql方言）

  

  

## postgres程序相关命令

在shell中执行

- 程序控制

  - [psql](#psql命令)

    基于终端的postgreSQL的前端程序，参看psql使用。


  - pg_ctl  启动、停止和重启pg服务


  - pg_controldata 显示PostgreSQL服务的内部控制信息


- 用户管理

  - createuser

  - dropuser

  

- 数据库管理

  - 创建、删除数据库

    - initdb       创建一个新的 PostgreSQL数据库集群

    - createdb  创建一个数据库实例

      或者使用sql的`create database`语句：

      ```postgresql
      create database <db_name> with owner <db_user>;
      ```

    - dropdb  删除一个数据库实例

      或者使用sql的`drop database`语句

      ```sql
      drop database <db_name>;
      ```




  - 备份、恢复数据库

    - pg_dump  pg_dumpall
    - pg_restore

    


  - 清理和分析数据库

    - vacuumdb

      它是客户端程序psql环境下SQL语句VACUUM的shell脚本封装，二者功能完全相同。




## psql命令

psql是postgreSQL的数据库管理命令。

### 常用参数

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



### 常用命令

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

  - 修改角色密码`\password`

    `\password username`  修改指定角色的密码
    
    



### 执行sql文件

可选择以下方法：

- 连接db后执行SQL文件

  1. 通过psql连接到对应的db

     ```shell
     psql -d <db_name> -U <db_user>
     ```

  2. 使用`\i`命令执行sql文件

     ```shell
     \i /path/to/test.sql
     ```

- 通过psql命令执行SQL文件

  ```shell
  psql -d <db_name> -U <db_user> -f </path/to/sql_file>
  ```



### 导入csv到数据库表

psql的\copy命令可以导入csv文件到表中，登录到psql执行：

```postgresql
\copy 数据表名 from '文件路径+文件名' with 文件后缀 header delimiter '分隔符' encoding '编码格式';
\copy table1 from '/root/document/csv/table_aaa.csv' with csv header delimiter ',' encoding 'UTF8';
```

或者使用shell执行psql命令：

```shell
psql -h 127.0.0.1 -p 5432 -U dbuser -d dbname -W -c "\copy命令"
```
