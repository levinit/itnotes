# MariaDB

mysql被收购后衍生的分支，由社区维护。

1. 安装mariadb（一些发行版可能将server和client分开打包）

2. 可选，执行以下命令进行初始化：

   ```shell
   #指定运行用户和数据存放位置
   mysql_install_db --user=mysql --datadir=/var/lib/mysql  --basedir=/var/lib/mysql --datadir=/var/lib/mysql/data
   
   #mariadb
   mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
   ```

   `mysql_install_db`将把数据库存放目录的权限所有者改为mysql用户当前用户。

   如果启动提示：

   >  Can't open and lock privilege tables: Table 'mysql.servers' doesn't exist

   则是制定的数据库位置中没有初始化的数据库，使用上面的命令初始化即可。

   

   mariadb安装后，系统会创建mysql用户用作运行mariadb的默认用户，`--user=mysql`会将数据库存放目录的权限所有者改为mysql用户；如果要使用mysql运行，但当前用户不是`mysql`且没有使用`--user=mysql`，需要修改数据库文件权限：

   ```shell
   chown -R mysql:mysql /var/lib/mysql
   ```

   

   使用systemctl启动mariadb会自动初始化数据库目录，具体查看其systemd unit文件。

3. 启动mariadb服务

   ```shell
   systemctl enable --now mariadb
   ```

   如果不使用systemctl，使用mysqld_safe（一个脚本，systemd units也是执行该脚本）启动：

   ```shell
   mysqld_safe  # --datadir='/var/lib/mysql'
   mysqld_safe #--defaults-file=xx.cnf
   ```

   可使用`--defaults-file`指定读取的配置文件（默认读取`/etc/my.conf`）。

   

4. 安全配置，可选

   ```shell
   mysql_secure_installation
   ```

   其会询问用户作出一些安全性相关的设置建议，主要包括：

   - 是否设置root密码
   - 是否关闭远程root登录
   - 是否删除匿名帐号（实际匿名用户是没有任何权限的）
   - 是否删除测试数据库test

   或者使用sql：

   ```sql
   use mysql;
   --:del root remote access
   delete from user where user='root' and host!='localhost';
   --if you want to set a password for root:
   --SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_pwd');
   --SET PASSWORD FOR 'root'@'%' = PASSWORD('new_pwd');
   --:del test db
   drop database if exists test;
   --:del anymous users
   delete from mysql.user where user='';
   FLUSH PRIVILEGES;
   ```



# Mysql

## 程序包

本文所述为oracle mysql community版本。

mysql community rpm bundles（5.7及以上版本）含有以下软件包：

- 基本程序
  - mysql-community-client
  - mysql-community-server
  - mysql-community-server-minimal（最小化版本）
  - mysql-community-libs
  - mysql-community-libs-compat（LIB兼容库）
  - mysql-community-common（公共文件）
- 嵌入式相关
  - mysql-community-embedded（嵌入式库）
  - mysql-community-embedded-compat（嵌入式共享兼容库）
  - mysql-community-embedded-dev（嵌入式开发库）
- 开发相关
  - mysql-community-devel（开发MySQL必备的头文件和库）
  - mysql-community-minimal-debuginfo（最小安装调式信息库）
- 测试
  - mysql-community-test（测试套件）

其中server-minimal是server的最小化版，二者中安装一个即可。

## 安装配置

1. 安装（以使用rpm包为例）

   ```shell
   yum install mysql*{server,client,common,libs}*.rpm
   systemctl enable --now mysqld  #注意mysql5.6及以下的服务名为mysql而非mysqld
   ```

2. root密码

   mysql5.7+为root用户生成了随机密码，位于`err_log`中（默认在`/var/log/mysqld.log`）：

   ```shell
   grep --color password /var/log/mysqld.log
   ```

   可从日志中看到类似该行字样`A temporary password is generated for root@localhost:`其行末便是root密码。

   可执行`mysql_secure_installation`进行初始配置，参看Mariadb中相关说明。
   
   

一些linux发行版中mariadb默认只监听127.0.0.1，在其配置文件中找到`bind-address`，将值改为`0.0.0.0`可监听所有端口吧。（提示，可在配置文件目录使用`grep address * -r`搜索）。



# 配置文件

主配置文件`/etc/my.cnf`，其载入`/etc/my.cnf.d`下的`.cnf`结尾的文件，配置文件使用.ini格式，配置文件将被按文件名顺序加载，后加载的文件中的配置项将覆盖先加载的相同配置项。

默认的server.cnf是server端配置文件，

```ini
[mysqld]
user = mysql  #mysql执行用户
datadir = /data/mysql      #数据存放位置
socket = /data/mysql.sock  #套接字（一般在datadir下）
bind-address=127.0.0.1     #默认0.0.0.0
port = 3306                #默认就是3306
##日志
log-error = /var/log/mysqld.log  #日志
pid-file = /var/run/mysqld/mysqld.pid  #进程标识号文件

##安全
#skip-networking  #禁止远程访问
#密码策略
validate_password_policy = 0    #复杂度
validate_password_length = 6　　#最小长度

#auto-rehash  #no-auto-rehash  #自动补全（默认关闭）

##调优
default-storage-engine = INNODB
innodb_file_per_table = 1
#max_connections = 1000

##编码
character-set-server = utf8
#utf8mb4是utf8的超集，兼容四字节unicode，占用更多空间，根据情况启用。
#default-character-set = utf8mb4

##排序规则
#ci是case insensitive--大小写不敏感（一般用这个）， cs是case sensitive--大小敏感
#utf8_general_ci比utf8_unicode_ci稍快，但对中、英文来说没有实质的差别
#有德语、法语或者俄语等最好启用utf8_unicode_ci
#collation-server = utf8_general_ci  #utf8_general_cs
#collation-server = utf8_unicode_ci  #utf8_unicode_cs
#collation-server = utf8_bin  #字符串用二进制数据编译存储，区分大小写

[client]
#客户端默认编码
default-character-set = utf8
#default-character-set = utf8mb4
```



