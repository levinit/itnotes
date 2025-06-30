[TOC]
# 环境变量

```shell
export PATH=/path-to-python/bin:$PATH
export PYTHONPATH=/path-to-python/lib/python*/site-packages
```

| 变量名        | 描述                                                         |
| ------------- | ------------------------------------------------------------ |
| PYTHONPATH    | PYTHONPATH是Python搜索路径，默认import的模块都从PYTHONPATH里面寻找。 |
| PYTHONSTARTUP | Python启动后，先寻找PYTHONSTARTUP环境变量，然后执行此变量指定的文件中的代码。 |
| PYTHONCASEOK  | 加入PYTHONCASEOK的环境变量, 就会使python导入模块的时候不区分大小写. |
| PYTHONHOME    | 另一种模块搜索路径。它通常内嵌于的PYTHONSTARTUP或PYTHONPATH目录中，使得两个模块库更容易切换。 |

- Python搜索模块的路径的先后顺序：
  1. 当前程序的主目录
  2. PYTHONPATH目录
  3. 标准连接库目录（一般在`/usr/local/lib/python*`）
  4. 任何的.pth文件的内容（如果存在的话），允许用户把有效果的目录添加到模块搜索路径中去.pth后缀的文本文件中一行一行的地列出目录。

```shell
pip show 模块名  #查看某个模块的安装路径
```

- 指定pip安装目录

  - 在用户家目录建立`.pip.conf`指定模块安装位置

    ```shell
    [install]
    install-option=--prefix=~/.local  #安装到~/.local
    ```

  - `pip install --user paramiko`指定其安装到家目录下。

  - `pip install --install-option="--install-purelib=/python/packages" package_name`

# 基础语法

## 书写格式

- 标识符大小写敏感


- 严格缩进

- 多行语句的行末使用反斜杠`\`  （ []、{}或 () 中的多行语句不需要使用反斜杠除外）

  ```python
  sum = a + \
          b + \
          c
  ```

- 一行书写多条语句使用分号`;`分隔

- 复合语句以冒号` : `结束（如if、while、def和class语句）

```python
print("Hello python")  #输出内容
print("what's your name?")
input()  #接受输入
str="hello"
ver1=3
ver2=3.6
#格式化
print("%s,I use python %d,version is %f" %(str,ver1,ver2))
```

## 编码格式

```python
#coding=utf-8
#或者
#-- coding:UTF-8 --
```
## 注释
使用井号`# `(hash symbol)注释。pyhon无多行注释，但可以使用三引号，达到多行注释的效果（注意缩进）：

```python
"""
	line1
	line2
"""
'''
	line1
	line2
'''
```

## 保留字

即关键字，不能用作标示符名称，可以导入`keyword`模块，然后使用` keyword.kwlist`查看。

# 数据类型

## 标准数据类型

- Number（数字）
  - 整数int
  - 浮点数float
  - 复数complex  在数字后面加上字母`j`
  - 布尔值bool
    - `True`  值为1
    - `False`  值为0
- String（字符串）
- None （空值）
- List（列表）
- Tuple（元组）
- Sets（集合）
- Dictionary（字典）

### 数字number

可以使用十六进制（以0x开头）和八进制（以0开头）来代表整数。

### 字符串string

用单/双/三引号（三引号可以使用单引号或双引号）包裹。

三个引号中使用单双引号、换行、斜杠`\`等**特殊字符均不用转义**。

- unicode字符串前面加上`u`或`U`
- 相邻字符串会连接起来（如'a''b'自动转成'ab'）

#### 操作字符串

- 拼接

  - 加号`+`

    字符符串和数字拼接时需要使用`str()`方法转换数字为字符串。

  - 占位

    - format方法，使用`{}`占位：`字符串{}.format(变量)`
    - `%`开头的占位符号，常用：``%s` 格式化字符串，`%d`  格式化整数，`%f`  格式化浮点数。

  - f-string（**python3.6及以上版本支持**）：`f'字符串{变量/表达式/函数}'`

  ```python
  a='hello-'
  b='-python'
  print(a+b)  #hello--python
  print("hello%s" %(b))  #hello--python
  print('{}{}!!!'.format(a,b))  #'hello--python!!!
  print(f'{a}{b}!!!')  #hello--pyton!!!
  ```

