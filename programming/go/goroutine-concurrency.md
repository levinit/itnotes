# goroutine

goroutine是由Go的运行时（runtime）调度和管理，创建一个协程只需要在调用函数前加上go关键字即可。

```go
func hello() {
    fmt.Println("Hello Goroutine 1 !")
}
func main() {
    go hello()  //创建协程调用
  //匿名函数运行
    go func(msg string) {
          fmt.Println(msg)
    }("hello goroutine 2")
    fmt.Println("main goroutine done!")
}
```

# channel通信

> Go语言的并发模型是CSP（Communicating Sequential Processes），提倡通过通信共享内存而不是通过共享内存而实现通信。

Golang使用channel实现协程之间、协程与主线程之间的通信。

## 通道类型

- 无缓冲通道——阻塞通道/同步通道

  通道内不能存储值（无缓冲区），发送方和接收方会同步化，如果发送-接收操作未完成，先执行的一方就会阻塞，以等待对方：

  - 发送方先执行，将阻塞以等待接收方的接收请求请求；

  - 接收方先执行，将阻塞以等待发送方向通道发送值。

  值发送成功，两个goroutine将继续执行。

  ```go
  //声明
  var name chan type
  //声明并初始化 make(chan 类型)
  var name=make(chan type)
  
  //例子
  var ch1 chan int    //传递整型数字对通道
  ch2:=make(chan int)
  ```

  

- 有缓冲通道——通道容量大于零的通道

  通道的容量表示通道中能存放元素的数量。当通道中存满（缓冲区已无可用空间）时，发送方继续向通道发送数据则会阻塞，直到接收方取走通道中的数据，出现可用空间，才能继续发送。

  初始化时指定其通道容量：

  ```go
  ch:=make(chan int ,1)  //容量为1的有缓冲区通道
  ```

  内置的len函数获取通道内元素的数量，cap函数获取通道的容量。



## 通道状态

- nil：通道未初始化的状态（零值），只进行了声明，或者手动赋值为`nil`

- active：正常的channel，可读或者可写

- closed：已关闭

  

3种操作和3种通道状态可以组合出9种情况：

| 操作 | nil的channel | 正常channel | 已关闭channel |
| ---- | ------------ | ----------- | ------------- |
| 发送 | 阻塞         | 成功或阻塞  | 读到零值      |
| 接收 | 阻塞         | 成功或阻塞  | panic         |
| 关闭 | panic        | 成功        | panic         |



## 通道操作

- **发送**数据到通道——写

  ```go
  //channelName <- value
  ch1 <- 10   //发送10到ch1通道中
  ```

- 从通道**接收**数据——读 

  ```go
  //valName = <- channelName
  x := <- ch1  //从ch1通道接收数据并赋值给变量x
  <- ch1       //仅接收
  ```

- 关闭通道

  ```go
  close(channelName)
  ```

  对关闭通道后再进行发送和关闭会触发panic，但是对其接受会：

  - 通道中有值：一直获取值直到通道为空
  - 通道中没有值：获取到对应类型的零值

  

通道使用示例：

```go
package main

func main() {
	ch := make(chan int) //创建通道ch 无缓冲通道

	go func() {
		println("~~~ receive data from channel ch")
		<-ch          //接收操作
	}()

	println("~~~ send data to channel ch: 2333")
	ch <- 2333      //发送操作
	println("===sent done")  //只有接收方完成接收后才会执行本行
}
```



## 单向channel

默认情况下，通道 channel 都是双向的，接收方也可以成为发送方向通道写数据。

定义单向通道只需要在chan的前面或后面添加`<-`指定方向，在前面为只接收，在后面为只发送。

```go
//var name chan type      //双向
//var name chan <- type   //单向发送
//var name <- chan type   //单向接收

var ch1 chan int          // ch1是一个双向通道
var ch2 chan <- float64   // ch2是单向通道，只用于写float64数据
var ch3 <- chan int       // ch3是单向通道，只用于读int数据
```

**可以将 channel 隐式转换为单向队列，只收或只发，不能将单向 channel 转换为普通 channel。**

只接收通道在使用时无需再使用`<-ch`操作，直接调用这个channel即可读取。

```go
var in <-chan int
println(in)
```



### 生产者消费者模型

