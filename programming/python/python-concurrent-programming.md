[TOC]

# Python 并发模型与选型矩阵

## GIL 本质与现状

CPython 解释器内建全局解释器锁（GIL, Global Interpreter Lock），用于保证解释器内部引用计数与内存管理的线程安全。**在标准发行版中，单个 CPython 进程内同一时刻仅允许一个操作系统线程执行 Python 字节码**。

- **自由线程模式（PEP 703）**：从 Python 3.13+ 开始，官方提供了可选的无 GIL 构建（可执行文件通常带 `t` 后缀，如 `python3.14t`，运行时通过 `sys._is_gil_enabled()` 检测）。该模式下多线程可真正并行利用多核 CPU。
- **生产与架构现实**：由于大量历史 C/C++ 扩展生态（如部分科学计算与硬件驱动）需要时间适配线程安全，且无锁引用计数伴随轻微单线程性能折损，**标准构建中 GIL 仍是默认开启状态**。对于高并发多核计算与高吞吐网络服务，**直接采用 Go 等原生支持轻量协程与真正并行的语言是更稳健的选型决策**。

| 并发模型 | 适用场景 | 核心机制 | 优势 | 劣势 / 边界限制 |
| :--- | :--- | :--- | :--- | :--- |
| **多进程 (`multiprocessing`)** | **CPU 密集型**（图像处理、科学计算、数据预处理） | 每个进程拥有独立的 Python 解释器与独立 GIL | 绕过 GIL，利用多核 CPU 算力 | 内存开销大；跨进程 IPC 需经 Pickle 序列化，大对象通信性能低 |
| **多线程 (`threading` / `ThreadPoolExecutor`)** | **阻塞式网络与文件 I/O**（调用第三方同步 SDK、等待数据库响应） | OS 原生线程；遇到 I/O 阻塞或底层 C 计算时释放 GIL | 内存共享直观、启动开销小于进程 | 在标准 GIL 环境下无法加速纯 Python CPU 计算；需防数据竞争 |
| **协程 (`asyncio`)** | **高并发异步网络 I/O**（Web 服务、长连接通信、高并发抓取） | 用户态单线程事件循环（Event Loop），`async/await` 协作式让出 | 单机承载数十万并发连接，内存占用极低 | 代码有语法染色性；严禁包含同步阻塞代码（会直接卡死事件循环） |

---

# 多进程核心暗坑与生产防御

## 1. 进程启动方式与 Windows / macOS 递归炸弹
- **机制**：
  - `fork`（Linux 默认）：直接克隆父进程内存空间，启动极快，但容易因锁状态克隆引发死锁。
  - `spawn`（Windows 默认，macOS Python 3.8+ 默认）：全新启动一个 Python 进程并重新导入主模块。
- **致命陷阱**：在 `spawn` 模式下，若未将多进程启动逻辑置于 `if __name__ == '__main__':` 保护块内，子进程导入主文件时会递归重新创建子进程，导致系统资源耗尽死机（Fork-bomb）。
- **防御准则**：所有涉及 `multiprocessing` 或 `ProcessPoolExecutor` 的主入口，必须包裹在 `if __name__ == '__main__':` 之后。

## 2. 对象可序列化（Pickle）限制
- **陷阱**：主进程向子进程分发任务时，参数与返回结果必须能够被 `pickle` 模块序列化。
- **不支持的对象**：`lambda` 匿名函数、闭包函数、类内部动态定义的临时函数、未绑定的生成器。若传入此类对象会抛出 `PicklingError`。

---

# 现代并发工业范式骨架

## 1. 统一线程/进程池 (concurrent.futures)

`concurrent.futures` 提供了统一的高层抽象，只需切换执行器即可在多线程与多进程之间无缝平移：

```python
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed
import time

def process_item(item: int) -> int:
    return item * item

# 任务分发与结果流式收取
def run_parallel_tasks():
    items = list(range(10))

    # CPU 密集型切换为 ProcessPoolExecutor(max_workers=4)
    # I/O 密集型切换为 ThreadPoolExecutor(max_workers=20)
    with ProcessPoolExecutor() as executor:
        # 方法 A: 保持原序批量映射（适合按序汇总）
        results = list(executor.map(process_item, items))

        # 方法 B: 哪个先完成就先处理哪个（适合处理时间不均衡的任务）
        future_to_item = {executor.submit(process_item, x): x for x in items}
        for future in as_completed(future_to_item):
            orig_item = future_to_item[future]
            try:
                data = future.result()
            except Exception as e:
                print(f"Task {orig_item} generated exception: {e}")
```

## 2. 异步结构化并发 (asyncio TaskGroup)

在 Python 3.11+ 中，推荐使用 `asyncio.TaskGroup` 替代传统的 `asyncio.gather`，具备严格的上下文管理与一票取消机制（任一协程异常，同组其他协程自动取消）：

```python
import asyncio

async def fetch_api(endpoint: str) -> dict:
    await asyncio.sleep(0.5) # 模拟非阻塞网络 I/O
    return {"endpoint": endpoint, "status": "ok"}

async def main():
    endpoints = ["/users", "/orders", "/metrics"]
    results = []

    # 结构化并发：任意任务异常触发整体取消与异常汇总
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_api(url)) for url in endpoints]

    # TaskGroup 退出时确保所有任务均已成功完成
    results = [t.result() for t in tasks]
    print(results)

if __name__ == '__main__':
    asyncio.run(main())
```

## 3. 异步与同步阻塞代码混合运行
在 `asyncio` 事件循环中严禁直接调用耗时计算或同步阻塞式 I/O（如 `requests`、传统磁盘文件读写）。必须将其推入线程池执行以防阻塞整个事件循环：

```python
import asyncio
import requests

def blocking_io_call(url: str) -> int:
    # 阻塞式调用
    resp = requests.get(url, timeout=5)
    return resp.status_code

async def async_handler():
    loop = asyncio.get_running_loop()
    # 将阻塞同步调用交由底层默认线程池执行，不卡死协程事件循环
    status = await loop.run_in_executor(None, blocking_io_call, "https://api.github.com")
    print(f"Fetched with status: {status}")
```