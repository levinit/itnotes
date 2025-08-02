#  主从复制

MySQL 主从复制是指数据可以从一个MySQL数据库服务器主节点复制到一个或多个从节点。

主从复制可实现数据备份，读写分离（主数据库负责写，从数据库负责读），高可用。



工作原理：

- 主节点

  1. 每个从节点连接到主节点时，主节点都会创建一个对应的 binlog dump 的线程；
  2. 主节点上进行 insert、update、delete 操作时，会按照时间先后顺序写入到 binlog 中；
  3. 主节点的 binlog 发生变化，binlog dump 线程就会通知从节点 (Push模式)，并将相应的 binlog 内容发送给从节点。

- 从节点

  当开启主从同步的时候，从节点会创建两个线程用来完成数据同步的工作。

- **I/O线程：** 此线程连接到主节点，主节点上的 binlog dump 线程会将 binlog 的内容发送给此线程。此线程接收到 binlog 内容后，再将内容写入到本地的 relay log。

- **SQL线程：** 该线程读取 I/O 线程写入的 relay log，并且根据 relay log 的内容对从数据库做对应的操作。



## 主服务器配置

1. 配置要同步的数据库信息

   添加或编辑数据库的cnf配置文件，例如添加一个配置文件`/etc/my.cnf.d/master-server.cnf`：

   ```ini
   [mysqld]
   #该值唯一，不能和其他从服务器的id一致
   server-id=1
   #bind-address=0.0.0.0
   
   #===日志记录
   #开启二进制日志 binlog用于主服务器上配置，记录二进制日志以供从服务器获取
   log_bin=mysql-bin
   #日志格式
   #statement 保存SQL语句（默认）| row 保存影响记录数据 | mixed 前面两种的结合
   binlog_format = mixed
   #bin日志过期时间（过期删除） 默认0（不过期因此不会删除）
   expire_logs_days = 90
   # binlog的写入频率
   sync_binlog = 5
   #将函数创建操作也写入日志文件
   log_bin_trust_function_creators = 1
     
   
   #===要用同步给从服务器的数据库信息
   #--binlog日志
   #白名单模式 需要开启二进制日志数据库（一行一个）
   binlog-do-db = db1
   #黑名单模式 也可以指定不需要开启二进制日志数据库（一行一个）
   #binlog-ignore-db = mysql  
   #binlog-ignore-db = test  
   #binlog-ignore-db = information_schema
   
   #===其他
   ```

   

2. 授权同步账户

   可以使用既有账户，或创建一个专门用于从服务器同步的账户。

   这里创建用户`sync`，密码`pwd@sync`。
   
   ```mysql
   --允许访问的主机可以限定为指定的从服务器
   grant replication slave,file on *.* to 'sync'@'%' identified by 'pwd@sync';
   flush privileges;
   --check
   select user,host,password  from mysql.user;
   ```
   
   重启mysql，检查状态：
   
   ```sql
   show master status;
   ```

​		输出类似：

> ```shell
> MariaDB [(none)]> show master status;
> +------------------+----------+--------------+------------------+
> | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
> +------------------+----------+--------------+------------------+
> | mysql-bin.000001 |      245 | testdb         |                  |
> +------------------+----------+--------------+------------------+
> ```



其他常用命令：

```mysql
flush logs; 
reset master;
reset slave all;
show master status;
show processlist\G;
```



## 主从服务器同步初始状态

从服务器同步原理是读取主服务器的log_bin文件，而在主服务器开启log_bin文件前，已有的数据在log_bin文件中是不存在的。因此，如果要同步的数据库主服务器已经存历史数据，且打算将历史数据全部复制到从服务器，则在进行主从复制时，需要先将主服务器数据导出，然后在从服务器中导入，以确保二者开启同步复制时初始状态一致。

如果允许同步所有数据库，也可以先停止从服务器的数据库服务，将主数据库数据（如`/var/lib/mysql`）完全复制覆盖从服务器的数据，然后再启动数据库服务。

1. 在主服务器上锁定要同步的数据库，避免同步时数据发生改变：

   ```sql
   --sql语句
   flush tables with read lock;
   ```
   
