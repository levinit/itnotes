# MariaDB

mysql被收购后衍生的分支，由社区维护。

1. 安装mariadb（一些发行版可能将server和client分开打包）

2. 可选，执行以下命令进行初始化：

   ```shell
   #指定运行用户和数据存放位置
   mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
   ```

3. 启动mariadb服务

   ```shell
   systemctl enable --now mariadb
   ```

4. 可选，执行安全配置助手`mysql_secure_installation`进行配置，以提升安全性。其会询问用户作出一些安全性相关的设置建议，主要包括：
   - 设置root密码
   - 远程登录开关
   - 删除匿名帐号
   - 是否删除测试数据库test

   或者使用sql：

   ```sql
   use mysql;
   delete from user where user='root' and host!='localhost';
   --SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$db_root_pwd');
   --SET PASSWORD FOR 'root'@'%' = PASSWORD('$db_root_pwd');
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

# 常用配置和操作

## 配置文件

主配置文件`/etc/my.cnf`，增改配置应当在：`/etc/my.cnf.d`下创建以`.cnf`结尾的文件。具体配置可能有所出入，看看配置文件中的说明和相关文档修改。

配置文件使用.ini风格，一些配置示例：

```ini
[mysqld]
user = mysql  #mysql执行用户
datadir = /data/mysql  #数据存放位置
socket = /data/mysql.sock  #套接字（一般在datadir下）
port = 3306  #默认就是3306
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
default-character-set = utf8  #客户端默认编码
#default-character-set = utf8mb4
```

## 忘记root用户密码

- 方法一

  可能在新版本mysql 中不适用。

  1. 停止mariadb/mysqld服务

  2. 执行命令

     ```shell
     mysqld_safe --skip-grant-tables &
     #或
     #mysqld –console –skip-grant-tables –shared-memory
     ```

  3. 执行`mysql`命令连接

     ```shell
     mysq  #或为 mysql -u root
     ```

  4. 执行SQL语句修改，这里示例将root密码设置为`root`：

     ```mariadb
     use mysql;
     FLUSH PRIVILEGES;
     SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root');
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

## 修改密码强度策略

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