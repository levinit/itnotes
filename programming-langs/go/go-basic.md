nDOC https://golang.org

文档 https://go-zh.org

---

# 基本设置和使用

## 重要环境变量设置

```shell
go env #查看go环境变量
```

- GOROOT：Go 语言安装根目录的路径

- GOPATH：自定义的若干工作区目录的路径的集合

  *一般安装后默认定义了`$HOME/go`这个工作区*

  ```shell
  export GOPATH=~/goworkdir1:~/goworkdir2:$GOPATH
  ```

- GOBIN：GO 程序生成的二进制可执行文件（executable file）的路径

- GOOS：操作系统，如linux

- GOARCH：平台架构，如amd64

- GO111MODULE：1.11+版本引入go模块管理模式后增加的变量。其取值：

  - `on`  使用Go 模块模式（需要 go.mod文件）：以`go.mod`配置内容查找模块，不会到`vendor`目录和`$GOPATH`中查找依赖模块，即使项目在`$GOPATH` 的目录下。
  - `off` 使用以前的GOPATH模式：会在`vendor`和`$GOPATH`查找依赖模块，即使项目在 `$GOPATH` 之外。
  - `auto`  默认值，只要存在`go.mod`文件（无论项目在什么位置）即会启用Go模块模式。

  

## 目录结构

工作区：存放go源码文件的目录

```shell
go-workspace1
├── bin （编译生成的可执行文件存放目录，可以定义到其他位置）
│   ├── prj1  （一个编译生成的可执行文件）
│   └── hello
├── pkg （包文件 预编译文件）
｜     └── hello.a
└── src  （源码目录）
    ├── prj1 （一个项目目录）
    │   └── prj1
    │   └── prj1.go
    └── hello （一个项目目录）
        └── hello.go
```



一般情况下，Go 语言的源码文件都需要被存放在环境变量 GOPATH 包含的某个工作区（目录）中的 src 目录下的某个代码包（目录）中。

## 源码文件

go源码文件以`.go`为后缀，源码文件的三种类型：

- 命令源文件：可以直接运行的程序。

  - 可以不编译而使用命令`go run`启动、执行。

  - 作为程序的运行入口，其是每个可独立运行的程序必须拥有的。

  - 文件中必须含有main package和main函数。

  - 目录下有一个命令源码文件，为了让同在一个目录下的文件都通过编译，其他源码文件应该也声明属于main包。

- 库源码文件：不能直接运行，用于存放程序实体，被其他代码引用（`import`）

- 测试源码文件

## 运行编译

```shell
#编译并运行
go run <go文件>
#编译
go build <go文件>
```

## 模块管理

- go modules包（通过`go mod get`安装）一般是域名形式

- 安装第三方包

  shell中执行：

  ```shell
  go mod get <包名>   #升级-u｜下载指定版本 go get package@version
  go mod download    #下载依赖的module到本地cache（默认为$GOPATH/pkg/mod目录）
  go mod edit        #编辑go.mod文件
  go mod graph       #打印模块依赖图
  go mod init        #初始化当前文件夹, 创建go.mod文件
  go mod tidy        #增加缺少的module，删除无用的module，会修正go.mod文件中的依赖
  go mod vendor      #将依赖复制到vendor目录下
  go mod verify      #校验依赖
  go mod why         #解释为什么需要依赖
  ```

