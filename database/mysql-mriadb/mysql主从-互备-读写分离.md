# 主从复制

被同步复制的数据库，在主服务器可读写，在从服务器上只能读。

工作原理：

- 主节点

  1. 每个从节点连接到主节点时，主节点都会创建一个对应的 binlog dump 的线程；
  2. 主节点上进行 insert、update、delete 操作时，会按照时间先后顺序写入到 binlog 中；
  3. 主节点的 binlog 发生变化，binlog dump 线程就会通知从节点 (Push模式)，并将相应的 binlog 内容发送给从节点。

- 从节点

  当开启主从同步的时候，从节点会创建两个线程用来完成数据同步的工作。

- **I/O线程：** 此线程连接到主节点，主节点上的 binlog dump 线程会将 binlog 的内容发送给此线程。此线程接收到 binlog 内容后，再将内容写入到本地的 relay log。

- **SQL线程：** 该线程读取 I/O 线程写入的 relay log，并且根据 relay log 的内容对从数据库做对应的操作。



配置前的可选操作，在规划好的主从服务器上创建专门用户同步的用户，注意要授予该用户对要被同步的数据库的读写权限。

这里示例创建用户`sync`密码`dbsync_@mysql`

```sql
create user 'sync'@'%' identified by 'dbsync_@mysql';
create database db_trawe character set utf8;
grant all privileges on *.* to 'sync'@'%' identified by 'dbsync_@mysql';
flush privileges;
```

停止所有主机mysql相关服务



## 主服务器配置

在主服务器操作。

1. 添加或编辑数据库的cnf配置文件

   例如添加一个配置文件`/etc/my.cnf.d/master-server.cnf`：

   ```ini
   [mysqld]
   ##其他相关配置略##
   server-id=1  #该值唯一，不能和其他从服务器的id一致
   
   #binlog用于主服务器上配置，指定日志记录哪些库的二进制日志（以供同步到从服务器数据库）
   #日志格式：statement 保存SQL语句（默认） row 保存影响记录数据 mixed 前面两种的结合
   binlog_format = mixed
   log_bin=mysql-bin #开启二进制日志
   expire_logs_days = 90  #bin日志保留时间 
   sync_binlog = 5  # binlog的写入频率  该参数性能消耗很大，但可减小MySQL崩溃造成的损失
   
   ##同步数据库配置
   #只同步以下数据库（一行一个）--除此之外，其他不同步 ，因此可以不再指定不同步的数据库
   binlog-do-db = hellodb
   
   #不同步以下数据库（一行一个）
   binlog-ignore-db = mysql  
   binlog-ignore-db = test  
   binlog-ignore-db = information_schema  
   ##其他相关配置略##
   ```

2. 添加从服务器，连接到`mysql`命令行执行SQL语句：

   `10.0.0.2`和`10.0.0.3`是假设的从服务器IP，这里是创建一主二从。

   `*.*`表示授权同步所有数据库的所有表（为了方便在直接使用`*.*`，而具体的同步或不同的数据库名单在主或从cnf配置文件中配置）。

   ```mysql
   show variables like "log_bin";
   show master status;
   grant replication slave,file on *.* to 'sync'@'10.0.0.2' identified by 'dbsync_@sc_mysql';
   grant replication slave,file on *.* to 'sync'@'10.0.0.3' identified by 'dbsync_@sc_mysql';
   flush privileges;
   select user,host,password  from mysql.user;
   ```

3. 可选，**如果主服务器已经存在应用数据且打算保留，则在进行主从复制时，需要先做以下处理：**

   1. 在主服务器上锁定数据表（主服务器上要被同步到从服务器的数据库中的表）

      ```mysql
      flush tables with read lock;
      show master status;
      ```

   2. 在主服务器上导出数据，将主服务器导出的文件复制到从服务器，在从服务器上导入数据。

      **也可以直接打包压缩主服务器上的数据库文件夹，发送到从服务器，在相应位置解开。**

      1. 主服务器上导出（假设用户吗是dbuser，密码是userpwd）

         ```shell
         mysqldump -u dbuser --password=userpwd DB1 > backup.sql
         ```
         
   2. 传送导出文件到从服务器，在从服务器上创建同名数据库：
      
      ```sql
         CREATE DATABASE DB1;
         ```
      
   3. 在从服务器上导入数据库：
      
      ```shell
         mysql -u dbuser --password=userpwd DB1 < backup.sql
         ```
      
   4. ！！！**配置完从服务器并启动同步后，再解锁主服务器上已锁定的数据表**
      
      ```sql
         UNLOCK TABLES;
         ```

其他常用命令：

```mysql
flush logs; 
reset master;
reset slave all;
show master status;
show processlist\G;
```

## 从服务器配置

在从服务器中操作（上文主服务器中添加的从服务器）。