- 重复：星号`*`重复字符串  ——`str*N`

  str指字符串变量或字符串本身（下同）；N为重复次数，其为一个自然数。

  ```python
  str='yes'
  str*3  #'yesyesyes'
  str*0  #''
  ```

- 索引：方括号`[]`索引字符串中字符

  - 指定位置索引：`str[index]`

    index表示索引位置，第一个位置为0，最后一个位置为-1。

    ```python
    'abcd'[0]    #'a'
    'abcd'[1]    #'b'
    'abcd'[-1]    #'d'
    ```

  - 区间索引（切片）：`str[start:end:step]` 

    start：开始位置，如果省略则值为0；

    end：结束位置，如果省略则值为-1；

    step：步长（在开始和结束区间中截取长度），如果省略则取值为end-start。

    ```python
    'abcd'[0:2]   #'ab'
    'abcd'[0:-1]  #'abc'
    'abcd'[0:]    #'abcd'
    
    'abcd'[:]     #'abcd'
    'abcd'[::]    #'abcd'
    'abcd'[::-1]  #'dcba'
    
    #如果从开始索引为-1，结束索引，得到的是空字符串
    'abcd'[-1::]   #'d'
    'abcd'[-1:0]  #''
    ```

    **索引的结果不包括结束位置上的字符**（*类似数学的前开后闭区间概念*） 。

