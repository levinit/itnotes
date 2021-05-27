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
  - [ustc rustup](https://lug.ustc.edu.cn/wiki/mirrors/help/rust-static)

- 基本使用

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
  #如stable版本 的 x86_64 gnu linux 版本
  rustup toolchain install stable-x86_64-unknown-linux-gnu
  ```

## cargo

- 创建一个项目

  ```shell
  cargo new hello_world
  ```

  - cargo项目结构：

    > - src/  源码
    > - Cargo.toml  配置文件
    > - target/  编译生成文件

  - 项目常用环境变量示例

    ```shell
    export CARGO_HOME="~/.cargo/"
    export RUSTBINPATH="~/.cargo/bin"
    export RUST="~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu"
    export RUST_SRC_PATH="$RUST/lib/rustlib/src/rust/src"
    export PATH=$PATH:$RUSTBINPATH
    ```

- 编译

  ```shell
  #编译debug
  cargo build #默认编译生成到 target/debug/下
  cargo run #编译并运行
  cargo check #仅检查是否可正确编译（速度快）
  #编译release 将会优化optimizations(耗时更长)
  cargo build --release
  ```

  

## 开发工具

- 插件工具：参看[rust dev tools](https://www.rust-lang.org/zh-CN/tools)
  
- vscode：CodeLLDB、rls
  
- rls  为各种IDE或编辑器提供Rust语言服务器协议实现以方便调试

  ```shell
  rustup component add rls rust-analysis rust-src
  ```

- clippy  提供lint校验

  ```shell
  rustup component add clippy
  ```

- rustfmt  代码格式化

  ```shell
  rustup component add rustfmt
  ```

  

  

  

