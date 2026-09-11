[TOC]

# Go 工程构建与交付核心心智模型

## 模块与多模块工作区 (Go Modules & Workspace)

### 1. 核心环境变量
- **`GOPROXY`**: 依赖下载镜像代理（国内主流：`https://goproxy.cn,direct`）。
- **`GOPRIVATE`**: 私有代码仓库路径前缀（如 `git.corp.internal/*`），阻止私有代码路径和包元数据泄露到公共代理或校验服务器（自动忽略 `GOPROXY` 与 `GOSUMDB`）。

### 2. 多模块工作区 (Go Workspace)
适用于同时开发多个存在相互依赖关系的本地模块（如基础库 `pkg/core` 与服务 `services/api`），替代传统的在 `go.mod` 中临时写 `replace` 的污染方案：

```shell
# 在项目根目录初始化工作区
go work init ./core ./api

# 添加新的本地开发模块
go work use ./common

# 统一同步工作区依赖
go work sync
```

> **生产规范**：`go.work` 与 `go.work.sum` 属于本地开发辅助文件，通常加入 `.gitignore`，避免影响 CI/CD 纯净构建环境。

---

# 纯静态编译与跨平台交叉构建

Go 标准库默认在需要 DNS 解析或特定系统调用时可能隐式调用 C 库（CGO）。生产部署（尤其是构建轻量级 Docker `scratch` / `alpine` 容器镜像）时，必须关闭 CGO 生成**纯静态二进制文件**，彻底避免动态链接库（glibc / musl）缺失事故。

## 1. 跨平台静态构建矩阵

```shell
# Linux amd64 纯静态构建（容器镜像首选）
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app_linux_amd64 .

# Linux arm64 纯静态构建（适配国产服务器/苹果芯片容器）
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o app_linux_arm64 .

# Windows 64位构建（可附加 -H windowsgui 隐藏控制台黑框）
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui" -o app.exe .

# macOS 平台
CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o app_darwin_arm64 .
```

---

# 二进制瘦身与元数据注入

## 1. 去除调试符号瘦身
默认构建的可执行文件内嵌 DWARF 调试信息与符号表。通过 `-ldflags="-s -w"` 可将二进制体积大幅缩减 30%~50%（不影响 runtime panic 堆栈跟踪行号）：
- `-s`：禁用符号表（Symbol table）。
- `-w`：禁用 DWARF 调试信息。

## 2. 编译期元数据动态注入 (`-X`)
在构建期动态注入 Git Commit、构建时间、语义版本号，避免在代码中硬编码：

```go
package main

import "fmt"

// 由链接器在编译期赋值
var (
	Version   = "dev"
	GitCommit = "none"
	BuildTime = "unknown"
)

func PrintVersion() {
	fmt.Printf("Version: %s\nCommit: %s\nBuilt: %s\n", Version, GitCommit, BuildTime)
}
```

```shell
# 编译命令注入变量
VERSION="v1.2.0"
COMMIT=$(git rev-parse --short HEAD)
BUILD_TIME=$(date "+%Y-%m-%d_%H:%M:%S")

go build -ldflags="-s -w \
  -X 'main.Version=${VERSION}' \
  -X 'main.GitCommit=${COMMIT}' \
  -X 'main.BuildTime=${BUILD_TIME}'" \
  -o app .
```

---

# 条件构建与平台分发 (Build Tags)

## 1. 现代 `//go:build` 语法
在文件第一行（`package` 声明前，空一行分隔）声明构建约束：

```go
//go:build linux && !arm
// +build linux,!arm

package platform
```

- 逻辑与：`&&`
- 逻辑或：`||`
- 逻辑非：`!`

## 2. 文件名后缀自动识别
无需编写构建标签，Go 工具链自动根据文件命名后缀识别目标系统与架构：
- `xxx_linux.go`：仅在 Linux 平台参与编译。
- `xxx_windows_amd64.go`：仅在 Windows 64 位平台参与编译。
- `xxx_test.go`：仅在执行 `go test` 时参与编译。
