文档  https://golang.org   https://go-zh.org 

---
[toc]

# 使用简介

安装golang。

## 环境变量

```shell
go env        #查看所有go环境变量
go env GOPATH #查看GOPATH环境变量
```

- GOROOT：Go 语言安装根目录的路径

- GOBIN：GO 程序生成的二进制可执行文件（executable file）的路径

- GOOS：操作系统

- GOARCH：平台架构，如amd64

- GOPATH：存放各种go包管理安装的包的目录，*在使用模块管理后该变量不再重要性*。

- GO111MODULE

  1.11+版本引入go模块管理模式后增加的变量

  1.17后该值默认为空，作用同`on`，新版本中该变量也将逐渐被忽略，[go modules模式成为默认行为](https://go.dev/blog/go116-module-changes)。参看[模块管理](#模块管理)

  - `on`  模块支持：即使项目在您的`GOPATH`中，也会强制使用Go模块，即使不存在`go.mod`文件。

    `go.mod`配置内容查找模块，不从`vendor`和`GOPATH`中查找依赖模块，即使项目在`$GOPATH` 的目录下。

    ```shell
    export GO111MODULE=on
    ```

  - `off`  无模块支持：从 `GOPATH` 和`vendor`依赖，即使项目在 `GOPATH` 之外。

  - `auto`  模块感知模式，仅当前目录或任何父目录中存在go.mod文件时使用模块模式。

## 源码文件

go源码文件以`.go`为后缀，每个go语言源码文件内容开头（不含注释内容）需要一个package声明，参看[package](#package包)。

源码文件的三种类型：

- 命令源码文件：程序入口，编译生成可执行文件

  一个包中的所有命令源码go文件中，必须有一个go文件存在main函数。

  go文件中的`init`函数（非必需存在）执行优先级高于主函数的执行优先级。

- 库源码文件：不能直接运行，用于存放程序实体，被其他代码引用（`import`）

- 测试源码文件



## 运行文件

go源码文件需要编译为二进制文件后运行。

```shell
#编译
go build         #为windows编译生成的文件将自动添加`.exe`后缀。
go build -o file #-o 指定输入文件

#编译并运行 | 实际上是编译生成二进制文件在临时目录中，然后运行
go run <file.go>
#对于有多个go文件的项目，指定路径，将执行含有main()的go文件
#go run <dir path>
go run .
```

更多编译相关内容参看后文[编译](#编译)。



## 模块管理

go module模式可以使各个项目的依赖库版本相互隔离。

目录结构相关：

```shell
path/to/your/project  #项目目录
 └── go.mod
 └── go.sum
 └── other files
 
GOPATH   #存放安装依赖库文件
 └── pkg
  └── mod  #各种下载到依赖
```

使用`go mod` 进行项目管理，所有操作都和`go.mod`文件紧密联系。

- 初始化项目目录`go mod init <project name>`

  将生成`go.mod`文件：

  ```shell
  #cd project dir
  go mod init <project name>
  #eg. mkdir proj1 && cd proj1 && go mod init proj1
  ```

- 常用操作命令

  ```shell
  #---操作当前module
  go mod download    #下载go.mod中的依赖的包到本地cache
  go mod edit        #编辑go.mod文件
  go mod graph       #打印模块依赖图
  go mod init        #初始化当前文件夹, 创建go.mod文件
  go mod tidy        #根据go.mod查漏补缺和删除多余module
  go mod vendor      #将依赖复制到vendor目录下
  go mod verify      #校验依赖
  go mod why         #解释为什么需要依赖
  
  #依赖相关
  go get <pkg_url>    #获取依赖，将变更go.mod
  go get -u           #更新所有依赖包
  go get -u <pkg_url> #更新指定依赖包
  ```

参看[package包](#package包)

另外，`go install`构建和安装二进制文件到全局——`GOPATH/bin`，以供直接使用。



## 工作区模式

Go 多模块工作区可以更容易地同时处理多个模块的工作，需要go 1.18+。

一个项目的目录中可能包含多个不同module模式的子项目，工作区模式可以让这些子项目复用相同的模块，一个模块也能方便地引用处于同于工作区的另一个模块。

```shell
#初始化工作区  生成go.work文件
go work init

#初始化子模块，加入到本工作区
go work init path/to/module_proj1 [/path/to/module_proj2]

#添加新的子模块
go work use /path/to/module_proj

#编辑go.work文件
go work edit

#将工作区的构建列表同步到工作区的模块
go work sync
```



## package包

package是go的基本分发单位，以目录划分package。

> ```shell
> project_dir
> ├── xx.go    #属于main包 包含main() 为程序入口
> ├── yy.go    #属于main包
> ├── a/       #package a ,package名字可以和目录名不同
> 	└── a1.go  #属于包 a
> 	└── a2.go  #属于包 a,包含main()
> ├── lib1/    #一个依赖包，任何文件都不含有main()
> 	└── a2.go  #属于包 lib1
> ```

- 每个go文件只能属于一个package，同一目录中所有go文件必须属于同一个package。

- 每个应用程序必须有且只有一个main package，执行时自动寻找其中的main()函数。

  应用程序指可生成可执行的程序，依赖包不需要main函数。

  

### 导出和导入

导出

- 函数或变量名字的首字母大写即表示其可以被从包外访问

- 一个包内的函数或者变量都是共享的

导入

- 如果在一个main package中导入其他包，会先初始化被导入包的变量、常量，执行被导入包的init函数（如果有），然后才执行main 中的init函数（如果有），最后执行main函数。

- 注册包引擎——不完全导入包：在包名前添加占位符`_ `（下划线 空格），将忽略该导入包中除了init函数之外的其他函数（无法使用该，包的其他函数）

  ```go
  import _ "package1"
  ```

- 导入包添加别名：在包名前添加别名和空格

  - 特殊别名`.` ：使用包的方法时可以省略包名

  ```go
  import (t "time")  //time包别名t
  import (. "fmt")   //使用fmt的方法即可省略包名 如fmt.Print可写为Print
  ```



### init函数

- 每一个包或每一个go文件中均可以包含一个或多个init函数
- init函数在所有程序在main函数前执行

一个程序尽量只使用一个init函数。

# 基本语法

```go
//一行注释 c风格注释 多行/* */
package main //程序所属包 必须在非注释内容的第一行
//导入包 需要双引号
import "fmt"
//可以这样导入多个包
import (
	"date"
  "time"
)

//const 变量名 变量类型=值 变量可不指明类型
const NAME string = "字符串" //const常量
var str1 = "hi"           //var变量

//类型声明 相当于类型别名
type ageInt int //一般类型声明 此处定义ageInt类型 其实际是一个int类型

type learn struct{} //结构声明

type newInterface interface{} //接口声明

//函数 func关键字
func hi() {
  name="neo"
	fmt.Println("hi",name)
}

//入口主函数 必须存在main()才能生成可执行文件
func main() {
	hi()
}
```



# 变量常量

- 变量/常量可见性命名规则

  大写字母开头的变量、函数、结构体可被其他包导入后读取，小写字母开头的变量只能在包内读取。

  同一包内的变量名不能重复。go的包特性相关内容参看[package包](#package包)。

  

- 全局变量/常量声明必须使用`var`/`const`关键字

- 变量/常量类型可推断——可不声明变量类型（隐式/无类型）

- **变量赋值必须在函数内进行**

  函数体外进行结构体成员赋值相当于函数外进行运算。

  **每种数据类型都有其默认值**，但是声明时可同时进行初始化（给予初始值替代默认值）

  因此在函数外操作变量值的唯一途径就是声明并初始化，初始化不可再次赋值，只能使用指针为其给定一个新值，`*varname=<new val>`：

  ```go
  var a=1
  a=2  // error
  *a=2 // pass
  ```

  

- 函数内局部变量/常量可使用`:=`简写语法省略关键字声明并赋值

- 可一次声明多个变量/常量

  - 单行模式：`,`分隔名称和值
  - 多行模式：`()`中可书写多行

  ```go
  const N1 int =1  //const常量
  var c,d = 1,2    //var变量
  
  //分组声明赋值
  var (
    num1 int  //声明
    str2 string = "hello" //声明并赋值
  )
  
  //简写模式 仅用于局部变量
  func test(){
    a,b:=1,2
  }
  ```

  

- 变量/常量声明后必须使用，否则不能编译通过。

  注意：变量只作为左值赋值是无法通过编译的

  ```go
  var n int
  n = 5 //无法通过编译
  _ = n //添加该行 使用_赋值可消除
  ```




- 常量类型：数字、布尔、字符串

- `iota`常量计数器：`const`行中使用了`iota`后，`iota`值被重置为0，每新增一行常量声明`iota`加一。

  ```go
  const a=iota  //a=0
  const b       //b=1
  const c       //c=2
  ```

  

- 类型转换

  ```go
  <变量名>[:]=<目标类型>(<原类型>)
  ```



# 数据类型

## 类型一览

- 基本类型

  - 布尔类型：`bool`，值`true`或`false`（默认值）

    

  - 字符串`string`  （默认值`""`）

    *字符串实际上是一片连续的内存空间，一个不可改变的字节序列*

    必须使用双引号`""`的UTF-8 字符串。字符串可以为空，但不能为nil。

    

  - 数字
    
    - 整型  （默认值0）
    
      `int8`、`uint8`、`int16`、`uint16`、`int32`、`uint32`、`int64`、`uint64`、`int`、`uint`和`uintptr`
    
      
    
      *`unitptr`（4或8字节）存储指针的 uint32 或 uint64 整数*
    
      
    
      另外以下两种实际是整型的类型别名：
    
      - `byte`： `unit8`的别名，只能表示ASCII码字符
      - `rune`： `int32`的别名，处理任何 Unicode 字符
    
      
    
    - 浮点型  （默认值0.0）
    
      `float32`和`float64`
    
    - 复数类型
    
      `complex64`和`complex128`

  

- 派生类型

  空指针值、slice、map、chanel、interface和function的默认值均为nil

  - 指针（Pointer）

    `*` 符号定义/声明一个指针类型，如`*int`是指向 int 类型值的指针类型。

    如果`*`在表达式中，则其为指针运算符，表示一个指针表量指向的存储单元，即变量的值。另外`&` 取地址符号，返回变量的内存地址。

  - 数组array

    定长数组（不可更改元素数量），元素类型必须一致

  - 切片slice

    通过内部指针和相关属性引用数组片段实现变长方案的数组

  - 映射map

    无序的基于key-value的数据结构

  - 信号channel： 关键字为`chan`

  - 接口interface

  - 函数function： 关键字为`func`

  - 结构体struct



## 数字

数值字面表示中使用下划线分段来增强可读性，如`400_200`即`400200`。

十六进制浮点字面量：以一个以2为底数的整数指数部分，由字母`p`或者`P`带一个十进制的整数字面量组成，`yPn`表示`y`乘以`2n`的意思，而`yP-n`表示`y`除以`2n`。

```go
0x1p-2     // == 1.0/4 = 0.25
0x2.p10    // == 2.0 * 1024 == 2048.0
```



一个rune值表示一个Unicode码点， rune字面量形式有几个变种，最常用的一种变种是将一个rune值对应的Unicode字符直接包在一对单引号中。

```go
'a'
'π'
'\u0061'
```

rune字面量由`\`开头的两个字符组成，则其为一个有特殊含义的字符，如`\n`

## 字符string

- 数字转字符串  `strconv.Itoa(1)`

### 字符串拼接

- `range`遍历

  ```go
  for _,v := range str{
    //do something for v, v is a character
  }
  ```

  注意，如果按索引遍历字符串（即`for i:=0;i<len(str);i++`方式），而字符串含有非ASCII字符，应当转换字符串为`[]rune`切片后再使用此方式遍历。

  *因为Unicode字符是变长的，如果字符串是`[]byte`切片（字节序列），直接对字符串进行索引操作，可能会得到错误的结果，因为一个 Unicode 字符可能由多个字节组成。

  

- `+`拼接

  适合简单少量的字符串拼接，使用`+`简明且性能最好。

  随着要拼接的字符串规模扩大，每次运算都会产生一个新的字符串，从而产生很多临时的无用的字符串，会给 gc 带来额外的负担，影响性能，大量拼接时性能差。

  

- `fmt.Sprintf()`  模版插值

  多种数据类型拼接为字符串，免去编写类型转换的代码。

  内部使用 []byte 实现，不产生临时字符串，但是内部逻辑增加额外判断，使用interface，性能受其影响。

  

- `strings.join()`

  将字符串数组拼接为字符串，数组规模很大时，该方式依然有极好的性能（优于`strings.Builder`和`bytes.buffer`）。

  join会先根据字符串数组的内容，计算出拼接之后的长度，然后申请对应大小的内存，一个个填入字符串。

  

- `strings.Builder`和`bytes.buffer`

  大规模字符串拼接场景下性能优异，灵活性也好。

  二者底层类似，都是用一个 []byte 类型的切片来存字符串，它们用法也类似，只需要将新增加的字符串放在buffer/builder对象的末尾，最终使用`.String()`方法输出字符串内容。

  因为`bytes.Buffer` 的 `String` 方法会把底层 []byte 转成字符串，这需要另外申请内存，而 `strings.Builder` 则不用，推荐使用Builder方法，性能更优。



```go
var str1="hello"
var str2=str1+",go" //str2="hello,go"

fmt.Sprintf("%s,%s", hello, world)
strings.Join([]string{hello, world}, ",")

//大量拼接操作使用Builder
var strBuilder strings.Builder   //var strBuf bytes.buffer
for i := 1; i <= 1000000; i++ {
  strBuilder.WriteString("test-----\n")
}
fmt.Print(strBuilder.String())
```



## 数组array

```go
var name [len]type  //声明

//声明并初始化
var name type=[len]type{item1,item2,item3,itemN
var name [...]type{item1,item2,itemN}  //使用...代替长度并初始化

var seasons =[4]string{"春","夏","秋","冬"}
var seasons =[...]string{"春","夏","秋","冬"}
                        
//如果设置了数组的长度，还可以指定下标初始化部分元素
arr4 := [5]int{1:20,3:40}  //初始化索引为 1 和 3 的元素    
```

- 数组元素必须同类型，数组长度不可变。

- 长度是数组类型的一部分，不同长度的数组不是同一个类型。

- 如果声明并初始化，数组长度的值可使用`...`，数组长度会被设置为实际给定的素个数

  

## 切片slice

*可理解为不定长数组*。

切片是对数组的抽象，它通过内部指针和相关属性引用数组片段，以实现变长方案。

- 切片可以改变元素个数，因此切片不需要说明其长度，声明的长度只是其初始长度。
- 切片可包含的元素个数称为容量（capacity），容量为可选参数，可以省略。

```go
//常规声明法
var sliceName []type
//数组元素也可以是数组
var 2dSlice [][]type

//make声明法
var sliceName []type =make([]type,len,capacity)
//make简写法
var sliceName = make([]type,len,capacity)

//声明并赋值
var s1=[] int {1,2,3 }   //int是类型，{1,2,3}为三个值
var s2=[][]{
  {"a","b"},{"c","d"}
}
```

- `append(sliceName,newItem)` 向切片添加元素，返回一个新的slice

  注意：需要使用一个变量接收返回值，append并不会改变原有slice，
  如果切片空间不足（超出原 slice.cap 限制）以容纳足够多的元素，切片就会进行“扩容”，此时新切片的长度会发生改变。
  
  ```go
  var nums = make([]int, 0)
  nums=append(nums,1)
  ```



## 结构体struct

struct结构体是一种**自定义类型**。

*struct数据结构与map有相通之处，但是不同于map可以声明并赋值；定义的结构体只是一种类型，需要先定义再实例化*。

```go
type 类型名 struct {
    字段名 字段类型 `标签名`
    字段名 字段类型
  }

type Person struct {
  gender string
  age int 
  name,city string
}

//必须实例化后才能使用结构体的字段
//方法1.1
var p0 = Person{"male",18,"Chengdu"}
//方法1.2  key-value对应模式赋值
var p1 = Person{gender:"male",age:18,city:"Chengdu"}

//方法2
var p2 Person
p2.name="lee"
p2.age=18
```

- 类型名：同一个包内唯一的标识符，自定义结构体的名称。

- 字段名：结构体中唯一的字段名称。同样类型的字段也可以写在一行。

  **如果首字母小写的话，则该字段无法被外部包访问和解析**，如需要go内置的json，toml等解析struct，就必须将字段名首字母大写。

- 字段类型：结构体字段的具体类型。

- 标签名：可选，使用反引号包裹，用于将struct处理为其他类型的数据（例如json）进行关系映射

  标签只对JSON、XML等某些解析器有意义，标签中有一些特殊的字符会被解析器识别，如：
  
  - `omitempty`  如果数据中没有提供这个字段，解析器也会忽略该字段；但是如果类型是引用类型，还需要添加`*`在类型前面。
  - `default:<default_val>`  为该字段赋值给定的值。
  - `"-"`  忽略该字段。
  
  ```go
  type Person struct {
    Id int `json:"id"`
    Name string `json:"name" xml:"name"`
    Group string `json:"-"`
    UUID int   //没有tag，也会忽略
    Permissions *[]string `json:"Permissions,omitempty"`
    Desc string `json:"desc,omitempty" default:"no desc"`
  }
  ```
  
  对Person的实例进行json转换时，json的将采用标签名中定义的属性名，如是使用`id`而非`Id`
  
  

匿名结构体，临时使用时：

```go
var user struct{Name string; Age int}
```



## 映射map

map是无序的键值对集合。

```go
var varname map[KeyType]ValType    //声明
make(map[KeyType]ValueType, [cap]) //make进行初始化 cap表示map容量
```

make初始化时，可指定map的容量，该参数不是必须的，但指定一个合适的容量预先申请内存有助于提升性能，避免在后续使用中频繁扩张浪费性能。获取cap容量使用`len()`。



map是引用类型，未初始化时默认的zero value是nil。map必须初始化才能赋值，三种使用方法：

```go
//方法1 声明--初始化--赋值
var map1 map[string]string     //声明 
map1 = make(map[string]string,10) //初始化（赋值）
map1["str1"]="abc"

//方法2 声明并初始化--赋值
var map1 = make(map[string]string)
map1["str1"]="abc"

//方法3 直接声明初始化赋值
var map1:= map[string]string{
    "a": "aa",
    "b": "bb",   //逗号必须
}
```

Interface定义动态结构体

```go
map[interface{}]interface{} 
```



注意：map是非线程安全的，多个线程或者协程对 map 进行写操作（例如插入或删除键值对），需要自己管理对 map 的访问，以避免数据竞争和其他并发问题，可使用[并发读写锁](#并发读写锁)或者[sync.Map](#sync.Map)。



### 结构体组成的map

如果*map*的值类型为*struct*结构体类型，那么是不能直接对*struct*中的字段进行赋值的。

提示类似`cannot assign to struct field map1[1].name in map`

go 中的 map 的 value 是不可寻址的。因为 map 的扩容的时候，可能会进行 key/val pair迁移，value 本身地址发生改变，因此value不支持寻址，因而无法赋值。

解决方法：**在建立结构体map时，声明存储为结构体地址**（使用`*`指针）而非具体的值，赋值时使用`&`取出结构体。

```shell
s := make(map[int]*person)
s[1] = &person{"tony", 20, "man"}
```



## 通道channel

Go使用channel通信来共享内存，实现并发的goroutine之间（以及goroutine和主线程之间）的连接，具体使用参看[并发编程](#并发编程)中channel使用的例子。



## 指针

变量是一种使用方便的占位符，用于引用计算机内存地址，而指针是一种指向内存地址的值，允许你在程序中访问内存中的数据，修改内存中的数据，或者在程序中通过指针来传递数据。

- `&`符号用于获取变量的内存地址

  将取地址符`&`放到一个变量前使用就会返回相应变量的内存地址，如`&User`。

- `*`符号用于获取指针指向的变量的值

这些情况可以考虑使用指针：

- 当**函数需要修改传入的参数**时

  使用指针传递可避免复制参数，节省内存和时间。

- 当**传递的参数数据类型较大**时

  使用指针可节省内存

- 当**传递**的参数是一个**结构体**时

  使用指针可以更方便地对结构体的字段进行修改

- 当需要**在函数之间传递多个参数**时

  使用结构体指针可以更方便地进行参数传递。

使用指针也有一些注意事项：例如在函数内部不能修改指针本身的值，也不能通过指针修改不可寻址的变量等

# 流程控制

## 条件分支

### if else

if...else if... else

```go
if a==1 {
  //
} else if a==2 {
  //
}
else{
  //
}
```



### switch case

```go
switch num {   //switch expression { case value: xxx default: xxx}
case 1:
  //
case 2:
  //
default:  //默认选择分支
  //
}
```



### select

select...case  只能用于[channel](#select控制)操作，每个`case`中必须含有至少一个信号，语法参照switch...case，只是将switch换成select。



## 循环

### for

```go
for {} // 无限循环 或 for true {}
for i:=1;i<10;i++{}
for k,v := range map{}
```

- range 关键字用于 for 循环中迭代数组(array)、切片(slice)、通道(channel)或集合(map)的元素。在数组和切片中它返回元素的索引和索引对应的值，在集合中返回 key-value 对。

  特别的：对通道的range进行的for循环会无限迭代，直到主动退出或者通道关闭。

  ```go
  for i:=range ch1{
    //do something
  }
  ```

  

- `break`  终止本循环体  

- `contiune`  进入本循环体的下一次循环（跳过`contiune`之后的内容）

- `goto`

  ```go
  One:  //定义一个带名字One的代码块
  	fmt.Print("提示信息啊啊")
  goto One  //跳到代码块One
  ```

  

## 函数

```go
func 函数名(参数1,参数2 参数类型) 返回值类型{}
func 函数名(参数1 参数1类型 , 参数2 参数2类型) (返回值1类型 返回值2类型){}

func max(m,n int) int{
  if m>=n{
    return m
  }
  return n
}
```

golang没有默认参数值特性。



## 异常处理

 `go` 语言里没有 `try catch` 的概念， `go` 语言的设计思想中主张：

- 如果一个函数可能出现异常，那么应该把异常作为返回值，没有异常就返回 `nil`
- 每次调用可能出现异常的函数时，都应该主动进行检查，并做出反应，这种 `if` 语句术语叫**卫述语句**

```go
func divisionInt(a, b int) (int, error) {
  if b == 0 {
    return -1, errors.New("除数不能为0")
  }
  return a/b,nil
}
res,err=divisionInt(100,6)
if err !=nil{
  fmt.Println(err.Error())
}else{
  fmt.Println(res)
}
```



# 并发编程

Golang基于多线程、协程实现，其协程实现称为goroutine，一个goroutine的栈在其生命周期开始时只有很小的栈（典型情况下2KB），大幅减少的创建和销毁开销，是其高并发的根本原因。

协程：独立栈空间，共享堆空间，用户控制调度，一个线程上可以执行多个协程，协程是轻量级的线程。

*goroutine的栈不是固定的，可以按需增大和缩小。*

*并发主要由切换时间片来实现"同时"运行，并行则是直接利用多核实现多线程的运行，go可以设置使用多核心运行。*

在go中创建一个协程只需要在调用函数前加上go关键字即可。

```go
go func(){}()

func fn1(){}
go fn1()
```

具体使用参看[goroutine-concurrency](goroutine-concurrency.md)



# 测试

## go test

go的test工具包用于编写单元测试，一个测试文件必须以`_test.go`结尾，测试文件的测试函数有三种，函数均以特定前缀开头：

|   类型   | 函数名前缀  |              作用              |
| :------: | :---------: | :----------------------------: |
| 测试函数 |   `Test`    | 测试程序的一些逻辑行为是否正确 |
| 基准函数 | `Benchmark` |         测试函数的性能         |
| 示例函数 |  `Example`  |       为文档提供示例文档       |

`go test`命令会遍历所有测试文件中符合以上命名规范的函数，生成一个临时的main包用于调用相应的测试函数，然后构建并运行、报告测试结果。

测试文件不会被`go build`编译到最终的可执行文件中。

```shell
go test #运行当前目录下的测试文件 等同于go test .
go -v test ./... #运行当前目录及所有层级子目录中的测试文件 -v 显示详细信息
```



## 单元测试函数

每个测试函数必须导入`testing`包，测试函数的基本格式（签名）：

```go
func TestName(t *testing.T){
    // ...
  t.Run(testName, func(t *testing.T) {
    //Fn1是要被测试的函数
			if _, err := Fn1(param1); err != nil {
        //t.Errorf()
				return
			}
		})
}
```

可参看[testing包文档](https://pkg.go.dev/testing)



# 常用标准库

## os

### 执行shell命令

使用`os/exec`，示例：

```go
cmdStr := "id | awk '{print $2}'"
cmd := exec.Command("sh", "-c", cmdStr)
output,err := cmd.CombinedOutput()
println(string(output))

//如果要分别获取标准输出和标准错误输出
cmd := exec.Command("sh", "-c", cmdStr)
var stdout, stderr bytes.Buffer
cmd.Stdout = &stdout
cmd.Stderr = &stderr
err := cmd.Run()
```

`CombinedOutput()`合并标准输出和标准错误输出的内容，返回数据类型为`[]byte`。

注意，如果shell命令使用了`|`，管道符，应当使用`sh -c <cmds>`（或`bash`等）来执行。



### 查找进程

`os.FindProcess(pid)`在unix上总是返回true，可以向进程发送信号以检测进程是否存在：

```go
 func checkFrpProcess(pid int) bool {
	process, err := os.FindProcess(pid)
	if err != nil {
		fmt.Println("Process not found", err)
		return false
	}
	err = process.Signal(syscall.Signal(0))
	if err != nil {
		log.Printf("Process %d is dead!", pid)
		return false
	}
	log.Printf("Process %d is alive!", pid)
	return true
}

fmt.Println(checkFrpProcess(1))
fmt.Println(checkFrpProcess(9999999))
```

### 文件读写

参看[go-io-file](go-io-file.md)

## runtime

### 调度控制

- runtime.Gosched() 重新调度

  让出CPU时间片，重新安排其他等待的任务运行：

  ```go
  //子协程
  go func(){
    //do something for a long time
  }()
  
  //主线程让出时间片，等待上面的协程
  runtime.Gosched()
  fmt.Println("done")
  ```

  

- runtime.Goexit() 退出协程

  立即终止当前协程，不会影响其他协程。

  如果当前协程存在defer语句，会先执行defer语句再终止。

  

- runtime.GOMAXPROCS() 控制最大并行核心数量

  默认值为当前系统所有在线的cpu逻辑核心数。

  ```go
  runtime.GOMAXPROCS(2)  //指定上限为2
  ```

  多核心并行计算适用于CPU密集型，IO密集型频繁切换CPU反而带来性能的损失。

  另外`runtime.NumCPU()` 返回前系统CPU核心 (**逻辑核心**)数量。

  

### 获取执行文件路径

`os.Executable` 可获取当前执行的go程序所在路径。

但是在编写程序的调试阶段，通常使用go run运行，程序被编译并放置在系统TMP目录中，使用`os.Executable()`获取到的路径在TMP目录的字子目录中，而`runtime.caller(0)`可获取go文件路径。

使用以下方法获取不同运行方法中当前项目的目录：

```go
var workdir string    //项目路径

exePath, _ := os.Executable()    //可执行文件路径
tmpDir, _ := filepath.EvalSymlinks(os.TempDir()) //系统临时目录

//可执行文件的目录的路径字符串 如果包含临时目录路径字符串 则判定为go run
if strings.Contains(exePath, tmpDir) {
	_, goFile, _, _ := runtime.Caller(0) //用runtime获取*.go程序入口文件的路径
	workdir = path.Dir(goFile) //获取*.go文件所在目录的路径
} else {
	workdir = path.Dir(exePath)
}
```



## 命令行参数

- 获取环境变量

  ```go
  os.getenv("HOME")  //获取变量HOME
  ```

- 获取按顺序传递的参数

  ```go
  os.Args[1]
  ```



### flag包

flag支持以下三种命令行格式，参数前面的`-`也可以换成`--`，单在flag库中，`--`并不是表示长选项的意思。

> ```shell
> cmd -flag
> cmd -flag=x
> cmd -flag x
> ```

flag默认生成简单的usage 说help列表，使用`-h` （或`--help` 或`-help` 亦可）即可，也可以自定义usage输出内容，参看实例中的方法重新设置`flag.Usage`的值（对应的函数）。



flag包提供了命令行参数解析：

```go
package main
import (
    "flag"
)
var version="1.0"

func main() {
  var (
    n string
    p *string
    v bool
    h bool
  )
    
  //从命令行获取选项的值
    
  //将-n参数的值赋值给name变量，如未指定-n则name默认值为user1 ，帮助信息为user name
  flag.StringVar(&name, "n", "user1", "user name")
  
  //这种方式返回的是*string类型,声明变量时定义为对应的指针类型
  port=flag.String("p", "80", "port") 
  
  //无需值的选项
  flag.BoolVar(&v, "v", false, "show version")  //选项-v后面无需指定值
  flag.BoolVar(&h, "h", false, "show help")  //即使不指定-h，flag也有默认的-h参数可用
  
  flag.Usage = usage //改变默认的usage（即-h展示的内容）
  
  flag.Parse() //开始解析
  
  //虽然flag有默认的-h可用，会展示每个选项的帮助信息，但是默认-h内容比较简单
  if h{
    flag.Usage() //覆盖了默认的-h行为，如果用户使用-h参数会调用usage函数
    os.Exit(0)
  }else if v{
    println("version"+version)
    os.Exit(0)
  }
}

//自定义一个usage函数代替flag默认的Usage
func usage(){
  println("A app \nversion: " + version + "\nUsage:\n")
  flag.PrintDefaults() //打印默认usage的列表
}
```



# 编译

## 跨平台编译

```shell
go build [options]  [-o output] <file.go>

#指定平台和架构编译
#以windows amd64为例 , -ldflags="-H windowsgui"可以隐藏终端窗口
env GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui" a.go

#显示支持的OS和Arch列表
go tool dist list
```



## 约束构建

Go 的构建系统提供了一些内置的构建约束，这些可以用于控制特定代码在哪些条件下被编译和运行。这些构建约束包括操作系统、架构、编译器、Go 版本等等。

- 操作系统：如 windows, linux, darwin（MacOS）, freebsd, openbsd, netbsd, solaris, android, dragonfly 等等。

- 架构：如 386, amd64, arm, arm64, ppc64, ppc64le, mips, mipsle, mips64, mips64le, s390x, wasm 等等。

- 编译器：如 gc（Go 自己的编译器）, gccgo（基于 GCC 的 Go 编译器）。

- Go 版本：可以使用构建标签来指定特定的 Go 版本，例如 go1.12。这个标签会匹配 Go 1.12 及其后的所有版本。

还可以自定义的构建标签，以控制不同的构建选项或者特性，在编译时用`-tags`指定即可，例如`-tags without_cgo`使用一个

*这些标签可以是任何你选择的字符串，只要它们满足 Go 语言的标识符规则（即由字母、数字和下划线组成，并且以非数字开头）。*


使用约束：

- 文件名约束

  文件名（不含`.go`后缀的部分）以`_`加约束标记结尾，只能使用系统和架构名字的约束标记，且只能使用一个标签，即最后一个`_`开头的标签，如果使用类似`test1_windows_amd64.go`，只有最后的`amd64`
  约束生效。

  - `file_linux.go`：只为Linux上编译
  - `file_darwin.go`：只为macOS（Darwin内核）上编译
  - `file_windows.go`：只为windows编译
  
- 构建标签

  go源码文件开头添加以`//go:build`开头的注释行，其后面使用约束标记，可以使用小括号及逻辑符号`!`（非）、`&&`（与）和`||`（或）

  示例：

  - Linux环境下编译： `//go:build linux`

  - 只在 Linux/386 或 Darwin/amd64 环境下编译：`//go:build darwin && amd64`

  - 非windows环境下编译： `//go:build !windows`






## 编译模式

`go build`默认编译模式为静态编译，gc（go自带的编译器go compiler）工具链中的链接器创建**静态链接的二进制文件**。

所有main package的文件被构建到可执行文件中，非main package的文件被构建到 .a 文件中。



使用编译选项`-builmode`指定模式。

- default   默认的模式



- archive Go静态链接

  **将非main package文件**编译为静态链接库，供其他go语言程序动态调用。

  源文件编译成Go语言静态库文件，如果包名为main会被忽略掉。

  > ```shell
  > Build the listed non-main packages into .a files. Packages named main are ignored.
  > ```

  

- shared  Go动态链接

  **将非main package 文件**编译为动态链接库，供其他go语言程序动态调用。

  在构建其他 go程序时使用 -linkshared 参数指定：

  ```shell
  #1. 先编译为shared库文件
  go install -buildmode=shared libName
  
  #2. 使用-linkshared 链接编译
  go build -linkshared file.go
  ```

  

- c-archive  C静态链接

  将**main package文件**编译成C语言可以使用的静态库`.a`文件。

  package main 中导出的方法（使用`// export` 标记，且该go文件需要导入`C`这个库）其他C程序可以静态链接该文件，并调用其中的方法。

  

  编译一个go链接库示例：

  go文件add.go内容：

  ```go
  package main
   
  import "fmt"
  import "C"
   
  func main(){}
   
  //export Add
  func Add(a, b int) int{
  	return a+b
  }
  ```

  编译add.go生成一个`.a`后缀的archive库文件和一个`.h`后缀的头文件：

  ```shell
  go build -buildmode=c-archive add.go
  ```

  

  C语言引用示例（使用上面的`add.so`）：

  ```C
  # include "add.h"
   
  int main(void) {
      Add(1, 2);
      return 0;
  }
  ```

  

- c-shared  C动态链接

  将**main package文件**编译成C语言可以使用的动态库`.so`或`.dll`文件。

  参看上面的c-archived例子，编译add.go生成一个`.so`后缀的动态链接库文件和一个`.h`后缀的头文件：

  ```shell
  go build -buildmode=c-shared -o add.so add.go
  ```

  然后使用C编译器编译，例如使用cc：

  ```shell
  cc myadd.c add.so
  ```

  由于是动态链接，因此也可以配置环境变量，让编译器自动搜索这些路径中的链接库文件和头文件：

  - `.so`文件所在目录要在动态链接库环境变量中

    - 在Linux系统中为`LD_LIBRARY_PATH`

    - 在Unix系统中为`DYLD_LIBRARY_PATH`

  - `.h`文件所在目录要在头文件环境变量`C_INCLUDE_PATH`或`CPATH`中

  

- exe  静态编译，编译成.exe文件，包名为main的忽略。

- pie   地址无关的可执行文件（安全特性，难以反编译）。

- plugin  将 package main 编译为一个 go 插件，并可在运行时动态加载。



## gccgo编译

默认参数情况下，gccgo比gc编译耗费时间更长，编译出的文件体积更大，但是性能略高，对go版本有一定要求。

```shell
go build -compiler gccgo <file.go>
```



## 减小文件体积

Go二进制文件包含 Go 运行时，以及支持动态类型检查，反射甚至紧急时间堆栈跟踪所必需的运行时类型信息，因此相对于不带运行时的语言，gc编译的可执行文件后体积更大。



- 去掉调试信息

  编译添加`-ldflags="-s -w"`，不会造成功能缺失，但是将缺失调试信息。

  - -s：忽略符号表和调试信息。

  - -w：忽略DWARFv3调试信息，使用该选项后将无法使用gdb进行调试。




- 使用[upx](https://github.com/upx/upx)缩小体积。

  ```shell
  upx --best <file.go>
  ```

  

- 使用[TinyGo](https://tinygo.org/)

  精简版本的go，用于嵌入式和WebAssembly场景。



##　编译优化

通过`gcflags='-m -l'`命令查看Go编译的优化决策

```shell
go build gcflags='-m -l -N'
```

- `-m`  逃逸分析

  输出内容中出现`escapes to heap` 表示出现了逃逸（逃逸到堆上）。

- `-l`  禁止内联编译（更好的观察逃逸情况，减少干扰。内联是把简短的函数在调用它的地方展开。）

- `-N`: 禁止编译优化



### 逃逸分析

> 当变量（或者对象）在方法中分配后，其指针有可能被返回或者被全局引用，这样就会被其他过程或者线程所引用，这种现象称作指针（或者引用）的逃逸(Escape)。

栈内存：程序中每个函数块都会有自己的内存区域存局部变量、返回地址、返回值等，这一块内存区域有特定的结构和寻址方式，其大小在编译时已经确定，寻址起来也十分迅速，开销很少，栈是自清理的。

堆内存：全局变量、内存占用大的局部变量、发生了逃逸的局部变量存在的地方就是堆。而堆内存没有特定的结构，也没有固定大小，其为线程级，使用堆内存的成本更大。



逃逸分析可确定一个对象是要放在堆还是栈上，一般遵循如下规则:

- 是否有非局部调用，如果有可能被引用，那通常会被分配到堆上，否则就在栈上

- 如果对象太大，无法放在栈区也是可能放到堆上

> 如果一个函数返回的是一个（局部）变量的地址，那么这个变量就发生逃逸



避免逃逸的好处:

- 减少gc压力，不逃逸的对象分配在栈上，当函数返回时就回收资源，不需要gc标记清除。

- 逃逸分析完后可以确定哪些变量可以分配在栈上，栈的分配比堆快，性能好（系统开销少）。

- 减少动态分配所造成的内存碎片。



避免内存逃逸：

1. 尽量减少外部指针引用，必要的时候可以使用值传递；
2. 对于自己定义的数据大小，有一个基本的预判，尽量不要出现栈空间溢出的情况；
3. Golang中的接口类型的方法调用是动态调度，如果对于性能要求比较高且访问频次比较高的函数调用，应该尽量避免使用接口类型；
4. 尽量不要写闭包函数，可读性差且发生逃逸。



# GC

触发GC的情况：

- 手动调用 runtime.GC 函数进行垃圾收集
- 申请内存时 runtime.mallocgc 会根据堆大小判断是否需要触发GC

- 监控线程 runtime.sysmon 定时调用

  > `runtime.sysmon`是Go语言运行时系统中的一个子系统，它负责监控程序的运行状态，包括内存使用情况、GC的执行情况、goroutine的状态等等

  当sysmon监控到堆内存超过一定阈值时，通知垃圾回收器来执行垃圾回收操作。

  

通过内置的 `debug.SetMemoryLimit` 函数可以调整触发 GC 的堆内存目标值，从而减少 GC 次数，降低GC 时 CPU 占用。

可使用以下环境变量实现对Go程序的内存限制：

- `GOMEMLIMIT`：设置 Go 程序的最大内存使用限制。

  值为：

  - `0`，无内存限制
  - 数字+容量单位（如1GB，大小写不敏感）
  - 正整数不带容量单位，则以字节为单位。

- `GOGC`：设置 Go 程序的垃圾回收策略。

  值为：

  - `off`或`0`，不会自动触发垃圾回收机制，垃圾回收只能手动触发。

  - `-1`，禁用垃圾回收机制

    这意味着垃圾回收机制将不会执行，而所有分配的内存将会一直保留在堆上，这可能会导致内存泄漏，大多数情况都不要使用该值。

  - 其他正整数值，表示当前内存使用量与垃圾回收后可用内存的比例。

    如`GOGC=100`（默认值）时，垃圾回收器将在内存使用量为可用内存的两倍时运行。

  

内存限制的一些使用建议：

- 对程序执行环境的可用内存有明确的把控时，使用内存限制，但是要预留一部分内存资源。
- Go语言程序可能会与其他程序共享有限的内存，不要将GOGC设置为off，因为这些程序通常与Go语言程序是解耦的。
- 部署到您无法控制的执行环境时，不要使用内存限制，特别是当程序的内存使用与其输入成比例时。
