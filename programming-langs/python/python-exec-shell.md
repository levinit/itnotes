# python中执行shell程序

## os的方法

## os.system()

```shell
os.system("pwd -P")
```

只返回值命令执行的状态码

## os.popen()

```shell
c=os.popen("pwd -P")  #pwd -P命令  
c.read()  #需要使用read()读取实例化对象
c.close()  #close成功时不返回任何值；close()失败时返回系统的返回值
```

只返回命令执行的结果。输出内容带有换行符。



# subprocess

## 基本使用

类似linux进行fork子进程。

subprocess启动一个新（子）进程，并连接到它们的输入/输出/错误管道，从而获取返回值。



Popen()是最基础的方法，subprocess其他方法都是Popen的封装。Popen控制功能更细致，聃使用较为繁琐，一般多使用其他subprocess方法。

```shell
p=subprocess.Popen(["id","-u"])
p.wait()  #等待子进程终止
p.communicate(input,timeout)  # 和子进程交互，发送和读取数据。
p.send_signal(signal)  #发送信号
p.kill()  #杀死子进程
```



- subprocess.run()

- subprocess.call()

  父进程等待子进程完成。
  运行结果将输出到标准输出，返回执行状态码。

  ```shell
  a=subprocess.call(["ls",'-h'])  #执行成功 a为0
  ```

- subprocess.check_call()

  检查返回状态码，如果其不为0，则举出错误subprocess.CalledProcessError，该对象包含有returncode属性，可用try…except…来检查。

- subprocess.check_output()

  ```shell
  subprocess.check_output("whoami")
  subprocess.check_output(['id','-u'])  #id -u命令
  ```




## 重要注意事项

### shell=True的安全风险

`subprocess.Popen()`即其他以`subprocess.Popen()`封装的方法，均有一个`shell=<Bool>`的参数，默认shell值为False，命令以IFS（空白分隔符）分隔各个部分需要以列表形式传入，如果shll值为True，则无需以列表形式传入，示例：

```shell
subprocess.Popen("id -u" ,shell=True)
```

但是这种做法可能是不安全的，如果要调用的外部执行命令获取自字符串，对命令内容不可控，则存在命令注入风险。使用列表形式则增加了确定性，参数可控更为安全。



### 函数调用的死锁风险

1. call、check_call和check_out，使用管道stdout=PIPE or stderr=PIPE 存在死锁风险

   该场景下应当使用 [`Popen.communicate()`](https://docs.python.org/zh-cn/3/library/subprocess.html#subprocess.Popen.communicate) 规避。

   subprocess 官方文档在上面几个函数中都标注了安全警告：

   > 当 `stdout=PIPE` 或者 `stderr=PIPE` 并且子进程产生了足以阻塞 OS 管道缓冲区接收更多数据的输出到管道时，将会发生死锁。当使用管道时用 [`Popen.communicate()`](https://docs.python.org/zh-cn/3/library/subprocess.html#subprocess.Popen.communicate) 来规避它。



2. popen和popen.wait() ，可能会导致死锁

   同上，官方文档里推荐使用 Popen.communicate()。

   这个方法会把输出放在内存，而不是管道里

   如果要获得程序返回值，可以在调用 Popen.communicate() 之后取 Popen.returncode 的值。

   

3. call、check_call、popen、check_output ，参数shell=True,命令参数不能为list，若为list则引发死锁

   参数shell=True时，命令参数为字符串形式
