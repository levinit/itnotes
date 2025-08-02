rust

---

# 环境搭建

- rust  RUST编译器（根据需要安装对应操作系统的rust）
- [cargo](https://crates.io/)  RUST项目管理器（一般集成在rust包中）
- [rustup](https://www.rustup.rs/)  可方便地安装和管理多个操作系统（windows、mac、android等）和架构（x86、x86_64、arm等）的rust工具



## rustup

选择安装rustup方便管理多个平台的rust。

- 镜像源

  可根据需要添加更快的镜像源。例如：
  - [tuna rsutup](https://mirror.tuna.tsinghua.edu.cn/help/rustup/)

  - [ustc rustup](https://mirrors.ustc.edu.cn/help/rust-static.html)

    ```shell
    export CARGO_HOME=xx
    export RUSTUP_HOME=xxx
    
    export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
    export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

  

- 工具链安装

  ```shell
  rustup toolchain list #当前安装的所有版本rust工具链
  rustup default #查看当前默认版本rust
  #查看当前默认的stable版本rust
  rustup default stable  #如果尚未安装将自动安装
  #查看所有可安装的rust版本
  rustup target list
  
  #安装指定版本rust
  rustup toolchain install <toolchain>
  #toolchain由两部分组成，前者可为stable、nightly、beta、1.2（版本号）等组成
  #后者以架构加平台名字构成，可从rustup list列表中获取
  rustup toolchain install stable  #stable-x86_64-unknown-linux-gnu
  ```



## 环境变量

rust常用环境变量示例

```shell
export CARGO_HOME="~/.cargo/"
export RUSTBINPATH="~/.cargo/bin"
export RUST="~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu"
export RUST_SRC_PATH="$RUST/lib/rustlib/src/rust/src"
export PATH=$PATH:$RUSTBINPATH
```



## 开发环境

- IDE及插件：参看[rust dev tools](https://www.rust-lang.org/zh-CN/tools)

- rls  为各种IDE或编辑器提供Rust语言服务器协议实现以方便调试

  ```shell
  #一些开发工具需要Rust源代码来提供更好的自动完成、跳转到定义等功能
  rustup component add rust-src
  
  #一个独立项目，实现了 Language Server Protocol (LSP) 的 Rust 语言服务器
  rustup component add rust-analyzer
  
  #rustfmt代码格式化 clippy静态代码分析
  component add rustfmt clippy
  ```

  rust官方也提供一个名为`rust-analysis` 的分析工具以及LSP工具`rls`，它们是 `rustc`（Rust 编译器）的一部分，用于生成 Rust 代码的静态分析数据。

- clippy  提供lint校验

  ```shell
  rustup component add clippy
  ```

- rustfmt  代码格式化

  ```shell
  rustup component add rustfmt
  ```

  


## cargo

Cargo 是 Rust 的构建系统和包管理器。

- 创建项目

  ```shell
  cargo new hello_world
  ```

  cargo项目结构：

  > - src/  源码
  > - Cargo.toml  配置文件
  > - target/  编译生成文件

- 编译项目

  ```shell
  #编译debug
  cargo build #默认编译生成到 target/debug/下
  cargo run #编译并运行
  cargo check #仅检查是否可正确编译（速度快）
  #编译release 将会优化optimizations(耗时更长)
  cargo build --release
  ```




# 变量和常量

声明变量需要使用`let`关键字，变量值不可变（不可变变量），但是变量可以重复定义，后定义的变量将覆盖前面相同的变量；如果额外使用`mut`关键字修饰，则变量值可变：

```rust
let x=1;       //不可再次赋值
x=2;           //error
let mut y = 5; //mut让变量值可变
y=6;
```



声明常量 (constants)使用`const`关键字，常量绑定到一个名称的不允许改变的值，不可以使用`mut`关键字使其可变；常量**只能被设置为常量表达式**，不可以是其他任何只能在运行时计算出的值。



# 数据类型

rust是静态类型（*statically typed*）语言，编译时就必须知道所有变量的类型。

- 标量类型

  - 整型：没有小数部分的数字

    | 长度    | 有符号  | 无符号  |
    | ------- | ------- | ------- |
    | 8-bit   | `i8`    | `u8`    |
    | 16-bit  | `i16`   | `u16`   |
    | 32-bit  | `i32`   | `u32`   |
    | 64-bit  | `i64`   | `u64`   |
    | 128-bit | `i128`  | `u128`  |
    | arch    | `isize` | `usize` |

  - 浮点型

  - 布尔类型

  - 字符类型

- 
