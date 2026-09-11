[TOC]

# Go并发核心心智模型

## CSP哲学与并发选型

Go 并发核心遵循 CSP（Communicating Sequential Processes）模型：**“通过通信共享内存，而非通过共享内存通信”**。但在实际工程中，需要根据场景权衡 Channel 与传统同步原语：

| 并发机制 | 适用场景 | 核心优势 | 核心劣势 / 注意点 |
| :--- | :--- | :--- | :--- |
| **Channel** | 数据流传递、所有权转移、任务分发、事件通知 | 解耦、无显式加锁、符合 CSP 流水线 | 存在缓冲管理、不当关闭易 panic、易泄漏 |
| **sync.Mutex** | 共享状态就地修改、保护小段临界区 | 性能开销极低、逻辑直观 | 需配合 defer 避免死锁、粒度需小 |
| **sync.RWMutex** | 读多写极少的数据结构保护 | 读操作并发不阻塞 | 写锁饥饿风险；读并发极高且写极多时不宜使用 |
| **sync.Map** | 只追加写入后大量并发读、多个协程读写互不相交的 key | 读写分离无锁读取、高并发读性能极佳 | 频繁并发修改同一 key 时由于 dirty 锁竞争劣于普通 map+Mutex |
| **sync/atomic** | 纯计数器、状态标志位切换（0/1）、指针级无锁替换 | 纳秒级硬件原子指令、无上下文切换 | 仅支持基础类型与指针，复杂逻辑难以保证一致性 |

## GMP 调度模型本质

- **G (Goroutine)**：用户态轻量级线程。初始栈仅 2KB，按需动态扩缩（最大通常 1GB），创建开销极小。
- **M (Machine)**：操作系统物理线程，由 OS 调度器调度。
- **P (Processor)**：逻辑处理器/上下文，数量默认为 CPU 核心数（`GOMAXPROCS`）。维护可运行 G 的本地队列。
- **调度机制**：
  - **Work Stealing**：当本地 P 的队列为空时，尝试从全局队列或其他 P 的本地队列偷取一半的 G 运行。
  - **Syscall 解绑**：当 G 执行阻塞系统调用时，M 与 P 解绑；调用返回时重新绑定空闲 P 或进入全局队列。
  - **抢占式调度**：基于系统监控（`sysmon`）与 OS 信号实现抢占，防止某个无函数调用的长耗时循环霸占 CPU。

---

# Channel 核心契约与状态矩阵

Channel 在未初始化、正常、已关闭三种状态下的行为具有严格的运行时契约：

| 操作 | nil Channel | 正常（未关闭）Channel | 已关闭（Closed）Channel |
| :--- | :--- | :--- | :--- |
| **发送 `ch <- v`** | 永久阻塞（导致 Goroutine 泄漏） | 缓冲未满成功；缓冲已满阻塞 | **直接 Panic** |
| **接收 `<-ch`** | 永久阻塞（导致 Goroutine 泄漏） | 缓冲非空读取成功；缓冲空阻塞 | **立即返回对应类型的零值** |
| **关闭 `close(ch)`** | **直接 Panic** | 成功关闭并唤醒所有等待接收方 | **直接 Panic** |

> **关闭原则**：**只由唯一的发送者关闭 Channel；若存在多个并发发送者，绝不要在发送端关闭**，应借助 `sync.WaitGroup`、关闭信号 Channel 或 `context.Context` 协调生命周期。

---

# 生产级高频暗坑与防御

## 1. Goroutine 泄漏（生产最隐蔽的 OOM 诱因）
- **现象**：Goroutine 启动后由于等待无缓冲 channel、等待已断开的 socket 或没有配置超时的 context，永远阻塞在接收/发送端，无法被 GC 回收。
- **防御准则**：
  - 发起异步子任务必须受 `context.WithTimeout` 或 `context.WithCancel` 约束。
  - 单向接收通知的 Channel（如退出信号），推荐使用容量为 1 的有缓冲 Channel 避免发送方卡死。
  - 关键服务引入 `runtime.NumGoroutine()` 监控告警。

