# 文件信息

## 是否存在

- 判断文件是否存在

  ```go
  if _, err := os.Stat(file); os.IsNotExist(err) {
      log.Println("path not exist: ", file)
  }
  ```

- 判断文件是否为目录

  ```go
  f, _ := os.Stat(file)
  f.IsDir()  //返回true或false
  ```



# 目录遍历

- 列出目录下的文件 os.ReadDir()

  ```go
   files, err := os.ReadDir(".")
   for _, file := range files {
      println(file.Name())
   }
  ```

  

-  递归遍历所有层级的子目录 `filepath.Walk()`
   注意：其不会返回文件列表，需要在函数中自行处理，例如将文件信息写入到外部的slice中储存。

  ```go
    dir := "/path/to/dir"
    err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
        files = append(files, path)
        return nil
    })
  ```

  

-  通配符遍历法 `filepath.Golb()`

  ```go
  matches, _ := filepath.Glob("foo/*")
  var dirs []string
  for _, match := range matches {
    f, _ := os.Stat(match)
    if f.IsDir() {
        dirs = append(dirs, match)
    }
  }
  ```

  

# 文件读写

在Go中，读取文件内容，会得到一个字节切片（`[]byte`），并默认将字节（byte）以16进制的形式打印出来（即`0x`为前缀的16进制数字），默认的字符串编码为UTF-8。



## `ReadFile`和`WriteFile`

一次性读/写所有内容到内存进行处理，读写的数据类型都是字节切片：

```go
//读 ReadFile()
data, err := os.ReadFile(file)
//而后对返回的[]byte数据进行下一步处理，参考后续文件读取方式处理的例子

//写WriteFile()
//向指定文件写入二进制内容
err = os.WriteFile("file.bin", []byte{0x00, 0x01, 0x02, 0x03}, 0644)
```

不适合处理大文件，因为：

- 可能内存不足
- 读入内容的等待时间可能较长

因此使用该方式要考虑处理文件的大小和运行系统的内存等情况。



## 文件对象的字节切片读写

使用`os.OpenFile(file, mode, permission)`方法打开文件，mode是文件打开方式，常用模式组合：

- `os.O_RDWR|os.O_CREATE `  文件不存在会新建文件，文件如果存在，会从文件开始处用新内容覆盖原始内容
- `os.O_RDWR|os.O_APPEND` ： 文件必须存在，在文件末尾进行追加新内容
- `os.O_RDWR|os.O_TRUNC` ： 文件必须存在，打开文件的时候先清空文件

permission是文件权限，使用Unix文件基本权限位的数值表示法。

另外`os.Open()`是`os.OpenFile()`的简写方式，以只读方式打开，该方法无法指定打开模式。



1. 打开文件对象

   注意，打开文件后一定要关闭，对于写操作，关闭时的错误处理一般也不要省略。后文示例代码中省略了关闭的相关代码。

   ```go
   //读
   f, err := os.Open(file)
   
   //处理打开错误
   if err != nil {
   		log.Fatalln(err)
   }
   
   //关闭文件，处理错误
   defer func(f fs.File) { _ = f.Close() }(f)
   
   
   //写
   f, err := os.Open(file, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
   ```

   

2. 在文件对象上操作字节切片：

   ```go
   //两种写入方法
   file.Write([]byte("hello"))
   file.WriteString("hello")
   
   //读取方法，读取为字节序列，按需求转换为其他类型
   buf, err := make([]byte, 4)  //按4个byte为一组读取
   for {
       readTotal, err := file.Read(buf) //一次读取指定字节的数据
       if err != nil {
           if err != io.EOF {
               fmt.Println(err)
           }
           break
       }
       fmt.Println(string(b[:readTotal]))
   }
   ```



## 文件对象的`bufio`读写

`bufio`包提供了缓冲读写的功能，可以按行或按块读取和写入文件，适合处理大文件。

1. 使用或`os.OpenFile()`（读/写）或`os.Open()`（只读，是前者的简写模式，无法指定打开模式）打开文件对象
2. 使用`buffio`相关方法操作




