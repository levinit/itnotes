安装mongodb，启动`mongodb`服务。

Mongodb安装后自身是没有密码的，用户连接只需填写id地址，端口号，数据库名称即可。

默认监听27017端口，可指定端口和数据库目录：

```
mongod --port 27017 --dbpath /data/db1
```

# 修改数据库默认目录

编辑/etc/mongodb.conf的dbpath

# 迁移数据

需要安装有`mongodb-tools`，以提供相关命令 。

##　导出

```shell
mongodump -h IP --port 端口 -u 用户名 -p 密码 -d 数据库 -o 导出到的目录
```

如果不指定`-d`数据库，则会导出所有数据库到该目录。



## 导入

```shell
mongorestore -h IP --port 端口 -u 用户名 -p 密码 -d 数据库 --drop 包含数据库的目录
```

`--drop`参数将删除所有先前的记录信息。

如果不指定`-d`数据库，将导入该目录下所有数据库。

