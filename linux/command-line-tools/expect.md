> **Expect**是[Unix](https://zh.wikipedia.org/wiki/Unix)系统中用来进行自动化控制和测试的软件工具，由[Don Libes](https://zh.wikipedia.org/w/index.php?title=Don_Libes&action=edit&redlink=1)制作，作为[Tcl](https://zh.wikipedia.org/wiki/Tcl)脚本语言的一个扩展，应用在交互式[软件](https://zh.wikipedia.org/wiki/%E8%BD%AF%E4%BB%B6)中。

expect是由[tcl语言](https://link.jianshu.com?t=http://www.tldp.org/HOWTO/TclTk-HOWTO-3.html#ss3.1)演变而来，需要tcl的支持。

# 常用参数

- `-c` 指定要执行的命令
- `-f` 指定要执行的文件
- `-d` 开启debug模式 (调试并且观看expect的执行过程)
- `-i` 开启交互

# expect脚本

在脚本文件开始时使用shebang指定expect解释器，例如`#!/bin/expect`。

可在shebang 后面直接使用参数（如`-d`开启debug）

## 常用命令

在expect脚本中最关键的四个命令：

- `spawn`：启动新的进程

  spawn执行的命令结果会被expect捕捉到

- `expect`：从进程接收字符串（可以使用通配符如`*`）

- `send`：向进程发送字符串

  将需要的信息发送给spawn启动的那个进程（模拟用户的输入）

  一些特殊按键需要使用其相应的ANSI escapte code表示，例如：

  - `\r `回车

  - `\t` 制表符（tab）


  spawn、expect和send最基本的组合——单分支：

  ```tcl
  spawn <cmd>  #启动一个进程
  expect "some strings*"  #如果程序运行后出现了字符串中指定内容
  send "some words you want to input"  #模拟用户输入一些内容 
  ```

  多分支：

  ```tcl
  spawn <cmd>
  expect{  #匹配下列行中任意一个字符串都会发送相应的内容
      "strings1" {send "word1"}
      "strings2" {send "word2"}
  }
  ```

- `interact`：允许用户交互模式（让用户输入）

- `set timeout <n>` 设置超时时间为n秒

  如果一个指令超时后则会直接执行下一条

  - timeout是内置的变量 **默认值为10** 
  - 如果n取值为`-1` 表示不超时

- `send_user`  发送内容给用户

- `set <variable> <value>`  设置变量

- `exp_continue`  继续进行下一项匹配

- `expect eof` 结束对spawn程序输出信息的捕获

  **如果程序不以interact结尾，应该在最后写上`expect eof`结束本次expect。**

- 命令行参数

  - `$argv0`  脚本本身
  - `$argv`命令行参数
  - `[lrange $argv 0 0]` 或`[lindex $argv 0]`  第1个参数`
  - `[lrange $argv m n]`  第m个到第n个参数

# 在shell中使用expect

这里的shell指的是bash shell。在bash中的expect语句均放置在字符串中，可以方便地在该expect内容的字符串中使用bash的变量。

bash shell中使用expect的几种方式：

- 将expect脚本内容作为字符串，使用EOF将expect内容重定向给expect程序，示例：

  ```shell
  #!/bin/sh
  #上传ssh密钥
  /usr/bin/expect  << EOF
  set timeout 10
  spawn ssh-copy-id root@host1
  expect{
      "*yes/no*" { send "yes" \r }
      "password*" { send "root"\r }
      }
  EOF
  ```

- `expect -c <cmds>`  `-c`参数指定expect要执行的命令 

  ```shell
  user=root
  hosts=192.168.0.1
  port=22
  password=root
  
  #ssh登录
  expect -c "
      spawn ssh $user@$host -p $port
      expect {
        "yes/no" { send "yes"\r }
        "*password*" { send $password\r }
      }
      interact  #进入交互式
    "
    
  #上传ssh密钥
  expect -c "
      spawn ssh-copy-id $user@$host -p $port
      expect {
        "yes/no" { send "yes"\r }
        "*password*" { send $password\r }
      }
     expect eof
    "
  ```

- `expect -f <cmdfile>`   使用expect执行指定（脚本）文件
