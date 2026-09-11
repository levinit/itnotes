[TOC]

# Go I/O 与文件系统核心心智模型

## 流式抽象哲学 (io.Reader / io.Writer)

Go 的 I/O 体系以 `io.Reader` 和 `io.Writer` 为核心接口契约：
- **避免全量加载**：大文件切忌使用 `os.ReadFile` 或 `io.ReadAll` 全量读入内存，极易导致堆内存尖峰与 OOM。
- **管道化串联**：通过极简小接口将文件、网络套接字（`net.Conn`）、内存缓冲区（`bytes.Buffer`）和压缩流（`gzip.Writer`）无缝串接。
- **高效零拷贝传输**：`io.Copy(dst, src)` 会自动识别操作系统底层的零拷贝机制（如 Linux `sendfile` 系统调用），将文件直接推送到网络套接字，绕过用户态内存拷贝。

```go
// 大文件流式复制/传输标准范式
func StreamCopy(dstPath, srcPath string) error {
	src, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer src.Close()

	dst, err := os.Create(dstPath)
	if err != nil {
		return err
	}
	defer dst.Close()

	// 内部复用 32KB 缓冲区分批流式搬运，内存占用恒定
	_, err = io.Copy(dst, src)
	return err
}
```

---

# 缓冲处理：Reader vs Scanner 决策

| 组件 | 核心机制 | 适用场景 | 关键陷阱与防范 |
| :--- | :--- | :--- | :--- |
| **`bufio.Scanner`** | 分词迭代器（默认按行 `ScanLines` 切分） | 规整文本日志行读取、简单格式流解析 | **默认最大行长度为 64KB**（`bufio.MaxScanTokenSize`）。单行超出此长度时 `Scan()` 会静默返回 false，必须检查 `scanner.Err()` 并显式扩容 `scanner.Buffer()`。 |
| **`bufio.Reader`** | 连续字节流缓冲 | 变长超长行读取、二进制数据解析、精确字符回退（`Peek`/`UnreadRune`） | `ReadString('\n')` 会一直分配内存直到遇到换行符；`ReadLine()` 遇长行会分多次返回 `isPrefix=true`。 |

## 1. Scanner 大行保护范式
```go
func ScanTextLines(r io.Reader) error {
	scanner := bufio.NewScanner(r)

	// 遇到超长日志行时必须调大上限（此处允许最大 1MB 单行）
	const maxCapacity = 1024 * 1024
	buf := make([]byte, 64*1024)
	scanner.Buffer(buf, maxCapacity)

	for scanner.Scan() {
		line := scanner.Text()
		_ = line
	}
	// 必须显式捕获扫描阶段产生的底层错误（如 bufio.ErrTooLong）
	return scanner.Err()
}
```

## 2. Reader 精细流处理范式
```go
func ReadWithReader(r io.Reader) error {
	reader := bufio.NewReader(r)
	for {
		line, err := reader.ReadString('\n')
		if len(line) > 0 {
			// 处理数据（注意 ReadString 返回内容保留末尾换行符）
		}
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return err
		}
	}
	return nil
}
```

---

# 现代目录遍历与文件检索

## 1. 单层遍历与存在性检查
```go
// 文件存在性安全检查（可识别包装错误）
if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
	// 文件不存在
}

// 浅层读取当前目录文件项（返回 []os.DirEntry）
entries, err := os.ReadDir("/var/log")
for _, entry := range entries {
	name := entry.Name()
	isDir := entry.IsDir()
	_ = name
	_ = isDir
}
```

## 2. 递归遍历目录：filepath.WalkDir
`filepath.WalkDir` 使用 `os.DirEntry`，在遍历过程中**无需为每个子项额外发起一次 `os.Lstat` 系统调用**，处理深层大文件树时性能数倍优于传统的 `filepath.Walk`。

```go
func FindFiles(root string, ext string) ([]string, error) {
	var matches []string

	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err // 权限不足等访问错误向上抛出
		}
		// 遇到特定目录可跳过整棵子树（如 .git 或 vendor）
		if d.IsDir() && (d.Name() == ".git" || d.Name() == "vendor") {
			return filepath.SkipDir
		}
		if !d.IsDir() && strings.HasSuffix(d.Name(), ext) {
			matches = append(matches, path)
		}
		return nil
	})

	return matches, err
}
```

---

# 生产级原子写入与静态内嵌

## 1. 原子写入防损模式
- **事故场景**：直接写入目标文件时若进程异常退出、崩溃或系统掉电，目标文件会被截断为空文件或残缺损坏。
- **工业级范式**：先写入同目录下的临时文件，调用 `Sync()` 刷盘，最后执行原子替换（`os.Rename`）：

```go
func AtomicWriteFile(filename string, data []byte, perm os.FileMode) error {
	dir := filepath.Dir(filename)
	// 在同文件系统目录创建临时文件（跨分区 Rename 会失败）
	tmpFile, err := os.CreateTemp(dir, "tmp-*")
	if err != nil {
		return err
	}
	tmpName := tmpFile.Name()
	defer os.Remove(tmpName) // 失败时确保清理

	if _, err := tmpFile.Write(data); err != nil {
		_ = tmpFile.Close()
		return err
	}
	// 强制刷入物理介质
	if err := tmpFile.Sync(); err != nil {
		_ = tmpFile.Close()
		return err
	}
	if err := tmpFile.Close(); err != nil {
		return err
	}

	if err := os.Chmod(tmpName, perm); err != nil {
		return err
	}
	// 原子重命名替换目标文件
	return os.Rename(tmpName, filename)
}
```

## 2. 静态资源编译期内嵌 (embed.FS)
将模版、静态网页、初始配置在编译期打包进单个二进制执行文件，实现无依赖分发：

```go
package main

import (
	"embed"
	"io/fs"
)

//go:embed static/* templates/*.html
var embeddedFS embed.FS

func LoadTemplate(name string) ([]byte, error) {
	// embed.FS 路径必须一律使用斜杠 "/"，不支持 Windows 反斜杠 "\"
	return embeddedFS.ReadFile("templates/" + name)
}

func GetStaticSubFS() (fs.FS, error) {
	// 剥离前缀路径供 http.FileServer 使用
	return fs.Sub(embeddedFS, "static")
}
```

---

# 内存管道转换 (io.Pipe)

当上游只支持写入（`io.Writer`），而下游只支持读取（`io.Reader`）时，使用 `io.Pipe()` 在内存中构建零拷贝管道，无需生成磁盘中间文件：

```go
func DemoPipe() {
	pr, pw := io.Pipe()

	// 异步写入协程
	go func() {
		defer pw.Close()
		// 例如：将 JSON 编码直接推入管道
		_ = json.NewEncoder(pw).Encode(map[string]string{"status": "ok"})
	}()

	// 主协程消费端（如直接作为 HTTP 请求的 Body 发送）
	// http.Post("http://example.com/api", "application/json", pr)
	data, _ := io.ReadAll(pr)
	_ = data
}
```
