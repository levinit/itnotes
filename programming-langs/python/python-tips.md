# 在列表、字典、集合中根据条件筛选数据





# python中执行shell程序

- os

  - os.system()

    ```shell
    os.systemc("pwd -P")
    ```

    只返回值命令执行的状态码

  - os.popen()

    ```shell
    c=os.popen("pwd -P")  #pwd -P命令  
    c.read()  #需要使用read()读取实例化对象
    c.close()  #close成功时不返回任何值；close()失败时返回系统的返回值
    ```

    只返回命令执行的结果。输出内容带有换行符。

- subprocess

  类似linux进行fork子进程。

  常用：

  - subprocess.run()

  - subprocess.Popen()

    ```shell
    p=subprocess.Popen(["id","-u"])
    p.wait()  #等待子进程终止
    p.communicate(input,timeout)  # 和子进程交互，发送和读取数据。
    p.send_signal(signal)  #发送信号
    p.kill()  #杀死子进程
    ```

    以下方法都是Popen的封装。

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

    

