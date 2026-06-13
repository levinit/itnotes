# Linux 巨大单层目录排查与清理笔记

## 问题发现

进入或查看某个目录时，`ls` 直接卡住，长时间没有输出。

典型现象：

```bash
cd /path/to/testcases
\ls -f -1
du -sh .
find . -maxdepth 1
```

这些命令都非常慢，甚至看不到结果。

`stat /path/to/testcases` 命令检查目录元数据发现inode Size大小超过300M，怀疑该目录第一层下就有海量文件，造成该目录元数据大小膨胀。

```text
Size:   374722560
Blocks: 868992
IO Block: 4096
类型:   目录
Links:  2
```



## 原因排查

为了验证是否是第一层目录下有大量文件，编写了一个python程序检查。

使用 Python 的 `os.scandir()` 进行轻量枚举，并设置最大时间。

示例：

```python
import os
import time

path = "/path/to/testcases"
deadline = time.time() + 10

n = 0
files = 0
dirs = 0
others = 0

with os.scandir(path) as it:
    for e in it:
        n += 1
		if < 20:
            print(e.name)  #获取下前面20文件名字
        try:
            if e.is_dir(follow_symlinks=False):
                dirs += 1
            elif e.is_file(follow_symlinks=False):
                files += 1
            else:
                others += 1
        except OSError:
            others += 1

        if time.time() >= deadline:
            break

print("scanned:", n)
print("files:", files)
print("dirs:", dirs)
print("others:", others)
```

本次确认结果中，普通文件数量约为：

```text
files: 5763546
```

也就是该目录下一层存在约 **576 万个普通文件**。

这解释了为什么ls等命令很久出不了结果，因为

- `ls` 慢，是因为要读取并排序数百万个目录项；
- `ls -l` 更慢，是因为还要对每个文件读取元数据；
- `du` 慢，是因为要统计每个文件的磁盘占用；
- `find` 慢，是因为要遍历完整目录；
- 删除慢，是因为最终必须逐个 `unlink()` 每个文件。

---

## 清理处理

确认问题后，处理思路分成两步：

- 先把问题目录移动到安全位置，避免继续影响业务；
- 再对移动后的目录执行低成本、可观察的清理。

如果原目录仍被业务使用，不应直接在原路径中删除。更稳妥的方式是在父目录中先改名，再创建新的空目录替代：

```bash
cd /path/to

mv testcases testcases.old
mkdir testcases

chown --reference=testcases.old testcases
chmod --reference=testcases.old testcases
```

`mv` 目录改名通常只是修改父目录中的目录项，不需要遍历内部几百万个文件，因此通常很快。



对于这种已经确认基本都是普通文件的巨大单层目录，可以用 Python 的 `os.scandir()` 逐项遍历，再对每个 `DirEntry` 执行：

```python
os.unlink(e.path)
```

`os.unlink()` 对应 Linux/Unix 的 `unlink` 系统调用，含义是删除该文件名对应的目录项。对普通文件来说，它相当于命令行里的：

```bash
rm -- "$file"
```

最小清理脚本如下：

```python
import os
import time

path = "/safe/place/testcases.old"

n = 0
start = time.time()

with os.scandir(path) as it:
    for e in it:
        try:
            os.unlink(e.path)
            n += 1
        except IsADirectoryError:
            print("skip dir:", e.name, flush=True)
        except FileNotFoundError:
            pass
        except Exception as err:
            print("error:", e.name, err, flush=True)

        if n % 100000 == 0:
            elapsed = time.time() - start
            rate = n / elapsed if elapsed > 0 else 0
            print(f"deleted={n}, rate={rate:.1f}/s", flush=True)

print("done deleted:", n)

try:
    os.rmdir(path)
    print("removed dir:", path)
except Exception as err:
    print("dir not removed:", err)
```

后台低优先级执行：

```bash
nohup ionice -c3 nice -n 19 python3 delete_testcases.py > /tmp/delete-testcases.log 2>&1 &
```

查看进度：

```bash
tail -f /tmp/delete-testcases.log
```

这个脚本的关键点是：

```python
os.unlink(e.path)
```

不要使用：

```python
os.remove(e.name)
```

除非当前工作目录已经切换到目标目录。使用 `e.path` 更稳，因为它包含完整的目录路径。

也不建议使用：

```bash
rm -rf /path/to/testcases/*
```

原因是：

- shell 会先展开 `*`；
- 数百万个文件可能触发 `Argument list too long`；
- shell 展开本身就可能长时间卡住；
- 还可能遗漏隐藏文件。

也不建议使用：

```bash
ls | xargs rm
```

因为：

- `ls` 本身已经是瓶颈；
- 普通管道处理特殊文件名不安全；
- 仍然绕不开完整目录遍历。

