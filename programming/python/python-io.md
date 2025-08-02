[toc]

# 基本用法

```python
f=open(<path/tofile>,[mode,...])  #返回文件对象用于读写
#do something
f.close() #关闭
```

`open()`不指定mode时，默认为`rt`（read text），以文本模式读。

读写模式：

- `r`：读read
- `w`：写write（清空内容）
- `a`：追加写append（不清空已有内容，等同于`w+`）
- `x`：新建文件并写入create（文件已经存在时会报错）
- `+`模式可读写，写为追加写，等同于`rw+`
- `r+`模式可读写，写模式将清空已有内容，等同于`rw`

读写数据类型：

- `t`  文本（text，默认模式）
- `b`  二进制（binary）



使用with语句读写文件，无需显式编写`close()`代码：

```python
with open(<path/tofile>,[mode,...]) as f:
    #do something
```



# 文件读取

使用`open()`打开文件，返回一个可迭代的文件对象，例如返回的对象命名为f，可对f使用以下方法读取：

- `read()`   方法  `f.read()`一次性读取所有内容，返回一个字符串。
- `readlines()`   方法`f.readlines()`一次性读取所有行，返回以行内容字符串作为元素的列表
- `readline()`  方法`f.readline()`每次迭代读取一行，返回一个字符串
- 使用for循环迭代文件对象，按行读取
  ```python
  with open('/etc/hosts','r') as f:
  	for line in f:
  		#do something
  ```

**一次性读取所有内容到内存操作更快；按行读取占用内存更小。**

- 文件对象可迭代，因此也可使用`next()`函数按行读取，`next(f)`返回当前迭代的行的内容（字符串）。



## 检测编码chardet

读取文件默认使用`UTF-8`，可在`open()`函数中使用`encoding=`参数指定编码格式。

对于不能确定文件编码的情况，可使用chardet模块检查编码：

```python
import chardet
with open('file1','r') as f
	res=chardet.detect(f)  #返回类似{'encoding': 'EUC-JP', 'confidence': 0.99}
```

返回值的`confidence`是猜测编码的准确率。

读取一个大文件，无需全部读取读完，可使用`universaldetector`（非贪婪模式）：

```python
import chardet
detector = chardet.universaldetector.UniversalDetector()
with open(file, 'rb') as f:
  for line in f.readlines():
    detector.feed(line)
      if detector.done:
        detector.close()  #返回类似{'encoding': 'EUC-JP', 'confidence': 0.99}
        break
```



# 文件写入

示例：

```python
with open('output_file', 'w', newline='') as f:
    #一些写入示例
    print('world',f)
    f.write(b'hello') #二进制
    f.write('new_info'.encode('utf-8'))
    f.writelines('a line with \n or \r\n')
```

换行符`newline`参数默认值为`None`，表示写入当前系统的默认换行符。



# 字符串I/O

使用操作类文件对象的程序来操作字符串I/O，可使用：

- `io.StringIO()`   用于文本数据
-  `io.BytesIO()`   用于二进制数据

```python
import io

s=io.StringIO()
s.write('111')
s.getvalue()  #'111'
s.close()
```



# 展开`~`为家目录

因为`~`不会被扩展识别为当前用户的家目录路径，可使用一下子方法实现：

```python
os.path.expanduser('~/abc')
#或者调用shell去执行：
os.system("mkdir -p ~/abc")
```

# 临时文件和目录

`TemporaryFile`模块

- 临时目录

  ```python
  from tempfile import TemporaryDirectory
  
  with TemporaryDirectory() as dirname:
      print('dirname is:', dirname)
      # Use the directory
      ...
  # Directory and all contents destroyed
  ```

- 临时文件

  - `TemporaryFile()`

    在大多数Unix系统上， `TemporaryFile()` 创建的文件都是匿名的，无法获取路径

  - `NamedTemporaryFile()`

    有名称的临时文件

  ```python
  from tempfile import NamedTemporaryFile
  
  with NamedTemporaryFile('w+t') as f:
      f.write('Hello World\n')
      # Seek back to beginning and read the data
      f.seek(0)
      data = f.read()
      print('file is : ', f.name)
  ```



# 序列化对象

> 序列化(Serialization)是将对象的状态信息转换为可以存储或传输的形式的过程。

反序列化则相反，将序列化后的内容还原。



pickle模块：

仅用于python对象，将一个Python对象序列化为一个字节流，以便将它保存到一个文件、存储到数据库或者通过网络传输。

序列化后的内容只能在Python内部使用。

反序列化则将存储的字节流内容创建python对象。

- 序列化对象

  - 存储到文件：`pickle.dump()`  
  - 转换为字符串：`pickle.dumps()`

- 反序列化对象

  - 从文件中恢复：`pickle.load()`
  - 从字符串恢复：`pickle.loads()`

  

json模块：也提供了`dumps()`、`dump()`、`loads()`、`load()`，与`pickle`用法一致，唯一的区别在于**JSON序列化后的格式为字符型**。


保存序列化对象到文件：

```python
import pickle

data = [1,2,3]
f = open('somefile', 'wb')
pickle.dump(data, f)
f.close()
```

注意：

> 不要对不信任的数据使用pickle.load()。
> pickle在加载时有一个副作用就是它会自动加载相应模块并构造实例对象。

从文件中读取并还原被序列化的对象：

```python
f = open('somefile', 'rb')
data = pickle.load(f)
f.close()
```
