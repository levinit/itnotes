# 简介

C 是一门编译型语言，不支持垃圾收集（garbage collection），需要编写者自行管理内存。



`hello.c`程序示例：

```c
#include <stdio.h>

int main(void) {
    printf("Hello, World!");
    return 0;
}
```

main函数时所有C程序的入口，C语言的标准规定main函数必须返回`int`类型，main函数最后可以不写return语句（实际上现在的编译器也会加上`return 0`语句。）

更多参看[函数](#函数)章节。



编译执行（参看[编译程序](#编译程序)）：

```shell
gcc hello.c -o hello
./hello    #执行二进制文件
```



## 基本语法特性

- 注释

  -  `//` 单行注释
  -   `/* */`  单行或多行注释

- 无缩进

- 一条**完整的语句**结尾需要使用分号`;`，除了

  - `#`开始的行
  - `}`结尾的行

  注意一条完整的语句可以跨越多行，单独一个`;`的行为一个空语句。



## 版本

C语言自诞生到现在经历了多次标准迭代，如C89、C99、C11、C17、C2x 等，编译时可使用`-std`指定语言标准。

不同的编译器或编译器版本的默认`std`值可能不同。C99以后，可以使用`printf("__STDC_VERSION__ = %ld \n", __STDC_VERSION__);`打印该值，例如`201710`表示C17。



一些主流编译器版本的[预定义宏](#预定义宏)：

| 主流编译器版本的宏定义        | 说明       |
| -------------------- | ------------------------------------------------------ |
| `GNUC`                 | GCC 的主版本号     |
| `GNUC_MINOR`           | GCC 的次版本号     |
| `GNUC_PATCHLEVEL` | 补丁版本号     |
| `_MSC_VER`       | MSVC 的版本号       |
| `clang_major`    | Clang 的主版本号   |
| `clang_minor`    | Clang 的次版本号   |
| `clang_patchlevel` | Clang 的补丁版本号 |



# 变量

C 是一门静态类型语言，任何变量都有一个相关联的类型，并且该类型在编译时是可知的。

```c
//*类型  变量名*
 int  num;  //*声明*

//*类型  变量名 赋值符号  值*
 int  num1   =    1  ;  //*声明并初始化*
```



## 静态变量

在函数内部使用 `static` 关键字初始化一个 **静态变量（static variable）**，**全局变量默认就是静态的**，无需添加static关键字。

静态变量在创建时会自动设置为默认值，基本类型被被初始化0，静态数组则每个元素被初始化为0.

```c
int incrementAge() {
  static int age;   //static int age = 0;
  age++;
  return age;
}
```



## 变量作用域

>  C 程序中定义一个变量时，根据你声明它的位置，它会有一个不同的 **作用域（scope）**。

两种类型的变量：

- **全局变量（global variables）**：函数外部定义的变量。

- **局部变量（local variables）**：函数内部定义的变量，只有在函数内才能访问。

  局部变量默认是在 **栈（stack）** 上声明的，除非使用指针在堆中显式地分配。




## 常量

定义常量的两种方法：

- 类似变量的定义，但是在声明的前面带有 `const` 关键字

- 使用`#define`，无类型限定（编译器将自行推断）和类型检查，无需赋值符号 `=`，可以省略末尾的分号

  参看[宏](#宏和符号常量)

```c
const int A=1
#define B 2
```

*一般习惯约定常量的字母使用大写。*



# 数据类型

- 数字（算数），基本数据类型
- 枚举
- `void`
- 派生
  - [数组](#数组)
  - [指针](#指针)
  - [结构体](#结构体)



## 数字

每种数据类型中所存储的具体值是由实现和系统架构决定的，可以使用`sizeof()`获取某个数字类型的占用的字节数，如`sizeof(int)`。

- 整数

  `unsigned`前缀表示无符号整数

  | 类型           | 存储大小    | 值范围                                               |
  | -------------- | ----------- | ---------------------------------------------------- |
  | char           | 1 字节      | -128 到 127 或 0 到 255                              |
  | unsigned char  | 1 字节      | 0 到 255                                             |
  | signed char    | 1 字节      | -128 到 127                                          |
  | int            | 2 或 4 字节 | -32,768 到 32,767 或 -2,147,483,648 到 2,147,483,647 |
  | unsigned int   | 2 或 4 字节 | 0 到 65,535 或 0 到 4,294,967,295                    |
  | short          | 2 字节      | -32,768 到 32,767                                    |
  | unsigned short | 2 字节      | 0 到 65,535                                          |
  | long           | 4 字节      | -2,147,483,648 到 2,147,483,647                      |
  | unsigned long  | 4 字节      | 0 到 4,294,967,295                                   |

  一般64位系统中，`int`/`unsigned int`为4字节即32位。

  

- 浮点数

  | 类型        | 存储大小 | 值范围                 | 精度        |
  | ----------- | -------- | ---------------------- | ----------- |
  | float       | 4 字节   | 1.2E-38 到 3.4E+38     | 6 位有效位  |
  | double      | 8 字节   | 2.3E-308 到 1.7E+308   | 15 位有效位 |
  | long double | 16 字节  | 3.4E-4932 到 1.1E+4932 | 19 位有效位 |



## void

void表示没有可用的值，通常用于：

- 函数返回为空

  ```c
  void fn1();
  ```

- 函数参数为空

  ```c
  int fn2(void);
  ```

- 指针指向为空

  ```c
  void *malloc(size_tsize);
  ```



## 数组

数组是存储多个变量的变量：

```c
int nums1[3];  //声明
nums1[0]=1;    //对第0个元素赋值

int nums2[3]={1, 2, 3};  //声明并赋值
```



- 数组中的每个值都必须有 **相同的类型**

- 数组元素序号从0开始

- 一般需要定义数组的大小，不过以下方法也能不给定数组大小：

  - 声明并赋值数组，但实际上数组大小将由给定的元素值的个数确定

    ```c
    int nums3[]={1, 2, 3};   //虽然未定义数组大小，但给定了3个元素值，因此数组大小为3
    ```

    

  - `malloc`或`calloc`动态分配

    无法获取数组长度

    

  - 全局静态数组

    使用static前缀或使用`#define`宏，无法获取数组长度

    ```c
    static arr1[];
    //#define arr1[]
    int main(){
        arr1[1]=1;  //此时arr1数组将被填充为[0,1] (int类型未给定值时默认填充0）
        printf("%d\n", arr[0]);  //0
        printf("%d\n", arr[1]);  //1
        printf("%d\n", arr[10]); //0 此时arr1将继续填充0直到有10个元素
    }
    ```

    

  - 变长数组（variable-length array, VLA）

    不一定所有编译器都支持。



字符串也是一种char数组，参看[字符串处理](#字符串处理)章节。



## 指针

> 指针是某个内存块的地址，这个内存块包含一个变量。

在[函数参数传递](#参数传递)中，传递指针可以实现在函数内部修改函数外部的变量值；

传递对象或函数的引用，可避免消耗更多的资源来进行复制。



定义变量时在变量前使用`*`表示定义一个指针类型，`*`**指针运算符获取该地址指向的变量的值**：

```c
int b = 2;
int *addr = &b;        //*addr表示一个指针类型，
printf("%u\n", *addr); //2
*addr = 3;
printf("%u\n", *addr); //3
printf("%u\n", b);     //3
```



使用 `&` 运算符获取内存中该变量的地址值：

```c
int a = 1;
printf("%p", &a); //00000000005ffe5c (一个内存地址)

int addr=&a;  //可以将地址赋给一个变量
```



## 自定义类型typedef

使用`typedef`关键字定义新的类型。*一般习惯约定常量的字母使用大写。*

```c
//typedef existingtype NEWTYPE
  typedef int          WEEKDAY
```



## 结构体struct

结构体是一组由不同类型的值组成的集合。

```c
//struct <structName>{
 //变量...
//};

//定义结构体
struct person {
  int age;
  char *name;
};

struct person user1;  //结构体实例化  将一个变量的类型设置为指定结构体
//使用.运算符操作结构体实例的属性
user1.age=1;
user1.name="baby1";

//实例化时初始化
struct person user2={1, "baby2"};
```



也可以使用typedef简化处理结构体：

```　ｃ
typedef struct{
    int age;
    char *name;
} PERSON;

PERSON user3;
PERSON user4={1, "baby4"}
```



## 枚举enum

`typedef` 和 `enum` 关键字，我们可以定义具有指定值的类型。

举定义中的每个枚举项在内部都与一个自然数配对，第一个枚举项值为0，后续枚举值依次加1。

```c
//typedef enum{
 //值...   
//} TYPENAME;

//示例，定义一个名为SEASON的枚举变量
typedef enum{
    spring,  //0
    summer,  //1
    autumn,  //2
    winter   //3
} SEASON;
```





## 数据类型转换

### 强制类型转换

```C
//(type_name) expression;
int a=1;
double b=(double) a + 1.0;  //2.000000
```



### 隐式类型转换

隐式类型转换由编译器自动进行。

- 算数类型中低类型能够转为高类型

  ```mermaid
  graph LR
  int(int)-->unsignedInt(unsigned int)-->long(long)-->unsignedLong(unsigned long)-->long2(long long)-->unsignedLong2(unsigned longlong)-->float(float)-->double(double)-->longDouble(long double)
  ```

  ```c
  printf("%f\n", 1 + 0.1); //1.100000
  ```

- 算术转换

  常用的算术运算中不同类型之间的运算也遵循隐式转换规则和整型类型提升，但不适用于赋值运算符、逻辑运算符 && 和 ||。

  - 字符`char`必须转换为整数（C语言中字符类型和整型可以通用）
  - `short`类型转换为`int`类型
  - `float`类型转换为`double`类型




# 运算符

- 算数算术运算符

  - 二元算数运算符（需要两个数参与）：加`+`   减`-`   乘`*`   除`/`   取模`%`

  - 一元算数运算符（只需要一个数参与）：自增`++`    自减`--`

  

- 位运算符

  对整数数字转换位二进制后进行按二进制位运算。

  位与`&`    位或`|`    位非`~`    `^`位异或     左移位`<<`    右移位`>> `  （`a<<b`相当于$$a*2^b$$，`a>>b`相当于$$a/2^b$$）

  

- 赋值运算符

  `=`将右边的值赋给左边的变量。

  复合赋值运算符：二元算数运算符（加 减 乘 除 取模）或位运算符（除了`~`）和赋值运算符的结合，表示运算并赋值，如`-=`

  

- 比较运算符（关系运算符）

  相等`==`   不相等`!=`   大于`>`   小于`<`   大于等于`>=`   小于等于`<=`

  

- 逻辑运算符

  与`&&`    或`||`    非`!`

  

- 三目运算符（三元运算符）

  用于替换简单的if/else条件分支，可以被内联进表达式。

  ```c
  // <条件> ? <表达式> : <表达式>
  ```



- 指针运算符

  - `&变量名`  返回变量的地址

  - `*变量名`  指向一个变量 

    

- 成员运算符`->`和`.`

  用于引用类、结构体和公用体成员

  

- `sizeof`

  返回传入的变量占用的空间大小（以字节为单位的`size_t`类型，即 `unsigned int` 类型）。

  传入一个变量或数据类型名称，如果参数是数据类型名称，必须使用括号，即`sizeof()`形式。

  ```c
  short i=1;
  printf("%llu", sizeof xx );  //2 因为short为2字节
  printf("%llu", sizeof(int)); //4 因为int类型4字节
  ```



- `,`    顺序求值运算符

  按从左往右顺序求表达式，整个逗号表达式的值为最后一个表达式的值。

  ```c
  //表达式1, 表达式2
  int a,b,c;  //定义多个变量
  for(i=0,j=0;i<10;i++,j++){}
  ```

  

- `()`  函数调用，强制类型转换
- `[]`  数组下标运算



# 流程控制

## 条件分支

- if
- if...else
- if...else if...else

```c
if (条件) {
  /* 进行一些操作 */
} 

if (条件) {
  /* 进行一些操作 */
} else if {
  /* 进行另一些操作 */
} else{  //  根据具体情况，最后的else分支也不是必须的
  /* 进行另一些操作 */
}
```



- switch...case

  ```c
  switch (a) {
    case 值1:
      /* 进行一些操作 */
      break;
    case 值2:
    case 值3: //两个值进行相同操作时，依次写出case分支
      /* 进行另一些操作 */
      break;
    default:
      break;
  }
  ```



## 循环

- for

  ```c
  for (int i = 0; i <= 10; i=i+1) {
    /* 反复执行的指令 */
  }
  ```

  

- while

  ```c
  int i=1;
  while(i<10){
      //一些指令
      i++;
  }
  ```



- do...while   先执行do后面括号中的语句，然后再判断while，如果判断结果为真，则继续执行do后面括号中的语句。

  ```c
  int i = 0;
  do {
    //做点事情 //这些语句至少会执行1次
    i++;
  } while (i < 10);
  ```



以上循环的`{}`中均可以使用`continue`立即跳过后面的语句，使用`break`跳出当前循环。

```c
int i = 0;
while (i <= 5) {
    i++;
    if (i == 2) {
        continue;
    }
    if (i == 4) {
        break;
    }
    printf("%d\n", i);
}  //只会打印出 1 和 3两行
```



# 字符串处理

C语言中是一种由`char`值组成的[数组](#数组)：

```c
//常规数组声明赋值方法
char name1[2] = { "h","i"};

//字符串字面量（也被称为字符串常量）声明赋值方法
char name2[2] = "hi";
```

C 提供了一个标准库`string.h`用于操作字符串，其提供了一些常用的函数：

- `strcpy()`：将一个字符串复制到另一个字符串
- `strcat()`：将一个字符串追加到另一个字符串
- `strcmp()`：比较两个字符串是否相等
- `strncmp()`：比较两个字符串的前 `n` 个字符
- `strlen()`：计算字符串的长度



# 函数

> 函数是一组一起执行一个任务的语句。每个 C 程序都至少有一个函数，即主函数 **main()**。

定义一个函数，其包括的部分：

- 返回值

  如果没有返回值则使用`void`关键字；

  返回值的数量不能超过一个。

  

- 函数名

  

- 参数（使用`()`包裹）

  必须声明数据类型

  

- 函数体（使用`{}`包裹）

```C
return_type function_name( parameter list ){
   body of the function
}

//例子
int sum(int a, int b){
    return a+b
}
```



调用函数之前必须先定义该函数。

main函数作为程序入口，无需显示调用。



## 参数传递

调用函数时，有两种向函数传递参数的方式：

- 传值调用

  把参数的实际**值复制**给函数的形式参数，修改函数内的形式参数不会影响实际参数。

  

- 引用调用

  把参数的**指针传递**给函数的形式参数，当对形参的指向操作时，就相当于对实参本身进行的操作。



## 可变参数

可选参数列表：`...`，需要使用 `stdarg.h` 头文件，该文件提供了实现可变参数功能的函数和宏，常用的有：

- `va_start(ap, last_arg)`

  初始化可变参数列表。`ap` 是一个 `va_list` 类型的变量，`last_arg` 是**最后一个固定参数的名称**（也就是可变参数列表之前的参数）。该宏将 `ap` 指向可变参数列表中的第一个参数。

- `va_arg(ap, type)`

  获取可变参数列表中的下一个参数。`ap` 是一个 `va_list` 类型的变量，`type` 是下一个参数的类型。该宏返回类型为 `type` 的值，并将 `ap` 指向下一个参数。

- ` va_end(ap)`

  结束可变参数列表的访问。`ap` 是一个 `va_list` 类型的变量。该宏将 `ap` 置为 `NULL`。



参看以下示例：

```c
#include <stdio.h>
#include <stdarg.h>  //va_start等函数需要该头文件
 
double average(int num, ...)  //可变参数放在最后，使用...
{
    va_list valist;   //创建一个va_list类型变量
    double sum = 0.0;
    int i;

    //使用va_start() 函数为 num 个参数初始化 valist
    va_start(valist, num);

    //访问所有赋给 valist 的参数
    for (i = 0; i < num; i++)
    {
       sum += va_arg(valist, int);  //使用 va_arg() 宏和 va_list 变量来访问参数列表中的每个项。
    }
    //清理为 valist 保留的内存
    va_end(valist);

    return sum/num;
}
```



## 命令行参数

命令行参数使用`main()` 函数参数处理。



一般习惯<u>约定</u>使用以下变量作为形参：

- `argc`：指传入参数的个数

- `argv[]`：指向传递给程序的每个参数的指针数组

  **`argv[0]`** 存储程序的名称，**`argv[1]`** 是一个指向第一个命令行参数的指针，`*argv[n] `是最后一个参数。



Linux下可使用`getopt`（处理短选项）、`getopt_long`和`getopt_long_only`解析命令行选项参数，形如`./app1 -i input1.txt -verbose`



```C
int main(int argc, char *argv[]){
    char *optstr = "i:";
    struct option opts[] = {
        {"input", 1, NULL, 'i'},
        {0},
    };
    int opt;
    while((opt = getopt_long(argc, argv, optstr, opts, NULL)) != -1){
        switch(opt) {
            case 'i':
                strcpy(path, optarg);
                break;
            case '?':
                if(strchr(optstr, optopt) == NULL){
                    fprintf(stderr, "unknown option '-%c'\n", optopt);
                }else{
                    fprintf(stderr, "option requires an argument '-%c'\n", optopt);
                }
                return 1;
        }
    }
    findInDir(path);
    return 0;
}
```





## 函数返回字符串

- 将字符串指针作为函数参数传入，并返回该指针。

- 使用malloc函数动态分配内存，注意在主调函数中释放。

  ```c
  char *getStr() {
      char *str;
      str = (char *) malloc(15);
      gets(str);
      return str;
  }
  
  int main() {
      char *str = getStr();
      puts(str);
      free(str); //release memory
  }
  ```

  

- 返回一个静态局部变量。

- 使用全局变量。



# 输入输出

C语言定义了三种类型的 I/O 流，流是一个高级接口，可以代表一个设备或文件（C 语言把所有的设备都当作文件）：

- 标准输入设备  `stdin`
- 标准输出设备  `stdout`
- 标准错误输出设备 `stderr`



C 的标准库在 `stdio.h` 头文件中定义了一组输入/输出函数，这些函数都和特定的流绑定。



- 格式化输入/输出

  可使用占位符，常用：`%d` 十进制整数    `%c` 字符    `%s` 字符串    `%f` 浮点数    `%p` 指针

  均返回一个`int`类型的数字。

  - `scanf()`   从`stdin`读取

  - `sscanf()`   从字符串读取

  - `fscanf()`   从文件流读取

    | 类型      | 合格的输入                                                   | 参数的类型     |
    | --------- | ------------------------------------------------------------ | -------------- |
    | c         | 单个字符：读取下一个字符。如果指定了一个不为 1 的宽度 width，函数会读取 width 个字符，并通过参数传递，把它们存储在数组中连续位置。在末尾不会追加空字符。 | char *         |
    | d         | 十进制整数：数字前面的 + 或 - 号是可选的。                   | int *          |
    | e,E,f,g,G | 浮点数：包含了一个小数点、一个可选的前置符号 + 或 -、一个可选的后置字符 e 或 E，以及一个十进制数字。两个有效的实例 -732.103 和 7.12e4 | float *        |
    | o         | 八进制整数。                                                 | int *          |
    | s         | 字符串。这将读取连续字符，直到遇到一个空格字符（空格字符可以是空白、换行和制表符）。 | char *         |
    | u         | 无符号的十进制整数。                                         | unsigned int * |
    | x,X       | 十六进制整数。                                               | int *          |

    

  - `printf()`   写入到到`stdout`

  ```c
  char str[100];
  int i;
  scanf("%s %d", str, &i);
  printf( "\nYou entered: %s %d ", str, i);
  
  char buf[128];
  sscanf("hello", "%s", buf);
  
  char str1[100], str2[100];
  FILE * fp;
  fp = fopen ("/etc/hosts", "w+");
  fscanf(fp, "%s", str1);  //遇到空白字符就会停止读取, 并将读取的字符串赋值给str1 
  fscanf(fp, "%s", str2);  //继续读取内容赋值给str2
  printf("%s   %s", str1, str2)
  ```

  

- 字符串

  c参数均为`const char *`类型，需要预定义长度。

  - `gets(str)`  字符串输入

    从`stdin`读取一行内容到 `str` 所指向的缓冲区，直到一个终止符或 EOF；返回类型为`char *`。

  - `puts(str)`  字符串输出

    将字符串`str` 和尾随的一个换行符写入到`stdout`；返回类型为`int`。

  ```c
  char str[100];
  gets( str );
  puts( str );
  ```

  

- 单个字符

  均返回`int`类型的数字；

  - `getchar()`  字符输入

    无参数，需要一个`int`类型的变量接收返回值。

  - `putchar(c)`  字符输出

    参数`c`为`int`类型

  ```c
  int c;
  c = getchar( );
  putchar( c );
  ```



# 文件读写

## 打开和关闭

- `fopen(filename, openMode)` 创建一个新的文件或者打开一个已有的文件，返回一个`FILE`对象的指针。

  > 这个调用会初始化类型 **FILE** 的一个对象，类型 **FILE** 包含了所有用来控制流的必要的信息。

  - 参数`filename`：文件路径的字符串
  - 参数`mode`：文件打开模式

- `fclose(*fp)`：关闭文件`fp`（参数为文件对象的指针）



## 读取和写入

单个字符：

- `fgetc(*fp)`：读取单个字符

  从 `fp` 所指向的输入文件中读取一个字符。返回值是读取的字符，如果发生错误则返回 **EOF**。

- `fputc(c, *fp)`：把参数 c 的字符值写入到 `fp` 所指向的输出流中。

  写入成功，返回写入的字符；如果发生错误，则会返回 **EOF**。

  

字符串：

- `fgets(*fp)`：读取 n - 1 个字符。

  它会把读取的字符串复制到缓冲区 **`buf`**，并在最后追加一个 **`null`** 字符来终止字符串。

- `fputs(s, *fp)`：把字符串 `s` 写入到 `fp` 所指向的输出流中。

  写入成功，返回一个**非负值**；如果发生错误，则会返回 **EOF**。

- `fprintf(*fp, format_s, ...) `：把格式化的字符串写入到 `fp` 所指向的输出流中。

  如果成功，则返回写入的字符总数，否则返回一个负数。



二进制数据：

- `fread(*ptr, size, member_num, *stream)`

- `fseek(*fp, offset, whence)`

  `whence`可以是一个整数，或者这些常量：`SEEK_SET` （文件开头）、`SEEK_CUR`（文件指针当前位置）、`SEEK_END`（文件末尾）。  

- `fwrite(*ptr, size, member_num, *stream)`

  - `ptr`  -- 指向带有最小尺寸 `size*nmemb` 字节的内存块的指针。

  - `size` -- 要读取的每个元素的大小，以字节为单位。

  - `nmemb`  -- 元素的个数，每个元素的大小为 size 字节。

  - `stream` -- 指向 FILE 对象的指针，该 FILE 对象指定了一个输入流。



# 预处理器

C预处理器不是编译器的一部分，它本质是一个**文本替换**工具，在预处理器在源代码编译之前对源代码中的预处理指令进行进行一些文本的增删替换操作。

预处理器先进行清理工作，如删除注释是，将多行语句合成一个逻辑行等工作，然后执行`#`开头的预处理指令。



## 预处理指令

- `#error`   当遇到标准错误时，输出错误消息
- `#pragma`  使用标准化方法，向编译器发布特殊的命令到编译器中
- `#include`  引用[头文件](#头文件)。



其他一些重要的预处理器指令：

### 宏定义

`#define`宏定义指令，定义一个宏（macro）；`#undef`  取消定义宏。

- 无参数的宏

  一般称其为[符号常量](#常量)

  ```c
  #define <宏名> <字符串>
  #define NAME abc;
  ```



- 有参数的宏

  用于定义一个与函数相似的类函数宏（function-like macro），不过其与函数有以下差别：

  - 宏在预处理阶段进行文本替换，*函数是通过调用函数体中的代码执行相应的功能*；
  - 宏没有作用域和命名空间概念，它们在整个源码文件中可见；
  - 宏不会声明参数或返回值的类型，也没有类型检查和错误处理；
  - 宏的定义被限制成只有一行。

  ```c
  #define <宏名>([参数表]) <字符串>
  
  #define PI 3.14
  
  //定义一个宏 用以计算圆周长， 调用该宏的地方会被预处理器替换为这个宏
  #define CIRCUMFERENCE(d) ((d) * (PI)
  
  int main() {
  	//CIRCUMFERENCE(2) 被预处理替换(大概）为 2 * PI
  	printf("%f\n", CIRCUMFERENCE(2));  //6.280000
  }
  ```

  宏参数两侧与左右括号之间不能有空格，参数左括号必须紧挨着宏的名称。

  C99 标准开始允许使用省略号以表示可选参数。

  

  `##`连接符，用于在带参数的宏定义中将两个子串联接起来，从而形成一个新的子串，但它不可以是第一个或者最后一个子串。

  ```c
  #define NAME(n) num ## n
  int num0 = 10;
  printf("num0 = %d\n", NAME(0));  //NAME(0)被替换为 num ## 0，被粘合为num0
  ```



### 条件分支

按照条件确定程序的编译方式。

- 条件分支

  - `#if`

  - `#else`

  - `#elif`   

  - `endif`
  - `#ifdef`   已定义则返回真，等价于`#if defined`

  - `#ifnef`   未定义则返回真，等价于`#if !defined`

  ```c
  #include <stdio.h>
  
  const int DEBUG = 0;
  
  int main(void) {
  #if DEBUG == 0
    printf("I am NOT debugging\n");
  #else
    printf("I am debugging\n");
  #endif
  }
  ```

  

  检查宏是否被定义：

  ```c
  //代码片段
  int d=2;
  #ifdef PI
    printf("%f\n", d*PI);  //9.420000
  #else
    printf("PI is not defined\n");
  #endif
  ```

   



## 预定义宏

ANSI C 定义了许多宏，这些宏只能引用不可修改：

| 宏         | 描述                                                |
| ---------- | --------------------------------------------------- |
| `__DATE__` | 当前日期，一个以 "MMM DD YYYY" 格式表示的字符常量。 |
| `__TIME__` | 当前时间，一个以 "HH:MM:SS" 格式表示的字符常量。    |
| `__FILE__` | 当前文件名，一个字符串常量。                        |
| `__LINE__` | 当前行号，一个十进制常量。                          |
| `__STDC__` | 当编译器以 ANSI 标准编译时，则定义为 1。            |



## 预处理运算符

- `\`  宏延续运算符

- `#`  字符串常量化运算符

- `##`  标记粘贴运算符，合并两个参数，它允许在宏定义中两个独立的标记被合并为一个标记。

- `defined()`  用以确定一个标识符是否已经使用 `#define` 定义过，已定义则值为真，否则为假。

  ```c
  #if !defined (MESSAGE)
     #define MESSAGE "You wish!"
  #endif
  
  int main(void)
  {
     printf("Here is the message: %s\n", MESSAGE);  
     return 0;
  }
  ```



# 头文件

程序规模规模扩大时，单个`.c`文件难以阅读和维护，需要拆分内容到多个`.c`文件中，并需要编写对应的头文件。



头文件是扩展名为 **.h** 的文件，包含了 C 函数**声明和宏定义**，**并不包含函数的具体实现**。头文件可被多个源文件中引用共享，引用头文件相当于复制头文件的内容到引用处。



*建议把所有的常量、宏、系统全局变量和函数原型写在头文件中，在需要的时候使用`#include`指令引用相应的头文件。*



## 引用头文件

使用`#include`[预处理指令](#预处理指令)引用头文件。

```c
#include <head_file>           //引用系统头文件，使用<>包裹
#include "path_to_head_file"   //引用自定义头文件
```

引用系统头文件，编译时将在在系统目录的标准列表中搜索名给定名称的的文件；

引用自定义头文件，它在包含当前文件的目录中搜索名为 file 的文件。也可编译时指定` -I` 选项把目录前置在该列表前。



- 避免重复引用

  如果一个头文件被引用两次，编译器会处理两次头文件的内容，这将产生错误。为了防止这种情况，标准的做法是把文件的整个内容放在条件编译语句中，如下：

  ```c
  #ifndef HEADER_FILE
  #define HEADER_FILE
  
  the entire header file file
  
  #endif
  ```

  

- 有条件引用

  有时需要从多个不同的头文件中选择一个引用到程序中。例如，需要指定在不同的操作系统上使用的配置参数：

  ```c
   #define SYSTEM_H "system_1.h"
   ...
   #include SYSTEM_H
  ```

  

- 完整的自定义头文件使用示例

  *以下示例文件文件在同一目录中*

  - 文件`calc.c`定义了`calcAge()`函数

    ```c
    int calcAge(int year) {
      const int INIT_YEAR = 2020;
      return INIT_YEAR - year;
    }
    ```
  
  
    - 头文件`calc.h`声明了`clacAge()`函数
  
      ```c
      int calcAge(int year);
      ```
  
  
    - 在`main.c`文件中调用`calcAge()`函数
  
      ```
      #include <stdio.h>
      #include "calc.h"
      
      int main(void) {
        printf("age is: %u\n", clacAge(1983));
      }
      ```
      
      编译时，需要将定义了被调用的函数的`.c`文件一并编译：
      
      ```shell
      gcc -o main main.c calc.c
      ```




# 错误处理

C 语言不提供对错误处理的直接支持，发生错误时，大多数C或UNIX函数调用返回1或`NULL`，同时会设置一个错误代码 `errno`，该错误代码是全局变量，表示在函数调用期间发生了错误。

`errno.h` 头文件中找到各种各样的错误代码。

> 把 `errno` 设置为 0，这是一种良好的编程习惯。0 值表示程序中没有错误



C语言提供了`perror()`和`strerror()`函数显示与`erron`相关文本消息。

通常情况下，程序成功执行完一个操作正常退出的时候会带有值 `EXIT_SUCCESS`，它被定义为 0。



# 内存管理

> C 语言中，内存是通过指针变量来管理的。指针是一个变量，它存储了一个内存地址，这个内存地址可以指向任何数据类型的变量

C语言提供了内存管理的相关函数，可对内存进行分配、释放、移动和复制等操作，它们定义在 `<stdlib.h>` 头文件中。

- **`malloc`在分配一块指定大小的内存空间**：`void *malloc(int num)`

  分配`num`大小的空间，分配的内存空间**不会被初始化**，值是未知的；返回一个指向分配内存的指针。

  

- **`calloc`动态分配内存空间**：`void *calloc(int num, int size)`

  分配 `num` 个长度为 `size` 的连续空间，并将每一个字节都**初始化为 0**；返回一个指向分配内存的指针。

  

- **`free`释放动态分配的内存空间**：`void free(void *addr)`

  释放`addr`指向的内存空间

  

- **`realloc`重新分配内存空间**：`void *realloc(void *addr, int newsize)`

  将`addr`指向的内存空间重新分配为指定的`newsize`；重新分配成功就返回一个指向重新分配内存的指针，否则返回一个空指针。

  

- `memcpy()`从源内存区域复制数据到目标内存区域

  参数依次为：目标内存区域的指针、源内存区域的指针和要复制的数据大小（以字节为单位）。

  

- `memmove()`：类似于 `memcpy()`，但它**可以处理重叠的内存区域**。

  参数依次为：目标内存区域的指针、源内存区域的指针和要复制的数据大小（以字节为单位）。



```c
char *detail;
//使用malloc分配
detail=(char *)malloc( 200* sizeof(char) );
//使用calloc分配
detail=(char *)calloc( 200, sizeof(char) );

detail = (char *) realloc( description, 500 * sizeof(char) );

free(detail)；
```



# 编译程序

GCC（GNU Compiler Collection）是由 GNU 开发的编程语言编译器集合，提供了C编译器。除此之外还有一些其他C编译器。

*GCC 最早含义是GNU C Compiler，仅用于C程序编译，后来逐渐扩充发展，已经不仅仅支持C语言，还支持包括C++、Ada、Objective-C、Fortran 和  Java等语言，因此被重新定义为GNU Compiler Collection。*