单向 channel 最典型的应用是 “生产者消费者模型”，某个模块（函数等）负责产生数据，形象地称为生产者；另一个模块处理数据，形象地称为消费者。参看前面的[channel通信示例2](#channel通信)代码。

```go
package main

import "fmt"

// 生产者 ---> 缓冲区 ---> 消费者

// 生产者
// 2.1 传入的双向通道被转换为只发送通道
func producer(out chan<- int) {
	defer close(out)
	for i := 0; i < 3; i++ {
		out <- i //2.2 生产（发送数据发送到通道）
	}
}

// 消费者
// 3.1 传入的双向通道被转换为只接收通道
func consumer(in <-chan int) {
	for num := range in { //3.2 消费（从通道中接收数据）
		fmt.Println(num) //3.3 打印接收到的数据
	}
}

func main() {
	c := make(chan int, 5) //1.0 创建一个双向通道 (也可以使用非缓冲通道)
	go producer(c)         //2.0 将通道传递给生产者
	consumer(c)            //3.0 将通道传递给消费者

	fmt.Println("done")
}
```



# 协程组

## sync.WaitGroup协程组并发同步

由于主线程并不会等待协程完成，在提交协程后就会返回主线程，这意味着如果主线程结束，所有未完成的协程也会被销毁，因此需要控制主线程等待协程的完成。

可使用channel传递协程状态，让主线程阻塞以等待协程完成。单Go提供了一个更简单的sync.WaitGroup方法实现协程同步

```go
var wg sync.WaitGroup

func hello(i int) {
    defer wg.Done() //当前协程完成时进行登记，使登记的协程数量-1
    fmt.Println("Hello Goroutine!", i)
}

func main() {
    for i := 0; i < 10; i++ {
        wg.Add(1)    // 登记1个协程状态，登记协程数量+1
        go hello(i)  // 启动1个协程
    }
  // wg.Add(10)      // 或者不在上方循环中每次添加一个计数，而是一次性添加所有计数
    wg.Wait()        // 等待所有登记的协程结束
}
```

WaitGroup内部实现了一个计数器以记录未完成的操作个数。它提供了三个方法：

- `Add()`：添加协程计数
- `Done()`：登记协程完成，从登记的协程计数中减掉完成的协程计数
- `Wait()`：等待所有登记的协程完成，即登记的协程计数变为0时结束等待，继续主线程。



## errgroup.Group协程组错误处理

> errgroup包是Go语言标准库中的一个实用工具，用于管理一组协程并处理它们的错误。

`errgroup.Group`结构可管理和同步一组具有相同生命周期的 goroutines，并且在出现错误时取消它们。

```go
var eg errgroup.Group
for i := 0; i < 5; i++ {
    eg.Go(func() error {
     return errors.New("error")
    })

    eg.Go(func() error {
     return nil
    })
}

if err := eg.Wait(); err != nil {
    // 处理错误
}
```

# 并发控制

## select控制

`select`用于在多个通道操作（发送或接收）之间进行选择。

`select` 会阻塞，直到其中一个通道操作可以进行，然后执行该操作。如果有多个通道操作可以进行，则会随机选择一个。

```go
	c1 := make(chan string)
	c2 := make(chan string)

	go func() {
		time.Sleep(1 * time.Second)
		c1 <- "one"
	}()
	go func() {
		time.Sleep(2 * time.Second)
		c2 <- "two"
	}()

	for i := 0; i < 2; i++ {
		select {
		case msg1 := <-c1:
			fmt.Println("received", msg1)
		case msg2 := <-c2:
			fmt.Println("received", msg2)
		}
	}
```



## context.Context生命周期管理

`context.Context` 是 Go 语言在处理多个 goroutine 之间的超时、取消信号、传递元数据等问题时的一种约定。

- 协程（被）取消

  使用`context.WithCancel()`创建一个可取消的上下文，并使用`context.WithTimeout()`创建一个带有超时的上下文。

  ```go
  ctx, cancel := context.WithCancel(context.Background())
  
  go func() {
     //so something
      if someCondition {
          cancel() // cancel a goroutine
      }
  }()
  
  select {
  case <-ctx.Done():
      // The routine is canceled or completed
  }
  ```

  

- 协程超时

  `context.WithDeadline()`和`context.WithTimeout()`函数可以用于创建带有截止时间的上下文，以限制异步任务的执行时间。

  ```go
  func doTask(ctx context.Context) {
     //so something
      select {
      case <-time.After(5 * time.Second):
          // //What to do if timed out
      case <-ctx.Done():
          // Context cancellation processing
      }
  }
  
  ctx := context.Background()
  ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
  defer cancel()
  go doTask(ctx)
  ```

  

- 协程间上下文传递

  `context.WithValue()`函数可用于在上下文中传递键值对，以在协程之间共享和传递上下文相关的值。

  ```go
  type keyContextValue string
  
  func doTask(ctx context.Context) {
      if val := ctx.Value(keyContextValue("key")); val != nil {
          // you can use the context value here
      }
  }
  
  ctx := context.WithValue(context.Background(), keyContextValue("key"), "value")
  go doTask(ctx)
  ```

  

## 并发数量限制

当要并发执行的任务过多时，常需要限制并发数量。

*如避免内存占用过大造成程序崩溃，存在cpu密集计算而并发数量远多于可用cpu数量造成大量cpu切换*。

解决思路：使用缓冲区通道存储任务信息，一个任务占用一个位置（即缓冲区中的元素）；复用指定数量的goroutine无限循环获取通道数据，逐一消耗掉通道的元素。

1. 创建一个指定大小为M的缓冲通道ch；

   这个M值应当大于或等于并发数量N，一般可以设置为和并发数量一样大。

   

2. 创建一个循环，发起N个gorountine，N即为要限制的并发数量；

   在每个goroutine函数中遍历缓冲通道ch，如果通道中有数据，就会消耗掉通道中的一个元素（接收者）；

   每个goroutine每次承担一个任务，因此就有N个goroutine并发执行N个任务。

   

3. 循环向通道ch中发送数据（发送者），当通道填满时则循环会阻塞，直到有可用空间时才能继续添加。

   *对于任务数量较少的情况，可以在第1步中建立和任务数量一致的通道。

如果需要阻塞主线程，可以使用`sync.WaitGroup`等待协程。



```go
package main

import (
	"math/rand"
	"sync"
	"time"
)

func main() {
	workerCount := 3                        //同时运行的goroutine数量
	workerCh := make(chan int, workerCount) //建立缓冲通道
	wg := sync.WaitGroup{}

	for i := 0; i < workerCount; i++ { //创建指定数量的goroutine
		go func() {
			for w := range workerCh { //无限迭代channel
				//模拟耗时任务
				spendTime := rand.Intn(5) + 1
				println("task", w, " will spend: ", spendTime, "s")
				time.Sleep(time.Second * time.Duration(spendTime))
				println("[DONE] task", w)
				wg.Done() //任务完成，计数器减一
			}
		}()
	}

	//模拟10个任务
	for i := 0; i < 10; i++ {
		wg.Add(1)     //计数器加一
		workerCh <- i //循环向通道中发送任务，如果通道已满，会阻塞
	}

	wg.Wait()       //计数器为0时，解除阻塞
	close(workerCh) //关闭通道（根据情况可选）
}
```



# 读写锁

当多个协程并发访问共享数据时，为避免数据竞争，可用于在访问共享资源之前进行锁定。

## 并发读写锁

读锁：`RLock()`方法加锁，`RUnLock()`方法解锁

写锁：`Lock()`方法加锁，`UnLock()`方法解锁



- `sync.Mutex`      互斥锁

  在确保每次只有一个协程能访问某个数据结构的场景下使用。

  ```go
  var count int
  var wg sync.WaitGroup
  
  func main() {
  	wg.Add(10)
  	for i:=0;i<5;i++ {
  		go read(i)
  	}
  	for i:=0;i<5;i++ {
  		go write(i);
  	}
  	wg.Wait()
  }
  
  func read(n int) {
    v := count //get the value of count (read)
  	wg.Done()
  }
  
  func write(n int) {
  	v := rand.Intn(1000)
    count = v //reassign to count  (write)
  	wg.Done()
  }
  ```

  

- `sync.RWMutex`   读写锁

  在读多写少的场景下使用。

  多个协程可以同时获取读锁（可读操作），但不能获取写锁（不可写操作）。

  一个协程获取写锁（进行写操作）时，其他协程不能获取写锁。

  ```go
  var count int
  var wg sync.WaitGroup
  var rw sync.RWMutex
  
  func main() {
  	wg.Add(10)
  
  	for i:=0;i<5;i++ {
  		go read(i)
  	}
  	for i:=0;i<5;i++ {
  		go write(i);
  	}
  	wg.Wait()
  }
  
  func read(n int) {
  	rw.RLock() //read lock, can not write now but others can read
  	v := count
  	wg.Done()
  	rw.RUnlock()
  }
  
  func write(n int) {
  	rw.Lock() //write lock, only 1 goroutine can write now
  	v := rand.Intn(1000)
  	count = v
  	wg.Done()
  	rw.Unlock()
  }
  ```



## sync.Map

`sync.Map` 是一个线程安全的 map，可以在多个 goroutine 之间安全地使用，而无需额外的锁。

其使用了一种称为 "懒惰删除" 的策略来处理删除操作，以及一种优化读操作的方法来处理在**读多写少**的情况下的并发访问，比单纯的读写锁效率更高；但是如果写操作较多，普通的 map 加锁可能会更高效。

`sync.Map` 的内部有两个 map：

- 只读的 `read` map
- 可读写的 `dirty` map

> 大部分读操作都在 `read` map 上进行，这使得在高并发读的情况下，`sync.Map` 可以避免大量的锁竞争。写操作首先在 `dirty` map 上进行，然后在一定条件下将 `dirty` map 提升为 `read` map。删除操作则是通过标记被删除的键值对，然后在后续的写操作中清理它们，从而实现 "懒惰删除"。

```go
var m sync.Map

// Store a pair of key-value
m.Store("k1", "v1")

// Load returns the value stored in the map for a key, or nil if no value is present.
val, ok := m.Load("k1")
if ok {
  fmt.Println(val) // Output: v1
}

// Range calls f sequentially for each key and value present in the map. 
// If f returns false, Range stops the iteration.
m.Range(func(key, value interface{}) bool {
  fmt.Println(key, value)
  return true
})

m.Delete("hello") // Delete deletes the value for a key.
```

# 