### `NewReader()`读

`bufio.NewReader()` 创建一个 Reader 对象，然后在 for 循环中根据需要逐个读取数据。这种方法提供了更灵活的读取控制，可根据具体需求选择不同的读取方式。

常用读取方法：

- `Read(p []byte) (n int, err error)`

  读取数据到提供的字节切片中

  

- `ReadByte() (byte, error)`

  读取并返回单个字节

  

- `ReadBytes(delim byte) ([]byte, error)`

  读取直到遇到指定的分隔符，返回包含分隔符的字节切片

  

- `ReadString(delim byte) (line string, err error)`

  读取输入直到遇到指定的分隔符，返回内容包含换行符

  

- `ReadLine() (line []byte, isPrefix bool, err error)`

  读取一行数据，返回内容包不含换行符

  

- `ReadRune() (r rune, size int, err error)`

  读取单个 UTF-8 编码的字符

  

- `Peek(n int) ([]byte, error)`

  返回接下来的 n 个字节，但不移动读取位置

  

- `ReadSlice(delim byte) (line []byte, err error)`

  读取直到遇到分隔符，返回包含分隔符的字节切片。注意：返回的切片可能会被后续的读取操作修改。



`ReadString("\n")`和`ReadLine()`按行读取的区别：

- `ReadString("\n")` 会包含换行符，而`ReadLine()` 不包含。
- `ReadLine()` 可能会返回不完整的行，如果行太长超过了缓冲区；`ReadString("\n") `在内部处理长行，会自动扩展缓冲区。

```go
f, err := os.Open(file)
if err != nil {
		log.Fatalln(err)
}
defer f.Close()

fileReader := bufio.newReader(f)  //创建reader对象
//fileReader := bufio.NewReaderSize(sourceReader, size) //设置缓冲区大小，默认4K

for {
    line,err:=fileReader.ReadString("\n")
//    line,err:=fileReader.ReadLine()

    if err != nil{
    	if err == io.EOF{ //检测文件读取完毕
        	break //结束
    	}
        //错误处理
    }
    fmt.Println(line)
}
```



### `NewScanner()` 读

`bufio.NewScanner()` 创建一个 Scanner 对象，通过反复调用该对象的 `Scan()`方法，可以逐个读取按指定分割器分割的数据。每次 `Scan()` 返回 `true` 时，可以通过 `Text()` 或 `Bytes()` 方法获取当前的令牌（token）内容。



令牌是输入数据流中的一个逻辑单元，它可以是一行文本、一个单词、一个字符，或者任何其他由分割函数定义的数据片段，可使用`Split()` 方法设置分割仿佛吃。

每次调用 `Scan()` 方法时，Scanner 会读取并准备下一个令牌。

Scanner 在内部会动态调整缓冲区大小，如果遇到大于当前缓冲区的令牌，它会自动增加缓冲区大小，缓冲区的增长不会超过令牌大小（缓冲区大小 ≤ 最大令牌大小）。

缓冲区用于读取数据，最大令牌大小限制处理的数据。如果预期有大令牌，需要同时增加这两个值。

- 增加缓冲区大小：处理大文件，减少 I/O 操作。

- 增加最大令牌大小：处理可能包含非常长行的文件。



```go
f, err := os.Open(file)
fileScanner := bufio.NewScanner(f)

//缓冲区和令牌大小设置，可选
buf := make([]byte, 0, 64*1024)      //设置缓冲区大小（默认4KB）
fileScanner.Buffer(buf, 1024*1024)   //设置令牌大小默认64KB）(第二个参数)

//设置分割方式，可选，默认就是使用ScanLines分割，即逐行读取
//fileScanner.Split(bufio.ScanLines) 

for fileScanner.Scan() {
	fmt.Println(fileScanner.Text())
}
```

scanner相对于reader的场景：

使用 Scanner：

- 需要简单地按行或特定模式读取数据
- 处理的数据结构相对固定且规整
- 不需要对读取过程进行精细控制
- 处理的行或令牌长度（可修改，默认64KB）在可接受范围内