1. 添加服务器相关信息

   可以添加或修改数据库的cnf配置文件（例如添加一个配置文件`/etc/my.cnf.d/slave-server.cnf`），保存后在`mysql`命令行中执行` slave start`

   ```ini
   [mysqld]
   ##该值唯一，不能和主服务器或其他从服务器的id一致
   server-id = 2
   
   master-host = 10.0.0.1
   master_port = 3306
   master-user = sync
   master-password = dbsync_@mysql
   master-connect-retry = 60
   
   ##同步数据库配置
   #要从主服务器复制的数据库
   replicate-do-db = db1
   replicate-do-db = db2
   
   #不从主服务器复制的数据库
   replicate-ignore-db = information_schema
   replicate-ignore-db = mysql
   ```

   也可以使用SQL命令添加：

   ```mysql
   change master to master_host='10.0.0.1', 
   master_port=3306, master_user='sync', 
   master_password='dbsync_@mysql',
   master_log_file='mysql-bin.000001', 
   master_log_pos=120; 
   ```

   命令中没有指定同步或不同不同步的数据库，则按照主服务器上配置情况同步被运行的数据库。

2. 启用slave服务，在`mysql`命令行中执行：

   ```mysql
   start slave;
   show slave status\G;
   ```

   注意：

   - `master_log_file`和`master_log_pos`的值主服务器上`show master status`中的一致。
   - `show slave status\G;`显示信息中，`Slave_IO_Running`和`Slave_SQL_Running`都为`YES`的时候就表示主从同步设置成功，

其他常用命令：

```mysql
start slave;
stop slave;
reset slave;
show slave status\G;
```

## 验证主从复制

1. 查看主从服务器状态

   ```sql
   show master status;
   show slave status;
   ```

2. 数据插入测试

   1. 在主服务器的数据库中插入一些内容：

      ```sql
      use test_db1;
      create table table1(id int(3),name char(10));
      insert into table1 values(001,'hello,db');
      ```

   2. 在从服务器上查看效果

      ```sql
      use test_db1;
      select * from table1;
      ```

# 互为主从

仍以前文[主从复制](#主从复制)中的示例，这里的没有单纯的`主`或`从`的角色，是既为主也为从，都能读写被同步的数据库，这种情况也有称为主主复制或双机/多机互备（主备），可能还有多机中一部分互备而一部分仅作从服务器复杂组合情况。

可参看上文主从复制的相关操作（如创建专门的用户，导出导入已有数据库等），互相配置主从即可。

1. 互相添加对方为从服务器

   假如是双机互备，那么两个服务器都要配置互相的`grant`，这里假设两个服务器A、B分别是`10.0.0.1`、`10.0.0.2`

   服务器A授权B：

   ```mysql
   grant file on *.* to 'sync'@'10.0.0.2' identified by 'dbsync_@sc_mysql';
   ```

   服务器B授权A：

   ```mysql
   grant file on *.* to 'sync'@'10.0.0.1' identified by 'dbsync_@sc_mysql';
   ```

2. 互相添加对方为主服务器

   参看主从配置中从服务器部分，使用SQL命令或修改cnf文件实现（注意`server-id`唯一性）。

   ```ini
   [mysqld]
   server-id = 2
   
   ###主配置
   log-bin=mysql-bin
   expire_logs_days = 233
   relay-log = mysql-relay-bin
   
   binlog-ignore-db = mysql
   binlog-ignore-db = information_schema
   
   ###从配置
   master-host = 10.0.0.1
   master_port = 3306
   master-user = sync
   master-password = dbsync_@mysql
   master-connect-retry = 60
   
   #replicate-do-db = db1
   #replicate-ignore-db = information_schema
   #replicate-ignore-db = mysql
   
   ##id自增
   #id的自增量
   auto_increment_increment=2
   #id起始值
   #auto_increment_offset=1
   
   #设置只读
   #read-only=1
   
   #其余略
   ```

## 半同步

降低一些性能，但有更好的数据完整性保障。

`mysql`执行：

```mysql
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
```

cnf文件添加：

```ini
`#半同步，10s超时``rpl_semi_sync_master_enabled=1``rpl_semi_sync_master_timeout=10000``rpl_semi_sync_slave_enabled=1`
```

总结：半同步复制个人感觉是维持数据完整性，安全性的的一个策略，虽会损失一点性能，还是值得的。配置很简单，关键是理解其工作机制。

# 排错

## 手动跳过slave复制中断

遇到错误而导致Slave复制中断（例如删除一个在slave不存在的数据库）时，需要人工干涉来跳过错误，才能使Slave端的复制。

```mysql
STOP SLAVE;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1;
SHOW GLOBAL VARIABLES LIKE 'SQL_SLAVE_SKIP_COUNTER'; 
start slave;
```

## 双机互为主从字段key自增长冲突

双主互备，且要同时对两台节点写数据才可能出现．

可以在cnf中配置`auto_increment_increment = 2 `，即id的自增为2，双主两台的id起始值不同，来保障两台机器的id完全不相同，这样在互相切换过程中不会导致id冲突而丢失数据。