2. 在主服务器上导出数据库

   ```shell
   mysqldump --user=dbuser --password=userpwd DB1 > db.sql
   #如果要到处函数和存储过程
   #mysqldump --user=dbuser --password=userpwd -R -ndt DB1 > backup.sql
   ```

3. 将数据库文件存放到从服务器上，然后导入从服务器数据库：

   ```shell
   #创建数据库
   mysql --user=root --password=rootpwd -e " CREATE DATABASE DB1;" 
   #导入
   mysql --user=dbuser --password=userpwd DB1 < backup.sql
   #检查
   mysql --user=dbuser --password=userpwd -e "show databases" |grep DB1
   ```

4. 解锁主服务器数据库

   ！！！确保已经配置完主服务器并重启服务生效后（新数据库变更操作会记录到log_bin文件中），再解锁主服务器上已锁定的数据表：

   ```sql
   UNLOCK TABLES;
   ```



## 从服务器配置

1. 添加同步信息

   添加或修改数据库的cnf配置文件，例如`/etc/my.cnf.d/sync-from-master.conf`：

   ```ini
   [mysqld]
   ##该值唯一，不能和主服务器或其他从服务器的id一致
   server-id = 2
   
   #===日志
   #log-bin = mysql-bin
   log-slave-updates
   sync_binlog = 0
   #log buffer将每秒一次地写入log file中，并且log file的flush(刷到磁盘)操作同时进行。该模式下在事务提交的时候，不会主动触发写入磁盘的操作
   innodb_flush_log_at_trx_commit = 0
   
   #将从服务器从主服务器收到的更新记入到从服务器自己二进制日志文件中
   #若从服务器要将从主服务器获取的数据库，提供给另一个从服务器（即本从服务器是另一个从服务器的主服务器），需启用
   #log-slave-updates
   #log_bin_trust_function_creators
   
   #===要从主服务器同步的数据库信息
   #白名单模式 要复制主服务器上哪些数据库（如有多个，则一行一个）
   replicate-do-db = db1
   
   #黑名单模式 不复制主服务器上哪些数据库（如有多个，则一行一个）
   #replicate-ignore-db = information_schema
   #replicate-ignore-db = mysql
   
   #===其他
   slave-skip-errors=all
   slave-net-timeout = 60
   #read-only=1
   ```
   
   
   
2. 设定要同步的主服务器，开始同步

   ```sql
   -- 执行同步命令，设置主服务器ip，同步账号密码
   change master to master_host='10.0.0.1', master_port=3306, master_user='sync',master_password='pwd@sync';
   
   --开启同步
   start slave;
   --查看同步状态
   show slave status\G;
   ```
   
   `change master`还可以指定使用的log文件、其实同步位置等：`master_log_file='mysql-bin.000001', master_log_pos=120; `。
   
   如果命令中没有指定同步或不同不同步的数据库，则按照主服务器上配置情况同步被运行的数据库。
   
   检查输出信息，输出信息（选取部分内容）类似：
   
   > ```shell
   > MariaDB [(none)]> show slave status\G;
   > *************************** 1. row ***************************
   >             Slave_IO_State: Connecting to master
   >                Master_Host: master
   >                Master_User: sync
   >                Master_Port: 3306
   >              Connect_Retry: 60
   >            Master_Log_File: 
   >        Read_Master_Log_Pos: 4
   >           Slave_IO_Running: Yes
   >          Slave_SQL_Running: Yes
   >            Replicate_Do_DB: testdb
   > ```
   
   
   
   - `master_log_file`和`master_log_pos`的值主服务器上`show master status`中的一致。
   - `show slave status\G;`显示信息中，`Slave_IO_Running`和`Slave_SQL_Running`都为`YES`的时候就表示主从同步设置成功，



其他常用命令：

```mysql
start slave;
stop slave;
reset slave;
show slave status\G;
```



## 验证

可选

