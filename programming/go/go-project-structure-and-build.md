# Go 项目结构与构建指南

---
[toc]

## 环境变量与工具链

### 核心环境变量

```shell
go env        # 查看所有 Go 环境变量
go env GOPATH # 查看 GOPATH 路径
```

- **`GOROOT`**: Go 语言安装根目录。
- **`GOPATH`**: 存放第三方依赖包和编译生成的二进制文件。在 Module 模式下，主要作为本地缓存路径（`$GOPATH/pkg/mod`）。
- **`GOBIN`**: 存放 `go install` 生成的可执行文件。
- **`GOOS` / `GOARCH`**: 目标编译平台（如 `linux`, `windows`, `darwin`）与架构（如 `amd64`, `arm64`）。
- **`GO111MODULE`**: 
  - `on`: 强制使用 Go Modules。
  - `off`: 传统 GOPATH 模式。
  - `auto`: 根据目录下是否有 `go.mod` 自动切换。

### CLI 常用操作

```shell
go build -o app .  # 编译当前目录，输出为 app
go install        # 编译并安装二进制到 $GOPATH/bin 或 $GOBIN
go run .          # 编译并直接运行（临时目录执行）
go clean -cache   # 清理构建缓存
```

---

## 模块管理 (Go Modules)

Go Module 是现代 Go 项目依赖管理的标准。

### 基础实战
- **初始化**: `go mod init <module_name>`（生成 `go.mod`）。
- **整理依赖**: `go mod tidy`（增加缺失的、删除多余的依赖）。
- **本地缓存**: `go mod download`。
- **离线依赖**: `go mod vendor`（将依赖复制到项目根目录下的 `vendor` 文件夹）。

### 多模块工作区 (Go Workspace)
适用于同时开发多个相互依赖的本地模块。
```shell
go work init ./module_a ./module_b
go work use ./module_c  # 添加模块到工作区
go work sync            # 同步工作区依赖配置
```

---

## 工程结构与生命周期

### 源码分类
- **命令源码 (Command)**: `package main` 且包含 `main()` 函数，编译生成可执行文件。
- **库源码 (Library)**: 供其他包 `import`，不包含 `main()`。
- **测试源码**: 以 `_test.go` 结尾，由 `go test` 调用。

### 分包逻辑与可见性
- **目录即包**: 同一目录下所有文件必须同属一个 `package`。
- **导出规则**: **首字母大写** 的函数、变量、结构体和字段可被包外访问；**首字母小写** 仅限包内。
- **内嵌 (Embedding)**: 通过在一个结构体中只写另一个结构体的类型名，实现类似继承的字段与方法复用。

### 初始化顺序 (`init` 函数)
1. **全局变量/常量** 初始化。
2. 执行 **`init()`** 函数。
3. `init` 无需参数和返回值，不能被手动调用。
4. **导入顺序**: 如果 A 导入 B，则先递归初始化 B 及其所有依赖，最后初始化 A。

---

## 编译与构建进阶

### 跨平台编译
```shell
# 编译为 Windows 64位执行文件
env GOOS=windows GOARCH=amd64 go build -o app.exe main.go

# 隐藏 Windows 终端窗口 (GUI 程序)
go build -ldflags="-H windowsgui" main.go

# 列出支持的所有平台
go tool dist list
```

### 约束构建 (Build Tags)
用于在同一代码库中实现平台特定的逻辑。
- **文件名方式**: `file_linux.go`, `file_windows_amd64.go`。
- **注释方式**: 在文件最开头（`package` 声明前）加入：
  ```go
  //go:build linux && !amd64
  ```

### 编译模式 (`-buildmode`)
- `default`: 生成静态可执行文件。
- `c-shared` / `c-archive`: 编译为供 C 语言调用的动态库 (`.so`/`.dll`) 或静态库 (`.a`)。需要使用 `//export` 注释导出函数。
- `plugin`: 编译为能在运行时动态加载的 Go 插件（仅支持特定系统）。

### 二进制瘦身与链接参数
- **去除调试信息**: `go build -ldflags="-s -w"`（减小体积）。
- **注入编译信息**: 可以通过链接参数在编译时向变量注入数据（如版本号）：
  ```shell
  go build -ldflags="-X 'main.version=1.1'" main.go
  ```

---

## 工程化核心概念

### 逃逸分析 (Escape Analysis)
决定变量分配在 **栈 (Stack)** 还是 **堆 (Heap)**。
- 栈：快速分配，随函数退出自动清理。
- 堆：较大开销，需 GC (垃圾回收) 处理。
- **分析命令**: `go build -gcflags="-m -l" main.go`。
- **原则**: 尽量减少逃逸以降低 GC 压力（避免在循环中创建大量短寿对象，返回局部变量指针会触发逃逸）。

### 系统交互
- **`os/exec`**: 稳健地调用 shell 命令。
  ```go
  cmd := exec.Command("sh", "-c", "ps -ef | grep go")
  out, _ := cmd.CombinedOutput()
  ```
- **`flag`**: 标准库提供的 CLI 参数解析。
  ```go
  flag.StringVar(&cfg, "c", "default.yaml", "config path")
  flag.Parse()
  ```

---

## 自动化测试与质量

### 测试规范
- 文件名: `xxx_test.go`。
- **单元测试**: `func TestXxx(t *testing.T)`。
- **基准测试 (Benchmark)**: `func BenchmarkXxx(b *testing.B)`，用于分析性能瓶颈。
- **示例测试**: `func ExampleXxx()`。

### 执行测试
```shell
go test .          # 运行当前目录测试
go test -v ./...   # 递归运行所有包测试并打印日志
go test -bench=.   # 运行基准测试
```
