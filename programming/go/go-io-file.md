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

列出目录下的文件 os.ReadDir()

```go
 files, e := os.ReadDir(".")
 if e != nil {
    //do something
 }
 for _, file := range files {
    println(file.Name())
 }
```

 递归遍历所有层级的子目录 `filepath.Walk()`
 注意：其不会返回文件列表，需要在函数中自行处理，例如将文件信息写入到外部的slice中储存。

```go
  dir := "/path/to/dir"
  err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
      files = append(files, path)
      return nil
  })
```

  通配符遍历法 filepath.Golb()

```go
  // Note: Ignoring errors.
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

## ReadFile/WriteFile 一次性读/写所有内容

使用该方式要考虑处理文件的大小和运行系统的内存情况，不适合处理大文件。

```go
//读示例
data, err := os.ReadFile(file)
//而后对返回的[]byte数据进行下一步处理，参考后续文件读取方式处理的例子

//写示例，向指定文件写入二进制内容
err = os.WriteFile("file.bin", []byte{0x00, 0x01, 0x02, 0x03}, 0644)
```

## `os.Open()` 打开文件对象后读/写

```go
//读
f, err := os.Open(file)

//写
f, err := os.Open(file, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)

if err != nil {
		log.Fatalln(err)
}
defer f.Close()

//两种写入方法
file.Write([]byte("hello"))
file.WriteString("hello")

//读取方法
b, err := make([]byte, 4)  //按4个byte为一组读取
for {
    readTotal, err := file.Read(b) //一次读取指定字节的数据
    if err != nil {
        if err != io.EOF {
            fmt.Println(err)
        }
        break
    }
    fmt.Println(string(b[:readTotal]))
}
```



## `os.Open()`+ bufio包缓冲读写

bufio包提供了缓冲读写的功能，可以按行或按块读取和写入文件，适合处理大文件。



读文件使用`os.Open()`方法打开文件，写文件使用`os.OpenFile()`打开文件，使用buffio相关方法操作。

### `NewReader()`读

`bufio.newReader()` 创建reader对象，在`for{}`循环中对reader对象根据需要逐个读取，可以使用`ReadString()`和`ReadSlice()`等方法。

```go
f, err := os.Open(file)
if err != nil {
		log.Fatalln(err)
}
defer f.Close()

fileReader := bufio.newReader(f)  //创建reader对象
for {
    line,err:=fileReader.ReadString("\n")
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

```go
f, err := os.Open(file)
if err != nil {
		log.Fatalln(err)
}
defer f.Close()

fileScanner := bufio.NewScanner(f)
//fileScanner.Split(bufio.ScanLines)  //默认就是使用ScanLines分割，逐行读取
for fileScanner.Scan() {
	fmt.Println(fileScanner.Text())
}
```



### `bufio.newWriter()` 写

`os.OpenFile(file, mode, permission)`方法打开文件，mode是文件打开方式，常用模式组合：

- `os.O_RDWR|os.O_CREATE `  文件不存在会新建文件，文件如果存在，会从文件开始处用新内容覆盖原始内容
- `os.O_RDWR|os.O_APPEND` ： 文件必须存在，在文件末尾进行追加新内容
- `os.O_RDWR|os.O_TRUNC` ： 文件必须存在，打开文件的时候先清空文件

permission是文件权限，使用Unix文件基本权限位的数值表示法。

创建writer对象，writer对象可以使用`Write()`和`WriteString()`等方法。

```go
f, err := os.OpenFile(file, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
if err != nil {
		log.Fatalln(err)
}
defer f.Close()

fileWriter := bufio.NewWriter(f)
fileWriter.WriteString("test\n")
fileWriter.Flush()  //将所有的缓存数据写入存储中
```



## 内嵌文件读写embed.FS

`//go:embed`功能，可在编译时将资源文件内容直接打包到二进制文件，读写嵌入文件：

```go
//嵌入当前目录下的files目录
//go:embed files/*
var embedDirFS embed.FS

content, _ := fs.ReadFile(files, "files/hello.txt")
//其他处理代码

//也可以使用fs.Sub()访问目录中的文件
subFS, _ := fs.Sub(configDir, "files")
data, err := subFS.Open(string("hello.txt"))
//其他处理代码
```

注意：embed.FS读取文件的路径分隔符号只能是`/`，因此不要使用`filepath.Join()`，因为其在windows中会使用`\`作为路径分隔府，可以使用`path.Join()`。



go内置了一些对特定格式文件读写的包。

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



## 