# Go性能优化

## GC优化

### GC触发机制

- 自动触发
  - 后台GC定时器（默认2分钟）
  - 达到内存阈值（默认是上次GC后内存量的2倍）
  - runtime.mallocgc内存申请时
  - runtime.sysmon监控线程
- 手动触发
  - 调用runtime.GC()



### GC限制

通过内置的 `debug.SetMemoryLimit` 函数可以调整触发 GC 的堆内存目标值，从而减少 GC 次数，降低GC 时 CPU 占用。

可使用以下环境变量实现对Go程序的内存限制：

- `GOMEMLIMIT`：设置 Go 程序的最大内存使用限制。

  值为：

  - `0`，无内存限制
  - 数字+容量单位（如1GB，大小写不敏感）
  - 正整数不带容量单位，则以字节为单位。

- `GOGC`：设置 Go 程序的垃圾回收策略。

  值为：

  - `off`或`0`，不会自动触发垃圾回收机制，垃圾回收只能手动触发。

  - `-1`，禁用垃圾回收机制

    这意味着垃圾回收机制将不会执行，而所有分配的内存将会一直保留在堆上，这可能会导致内存泄漏，大多数情况都不要使用该值。

  - 其他正整数值，表示当前内存使用量与垃圾回收后可用内存的比例。

    如`GOGC=100`（默认值）时，垃圾回收器将在内存使用量为可用内存的两倍时运行。

  

内存限制的一些使用建议：

- 对程序执行环境的可用内存有明确的把控时，使用内存限制，但是要预留一部分内存资源。
- Go语言程序可能会与其他程序共享有限的内存，不要将GOGC设置为off，因为这些程序通常与Go语言程序是解耦的。
- 部署到您无法控制的执行环境时，不要使用内存限制，特别是当程序的内存使用与其输入成比例时。



### GC调优策略

####  内存限制配置
```go
// 代码中设置
debug.SetMemoryLimit(limit)

// 环境变量设置
GOMEMLIMIT=2GB    // 设置最大内存使用限制
GOGC=100          // 设置GC触发比例，默认100
```



####  GC友好的代码实践

核心：尽量复用内存，减少内存的频繁分配



- 复用变量，如在循环外部定义变量而不是在每次迭代时重新声明赋值

- 大型struct，使用指针传递代替值传递

- 预分配合适的slice的cap避免频繁的自增长

- 对象池化

  - 使用sync.Pool复用临时对象
  - 自定义对象池来复用频繁分配的对象

  ```go
  var pool = sync.Pool{
      New: func() interface{} {
          return &bytes.Buffer{}
      },
  }
  ```

  

## 内存优化

### 避免内存泄漏

- 及时关闭文件、网络连接等资源
- 注意goroutine泄漏
- 使用defer确保资源释放



### 内存分配优化

- 使用字节切片替代字符串处理

  ```go
  b := []byte(str)
  // 处理b
  str = string(b)
  ```

- 大结构体使用指针传递



###  内存布局优化

- 内存对齐，优化struct字段顺序，必要时增加额外的字段补充长度实现对齐

```go
type OptimizedStruct struct {
    field1 int64    // 8字节
    field2 int32    // 4字节
    field3 int16    // 2字节
    field4 bool     // 1字节
    field5 bool     // 1字节
}
```



## CPU优化

### 并发处理

```go
// Worker Pool模式
func worker(jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        results <- process(job)
    }
}

// 启动固定数量的worker
func startWorkerPool(numWorkers int) {
    jobs := make(chan Job, 100)
    results := make(chan Result, 100)
    
    for i := 0; i < numWorkers; i++ {
        go worker(jobs, results)
    }
}
```



### 锁优化

```go
// 使用读写锁代替互斥锁
type Cache struct {
    sync.RWMutex
    data map[string]interface{}
}

// 读操作使用RLock
func (c *Cache) Get(key string) interface{} {
    c.RLock()
    defer c.RUnlock()
    return c.data[key]
}
```



## I/O优化

###  缓冲I/O

```go
// 使用bufio
reader := bufio.NewReader(file)
scanner := bufio.NewScanner(reader)

// 批量写入
writer := bufio.NewWriter(file)
defer writer.Flush()
```



###  连接池

```go
// 数据库连接池配置
db.SetMaxOpenConns(100)
db.SetMaxIdleConns(10)
db.SetConnMaxLifetime(time.Hour)
```



## 性能分析工具

###  GC分析

```shell
# 查看GC日志
GODEBUG=gctrace=1 go run main.go

# 使用trace工具
go test -trace trace.out
go tool trace trace.out
```



###  性能分析

```go
// CPU分析
f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()

// 内存分析
f, _ := os.Create("mem.prof")
pprof.WriteHeapProfile(f)
```



### 基准测试

```go
func BenchmarkXXX(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // 测试代码
    }
}

// 运行基准测试
go test -bench=. -benchmem
```



## 优化建议

1. 性能优化步骤
   - 先通过性能分析工具定位瓶颈
   - 有针对性地进行优化
   - 通过基准测试验证效果
   - 持续监控优化效果

2. 优化原则
   - 避免过早优化
   - 基于数据驱动优化
   - 在保证代码可读性的前提下优化
   - 权衡优化成本和收益

3. 常见优化场景
   - CPU密集型：注重并发优化
   - 内存密集型：注重GC和内存分配优化
   - I/O密集型：注重缓冲和异步处理
