# 简介

dropbear是一款基于ssh协议的轻量sshd服务器。

> **Dropbear**是由Matt Johnston所开发的[Secure Shell](https://zh.wikipedia.org/wiki/Secure_Shell)软件（包括服务端与客户端）。期望在存储器与运算能力有限的情况下取代[OpenSSH](https://zh.wikipedia.org/wiki/OpenSSH)，尤其是[嵌入式系统](https://zh.wikipedia.org/wiki/嵌入式系统)[[1\]](https://zh.wikipedia.org/wiki/Dropbear#cite_note-official-1)。

Dropbear实现了[SSH](https://zh.wikipedia.org/wiki/Secure_Shell)协议第二版（SSH-2）。加密算法则是采用了其他第三方的实现。因此openssh客户端可以访问dropbear服务端，dropbear客户端也可以访问openssh服务端。



# dropbear与openssh

dropbear与openssh类似功能角色程序对比：

| 程序     | dropbear               | openSSH    |
| -------- | ---------------------- | ---------- |
| 服务端   | dropbear               | sshd       |
| 客户端   | dbclient/dropbearmulti | ssh        |
| 密钥生成 | dropbearkey            | ssh-keygen |
| 复制     | scp                    | scp        |



# dropbear使用

## 生成密钥对

用`dropbearkey`生成私钥，再使用私钥生成公钥：

```shell
#1. 私钥
#dropbearkey -t <type> -f <path/to/file> [-s <num of key bits>] [-y]
#-y Just print the publickey and fingerprint for the private key
dropbearkey -t rsa -f id_dropbear #-s 2048

#2. 公钥
dropbearkey -f id_dropbear | grep "^ssh-rsa " > id_dropbear.pub
```

dbclient默认使用的私钥一般是`.ssh/id_dropbear`，具体情况可能有所不同，查看dbclient的帮助文件了解。



openssh 客户端可使用ssh-copy-id上传公钥到dropbear服务器，dropbear客户端没有类似的程序，可以添加公钥内容到openssh服务器上用户的`~/.ssh/authorized_keys`中。



## dbcleint登陆

dbclient支持一部分和ssh相同功能的参数，对比openssh，dbclient常用参数中不支持`-C`压缩数据传输，

dbclient支持本地转发`-L`和远程转发`-R`，不支持动态转发`-D`。



注意：以上内容机遇文章写作时所了解的情况，具体应参照其使用文档。



