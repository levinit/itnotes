python并发编程，包括：

- 多进程
- 多线程
- 协程



注意，因为windows创建子进程不是采用fork模式，编写的多进程程序运行时会不断调用自身递归创建进程（无论是`multiprocessing`还是`concurrent.futures.ProcessPoolExecutor`），函数外部和`__main__`外部的内容会被重复执行，因此需要将多进程的代码置于`if __name__ == '__main__':`中。（基于此特性，可能其他位于顶层的代码也需要放在`__main__`中）

使用multiprocessing最好也添加` multiprocessing.freeze_support()`语句（在非 Windows 平台上是无效）

另外注意，`if __name__ == '__main__':`内部的变量是局部变量，且根据python特性，不能在`__main__`（和函数）中修改不可变数据类型的全局变量的值，除非在赋值语句前使用`global`。

不可变数据类型：int，float，bool，tuple，str。

```python
x=5
if __name__ == '__main__':
    global x=8 #此x是一个局部变量，不同于外部的x
    multiprocessing.freeze_support() 
    with Pool(x) as pool:
        pool.map(print, range(x))
```



# concurrent.futures标准库

[`concurrent.futures`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#module-concurrent.futures) 模块提供异步执行可调用对象高层接口，可代替threading、multiprocess等标准库。



## Executor

异步执行可以由 [`ThreadPoolExecutor`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#concurrent.futures.ThreadPoolExecutor) 使用线程，或由 [`ProcessPoolExecutor`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#concurrent.futures.ProcessPoolExecutor) 使用单独的进程来实现。 

两者都是实现抽像类 [`Executor`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#concurrent.futures.Executor) 定义的接口，它们的使用方法相同，api基本一致。

> `__main__` 模块必须可以被工作者子进程导入。这意味着 [`ProcessPoolExecutor`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#concurrent.futures.ProcessPoolExecutor) 不可以工作在交互式解释器中。

可使用`Executor`的`subumit`或`map`方法提交任务。以`ThreadPoolExecutor`为例：

```python
from concurrent.futures import ProcessPoolExecutor
from time import sleep

def task(num):
    print(f'task {num}')
    sleep(5)

#submit 提交任务
with ProcessPoolExecutor(2) as executor:
    futures=[]  #存储返回的futures任务对象列表
    for i in range(4):
		    #executor.submit(task, i)  #不需要操作futures对象时直接提交
        futures.append(executor.submit(task, i))
        
#map 提交任务
with ProcessPoolExecutor(2) as executor:
    executor.map(task, range(4))
```

- 使用方法：

  1. 创建Executor对象（进程池实例）`concurrent.futures.ProcessPoolExecutor()`

     `ProcessPoolExecutor()`常用参数

     - `max_workers`  进程池中同时运行的进程数量

       值为 `None`（默认值） 或未给出时，默认数量为机器的处理器个数。（Windows上该值有限制，参看最新的python文档说明）。

       

  2. 提交任务（调用一个方法在子进程中执行）

     Executor对象可使用以下异步调用方法

     - `submit(fn,*args,**kwargs)`  返回一个**Future对象**

     - `map(fn, *iterables, timeout=None, chunksize=1)`  

       注意：map方法返回的是迭代器，无法取得Future对象进行操作。

     

- `Executor.shutdown(wait=True,*, cancel_futures=False)`

  当待执行的 future 对象完成执行后向执行者发送信号，它就会释放正在使用的任何资源。

  *相当于进程池的`pool.close()`+`pool.join()`操作。*

  

- Future对象的常用方法：

  *使用submit提交任务才能获取到Future对象。*

  - `done()`  调用已被取消或正常结束那么返回 `True`

  - `cancel()`  尝试取消调用（只能取消未执行的任务）

    取消尚未运行的调用会返回True，否则返回False。

  - `canceled()`  如果调用成功取消返回 True

  - `running()`  如果调用正在执行而且不能被取消那么返回 `True` 

  - `result(timeout=None)`  返回调用返回的值（该方法阻塞）

  - `exception(timeout=None)`  返回由调用引发的异常

  - `add_done_callback(fn)`  future 对象被取消或完成运行时调用回调函数 *fn*

  

- `wait()`函数

  `concurrent.futures.wait(fs, timeout=None,return_when=ALL_COMPLETED)`

  `fs`: 需要执行的序列

  `timeout`: 等待的最大时间，如果超过这个时间即使线程未执行完成也将返回 `return_when`：返回结果的条件。默认为`ALL_COMPLETED`全部执行完成再返回，另`FIRST_COMPLETED`表示函数将在任意可等待对象结束或取消时返回，`FIRST_EXCEPTION`表示函数将在任意可等待对象因引发异常而结束时返回。

  

  返回两个set组成的tuple：

  第1个set名称为`done`，包含在等待完成之前已完成的 future（包括正常结束或被取消的 future）。

  第2个set名称为`not_done`，包含未完成的 future（包括挂起的或正在运行的 future）。

  

- `as_completed()`函数

  `concurrent.futures.as_completed(fs, timeout=None)`

  返回一个包含 *fs* 所指定的 [`Future`](https://docs.python.org/zh-cn/3/library/concurrent.futures.html#concurrent.futures.Future) 实例的迭代器，这些实例会在完成时生成 future 对象。

  在没有任务完成的时候会阻塞，在有某个任务完成的时候，会`yield`这个任务，就能执行for循环下面的语句，然后继续阻塞住，循环到所有的任务结束。

# 线程标准库

## threading基于线程的并行

使用`threading.Thread()`创建一个线程对象，可以在单独的线程中执行任何的在 Python 中可以调用的对象。

```python
import threading
import time

def process(count):
    for i in range(count):
        time.sleep(1)
        print(i)
        
thread = threading.Thread(target=process, args=(5,))
#daemon=True将线程设置为后台线程，主线程不会等待该后台线程结束，该线程输出内容也不会在控制台上显示
#thread = threading.Thread(target=process, args=(5,),daemon=True)
thread.start()

#is_alive()获取线程是否运行True/False
print(f'thread status: {thread.is_alive()}')

thread.terminate() #terminate()发送中断信号结束进程

thread.join()      #join()阻塞主线程直到前面的thread完成

print("I am main thread")
```

> 由于全局解释锁（GIL）的原因，Python 的线程被限制到同一时刻只允许一个线程执行这样一个执行模型。所以，Python 的线程更适用于处理I/O和其他需要并发执行的阻塞操作（比如等待I/O、等待从数据库获取数据等等），而不是需要多处理器并行的计算密集型任务。

`threading.Thread()`创建进程对象时可设置`daemon=True`参数将这个线程其设置为守护进程，进程对象的`isDaemon()`方法判断其是否为后台进程。



## queue.Queue线程间通信

创建队列对象

- `queue.Queue()`   FIFO队列
- `queue.Queue.LifoQueue()`   LIFO队列
- `queue.PriorityQueue()`   带优先级的队列，队列里面的任务按照优先级排序
- `queue.SimpleQueue()`  简单队列（缺少一些高级方法，`task_done`，`join`等）

```python
#示例 处理一个目录中所有文件
import queue

dir=/etc
q = queue.Queue()  #如不传给Queue()参数指明队列容量，则默认队列容量无限制

#创建队列 由要被处理的文件路径组成
for file in os.listdir(dir):
   file_path = os.path.join(dir, file)
   q.put(file_path)

def worker():
    while not q.empty():
        file=q.get()
        #do some thing for file
        q.task_done()
        
    
t=threading.Thread(target=worker, daemon=True)
t.start()

q.join()
print("DONE")
```

注意：

- 线程间通信实际上是在线程间传递**对象引用**，如果担心对象的共享状态，那么最好只传递不可修改的数据结构（如：整型、字符串或者元组）或者一个对象的深拷贝。

- 每次执行`q.get()`就会从队列中取出一个要处理的项。

- `q.qsize()` ， `q.full()` ， `q.empty()` 等实用方法可以获取一个队列的当前大小和状态。

  但要注意，这些方法都不是线程安全的，因此不时所有情况下都能使用这些方法来准确判断队列中的数据是否都已经获取完，除非在使用以上方法判断前已经将所有要处理的项加入了队列。

  例如后文示例的消费者生产者模型中，生产者线程和消费者线程各自运行，一些场景中，因为各自处理耗时的不确定性，消费者线程处理完成了队列现有所有项，但生产者后续仍然有新的待处理项加入队列的情况。

  另外，如果要处理的任务数量已知的情况，可以自行维护一个计数器，用以和总任务数量对比来判断队列中的项是否全部处理完成，在每次执行完任务和更新计数器。

  

### 消费者生产者模型

队列作为**容器**，存储通讯数据；**生产者**线程向队列中put数据；**消费者**线程从队列中get数据进行处理。

生产者不必在因为消费者速度过慢而等待，直接将任务放入容器即可，消费者也不必因生产者生产速度过慢而等待，直接从容器中获取任务，以此达到了资源的最大利用。

```python
from queue import Queue
from threading import Thread

# 生产者函数
def producer(out_q, source_data):
    for item in source_data:
        out_q.put(item)  # 将生产的数据放到队列中
    q.join()  # 等待队列结束

# 消费者函数
def consumer(in_q):
    while True:
        data = in_q.get()  # 从队列中获取数据
        print(f'get data: {data}') # do something
        in_q.task_done()

q = Queue(maxsize=2)  # 默认为0，无限制

# 生产者线程
p = Thread(target=producer, args=(q, 'hello'))
# 消费者线程，设置为守护线程，主线程结束时消费者线程也会一并结束
c = Thread(target=consumer, args=(q,), daemon=True)

p.start()  # 启动生产者线程
c.start()  # 启动消费者线程

p.join()  # 等待生产者线程结束
```

producer函数的`q.join()`使得生产者线程生产完毕后将阻塞，监听队列任务的完成状态；

consumer函数中每次任务完成后，将执行`task_done()`向`q.join()`发送完成信号，所有任务完成后，`q.join()`结束阻塞状态，生产者线程结束。

`p.join()`使得主线程等待生产者线程结束，再继续执行主线程。

主线程结束后作为守护线程（设置` daemon=True`）的消费者线程会一并结束。



生产者消费者模型使用Queue作为容器实现解耦，通过 `task_done()` 和 `join()` 互相通信实现对任务数量的监听。



# 进程标准库

## subprocess子进程管理

尽管`os.system()`和`os.popen()`可执行外部shell命令，但是它们功能简单，无法满足一些控制需求：

- `os.system()`

  立即执行给定的shell命令，并阻塞当前python进程直到执行的shell命令结束。

  其产生的任何输出（标准输出和标准错误输出）将会发送到解释器的标准输出流中，可通过变量接收执行完成后返回退出状态码。

  ```python
  result=os.system("pwd -P")   #result值为执行的shell命令的退出码
  ```

- `os.popen(command[, mode[, bufsize]])`

  打开一个管道执行给定的shell命令并返回一个文件描述符号为fd的打开的文件对象 ，可对该对象读或写，只能和管道单向通讯，

  shell命令的输出会发送到这个文件对象中

  - mode，模式权限：默认值`r`读（可省略），写则为`w` ，只能读或写二选一。

  - buffering，文件需要的缓冲大小：默认值`-1`表示系统默认值（可省略，任何负值均表示使用系统默认值），0为无缓冲，1为行缓冲区（仅在文本模式下可用），用大于1的整数表示固定大小的块缓冲区的字节大小。

    > 一般来说，对于tty设备，它是行缓冲；对于其它文件，它是全缓冲。

  ```python
  c=os.popen("pwd -P", mode='r', buffering=-1)
  c.read()       #read()读取文件对象
  c.readlines()  #readlines()返回每行内容组成的list
  #c.write()     #向管道写入内容，由要执行的shell命令去接收
  c.close()      #close成功时不返回任何值；close()失败时返回系统的返回值
  ```

  

### subprocess.Popen()

```python
subprocess.Popen(args, bufsize=-1, executable=None, stdin=None, stdout=None, stderr=None, 
preexec_fn=None, close_fds=True, shell=False, cwd=None, env=None, universal_newlines=False, 
startupinfo=None, creationflags=0,restore_signals=True, start_new_session=False, pass_fds=(),
*, encoding=None, errors=None)
```

- stdin、stdout 和 stderr：子进程的标准输入、输出和错误。其值可以是  `subprocess.PIPE`、`subprocess.DEVNULL`、一个已经存在的文件描述符、已经打开的文件对象或者  `None`（默认值，表示什么都不做）

```shell
p=subprocess.Popen(["id","-u"])
```

`subprocess.Popen()`返回一个Popen对象，常用方法：

- `poll()`: 检查进程是否终止，如果终止返回 returncode，否则返回 None。 
- `wait(timeout)`: 等待子进程终止。  （Popen()不会阻塞当前进程，除非显式地调用`wait()`方法）
- `communicate(input,timeout)`: 和子进程交互，发送和读取数据。  
- `send_signal(singnal)`: 发送信号到子进程 。 
- `terminate()`: 停止子进程,也就是发送SIGTERM信号到子进程。  
- `kill()`: 杀死子进程。发送 SIGKILL 信号到子进程。 

常用属性：

- `args`   执行的shell命令
- `pid`  子进程的ID
- `returncode`  子进程的返回码
- `stdin`、`stdout`和`stderr`  参看上文对`subprocess.Popen()`参数的说明，如需获取输出，需要在调用`Popen()`时指定非`None`值。



`Popen()`是 subprocess的核心，subprocess的方法都是对Popen的封装。



### 对Popen()封装的方法

注意，以下方法都会阻塞当前进程直到子进程执行完毕。

#### subprocess.run()

`run()` 等待子进程完成，返回一个 CompletedProcess 类型对象的实例

```python
subprocess.run(args, *, stdin=None, input=None, stdout=None, stderr=None, capture_output=False, shell=False, cwd=None, timeout=None, check=False, encoding=None, errors=None, text=None, env=None, universal_newlines=None)

p=subprocess.run(["sleep","233"]) #CompletedProcess(args=['pwd', '-P'], returncode=0)
```



返回的CompletedProcess对象，有：

- `args`  、`stdout`、`stderr` 和`returncode` 属性（参看上文Popen对象的属性说明）
- `check_returncode()`方法  用于检查返回码。如果返回状态码不为零，抛出`CalledProcessError`异常（状态码为0则什么也不发生）



#### call()、check_call()和checkoutput()

`call()` 、`check_call()`和`check_output()`是对`run()`的进一步封装，只返回特定的内容。



- `call()`  返回退出码

  ```python
  process=subprocess.call(["sleep","233"])
  ```



- `check_call()`  返回并检查退出码

  如果返回的状态码不为0，会抛出错误`subprocess.CalledProcessError`，该对象包含有returncode属性，可用`try…except…`来检查。

  ```python
  subprocess.check_call("whoami")
  ```



- `check_output()` 返回的标准输出，并检查退出码

  如果返回的状态码不为0，会抛出错误`subprocess.CalledProcessError`，该对象包含有returncode属性和output属性，可用`try…except…`来检查。

  ```python
  subprocess.check_output("whoami")
  ```



### Popen使用注意

#### shell=True的安全风险

`subprocess.Popen()`即其他以`subprocess.Popen()`封装的方法，均有一个`shell=<Bool>`的参数。

默认shell值为False，命令以IFS（空白分隔符）分隔各个部分，需要以列表形式传入：

```python
subprocess.Popen(["id","-u"])
```



如果shll值为True，则无需以列表形式传入，示例：

```python
subprocess.Popen("id -u" ,shell=True)
```

如果要调用的外部执行命令获取自字符串，对命令内容不可控，则存在命令注入风险。使用列表形式则增加了确定性，参数可控更为安全。



#### 函数调用的死锁风险

- call、check_call和check_out，使用管道stdout=PIPE or stderr=PIPE 存在死锁风险，可使用 [`Popen.communicate()`](https://docs.python.org/zh-cn/3/library/subprocess.html#subprocess.Popen.communicate) 规避。

  subprocess 官方文档在上面几个函数中都标注了安全警告：

  > 当 `stdout=PIPE` 或者 `stderr=PIPE` 并且子进程产生了足以阻塞 OS 管道缓冲区接收更多数据的输出到管道时，将会发生死锁。当使用管道时用 [`Popen.communicate()`](https://docs.python.org/zh-cn/3/library/subprocess.html#subprocess.Popen.communicate) 来规避它。

- popen和popen.wait() ，可能会导致死锁，可使用 [`Popen.communicate()`](https://docs.python.org/zh-cn/3/library/subprocess.html#subprocess.Popen.communicate) 规避。

  这个方法会把输出放在内存，而不是管道里，如果要获得程序返回值，可以在调用 Popen.communicate() 之后取 Popen.returncode 的值。

- call、check_call、popen、check_output 函数中，若参数shell=True，命令参数不能为list，若为list则引发死锁。



## multiprocessing基于进程并行

### Process创建进程

Process创建进程对象，进程对常用方法：

- 启动：`start()`

- 等待：`join([timeout])` 将阻塞主进程

- 结束：

  - `terminate()`

     在Unix上，这是使用 `SIGTERM` 信号完成；在Windows上使用 `TerminateProcess()` 。 

    注意，不会执行退出处理程序和finally子句等，子进程的后代进程将变成孤儿进程。

  - `kill()`  与 [`terminate()`](https://docs.python.org/zh-cn/3/library/multiprocessing.html#multiprocessing.Process.terminate) 相同，但在Unix上使用 `SIGKILL` 信号

  - `close`()  关闭[`Process`](https://docs.python.org/zh-cn/3/library/multiprocessing.html#multiprocessing.Process)对象并释放与之关联的所有资源。如果底层进程仍在运行，则会引发 [`ValueError`](https://docs.python.org/zh-cn/3/library/exceptions.html#ValueError) 。

```python
from multiprocessing import Process

process = Process(target=print, args=('Hello World',))
process.start()  # Start the process
process.join()  # Wait for the process to finish
# process.close()  # Close the process
```



### Pool进程池

另，可使用[concurrent.futures.ProcessPoolExecutor](#concurrent.futures并行任务) 模块，它提供异步执行可调用对象高层接口，其会使用`multiprocessing`模块。

使用`multiprocessing.Pool()`创建进程池对象，该对象可使用以下方法处理多个子进程：

| Functions   | Multi-args | Concurrence | Blocking | Ordered-results |
| ----------- | ---------- | ----------- | -------- | --------------- |
| map         | no         | yes         | yes      | yes             |
| apply       | yes        | no          | yes      | no              |
| map_async   | no         | yes         | no       | yes             |
| apply_async | yes        | yes         | no       | no              |

map 和 map_async 的参数为迭代器类型，可批量调用；apply和apply_async只能一个个调用。

apply_async调用立即返回而不是等待结果，可调用其get()方法获取返回值（get()方法将阻塞直到功能完成），因此，`pool.apply(func, args, kwargs)`等效于`pool.apply_async(func, args, kwargs).get()`。

```python
from multiprocessing import Pool

pool = Pool(processes=4)  # os.cpu_count()

with pool:
    pool.map(print, range(5))

#不使用with
#for i in range(5):
#    pool.apply_async(print, args=(i,))
#pool.close()  #停止接收其他进程到pool
#pool.join()   #主进程等待子进程结束
```



## 进程间通信

### multiprocessing.Queue

`multiprocessing.Queue`用于进程间数据交换，而[queue.Queue](#线程间通信queue.Queue)用于多线程间交换数据，二者使用方法类似。

```python
from multiprocessing import Process, Queue
def f(q):
    q.put([11, None, 'lily'])
if __name__ == '__main__':
    q = Queue()
    p = Process(target=f, args=(q,))
    p.start()
    print(q.get())
    p.join()

#执行结果：[11, None, 'lily']
```



### Pipe类

`Pipe()`函数返回两个对象 `conn1` 和 `conn2` ，这两个对象表示管道的两端。

Queue 和 Pipe 拥有相似的功能。但在日常开发中，两者使用的场景有所不同，Pipe 多用于两个进程间通信，而 Queue 则多用于两个及以上进程间的通信。

`Pipe()`函数有一个可选参数 duplex：

- 默认值为 True，表示该管道是双向的，即两个对象都可以发送和接收消息。
- 如果值设置为False ，表示该管道是单向的，即 `conn1` 只能用于接收消息，`conn2`只能用于发送消息。

```python
from multiprocessing import Process, Pipe 

def f(conn):
  conn.send([11, None, 'lily'])
  conn.close()

if __name__ == '__main__':
  conn1, conn2 = Pipe()
  p = Process(target=f, args=(conn2,))
  p.start()
  print(conn1.recv())
  p.join() #执行结果： [11, None, 'lily'] 
```



# 协程

使用 async/await 语法声明的协程是编写异步应用程序的首选方式。

```python
import asyncio

async def main():
    print("Hello")
    await asyncio.sleep(1)
    print("World")

asyncio.run(main())
```

异步协程函数必须在`def`前使用`async`关键字，运行一个协程，asyncio提供了三种主要机制：

- 在`async`函数使用`await` 中等待一个协程

  > 如果一个对象可以在 `await`语句中使用，那么它就是 **可等待** 对象。

- 使用`asyncio.run()` 运行一个async函数

- `asyncio.create_task()` 函数并发运行作为 asyncio任务的多个协程



多任务协程示例：

```python
import asyncio

async def nested():
    return 42

async def main():
    task = asyncio.create_task(nested())
    # "task" can now be used to cancel "nested()", or
    # can simply be awaited to wait until it is complete:
    await task

asyncio.run(main())
```



等待超时处理：`await asyncio.wait()`

```python
async def foo():
    return 42

task = asyncio.create_task(foo())
done, pending = await asyncio.wait({task})  #返回done或pending状态

if task in done:
    # Everything will work as expected now.
```