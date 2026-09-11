[TOC]

# Python I/O 与文件处理核心心智模型

## 文本模式与二进制模式契约

| 模式分类 | 典型标识 | 核心区别与心智模型 | 生产注意事项 |
| :--- | :--- | :--- | :--- |
| **文本模式 (Text)** | `'r'`, `'w'`, `'a'` | 读取输出为 Unicode `str`；内部自动执行字节与字符编解码转换 | **必须显式指定 `encoding="utf-8"`**，严禁依赖平台默认编码（Windows 默认可能为 GBK 导致乱码崩溃） |
| **二进制模式 (Binary)** | `'rb'`, `'wb'`, `'ab'` | 读取输出为原始 `bytes`；不进行任何编码与换行符转换 | 处理图片、压缩包、网络报文、序列化对象（Pickle/Protobuf）时使用 |

### 换行符转换与 `newline=''` 陷阱
- 默认文本模式下，Python 会将不同系统的换行符（Windows `\r\n`、旧 Mac `\r`）透明转换为统一的 `\n`，写入时还原为系统默认。
- **陷阱**：在处理 CSV 文件或调用特定格式协议时，这种自动转换会导致 Windows 平台生成多余的空白行。**处理 CSV 文件必须显式指定 `newline=''`**。

---

# 大文件流式处理与内存防爆

## 1. 逐行惰性迭代（内存占用恒定）
绝不能对几十 MB 以上的文件调用 `f.read()` 或 `f.readlines()`（会将全部内容载入内存为巨大字符串或列表）：

```python
# 标准逐行迭代：文件对象本身即为生成器，内存占用几乎为 0
def process_large_log(filepath: str):
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            if "ERROR" in line:
                handle_error(line)
```

## 2. 定长分块流式读取 (Chunked Streaming)
对于超大二进制文件或单行极其漫长（如无换行符的单行压缩包/JSON）的文件，使用分块读取：

```python
def stream_large_binary(filepath: str, chunk_size: int = 64 * 1024):
    with open(filepath, "rb") as f:
        # 使用 iter(callable, sentinel) 惰性生成器
        for chunk in iter(lambda: f.read(chunk_size), b""):
            process_chunk(chunk)
```

---

# 超大文件内存映射 (mmap)

对于需要随机高速访问、切片或多进程共享读取的数百 MB 到 GB 级只读文件，使用 `mmap` 将文件直接映射到进程的虚拟内存空间，由操作系统按需执行缺页加载：

```python
import mmap

def search_in_mmap(filepath: str, pattern: bytes) -> int:
    with open(filepath, "rb") as f:
        # 0 表示映射整个文件，ACCESS_READ 开启只读保护
        with mmap.mmap(f.fileno(), length=0, access=mmap.ACCESS_READ) as mm:
            # 像普通 bytes 一样支持切片、find 与正则
            pos = mm.find(pattern)
            return pos
```

---

# 生产级原子写入与 Pathlib 规范

## 1. 原子写入防损坏模式 (Atomic Write)
- **风险**：直接以 `'w'` 模式写入文件时，文件会先被截断清空。如果此时进程被 Kill 或系统断电，原数据直接丢失且新数据残缺。
- **标准范式**：先写入同目录临时文件并刷盘（`flush` + `os.fsync`），然后使用 `os.replace` 原子替换：

```python
import os
import tempfile
from pathlib import Path

def atomic_write(filepath: str | Path, content: str, encoding: str = "utf-8"):
    target_path = Path(filepath).resolve()
    dir_name = target_path.parent

    # 必须在同一目录下创建临时文件，跨文件系统/挂载点无法执行原子 replace
    with tempfile.NamedTemporaryFile("w", dir=dir_name, delete=False, encoding=encoding) as tf:
        tf.write(content)
        tf.flush()
        os.fsync(tf.fileno()) # 强制刷入物理介质
        temp_name = tf.name

    # 原子重命名替换，绝不产生损坏的中间态
    os.replace(temp_name, target_path)
```

## 2. 现代路径工程 (pathlib.Path)
全面替代传统繁杂的 `os.path.join` / `os.path.dirname`：

```python
from pathlib import Path

base_dir = Path("/var/log")
app_log = base_dir / "app" / "current.log"  # 使用 "/" 操作符拼接路径

app_log.parent.mkdir(parents=True, exist_ok=True) # 自动递归建目录
if app_log.exists() and app_log.is_file():
    size_mb = app_log.stat().st_size / (1024 * 1024)
```

---

# 结构化表格流式处理 (CSV)

- **`newline=''` 必须项**：打开 CSV 文件必须显式传入 `newline=''`，避免 Windows 平台换行符转换产生多余空行。
- **BOM 编码防御**：若生成的 CSV 需兼容 Excel 客户端双击打开，使用 `encoding='utf-8-sig'`（带 BOM），防止中文乱码。
- **长数字文本化**：订单号、芯片 Pin 序号等长数字末尾添加 `\t`，防止被 Excel 自动转为科学计数法丢失精度。

```python
import csv

# 流式字典读取（解耦列顺序依赖）
def stream_csv_dict(filepath: str):
    with open(filepath, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield row.get("id"), row.get("name")

# 流式字典写入
def write_csv_dict(filepath: str, records: list[dict]):
    fieldnames = ["id", "name", "serial_no"]
    with open(filepath, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in records:
            r["serial_no"] = f"{r['serial_no']}\t" # 防科学计数法截断
            writer.writerow(r)
```