参看[package包](#package包)



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



## 变量常量

- 声明、初始化和赋值

  - **变量赋值必须在函数内进行**： 因为go和c一样，所有的运算都必须在函数内进行，函数外进行运算是语法错误，函数体外进行结构体成员赋值相当于函数外进行运算。

    **每种数据类型都有其默认值**，但是声明时可同时进行初始化（给予初始值替代默认值）

    因此在函数外操作变量值的唯一途径就是声明并初始化，不可声明（或声明并初始化）后再次赋值。

    

  - 变量/常量类型可推断——可不声明变量类型（隐式/无类型）

  - 全局变量/常量声明必须使用`var`/`const`关键字

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

  - 变量/常量声明必须使用，否则编译报错

    不使用的变量可使用占位符`_`，示例应用场景：

    ```go
    fruits:=[]string{"香蕉","苹果"}
    for _,val:=range fruits{
      fmt.Println(val)
    }
    ```
    
    

- 变量/常量可见性命名规则

  - 大写字母开头的变量可导出，被其他包读取
  - 小写字母开头的变量不可被导出

- 常量类型：数字、布尔、字符串

- `iota`常量计数器：`const`行中使用了`iota`后，`iota`值被重置为0，每新增一行常量声明`iota`加一。

  ```go
  const a=iota   //a=0
  const b=1      //b=1
  const c=iota   //c=0
  ```

- 类型转换

  ```go
  <变量名>[:]=<目标类型>(<原类型>)
  ```



## 数据类型

- bool：true 和 false（默认值）
- 数字（整型默认值0，浮点型默认值0.0）
  - byte（unit8的别名） 表示ASCII码字符
  - rune（int32的别名，处理unicode）表示CJKV等复合字符
  - int和unit，以及int/unit 8/16/32/64
  - float32/64
- 复数 complex64/128
- unitptr（4或8字节）存储指针的 uint32 或 uint64 整数
- struct
- string  必须使用双引号`""`的UTF-8 字符串
- array  定长数组（不可更改元素数量），元素类型必须一致
- slice   [切片](#切片) 通过内部指针和相关属性引用数组片段实现变长方案的数组引用数据类型。  引用类型
- map  映射 无序的基于key-value的数据结构 引用类型
- channel   信号 关键字为`chan`    引用类型
- interface  接口
- function   函数 关键字为`func`

空指针值为`nil`，也是slice、map、chanel、interface和function的默认值

### 字符串拼接

- `+`拼接

  简单清晰。golang 字符串都是不可变的，每次运算都会产生一个新的字符串，从而产生很多临时的无用的字符串，会给 gc 带来额外的负担，影响性能。

- `fmt.Sprintf()`  模版插值

  多种类型拼接时较为合适使用。

  内部使用 []byte 实现，不产生临时字符串，但是内部逻辑增加额外判断，使用interface，性能受其影响。

- `strings.join()`

  join会先根据字符串数组的内容，计算出拼接之后的长度，然后申请对应大小的内存，一个个填入字符串。

  在已有字符串数组的场合，使用 `strings.Join()` 有比较好的性能。

- `buffer.WriteString()`

  `bytes.Buffer`组装字符串，无需复制，只需要将添加的字符串放在缓存末尾即可，使用`buffer.String()`获取最终字符串的值。

  以可变字符使用，对内存的增长也有优化，如果能预估字符串的长度，还可以用 buffer.Grow() 接口来设置 capacity。

  性能要求较高的场合，尽量使用 `buffer.WriteString()` 以获得更好的性能

```go
var str1="hello"
var str2=str1+",go" //str2="hello,go"

fmt.Sprintf("%s,%s", hello, world)
strings.Join([]string{hello, world}, ",")

var buffer bytes.Buffer
buffer.WriteString(str1)
buffer.WriteString(str2)
fmt.Print(buffer.String())
```



### 数组

```go
var 数组名 [数组长度]数组元素类型  //声明
var 数组名 数组元素类型=[数组长度]数组元素类型{元素1,元素2,元素n} //声明并初始化

var seasons =[4] string{"春","夏","秋"}
fmt.Print(seasons[1])
seasons.append("冬") //追加元素

```

- 数组元素必须同类型，数组长度不可变。

- 数组长度的值可省略（`[]`不可省略），则数组长度会被设置为实际数组元素个数

- 声明并赋值，可以省略`=`左侧的数组元素类型，`=`右侧的不可省略，能够省略到的最简洁的方式：

  ```go
  var arr = []int {1,2}
  ```

### 切片

GO语言切片是对数组的抽象。

- 切片可以改变元素个数，因此切片不需要说明其长度，声明的长度只是其初始长度。
- 切片可包含的元素个数称为容量（capacity），容量为可选参数，可以不声明。

```go
//常规声明法
var sliceName []type
//make声明法
var sliceName = make([]type,len,capacity)
```

- `append()`向切片添加元素

  如果切片空间不足以容纳足够多的元素，切片就会进行“扩容”，此时新切片的长度会发生改变。

  ```go
  var nums = make([]int, 0)
  nums=append(nums,1)
  ```



### map

```go
var varname map[type]type
var varname=make(map[type]type)
var varname=map[type]type{}
```



### struct

struct结构体是一种自定义类型：

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
var p1 Person
p1.name="lee"
p1.age=18
```

- 类型名：同一个包内唯一的标识符，自定义结构体的名称。

- 字段名：结构体中唯一的字段名称。同样类型的字段也可以写在一行。

- 字段类型：结构体字段的具体类型。

- 标签名：可选，使用反引号包裹，用于将struct处理为其他类型的数据（例如json）进行关系映射

  ```go
  type Person struct {
    Id int `json:"id"`
    Name string `json:"name" xml:"name"`
  }
  ```

  对Person的实例进行json转换时，json的将采用标签名中定义的属性名，如是使用`id`而非`Id`

  

匿名结构体，临时使用时：

```go
var user struct{Name string; Age int}
```



结构体map复制问题——提示类似`cannot assign to struct field map1[1].name in map`

go 中的 map 的 value 是不可寻址的。因为 map 的扩容的时候，可能会进行 key/val pair迁移，value 本身地址发生改变，因此value不支持寻址，因而无法赋值。

解决方法：**在建立结构体map时，声明存储为结构体地址**（使用`*`指针）而非具体的值，赋值时使用`&`取出结构体。

```shell
s := make(map[int]*person)
s[1] = &person{"tony", 20, "man"}
```



结构体转json问题——`struct field xxx has json tag but is not exported`

encoding/json 库可以很方便的处理 json 格式的数据，使用web库gin返回struct（或含map的struct）时会自行转换成json无需进行。

如果遇到该错误，将结构体中所有属性的名称首字母改为大写，首字母没有大写的属性将不会被导出，示例：

```go
type article struct {
	Id    int32  `json:"id"`
	Title string `json:"title"`
	Desc  string `json:"desc"`
	deleted  bool   //该属性首字母小写不会导出
}
```

因此，对于需要导出的属性将首字母改成大写即可。





## 信号channel

channel存在`3种状态`：

- nil，未初始化的状态，只进行了声明，或者手动赋值为`nil`

- active，正常的channel，可读或者可写

- closed，已关闭

channel可进行`3种操作`：

- 读
- 写
- 关闭

3种操作和3种channel状态可以组合出`9种情况`：

| 操作      | nil的channel | 正常channel | 已关闭channel |
| --------- | ------------ | ----------- | ------------- |
| <- ch     | 阻塞         | 成功或阻塞  | 读到零值      |
| ch <-     | 阻塞         | 成功或阻塞  | panic         |
| close(ch) | panic        | 成功        | panic         |

## 控制语句

C风格

- 条件分支

  - if...else

  - switch...case

  - select...case  只能用于channel操作，每个`case`中必须含有至少一个信号，语法参照switch...case，只是将switch换成select

    如果`select`的多个分支都满足条件，则会随机的选取其中一个满足条件的分支

  ```go
  if a==1 {
    //
  } else if a==2 {
    //
  }
  else{
    //
  }
  
  switch num {   //switch expression { case value: xxx default: xxx}
  case 1:
    //
  case 2:
    //
  default:  //默认选择分支
    //
  }
  ```

- for

  ```go
  for {} // 无限循环 或 for true {}
  for i:=1;i<10;i++{}
  ```

- `goto`

  ```go
  One:  //定义一个带名字One的代码块
  	fmt.Print("提示信息啊啊")
  goto One  //跳到代码块One
  ```

- `break`  终止本循环体  

- `contiune`  进入本循环体的下一次循环（跳过`contiune`之后的内容）

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

## 异常处理

 `go` 语言里是没有 `try catch` 的概念， `go` 语言的设计思想中主张：

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



## package包

- package
  - go的基本分发单位
  - 每个go语言源码文件内容开头（不含注释内容）需要一个package声明
  - 一个源码文件要生成可执行文件，必须有main package和main函数。
  - 一个目录下只能存在一个package

- import

  - 导入没有使用的包会造成编译不通过。

  - 如果在一个main package中导入其他包，会先初始化被导入包的变量、常量，执行被导入包的init函数（如果有），然后才执行main 中的init函数（如果有），最后执行main函数。

  - 重复导入的包只会被导入一次。

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



# 协程goroutine

> goroutine的概念类似于线程，但 goroutine是由Go的运行时（runtime）调度和管理的。Go程序会智能地将 goroutine 中的任务合理地分配给每个CPU。

创建一个协程，在调用函数的时候在前面加上go关键字即可：

```go
func hello() {
    fmt.Println("Hello Goroutine!")
}
func main() {
    go hello()  //创建协程调用
    fmt.Println("main goroutine done!")
}
```





```go
var cpus = runtime.NumCPU() //获取系统cpu数
runtime.GOMAXPROCS(N)  //N为一个数字 设置过可用cpu数量
```

