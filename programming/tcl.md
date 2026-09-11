[TOC]

# Tcl 快速上手核心心智模型

> 适用读者：具备 Python / C / Bash / Go 等多门语言经验的开发者。用最短篇幅建立 Tcl（Tool Command Language）的底层心智模型与语法映射。

---

## 核心心智模型：一切皆字符串与命令替换

Tcl 区别于主流语言的最核心特征：**没有原生类型系统，一切皆字符串；一切语法皆命令调用**。

### 1. 命令调用结构
在 Tcl 中，代码行不存在 `func(a, b)` 这种形式，结构完全类似 Shell：
```tcl
command arg1 arg2 arg3 ...
```
- 每行的第一个单词即为**命令名**，后续以**空格**分隔的所有内容均为传递给该命令的字符串参数。
- 换行或分号 `;` 表示一条命令结束。

### 2. 三大替换机制与分组法则

解释器在执行命令前，仅对参数执行一轮从左到右的扫描与替换：

| 语法符号 | 机制类型 | 行为说明 | 对应其他语言认知 |
| :--- | :--- | :--- | :--- |
| **`$var`** | **变量替换** | 将变量名替换为其对应的值 | 类似 Shell 的 `$VAR` |
| **`[cmd]`** | **命令替换** | 执行中括号内部的命令，并用其标准输出/返回值替换自身 | 类似 Shell 的 `$(cmd)` 或反引号 |
| **`\`** | **转义** | 转义特殊字符或换行符延续代码行 | 标准转义 |
| **`{}`** | **字面量分组** | **彻底禁用所有替换**，保留内部原始文本（延迟求值） | 类似 Shell 单引号 `''`，但在 Tcl 中支持完美嵌套 |
| **`""`** | **文本分组** | 允许空格作为一个整体，**内部仍会触发 `$`, `[]`, `\` 替换** | 类似 Shell 双引号 `""` |

### 3. 最常踩的陷阱：什么时候带 `$`？
- **传递变量“名”（写/修改/引用绑定）** ➜ **不带 `$`**：
  ```tcl
  set a 10        ;# 声明/赋值变量 a，传入的是变量名 "a"
  incr a          ;# 将 a 的值自增 1，传入的是变量名 "a"
  lappend mylist  ;# 向列表追加元素，传入变量名
  ```
- **读取变量“值”** ➜ **带 `$`**：
  ```tcl
  puts $a         ;# 读取 a 的值并打印
  set b $a        ;# 将 a 的值赋予 b
  ```

---

## 核心数据结构

### 1. 列表 (List)
Tcl 列表在底层仍是经过空格与转义规范化的字符串，为一等公民。

```tcl
# 创建列表
set fruits [list apple banana "cherry pie"]  ;# 推荐显式 list 构建
set colors {red green blue}                  ;# 使用字面量分组创建

# 基础操作
lindex $colors 0           ;# 获取索引 0 的元素: "red"
llength $colors            ;# 列表长度: 3
lrange $colors 0 1         ;# 切片: "red green"

# 修改列表（就地追加变量需传变量名，不带 $）
lappend colors yellow      ;# colors 变为 {red green blue yellow}

# 赋值拆包
lassign $colors c1 c2 c3   ;# c1="red", c2="green", c3="blue"

# 排序并返回新列表
set sorted [lsort -dictionary $colors]
```

### 2. 关联数组 (Array)
散列表哈希，**不是一等公民**（不能作为函数参数直接传值，不能嵌套，通常需配合全局或 `upvar` 使用）。

```tcl
# 声明与赋值
set port_speed(eth0) 1000
set port_speed(eth1) 10000

# 访问与检查
puts $port_speed(eth0)
info exists port_speed(eth2)  ;# 返回 0

# 遍历数组键
foreach iface [array names port_speed] {
    puts "$iface -> $port_speed($iface)"
}
```

### 3. 字典 (Dict)
现代 Tcl（8.5+）引入的一等公民键值映射结构，**完全支持嵌套并可作为参数传递**。

```tcl
# 创建与读写
set config [dict create host "localhost" port 8080 timeout 30]
dict set config debug 1

# 获取与检查
set port [dict get $config port]
if {[dict exists $config timeout]} {
    puts "timeout defined"
}

