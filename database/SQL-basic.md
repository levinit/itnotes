[toc]

# SQL简介

SQL 结构化查询语言

> **SQL** ([/ˌɛsˌkjuːˈɛl/](https://en.wikipedia.org/wiki/Help:IPA/English) *S-Q-L*, [/ˈsiːkwəl/](https://en.wikipedia.org/wiki/Help:IPA/English) "sequel"; **Structured Query Language**



## 数据库结构

参看[oracle 什么是数据库](https://www.oracle.com/cn/database/what-is-database/)

- 数据库  **database**：一个以某种有组织的方式存储的数据集合

  数据库软件应该称为数据库管理系统DBMS

- 表  **table**：存储某种特定类型数据的结构化文件  (类似表格)

  表名在一个数据库中是唯一的，实际上它由数据库名和表名等组成。

  表由行和列组成：

  - 行  row  表中的一个记录
  - 列  column  表中的字段  每个列都有限制的数据类型

  主键  primary key  每一行中的可以唯一标识本行的列（至少一列，可以多列）

  person表示例：

  | id   | name  | gender | birth        |
  | ---- | ----- | ------ | ------------ |
  | 1    | Lily  | Ola    | Timoteivn 10 |
  | 2    | Ivy   | Tove   | Borgvn 23    |
  | 3    | lilac | Kari   | Storgt 20    |


## SQL语法

- SQL的关键字不区分大小写，但是数据库的表名、列名和值可能需要区分（具体的DBMS可能有不同的规则）
- 一条语句（无论是否换行）使用分号结束
- 使用`--`注释单行，`/* */`注释多行

以下语法主要基于mysql、mariadb、postgresql、sqlite，与oracel、db2、sql server、access等有所差异。



# 数据库操作

### 增删数据库



## 对表的操作

### 创建表 create table

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
intro null,
);
```

- 指定列`null`的列，在插入或更新数据时允许空值（不写入任何内容），`not null`列则表示插入或更新时必须为其提供值。

- `null`值的列不可以作为主键。
- `default`可以指定默认值，当插入或更新时未提供值则使用该默认值。

数据类型：不同的数据库实现有不同的数据类型，具体参考该其文档。



### 查看表

```sql
--use切换到数据库
use mysql;

--查看该数据库的表
show tables;
```



### 更新表alternate	Qwertyukl.kjhgfdsa	aqwert

```sql
alternate
```



### 删除表drop table

# 对表内容的操作

对table内容的操作。

## 基本增删改查

### 检索select

```sql
--检索多列时，使用逗号分隔列名
SELECT column_name,column_name FROM table_name;

--*通配符匹配所有列
SELECT * FROM table_name;

--仅返回唯一值（过滤相同的列）：在SELECT后使用DISTINCT关键字
SELECT DISTINCT column_name,column_name FROM table_name;

--示例
select user,host from mysql.user;
```



### 插入insert into

```sql
--形式一：不指定要插入数据的列名，只提供被插入的值：
INSERT INTO table_name
VALUES (value1,value2,value3,...);

--形式二：指定列名及被插入的值：
INSERT INTO table_name (column1,column2,column3,...)
VALUES (value1,value2,value3,...);
```



### 更新update

```sql
UPDATE table_name
SET column1=value1,column2=value2,...
WHERE some_column=some_value;
```

**操作数据库时要主要使用WHERE 子句限定要更新的行。**



### 删除DELETE

从数据库表中删除行

```sql
DELETE FROM table_name WHERE some_column=some_value;

--示例
delete from mysql.user where user='test';
```



### 排序order by

```sql
SELECT column_name,column_name FROM table_name
ORDER BY column_name,column_name ASC|DESC;

--示例，从users表中查询id,name,age三列，并且以age值的大小排序输出
select id,name,age from users order by age asc;
```

- ASC 升序（默认，可以不写出）
- DESC 降序



### 限定行数limit

```sql
--获取Persons表中的前5行内容
SELECT * FROM Persons LIMIT 5;
```

limit是mysql、mariadb、postgresql、sqlite的关键字，其他数据库不一定支持。

```sql
# TOP n  | SQL Server / MS Access 语法
SELECT TOP number|percent column_name(s) FROM table_name;

#ROWNUM <= number | oracle语法
SELECT column_name(s) FROM table_name WHERE ROWNUM <= number;
```



## where数据过滤

where子句用于提取那些满足指定条件的行，需要与增删改查语句配合使用。

```sql
SELECT column_name,column_name FROM table_name
WHERE column_name operator value;

--示例
select user,host from mysql.user where host!='localhost';
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
  delete from mysql.user where user='root' and host!='localhost';
  
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