# 交叉编译

以在amd64(x86_64)上编译aarch64(arm64)程序为例。

1. 安装aarch64的C编译器，例如aarch64-linux-gnu-gcc

2. 指定C编译器和目标系统类型和当前系统类型

   ```shell
   CC=aarch64-linux-gnu-gcc ./configure \
     --host=aarch64-linux-gnu \
     --build=x86_64-linux-gnu
   ```

   `--build` 当前系统的类型（非必要）,一般configure脚本都会检测当前系统类型

   `--host` 目标系统的类型

   

   在GNU构建系统中，系统类型的名字通常由三部分构成：

   - CPU类型
   - 厂商
   - 操作系统

   这三部分通过破折号连接在一起，形成了一个称为“三元组”的字符串，例如`x86_64-pc-linux-gnu`
