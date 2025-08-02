# 运行R

以下示例中R文件名为`~/file.R`，且`Rscript`位于`/usr/bin/Rscript`。

- 交互式运行 -- R命令行

  `R`运行后将进入R的命令行，可以用以下方式运行R代码：

  - 直接输入命令：如`getwd()`
  - 载入写好的R文件：`source("~/file.R")`

- 脚本运行 -- 使用`Rscritp`

  - 前台运行

    - `~/file.R`

      要求：

      - 该R文件需要有可执行权限 `chmod +x ~/file.R`
      - 该R文件头部需要添加shebang： `#!/usr/bin/Rscript`或`#!/usr/bin/env Rscript`

    - `Rscript ~/file.R`

      无需shebang和可执行权限

    - `R --slave -f ~/file.R`

      无需shebang和可执行权限

  - 后台运行

    输出内容将写入到与脚本文件同名切后缀为Rout的文件中，此例子中为`file.Rout`。

    ```shell
    R CMD BATCH --args ~/file.R
    #或
    R CMD BATCH ~/file.R
    ```
    注意：实际上该方法执行的r脚本会一直等待计算完成才返回shell的提示符，想要使其后台运行可在命令后添加`&`放入后台，如：
    ```shell
    R CMD BATCH ~/file.R &
    #使用nohup忽略挂起信号 避免该命令被终止
    nohup R CMD BATCH ~/file.R &
    ```
    或可使用scree/tmux之类的工具运行r脚本避免其进程被挂断。
- 在bash脚本中插入R

  使用EOF将R语言代码传递给`R --slave [option]`执行（option是R的其他可选参数）：

  ```bash
  #!/bin/sh
  echo "this is a bash script"
  echo "=====these are R lang codes below====="
  # R
  R --slave <<EOF
  hello <- "hello R lang"
  print(hello)
  getwd()
  EOF
  echo "=====R code end====="
  ```



# 包管理

```R
installed.packages()

```

`downloaded length 1886962 != reported length 1886962`之类的错误，尝试设置：

```R
options(timeout = max(1000, getOption("timeout")))
```

下载大型文件（50MB或以上），因此当软件包中使用download.file时，默认timeout值可能无法满足要求，可使用以上命令行设置超时时间。也可以在shell环境变量中设置`R_DEFAULT_INTERNET_TIMEOUT`:

```shell
export R_DEFAULT_INTERNET_TIMEOUT=999
```

