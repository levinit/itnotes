SQL 结构化查询语言

# 数据库结构

- 数据库  database

  > 数据库是一个以某种有组织的方式存储的数据集合

  数据库软件－－数据库管理系统DBMS

- 表  table：存储某种特定类型数据的结构化文件  (类似表格)

  表由行和列组成。

  - 列  column  表中的字段  每个列都有限制的数据类型
  - 行  row  表中的一个记录
  - 主键  primary key  对行进行唯一标志的一列或几列
  
  person表示例：
  
  | name  | gender | birth        |
  | ----- | ------ | ------------ |
  | Lily  | Ola    | Timoteivn 10 |
  | Ivy   | Tove   | Borgvn 23    |
  | lilac | Kari   | Storgt 20    |
  
  

# SQL语句

SQL语法规则

- 大小写不敏感
- 使用分号结束



## SQL 数据操作语言 (DML)

查询和更新：

- `SELECT` - 从数据库表中获取数据

  ```sql
  SELECT <column_name[,column_name]> FROM table_name;
  SELECT * FROM table_name;
  SELECT DISTINCT <column_name[,column_name]> FROM table_name;
  ```

  `*`通配符

  一个列可能会包含多个重复值，有时您也许希望仅仅列出不同（distinct）的值。

  DISTINCT` 关键词用于返回唯一不同的值。

  

- `UPDATE` - 更新数据库表中的数据

  ```sql
  ```

  

- `DELETE` - 从数据库表中删除数据

  ```sql
  DELETE FROM <table_name> WHERE <some_column>=<some_value>;
  ```

  

- `INSERT INTO` - 向数据库表中插入数据

  ```sql
  insert into person 
  ```

  

## SQL 数据定义语言 (DDL)

创建或删除表格，定义索引（键），规定表之间的链接，以及施加表间的约束：

- `CREATE TABLE` - 创建新表
- `ALTER TABLE` - 变更（改变）数据库表
- `DROP TABLE` - 删除表
- `CREATE INDEX` - 创建索引（搜索键）
- `DROP INDEX` - 删除索引