[TOC]

下文中，客户端即是用户使用ssh命令或工具的主机，ssh服务器/目标主机/远程主机即运行sshd服务的主机。



# 配置文件

- 服务端：一般是`/etc/ssh/sshd_config`

  访问ssh服务器可使用`-f`选项可指定配置文件

- 客户端：一般是`/etc/ssh/ssh_config`（全局）或`$HOME/.ssh/config`（用户）

  启动sshd服务可使用`-F`选项可指定配置文件



# ssh登录

```bash
ssh [-p port] user@host
ssh -p 2333 root@host
ssh -l user root@host
ssh host
```
- port：要登录的远程主机的端口，如果省略则默认为22（以下示例中如无指定均表示使用22）。

- user：要登录的主机上的用户名，也可使用`-l`指定（此时无需`@`连接用户名和服务器地址），如果省略用户名（和`@`），将会以当前用户名尝试登录ssh服务器，例如root用户执行`ssh host`同于`ssh root@host`。
- host：要登录的主机地址。



常用参数：

- `-p`：指定要连接的远程主机的端口
- `-4`或`6`：指定使用的IP协议版本
- `-l`：指定用户
- `-f`：将指令放入后台执行
- `-n`：将stdin重定向到`/dev/null`（实际上，阻止从stdin读取内容），将程序放到后台，类似`-f`的作用。
- `-C`：压缩所有数据
- `-N`：不执行远程命令（不登录到服务器执行命令）
- `-D`：动态端口转发
- `-R`：远程端口转发
- `-L`：本地端口转发
- `-g`：如果在[多路复用](#端口复用)连接上使用[端口转发](#端口转发)，必须在主进程上指定此选项，以允许远程主机连接到建立的转发的端口。
- `-t`：分配伪终端（可以用来执行任意的远程计算机上**基于屏幕的程序**）
- `-T`：不分配TTY
- `-A`：开启身份认证代理转发
- `-q`：安静模式（不输出错误/警告）
- `-v`：显示详细信息（可用于排错）



## 密钥认证

使用非对称加密的密钥，可免密码登录。

1. 生成密钥——生成非对称加密的密钥对

   ```shell
   ssh-keygen   #根据提示选择或填写相关信息
   #相等于执行ssh-keygen后一直回车(均默认)
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   
   ssh-keygen -C "some text"
   ```
   - -t：加密类型，有dsa、ecdsa 、ed25519、rsa等

     注意，dsa密钥已经证实为不安全，rsa密钥位数过低也较为不安全，推荐至少4096位。

   - -b：密钥长度

   - -f：密钥放置位置

   - -N：为密钥设置密码

   - -C：添加注释，默认为`用户名@主机名`，如`root@localhost`

2. 上传密钥——将密钥对中的公钥上传到ssh服务器

   ```shell
   ssh-copy-id user@host
   #有多个密钥时可使用`SSH_KEY_PATH`变量指定私钥路径，或者使用参数-i指定一个私钥
   ssh-copy-id -i ~/.ssh/test user@host


公钥内容将添加到登录用户在服务器的`~/.ssh/authorized_keys`文件中。



### ssh-agent密钥代理

ssh-agent用以管理多个私钥，它将用户加入的私钥存储在内存中，以不同的指纹做标识，使用ssh时将自动通过agent调用加入的私钥进行验证。

```shell
#启动ssh-agent会为当前用户启用一个新的子shell，并加载默认密钥
ssh-agent  [shell]             #启动agent 可指定shell，不指定则使用当前shell

#也可以使用以下方式，在后台运行agent（退出shell时agent进程不会退出）
eval $(ssh-agent)

#管理agent代理的私钥（每个私钥有不同的指纹信息）
ssh-add <path-to-private-key-file>    #添加一个私钥身份
ssh-add -d <path-to-private-key-file> #删除一个私钥身份信息
ssh-add -l                            #列出所有加载的身份指纹
ssh-add -D                            #清空代理的身份指纹
ssh-add -s                            #生成Bourne shell命令到标准输出
ssh-agent -k                          #关闭当前agent
```



ssh-agent启动时会设置`SSH_AUTH_SOCK` 和 `SSH_AGENT_PID` 环境变量，将这两个变量在用户的其他shell中export后也能被其使用。



可以将`eval $(ssh-agent)`添加到shell的配置文件（如bash的`~/.bashrc`），实现登录时自动加载agent：

```shell
if [[ -z $(ps -eo pid,user,command | grep -w $USER | grep "ssh-agent" | grep -v grep) ]]; then
    eval $(ssh-agent -s)
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >~/.cache/.ssh-agent.env
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >~/.cache/.ssh-agent.env
    ssh-add
else
    [[ -f ~/.ssh-agent.env ]] && source ~/.cache/.ssh-agent.env
fi
```

`ssh-agent -k`添加到shell的logout文件（例如bash的`~/.bash_logout`，zsh的`~/.zlogout`），实现退出shell时自动中止agent进程。



ssh-agent代理转发需要开启[转发认证](#转发认证)



## 别名登录

为需要经常登录的服务器设置别名，简化登录步骤。

在`~/.ssh/config`（如无该文件则创建之）中配置：

```
Host host1 #host1为所命名的别名 Host或host大小写均可
   hostname xxx.xxx.xxx.xxx #登录地址
   user user1  #用户名
   #port 1998  #如果修改过默认端口则指定之
   #IdentityFile  ~/path/to/id_rsa.pub #如果要指定公钥
   #IdentitiesOnly yes #只使用指定的公钥进行认证
```

登录时直接使用`ssh host1`即可。



## 跳板登录

在某些网络限制的情况下，需要通过跳板机（可能不止一个跳板机）登录到目标服务器：

**客户端** ---> **跳板机** ---> **目标主机**

通常地，先从客户端登录到跳板主机，再从跳板主机登录到目标主机：

```shell
ssh user@jump-host   #从客户端登录到跳板机
ssh user@target-host #从跳板机登录到最终目标主机
```



使用以下方式可以直接从客户端主机登录到跳板机：

### 伪终端

使用`-t`分配伪终端，相当于合并多次ssh命令：

```shell
ssh -t user@jump-host ssh -t user@target-host
```



### ProxyJump

其原理是在跳板机上建立TCP转发，让客户端ssh数据直接转发到目标服务器上等ssh端口。

该方式会自动进行密钥认证的转发。



可使用以下任意方式：

- `-J`选项

- `-o`选项并指定`ProxyJump`参数配置，可配置更多的选项参数。

  *`-J`是该方式的**快捷方法**(shortcut)*



使用`-J`选项：

```shell
#注意，跳板机的端口需要直接在地址后面添加 以冒号分隔
ssh -J user@jum[:port] user@target -p <port>

#如有多个跳板机使用逗号隔开 #客户端->jump1服务器->jump2服务器->target服务器
ssh -J user@jump1,user@jump2:2333 user@target -p 22

#通过server1跳跃到server2 使用X转发打开server上的firefox
ssh -J user@server1 user@server2 -X firefox
```



使用`ProxyJump`：

```shell
#user@target 目标主机地址和在目标主机上的用户
#user@jump   跳板机和在跳板机上的用户
ssh user@target -o ProxyCommand='ssh user@jump -W %h:%p'
```



可在`~/.ssh/config`中固化配置，使用更简便的[别名登录](#别名登录)，示例：

```shell
Host jump               #跳板机配置
    HostName 10.10.1.2  #跳板机地址
  	Port 22             #跳板机ssh端口 22可省略该行
    User user_at_proxy  #跳板机上的用户

Host target             #目标主机配置
    HostName 10.10.10.1 #目标主机地址（即直接从跳板机上ssh到目标主机的地址）
    Port 2222           #跳板机ssh端口 22可省略该行
    User user_at_target #目标主机上的用户
    ForwardAgent yes    #开启代理转发 可选
    #代理命令  -q安静模式（忽略各种提示和警告信息）
    #%h和%p变量表示改行中jump对应的配置中的hostname和port
    ProxyCommand ssh jump -q -W %h:%p
```

然后即可使用`ssh target`进行登录。



使用proxyComand模式，可以实现scp向目标主机传输文件。以上面的配置为例：

```shell
scp local.file target:~/remote.file #将本地文件scp到targe主机上
```



## 远程命令

直接在登录命令后添加命令，可使该命令在远程主机上执行，示例：

```shell
ssh [-p port] user@host <command>
ssh root@192.168.1.1 whoami

#将本地.vimrc内容传入远程主机的.vimrc中
ssh root@192.168.1.1 'cat > .vimrc' < .vimrc

#多条命令使用引号包裹起来
ssh root@192.168.1.1 'echo `whoami` > name && mv -f name myname'
```

如果执行某个命令遇到`command not found`，而实际上远程主机上可以正常执行该命令，尝试使用该命令在远程主机上的绝对路径，具体参看[问题解决](#问题解决)中“远程命令cmmand not found”。

远程命令执行完毕后，即会退出ssh连接。

使用`-t`参数分配伪终端，且远程命令的最后一条命令为`bash`（或其他shell），则可以在远程主机执行命令后仍停留在远程主机的shell中。

示例登录后自动进入某个目录：

```shell
ssh -t <host> 'cd /tmp;bash'
```

如果是交互式操作，例如使用vim操作远程主机的文件，配合scp使用，示例：

```shell
vim scp://user@host[:port]//path/to/file
```



# 转发认证

为了方便，一般我们会配置，客户端到跳板机的密钥认证，以及跳板机到目标主机的密钥认证（甚至使用同一套密钥）：

> 客户端---ssh-keys--->跳板机
>
> 跳板机---ssh-keys--->目标主机

但在某些对安全性有较高要求的情况下，我们**不希望跳板机可以通过密钥认证登录到目标主机**（可能没有配置跳板机到目标主机的密钥认证，甚至为了安全关闭了目标主机的密码登录），而是**将客户端的公钥直接存放到目标服务器**。

> 客户端：私钥<--->公钥：目标服务器

为了实现使用客户端使用密钥登录的目标服务，可以使用转发密钥认证的方式实现。



实现认证转发的方法：

1. 添加本地密钥到agent

   ```shell
   eval $(ssh-agent -s)
   ssh-add #默认添加~/.ssh的私钥钥
   ```

   参看[ssh-agent](#ssh-agent密钥代理)

2. 确保agent转发开启

   - 服务端一般默认开启

     `/etc/sshd/sshd_config`确保`ForwardAgent`不为`no`（或者显式配置为`yes`确保总是打开）

   - 客户端一般默认为关闭，可以配置打开或者不配置但是在后续ssh命令中增加`-A`选项

     可以在`/etc/ssh/sshd_config`（全局）或者`~/.ssh/config`（个人）中配置`AllowAgentForwarding yes`

3. 登录

   如未配置`ForwardAgent yes`，需要使用`-A`参数。

   - `-J`（ProxyJump）登录

     ```shell
     ssh -A -J user@jump-host user@target-host
     ```

   - 逐步跳跃登录的方式：

     ```shell
     #1. 从客户端登录到跳板机 并将密钥交给agent 以供跳板机使用
     ssh -A user@jump-host
     #2. 从跳板机登录到目标主机将使用来自客户端的密钥
     ssh user@target-host
     ```

   - 分配伪终端`-t`登录的方式：

     ```shell
     ssh -t -A user@jump-host ssh -t user@target-host
     ```

     

# 端口复用

SSH 守护进程通常监听 22 端口，但是许多公共热点会屏蔽非常规 HTTP/S 端口（分别是 80 和 443 端口）的流量，这样就屏蔽了 SSH 连接。最快的解决方法是让 `sshd` 额外监听白名单上的端口：

```
/etc/ssh/sshd_config
Port 22
Port 443
```

但是443端口很有可能已经被 HTTPS 服务占用，在这种情况下可以使用端口复用工具，比如 [sslh](https://www.archlinux.org/packages/?name=sslh)，它可以监听在一个被复用的端口上并转发相应的数据包给对应的服务。



# 保持连接

## 持续连接

在已经连接到某个服务器的情况下，再连接该服务器时将直接从先前的连接缓存中读取信息，加快连接速度，尤其是于网络不太稳定的场景下。

在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

```shell
ControlMaster auto
ControlPath /tmp/%r@%h:%p #连接信息存储路径
ControlPersist yes #总是在后台连接保持
#ControlPersist 1h #连接保持指定时间，超时则退出
```



## 存活检测

默认情况下，连接的会话在空闲一段时间后会自动登出。

为了保持会话，在长时间没有数据传输时客户端可以向服务器发送一个激活信号；与之对应，服务器也可以在一段时间没有收到客户端消息时定期向客户端发送一个激活信号。

另外可开启`TCPKeepAlive`以发送TCP连接消息，其可检测到连接异常，以避免僵尸进程产生。

可根据情况在服务端或客户端设置：

- 服务端`/etc/ssh/sshd_config`中添加

  ```shell
  TCPKeepAlive yes  #可选 保持tcp连接
  ClientAliveInterval 60 #如果设置为0 则表示不发送激活信息。
  ClientAliveCountMax 5
  ```

  服务端每60s向连接的客户端传送信息，客户端连续5次无响应则自动关闭该连接。

- 客户端`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加

  ```shell
  TCPKeepAlive yes  #可选 保持tcp连接
  ServerAliveInterval 60
  ServerAliveCountMax 5
  ```

  每60s向连接的服务端端传送信息，服务端连续5次无响应则自动关闭该连接。

也可以在ssh命令中使用`-o`参数指定向服务端发送激活信息间隔时间：

```shell
ssh -o ServerAliveInterval=60 user@host
```



## autossh工具

autossh可以在监测ssh连接状态，当ssh断开后会自动重新发起连接。

在ssh命令前使用`autossh -M <port>`即可，其指定一个端口，用以持续监听当前ssh连接状态。

```shell
autossh -M 2333 ssh -fCNR 8080:localhost:80 user@remote-host
```

一个autossh的systemd units文件示例，可放置于`/etc/systemd/system/autossh.service`或`$HOME/.config/systemd/user/`下。

```shell
[Unit]
Description=Keeps a tunnel to 'example.com' open
After=network.target

[Service]
User=autossh
ExecStart=/usr/bin/autossh -M 5678 -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -NR 1234:localhost:22 -i /home/autossh/.ssh/id_rsa someone@remote-host
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```



# 端口转发

通过ssh将一个端口的请求转发到另一个端口上。ssh端口转发另一个名字是“ssh隧道”：

> 隧道是一种把一种网络协议封装进另外一种网络协议进行传输的技术。

ssh端口转发相关：

- 使用1024以下的端口需要root权限。

- 端口转发命令配合`-g`参数，允许远程主机(remote hosts)连接到本地转发的端口(local forward port)，如果不使用该参数则只允许本地主机建立连接。

  也可在代理主机的配置文件`/etc/ssh/sshd_config`中设置：`GatewayPorts yes`，以允许远程主机向本地转发端口建立连接。

- 禁止端口转发：在配置文件`/etc/ssh/sshd_config`中设置`AllowTcpForwarding no`。

- 可配合[保持连接](#保持连接)的autossh，创建systemd units持续提供转发服务。

- 动态转发与本地/远程转发

  **动态转发是正向代理，本地/远程转发是反向代理。**

  **”正向(代理)“ 代理客户端**：正向代理代表客户端向服务器发送请求，隐匿客户端。

  **”反向(代理)“ 代理服务端**：反向代理代表服务器为客户端提供服务，隐匿服务端。



以下转发公用的ssh选项：

- `-f`  后台运行ssh命令

  在转发场景下适用，不会登录到目标ssh服务器，可以在启动端口转发后继续在本地终端使用其他命令

  

- `-N`  不执行远程命令

  在转发场景下适用，因为转发只需要建立连接但不打开一个 shell 或执行任何命令

  

- `-g`  允许其他主机转发端口

  适用于本地端口转发(`-L`)和远程端口转发(`-R`)

  默认情况下， `-L` 或 `-R` 选项建立的转发的端口只允许本机访问，即使端口监听在 `0.0.0.0`（即所有网络接口）；如果使用了 `-g` 选项，则允许其他主机访问转发端口。

  注意，`-g` 选项可能会带来安全风险，因为它允许任何远程主机连接到转发的端口。



## X转发

转发远程主机上应用程序的X11图形界面到本机。X转发的要求：

- 服务端

  - xorg-server，xorg-xauth，启动X服务。

  - 确保`sshd_config`关于X的配置如下：

    ```shell
    X11Forwarding yes
    X11DisplayOffset 10
    X11UseLocalhost no
    ```

- 客户端

  需要有X环境。

  原理是服务器作为 X Client 发送渲染指令到本地的 X Server，本地 X Server 调用本地的 OpenGL 库渲染图像。

  提示：windows需要安装x实现如Xming等，macos可安装xquartz。

  ```shell
  #打开远程主机的firefox （或者登录到远程主机上再执行命令）
  ssh -fX user@host <app-name>  #或配置ForwardX11 yes 则可不写出-X
  #或
  ssh -fY user@host <app-name>  #或者ForwardX11Trusted yes 则可不写出Y
  ```

  - `-X`  远程机器将被视为不受信任的客户端，本地客户端向远程机器发送命令并接收图形输出，如果某些命令违反了某些安全设置，将收到错误提示。 可在客户端ssh配置中添加。
  - `-Y`  远程机器将被视为受信任的客户端。 （其他图形(X11)客户端可以从远程机器中嗅探数据（制作屏幕截图、做键盘记录和其他讨厌的东西，甚至可以更改这些数据。）

  提示 no Display xxx：

  ```shell
  export DISPLAY=localhost:0
  ```

  启用OpenGL加速：

  ```shell
  export LIBGL_ALWAYS_INDIRECT=1
  ```

  

  ### X转发+VirutalGL

  ssh转发使用本地GPU渲染，仅有限支持 OpenGL，当运行图形功能较为复杂的软件时效率较低。 

  Virual GL 则能作为一个代理使用服务器的 OpenGL 在服务器端进行渲染，然后将渲染结果转发到本地 X Server。

  安装[Virtual GL](https://www.virtualgl.org) 后运行 vglserver_config 配置 Virtual GL 代理，配合X转发使用：

  ```shell
  ssh -Y user@host vglrun <app-name>
  ```

  

## 动态端口转发（socks代理）

`-D`选项：动态转发本机指定端口的数据到远程主机，一般组合`-fCND`使用

在本机分配一个 socket 侦听端口，一旦这个端口上有了连接，该连接就经过ssh隧道转发到远程主机，通过远程主机与目标连接。

```shell
客户端C----->代理主机P----->多个目标主机的多个端口
```

应用场景举例：代理主机科学上网。

```shell
ssh -fCND  [bind_address:]<local-port> <proxy-user>@<proxy-host> [-p proxy-port]
```

- bind_address：指定绑定的地址，如该值为空即绑定到`127.0.0.1`，可使用`0.0.0.0`或`*`绑定到任意主机（下同，不在赘述）。

- local-port：绑定的端口。


示例，本机通过远程主机hostP代理访问不存在的网站`google.com`：

```shell
ssh -fCND *:2333 user@hostP
```

*参看[参数说明](#常用参数)了解各个参数意思。*

在本机系统设置中全局（或者浏览器应用设置中）添加socks代理，地址：`127.0.0.1`，端口`2333`，本机即可通过服务器hostP代理访问；打开浏览器访问`google.com`将通过hostP代理`google.com`。

提示：客户端配置socks5代理后使用（或设置全局的代理，可配合PAC使用）。



## 本地端口转发

`-L`选项：本地端口转发（Local Port Forwarding）在本地机器上打开一个端口，并将此端口的流量转发到通过 SSH 连接的远程机器上的指定端口。一般组合`-fCNL`使用：

```shell
ssh -fCNL [bind_address:]<local-port>:<target-host>:<target-port> [user>@]<local-host>
```



将本地主机的指定端口和远端主机的目标端口绑定，本地主机上分配了一个 socket 侦听端口， 一旦本地主机端口上有了连接，该连接就经过ssh隧道转发到程主机的端口上。

```shell
客户端C---->本地主机端口----->远程主机端口（提供服务者）
```



*本章节涉及转发的本地主机/远端主机只是一种区分式表述，本地主机是执行转发命令的主机。不过实际上将本机的一个端口转发到本机同一IP多其他端口也是可以的。例如在主机a上执行：*

```shell
ssh -fCNL 127.0.0.8080:127.0.0.1:80 user@localhost
```



应用场景举例：网络安全管控。有主机A、B，主机B运行的web服务监听于80端口，处于某些考虑，禁止用户直接访问B的80端口，在A执行了本地转发，将A的80端口绑定到B的80端口，这样用户访问A的80端口即可访问B的80的web服务。

示例，转发本机8080端口到`www.kernel.org`：

```shell
#转发该主机的8080端口到kernel.org的80端口   访问该主机的8080端口的流量即被转向www.kernel.org
ssh -fCNL *:8080:www.kernel.org:80 user@localhost
```

假如本地主机的IP是`192.168.0.1`，访问`192.168.0.1:8080`即访问`www.kernel.org`。



## 远程端口转发（反向隧道连接）

`-R`选项：远程端口转发（Remote Port Forwarding）在远程机器上打开一个端口，并将此端口的流量转发到本地机器的指定端口。一般组合`-fCNR`使用：

```shell
ssh -fCNR [bind_address:remote-port:<local-host>:<local-port> [<remote-user>@]<remote-host>
```



将远程主机的指定端口和本地主机的端口绑定，本地主机主动向远程主机发起连接，建立反向隧道。远程主机上分配了一个 socket 侦听端口，一旦这个端口上有了连接，该连接就经过ssh隧道转发到本地主机的这个目标端口。

```shell
客户端----->远程主机端口----->本地主机端口（提供服务者）
```



应用场景举例：内网穿透。在内网服务器与公网服务只见建立反向隧道，转发公网服务器的2222端口到内网服务器的22端口，用户访问公网服务器的2222端口即访问内网服务器的22端口。

示例，转发远程主机的9500端口到本地主机的5900：

```shell
ssh -gfCNR :2222:localhost:22 user@remote  #注意-g允许其他主机访问转发端口
```

假如位于NAT后的本地主机运行了xvnc（监听于5900端口），远程主机remote为公网主机，经过以上转发后，使用vnc客户端访问`remote:9500`即可连接上本地主机的vnc服务。



# 文件传输

## scp远程复制

scp是基于ssh的远程复制，使用**类似cp命令**。基本形式：

```shell
scp </path/to/local-file> user@host:</path/to/file>  #本地到远程
scp user@host:</path/to/file> </path/to/local-file>  #远程到本地
```

注意：scp遇到软连接时，**会复制软连接的源文件**！可以打包要复制的文件，待scp复制到目标主机后再解包，或者换用其他工具如rsync。

scp选项不能在命令最后指定，例如`scp test hostA:~/ -r`中将`-r`置于后方，其将不生效。

常用选项：

- `-P`  指定远程主机的端口号
- `-C`  使用压缩
- `-r`  递归方式复制（即复制文件夹下所有内容）
- `-p`  保留文件的权限、修改时间、最后访问时间
- `-q`  静默模式（不显示复制进度）
- `-F`  指定配置文件

示例——复制本地ssh公钥到远程主机：

```shell
#复制本地公钥到远程主机 并将其命名为authorized_keys
scp ~/.ssh/id_rsa.pub root@ip:/root/.ssh/authorized_keys
#指定端口需要紧跟在scp之后
scp -P 999 ~/.ssh/id_rsa.pub root@ip:/root.ssh/authorized_keys
```



## sftp传输协议

使用sftp协议可以同ssh服务器进行文件传输，访问地址类似：

```shell
sftp://192.168.1.100:22/home/<user>/path/to/file
```



## sshfs文件系统

> SSHFS 是一个通过 SSH 挂载基于 FUSE 的文件系统的客户端程序。

需要安装有`sshfs`。

```shell
#sshfs [user@]host:[dir] <mountpoint> [options] #挂载
sshfs ueser1@host1:/share /share -C -p 2333 -o allow_other

#fusermount -u <mount-point>  #卸载
fusermount -u /share
```

常用选项有：

- `-C` 启用压缩

- `-p` 指定端口

- `-o allow_other` 允许非root用户读写


`/etc/fastab`自动挂载示例：

```shell
user@host:/remote/folder /mount/point  fuse.sshfs noauto,x-systemd.automount,_netdev,users,idmap=user,IdentityFile=/home/user/.ssh/id_rsa,allow_other,reconnect 0 0
```



# 安全策略

- 登录记录查看

  - 登录历史
    - 用户最近登录情况：`lastlog`
    - 登录成功的记录：`last`
    - 登录失败的记录：`lastb`
  - 当前登录用户
    - 当前已登录用户列表（以及登录的用户正在执行什么操作）：`w`
    - 当前已登录的用户信息：`who`

- 防御工具

  - [fail2ban](https://github.com/fail2ban/fail2ban)
  - [sshguard](https://www.sshguard.net/)

  

- ssh版本

  如果服务端openssh版本过低，应该更新openssh，尤其是某些版本已经曝出过重大漏洞的情况。



- 防火墙策略



- 加密算法

  主要针对较老的系统。

  检查服务端sshd使用的加密算法，应该去掉已经被证实的弱加密算法，例如`arcfour`和`des`系列算法。

  新版本openssh一般会不采用已经曝光的弱加密算法。

  可以用nmap扫描目标ssh服务器，获取其sshd使用的加密算法（encryption_algorithms）

  ```shell
  nmap --scrip "ssh2*" <server>
  ```

  可以在`sshd_config`中配置`Ciphers`指定使用高强度加密算法，例如：

  ```shell
  Ciphers aes256-ctr chacha20-poly1305@openssh.com aes256-gcm@openssh.com
  ```

  修改后需要重启sshd服务。

  

- 更改默认的22端口

  减少被工具批量扫描的几率。修改服务器的`/etc/ssh/sshd_config`文件中的`Port` 值为其他可用端口。

  如果要监听多端口，则添加多行`Port`，如果要指定监听的地址，添加`ListenAddress`行：

  ```shell
  #示例1
  Port 1234
  Port 520
  ListenAddress 192.168.0.1
  ListenAddress 0.0.0.0
  
  #示例2
  ListenAddress 0.0.0.0:10022
  ListenAddress 10.1.1.1:22
  ```




## shell和sftp限制

- 禁止某些用户使用shell（以禁止其登录）

  某些用户可能只用于自动启动某个守护进程，无需登录，可以修改其shell为nologin，修改方法：

  - `chsh -s /sbin/nologin username`  username为用户的名字
  - 编辑`/etc/passwd`文件，找到该用户所在行，将`/bin/bash`字样改为`/sbin/nologin`。

- 如果不希望启用sftp，注释`/etc/ssh/sshd_config`该行并重启sshd服务

  ```shell
  #Subsystem sftp /usr/lib/openssh/sftp-server
  ```

- 启用sftp但是禁用ssh，编辑`/etc/ssh/sshd_config`：

  ```shell
  #Subsystem sftp /usr/lib/openssh/sftp-server
  #该行(上面这行)注释掉
  Subsystem sftp internal-sftp 
  ```

  

## 针对客户端IP限制

### `sshd`配置Match

修改服务器的`/etc/ssh/sshd_config`文件，保存后需要重启`sshd`。

```shell
# 默认拒绝所有人登录
DenyUsers ALL

# 允许特定 IP 段用户登录
Match Address 192.168.10.0/24
    AllowGroups hpcusers
    AllowUsers  user1 user2
```



### TCP Wrappers

TCP Wrappers 机制适用于链接到 `libwrap` 的服务，新版本可能不再支持，可使用防火墙配置进行代替。
检查 `sshd` 是否支持：

```shell
ldd /usr/sbin/sshd | grep libwrap #输出类似libwrap.so.0 => /lib64/libwrap.so.0表示支持
```



IP白名单配置文件`/etc/hosts.allow`和黑名单配置文件`/etc/hosts.deny`：

- 当`hosts.allow`（允许登录列表） 存在时，优先以其设定为准；

- 在`hosts.allow`（禁止登录列表） 没有规定到的项，会在`hosts.deny`中继续限制（如果有）；
- `hosts.allow`优先级高于`hosts.deny`，`hosts.deny`在 `hosts.allow` 没命中的情况下才生效！



黑名单`/etc/hosts.deny`中添加禁止列表，示例：

```shell
#程序名字:来源地址[:spawn操作:twist操作]
sshd:ALL  #禁止所有
#sshd:192.168.0.1 10.0.0.0/24

#可以添加警告信息发送给其他用户已经登陆的客户端
sshd:ALL: spawn (echo -e "security notice from host $(/bin/hostname)\n") | /bin/mail -s "%d-%h security" root & \
  : twist (/bin/echo "WARNING connection not allowed." )
```

spawn和twist是可选后续操作，例如当有非法来源请求时，向请求者发送警告，并向管理员发送通知邮件。

示例中spawn部分是向root用户发送邮件提示有来自某个主机发出的告警，twist部分的警告信息将呈现给发起请求的客户端。



## 针对用户限制

### 用户认证策略

修改服务器的`/etc/ssh/sshd_config`文件，保存后需要重启`sshd`。

- root用户登录限制

  ```shell
  PermitRootLogin  no
  ```

  值可以为：

  - `no`或`yes`  禁止或允许root用户登录

  - `prohibit-password`或者`without-password`  不允许使用密码认证

  - `forced-commands-only`  只能使用密钥登录 且 仅允许使用授权的命令




- 用户认证策略

  ```shell
  PasswordAuthentication no #默认yes  是否允许使用密码认证
  
  #指定用户或用户组只能使用密码登录
  #for User
  Match User user1,user2
      PasswordAuthentication no
  
  #for Group
  Match Group group1
      PasswordAuthentication no
  
  #exclude spefied user
  Match User !root
      PasswordAuthentication n
  ```



### `sshd`配置用户白名单和黑名单

限制编辑`/etc/ssh/sshd_config`文件，保存后需要重启`sshd`。

```shell
#白名单示例
AllowUsers user1 user2  #允许的用户
AllowGroups grp1 grp2   #允许的用户组

#黑名单示例
DenyUsers user1 user2  #禁止的用户  所有用户使用 ALL
DenyGroups grp1 grp2   #禁止的用户组 所有用户组使用 ALL
```

同时设置 `AllowUsers` 与 `AllowGroups`，用户必须匹配 `AllowUsers` 中的某个用户名，**且**属于 `AllowGroups` 中的某个组，才能登录。

设置 `DenyUsers` 与 `DenyGroups` 时，用户**只要**匹配 `DenyUsers` 中的某个用户名，**或**属于任意 `DenyGroups` 中某个组，就会被拒绝登录。

**Deny 优先级高于 Allow**！



### PAM配置用户白名单和黑名单

可选用以下方式

- `pam_listfile.so` 模块

  1. 在`/etc/pam.d/sshd`文件中添加：

     ```shell
     auth required pam_listfile.so item=group sense=allow file=/etc/ssh/ssh.allow_groups onerr=fail
     auth required pam_listfile.so item=user  sense=allow file=/etc/ssh/ssh.allow_users  onerr=fail
     auth substack password-auth
     ```

     `sense`取值：黑名单值为`deny`，白名单值为`allow`。

  2. 在上面配置的file对应的文件中添加黑名单/白名单用户/用户组，一行一个。

  

- `pam_access.so` + `/etc/security/access.conf`（规则更灵活）

  1. 在 /etc/pam.d/sshd 中添加：

     ```shell
     # 通常放在 account required pam_nologin.so 或 account include password-auth 之前
     account required pam_access.so 
     ```

  2. 编辑 `/etc/security/access.conf`

     这是一个基于“用户/组 + 来源主机”的控制文件。例子

     ```shell
     #permission : users/groups : origins
     
     + : root : ALL
     + : git : ALL
     + : lsfadmin : ALL
     + : %cad : ALL
     - : ALL : ALL
     ```

     + `+`表示允许，`-` 表示拒绝

     - `ALL` 通配所有

     - `%groupname` 表示组

     - tty、console、主机名/IP也可指定来源



# 问题解决

ssh命令中使用参数`-v`可输出详细的调试信息，`-vvv`可以显示更多的信息。

在ssh服务端检查sshd日志，如`systemctl status sshd`。



## ssh密钥登录失败问题

已经上传公钥仍然不能免密码登录。

- 可能是selinux处于enforcing模式

  关闭selinux

  ```shell
  setenforce 0
  sed -i '/SELINUX=/c SELINUX=disabled' /etc/selinux/config
  ```

  或者配置相关策略

  

- 关闭了用户密钥登录

  修改sshd_config：

  ```shell
  PubkeyAuthentication yes #默认注释 值为yes
  ```

- > error fetching identities for protocol 1: agent refused operation

  在客户端执行：

  ```shell
  eval "$(ssh-agent -s)"
  ssh-add
  ```

  

- 已经进行ssh密钥认证而提示输入密码

  - 重要目录/文件权限问题——权限过于宽松，提示permission too open

    ssh服务端的sshd_config中`StrictModes`设置为`off`（需要去掉注释）可关闭对服务的重要目录/文件的权限检查，但不建议！

    

    - ssh服务端的用户家目录权限

      用户家目录对组（group）成员或其他（others）用户不能有写权限，

      ```shell
      chmod g-w,o-w $HOME
      ```
      
    - 服务端和客户端`$HOME/.ssh`目录及目录下文件的权限
    
      `.ssh`文件夹权限为700（`drwx------`），`.ssh`目录中的私钥文件设置为600（`-rw-------`），`authorized_keys`不能让组用户和其他用户有写权限（其他一些文件可以权限宽松，如`.ssh/config`）：
      
      ```shell
      chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
    
    
    
  - ssh服务端是否禁用了密钥认证，查看`/etc/ssh/sshd_config`

    ```shell
    #PubkeyAuthentication yes #默认yes且注释 未注释且为no则关闭密钥认证
    AuthorizedKeysFile      .ssh/authorized_keys
    #检查以下几行 默认值为如下内容（默认注释）
    #AuthorizedPrincipalsFile none
    #AuthorizedKeysCommand none
    #AuthorizedKeysCommandUser nobody
    ```
    
    修改后重启sshd服务。
    
  - 客户端存在多个密钥对时，可能需要指定使用的私钥

    ```shell
    ssh -i /path/to/private-key/ [-p port] user@host
    ```

- 集群环境中，用户家目录在共享存储上的情况，注意检查不同节点上用户的目录是否为共享存储上的同一目录。

  

## 登录卡顿或缓慢但是能够登录成功

### 环境较差网络使用mosh

如果因为网络较差而导致的使用不畅，可以换用以UDP传输数据的[mosh](https://wiki.archlinux.org/index.php/Mosh_(简体中文))进行远程连接：

1. 服务端和客户端均安装mosh

   mosh默认使用从60000到61000的UDP端口，一个Mosh连接就会打开一个UDP端口，比如建立两个连接就是60001、60002，以此类推，也可以使用`-p`选项指定UDP端口。

   

2. 使用mosh访问服务端

   ```shell
   #可使用-p指定mosh的udp端口
   mosh [-p mosh_udp_port] <user>@<server>
   
   #如果要使用ssh的选项，使用-ssh="ssh命令及选项内容"
   #例如sshd的端口不是默认的22时，必须制定ssh -p <sshd端口>的--ssh命令
   mosh -p 12345 --ssh="ssh -p 2222" user1@server1
   ```



### ssh验证相关原因

以下所述内容不包括因为网络因素（比如与ssh服务器之间的网络很差、安全防火墙等工具/设备检查时间过长）引起的使用问题。



- 服务端sshd配置中启用了GSS认证（GSSAPIAuthentication，公共安全事务认证）导致登陆慢

  认证中启用了GSS但是没有使用到GSS，增加无意义的校验步骤。如果不使用GSS，可修改sshd_config禁止GSS认证，重启sshd服务。

  ```shell
  GSSAPIAuthentication no
  ```

  

- 服务端设置了DNS查询

  如果服务器根据客户端IP进行DNS查询，ssh实际上用不上查询DNS，增加了无意义查询步骤，或者因为（各种网络因素）查询时间过长（应当排查网络服务）。
  
  如无需要，可修改sshd_config禁止使用DNS查询，重启sshd服务。
  
  ```shell
  UseDNS no
  ```



- 服务端polkit或systemd-logind等服务的问题导致sshd服务不正常

  ssh -v登录显示可能在`ledge: network`后卡顿，`systemctl status sshd`可能显示：

  > pam_systemd(sshd:session): Failed to create session: Connection reset by peer

  ssh -v调试的同时，使用`systemctl status`检查 sshd、systemd-logind和polkit状态，可能有错误信息以供排查，如果服务异常退出，重启有问题的服务。

  

  如果重启polkit服务后其状态仍不正常，重装（覆盖安装）polkit、openssh-server等软件包并重启对应服务；重启polkit服务可能不能完全重置服务而不能解决问题，则如果仍有问题重启系统。

 

### 系统环境相关

ssh验证通过，会出现类似`Last login`的登陆提示，出现该提示说明已经完成ssh登陆。ssh登陆后shell卡住，可能：

- shell配置文件问题

  以bash为例：

  登陆卡住为执行`/etc/profile`、`/etc/profile.d`、`~/.bash_profile`或`~/.bashrc`等文件造成。

  在登陆后执行bash，为`~/.bashrc`文件造成。

- 网络文件系统挂载问题

  例如nfs、glusterfs客户端挂载出现问题，在ssh登陆该服务器时可能会出现无法初始化shell。

成功登录但是不出现命令提示符，一般是载入shell初始配置文件卡住，使用以下方式绕过载入shell的初始配置文件，登录后排查解决：

```shell
ssh -t user@server "bash --noprofile"
#或
ssh -t user@server "bash --norc" #todo
ssh -t user@server /bin/sh
```

`--noprofile`不载入任何全局或个人初始配置文件，包括`/etc/profile` 、`~/.bash_profile`、`~/.bash_login`和`~/.profile`等。

`--norc`不载入个人初始配置文件`~/.bashrc`。

如果仍然不能完成shell初始化，可能需要使用其他方式登录系统进行检查。

```shell
bash -x #检查哪一步加载造成卡顿

strace -fF su - $USER
#或者
strace -fF bash
```

可能原因有：shell初始化脚本问题、系统崩溃或者十分繁忙、网络文件系统（如果NFS）问题。



## 各种ssh登录失败原因

- 地址、端口错误

- 用户名/密码错误

  - 错误的用户名或密码
  - 用户未设置密码
  - 服务端禁止所有用户或该用户使用密码登录
  - 该用户被锁定（禁用）

  

- 开启了`ControlPersist`（参看[持续连接](#持续连接)），但因为各种原因中断后，缓存的信息失效，

  删除客户端中`ControlPath` 配置的对应目录中关于该sshd服务器缓存文件。

  

- 客户端地址被服务器屏蔽

  - 在黑名单中
  - 不在白名单中
  - 防火墙、pam等屏蔽

  

- ssh服务器上文件系统空间已满

  

- `System is booting up. See pam_nologin(8)`

  删除服务端的`/var/run/nologin`或`/etc/nologin`或`/var/nologin`或`/run/nologin`等文件。

  

- ` REMOTE HOST IDENTIFICATION HAS CHANGED` 远程主机公钥未能通过主机密钥检查

  客户端首次登录ssh服务器时，客户端会记录服务器的公钥信息，如果连接服务器时，服务器公钥与know_hosts列表中记录的公钥不同（例如远程主机更改了密钥），就会校验不通过。

  移除客户端`.ssh/known_hosts`文件中检查不通过的ssh服务器的公钥信息：
  
  ```shell
  rm ~/.ssh/know_hosts
  #或者
  ssh-keygen -R <host>
  ```
  
  


- `command not found` 执行远程命令提示找不到命令

  使用ssh服务器上的**非root用户**执行位于其`/sbin`（或`/usr/sbin/`）目录下的程序时，提示"command not found"，解决方法：

  - 使用root用户执行

  - 如果该用户具有sudo权限，在命令前添加sudo执行

  - 使用绝对路径执行，例如：

    ```shell
    /usr/sbin/ip a
    /usr/sbin/lspci
    ```

  

- `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`

  检查服务端`/etc/ssh/sshd_config`是否关闭了密码登录。如需开启密码登录，修改该行：

  ```shell
  PasswordAuthentication no #注释该行或值改为yes 再重启sshd服务
  ```

  

- 协议不支持

  均可以升级服务器/客户端的ssh程序版本解决。

  - `no matching key exchange method found. Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1`

    服务端ssh版本过低，不支持`diffie-hellman-group1-sha1`等协议，在其`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

    ```shell
    KexAlgorithms +diffie-hellman-group1-sha1
    ```

  - `no compatible cipher.The server supports these cipher:  aes128-ctr,aes192-ctr,aes256-ctr`

    服务端不支持`aes128`等加密协议。在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

    ```shell
    Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
    ```

  

- ssh: Exited: String too long

  很可能当前ssh客户端或ssh服务端使用的是[dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html) ssh，参看[dropbear ssh基本使用](dropbear-ssh-usage.md)



---

~/.ssh/authorized_keys中还可以配置ssh的选项，其中`command`选项还能指定ssh登录时要执行命令，示例：

```shell
no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"admin\" rather than the user \"root\".';echo;sleep 10;exit 142"
```