使用 Reader：

- 需要更精细地控制读取过程

- 处理二进制数据或需要精确控制读取字节数
- 可能遇到非常长的行或数据块
- 需要预览数据而不移动读取位置
- 处理复杂或非结构化的数据格式



### `newWriter()` 写

创建writer对象，writer对象可以使用`Write()`和`WriteString()`等方法。

```go
f, err := os.OpenFile(file, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)

fileWriter := bufio.NewWriter(f)
fileWriter.WriteString("test\n")
fileWriter.Flush()  //将所有的缓存数据写入存储中
```



## io包文件读写

###  `io.ReadAll()`读

`io.ReadAll` 函数可以一次性读取整个文件内容的字节切片：

```go
file, err := os.Open(filename)
content, err := io.ReadAll(file) //content是[]byte类型
```



### `io.ReadFull()`读

`io.ReadFull` 函数尝试**读取精确数量的字节**：

```go
file, err := os.Open(filename)
buf := make([]byte, numBytes)
_, err = io.ReadFull(file, buf)

//缓冲区对象也是可以作为ReadFull()的第一个参数的
file, err := os.Open(filename)
reader := bufio.NewReader(file) 
buf := make([]byte, numBytes)
_, err = io.ReadFull(reader, buf)

//处理buf数据 ...
```

`ReadFull(r io.Reader, buf []byte) (n int, err error)`第一个参数是可以是文件、网络连接、字符串等任何实现了 `io.Reader`接口的对象。

对于文件的读写，使`bufio`的reader对象，可以减少系统调用次数，特别是对于单次读取的数据较小（小于缓冲区大小），可能会提升性能。



### `io.WriteString()`写

`io.WriteString` 函数可以将字符串写入文件：

```go
file, err := os.Create(filename)
_, err = io.WriteString(file, content)
```



### `io.Copy()`复制写入

`io.Copy` 函数可以将一个 Reader 的内容复制到一个 Writer：

```go
sourceFile, err := os.Open(src)
destFile, err := os.Create(dst)
_, err = io.Copy(destFile, sourceFile)
```



### `io.TeeReader()` 同时读写

`io.TeeReader` 可以在读取数据的同时将数据写入另一个 Writer：

```go
func readAndLog(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return err
    }
    defer file.Close()

    logFile, err := os.Create("log.txt")
    if err != nil {
        return err
    }
    defer logFile.Close()

    teeReader := io.TeeReader(file, logFile)

    _, err = io.ReadAll(teeReader)
    return err
}
```



## 内嵌文件读写`embed.FS`

Go 1.16 引入的 `//go:embed` 指令允许在编译时将资源文件直接打包到二进制文件中，提供了一种便捷的方式来管理和访问静态资源。该功能由 `embed` 包实现。

```go
//嵌入单个文件

//go:embed version.txt
var version string

//嵌入多个文件或目录

//go:embed templates/* static/*
var content embed.FS

//结合 `html/template

//go:embed templates/*
var templateFS embed.FS

tmpl, err := template.ParseFS(templateFS, "templates/*.html")

//---操作嵌入的文件

//ReadFile()读取嵌入文件
content, _ := fs.ReadFile(files, "files/hello.txt")

//Sub()访问目录中的文件
subFS, _ := fs.Sub(configDir, "files")
data, err := subFS.Open(string("hello.txt"))
//其他处理代码

//WalkDir()遍历嵌入的文件
fs.WalkDir(embedDirFS, ".", func(path string, d fs.DirEntry, err error) error {
    //其他处理代码
})
```

注意：

- 路径分隔符：`embed.FS` 使用的路径分隔符始终是 `/`，不论操作系统如何。因此：

  - 不要使用 `filepath.Join()`，它在 Windows 上会使用 `\`。

  - 推荐使用 `path.Join()` 或直接使用 `/` 作为分隔符。

- 只读访问：嵌入的文件系统是只读的，不能修改嵌入的文件。

- 编译时嵌入：文件内容在编译时嵌入，运行时不能更改嵌入的内容。

- 模式匹配：`//go:embed` 支持通配符，如 `*.txt` 或 `**/*.png`。