# 登录数据库

```shell
mysql [-h <host>] -u <user> -p <password> [-D <database_name>]
```

注意：不指定-h时，默认通过localhost连接数据库，localhost连接所使用的是unix socket，因此只有对socket文件有权限的用户才能使用localhost登录。

如果要使用tcp/ip访问，需要使用127.0.0.1。



# 用户管理

执行`mysql`进入数据库操作：



## 增删用户

- 创建用户

  创建一个名为'user1'的用户，授予其可以从10.1.1.0/24网段访问，并授予权限：

  ```sql
  -- password改为实际的密码字符
  GRANT ALL PRIVILEGES ON db1.* TO 'user1'@'10.0.0.%' IDENTIFIED BY 'user_password';
  FLUSH PRIVILEGES;
  
  -- 另一个例子，创建并授予'root'@'127.0.0.1'用户所有数据库权限
  -- WITH GRANT OPTION 表示该用户可以将自己拥有的权限授权给别人
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY 'password' WITH GRANT OPTION;
  ```

  提示：用`%`代之任意地址

  

- 删除用户

  ```sql
  -- 删除用户 'user1'@'127.0.0.1'
  drop user 'user1'@'127.0.0.1';
  ```



## 设置密码

```sql
-- 更改密码 方式1
UPDATE mysql.user SET authentication_string=PASSWORD('new_password') WHERE User='username';
-- 更改密码 方式2
SET PASSWORD FOR 'username'@'hostname' = 'new_password';
```



###  重置root用户密码

- 方法一

  **可能在新版本mysql 中不适用。**

  1. 停止mariadb/mysqld服务

  2. 执行命令

     ```shell
     mysqld_safe --skip-grant-tables &
     #或
     #mysqld –console –skip-grant-tables –shared-memory
     ```

  3. 执行`mysql`命令连接

     ```shell
     mysql  #或为 mysql -u root
     ```

  4. 执行SQL语句修改，这里示例将root密码设置为`root`：

     ```mariadb
     use mysql;
     FLUSH PRIVILEGES;
     --set root password 123456
     SET PASSWORD FOR 'root'@'localhost' = PASSWORD('123456');
     exit
     ```

  5. 终止mysqld/mariadb进程，再重启服务。

     ```shell
     pkill mysqld #pkill mariadb
     systemctl start mariadb
     ```

- 方法二

  1. 在`my.cnf`的mysqld下添加`skip-grant-tables`

     ```ini
     [mysqld]
     skip-grant-tables
     ```

  2. 重启mysql服务

  3. 使用`mysql -uroot -p`登录mysql命令行

  4. 执行SQL语句修改密码，这里示例将root密码设置为`root`：

     ```mysql
     use mysql
     update mysql.user set authentication_string=password('root') where user='root';
     flush privileges;  
     ```

     注意：mysql5.6以下版本设置密码使用`update user set password =password('root') where user='root';`。

  5. 去掉`my.cnf`中的`skip-grant-tables`，重启mysql服务，以`mysql -uroot -proot`即可登录mysql。



### 修改密码强度策略

MySQL5.6.6版本之后增加了密码强度验证插件validate_password，默认策略较为严格，要求密码满足三种不同类型的字符（例如数字+字母+符号）。

通过修改validate_password_policy的值降低密码强度要求，例如修改为最小3个字符的任意字符密码：

```sql
 select @@validate_password_policy;
 set global validate_password_policy=0;
 set global validate_password_mixed_case_count=0;
 set global validate_password_number_count=3;
 set global validate_password_special_char_count=0;
 set global validate_password_length=3;
 SHOW VARIABLES LIKE 'validate_password%';
 flush privileges;
 SET PASSWORD FOR 'root'@'localhost' = PASSWORD('123');
```

也可以参看[配置文件](#配置文件)中关于密码强度策略的设置。



# 数据库操作

参看常规的sql语言的相关命令。



# 问题

## 含双引号语句报错Column not found

mysql 参数配置导致：

1.设置SQL_MODE命令：

```
set session sql_mode='STRICT_TRANS_TABLES';
```

各种模式：

1.`严格模式`是指将SQL_MODE变量设置为STRICT_TRANS_TABLES或STRICT_ALL_TABLES中的至少一种。现在来看一下SQL_MODE可以设置的选项。

2.`STRICT_TRANS_TABLES`：在该模式下，如果一个值不能插入到一个事务表(例如表的存储引擎为InnoDB)中，则中断当前的操作不影响非事务表(例如表的存储引擎为MyISAM)。

3.`ALLOW_INVALID_DATES`：该选项并不完全对日期的合法性进行检查，只检查月份是否在1～12之间，日期是否在1～31之间。该模式仅对DATE和DATETIME类型有效，而对TIMESTAMP无效，因为TIMESTAMP总是要求一个合法的输入。

4.`ANSI_QUOTES`：启用ANSI_QUOTES后，不能用双引号来引用字符串，因为它将被解释为识别符

你应该是启用`ANSI_QUOTES`了。