1. 查看主从服务器状态

   ```sql
   show master status;
   show slave status\G;
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

没有单纯的`主`或`从`的角色，是既为主也为从，都能读写被同步的数据库，又称为主主复制或双机/多机互备（主备），可能还有多机中一部分互备而一部分仅作从服务器复杂组合情况。

参看上文主从复制的相关操作，锁定并完全同步各个服务器数据库，**开启自身的log_bin相关设置，并将彼此添加为自己的主服务器。**

可参看上文主从复制。

## 配置同步文件

各个服务器均配置同步文件，内容融合主从复制中主和从两个服务器的cnf配置文件，示例`/etc/my.cnf.d/replication.conf`内容如下：

```ini
[mysqld]
#---主要修改的内容就是server-id，该值需要唯一，另一个主机的id不可相同
server-id = 1
#bind-address=0.0.0.0

#===日志记录
#开启二进制日志 binlog用于主服务器上配置，记录二进制日志以供从服务器获取
log_bin=mysql-bin
#日志格式
#statement 保存SQL语句（默认）| row 保存影响记录数据 | mixed 前面两种的结合
binlog_format = mixed
#bin日志过期时间（过期删除） 默认0（不过期因此不会删除）
expire_logs_days = 90
# binlog的写入频率
sync_binlog = 5
#将从服务器从主服务器收到的更新记入到从服务器自己二进制日志文件中               
log-slave-updates
#log buffer将每秒一次地写入log file中，并且log file的flush(刷到磁盘)操作同时进行。该模式下在事务提交的时候，不会主动触发写入磁盘的操作
innodb_flush_log_at_trx_commit = 0
#函数操作也写入日志文件
log_bin_trust_function_creators = 1

#===要用同步给从服务器的数据库信息
#--binlog日志
#白名单模式 需要开启二进制日志数据库（一行一个）
binlog-do-db = db1
#黑名单模式 也可以指定不需要开启二进制日志数据库（一行一个）
#binlog-ignore-db = mysql  
#binlog-ignore-db = test  
#binlog-ignore-db = information_schema

#===要从主服务器同步的数据库信息
#白名单模式 要复制主服务器上哪些数据库（如有多个，则一行一个）
replicate-do-db = db1

#黑名单模式 不复制主服务器上哪些数据库（如有多个，则一行一个）
#replicate-ignore-db = information_schema
#replicate-ignore-db = mysql

#===自增长字段设置  一般用在主主同步中，避免同时写入时出现键值冲突
# 自增长字段增量值
auto-increment-increment=2
# 自增长字段初始值为1，保证不同节点的自增值不会重复
auto-increment-offset=2

#===其他
slave-skip-errors = all
slave-net-timeout = 60
#read-only=1
```



## 授权同步账户

可以使用既有账户，或创建一个专门用于从服务器同步的账户。

示例，在各个服务器均创建用户`sync`，密码`pwd@sync`：

```mysql
--允许访问的主机可以限定为可以访问的从服务器
grant replication slave,file on *.* to 'sync'@'%' identified by 'pwd@sync';
flush privileges;
--check
select user,host,password  from mysql.user;
```

重启mysql，检查状态：

```sql
show master status;
```



## 同步各服务器数据库初始状态

参照[同步主从服务器数据库初始状态](#同步主从服务器数据库初始状态)，将各个服务器要同步的数据状态一致化。



## 互相同步

设定彼此为主服务器，操作内容相同，以其中一个为例：

```sql
-- 执行同步命令，设置主服务器ip，同步账号密码
change master to master_host='10.0.0.1', master_port=3306, master_user='sync', master_password='pwd@sync';

--开启同步
start slave;
--查看同步状态
show slave status\G;
```

`change master`还可以指定使用的log文件、其实同步位置等：`master_log_file='mysql-bin.000001', master_log_pos=120; `。

同步成功后，解除数据库的锁定：

```shell
UNLOCK TABLES;
```



## 半同步

降低一些性能，但有更好的数据完整性保障。

`mysql`执行：

```sql
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
```

cnf文件添加：

```ini
#半同步，10s超时pl_semi_sync_master_enabled=1
rpl_semi_sync_master_timeout=10000
rpl_semi_sync_slave_enabled=1
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