## csv库

```go
//---读写CSV文件
file, err := os.Open("file.csv")
if err != nil {
	log.Fatal(err)
}
defer file.Close()

reader := csv.NewReader(file)
records, err := reader.ReadAll() // 读取 CSV 文件
if err != nil {
	log.Fatal(err)
}
for _, record := range records {
	fmt.Println(record)
}
```



## JSON库

使用前应当定义数据结构。如果允许定义的字段在JSON数据中不存在，可以参考[结构体struct](#结构体struct)章节对字段设置`omitempty`标签，如果要设置默认值可以使用默认值`default:`标签。

```go
//---读写JSON文件
file, err := os.Open("file.json")
if err != nil {
	log.Fatal(err)
}
defer file.Close()

var data interface{} //一个变量用以接受解析器的结果
if err:=json.NewDecoder(file).Decode(&data);err != nil {
	log.Fatal(err)
}
fmt.Println(data)
```



# 管道pipe读写

管道（Pipe）是 Go 中用于协程间通信的一种重要机制，其提供了一种强大的方式来协调 goroutine 之间的数据流。

根据不同应用场景选择合适的管道类型：

- 简单的内存中数据传输： `io.Pipe()`

- 需要系统级管道或进程间通信：`os.Pipe()`
- 网络通信的模拟和测试： `net.Pipe()`

这些管道类型都支持并发安全的读写操作，可以在不同的 goroutine 中进行读写。

注意正确处理错误，特别是 `io.EOF`，它表示管道已关闭。



## `io.Pipe()`

`io.Pipe()` 创建一个同步的内存管道，主要用于在内存中进行读写操作。

- 同步操作：写入会阻塞，直到所有数据被读取
- 适用于内存中的数据传输
- 无缓冲：数据直接从写入方传递到读取方

```go
import (
    "io"
    "fmt"
)

func ioPipeExample() {
    reader, writer := io.Pipe()

    go func() {
        defer writer.Close()
        io.WriteString(writer, "Hello from io.Pipe!")
    }()

    buffer := make([]byte, 100)
    n, err := reader.Read(buffer)
    if err != nil {
        fmt.Println("Error reading:", err)
        return
    }

    fmt.Println(string(buffer[:n]))
}
```



## `os.Pipe()`

`os.Pipe()` 创建一个系统级的管道，主要用于进程间通信。

- 系统级操作：使用操作系统的管道机制
- 可用于进程间通信
- 支持非阻塞 I/O（通过设置文件描述符的标志）

```go
import (
    "os"
    "fmt"
    "io"
)

func osPipeExample() {
    reader, writer, err := os.Pipe()
    if err != nil {
        fmt.Println("Error creating pipe:", err)
        return
    }

    go func() {
        defer writer.Close()
        writer.Write([]byte("Hello from os.Pipe!"))
    }()

    buffer := make([]byte, 100)
    n, err := reader.Read(buffer)
    if err != nil && err != io.EOF {
        fmt.Println("Error reading:", err)
        return
    }

    fmt.Println(string(buffer[:n]))
}
```



## `net.Pipe()`

`net.Pipe()` 创建一个内存中的网络连接，主要用于网络通信的模拟和测试。

- 模拟网络连接：在内存中创建一个全双工的网络连接
- 主要用于测试网络相关代码
- 支持 `net.Conn` 接口的所有操作

```go
import (
    "net"
    "fmt"
    "io"
)

func netPipeExample() {
    client, server := net.Pipe()

    go func() {
        defer client.Close()
        io.WriteString(client, "Hello from net.Pipe!")
    }()

    buffer := make([]byte, 100)
    n, err := server.Read(buffer)
    if err != nil {
        fmt.Println("Error reading:", err)
        return
    }

    fmt.Println(string(buffer[:n]))
}
```