## 2. 读取已关闭 Channel 导致的“零值雪崩”
- **现象**：从已关闭的 channel 接收数据不会报错，而是立即返回零值。如果使用 `for { val := <-ch }` 没有双返回值判断，会导致死循环狂吃 CPU 并处理错误数据。
- **防御准则**：
  ```go
  // 必须使用双返回值校验通道是否仍处于开启状态
  val, ok := <-ch
  if !ok {
      // 通道已关闭且无残留数据
      return
  }
  
  // 或者使用 range 消费通道（通道关闭时自动退出循环）
  for val := range ch {
      process(val)
  }
  ```

## 3. 闭包捕获循环变量
- **现象**：在循环中直接启动 goroutine 并引用循环变量，可能导致所有协程访问同一变量地址。
  ```go
  // 推荐：将变量作为参数显式传入协程函数
  for i := 0; i < 10; i++ {
      go func(idx int) {
          process(idx)
      }(i)
  }
  ```

## 4. 数据竞争检测
- **规则**：测试与持续集成阶段必须开启竞态检测器：
  ```shell
  go test -race ./...
  go run -race main.go
  ```

---

# 常用高并发工业范式骨架

## 1. Worker Pool 与反压控制（限流）

```go
package main

import (
	"context"
	"fmt"
	"sync"
)

// 限制并发量为 workerCount，任务队列带容量反压
func RunWorkerPool(ctx context.Context, workerCount int, tasks []int) {
	taskCh := make(chan int, workerCount*2) // 带反压缓冲
	var wg sync.WaitGroup

	// 启动固定数量工作协程
	for i := 0; i < workerCount; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case task, ok := <-taskCh:
					if !ok {
						return // 任务已全部派发且通道关闭
					}
					fmt.Printf("worker %d processed task %d\n", workerID, task)
				}
			}
		}(i)
	}

	// 任务分发
	go func() {
		defer close(taskCh)
		for _, task := range tasks {
			select {
			case <-ctx.Done():
				return
			case taskCh <- task:
			}
		}
	}()

	wg.Wait()
}
```

## 2. 级联超时与取消控制 (context)

```go
package main

import (
	"context"
	"time"
)

func DoSubTask(ctx context.Context) error {
	select {
	case <-time.After(2 * time.Second): // 模拟耗时任务
		return nil
	case <-ctx.Done(): // 收到上层取消或超时信号立即中断退出
		return ctx.Err()
	}
}

func main() {
	// 设置全局最长等待时间
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	_ = DoSubTask(ctx)
}
```

## 3. 错误快速收敛与一票取消 (errgroup)

```go
package main

import (
	"context"
	"fmt"
	"golang.org/x/sync/errgroup"
)

func FetchAll(ctx context.Context, urls []string) error {
	// 当任意一个任务出错时，g 自动取消同组其他所有任务的 context
	g, ctx := errgroup.WithContext(ctx)

	for _, url := range urls {
		target := url
		g.Go(func() error {
			// 将带级联取消的 ctx 传入下层调用
			if err := fetch(ctx, target); err != nil {
				return err // 任意协程返回非 nil 错误都会被捕获并触发一票取消
			}
			return nil
		})
	}

	// 等待所有协程完成，返回首个捕获到的错误
	return g.Wait()
}

func fetch(ctx context.Context, url string) error {
	return nil
}
```

## 4. 高并发线程安全字典 (sync.Map)

```go
package main

import (
	"fmt"
	"sync"
)

func DemoSyncMap() {
	var m sync.Map

	// 存取
	m.Store("server_status", "running")
	val, ok := m.Load("server_status")
	if ok {
		fmt.Println(val)
	}

	// 存在即读取，不存在则存入
	actual, loaded := m.LoadOrStore("max_conn", 1000)
	_ = actual

	// CAS 原子替换
	swapped := m.CompareAndSwap("server_status", "running", "paused")
	_ = swapped

	// 遍历（返回 false 终止遍历）
	m.Range(func(key, value any) bool {
		fmt.Println(key, value)
		return true
	})

	// 清空与删除
	m.Delete("server_status")
	m.Clear()
}
```