- `in`和`not in` ：见前文[成员运算符](#成员运算符)

- `r`或`R` ：原始字符串（即不转义） `print(r'\nabc\nabc')`结果是`\nabc\nabc`

#### 转义字符

使用`\`转义。此外python中特别的转义字符：

- `\`  在行尾时表示续行
- `\e`转义
- `\000`空
- `\other`其他的字符以普通格式输出
- `\`后可加上不带`0`或`0x`开头的八进制或十六进制数  
  - `\o12`和`\x0a`表示换行

### 列表list

使用方括号`[]`定义列表，列表内元素以逗号`,`分隔，列表的各个元素的数据类型可以不同。

```python
li=[1,"hello",True]
```

range也可以产生一个列表（前闭后开区间），不过直接返回列表 而是一个range对象 但可以用来遍历。

```python
print(range(1,3))    #range(1,3)  不会打印出来了[1,2]
for x in range(1,3):    #但是可以用于遍历
    print(x)    #1,2
```

#### 操作列表

- 拼接、重复和索引元素：[同字符串的相关操作](操作字符串)。

- 添加元素：`list.append(item)`

- 删除元素

  - `del list[index]`

  - `list.pop(index)` 

    如果index为空，则index将取值为-1。

  - `list.remove(item)`

  ```python
  list1=['x','y','z']
  list1.append('a')  #['x','y','z','a']
  list1.pop(0)  #['y','z','a']
  list1.del(0)  #['z','a']
  list1.remove('z')  #['a']
  ```


- 使用`List[index]`的方式进行索引（同上文字符串的索引方式）。

  ```python
  li[1]  #第1个元素
  li[-1]  #倒数第1个元素
  li[1:3]  #第1到第3个元素
  li[0:]  #第0到最后一个元素（即-1）
  li[:-2]  #倒数第二个到开始的元素（即0）
  li[0]='first'  #修改第0个元素
  li.append('new')  #添加一个元素
  del list[0]  #删除第0个元素
  
  max([1,2,3])    #3  返回最大值，还有min函数返回最小值
  #list(seq)  将元组转换为列表
  ```

- `len()`获取列表长度  （`len([1,2])`长度是2）

- `in`：

  ```python
  3 in [1, 2, 3]    #返回True  在列表中是否有某元素
  #在列表中迭代
  for x in [1, 2, 3]: 
    print(x, end=" ")
  ```

### 元组tuple

使用小括号，且不能修改元素的“列表”。

元组与列表类似，主要区别：

- **元组的元素不能修改**（如果某个元素是一个列表，可以修改该列表的内容）
- **元组使用小括号**
- **元组中只包含一个元素时，需要在元素后面添加逗号**，否则括号会被当作运算符使用。

```python
tup=(1,2,3)
tup1=(100,)
```

### 字典dictionary

大括号`{ }`创建的键值对（key-value pair)集合。

注意：字典中键值对是**乱序**的，且键不可重复。

```python
dict={'boy':7,'girl':5}
```

### 字典操作

- 获取值

  - `dict[key]`

  - `dict.get[key[,default-value]`

    default-value，当要取的键不存在，返回这个给定的值。

  ```shell
  dict={'boy':7,'girl':5}
  dict['boy']  #7
  dict.get('boy')
  dict.get('other','nobody')  #'nobody'
  ```

- 设置值

  `dict[key]=value`修改值，如果该键不存在，将会新建该键值对。

  注意：因为键值对是**乱序**的，不能认为先添加的键值对就在前面。

  ```python
  dict={'apple':7,'orange':5}
  dict[apple]=9  #{'apple': 9,'orange': 5}
  dict[pear]=2  #{'apple': 9,'orange': 5,'pear':2}
  ```

### 集合set

**无序且不重复**的元素集合。

使用大括号`{ }`或者`set()`函数创建集合。

注意：创建一个空集合必须用`set()` 而不是`{ }`，因为`{ }`是用来创建一个空字典。

```python
set={1,2,3}
set=set({1,2,3})
set=set({1})
```
## 数据类型转换 

```python
int(1.1)  #1
float(1)  #1.0
complex(1)    #(1+0j)
complex(1,0j)    #将 x 和 y 转换到一个复数，实数部分为 x，虚数部分为 y。x 和 y 是数字表达式。
str(12)    #'12'
chr(1)  #'1' 将整数转为一个字符
frozenset({1,2})  #转换为不可变集合
bool('hi')    #true
eval('abc')  #计算在字符串中的有效Python表达式,并返回一个对象
```
## 数据类型判断

- `type()`返回数据类型：一个参数--变量或数据内容
- `isinstance()`返回布尔值：两个参数--变量或数据内容，数据类型

```python
a=1
type(a)    #<class 'int'>
type(a)==int    #True
isinstance(a,int)    #True
```
## 推导式

推导式(comprehensions)，又称解析式）是Python的一种独有特性，用以从一个数据序列构建另一个新的数据序列的结构体。 共有三种推导：

- 列表(`list`)推导式

  > 列表推导式（又称列表解析式）提供了一种简明扼要的方法来创建列表。
  > 它的结构是在一个中括号里包含一个表达式，然后是一个`for`语句，然后是0个或多个`for`或者`if`语句。
  >
  > [item_exp_result for item in list if condition]

  *内置函数`filter(function,iterable)`方式等效于列表推导式，一般列表推导式速度更快。*

  

  前面的item_exp_result是列表生成元素表达式，可以是有返回值的函数。

  ```python
  nums1 = [i for i in range(10) if i%2==0] #nums = [i for i in range(10) if i%2 is 0]
  print(nums1)  #[0, 2, 4, 6, 8]
  nums2 = [i**2 for i in range(10) if i%2==0]
  print(nums2)  #[0, 4, 16, 36, 64]
  strs=["say"+str(i) for i in range(2)]
  print(strs)  #['say0','say1','say2']
  ```

- 字典(`dict`)推导式

  类似列表推导式，基本格式：

  > { key_expr: value_expr for key,value in collection if condition }

  ```python
  strings={'h':1,'i':2}
  strings = {value: key for key, value in strings.items()}
  print(strings)  #{1: 'h', 2: 'i'}
  ```

- 集合(`set`)推导式

  用法参考列表和字典推导式。



## 迭代器与生成器

迭代海量数据时，生成器（迭代器）内存使用更低，例如可迭代对象太大，无法完整地存储在内存中（如要处理的是大型文件，或构建超大列表），每次能够使用一部分时很有用。



### 迭代器

迭代器是可以用于迭代操作的对象。相比其他“可迭代对象”（如字符串、列表、元组、字典、集合），迭代器对象迭代器只能往前访问，不能后退，迭代访问完毕后不能再次访问。

字符串，列表或元组对象都可用于创建迭代器，迭代器有两个基本的方法：**iter()** 和 **next()**。

for循环访问迭代器对象，实际也是每次调用next()。

```python
iter1=iter([1,2,3,4])  #创建迭代器
next(iter1) #访问下一个元素，输出1
next(iter1) #输出2

for i in iter1: #此时迭代对象中只有3，4
  print(i)
```

### 生成器

使用了 yield 的函数被称为生成器（generator）。生成器是一个返回迭代器的函数，只能用于迭代操作。**生成器本质上就是一种特殊的迭代器。**

普通函数中用 return 返回一个值，函数立即退出，如果使用yield代替return，函数被调用时会返回一个生成器对象。

yield 对应的值在函数被调用时不会立刻返回，而是调用next方法时（本质上对生成器使用 for 循环也是调用 next 方法）才返回值。yield还能从其退出的地方继续运行（如果后面还有内容），不像return会立即退出函数。

```python
def double(n):
  yield n*2
  
x=double(2)  #x的值为一个生成器
next(x)   #4， 调用next，生成器中yield的值返回

def status():
  yield 'active'
  yield 'block'
  yield 'banned'
  
user_status=status()
next(user_status)  #'active'
```

### 生成器表达式

将列表推导式的中括号`[]`换成小括号`()`将返回一个生成器而不是一个列表：

```python
list1=(x * x for x in range(10))

#只有对list1生成器进行迭代时，才会返回x*x的值
for i in list1:
	print(i)
```

注意：每次调用generator函数都会创建一个generator对象，多次调用函数得到的生成器是互相独立的。

# 变量和运算符

## 变量

- 变量定义和赋值：`变量名=值`

  ```python
  a=b=c=1    #同时为多个变量赋相同的值
  x,y,x=1,2,3   #同时为多个变量赋不同的值
  a+b
  ```

- 常量

  `pi` `e`

- 私有变量：在变量名前面加上两个下划线`__`，其就变成了一个私有变量（private），只有内部可以访问，外部不能访问。

  示例参看[类的封装——访问限制](#访问限制)。
  
- `global`可以将变量提升为全局变量

- `nonlocal `在函数中声明，可以将变量作用域提升到该函数的外部函数到作用范围中

## 运算符

- 算数运算符

  同大多数编程语言一致，特别的有：

  - 混合计算时，整型会转换成为浮点数。

  - 数值的除法总是返回一个浮点数，要获取整数使用`//`操作符。

  - `**`平方  （也可以使用`math`模块中的`power`函数）

    ```shell
    3//2   #1
    2**2    #4
    ```

- 比较运算符
  
  同大多数编程语言一致
  
  
  
- 赋值符
  
  同大多数编程语言一致
  
  - 海象运算符`:=`  将赋值语句融合到其他饮用到被赋值变量的语句中
  
    ```python
    #普通写法
    pwd=input()
    if pwd != '1234':
      print('valid password')
    
    #海象赋值表达式
    if (pwd:=input()) !-'1234':
      print('valid password')
    ```
  
    
  
    
  
- 逻辑运算符
  
  - `and` 和
  - `or` 或
  - `not` 非
  
  
  
- 成员运算符

  测试实例中包含了一系列的成员，包括字符串，列表或元组。

  - `in`  在指定的序列中找到值返回 True，否则返回 False。
  - `not in`  在指定的序列中没有找到值返回 True，否则返回 False。

  

- 身份运算符
  - `is`  判断两个标识符是不是引用自一个对象

  - `is not`  is not 是判断两个标识符是不是引用自不同对象

  ```python
  a=1
  b=2
  a is b    #Fasle
  a is not b    #True  （注意is和not之间有空格）
  ```

  `is`和`==`以及`is not`和`!=` ：

  `is`（或`is not`)用于判断两个变量引用对象是否为同一个对象（或不同对象）， `==`（或`!=`） 用于判断引用变量的值是否相等（或不相等）。



# 流程控制

## if条件

if后的条件语句可以使用括号括起来，也可以不使用括号，条件后面需要以冒号`:`结束。

```python
num = 5     
if num == 3:            # 判断num的值
    print 'boss'        
elif num == 2:
    print 'user'
elif num == 1:
    print 'worker'
elif num < 0:           # 值小于零时输出
    print 'error'
else:
    print 'roadman'     # 条件均不成立时输出
```

### 三元表达式

在其他语言中三元表达为：`判断条件?为真时的值:为假时的值`

```javascript
const x=0
x==0?'数字是0':'数字不是0'
```

python写法：

```python
x=0
print('数字是0') if x==0 else print('数字不是0')
```

## 循环

break 结束循环。

continue 跳过后面的代码，直接开始下一次循环。

### while循环

```python
x = 1
while x <= 3:
    print(x)
    x = x + 1
```

while … else 在循环条件为 false 时执行 else 语句块：

```python
while expression:
    #code...
else:
    #code...
```

### for...in循环

```python
for item in range(1,3):
    print(item)
```

# 函数def

```python
def test(x):
    print('you input: %s' %x)

a=input()  #调用内建函数input()
test(a)  ##test函数调用
```

## 部分内建函数

介绍部分内建函数，具体参看相关文档。

- 键盘输入：`input()`

- 打印内容：`print() `

- `filter()` 根据提供的函数过滤序列，返回由符合条件元素组成的新列表对象。

  ```python
  a = [1, 2, 3]
  print(list(filter(lambda x: x % 2 == 0, a)))  #[2]
  ```

- `map()` 根据提供的函数对指定序列做映射，返回映射的新的迭代器对象。

  ```python
  a = [1, 2, 3]
  b = [-1, -2, -3]
  print(list(map(lambda x, y: x+y, a, b)))  #[0, 0, 0]
  ```

- `reduce()` 根据提供的函数对参数序列中元素进行累积运算。

  ```python
  from functools import reduce
  print(reduce(lambda x, y: x + y, [2, 3, 4], 0))  #9 #将[2,3,4]按照lambda进行运算，0+2+3+4
  ```

- `enumerate()`  将一个可遍历的数据对象(如列表、元组或字符串)组合为一个索引序列，同时列出数据和数据下标，一般用在 for 循环当中。`enumerate(sequence, [start=0])`  start是下标起始位置。

  ```python
  list1=['aaa','bbb','ccc']
  for i,v in enumerate(list1):
      print(i,v)
  ```

- `zip()` 将可迭代的对象作为参数，将对象中对应的元素打包成一个个元组，然后返回由这些元组组成的列表。

  ```python
  list(zip((1, 2, 3), (4, 5, 6)))  #[(1, 4), (2, 5), (3, 6)]
  
  dict1={'a':'aa','b':'bb'}
  dict2 = zip(dict1.values(), dict1.keys())
  print(dict(dict2))  #{'aa': 'a', 'bb': 'b'}
  ```

## 参数

- 默认参数值：在定义函数时对参数使用`=`赋予默认值，如果调用该函数时为传入参数的值则使用定义的默认值。
- 可变参数：如果不确定该函数要传入的参数个数时，定义函数时在参数前面写上`*`；调用该函数时，**所有参数自动组成一个元组tuple**。
- 关键字参数：也是可变参数，定义函数时在参数前面写上`**`；调用该函数时，**所有参数自动组成一个元组字典dict**。

```python
def func(x,*y,**z):
    print(x,y,z)
    
func(1,3,4,5,a=1,b=2)  #1 3 (4,5) {'a':6,'c':7} 

#编写一个程序时，执行语句部分思路还没有完成，这时你可以用pass语句来占位
def Name():
    pass
```

## 迭代器

- `item()`  `next()` 迭代(iterator)

  ```python
  list1=[1,2,3]
  it = iter(list1)
  print(next(it))  #1
  print(next(it))  #2
  print(next(it))  #3
  ```

- yield (` [jiːld]`)生成器(generator)

  带有 yield 的函数是一个生成器，调用该函数时并不是执行函数，而是返回一个 可迭代(iterable) 对象。

  

  通常的for循环迭代时，**所有数据都在内存中**（如果有海量数据的话将会非常耗内存）；

  而生成器每次迭代执行到yield语句时，函数就返回一个迭代值，下次迭代时，代码从 yield 语句的下一条语句继续执行。

  ```python
  def frange(start, stop, step):
      x = start
      while x < stop:
          yield x
          x += step
  
  
  for i in frange(1, 3, 0.5):
      print(i)
  ```


## lambda表达式

lambda只是一个表达式，而def则是一个语句。

lambda会创建一个函数对象，但不会把这个函数对象赋给一个标识符，而def则会把函数对象赋值给一个变量。

lambda一般只用来定义简单的函数（一般是匿名函数）

`lambda 参数:表达式`

```python
def add(x,y): return x+y
#改写
lambda x,y:x+y

arr1 = [1,-2,0]
print(sorted(arr1, key=lambda x: abs(x)))  #0 1 -2
```


## 闭包

> 闭包（Closure）是词法闭包（Lexical Closure）的简称，是引用了自由变量的函数。

```python
# a*x+b=y
def a_line(a, b):
    # def arg_y(x):
    #     return a*x+b
    # return arg_y
    return lambda x: a*x+b

line1 = a_line(1, 2)  #a_line返回一个函数 这个函数中保存了a,b（1,2）
print(line1(3))  #5
print(line1(5))  #7
```

## 装饰器

装饰器（Decorator）将被装饰的函数当作参数传递给与装饰器对应的函数（名称相同的函数），并返回包装后的被装饰的函数对象。
装饰器是一种语法糖，其使用闭包原理实现。

应用优点：

- 扩展原有函数的功能时，不需要修改原来的代码。
- 复用代码更为简洁。

```python
def decorator(func):  #与装饰器对应的函数
    def add_sth(*args, **kwargs):
        print('add a log for func')
        func()  #传入的被装饰的函数
    rturn add_sth

@decorator  # 装饰器
def fn():  # 被装饰的函数  fn
    print('I am fn')
```

*将被装饰的函数fn前面加上`@decorator`后，fn就被函数decorator给装饰了，fn将被当作参数传给deorator函数，deorator函数将返回被装饰后的新函数，该新函数实际上取代了原来的fn。*

# 面向对象

类是抽象的模板，是相同属性和函数的对象的集合，实例是根据类创建出来的具体的“对象”。

## 封装

```python
class Player():
    def __init__(self, name, hp):  #绑定实例化类对象的属性
        self.name = name
        self.hp = hp

    def print_role(self):  #类的方法
        print('%s:%s' % (self.name, self.hp))

user1 = Player('neo', 100)  #实例化对象
user1.print_role()  #调用类的方法
```

`__init__`方法作用是在实例化对象时绑定对象的属性；`__init__`方法的第一个参数永远是`self`，表示创建的实例本身。

class里面也能使用`pass`占位。

### 私有属性

在类中使用[私有变量](#变量)（在变量名前后添加`__`），以确保了外部代码不能随意修改对象内部的状态（访问限制）。

欲访问内部私有变量，可以为其定义一个方法实现。

```python
class user():
    def __init__(self, name, age):
        self.__name = name
        self.__age = age

    def print_info(self):
        print('%s:%s' % (self.__name, self.__age))

    def set_age(self, age):
        self.__age = age


neo = user('Neo', '30')
neo.print_info()  #Neo:30

neo.age = 100
neo.print_info()  #Neo:30

neo.set_age(100)
neo.print_info()  #Neo:100
```

## 继承

```python
class Human():
    def __init__(self,name,iq):
        self.iq=iq
        self.name=name
    def get_iq(self):
        print(f'I am {self.name}, My IQ is {self.iq}')

class AI(Human):  #继承Human类
    def __init__(self,name, iq):
        super().__init__(name,iq)
        
robot=AI('sky_net',5)
print(robot.get_iq())  #5
```

子类继承父类的属性和方法。

`super()` 函数是用于调用父类(超类)的一个方法。

- 定义子类时，将父类作为参数传给子类。

- 子类可以新增和覆盖父类的方法。

- 多重继承

  如果继承多个父类，则依次将这些父类作为参数传入。

  子类的多个父类中如果存在有同名方法，子类的实例调用该方法时，执行先被继承的父类的方法。

  继承顺序采用了深度优先原则确定，参看[深度优先搜索算法](https://zh.wikipedia.org/wiki/%E6%B7%B1%E5%BA%A6%E4%BC%98%E5%85%88%E6%90%9C%E7%B4%A2)。

  **应该慎重使用多重继承**，以避免过于复杂的继承关系。

## 多态

主要是为了解决**类型耦合**，从而实现代码的可扩展性。要实现多态，需要存在：

- 继承
- 重写
- 父类引用指向子类对象

> 实现多态的技术称为：动态绑定（dynamic binding），是指在执行期间判断所引用对象的实际类型，根据其实际的类型调用其相应的方法。

但同时python是弱类型语言，实际上并不需要规避类型的耦合风险，所以可以认为python本身就是多态的。



python动态绑定，无需专门定义重载。

> 仅当两个函数除了**参数类型和参数个数不同**以外，**其功能是完全相同**的，此时才使用函数重载，如果两个函数的功能其实不同，那么不应当使用重载，而应当使用一个名字不同的函数。

函数重载主要解决的问题：

- 可变参数类型

  python弱类型，无需重新定义函数以规定新类型的参数。

- 可变参数个数

  python有可变[参数](#参数)。

## 枚举类

```python
from enum import Enum
Role = Enum('role', ('admin','normal','guest'))
#或
# class Role(Enum):
#     admin = 1
#     normal = 2
#     guest = 3

Role.admin.value  #1
Role.admin.name   #male

for role in Role.__members__:
  print(role)  #打印 admin normal guest

def check_permission(role):
  if Role[role]==Role.admin:
   	print(f'role {role} has permission')

user1={'id':'123','role':'admin'}
check_permission(user1['role'])
```



# 异常处理

如果不使用进行异常处理，发生异常后会打印错误信息并且中止程序。

`try...except...finally`：

1. `try`后面是可能会出错的代码；

2. 如果`try`后面的代码出错就，则错误被捕获，跳至`except`处进行处理；

   `except`语句后可以包含错误类型和参数两个值：`except [ExceptionType][, Argument]:`

   多种错误要处理时添加多个`except`，被捕获的错误会跳到对应的错误类型的`except`语句处理。

   也不带任何异常类型直接使用`except:`，它会捕获所有类型的异常。

3. 如果有`finally`语句块，则执行`finally`语句块。

```python
try:
    print(10 / 0)  #除数为0  对应ZeroDivisionError
    print(10/a)  #a不存在 对应NameError
except ZeroDivisionError as e:
    print('zero:',e)
except NameError as e:
    print('not found:',e)
finally:  #无论有无错误，finally都会执行
    print('do it next time')
```

`raise`主动抛出错误：`raise [Exception [, args [, traceback]]]`

```python
n = 1.1
if n % 1 != 0:
    raise Exception('error')
print(n+1)  #不被执行
```

也可以自定一个错误类型的class，代替`Exception`。

## with

with语句是一种异常处理语句`try...except...finally`的简写方法。

```python
def write_sth():
    f = open("output.txt", "w")
    try:
        f.write("python之禅")
    except IOError:
        print("oops error")
    finally:
        f.close()
```

改为with语句：

```python
def write_sth():
    with open("output.txt", "w") as f:
        f.write("Python之禅")
```

离开 with 代码块时系统会自动调用 `f.close()` 方法关闭文件。

> 任何实现了 *__enter__()* 和 *__exit__()* 方法的对象都可称之为上下文管理器，上下文管理器对象可以使用 with 关键字。

自定一个类供class调用示例：

```python
class Test():
    def __enter__(self,*args):
        #code
     def __exit__(self,*args):
        #code
  
with Test():
    #code
```

## 调试

可用方法

- `print()`把可能有问题的变量打印出来

- 断言`assert`：`assert 表达式[,'调试信息']`

  如果`assert`后面的表达式的值是False，就执行断言展示调试信息。

  ```python
  def foo(n):
      n = int(n)
      assert n != 0, 'n is zero!'  #由于n!=0为False，断言AssertionError: n is zero!
      return 10 / n
  foo(0)
  ```

  启动Python解释器时可以用`-O`参数来关闭`assert`。

- 错误输出到文件：`logging`

  ```python
  import logging  #导入模块
  logging.basicConfig(level=logging.INFO)  #指定记录信息的级别
  ```

  log级别：`debug`，`info`，`warning`，`error`。

- pdb调试（以参数`-m pdb`启动）：`python -m pdb err.py`

# 模块

模块无需导出，直接导入python文件即可。

## 导入模块

模块名无需`.py`扩展名。

注意，自己编写的python文件名不要与已经安装的模块的库名重复。*例如不要将自己的py文件命令为urllib.py、queue.py，这些名字与标准类库名字相同。*

- 导入某个模块：`import 模块名`
- 导入某个模块中的某个函数：`from 模块名 import 方法名`
- 导入模块并为其定义别名：`import 模块名 as 别名`
- 导入未来可能会成为标准的模块：`import __模块名__`

可以使用逗号分隔多个导入的模块：`import 模块1,模块2`

## 常用标准库模块

参看python文档的标准库部分。

- `__future__`模块 将新版本的特性导入到当前版本

  例如在运行于python2.7的代码中导入`__future__`，可像python3.x一样使用`'a-unicode-str'`而不是`u'a-unicode-str'`表示unicode字符串（即不加`u`）。

- os模块  主要用于操作系统相关命令，如UNIX/Linux进程管理，文件目录操作等

  - 多进程：UNIX/Linux使用`os.fork()`，另有跨平台的multiprocessing模块。
  - 多线程：threading模块
  - 文件属性：`os.path`  `os.chown()`  `os.chmod()`等等 （参照Unix/Linux的各种命令行工具）
  - 操作文件：`os.open()`  `os.read()`  `os.write()`  `os.close()`等
  
- 执行shell命令：
  - os模块：`os.system()`  `os.popen()` 
  - command模块：`command.getstatusoutput()`
  - subprocess模块：`subprocess.call()`
  
- 正则表达式模块  re

- 时间相关模块：time datetime

- 数学库：math random statistics

- 

## json模块

json在pyton中是由list和dict组成。Json模块提供了四个功能

- dumps    数据类型转换成字符串
- dump      数据类型转换成字符串并存储在文件中
- loads       字符串转换成数据类型
- load         读取文件的字符串并转换成数据类型

JSON编码的格式对于Python语法一些小的差异： True映射为true，False映射为false，None映射为null。

提示：当数据的嵌套结构层次很深或者包含大量的字段时，通常很难通过简单的print来确定它的结构，可以考虑使用pprint模块的 `pprint()` 函数来代替普通的 `print()` 函数。



### getopt+sys读取命令行参数

- `sys.argv` 是命令行参数列表，第0个元素是python脚本自身。

- `getopt.getopt(args, options[, long_options])`

  返回一个tuple，包含两个为list的类型的元素，分别是选项和该选项对应的值

  - args  要解析的命令行参数列表（如`sys.argv[1:]`）

  - options  短选项（单个字符）组成的字符串

    如果一个字符后面有`:`，表示命令行中使用该选项必须指定一个值

    示例：`vhi:o:`，命令行使用`python test.py -h`

  - long_options  长选项（例如`--help`形式）组成的一个列表

    如果一个选项后面有`=`，表示命令行中使用该选项必须指定一个值

    示例：` ["help", "input=", "output=","version"]`，命令行使用`python test.py --input=test1.txt`

```python
try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:o:", ["help", "input=", "output=","version"])
        for opt, arg in opts:
            if opt in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif opt == "--version":
                print("sys.argv[0] version 0.1")
                sys.exit(0)
            elif opt in ("-i", "--input"):
                input_file = arg  #取到参数指定的值
            elif opt in ("-o", "--output"):
                output_file = arg
                
except getopt.GetoptError as err:
    print(err)
    sys.exit(2)
```





## 安装第三方模块

可使用`pip`或`easy_install`等工具安装



# python 加速

- numba   库，少量改动代码——在原python函数上加上numba装饰器

  可以在运行时将Python代码编译为本地机器指令。对数值运算很好，适用于计算密集型应用，支持异构计算

- cython   让Python脚本支持C语言扩展的编译器  需要重写代码

  将Python和C混合编码的.pyx脚本转换为C代码，用于优化Python脚本性能或Python调用C函数库。C扩展性能优异。

- pypy  带jit的解释器 无需改动代码

  直接用pypy运行py脚本即可，对CPython改良，纯python加速十分明显。

  对很多C语言库支持性很不好，调用c库的程序可能反而减速。