# 遍历字典
dict for {k v} $config {
    puts "$k: $v"
}
```

---

## 控制流与表达式 (expr)

> **黄金安全与性能准则**：**`expr` 表达式必须永远用花括号 `{}` 包裹**！
> - 不用花括号会导致参数在传入前发生多余的双重替换，引发极其隐蔽的代码注入漏洞并破坏字节码预编译性能。

```tcl
# 正确写法（字节码预编译，安全高效）
set sum [expr {$a + $b * 2}]

# 错误写法（严禁使用）
# set sum [expr $a + $b * 2]
```

### 1. 条件分支 (if / switch)
注意：开花括号 `{` 必须与 `if`/`elseif`/`else` 保持在同一行（防止换行被误认为命令结束）。

```tcl
if {$score >= 90} {
    puts "A"
} elseif {$score >= 80} {
    puts "B"
} else {
    puts "C"
}

# 字符串 switch 匹配
switch -exact -- $state {
    "INIT"  { init_system }
    "RUN"   { start_work }
    default { puts "unknown state" }
}
```

### 2. 循环结构
```tcl
# 遍历列表
foreach item $fruits {
    puts "Fruit: $item"
}

# 并行遍历多个列表
foreach name {Alice Bob} age {25 30} {
    puts "$name is $age"
}

# 计数循环
for {set i 0} {$i < 5} {incr i} {
    if {$i == 2} continue
    puts "Step $i"
}
```

---

## 过程、作用域与 upvar

### 1. 过程定义与默认参数
Tcl 使用 `proc` 定义函数，默认情况下其内部变量与外部完全隔离（局部作用域）：

```tcl
proc connect {host {port 22} {timeout 10}} {
    # host 为必选参数，port 默认 22，timeout 默认 10
    puts "Connecting to $host:$port (timeout: ${timeout}s)"
    return 1
}

connect "192.168.1.1"       ;# 使用默认 port 与 timeout
connect "10.0.0.1" 8080 5   ;# 显式覆盖
```

### 2. 杀手级特性：`upvar` 跨栈帧引用传递
由于 Tcl 变量传递默认是值复制（字符串），`upvar` 允许过程绑定上层调用者的变量（类似 C 语言传递指针）：

```tcl
# 在函数内部直接就地修改调用方传递过来的变量
proc increment_caller_var {var_name step} {
    # 将上一层栈帧（1 表示上一层）的 var_name 绑定到当前局部的 v
    upvar 1 $var_name v
    incr v $step
}

set my_counter 100
increment_caller_var my_counter 5
puts $my_counter  ;# 输出 105
```

---

## I/O 与异常处理

### 1. 文件读写
```tcl
# 写入文件
set fp [open "report.txt" "w"]
puts $fp "Task finished successfully"
close $fp

# 逐行读取文件
set fp [open "report.txt" "r"]
while {[gets $fp line] >= 0} {
    puts "Read: $line"
}
close $fp
```

### 2. 错误捕获 (catch / try)
- **极简模式 (`catch`)**：返回 0 表示正常，非 0 表示抛出错误。
  ```tcl
  if {[catch {
      open "not_exist.txt" "r"
  } err_msg]} {
      puts "Captured error: $err_msg"
  }
  ```

- **现代结构化捕获 (`try / trap`)**：
  ```tcl
  try {
      set fp [open "data.bin" "r"]
  } trap {POSIX ENOENT} {err} {
      puts "File not found: $err"
  } finally {
      puts "Cleanup executed"
  }
  ```

---

## CAD / EDA 开发者特别认知

1. **宿主环境集成**：在 DC、Innovus、Virtuoso 等 EDA 工具中，Tcl 直接作为交互式命令行与脚本引擎。
2. **Collection vs List**：
   - EDA 工具通常返回内部 C 结构封装的“集合（Collection）”（如 `get_cells *`、`all_fanin`）。
   - **集合不是 Tcl 原生 List**，不能直接用 `lindex` 或 `foreach`。必须使用 EDA 提供的专有命令：
     - 获取数量：`sizeof_collection $col`
     - 迭代集合：`foreach_in_collection itm $col { ... }`
     - 转为普通 Tcl 字符串列表：`get_object_name $col`
