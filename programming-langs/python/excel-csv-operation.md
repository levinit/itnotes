# csv

## csv简介

csv，即Comma-Separated Values（有时也称为字符分隔值，因为分隔字符也可以不是逗号，下文均默认指以逗号为分隔符），以纯文本形式存储表格数据。CSV泛指具有以下特征的任何文件：

> 1. [纯文本](https://zh.wikipedia.org/wiki/文本文件)，使用某个字符集，比如[ASCII](https://zh.wikipedia.org/wiki/ASCII)、[Unicode](https://zh.wikipedia.org/wiki/Unicode)、[EBCDIC](https://zh.wikipedia.org/wiki/EBCDIC)或[GB2312](https://zh.wikipedia.org/wiki/GB2312)（简体中文环境）等；
> 2. 由[记录](https://zh.wikipedia.org/wiki/记录)组成（典型的是每行一条记录）；
> 3. 每条记录被[分隔符](https://zh.wikipedia.org/w/index.php?title=分隔符&action=edit&redlink=1)分隔为[字段](https://zh.wikipedia.org/w/index.php?title=字段&action=edit&redlink=1)（典型分隔符有逗号、分号或制表符；有时分隔符可以包括可选的空格）；
> 4. 每条记录都有同样的字段序列。

csv文件内容是一行行以逗号`,`分隔的数据，示例文件animals.csv：

```csv
animal,id,name
dog,1,wangwang
cat,2,miaomiao
```

使用支持csv格式的文本处理软件（如excel，numbers）即可以表格方式展示csv文件。

## python csv模块

python内置支持csv，导入`csv`模块使用。

### 读取 `csv.reader()`

读取csv文件，返回一个可迭代的reader 对象。

示例info.csv：

```shell
1,"1,1"
2,2
```

读取info.csv，返回一个可迭代数组对象，每个数组为csv中的一行内容去掉分隔符后的字符串组成：

```python
import csv
with open('info.csv') as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    for row in reader:
    		print(row) #type(row) #list
```

csv.reader常用参数：

- `delimiter`  即分隔符，默认为逗号

- `quotechar` 某行item 中包含了分隔符，应该用 quotechar 把它包裹起来，默认不指定表示

  如info.csv示例中第一行中第2项含有分隔符逗号，使用了双引号包裹，需要在读取csv时指明quotechar为`”`。

- `doublequote`，如果某个 item 中出现了 quotechar 那么可以把整个内容用 quotechar 包裹，并把 quotechar double 一下用来做区分

- `lineterminator`  每一行的结束符，默认的是 `\r\n`

- `skipinitialspace`，是否忽略分隔符后面跟着的空格

### 写入 `csv.writer()` 

返回一个 writer 对象，该对象负责将用户的数据在给定的文件类对象上转换为带分隔符的字符串。

将一行内容组成一个可迭代对象（如数组或元组），传递给writer的对象的`writerow()`方法即可写入一行内容。

writer对象的`writerows()`方法可以写入一行或多行，传递一个由多个可迭代对象组成的对象，例如每行内容组成一个数组，多行内容组成一个两层数组。

```shell
with open('/tmp/a', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=':')
    writer.writerow((1,'line1'))
    writer.writerows([[5,'line2'],[3,'line3']])
```



# execl

以下使用openpyxl操作excel，可使用pip安装：`pip install openpyxl`。

一个excel文件被称为一个工作簿workbook，工作簿由至少一个工作表worksheet组成；

每个工作表内容即表格，表格由若干行row组成，每行由单元格cell组成。

操作的行、列和单元格编号均从1开始。

## 基本读写方法

### 写的基本方法

1. 创建工作簿workbook对象，以下简称wb（使用`Work()`）
2. 向工作簿中添加工作表——创建工作表worksheet对象，以下简称ws
3. 向工作表ws写入各种信息
4. 保存工作簿

```python
from openpyxl import Workbook

wb=workbook() #1. workbook
ws=wb.active  #2. worksheet 默认设置为0即第一个工作表
#3. 各种写操作……
ws.title='my sheet' #重命名sheet名字，默认名字为sheet
ws[1][1].value=111  #给第1行第1个单元格插入值111
#4. 保存
wb.save('/tmp/new.xlsx') #保存
```

`wb.active`返回第一个工作表对象，如果有多个工作表对象要操作，参看后文获取多个[工作表sheet](#工作表sheet)。

### 读的基本方法

1. 读取excel文件获取工作簿wb对象（使用`load_workbook()`）
2. 从工作簿对象中获取工作表ws对象
3. 操作工作表ws

```shell
from openpyxl import load_workbook

wb = load_workbook('test.xlsx') #1. workbook
ws=wb.active                    #2. worksheet
#各种读操作……
print(ws[1][1].value)           #获取第1行第1个单元格的值
```



## 工作簿对象的操作

### 获取工作表对象

获取所有工作表的名称：

```python
#返回工作表名称组成的list
wb.sheetnames
wb.get_sheet_names()
```



获取指定工作表：

```python
ws=wb.active     #获取活动的工作表 默认是第0个

#根据工作表名称获取工作表对象
ws=wb['sheet1']
ws=wb.get_sheet_by_name('sheet1')
```



遍历获取工作表：

- wb是一个可迭代对象，遍历ws获得的item是ws对象
- `wb.worksheets` 返回所有ws组成的list

```shell
for ws in wb:  #wb.worksheets
  print(ws.title)
```



选择活动的工作表：

`wb.active`只获取激活的工作表，默认就是第0个工作表：

```shell
wb.active=3  #激活第4个工作表
active_ws=wb.get_active_sheet()  #获取当前活动的工作表
```



### 创建、复制和删除工作表

创建工作表：

```python
ws= wb.create_sheet("sheet1")    #创建工作表对象 默认在最后添加新工作表
ws= wb.create_sheet("sheet1",0)  #最前面插入
ws= wb.create_sheet("sheet1",-1) #倒数第2个位置插入
```



复制工作表：

```python
source = wb.active
target = wb.copy_worksheet(source)
```



删除工作表：

```python
wb.remove(ws)  #传入要删除的ws对象
del wb['sheet'] #或者用del删除
```



### 保存工作簿对象

```python
wb.save('document.xlsx')

#保存工作簿为模版
wb.template = True
wb.save('document_template.xltx')
```



保存工作簿对象为流数据，如提供给web应用程序使用

```python
from tempfile import NamedTemporaryFile
from openpyxl import Workbook
wb=Workbook()
with NamedTemporaryFile() as tmp:
    wb.save(tmp.name)
    tmp.seek(0)
    stream = tmp.read()  #流
```



## 工作表对象的操作

### 工作表常用属性

```python
ws.title       #ws标题
ws.dimensions  #工作表大小（表格中的数据有几行几列）
ws.max_row     #最大行数
ws.max_columns #最大列数
ws.rows        #行生成器 其中的每一个item是一个tuple tuple包含各个cell对象
ws.columns     #列生成器 其中的每一个item是一个tuple tuple包含各个cell对象
```



### 遍历工作表

- 可迭代的行生成器/对象：`ws`、`ws.rows`、 `ws.iter_rows()`
- 可迭代的列生成器/对象：`ws.columns`、`ws.iter_cols()`

遍历行/列的每个item包含一个或多个cell对象，因此两层循环遍历即可操作到每个单元格对象：

```shell
for row in ws:  #row in ws.rows
	for cell in row:
	  #do something
	  
#可以指定一些参数限定要使用的行、列，如不指定则是遍历整个表格内容
for row in ws.iter_rows(min_row=2, max_row=5, min_col=1, max_col=2):
    for cell in row:
        print(cell.value)
```



### 删除工作表的行或列

```python
#插入 在第n行/列前插入
ws.insert_rows(7)
ws.insert_cols(7)

#删除第n行/列
ws.delete_rows(7)
ws.delete_cols(7)
#删除多个时传入多个行/列值
ws.delete_cols(6, 3)
```



### 向工作表追加数据`append()`

```python
data=[["user1","123"],["user2","456"]]
for row in data:
	ws.append(row)
```



## 单元格cell对象操作

### 一个单元格

- 以 横行字母+纵列数字 组成的单元格表示方式，如`A4`
- 以 指定行列的形式 表示单元格，使用`ws.cell()`方法

```python
cell_a4=ws['A4']
cell_a4=ws.cell(row=4,column=1)
```



### 多个单元格

- 指定开始和结尾的两个单元格：`ws[A1:C2]`

- 指定开始和结束的两个行号：`ws['A:C']`  ,`ws[1:3]`

- 指定某一行（字母或数字均可表示）：`ws[A]` `ws[5]` 

  ```python
  cell_range = ws["A1:C2"]
  for row in cell_range:
      for cell in row:
          print(cell.value)
  ```

  

### 单元格常用属性

```python
cell.value          #单元格内容
cell.number_format  #单元格内容格式 默认General
cell.font           #单元格字体
cell.row            #单元格所在的行
cell.column         #单元格所在列
cell.coordinate     #单元格坐标
```



### 公式

向单元格写入公式即可

```python
cell.value='SUM(A2:B2)'
```



### 合并、拆分和移动单元格

单元格合并拆分：

```python
ws.merge_cells('A2:D2')  #合并单元格
ws.unmerge_cells('A2:D2') #拆分单元格
```

移动单元格：

```python
#表示单元格D4:F10向上移动一行，右移两列。单元格将覆盖现有单元格。
ws.move_range("D4:F10", rows=-1, cols=2)
#移动中包含公式的自动转换
ws.move_range("G4:H10", rows=1, cols=1, translate=True)
```

