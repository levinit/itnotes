[toc]

# SQL简介

SQL 结构化查询语言

> **SQL** ([/ˌɛsˌkjuːˈɛl/](https://en.wikipedia.org/wiki/Help:IPA/English) *S-Q-L*, [/ˈsiːkwəl/](https://en.wikipedia.org/wiki/Help:IPA/English) "sequel"; **Structured Query Language**



## 数据库结构

参看[Oracle 什么是数据库](https://www.Oracle.com/cn/database/what-is-database/)

- 数据库  **database**：一个以某种有组织的方式存储的数据集合

  数据库软件应该称为数据库管理系统DBMS

- 表  **table**：存储某种特定类型数据的结构化文件  (类似表格)

  表名在一个数据库中是唯一的，实际上它由数据库名和表名等组成。

  表由行row和列column组成。

  - 字段：即列名。按照一个带表头带简单表格来描述，表头的每个单元格的内容就是字段。

  - 记录：表中的一行内容。按照一个带表头带简单表格来描述，除了表格第一行即表头外，其余行都是实际的数据记录。
  - 主键：  primary key，能够唯一标示一个事物的一个字段或者多个字段的组合。 

  person表示例：

  | id   | name  | gender | birth        |
  | ---- | ----- | ------ | ------------ |
  | 1    | Lily  | Ola    | Timoteivn 10 |
  | 2    | Ivy   | Tove   | Borgvn 23    |
  | 3    | lilac | Kari   | Storgt 20    |

  第1行内容描述了这个表的字段，后面3行即3条记录。

  

## SQL语法

- SQL的关键字不区分大小写，但是数据库的表名、列名和值可能需要区分（具体的DBMS可能有不同的规则）
- 一条语句（无论是否换行）使用分号结束
- 使用`--`注释单行，`/* */`注释多行

以下语法主要基于MySQL、Mariadb、PostgreSQL、SQLite，与oracel、DB2、sql server、access等有所差异。



# 数据库操作

## 创建

### 创建数据库create database

```sql
CREATE DATABASE dbname;
```



### 创建表create table

```sql
CREATE TABLE table_name
(
column_name1 data_type(size),
column_name2 data_type(size),
column_name3 data_type(size),
....
);

--示例
create table books (
id  int not null,
name varchar(255) not null,
author varchar(255) default '佚名',
intro null
);
```

### 复制表内容插入到新表

从一个表复制数据，然后把数据插入到另一个新表中。DB2不支持.

```sql
--创建一个新表table2，并将table1的所有内容插入到新表table1中

select * into newtable from oldtable;


--Mariadb Mysql PostgreSQL SQLite Oracle
create table newtable
as
select * from oldtable;
```





### 创建索引create index

创建索引以便更加快速高效地查询数据。用户无法看到索引，它们只能被用来加速搜索/查询。

```sql
--在表上创建一个简单的索引。允许使用重复的值：
CREATE INDEX index_name ON table_name (column_name)

--创建一个唯一的索引 (用于创建索引的语法在不同的数据库中不一样)
CREATE UNIQUE INDEX index_name ON table_name (column_name)
```

更新一个包含索引的表需要比更新一个没有索引的表花费更多的时间，这是由于索引本身也需要更新。因此，理想的做法是仅仅在常常被搜索的列（以及表）上面创建索引。



## 检索

### 检索记录select

```sql
--检索多列时，使用逗号分隔列名
SELECT column_name,column_name FROM table_name;

--*通配符匹配所有列
SELECT * FROM table_name;

--仅返回唯一值（过滤相同的列）：在SELECT后使用DISTINCT关键字
SELECT DISTINCT column_name,column_name FROM table_name;

--示例
select user,host from MySQL.user;
```

#### 检索排序order by

```sql
--DESC倒序  ASC顺序（默认值，可不写出）
SELECT column_name,column_name FROM table_name
ORDER BY column_name,column_name DESC;

--示例，从users表中查询id,name,age三列，并且以age值的大小排序输出
select id,name,age from users order by age asc;
```



## 增加

### 插入记录insert into

```sql
--形式一：不指定要插入数据的列名，只提供被插入的值：
INSERT INTO table_name
VALUES (value1,value2,value3,...);

--形式二：指定列名及被插入的值（可以只部分列实现只为部分列插入数据）:
INSERT INTO table_name (column1,column2,column3,...)
VALUES (value1,value2,value3,...);
```

插入检索出来的记录insert select：

```sql
--将table2中的column1，column2的数据检索出来，然后插入到table1的column1,column2中
insert into table1 (column1,column2)
select column1,column2 from table2;
```



## 修改

### 更新记录update

```sql
UPDATE table_name
SET column1=value1,column2=value2,...
WHERE some_column=some_value;
```

**操作数据库时要主要使用WHERE 子句限定要更新的行。**



### 修改表名

对于修改表名对操作，DB2、Mariadb、MySQL、PostgreSQL、Oracle使用`RENAME`，SQL Server使用`sp_rename`，SQLite使用`ALTERNATE`。

```sql
--重命名表 Oracle、MySQL、MariaDB、SQLite
ALTER TABLE table_name RENAME TO new_table_name;
```



### 修改列

不同DBMS有不同的限制，许多DBMS不允许删除或更改表的列，限制对已填数据的列进行更改。

一般应当避免对表的列进行修改。对于复杂的表结构的更改，可以：

1. 根据新的列需求创建一个新表；
2. 将原表数据迁移到新表；
3. 删除旧表，将新表重命名旧表的名字；
4. 如果有索引、外键等，参考旧表在新表中创建之。



#### 修改列顺序

```sql
--将数据类型为 int(10) 的 id 列移动到最前面
alter table student modify id int(10) unsigned auto_increment first;

--将数据类型为 varchar(10) 的 name 列移动到 id 列之后
alter table student modify name varchar(10) after id;

--将数据类型为 int(1) 的 gender 列移动到 name 列之前
alter table student modify gender int(1) before name;
```



#### 修改列名

```sql
--修改列名 DB2、Mariadb、MySQL、PostgreSQL、Oracle
ALTER TABLE table_name RENAME COLUMN old_name TO new_name;

--修改列名 MariaDB
ALTER TABLE table_name CHANGE COLUMN old_name TO new_name;

--修改列名 SQL Server
EXEC sp_rename old_name, new_name;  
```

#### 修改列数据类型

```sql
--改变列的数据类型 SQL Server、MS Access
ALTER TABLE table_name ALTER COLUMN column_name datatype

--改变列的数据类型 MySQL、Mariadb
ALTER TABLE table_name MODIFY COLUMN column_name datatype

--改变列的数据类型 oracle
ALTER TABLE table_name MODIFY column_name datatype;
```

#### 添加列

```sql
--在表中添加列 Mariadb、MySQL、PostgreSQL（datatype是数据类型）
ALTER TABLE table_name ADD column_name datatype;
--在表中添加列 SQLite
ALTER TABLE table_name ADD COLUMN column_def...;
```

#### 删除列

```sql
--在表中删除列
ALTER TABLE table_name DROP COLUMN column_name；
```





## 删除

### 删除数据库drop table

```sql
DROP DATABASE database_name;
```



### 删除表drop table

```sql
DROP TABLE table_name;
```



### 仅删除表的记录truncate table

删除表内的数据但并不删除表本身

```sql
TRUNCATE TABLE table_name;
```



### 删除索引

```sql
--MS Access
DROP INDEX index_name ON table_name
--MS SQL Server
DROP INDEX table_name.index_name
--DB2/Oracle
DROP INDEX index_name
--MySQL、Mariadb、PostgreSQL
ALTER TABLE table_name DROP INDEX index_name
```



### 删除记录DELETE

从数据库表中删除行

```sql
DELETE FROM table_name WHERE some_column=some_value;

--示例
delete from MySQL.user where user='test' or user='';
```



## 数据过滤

## 限定行数limit

```sql
--获取Persons表中的前5行内容
SELECT * FROM Persons LIMIT 5;
```

limit是MySQL、Mariadb、PostgreSQL、SQLite的关键字，其他数据库不一定支持。

```sql
# TOP n  | SQL Server / MS Access 语法
SELECT TOP number|percent column_name(s) FROM table_name;

#ROWNUM <= number | Oracle语法
SELECT column_name(s) FROM table_name WHERE ROWNUM <= number;
```



## where子句

where子句用于提取那些满足指定条件的行，需要与增删改查语句配合使用。

```sql
SELECT column_name,column_name FROM table_name
WHERE column_name operator value;

--示例
select user,host from MySQL.user where host!='localhost';
```

这里的operator指一个连接column_name和value的操作符号，value值必须用引号包裹。

### where操作符

- 等于`=`

- 不等于 `<>`或`!=`  某些数据库可能只支持其中一种写法

- `>`  `<`  `>=`  `<=`

- 不大于和不小于：`!>`  `!<`

- `BETWEEN AND`：在某个范围内，在`AND`前后的两个值即使范围的两个边界

  ```sql
  --在1和10之间 （这是一个不是完整示例语句）
  between 1 and 10
  ```

- `IN`：指定条件范围，`IN`后面接连接一组由逗号分隔，圆括号包裹的值

  ```shell
  --（这是一个不是完整示例语句）
  in ('user1','user2','user6')
  ```

  - `IN`操作符比一组`OR`操作符执行更快（可选值数量多的时候才能体现出来）

- `IS NULL`  为NULL值

- `AND` 和 `OR` 

  ```sql
  --示例
  delete from MySQL.user where user='root' and host!='localhost';
  
  select from mysq.user where host!='localhost' or user='test' or user='root';
  ```

  可以使用多个`and`或`or`。

- `NOT`：否定其后的任何条件。

  ```sql
  --从users中选择所有country不为'china'的行 （和country!='china'一个作用）
  select * from users where
  not country='china' order by id;
  ```

- `LIKE`：通配符过滤

  前面的操作符均用于对确定值（或确定范围的值）进行过滤，LIKE配合通配符进行过滤：

  ```sql
  --检索出users表中 name以user开头的行
  select id,name from users
  where name like "user%";
  ```

  通配符：

  - `%`：任意次数的任何字符

  - `_`：任意单个字符

    DB2不支持；Acess使用`?`表示。

  - `[]`：字符集    SQL Server和Acess支持。

    SQL Server在中括号中第一个位置使用`^`表示取反，Access使用`!`表示取反。

    示例：`like [JMx]`，`like [!ax]`

## group by数据过滤

用于过滤分组。



# 计算字段

